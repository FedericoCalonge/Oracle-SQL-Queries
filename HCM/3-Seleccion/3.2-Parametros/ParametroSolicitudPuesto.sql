Select  
	ALIAS_1.TITLE
	,BASE_0.REQUISITION_ID
From
	IRC_SUBMISSIONS BASE_0_0
	,IRC_REQUISITIONS_B BASE_0 
	,IRC_REQUISITIONS_TL ALIAS_1 
Where 
	BASE_0.REQUISITION_ID = BASE_0_0.REQUISITION_ID
	and BASE_0.REQUISITION_ID = ALIAS_1.REQUISITION_ID
	and BASE_0.CURRENT_PHASE_ID = 5 --abierto
	and ALIAS_1.LANGUAGE = 'E'
	and ((COALESCE(null, :pCandidatos) is null) OR (BASE_0_0.PERSON_ID IN (:pCandidatos)))
Order By ALIAS_1.TITLE