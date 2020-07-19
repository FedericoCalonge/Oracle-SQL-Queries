select distinct 

		--ASS.assignment_id, 
		ASS.business_unit_id "SEDE",  --Union con Directores.BUSINESS_UNIT_ID
		ASS.person_id, 
		NAME.FIRST_NAME||' '||NAME.MIDDLE_NAMES||' '||NAME.LAST_NAME||' '||NAME.NAM_INFORMATION1 "NOMBRECOMPLETO",
		SER.ATTRIBUTE1 "TIPOCONTRATO",
		DEP.name "DEPARTAMENTO_NAME",
		NID.NATIONAL_IDENTIFIER_NUMBER "DOCUMENTO_DE_IDENTIDAD",
		NATIONAL_IDENTIFIER_TYPE "TIPO_DOCUMENTO",

		ROUND(SAL.SALARY_AMOUNT,0)  "SUELDOS",
		TO_CHAR(SAL.DATE_FROM, 'DD/MM/YYYY')		"Date_From_SAL",
		POS.name "POSITION_NAME",

		TO_CHAR(SER.DATE_START, 'DD/MM/YYYY') "Date_Start_SER",
		TO_CHAR(SER.ORIGINAL_DATE_OF_HIRE, 'DD/MM/YYYY') "Fecha_Antiguedad_SER",

		--Antes acá era todo con "ORIGINAL_DATE_OF_HIRE", pero NO, esa seria la antiguedad, enrealidad es la fecha DATE_START (ya que es la del último contrato vigente):
		Extract(day from SER.DATE_START)||' de '||
		(CASE WHEN extract(month from SER.DATE_START)=1 then 'Enero'
		WHEN extract(month from SER.DATE_START)=1 then 'Enero'
		WHEN extract(month from SER.DATE_START)=2 then 'Febrero'
		WHEN extract(month from SER.DATE_START)=3 then 'Marzo'
		WHEN extract(month from SER.DATE_START)=4 then 'Abril'
		WHEN extract(month from SER.DATE_START)=5 then 'Mayo'
		WHEN extract(month from SER.DATE_START)=6 then 'Junio'
		WHEN extract(month from SER.DATE_START)=7 then 'Julio'
		WHEN extract(month from SER.DATE_START)=8 then 'Agosto'
		WHEN extract(month from SER.DATE_START)=9 then 'Septiembre'
		WHEN extract(month from SER.DATE_START)=10 then 'Octubre'
		WHEN extract(month from SER.DATE_START)=11 then 'Noviembre'
		WHEN extract(month from SER.DATE_START)=12 then 'Diciembre'
		ELSE NULL END)||' de '||Extract(year from SER.DATE_START) "FECHA_INICIO_CONTRATO",

		(CASE WHEN ASS.PROJECTED_ASSIGNMENT_END is not null then
		'El contrato de trabajo actual tiene vigencia hasta el '||
		Extract(day from ASS.PROJECTED_ASSIGNMENT_END)||' de '||
		(CASE WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=1 then 'Enero'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=1 then 'Enero'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=2 then 'Febrero'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=3 then 'Marzo'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=4 then 'Abril'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=5 then 'Mayo'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=6 then 'Junio'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=7 then 'Julio'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=8 then 'Agosto'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=9 then 'Septiembre'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=10 then 'Octubre'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=11 then 'Noviembre'
		WHEN extract(month from ASS.PROJECTED_ASSIGNMENT_END)=12 then 'Diciembre'
		ELSE NULL END)||' de '||Extract(year from ASS.PROJECTED_ASSIGNMENT_END) 
		ELSE NULL END)

		"FECHA_FIN_CONTRATO",

		Extract(year from sysdate) "AÑO",

		(CASE WHEN extract(month from sysdate)=1 then 'Enero'
		WHEN extract(month from sysdate)=1 then 'Enero'
		WHEN extract(month from sysdate)=2 then 'Febrero'
		WHEN extract(month from sysdate)=3 then 'Marzo'
		WHEN extract(month from sysdate)=4 then 'Abril'
		WHEN extract(month from sysdate)=5 then 'Mayo'
		WHEN extract(month from sysdate)=6 then 'Junio'
		WHEN extract(month from sysdate)=7 then 'Julio'
		WHEN extract(month from sysdate)=8 then 'Agosto'
		WHEN extract(month from sysdate)=9 then 'Septiembre'
		WHEN extract(month from sysdate)=10 then 'Octubre'
		WHEN extract(month from sysdate)=11 then 'Noviembre'
		WHEN extract(month from sysdate)=12 then 'Diciembre'
		ELSE NULL END) "MESLETRAS",

		Extract(day from Sysdate) "DIA",
		(CASE WHEN extract(day from sysdate)=1 THEN 'un'
		WHEN extract(day from sysdate)=2 THEN 'dos'
		WHEN extract(day from sysdate)=3 THEN 'tres'
		WHEN extract(day from sysdate)=4 THEN 'cuatro'
		WHEN extract(day from sysdate)=5 THEN 'cinco'
		WHEN extract(day from sysdate)=6 THEN 'seis'
		WHEN extract(day from sysdate)=7 THEN 'siete'
		WHEN extract(day from sysdate)=8 THEN 'ocho'
		WHEN extract(day from sysdate)=9 THEN 'nueve'
		WHEN extract(day from sysdate)=10 THEN 'diez'
		WHEN extract(day from sysdate)=11 THEN 'once'
		WHEN extract(day from sysdate)=12 THEN 'doce'
		WHEN extract(day from sysdate)=13 THEN 'trece'
		WHEN extract(day from sysdate)=14 THEN 'catorce'
		WHEN extract(day from sysdate)=15 THEN 'quince'
		WHEN extract(day from sysdate)=16 THEN 'dieciseis'
		WHEN extract(day from sysdate)=17 THEN 'diecisiete'
		WHEN extract(day from sysdate)=18 THEN 'dieciocho'
		WHEN extract(day from sysdate)=19 THEN 'diecinueve'
		WHEN extract(day from sysdate)=20 THEN 'veinte'
		WHEN extract(day from sysdate)=21 THEN 'veintiun'
		WHEN extract(day from sysdate)=22 THEN 'veintidos'
		WHEN extract(day from sysdate)=23 THEN 'veintitres'
		WHEN extract(day from sysdate)=24 THEN 'veinticuatro'
		WHEN extract(day from sysdate)=25 THEN 'veinticinco'
		WHEN extract(day from sysdate)=26 THEN 'veintiseis'
		WHEN extract(day from sysdate)=27 THEN 'veintisiete'
		WHEN extract(day from sysdate)=28 THEN 'veintiocho'
		WHEN extract(day from sysdate)=29 THEN 'veintinueve'
		WHEN extract(day from sysdate)=30 THEN 'treinta'
		WHEN extract(day from sysdate)=31 THEN 'treinta y un'
		ELSE NULL END) "DIALETRAS",

		(CASE WHEN :Int is not null THEN
		' a solicitud del interesado '||:Int
		ELSE
		NULL
		END) "TEXTO",

		CONTRATO.DESCRIPTION,
		'La vigencia es hasta el ' TEXTO2

