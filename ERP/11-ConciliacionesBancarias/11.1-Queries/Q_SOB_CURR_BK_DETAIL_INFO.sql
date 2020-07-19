SELECT  CEL1.Meaning                                ORIGIN,
        CEL1.lookup_code                            ORIGIN_2,
        CEL.MEANING                                 TRX_TYPE , /* ssumaith - bug 9498432*/
        SL.RECON_REFERENCE                          DOC_NUMBER,  
        TO_CHAR(SL.BOOKING_DATE,'YYYY-MM-DD')       TRX_DATE,
        0                                           BOOKS,
        DECODE(SL.FLOW_INDICATOR, 'DBIT', -1 * SL.AMOUNT, SL.AMOUNT)        BANK, /* based in input from Hillary in bug 9498432*/		
        'Line ' || to_char(SL.LINE_NUMBER) || ',' || SH.statement_number    STATEMENT_NUMBER, -- bug#9950271 based on shaik/xin resp,
        NULL                                        JOURNAL_NAME,
        NULL                                        BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME 
        --SL.STRUCTURED_PAYMENT_REFERENCE             REFERENCE_PAYMENT_FILE  --Ver si es este.

FROM    CE_STATEMENT_LINES      SL, 
        CE_STATEMENT_HEADERS    SH,
        CE_LOOKUPS              CEL,   /* ssumaith - bug 9498432*/
        CE_LOOKUPS              CEL1, 
        CE_BANK_ACCOUNTS        CBAC,
        CE_ALL_BANKS_V          CABV
        
WHERE   SL.STATEMENT_HEADER_ID = SH.STATEMENT_HEADER_ID
        AND RECON_STATUS = 'UNR'
        AND CEL.lookup_type = 'CE_TRX_TYPE' /* ssumaith - bug 9498432*/
        AND CEL.lookup_code = SL.TRX_TYPE /* ssumaith - bug 9498432*/
        AND CEL1.lookup_type = 'CE_UNRECON_SOURCE' /* ssumaith - bug 9498432*/
        AND CEL1.lookup_code = 'BS' /* ssumaith - bug 9498432*/
        AND nvl(sh.intraday_flag, 'N') <> 'Y'
        
        --Join to get to the name of the bank and the bank account: 
        AND SH.BANK_ACCOUNT_ID      = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID            = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --AND SH.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        AND TRUNC(SL.BOOKING_DATE) BETWEEN :start_date AND :end_date
        AND CBAC.ACCOUNT_OWNER_ORG_ID    =:P_LEGAL_ENTITY_ID --Legal Entity Filter
        AND SH.CURRENCY_CODE        =:P_CURRENCY_CODE --Currency Filter

UNION ALL

-- payables non-reconciled journals
SELECT	DISTINCT CEL1.Meaning                       ORIGIN,
        CEL1.lookup_code                            ORIGIN_2,
        CEL.MEANING                                 TRX_TYPE,
        to_char(AC.CHECK_NUMBER)                    DOC_NUMBER,
        TO_CHAR(NVL(AC.CLEARED_DATE, AC.CHECK_DATE),'YYYY-MM-DD') 
                                                    TRX_DATE,
        -- -1*CLEARED_AMOUNT BOOKS,
        --NVL(GJL.ENTERED_DR,0)- NVL(GJL.ENTERED_cR ,0) BOOKS, --bug 14539897 replace with ACCOUNTED_DR/CR
        --NVL(GJL.ACCOUNTED_DR,0)- NVL(GJL.ACCOUNTED_cR ,0) BOOKS, --bug 15858278 replace GL with XLA,
        --NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0) BOOKS,  -- bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(XAL.ENTERED_DR,0)- NVL(XAL.ENTERED_CR ,0)), (NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0)))
                                                    BOOKS,  
        0                                           BANK,
        'Line ' || GJL.je_Line_num ||',' ||GJH.Name||','||GJB.NAME 
                                                    STATEMENT_NUMBER, 
        GJH.NAME                                    JOURNAL_NAME, 
        GJB.NAME                                    BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --AC.PAYMENT_INSTRUCTION_ID                   REFERENCE_PAYMENT_FILE
        
