--Impuestos:

select  --Para joinear en Cloud con AR_Lines_Taxes:
        RCTLA.TAX_LINE_ID               AS Tax_Line_ID_2,           --Con AR_Lines
        ZXL.TRX_LINE_ID                 AS TRX_LINE_ID_1,             --Con CUSTOMER_TRX_LINE_ID_1 de AR_LINES_LINES. Para identificar a qué factura está aplicado este impuesto.
        ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        ZXL.TAX_LINE_NUMBER             AS TAX_LINE_NUMBER,         --Es el numero de ID de ESTA tabla. 
        ZXL.TAX_AMT                     AS Amount,
        ZXL.TAX                         AS TAX,
        ZXL.TAX_RATE_CODE               AS TAX_Clasification
from    RA_CUSTOMER_TRX_LINES_ALL		RCTLA, 		--Líneas.   

        ZX_LINES                        ZXL         --Lines de los impuestos.         

where
		--Con ZX_LINES:
		RCTLA.TAX_LINE_ID               =ZXL.TAX_LINE_ID 
        
        
        