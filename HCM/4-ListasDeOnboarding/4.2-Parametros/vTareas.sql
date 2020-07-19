SELECT 	distinct
		TASK_NAME
FROM 	PER_ALLOCATED_TASKS_TL 
WHERE 	LANGUAGE = USERENV ('LANG')
		--Filtramos estas 2 tareas que no querían visualizar:
		AND TASK_NAME NOT IN ('Antes del primer día', 'Actividades del primer día')
		--NO pude filtrar por los IDs porque con cada nuevo registro se hace una actualizacion y cambia el id... entonces para el Task Name = "Antes del primer dia" tenemos varios registros con id distintos. Por esto es mejor borrar el Task_Name:
		--AND ALLOCATED_TASK_ID NOT IN (300000019204287, 300000019204288)		
--GROUP BY TASK_NAME
ORDER BY TASK_NAME



