SELECT 	GLP.PERIOD_NAME --Lo que muestro y por lo que comparo. 

FROM 	GL_PERIODS                GLP

WHERE 	TRUNC(GLP.Start_Date)         	<= TRUNC(SYSDATE)			--Tambien poner esto ya que hay periodos de 1 año superior (por ej. ahora es 2020 pero hay periodos cargados de 2021).
		AND GLP.ADJUSTMENT_PERIOD_FLAG     	= 'N'				    --Esto tiene que ir. Ya que tambien hay 'Y' y otros que no tienen nada que ver. 

ORDER BY 	GLP.PERIOD_YEAR                DESC,							
			GLP.PERIOD_NUM                 DESC  
			--Por ej. para el PERIOD_NAME "ENE-19"... 2019 es el PERIOD_YEAR y 2 es PERIOD_NUM. (es el numero del mes +1).
			--De esta manera arriba de todo nos mostraría el último año y mes actuales. Y así 