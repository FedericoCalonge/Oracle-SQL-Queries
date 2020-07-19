-- 3-Parametro Ledger: 

SELECT 	GL.Name,
		GL.Ledger_Id
		
FROM  	Gl_Ledgers                           GL,
		Gl_Ledger_Configurations             CFG,
		Gl_Ledger_Config_Details             CFGDET, 
		Xle_Entity_Profiles                  XLEP,
		Xle_Registrations_V                  XREG,
		Hz_Parties                           XHP,
		Fnd_Currencies_Vl                    FCV

WHERE 	GL.ledger_category_code          	IN ('PRIMARY','SECONDARY')
		AND XLEP.legal_entity_id             =  :P_ENTIDAD_LEGAL_ID
		AND NVL(XLEP.effective_to, SYSDATE)  >= SYSDATE   
		AND GL.configuration_id              = CFG.configuration_id
		AND CFGDET.configuration_id      	(+) = CFG.configuration_id
		AND CFGDET.object_type_code      	(+) = 'LEGAL_ENTITY'
		AND CFGDET.object_id                 = XLEP.legal_entity_id
		AND XREG.identifying                 = 'Y'
		AND XHP.party_id                     = XLEP.party_id
		AND GL.currency_code                 = FCV.currency_code   
		AND XREG.legal_entity_id             = XLEP.legal_entity_id
 ORDER BY GL.name