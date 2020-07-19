SELECT 	
		--Campos de Union en Cloud:
        
        --Son los 2 del where (mediante union de grupo) + estos 2:
        AID.invoice_line_number                                     AS Invoice_Line_Number_2,       --Con AP_WITHOLDINGS (ZWL.TRX_LINE_ID) comoo padre y tambien con AP_LINES_LINES (AIL.LINE_NUMBER) como hijo. 
        AID.DETAIL_TAX_LINE_ID                                      AS DETAIL_TAX_LINE_ID,          --Con AP_WITHOLDINGS (ZWL.TAX_LINE_ID) como padre.
        
        GC.CODE_COMBINATION_ID,     --Para pasarle a AP_DIST_LINES
        AID.SET_OF_BOOKS_ID,        --Para pasarle a AP_DIST_LINES
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        AID.invoice_id                                              AS INVOICE_ID,
        nvl(AID.base_amount, AID.AMOUNT)                            AS C_DIST_AMOUNT,
        TO_CHAR(AID.ACCOUNTING_DATE,'YYYY-MM-DD')                   AS C_ACCOUNTING_DATE,           --Distribution_GL_DATE
        AID.LAST_UPDATE_DATE                                        AS DIST_LAST_UPDATE_DATE,     
        AID.LAST_UPDATED_BY                                         AS DIST_LAST_UPDATED_BY,      
        AID.CREATION_DATE                                           AS DIST_CREATION_DATE,        
        AID.CREATED_BY                                              AS DIST_CREATED_BY,            
        AID.DISTRIBUTION_LINE_NUMBER                                AS C_DIST_NUMBER,
        AID.cancellation_flag                                       AS Cancel_Flag_AID,             --Cancel flag para ver en el where. 
        
        (   SELECT      SUM(NVL(d2.base_amount, d2.amount))
            FROM        ap_invoice_distributions_all d2
            WHERE       d2.awt_related_id = AID.invoice_distribution_id
                        AND d2.line_type_lookup_code = 'AWT'
                        AND d2.invoice_id = AID.invoice_id)                      
                                                                    AS AWT,
        
        --Forma 1 para obtener la cuenta contable (directamente de GL_CODE_COMBINATIONS):   
         GC.SEGMENT1||'-'||gc.SEGMENT2||'-'||gc.SEGMENT3||'-'||gc.SEGMENT4||'-'||gc.SEGMENT5||'-'||gc.SEGMENT6||'-'||gc.SEGMENT7||'-'||gc.SEGMENT8 
                                                                    AS Account,
         
         --Forma 2 con la FUNCION:  (VER AP_DIST_LINES), funcion FND_FLEX_XML_PUBLISHER_APIS.                                      

         ALC1.DISPLAYED_FIELD                                       AS POSTED,
         ALC2.DISPLAYED_FIELD                                       AS C_DIST_TYPE
           
FROM    AP_INVOICE_DISTRIBUTIONS_ALL 		AID,		    --Claudio: Se guardan las cuentas contables de las lineas de transacciones
                                                            --Ademas, si una linea tiene un impuesto compuesto (osea varios impuestos), en las distribuciones te ponen el importe de cada impuesto.
        GL_CODE_COMBINATIONS                GC,             --VER bien definicion de esta tabla.
        AP_LOOKUP_CODES                     ALC1,
        AP_LOOKUP_CODES                     ALC2

WHERE   --Condiciones que saque de la query principal que ya estaba hecha (de Q_AP_INVOICES.sql):
        nvl(AID.reversal_flag,'N')                      != 'Y'
		AND AID.posted_flag                             = 'Y'  --Si esta posteado significa que fue contabilizado (fue mandado a GL).. este filtro al final NO lo usamos. 
        --AND AID.cancellation_flag                     = 'N' --Este NO, hay que filtrar por el de abajo.
        
        AND AID.DIST_CODE_COMBINATION_ID                = GC.CODE_COMBINATION_ID            (+)     --Ver si es asi o tengo que joinear en AP_INVOIVCE_HEADERlsql con esta condicion: AIA.ACCTS_PAY_CODE_COMBINATION_ID       = GC.code_combination_id        (+) 
                                                                                                    --Y mostrar los gc en esa query.... o ver si aca esta bien en distruciones.... VER.
                                                                                                    --O ver si tenemos que unir AID con AIA directamente en cloud ( AIA.ACCTS_PAY_CODE_COMBINATION_ID = AID.dist_code_combination_id) ?¿?¿?¿
        --Joins lookups: 
        AND ALC1.lookup_type                        (+) = 'POSTING STATUS'                      
        AND ALC1.lookup_code                        (+) = AID.Posted_Flag

        AND ALC2.lookup_type                        (+) = 'INVOICE DISTRIBUTION TYPE'               
        AND ALC2.lookup_code                        (+) = AID.Line_Type_Lookup_Code                    
        
        --Campos union Cloud (mediante union de grupo) con AP_LINES_LINES (AP_DIST seria el HIJO de AP_LINES_LINES):
        AND AID.invoice_id                              = :Invoice_ID_2                
        AND AID.invoice_line_number                     = :Invoice_Line_Number_1                

ORDER BY	AID.INVOICE_ID asc,
            AID.DISTRIBUTION_LINE_NUMBER

--VER SI PUEDO IR DE LINES A TAXES O ES DE DIST A TAXES..... O SI ES LO MISOM, VER. 