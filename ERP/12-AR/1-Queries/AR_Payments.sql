--AR_Payments: los pagos de la factura. 

--PAGOS:
--Un pago se puede aplicar a una factura, o varias. O a una parte de una factura.
--Por ej. gaston me hace una factura por 100pe, y yo le hago un pago "parcial" de 50 pe. Me quedo debiendo 50 pe. Esto es un "pago parcial".

select  --Para joinear en Cloud con AR_Invoice_Header: 
        RCTA.CUSTOMER_TRX_ID	  	                                AS Customer_ID_3,
        -----------------------------------------------------------------------------------------------------------------------------------------------
        
        AR_PAYMENT_SCHED_BIL.due_date                               AS Due_Date,
        to_char(nvl(AR_PAYMENT_SCHED_BIL.receivables_charges_charged,to_number(0))          --Ver si usar AR_PAYMENT_SCHED_BIL o AR_PAYMENT_SCHED_PAYING
               )                                                    AS Charges_2,            --Amount_charges 
               
        AR_PAYMENT_SCHED_BIL.FREIGHT_ORIGINAL,
        AR_PAYMENT_SCHED_BIL.AMOUNT_DUE_ORIGINAL,
        AR_PAYMENT_SCHED_BIL.AMOUNT_DUE_REMAINING,
        AR_PAYMENT_SCHED_BIL.AMOUNT_APPLIED,
        AR_PAYMENT_SCHED_BIL.AMOUNT_CREDITED
        
from    RA_CUSTOMER_TRX_ALL 			    RCTA, 
        ar_payment_schedules_all            AR_PAYMENT_SCHED_BIL,
        --ar_payment_schedules_all          AR_PAYMENT_SCHED_PAYING
        HZ_CUST_ACCOUNTS                    HZCA_BILL        
        --HZ_CUST_ACCOUNTS                  HZCA_PAYING,
where
        --Join con Payments:
        RCTA.BILL_TO_CUSTOMER_ID                        = HZCA_BILL.cust_account_id
        AND HZCA_BILL.cust_account_id                   = AR_PAYMENT_SCHED_BIL.CUSTOMER_ID
        --AND     AR_PAYMENT_SCHED_PAYING.CUSTOMER_ID = HZCA_PAYING.cust_account_id 