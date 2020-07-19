--Lista de parametros:

--Lista Monedas:
select FCVL.DESCRIPTION,
          FCVL.CURRENCY_CODE
from FND_CURRENCIES_VL  		FCVL
order by FCVL.DESCRIPTION asc


--Lista Proveedores.
--Opcion 1 (la mejor opcion es la 2, ya que de esta opcion, en la hz_party te trae nombre de proveedores, clientes, bancos y un largo etc):
--select HZP.PARTY_NAME, HZP.PARTY_ID
--from HZ_PARTIES HZP

--Opcion 2 (Es mejor esta opcion)
SELECT distinct POZSV.vendor_name,  POZSV.vendor_id 
FROM POZ_SUPPLIERS_V 	POZSV


--Lista Entidades Legales:
--1era opcion - Esta bien pero mejor la 2da opcion:

--SELECT xlep.name legal_entity_name,
     -- xlep.legal_entity_id
--FROM xle_entity_profiles      xlep

--2da opcion - Boilerplate - Es mejor esta opcion (igualmente le sobra unas tablas, como la de fnd_currencies y la hz party):
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


--Lista BUs:
--Forma 1 (es la correcta):
SELECT BU_NAME, BU_ID
FROM FUN_ALL_BUSINESS_UNITS_V

--Forma 2 (MUY MALA PRACTICA: no podemos joinear con AP_INVOICES ALL ya que si tenemos millones de registros el distinct tiene que eliminar toooodos los duplicados, muy mala performance):
--SELECT distinct  HOU.NAME, HOU.ORGANIZATION_ID
--FROM  HR_ORGANIZATION_UNITS  HOU,
--		AP_INVOICES_ALL AIA
--WHERE  AIA.ORG_ID = HOU.ORGANIZATION_ID