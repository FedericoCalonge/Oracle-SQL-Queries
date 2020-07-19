--Lines: aca vemos las 2 lineas que tiene la factura. 

select  
        --Para joinear en Cloud:
        RCTA.CUSTOMER_TRX_ID	  	                            AS Customer_ID_4,           --Con AR_Invoice_Header
        RCTLA.CUSTOMER_TRX_LINE_ID                              AS CUSTOMER_TRX_LINE_ID_1,  --Con TRX_LINE_ID_1 de AR_TAXES_DETAILS. Para identificar qué impuesto/s aplica/n a esta factura.
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
        
        RCTLA.line_type,                                        --TAX, LINE.
        RCTLA.LINE_NUMBER                                       AS Line,
        --                                                      AS Item,
        RCTLA.DESCRIPTION                                       AS Description,
        --                                                      AS Memo_Line,
        --UOM_CODE	                                            AS UOM, --Devuelve un... decode?
        RCTLA.quantity_invoiced                                 AS Quantity,
        RCTLA.unit_selling_price                                AS Unit_Price,
        RCTLA.extended_amount                                   AS Amount
        --                                                      AS Details --(VER DESPUES)
        --                                                      AS Tax_Classification          
        --                                                      AS Transaction_Business_Cat

from    RA_CUSTOMER_TRX_ALL 			RCTA, 
        RA_CUSTOMER_TRX_LINES_ALL		RCTLA 		            --Líneas.
where 	
        RCTLA.line_type = 'LINE'
        --RCTLA.line_type = 'TAX'
        AND RCTA.CUSTOMER_TRX_ID 	        = RCTLA.CUSTOMER_TRX_ID     
