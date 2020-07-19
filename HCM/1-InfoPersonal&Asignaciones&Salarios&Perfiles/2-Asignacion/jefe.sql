SELECT  person.PERSON_ID "EMPLEADO", 
		assign.ASSIGNMENT_ID "ASIGEMPL",  
		assign.effective_start_date "FechaINI",assign.effective_end_date "FechaFIN",
		--superv.MANAGER_ID  "JEFE",
		nombre.FIRST_NAME||' '||nombre.LAST_NAME "NOMBREJEFE",
		--ASS.job_id "JOB JEFE",
		--J.MANAGER_LEVEL "Cod Nivel JEFE",
		JO.name "Puesto del Jefe", 
		LOO.MEANING "Nivel JEFE"
FROM 
		PER_PERSON_SECURED_LIST_V person,
		PER_PERSON_NAMES_F nombre,
		PER_ALL_ASSIGNMENTS_M_V assign,
		PER_ASSIGNMENT_SUPERVISORS_F_V superv, 
		per_all_assignments_f ASS,
		per_jobs j,
		per_jobs_f_tl JO, HCM_LOOKUPS LOO


WHERE	LOO.LOOKUP_CODE=J.MANAGER_LEVEL AND 
		j.job_id=JO.job_id and JO.language= 'E' and
		ASS.person_id=superv.manager_id and sysdate between ASS.effective_start_date and ASS.effective_end_date and 
		ASS.job_id=J.job_id and
		assign.PERSON_ID = person.PERSON_ID 
		and superv.MANAGER_ID=nombre.PERSON_ID
		AND nombre.NAME_TYPE = 'GLOBAL'
		AND assign.ASSIGNMENT_TYPE in ('E','C')
		AND assign.PRIMARY_FLAG = 'Y' AND TRUNC(SYSDATE) BETWEEN
		assign.EFFECTIVE_START_DATE AND assign.EFFECTIVE_END_DATE AND
		assign.ASSIGNMENT_ID = superv.ASSIGNMENT_ID(+) AND
		superv.EFFECTIVE_START_DATE(+) BETWEEN
		assign.EFFECTIVE_START_DATE AND assign.EFFECTIVE_END_DATE AND
		superv.PRIMARY_FLAG(+) = 'Y'