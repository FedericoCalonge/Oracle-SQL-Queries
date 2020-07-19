--Ver post: https://fusionhcmknowledgebase.com/2019/01/query-to-get-users-last-login/

--Opcion 1: pero para que sirva esta query se debía correr un proceso scheduling ya programado que llene diariamente la tabla ASE_USER_LOGIN_INFO.
--Por esto es que no tira bien los resultados, con repetidos y fechas a futuro.  

SELECT
		U.USERNAME,
		A.LAST_LOGIN_DATE
		--to_char(U.CREATION_DATE, 'dd-mm-yyyy') CREATION_DATE,
		--to_char(A.LAST_LOGIN_DATE, 'dd-mm-yyyy') LAST_LOGIN_DATE

FROM 	ASE_USER_LOGIN_INFO A,
		PER_USERS U

WHERE 	A.USER_GUID = U.USER_GUID
		AND U.USERNAME NOT LIKE 'FUSION_APPS_%'
		AND A.LAST_LOGIN_DATE IS NOT NULL
		--AND A.LAST_LOGIN_DATE > sysdate - 30
order by LAST_LOGIN_DATE desc
		
--Opción 2: NO es lo recomendable... trae muchísimos campos para 1 solo día de conexion... lo bueno que no me 
--traia fechas a futuro. Evaluar después por qué criterio filtrar.

SELECT 
	user_name "LOGIN_USERNAME",
	last_connect
	--to_char(last_connect, 'dd-mm-yyyy') "LAST_LOGIN_DATE"

FROM 	fnd_sessions

WHERE 	user_name NOT LIKE 'FUSION_APPS%'

ORDER BY last_connect desc
