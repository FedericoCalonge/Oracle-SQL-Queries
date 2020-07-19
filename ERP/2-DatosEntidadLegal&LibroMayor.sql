SELECT xlep.name Legal_entity_name
     , REGEXP_REPLACE(xlep.legal_entity_identifier,'[^0-9]') legal_entity_identifier
     , xlep.legal_entity_id
     , xhp.party_number Legal_Entity_location_code
     , xreg.town_or_city Legal_Entity_city
     ,    xhp.address1
       || DECODE (xhp.address2, NULL, NULL, ' ' || xhp.address2)
       || DECODE (xhp.address3, NULL, NULL, ' ' || xhp.address3)
       || DECODE (xhp.address4, NULL, NULL, ' ' || xhp.address4)
          Legal_Entity_address
     , xhp.country Legal_Entity_country
     , xhp.postal_code Legal_Entity_postal_code
     , xhp.province Legal_Entity_province
     , gl.ledger_id
     , gl.name ledger_name
     , gl.short_name ledger_short_name
     , gl.description ledger_description
     , gl.currency_code currency_code
     , fcv.name entity_currency_name
     , (SELECT name
        FROM   hr_operating_units
        WHERE  organization_id = :p_org_id) org_name --Nombre del BU! NO de la Entidad Legal.
FROM   gl_ledgers gl
     , gl_ledger_configurations cfg
     , gl_ledger_config_details cfgdet
     , xle_entity_profiles xlep
     , xle_registrations_v xreg
     , hz_parties xhp
     , fnd_currencies_vl fcv
WHERE  gl.ledger_category_code = 'PRIMARY'
AND    xlep.legal_entity_id = :p_legal_entity_id
AND    NVL (xlep.effective_to, SYSDATE) >= SYSDATE
AND    gl.configuration_id = cfg.configuration_id
AND    cfgdet.configuration_id(+) = cfg.configuration_id
AND    cfgdet.object_type_code(+) = 'LEGAL_ENTITY'
AND    cfgdet.object_id = xlep.legal_entity_id
AND    xreg.identifying = 'Y'
AND    xhp.party_id = xlep.party_id
AND    gl.currency_code = fcv.currency_code
AND    xreg.legal_entity_id = xlep.legal_entity_id