
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
DECLARE  @correct_guid uniqueidentifier = '5B9A108B-E168-4464-91AD-2942A7C831E1'	--VIEWQWEST HOLDINGS  SDN. BHD.
	    ,@wrong_guid uniqueidentifier = '201AE58D-6B14-47C8-A9CB-0AA13BD48439'	--VIEWQWEST HOLDINGS SDN BHD
		,@user_guid uniqueidentifier	= (SELECT user_guid FROM HSUSER WHERE login_name = 'qianpin' AND is_deleted = '0')
		,@correction_datetime datetime	= GETDATE()


--======================================================
--1.1 INVESTIGATION + PREPARATION
--======================================================

-- INVESTIGATION
-- =================================
SELECT * FROM KETUPAT_FE.DBO.ENTITY WHERE ACTIVE_NAME LIKE '%KEYFIELD INTERNATIONAL B%'
--Straightforward, no relationship to patch. Just need to set wf=2 for the @wrong_guid in ENTITY

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
--There is no relationship for @wrong_guid

/*	STEP 1 */
SELECT new_rel_guid = NEWID(), *
INTO #new_rel
FROM dbo.RELATIONSHIP r
WHERE entity_from_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_from_guid=@correct_guid 
												AND w.entity_to_guid=r.entity_to_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 2 */
INSERT INTO #new_rel
SELECT new_rel_guid = NEWID(), *
FROM dbo.RELATIONSHIP r
WHERE entity_to_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_to_guid=@correct_guid 
												AND w.entity_from_guid=r.entity_from_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 3 */
UPDATE #new_rel
SET  entity_from_guid	= IIF(entity_from_guid = @wrong_guid, @correct_guid, entity_from_guid)
	,entity_to_guid		= IIF(entity_to_guid = @wrong_guid, @correct_guid, entity_to_guid)
	,internal_comment	= CONCAT(internal_comment, char(13), CAST(GETDATE() as DATE),': copied from rel_guid (',relationship_guid,') due to merge in ',IIF(entity_from_guid=@wrong_guid,'entity_from','entity_to'))


/*	STEP 4 */
SELECT new_rel_guid, new_mod_id = NEWID(), m.*
INTO #mod
FROM #new_rel r
JOIN dbo.MODIFICATION m on m.id=r.modification_info

/*	STEP 5 */
SELECT r.new_rel_guid, new_rs_guid = NEWID(), rs.*
INTO #new_rel_source
FROM dbo.RELATIONSHIP_SOURCE rs
JOIN #new_rel r on r.relationship_guid = rs.relationship_guid

/*	STEP 6 */
INSERT INTO #mod
SELECT rs.new_rs_guid,NEWID(), m.*
FROM #new_rel_source rs
JOIN dbo.MODIFICATION m on m.id=rs.modification_info


/*	STEP 7 */
UPDATE #mod
SET  creation_datetime  = @correction_datetime
	,creation_user		= @user_guid

/*	STEP 8 */
UPDATE r
SET modification_info = m.new_mod_id
FROM #new_rel r
JOIN #mod m on r.new_rel_guid=m.new_rel_guid

/*	STEP 9 */
UPDATE rs
SET modification_info = m.new_mod_id
FROM #new_rel_source rs
JOIN #mod m on rs.new_rs_guid=m.new_rel_guid


------------------------------------------------------------------------
-- ======== ENTITY_SHAREHOLDING_ALL ======== --
--Creates a new batch of entity_shrhldg_guid
SELECT 
	new_rel_guid
	, new_ent_shr_guid = NEWID()
	, r.internal_comment as copy_rel_comment
	, a.*
INTO #entity_shareholding
FROM #new_rel r
JOIN dbo.ENTITY_SHAREHOLDING_ALL a on a.relationship_guid = r.relationship_guid




------------------------------------------------------------------------
SELECT * FROM #mod
SELECT * FROM #new_rel
SELECT * FROM #new_rel_source
SELECT * FROM #entity_shareholding


COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO

--============================================================================================================
--============================================================================================================
--============================================================================================================


