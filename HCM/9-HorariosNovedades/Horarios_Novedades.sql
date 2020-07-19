SELECT 	

		(CASE   
			
			--SCH_ASIGN: 	
			WHEN (to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (SCH_ASIGN.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (SCH_ASIGN.LAST_UPDATE_DATE)) 
			THEN SCH_ASIGN.CREATION_DATE
			
			ELSE NULL 
			END 
			
		)"FECHA_ALTA",
			
		(CASE   
			
			--SCH_ASIGN: 
			WHEN 	(
					to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') 		>= 	(SCH_ASIGN.LAST_UPDATE_DATE) 
					AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < 	(SCH_ASIGN.LAST_UPDATE_DATE)
					) 
			THEN 	SCH_ASIGN.LAST_UPDATE_DATE
			
			ELSE NULL 
			END 
			
		)"Fecha_Ultima_Modific",

		
		PER_P.person_number								as Person_Number,
		ASIGN.ASSIGNMENT_NUMBER							as Assign_Number,
		to_char(SCH_ASIGN.start_date,'DD/MM/YYYY')		as Fecha_de_inicio, 
		SCH_TRASL.schedule_name							as ID_Horario,	 --Campo NAME en Fusion. 									
		SCH_TRASL.SCHEDULE_ID							as SCHEDULE_ID	
		
FROM   	
		per_all_people_f 			PER_P,			--Person_id y person_number.
		per_all_assignments_m 		ASIGN,   		--Assignment_id para joinear en SCH_ASIGN.
		per_schedule_assignments 	SCH_ASIGN,     	--Work schedules asignados a las asignaciones de las personas.
		zmm_sr_schedules_tl 		SCH_TRASL		--Te da los work schedule names.

		
WHERE  	
		--Para que traiga empleados a futuro reemplazamos SYSDATE por el parametro :P_Effective_End_Date.
		:P_Effective_End_Date 		BETWEEN 	PER_P.effective_start_date AND PER_P.effective_end_date	
		AND :P_Effective_End_Date 	BETWEEN 	ASIGN.effective_start_date AND ASIGN.effective_end_date
		
		--PER_P a ASIGN:
		AND PER_P.person_id 				= 	ASIGN.person_id
		AND ASIGN.assignment_type 			= 	'E'
		AND ASIGN.effective_latest_change 	= 	'Y'
		AND ASIGN.primary_flag 				= 	'Y'

		--ASIGN a SCH_ASIGN:
		AND ASIGN.assignment_id				=	SCH_ASIGN.resource_id 	
		AND SCH_ASIGN.resource_type 		= 	'ASSIGN'	
		
		--SCH_ASIGN a SCH_TRASL:
		AND SCH_ASIGN.schedule_id			=	SCH_TRASL.schedule_id  
		AND SCH_TRASL.language 				= 	userenv('LANG')  
 
		and ((COALESCE(null, :P_Person_Number) is null) OR (PER_P.PERSON_NUMBER IN (:P_Person_Number)))

		AND  
		(
		( to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (SCH_ASIGN.LAST_UPDATE_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (SCH_ASIGN.LAST_UPDATE_DATE) )
		OR
		( to_timestamp(:P_Effective_End_Date,'yyyy-MM-dd hh24:mi:SS.FF9') >= (SCH_ASIGN.CREATION_DATE) AND to_timestamp(:P_Effective_Start_Date,'yyyy-MM-dd hh24:mi:SS.FF9') < (SCH_ASIGN.CREATION_DATE) )
		)
		
ORDER BY SCH_ASIGN.start_date, PER_P.person_number