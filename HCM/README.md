# Ejemplos de Queries para HCM:

* 1-Reportes de listados con informaciones personales, asignaciones, salarios y perfiles  (títulos) de los empleados.

* 2-Reporte de Candidatos: permite evaluar si un candidato tiene las calificaciones necesarias para la posición a la que realiza la requisición. 
	* 2.1-Queries utilizadas para el reporte.
	* 2.2-Parametros utilizados para el reporte.
	* 2.3-Data Model utilizado en BI para el reporte.
	* 2.4-Imagen del Excel del reporte.

* 3-Reporte de Selección de Candidatos: permite visualizar las fases y estados del Candidato en su progreso histórico de selección y las evaluaciones/cuestionarios que se le fueron realizados. 
	* 3.1-Queries utilizadas para el reporte.
	* 3.2-Parametros utilizados para el reporte.
	* 3.3-Imagen del RTF del reporte.

* 4-Reporte de Listas de Onboarding: este reporte debería traer una lista de tareas/”Checklist” que los empleados tienen que realizar (por ej. completar ciertos documentos, firmar contrato, etc.) con distintos datos (si esta tarea la completó o todavía está pendiente, la fecha de inicio y fin de la tarea, fecha en la cual se le asignó la tarea, etc.). 
	* 4.1-Queries utilizadas para el reporte.
	* 4.2-Parametros utilizados para el reporte.
	* 4.3-Imagen del Excel del reporte.

* 5-Reporte de Certificaciones Laborales: carta expedida a los empleados con el fin de obtener información acerca de su contrato (vigencia y fecha de inicio del mismo, salario, etc.).
	* 5.1-Queries utilizadas para el reporte.
	* 5.2-Imagen del RTF del reporte/carta.

* 6-Query utilizada para Reporte de Contactos de Empleados. 

* 7-Query utilizada para Reporte de Horarios de Empleados.

* 8-Query utilizada para Reporte de Contactos de Empleados emulando la funcionalidad de HCM Extract en modo novedades (De esta tendremos 2 fechas como parámetro y solo nos traerá los Contactos de los Empleados que sufrieron alguna modificación o fueron creados en ese rango de fechas). Para esto se tomaron en cuenta las fechas de last_update (por modificación) y effective_start_date (por creación) para filtrar en el where.  

* 9-Query utilizada para Reporte de Horarios asignados a los Empleados emulando la funcionalidad de HCM Extract en modo novedades (De esta tendremos 2 fechas como parámetro y solo nos traerá los Horarios de los Empleados que sufrieron alguna modificación o fueron creados en ese rango de fechas). Para esto se tomaron en cuenta las fechas de last_update (por modificación) y effective_start_date (por creación) para filtrar en el where.  

* 10-Queries para obtener:
	* 10.1-Datos de la Consola de transacción.
	* 10.2-Logueos de usuarios en el sistema. 
	* 10.3-Datos de flujos de aprobación (por ej. cuando se le da de alta a algún empleado). 

* 11-Reporte que muestra datos de Empleados y sus tareas correspondientes a sus distintias checklists asociadas que están en estado 'pendiente'. Además, se realizó una query de BURSTING (Ver carpeta 'CON_Bursting') para el envío de email diario mediante Jobs/Schedule. En esta especificamos los parámetros del Bursting y además obtenemos los emails de los usuarios con el rol de IT Security Manager (los cuales recibirán las salidas en Excel de estos Reportes).
	* 11.1-Queries utilizadas para el reporte (CON y SIN Bursting).
	* 11.2-Parametro utilizado para el Reporte (Checklists).

* 12-Reporte que muestra datos de Empleados y los Cuestionarios que completaron (los cuales están asociados a Checklists) con sus preguntas y respuestas. 
	* 12.1-Queries utilizadas para el reporte (Versión con y sin comentarios).
	* 12.2-Parametros utilizados para el Reporte.