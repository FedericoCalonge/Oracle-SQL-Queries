--Hacemos 2 querys: 
	--1- Para sacar los datos de la cabecera - info de la entidad legal (NO necesitan funciones de agregación).
	--2- Para sacar los datos de la tabla - detalles de la factura (NECESITAN funciones de agregación y un GROUP BY).

--Esta es la query para 2-:

SELECT
		EXTRACT(DAY FROM RCTA.TRX_DATE)						AS Num_Dia,  	--Número del 1 al 31. 
		TO_CHAR(RCTA.TRX_DATE, 'Day')						AS Nombre_dia,  --NO FUNCIONA de esta forma para obtener el nombre del mes... Pero nos da
																			--un numero Del 1 al 7 (donde 1 es lunes y 7 es domingo).
		
		--Nombres del dia:
		--Opcion 1 (en el RTF le ponemos el formato para sacar directamente el nombre del dia dada la fecha):
		--TRUNC(RCTA.TRX_DATE)								AS Nombre_Dia_Forma_1,	--Trunc para poner las horas en 00.
		--NO me funciono la de arriba, no encontre ningun formato que me traiga el nombre del dia.
		  
		--Opcion 2 - con DECODE: Compara el valor de un campo (en este caso estamos comparando Num_Dia con 1,2,3,4,5,6,7.
			--Y devuelve un valor seteado (en nuestro caso "Lunes" para 1, .... "Domingo" para 7). 
			--Y sino, devuelve un default (en nuestro caso "Dia fuera de rango")
			DECODE(  
					TO_CHAR(RCTA.TRX_DATE, 'Day'), 
					1, 'Lunes',
					2, 'Martes',
					3, 'Miercoles',
					4, 'Jueves',
					5, 'Viernes',
					6, 'Sabado',
					7, 'Domingo',
						'Dia Fuera Rango') 					AS Nombre_Dia_Forma_2,
					
		--Estos 2 de abajo es el 1er y ultimo numero de factura de un dia determinado:
		MIN(RCTA.TRX_NUMBER)  								AS From_Number,  	--Es la 1er factura / factura desde (dada la condicion where que filtre las facturas en un periodo correspondiente).
		MAX(RCTA.TRX_NUMBER)								AS To_Number,		--Es la última factura / factura hasta (dada la condicion where que filtre las facturas en un periodo correspondiente).
		
		--Vemos los NUMEROS de facturas y de lineas:
		--Cada vez que se carga una linea de una factura en RCTA se llena el campo CUSTOMER_TRX_ID y mientras la linea sea la misma este campo es el mismo.
		--Entonces, contando estos campos obtenemos el N° total de lineas; y con los distincts (agrupamos los que tienen el mismo numero) obtenemos el N° total de facturas. 
		COUNT(DISTINCT RCTA.CUSTOMER_TRX_ID)   				AS Numero_Total_Facturas, 																
		COUNT(RCTA.CUSTOMER_TRX_ID)                 		AS Numero_Total_Lines, 		
		
		--Ahora vemos los MONTOS de facturas y de lineas: 
		SUM(RCTLA.EXTENDED_AMOUNT)                  		AS Total_Lines, 		--El monto de transaccion de cada linea. 			Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).  
		SUM(ZXL.TAX_AMT)                                 	AS Taxable_Impuestos,	--Monto impuestos de cada linea.  					Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).  
		(SUM(RCTLA.EXTENDED_AMOUNT) + SUM(ZXL.TAX_AMT))  	AS Sales_Total,			--Monto impuestos + transaccion de cada linea. 		Al hacer el SUM obtenemos el de TODAS las lineas (el de la factura).  
			
		--HACER:
		--Forma 2 de obtener el monto total de la factura: 
		--Con estos filtros RCTLGDA nos trae 1 solo registro con el monto total de la factura:
        --RCTLGDA.LATEST_REC_FLAG = 'Y'
        --RCTLGDA.ACCOUNT_CLASS = 'REC'
		-- AS Sales_Total2_2
        
		FCVL.DESCRIPTION 									AS Amount_In,  				--Es la moneda (USD por ejemplo). 
		FCVL.SYMBOL 										AS Simbolo_Moneda 			--Lo agregamos a cada monto de la tabla. 
		
		--RCTA.SET_OF_BOOKS_ID								AS RCTA_LEDGER_ID,
		--GL.LEDGER_ID										AS GL_LEDGER_ID
        --RCTTA.name										AS Tipo_Transaccion 
		
		--Y por último linea totalizadora sumando los últimos 3!.
		
FROM    RA_CUSTOMER_TRX_ALL 			RCTA, 		--Cabeceras.
		--RA_CUST_TRX_TYPES_ALL 	 	RCTTA, 		--Tipo de transacción.
		RA_CUSTOMER_TRX_LINES_ALL		RCTLA, 		--Líneas.
		--RA_CUST_TRX_LINE_GL_DIST_ALL	RCTLGDA, 	--Distribuciones. Detalles de los impuestos y monto total de la factura. 
		ZX_LINES						ZXL, 		--Líneas de CADA factura. Acá tenemos también los impuestos aplicados a CADA línea. 
		FND_CURRENCIES_VL				FCVL,		--Monedas.
		GL_LEDGERS						GL			--Libro contable (Ledger). Solo lo uso para mostrar el campo GL_LEDGER_ID, no es necesario, era solo para saber si era la misma ID que el campo RCTA_LEDGER_ID. 
		
