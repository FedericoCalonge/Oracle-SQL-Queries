SELECT
		--Para joinear en Cloud: 
        RCTA.CUSTOMER_TRX_ID	  	                            AS Customer_ID_1,       --Con AR_Lines_SUM, AR_Lines_Lines, AR_Lines_Taxes y AR_Payments.

        -----------------------------------------------------------------------------------------------------------------------------------------------        
        RCTA.LEGAL_ENTITY_ID                                    AS Legal_Entity,
        RCTA.ORG_ID                                             AS BU,
        RBSA.name                                               AS Transaction_Source,      --Es el "Batch Name". En este caso es GTA - Comprobante Fiscal.
        
        --Esto nos sirve para diferenciar factura, de nota de debito , de credito:
        RCTTA.name										        AS Transaction_Type_Name,  --Ejemplos (VER QUE SON LOS GTA, NUMEROS Y ESO):
                                                                                            --GTA-N. Debito 0050
                                                                                            --GTA-Factura 0050
                                                                                            --GTA-N. Credito 0052
        RCTTA.DESCRIPTION                                       AS Transaction_Type_Descr,  --Mas largo que el  Transaction_Type_Name (por ej. GTA-Nota de Credito 0052) 
        RCTTA.TYPE                                              AS Transaction_Type,        --Clase de la transaccion: INV, CM, DM, or CB. (para nota de credito CM)
        
        RCTA.TRX_NUMBER                                         AS Transaction_Number,	
        --Formato del TRANSACTION_NUMBER: A-9050-00000004 (SOLO PARA ARGENTINA ES ESTO). Aunque para la factura que vimos como ejemplo este numero es solo 4017. 
                --Letra: A,B,C,E,etc...: monotributista, etc. 
                --9050: es el PUNTO DE VENTA. 
                --Los otros 8 numeros: son el numero de comproibante, el que realiza la entidad legal. 
        
        substr(RCTA.TRX_NUMBER ,1,1)                            AS TRX_NUMBER_Letter, --A         
        regexp_replace(substr( RCTA.TRX_NUMBER ,3,5)             
                                            ,'[^[:alnum:]]*'       
                                            ,''             ) 
                                                                AS TRX_NUMBER_Part1,  --9050. Empezamos en la posicion 3 y extraemos 5 carecteres.
        regexp_replace(substr( RCTA.TRX_NUMBER ,8,8)             
                                            ,'[^[:alnum:]]*'       
                                            ,''             ) 
                                                                AS TRX_NUMBER_Part2,  --00000004. Empezamos en la posicion 8 y extraemos 8 carecteres.

       	RCTA.DOC_SEQUENCE_VALUE                                 AS Document_Number,          --Claudio dijo que no sabia que significaba pero que CREIIIIA que era este campo.

        RCTA.complete_flag                                      AS Status,                  --'N'. NO es el campo STATUS_TRX. Si esta incomplete significa que no se pagó la factura? Y si esta incomplete la nota de debito o credito? O significa otra cosa? Decode para que sea complete e incomplete? 
        RCTA.TRX_DATE						                    AS Transaction_Date,        --Fecha en que realmente se hizo el pago.
        RCTLGDA.GL_DATE                                         AS Accounting_Date,         --Es la fecha de contabilizacion en el GL. 
		--¿Region, Invoicing Rule, Attachments, y Notes se usan? Que campos serian? 
        
        --Moneda:
        FCVL.CURRENCY_CODE   || ' - ' ||  FCVL.DESCRIPTION      AS Currency,                --USD - US Dollar.
		FCVL.SYMBOL 										    AS Currency_Symbol, 		--Simbolo: $
        
        --Forma 2 de obtener el monto total de la factura (forma 1 es haciendo los SUM en AR_Lines_SUM):
        --Saber: --Si es una nota de credito (ver campo Transaction_Type) el monto es en negativo. 
        RCTLGDA.AMOUNT                                          AS Transaction_Total_2_E,     --En moneda extranjera.    99175   (me da igual que Transaction_Total de AR_LINES).
        RCTLGDA.ACCTD_AMOUNT                                    AS Transaction_Total_2_F,     --En moneda funcional.     5950500
        --Así, por ej., si estoy en Argentina y cargo la moneda en dls entonces acctd_amount esta en pesos argentinos. Se hace un nvl entre los 2 generalmente. 
        
        --Forma 3 de obtener el monto total de la factura (con subquery, pero usando la misma tabla ra_customer_trx_lines_all que en AR_Lines):
        (   SELECT  abs(SUM(extended_amount))
            FROM    ra_customer_trx_lines_all RCTLA
            WHERE RCTLA.customer_trx_id = RCTA.customer_trx_id
        )                                                       AS Transaction_Total_3,       --99175
  
       --Saber: NO hay forma 2 de obtener el monto total de Lines "Lines" y de Taxes "Tax" con RCTLGDA (VER la forma haciendo los SUM en AR_Lines_SUM): 
        -- AS Lines.    --Ver AR_LINES, ahi esta. 
        -- AS Tax.      --Ver AR_LINES, ahi esta.
        
        --Pero si se puede mediante una subquery usando la misma tabla ra_customer_trx_lines_all que en AR_Lines:        
        (   SELECT  abs(SUM(extended_amount))
            FROM    ra_customer_trx_lines_all RCTLA
            WHERE   RCTLA.customer_trx_id = RCTA.customer_trx_id
                    AND RCTLA.line_type           ='LINE'
        )                                                            AS Lines_2,  --85000
        
        (   SELECT  abs(SUM(extended_amount))
            FROM    ra_customer_trx_lines_all RCTLA
            WHERE   RCTLA.customer_trx_id = RCTA.customer_trx_id
                    AND RCTLA.line_type           ='TAX'
        )                                                            AS Tax_2,   --14175
        
        --Freight (flete) y charges (cargos adicionales) de la factura:
        --Siempre se lo mantiene como un monto separado y no se lo suma al total de factura. Cuando haces el pago tambien aparece sepadado. Al parecer Freight está en las lineas de la factura y Charges se saca de ADJ:

            RCTA.FINANCE_CHARGES                                         AS Flag_Charges,      --No trae nada igual. 
    
            nvl((   SELECT  SUM(NVL(ADJ.receivables_charges_adjusted, 0))   ---NVL a receivables_charges_adjusted (osea si es null devuelve 0).
                    FROM    ar_adjustments_all ADJ
                    WHERE   ADJ.customer_trx_id = RCTA.customer_trx_id
                            AND  ADJ.status = 'A'
                            AND  ADJ.receivables_trx_id <> -15
                ),0)                                                    AS Charges,  --Finance_Charges.
            
            --Ver Charges_2 de "AR.Payments.sql"

            nvl((   SELECT  SUM(extended_amount)
                    FROM    ra_customer_trx_lines_all lines
                    WHERE   lines.customer_trx_id = RCTA.customer_trx_id
                            AND lines.line_type           ='FREIGHT'
            ),0)                                                        AS Freight,
        
        --Customers (Clientes) (DESPUES VER SI HACER TABLA APARTE):
            --Bill_to:
                RCTA.BILL_TO_CUSTOMER_ID,               --300000002749672
                RCTA.BILL_TO_SITE_USE_ID,               --Tiene datos.
                HZCA_BILL.account_number                AS Account_Number,      --BILL_TO_CUSTOMER_NUMBER    --9007<
        
            --Ship_to:
                RCTA.SHIP_TO_PARTY_ID,                  --Tiene datos. De aca tenemos que sacar el campo, NO de SHIP_TO_CUSTOMER_ID que no tiene nada. 
                RCTA.SHIP_TO_PARTY_SITE_USE_ID,         --Tiene datos. De aca tenemos que sacar el campo, NO de SHIP_TO_SITE_USE_ID que no tiene nada. 
                RCTA.SHIP_TO_PARTY_ADDRESS_ID,          --Tiene datos. De aca tenemos que sacar el campo, NO de SHIP_TO_ADDRESS_ID que no tiene nada.
                --RCTA.SHIP_TO_PARTY_CONTACT_ID,        --Vacio como el campo SHIP_TO_CONTACT_ID.   
            
            --Sold_to:
                --Para sold estan solo estos, ver cual trae algo:
                --Estos para SOLD NO tienen datos: RCTA.SOLD_TO_CUSTOMER_ID, RCTA.SOLD_TO_CONTACT_ID, RCTA.SOLD_TO_SITE_USE_ID,
                RCTA.SOLD_TO_PARTY_ID,                  --Tiene datos. 
                
            --Paying_to:
                RCTA.paying_customer_id,                --Tiene datos.
                RCTA.PAYING_SITE_USE_ID,                --Tiene datos.
        
        --Remit_to (direccion de envio de la factura): 
                RCTA.REMIT_TO_ADDRESS_SEQ_ID,           --Tiene datos. NO tenia datos: REMIT_TO_ADDRESS_ID
        
        --Nombre de los clientes y de la cuenta (los sacamos de HZP, que debe estar joineado con HZ_CUST_ACCOUNTS):
         HZP_BILL_PARTY.PARTY_NAME                           AS Name_Bill_To,
         HZP_SHIP_PARTY.PARTY_NAME                           AS Name_Ship_To,
         HZP_SOLD_PARTY.PARTY_NAME                           AS Name_Sold_To,
         HZP_PAYING_PARTY.PARTY_NAME                         AS Name_Paying_To,

        --Direcciones de los Sites de los Clientes y numero de Site: 
         
            --Bill_to:
            (HZ_LOC_BILL_LOC.ADDRESS1  || '.' ||   HZ_LOC_BILL_LOC.ADDRESS2   || '.' ||   HZ_LOC_BILL_LOC.ADDRESS3   || '.' ||    HZ_LOC_BILL_LOC.ADDRESS4)                                                     AS Address_Bill_To_1,
            (HZ_LOC_BILL_LOC.CITY      || '.' ||   HZ_LOC_BILL_LOC.COUNTY     || '.' ||   HZ_LOC_BILL_LOC.STATE      || '.' ||    HZ_LOC_BILL_LOC.PROVINCE    || '.' ||  HZ_LOC_BILL_LOC.POSTAL_CODE)           AS Address_Billl_To_2,
            FT_BILL.TERRITORY_SHORT_NAME                                                                                                                                                                        AS Territory_Name_Bill_To,
            HZP_SITES_BILL_PS.PARTY_SITE_NUMBER                                                                                                                                                                 AS Site_Bill_To,

           --Ship_to:
            (HZ_LOC_SHIP_LOC.ADDRESS1  || '.' ||   HZ_LOC_SHIP_LOC.ADDRESS2   || '.' ||   HZ_LOC_SHIP_LOC.ADDRESS3   || '.' ||    HZ_LOC_SHIP_LOC.ADDRESS4)                                                     AS Address_Ship_To_1,
            (HZ_LOC_SHIP_LOC.CITY      || '.' ||   HZ_LOC_SHIP_LOC.COUNTY     || '.' ||   HZ_LOC_SHIP_LOC.STATE      || '.' ||    HZ_LOC_SHIP_LOC.PROVINCE    || '.' ||  HZ_LOC_SHIP_LOC.POSTAL_CODE)           AS Address_Ship_To_2,
            FT_SHIP.TERRITORY_SHORT_NAME                                                                                                                                                                        AS Territory_Name_Ship_To,
             HZP_SITES_SHIP_PS.PARTY_SITE_NUMBER                                                                                                                                                                AS Site_Ship_To,
             
            --Paying_to:
             (HZ_LOC_PAY_LOC.ADDRESS1  || '.' ||   HZ_LOC_PAY_LOC.ADDRESS2   || '.' ||   HZ_LOC_PAY_LOC.ADDRESS3   || '.' ||    HZ_LOC_PAY_LOC.ADDRESS4)                                                        AS Address_Pay_To_1,
             (HZ_LOC_PAY_LOC.CITY      || '.' ||   HZ_LOC_PAY_LOC.COUNTY     || '.' ||   HZ_LOC_PAY_LOC.STATE      || '.' ||    HZ_LOC_PAY_LOC.PROVINCE    || '.' ||  HZ_LOC_PAY_LOC.POSTAL_CODE)               AS Address_Pay_To_2,
             FT_PAY.TERRITORY_SHORT_NAME                                                                                                                                                                        AS Territory_Name_Pay_To,
             HZP_SITES_PAY_PS.PARTY_SITE_NUMBER                                                                                                                                                                 AS Site_Paying_To,
             
        --Direccion de envio de la factura - Remit_to:
        (HZ_LOC_REMIT_LOC.ADDRESS1  || '.' ||   HZ_LOC_REMIT_LOC.ADDRESS2   || '.' ||   HZ_LOC_REMIT_LOC.ADDRESS3   || '.' ||    HZ_LOC_REMIT_LOC.ADDRESS4)                                                     AS Address_Remit_To_1,
        (HZ_LOC_REMIT_LOC.CITY      || '.' ||   HZ_LOC_REMIT_LOC.COUNTY     || '.' ||   HZ_LOC_REMIT_LOC.STATE      || '.' ||    HZ_LOC_REMIT_LOC.PROVINCE    || '.' ||  HZ_LOC_REMIT_LOC.POSTAL_CODE)          AS Address_Remit_To_2,
        FT_REMIT.TERRITORY_SHORT_NAME                                                                                                                                                                           AS Territory_Name_Remit_To,
        
        --Metodos y terminos de pago de la factura: 
        ARM.NAME                                            AS Metodo_Pago,         --No me trae nada porque no tiene metodos de pago, pero el campo es este. Y seguramente traiga varios registros porque debe tener varios metodos de pago. 
        RATT.NAME                                           AS Termino_Pago         --30 dias FF
            
