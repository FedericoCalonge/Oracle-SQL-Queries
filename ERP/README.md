# Ejemplos de Queries para ERP:

* 1-Ejemplo para construir una factura de compra con datos básicos (encabezado y linea de la factura, datos de comprador, etc.)

* 2-Datos de entidades legales, unidades de negocio y libros mayores. 

* 3-Datos para reportes de facturación/pagos (info de clientes, proveedores, localizaciones proveedores, etc.)

* 4-Ejemplo de utilización de Decode y cómo encontrar campos en común entre 2 tablas para realizar los JOIN (necesario cuando en la documentación no nos especifican estos campos en común)

* 5-Ejemplo con más cantidad de datos que el -1- para construir una factura de compra: 
	* 5.1-Query principal.
	* 5.2-Lista parametros para utilizar en BI.
	* 5.3-Imágen del RTF de ejemplo del Reporte/Factura.

* 6-Ejemplo Facturas de Venta. Los parámetros a utilizar en el reporte son: entidad legal, unidad de negocio y período (por ejemplo Ene-19). Y el Reporte nos traerá todas las facturas generadas en ese periodo para esa entidad legal y unidad de negocio especificados. La información debe estar agrupadas por día trayendo el primer y último número de factura y sus montos (o sea "día 1 tenemos estas facturas con estos montos; día 2 tenemos estas otras facturas con estos montos" y así).
	* 6.1-Queries principales.
	* 6.2-Lista parametros para utilizar en BI. 
	* 6.3-Imágen del RTF de ejemplo del reporte.

* 7-Reporte de estados de pedidos. Hubo que hacer un UNION en 3 queries (cada una mostraba info distinta de acuerdo a distintos criterios que se tomaron). 
	* 7.1-Query principal con el UNION de las 3 queries. 
	* 7.2-Imágen del RTF de ejemplo del reporte.

* 8- Libro Diario (libro donde se anota día a día las operaciones) con todas las queries utilizadas e Imágen del RTF de ejemplo del reporte.
	* 8.1-Queries principales.
	* 8.2-Imágen del RTF de ejemplo del reporte.

* 9- Libro de Compras (libro donde se tiene un registro de las compras históricas de la empresa).
	* 9.1-Queries utilizadas para el reporte.
	* 9.2-Parametros utilizados para el reporte.
	* 9.3-Imágen del RTF de ejemplo del reporte.

* 10- Reporte de Facturaciones, Remitos y Puntos de Venta.
	* 10.1-Queries utilizadas para el reporte.
	* 10.2-Parametros utilizados para el reporte.
	* 10.3-Data Model utilizado en BI para el reporte: del Data Set 'G_LEGAL_ENTITY' se obtiene la entidad legal y sus datos. Luego pasamos a obtener los branchs (puntos de venta) y luego sus transacciones=facturas y los remitos asociados. Y por último mediante el party_id obtenemos los datos del cliente al cual le facturaron / hicieron el envio de mercadería. 

* 11-Reporte de Conciliaciones Bancarias.
	* 11.1-Queries utilizadas para el reporte.
	* 11.2-Parametros utilizados para el reporte.
	* 11.3-Imagen del RTF de ejemplo del reporte.
	* 11.4-Data Model utilizado en BI para el reporte.

* 12-Queries para sacar los datos más requeridos del módulo de AR (se almacenan las facturas de VENTAS - por esto tenemos CLIENTES -).
	* 12.1-Queries utilizadas para el reporte.
	* 12.2-Data Model utilizado en BI para el reporte.
	* 12.3-Esquema general módulo AR con tablas principales usado como orientación.

* 13-Queries para sacar los datos más requeridos del módulo de AP (se almacenan las facturas de COMPRAS - por esto tenemos PROVEEDORES -).