FROM    GL_JE_HEADERS GJH, 
        GL_JE_LINES GJL, 
        GL_JE_BATCHES GJB,
        GL_LEDGERS  GL,
        XLA_AE_HEADERS XAH , 
        XLA_AE_LINES XAL, 
        AP_CHECKS_ALL AC, 
        XLA_TRANSACTION_ENTITIES TRX, 
        XLA_EVENTS XE ,
        CE_INTERNAL_BANK_ACCTS_V ACCT,
        GL_IMPORT_REFERENCES GLIR,
        CE_LOOKUPS CEL, 
        CE_LOOKUPS CEL1,
        CE_TRX_TYPE_MAPPING CE_TRX,
        CE_BANK_ACCT_USES_ALL CE_BAU,
        CE_BANK_ACCOUNTS CBAC,
        CE_ALL_BANKS_V   CABV
        
WHERE   GJH.JE_HEADER_ID = GJL.JE_HEADER_ID 
        AND	GJH.JE_SOURCE = 'Payables' 
        AND GJL.LEDGER_ID = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	= 'PRIMARY'
        AND	XAH.AE_HEADER_ID = XAL.AE_HEADER_ID 
        --AND XAL.GL_SL_LINK_ID     = GJL.GL_SL_LINK_ID -- ssumaith - bug9498432 added following 3 joins
        AND XAL.GL_SL_LINK_ID = GLIR.GL_SL_LINK_ID 
        and xah.application_id = 200			-- bug 15858278 ADDED
        and xah.application_id = xal.application_id
        and xal.gl_sl_link_table = GLIR.GL_SL_LINK_table
        AND GJB.JE_BATCH_ID = GLIR.JE_BATCH_ID
        AND GLIR.JE_HEADER_ID = GJL.JE_HEADER_ID 
        AND GLIR.JE_LINE_NUM = GJL.JE_LINE_NUM 
        AND GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
        AND GJB.STATUS = 'P'   -- bug 15858278 ADDED
        --AND	TRX.SOURCE_ID_INT_1 = AC.CHECK_ID  --bug 25027655
        AND NVL(TRX.SOURCE_ID_INT_1, -99) = AC.CHECK_ID
        AND	XE.ENTITY_ID = TRX.ENTITY_ID
        AND	XAH.EVENT_ID = XE.EVENT_ID
        AND	TRX.APPLICATION_ID =200
        AND	AC.RECON_FLAG = 'N'
        AND	ac.status_lookup_code  in ('NEGOTIABLE', 'CLEARED') -- bug 22499351 exclude Voided trx
        AND	TRX.APPLICATION_ID = XE.APPLICATION_ID 
        AND	TRX.ENTITY_CODE = 'AP_PAYMENTS'  
        AND	XAL.GL_SL_LINK_TABLE IN ('XLAJEL') 
        and ACCT.BANK_ACCOUNT_ID = CE_BAU.BANK_ACCOUNT_ID
        AND GJL.CODE_COMBINATION_ID = ACCT.ASSET_CODE_COMBINATION_ID
        AND CE_BAU.ORG_ID = AC.ORG_ID
        AND CE_BAU.BANK_ACCT_USE_ID = AC.CE_BANK_ACCT_USE_ID
        AND CE_BAU.AP_USE_ENABLE_FLAG = 'Y' 
        AND CEL1.lookup_type = 'CE_UNRECON_SOURCE'
        AND CEL1.lookup_code = 'AP'
        AND CEL.lookup_type(+) = 'CE_TRX_TYPE'
        and nvl(ce_trx.active_flag (+), 'Y') = 'Y'
        AND CE_TRX.trx_type =CEL.LOOKUP_CODE(+)
        AND CE_TRX.PMT_RCT_METHOD(+)=ac.payment_method_code
        
        --Join to get to the name of the bank and the bank account:
        AND ACCT.BANK_ACCOUNT_ID = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID         = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --AND ACCT.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        --Keep it commented: AND	GJL.EFFECTIVE_DATE BETWEEN :start_date AND :end_date -- bug 15968568 replace with XE.EVENT_DATE  
        AND	XE.EVENT_DATE BETWEEN :start_date AND :end_date 
        AND AC.LEGAL_ENTITY_ID  =:P_LEGAL_ENTITY_ID  --Legal Entity Filter
        AND GJH.CURRENCY_CODE   =:P_CURRENCY_CODE --Currency Filter
        
