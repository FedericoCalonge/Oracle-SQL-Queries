select DISTINCT
	PERA.person_id, 
	ASS.ASSIGNMENT_ID,
	ass.effective_start_date "Fecha Inicio Asignacion", 
	ass.effective_end_date "Fecha Fin Asignacion",
	PERA.PERSON_NUMBER "Numero Persona",
	ASS.ASSIGNMENT_NUMBER "Numero Asignacion",
	ASS.ASSIGNMENT_NAME "Nombre Asignacion",
	ASS.ASSIGNMENT_STATUS_TYPE "Tipo Asignacion",
	ORG.name "Sede", --ASS.BUSINESS_UNIT_ID,
	LOC.LOCATION_NAME "Ubicacion", --ASS.LOCATION_ID,
	JOB.NAME "Puesto", --ASS.JOB_ID,
	PN.NAME "Posicion", --ASS.POSITION_ID,
	AN.ACTION_NAME "Accion", --ASS.ACTION_CODE,
	
	NVL(
	(
	SELECT ARN.ACTION_REASON
	FROM	
		PER_ACTION_REASONS_B ARC, 
		PER_ACTION_REASONS_TL ARN
	WHERE
		ARC.ACTION_REASON_CODE = ASS.REASON_CODE 	
		AND	ARN.ACTION_REASON_ID = ARC.ACTION_REASON_ID 
		AND ARN.LANGUAGE='E' 
	),'') "Motivo",
	
	--ARN.ACTION_REASON "Motivo", --ASS.REASON_CODE,
	--'motivo' "Motivo",
	
	DEP.NAME "Nombre Depto", --ASS.ORGANIZATION_ID,
	ASS.FULL_PART_TIME "Full o Part time?",
	LN.NAME "Escala", --ASS.GRADE_LADDER_PGM_ID,
	GN.NAME "Grado", --ASS.GRADE_ID,
	ASS.WORK_AT_HOME "Trabaja en Casa?",

	LOO.MEANING "Categoria Empleado",--ASS.EMPLOYEE_CATEGORY,

	LOOK.MEANING "Categoria Empleador", --ASS.EMPLOYMENT_CATEGORY,
	ASS.PERMANENT_TEMPORARY_FLAG "Regular o Temporal",
	ASS.NORMAL_HOURS "Horas",
	ASS.FREQUENCY "Frecuencia",
	ASS.TIME_NORMAL_START "Hora Inicio",
	ASS.TIME_NORMAL_FINISH "Hora Fin",
	ASS.ASS_ATTRIBUTE1 "Sincronizado Sac",
	PG.SEGMENT1 "GrupoPago",
	PG.SEGMENT2 "Eligibilidad",
	ASS.DEFAULT_CODE_COMB_ID "Cuenta Default", 
	ASS.LEGAL_ENTITY_ID "Empleador Legal",
	ASS.SYSTEM_PERSON_TYPE "Tipo Persona",
	(select EI.AEI_INFORMATION_NUMBER1 
	from
	PER_ASSIGNMENT_EXTRA_INFO_M EI
	where EI.assignment_id(+)=ASS.assignment_id and EI.INFORMATION_TYPE= 'Escalafon') "Acta",
	(select to_char(EI.AEI_INFORMATION_DATE1,'DD/MM/YYYY')
	from
	PER_ASSIGNMENT_EXTRA_INFO_M EI
	where EI.assignment_id(+)=ASS.assignment_id and EI.INFORMATION_TYPE= 'Escalafon')
	"FechaEscalafon",

	(select EI.AEI_ATTRIBUTE2 
	from
	PER_ASSIGNMENT_EXTRA_INFO_M EI
	where EI.assignment_id(+)=ASS.assignment_id and EI.INFORMATION_TYPE= 'Escalafon')
	"CodigoEscalafon",
	  glcc.segment1 "COMPAÑIA",
	  glcc.segment2 "USTA_SEDE",
	  glcc.segment3 "USTA_CUENTA",
	  glcc.segment4 "USTA_CECOS",
	  glcc.segment5 "USTA_OPE",
	  glcc.segment6 "USTA_NFORM",
	  glcc.segment7 "USTA_MGESTION",
	  glcc.segment8 "USTA_PIMPGD",
	  glcc.segment9 "USTA_FUTURO",

	to_char(SER.ORIGINAL_DATE_OF_HIRE,'DD/MM/YYYY')  "Fecha antiguedad",
	to_char(SER.ACTUAL_TERMINATION_DATE,'DD/MM/YYYY')  "Fecha cese",
	to_char(SER.DATE_START,'DD/MM/YYYY')  "Fecha inicio Contrato",
	--SER.ATTRIBUTE1
	CONTRATO.DESCRIPTION "Tipo Contrato",
	to_char(SER.DATE_START,'DD/MM/YYYY')  "Fecha inicio vigencia contrato",
	to_char(ASS.PROJECTED_ASSIGNMENT_END,'DD/MM/YYYY') "Fecha Fin vigencia Contrato"


