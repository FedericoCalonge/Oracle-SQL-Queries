SELECT 
    
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE EMPLEADO:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	PPOS.ACTUAL_TERMINATION_DATE,
	PERA.PERSON_ID										as Person_ID,

	PPNF.FULL_NAME										as Name_Colaborador, 		--Nome do Colaborador.
	ASS.ASSIGNMENT_NUMBER								as Assignment_Number,
	ORG_T.NAME											as Legal_E_Name,   
	DEP.NAME											as Departamento,
	JOBS_TL.NAME										as Cargo,
	POS.POSITION_CODE||'  '||POS_TL.NAME				as Posicion, 				--Posição. 	
	PPNF_SUP.FULL_NAME 									as Manager, 				--Gestor/Supervisor   					
		
	(	SELECT  to_char(MIN(B.effective_start_date),'DD/MM/YYYY')	 
		FROM 	PER_ALL_ASSIGNMENTS_M B 
		WHERE 	B.PERSON_ID (+) = PPNF.PERSON_ID
				--AND ASS.PRIMARY_FLAG= 'Y' 			--Ver si dejarlo o no
				--Como aca NO ponemos el filtro de fechas efectivas nos fijamos TODAS las asignaciones. 
		Group by B.PERSON_ID					
	)  													as Fecha_De_Contratacion, 	--Data de Admissão  
	
	--Lógica fecha de renuncia: los que renunciaron tienen el campo PPOS.actual_termination_date con un valor que es < fecha de hoy. Y los que estan como empleados > :
	CASE
		WHEN PPOS.actual_termination_date < TRUNC(SYSDATE)	THEN to_char(PPOS.ACTUAL_TERMINATION_DATE,'DD/MM/YYYY')	--Desligado. 
		ELSE 'Não corresponde'																						--Empleado actual NO desligado. 
	END Fecha_Desligamiento,  --Data de Demissão / Fecha de renuncia.  

	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE LAS TAREAS Y LAS CHECKLISTS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	CHECKLIST.PACHECK_TL_CHECKLIST_NAME,
	TAREAS.TASK_NAME,
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE CUESTIONARIOS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	CUESTIONARIO_TL.NAME 						as NOMBRE_QTNR,

	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE PREGUNTAS Y RESPUESTAS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	decode (QSTNR_QUESTIONS.MANDATORY,
			'Y', 'Sim',
			'N', 'Não'
			) Obligatoria,
			
	QUESTIONS_TL.QUESTION_TEXT,
	
	decode (QUESTIONS_B.QUESTION_TYPE,
			'TEXT', 'Texto',
			'1CHOICE', 'Lista de opções'
			) TIPO_PREGUNTA,

	--Decode para que me traiga el RTA_OTRAS_NO_TEXTO o RTA_TEXTO dependiendo del QUESTIONS_B.QUESTION_TYPE:
	decode (QUESTIONS_B.QUESTION_TYPE,
			'TEXT', QSTN_RESP.ANSWER_TEXT,
			'1CHOICE',  QSTN_ANSWERS.LONG_TEXT
			) RESPUESTA,
	
	QSTN_RESP.CREATION_DATE			as creation_date_1 --Para ordenar por este campo.
		
