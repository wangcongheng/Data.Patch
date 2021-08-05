

--ISSUE #3265 RFK TECHNOLOGIES 1289732M
SELECT * FROM KETUPAT.dbo.Shareholder_ROC_ALL where vchcompanyno like '%1289732%' --vchcompanyname like '%RFK TECHNOLOGIES%'    --vchcompanyno like '%1289732M%'
SELECT * FROM KETUPAT_FE.dbo.ENTITY WHERE active_name like '%RFK TECHNOLOGIES%' --entity_guid = '984CA5D0-216C-4BFB-82BD-7E1E20516131'

SELECT e.active_name, r.is_past_relationship ,r.* FROM KETUPAT_FE.dbo.RELATIONSHIP r
left join KETUPAT_FE.dbo.ENTITY e
	on e.entity_guid = r.entity_from_guid
where entity_to_guid = '984CA5D0-216C-4BFB-82BD-7E1E20516131' and relationship_subtype_uid = '47'

--who is the correct DATO
SELECT * FROM KETUPAT_FE.dbo.ENTITY WHERE entity_guid in ('EB66D3D1-AC3E-403B-92AB-61553A866E12','1BDA94BB-16B0-4CAF-9956-EF56B8038FC0')
SELECT top 10 * FROM KETUPAT.DBO.ROB_OWNER_ALL where name like '%ROSNI BINTI ZAHARI%' -- where nic_no = '610411035338'
SELECT * FROM KETUPAT_FE.dbo.MODIFICATION  WHERE id ='DF00BBCF-E2D8-4009-B973-7E18F175B3F3'  --2018-02-21 10:03:00 (WE LOST DATA FROM 2018 TO 2019)

--correct: '1BDA94BB-16B0-4CAF-9956-EF56B8038FC0' --mod = 'DF00BBCF-E2D8-4009-B973-7E18F175B3F3'
--wrong  : 'EB66D3D1-AC3E-403B-92AB-61553A866E12' --mod = '06201AE8-197E-4522-B5EF-A47AB7E02F6D'
--DATO' ROSNI BINTI ZAHARI
select * from ketupat.dbo.Shareholder_ROC_ALL where vchname like '%OSNI BINTI ZAHARI%' order by source_date

--======================================================
--PERFORM HARMONIZATION
--======================================================
USE Ketupat_FE
GO

SET XACT_ABORT ON;  
GO  
BEGIN TRANSACTION; 

ALTER TABLE [ADDRESS] NOCHECK CONSTRAINT ALL
ALTER TABLE ENTITY NOCHECK CONSTRAINT ALL
ALTER TABLE ENTITY_NAMES NOCHECK CONSTRAINT ALL
ALTER TABLE ENTITY_CAPITAL_ALL NOCHECK CONSTRAINT ALL
ALTER TABLE ENTITY_BLACKLIST NOCHECK CONSTRAINT ALL
ALTER TABLE RELATIONSHIP NOCHECK CONSTRAINT ALL

--correct: '1BDA94BB-16B0-4CAF-9956-EF56B8038FC0' --mod = 'DF00BBCF-E2D8-4009-B973-7E18F175B3F3'
--wrong  : 'EB66D3D1-AC3E-403B-92AB-61553A866E12' --mod = '06201AE8-197E-4522-B5EF-A47AB7E02F6D'
--DATO' ROSNI BINTI ZAHARI
-----------------------------------------------------------------------------------------------------------------
DECLARE @harmo_guid uniqueidentifier = '1BDA94BB-16B0-4CAF-9956-EF56B8038FC0'
Declare @old_guid uniqueidentifier = 'EB66D3D1-AC3E-403B-92AB-61553A866E12'
DECLARE @harmo_id uniqueidentifier = 'DF00BBCF-E2D8-4009-B973-7E18F175B3F3'
DECLARE @old_mod_id uniqueidentifier = '06201AE8-197E-4522-B5EF-A47AB7E02F6D'


--======================================================
--ENTITY_IDENTITY
--======================================================
select * from Ketupat_FE.dbo.ENTITY_IDENTITY
where entity_guid in (@harmo_guid, @old_guid)

--select * from Ketupat_FE.dbo.ENTITY_IDENTITY where entity_guid IN (@old_guid, @harmo_guid)
delete from Ketupat_FE.dbo.ENTITY_IDENTITY where entity_guid = @old_guid

