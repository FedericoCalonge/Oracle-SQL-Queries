--Ejemplo 1-Decode:
--Formato Decode:
	--decode(1,2,3,4):
			-- 1 Campo a evaluar.
			-- 2 Condicion.
			-- 3 Lo que muestra en caso que la condicion sea true para el campo.
			-- 4 Lo que muestra en caso que la condicion sea false para el campo.
			--> SABER: podemos CONCATENAR varias condiciones (Ver 2do ejemplo).

	--1er ejemplo: 
	--decode(HZP.ADDRESS1, null, null, '.') --
		   decode(HZP.ADDRESS1, null, null, '.')
		   
	--2do ejemplo: concatenamos varias condiciones:	
		decode(ACA.PAYMENT_METHOD_CODE
				  ,'CHECK','Cheque'
				  ,'EFT', 'Efectivo'
				  , 'Default')
		--De esta manera evaluamos el campo PAYMENT_METHOD_CODE... si es CHECK nos mostraria 'Cheque', si es EFT nos mostraria 'Efectivo' y si no es ninguna de 
		--las dos nos mostraría 'Default'.

--Ejemplo 2- CampoAJoinear - Para sacar campos en comun entre 2 tablas (esto nos sirve cuando no sabemos como joinear tablas y en la documentacion, en FKs, NO aparecen los campos en común).
	--Por ejemplo abajo vamos a corroborar esto que VENDOR_SITE_ID es un campo en común para las tablas POZ_SUPPLIER_SITES_ALL_M y AP_CHECKS_ALL.
	--De esta manera, asi podemos obtener los campos posibles para hacer join en ambas tablas.
	--La tabla ALL_TAB_COLUMNS (ver documentación docs.oracle) contiene info de todas las tablas.... los campos que tienen importantes son:
	--TABLE_NAME --> indica el nombre de la tabla. 
	--COLUMN_NAME	--> indica el nombre de la columna (campo) de la TABLE_NAME.
	--DATA_TYPE	VARCHAR2(106) --> indica el tipo de dato de la columna COLUMN_NAME
	--Y demás datos de dichas COLUMN_NAME.

	--Queremos ver los campos en comun entre POZ_SUPPLIER_SITES_ALL_M y AP_CHECKS_ALL. Con intersect nos trae solo la columna de las 2 tablas (intersección);
		select COLUMN_NAME
		from ALL_TAB_COLUMNS
		where TABLE_NAME='POZ_SUPPLIER_SITES_ALL_M'
		intersect 
		select COLUMN_NAME
		from ALL_TAB_COLUMNS
		where TABLE_NAME='AP_CHECKS_ALL'
	--NO PRESTARLE ATENCION A LOS CAMPOS ATTRIBUTES O GLOBAL_ATTRIBUTES, LOS OTROS SON LOS CAMPOS IMPORTANTES POR LOS QUE JOINEAN (	PARTY_SITE_ID, REQUEST_ID, VENDOR_ID, VENDOR_SITE_CODE, VENDOR_SITE_ID)
	

