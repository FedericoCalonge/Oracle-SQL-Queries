SELECT 	
		--Campos de Union en Cloud:
        --Ver los 2 campos en el where (vienen de AP_DIST)
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        FND_FLEX_XML_PUBLISHER_APIS.Process_Kff_Combination_1( 'GL_ACCT'
                                                     , 'GL'
                                                     , 'GL#'
                                                     , GL.CHART_OF_ACCOUNTS_ID
                                                     , NULL
                                                     , GJL.CODE_COMBINATION_ID
                                                     , 'GL_ACCOUNT'
                                                     , 'N'
                                                     , 'VALUE'                          )   AS Account_2,
                                                     
         GJL.ACCOUNTED_CR,                     
         GJL.ACCOUNTED_DR
           
FROM    --Para la FUNCION de cuenta contable (Account_2):
        GL_LEDGERS                          GL,
        GL_JE_LINES                         GJL
        
WHERE  --Joins con GL_LEDGERS Y GL_JE_LINES:
        GL.LEDGER_ID                            =  :SET_OF_BOOKS_ID           --AID.SET_OF_BOOKS_ID (viene de AP_DIST)
        AND GL.LEDGER_ID                        =  GJL.LEDGER_ID
        AND GJL.CODE_COMBINATION_ID             =  :CODE_COMBINATION_ID       --GC.CODE_COMBINATION_ID (viene de AP_DIST)