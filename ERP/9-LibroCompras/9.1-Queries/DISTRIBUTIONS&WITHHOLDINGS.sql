--Distribuciones y Retenciones:
SELECT 	
		--Campos de Union en Cloud:
        --Muestro estas lineas para asociarlo con las lineas de la factura (INVOICE_LINES.sql) en Cloud:
        AID.invoice_id                      AS Invoice_ID_3,
       -- AID.invoice_line_number             AS Invoice_Line_Number_2, 
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        AID.cancellation_flag               AS Cancel_Flag_AID, --Cancel flag para ver en el where. 
        ZWL.CANCEL_FLAG                     AS Cancel_Flag_ZWL, --Cancel flag para ver en el where. 
        
        --ZWL.TAX_DATE						AS Fecha_Trans2,	--Misma fecha que la de INVPOICES.sql (AI.invoice_date).
        
        nvl(ZWL.UNIT_PRICE,0) 				AS UNIT_PRICE,		--Precio unitario de una LINEA de transacción. En este caso es igual a los de abajo, pero 
																--debería haber un campo "cantidad" que multiplique esto y me dé el LINE_AMT de abajo. 
		nvl(ZWL.LINE_AMT,0) 				AS LINE_AMT,		--CAMPO BASE DE CALCULO. 
                                                                --Es el Monto de la linea. Es igual porque hay 1 sola linea, pero si hubieran más sería distinto
																--Y habría que hacer una suma de estas lineas para obtener el AI.invoice_amount.
																--Pero realmente son varias lineas de retenciones. 
																--Esta es la suma de la factura con TODOS los impuestos asociados a la misma YA restados
																--(con todas sus transacciones y a su vez todas las lineas de las transacciones) 
        
        
		ZWL.TRX_NUMBER						AS TRX_NUMBER,		--Numero de transacción / factura. 
		ZWL.TRX_LINE_NUMBER					AS TRX_LINE_NUMBER,	--Numero de cada linea (correspondiente a una transacción / factura). NO hay diferencia con TRX_LINE_ID (en AR SI hay diferencia, aca en AP NO). 
		ZWL.TRX_LINE_ID                     AS TRX_LINE_ID,     --Numero de cada linea (correspondiente a una transacción / factura). NO hay diferencia con TRX_LINE_NUMBER (en AR SI hay diferencia, aca en AP NO). 
        
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
		
        (select --'Valor ' || ZWL2.TAX_TYPE_CODE || ' retido: ' || NVL((ZWL2.TAX_AMT)*-1,0)
                'Valor ' || decode(  ZWL2.TAX_TYPE_CODE,
                                    'ORA_ISS',    'ISS',
                                    'AWT',        'INSS',
                                    'ORA_IRRF',   'IRRF'
                                 )
                ||' retido: ' 
                || NVL((ZWL2.TAX_AMT)*-1,0)

        --HACER DECODE PARA LOS 3 TIPOS DE CODIGO. 
        from    ZX_WITHHOLDING_LINES   ZWL2
        where   ZWL2.TAX_TYPE_CODE IN ('ORA_ISS', 'AWT', 'ORA_IRRF') --AWT es el INSS. No hay registros con este campo pero es porque no está configurado (dijo Omar).
                
                --Joins:
                AND AID.DETAIL_TAX_LINE_ID 			= ZWL2.TAX_LINE_ID(+) 		
                AND AID.SUMMARY_TAX_LINE_ID         = ZWL2.SUMMARY_TAX_LINE_ID (+) 
                AND AID.AWT_TAX_RATE_ID             = ZWL2.TAX_RATE_ID (+) 
        )                                   AS Observaciones

FROM    AP_INVOICE_DISTRIBUTIONS_ALL 		AID,		--Claudio: Se guardan las cuentas contables de las lineas de transacciones
														--Ademas, si una linea tiene un impuesto compuesto (osea varios impuestos), 
														--en las distribuciones te ponen el importe de cada impuesto.
        ZX_WITHHOLDING_LINES 				ZWL		    --Witholding: RETENCIONES. 
        
WHERE   --Joins:
        --Joineamos distribuciones a la tabla de retenciones: 
        AID.DETAIL_TAX_LINE_ID 				= ZWL.TAX_LINE_ID(+) 			--El + es para que me traiga tambien si NO hay retenciones aplicadas (TAX RATE pueden ser 0). 
																			--El + me permite que ese lado (campo ZWL.TAX_LINE_ID) pueda ser NULO. Si es null igual me trae los datos. 
        --NO hacen falta estos (Claudio), con la de arriba ya esta:
        --AND AID.SUMMARY_TAX_LINE_ID     = ZWL.SUMMARY_TAX_LINE_ID (+) 
        --AND AID.AWT_TAX_RATE_ID         = ZWL.TAX_RATE_ID (+) 
        
        --Otras condiciones que saque de la query principal que ya estaba hecha (de Q_AP_INVOICES.sql):
        AND nvl(AID.reversal_flag,'N')      != 'Y'
		AND AID.posted_flag                 = 'Y'  --Si esta posteado significa que fue contabilizado (fue mandado a GL).. este filtro al final NO lo usamos. 
        --AND AID.cancellation_flag           = 'N' --Este NO, hay que filtrar por el de abajo. 
        AND ZWL.CANCEL_FLAG                 = 'N' --Para que no nos tire lineas con CANCEL_FLAG vacios (osea que son lineas canceladas). 
        
        AND AID.invoice_id                 = :INVOICE_ID_2
        --AND AID.invoice_line_number        = :INVOICE_LINE_NUMBER_1 
        
        --AND ( AID.invoice_line_number      = :INVOICE_LINE_NUMBER_1 
         --     OR AID.invoice_line_number   IS NULL                          --Este OR es porque tenemos retenciones que son propias del proveedor y NO dependen de las lineas (Claudin)
        --    )
        
        --Al final "joineamos" con el campo ZWL.TRX_LINE_ID enves del AID.invoice_line_number:
        AND (ZWL.TRX_LINE_ID     = :INVOICE_LINE_NUMBER_1 
             OR AID.invoice_line_number   IS NULL                          --Este OR es porque tenemos retenciones que son propias del proveedor y NO dependen de las lineas (Claudin)
            )
        --ZWL.TAX_LINE_NUMBER             = :INVOICE_LINE_NUMBER_1 
        
        --Parametros:
                --TAMBIEN HAY QUE FILTRAR POR LO DE LA FECHA O ESO YA ESTARÍA AL FILTRAR EN INVOICES.sql!? 

ORDER BY	AID.INVOICE_ID asc,
            ZWL.TRX_NUMBER asc,
			ZWL.TAX_LINE_NUMBER asc