SELECT
		SUM(NVL(gjl.accounted_dr,0)) TOT_SUM_ACC_DR
		,SUM(NVL(gjl.accounted_cr,0)) TOT_SUM_ACC_CR
FROM 
		gl_period_statuses gps
		,gl_je_categories gjc
		,gl_je_sources gjs
		,gl_code_combinations gcc
		,gl_je_batches gjb
		,gl_je_headers gjh
		,gl_je_lines   gjl
WHERE --gjh.period_name = nvl(:p_period_name, gjh.period_name)
		gjl.effective_date between nvl(:P_START_DATE,gjl.effective_date) and nvl(:P_END_DATE,gjl.effective_date)
		AND gjb.je_batch_id = gjh.je_batch_id 
		AND gjh.je_header_id = gjl.je_header_id 
		AND gjh.je_source = gjs.je_source_name
		AND gjb.actual_flag = 'A' 
		AND gjh.ledger_id = :p_ledger_id 
		AND gjl.code_combination_id = gcc.code_combination_id 
		AND gps.period_name = gjh.period_name 
		AND gps.ledger_id = gjh.ledger_id
		AND gps.application_id = 101
		AND gjc.je_category_name = gjh.je_category
		AND nvl(gjh.currency_code,'xxx') != 'STAT'
		AND gjb.status = 'P'