select otl.name
      ,xlll.operating_unit_id org_id
  from hr_all_organization_units      o
      ,hr_all_organization_units_tl   otl
      ,hr_organization_information    o2
      ,xle_le_ou_ledger_v             xlll
  where xlll.legal_entity_id||''   = o2.org_information2
  and   xlll.ledger_id||''         = o2.org_information3
  and   xlll.operating_unit_id     = o2.organization_id
  and   o.organization_id          = o2.organization_id 
  and   o2.org_information_context = 'FUN_BUSINESS_UNIT' 
  and   o.organization_id          = otl.organization_id 
  and   otl.language               = userenv('LANG')
  and   xlll.legal_entity_id       = :p_legal_entity_id
  order by otl.name