--Ahora armamos nuestra consulta FINAL:
select --ACA.PAYMENT_TYPE_FLAG  		   AS FLAG_TIPO_PAGO,  		--FLAG_TIPO_PAGO es el ALIAS de PAYMENT_TYPE_FLAG. Tambien se puede utilizar el alias SIN el AS.  
	   --ACA.PAYMENT_METHOD_LOOKUP_CODE   AS LOOKUP_CODE,  		--Este campo no tiene nada que ver al FLAG_TIPO_PAGO
	   --Abajo hacemos que el Q sea traido desde el FLAG_TIPO_PAGO de la tabla AP_CHECKS_ALL (ver subquery) y que nos traiga el meaning (select):
  
		--Subquery para obtener el TYPE (Batch o Quick) --> DESPUES VER PORQUE NO HAY BATCH, SOLO QUICK y Payment Process RequesT... VER SI ESTA BIEN.
		(select MEANING
		from fnd_lookup_values 			--ESTA ES LA TABLA DE LOOKUPS!. Nos la dieron, vamos a tener que usarla muchas mas veces. 
		where LANGUAGE = 'US' 			--EL lenguaje tiene que ser US si o si.
		--AND LOOKUP_TYPE LIKE '%PAY%' 	--Buscamos algo de nuestro modulo (payments). Encontramos el "PAYMENT_TYPE", entonces ponemos abajo eso:
		AND LOOKUP_TYPE = 'PAYMENT TYPE' 
		AND LOOKUP_CODE =  ACA.PAYMENT_TYPE_FLAG --Aca obtenemos el Q o B. 
		) --Termina subquery.
		AS TYPE,

	   ACA.BANK_ACCOUNT_NAME            AS BANK_ACCOUNT, 	--SABER: "BANK ACCOUNT" es una palabra reservada... Y muchas mas tambien son reservadas
															--Si pasa esto cuando hagamos la consulta nos va a tirar un error  "FROM keyword not found where expected".
															--Por esto agregamos los "_" para que quede "BANK_ACCOUNT"
	   --Estos 2 que aparecen en el Excel, NO son:
       --ACA.CHECK_STOCK_ID             AS DOCUMENT,
       --ACA.CHECK_NUMBER               AS DOCUMENT_NUM,
	   
       --Son estos 2 que aparecen en la documentacion:
       ACA.DOC_CATEGORY_CODE            AS DOCUMENT,			--Sequential Numbering (voucher number) document category for payment
       ACA.DOC_SEQUENCE_VALUE			AS DOCUMENT_NUM, 		--Voucher number (sequential numbering) for payment
       
	   ACA.CHECK_DATE                   AS PAYMENT_DATE,
       ACA.AMOUNT                     	AS PAYMENT_AMOUNT,
       ACA.CURRENCY_CODE                AS CURR, --Tambien se puede sacar de iby_payments_all.payment_currency_cod
       ACA.VENDOR_NAME                  AS SUPPLIER,  
       ACA.VENDOR_ID                    AS SUPPLIER_NUM,
       --ACA.VENDOR_SITE_CODE           AS SUPPLIER_SITE,
	   PSSA.VENDOR_SITE_CODE 			AS SUPPLIER_SITE, 		--Es lo mismo esta solucion o la de arriba.
	   
       ACA.STATUS_LOOKUP_CODE           AS STATUS,     			--No hay que buscar por lookup aca, simplemente nos trae lo que queremos.   
																--Ver si es igual a iby_payments_all.payment_status (donde estan los status de los pagos), Claudio dijo de sacarlo de ahí.
      
	  --Subquery para country (MEDIANTE lookup, ver abajo de todo pruebas con esto):
       (select MEANING  --Aca esta Argentina, Alemania, Australia, etc..
        from fnd_lookup_values TABLE_LOOKUPS
        where language = 'US' 
        AND TABLE_LOOKUPS.LOOKUP_TYPE = 'HZ_DOMAIN_SUFFIX_LIST' --Tipo que nos dijo Claudio para ponerle.
        AND TABLE_LOOKUPS.LOOKUP_CODE=ACA.COUNTRY   --En LOOKUP_CODE esta AR, AL, AU,etc. y le mandamos lo mismo (lo que tenemos en ACA.COUNTRY)
        )
        AS COUNTRY,
        
        --De esta manera me tira la dirección con los . (ver como sacar los . si no existe la dirección/ciudad/estado,etc.):
       (HZP.ADDRESS1 || '.' || HZP.ADDRESS2 || '.' || HZP.ADDRESS3 || '.' || HZP.ADDRESS4  
       || '.' || HZP.CITY ||'.' ||HZP.STATE || '.' || HZP.POSTAL_CODE  || '.' || HZP.PROVINCE || '.'  || HZP.COUNTY)   
       AS ADDRESS,  -- || es para concatenar y '.' es un punto.
       --Ejemplo: 21004 Norcroft Road....Springfield.Texas.75853.. Y quiero que me tire --> 21004 Norcroft Road . Sprinfield . Texas . 75853
       --(o sea in los . en caso que el campo NO exista): MEJORA MAS ADELANTE. 
	   --Ver DECODE para hacer esto (ver ejemplo 6-Ejemplos decode y como sacar campos en comun entre 2 tablas).
   
       ACA.CURRENCY_CODE       	        AS ACCOUNT_CURRENCY,                                                                      
       ACA.CHECKRUN_NAME             	AS BATCH_NAME,  			--Archivo batch que se ejecuta por lotes (ejecuta una secuencia de cosas). 
	   -- nvl(ACA.BATCH_NAME,iby_pay_service_requests.PROCESS_TYPE) AS BATCH_NAME, --Si no tiene un batch ID debemos mostrar la columna PROCESS_TYPE de la tabla de batch de pagos, la cual es iby_pay_service_requests.
	   --Ver si esta bien la forma de arriba (Claudio)
	   
       ACA.PAYMENT_METHOD_CODE          AS PAYMENT_METHOD,   		--Payment method used to make payment.                                                                  
					  
       --Estos 2 ambos son VENDOR_NAME (tambien lo es SUPPLIER):
       ACA.VENDOR_NAME                  AS REMIT_TO_ACCOUNT,
       ACA.VENDOR_NAME                  AS PAID_TO_NAME,
       
	   ACA.DOC_CATEGORY_CODE            AS DOCUMENT_CATEGORY,  	-- Sequential Numbering (voucher number) document category for payment. Sera un lookup?
       
	   --Estos 3 campos los sacamos de ACA (NO de AIPA)... para que NO nos traigan algunos campos repetidos. 
	   --Si usamos los Exchange de ACA son los pagos con la Tasa del pago; y si usamos los de AIP son los pagos con la Tasa de la factura: consultar con el funcional qué tabla usar dependiendo lo que se quiera hacer.
       ACA.EXCHANGE_RATE_TYPE           AS RATE_TYPE,  				
       --AIPA.EXCHANGE_RATE_TYPE        AS RATE_TYPE, 
	   ACA.EXCHANGE_DATE                AS RATE_DATE,
       --AIPA.EXCHANGE_DATE             AS RATE_DATE,
	   ACA.EXCHANGE_RATE              	AS PAYMENT_RATE,
       --AIPA.EXCHANGE_RATE             AS PAYMENT_RATE,  			
    
	   --Para el funcional amount usamos el campo BASE_AMOUNT... y si es null AMOUNT (NO usamos el campo CLEARED_BASE_AMOUNT). Al parecer el campo CLEARED_BASE_AMOUNT seria por ejemplo si el pago es de 1000 y solo pagaron 800, 800 sería el CLEARED_BASE_AMOUNT.
	   --Por lo general hay 2 campos para montos: el de la moneda original (amount) y el de la moneda funcional (base_amount). El base_amount se carga cuando el mismo es distinto a la moneda de la factura.
	   nvl(ACA.BASE_AMOUNT,ACA.AMOUNT) 	AS FUNCIONAL_AMOUNT,   --Si BASE_AMOUNT es null devuelve amount, y si BASE_AMOUNT NO es null entonces devuelve el mismo.               
	   
	   --Forma 1 de obtener los 2 campos vacios, desde la tabla (ya que nos traen null):
	   ACA.MATURITY_EXCHANGE_RATE_TYPE AS MATURITY_RATE_TYPE,
	   ACA.MATURITY_EXCHANGE_DATE      AS MATURITY_RATE_DATE,
	   --Forma 2, seteandole ' ':
	   --' ' MATURITY_EXCHANGE_RATE_TYPE,
	   --' ' MATURITY_EXCHANGE_DATE_TYPE
		
	   PSUP.VENDOR_TYPE_LOOKUP_CODE 	AS SUPPLIER_CLASIFICATION
	   
	   --Siempre joinear todas las tablas (HZP, PSUP, PSSA y las demas que usemos) con la tabla "principal" (en nuestro caso AP_CHECKS_ALL):
