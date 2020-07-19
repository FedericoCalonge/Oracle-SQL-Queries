--Lines: aca vemos las 2 lineas que tiene la factura. 

select  
        --Para joinear en Cloud:
        RCTA.CUSTOMER_TRX_ID	  	                            AS Customer_ID_5,           --Con AR_Invoice_Header
        RCTLA.TAX_LINE_ID                                       AS Tax_Line_ID_1,           --Con AR_Taxes_Details
        -----------------------------------------------------------------------------------------------------------------------------------------------         
        
        RCTLA.line_type,                                        --TAX, LINE.
        RCTLA.LINE_NUMBER                                       AS Line,
        --                                                      AS Item,
        --RCTLA.DESCRIPTION                                       AS Description, --No me trae nada. 
        --                                                      AS Memo_Line,
        --UOM_CODE	                                            AS UOM, --Devuelve un... decode? . VER ESTE UOM
        RCTLA.extended_amount                                   AS Amount 
        --                                                      AS Details --(VER DESPUES)
        --                                                      AS Tax_Classification         
        --                                                      AS Transaction_Business_Cat
        
from    RA_CUSTOMER_TRX_ALL 			RCTA, 
        RA_CUSTOMER_TRX_LINES_ALL		RCTLA 		            --Líneas.
where 	
        --RCTLA.line_type = 'LINE'
        RCTLA.line_type = 'TAX'
        AND RCTA.CUSTOMER_TRX_ID 	        = RCTLA.CUSTOMER_TRX_ID     
