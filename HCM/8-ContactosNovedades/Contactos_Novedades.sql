SELECT  
		PERA.PERSON_ID						as PersonID_Empleado,  
		PERA.PERSON_NUMBER					as Person_Number_Empleado,
		NAME.FULL_NAME						as Nombre_Empleado, 
		--NAME_Contact.FULL_NAME				as Nombre_Contact,  
		CON.EMERGENCY_CONTACT_FLAG 			as Es_Contacto_Emerg,
		CON.CONTACT_PERSON_ID				as PersonID_Contact,
		
		--Cod Pais, Cod area, N° Tel Principal contacto:
		PH_Contact.COUNTRY_CODE_NUMBER || ' ' || PH_Contact.AREA_CODE || ' '|| PH_Contact.PHONE_NUMBER 			  
											AS Tel_All_Contact,
		PH_Contact.PHONE_TYPE  				as Tipo_Tel,
		DECODE(PH_Contact.PHONE_TYPE , 	'WM', 'Celular Oficina', 'HM', 'Celular Casa', 'W1', 'Telefono Oficina', 'H1', 'Telefono Casa',						
									'Otro') as Tipo_Tel_Desc,
		PA_Contact.ADDRESS_LINE_1 || ' ' || PA_Contact.ADDRESS_LINE_2 || ', '|| PA_Contact.TOWN_OR_CITY || ',' || Name_territore.NLS_TERRITORY 
									as Address,							
		--Otros campos Direccion:
		/*PA_Contact.TOWN_OR_CITY 			as Barrio, 
		PA_Contact.REGION_3 				as Provincia, 
		PA_Contact.REGION_1 				as Canton, 	
		PA_Contact.REGION_2 				as Distrito, 
		PA_Contact.POSTAL_CODE				AS Postal_Code,*/ 
		
		--En base al context_value me trae el creditofiscal:
		CON.CONT_ATTRIBUTE_CATEGORY as context_value,
		DECODE(CON.CONT_ATTRIBUTE1	,'Y','Si','N','No','HCE','HCE','HM25E', 'HM25E', 
									CON.CONT_ATTRIBUTE1) 	as creditofiscal,
		NAME_Contact.LAST_NAME				as Apellido_Contact,
		LEG_Contact.SEX 					AS Sexo,
				NAME_Contact.FIRST_NAME				as Primer_Nombre_Contact,
		NAME_Contact.MIDDLE_NAMES			as Segundo_Nombre_Contact,
		
		TO_CHAR(CON.EFFECTIVE_START_DATE, 'DD/MM/YYYY')	
											as Fecha_Inicio_Relac,
											
		(CASE   
			WHEN 	(
					to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') 		>= 	(CON.LAST_UPDATE_DATE) 
					AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')   < 	(CON.LAST_UPDATE_DATE)
					) 
			THEN 	CON.EFFECTIVE_START_DATE
						
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PERA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PERA_Contact.LAST_UPDATE_DATE)) 
			THEN PERA_Contact.EFFECTIVE_START_DATE
			
			--NAME_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (NAME_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (NAME_Contact.LAST_UPDATE_DATE)) 
			THEN NAME_Contact.EFFECTIVE_START_DATE
			
			--PH_Contact:
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PH_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PH_Contact.LAST_UPDATE_DATE)) 
			THEN PH_Contact.DATE_FROM

			--PA_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PA_Contact.LAST_UPDATE_DATE)) 
			THEN PA_Contact.EFFECTIVE_START_DATE
			
			ELSE NULL 
			END 
			
		)"FECHA_ALTA",
		
		(CASE   
			
			--CON: 
			WHEN 	(
					to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') 		>= 	(CON.LAST_UPDATE_DATE) 
					AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < 	(CON.LAST_UPDATE_DATE)
					) 
			THEN 	CON.LAST_UPDATE_DATE
						
			--PERA_Contact: 	
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PERA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PERA_Contact.LAST_UPDATE_DATE)) 
			THEN PERA_Contact.LAST_UPDATE_DATE
			
			--NAME_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (NAME_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (NAME_Contact.LAST_UPDATE_DATE)) 
			THEN NAME_Contact.LAST_UPDATE_DATE
			
			--PH_Contact:
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PH_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PH_Contact.LAST_UPDATE_DATE)) 
			THEN PH_Contact.LAST_UPDATE_DATE

			--PA_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PA_Contact.LAST_UPDATE_DATE)) 
			THEN PA_Contact.LAST_UPDATE_DATE
			
			ELSE NULL 
			END 
			
		)"Fecha_Ultima_Modific",
		
		CON.CONTACT_TYPE					as Contact_Type,
		--Esto no hace falta:
		--DECODE(CON.CONTACT_TYPE, 	'C', 'Hijo/a', 'S', 'Esposo/a', 'DP', 'Concubino/a', 'R', 'Hijo/a Concubino/a',	'P', 'Padre/Madre',						
		--							'Otro') as Tipo_Contact_Desc,
		
		TO_CHAR(PER_Contact.DATE_OF_BIRTH, 'DD/MM/YYYY') 	as Fecha_Nacim_Cont								
		--PA_Contact.EFFECTIVE_START_DATE

from 	PER_CONTACT_RELSHIPS_F 		CON,
		PER_ALL_PEOPLE_F 			PERA,
		PER_ALL_PEOPLE_F 			PERA_Contact,
		PER_PERSON_NAMES_F 			NAME,
		PER_PERSON_NAMES_F 			NAME_Contact,
		PER_PERSONS 				PER,
		PER_PERSONS 				PER_Contact,
		PER_PHONES 					PH_Contact,						
		PER_PERSON_ADDRESSES_V 		PA_Contact,				--Vista para obtener la dirección de la persona. 
		FND_TERRITORIES_VL 			Name_territore,
		PER_PEOPLE_LEGISLATIVE_F  	LEG_Contact
		
