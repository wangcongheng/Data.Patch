/*
CHECKING SCRIPT
*/
USE BAKKWA_FE

SELECT * FROM ENTITY WHERE ACTIVE_NAME like 'Dry Bulk%'
select a.[description], e.active_name, r.* from relationship r 
left join RELATIONSHIP_SUBTYPE a on a.relationship_subtype_uid = r.relationship_subtype_uid
left join entity e on e.entity_guid = r.entity_from_guid
where entity_to_guid = '9BEE5B28-2DE9-43CC-A7D9-9A6202E5DF3C'


select * from oneworld.dbo.RELATIONSHIP_SUBTYPE 

/* ================================================
   PATCHING
================================================ */
update Oneworld.dbo.Relationship_subtype
set [description] = 'Officer' 
,relationship_type_uid = 5
where relationship_subtype_uid = 108

update Oneworld.dbo.Relationship_subtype
set [description] = 'Public Accountant Employee' 
,relationship_type_uid = 5
where relationship_subtype_uid = 109

insert into Oneworld.dbo.Relationship_subtype (relationship_subtype_uid, [description], relationship_type_uid)
VALUES (110, 'Member', 3)

insert into Oneworld.dbo.Relationship_subtype (relationship_subtype_uid, [description], relationship_type_uid)
VALUES (111, 'Nominee / Trustee', 2)

insert into Oneworld.dbo.Relationship_subtype (relationship_subtype_uid, [description], relationship_type_uid)
VALUES (112, 'Sole-Proprietor / Partner', 5)

insert into Oneworld.dbo.Relationship_subtype (relationship_subtype_uid, [description], relationship_type_uid)
VALUES (113, 'General Partner As Nominee/Trustee', 5)

insert into Oneworld.dbo.Relationship_subtype (relationship_subtype_uid, [description], relationship_type_uid)
VALUES (114, 'General Partner as Agent of Foreign Firm', 5)

