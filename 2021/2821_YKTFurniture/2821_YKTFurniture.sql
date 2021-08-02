--========================
--#2821 YKT FURNITURE SDN BHD (1001975U) - CIMB Bank Berhad
--========================

--FIX PATCH
UPDATE Ketupat_FE.dbo.RELATIONSHIP
set is_past_relationship = 0 
where 
    relationship_guid = '9ffb1920-6eb1-4d4f-b8a9-78b2209ffd1e'
;