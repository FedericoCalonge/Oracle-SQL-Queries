/*
select 	--to_char(START_DATE,'Month','NLS_DATE_LANGUAGE = SPANISH') fecha
		EXTRACT( MONTH  FROM :P_START_DATE)		AS Mes_Start_Date,
		EXTRACT( YEAR  :FROM P_START_DATE)			AS Año_Start_Date
from 	gl_periods
*/

select distinct to_char(:P_START_DATE,'YYYY','NLS_DATE_LANGUAGE = SPANISH') Year
from gl_periods