--update Ketupat_FE.dbo.ENTITY_IDENTITY
--set entity_guid = @harmo_guid
--where entity_guid =  @old_guid

select * from Ketupat_FE.dbo.ENTITY_IDENTITY
where entity_guid in (@harmo_guid, @old_guid)


--======================================================
--ENTITY
--======================================================
--Declare @old_guid uniqueidentifier = 'EB66D3D1-AC3E-403B-92AB-61553A866E12'
select * from Ketupat_FE.dbo.entity where entity_guid IN (@old_guid)
delete from Ketupat_FE.dbo.entity where entity_guid IN (@old_guid)

update Ketupat_FE.dbo.ENTITY
set entity_guid = @harmo_guid
	--,date_of_incorporation = '1968/09/21'
	--,nric = '6836030G'
   --,active_name = 
where entity_guid = @old_guid

select * from Ketupat_FE.dbo.entity where entity_guid in (@harmo_guid, @old_guid)

--======================================================
--MODIFICATION
--======================================================

select * from Ketupat_FE.dbo.MODIFICATION where id in (@old_mod_id, @harmo_id)

delete from Ketupat_FE.dbo.MODIFICATION where id in (@old_mod_id)

select * from Ketupat_FE.dbo.MODIFICATION where id in (@old_mod_id, @harmo_id)

--======================================================
--FINANCIAL_HIGHLIGHTS_ALL
--======================================================
select * from Ketupat_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL where entity_guid in (@harmo_guid, @old_guid)

update Ketupat_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL
set entity_guid = @harmo_guid
where entity_guid = @old_guid

--select * from Ketupat_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL
--where entity_guid in ('C77CBE73-F50C-4C49-ABBA-F9510B45D867', '95AE0363-6EC6-4039-8691-4A1571FC0BD0','A5E80394-C52B-449A-B625-A5CD49F51125')


--======================================================
--ENTITY_NAMES
--======================================================


select * from Ketupat_FE.dbo.ENTITY_NAMES where entity_guid in (@harmo_guid, @old_guid)

delete from Ketupat_FE.dbo.entity_names where entity_guid IN (@old_guid)

--update Ketupat_FE.dbo.entity_names
--set is_active = 0
--where entity_guid IN ('95AE0363-6EC6-4039-8691-4A1571FC0BD0','A5E80394-C52B-449A-B625-A5CD49F51125')

update Ketupat_FE.dbo.entity_names
set entity_guid = @harmo_guid
where entity_guid =@old_guid

select * from Ketupat_FE.dbo.ENTITY_NAMES where entity_guid in (@harmo_guid, @old_guid)

--======================================================
--ADDRESS
--======================================================

select * from Ketupat_FE.dbo.ADDRESS
where entity_guid in (@harmo_guid, @old_guid)
order by entity_guid, source_guid

--delete Ketupat_FE.dbo.ADDRESS
--where entity_guid = '95AE0363-6EC6-4039-8691-4A1571FC0BD0','A5E80394-C52B-449A-B625-A5CD49F51125'

--update Ketupat_FE.dbo.address
--set is_active = 0
--where entity_guid IN ('95AE0363-6EC6-4039-8691-4A1571FC0BD0','A5E80394-C52B-449A-B625-A5CD49F51125')

update Ketupat_FE.dbo.address
set entity_guid = @harmo_guid
where entity_guid =@old_guid

select * from Ketupat_FE.dbo.ADDRESS
where entity_guid in (@harmo_guid, @old_guid)



--======================================================
--ENTITY_CITIZENSHIP
--======================================================
select * from Ketupat_FE.dbo.ENTITY_CITIZENSHIP
where entity_guid in (@harmo_guid, @old_guid)
order by entity_guid, source_guid

--delete from Ketupat_FE.dbo.ENTITY_CITIZENSHIP
--where guid IN ('CD9D9086-A2B4-4B72-9D63-077E852EC8AE',
--'E69647DF-73A5-4151-823C-5282338932BF',
--'DF4413AD-AED8-4F69-85A4-791A3A2F51B3',
--'B6BD52DF-6C84-4431-889B-CEF0522D2183',
--'D8286CDE-F204-4257-A443-84EFD9E5F389')
--and entity_guid in ('C77CBE73-F50C-4C49-ABBA-F9510B45D867', '95AE0363-6EC6-4039-8691-4A1571FC0BD0','A5E80394-C52B-449A-B625-A5CD49F51125')

