
USE Ketupat_FE
GO

SET XACT_ABORT ON;  
GO  
BEGIN TRANSACTION; 

/*
	Process is split into 2 parts to clearly segregate the TESTING phases from the PATCHING phase
	This is to avoid spending time on database restoration should the script fail at TESTING phase
		1.1 INVESTIGATION + PREPARATION
			- Can run without modifying current tables/data
		1.2 PATCHING
			- Once above 2 sections have been verified, proceed to commit the changes into current database 
*/

-----------------------------------------------------------------------------------------------------------------
declare  @correct_guid uniqueidentifier = 'EB66D3D1-AC3E-403B-92AB-61553A866E12'
		,@wrong_guid uniqueidentifier = '1BDA94BB-16B0-4CAF-9956-EF56B8038FC0'
		,@user_guid uniqueidentifier	= (SELECT user_guid FROM HSUSER WHERE login_name = 'qianpin' AND is_deleted = '0')
		,@correction_datetime datetime	= GETDATE()


--======================================================
--INVESTIGATION  /  FINDINGS
--======================================================

--Can't tell which is the correct/wrong guid
SELECT * FROM ENTITY WHERE ACTIVE_NAME LIKE '%ROSNI BINTI ZAHARI%'
SELECT * FROM MODIFICATION WHERE id in ('DF00BBCF-E2D8-4009-B973-7E18F175B3F3','06201AE8-197E-4522-B5EF-A47AB7E02F6D')
select e.active_name, r.* from relationship r
left join entity e on e.entity_guid = r.entity_from_guid
where entity_to_guid = '984CA5D0-216C-4BFB-82BD-7E1E20516131'  and relationship_subtype_uid = '47'

select * from entity_names where entity_guid in (@correct_guid, @wrong_guid)

select * from ENTITY_SHAREHOLDING_ALL where relationship_guid IN ('836C12A3-5F6A-4F8A-B908-396FAEC748C5','1BDA94BB-16B0-4CAF-9956-EF56B8038FC0')
--From Entity_Shareholder_All, there are no records for @wrong_guid

select e.active_name, r.* from relationship r left join entity e on e.entity_guid = r.entity_to_guid where entity_from_guid = @correct_guid order by e.active_name
select e.active_name, r.* from relationship r left join entity e on e.entity_guid = r.entity_to_guid where entity_from_guid = @wrong_guid
select * from relationship_subtype
/*
@wrong_guid is Director of RFK TECHONOLOGIES and 2 other companies (SRI JENGKA SDN BHD, ROSZA HOME DECOR) but there are no relationships from @correct_guid to those, so need to check to be sure that we are changing the correct one
*/
select * from ketupat.dbo.Shareholder_ROC_ALL where vchcompanyno = '1289732' order by source_date

select * from entity where active_name like '%RFK TECHNOLOGIES%'


--======================================================
--PREPARATION
--======================================================
-- ======== RELATIONSHIP ======== --
/*	
	STEPS
	1. Creates a "duplicate" relationship with @correct_guid based on every existing entity_FROM_guid=@wrong_guid relationship
		- Assigns a new @new_rel_guid for the created line(s)
		- Stores into ##new_rel
	2. Creates a "duplicate" relationship with @correct_guid based on every existing entity_TO_guid=@wrong_guid relationship
		- Assigns a new @new_rel_guid for the created line(s)
		- Stores into ##new_rel
	3. Updates ##new_rel to replace @wrong_guid with @correct_guid, adds respective internal_comment
	4. Creates tmp MODIFICATION table ##mod 
		- Assigns new MODIFICATION id for newly created NEW_RELATIONSHIP_GUID
	5. Prepares respective RELATIONSHIP_SOURCE table into tmp table ##new_rel_source
	6. Assigns new MODIFICATION id for newly created NEW_RELATIONSHIP_SOURCE_GUID in Step 5
	7. Updates ##mod with creation_datetime and creation_user
	8. Updates ##new_rel table with modification_id created in Step 4
	9. Updates ##new_rel_source table with modification_id created in Step 6

*/
--@wrong_guid has 2 other relationships that @correct_guid doesn't have
--	Director of SRI JENGKA SDN BHD		(subtype = 4)  is_past_relationship = 1
--	Business Owner of ROSZA HOME DECOR	(subtype = 98) is_past_relationship = 0

/*	STEP 1 */
SELECT new_rel_guid = NEWID(), *
INTO ##new_rel
FROM dbo.RELATIONSHIP r
WHERE entity_from_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_from_guid=@correct_guid 
												AND w.entity_to_guid=r.entity_to_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 2 */
INSERT INTO ##new_rel
SELECT new_rel_guid = NEWID(), *
FROM dbo.RELATIONSHIP r
WHERE entity_to_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_to_guid=@correct_guid 
												AND w.entity_from_guid=r.entity_from_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 3 */
UPDATE ##new_rel
SET  entity_from_guid	= IIF(entity_from_guid = @wrong_guid, @correct_guid, entity_from_guid)
	,entity_to_guid		= IIF(entity_to_guid = @wrong_guid, @correct_guid, entity_to_guid)
	,internal_comment	= CONCAT(internal_comment, char(13), CAST(GETDATE() as DATE),': copied from rel_guid (',relationship_guid,') due to merge in ',IIF(entity_from_guid=@wrong_guid,'entity_from','entity_to'))

	select * from ##new_rel
/*	STEP 4 */
SELECT new_rel_guid, new_mod_id = NEWID(), m.*
INTO ##mod
FROM ##new_rel r
JOIN dbo.MODIFICATION m on m.id=r.modification_info

/*	STEP 5 */
SELECT r.new_rel_guid, new_rs_guid = NEWID(), rs.*
INTO ##new_rel_source
FROM dbo.RELATIONSHIP_SOURCE rs
JOIN ##new_rel r on r.relationship_guid = rs.relationship_guid

/*	STEP 6 */
INSERT INTO ##mod
SELECT rs.new_rs_guid,NEWID(), m.*
FROM ##new_rel_source rs
JOIN dbo.MODIFICATION m on m.id=rs.modification_info


/*	STEP 7 */
UPDATE ##mod
SET  creation_datetime  = @correction_datetime
	,creation_user		= @user_guid

/*	STEP 8 */
UPDATE r
SET modification_info = m.new_mod_id
FROM ##new_rel r
JOIN ##mod m on r.new_rel_guid=m.new_rel_guid

/*	STEP 9 */
UPDATE rs
SET modification_info = m.new_mod_id
FROM ##new_rel_source rs
JOIN ##mod m on rs.new_rs_guid=m.new_rel_guid


------------------------------------------------------------------------
-- ======== ENTITY_SHAREHOLDING_ALL ======== --
--Creates a new batch of entity_shrhldg_guid
SELECT 
	new_rel_guid
	, new_ent_shr_guid = NEWID()
	, r.internal_comment as copy_rel_comment
	, a.*
INTO ##entity_shareholding
FROM ##new_rel r
JOIN dbo.ENTITY_SHAREHOLDING_ALL a on a.relationship_guid = r.relationship_guid


------------------------------------------------------------------------
SELECT * FROM ##mod
SELECT * FROM ##new_rel
SELECT * FROM ##new_rel_source
SELECT * FROM ##entity_shareholding


COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO
