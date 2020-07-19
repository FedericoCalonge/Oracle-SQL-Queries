--Parametro Tipo de comprobante - DOCUMENT_TYPE:
SELECT Meaning
     , tag 
FROM   fnd_lookup_values_vl
WHERE  lookup_type = 'LACLS_AR_TRX_DOCUMENT_TYPE'
AND    enabled_flag = 'Y'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active,SYSDATE))
                      AND     TRUNC(NVL(end_date_active,SYSDATE)) 
ORDER BY Meaning