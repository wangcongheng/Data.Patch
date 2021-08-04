--========================
--#2884 3 bros should be tagged to Venture Steel not Gemalto
--========================

--======================== FIX

/*
Below is to combine multiple update statements of below 2
update Ketupat_FE.dbo.ENTITY_NAMES
set is_active = 1 where name_id = 1368636;

update Ketupat_FE.dbo.ENTITY_NAMES
set is_active = 0 where name_id = 5743359
;
*/

update e 
set is_active = tmp.is_active
from Ketupat_FE.dbo.ENTITY_NAMES E
join (
select is_active = 1, name_id = 1368636
UNION
select is_active = 0, name_id = 5743359
) tmp on tmp.name_id = e.name_id
;
update Ketupat_FE.dbo.ENTITY
set active_name = 'VENTURE STEEL CORPORATION SDN. BHD.' 
where ENTITY_GUID = 'fef40756-e87a-4796-8dd2-adf6b274a62d'
;

