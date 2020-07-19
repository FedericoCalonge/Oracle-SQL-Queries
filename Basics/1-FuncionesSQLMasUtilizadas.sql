--Saber: 
	--1- Son pruebas hechas para distintas funciones SQL: TRIM,  NVL, SUBSTR, INSTR, DECODE, (UPPER, LOWER, INITCAP),  TO_CHAR, TO_DATE, LENGTH, MAX, MIN, SUM, COUNT, AVG, DISTINCT, TRANSLATE, REPLACE, (TRUNC, ABS, ROUND, GREATEST), (ROWNUM, HAVING), operadores LIKE, IN e ISNULL, funciones para FECHAS. 	
	--2- Se usó SQL Developer para las pruebas utilizando la tabla de la BD de pruebas 'dual' y la tabla 'AP_CHECKS_ALL' para algunos casos más específicos. Esta tabla almacena informacion de pagos hechos o recividos a/de proveedores (suppliers).
	--3- A la derecha de los alias de los campos en el select (los "AS campo") coloqué la salida obtenida con SQL Developer.
	--4- Basándome en: http://psoug.org/reference/string_func.html y https://docs.oracle.com/cd/B19306_01/server.102/b14200/

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--1-TRIM: Quita caracteres de inicio y fin de los Strings o los espacios en blancos de inicio o fin. 
        --TRIM( [ [ LEADING | TRAILING | BOTH ] trim_character FROM ] string1 )
        --Si no ponemos el [] de arriba nos quedaría solo TRIM (String1) y esto elimina los spaces de inicio y fin del String1.
        --Por ej. si tenemos "   Fede Calong " nos va a devolver "Fede Calong" - NO sirve para eliminar los espacios entre Strings, solo antes y después. Para esto usamos 16-REPLACE
        --Parametros si ponemos el []:
            --1- 
                --1.A-Si ponemos LEADING borrará el trim_character al INICIO del String (por ej. Si el String es "Alejo" y ponemos 
                    --trim_character "A", entonces nos devuelve "lejo").
                --1.B-Si ponemos TRAILING nos borra el caracter al FIN del String.                
                --1.C-Si ponemos BOTH nos borra ambos caracteres (inicio y fin).
	select 	'       Hola Pepe    '                 AS HolaPepe,         	--       Hola Pepe    
			TRIM('       Hola Pepe    ')           AS HolaPepeTrim,     	--Hola Pepe
			TRIM(LEADING 'a' from 'antonia')       AS Example_Trim_1,   	--ntonia
			TRIM(TRAILING 'a' from 'antonia')      AS Example_Trim_2,   	--antoni
			TRIM(BOTH 'A' FROM 'ANTONIA')          AS Example_Trim3,    	--NTONI
			--Ejemplos tabla AP_CHECKS_ALL:
			VENDOR_NAME 		                	AS Vendor_Name,         --Advanced Network Devices
			TRIM(BOTH 'A' from VENDOR_NAME) 		AS Vendor_Name_Trim_A,  --dvanced Network Devices (solo borra la A inicial porque A final no tiene).
			TRIM(VENDOR_NAME) 	                	AS Vendor_Name_Trim     --Advanced Network Devices - Devuelve lo mismo ya que no hay espacios al inicio o fin (solo entre las palabras). 
			from AP_CHECKS_ALL;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--2-NVL: Si el 1er parametro es null (BANK_ACCOUNT_NAME), nos trae el 2do parametro (VENDOR_NAME).
	select 	BANK_ACCOUNT_NAME 					AS Bank_Account_Name,
			VENDOR_NAME							AS Vendor_Name,
			NVL(BANK_ACCOUNT_NAME,VENDOR_NAME) 	AS NVL_Vendor
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--3-SUBSTR: Corta un string (1er parametro) desde el comienzo seteado (2do paraemtro - "1") hasta el final seteado (3er parametro - "4").
	select 	VENDOR_NAME 			AS Vendor_Name,       --Advanced Network Devices
			SUBSTR(VENDOR_NAME,1,4) AS Substr_Vendor_Name --Adva 
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--4-INSTR. Devueve la POSICION de un String o Char (2do parametro) dentro de otro String (1er parametro). 
		--Parametros:
		--1-String donde buscar.
		--2-String o caracter a buscar en 1.
		--3-Comienzo de busqueda.
		--4-Ocurrencia. 

	select 	--Abajo buscamos en el string "CORPORATE FLOOR", comenzando por el 3er caracter (osea por R) ("3") al String "OR". 
			--Y retorna la posición de inicio de dicho string ("OR") en su 2da ocurrencia ("2").
			--Y si no está dicho caracter buscado entonces devuelve 0. 
			INSTR('CORPORATE FLOOR','OR', 3, 2) 	AS Ejemplo_Corporate,       --Devuelve 14, osea la posicion de la O del 3er OR (BIEN).
			VENDOR_NAME 							AS Vendor_Name,             --Bailey, Sara
			INSTR(VENDOR_NAME,',',1,1) 				AS Posicion_1ra_Coma,       --7 (Empieza a contar en 1, NO en 0).
			INSTR(VENDOR_NAME,'a',5,2)				AS Pos_2da_A_Desde_5ta_Pos  --12 (la última a).
	from AP_CHECKS_ALL
	;	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--5-DECODE: Compara el valor de un campo (en este caso estamos comparando VENDOR_ID con 723, 724, 725 y 726.
			--Y devuelve un valor seteado (en nuestro caso "Kingston Max" para 723, "Gaston Platania" para 724, etc.). 
			--Y sino, devuelve un default (en nuestro caso "No encontrado")
	select  VENDOR_ID                           AS Vendor_ID,
			DECODE(  
					VENDOR_ID,
					21, 'Kingston Max',
					334, 'Gaston Platania',
					12, 'Federico Calonge',
					22, 'Federico Enrrique',
						'No encontrado') 		AS Vendor
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--6-UPPER, LOWER, INITCAP: Pasa a mayusculas, minusculas o capitalizado (1ra letra en mayuscula, resto minuscula) un String.
	select 	VENDOR_NAME				AS Vendor_Name,            		--GE Plastics
			UPPER(VENDOR_NAME) 		AS Vendor_Name_Mayuscula,    	--GE PLASTICS
			LOWER(VENDOR_NAME) 		AS Vendor_Name_Minuscula,    	--ge plastics
			INITCAP(VENDOR_NAME)	AS Vendor_Name_Capitalizado		--Ge Plastics
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--7-LENGTH: Devuelve la cantidad de caracteres / longitud del String.
	select 	VENDOR_NAME					AS Vendor_Name,     --GE Capital
			LENGTH(VENDOR_NAME) 		AS Tamaño_Vendor    --10
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--8-TO_CHAR: Convierte(castea) a caracteres un campo (1er parametro). Se pueden dar valores para setear en el 2do parametro (en nuestro caso una fecha). 
	select 	CHECK_DATE								AS CHECK_DATE,          --07/01/1996
			TO_CHAR(CHECK_DATE	,'DD-MON-YYYY')	    AS CHECK_DATE_TO_CHAR   --07-ENE-1996
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--9-TO_DATE: Convierte(castea) un String (1er paraemtro) con el formato del 2do parametro a una fecha DATE (DD/MM/AAAA).
	select 	
			TO_DATE('Enero 15, 2019','Month dd, YYYY') AS Date_Cast --Devuelve 15/01/2019.
	from dual --BD De pruebas.
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--10-Funciones de agregación (MAX, MIN, SUM, COUNT, AVG).

--MAX. Busca el maximo valor de un campo de una tabla.
	select 	--VENDOR_ID					AS Vendor_ID, --NO, esta linea no, sino tendría que poner un group by!.
			MAX(VENDOR_ID) 				AS Max_Vendor_ID  --188184
	from AP_CHECKS_ALL
	;

--MIN. Devuelve el minimo valor de un campo de una tabla
	select 	--VENDOR_ID					AS Vendor_ID, --NO, esta linea no, sino tendría que poner un group by!.
			MIN(VENDOR_ID) 				AS Min_Vendor_ID  --1
	from AP_CHECKS_ALL
	;

--SUM. Vamos a sumar todos los VENDOR_ID...
	select 	SUM(VENDOR_ID) 			    AS Sum_Vendors_IDs  --47901880
	from AP_CHECKS_ALL
	;

--COUNT cuenta la cantidad de registros que devuelve la consulta. Vamos a contar un campo especifico.
	select 	COUNT(VENDOR_ID) 			AS Count_Vendors_IDs --25876
	from AP_CHECKS_ALL
	;

--AVG: promedio (es un SUM / COUNT).  
	select 	AVG(VENDOR_ID) 			    AS Sum_Vendors_IDs  --1851
	from AP_CHECKS_ALL
	;

--FALTA HACER rejunte de todas las Funciones de agregación y uso de group by (el group by lo usamos si además de las funciones de agregación que ponemos tambien queremos poner algún campo). 

	/*
	SELECT  COUNT(*) AS TotalFilas, 
			COUNT(ShipRegion) AS FilasNoNulas,
			MIN(ShippedDate) AS FechaMin, 
			MAX(ShippedDate) AS FechaMax, 
			SUM(Freight) AS PesoTotal, 
			AVG(Freight) PesoPromedio
	FROM Orders
	*/

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--11-DISTINCT: Agrupa todos los registros con el mismo valor, solo trae el "distinto". Están comentados los demás porque sino tendría que hacer un group by.
	select  --COUNT(VENDOR_ID)              --25876.
			DISTINCT(VENDOR_ID) 		    --Me trae los 290 Vendor_ID. IDs SIN repetir. 
			--COUNT(DISTINCT(VENDOR_ID) )   --290.
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--12-TRASLATE: Traduce las coincidencias de un string a otro seteado por nosotros. Puede coincidir toda la palabra o solo letras de la palabra. 
	select 	VENDOR_NAME							AS Vendor_Name,             --Advanced Network Devices
			TRANSLATE(VENDOR_NAME,'ce','123') 	AS Vendor_Name_Traslated,   --Advan12d N2twork D2vi12s
			TRANSLATE('1tech23', '123', '456')  AS Example                  --4tech56
	from AP_CHECKS_ALL
	; 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--13-REPLACE: Permite reemplazar un caracter en un String. Por ej. abajo hacemos un replace para reemplazar los espacios por NULL, asi se unen las palabras para el campo vendor_name.
	--Por ejemplo así reemplazamos la T por la M: REPLACE('SQL Tutorial', 'T', 'M'); 
	select 	VENDOR_NAME							AS Vendor_Name,   		--Advanced Network Devices
			REPLACE(VENDOR_NAME,' ','')     	AS Vendor_Name_Replaced --AdvancedNetworkDevices
	from AP_CHECKS_ALL
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--14-TRUNC, ABS, ROUND, GREATEST:
	select  abs(-2), 			--retorna el absoluto, 2.
			trunc(123.25, 1), 	--Lo truncamos a 1 decimal, 123,2. 
			greatest(5,4,10,2), --El valor más grande, 10.
			round(12.543) --Redondea para arriba o abajo y saca los decimales, 13.
	from dual; --BD Pruebas.
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--15- Clausulas ROWNUM y HAVING:
--SABER IMPORTANTE: LIMIT Y TOP SE USAN EN MYSQL, EN ORACLE NO! PARA ESTO USAMOS EN EL WHERE "ROWNUM < 2" POR EJ. PARA LIMITAR A LAS 2 PRIMERAS COLUMNAS.
                    --Having count SI se usa aca.

--15.1-Ejemplo con ROWNUM:

    --Si queremos obtener los 3 con mayor ID (si queremos los 3 con menor ponemos asc enves de desc):
   select *
   from (  --Subquery para obtener todos los VENDOR_ID ordenados de mayor a menor, DISTINTOS y NO NULOS:
        select distinct VENDOR_ID
        from AP_CHECKS_ALL 
        where VENDOR_ID is not null --Porque hay IDs nulos, para sacarlos. 
        order by Vendor_ID desc
        )
    --Y ahora en el select principal limitamos los registros a 3.
    where ROWNUM<=3
	;
    
--15.2-Ejemplo con Having: 

	--Este es un ejemplo de uso SIN USAR TABLAS REALES:
	--Listamos conductores con mayor cantidad de infracciones:
	--La info la sacamos dde 2 tablas (por eso en el where igualamos los 2 pks de las 2 tablas.

	select  INFO.num_licencia,
			LICENCIA.apellido_conductor,
			LICENCIA.nombre_conductor,
			COUNT(*) as CANTIDAD --Ya que por cada registro es una infracción. 
	from 	INFO,
			LICENCIA
	where   ROWNUM<=5  --Es el LIMIT de MySQL (obtenemos los 5 mayores infractores). Si fuera 1 sería el MAYOR.
			AND INFO.num_licencia = LICENCIA.num_licencia
	group by    --Agrupamos por los 3 campos del select...
			INFO.num_licencia, 
			LICENCIA.apellido_conductor, 
			LICENCIA.nombre_conductor}
			--Y ademas agregamos este having:
			having count(*)>=5 --Con 5 o más infracciones.             
	order by CANTIDAD desc --ordenados de + a - cantidad de infracciones.
	--Ver si se pueden reemplazar los count(*) por el alias que puse antes (CANTIDAD).
	;

--USANDO TABLAS REALES:  
  --HACER.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--16- Operadores LIKE, IN, IS NULL:

--16.1-LIKE:

	--Ejemplo SIN USAR TABLAS REALES:
	--Me devuelve todos los nombres como Perez, Pereira, PereH, etc. por el comodón (%):
	select nombre 		
	from Persona 
	where apellido like 'Pere%'     
	;
	
	--Ejemplo SIN USAR TABLAS REALES:
	--Me devuelve todos los nombres como Celia, Felia (NO Cecilia ni Ofelia porque solo puse 2 '_ _')
	select nombre 		
	from Persona 
	where apellido like '__lia'     
	;
	
--16.2-IN:
	--Ejemplo SIN USAR TABLAS REALES:
	select nombre 		
	from Persona 
	where apellido in ('Perez', 'Ruiz')  --IN me permite seleccionar múltiples valores. Si pondria un "=" solo me permite seleccionar 1 valor. 

	--Ejemplo SIN USAR TABLAS REALES:
		--Ahora usamos '=' enves de IN:
	select nombre 		
	from Persona 
	where apellido = 'Perez' or apellido = 'Ruiz'  --"=" solo me permite seleccionar 1 valor, por eso ponemos un or para más de 1 valor. Aunque lo más eficiente es como arriba usando IN. 
	;
	
--16.3-IS NULL: lo usamos acá para que... si es null la cantidad, se multiplica el precio por 0:
	--Ejemplo SIN USAR TABLAS REALES:
	select    Persona.legajo as legajo,
			  persona.precioalgo * (is null (cant_certificados,0)) as precio
	from persona
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--17-Funciones con Fechas:

	--17.1-Para obtener el NOMBRE del día y del mes:
	select 	to_char(date'1996-04-01', 'DAY')     AS Dia_Nombre_Completo, --LUNES
			to_char(date'1996-04-01', 'DY')      AS Dia_Abreviacion,     --LUN
			to_char(date'1996-04-01', 'D')       AS Dia_De_La_Semana,    --1 (1-Lunes, 2-Martes,...)
			to_char(date'1996-04-01', 'Month')   AS Mes_Nombre_Completo, --Abril
			to_char(date'1996-04-01', 'MON')     AS Mes_Abreviacion     --ABR
			
			--Con una fecha cualquiera:
			CHECK_DATE							AS Fecha,
			to_char(CHECK_DATE, 'DAY')     AS Dia_Nombre_Completo --LUNES 
			
	from   AP_CHECKS_ALL
	;

	--17.2-To_date, trunc, restar y sumar dias/meses/años, to_char:
	select  --TO_DATE devuelve una fecha (en formato date: DD/MM/AAAA), conviertiendo un string (1er parametro) en dicha fecha date, en el formato especificado en el 2do parametro.
			-- Sintaxis: TO_DATE(string1, formato_mascara, nls_language).  -- nls_language es opcional, casi nunca lo usamos.
			TO_DATE('2003/07/09', 'yyyy/mm/dd')                     		AS DATE1, 		--Devuelve 09/07/2003
			TO_DATE('2003/07/09 23:30:25', 'YYYY/MM/DD HH24:MI:SS') 		AS DATE2, 		--Devuelve 09/07/2003. --HH24 para que me tome las 23 hs.
			TO_DATE('070903', 'MMDDYY')                             		AS DATE3, 		--Devuelve 09/07/2003
			TO_DATE('09-JUL-2003','DD-MON-YYYY')                    		AS DATE4, 		--Devuelve 09/07/2003
			
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
			--TRUNC(DATE) devuelve una fecha (en formato date: DD/MM/AAAA), la cual es la la fecha (del 1er parametro) truncada a la unidad especifica por el formato (del 2do parametro). 
			-- Sintaxis: TRUNC(date, format).
			--Si se omite el formato se trunca al dia mas cercano (o si ponemos 'DD', es lo mismo): TRUNC_DATE3 y TRUNC_DATE4.
			--Si el formato es 'D' nos trunca al día de inicio de la semana: TRUNC_DATE5
			--Si el formato es 'YYYY' se trunca abajo dependiendo del dia del año (día y mes 1), deja el año igual): TRUNC_DATE.
			--Si es formato es 'MM' se trunca abajo dependiendo del dia del mes (día 1, deja el mes y año igual): TRUNC_DATE2.
			--Ver los format models (2do paraemtro) de acá: https://www.w3resource.com/oracle/datetime-functions/oracle-trunc(date)-function.php
			
			TRUNC(TO_DATE('27-OCT-1992','DD-MM-YYYY'), 'YYYY')              AS TRUNC_DATE,   --Devuelve 01/01/1992
			TRUNC(TO_DATE('27-OCT-1992','DD-MM-YYYY'), 'MM')                AS TRUNC_DATE2,  --Devuelve 01/10/1992
			
			TRUNC(TO_DATE('21-NOV-2019','DD-MM-YYYY'))                      AS TRUNC_DATE3,  --Devuelve 21/11/1992, lo mismo.
			TRUNC(TO_DATE('21-NOV-2019','DD-MM-YYYY'), 'DD')                AS TRUNC_DATE4,  --Devuelve 21/11/1992, lo mismo.
			TRUNC(TO_DATE('21-NOV-2019','DD-MM-YYYY'), 'D')                 AS TRUNC_DATE5,  --Devuelve 18/11/1992, ya que...
																							 --El 21 NOV de 2019 fue Jueves, asi que el día inicial de la semana (lunes) fue el 18 NOV.
			
			sysdate                                                         AS Sys_Date,
			TRUNC(sysdate)                                                  AS TRUNC_Sys_Date,
			--VER QueryTestDates.sql (7-eText y diseños/eText/2-Ejercicio para entregar) para ver ejemplos de uso de TRUNC (lo use para reiniciar las horas, min y seg así puedo comprar 2 fechas sin horarios).

			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
			--Para añadir o restar dias, meses, años. Sacado de aca: http://profesionghh.blogspot.com/2015/03/funciones-con-fechas.html
			TO_DATE('10-JUN-2015','DD-MM-YYYY') - 14			  			AS RestamosDias,	--Restamos 14 dias.			--Devuelve 27/05/2015
			add_months('10/06/2015',-5)   									AS RestamosMeses,	--Restamos 5 meses.			--Devuelve 10/01/2015
			add_months('10/06/2015',12)   									AS SumamosUnAño,	--Sumamos 1 año (12 meses). --Devuelve 10/06/2016
			last_day('10/06/2015') 		  									AS UltimoDiaMes,    --Claudio usa bastante last_day, cuando le piden el primer dia del mes siguiente y esta bueno porque a esa funcion le sumas 1 mes y listo. 
			
			--Devuelve 30/06/2015
		
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
			--TO_CHAR convierte un numero o date en un string. https://www.techonthenet.com/oracle/functions/to_char.php
			-- Sintaxis: TO_CHAR( value [, format_mask] [, nls_language] ).
				--Date: es el numero o date para ser pasado a string. 
				--Format_mask: Opcional. Formato que será usado para convertir el valor a string. 
				--Nls_language: Opcional. Lenguaje usado para convertir el valor a string. 
				
			--Por ej. me sirve Para obtener una fecha determinada de otra (por ej. AP_INVOICES_ALL.INVOICE_DAT era del tipo 2019-04-25T00:00:00.000+00:00. Y yo solo quiero DD/MM/YYYY. Entonces...:
			TO_CHAR(AP_INVOICES_ALL.INVOICE_DAT,'DD/MM/YYYY')				AS Fecha_De_Factura, --Devuelve 25-04-2019 en caso que AP_INVOICES_ALL.INVOICE_DAT sea 2019-04-25T00:00:00.000+00:00.
			
			--Otros ejemplos para numeros (Se puede usar para poner menos decimales: 
			TO_CHAR(-1210.73, '9999.9')										AS Numero			 --Devuelve -1210.7
	from 	dual;

	--FALTA: Obtener fechas menores a tanto. Usando <: where fecha < fecha1;
	--FALTA: Obtener fechas entre tanto y tanto... usando between: where fecha between fecha1 and fecha2;

	--17.3-Extract para ver la diferencia de meses, dias, años entre 2 fechas:
	select
			sysdate                                     					AS Fecha_Actual_Sistema,        --05/12/2019. Para sacar la fecha de hoy.
			CHECK_DATE                                  					AS Check_Date,                  --07/01/1996. Un campo de fecha. 
			round(MONTHS_BETWEEN(sysdate, CHECK_DATE))  					AS Dif_Fechas_En_Meses,         --287. Para sacar la diferencia de meses entre 2 fechas. 
			round(sysdate - CHECK_DATE)                 					AS Dif_Fechas_En_Dias,          --8734. Para sacar la diferencia de dias entre 2 fechas.
			EXTRACT(YEAR from sysdate)                  					AS Año_Actual,                  --2019
			
			--Aca obtenemos la cantidad de años de diferencia entre 2 fechas (la fecha actual sysdate y CHECK_DATE) obteniendo los años y luego restandolos:
			(EXTRACT(YEAR from sysdate) - EXTRACT(YEAR from CHECK_DATE)) 	AS Dif_Fechas_En_Años 			--23. Para sacar la diferencia de años entre 2 fechas. 
			--Hacemos como arriba ya que en Oracle no esta la funcion datediff.
	from AP_CHECKS_ALL
	;

	--17.4-Usando AVG sacamos la Antiguedad de CHECK_DATE promedio: para esto usamos la diferencia de años como lo hicimos arriba y sacamos un promedio de los años: 
	select 	trunc(  AVG(EXTRACT(YEAR from sysdate) - EXTRACT(YEAR from CHECK_DATE))  , 2) 	AS Prom_Dif_Fechas_En_Años --14,80
	from AP_CHECKS_ALL 
	;

	--FALTA HACER: VER SI FALTAN MÁS FUNCIONES PARA FECHAS. 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------