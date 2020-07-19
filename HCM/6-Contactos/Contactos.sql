SELECT  
		PERA.PERSON_ID						as PersonID_Empleado, 
		PERA.PERSON_NUMBER					as Person_Number_Empleado,
	
		NAME.FULL_NAME						as Nombre_Empleado,
		--NAME_Contact.FULL_NAME				as Nombre_Contact,
		NAME_Contact.LAST_NAME				as Apellido_Contact,
		NAME_Contact.FIRST_NAME				as Primer_Nombre_Contact,
		NAME_Contact.MIDDLE_NAMES			as Segundo_Nombre_Contact,
		
		LEG_Contact.SEX 					AS Sexo,

		TO_CHAR(CON.EFFECTIVE_START_DATE, 'DD/MM/YYYY')	as Fecha_Inicio_Relac, --Fecha de inicio relación con el contacto
		CON.EMERGENCY_CONTACT_FLAG 			as Es_Contacto_Emerg,
		CON.CONTACT_PERSON_ID				as PersonID_Contact,
			
		DECODE(CON.CONTACT_TYPE, 	'C', 'Hijo/a', 'S', 'Esposo/a', 'DP', 'Concubino/a', 'R', 'Hijo/a Concubino/a',	'P', 'Padre/Madre',						
									'Otro') as Tipo_Contact_Desc,

		--Cod Pais, Cod area, N° Tel Principal contacto:
		PH_Contact.COUNTRY_CODE_NUMBER || ' ' || PH_Contact.AREA_CODE || ' '|| PH_Contact.PHONE_NUMBER AS Tel_All_Contact,
		
		PH_Contact.PHONE_TYPE  				as Tipo_Tel,
		DECODE(PH_Contact.PHONE_TYPE , 	'WM', 'Celular Oficina', 'HM', 'Celular Casa', 'W1', 'Telefono Oficina', 'H1', 'Telefono Casa',						
									'Otro') as Tipo_Tel_Desc,
									
		--Otros campos Direccion:
		/*PA_Contact.TOWN_OR_CITY 			as Barrio, 
		PA_Contact.REGION_3 				as Provincia, 
		PA_Contact.REGION_1 				as Canton, 	
		PA_Contact.REGION_2 				as Distrito, 
		PA_Contact.POSTAL_CODE				AS Postal_Code,*/ 
		
		PA_Contact.ADDRESS_LINE_1 || ' ' || PA_Contact.ADDRESS_LINE_2 || ', '|| PA_Contact.TOWN_OR_CITY || ',' || Name_territore.NLS_TERRITORY 
									as Address,
		
		--En base al context_value me trae el creditofiscal:
		con.CONT_ATTRIBUTE_CATEGORY as context_value,
		DECODE(con.CONT_ATTRIBUTE1,'Y','Si','N','No',con.CONT_ATTRIBUTE1) AS creditofiscal									

from 	PER_CONTACT_RELSHIPS_F 		CON,
		PER_ALL_PEOPLE_F 			PERA,
		PER_ALL_PEOPLE_F 			PERA_Contact,
		PER_PERSON_NAMES_F 			NAME,
		PER_PERSON_NAMES_F 			NAME_Contact,
		PER_PERSONS 				PER,
		PER_PERSONS 				PER_Contact,
		PER_PHONES 					PH_Contact,						
		PER_PERSON_ADDRESSES_V 		PA_Contact,	--Vista para obtener la dirección de la persona. 
		FND_TERRITORIES_VL 			Name_territore,
		PER_PEOPLE_LEGISLATIVE_F  	LEG_Contact
		
		
where 	CON.person_id(+)				=	PERA.person_id   --Traigo la persona tenga o no contactos. 
		and	PERA.person_id				=	PER.person_id
		and NAME.person_id 				=	PERA.person_id
		and NAME.NAME_TYPE 				= 	'GLOBAL'
		and NAME_Contact.NAME_TYPE 		= 	'GLOBAL'
		and NAME_Contact.person_id 		=	CON.CONTACT_PERSON_ID
		
		and SYSDATE between PERA.EFFECTIVE_START_DATE and PERA.EFFECTIVE_END_DATE
		and SYSDATE between NAME.EFFECTIVE_START_DATE and NAME.EFFECTIVE_END_DATE
		and SYSDATE between NAME_Contact.EFFECTIVE_START_DATE and NAME_Contact.EFFECTIVE_END_DATE
		and SYSDATE between PA_Contact.EFFECTIVE_START_DATE and PA_Contact.EFFECTIVE_END_DATE
		and SYSDATE between PERA_Contact.EFFECTIVE_START_DATE and PERA_Contact.EFFECTIVE_END_DATE
		
		and CON.CONTACT_PERSON_ID				= PH_Contact.person_id			--Para el numero del contacto. 
		and PA_Contact.person_id(+) 			= NAME_Contact.person_id		--Me trae el contacto tenga o no direccion. 
		and Name_territore.TERRITORY_CODE(+)  	= PA_Contact.country  			--Me trae la descripcion de pais para la direccion.
		
		and PH_Contact.person_id(+) 			= PERA_Contact.person_id 		--Me trae el contacto tenga o no numero. 
		AND PH_Contact.PHONE_ID (+) 			= PERA_Contact.PRIMARY_PHONE_ID --Me trae el contacto tenga o no numero marcado como principal.
		
		and	PERA_Contact.person_id				= PER_Contact.person_id
		and PER_Contact.person_id  				= LEG_Contact.person_id	
		and LEG_Contact.legislation_code 				= 'CR'		
		and SYSDATE between LEG_Contact.EFFECTIVE_START_DATE and LEG_Contact.EFFECTIVE_END_DATE
		
		--Con person_number = 'all' en la selección de parametros en 'Data', 'View' NO me tira nada... pero si selecciono los person number con selección multiple si me tira esos nomas:
		and PERA.PERSON_NUMBER 					IN (:P_Person_Number)  	--Parametro.
		
		--Con person_number = 'all' me tira todos pero NO puedo seleccionar múltiples (me tira un error):
		--and PERA.PERSON_NUMBER =  				NVL(:P_Person_Number, PERA.PERSON_NUMBER)
		
		--Si quiero que me traiga con ALL todos y tambien que pueda traer solo algunos seleccionando los person number con selección multiple: 
		--and ((COALESCE(null, :P_Person_Number) is null) OR (PERA.PERSON_NUMBER IN (:P_Person_Number)))
		
order by PERA.PERSON_NUMBER desc