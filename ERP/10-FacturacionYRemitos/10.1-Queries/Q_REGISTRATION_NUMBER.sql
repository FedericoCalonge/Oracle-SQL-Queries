SELECT zxptp.party_id
     , zxregst.registration_number
     , zxregst.registration_type_code
     , REGEXP_REPLACE (zxregst.registration_number
                     , '([[:digit:]]{2})([[:digit:]]{8})([[:digit:]]{1})'
                     , '\1-\2-\3')
          reg_number_format
FROM   zx_registrations zxregst, zx_party_tax_profile zxptp
WHERE  zxregst.party_tax_profile_id = zxptp.party_tax_profile_id
AND    zxptp.party_type_code = 'THIRD_PARTY'
AND    zxregst.registration_number IS NOT NULL
AND    zxregst.effective_from <= TRUNC (SYSDATE)
AND    (zxregst.effective_to IS NULL
OR      zxregst.effective_to >= TRUNC (SYSDATE))
AND    ( (SUBSTR (zxregst.validation_type, 11) = 'FOREIGN'
AND       zxregst.registration_type_code = 'CUIT'
OR        (SUBSTR (zxregst.validation_type, 11) = 'DOMESTIC'
AND        NVL (zxregst.default_registration_flag, 'N') = 'Y')))