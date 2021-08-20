
--======================================================
--1.1 INVESTIGATION + PREPARATION
--======================================================


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
DECLARE  @correct_guid uniqueidentifier = 'ECCCD44E-E3D1-4B97-B0F7-36A97150E845'	--Y SAFE SDN. BHD.
		,@wrong_guid uniqueidentifier	= 'FCAE67ED-561F-4512-955D-70744FBED8C2'	--Y SAFE SDN BHD
		,@user_guid uniqueidentifier	= (SELECT user_guid FROM HSUSER WHERE login_name = 'qianpin' AND is_deleted = '0')
		,@correction_datetime datetime	= GETDATE()



-- INVESTIGATION
-- =================================
--IF RUN THE UBO SP, THE ENTITY_GUID AT degree=3 for MOHD YUSOF BIN HAJI NURIN is FCAE67ED-561F-4512-955D-70744FBED8C2
--But it should be ECCCD44E-E3D1-4B97-B0F7-36A97150E845
SELECT * FROM ENTITY WHERE ACTIVE_NAME = 'SAFEGUARDS G4S SDN BHD' --F22E21D3-121A-4E8D-8825-7B2941EEAE5C

SELECT * FROM ENTITY WHERE ACTIVE_NAME LIKE 'Y SAFE%' --FCAE67ED-561F-4512-955D-70744FBED8C2

--DEGREE 1
SELECT e.active_name, r.* FROM RELATIONSHIP r 
left join entity e on e.entity_guid = r.entity_from_guid
WHERE ENTITY_TO_GUID IN ('F22E21D3-121A-4E8D-8825-7B2941EEAE5C') --'FCAE67ED-561F-4512-955D-70744FBED8C2','ECCCD44E-E3D1-4B97-B0F7-36A97150E845'

--DEGREE 2 (SAFEGUARDS CORPORATION SDN BHD)
SELECT e.active_name, r.* FROM RELATIONSHIP r 
left join entity e on e.entity_guid = r.entity_from_guid
WHERE ENTITY_TO_GUID = 'F1F04B99-DECA-4954-8814-BCFB3A35ABD5'

--DEGREE 2 (EIGHTH JEWELS SYSTEMS SDN BHD)
SELECT e.active_name, r.* FROM RELATIONSHIP r 
left join entity e on e.entity_guid = r.entity_from_guid
WHERE ENTITY_TO_GUID = '6E189B2D-C5B9-4B9A-A074-0F0E49D288AD'

/*
* relationship_guid = '90FBC6C0-6D16-41C0-A085-C951925A2994', 
* need to change the entity_from_guid to 'ECCCD44E-E3D1-4B97-B0F7-36A97150E845'
*/

--AND relationship_subtype_uid = '47'

-- PREPARATION
-- =================================
-- ======== RELATIONSHIP ======== --
/*	
	STEPS
	1. Creates a "duplicate" relationship with @correct_guid based on every existing entity_FROM_guid=@wrong_guid relationship
		- Assigns a new @new_rel_guid for the created line(s)
		- Stores into #new_rel
	2. Creates a "duplicate" relationship with @correct_guid based on every existing entity_TO_guid=@wrong_guid relationship
		- Assigns a new @new_rel_guid for the created line(s)
		- Stores into #new_rel
	3. Updates #new_rel to replace @wrong_guid with @correct_guid, adds respective internal_comment
	4. Creates tmp MODIFICATION table #mod 
		- Assigns new MODIFICATION id for newly created NEW_RELATIONSHIP_GUID
	5. Prepares respective RELATIONSHIP_SOURCE table into tmp table #new_rel_source
	6. Assigns new MODIFICATION id for newly created NEW_RELATIONSHIP_SOURCE_GUID in Step 5
	7. Updates #mod with creation_datetime and creation_user
	8. Updates #new_rel table with modification_id created in Step 4
	9. Updates #new_rel_source table with modification_id created in Step 6

*/

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