Select 
	 --numero_asiento,
	data.*
from
(
	SELECT
			gjh.NAME   je_source
			,TO_CHAR(gjh.default_effective_date,'DD/MM/YYYY') je_effective_date
			,to_char(gjh.default_effective_date,'Month','NLS_DATE_LANGUAGE = SPANISH') Mes
			,SUM(NVL(gjl.accounted_dr,0)) SUM_SRC_ACC_DR
			,SUM(NVL(gjl.accounted_cr,0)) SUM_SRC_ACC_CR
			, gjh.POSTING_ACCT_SEQ_VALUE numero_asiento
	FROM 
		   gl_period_statuses gps
		  ,GL_JE_CATEGORIES_TL gjc
		  ,GL_JE_SOURCES_TL gjs
		  ,gl_code_combinations gcc
		  ,gl_je_batches gjb
		  ,gl_je_headers gjh
		  ,gl_je_lines   gjl
		  ,(select fvvl.description, fvv.FLEX_VALUE 
			from FND_FLEX_VALUE_SETS fvs,  FND_FLEX_VALUES fvv, FND_FLEX_VALUES_TL fvvl
			where FLEX_VALUE_SET_NAME = 'GB_SOURCES'
			and fvs.FLEX_VALUE_SET_ID = fvv.FLEX_VALUE_SET_ID
			and fvv.FLEX_VALUE_ID = fvvl.FLEX_VALUE_ID
			and fvvl.language = 'E'
			) vsl
		  ,(select fvvl.description, fvv.FLEX_VALUE 
			from FND_FLEX_VALUE_SETS fvs,  FND_FLEX_VALUES fvv, FND_FLEX_VALUES_TL fvvl
			where FLEX_VALUE_SET_NAME = 'GB_CATEGORIES'
			and fvs.FLEX_VALUE_SET_ID = fvv.FLEX_VALUE_SET_ID
			and fvv.FLEX_VALUE_ID = fvvl.FLEX_VALUE_ID
			and fvvl.language = 'E'
			) vscat
			
	WHERE 	--gjh.period_name = nvl(:p_period_name, gjh.period_name)
			gjh.default_effective_date between :P_START_DATE and :P_END_DATE
			AND gjb.je_batch_id = gjh.je_batch_id 
			AND gjh.je_header_id = gjl.je_header_id 
			AND gjh.je_source = gjs.je_source_name
			AND vsl.FLEX_VALUE (+) = gjs.user_je_source_name
			AND gjs.LANGUAGE = 'E'
			AND gjb.actual_flag = 'A' 
			AND gjh.ledger_id = :p_ledger_id 
			AND gjl.code_combination_id = gcc.code_combination_id 
			AND gps.period_name = gjh.period_name 
			AND gps.ledger_id = gjh.ledger_id
			AND gps.application_id = 101
			AND gjc.je_category_name = gjh.je_category
			AND vscat.FLEX_VALUE (+) = gjc.user_je_category_name
			AND gjc.LANGUAGE = 'E'
			AND nvl(gjh.currency_code,'xxx') != 'STAT'
			AND gjb.status = 'P'
	group by
			vsl.description
			,gjs.user_je_source_name   
			,TO_CHAR(gjh.default_effective_date,'DD/MM/YYYY')
			,to_char(gjh.default_effective_date,'Month','NLS_DATE_LANGUAGE = SPANISH')
			, gjh.NAME
			, gjh.POSTING_ACCT_SEQ_VALUE
	ORDER BY gjs.user_je_source_name
) data
ORDER BY 2