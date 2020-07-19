--Taxes de la factura (el ejemplo que hicimos no tenia igual): 

--VER SI HACER UN DM DE SUM PARA LOS 3 Y ACA SOLO MOSTRAR LOS TAXES. 

SELECT --SUM(ZXL.TAX_AMT)			 --Pueden haber varios TAX_AMT por factura... por eso hacemos el SUM.
        ZXL.TRX_ID                      AS Invoice_ID_3
        ZXL.TAX_TYPE_CODE,
        ZXL.TAX_AMT,
        ZXL.TAX_AMT_TAX_CURR
        
from    ZX_LINES 			ZXL

where   ZXL.TRX_ID              = :Invoice_ID_2             
        AND ZXL.trx_line_id     = :Invoice_Line_Number_1              
        AND ZXL.entity_code     ='AP_INVOICES' 
        AND nvl(ZXL.cancel_flag,'N') = 'N'
        AND nvl(ZXL.delete_flag,'N') = 'N'
        AND ZXL.application_id  = 200 