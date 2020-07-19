--Para chequear status: 
	--fa_fusion_soainfra.wftask will have a column OUTCOME, once a request is approved this column will show a value as "Approve" 
	--To check pending, approved, submitted, aborted statuses, you can refer to table FUSION.HRC_TXN_DATA

SELECT  d.state,d.status,h.*
FROM fusion.HRC_TXN_HEADER h,
  FUSION.HRC_TXN_DATA d
WHERE h.Transaction_id = d.Transaction_id
AND ( h.subject_id    IN
  ( SELECT DISTINCT PERSON_ID
  FROM fusion.PER_ALL_PEOPLE_F
  --WHERE person_number IN ('<<PERSON_NUMBER>>')
  )

OR h.object_id IN
  (SELECT DISTINCT assignment_id
  FROM fusion.per_all_assignments_m
  WHERE person_id IN
    (SELECT DISTINCT PERSON_ID
    FROM fusion.PER_ALL_PEOPLE_F
    --WHERE PERSON_NUMBER IN ('<<PERSON_NUMBER>>')
    )
  )

OR h.object_id IN
  (SELECT DISTINCT period_of_service_id
  FROM fusion.per_periods_of_service
  WHERE person_id IN
    (SELECT DISTINCT PERSON_ID
    FROM fusion.PER_ALL_PEOPLE_F
    --WHERE PERSON_NUMBER IN ('<<PERSON_NUMBER>>')
    )
	
  ) ) order by h.creation_date desc