where 	--CON.person_id 			--es el EMPLEADO.
		--CON.CONTACT_PERSON_ID  	--ES el CONTACTO del EMPLEADO. 
		--CON.CONTACT_PERSON_ID  es = a PERA_Contact.person_id.
		
		--Empleado:
		PERA.person_id					=   CON.person_id				--Traigo la persona solo si tiene contactos. (antes era CON.person_id (+))  
		and	PERA.person_id				=	PER.person_id
		and NAME.person_id 				=	PERA.person_id
		and NAME.NAME_TYPE 				= 	'GLOBAL'
		
		--Contacto:
		and CON.CONTACT_PERSON_ID 		=   PERA_Contact.person_id    --AGREGADO. 
		and	PERA_Contact.person_id		= 	PER_Contact.person_id
		and PERA_Contact.person_id 		=   NAME_Contact.person_id   --Aca tengo al nombre de la persona.
		and NAME_Contact.NAME_TYPE 		= 	'GLOBAL'
		
		--Telefono: 
		--and PH_Contact.person_id(+) 			= PERA_Contact.person_id 			--Me trae el contacto tenga o no numero. NO, estaba de mas. Dejo la de abajo. 
		AND PH_Contact.PHONE_ID (+) 			= PERA_Contact.PRIMARY_PHONE_ID  	--Me trae el contacto tenga o no numero marcado como principal.
		
		--Dirección:
		and PA_Contact.person_id(+) 			= NAME_Contact.person_id		--Me trae el contacto tenga o no direccion. 
		and Name_territore.TERRITORY_CODE(+)  	= PA_Contact.country  			--Me trae la descripcion de pais para la direccion.
		
		--Leg:
		and PER_Contact.person_id  				= LEG_Contact.person_id	
		--and LEG_Contact.legislation_code 		= 'CR'							--Tiene que estar comentado esto. 
		
		--TODAS las tablas con fechas efectivas tengo que filtrarlas acá, TODAS:
		--Para que traiga empleados a futuro reemplazamos SYSDATE por el parametro :P_Effective_End_Date.
		and :P_Effective_End_Date between PERA.EFFECTIVE_START_DATE 			and PERA.EFFECTIVE_END_DATE
		and :P_Effective_End_Date between NAME.EFFECTIVE_START_DATE 			and NAME.EFFECTIVE_END_DATE
		and :P_Effective_End_Date between LEG_Contact.EFFECTIVE_START_DATE 		and LEG_Contact.EFFECTIVE_END_DATE
		and :P_Effective_End_Date between NAME_Contact.EFFECTIVE_START_DATE 	and NAME_Contact.EFFECTIVE_END_DATE
		and :P_Effective_End_Date between PA_Contact.EFFECTIVE_START_DATE (+)	and PA_Contact.EFFECTIVE_END_DATE (+)     --TENGA O NO DIRECCION ME LO TRAE IGUAL. 
		and :P_Effective_End_Date between PERA_Contact.EFFECTIVE_START_DATE  	and PERA_Contact.EFFECTIVE_END_DATE
		and :P_Effective_End_Date between CON.EFFECTIVE_START_DATE 				and CON.EFFECTIVE_END_DATE

		and ((COALESCE(null, :P_Person_Number) is null) OR (PERA.PERSON_NUMBER IN (:P_Person_Number)))
		
		and (CASE   
			
			--CON: 
			WHEN 	(
					to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') 		>= 	(CON.LAST_UPDATE_DATE) 
					AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < 	(CON.LAST_UPDATE_DATE)
					) 
			THEN 	CON.EFFECTIVE_START_DATE
					
			--PERA_Contact: 	
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PERA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PERA_Contact.LAST_UPDATE_DATE)) 
			THEN PERA_Contact.EFFECTIVE_START_DATE
			
			--NAME_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (NAME_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (NAME_Contact.LAST_UPDATE_DATE)) 
			THEN NAME_Contact.EFFECTIVE_START_DATE
			
			--PH_Contact:
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PH_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PH_Contact.LAST_UPDATE_DATE)) 
			THEN PH_Contact.DATE_FROM

			--PA_Contact: 
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (PA_Contact.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (PA_Contact.LAST_UPDATE_DATE)) 
			THEN PA_Contact.EFFECTIVE_START_DATE
			
			ELSE NULL 
			END 
		) BETWEEN CON.EFFECTIVE_START_DATE AND CON.EFFECTIVE_END_DATE

		AND( 
			  (CON.LAST_UPDATE_DATE <= (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9')) AND CON.LAST_UPDATE_DATE > (to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')))
			  OR (PERA_Contact.LAST_UPDATE_DATE <= (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9')) AND PERA_Contact.LAST_UPDATE_DATE > (to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')))
			  OR (NAME_Contact.LAST_UPDATE_DATE <= (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9')) AND NAME_Contact.LAST_UPDATE_DATE > (to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')))
			  OR (PH_Contact.LAST_UPDATE_DATE <= (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9')) AND PH_Contact.LAST_UPDATE_DATE > (to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')))
			  OR (PA_Contact.LAST_UPDATE_DATE <= (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9')) AND PA_Contact.LAST_UPDATE_DATE > (to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9')))
		)
		
order by PERA.PERSON_NUMBER desc