--======================================================
--1.2 PATCHING
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
DECLARE  @correct_guid uniqueidentifier = '5B9A108B-E168-4464-91AD-2942A7C831E1'	--VIEWQWEST HOLDINGS  SDN. BHD.
	    ,@wrong_guid uniqueidentifier = '201AE58D-6B14-47C8-A9CB-0AA13BD48439'	--VIEWQWEST HOLDINGS SDN BHD
		,@user_guid uniqueidentifier	= (SELECT user_guid FROM HSUSER WHERE login_name = 'qianpin' AND is_deleted = '0')
		,@correction_datetime datetime	= GETDATE()




--INSERTION / UPDATING TABLES
--======================================================

-- ======== ENTITY_SHAREHOLDING_ALL ======== --
INSERT INTO dbo.ENTITY_SHAREHOLDING_ALL (entity_shrhldg_guid, relationship_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, internal_comment, external_comment, is_active, source_guid)
SELECT new_ent_shr_guid, new_rel_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, [copy_rel_comment], external_comment, is_active, source_guid
FROM #entity_shareholding


------------------------------------------------------------------------
-- ======== ENTITY ======== --
--Combined Soft Delete and update internal comment into 1 single update
update Ketupat_FE.dbo.ENTITY
set  
	 workflow_state = '2' 
	,internal_comment = CONCAT(internal_comment, char(13), CAST(@correction_datetime as DATE), ': Set to DELETED as part of merge with entity_guid (',@correct_guid,')')
where entity_guid = @wrong_guid

update Ketupat_FE.dbo.MODIFICATION
set 
	 modification_datetime  = @correction_datetime 
	,modification_user		= @user_guid
where id = (SELECT modification_info FROM ENTITY WHERE entity_guid = @wrong_guid)


------------------------------------------------------------------------
-- ======== ENTITY_NAMES ======== --
/* 	This generic code checks and merges the name aliases together, 
	this inserts any name aliases from the discarded entity that are not found in the retained entity as inactive name aliases
*/
INSERT INTO dbo.ENTITY_NAMES (is_active, name, language, startdate, enddate,entity_guid, source_guid)
SELECT is_active = 0, name, language, startdate, enddate,entity_guid = @correct_guid, source_guid
FROM dbo.ENTITY_NAMES en
WHERE entity_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM dbo.ENTITY_NAMES ew WHERE ew.entity_guid=@wrong_guid AND ew.name=en.name)


------------------------------------------------------------------------
-- ======== RELATIONSHIP ======== --
/* Soft Delete the @wrong_guid relationships */
update Ketupat_FE.dbo.RELATIONSHIP
set  
	 workflow_state = '2' 
	,internal_comment = CONCAT(internal_comment, char(13), CAST(@correction_datetime as DATE), ': Set to DELETED as part of merge with entity_guid (',@correct_guid,')')
where entity_from_guid = @wrong_guid

update Ketupat_FE.dbo.MODIFICATION
set 
	 modification_datetime  = @correction_datetime 
	,modification_user		= @user_guid
where id IN (SELECT modification_info FROM RELATIONSHIP WHERE entity_from_guid = @wrong_guid)


/* commit changes */
INSERT INTO dbo.MODIFICATION (id, creation_datetime, creation_user, modification_datetime, modification_user, publication_datetime, publication_user)
SELECT new_mod_id, creation_datetime, creation_user, modification_datetime, modification_user, publication_datetime, publication_user
FROM #mod

INSERT INTO dbo.RELATIONSHIP(relationship_guid, workflow_state, entity_from_guid, entity_to_guid, relationship_subtype_uid, from_date, to_date, is_past_relationship, modification_info, external_comment, internal_comment, permission_group_guid, active_source_date, DESIGNATION_TYPE)
SELECT new_rel_guid, workflow_state, entity_from_guid, entity_to_guid, relationship_subtype_uid, from_date, to_date, is_past_relationship, modification_info, external_comment, internal_comment, permission_group_guid, active_source_date, DESIGNATION_TYPE
FROM #new_rel