WHERE
		--Joins:
		--RCTA.CUST_TRX_TYPE_SEQ_ID 			= RCTTA.CUST_TRX_TYPE_SEQ_ID
		RCTA.CUSTOMER_TRX_ID 					= RCTLA.CUSTOMER_TRX_ID 
		--AND RCTA.CUSTOMER_TRX_ID				= RCTLGDA.CUSTOMER_TRX_ID 
		AND RCTA.SET_OF_BOOKS_ID				= GL.LEDGER_ID
		AND RCTA.INVOICE_CURRENCY_CODE 			= FCVL.CURRENCY_CODE 
		
		--Con ZX_LINES:
		AND RCTLA.CUSTOMER_TRX_ID      			= ZXL.TRX_ID
		AND RCTLA.CUSTOMER_TRX_LINE_ID     		= ZXL.TRX_LINE_ID
 
        --Parametros: 
		
		--1-Periodo(por ej. Ene-19): ...
		
			--"Con estos parámetros, para el periodo 'ENE19' el reporte debe traer todas las facturas generadas 
			--entre el 01-01-2019 al 31-01-2019". Entonces acá filtramos esto:
			
			--1- Filtramos que la fecha de la factura sea mayor o igual a la fecha de INICIO del periodo:
			AND TRUNC(RCTA.TRX_DATE) >=  	(SELECT TRUNC(GLP.START_DATE)   	--START_DATE y TRX_DATE estan en formato 2019-11-29T22:00:00.000-02:00...
																			--Al ponerles trunc solo reiniciamos lo de las horas, min y seg a 00 todo.
																			--Podemos sino usar TO_CHAR para transformar ambas fechas al formato DD/MM/YYYY y luego compararlas, pero es lo mismo --> TO_CHAR(:START_DATE,'DD/MM/YYYY')
											FROM 	gl_periods 			GLP,
													GL_LEDGERS			GL
											WHERE 	period_name 		 			= :P_PERIOD_NAME  			--Parametro.
													--Tambien hay que filtrar por el libro (LEDGER) y por periodo (YA QUE ME TIENE QUE TRAER 1 REGISTRO la subquery); y así sacamos el START_DATE de ese y hacemos la comparación de arriba): 
													AND GL.ledger_id        		= :P_LEDGER_ID				--Parametro.
													AND GLP.PERIOD_SET_NAME  		= GL.PERIOD_SET_NAME		--JOIN para asociar GL a GLP. 	
											)
								
			--2- Filtramos que la fecha de la factura sea mayor o igual a la fecha de FIN del periodo:
			AND TRUNC(RCTA.TRX_DATE) <=  	(SELECT TRUNC(GLP.END_DATE)
											FROM 	gl_periods 			GLP,
													GL_LEDGERS			GL
											WHERE 	GLP.period_name 		 		= :P_PERIOD_NAME 			--Parametro.
													--Tambien hay que filtrar por el libro (LEDGER) y por periodo (YA QUE ME TIENE QUE TRAER 1 REGISTRO la subquery); y así sacamos el START_DATE de ese y hacemos la comparación de arriba):
													AND GL.ledger_id        		= :P_LEDGER_ID				--Parametro.
													AND GLP.PERIOD_SET_NAME  		= GL.PERIOD_SET_NAME		--JOIN para asociar GL a GLP. 
											)
				
		--2-BU:
			AND RCTA.ORG_ID 				= :P_BU						--El parametro UNIDAD_NEGOCIO es una ID. Pero lo que se muestra en el reporte son los name (query que hacemos en Cloud)
	
		--3-Entidad legal: ....
			AND RCTA.LEGAL_ENTITY_ID 		= :P_ENTIDAD_LEGAL_ID		--El parametro ENTIDAD_LEGAL_ID es una ID. Pero lo que se muestra en el reporte son los name (query que hacemos en Cloud)
		
		--4-Ledger:
			AND RCTA.SET_OF_BOOKS_ID        = :P_LEDGER_ID
		
--"La información debe estar agrupadas por día trayendo el primer y 
--último número de factura y sus montos". Además, como usamos en el select principal 
--funciones de agrupamiento (count, sum, max, min)... SI O SI tenemos que agrupar!
GROUP BY 	EXTRACT(DAY  FROM RCTA.TRX_DATE),--Agrupamos por día
			--Y aparte agrupamos por descripcion y simbolo de la moneda (por esto en NOV-19 por ej. se nos repiten 2 28s en dia, ya que 1 dia corresponde
			--a moneda USD y otra en pesos argentinos). 
			FCVL.DESCRIPTION,
			FCVL.SYMBOL,
			--Y tambien agrupamos por nombre de transacción (si lo necesitamos):
			--RCTTA.name
			TO_CHAR(RCTA.TRX_DATE, 'Day'),
			TRUNC(RCTA.TRX_DATE),
			DECODE(  
					TO_CHAR(RCTA.TRX_DATE, 'Day'), 
					1, 'Lunes',
					2, 'Martes',
					3, 'Miercoles',
					4, 'Jueves',
					5, 'Viernes',
					6, 'Sabado',
					7, 'Domingo',
						'Dia Fuera Rango')
			--RCTA.SET_OF_BOOKS_ID
			
			--GL.LEDGER_ID	
			--SABER: Tenemos que poner todo el codigo en el group by envés de solo poner el alias porque en Oracle se ejecuta primero el group by y después el select. Se podía en MySQL nomas. 
			
ORDER BY 	EXTRACT( DAY  FROM RCTA.TRX_DATE) ASC,
			FCVL.DESCRIPTION ASC
			 
--Ver despues como diferenciar factura, de nota de debito , de credito, etc. 