--Person_Perfiles_Titulos:

select

	PER.PERSON_ID		"Person_ID", 		--300000011489575
	--Campos para mostrar en el reporte:
	NAME.FULL_NAME 		"Nombre y Apellido",
	PAPF.PERSON_NUMBER 	"Num_Id",			--Número de identificación. 909090
	PN.NAME "Posicion", 					--DOCENTE TIEMPO COMPLETO II
	
	(
	select 
		haotl.NAME 
	from 
		hr_org_unit_classifications_f hac, 
		HR_ALL_ORGANIZATION_UNITS_F org,        
		hr_organization_units_f_tl haotl  
	where 
		hac.CLASSIFICATION_CODE='DEPARTMENT' 
		and haotl.LANGUAGE= 'E' 
		and org.ORGANIZATION_ID = haotl.ORGANIZATION_ID
		and hac.ORGANIZATION_ID = haotl.ORGANIZATION_ID
		and org.ORGANIZATION_ID = ASS.ORGANIZATION_ID		--Este join es importante. 
	) "Departamento_1",
	
	--Campos de titulos:
	Titulo.Programa,
	Titulo.Cuerpo_Doc_O_Dpto,			--Cuerpo doc o depto
	Titulo.Nombre_institucion,			--Nombre institucion
	Titulo.Numero_Tarjeta_Profesional,  --123
	Titulo.Numero_acta_grado, 			--12345
	Titulo.Titulo_Extranj_Conval,		--SI
	Titulo.Resolucion_MEN,				--0001
	Titulo.Metodologia_Programa,		--Presencial. 
	Titulo.Comentarios, 				--Comentariosss
	Titulo.Descripcion, 				--Descripcionnn
	Titulo.Fecha_Resolucion_Men,  		--2001-04-01T00:00:00.000+00:00
	Titulo.Fecha_Inicio,				--1995-01-07T00:00:00.000+00:00
	Titulo.Fecha_Finalizacion,  		--2018-07-08T00:00:00.000+00:00
	Titulo.Fecha_Adquisicion,			--2020-04-01T00:00:00.000+00:00
	Titulo.Fecha_Cumplimiento_Estimada, --2000-12-04T00:00:00.000+00:00
	Titulo.Codigo_Pais,	   				--NO mostramos esto. Te devuelve CO, ver "lookup" de abajo.	
	Titulo.Pais,						--Colombia para CO, BIEN. Esto si lo mostramos. 
	Titulo.Formacion_Academica,  		--Tecnologia (tambien estaba Bachiller, Doctorado, Especializacion en..., etc.). 
	Titulo.Departamento, 				--BOGOTA, D.C.     --Ver si esta bien este, casi seguro que si. 
	Titulo.Estado						
	
