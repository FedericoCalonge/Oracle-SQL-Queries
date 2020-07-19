--Perfiles_Titulos_DS:

--Obtenemos los titulos:
select distinct 
	PROF.person_id,
	PROFILES.person_id,
	PROFILES.profile_id 
	AA.SECTION_ID,
	AA.ITEM_TEXT240_1 --"Titulo"

from 
	hrt_profiles_b   PROFILES
	HRT_PROFILE_ITEMS AA, 
	(	select distinct 
			X.person_id,
			X.profile_id 
		from hrt_profiles_b X 
		
	) 	PROF

where 
	AA.SECTION_ID=300000005246951 --titulos
	AND PROF.profile_id=AA.Profile_id
	and PROFILES.person_id is not null
	--and PER.person_id=100000004036245