FROM    RA_CUSTOMER_TRX_ALL 			RCTA, 		--Cabecera.
        RA_CUST_TRX_TYPES_ALL 	 	    RCTTA, 		--Tipo de transacción.
		FND_CURRENCIES_VL				FCVL,		--Monedas.
        RA_CUST_TRX_LINE_GL_DIST_ALL	RCTLGDA, 	--Distribuciones. Detalles de los impuestos y monto total de la factura. Tambien sacamos de aca la fecha GL_DATE. 
        RA_BATCH_SOURCES_ALL            RBSA,       --Solo para el campo Transaction_Source
        
        --Customers (Clientes):
        --De Hz_cust_accounts obtenemos TODOS los clientes. Tenemos que joinear con HZP para los nombres de los mismos (ABAJO esta joineado).
            --Hay DISTINTOS tipos de clientes (bill_to, ship_to, sold_to, paying_to). 
                --Bill_to: A quien le cobramos/facturamos. Tiene direccion.
                --Ship_to: A quien se le entregó/hay que entregar la MERCADERIA (NO la factura/nota debito/credito). Tiene direccion.
                --Sold_to: A quien se le vendió. Puede ser que se la hayan vendido a Pepe pero que la haya pagado Juan (entonces Juan seria el Bill_to y Pepe el Sold_to). 
                          --NO tiene dirección. Porque????
                --Paying_to: ??? Ver si es quien realmente lo paga o que.  Tiene direccion.
            --Y FUERA de los clientes estaría el:
                --Remit_to: Contiene la dirección donde se envia la factura o se notifica el pago de la misma. 
            
            HZ_CUST_ACCOUNTS                HZCA_BILL,            --Cuentas del cliente Bill_to             
            HZ_PARTIES                      HZP_BILL_PARTY,

            --HZ_CUST_ACCOUNTS              HZCA_SHIP,            --Al final NO la usmaos a la tabla porque en RCTA.SHIP_TO_CUSTOMER_ID NO tenemos nada y hacemos otro join (osea que no hay cuentas para ship_to).
            HZ_PARTIES                      HZP_SHIP_PARTY,     
            
            --HZ_CUST_ACCOUNTS              HZCA_SOLD,            --Al final NO la usmaos a la tabla porque en RCTA.SHIP_TO_CUSTOMER_ID NO tenemos nada y hacemos otro join. (osea que no hay cuentas para sold_to).
            HZ_PARTIES                      HZP_SOLD_PARTY,
            
            HZ_CUST_ACCOUNTS                HZCA_PAYING,            --VER ESTE QUE SERIA.
            HZ_PARTIES                      HZP_PAYING_PARTY,      
        
        --Para las direcciones de las  todos los clientes:
        --SABER: 1 cliente puede tener 1 o varias SITES (estas son las "sucursales"). Por ej. si YO soy el cliente entonces en SITES figuraría solo mi casa. En cambio si es Garbarino figurarían TODAS sus sucursales.
        --Por esto hay que joinear si o si con SITES (primero con HZ_CUST_SITE_USES_ALL y despues con HZ_CUST_ACCT_SITES_ALL):
            --VER HZ_CUST_SITE_USES_ALL DIFERENCIA CON  HZ_CUST_ACCT_SITES_ALL???:      
           
           --Bill_to:
                HZ_CUST_SITE_USES_ALL           HZ_CUST_USES_BILL,           --Sucursal a la cual se cobrara.  
                HZ_CUST_ACCT_SITES_ALL          HZ_CUST_SITES_BILL,
                HZ_PARTY_SITES                  HZP_SITES_BILL_PS,
                HZ_LOCATIONS                    HZ_LOC_BILL_LOC,
                FND_TERRITORIES_TL              FT_BILL,
            
            --Ship_to:
                --HZ_CUST_SITE_USES_ALL         HZ_CUST_USES_SHIP,         --Sucursal a la cual se enviará (la mercaderia).  NO la usamos al final, hacemos el join con otra tabla.  
                --HZ_CUST_ACCT_SITES_ALL        HZ_CUST_SITES_SHIP,       --NO LA USAMOS, usamos directamente la de Party.
                HZ_PARTY_SITES                  HZP_SITES_SHIP_PS,
                HZ_LOCATIONS                    HZ_LOC_SHIP_LOC,
                FND_TERRITORIES_TL              FT_SHIP,
            
            --Sold_to:
                --NO tiene direccion asi que no usamos tablas para esto.
                
            --Paying_to:
                HZ_CUST_SITE_USES_ALL           HZ_CUST_USES_PAYING,         --Sucursal a la cual.... VER!??!
                HZ_CUST_ACCT_SITES_ALL          HZ_CUST_SITES_PAY,
                HZ_PARTY_SITES                  HZP_SITES_PAY_PS,
                HZ_LOCATIONS                    HZ_LOC_PAY_LOC,
                FND_TERRITORIES_TL              FT_PAY,
               
        --Para la direccion de Remit_to (lugar donde se enviará la factura). NO usamos HZ_CUST_SITE_USES_ALL ni HZ_CUST_ACCT_SITES_ALL (como en "Ship_to", joineamos directamente con otra tabla).
            --HZ_CUST_SITE_USES_ALL             HZ_CUST_USES_REMIT,     --NO.
            --HZ_CUST_ACCT_SITES_ALL            HZ_CUST_SITES_REMIT,    --NO.
            ar_remit_to_locs_all                AR_REMIT_A,             --Nueva tabla, la descubrimos viendo la query para el reporte estandard de AR.
            HZ_LOCATIONS                        HZ_LOC_REMIT_LOC,
            FND_TERRITORIES_TL                  FT_REMIT,

        --Metodos y terminos de pago de la factura: 
        AR_RECEIPT_METHODS           ARM,               --Metodos de pago. Es el COMO te va a pagar (por ej. efectivo o cheque). 
        RA_TERMS_TL                  RATT,              --Terminos de pago. Le decis si es a 15 o 30 dias, es CUANDO te van a pagar. Ver diferencia con la de abajo?  
        RA_TERMS_B                   RATB
        
