
USE Ketupat_FE
GO

SET XACT_ABORT ON;  
GO  
BEGIN TRANSACTION; 

--BOTH HAVE THE EXACT SAME NAME
--SELECT * FROM KETUPAT_FE.DBO.ENTITY WHERE ACTIVE_NAME = 'BORNEO FOODSHOP SDN BHD'
-----------------------------------------------------------------------------------------------------------------
DECLARE  @correct_guid uniqueidentifier = 'B16644E9-B7F1-442D-9FEE-FEBE5FB51F9D'
		,@wrong_guid uniqueidentifier	= 'F218953B-8795-4DAD-8DD9-CC6628F987DC'
		,@user_guid uniqueidentifier	= 'E0FC8B59-4F68-4ADF-B7A7-BCB666D15E5F'	--qianpin
		,@correction_datetime datetime	= GETDATE()


--======================================================
--ENTITY_IDENTITY (check that identity_text is not duplicated for the same entity_guid)
--======================================================

--======================================================
--MODIFICATION
--======================================================

--======================================================
--FINANCIAL_HIGHLIGHTS_ALL
--======================================================


--======================================================
--ENTITY_NAMES
--======================================================

/* CP:	This generic code checks and merges the name aliases together, 
		this inserts any name aliases from the discarded entity that are not found in the retained entity as inactive name aliases
*/

INSERT INTO dbo.ENTITY_NAMES (is_active, name, language, startdate, enddate,entity_guid, source_guid)
SELECT is_active = 0, name, language, startdate, enddate,entity_guid = @correct_guid, source_guid
FROM dbo.ENTITY_NAMES en
WHERE entity_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM dbo.ENTITY_NAMES ew WHERE ew.entity_guid=@wrong_guid AND ew.name=en.name)

--======================================================
--ADDRESS (NOTHING RETURNED)
--======================================================

--======================================================
--ENTITY_CITIZENSHIP (NOTHING RETURNED)
--======================================================

--======================================================
--ENTITY_BLACKLIST (NOTHING RETURNED)
--======================================================

--======================================================
--ENTITY_CAPITAL_ALL
--======================================================

--======================================================
--SICC (industry classification) SECONDARY TBL
--======================================================

--======================================================
--RELATIONSHIP
--======================================================
--===============
-- FROM PORTION
--===============

/* CP:	This method checks for relationships that should be inherited into the correct entity
		The key columns we use to compare are entity_from, entity_to and rel_subtype only. This can be modified if necessary
*/

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
where id = (SELECT modification_info FROM RELATIONSHIP WHERE entity_from_guid = @wrong_guid)


/* prepare new relationships that needs to be added */
SELECT new_rel_guid = NEWID(), *
INTO #new_rel
FROM dbo.RELATIONSHIP r
WHERE entity_from_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w WHERE w.entity_from_guid=@correct_guid AND w.entity_to_guid=r.entity_to_guid AND w.relationship_subtype_uid=r.relationship_subtype_uid)

INSERT INTO #new_rel
SELECT new_rel_guid = NEWID(), *
FROM dbo.RELATIONSHIP r
WHERE entity_to_guid = @wrong_guid
AND NOT EXISTS (SELECT 1 FROM RELATIONSHIP w WHERE w.entity_to_guid=@correct_guid AND w.entity_from_guid=r.entity_from_guid AND w.relationship_subtype_uid=r.relationship_subtype_uid)
select * from #new_rel
/* make the correction on new_rel */
UPDATE #new_rel
SET  entity_from_guid	= IIF(entity_from_guid = @wrong_guid, @correct_guid, entity_from_guid)
	,entity_to_guid		= IIF(entity_to_guid = @wrong_guid, @correct_guid, entity_to_guid)
	,internal_comment	= CONCAT(internal_comment, char(13), CAST(GETDATE() as DATE),': copied from rel_guid (',relationship_guid,') due to merge in ',IIF(entity_from_guid=@wrong_guid,'entity_from','entity_to'))


SELECT new_rel_guid, new_mod_id = NEWID(), m.*
INTO #mod
FROM #new_rel r
JOIN dbo.MODIFICATION m on m.id=r.modification_info

/* prep rel_source */
SELECT r.new_rel_guid, new_rs_guid = NEWID(), rs.*
INTO #new_rel_source
FROM dbo.RELATIONSHIP_SOURCE rs
JOIN #new_rel r on r.relationship_guid = rs.relationship_guid

INSERT INTO #mod
SELECT rs.new_rs_guid,NEWID(), m.*
FROM #new_rel_source rs
JOIN dbo.MODIFICATION m on m.id=rs.modification_info


/* prepare mod entries */
UPDATE #mod
SET  creation_datetime  = @correction_datetime
	,creation_user		= @user_guid

UPDATE r
SET modification_info = m.new_mod_id
FROM #new_rel r
JOIN #mod m on r.new_rel_guid=m.new_rel_guid

UPDATE rs
SET modification_info = m.new_mod_id
FROM #new_rel_source rs
JOIN #mod m on rs.new_rs_guid=m.new_rel_guid


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
--ENTITY
--======================================================

--CP: I combined Soft Delete and update internal comment into 1 single update
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


--======================================================
--ENTITY_SHAREHOLDING_ALL
--======================================================
--Creates a new batch of entity_shrhldg_guid
SELECT 
	new_rel_guid
	, new_ent_shr_guid = NEWID()
	, r.internal_comment as copy_rel_comment
	, a.*
INTO #entity_shareholding
FROM #new_rel r
JOIN dbo.ENTITY_SHAREHOLDING_ALL a on a.relationship_guid = r.relationship_guid

INSERT INTO dbo.ENTITY_SHAREHOLDING_ALL (entity_shrhldg_guid, relationship_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, internal_comment, external_comment, is_active, source_guid)
SELECT new_ent_shr_guid, new_rel_guid, shr_type_uid, capital_currency, nominal_val, guaranteed_amt, shr_allocated, joint_shareholding, shr_allocated_joint, is_joint, from_date, [copy_rel_comment], external_comment, is_active, source_guid
FROM #entity_shareholding


/* ======================================================
clean up 
====================================================== */
DROP TABLE #mod
DROP TABLE #new_rel
DROP TABLE #new_rel_source
DROP TABLE #entity_shareholding



COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO
