--4-Parametro Entidad legal - Boilerplate - Es mejor esta opcion para sacar la Entidad Legal (igualmente le sobra unas tablas, como la de fnd_currencies y la hz party):
SELECT 	xlep.name legal_entity_name,
		xlep.legal_entity_id,
		gl.ledger_id,
		gl.name
 FROM 	gl_ledgers               gl,
		gl_ledger_configurations cfg,
		gl_ledger_config_details cfgdet,
		xle_entity_profiles      xlep,
		xle_registrations_v      xreg,
		hz_parties               hzp,
		fnd_currencies_vl        fcv
WHERE 	gl.ledger_category_code = 'PRIMARY'
		AND NVL(xlep.effective_to, SYSDATE) >= SYSDATE
		AND gl.configuration_id = cfg.configuration_id
		AND cfgDet.configuration_id(+) = cfg.configuration_id
		AND cfgDet.object_type_code(+) = 'LEGAL_ENTITY'
		AND cfgDet.object_id = xlep.legal_entity_id
		AND xreg.identifying = 'Y'
		AND hzp.party_id = xlep.party_id
		AND gl.currency_code = fcv.currency_code
		AND xreg.legal_entity_id = xlep.legal_entity_id
		order by xlep.name