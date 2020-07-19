SELECT distinct 
	PERA.person_number "Numero de Persona",
	ppf.full_name "Nombre Completo",
	pf.assignment_number "Numero Asignacion",
	pf.assignment_id "ID Asignacion",
	pos.name "Posicion",
	pf.PERSON_ID "PersonID",
	NVL(SOBRES.VALOR,0) "Bonificacion",
	SAL.SALARY_AMOUNT "Sueldo",
	DECODE(pf.Business_unit_id, 300000002580231, 'Bucaramanga',300000002580393, 'Medellin',300000002580474, 'Villavicencio',300000002580312,'Tunja',300000002580150,'Bogota') "Sede"
FROM 
	CMP_SALARY SAL, 
	PER_ALL_PEOPLE_F PERA,
	PER_PERSON_NAMES_F ppf,
	per_all_assignments_f pf,
	HR_ALL_POSITIONS_F_TL pos,
	(
		SELECT UNIQUE
			PIV.BASE_NAME,
			EEV.screen_entry_value VALOR , 
			EEV.EFFECTIVE_END_DATE FECHAFIN , 
			EEV.EFFECTIVE_START_DATE FECHAINICIO ,
			--EE.element_entry_id , 
			--EEV.element_entry_value_id , 
			EE.PERSON_ID , 
			--EE.effective_end_date , EE.effective_start_date ,   
			EU.payroll_assignment_id , 
			--EU.DATE_FROM , EU.DATE_TO , 
			ET.BASE_ELEMENT_NAME 
			--ET.element_name
			-- , ET.element_type_id
		FROM  
			pay_entry_usages               EU, 
			pay_element_entries_f          EE, 
			pay_element_types_vl           ET, 
			pay_input_values_f             PIV, 
			pay_element_entry_values_f     EEV
	    WHERE   
			EE.element_entry_id = 	EU.element_entry_id 
			and  PIV.input_value_id (+)       = EEV.input_value_id 
			and  EEV.effective_start_date between PIV.effective_start_date (+) 	and PIV.effective_end_date (+) 
			AND  EU.date_from <= nvl(SYSDATE, to_date('31/12/4712', 'DD/MM/YYYY'))  -- END_DATE 
			AND  EU.date_to >= nvl(SYSDATE, to_date('01/01/0001', 'DD/MM/YYYY'))  -- START_DATE 
			AND  EU.date_from BETWEEN  ET.effective_start_date AND  ET.effective_end_date 
			AND    EE.element_type_id          =  ET.element_type_id 
			AND    EEV.element_entry_id (+)    =  EE.element_entry_id 
			AND    EE.effective_start_date between EEV.effective_start_date (+) and EEV.effective_end_date (+) 
			and PIV.BASE_NAME= 'Amount'
			--and EE.PERSON_ID in (300000003185023,100000001731830,300000003414350)
			and ET.BASE_ELEMENT_NAME= 'USTA Bonificación'
		order by ET.base_element_name, EU.date_from, PIV.base_name
	) SOBRES,
	hr_organization_units_f_tl org,
	CMP_SALARY_SECURED_LIST_V SAL_Seguridad
WHERE ------------------------------------
	SOBRES.person_Id(+) = pf.person_id 
	and PERA.person_id(+) = pf.person_id 
	and ppf.person_id = pf.person_id
	and pos.position_id = pf.position_id
	and pf.primary_flag = 'Y'
	--and SAL.person_id(+)= pf.person_id
	AND SAL.ASSIGNMENT_ID(+) = pf.ASSIGNMENT_ID
	AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date AND ppf.effective_end_date
	AND TRUNC(SYSDATE) BETWEEN pf.effective_start_date AND pf.effective_end_date
	and TRUNC(Sysdate) between SAL.DATE_FROM and SAL.DATE_TO
	and pf.business_unit_id = :Parametro

    --Join de Seguridad
	and SAL.SALARY_ID = SAL_Seguridad.SALARY_ID
	
	and ORG.organization_id = pf.BUSINESS_UNIT_ID
	AND ORG.LANGUAGE = 'E'
	and pf.SYSTEM_PERSON_TYPE in ('EMP','CWK')
	and pf.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
	and ppf.name_type = 'CO'