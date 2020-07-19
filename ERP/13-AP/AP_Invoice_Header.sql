--Query:
select 	--Campos para joinear en Cloud: 
		 AIA.INVOICE_ID,    --Con AP_LINES_LINES, AP_LINES_TAXES y AP_LINES_TAXES_SUM.
                            -- AIA.INVOICE_ID es el ID de la factura, es diferente al AIA.Invoice_Num.
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
        
        AIA.Invoice_Num                                             AS Invoice_Number,              --Seria el NUM_DOC_Factura_Completa:           0004-00082305. 
		substr(AIA.Invoice_Num,1,instr(AIA.Invoice_Num,'-')-1) 		AS NUM_DOC_SERIE,                --Lo que esta antes del guion: 0004.           --Otra forma con expresiones regulares: REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,1)
		substr(AIA.Invoice_Num,instr(AIA.Invoice_Num,'-')+1) 		AS NUM_DOC_NUMERO,               --Lo que esta despues del guion: 00082305      --Otra forma con expresiones regulares: REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,3)

        --SACAR AS Due_Date --Que seria esta fecha? (11/1/19 me dice en la factura)
        AIA.TERMS_DATE                                              AS Due_Date,        --Es esta fecha? Porque es la única que coincide. 
        
        
        AIA.INVOICE_AMOUNT                                          AS Amount,          --Invoice amount in transaction currency (moneda de la factura).     --En moneda funcional... no? (VER)
        
        (   SELECT  SUM(AMOUNT)
            FROM    AP_INVOICE_LINES_ALL AILA1
            WHERE   AILA1.INVOICE_ID = AIA.INVOICE_ID)              AS Amount_2,
        --Estos 2 los usamos?:
        --AIA.BASE_AMOUNT,                                                              --Monto de la factura en moneda extranjera CREO. (VER) 
        --AIA.AMOUNT_PAID,                                                              --Monto pagado de la factura.  (VER)
        
        --Ver cual de estos dos es el campo Current_Approver (traen a la misma persona ambos):
        AIA.LAST_UPDATED_BY                                         AS Current_Approver_1,
        AIA.CREATED_BY                                              AS Current_Approver_2,
        
        --Hay muchos casos donde una factura no está asociada a un proveedor... entonces el campo AIA.VENDOR_ID esta nulo... por eso conviene usar el campo En Party_id que siempre vamos a tenerlo ahi.          
        AIA.VENDOR_ID,      --Proveedor.
        AIA.PARTY_ID,       --Proveedor tambien, solo que hacemos otro join. 
        
        
         --Proveedores(Datos principales + direcciones de los sites): 
        
        --Usamos la forma 1 (la mejor, pero es lo mismo que usar HZ_PARTIES_Proveedor_2):
        HZ_PARTIES_Proveedor_1.PARTY_NAME 							AS Supplier,  
        nvl(HZ_PARTIES_Proveedor_1.JGZZ_FISCAL_CODE,0)				AS NIT_Supplier_1, 	--Rigurosamente el NIT es JGZZ_FISCAL_CODE (NO es HZ_PARTIES_Proveedor.PARTY_NUMBER). Como a veces me trae el NIT vacio, entonces en caso que pase esto le ponemos un 0 (para evitar errores en el BIPUBLISHER).
		nvl(HZ_PARTIES_Proveedor_1.PARTY_NUMBER,0)                  AS NIT_Supplier_2,
        
        --VER SI PROVEEDORES ES 1 POR FACTURA O si es POR CADA LINEA ... ENTONCES EN 1 FACTURA CON MUCHAS LINEAS PUEDEN HABER DISTINTISO PROVEEDORES.. VER (de esa ultima forma lo hice en el 12-SKY Omar. Donde joinee en la query de lineas
        --con la de vendors poor el campo vendor_id: ver grafico en CLOUD). Y aca en esta query lo hice como 1 proveedor 1 factura. 
        
		--Sino lo traemos de aca al nombre del proveedor: POZ_SUPPLIERS_V.vendor_name (con la forma 2 y con esa tabla).
        
               --Subquery para traer el NOMBRE de la Unidad de Negocio / BU (usando el parametro ingresado UNIDAD_NEGOCIO que es la ID):
		(SELECT name
        FROM   	HR_ORGANIZATION_UNITS		HRU		--Las tablas de las sub-querys NO tienen que estar joineadas en nuestra query principal.
        WHERE  	HRU.organization_id 		= AIA.ORG_ID) 
																	 AS Business_Unit,  --Nombre_Unidad_Negocio
                                                                     
        AIA.DESCRIPTION                                              AS Description,

        -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        --INVOICE DETAILS:
                
        TO_CHAR(AIA.INVOICE_DATE,'DD/MM/YYYY')						AS Invoice_Date,   -- Fecha de la factura. AIA.INVOICE_DATE solo me tira esta fecha: 2019-04-25T00:00:00.000+00:00. Y yo solo quiero DD-MM-YYYY (POR ESTO USAMOS TO_DATE).
		--Con TO_CHAR nos devuelve 25/04/2019.
        --Subquery para obtener el TIPO:
		(select MEANING								--MEANING es standard, credit memo, etc. (dado el where de abajo)
		from 	fnd_lookup_values 	 	FLV			--Tabla de Lookups. 
		where 	FLV.LANGUAGE = 'US' 			
				AND FLV.LOOKUP_TYPE = 'INVOICE TYPE'   	--Esto cambiamos con respecto al reporte 2. 
				AND FLV.LOOKUP_CODE =  AIA.INVOICE_TYPE_LOOKUP_CODE --Esto tambien cambiamos.  	  INVOICE_TYPE_LOOKUP_CODE es STANDARD, CREDIT, etc.
		) --Termina subquery.
																	AS Invoice_Type,
        --Otra forma de sacar el Invoice_Type:
        ALC.DISPLAYED_FIELD                                         AS Invoice_Type_2,          

        PSSA_M.VENDOR_SITE_CODE                                     AS SUPPLIER_SITE,         
        
        (HZ_LOC_Supplier_1.ADDRESS1  || '.' ||   HZ_LOC_Supplier_1.ADDRESS2   || '.' ||   HZ_LOC_Supplier_1.ADDRESS3   || '.' ||    HZ_LOC_Supplier_1.ADDRESS4)                                                     AS Address_1_Supplier,
        (HZ_LOC_Supplier_1.CITY      || '.' ||   HZ_LOC_Supplier_1.COUNTY     || '.' ||   HZ_LOC_Supplier_1.STATE      || '.' ||    HZ_LOC_Supplier_1.PROVINCE    || '.' ||  HZ_LOC_Supplier_1.POSTAL_CODE)         AS Address_2_Supplier,
        F_T_TL_Supplier_1.TERRITORY_SHORT_NAME                                                                                                                                                                      AS Territory_Name_Supplier,
        HZ_P_S_Supplier_1.PARTY_SITE_NUMBER                                                                                                                                                                         AS Site_Supplier,
            
        --Applied Prepayments   --VER que campo es
        --Unpaid Amount         --VER. (AIA.Amount - AIA.AMOUNT_PAID seria?   O sino AIA.Amount - AIA.PAYMENT_AMOUNT_TOTAL)
        
        --AS HOLDS               --REPESAR LO QUE HICE DE RETENCIONES Y DISTRIBUCIONES Y ESO Y PONERLO. De aca lo saco: AP_HOLDS_ALL?
        
        --AS Notes              --Que campo seria?
        
        --As Payment_Business_Unit --VER QUE SERIA ESTE CAMPO. 
        
        APTT.NAME                                                   AS Payment_Terms,  --Termino de pago, CONTADO. 
       
		FCVL.DESCRIPTION 									        AS Payment_Currency,
		FCVL.SYMBOL 												AS Simbolo_Moneda,
        
        -- AS Attachment (VER) 
        
        --Subquery para traer el NOMBRE de la Unidad de la Entidad Legal (usando el parametro ingresado ENTIDAD_LEGAL que es la ID):
		(SELECT name
		FROM 	XLE_ENTITY_PROFILES 		XEP	  	--Las tablas de las sub-querys NO tienen que estar joineadas en nuestra query principal.  
		WHERE 	XEP.legal_entity_id 		= AIA.LEGAL_ENTITY_ID)
																	AS Nombre_Entidad_Legal,
        
        --Ver que son estos remit: (?)
        AIA.REMIT_TO_SUPPLIER_ID,
        AIA.REMIT_TO_ADDRESS_ID,
        
        UPPER(BATCH.BATCH_NAME)                                     AS C_UPPER_BATCH_NAME   --Batch_Name en mayuscula. 
        