from  
	PER_ALL_PEOPLE_F PAPF,
	PER_PERSONS PER,
	PER_PERSON_NAMES_F NAME,
	PER_ALL_ASSIGNMENTS_M ASS,
	HR_ALL_POSITIONS_F_TL PN,	
	hr_organization_units_f_tl DEP,
	
	--Titulos:
	(
	select        
		
		HPB.person_id as person_id_2, --Campo para unir con PESON_ID de PER_PERSONS.
		AA.PROFILE_ID,   		--300000011313031
		AA.SECTION_ID,			--300000005246951 
		AA.CONTENT_TYPE_ID, 	--106. 
		
		AA.ITEM_TEXT240_1 		as Programa,					--TECNOLOGÍA EN PROCEDIMIENTOS.
		AA.ITEM_TEXT240_9		as Cuerpo_Doc_O_Dpto,			--Cuerpo doc o depto
		AA.ITEM_TEXT2000_1		as Nombre_institucion,			--Nombre institucion
		AA.ATTRIBUTE1			as Numero_Tarjeta_Profesional,  --123
		AA.ATTRIBUTE2			as Numero_acta_grado, 			--12345
		AA.ATTRIBUTE3			as Titulo_Extranj_Conval,		--SI
		AA.ATTRIBUTE4			as Resolucion_MEN,				--0001
		AA.ATTRIBUTE5			as Metodologia_Programa,		--Presencial. 
		AA.ITEM_CLOB_1			as Comentarios, 				--Comentariosss
		AA.ITEM_CLOB_2 		 	as Descripcion, 				--Descripcionnn
		
		--Fechas (ponerle bien el formato):
		To_char(AA.ATTRIBUTE_DATE1,'DD/MM/YYYY') 	as Fecha_Resolucion_Men,  		--2001-04-01T00:00:00.000+00:00: Formateado asi queda 01/04/2001.
		To_char(AA.ITEM_DATE_7,'DD/MM/YYYY') 		as Fecha_Inicio,				--1995-01-07T00:00:00.000+00:00
		To_char(AA.ITEM_DATE_4,'DD/MM/YYYY') 		as Fecha_Finalizacion,  		--2018-07-08T00:00:00.000+00:00
		To_char(AA.ITEM_DATE_6,'DD/MM/YYYY') 		as Fecha_Adquisicion,			--2020-04-01T00:00:00.000+00:00
		To_char( AA.ITEM_DATE_8 ,'DD/MM/YYYY') 	    as Fecha_Cumplimiento_Estimada, --2000-12-04T00:00:00.000+00:00
		
		AA.COUNTRY_CODE			as Codigo_Pais,	   				--NO mostramos esto. Te devuelve CO, ver "lookup" de abajo.	
		(SELECT MAX(NLS_TERRITORY) FROM FND_TERRITORIES_VL WHERE TERRITORY_CODE = AA.COUNTRY_CODE)
								as Pais,						--Colombia para CO, BIEN. Esto si lo mostramos. 
		HCIT.NAME				as Formacion_Academica,  		--Tecnologia (tambien estaba Bachiller, Doctorado, Especializacion en..., etc.). 
		AA.STATE_PROVINCE_CODE  as Departamento, 				--BOGOTA, D.C.     --Ver si esta bien este, casi seguro que si. 
		--as graduado --Este campo NO hay que traerlo, es redundante. Es lo mismo que el campo 'Estado'
		AA.ITEM_TEXT30_11		as Estado						--USTA_FINALIZADO me tira (buscar lookup o hacer decode?). Cuantos estados puedo tener? VER DE FUSION. 
	
	from 
		HRT_PROFILE_ITEMS AA, 
		hrt_profiles_b HPB,
		HRT_CONTENT_ITEMS_TL HCIT
	
	where 	
		HPB.profile_id=AA.Profile_id
		AND AA.SECTION_ID=300000005246951 --titulos
		--Otra forma de acceder enves del section_id es por el content_id: AND AA.CONTENT_TYPE_ID = 106 
		--and HPB.person_id=100000004036245
		
		AND HCIT.CONTENT_ITEM_ID = AA.CONTENT_ITEM_ID
		AND HCIT.LANGUAGE = 'E'
	)  Titulo
	
where 
	PAPF.person_id		=	PER.person_id
	and NAME.person_id 	=	PER.person_id 
	and NAME.NAME_TYPE 	= 	'CO'   			--CO=Colombia. 
	and SYSDATE between NAME.EFFECTIVE_START_DATE and NAME.EFFECTIVE_END_DATE
	AND PN.POSITION_ID	=	ASS.POSITION_ID 
	AND PN.LANGUAGE		= 	'E'  
	
	--Parametro:
	and ASS.person_id=PER.person_id
	and SYSDATE between ASS.EFFECTIVE_START_DATE and ASS.EFFECTIVE_END_DATE
	and ASS.PRIMARY_FLAG= 'Y'
	and ASS.SYSTEM_PERSON_TYPE in ('EMP','CWK')
	and ASS.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
	and ASS.BUSINESS_UNIT_ID= :Parametro
	
	and PER.person_id = Titulo.person_id_2(+)  			--Con el (+) traemos las personas que NO tienen titulos tambien. Si queremos solo las que tienen titulos sacamos este (+)
	--and PER.person_id=100000004036245					--Ejemplo de persona con titulo. 
	
	and DEP.organization_id=ASS.BUSINESS_UNIT_ID 		--Sino joineo me trae repetidos. 
	AND DEP.LANGUAGE = 'E'