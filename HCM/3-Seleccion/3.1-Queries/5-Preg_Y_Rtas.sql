--Traigo Answers y Responses:

select 	
		--El cuestionario tiene 1 y 2:
							--1-Responses (respuestas de preguntas de texto --> tabla HRQ_QSTN_RESPONSES)       --> NO tienen QSTN_ANSWER_ID ni ANSWER_LIST.
							--2-Answers (respuestas de preguntas con una lista opciones --> tabla QSTN_ANSWERS) --> tienen QSTN_ANSWER_ID y ANSWER_LIST.
		--Las Responses son rtas para preguntas de tipo TEXT (campo QUESTION_TYPE) y las Answers son rtas para preguntas de tipo 1CHOICE.
		--Otro tipo de respuestas es NONE (para el Anexo por ejemplo, que tiene adjuntos y no habría que mostrarlo). 
		
		QSTNR_RESP.QSTNR_PARTICIPANT_ID,   	--Union con Cuestionario.QSTNR_PARTICIPANT_ID
		----------------------------------------------------------------------------------
		QSTNR_RESP.QSTNR_RESPONSE_ID,		--Identifies the questionnaire response
		QSTN_RESP.QSTN_ANSWER_ID, 			--Me lo trae vacio si es de texto al parecer (si QUESTION_TYPE es TEXT).  Identifies the answer for a question.	
		QSTN_RESP.QSTNR_QUESTION_ID,  		--Identifies the questionnaire question.		

		QSTN_RESP.ANSWER_LIST,
		
		QUESTIONS_TL.QUESTION_TEXT,			--Texto de la pregunta.
		QUESTIONS_B.QUESTION_TYPE,     
		QSTN_ANSWERS.LONG_TEXT 				RTA_OTRAS_NO_TEXTO, 	--Texto de la rta si el QUESTION_TYPE NO es TEXT (osea si TENEMOS un QSTN_ANSWER_ID)
																	--Para este texto NO tengo el problema de abajo que me trae el html, asi que no hace falta hacer lo de abajo!
		
		--QSTN_RESP.ANSWER_TEXT				RTA_TEXTO,				--Texto de la rta si el QUESTION_TYPE es TEXT (osea si NO tenemos un QSTN_ANSWER_ID)
																	--MAL, me trae el html feo, hay que sacarlo como abajo:
		'<![CDATA' || '['|| QSTN_RESP.ANSWER_CLOB || ']' || ']>'   
										RTA_TEXTO,   --Enves de QSTN_RESP.ANSWER_CLOB puede ir TO_CLOB(QSTN_RESP.ANSWER_TEXT).
		
		/* VER para hacer este decode para que me traiga el RTA_OTRAS_NO_TEXTO o RTA_TEXTO dependiendo del QUESTIONS_B.QUESTION_TYPE... igual esto lo arreglé con el rtf poniendo los 2 campos y LISTO (ya que siempre trae uno o el otro). 
		decode (QUESTIONS_B.QUESTION_TYPE,
				'TEXT', '<![CDATA' || '['|| QSTN_RESP.ANSWER_CLOB || ']' || ']>',
				'1CHOICE',  QSTN_ANSWERS.LONG_TEXT
				)
		
		--Case tampoco sirve:
		--case QUESTIONS_B.QUESTION_TYPE 
		--	when 'TEXT' 	then QSTN_ANSWERS.LONG_TEXT  
		--	when '1CHOICE' 	then QUESTIONS_B.QUESTION_TYPE  
		--	else 'Nada'
		--end
		*/
		
		--Ordenar las rtas:
		--Por estos NO:
		--QSTNR_RESP.SUBMITTED_DATE_TIME  as subm_date_1,
		--QSTNR_RESP.ATTEMPT_NUM,
		--QSTN_ANSWERS.LAST_UPDATE_DATE  as last_up_date_3,
		--QSTN_ANSWERS.CREATION_DATE    as creation_date_2
		--QSTNR_RESP.LAST_UPDATE_DATE		as last_up_date_1,
		
		--Por estos 2 campos puedo ordenar al parecer... me trae el orden que se pregunta y responde en Fusion:
		QSTN_RESP.LAST_UPDATE_DATE		as last_up_date_2,  --esta meparece que no porque si se modifica me la traeria primero, usar la de abajo de creacion.
		QSTN_RESP.CREATION_DATE			as creation_date_1
		
from 			
		HRQ_QSTNR_RESPONSES		QSTNR_RESP,	
		HRQ_QSTN_RESPONSES		QSTN_RESP,				--Rtas asociadas a las preguntas.
		HRQ_QSTNR_QUESTIONS 	QSTNR_QUESTIONS, 		--Tabla de preguntas.
		HRQ_QUESTIONS_B			QUESTIONS_B,			--Tabla de preguntas 2.
		HRQ_QUESTIONS_TL 		QUESTIONS_TL,			--Tabla de preguntas trasladadas.
		HRQ_QSTN_ANSWERS_TL 	QSTN_ANSWERS

where
	QSTNR_RESP.QSTNR_RESPONSE_ID		=	QSTN_RESP.QSTNR_RESPONSE_ID
	and QSTN_RESP.QSTNR_QUESTION_ID		= 	QSTNR_QUESTIONS.QSTNR_QUESTION_ID	
	AND QSTNR_QUESTIONS.QUESTION_ID		=	QUESTIONS_B.QUESTION_ID
	and QUESTIONS_B.QUESTION_ID     	=    QUESTIONS_TL.QUESTION_ID
	AND QUESTIONS_TL.LANGUAGE 			= 	USERENV ('LANG')
	AND QUESTIONS_TL.SOURCE_LANG 		= 	'E'
	
	AND QSTN_RESP.QSTN_ANSWER_ID		= QSTN_ANSWERS.QSTN_ANSWER_ID(+)	    --Aca esta el 'problema', este join. 
																				--Pongo right join (como tambien abajo) para que me traiga el RTA_OTRAS_NO_TEXTO tenga o no QSTN_ANSWER_ID el campo)... Asi puedo ver todas las respuestas: RTA_OTRAS_NO_TEXTO y RTA_TEXTO.
	AND QSTN_ANSWERS.LANGUAGE(+) 		= 'E'  --O USERENV ('LANG')?	
		
	and QUESTIONS_B.QUESTION_TYPE		!='NONE'	  --Traigo todos los tipos (TEXT y 1CHOICE) menos NONE (como el Anexo).
	--and QUESTIONS_B.QUESTION_TYPE		='TEXT'   	  --Para traer solo las de texto (responses).
	--and QUESTIONS_B.QUESTION_TYPE		='1CHOICE'	  --Para traer solo las choice (answers).

order by QSTN_RESP.CREATION_DATE
------------------------------------------------------------------------------------------------------------