from 	AP_INVOICES_ALL 		    AIA,		--Tabla principal. Tabla de FACTURAS. 	
		FND_CURRENCIES_VL  		    FCVL, 		--Tabla con info de las monedas. 
		
        --Para los proveedores (supplier) y compradores: 
        POZ_SUPPLIERS		        POZS,   	            --Tabla de los proveedores.  --Sino podemos usar POZ_SUPPLIERS_V (aunque es mas costoso computacionalmente hablando).
        HZ_PARTIES                  HZ_PARTIES_Proveedor_1, --Proveedor forma 1.
        HZ_PARTIES                  HZ_PARTIES_Proveedor_2, --Proveedor forma 2, usamos la 1 mejor (ya que siempre vamos a tener PARTY_ID).
        HZ_PARTY_SITES              HZ_P_S_Supplier_1,
        HZ_LOCATIONS                HZ_LOC_Supplier_1,
        FND_TERRITORIES_TL          F_T_TL_Supplier_1,
        POZ_SUPPLIER_SITES_ALL_M    PSSA_M,
        
        --Metodos y terminos de pago de la factura: 
        AP_TERMS_TL                 APTT,              --Terminos de pago. Le decis si es a 15 o 30 dias, es CUANDO te van a pagar. Ver diferencia con la de abajo?  
        AP_TERMS_B                  APTB,
        
        AP_LOOKUP_CODES             ALC,               --Forma 2 de sacar tipo factura. 
        
        AP_BATCHES_ALL              BATCH              --Ver bien definicion de esta tabla. 
        
