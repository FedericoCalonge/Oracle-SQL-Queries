--DS para traerme el nombre de la moneda, entidad legal y para pasar el Start_Date y End_Date a la otra query:
Select 

(
    select      FCVL.DESCRIPTION
    from        FND_CURRENCIES_VL  		FCVL
    where       FCVL.CURRENCY_CODE = :P_CURRENCY_CODE
)                                                       currency_name,

(
    select      name
    from        xle_entity_profiles xlep
    where       xlep.legal_entity_id = :P_LEGAL_ENTITY_ID 
)                                                       legal_entity_name,

(
    SELECT 	GLP2.start_Date     --Lo que usamos en la queery.
    FROM 	GL_PERIODS                GLP2                              --ALIAS DISTIN
    WHERE 	GLP2.period_name = :P_ACC_PERIOD 
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
) Start_Date,

(
    SELECT 	GLP2.end_Date             --Lo que usamos en la queery.
    FROM 	GL_PERIODS                GLP2                              --ALIAS DISTIN
    WHERE 	GLP2.period_name = :P_ACC_PERIOD_TO 			
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
) End_Date

from dual