FROM 
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--TABLAS DE EMPLEADO:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	PER_ALL_PEOPLE_F 				PERA,
	PER_PERSON_NAMES_F				PPNF,
	PER_ASSIGNMENT_SUPERVISORS_F_V 	SUPERV,  			--Para el Supervisor/Manager/Jefe/Gestor.
	PER_PERSON_NAMES_F				PPNF_SUP,			--Para el nombre del Gestor.
	PER_ALL_ASSIGNMENTS_M 			ASS,
	PER_JOBS 						JOBS,
	PER_JOBS_F_TL					JOBS_TL,
	HR_ALL_POSITIONS_F				POS,
	HR_ALL_POSITIONS_F_TL 			POS_TL,
	--hr_legal_entities				LENTITY,       		--O xle_entity_profiles.  --Al final NO la use, use ORG para esto. 
	HR_ALL_ORGANIZATION_UNITS_F 	ORG,        
	hr_organization_units_f_tl 		ORG_T, 	
	hr_organization_units_f_tl 		DEP,
	per_periods_of_service 			PPOS,				--Para traer las fechas de despido de los desligados. 
	
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--TABLAS DE LAS TAREAS Y LAS CHECKLISTS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Tabla CHECKLIST:
		(	
		SELECT
				PACHECK.ALLOCATED_CHECKLIST_ID,
				PACHECK_TL.CHECKLIST_NAME		PACHECK_TL_CHECKLIST_NAME,
				PACHECK_TL.DESCRIPTION,
				PACHECK_TL.MESSAGE_TITLE,
				PACHECK_TL.MESSAGE_TEXT,
				PACHECK_TL.CHECKLIST_DETAILS,
				PACHECK.LEGISLATION_CODE,
				PACHECK.CHECKLIST_ID,
				PACHECK.PERSON_ID,
				PAPF.PERSON_NUMBER,
				PACHECK.CHECKLIST_NAME,
				PACHECK.DESCRIPTION BASE0_DESCRIPTION,
				PACHECK.CHECKLIST_STATUS,
				PACHECK.ALLOCATION_DATE,
				PACHECK.COMPLETED_ON,
				PACHECK.ALLOCATION_DETAILS
				
		FROM	PER_ALLOCATED_CHECKLISTS 		PACHECK,
				PER_ALLOCATED_CHECKLISTS_TL 	PACHECK_TL,
				PER_ALL_PEOPLE_F 				PAPF
		WHERE
				PACHECK.ALLOCATED_CHECKLIST_ID = PACHECK_TL.ALLOCATED_CHECKLIST_ID
				AND PACHECK_TL.LANGUAGE = USERENV ('LANG')
				AND PAPF.PERSON_ID = PACHECK.PERSON_ID 
				AND SYSDATE BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE         
				
				--Parametro lista de tareas:
				AND ((COALESCE(null, :pCheckLists) is null) OR (PACHECK.CHECKLIST_ID IN (:pCheckLists)))
		) 
		CHECKLIST,
	
	--Tabla TAREAS:
		(	
		SELECT
				(	SELECT 	MAX(PACHECK_TL.TASK_NAME) 
					FROM 	PER_ALLOCATED_TASKS_TL PACHECK_TL 
					WHERE 	PACHECK_TL.ALLOCATED_TASK_ID = PATASKS.ALLOCATED_TASK_ID 
							AND PACHECK_TL.LANGUAGE = USERENV ('LANG') 
				) TASK_NAME,
				
				PATASKS.ALLOCATED_CHECKLIST_ID,
				
				--Sacamos el tipo de tarea viendo los lookups:
				(	select 	LOOKUPS.MEANING				--Por las dudas poner distinct? o MAX?
					from 	fnd_lookup_values LOOKUPS
					where 	PATASKS.ACTION_TYPE = LOOKUPS.LOOKUP_CODE
							and LOOKUPS.LOOKUP_TYPE = 'ORA_PER_CHK_TASK_ACTION_TYPE'
							and LOOKUPS.LANGUAGE = USERENV ('LANG')
				) TASK_TYPE,
				
				CASE 
				
					WHEN PATASKS.RESPONSIBILITY_TYPE 	IN ('ORA_INITIATOR', 'ORA_ADHOC_USER', 'ORA_RESP_TYPE', 'ORA_WORKER', 'ORA_EHS_REP', 'ORA_LN_MGR')
														THEN	(	select 	LOOKUPS.MEANING    --Por las dudas poner distinct? o MAX?
																	from 	fnd_lookup_values  			LOOKUPS
																	where 	PATASKS.RESPONSIBILITY_TYPE = LOOKUPS.LOOKUP_CODE
																			and LOOKUPS.LOOKUP_TYPE 	= 'ORA_PER_CHECKLIST_PERFORMERS'
																			and LOOKUPS.LANGUAGE 		= USERENV ('LANG')
																 )
																 
					ELSE  										(	select 	LOOKUPS.MEANING    --Por las dudas poner distinct? o MAX?
																	from 	fnd_lookup_values  			LOOKUPS
																	where 	PATASKS.RESPONSIBILITY_TYPE = LOOKUPS.LOOKUP_CODE
																			and LOOKUPS.LOOKUP_TYPE 	= 'PER_RESPONSIBILITY_TYPES'
																			and LOOKUPS.LANGUAGE 		= USERENV ('LANG')
																)
					--ELSE 'Não relata'	--No Informa.
				END RESPONSABILIDAD_LOOKUP,
				
				TO_CHAR(PATASKS.TARGET_START_DATE, 'DD/MM/YYYY') 	INICIO,
				TO_CHAR(PATASKS.TARGET_END_DATE, 'DD/MM/YYYY') 		FIN,
				PATASKS.CREATION_DATE 								as CREATION_DATE,
				--TO_CHAR(PATASKS.CREATION_DATE, 'DD/MM/YYYY') CREATION_DATE
				PATASKS.STATUS										as TASK_STATUS,
				PATASKS.ALLOCATED_TASK_ID,
				
				--Campos de TAREAS_QUEST:
				TAREAS_QUEST.TASK_IN_CHECKLIST_CODE,
				TAREAS_QUEST.CHECKLIST_ID,
				TAREAS_QUEST.RESPONSIBILITY_TYPE,
				TAREAS_QUEST.ACTION_TYPE,
				TAREAS_QUEST.QUESTIONNAIRE_ID,
				TAREAS_QUEST.TASK_IN_CHECKLIST_ID
				
		FROM	PER_ALLOCATED_TASKS 			PATASKS,
				PER_TASKS_IN_CHECKLIST_B		TAREAS_QUEST    --This table records the tasks within the checklist templates.
		
		WHERE	
				PATASKS.STATUS = 'COM' --Filtro de solo las tareas COMPLETAS. En el Reporte 1 era solo tareas pendentes ('INI').
				and PATASKS.TASK_IN_CHECKLIST_ID = TAREAS_QUEST.TASK_IN_CHECKLIST_ID
				and TAREAS_QUEST.ACTION_TYPE = 'ORA_CHK_QUESTIONNAIRE' 
		) 	
		TAREAS,
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		--TABLAS DE CUESTIONARIOS:
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
		HRQ_QUESTIONNAIRES_B    CUESTIONARIO_B,
		HRQ_QUESTIONNAIRES_TL 	CUESTIONARIO_TL, --Solo para traer el nombre cuestionario. 
		HRQ_QSTNR_PARTICIPANTS 	QSTNR_PARTICIP,

		--------------------------------------------------------------------------------------------------------------------------------------------------------------
		--TABLAS DE PREGUNTAS Y RESPUESTAS:
		--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
		HRQ_QSTNR_RESPONSES		QSTNR_RESP,	
		HRQ_QSTN_RESPONSES		QSTN_RESP,				--Rtas asociadas a las preguntas.
		HRQ_QSTNR_QUESTIONS 	QSTNR_QUESTIONS, 		--Tabla de preguntas.
		HRQ_QUESTIONS_B			QUESTIONS_B,			--Tabla de preguntas 2.
		HRQ_QUESTIONS_TL 		QUESTIONS_TL,			--Tabla de preguntas trasladadas.
		HRQ_QSTN_ANSWERS_TL 	QSTN_ANSWERS
		
