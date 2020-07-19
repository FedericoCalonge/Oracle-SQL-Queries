--Hacemos 2 querys: 
	--1- Para sacar los datos de la cabecera - info de la entidad legal (NO necesitan funciones de agregación).
	--2- Para sacar los datos de la tabla - detalles de la factura (NECESITAN funciones de agregación y un GROUP BY).

--Esta es la query para 1-:

--La anterior query (DMVentasCabeceraMAL.sql) estaba MAL ya que:
	--1-Me traía VARIOS registros... y es muy poco optimo. Me tiene que devolver solo 1 registro.
	--2-NO TENIAMOS QUE USAR LA TABLA RCTA DE CABECERAS, ya que la info de los años y meses es mejor sacarlo el periodo que te ingresan como parametro.

SELECT 	
		--Subquerys para traer la fecha, el año y el mes (todo esto lo sacamos de la tabla GLP de periodos):
		
		(SELECT EXTRACT(YEAR FROM GLP.START_DATE) --Obtenemos el año de GLP.START_DATE (o sea que depende del periodo que seleccionemos en el parametro). 	 
		FROM 	gl_periods 			GLP,
				GL_LEDGERS			GL
		--Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
		--Entonces filtramos por el periodo del libro y el libro:
		WHERE 	period_name 		 			= :P_PERIOD_NAME  			--Parametro.
				AND GL.ledger_id        		= :P_LEDGER_ID				--Parametro.
				AND GLP.PERIOD_SET_NAME  		= GL.PERIOD_SET_NAME		--JOIN para asociar GL a GLP. 
		)
		AS YEAR,

		
		--Mes forma 1 (en el RTF le ponemos el formato para sacar directamente el nombre del mes dada la fecha):
		(select add_months(TRUNC(GLP.START_DATE),+1)  	--Agregamos 1 mes mas... ya que en la salida del reporte nose porque dá 1 mes menos al que ponemos en el periodo. 
				--TRUNC(GLP.START_DATE)					--Trunc para poner las horas en 00.						
		FROM 	gl_periods 			GLP,
				GL_LEDGERS			GL
		--Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
		--Entonces filtramos por el periodo del libro y el libro:
		WHERE 	period_name 		 			= :P_PERIOD_NAME  			--Parametro.
				AND GL.ledger_id        		= :P_LEDGER_ID				--Parametro.
				AND GLP.PERIOD_SET_NAME  		= GL.PERIOD_SET_NAME		--JOIN para asociar GL a GLP. 
		) 
		AS Fecha_Nombre_Mes_Forma_1,  		
		
		--Mes forma 2, el problema es que si está en inglés tenemos que acá cambiar los meses a inglés. 
		--Lo hacemos con decode: Compara el valor de un campo (en este caso estamos comparando Num_Dia con 1,2,3,4,5,6,7.
		--Y devuelve un valor seteado (en nuestro caso "Lunes" para 1, .... "Domingo" para 7). 
		--Y sino, devuelve un default (en nuestro caso "Dia fuera de rango")
		(	select  DECODE
					(  
					TO_CHAR(GLP.START_DATE, 'Month'),
					1, 'Enero',
					2, 'Febrero',
					3, 'Marzo',
					4, 'Abril',
					5, 'Mayo',
					6, 'Junio',
					7, 'Julio',
					8, 'Agosto',
					9, 'Septiembre',
					10, 'Octubre',
					11, 'Noviembre',
					12, 'Diciembre',
						'Mes Fuera Rango'
					)
			FROM 	gl_periods 			GLP,
					GL_LEDGERS			GL
			--Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
			--Entonces filtramos por el periodo del libro y el libro:
			WHERE 	period_name 		 			= :P_PERIOD_NAME  			--Parametro.
					AND GL.ledger_id        		= :P_LEDGER_ID				--Parametro.
					AND GLP.PERIOD_SET_NAME  		= GL.PERIOD_SET_NAME		--JOIN para asociar GL a GLP. 
		)
		AS Nombre_Mes_Forma_2,
		
		--Subquery para traer el nombre del BU:
		(	select  	name  												
			from 		HR_ORGANIZATION_UNITS
			where  		ORGANIZATION_ID = :P_BU
		)
		AS BU_Name, 	--Business Unit (seria la "Sucursal" que aparece al lado de la Entidad Legal). 	
		
		XEP.name											AS Entidad_Legal_Name,
		XEP.legal_entity_identifier							AS NIT_Entidad_Legal 		--Sino tambien lo podemos sacar de HZ_PARTYS.... nvl(HZP.JGZZ_FISCAL_CODE,0) pero tendriamos que joiner la tabla.
		
FROM   XLE_ENTITY_PROFILES 				XEP		
		
WHERE   --NO ponemos ningún join ya que solo usamos la tabla XEP y las otras tablas de donde sacamos info son de subquerys. 
		--Parametros: 
		XEP.legal_entity_id = :P_ENTIDAD_LEGAL_ID
			
--VER-HACER despues como diferenciar factura, de nota de debito, de credito, etc. 