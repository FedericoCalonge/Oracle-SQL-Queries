--Las expresiones regulares son un "arma de doble filo", ya que para usarlas hay que saber BIEN como funcionan, LEER --> https://docs.oracle.com/cd/B12037_01/appdev.101/b10795/adfns_re.htm

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1-SUBSTR y INSTR (NO son expresiones regulares pero hay que saber estas funciones):
		
		--Usamos SUBSTR:
			--Con este ejemplo extraemos un substring desde un string "SQL Tutorial" (empezamos en la posición 5 (T) y extraemos 3 caracteres (Tut).
				-->Devuelve Tut.
				SELECT SUBSTR('SQL Tutorial', 5, 3) 	AS Extract_String  --Tut
                from DUAL; --Tabla de pruebas para hacer en SQL Developer
		
		--Usamos SUBSTR con INSTR:
			--Con este ejemplo separamos en 2 partes el numero 1235-5942 (separado por el -):
				--INSTR devuelve la posición del caracter que buscamos (en este caso el '-'). 
				--> Devuelve 1234 en primera_parte y 5942 en segunda_parte:
				Select 		SUBSTR('1235-5942',1,INSTR('1235-5942','-')-1) 	AS primera_parte, --Recorremos la cadena de la posicion 1 hasta la 4 (1 antes que empiece el -)
							SUBSTR('1235-5942',INSTR('1235-5942','-')+1) 	AS segunda_parte  --Recorremos la cadena desde la posicion 6 (1 despues que empiece el -) hasta el final.
				from DUAL;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Ahora si, expresiones regulares:

-- 2-REGEXP_SUBSTR:    VER --> https://docs.oracle.com/cd/B12037_01/appdev.101/b10795/adfns_re.htm
		
		--Con +:
		select
		REGEXP_SUBSTR('9999-8888','[[:digit:]]+',1,1)           AS NUM_DOC_SERIE,
		REGEXP_SUBSTR('9999-8888','[[:digit:]]+',1,2)           AS NUM_DOC_NUMERO
		from DUAL;
		
		--Con *:
		REGEXP_SUBSTR('9999-8888','[[:digit:]]*',1,1)           AS NUM_DOC_SERIE,
		REGEXP_SUBSTR('9999-8888','[[:digit:]]*',1,3)           AS NUM_DOC_NUMERO
		
			--Parametros del REGEXP_SUBSTR:
			--1: campo a evaluar 
			--2: 	con que vamos a machear (en nuestro caso es una LISTA (por los []) de caracteres "digit" (por el [:digit:]). 
						--y el + significa que machea 1 o más ocurrencias.
						--Si ponemos un * signica que machea 0 o más ocurrencias.
						--ENTENDER BIEN ESTO!, no entendi diferencia + y *: Ver https://docs.oracle.com/cd/B12037_01/appdev.101/b10795/adfns_re.htm tabla 12-2.
			--3: posicion de inicio de nuestro patron (1 serie 9999, 2 seria - y 3 seria 88888)
			--4: numero de ocurrencia. 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
-- 3-REGEXP_REPLACE:
	--Para SACAR todo lo que NO sea numerico [0-9] y dejar solo el numero sin -, /, #, etc... usamos:
		select  REGEXP_REPLACE(APIA.Invoice_Num,'[^0-9]') AS NUM_SIN_GUION
				--Si quremos que deje solo alfanumericos: [^0-9a-zA-Z]
				-- ^ es un NEGADOR.
		from AP_INVOICES_ALL APIA

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
-- 4-REGEXP_REPLACE con substr:
        -- Los numeros de remito esran de este tipo:  R-00007-95436   
        --                                            R-0004-56434
        -- Pero tambien habian de este tipo:          CT464634556435
        --Entonces había que filtrar para que comience en 'R-....", había que sacar la letra (LETTER) y tambien el número del medio que representaba el BRANCH-PUNTO DE VENTA
        --(el 00007 o 0004 --> notar que son 5 o 4 numeros). Para eso ultimo usamos el regexp_replace combinado con substr.
        --AND substr(WND.waybill,3,5)     =:BRANCH                --Ejemplo: 0007-
         
         
         --Consulta original (WND.waybill era el campo con el numero de remito):
         select 
                    substr(WND.waybill,3,5)                 AS Branch1,
                    regexp_replace(substr(WND.waybill,3,5)             
                                            ,'[^[:alnum:]]*'       
                                            ,''             ) --Aplicamos el regexp_replace luego del substr para reemplazar todos los caracteres que no son numericos (:alnum:)
                                                              --(en nuestro caso solo el '-') por espacios vacios.
                                                            AS Branch2,              --Ejemplo: 0007 (este es el que queremos, sin el -)
                    substr(WND.waybill,1,1)                 AS Letter                --Ejemplo: R. Agarramos solo el 1er campo.
            where   WND.waybill like 'R-%' 
            from    WSH_NEW_DELIVERIES                      WND
         
         --Consulta para que me ande en el SQL Developer (con un ejempplo):
          select 
                    substr('R-00007-95436' ,3,5)                AS Branch1_1,  --00007
                    substr('R-0004-56434' ,3,5)                 AS Branch1_2,  --0004- (con el -, MAL!).
                    regexp_replace(substr('R-00007-95436',3,5)             
                                            ,'[^[:alnum:]]*'       
                                            ,''             ) 
                                                                AS Branch2_1,  --00007
                    regexp_replace(substr('R-0004-56434',3,5)             
                                            ,'[^[:alnum:]]*'       
                                            ,''             ) 
                                                                AS Branch2_2,  --0004 (sin el -, BIEN!).
                                                            
                    substr('R-00007-95436',1,1)                     AS Letter  --R          
            from    dual;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5-TEST: Usamos el campo Invoice_Num de AP_INVOICES_ALL, el cual es el Numero de documento de la factura... 
		--es del tipo: 0004-00082305.  Tenemos que separar el numero en dos.
		--La 1ra parte es el NUM_DOC_SERIE y la otra es el NUM_DOC_NUMERO separados por un GUION.
		
		--Como hice yo (CON EXPRESIONES REGULAR):
		REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,1)           AS NUM_DOC_SERIE,
		REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,3)           AS NUM_DOC_NUMERO,
		
		--Como me dijo Claudio (SIN EXPRESIONES REGULARES, con SUBSTR y INSTR:) --> VER EJEMPLO DE ARRIBA DE SUBSTR con INSTR. Nos quedaria asi:
		SUBSTR(AIA.Invoice_Num,1,INSTR(AIA.Invoice_Num,'-')-1) 		AS NUM_DOC_SERIE,
		SUBSTR(AIA.Invoice_Num,INSTR(AIA.Invoice_Num,'-')+1) 		AS NUM_DOC_NUMERO,
