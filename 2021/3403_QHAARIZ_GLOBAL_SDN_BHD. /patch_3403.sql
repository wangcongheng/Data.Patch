--- TICKET 3403

-- Record of entity is updated by CTOS on the 7th July 2021 (previous company name is MJ LIFE ENTERPRISES SDN BHD)
--but shows no shareholder reported on LBO & on the Radial Map
--QHAARIZ GLOBAL SDN. BHD. (0734463T) CIMB
--it shows the current shareholder as a past shareholder – namely TEE SWEE GUAN.


-- Investigation
Select * from Ketupat_fe.dbo.entity where company_registration_number = '734463T' --QHAARIZ GLOBAL SDN. BHD.
Select * from Ketupat_fe.dbo.entity where active_name = 'TEE SWEE GUAN'
select * from ketupat_fe.dbo.modification where id = '9304D59F-0CBD-4855-810B-E2ACB19B56CE'
select * from ketupat_fe.dbo.RELATIONSHIP where entity_to_guid = '01223CB2-DE06-4A78-852E-F76D3FB82611' and entity_from_guid = '1A59AD29-FE94-4032-9102-E6C720038B00'


--Patching
update ketupat_fe.dbo.RELATIONSHIP
set is_past_relationship = '0' , internal_comment = concat(internal_comment,'20210813 Brute force changing is_past_relationship= '0' to align with CTOS report')
where relationship_guid = '5EB4018B-DB24-4A24-962D-ED6C7A125551'

update ketupat_fe.dbo.modification
set modification_datetime = GETDATE(), modification_user = 'BDDB8000-DB42-49AF-9937-9DE6E1FF4CC2' ,
where id = '9304D59F-0CBD-4855-810B-E2ACB19B56CE'




-- CHECKING
Exec ketupat_fe.dbo.GetUBORelationships  '01223CB2-DE06-4A78-852E-F76D3FB82611' --QHAARIZ GLOBAL SDN. BHD.