UNION ALL

-- GETTING UNRECONCILED LINES FROM RECEIVABLES
SELECT	DISTINCT CEL1.Meaning   ORIGIN ,
        CEL1.lookup_code        ORIGIN_2,
        CEL.Meaning  TRX_TYPE  ,
        to_char(CR.RECEIPT_NUMBER) DOC_NUMBER,
        TO_CHAR(NVL(CR.DEPOSIT_DATE, CR.RECEIPT_DATE),'YYYY-MM-DD') TRX_DATE,
        --CR.AMOUNT BOOKS,
        --NVL(GJL.ENTERED_DR,0)- NVL(GJL.ENTERED_cR ,0) BOOKS,--bug 14539897 replace with ACCOUNTED_DR/CR
        --NVL(GJL.ACCOUNTED_DR,0)- NVL(GJL.ACCOUNTED_cR ,0) BOOKS, --bug 15858278 replace GL with XLA,
        --NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0) BOOKS, -- bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(XAL.ENTERED_DR,0)- NVL(XAL.ENTERED_CR ,0)), (NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0))) BOOKS,  
        0  BANK,
        'Line ' || GJL.je_Line_num ||',' ||GJH.Name||','||GJB.NAME STATEMENT_NUMBER, 
        GJH.NAME JOURNAL_NAME, 
        GJB.NAME BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --NULL                                        REFERENCE_PAYMENT_FILE
        
FROM    GL_JE_LINES GJL
        , GL_JE_HEADERS GJH
        , GL_JE_BATCHES  GJB
        , AR_DISTRIBUTIONS_ALL ARD
        , XLA_DISTRIBUTION_LINKS XDL
        , XLA_AE_LINES XAL
        , AR_CASH_RECEIPT_HISTORY_ALL CRH
        , AR_CASH_RECEIPTS_ALL CR
        , XLA_AE_HEADERS XAH
        , CE_TRX_TYPE_MAPPING CTTM 
        , CE_INTERNAL_BANK_ACCTS_V ACCT
        , GL_IMPORT_REFERENCES GLIR 
        , CE_LOOKUPS CEL
        , CE_LOOKUPS CEL1
        , GL_LEDGERS  GL
        , CE_BANK_ACCT_USES_ALL  CE_BAU
        ,CE_BANK_ACCOUNTS CBAC
        ,CE_ALL_BANKS_V   CABV
        
