--Retenciones: 
select  --Campos union Cloud: Son los 2 del where (union de grupo). 
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        ZWL.CANCEL_FLAG                     AS Cancel_Flag_ZWL, --Cancel flag para ver en el where. 
        
        ZWL.TAX_DATE						AS Fecha_Trans2,	--Misma fecha que la de INVPOICES.sql (AI.invoice_date).
        
        nvl(ZWL.UNIT_PRICE,0) 				AS UNIT_PRICE,		--Precio unitario de una LINEA de transacción. En este caso es igual a los de abajo, pero 
																--debería haber un campo "cantidad" que multiplique esto y me dé el LINE_AMT de abajo. 
		nvl(ZWL.LINE_AMT,0) 				AS LINE_AMT,		--CAMPO BASE DE CALCULO. 
                                                                --Es el Monto de la linea. Es igual porque hay 1 sola linea, pero si hubieran más sería distinto
																--Y habría que hacer una suma de estas lineas para obtener el AI.invoice_amount.
																--Pero realmente son varias lineas de retenciones. 
																--Esta es la suma de la factura con TODOS los impuestos asociados a la misma YA restados
																--(con todas sus transacciones y a su vez todas las lineas de las transacciones) 
        
        
		ZWL.TRX_NUMBER						AS TRX_NUMBER,		--Numero de transacción / factura. 
        ZWL.TRX_ID                          AS Invoice_ID,      --ID de la factura. 
		ZWL.TRX_LINE_NUMBER					AS TRX_LINE_NUMBER,	--Numero de cada linea (correspondiente a una transacción / factura). NO hay diferencia con TRX_LINE_ID (en AR SI hay diferencia, aca en AP NO). 
		ZWL.TRX_LINE_ID                     AS TRX_LINE_ID,     --Numero de cada linea (correspondiente a una transacción / factura). NO hay diferencia con TRX_LINE_NUMBER (en AR SI hay diferencia, aca en AP NO). 
        ZWL.TAX_LINE_ID                     AS TAX_LINE_ID,
        
		ZWL.TAX								AS TAX,				--Nombre de impuesto. Por ej. BR_RET_IMP_PIS-0.65%
		NVL((ZWL.TAX_AMT)*-1,0) 			AS TAX_AMT,			--Monto del impuesto. CAMPO IMPOSTO RETENIDO.
																--Lo ponemos en positivo haciendo el * -1 (ya que por defecto está en negativo, por ej.: -18.53)
																--Sino el monto del impuesto tambien lo podemos sacar de: AID.AMOUNT.
		
		ZWL.TAX_LINE_NUMBER					AS TAX_LINE_NUMBER,	--Numero de linea de cada impuesto. 
        
		nvl(ZWL.TAX_RATE,0) 				AS TAX_RATE, 		--TASA/PORCENTAJE de impuesto. CAMPO "ALICUOTA". 
		
		--3 codigos distintos para usar en el campo de Observaciones: 
		ZWL.TAX_RATE_CODE					AS TAX_RATE_CODE,	--Codigo de la tasa de impuesto.
		ZWL.TAX_STATUS_CODE					AS TAX_STATUS_CODE,	--Codigo de status de la tasa de impuesto. 
		ZWL.TAX_TYPE_CODE					AS TAX_TYPE_CODE,	--Codigo de tipo de la tasa de impuesto.
		
        'Valor ' || ZWL.TAX_TYPE_CODE || ' retido: ' || NVL((ZWL.TAX_AMT)*-1,0)     AS Valor_retido,
        
        'Valor ' || decode(  ZWL.TAX_TYPE_CODE,
                             'ORA_ISS',    'ISS',
                             'AWT',        'INSS',
                             'ORA_IRRF',   'IRRF'
                             )
                ||' retido: ' 
                || NVL((ZWL.TAX_AMT)*-1,0)                                          AS Valor_retido_traducido
    
    
from        ZX_WITHHOLDING_LINES 				ZWL		    --Witholding: RETENCIONES. 

where       ZWL.TRX_ID = 300000002763345
            AND ZWL.CANCEL_FLAG                 = 'N' --Para que no nos tire lineas con CANCEL_FLAG vacios (osea que son lineas canceladas). 
            
            --Joins Cloud:
            --AND ZWL.TAX_LINE_ID(+)          = :DETAIL_TAX_LINE_ID
            --AND ZWL.TRX_LINE_ID             = :Invoice_Line_Number_2
            
            
order by    ZWL.TRX_NUMBER asc,
			ZWL.TAX_LINE_NUMBER asc