from    AP_CHECKS_ALL                   ACA,  	--ACA es el ALIAS. Tabla de cheques / tabla "principal". 
        HZ_PARTIES                      HZP, 	--Tabla con informacion de los clientes.
        POZ_SUPPLIERS					PSUP,	--Tabla con informacion de los proveedores.
		POZ_SUPPLIER_SITES_ALL_M 		PSSA  	--Table con información de la localizacion de proveedores.

		--NO sirve joinear las tablas si no las mostramos (SOLO JOINEAR SI MOSTRAMOS CAMPOS DE LAS TABLAS!):
			--HZ_LOCATIONS 					HZL,	--Tabla con información de la localizacion, general. 
			--HZ_PARTY_SITES				HZPS	--Table con información de la localizacion de los clientes.
			--AP_INVOICE_PAYMENTS_ALL    	AIPA, 	--Tabla con informacion de los pagos. 
		
--Joineamos en el where (Tambien se podia hacer en el from con innner join tabla on tabla1.campo=tabla2.campo) pero es más largo. Joineamos con la tabla principal (ACA).
where   HZP.PARTY_ID 			    = 	ACA.PARTY_ID   
		AND PSUP.VENDOR_ID 			= 	ACA.VENDOR_ID
		AND PSSA.VENDOR_SITE_ID 	= 	ACA.VENDOR_SITE_ID 
		--El campo VENDOR_SITE_ID NO estaba en la documentacion de docs.Oracle(en FKs de ambas tablas).... 
		--Claudio nos dijo que el campo VENDOR_SITE_ID pertenecía a ambas tablas y con este podíamos Joinear (y confiamos en él)... 
		--Pero para CORROBORAR cuales son los campos con los que podemos joinear hacemos la consulta: Ver Ejemplo 2 en "6-Ejemplos Decode y CampoAJoinear.sql".

		--Al final NO joineamos estas tablas (ya que no traemos ningún campo de las mismas --> (SOLO JOINEAR SI MOSTRAMOS CAMPOS DE LAS TABLAS!):
		--AND HZL.LOCATION_ID 		= 	HZPS.LOCATION_ID
		--AND PSSA.party_site_id 	= 	HZPS.party_site_id
		--AND PSSA.VENDOR_ID 		= 	PSUP.VENDOR_ID --Es lo mismo dejarla o sacarlo. 
		--AND AIPA.CHECK_ID 		= 	ACA.CHECK_ID
		
		--Parametros:
		AND ACA.CHECK_DATE BETWEEN :START_DATE AND :END_DATE
		AND ACA.ORG_ID = :BUSINESS_UNIT