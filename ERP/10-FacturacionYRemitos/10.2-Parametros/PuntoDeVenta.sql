--Parametro Punto de Venta - BRANCH:
--Tiraba un error y se soluciono poniendo los parametros en los 2 select que involucran el UNION. 

--UNION entre remitos (Q_WSH_NEW_DELIVERIES) y Puntos de venta/Branch:
                         
--Branch:                             
(
SELECT Distinct regexp_replace(substr(rct.trx_number,3,5)       -- reg_number_format
                             ,'[^[:alnum:]]*'       
                             ,''                         )      AS Branch
FROM    ra_customer_trx_all rct
WHERE   rct.LEGAL_ENTITY_ID =  :P_LEGAL_ENTITY_ID
        AND (rct.attribute1 is null or rct.attribute1 ='N')
)

UNION ALL

(
--Remitos:
select  Distinct regexp_replace(substr(WND.waybill ,3,4)       -- reg_number_format
                             ,'[^[:alnum:]]*'       
                             ,''                         )          AS Branch
from    WSH_NEW_DELIVERIES   WND,
        INV_ORG_PARAMETERS   IOP
where   WND.ORGANIZATION_ID        = IOP.ORGANIZATION_ID
        AND IOP.LEGAL_ENTITY_ID    = :P_LEGAL_ENTITY_ID
        AND WND.waybill             like 'R-%'                  --Ya que hay remitos de tipo "CCAF006000022", solo hay que traer los de tipo "R-0007-00000001"
)

ORDER BY 1