WHERE   GJH.JE_HEADER_ID = GJL.JE_HEADER_ID 
        AND	GJH.JE_SOURCE = 'Receivables' 
        AND GJL.LEDGER_ID = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	= 'PRIMARY'
        AND	XAH.AE_HEADER_ID = XAL.AE_HEADER_ID 
        --AND XAL.GL_SL_LINK_ID     = GJL.GL_SL_LINK_ID -- ssumaith - bug9498432 added following 3 joins
        AND XAL.GL_SL_LINK_ID = GLIR.GL_SL_LINK_ID 
        and xah.application_id = 222			-- bug 15858278 ADDED
        and xah.application_id = xal.application_id
        and xal.gl_sl_link_table = GLIR.GL_SL_LINK_table
        AND GJB.JE_BATCH_ID = GLIR.JE_BATCH_ID
        AND GLIR.JE_HEADER_ID = GJL.JE_HEADER_ID 
        AND GLIR.JE_LINE_NUM = GJL.JE_LINE_NUM 
        AND GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
        AND GJB.STATUS = 'P'   -- bug 15858278 ADDED
        AND	ARD.SOURCE_TABLE = 'CRH'
        AND	ARD.SOURCE_ID = CRH.CASH_RECEIPT_HISTORY_ID
        AND	ARD.LINE_ID = XDL.SOURCE_DISTRIBUTION_ID_NUM_1
        AND	XDL.APPLICATION_ID = 222
        AND	XDL.SOURCE_DISTRIBUTION_TYPE = 'AR_DISTRIBUTIONS_ALL'
        AND	XAL.APPLICATION_ID = 222
        AND	XDL.AE_HEADER_ID = XAL.AE_HEADER_ID
        AND	XDL.AE_LINE_NUM = XAL.AE_LINE_NUM
        AND	XDL.AE_HEADER_ID = XAH.AE_HEADER_ID
        AND CTTM.PMT_RCT_METHOD(+) = TO_CHAR(CR.RECEIPT_METHOD_ID)
        AND CTTM.MAPPING_TYPE(+)='RECEIPT'
        and nvl(CTTM.active_flag (+), 'Y') = 'Y'
        AND crh.status in ('REMITTED', 'CLEARED', 'RISK_ELIMINATED')  -- bug 22499351 exclude Voided trx
        and not exists (select 1 from ar_cash_receipt_history_all crh1 where crh1.status = 'REVERSED' and crh1.current_record_flag = 'Y' and crh.cash_receipt_id = crh1.cash_receipt_id) 
        AND	CRH.CASH_RECEIPT_ID = CR.CASH_RECEIPT_ID
        AND	CR.SET_OF_BOOKS_ID = XAH.LEDGER_ID
        AND	CRH.EVENT_ID IS NOT NULL
        AND	CR.RECON_FLAG = 'N'
        AND	GJL.CODE_COMBINATION_ID         = ACCT.ASSET_CODE_COMBINATION_ID
        and CE_BAU.ORG_ID                   = CR.ORG_ID
        and CE_BAU.BANK_ACCT_USE_ID         = CR.REMIT_BANK_ACCT_USE_ID
        and CE_BAU.AR_USE_ENABLE_FLAG       = 'Y'
        and ACCT.BANK_ACCOUNT_ID            = CE_BAU.BANK_ACCOUNT_ID
        AND CEL.lookup_type (+)= 'CE_TRX_TYPE' /* ssumaith this join and next join - bug 9498432*/
        AND CEL.lookup_code (+)= CTTM.TRX_TYPE 
        AND CEL1.lookup_type = 'CE_UNRECON_SOURCE'
        AND CEL1.lookup_code = 'AR'
        
        --Join to get to the name of the bank and the bank account:
        AND ACCT.BANK_ACCOUNT_ID = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID         = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
       --AND ACCT.BANK_ACCOUNT_ID   = :P_BANK_ACCOUNT_ID
        --Keep it commented: AND	GJL.EFFECTIVE_DATE BETWEEN  :start_date AND :end_date --bug 15968568 replace with XAL.ACCOUNTING_DATE 
        AND	XAL.ACCOUNTING_DATE BETWEEN  :start_date AND :end_date 
        AND GJH.LEGAL_ENTITY_ID     =:P_LEGAL_ENTITY_ID     --Legal Entity Filter. Sino ver para sacarlo de aca: CR.LEGAL_ENTITY_ID  =:P_LEGAL_ENTITY_ID
        AND GJH.CURRENCY_CODE       =:P_CURRENCY_CODE       --Currency Filter
        
UNION ALL

-- UNRECONCILED  PAYROLL  TRX
SELECT  DISTINCT CEL.Meaning   ORIGIN ,
        CEL.lookup_code       ORIGIN_2,
        CEL.MEANING  TRX_TYPE,
        to_char(CE_PR.CHECK_NUMBER) DOC_NUMBER,
        TO_CHAR(NVL(CE_PR.CLEARED_DATE, CE_PR.PAYMENT_DATE),'YYYY-MM-DD') TRX_DATE,
        --  -1*AMOUNT BOOKS,
        --NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0) BOOKS,  --bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(XAL.ENTERED_DR,0)- NVL(XAL.ENTERED_CR ,0)), (NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0))) BOOKS,
        0  BANK,
        /* CE_PR.CHECK_NUMBER  STATEMENT_NUMBER,
        NULL  JOURNAL_NAME,
        NULL  BATCH_NAME */
        'Line ' || GJL.je_Line_num ||',' ||GJH.Name||','||GJB.NAME STATEMENT_NUMBER, 
        GJH.NAME JOURNAL_NAME, 
        GJB.NAME BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --NULL                                        REFERENCE_PAYMENT_FILE
        
