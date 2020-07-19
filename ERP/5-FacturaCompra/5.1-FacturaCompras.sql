--Query:
select 	
		--------------------------------------------------------------------------------------------------------------------------------------------------
		--Encabezado / parametros:
		--------------------------------------------------------------------------------------------------------------------------------------------------
		--Como START_DATE y END_DATE estan en el formato: 2019-11-29T22:00:00.000-02:00 entonces usamos TO_CHAR para transformarla al formato DD/MM/YYYY.		
		TO_CHAR(:START_DATE,'DD/MM/YYYY') 							AS START_DATE_DD_MM_AAAA,
		TO_CHAR(:END_DATE,'DD/MM/YYYY') 							AS END_DATE_DD_MM_AAAA,
		
		--Subquery para traer el NOMBRE de la Unidad de Negocio / BU (usando el parametro ingresado UNIDAD_NEGOCIO que es la ID):
		(SELECT name
        FROM   	HR_ORGANIZATION_UNITS		HRU		--Las tablas de las sub-querys NO tienen que estar joineadas en nuestra query principal.
        WHERE  	HRU.organization_id 		= :UNIDAD_NEGOCIO) 
																	AS Nombre_Unidad_Negocio,
		
		--Subquery para traer el NOMBRE de la Unidad de la Entidad Legal (usando el parametro ingresado ENTIDAD_LEGAL que es la ID):
		--NO tenemos que joinear en la subquery XEP con AIA, aca solo buscamos el nombre de la entidad legal. 			
		(SELECT name
		FROM 	XLE_ENTITY_PROFILES 		XEP	  	--Las tablas de las sub-querys NO tienen que estar joineadas en nuestra query principal.  
		WHERE 	XEP.legal_entity_id 		= :ENTIDAD_LEGAL)
																	AS Nombre_Entidad_Legal,

		XEP.legal_entity_identifier									AS NIT_Entidad_Legal,
		FCVL.DESCRIPTION 											AS Moneda,
		FCVL.SYMBOL 												AS Simbolo_Moneda, 
		
		--Estos 2 no hacen falta... los agrego desde BI Publisher en "Insert", "Fields" (Están arriba de todo como "parameters"):
		--Fecha_Desde.
		--Fecha_Hasta.
		--Despues ver la fecha que me quede así como dice en el reporte.
		
		--------------------------------------------------------------------------------------------------------------------------------------------------
		--Tabla:
		--------------------------------------------------------------------------------------------------------------------------------------------------
	
		--Subquery para obtener el TIPO:
		(select MEANING								--MEANING es standard, credit memo, etc. (dado el where de abajo)
		from 	fnd_lookup_values 	 	FLV			--Tabla de Lookups. 
		where 	FLV.LANGUAGE = 'US' 			
				AND FLV.LOOKUP_TYPE = 'INVOICE TYPE'   	--Esto cambiamos con respecto al reporte 2. 
				AND FLV.LOOKUP_CODE =  AIA.INVOICE_TYPE_LOOKUP_CODE --Esto tambien cambiamos.  	  INVOICE_TYPE_LOOKUP_CODE es STANDARD, CREDIT, etc.
		) --Termina subquery.
																	AS TIPO,
		--SABER: NO hay que joinear adentro de la subquery de arriba AIA con FLV (o sea agregar en el from la AIA). Ya que si hacemos esto nos tira lo siguiente en el DM: "single-row subquery returns more than one row"

		--Numero de documento de la factura... AIA.Invoice_Num es del tipo: 0004-00082305. 
		--La 1ra parte es el NUM_DOC_SERIE y la otra es el NUM_DOC_NUMERO separados por un GUION.
		--Usamos SUBSTR: 
		substr(AIA.Invoice_Num,1,instr(AIA.Invoice_Num,'-')-1) 		AS NUM_DOC_SERIE,
		substr(AIA.Invoice_Num,instr(AIA.Invoice_Num,'-')+1) 		AS NUM_DOC_NUMERO,
		
		--Otra forma, con expresiones regulares:
		--REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,1)         AS NUM_DOC_SERIE,
		--REGEXP_SUBSTR(AIA.Invoice_Num,'[[:digit:]]*',1,3)         AS NUM_DOC_NUMERO,
		 
		TO_CHAR(AIA.INVOICE_DATE,'DD/MM/YYYY')						AS FECHA_DE_FACTURA,   -- AIA.INVOICE_DATE solo me tira esta fecha: 2019-04-25T00:00:00.000+00:00. Y yo solo quiero DD-MM-YYYY (POR ESTO USAMOS TO_DATE).
		--Con TO_CHAR nos devuelve 25/04/2019.
			
		nvl(HZP.JGZZ_FISCAL_CODE,0)									AS NIT_DEL_PROVEEDOR, 	--Rigurosamente el NIT es JGZZ_FISCAL_CODE (NO es HZP.PARTY_NUMBER). Como a veces me trae el NIT vacio, entonces en caso que pase esto le ponemos un 0 (para evitar errores en el BIPUBLISHER).
		HZP.PARTY_NAME 												AS PROVEEDOR,  			--Claudio me dijo que de aca esta bien sacar de aca el nombre del proveedor (para esto joineamos  POZS.VENDOR_ID = HZP.PARTY_ID). Si joineamos asi:  AIA.PARTY_ID 	= HZP.PARTY_ID me traería el comprador (NO el Proveedor) y estaría MAL.
		--Sino lo traemos de aca al nombre del proveedor: POZ_SUPPLIERS_V.vendor_name (Gastón).
		
		--Estas columnas ignorar porque no existen en red link: TRANS, COMPRAS_GRAVADAS_BIENES,COMPRAS_GRAVADAS_SERVICIOS, COMPRAS_EXENTAS_BIENES, COMPRAS_EVENTAS_SERVICIOS, IVA.  							
		
		--Usamos ZX_LINES (tabla de impuestos para cada factura) para las 3 columnas que hay que agregar:
		(SELECT --SUM(ZXL.TAX_AMT)			--Pueden haber varios TAX_AMT por factura... por eso hacemos el SUM.
				--Otra forma:
				SUM(decode(ZXL.TAX_TYPE_CODE,'VAT',ZXL.tax_amt,0)) --Si el campo ZXL.TAX_TYPE_CODE es 'VAT' entonces sumamos ZXL.tax_amt, sino (o sea si es otro tipo) sumamos 0. 
		FROM 	ZX_LINES 			ZXL,
				AP_INVOICES_ALL 	AIA
		WHERE 	ZXL.TAX_TYPE_CODE = 'VAT'
				AND ZXL.TRX_ID = AIA.INVOICE_ID  	--Aca asociamos la factura. Así los TAX_AMT son de 1 factura. 
				--Cosas que tenemos que filtrar (boilerplate):
				AND ZXL.application_id = 200 
				AND ZXL.entity_code = 'AP_INVOICES'	
				AND nvl(ZXL.cancel_flag,'N') = 'N'
				AND nvl(ZXL.delete_flag,'N') = 'N'
		) 															AS VAT, --Impuesto de tipo 'VAT'

		(SELECT --SUM(ZXL.TAX_AMT)			--Pueden haber varios TAX_AMT por factura... por eso hacemos el SUM.
				--Otra forma:
				SUM(decode(ZXL.TAX_TYPE_CODE,'PER IIBB',ZXL.tax_amt,0))
		FROM 	ZX_LINES 			ZXL,
				AP_INVOICES_ALL 	AIA
		WHERE 	ZXL.TAX_TYPE_CODE = 'PER IIBB'
				AND ZXL.TRX_ID = AIA.INVOICE_ID  	--Aca asociamos la factura. Así los TAX_AMT son de 1 factura. 
				--Cosas que tenemos que filtrar (boilerplate):
				AND ZXL.application_id = 200 
				AND ZXL.entity_code = 'AP_INVOICES'	
				AND nvl(ZXL.cancel_flag,'N') = 'N'
				AND nvl(ZXL.delete_flag,'N') = 'N'
		) 															AS PER_IIBB, --Percepciones de ingreso bruto ('PER IIBB').

		(SELECT --SUM(ZXL.TAX_AMT)			--Pueden haber varios TAX_AMT por factura... por eso hacemos el SUM.
				--Otra forma:
				nvl(SUM(decode(ZXL.TAX_TYPE_CODE,'WAT',ZXL.tax_amt,0)),0) --Usamos NVL ya que a veces me trae el WAT vacio, entonces en caso que pase esto le ponemos un 0 (para evitar errores en el BIPUBLISHER).
		
		FROM 	ZX_LINES 			ZXL,
				AP_INVOICES_ALL 	AIA
		WHERE 	ZXL.TAX_TYPE_CODE = 'AWT'
				AND ZXL.TRX_ID = AIA.INVOICE_ID  	--Aca asociamos la factura. Así los TAX_AMT son de 1 factura. 
				--Cosas que tenemos que filtrar (boilerplate):
				AND ZXL.application_id = 200 
				AND ZXL.entity_code = 'AP_INVOICES'	
				AND nvl(ZXL.cancel_flag,'N') = 'N'
				AND nvl(ZXL.delete_flag,'N') = 'N'
		) 															AS AWT --Retenciones 'AWT'.
		
		--Despues lo de obtener los totales para TODAS las facturas lo hacemos desde el BI Publisher (Word) - "Linea totalizadora de montos": TOTAL_VAT, TOTAL_IIBB, TOTAL_VAT.
		
