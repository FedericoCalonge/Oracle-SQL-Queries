--Comentarios de workflow de aprobacion con algunos filtros: 

SELECT 	TXN_header.module_identifier ProcessName,
		WT_task.creator Requestor,
		WT_task.assignees CurrentAssignee,
		WT_task.assigneddate AssignedDate,
		WT_task.title NotificationTitle,
		WT_task.COMPONENTNAME,
		TXN_data.status TxnStatus,
		TXN_header.object ObjectName,  
		WF_comments.wfcomment
FROM 	per_all_people_f PAPF,
		per_person_names_f_v PNAMES,
		per_all_assignments_m ASG,
		hrc_txn_header TXN_header,
		hrc_txn_data TXN_data,
		FA_fusion_soainfra.WFTASK WT_task,
		FA_FUSION_SOAINFRA.wfcomments WF_comments

WHERE 	PAPF.person_id             			=PNAMES.person_id
AND 	ASG.person_id              			=PNAMES.person_id
AND 	LENGTH(ASG.assignment_type)			=1
AND 	ASG.assignment_id          			=TXN_header.object_id
AND 	WT_task.identificationkey      		=TO_CHAR(TXN_header.transaction_id)
and 	WF_comments.taskid 					= WT_task.taskid
--AND 	TXN_header.object                	='PER_ALL_ASSIGNMENTS_M'   --Si quiero que me traiga solo asignaciones. 
AND 	TXN_header.transaction_id        	=TXN_data.transaction_id
AND 	sysdate BETWEEN ASG.effective_start_date AND ASG.effective_end_date
AND 	ASG.effective_latest_change	='Y'
AND 	sysdate BETWEEN PAPF.effective_start_date AND PAPF.effective_end_date
AND 	sysdate BETWEEN PNAMES.effective_start_date AND PNAMES.effective_end_date

order by WF_comments.COMMENTDATE desc