where	--Filtramos una sola factura (la del word):
        --AIA.INVOICE_NUM                             =  'EUR1234'  --'RENKZ11122019' es la que aparecia en el word. 
       -- AIA.INVOICE_ID                              = 300000002749358  --Una que me traia datos de impuestos. 
        AIA.INVOICE_ID                              = 300000002763345 --Una que me trae datos de retenciones. 
        --Joins con la tabla principal (la mayoria los saque de docs.oracle tabla AIA):             
		AND AIA.INVOICE_CURRENCY_CODE 	            = FCVL.CURRENCY_CODE  		    --JOIN PARA FCVL MONEDAS.
        
        --Filtros proveedor:
        AND AIA.PARTY_ID 		                    =HZ_PARTIES_Proveedor_1.PARTY_ID    --Asi traemos al proveedor (forma 1 - la mejor porque siempre vamos a tener PARTY_ID).

        AND POZS.VENDOR_ID	                        =AIA.VENDOR_ID                      --Asi traemos al proveedor (forma 2: a veces NO vamos a tener VENDOR_ID).
        AND POZS.PARTY_ID                           =HZ_PARTIES_Proveedor_2.PARTY_ID    --Asi traemos al proveedor (forma 2).

        --Joins para las direcciones de los proveedores:
        AND AIA.PARTY_SITE_ID                       =HZ_P_S_Supplier_1.PARTY_SITE_ID    (+)
        AND HZ_P_S_Supplier_1.location_id           =HZ_LOC_Supplier_1.location_id      (+)
        AND HZ_LOC_Supplier_1.country               =F_T_TL_Supplier_1.territory_code   (+)
        AND F_T_TL_Supplier_1.language (+)          =userenv ('LANG')
        AND AIA.vendor_site_id                      =PSSA_M.VENDOR_SITE_ID              (+)

        --Join terminos de pago:
        AND AIA.terms_id                            = APTB.TERM_ID                      (+)
        AND APTB.term_id                            = APTT.term_id                      (+)
        AND userenv ('LANG')                        = APTT.language                     (+)
        --DUDA: porque tiene terminos de pago pero NO metodos de pago. !??!?!!?!? Por ej. AR si tenia las 2. (tabla AR_RECEIPT_METHODS y se joineaba con el campo receipt_method_id de la cabecera de la factura). 
        
        --Join AP_LOOKUP_CODES: 
        AND ALC.lookup_type                         = 'INVOICE TYPE'
        AND ALC.lookup_code                         = AIA.Invoice_Type_Lookup_Code
        
        --Join con AP_BATCHES_ALL:
        AND AIA.batch_id                            = BATCH.batch_id                    (+)