from 	AP_INVOICES_ALL 		AIA,		--Tabla principal. Tabla de FACTURAS. 
		POZ_SUPPLIERS			POZS,   	--Tabla de los proveedores.
		HZ_PARTIES				HZP,		
		FND_CURRENCIES_VL  		FCVL, 		--Esta tabla la agregue yo. Tabla con info de las monedas (ver documento "Tablas para sacar infromacion para cada caso.docx"
		XLE_ENTITY_PROFILES		XEP			--Tabla para entidades legales (de acá sacamos el NIT).
		--ZX_LINES solo la usamos para las subquerys de los montos... por eso en el from principal NO la usamos y en el where principal NO la joineamos con AIA:
		--ZX_LINES				ZXL,		--Líneas de CADA factura. Acá tenemos también los impuestos aplicados a CADA línea. Por esto hacemos después una SUMATORIA SUM. 
											--Y después en Word hacemos una sumatoria de todos los impuestos de TODAS LAS FACTURAS.  
	
where	--Joins con la tabla principal (la mayoria los saque de docs.oracle tabla AIA):             
		AIA.VENDOR_ID					= POZS.VENDOR_ID			--JOIN PARA POZS.
		AND AIA.INVOICE_CURRENCY_CODE 	= FCVL.CURRENCY_CODE  		--JOIN PARA FCVL MONEDAS.
		AND POZS.PARTY_ID      			= HZP.PARTY_ID 				--Me trae el proveedor así.
		--AND	AIA.PARTY_ID 		= HZP.PARTY_ID 					--Me traeria el comprador así (no queremos esto, ya que necesitamos el campo para el PROVEEDOR - Ver arriba campo PROVEEDOR).
		AND XEP.LEGAL_ENTITY_ID			= AIA.LEGAL_ENTITY_ID		--JOIN PARA XEP.
		--Parametros: 
		AND AIA.INVOICE_DATE 			BETWEEN :START_DATE AND :END_DATE		--En un test del DM vemos que el invoice_date NO guarda hh:mm:ss (nos dá todo en 0... por ej: 2018-09-07T00:00:00.000+00:00). 
																				--Por esto NO usamos trunc para reiniciar las horas, min y seg a 0, no lo necesitamos. Pero si SI se guardarían hh:mm:ss ahí si lo utilizaríamos (para START_dATE y END_DATE en nuestro caso). 
 
		AND AIA.ORG_ID 					= :UNIDAD_NEGOCIO 						--El parametro UNIDAD_NEGOCIO es una ID. Pero lo que se muestra en el reporte son los name (query que hacemos en Cloud)
		AND AIA.LEGAL_ENTITY_ID 		= :ENTIDAD_LEGAL						--El parametro ENTIDAD_LEGAL es una ID. Pero lo que se muestra en el reporte son los name (query que hacemos en Cloud)
		AND POZS.VENDOR_ID 				= NVL(:PROVEEDOR,    POZS.VENDOR_ID )   --PROVEEDOR es el ID "POZ_SUPPLIERS_V.VENDOR_ID". Es POZ_SUPPLIERS_V y NO POZ_SUPPLIERS, ya que el _V (vista), tambien tiene el nombre del proveedor.
		AND FCVL.CURRENCY_CODE			= :MONEDA								--ID. En el reporte mostramos el description.
		--Para que los parametros sean obligatorios hay que marcar el "Mandatory" en el DM de Oracle Cloud (eso saca de la lista la opcion "all").
		--Y para hacer que si o si tengamos que seleccionar una opción (y NO "all") hay que ir a la opcion "Puede seleccionar todo"	