FROM   PAY_CE_TRANSACTIONS	CE_PR,
       CE_BANK_ACCOUNTS_PAY_V 	CE_BA,
       CE_TRX_TYPE_MAPPING	CTTM,
       --CE_INTERNAL_BANK_ACCTS_V ACCT, --bug 15858278 removed
       GL_IMPORT_REFERENCES GLIR,--bug 15858278 7 tables added
       GL_JE_LINES    GJL,
       GL_JE_HEADERS  GJH,
       GL_JE_BATCHES  GJB,
       GL_LEDGERS  GL,
       xla_ae_headers xah,
       XLA_AE_LINES   XAL,
       pay_xla_events pe,
       CE_LOOKUPS CEL,
       CE_BANK_ACCOUNTS CBAC,
       CE_ALL_BANKS_V   CABV
       
WHERE   CE_PR.RECON_FLAG = 'N'
        AND CE_PR.PAYMENT_STATUS = 'PAID'
        AND CE_BA.BANK_ACCOUNT_ID = CE_PR.PAYER_BANK_ACCOUNT_ID                                      

        AND CTTM.PAY_PAYMENT_TYPE_ID(+) = CE_PR.PAYMENT_TYPE_ID
        and nvl(CTTM.active_flag (+), 'Y') = 'Y'		
        AND CE_BA.ASSET_CODE_COMBINATION_ID = GJL.CODE_COMBINATION_ID 
        AND CEL.lookup_type = 'CE_UNRECON_SOURCE' /* ssumaith this join and next join - bug 9498432*/
        AND CEL.lookup_code = 'PR' 
        and XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
        AND XAL.GL_SL_LINK_ID = GLIR.GL_SL_LINK_ID
        and xah.application_id = 801
        and xah.application_id = xal.application_id
        and xal.gl_sl_link_table = GLIR.GL_SL_LINK_table
        AND GJB.JE_BATCH_ID = GLIR.JE_BATCH_ID
        AND GLIR.JE_HEADER_ID = GJL.JE_HEADER_ID
        AND GLIR.JE_LINE_NUM = GJL.JE_LINE_NUM
        and GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
        AND GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
        AND GJB.STATUS = 'P'
        AND GJL.LEDGER_ID = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	= 'PRIMARY'
        and xah.gl_transfer_status_code = 'Y'
        and pe.event_id = xah.event_id
        and exists
            (select 1
                from pay_payroll_rel_actions ra,
                        pay_action_interlocks int1,
                        pay_action_interlocks int2,
                pay_action_interlocks int3 
             where ce_pr.pre_payment_id = ra.pre_payment_id 
                 and int1.locked_action_id = ra.payroll_rel_action_id
                 and int2.locked_action_id = int1.locking_action_id
                 and int2.locking_action_id = pe.payroll_rel_action_id
                 and int3.locked_action_id = ra.payroll_rel_action_id
                 and ce_pr.payroll_rel_action_id = int3.locking_action_id 
             )
        
       --Join to get to the name of the bank and the bank account:
        AND CE_BA.BANK_ACCOUNT_ID = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID          = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --Keep it commented: AND  CE_BA.ASSET_CODE_COMBINATION_ID = ACCT.ASSET_CODE_COMBINATION_ID
        --Keep it commented: AND  ACCT.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID  -- replaced with CE_BA.BANK_ACCOUNT_ID
        --AND CE_BA.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        --Keep it commented: AND    TRUNC(CE_PR.PAYMENT_DATE) BETWEEN :start_date AND :end_date -- replaced with GJL.EFFECTIVE_DATE
        --Keep it commented: AND    GJL.EFFECTIVE_DATE BETWEEN :start_date AND :end_date --bug 15968568 replace with XAL.ACCOUNTING_DATE 
        AND XAL.ACCOUNTING_DATE BETWEEN :start_date AND :end_date 
        AND GJH.LEGAL_ENTITY_ID =:P_LEGAL_ENTITY_ID --Legal Entity Filter
        AND GJH.CURRENCY_CODE   =:P_CURRENCY_CODE --Currency Filter
        
