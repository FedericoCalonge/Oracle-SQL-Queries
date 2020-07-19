--Lines: aca nos devuelve la sumatoria de la factura correspondiente a las 2 lineas. 

select  --Para joinear en Cloud con AR_Invoice_Header:
        RCTA.CUSTOMER_TRX_ID	  	                        AS Customer_ID_2,
        -----------------------------------------------------------------------------------------------------------------------------------------------        
        
		SUM(RCTLA.EXTENDED_AMOUNT)                  		AS Lines, 		        --El monto de transaccion de cada linea. 			Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).      85000
		SUM(ZXL.TAX_AMT)                                 	AS Tax,	                --Monto impuestos de cada linea.  					Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).      14175
		(SUM(RCTLA.EXTENDED_AMOUNT) + SUM(ZXL.TAX_AMT))  	AS Transaction_Total	--Monto impuestos + transaccion de cada linea. 		Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).      99175

from    RA_CUSTOMER_TRX_ALL 			RCTA, 
        ZX_LINES						ZXL, 		--Líneas de CADA factura. Acá tenemos también los impuestos aplicados a CADA línea.
        RA_CUSTOMER_TRX_LINES_ALL		RCTLA 		--Líneas.

where 	RCTA.CUSTOMER_TRX_ID 	                = RCTLA.CUSTOMER_TRX_ID 
		--Con ZX_LINES:
		AND RCTLA.CUSTOMER_TRX_ID      			= ZXL.TRX_ID
		AND RCTLA.CUSTOMER_TRX_LINE_ID     		= ZXL.TRX_LINE_ID
		
group by RCTA.CUSTOMER_TRX_ID