INSERT INTO dbo.RELATIONSHIP_SOURCE (relationship_source_guid, relationship_guid, source_guid, modification_info, document_location, discovered_start_date, discovered_end_date, discovered_as_past_relationship, comment)
SELECT new_rs_guid, new_rel_guid, source_guid, modification_info, document_location, discovered_start_date, discovered_end_date, discovered_as_past_relationship, comment
FROM #new_rel_source


--======================================================
--CLEAN UP
--======================================================
DROP TABLE #mod
DROP TABLE #new_rel
DROP TABLE #new_rel_source
DROP TABLE #entity_shareholding



COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO

--======================================================
--INVESTIGATION  /  FINDINGS
--======================================================
SELECT * FROM KETUPAT_FE.DBO.ENTITY WHERE ACTIVE_NAME LIKE '%KEYFIELD INTERNATIONAL B%'
--Straightforward, no relationship to patch. Just need to set wf=2 for the @wrong_guid in ENTITY

--======================================================
--PREPARATION
--======================================================
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
--There is no relationship for @wrong_guid

/*	STEP 1 */
SELECT new_rel_guid = NEWID(), *
INTO #new_rel
FROM dbo.RELATIONSHIP r
WHERE entity_from_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_from_guid=@correct_guid 
												AND w.entity_to_guid=r.entity_to_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 2 */
INSERT INTO #new_rel
SELECT new_rel_guid = NEWID(), *
FROM dbo.RELATIONSHIP r
WHERE entity_to_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w  WHERE w.entity_to_guid=@correct_guid 
												AND w.entity_from_guid=r.entity_from_guid 
												AND w.relationship_subtype_uid=r.relationship_subtype_uid
												AND w.external_comment = r.external_comment
				)

/*	STEP 3 */
UPDATE #new_rel
SET  entity_from_guid	= IIF(entity_from_guid = @wrong_guid, @correct_guid, entity_from_guid)
	,entity_to_guid		= IIF(entity_to_guid = @wrong_guid, @correct_guid, entity_to_guid)
	,internal_comment	= CONCAT(internal_comment, char(13), CAST(GETDATE() as DATE),': copied from rel_guid (',relationship_guid,') due to merge in ',IIF(entity_from_guid=@wrong_guid,'entity_from','entity_to'))


/*	STEP 4 */
SELECT new_rel_guid, new_mod_id = NEWID(), m.*
INTO #mod
FROM #new_rel r
JOIN dbo.MODIFICATION m on m.id=r.modification_info

/*	STEP 5 */
SELECT r.new_rel_guid, new_rs_guid = NEWID(), rs.*
INTO #new_rel_source
FROM dbo.RELATIONSHIP_SOURCE rs
JOIN #new_rel r on r.relationship_guid = rs.relationship_guid

/*	STEP 6 */
INSERT INTO #mod
SELECT rs.new_rs_guid,NEWID(), m.*
FROM #new_rel_source rs
JOIN dbo.MODIFICATION m on m.id=rs.modification_info


/*	STEP 7 */
UPDATE #mod
SET  creation_datetime  = @correction_datetime
	,creation_user		= @user_guid

/*	STEP 8 */
UPDATE r
SET modification_info = m.new_mod_id
FROM #new_rel r
JOIN #mod m on r.new_rel_guid=m.new_rel_guid

/*	STEP 9 */
UPDATE rs
SET modification_info = m.new_mod_id
FROM #new_rel_source rs
JOIN #mod m on rs.new_rs_guid=m.new_rel_guid


------------------------------------------------------------------------
-- ======== ENTITY_SHAREHOLDING_ALL ======== --
--Creates a new batch of entity_shrhldg_guid
SELECT 
	new_rel_guid
	, new_ent_shr_guid = NEWID()
	, r.internal_comment as copy_rel_comment
	, a.*
INTO #entity_shareholding
FROM #new_rel r
JOIN dbo.ENTITY_SHAREHOLDING_ALL a on a.relationship_guid = r.relationship_guid




------------------------------------------------------------------------
SELECT * FROM #mod
SELECT * FROM #new_rel
SELECT * FROM #new_rel_source
SELECT * FROM #entity_shareholding


COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO
