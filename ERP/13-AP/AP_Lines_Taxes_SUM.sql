--Otra forma:
select  --Campo a Joinear en Cloud --> (Ver abajo en el Where con union de grupo con AP_Invoice_Header).
        --ZXL_VAT.TRX_ID   --Para hacer el group by. 
        
        SUM(nvl(ZXL_VAT.tax_amt,0))        AS SUM_ZXL_VAT,
        SUM(nvl(ZXL_IIBB.tax_amt,0))       AS SUM_ZXL_IIBB,
        SUM(nvl(ZXL_AWT.tax_amt,0))        AS SUM_ZXL_AWT
        
from    AP_INVOICES_ALL     AIA,   
        ZX_LINES 			ZXL_VAT,  --ZX_LINES: Tabla de impuestos para cada factura. 
        ZX_LINES 			ZXL_IIBB,  
        ZX_LINES 			ZXL_AWT
            
where
        ZXL_VAT.TRX_ID          = :Invoice_ID
        AND ZXL_IIBB.TRX_ID     = :Invoice_ID
        AND ZXL_AWT.TRX_ID      = :Invoice_ID 
        
        AND ZXL_VAT.TAX_TYPE_CODE   = 'VAT'
        AND ZXL_VAT.application_id  = 200 
		AND ZXL_VAT.entity_code     = 'AP_INVOICES'	
        AND nvl(ZXL_VAT.cancel_flag,'N') = 'N'
        AND nvl(ZXL_VAT.delete_flag,'N') = 'N'
                
        AND ZXL_IIBB.TAX_TYPE_CODE  = 'PER IIBB'
        AND ZXL_IIBB.application_id = 200 
		AND ZXL_IIBB.entity_code    = 'AP_INVOICES'	
        AND nvl(ZXL_IIBB.cancel_flag,'N') = 'N'
        AND nvl(ZXL_IIBB.delete_flag,'N') = 'N'
        
        AND ZXL_AWT.TAX_TYPE_CODE   = 'AWT'
        AND ZXL_AWT.application_id  = 200 
		AND ZXL_AWT.entity_code     = 'AP_INVOICES'	
        AND nvl(ZXL_AWT.cancel_flag,'N') = 'N'
        AND nvl(ZXL_AWT.delete_flag,'N') = 'N'

--group by ZXL_VAT.TRX_ID 