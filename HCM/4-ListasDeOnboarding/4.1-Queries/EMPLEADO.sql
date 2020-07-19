--En realidad no son candidatos, son simplemente empleados. 
SELECT 
	PPNF.PERSON_ID,
	PPNF.FULL_NAME, 
	PNI.NATIONAL_IDENTIFIER_TYPE,
	PNI.NATIONAL_IDENTIFIER_NUMBER,
	PN.NAME 											As Position, 				--Posicion de la ultima asignacion activa (por esto hacemos los filtros de fecha en el where).
	to_char(ASS.effective_start_date,'DD/MM/YYYY')		As Fecha_Ultima_Posicion,	--Fecha_Ultima_Asign. NO la usamos en el reporte pero la mostramos para analisis. 			
	--to_char(SER.ORIGINAL_DATE_OF_HIRE,'DD/MM/YYYY')  	As Fecha_Antiguedad,		
	(	SELECT  to_char(MIN(B.effective_start_date),'DD/MM/YYYY')	 
		FROM 	PER_ALL_ASSIGNMENTS_M B 
		WHERE 	B.PERSON_ID (+) = PPNF.PERSON_ID
				--AND ASS.PRIMARY_FLAG= 'Y' 			--Ver si dejarlo o no
				--Como aca NO ponemos el filtro de fechas efectivas nos fijamos TODAS las asignaciones. 
		Group by B.PERSON_ID					
	)  													As Fecha_Solicitud, 			--Fecha_Primera_Asign. Fecha de Inicio de la asignación más vieja 
																						--(la 1ra de todas, NO la actual). 
	DECODE(ASS.Business_unit_id, 300000002580231, 'Bucaramanga',300000002580393, 'Medellin',
			300000002580474, 'Villavicencio',300000002580312,'Tunja',300000002580150,'Bogota') 
														AS Sede
	
FROM 
	PER_PERSON_NAMES_F			PPNF,
	PER_NATIONAL_IDENTIFIERS 	PNI,
	PER_ALL_ASSIGNMENTS_M 		ASS,
	HR_ALL_POSITIONS_F_TL 		PN
	--PER_PERIODS_OF_SERVICE 		SER   
	
WHERE 
	SYSDATE BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE
	AND PPNF.NAME_TYPE = 'GLOBAL'
	AND PNI.PERSON_ID(+) = PPNF.PERSON_ID
	AND PPNF.PERSON_ID = :pColaborador  --Entra el ID.
	--PER Y ASS:
	--TODOS los (+) es porque la persona puede NO tener una asignación activa primaria... entonces todos los (+) pueden ser NULL!:
	AND PPNF.PERSON_ID					= ASS.PERSON_ID (+)
	AND ASS.PRIMARY_FLAG 	(+)			= 'Y' 	 							--Para filtrar solo la asignacion principal (para la posicion).
	AND ASS.ASSIGNMENT_STATUS_TYPE 	(+) = 'ACTIVE'
	--AND ASS.PRIMARY_ASSIGNMENT_FLAG	 = 'Y'  							--VER. 
	AND trunc(SYSDATE) BETWEEN ASS.EFFECTIVE_START_DATE (+) AND ASS.EFFECTIVE_END_DATE (+) --Para filtrar solo la asignacion activa al dia de hoy (para la posicion).
	
	--PN:
	AND PN.POSITION_ID	(+)			= ASS.POSITION_ID 
	AND PN.LANGUAGE		(+)			= USERENV ('LANG')
	--SER:
	--AND SER.person_id	 (+)			= ASS.person_id  
	--AND SER.PERIOD_OF_SERVICE_ID	(+) = ASS.PERIOD_OF_SERVICE_ID 