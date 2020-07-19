select
	PAPF.PERSON_NUMBER 		AS Num_Trabajador,
	PER.PERSON_ID			AS Person_ID_2,			
	PER.DATE_OF_BIRTH 		AS Fecha_Nacimiento,
	PER.COUNTRY_OF_BIRTH 	AS Pais_Nacimiento,
	PER.TOWN_OF_BIRTH 		AS Municipio_Nacimiento,
	NAME.FULL_NAME 			AS Nombre_Y_Apellido,
	
	--EMAILS:
	(	select 	EM.EMAIL_ADDRESS
		from 	PER_EMAIL_ADDRESSES EM
		where   PER.person_id = EM.person_id
				AND EM.EMAIL_TYPE='W1'
				and rownum = 1
	) 	AS Email_Coorporativo,			

	(	select 	EM2.EMAIL_ADDRESS
		from 	PER_EMAIL_ADDRESSES EM2
		where   PER.person_id= EM2.person_id
				AND EM2.EMAIL_TYPE='H1'
				and rownum = 1
	) AS Email_Personal,				

	--TELEFONOS:

	(	Select 	PH.PHONE_NUMBER 
		FROM 	PER_PHONES PH
		where 	PER.person_id=PH.person_id 
				and PH.PHONE_TYPE= 'H1'
				and rownum = 1
	) AS TelefonoResidencia,			--NO TIENE

	(	SELECT 	PH2.PHONE_NUMBER
		FROM 	PER_PHONES PH2
		where 	PER.person_id = PH2.person_id
				AND PH2.PHONE_TYPE= 'HM'
				and rownum = 1
	) AS NumCelular,					

	(	SELECT 	PH3.PHONE_NUMBER
		FROM 	PER_PHONES PH3
		where 	PER.person_id = PH3.person_id
				AND PH3.PHONE_TYPE= 'W1'
				and rownum = 1
	) AS TelefonoOficina,				
	
	(	Select 	PH4.AREA_CODE 
		FROM 	PER_PHONES PH4
		where 	PER.person_id=PH4.person_id 
				and PH4.PHONE_TYPE= 'H1' 
				and rownum = 1
	) AS CodAreaTelefono,				--NO TIENE
	
		(	Select 	PH5.COUNTRY_CODE_NUMBER 
		FROM 	PER_PHONES PH5
		where 	PER.person_id=PH5.person_id 
				and PH5.PHONE_TYPE= 'H1'
				and rownum = 1
	) AS CodPaisTelefono,				--NO TIENE
	
	(	select 	PH6.phone_number 
		from 	PER_PHONES PH6 
		where 	PH6.person_id=CON.contact_person_id
	) AS TelefonoEMERG,
	
	CON.CONTACT_TYPE 			AS Tipo_Contacto, 
	CON.EMERGENCY_CONTACT_FLAG 	AS Es_Contacto_Emerg,
	CON.CONTACT_PERSON_ID		AS Contact_Person_ID

from  
	PER_ALL_PEOPLE_F PAPF,
	PER_PERSONS PER,
	PER_PERSON_NAMES_F NAME,
	PER_CONTACT_RELSHIPS_F CON
	
where 
	PAPF.person_number	=	'1030578205'     --'51752634'
	AND PAPF.person_id	=	PER.person_id
	and NAME.person_id 	=	PER.person_id 
	and NAME.NAME_TYPE 	= 	'CO'   			--Ver porque esto.
	and SYSDATE between NAME.EFFECTIVE_START_DATE and NAME.EFFECTIVE_END_DATE  --Ver porque esto. 
	AND CON.person_id(+)=PAPF.person_id