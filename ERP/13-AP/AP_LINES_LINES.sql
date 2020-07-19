--Lineas de la factura:

select   --Campos de union en Cloud:
        AIL.invoice_id                      AS Invoice_ID_2,	           --Con AP_Invoice_Header y AP_DIS. Este Invoice_ID es el numero de factura. Es el ID del sistema (distinto al Invoice_Num de AP_Invoice_Header.sql)    
        AIL.LINE_NUMBER                     AS Invoice_Line_Number_1,      --Con AP_DIST (AID.INVOICE_LINE_NUMBER)  
       --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        AIL.LINE_TYPE_LOOKUP_CODE           AS LINE_TYPE_LOOKUP_CODE,       --AWT SI ES UNA RETENCION. ITEM
        ALC3.DISPLAYED_FIELD                AS LINE_TYPE,                   --Otra forma de sacar el tipo de linea.         
        
        --Hay 2 tipos de linea: ITEM y TAX (o AWT)... Item son los items y TAX impuestos aplicados a dichos items (no?). Podrìamos hacer 2 querys... una AP_LINES_ITEM y otra AP_LINES_TAXES... 
        --Y hariamos este filtro: AIL.LINE_TYPE_LOOKUP_CODE	= 'ITEM' o AIL.LINE_TYPE_LOOKUP_CODE	= 'TAX'.
        --Pero decidimos hacer 1 sola query y poner todas las lineas (sea ITEM o TAX) aca:
        
        
         --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       
        --Invoice Details - Lines - Items:  (los podemos filtrar con la condicion AIL.LINE_TYPE_LOOKUP_CODE	= 'ITEM')
        
         -- AS LINE   --Seria el Invoice_Line_Number_1 de arriba.
         AIL.AMOUNT                          AS Amount,                --VER ESTO DENUEVO, diferencia con base_amount
         AIL.DESCRIPTION                     AS DESCRIPTION,
         AIL.QUANTITY_INVOICED               AS Quantity,
         AIL.UNIT_PRICE                      AS Price,
         AIL.UNIT_MEAS_LOOKUP_CODE           AS UOM_Name,               --Ver si es este.
         
            --Ver de donde sacar estos:
            --Orden de compra:
                --AS Number,
                --AS Line,
                --AS Schedule
                
            --Receipt:
                --AS Number,
                --AS Line, 
            
            --Consumption Advice:
                --AS Number, 
                --AS Line, 
             
             --Multiperiod Accounting:    --Fefe tenia anotado que era el campo Accounting_Date... VER. 
                --AS Start Daate,
                --AS End_Date,
                --AS Accrual Account, 
                
        --AS Ship_To_Location, --Ver algun join con campo SHIP_TO_LOCATION_ID ?
         
       
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       
        --Invooice Details - Summary Tax Lines: (los podemos filtrar con la condicion AIL.LINE_TYPE_LOOKUP_CODE	= 'TAX')
        -- AS LINE   --Seria el Invoice_Line_Number_1 de arriba.
        AIL.TAX_RATE_CODE                   AS RATE_NAME, 
        AIL.TAX_RATE                        AS RATE, 
        -- AS AMOUNT --Seria el Amount de arriba. 
         AIL.DISCARDED_FLAG                 AS Canceled,                    --Para ver si esta cancelada o no. 
         --Inclusive        --Ver cual es y que es. 
         --Self-Assessed    --Ver cual es y que es. 
         --Tax_Only_Line    --Ver cual es y que es. 

        AIL.TAX_REGIME_CODE                 AS Regime,                      -- --> ZX_REGIMES_TL.TAX_REGIME_NAME
        AIL.TAX                             AS TAX_Name,                    -- -->  ZX_TAXES_TL.TAX_FULL_NAME
        AIL.TAX_JURISDICTION_CODE           AS TAX_JURISDICTION,            -- -->  ZX_JURISDICTIONS_TL.TAX_JURISDICTION_NAME
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       
       --Otros campos (VER): 
        AIL.base_amount                     AS Base_Amount_Linea,           --VER ESTO DENUEVO, diferencia con amount. 
        AIL.LAST_UPDATE_DATE                AS LINES_LAST_UPDATE_DATE,    
        AIL.LAST_UPDATED_BY                 AS LINES_LAST_UPDATED_BY,     
        AIL.CREATION_DATE                   AS LINES_CREATION_DATE,       
        AIL.CREATED_BY                      AS LINES_CREATED_BY   

from    
        AP_INVOICE_LINES_ALL				AIL,		                        --Tabla de las lineas de la factura.
        AP_LOOKUP_CODES                     ALC3
         
where   
        --AIL.LINE_TYPE_LOOKUP_CODE	= 'ITEM'  --Si queremos filtrar para que nos traiga solo las lineas 'ITEM'
        --AIL.LINE_TYPE_LOOKUP_CODE	= 'TAX'  --Si queremos filtrar para que nos traiga solo las lineas 'TAX'
        
        ALC3.lookup_type                        (+) = 'INVOICE LINE TYPE'                   --Ver si este tiene que ir (lo habia puesto fefe). 
        AND ALC3.lookup_code                    (+) = AIL.Line_Type_Lookup_Code           -- JOIN LOOKUP
        