UNION ALL

-- CE_EXTERNAL_TRANSACTIONS
SELECT  CEL.Meaning ORIGIN,
        CEL.lookup_code   ORIGIN_2,
        CEL1.Meaning TRX_TYPE,
        TO_CHAR(EXT.REFERENCE_TEXT) DOC_NUMBER,
        TO_CHAR(EXT.TRANSACTION_DATE,'YYYY-MM-DD') TRX_DATE,
        --NVL(-GJL.ENTERED_DR, GJL.ENTERED_CR) BOOKS     ,
        --NVL(GJL.ENTERED_DR,0)- NVL(GJL.ENTERED_cR ,0) BOOKS, --bug 14539897 replace with ACCOUNTED_DR/CR
        --NVL(GJL.ACCOUNTED_DR,0)- NVL(GJL.ACCOUNTED_cR ,0) BOOKS,--bug 15858278 replace GL with XLA,
        --NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0) BOOKS,-- bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(XAL.ENTERED_DR,0)- NVL(XAL.ENTERED_CR ,0)), (NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0))) BOOKS,
        0 BANK,
       	'Line ' || GJL.je_Line_num ||',' ||GJH.Name||','||GJB.NAME STATEMENT_NUMBER, 
        GJH.NAME JOURNAL_NAME, 
        GJB.NAME BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --NULL                                        REFERENCE_PAYMENT_FILE
        
FROM   GL_JE_HEADERS GJH           ,
       GL_JE_LINES GJL             ,
       GL_JE_BATCHES GJB           ,
       GL_LEDGERS  GL,  
       XLA_AE_HEADERS XAH          ,
       XLA_AE_LINES XAL            ,
       CE_EXTERNAL_TRANSACTIONS EXT,
       XLA_TRANSACTION_ENTITIES TRX,
       XLA_EVENTS XE,
       CE_INTERNAL_BANK_ACCTS_V ACCT,
       GL_IMPORT_REFERENCES GLIR ,
       CE_LOOKUPS CEL, 
       CE_LOOKUPS CEL1,
       CE_BANK_ACCOUNTS CBAC,
       CE_ALL_BANKS_V   CABV
       
WHERE   GJH.JE_HEADER_ID                = GJL.JE_HEADER_ID
        AND GJH.JE_SOURCE               = 'Cash Management'
        AND GJL.LEDGER_ID               = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	    = 'PRIMARY'
        AND XAH.AE_HEADER_ID            = XAL.AE_HEADER_ID
        --AND XAL.GL_SL_LINK_ID         = GJL.GL_SL_LINK_ID -- ssumaith - bug9498432 added following 3 joins
        AND XAL.GL_SL_LINK_ID           = GLIR.GL_SL_LINK_ID 
        AND GLIR.JE_HEADER_ID           = GJL.JE_HEADER_ID 
        AND GLIR.JE_LINE_NUM            = GJL.JE_LINE_NUM
        AND GJB.JE_BATCH_ID             = GJH.JE_BATCH_ID
        AND GJB.STATUS                  = 'P'   -- bug 15858278 ADDED
        AND NVL(TRX.SOURCE_ID_INT_1, -99) = EXT.TRANSACTION_ID
        AND GL.LEDGER_ID          = TRX.LEDGER_ID
        AND TRX.SOURCE_ID_INT_1   = EXT.TRANSACTION_ID
        AND XE.ENTITY_ID          = TRX.ENTITY_ID
        AND XAH.EVENT_ID          = XE.EVENT_ID
        AND TRX.APPLICATION_ID    =260
        AND EXT.STATUS            = 'UNR'     
        AND TRX.APPLICATION_ID    = XE.APPLICATION_ID
        AND TRX.APPLICATION_ID    = XAL.APPLICATION_ID
        AND TRX.APPLICATION_ID    = XAH.APPLICATION_ID
        AND TRX.ENTITY_CODE       = 'CE_EXTERNAL'
        AND CEL.lookup_type = 'CE_UNRECON_SOURCE'    AND CEL.Lookup_code = 'XT'                              
        AND CEL1.Lookup_type(+) = 'CE_TRX_TYPE' AND CEL1.lookup_code(+) = EXT.TRANSACTION_TYPE  
        AND XAL.GL_SL_LINK_TABLE IN ('XLAJEL') 
        AND GJL.CODE_COMBINATION_ID = ACCT.ASSET_CODE_COMBINATION_ID
        AND ACCT.BANK_ACCOUNT_ID = EXT.BANK_ACCOUNT_ID

        --Join to get to the name of the bank and the bank account: 
        AND ACCT.BANK_ACCOUNT_ID  = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID          = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --AND ACCT.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        --Keep it commented: AND	GJL.EFFECTIVE_DATE BETWEEN :start_date AND :end_date --bug 15968568 replace with XE.EVENT_DATE
        AND XE.EVENT_DATE BETWEEN :start_date AND :end_date
        AND GJH.LEGAL_ENTITY_ID =:P_LEGAL_ENTITY_ID --Legal Entity Filter
        AND GJH.CURRENCY_CODE   =:P_CURRENCY_CODE   --Currency Filter:
        
