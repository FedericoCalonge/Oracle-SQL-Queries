SELECT 
    
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE EMPLEADO:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Este campo es para utilizar BURSTING y enviar por email las salidas del Reporte:
	distinct trunc(sysdate)								as fecha_burst,				--Para que no me repita los registros de empleado. 
	-------------------------------------------------------------------------------
	
	--No hay que mostrar estos Campos, los pongo para test:
	PERA.PERSON_ID										as Person_ID,
	PERA.PERSON_NUMBER									as Person_Number,
	--SUPERV.MANAGER_ID  									as ID_Supervisor,
	--to_char(ASS.effective_start_date,'DD/MM/YYYY')		as Fecha_Ultima_Posicion,	--Fecha_Ultima_Asign. 
	--ASS.ASSIGNMENT_TYPE									as Tipo_Asignacion,
	--ASS.Business_unit_id									as BU_ID,
	--ASS.LEGAL_ENTITY_ID									AS LEGAL_ENTITY_ID,			--Legal_Entity_ID.
	--ASS.ORGANIZATION_ID									as ORGANIZATION_ID,			--Enrealidad este campo seria el Department_ID.
	-------------------------------------------------------------------------------
	
	--Campos a mostrar en el encabezado (datos del empleado):
	PPNF.FULL_NAME										as Name_Colaborador, 		--Nome do Colaborador.
	ASS.ASSIGNMENT_NUMBER								as Assignment_Number,
	ORG_T.NAME											as Legal_E_Name,   
	DEP.NAME											as Departamento,
	JOBS_TL.NAME										as Cargo,
	POS.POSITION_CODE||'  '||POS_TL.NAME				as Posicion, 				--Posição. 				--Me trae la posicion de la ÚLTIMA asignacion activa 
																											--(por esto hacemos los filtros de fecha en el where).
	PPNF_SUP.FULL_NAME 									as Manager, 				--Gestor/Supervisor   	--O sino: PPNF_SUP.FIRST_NAME||''||PPNF_SUP.LAST_NAME				
		
	(	SELECT  to_char(MIN(B.effective_start_date),'DD/MM/YYYY')	 
		FROM 	PER_ALL_ASSIGNMENTS_M B 
		WHERE 	B.PERSON_ID (+) = PPNF.PERSON_ID
				--AND ASS.PRIMARY_FLAG= 'Y' 			--Ver si dejarlo o no
				--Como aca NO ponemos el filtro de fechas efectivas nos fijamos TODAS las asignaciones. 
		Group by B.PERSON_ID					
	)  													as Fecha_De_Contratacion, 	--Data de Admissão --Esta seria la fecha de Inicio de la asignación más vieja 
																					--(la 1ra de todas, NO la actual). VER SI ESTA ES LA QUE QUIEREN.  

	--Lógica fecha de renuncia: los que renunciaron tienen el campo PPOS.actual_termination_date con un valor que es < fecha de hoy. Y los que estan como empleados > :
	CASE
		WHEN PPOS.actual_termination_date < TRUNC(SYSDATE)	THEN to_char(PPOS.ACTUAL_TERMINATION_DATE,'DD/MM/YYYY')	--Desligado. 
		ELSE 'Não corresponde'																						--Empleado actual NO desligado. 
	END Fecha_Desligamiento,  --Data de Demissão / Fecha de renuncia.  
	--to_char(ASS.effective_end_date,'DD/MM/YYYY')	  	as Fecha_Asignacion,	--Esta fecha solo me la trae para los empleados NO desligados obviamente. 	

	--Para traer al responsable de 'Time BP - Brasil':
	(
		SELECT  distinct 
				MAX(ppnfv.full_name)					as Responsable_Name		--Puse MAX por si sucede que en algún caso hay más de 1 representante en 'Time BP - Brasil'
																				--(no debería ocurrir igualmente)
		FROM
			  (
				SELECT papf.person_id,
					  papf.person_number,
					  paam.LEGISLATION_CODE,
					  (	SELECT DISTINCT hlaf.country
						FROM 	HR_LOCATIONS_ALL_F hlaf
						WHERE 	hlaf.location_id=paam.location_id
								AND sysdate BETWEEN hlaf.effective_start_date AND hlaf.effective_end_Date 
					  )
					  country,
					  paam.business_unit_id,
					  paam.LEGAL_ENTITY_ID,
					  paam.ORGANIZATION_ID,
					  paam.location_id,
					  paam.POSITION_ID,
					  paam.job_id
			   
				FROM per_all_people_f papf,
					per_all_assignments_m paam
			   
				WHERE 	paam.person_id=papf.person_id
						AND sysdate BETWEEN paam.effective_start_date AND paam.effective_end_date
						AND sysdate BETWEEN papf.effective_start_date AND papf.effective_end_Date
						AND paam.EFFECTIVE_LATEST_CHANGE='Y'
						AND paam.ASSIGNMENT_TYPE IN ('E') 
				) 
				per,
				PER_PERSON_NAMES_F_V  ppnfv,
				PER_ASG_RESPONSIBILITIES par,		--AoR (Areas de responsabilidad) are stored in this table
				per_all_people_f papfc

		WHERE 	papfc.person_id=par.person_id
				and sysdate between ppnfv.effective_Start_date and ppnfv.effective_end_Date
				and ppnfv.person_id=papfc.person_id
				AND sysdate BETWEEN papfc.effective_Start_date AND papfc.effective_end_Date
				AND (nvl(par.country,NVL(per.country,1))=NVL(per.country,1) OR nvl(par.country,NVL(per.LEGISLATION_CODE,1))=NVL(per.LEGISLATION_CODE,1)) 
				AND nvl(par.business_unit_id,NVL(per.business_unit_id,1))=NVL(per.business_unit_id,1)
				AND nvl(par.LEGAL_ENTITY_ID,NVL(per.LEGAL_ENTITY_ID,1))=NVL(per.LEGAL_ENTITY_ID,1)
				AND nvl(par.ORGANIZATION_ID,NVL(per.ORGANIZATION_ID,1))=NVL(per.ORGANIZATION_ID,1)
				AND nvl(par.location_id,NVL(per.location_id,1))=NVL(per.location_id,1)
				AND nvl(par.POSITION_ID,NVL(per.POSITION_ID,1))=NVL(per.POSITION_ID,1)
				AND nvl(par.job_id,NVL(per.job_id,1))=NVL(per.job_id,1)
				AND par.END_DATE IS NULL
				
				AND par.responsibility_type = 'XP_REP_BP'  			--Hay varios names para este type, por eso es necesario agregar el filtro de abajo. 
				--and par.responsibility_name = 'Time BP - Brasil'	--Ver que se mantenga el mismo nombre... antes era 'Time de BP '.
				AND per.person_id=PERA.person_id 					--PERA.person_id es de la query que está FUERA. 
				and par.include_top_hier_node = 'N' 				--VER. 
				
	) 	Responsable_BP,
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--CAMPOS DE LAS TAREAS Y LAS CHECKLISTS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Tabla CHECKLIST:
	--to_char(CHECKLIST.ALLOCATION_DATE,'DD/MM/YYYY')  	as ALLOCATION_DATE, --Esta es la Fecha que se le ASIGNÓ al empleado el checklist de tareas a resolver (NO la tarea individual).
																			--En el reporte 5 la filtraba por :pFechaInicio y :pFechaFin, pero ahora NO hace falta. 
	CHECKLIST.PACHECK_TL_CHECKLIST_NAME,   	--Por esta lista de comprobacion filtramos en :pListas.
	CHECKLIST.PERSON_ID									as Person_ID_Checklist,
	
	--Tabla TAREA:
	TAREAS.TASK_NAME,
	TAREAS.TASK_TYPE,
	TAREAS.RESPONSABILIDAD_LOOKUP,
	--Estas 2 fechas (INICIO Y FIN) son las fechas cuando el empleado comenzó (o debe comenzar) y finalizó (o debería finalizar) la tarea individual de la checklist: 
	--TAREAS.INICIO, 						
	TAREAS.FIN,							--ESTA es la fecha de vencimiento de la tarea (ya que filtramos para traer solo las tareas PENDIENTES).
	--TAREAS.ESTADO						--NO lo muestro porque es redundante, siempre va a estar PENDIENTE por el filtro que hice en el where. 
	
	--Fecha de creación de la tarea (VER CUAL DE ESTOS SERIA):
	--TAREAS.INICIO, 						
	TAREAS.CREATION_DATE								as CREATION_DATE		--Creo que por esta quieren ordenar. A veces varia con TAREAS.INICIO (BIEN), 
									--ya que a veces se creó una tarea para ser asignada en el futuro al empleado. 
									--Saber: NO es la fecha CHECKLIST.ALLOCATION_DATE ya que es la fecha en que se asigna la CHECKLIST (NO la tarea individual).
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
				
				--Para enviar por email solo las 'Pre-Hire Pending Worker': 
				and PACHECK_TL.CHECKLIST_NAME ='Pre-Hire Pending Worker'
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
				PATASKS.CREATION_DATE 								as CREATION_DATE
				--TO_CHAR(PATASKS.CREATION_DATE, 'DD/MM/YYYY') CREATION_DATE
				
		FROM	PER_ALLOCATED_TASKS PATASKS
		
		WHERE	--Filtro de solo las tareas pendientes:
				PATASKS.STATUS = 'INI' 
		) 	
		TAREAS
		
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
	--AND SUPERV.manager_type 		= 'LINE_MANAGER'
	--and ASS.ASSIGNMENT_ID 		= SUPERV.ASSIGNMENT_ID(+)
	
	--ASS:
	--TODOS los (+) es porque la persona puede NO tener una asignación activa primaria... entonces todos los (+) pueden ser NULL!:
	AND PERA.PERSON_ID					= ASS.PERSON_ID (+)
	--AND ASS.PRIMARY_FLAG 	(+)			= 'Y' 	 							--Para filtrar solo la asignacion principal (para la posicion).
	AND ASS.ASSIGNMENT_STATUS_TYPE 	(+) = 'ACTIVE'
	AND ASS.PRIMARY_ASSIGNMENT_FLAG	(+) = 'Y'  							--VER. 
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
	
	-------------------------------------------------------------------------------------------------
	
	--LEGAL ENTITY Y DEPARTAMENT... usamos la misma tabla (ORG_T), pero la diferencia es que joineamos por  ASS.LEGAL_ENTITY_ID en caso de la Legal_Entity y con ASS.ORGANIZATION_ID en el caso del Department. 	
	
	--LENTITY (Antes) / ORG y ORG_T (ahora):
	--AND ASS.LEGAL_ENTITY_ID 		=   LENTITY.LEGAL_ENTITY_ID(+)	--Tenga o no legal_entity_id me lo trae igual. 
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
	--and PPOS.PERIOD_OF_SERVICE_ID=ASS.PERIOD_OF_SERVICE_ID		--Creo que no usamos esto porque arriba sacamos el period_of_service_id MAX y listo. 
			
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
					--Para enviar por mail solo estas:
					and PACHECK_TL.CHECKLIST_NAME ='Pre-Hire Pending Worker'
		)
	
	--TEST- para filtrar solo algunos en particular:
	--and PERA.Person_ID IN (300000001872332, 300000004557840, 300000001872205, 300000001865475)  --Arthur saraiva, empleado 10 (Desligado), Andre Saraiva (tambien desligado), Joao Martins.
	--AND PERA.person_id=300000001865475
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--WHERE DE LAS TAREAS Y LAS CHECKLISTS:
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--Join tabla CHECKLIST con tabla TAREAS:
	AND CHECKLIST.ALLOCATED_CHECKLIST_ID = TAREAS.ALLOCATED_CHECKLIST_ID
		
	--Para enviar por mail solo estas:
	and CHECKLIST.PACHECK_TL_CHECKLIST_NAME ='Pre-Hire Pending Worker'
	
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--JOIN ENTRE EMPLEADO Y TAREAS Y LAS CHECKLISTS:   (Este join antes lo tenía directamente en Cloud)
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	AND PERA.PERSON_ID	=  CHECKLIST.PERSON_ID
	
ORDER BY 	CHECKLIST.PACHECK_TL_CHECKLIST_NAME,  		--1ro orden.   --14
			TAREAS.CREATION_DATE						--2do orden.   --20		--HABIA QUE SACARLE EL CASTEO DE FECHA, SINO NO ME ORDENABA.