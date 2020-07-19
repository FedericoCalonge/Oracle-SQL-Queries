SELECT 	
	PER_P.person_number								as Person_Number,
	ASSIGNMENT_NUMBER								as Assign_Number,
	to_char(SCH_ASIGN.start_date,'DD/MM/YYYY')		as Fecha_de_inicio, 
	SCH_TRASL.schedule_name							as ID_Horario,	 --Campo NAME en Fusion. 									
	SCH_TRASL.SCHEDULE_ID							as SCHEDULE_ID	
		
FROM   	
	per_all_people_f 			PER_P,			--Person_id y person_number.
	per_all_assignments_m 		ASIGN,   		--Assignment_id para joinear en SCH_ASIGN.
	per_schedule_assignments 	SCH_ASIGN,     	--Work schedules asignados a las asignaciones de las personas.
	zmm_sr_schedules_tl 		SCH_TRASL		--Te da los work schedule names. Tambien esta ZMM_SR_SCHEDULES_VL.. VER si hay algo mas ahi. 

		
WHERE  	1=1
	AND TRUNC (SYSDATE) BETWEEN PER_P.effective_start_date AND PER_P.effective_end_date		
	--PER_P a ASIGN:
	AND PER_P.person_id 				= 	ASIGN.person_id
	AND ASIGN.assignment_type 			= 	'E'
	AND ASIGN.effective_latest_change 	= 	'Y'
	AND ASIGN.primary_flag 				= 	'Y'
	AND TRUNC (SYSDATE) BETWEEN 	ASIGN.effective_start_date AND ASIGN.effective_end_date
	--ASIGN a SCH_ASIGN:
	AND ASIGN.assignment_id				=	SCH_ASIGN.resource_id 	
	AND SCH_ASIGN.resource_type 		= 	'ASSIGN'	
	
	AND to_char(:P_Start_Date, 'YYYY/MM/DD') BETWEEN TO_CHAR(SCH_ASIGN.start_date, 'YYYY/MM/DD') AND TO_CHAR(SCH_ASIGN.end_date, 'YYYY/MM/DD')
	
	--SCH_ASIGN a SCH_TRASL:
	AND SCH_ASIGN.schedule_id			=	SCH_TRASL.schedule_id  
	AND SCH_TRASL.language 				= 	userenv('LANG')  
	--Para una persona en especifico:
	and PER_P.person_number 			IN (	:P_Person_Number )  

ORDER BY SCH_ASIGN.start_date, PER_P.person_number

