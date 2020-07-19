--Union entre transacciones y remitos:
--(Deben tener la misma cantidad de campos para usar el union):

--Formato a seguir:
--SELECT Campo1, Campo2 FROM Tabla1
-- SELECT Campo1, Campo2 FROM Tabla2

----Remitos (G_WSH_NEW_DELIVERIES):
(
select  distinct WND.waybill        AS trx_number,  --R-0007-00000001  /  CCAF006000022
        WND.ULTIMATE_DROPOFF_DATE   AS trx_date,
        null                        AS type,        --Si el campo fuera numerico enves de null se tendría que poner: to_number(null)
        WDD.SHIP_TO_PARTY_ID        AS party_id,    --De la tabla WDD (NO de la WND). 
        HZP.party_name              AS party_name
from    WSH_NEW_DELIVERIES         WND,
        INV_ORG_PARAMETERS         IOP,
        HZ_PARTIES                 HZP,
        WSH_DELIVERY_ASSIGNMENTS   WDA,
        WSH_DELIVERY_DETAILS       WDD
where   WND.ORGANIZATION_ID        = IOP.ORGANIZATION_ID
        AND IOP.LEGAL_ENTITY_ID    = :P_LEGAL_ENTITY_ID
        
        --Para llegar al SHIP_TO_PARTY_ID:
        AND WND.DELIVERY_ID           = WDA.DELIVERY_ID
        AND WDA.DELIVERY_DETAIL_ID    = WDD.DELIVERY_DETAIL_ID
        AND WDD.SHIP_TO_PARTY_ID      = HZP.PARTY_ID
        
        AND WND.waybill            like 'R-%'                   --Ya que hay remitos de tipo "CCAF006000022", solo hay que traer los de tipo "R-0007-00000001"
        AND WND.waybill  IN ( SELECT MAX(WND.waybill)           --Obtenemos el remito con el maximo numero (como hicimos con la transaccion). 
                            FROM    WSH_NEW_DELIVERIES              WND, 
                                    INV_ORG_PARAMETERS              IOP
                            WHERE   WND.ORGANIZATION_ID             = IOP.ORGANIZATION_ID
                                    AND IOP.LEGAL_ENTITY_ID         = :P_LEGAL_ENTITY_ID
                                    AND WND.waybill                 like 'R-%' 
                                    --AND substr(WND.waybill,3,5)     =:BRANCH                --Ejemplo: 0007-
                                    AND regexp_replace(substr(WND.waybill,3,5)             -- reg_number_format
                                            ,'[^[:alnum:]]*'       
                                            ,''                         ) 
                                                                    =:BRANCH                --Ejemplo: 0007 (este es el que queremos, sin el -)
                                    AND substr(WND.waybill,1,1)     =:LETTER                --Ejemplo: R
                                    AND WND.ULTIMATE_DROPOFF_DATE   <= :P_TRX_DATE
                              )
)
 
UNION ALL

(
--Transacciones (G_CUSTOMER_TRX):
SELECT  rct.trx_number               AS trx_number,
        --rct.attribute1,
        rct.trx_date                 AS trx_date,
        rctt.type                    AS type,
        --rbs.name,
        rac_bill_party.party_id      AS party_id,
        rac_bill_party.party_name    AS party_name

FROM   ra_customer_trx_all          rct
     , ra_batch_sources_all         rbs
     , ra_cust_trx_types_all        rctt
     , hz_cust_accounts             rac_bill
     , hz_parties                   rac_bill_party     
WHERE rct.batch_source_seq_id = rbs.batch_source_seq_id
AND   rct.cust_trx_type_seq_id = rctt.cust_trx_type_seq_id
AND   rct.bill_to_customer_id = rac_bill.cust_account_id
AND   rac_bill.party_id = rac_bill_party.party_id
AND   rct.legal_entity_id = :p_legal_entity_id

AND   rct.trx_number IN (   SELECT MAX(rct.trx_number)
                            FROM   ra_customer_trx_all          rct
                                , ra_batch_sources_all         rbs
                                , ra_cust_trx_types_all        rctt
                                , jg_doc_seq_derivations_all_f jgd
                            WHERE   rct.batch_source_seq_id = rbs.batch_source_seq_id
                                    AND   rct.cust_trx_type_seq_id = rctt.cust_trx_type_seq_id
                                    AND   rct.legal_entity_id = :p_legal_entity_id
                                    AND   rctt.type = :CLASS
                                    --AND   rctt.name = :TRX_TYPE
                                    --AND   substr(rct.trx_number,3,5)=:BRANCH
                                    AND regexp_replace(substr(rct.trx_number,3,5)             -- reg_number_format
                                            ,'[^[:alnum:]]*'       
                                            ,''                         ) 
                                                                     =:BRANCH
                                    AND   substr(rct.trx_number,1,1) =:LETTER
                                    and   rct.trx_date <= :P_TRX_DATE
                                    --and rct.trx_date >= :P_FECHA_DESDE
                                    AND (rct.attribute1 is null or rct.attribute1 ='N')  --Solo mostramos los que tienen este campo vacio o 'N'  
                        )
 )
 
  /*AND EXISTS (SELECT 'Line Tax exists'
                FROM ra_customer_trx_lines_all rctlt4
			   WHERE rct.customer_trx_id = rctlt4.customer_trx_id
			     AND rctlt4.line_type = 'TAX')*/