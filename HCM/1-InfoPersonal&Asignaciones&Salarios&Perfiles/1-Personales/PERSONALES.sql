SELECT  distinct
		PER.PERSON_ID,
		ASS.SYSTEM_PERSON_TYPE  "Tipo de persona",
		PERA.PERSON_NUMBER "Num Trabajador",
		NAME.FULL_NAME "Nombre y Apellido",
		PNI.NATIONAL_IDENTIFIER_TYPE  "Tipo Documento",
		PNI.NATIONAL_IDENTIFIER_NUMBER "Documento de identidad",
		(	CASE WHEN extract(year from PER.DATE_OF_BIRTH) is not null 
			then extract(year from SYSDATE)-extract(year from PER.DATE_OF_BIRTH)
			ELSE NULL END
		) 	"Edad",
		
		--Email y telefono principal:
		EM.EMAIL_ADDRESS "EmailPrincipal",	   --Es el "Email_Coorporativo".
		PH.PHONE_NUMBER  "TelefonoPrincipal",  --Es el "TelefonoOficina".
		
			--EMAILS:
		(	select 	EM.EMAIL_ADDRESS
			from 	PER_EMAIL_ADDRESSES EM
			where   PER.person_id = EM.person_id
					AND EM.EMAIL_TYPE='W1'
					and rownum = 1
		) 	"Email_Coorporativo",			

		(	select 	EM2.EMAIL_ADDRESS
			from 	PER_EMAIL_ADDRESSES EM2
			where   PER.person_id= EM2.person_id
					AND EM2.EMAIL_TYPE='H1'
					and rownum = 1
		) 	"Email_Personal",				

		(	SELECT 	PH2.PHONE_NUMBER
			FROM 	PER_PHONES PH2
			where 	PER.person_id = PH2.person_id
					AND PH2.PHONE_TYPE= 'HM'
					and rownum = 1
		) 	"NumCelular",						

		(	SELECT 	PH3.PHONE_NUMBER
			FROM 	PER_PHONES PH3
			where 	PER.person_id = PH3.person_id
					AND PH3.PHONE_TYPE= 'W1'
					and rownum = 1
		) 	"TelefonoOficina",				

		(	select 	phone_number 
			from 	per_phones 
			where 	person_id=CON.contact_person_id
		) 	"telefonoEMERG",
		CON.CONTACT_TYPE "Tipo Contacto", 
		CON.EMERGENCY_CONTACT_FLAG "Es Contacto Emerg?",
		CON.CONTACT_PERSON_ID,
		
		PER.BLOOD_TYPE "Grupo Sanguineo",
		LEG.SEX "Sexo",
		PER.DATE_OF_BIRTH "Fecha de Nacimiento",
		PER.DATE_OF_DEATH "Fecha de defuncion",
		PER.COUNTRY_OF_BIRTH "Pais de Nacimiento",
		PER.REGION_OF_BIRTH "Region de Nacimiento", 
		PER.TOWN_OF_BIRTH "Municipio de Nacimiento",
		PER.CORRESPONDENCE_LANGUAGE "Idioma",
		LEG.MARITAL_STATUS_DATE "Fecha cambio est civil",
		LEG.MARITAL_STATUS "Estado Civil",
		LOO.meaning "Nivel Edu Sup",
		--LEG.HIGHEST_EDUCATION_LEVEL "Nivel Edu Sup",
		ET.ETHNICITY "Grupo Etnico",
		PA.ADDRESS_LINE_1 "direccionResidencia",
		DIS.STATUS,
		DIS.REASON "Discapacidad Motivo",
		DIS.DISABILITY_CODE "Codigo Discapacidad",
		DIS.CATEGORY "Categoria Discapacidad",
		DIS.EFFECTIVE_START_DATE "Fecha Inicio Discap",
		CIT.DATE_FROM "Fecha Inicio Ciudadania",
		CIT.CITIZENSHIP_STATUS "StatusCiudadania",
		CIT.LEGISLATION_CODE "PaisCiudadania",
		LIC.LICENSE_NUMBER"Numero Licencia",
		LIC.DATE_FROM "Fecha Inicio Licencia",

		DECODE(	ASS.Business_unit_id, 300000002580231, 'Bucaramanga',300000002580393, 'Medellin',300000002580474, 
				'Villavicencio',300000002580312,'Tunja',300000002580150,'Bogota'
			   ) "Sede"

from 	PER_CONTACT_RELSHIPS_F CON,
		HCM_LOOKUPS LOO,
		PER_DRIVERS_LICENSES LIC,
		per_disabilities_f DIS,
		PER_ADDRESSES_F PA,
		PER_ETHNICITIES  ET,
		PER_ALL_PEOPLE_F PERA, 
		PER_PERSONS PER,
		PER_PERSON_NAMES_F NAME,
		PER_PEOPLE_LEGISLATIVE_F  LEG,
		hr_organization_units_f_tl ORG,
		PER_PERIODS_OF_SERVICE S,
		PER_NATIONAL_IDENTIFIERS PNI,
		PER_PHONES PH,
		PER_EMAIL_ADDRESSES EM,
		PER_ALL_ASSIGNMENTS_F ASS,
		PER_CITIZENSHIPS CIT

where 	CON.person_id(+)=PERA.person_id
		AND LIC.person_id(+)=PERA.person_id   --Traigo persona tengan o no licencias (por el (+)). 
		AND CIT.person_id(+)=PERA.person_id
		AND DIS.person_id(+)=PERA.person_id	  --Traigo persona tenga o no discapacidad (por el (+)).
		AND PERA.MAILING_ADDRESS_ID(+)= PA.ADDRESS_ID
		AND PER.person_id=ET.person_id(+) 
		AND	PERA.person_id=PER.person_id
		
		and NAME.person_id =PER.person_id 
		and NAME.NAME_TYPE = 'CO' 
		
		and SYSDATE between NAME.EFFECTIVE_START_DATE and NAME.EFFECTIVE_END_DATE
		
		and LEG.person_id= PER.person_id 
		and LEG.legislation_code = 'CO'
		
		and SYSDATE between LEG.EFFECTIVE_START_DATE and LEG.EFFECTIVE_END_DATE

		and ORG.organization_id=ASS.BUSINESS_UNIT_ID
		AND ORG.LANGUAGE = 'E'

		and S.person_id=ASS.person_id
		and S.PERIOD_OF_SERVICE_ID=ASS.PERIOD_OF_SERVICE_ID

		and PER.person_id= PNI.PERSON_ID(+)
		AND PNI.NATIONAL_IDENTIFIER_ID(+)= PERA.PRIMARY_NID_ID

		and PER.person_id(+)=PH.person_id
		AND PH.PHONE_ID(+)= PERA.PRIMARY_PHONE_ID

		and PER.person_id(+)= EM.person_id
		and EM.EMAIL_ADDRESS_ID(+)= PERA.PRIMARY_EMAIL_ID

		and ASS.person_id=PER.person_id
		and SYSDATE between ASS.EFFECTIVE_START_DATE and ASS.EFFECTIVE_END_DATE
		and ASS.PRIMARY_FLAG= 'Y'
		and ASS.SYSTEM_PERSON_TYPE in ('EMP','CWK')
		and ASS.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
		and SYSDATE between LEG.EFFECTIVE_START_DATE and LEG.EFFECTIVE_END_DATE

		--and ASS.person_id=300000002613180
		-- ASS.BUSINESS_UNIT_ID= :Parametro
		and LEG.HIGHEST_EDUCATION_LEVEL(+)=LOO.lookup_code and
		LOO.lookup_type='PER_HIGHEST_EDUCATION_LEVEL'