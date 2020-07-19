SELECT xep.name                 legal_entity_name
      , xep.legal_entity_id      legal_entity_id     
   FROM gl_ledgers                      gl
      , xle_entity_profiles         xep
      , xle_registrations             xr
      , xle_jurisdictions_vl       xjv
      , gl_ledger_config_details   glcd
      , gl_ledger_relationships    glr
      , fnd_currencies_vl          fcv
      , hz_geographies             hg
  WHERE xr.source_table         = 'XLE_ENTITY_PROFILES'
    AND xr.identifying_flag     = 'Y' 
    AND gl.ledger_category_code = 'PRIMARY'   
    AND glcd.object_type_code   = 'LEGAL_ENTITY'
    AND NVL(xep.effective_to, SYSDATE) >= SYSDATE   
    AND xep.geography_id        = hg.geography_id
    AND hg.geography_type       = 'COUNTRY'
    AND xep.legal_entity_id     = xr.source_id
    AND xr.jurisdiction_id      = xjv.jurisdiction_id
    AND glcd.object_id          = xep.legal_entity_id
    AND glr.primary_ledger_id   = gl.ledger_id
    AND gl.ledger_category_code = glr.target_ledger_category_code
    AND glcd.configuration_id   = gl.configuration_id
    AND gl.currency_code        = fcv.currency_code   
   ORDER BY xep.name