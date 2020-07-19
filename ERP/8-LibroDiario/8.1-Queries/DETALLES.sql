SELECT
		gjh.name   je_source_f
		,TO_CHAR(gjh.default_effective_date,'DD/MM/YYYY') je_effective_date_f
		,TO_CHAR(gjh.default_effective_date,'DD/MM') fecha
		,gcc.segment2      account_cc
		,SUM(NVL(gjl.accounted_dr,0)) SUM_DET_ACC_DR
		,SUM(NVL(gjl.accounted_cr,0)) SUM_DET_ACC_CR
		,ACCOUNT_DESC.description
		,decode(sum(gjl.accounted_cr) , null , 'D' , 'C') ES_CRED      
		,gjh.POSTING_ACCT_SEQ_VALUE num_asiento            
FROM 
		gl_period_statuses gps
		,gl_je_categories_tl gjc
		,gl_je_sources_tl gjs
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
				
		,(select 		fvvl.description, fvv.FLEX_VALUE 
				from 	FND_FLEX_VALUE_SETS fvs,  FND_FLEX_VALUES fvv, FND_FLEX_VALUES_TL fvvl
				where 	FLEX_VALUE_SET_NAME = 'GB_CATEGORIES'
						and fvs.FLEX_VALUE_SET_ID = fvv.FLEX_VALUE_SET_ID
						and fvv.FLEX_VALUE_ID = fvvl.FLEX_VALUE_ID
						and fvvl.language = 'E'
		) vscat
						
		,(select 		fvtl.description
						,fv.flex_value 
                from
						fnd_flex_value_sets fvs
						,fnd_flex_values     fv
						,fnd_flex_values_tl  fvtl
				where
						 1                   = 1
						 AND fv.enabled_flag = 'Y'
						 AND SYSDATE BETWEEN NVL (fv.start_date_active, SYSDATE) AND NVL (fv.end_date_active, SYSDATE + 1)
						 AND fvs.flex_value_set_id   = fv.flex_value_set_id
						 AND fv.flex_value_id        = fvtl.flex_value_id
						-- AND fvs.flex_value_set_name = 'ACCOUNT GB_CORP_PL'
						 AND fvtl.LANGUAGE           = USERENV ('LANG')	 
        ) ACCOUNT_DESC
		
WHERE 	--gjh.period_name = nvl(:p_period_name, gjh.period_name)
		gjh.default_effective_date between :P_START_DATE and :P_END_DATE
		AND gjb.je_batch_id = gjh.je_batch_id 
		AND gjh.je_header_id = gjl.je_header_id 
		AND gjb.actual_flag = 'A' 
		AND gjh.ledger_id = :p_ledger_id 
		AND gjl.code_combination_id = gcc.code_combination_id 
		AND gps.period_name = gjh.period_name 
		AND gps.ledger_id = gjh.ledger_id
		AND gps.application_id = 101
		AND gjc.je_category_name = gjh.je_category
		AND ACCOUNT_DESC.flex_value           = gcc.segment2
		AND vscat.FLEX_VALUE (+) = gjc.user_je_category_name
		AND nvl(gjh.currency_code,'xxx') != 'STAT'
		AND gjb.status = 'P'
		AND gjs.LANGUAGE = 'E'
		AND gjc.LANGUAGE = 'E'
		AND gjh.je_source = gjs.je_source_name
		AND vsl.FLEX_VALUE (+) = gjs.user_je_source_name
group by
		vsl.description
		, gjs.user_je_source_name  
		,TO_CHAR(gjh.default_effective_date,'DD/MM/YYYY')
		,TO_CHAR(gjh.default_effective_date,'DD/MM')
		,gjh.name
		,ACCOUNT_DESC.description
		,gcc.segment2
		--,gcc.code_combination_id
		,gjh.POSTING_ACCT_SEQ_VALUE
ORDER BY 
		gjs.user_je_source_name