--Union entre puntos de venta y remitos:
--(Deben tener la misma cantidad de campos para usar el union):

--Formato a seguir:
--SELECT Campo1, Campo2 FROM Tabla1
-- SELECT Campo1, Campo2 FROM Tabla2

--Remitos (G_WSH_NEW_DELIVERIES):
(
select  distinct regexp_replace(substr(WND.waybill,3,5)             -- reg_number_format
                             ,'[^[:alnum:]]*'       
                             ,''                         )         
                                        AS Branch,
        substr(WND.waybill,1,1)         AS Letter,
        null                            AS Class,
        '091'                           AS Document_code

from    WSH_NEW_DELIVERIES   WND,
        INV_ORG_PARAMETERS   IOP
where   WND.ORGANIZATION_ID        = IOP.ORGANIZATION_ID
        AND IOP.LEGAL_ENTITY_ID    = :P_LEGAL_ENTITY_ID
        AND WND.waybill             like 'R-%'                  --Ya que hay remitos de tipo "CCAF006000022", solo hay que traer los de tipo "R-0007-00000001"
        
       AND regexp_replace(substr(WND.waybill,3,5)               -- reg_number_format
                          ,'[^[:alnum:]]*'       
                          ,''                         ) IN (:p_branch)
       AND :P_DOCUMENT_TYPE is null 
)

UNION ALL

(
--Puntos de venta (Q_SECUENCE):
SELECT  distinct  regexp_replace(substr(rct.trx_number,3,5)             -- reg_number_format
                             ,'[^[:alnum:]]*'       
                             ,''                         )     AS Branch,
        substr(rct.trx_number,1,1)                             AS Letter,
        rctt.type                                              AS Class,
        -- , jds.document_sequence_context3                    AS Trx_Type,
        flv.Lookup_code                                        AS Document_code
        
FROM    ra_customer_trx_all         rct,
        ra_cust_trx_types_all       rctt,
        fnd_lookup_values_vl        flv
        
WHERE   rct.cust_trx_type_seq_id = rctt.cust_trx_type_seq_id
        AND rct.LEGAL_ENTITY_ID =  :p_legal_entity_id
        --AND jds.context_derivation_code = 'DOCUMENT_NUMBERING'     -- Doc Assignment
        AND regexp_replace(substr(rct.trx_number,3,5)               -- reg_number_format
                             ,'[^[:alnum:]]*'       
                             ,''                         ) IN (:p_branch)
        AND rctt.type||substr(rct.trx_number,1,1) = NVL(:P_DOCUMENT_TYPE,rctt.type||substr(rct.trx_number,1,1))
        AND (rct.attribute1 is null or rct.attribute1 ='N')
        AND flv.lookup_type = 'LACLS_AR_TRX_DOCUMENT_TYPE'
        AND flv.tag = rctt.type||substr(rct.trx_number,1,1)
)
       
ORDER BY 1,2,3