FROM -----------------------
	(select flex_value,DESCRIPTION from fnd_flex_values_vl 
	where value_category= 'USTA_TIPO_CONTRATO'
	and enabled_flag='Y') CONTRATO,

	PER_ALL_PEOPLE_F PERA,
	PER_ALL_ASSIGNMENTS_M ASS, 
	PER_PERIODS_OF_SERVICE SER,
	PER_GRADE_LADDERS_F_TL LN,
	PER_GRADES_F_TL GN,
	HR_ALL_POSITIONS_F_TL PN,
	PER_ACTIONS_B ACC, 
	PER_ACTIONS_TL AN,
	--PER_ACTION_REASONS_B ARC, 
	--PER_ACTION_REASONS_TL ARN,
	PER_PEOPLE_GROUPS  PG,
	PER_JOBS_F_TL JOB,
	HCM_LOOKUPS LOO,
	HCM_LOOKUPS LOOK,
	hr_organization_units_f_tl ORG,
	hr_organization_units_f_tl DEP,  
	hr_locations_all LOC,
	gl_code_combinations glcc
WHERE ------------------------
	PERA.PERSON_ID=ASS.PERSON_ID
	
	AND ASS.PRIMARY_FLAG= 'Y' 
	AND trunc(SYSDATE) BETWEEN ASS.EFFECTIVE_START_DATE AND ASS.EFFECTIVE_END_DATE
	
	--FILTRO AGREGADO
	and ASS.SYSTEM_PERSON_TYPE in ('EMP','CWK') --contingent worker/aprendices
	and ASS.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
	-----------------
	
	--and ASS.business_unit_id= 300000002580150
	and ASS.business_unit_id= :Parametro	
	
	AND SER.person_id=ASS.person_id 
	and SER.PERIOD_OF_SERVICE_ID=ASS.PERIOD_OF_SERVICE_ID 
	and SER.Attribute1=CONTRATO.Flex_value
	
	AND LN.LANGUAGE='E' 
	AND LN.GRADE_LADDER_ID=ASS.GRADE_LADDER_PGM_ID 
	
	AND GN.GRADE_ID=ASS.GRADE_ID 
	AND GN.LANGUAGE='E' 
	
	AND ACC.ACTION_CODE=ASS.ACTION_CODE 
	
	AND AN.LANGUAGE='E' 
	AND AN.ACTION_ID=ACC.ACTION_ID 
	
	--AND ARC.ACTION_REASON_CODE(+) = ASS.REASON_CODE 	
	--AND ARN.ACTION_REASON_ID=ARC.ACTION_REASON_ID(+) 
	--AND ARN.LANGUAGE='E' 
	
	AND LOC.LOCATION_ID=ASS.LOCATION_ID 
	
	AND DEP.organization_id=ASS.ORGANIZATION_ID
	AND DEP.LANGUAGE = 'E' 
	
	AND  ORG.organization_id=ASS.BUSINESS_UNIT_ID
	AND ORG.LANGUAGE = 'E' 
	
	AND	LOO.LOOKUP_CODE=ASS.EMPLOYMENT_CATEGORY 
	AND LOO.LOOKUP_TYPE='EMP_CAT' 
	
	AND LOOK.LOOKUP_CODE=ASS.EMPLOYEE_CATEGORY 
	AND LOOK.LOOKUP_TYPE='EMPLOYEE_CATG' 
	
	AND JOB.JOB_ID(+)=ASS.JOB_ID 
	AND JOB.LANGUAGE= 'E' 
	
	AND PN.POSITION_ID=ASS.POSITION_ID 
	AND PN.LANGUAGE= 'E' 
	
	AND ASS.PEOPLE_GROUP_ID=PG.PEOPLE_GROUP_ID
	
	and ass.default_code_comb_id(+)=glcc.code_combination_id