UNION ALL
   
-- manual journal in GL
SELECT  CEL.MEANING ORIGIN,
        CEL.lookup_code  ORIGIN_2,    
        NULL TRX_TYPE, 
        GLH.NAME  DOC_NUMBER, 
        TO_CHAR(GLL.EFFECTIVE_DATE,'YYYY-MM-DD') TRX_DATE,
        --NVL(GLL.ENTERED_DR,0)- NVL(GLL.ENTERED_cR ,0) BOOKS,--bug 14539897 replace with ACCOUNTED_DR/CR
        --NVL(GLL.ACCOUNTED_DR,0)- NVL(GLL.ACCOUNTED_cR ,0) BOOKS, -- bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(GLL.ENTERED_DR,0)- NVL(GLL.ENTERED_CR ,0)), (NVL(GLL.ACCOUNTED_DR,0)- NVL(GLL.ACCOUNTED_CR ,0))) BOOKS,
        0 BANK,
        'Line ' || GLL.je_Line_num ||',' ||GLH.Name||','||GJB.NAME STATEMENT_NUMBER, 
        GLH.NAME JOURNAL_NAME,
        GJB.NAME BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --NULL                                        REFERENCE_PAYMENT_FILE
        
FROM    GL_JE_HEADERS  GLH,
        GL_JE_LINES GLL,
        GL_JE_BATCHES GJB,
        GL_LEDGERS  GL,  
        CE_INTERNAL_BANK_ACCTS_V CE,
        CE_LOOKUPS CEL,
        CE_BANK_ACCOUNTS CBAC,
        CE_ALL_BANKS_V   CABV
        
WHERE   GLL.CODE_COMBINATION_ID = CE.ASSET_CODE_COMBINATION_ID
        AND GLH.JE_SOURCE  NOT IN ('Cash Management','Receivables','Payables','Revaluation','Payroll')
        AND GJB.JE_BATCH_ID = GLH.JE_BATCH_ID 
        AND GLL.JE_HEADER_ID = GLH.JE_HEADER_ID
        AND GLL.LEDGER_ID = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	= 'PRIMARY'
        AND CEL.lookup_type = 'CE_UNRECON_SOURCE' 
        AND CEL.lookup_code = 'GL'
        AND GJB.STATUS = 'P'
        AND ((GLH.JE_FROM_SLA_FLAG is NULL) or (GLH.JE_FROM_SLA_FLAG='N'))
        /* bug 22635379, filtering out the journals which are reconciled. Journal reconciliation is enabled by fin-514 project.  */
        AND NOT EXISTS
            (
              SELECT 1
              FROM CE_RECON_HISTORY_ITEMS CRHI
              WHERE CRHI.SOURCE_ID    = GLL.JE_HEADER_ID
              AND CRHI.SOURCE_LINE_ID = GLL.JE_LINE_NUM
              AND CRHI.RECON_SOURCE       = 'ORA_GL'
              AND CRHI.CLEARED_DATE <= :end_date
            )
            
        --Join to get to the name of the bank and the bank account: 
        AND CE.BANK_ACCOUNT_ID    = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID          = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --AND CE.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        AND GLL.EFFECTIVE_DATE BETWEEN :start_date AND :end_date 
        AND GLH.LEGAL_ENTITY_ID =:P_LEGAL_ENTITY_ID --Legal Entity Filter
        AND GLH.CURRENCY_CODE   =:P_CURRENCY_CODE --Currency Filter
        
