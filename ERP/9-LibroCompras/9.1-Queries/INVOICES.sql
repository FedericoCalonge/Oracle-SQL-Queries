--Lineas:
SELECT 	
		--Campos de union en Cloud:
        AI.legal_entity_id                  AS Legal_Entity_ID_2, --Tenemos que mostrar este campo para asociarlo con el campo Legal_Entity_ID de LEGALENTITY.sql.
                                                                --Esto lo hacemos mediante Cloud, haciendo click derecho en el campo del DS que queramos y poniendo en "link del campo". 
        AI.vendor_id                        AS Vendor_ID_1,       --Muestro esto para asociarlo con el proveedor (SUPPLIERS.sql) en Cloud.
        AI.invoice_id                       AS Invoice_ID_1,      --Muestro esto para asociarlo con las lineas de la factura (INVOICE_LINES.sql) en Cloud.
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        --Subquerys para traer la fecha, el año y el mes (todo esto lo sacamos de la tabla GLP de periodos):
		
		(SELECT EXTRACT(YEAR FROM GLP.START_DATE) --Obtenemos el año de GLP.START_DATE (o sea que depende del periodo que seleccionemos en el parametro). 	 
		FROM 	gl_periods 			GLP
		--Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
		--Entonces filtramos por el periodo del libro:
		WHERE 	GLP.period_name 		 	= :P_PERIODS  			--Parametro. Es el Period_name.
		)
		AS YEAR_GLP,
        
        --CAMPO MES_GLP: Para sacar el MES en el reporte tenemos que tocar el RTF y ponerle el formato para sacar directamente 
        --el nombre del mes dada la fecha (campo Fecha_GL de arriba) ahì.
        
        /*
		--De esta forma para sacar el mes en el RTF le ponemos el formato para sacar directamente el nombre del mes dada la fecha:
		(select add_months(TRUNC(GLP.START_DATE),+1)  	--Agregamos 1 mes mas... ya que en la salida del reporte nose porque dá 1 mes menos al que ponemos en el periodo. 
				--TRUNC(GLP.START_DATE)					--Trunc para poner las horas en 00.						
		FROM 	gl_periods 			GLP
		--Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
		--Entonces filtramos por el periodo del libro:
		WHERE 	GLP.period_name 		 	= :P_PERIODS  			--Parametro. Es el Period_name.
		) 
		AS Fecha_MES_GLP,  
        */
        
        AI.INVOICE_NUM                      AS Invoice_Num,     --CAMPO DOCUMENTO - NUMERO. Es el ID que se implementa en cada pais. 
		
        --Estas 2 fechas (Fecha_GL y Fecha_Trans) son distintas en algunos casos... ya que la fecha en que se contabiliza es distinto a la fecha en que efectivamente se realizó la transacción: 
		AI.gl_date							AS Fecha_GL, 		--Fecha de CONTABILIZACIÓN (donde se registra en el libro mayor / General Leadger).
		AI.invoice_date 					AS Fecha_Trans,		--Fecha en que efectivamente se realizó la transacción.
		TO_CHAR(AI.invoice_date ,'DD') 	    AS Dia_Trans,		--Dia de la transaccion. Campo DIA.
        
		AI.invoice_type_lookup_code 		AS Invoice_Type, 	--CAMPO documento - ESPECIE. FORA y NFE son lookups codes, NO hay que buscar la descripción (esto lo
                                                                --hice antes, ver LINES.SQL del reporte hecho de la manera 1 - Omar).
		
		AI.invoice_amount					AS Invoice_Amount, 	--Monto de la factura. CAMPO "VALOR DO DOCUMENTO"	
        AI.base_amount                      AS Base_Amount       --Ver diferencia, al parecer es Base_amount + impuestos - retenciones = amount. 
       
                                                                --Tuvimos que hacer 2 joins para tener este campo. 
FROM	ap_invoices_all               		AI
			
