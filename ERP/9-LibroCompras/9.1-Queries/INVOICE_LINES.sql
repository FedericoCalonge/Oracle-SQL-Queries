--Lineas de la factura:
select  
        --Campos de union en Cloud:
        
        --Para unirlos con las Distribuciones (DISTRIBUTIONWITHHOLDINGS.sql:                 
        --El 1er campo tambien es para unirlo con la factura (INVPOICES.sql):
        AIL.invoice_id                      AS Invoice_ID_2,	           --Este Invoice_ID es el numero de factura. Es el ID del sistema (distinto al Invoice_Num de INVOICES.sql)    
        AIL.LINE_NUMBER                     AS Invoice_Line_Number_1,       
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        AIL.LINE_TYPE_LOOKUP_CODE           AS LINE_TYPE_LOOKUP_CODE,       --AWT SI ES UNA RETENCION. ITEM 
       
        AIL.amount                          AS Amount_Linea,                --No lo uso pero para tenerlo. Es el TOTAL. Amount = Base_amount + impuestos - retenciones.
        AIL.base_amount                     AS Base_Amount_Linea,           --No lo uso pero para tenerlo. Base_amount + impuestos - retenciones = amount. 
        AIL.PRODUCT_CATEGORY                AS Cod_Recon_Ret 	            --CAMPO RETENCION - Código do Recolhimento. Está en la linea de las facturas. 
from    
        AP_INVOICE_LINES_ALL				AIL		                        --Tabla de las lineas de la factura.
        
where   
        --Filtramos para que solo nos traiga los ITEM:
        AIL.LINE_TYPE_LOOKUP_CODE	= 'ITEM'
        --TAMBIEN HAY QUE FILTRAR POR LO DE LA FECHA O ESO YA ESTARÍA AL FILTRAR EN INVOICES.sql!? 