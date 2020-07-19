select 
        --Campos de Union en Cloud:
        PSV.vendor_id                   AS Vendor_ID_2,           --Muestro esto para asociarlo con la factura (INVOICES.sql) en Cloud.
                                                                --Asi no hago esto en el WHERE: AND AI.vendor_id  = PSV.vendor_id
        
        --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
        PSV.VENDOR_NAME					AS Proveedor_Name_1,
		HZP.PARTY_NAME					AS Proveedor_Name_2,
        PSII.INCOME_TAX_ID				AS CNPJ_Proveedor    	--CAMPO CNPJ/CPF para el PRESTADOR DO SERVICIO (Proveedor).   

from    HZ_PARTIES                      HZP,
        poz_suppliers_v               	PSV,                    --Consejo de Claudio: tratar de no usar vistas porque consumen mucha memoria. MEJORAR ESTO y ver para hacer join sin esta tabla. 
		poz_suppliers               	PS,
		POZ_SUPPLIERS_PII				PSII

where   HZP.party_id					= PSV.party_id
		AND PS.vendor_id		        = PSV.vendor_id
		AND PSII.vendor_id			    = PS.vendor_id 	