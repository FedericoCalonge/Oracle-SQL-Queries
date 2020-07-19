SELECT
       RCTA.TRX_NUMBER      NRO_FACTURA
     , TRX_DATE             FECHA_TRANSACCION
     , RCTLGDA.GL_DATE      FECHA_CONTABLE
     , COMPRADOR.PARTY_NAME NOMBRE_COMPRADOR
     , COMPRADOR.DIRECCION
     , RCTA.INVOICE_CURRENCY_CODE MONEDA
       --------------------------
     , RCTLA.LINE_NUMBER NRO_LINE
     , (
              SELECT
                     ITEM_NUMBER
              FROM
                     EGP_SYSTEM_ITEMS
              WHERE
                     RCTLA.INVENTORY_ITEM_ID = INVENTORY_ITEM_ID
                     AND RCTLA.WAREHOUSE_ID  = ORGANIZATION_ID
       )
                                ITEM
     , RCTLA.DESCRIPTION        DESCRIPCION
     , RCTLA.QUANTITY_ORDERED   CANTIDAD_ORDENADA
     , RCTLA.UNIT_SELLING_PRICE PRECIO_UNITARIO
     , RCTLA.EXTENDED_AMOUNT    MONTO_POR_LINEA
     , IMPUESTOS.MONTO_IMPUESTO
FROM
       --------------------------------------
       RA_CUSTOMER_TRX_ALL         	RCTA
     , RA_CUST_TRX_LINE_GL_DIST_ALL RCTLGDA
     , RA_CUSTOMER_TRX_LINES_ALL    RCTLA
     , (
                SELECT
                         CUSTOMER_TRX_ID
                       , SUM(EXTENDED_AMOUNT) MONTO_IMPUESTO
                FROM
                         RA_CUSTOMER_TRX_LINES_ALL
                WHERE
                         LINE_TYPE = 'TAX'
                GROUP BY
                         CUSTOMER_TRX_ID
       )
       IMPUESTOS
       --------------------------------------
     , (
              SELECT
                     HCSUA.SITE_USE_ID
                   , HPS.PARTY_SITE_ID
                   , HPS.PARTY_SITE_NAME
                   , HL.LOCATION_ID
                   , HCA.CUST_ACCOUNT_ID
                   , HP.PARTY_NAME
                   , HL.ADDRESS1
                            || '-'
                            || HL.CITY
                            || '-'
                            || HL.COUNTRY DIRECCION
              FROM
                     HZ_CUST_SITE_USES_ALL  HCSUA
                   , HZ_CUST_ACCT_SITES_ALL HCASA
                   , HZ_PARTY_SITES         HPS
                   , HZ_LOCATIONS           HL
                   , HZ_CUST_ACCOUNTS       HCA
                   , HZ_PARTIES             HP
              WHERE
                     HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID
                     AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID
                     AND HPS.LOCATION_ID     = HL.LOCATION_ID
                     AND HP.PARTY_ID         = HCA.PARTY_ID
                     AND HPS.PARTY_ID        = HP.PARTY_ID
       )
       COMPRADOR
WHERE
       RCTA.CUSTOMER_TRX_ID       = RCTLGDA.CUSTOMER_TRX_ID
       AND RCTA.CUSTOMER_TRX_ID       = RCTLA.CUSTOMER_TRX_ID
       AND RCTLA.CUSTOMER_TRX_LINE_ID = RCTLGDA.CUSTOMER_TRX_LINE_ID
       AND RCTA.BILL_TO_CUSTOMER_ID   = COMPRADOR.CUST_ACCOUNT_ID(+) --
       AND RCTA.BILL_TO_SITE_USE_ID   = COMPRADOR.SITE_USE_ID(+)
       AND RCTLA.LINE_TYPE            = 'LINE'
       AND IMPUESTOS.CUSTOMER_TRX_ID(+)  = RCTA.CUSTOMER_TRX_ID -- Se usa cuando no tiene información.. y no machean. Entonces, si anulamos lo otro. 
	   ---------------------------------------------------
       AND RCTA.TRX_NUMBER            = :NRO_FACTURA  --En la tabla es un varchar. 
	   AND RCTA.CUSTOMER_TRX_ID 	  = :NRO_FACTURA2  --En la tabla es un NUMBER. Para la lista de valores de tipo SQL Query. 
	   -- AND RCTA.FLAG       		  = :NUMERO_FACTURA2  --Esto es en caso que la lista de valores sea de tipo Fixed data. 
	   -- IGUALMENTE esta tabla RCTA.FLAG no está, es de modo ejemplo.