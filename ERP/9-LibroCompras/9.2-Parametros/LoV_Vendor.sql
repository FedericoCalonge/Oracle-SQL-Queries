select distinct psv.vendor_name --proveedores
      ,psv.vendor_id
  from poz_supplier_sites_all_m pssa
      ,poz_suppliers_v psv
  where psv.vendor_id   = pssa.vendor_id
  and   pssa.prc_bu_id  = :p_org_id
  order by 1