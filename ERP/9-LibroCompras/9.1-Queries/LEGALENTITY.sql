--Cabecera:
SELECT 	
        --Campo de union en Cloud:
        XEP.legal_entity_id                         AS Legal_entity_ID_1,     --Tenemos que mostrar este campo para asociarlo con el campo Legal_Entity_ID de INVOICES.sql.
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        XEP.name									AS Legal_entity_name,

	   (HZP.ADDRESS1 || '-' || HZP.ADDRESS2 || '-' || HZP.ADDRESS3 || '-' || HZP.ADDRESS4  
       || '-' || HZP.CITY ||'-' ||HZP.STATE || '.' || HZP.POSTAL_CODE  || '-' || HZP.PROVINCE || '-'  || HZP.COUNTY)   
													AS Address,  -- || es para concatenar.
		
		XEP.legal_entity_identifier					AS CNPJ,
		
		--Subquery para traer el NOMBRE de la Nombre_Unidad_Operativa/ BU (usando el parametro ingresado UNIDAD_NEGOCIO que es la ID):
		(select name                                  
        FROM   	HR_ORGANIZATION_UNITS		HRU		--Las tablas de las sub-querys NO tienen que estar joineadas en nuestra query principal.
        WHERE  	HRU.organization_id 		= :P_ORG_ID) 
													AS BU_name
        --1 entidad legal tiene varios BUs, por eso lo traemos de una subquery. 
	   
FROM	xle_entity_profiles        			XEP,
		hz_parties                    		HZP
        
WHERE 	--Join:
		XEP.party_id            			= HZP.party_id
		--Parametro (solo entidad legal, los demas son para las lineas):
		AND XEP.legal_entity_id    			= :P_LEGAL_ENTITY_ID