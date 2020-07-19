select 
	SUBMISSION_ID,   	--Union entrante con Candidato.SUBMISSION_ID y saliente con Cuestionario.SUBJECT_ID --> ES SUBJECT_ID, NO SUBMISSION AHI, ATENCION.
	REQUISITION_ID, 	--Union entrante con Candidato.REQUISITION_ID y saliente con Cuestionario.REQUISITION_ID.
	FEEDBACK_ID,		--Union saliente con Cuestionario.FEEDBACK_ID.
	LAST_UPDATE_DATE
	
from IRC_IM_FEEDBACKS