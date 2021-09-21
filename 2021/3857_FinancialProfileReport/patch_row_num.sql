-- This patch reverts the row_num of fha and revert the row_num of all entities in FHA. The subsequent code change is done on bakkwa.etl

UPDATE Bakkwa_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL SET row_num = NULL
--where co_reg_no in (select distinct co_reg_no from bakkwa_prep.dbo.working_fh)
print CAST(@@ROWCOUNT as nvarchar(10)) + ' FH_ALL row_num reset all to null'
GO


--select *
UPDATE Bakkwa_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL SET row_num = l.row_num
FROM Bakkwa_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL fha
JOIN (
	SELECT fh.financial_highlights_guid, co_fh_transaction_no, source_date,
		ROW_NUMBER() OVER(PARTITION BY fh.co_reg_no ORDER BY fh.fin_period DESC) as row_num
	FROM Bakkwa_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL fh
	JOIN (
			-- max the transaction no for the fh to throw out outdated ones or in short knockout duplicates
			SELECT co_reg_no, fin_period, MAX(co_fh_transaction_no) as max_trans
			FROM Bakkwa_FE.dbo.FINANCIAL_HIGHLIGHTS_ALL
			GROUP BY co_reg_no, fin_period
		) m on fh.co_reg_no = m.co_reg_no AND m.fin_period = fh.fin_period and m.max_trans = fh.co_fh_transaction_no
) l on fha.financial_highlights_guid = l.financial_highlights_guid
--join bakkwa_prep.dbo.working_fh prep_fh on prep_fh.co_reg_no = fha.co_reg_no
print CAST(@@ROWCOUNT as nvarchar(10)) + ' FH_ALL row_num assigned'
GO