WHERE 

	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--WHERE DE EMPLEADO:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--PERA Y PPNF:
	PERA.PERSON_ID 		= PPNF.PERSON_ID
	AND PPNF.NAME_TYPE 	= 'GLOBAL'
	AND SYSDATE BETWEEN PERA.EFFECTIVE_START_DATE AND PERA.EFFECTIVE_END_DATE
	AND SYSDATE BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE
	
	--SUPERV y PPNF_SUP:
	AND PERA.person_id 				= SUPERV.person_id  (+)			--Macheo la persona en la tabla SUPERV con el ID de person.
	AND SUPERV.manager_id			= PPNF_SUP.person_id (+)  		--Con el ID de manager para ese person_id macheo en la tabla de nombres para obtener el nombre del manager. 
	AND TRUNC(SYSDATE) BETWEEN PPNF_SUP.effective_start_date (+) AND PPNF_SUP.effective_end_date (+)
	AND TRUNC(SYSDATE) BETWEEN SUPERV.effective_start_date (+) AND SUPERV.effective_end_date (+)
	AND PPNF_SUP.NAME_TYPE(+) 		= 'GLOBAL'
	AND	SUPERV.PRIMARY_FLAG(+) 		= 'Y'

	--ASS:
	--TODOS los (+) es porque la persona puede NO tener una asignación activa primaria... entonces todos los (+) pueden ser NULL!:
	AND PERA.PERSON_ID					= ASS.PERSON_ID (+)
	--AND ASS.PRIMARY_FLAG 	(+)			= 'Y' 	 							--Para filtrar solo la asignacion principal (para la posicion).
	AND ASS.ASSIGNMENT_STATUS_TYPE 	(+) = 'ACTIVE'
	AND ASS.PRIMARY_ASSIGNMENT_FLAG	 (+) = 'Y'  							--VER. 
	AND trunc(SYSDATE) BETWEEN ASS.EFFECTIVE_START_DATE (+) AND ASS.EFFECTIVE_END_DATE (+) --Para filtrar solo la asignacion activa al dia de hoy (para la posicion).
	
	--JOBS y JOBS_TL:
	AND ASS.JOB_ID					=	JOBS.JOB_ID  (+) 		--Tenga o no job me lo trae igual. 
	AND	JOBS.JOB_ID					=	JOBS_TL.JOB_ID  (+)
	AND JOBS_TL.LANGUAGE	(+)		= 	USERENV ('LANG') 	--VER LENGUAJE, antes era 'E', creo que seria GLOBAL o USERENV ('LANG') ?
				
	--POS y POS_TL:
	AND ASS.POSITION_ID  			= 	POS.POSITION_ID (+)
	AND POS.POSITION_ID 			=	POS_TL.POSITION_ID  (+)
	AND POS_TL.LANGUAGE		(+)		= 	USERENV ('LANG')
	--Antes no había filtrado por estas (VER porque):
	AND trunc(SYSDATE) BETWEEN POS.EFFECTIVE_START_DATE (+)	AND POS.EFFECTIVE_END_DATE (+) 
	AND trunc(SYSDATE) BETWEEN POS_TL.EFFECTIVE_START_DATE  (+)	AND POS_TL.EFFECTIVE_END_DATE   (+) 
	
	--LENTITY (Antes) / ORG y ORG_T (ahora):
	And ASS.LEGAL_ENTITY_ID 		= 	ORG.ORGANIZATION_ID (+)		--Tenga o no legal_entity_id me lo trae igual.
	and ORG.ORGANIZATION_ID			=	ORG_T.ORGANIZATION_ID (+)
	and ORG_T.LANGUAGE	(+)			=  	USERENV ('LANG')
	AND SYSDATE BETWEEN ORG.EFFECTIVE_START_DATE (+) AND ORG.EFFECTIVE_END_DATE (+)
	AND SYSDATE BETWEEN ORG_T.EFFECTIVE_START_DATE (+) AND ORG_T.EFFECTIVE_END_DATE (+)

	--DEP:
	AND DEP.organization_id(+)		=	ASS.ORGANIZATION_ID		--Puede tener o no departamento.
	AND DEP.LANGUAGE 	(+)			= 	USERENV ('LANG')  
	
	--PPOS:
	AND PERA.person_id = PPOS.person_id								--TODOS tienen un Period of service (sean empleados o desempleados)... entonces NO ponemos (+)
	AND PPOS.period_of_service_id = (	SELECT 	MAX(period_of_service_id)
											FROM 	per_periods_of_service
											WHERE 	person_id = PERA.person_id
									)		
	-------------------------------------------------------------------------------------------------
	
	--Traigo colaboradores que SOLO tengan checklists asociadas (y uso el parametro de checklist): 
	AND PERA.PERSON_ID IN
		(	SELECT 	distinct
					CHECKL.PERSON_ID
			FROM 	PER_ALLOCATED_CHECKLISTS 			CHECKL,
					PER_ALLOCATED_CHECKLISTS_TL 		PACHECK_TL
			WHERE 	PERA.PERSON_ID 						= CHECKL.PERSON_ID
					AND CHECKL.ALLOCATED_CHECKLIST_ID 	= PACHECK_TL.ALLOCATED_CHECKLIST_ID
					AND PACHECK_TL.LANGUAGE = USERENV ('LANG')
					--Parametro lista de tareas:
					AND ((COALESCE(null, :pCheckLists) is null) OR (CHECKL.CHECKLIST_ID IN (:pCheckLists)))				
		)
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--WHERE DE LAS TAREAS Y LAS CHECKLISTS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND CHECKLIST.ALLOCATED_CHECKLIST_ID = TAREAS.ALLOCATED_CHECKLIST_ID --Join tabla CHECKLIST con tabla TAREAS.
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--JOIN ENTRE EMPLEADO Y TAREAS Y LAS CHECKLISTS:   (Este join antes lo tenía directamente en Cloud)
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND PERA.PERSON_ID	=  CHECKLIST.PERSON_ID
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--WHERE DE LOS CUESTIONARIOS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND CUESTIONARIO_B.QUESTIONNAIRE_ID				= 	CUESTIONARIO_TL.QUESTIONNAIRE_ID 
	AND CUESTIONARIO_TL.LANGUAGE 					= 	USERENV ('LANG')
	AND CUESTIONARIO_TL.SOURCE_LANG					=   USERENV ('LANG')
	AND CUESTIONARIO_TL.QUESTIONNAIRE_ID 			=   QSTNR_PARTICIP.QUESTIONNAIRE_ID
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--WHERE DE PREGUNTAS Y RESPUESTAS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND QSTNR_RESP.QSTNR_RESPONSE_ID	=	QSTN_RESP.QSTNR_RESPONSE_ID
	AND QSTN_RESP.QSTNR_QUESTION_ID		= 	QSTNR_QUESTIONS.QSTNR_QUESTION_ID	
	AND QSTNR_QUESTIONS.QUESTION_ID		=	QUESTIONS_B.QUESTION_ID
	AND QUESTIONS_B.QUESTION_ID     	=    QUESTIONS_TL.QUESTION_ID
	AND QUESTIONS_TL.LANGUAGE 			= 	USERENV ('LANG')
	AND QUESTIONS_TL.SOURCE_LANG 		= 	USERENV ('LANG')

	AND QSTN_RESP.QSTN_ANSWER_ID		= QSTN_ANSWERS.QSTN_ANSWER_ID(+) --Right join (como tambien abajo) para que me traiga el RTA_OTRAS_NO_TEXTO 
																		 --tenga o no QSTN_ANSWER_ID el campo)... Asi puedo ver todas las respuestas: RTA_OTRAS_NO_TEXTO y RTA_TEXTO.
	AND QSTN_ANSWERS.LANGUAGE(+) 		= USERENV ('LANG')	
	
	--Filtro solo los que tengan respuestas hechas (las NULAS las eliminamos):
	AND ( (QSTN_RESP.ANSWER_TEXT IS NOT NULL) or (QSTN_ANSWERS.LONG_TEXT IS NOT NULL) )
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--JOIN ENTRE EMPLEADO-TAREAS-CHECKLISTS   CON   CUESTIONARIOS  y CUESTIONARIOS   CON   PREGUNTASYRTAS:   (Este join antes lo tenía directamente en Cloud)
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND TAREAS.QUESTIONNAIRE_ID 					= CUESTIONARIO_B.QUESTIONNAIRE_ID
	AND CHECKLIST.PERSON_ID							= QSTNR_PARTICIP.SUBJECT_ID				--Join persona de la checklist al cuestionario. 
	AND TAREAS.ALLOCATED_TASK_ID					= QSTNR_PARTICIP.PARTICIPANT_ID			--Join tarea especifica de la checklist al cuestionario. Este JOIN es solo si la tarea esta completa. Si Tambien queremos mostrar tareas pendientes (Estado: 'INI'), entonces no usamos este JOIN. 
	AND QSTNR_PARTICIP.QSTNR_PARTICIPANT_ID			= QSTNR_RESP.QSTNR_PARTICIPANT_ID		--Join del cuestionario con PREG y RTAS.
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--PARAMETROS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--:pCheckLists --Este esta dentro de las queries de arriba de TAREAS Y CHECKLISTS.
	AND ((COALESCE(null, :pQuestionario) is null) 	OR 	(CUESTIONARIO_TL.QUESTIONNAIRE_ID IN (:pQuestionario)))
	AND ((COALESCE(null, :pPersonName) is null) 	OR 	(PERA.PERSON_ID IN (:pPersonName)))
	
	--Para la Fecha de desligamento (PPOS.ACTUAL_TERMINATION_DATE puede ser null, pero no influye en nada esto):
	AND (	( 	:pStartFechaDesligamiento IS NOT NULL and :pEndFechaDesligamiento IS NOT NULL
				AND PPOS.ACTUAL_TERMINATION_DATE between  :pStartFechaDesligamiento and :pEndFechaDesligamiento
			)
		OR  (   :pStartFechaDesligamiento IS NULL AND :pEndFechaDesligamiento IS NULL)
		)
	--Para la Fecha de desligamento: 
	AND (	( 	:pStartFechaAdmision IS NOT NULL and :pEndFechaAdmision IS NOT NULL
				AND (	SELECT  MIN(B.effective_start_date) 
					FROM 	PER_ALL_ASSIGNMENTS_M B 
					WHERE 	B.PERSON_ID (+) = PPNF.PERSON_ID
					Group by B.PERSON_ID					
				)	between  :pStartFechaAdmision and :pEndFechaAdmision
			)
		OR  (   :pStartFechaAdmision IS NULL AND :pEndFechaAdmision IS NULL)
		)
		
ORDER BY 	CHECKLIST.PACHECK_TL_CHECKLIST_NAME,  			--1ro orden: Nombre Checklist
			TAREAS.CREATION_DATE,							--2do: Data Creación de la terea.
			ASS.ASSIGNMENT_NUMBER,							--3ro: Assignment Number del empleado.
			PPNF.FULL_NAME,									--4to: Nombre del Empleado.
			QSTN_RESP.CREATION_DATE							--5to: Orden de las preguntas (Data de creación de la pregunta supongo, asi está ordenado el cuestionario). 