SELECT A.* 

FROM

(
SELECT txnh.module_identifier ProcessName,
  wft.creator Requestor,
  wft.assignees CurrentAssignee,
  wft.assigneddate AssignedDate,
  wft.title NotificationTitle,
  txnd.status TxnStatus,
  txnh.object ObjectName

FROM 	per_all_people_f dp,
		per_person_names_f_v n,
		per_all_assignments_m asg,
		hrc_txn_header txnh,
		hrc_txn_data txnd,
		hcm_fusion_soainfra.WFTASK wft

WHERE dp.person_id             =n.person_id
AND asg.person_id              =n.person_id
AND LENGTH(asg.assignment_type)=1
AND asg.assignment_id          =txnh.object_id
AND wft.identificationkey      =TO_CHAR(txnh.transaction_id)
AND txnh.object                ='PER_ALL_ASSIGNMENTS_M'
AND txnh.transaction_id        =txnd.transaction_id
AND sysdate BETWEEN asg.effective_start_date AND asg.effective_end_date
AND asg.effective_latest_change='Y'
AND sysdate BETWEEN dp.effective_start_date AND dp.effective_end_date
AND sysdate BETWEEN n.effective_start_date AND n.effective_end_date

UNION

SELECT txnh.module_identifier ProcessName,
  wft.creator Requestor,
  wft.assignees CurrentAssignee,
  wft.assigneddate AssignedDate,
  wft.title NotificationTitle,
  txnd.status TxnStatus,
  txnh.object ObjectName

FROM 
	per_all_people_f dp,
	per_person_names_f_v n,
	per_all_assignments_m asg,
	hrc_txn_header txnh,
	hrc_txn_data txnd,
	hcm_fusion_soainfra.WFTASK wft

WHERE dp.person_id             =n.person_id
AND asg.person_id              =n.person_id
AND LENGTH(asg.assignment_type)=1
AND asg.period_of_service_id   =txnh.object_id
AND wft.identificationkey      =TO_CHAR(txnh.transaction_id)
AND txnh.object                ='PER_PERIODS_OF_SERVICE'
AND txnh.transaction_id        =txnd.transaction_id
AND sysdate BETWEEN asg.effective_start_date AND asg.effective_end_date
AND asg.effective_latest_change='Y'
AND sysdate BETWEEN dp.effective_start_date AND dp.effective_end_date
AND sysdate BETWEEN n.effective_start_date AND n.effective_end_date

UNION

SELECT txnh.module_identifier ProcessName,
  wft.creator Requestor,
  wft.assignees CurrentAssignee,
  wft.assigneddate AssignedDate,
  wft.title NotificationTitle,
  txnd.status TxnStatus,
  txnh.object ObjectName

FROM 
	hrc_txn_header txnh,
	hrc_txn_data txnd,
	hcm_fusion_soainfra.WFTASK wft

WHERE wft.identificationkey =TO_CHAR(txnh.transaction_id)
AND txnh.object             ='PER_ALL_PEOPLE_F'
AND txnh.transaction_id     =txnd.transaction_id
) A

order by A.TxnStatus