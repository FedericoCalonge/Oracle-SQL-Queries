SELECT 	xlep.name COMPANY_NAME
		,xlep.legal_entity_identifier COMPANY_REGISTRATION_NUMBER
		,xlep.legal_entity_id
		,xhp.party_number COMPANY_LOCATION_CODE
		,xreg.town_or_city COMPANY_CITY
		,xhp.address1
		||decode(xhp.address2,null,null,' '||xhp.address2)
		||decode(xhp.address3,null,null,' '||xhp.address3)
		||decode(xhp.address4,null,null,' '||xhp.address4) COMPANY_ADDRESS
		,gl.ledger_id
		,gl.name                  ledger_name
		,gl.short_name            ledger_short_name
		,gl.description           ledger_description
		,gl.currency_code         currency_code
		,fcv.name                 entity_currency_name
		,(	SELECT 	zrca.reporting_code_char_value || ' - ' || zrcv.reporting_code_name
			FROM 	zx_reporting_types_vl zrtv
					,zx_report_codes_assoc zrca
					,zx_reporting_codes_vl zrcv
					,zx_party_tax_profile  zptp
		  WHERE 	zrtv.reporting_type_code       		= 'LACLS_CL_ACTIVITY_CODE'
					AND zrtv.reporting_type_id         	= zrca.reporting_type_id
					AND zrtv.reporting_type_id         	= zrcv.reporting_type_id
					AND zrcv.reporting_code_id        	= zrca.reporting_code_id
					AND zrca.entity_id                 	= zptp.party_tax_profile_id
					AND zrca.entity_code 				= 'ZX_PARTY_TAX_PROFILE'
					AND zptp.party_id                  	= xlep.party_id
					AND trunc(sysdate) between zrtv.effective_from and nvl(zrtv.effective_to, trunc(sysdate))
					AND trunc(sysdate) between zrcv.effective_from and nvl(zrcv.effective_to, trunc(sysdate ) ) ) XEP_SERVICE_TYPE_CODE
					
FROM 	gl_ledgers gl
		,gl_ledger_configurations cfg
		,gl_ledger_config_details cfgdet
		,xle_entity_profiles xlep
		,xle_registrations_v xreg
		,hz_parties xhp
		,fnd_currencies_vl fcv
		
WHERE 	gl.ledger_category_code='PRIMARY'
		AND NVL(xlep.effective_to, SYSDATE) >= SYSDATE
		AND gl.configuration_id=cfg.configuration_id
		AND cfgDet.configuration_id (+) = cfg.configuration_id
		AND cfgDet.object_type_code (+) = 'LEGAL_ENTITY'
		AND cfgDet.object_id = xlep.legal_entity_id
		AND xreg.identifying = 'Y'
		AND xhp.party_id = xlep.party_id
		AND gl.currency_code = fcv.currency_code
		AND xreg.legal_entity_id = xlep.legal_entity_id
		AND gl.ledger_id =:P_LEDGER_ID