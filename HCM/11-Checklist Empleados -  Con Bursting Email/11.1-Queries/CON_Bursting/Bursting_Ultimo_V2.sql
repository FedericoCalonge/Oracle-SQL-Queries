--Query para poner en "Bursting" abajo a la izquierda y construir asi el XML de entrega:

--List:
with list as (
		--Obtenemos los emails para usuarios con el rol de IT Security Manager:

		select distinct 			--Para obtener solo los distintos por si se repite algún registro. 
			   users.email_address
		from 	
			(
			SELECT 	
					EM.EMAIL_ADDRESS,	   --Es el "Email_Coorporativo".
					pu.user_id,
					pu.username,
					ppnf.full_name,
					prdt.role_id,
					prdt.role_name,
					prdt.description,
					TO_CHAR (pur.start_date, 'DD-MON-YYYY') role_start_date,
					TO_CHAR (pur.end_date, 'DD-MON-YYYY') role_end_date,
					prd.abstract_role,
					prd.role_common_name,
					prd.job_role,
					prd.data_role,
					prd.duty_role,
					prd.active_flag
				
			FROM 	per_user_roles    		pur,
					per_users         		pu,
					per_roles_dn_tl   		prdt,
					per_roles_dn      		prd,
					per_person_names_f 		ppnf,
					PER_ALL_PEOPLE_F 		PERA,
					PER_EMAIL_ADDRESSES 	EM

			WHERE   pu.user_id = pur.user_id
					AND prdt.role_id = pur.role_id
					AND prdt.language = USERENV ('lang')
					AND prdt.role_id = prd.role_id
					AND NVL (pu.suspended, 'N') = 'N'
					AND ppnf.person_id = pu.person_id
					AND ppnf.name_type = 'GLOBAL'
					AND pu.active_flag = 'Y'
					AND NVL (pu.start_date, SYSDATE) <= SYSDATE
					AND NVL (pu.end_date, SYSDATE) >= SYSDATE
					
					--EMAIL:
					and PERA.PERSON_ID 			= PPNF.PERSON_ID
					AND SYSDATE BETWEEN PERA.EFFECTIVE_START_DATE AND PERA.EFFECTIVE_END_DATE
					AND SYSDATE BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE
					and PERA.person_id			= EM.person_id 
					and EM.EMAIL_ADDRESS_ID		= PERA.PRIMARY_EMAIL_ID 
					and prd.ACTIVE_FLAG 		= 'Y'
					
					--and EM.email_address like '%@oracle.com'
					--Filtramos solo por algún rol en específico: 
					--and prdt.role_name= 'IT Security Manager'
					--and prdt.role_name= 'HR Specialist - View All'
					and prd.role_common_name = 'ORA_FND_IT_SECURITY_MANAGER_JOB'
					
			ORDER BY 
					pu.username
			) users
)

SELECT 
		distinct
		fecha_burst 								as KEY,
		'Report_1_Checklists_Bursting' 				as TEMPLATE,		--Nombre del Reporte al que apuntamos.
		'en-US' 									as LOCATE,
		'excel2000' 								as OUTPUT_FORMAT,  	--Todas las definiciones aca: https://docs.oracle.com/cd/E28280_01/bi.1111/e22258/add_burst_def.htm#BIPDM350
		'true' 										as SAVE_OUTPUT,
		'EMAIL' 									as DEL_CHANNEL,
		
		(	select 	'federico.calonge@oracle.com' || ',' || 'ejemplo@gmail.com.ar' || ',' || listagg(email_address,',') WITHIN GROUP(order by email_address) 
			from 	list) 							parameter1,
		
		--'federico.calonge@oracle.com' 			as parameter1, --Email address
		
		'' 											as parameter2, --cc
		'notifications@oracle.com' 					as parameter3, --from
		'TEST - Relatório - Atividades vencidas Pre-Hire Pending Worker'
													as parameter4, --Subject
		'Envio de Relatório - Atividades vencidas para a lista -Pre-Hire Pending Worker-'
													as parameter5, --Message body
		'True' 										as parameter6, --Attachment value (si quiero salida en PDF o Excel tengo que poner TRUE). 
		'' 											as parameter7  --Reply-To

--Esta query de abajo es simplemente para poder acceder arriba a datos de abajo como 'data.alguncampo'.
--MISMO FROM Y WHERE QUE LA QUERY DE CABECERA (EN MI CASO 'Empleado_Checklists_Tareas', SOLO QUE EN EL SELECT PONGO 'fecha_burst':
FROM 
	(	SELECT 	distinct
				trunc(sysdate) 					as fecha_burst
			
		FROM 	--------------------------------------------------------------------------------------------------------------------------------------------------------------
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
	
	) data