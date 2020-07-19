SELECT 	distinct					--Despues sacar este distinct y ver porque vienen repetidos.
		PPNF.FULL_NAME,
		CHECKL.PERSON_ID

FROM 	PER_ALLOCATED_CHECKLISTS CHECKL,
		PER_PERSON_NAMES_F	PPNF

WHERE 	PPNF.PERSON_ID = CHECKL.PERSON_ID	--Solo traigo los que tienen listas de comprobacion.
		AND SYSDATE BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE
		AND PPNF.NAME_TYPE = 'GLOBAL'   --Este filtro si o si. Sino me aparece el nombre regional y global. 

ORDER BY PPNF.FULL_NAME