update Ketupat_FE.dbo.ENTITY_CITIZENSHIP
set entity_guid = @harmo_guid
where entity_guid =@old_guid

select * from Ketupat_FE.dbo.ENTITY_CITIZENSHIP
where entity_guid in (@harmo_guid, @old_guid)


--======================================================
--ENTITY_BLACKLIST
--======================================================
select * from Ketupat_FE.dbo.ENTITY_BLACKLIST
where entity_guid in (@harmo_guid, @old_guid)

--select * from HandshakesWebDB.dbo.UserEntitys
--where entity_guid in (@harmo_guid, @old_guid)



--======================================================
--ENTITY_CAPITAL_ALL
--======================================================

select * from Ketupat_FE.dbo.ENTITY_CAPITAL_ALL
where entity_guid in (@harmo_guid, @old_guid)

update Ketupat_FE.dbo.ENTITY_CAPITAL_ALL
set entity_guid = @harmo_guid
where entity_guid =@old_guid

select * from Ketupat_FE.dbo.ENTITY_CAPITAL_ALL
where entity_guid in (@harmo_guid, @old_guid)


--======================================================
--SICC
--======================================================
select * from Ketupat_FE.dbo.SICC
where entity_guid in (@harmo_guid, @old_guid)

update Ketupat_FE.dbo.SICC
set entity_guid = @harmo_guid
where entity_guid = @old_guid

select * from Ketupat_FE.dbo.SICC
where entity_guid in (@harmo_guid, @old_guid)


--======================================================
--RELATIONSHIP
--======================================================
select 
	relationship_guid
	, workflow_state
	, entity_from_guid
	, entity_to_guid
	, relationship_subtype_uid
	, is_past_relationship
	, from_date
	, to_date
	, modification_info
	, REPLACE(REPLACE(REPLACE(external_comment, CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ')
	, REPLACE(REPLACE(REPLACE(internal_comment, CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ')
	, permission_group_guid
	, active_source_date
	, DESIGNATION_TYPE 
from Ketupat_FE.dbo.RELATIONSHIP
where 
	entity_from_guid in (@harmo_guid, @old_guid) OR entity_to_guid in (@harmo_guid, @old_guid)
--select * from Ketupat_FE.dbo.RELATIONSHIP where
order by entity_to_guid, relationship_subtype_uid

update Ketupat_FE.dbo.RELATIONSHIP set entity_from_guid = @harmo_guid where entity_from_guid = @old_guid

update Ketupat_FE.dbo.RELATIONSHIP set entity_to_guid = @harmo_guid where entity_to_guid  = @old_guid 



select 
	relationship_guid
	, workflow_state
	, entity_from_guid
	, entity_to_guid
	, relationship_subtype_uid
	, is_past_relationship
	, from_date
	, to_date
	, modification_info
	, REPLACE(REPLACE(REPLACE(external_comment, CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ')
	, REPLACE(REPLACE(REPLACE(internal_comment, CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ')
	, permission_group_guid
	, active_source_date
	, DESIGNATION_TYPE 
from Ketupat_FE.dbo.RELATIONSHIP
where 
	entity_from_guid in (@harmo_guid, @old_guid) OR entity_to_guid in (@harmo_guid, @old_guid)
order by entity_to_guid, relationship_subtype_uid

--======================================================
--PREP_ENTITY45
--======================================================
select * from Ketupat_Prep.dbo.PREP_ENTITY45
where e_guid in (@harmo_guid, @old_guid)

update Ketupat_Prep.dbo.PREP_ENTITY45
set e_guid = @harmo_guid
where e_guid = @old_guid


select * from Ketupat_Prep.dbo.PREP_ENTITY45
where e_guid in (@harmo_guid, @old_guid)


--------------------------------------------------------------

ALTER TABLE [ADDRESS] WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE ENTITY WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE ENTITY_NAMES WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE ENTITY_CAPITAL_ALL WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE ENTITY_BLACKLIST WITH CHECK CHECK CONSTRAINT ALL
ALTER TABLE RELATIONSHIP WITH CHECK CHECK CONSTRAINT ALL

COMMIT TRANSACTION;  
GO  
SET XACT_ABORT OFF; 
GO

