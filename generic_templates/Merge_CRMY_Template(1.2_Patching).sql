

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
DECLARE  @correct_guid uniqueidentifier = '370D4557-C506-43AC-8E24-EB53B5DB71CE'	--KEYFIELD INTERNATIONAL BERHAD
		,@wrong_guid uniqueidentifier	= '3608FCA9-C71D-40F0-9F05-32FF1DA1B07C'	--KEYFIELD INTERNATIONAL BHD
		,@user_guid uniqueidentifier	= (SELECT user_guid FROM HSUSER WHERE login_name = 'qianpin' AND is_deleted = '0')
		,@correction_datetime datetime	= GETDATE()




--INSERTION / UPDATING TABLES
--======================================================

-- ======== ENTITY_SHAREHOLDING_ALL ======== --
INSERT INTO dbo.ENTITY_SHAREHOLDING_ALL (entity_shrhldg_guid, relationship_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, internal_comment, external_comment, is_active, source_guid)
SELECT new_ent_shr_guid, new_rel_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, [copy_rel_comment], external_comment, is_active, source_guid
FROM ##entity_shareholding


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
FROM ##mod

INSERT INTO dbo.RELATIONSHIP(relationship_guid, workflow_state, entity_from_guid, entity_to_guid, relationship_subtype_uid, from_date, to_date, is_past_relationship, modification_info, external_comment, internal_comment, permission_group_guid, active_source_date, DESIGNATION_TYPE)
SELECT new_rel_guid, workflow_state, entity_from_guid, entity_to_guid, relationship_subtype_uid, from_date, to_date, is_past_relationship, modification_info, external_comment, internal_comment, permission_group_guid, active_source_date, DESIGNATION_TYPE
FROM ##new_rel

INSERT INTO dbo.RELATIONSHIP_SOURCE (relationship_source_guid, relationship_guid, source_guid, modification_info, document_location, discovered_start_date, discovered_end_date, discovered_as_past_relationship, comment)
SELECT new_rs_guid, new_rel_guid, source_guid, modification_info, document_location, discovered_start_date, discovered_end_date, discovered_as_past_relationship, comment
FROM ##new_rel_source


--======================================================
--CLEAN UP
--======================================================
DROP TABLE ##mod
DROP TABLE ##new_rel
DROP TABLE ##new_rel_source
DROP TABLE ##entity_shareholding



COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO
