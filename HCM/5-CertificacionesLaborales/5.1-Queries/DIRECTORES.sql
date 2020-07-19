--Info del director con nombre y asignaciones.

select 	
		P.BUSINESS_UNIT_ID, --Union con Empleado.SEDE
		P.position_id,
		ASS.person_id,
		P_Name.FIRST_NAME||' '||P_Name.MIDDLE_NAMES||' '||P_Name.LAST_NAME||' '||P_Name.NAM_INFORMATION1 "NAMEDIRECTOR",
		NID.NATIONAL_IDENTIFIER_NUMBER "CCDIRECTOR"
		
from 	HR_ALL_POSITIONS_F_TL N,
		HR_ALL_POSITIONS_F P,
		per_all_assignments_f ASS,
		per_person_names_f P_Name,
		PER_NATIONAL_IDENTIFIERS NID
		
where 
		N.position_id=P.position_id
		and N.name  in ('DIRECTOR (A) DEPARTAMENTO DE GESTION DEL TALENTO HUMANO', 'COORDINADOR (A) ESTRATEGICO GESTION DEL TALENTO HUMANO')
		and N.language= 'E'
		
		and ASS.position_id = P.position_id
		and sysdate between ASS.effective_start_date and ASS.effective_end_date
		
		and ASS.person_id=NID.person_id
		and NID.person_id=P_Name.person_id 
		and P_Name.name_type='GLOBAL' 
		and NID.NATIONAL_IDENTIFIER_TYPE= 'CC' 
		and NID.person_id=P_Name.person_id