WHERE   RCTA.TRX_NUMBER  = '4017'  --Hardcodeamos para que nos traiga la factura de prueba. 
        
        --2 filtros para traer el monto total de la factura y la fecha GL_DATE desde la tabla RCTLGDA (ver arriba en los 3 campos en select para RCTLGDA):
            AND     RCTLGDA.ACCOUNT_CLASS           = 'REC'
            AND     RCTLGDA.LATEST_REC_FLAG         = 'Y'

        --Joins:
            AND     RCTA.CUSTOMER_TRX_ID			    = RCTLGDA.CUSTOMER_TRX_ID 

            AND     RCTA.CUST_TRX_TYPE_SEQ_ID 		    = RCTTA.CUST_TRX_TYPE_SEQ_ID
            AND     RCTA.INVOICE_CURRENCY_CODE 		    = FCVL.CURRENCY_CODE 
            AND     RCTA.BATCH_SOURCE_SEQ_ID            = RBSA.BATCH_SOURCE_SEQ_ID
        
        --Join con Customers y con Hz_Party para obtener el nombre de los clientes: 
            --Bill_to:
                AND     RCTA.bill_to_customer_id        = HZCA_BILL.cust_account_id             --Porque aca no les pusimos el outer join? (el (+)). Porque se supone que una factura SIEMPRE va a tener un bill_to. Y quizas no va a tener un ship_to  o sold_to (CREO QUE ES POR ESO).
                AND     HZCA_BILL.party_id              = HZP_BILL_PARTY.party_id
        
            --Ship_to:
                --Como en RCTA.ship_to_customer_id no hay nada entonces estas 2 lineas NO, directamente joineamos RCTA con HZP_SHIP_PARTY
                --AND   RCTA.ship_to_customer_id        = HZCA_SHIP.cust_account_id (+)         
                --AND   HZCA_SHIP.party_id              = HZP_SHIP_PARTY.party_id (+)
                AND     RCTA.SHIP_TO_PARTY_ID           =  HZP_SHIP_PARTY.party_id (+)
          
            --Sold_to:
                --AND     RCTA.sold_to_customer_id        = HZCA_SOLD.cust_account_id (+)
                --AND     HZCA_SOLD.party_id              = HZP_SOLD_PARTY.party_id (+)
                AND     RCTA.SOLD_TO_PARTY_ID           =  HZP_SOLD_PARTY.party_id (+)
            --Paying_to:
                AND     RCTA.paying_customer_id         = HZCA_PAYING.cust_account_id (+)
                AND     HZCA_PAYING.party_id            = HZP_PAYING_PARTY.party_id (+)
        
        
        --Joins con las tablas de direcciones (HZ_CUST_SITE_USES_ALL, HZ_CUST_ACCT_SITES_ALL, HZ_PARTY_SITES, HZ_LOCATIONS, FND_TERRITORIES_TL):
            --Bill_to:
                AND     RCTA.bill_to_site_use_id                        =HZ_CUST_USES_BILL.site_use_id (+)  
                AND     HZ_CUST_USES_BILL.cust_acct_site_id             =HZ_CUST_SITES_BILL.cust_acct_site_id (+)
                AND     HZ_CUST_SITES_BILL.party_site_id                =HZP_SITES_BILL_PS.party_site_id (+)
                AND     HZP_SITES_BILL_PS.location_id                   =HZ_LOC_BILL_LOC.location_id (+)
                AND     HZ_LOC_BILL_LOC.country                         =FT_BILL.territory_code (+)
                AND     FT_BILL.language (+)                            = userenv ('LANG')                           --Si no ponemos este filtro nos trae 2 registros por factura para bill_to. 
          
            --Ship_to (NO usamos la tabla HZ_CUST_SITE_USES_ALL ni HZ_CUST_ACCT_SITES_ALL):
                AND     RCTA.SHIP_TO_PARTY_ADDRESS_ID                   =HZP_SITES_SHIP_PS.party_site_id   (+)
                AND     HZP_SITES_SHIP_PS.location_id                   =HZ_LOC_SHIP_LOC.location_id  (+)
                AND     HZ_LOC_SHIP_LOC.country                         =FT_SHIP.territory_code (+) 
                AND     FT_SHIP.language (+)                            = userenv ('LANG')          
            
            --Sold_to: 
                --NO tiene dirección.
            
            --Paying_to:
                AND     RCTA.paying_site_use_id                         = HZ_CUST_USES_PAYING.site_use_id (+)
                AND     HZ_CUST_USES_PAYING.cust_acct_site_id           =HZ_CUST_SITES_PAY.cust_acct_site_id (+)
                AND     HZ_CUST_SITES_PAY.party_site_id                 =HZP_SITES_PAY_PS.party_site_id (+)
                AND     HZP_SITES_PAY_PS.location_id                    =HZ_LOC_PAY_LOC.location_id (+)
                AND     HZ_LOC_PAY_LOC.country                          =FT_PAY.territory_code (+)
                AND     FT_PAY.language (+)                             = userenv ('LANG') 
        
        --Joins con Remit_to (direccion de envio de la factura / notificacion de pago de la misma):             
            AND RCTA.REMIT_TO_ADDRESS_SEQ_ID                =AR_REMIT_A.address_loc_seq_id(+)
            AND AR_REMIT_A.location_id                      =HZ_LOC_REMIT_LOC.location_id(+)
            AND HZ_LOC_REMIT_LOC.country                    =FT_REMIT.territory_code (+) 
            AND FT_REMIT.language (+)                       = userenv ('LANG') 
    
        --Join con Metodos y terminos de pago:
            AND RCTA.receipt_method_id                      = ARM.receipt_method_id (+)
            AND RCTA.term_id                                = RATB.term_id (+)
            AND RATB.term_id                                = RATT.term_id (+)
            AND userenv ('LANG')                            = RATT.language (+)