from 
		per_all_assignments_f ASS, 
		per_person_names_f NAME, 
		PER_NATIONAL_IDENTIFIERS NID,
		CMP_SALARY SAL,
		PER_PERIODS_OF_SERVICE SER,
		HR_ALL_POSITIONS_F_TL POS,
		hr_organization_units_f_tl DEP,
		CMP_SALARY_SECURED_LIST_V SAL_Seguridad,
		(select flex_value,DESCRIPTION from fnd_flex_values_vl 
		where value_category= 'USTA_TIPO_CONTRATO'
		and enabled_flag='Y') CONTRATO

where
		CONTRATO.FLEX_VALUE=SER.attribute1 
		and TO_DATE(ASS.EFFECTIVE_END_DATE,'YYYY-MM-DD')=TO_DATE('4712-12-31','YYYY-MM-DD')

		and ASS.person_id=NAME.person_id
		and ASS.location_id is not null
		and ASS.person_id=NID.person_id
		and ASS.person_id=SAL.person_id
		and ASS.person_id=SER.person_id
		and ASS.position_id=POS.position_id and POS.language='E'
		and ASS.organization_id=DEP.organization_id and DEP.language='E'
		and ASS.SYSTEM_PERSON_TYPE= 'EMP'

		and NID.NATIONAL_IDENTIFIER_TYPE in ('CC','CE','TI')
		and NID.NATIONAL_IDENTIFIER_NUMBER=:Cedula

		and NAME.name_type='GLOBAL' 

		and trunc(SYSDATE) BETWEEN NAME.EFFECTIVE_START_DATE AND NAME.EFFECTIVE_END_DATE 
		and TO_DATE(SAL.DATE_TO,'YYYY-MM-DD')=TO_DATE('4712-12-31','YYYY-MM-DD')

		--Filtros agregados:
		AND ASS.PRIMARY_FLAG 				= 'Y' 	 									--Para filtrar solo la asignacion principal (para la posicion).
		AND ASS.ASSIGNMENT_STATUS_TYPE 	    = 'ACTIVE'
		AND ASS.PRIMARY_ASSIGNMENT_FLAG	 	= 'Y'  										--VER. 
		AND trunc(SYSDATE) BETWEEN ASS.EFFECTIVE_START_DATE AND ASS.EFFECTIVE_END_DATE  --Para filtrar solo la asignacion activa al dia de hoy (para la posicion).
		and ASS.assignment_id = SAL.assignment_id   									--Salario con la asignacion correspondiente. 
		--and SER.ACTUAL_TERMINATION_DATE = NULL 
		and SER.PERIOD_OF_SERVICE_ID=ASS.PERIOD_OF_SERVICE_ID  							--Para que nos traiga el último contrato.

		--Join de Seguridad:
		and SAL.SALARY_ID = SAL_Seguridad.SALARY_ID