WHERE 	--Joins: NINGUNO.

		--Otras condiciones que saque de la query principal que ya estaba hecha (de Q_AP_INVOICES.sql):
		AI.approval_status              = 'APPROVED'
		AND	AI.invoice_type_lookup_code 	in ('CREDIT','DEBIT','STANDARD','EXPENSE REPORT') --Estos no estan en portuges? O siempre son así en ingles?
        
		--Parametros:
        
        AND AI.org_id                        = NVL(:P_ORG_ID, AI.org_id)
        AND AI.vendor_id                     = NVL(:P_VENDOR_ID, AI.vendor_id)    --Este filtr lo haceoms ACA (NO en SUPPLIERS.sql)  
        
        --Cuando teniamos parametro de fechas (P_START_INVOICE_GL_DATE y P_END_INVOICE_GL_DATE) unicamente es como abajo para filtrar (
        --pero lo malo de esto es que nosotros tenemos que seleccionar un mes! Ya que en la salida tenemos la columna DIA que
        --corresponde a los dias de 1 mes... y por esto no es aconsejable tener parametros de fechas ya que el usuario puede poner 
        --23/08/2019 hasta el 20/12/2019 y ahì hay 5 meses... entonces en la columna "DIA" no se sabrìa a que mes pertenecerìa). 
		--AND AI.gl_date                       >= :P_START_INVOICE_GL_DATE
		--AND AI.gl_date                       <= :P_END_INVOICE_GL_DATE
        
        --Entonces, ahora el parametro es P_PERIODS.Asi, para el periodo 'ENE19' el reporte debe traer todas las facturas generadas entre el 01-01-2019 al 31-01-2019". 
        --Acá filtramos esto:
			
        --1- Filtramos que la fecha de la factura (AI.invoice_date) sea mayor o igual a la fecha de INICIO del periodo:
        AND TRUNC(AI.invoice_date) >=  	(SELECT TRUNC(GLP.START_DATE)   	--START_DATE y TRX_DATE estan en formato 2019-11-29T22:00:00.000-02:00...
                                                                        --Al ponerles trunc solo reiniciamos lo de las horas, min y seg a 00 todo.
                                                                        --Podemos sino usar TO_CHAR para transformar ambas fechas al formato DD/MM/YYYY y luego compararlas, pero es lo mismo --> TO_CHAR(:START_DATE,'DD/MM/YYYY')
                                    FROM 	gl_periods 			GLP
                                    --Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
                                     --Entonces filtramos por el periodo del libro:
                                    WHERE 	period_name 		 			= :P_PERIODS  			--Parametro. Es el Period_name.
                                    )
                            
        --2- Filtramos que la fecha de la factura (AI.invoice_date) sea mayor o igual a la fecha de FIN del periodo:
        AND TRUNC(AI.invoice_date) <=  	(SELECT TRUNC(GLP.END_DATE)
                                     FROM 	gl_periods 			GLP
                                     --Tenemos que filtrar para que nos traiga 1 solo resultado (ya que la subquery debe traer 1 solo registro)...  
                                     --Entonces filtramos por el periodo del libro:
                                     WHERE 	GLP.period_name 		 		= :P_PERIODS 		    --Parametro. Es el Period_name.	
                                    )

        --Esto por si queremos que me traiga SOLO las facturas con retenciones (o sino sacamos el (+) del 1er join) - Pero en nuestro caso queremos 
        --tambien las que NO tienen retenciones (tienen un 0 en las columnas Alicuota y Imposto retido):
        /*
        AND EXISTS (SELECT 1
                   FROM AP_INVOICE_LINES_ALL    AILA1
                  WHERE AILA1.INVOICE_ID                = AI.INVOICE_ID
                    AND AILA1.LINE_TYPE_LOOKUP_CODE     = 'AWT'         )
          */
          
order by 	--TO_CHAR(AI.invoice_date ,'DD') asc,
            TO_CHAR(AI.invoice_date,'DD') asc,
            AI.invoice_id  asc