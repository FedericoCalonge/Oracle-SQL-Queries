--Comentarios de workflow de aprobacion para TODO:

select 	*  
from 	FA_FUSION_SOAINFRA.wfcomments
order by COMMENTDATE desc

/*
--Ver estas otras tablas:
FA_FUSION_SOAINFRA.WFATTACHMENT
FA_FUSION_SOAINFRA.WFTASKASSIGNMENTSTATISTIC
FA_FUSION_SOAINFRA.WFTASKHISTORY
FA_FUSION_SOAINFRA.WFAPPROVALGROUPS
FA_FUSION_SOAINFRA.WFAPPROVALGROUPMEMBERS
FA_FUSION_SOAINFRA.WFCOLLECTIONTARGET
FA_FUSION_SOAINFRA.WFTASK   --column OUTCOME, once a request is approved this column will show a value as "Approve"
FA_FUSION_SOAINFRA.WFASSIGNEE
FA_FUSION_SOAINFRA.WFMESSAGEATTRIBUTE
OKC_K_APPROVAL_HISTORY 
fusion_ora_ess.request_history
*/


--Al parecer quieren un reporte con los comentarios incluidos en las transacciones pendientes.