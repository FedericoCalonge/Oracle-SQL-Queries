--Oara hacer esta LoV lo que hice fue ver el WHERE de 1-Empleados_Y_Tareas_Y_Cuestionarios y puse todos esos filtros...
--de esta manera me aseguro que me traiga a los assignment number que se ven ahi (NO a tooodos los demás). 

SELECT 
    distinct
	PACHECK_TL.CHECKLIST_NAME, 		--Lo que muestro.
	--PACHECK.ALLOCATED_CHECKLIST_ID,
	PACHECK.CHECKLIST_ID  			--Lo que comparo en la query.
from 
	PER_ALL_PEOPLE_F 				PERA,
	PER_PERSON_NAMES_F				PPNF,
	PER_ALL_ASSIGNMENTS_M 			ASS,
	per_periods_of_service 			PPOS,
	
	--Checklists:
	PER_ALLOCATED_CHECKLISTS 		PACHECK,
	PER_ALLOCATED_CHECKLISTS_TL 	PACHECK_TL,
	
	--Tareas:
	PER_ALLOCATED_TASKS 			PATASKS,
	PER_TASKS_IN_CHECKLIST_B		TAREAS_QUEST,
	
	--Cuestionarios:
	HRQ_QUESTIONNAIRES_B    		CUESTIONARIO_B,
	HRQ_QSTNR_PARTICIPANTS 			QSTNR_PARTICIP,
	
	--Preg y rtas:
	HRQ_QSTNR_RESPONSES				QSTNR_RESP,	
	HRQ_QSTN_RESPONSES				QSTN_RESP,
	HRQ_QSTNR_QUESTIONS 			QSTNR_QUESTIONS,
	HRQ_QUESTIONS_B					QUESTIONS_B	

where
	
	--PERA Y PPNF:
	PERA.PERSON_ID 		= PPNF.PERSON_ID
	AND PPNF.NAME_TYPE 	= 'GLOBAL'
	AND SYSDATE BETWEEN PERA.EFFECTIVE_START_DATE AND PERA.EFFECTIVE_END_DATE
	AND SYSDATE BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE

	--ASS:
	--ACA DEJO el (+) porque la persona puede no tener asignación:
	AND PERA.PERSON_ID					= ASS.PERSON_ID(+)
	--AND ASS.PRIMARY_FLAG (+)			= 'Y' 
	AND ASS.ASSIGNMENT_STATUS_TYPE (+)	= 'ACTIVE'
	and ASS.PRIMARY_ASSIGNMENT_FLAG (+)	= 'Y'
	AND trunc(SYSDATE) BETWEEN ASS.EFFECTIVE_START_DATE (+) AND ASS.EFFECTIVE_END_DATE (+)
	
	--PPOS:
	AND PERA.person_id = PPOS.person_id	
	AND PPOS.period_of_service_id = (	SELECT 	MAX(period_of_service_id)
											FROM 	per_periods_of_service
											WHERE 	person_id = PERA.person_id
									)
	
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Filtramos solo los que tengan tareas 'COM' y cuestionarios:
	
	--Checklists:
	AND PERA.PERSON_ID = PACHECK.PERSON_ID 														--Join con PERA.
	AND PACHECK.ALLOCATED_CHECKLIST_ID = PACHECK_TL.ALLOCATED_CHECKLIST_ID
	AND PACHECK_TL.LANGUAGE = USERENV ('LANG')       
	
	--Tareas:
	AND PACHECK.ALLOCATED_CHECKLIST_ID = PATASKS.ALLOCATED_CHECKLIST_ID							--Join con las checklists. 
	AND PATASKS.STATUS = 'COM' --Solo traigo los que completaron los cuestionarios. 
	and PATASKS.TASK_IN_CHECKLIST_ID = TAREAS_QUEST.TASK_IN_CHECKLIST_ID
	and TAREAS_QUEST.ACTION_TYPE = 'ORA_CHK_QUESTIONNAIRE' 
	
	--Cuestionarios:
	AND PATASKS.QUESTIONNAIRE_ID 					= CUESTIONARIO_B.QUESTIONNAIRE_ID			--Join con tasks.
	AND PACHECK.PERSON_ID							= QSTNR_PARTICIP.SUBJECT_ID					--Join con checklists.
	AND CUESTIONARIO_B.QUESTIONNAIRE_ID 			= QSTNR_PARTICIP.QUESTIONNAIRE_ID
	AND PATASKS.ALLOCATED_TASK_ID					= QSTNR_PARTICIP.PARTICIPANT_ID			--Join tarea especifica de la checklist. Este JOIN es solo si la tarea esta completa. Si tambien queremos mostrar tareas pendientes (Estado: 'INI'), entonces no usamos este JOIN. 
	
	--Que tengan preguntas y rtas (Que el cuestionario esté completo):
	AND QSTNR_PARTICIP.QSTNR_PARTICIPANT_ID	= 	QSTNR_RESP.QSTNR_PARTICIPANT_ID
	AND QSTNR_RESP.QSTNR_RESPONSE_ID		=	QSTN_RESP.QSTNR_RESPONSE_ID
	and QSTN_RESP.QSTNR_QUESTION_ID			= 	QSTNR_QUESTIONS.QSTNR_QUESTION_ID	
	AND QSTNR_QUESTIONS.QUESTION_ID			=	QUESTIONS_B.QUESTION_ID


order by 	PACHECK_TL.CHECKLIST_NAME