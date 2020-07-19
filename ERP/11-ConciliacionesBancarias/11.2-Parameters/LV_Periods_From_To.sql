SELECT 	GLP2.PERIOD_NAME   --Lo que mostramos y usamos en la query. 
        --Antes usabamos este:  GLP2.start_Date . Pero lo tuvimos que sacar porque nos tiraba un error. 
FROM 	GL_PERIODS                GLP2                              --ALIAS DISTINTO al que usamos abajo (GL)
WHERE 	TRUNC(GLP2.Start_Date)         	<= TRUNC(SYSDATE)			
		AND GLP2.ADJUSTMENT_PERIOD_FLAG     	= 'N'
        --Exist para filtrar el libro de la entidad que te pasan por parametro
        AND EXISTS   --Retorna true si se devuelve un registro en la subquery:
                    (
                        select  GL.Name
                        from    GL_LEDGERS                           GL,
                                GL_PERIODS                           GLP,
                        		Gl_Ledger_Configurations             CFG,
                                Gl_Ledger_Config_Details             CFGDET,
                                Xle_Entity_Profiles                  XLEP,
                                Xle_Registrations_V                  XREG,
                                Fnd_Currencies_Vl                    FCV
                        where   GL.ledger_category_code          	 IN ('PRIMARY','SECONDARY')
                                AND GLP.PERIOD_SET_NAME            	 = GL.PERIOD_SET_NAME           --Join GLP con GL.
                                AND XLEP.legal_entity_id             =  :P_LEGAL_ENTITY_ID
                                AND NVL(XLEP.effective_to, SYSDATE)  >= SYSDATE
                                AND GL.configuration_id              = CFG.configuration_id
                                AND CFGDET.configuration_id      	(+) = CFG.configuration_id
                                AND CFGDET.object_type_code      	(+) = 'LEGAL_ENTITY'
                                AND CFGDET.object_id                 = XLEP.legal_entity_id         --Aca nos aseguramos que el ledger esta asociada a la entidad legal.
                                AND XREG.identifying                 = 'Y'
                                AND GL.currency_code                 = FCV.currency_code
                                AND XREG.legal_entity_id             = XLEP.legal_entity_id
                    )
ORDER BY 	GLP2.PERIOD_YEAR                DESC,							
			GLP2.PERIOD_NUM                 DESC
            
            