UNION ALL
   
-- manual journal in XLA
SELECT  CEL.MEANING ORIGIN   ,
        CEL.lookup_code   ORIGIN_2,
        NULL TRX_TYPE,
        XAH.DESCRIPTION DOC_NUMBER, -- GLH.NAME  DOC_NUMBER,
        TO_CHAR(XAL.ACCOUNTING_DATE,'YYYY-MM-DD') TRX_DATE,-- GLL.EFFECTIVE_DATE TRX_DATE,
        --NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR ,0) BOOKS,-- bug 22550369 
        decode(GL.CURRENCY_CODE, CBAC.CURRENCY_CODE, (NVL(XAL.ENTERED_DR,0)- NVL(XAL.ENTERED_CR ,0)), (NVL(XAL.ACCOUNTED_DR,0)- NVL(XAL.ACCOUNTED_CR,0))) BOOKS,
        0 BANK,
        'Line ' || XAL.AE_LINE_NUM ||',' ||XAH.DESCRIPTION||','||GJB.NAME STATEMENT_NUMBER,
        XAH.DESCRIPTION JOURNAL_NAME, 
        GJB.NAME BATCH_NAME,
        CBAC.BANK_ACCOUNT_NAME                      BANK_ACCOUNT_NAME,
        CABV.BANK_NAME                              BANK_NAME
        --NULL                                        REFERENCE_PAYMENT_FILE
        
FROM    GL_JE_BATCHES GJB,
        GL_IMPORT_REFERENCES GLIR,
        XLA_AE_HEADERS XAH ,
        XLA_AE_LINES XAL,
        GL_LEDGERS  GL,  
        CE_INTERNAL_BANK_ACCTS_V CE,
        CE_LOOKUPS CEL,
        CE_BANK_ACCOUNTS CBAC,
        CE_ALL_BANKS_V   CABV
        
WHERE   xal.CODE_COMBINATION_ID = CE.ASSET_CODE_COMBINATION_ID
        AND XAH.AE_HEADER_ID = XAL.AE_HEADER_ID
        AND XAL.LEDGER_ID = GL.LEDGER_ID
        AND GL.LEDGER_CATEGORY_CODE	= 'PRIMARY'
        and xah.application_id = xal.application_id
        AND XAL.GL_SL_LINK_ID = GLIR.GL_SL_LINK_ID
        and XAL.gl_sl_link_table = GLIR.GL_SL_LINK_table
        AND GJB.JE_BATCH_ID = GLIR.JE_BATCH_ID
        AND CEL.lookup_type = 'CE_UNRECON_SOURCE'
        AND CEL.lookup_code = 'GL'  
        AND GJB.STATUS = 'P'
        AND xah.event_type_code = 'MANUAL'
        
        --Join to get to the name of the bank and the bank account:
        AND CE.BANK_ACCOUNT_ID    = CBAC.BANK_ACCOUNT_ID
        AND CBAC.BANK_ID          = CABV.BANK_PARTY_ID   --O ver si joineo CBAC.BANK_ID contra HZ_PARTIES.
        
        --Parameters:
        --AND CE.BANK_ACCOUNT_ID = :P_BANK_ACCOUNT_ID
        AND XAL.ACCOUNTING_DATE BETWEEN :start_date AND :end_date
        AND XAH.LEGAL_ENTITY_ID   =:P_LEGAL_ENTITY_ID --Legal Entity Filter. Ver si tiene datos cargados.
        AND XAL.CURRENCY_CODE     =:P_CURRENCY_CODE --Currency Filter.

order by 5, 11 --TRX_DATE y BANK_ACCOUNT_NAME