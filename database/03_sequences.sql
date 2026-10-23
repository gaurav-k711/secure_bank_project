-- ============================================================================
-- SecureBank DBMS Project - 03_sequences.sql
-- Description: Oracle Sequences and Auto-Increment Triggers for all 8 tables.
-- Ensures seamless compatibility across Oracle 11g XE, 12c, 19c, 21c, and 23c.
-- ============================================================================

-- Drop existing sequences if present
BEGIN
   FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
       'CUST_SEQ', 'ACC_SEQ', 'TXN_SEQ', 'BEN_SEQ', 'LOAN_SEQ', 'PAY_SEQ', 'ALERT_SEQ', 'AUDIT_SEQ'
   )) LOOP
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
   END LOOP;
END;
/

-- 1. Sequence for Customer
CREATE SEQUENCE cust_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 2. Sequence for Account
CREATE SEQUENCE acc_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 3. Sequence for Bank Transaction
CREATE SEQUENCE txn_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 4. Sequence for Beneficiary
CREATE SEQUENCE ben_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 5. Sequence for Loan
CREATE SEQUENCE loan_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 6. Sequence for Loan Payment
CREATE SEQUENCE pay_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 7. Sequence for Fraud Alert
CREATE SEQUENCE alert_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- 8. Sequence for Audit Log
CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1 NOCACHE;


-- ----------------------------------------------------------------------------
-- Auto-Increment Triggers: Assign NEXTVAL if primary key is not provided
-- ----------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_cust_id_pk
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    IF :NEW.customer_id IS NULL THEN
        SELECT cust_seq.NEXTVAL INTO :NEW.customer_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_acc_id_pk
BEFORE INSERT ON account
FOR EACH ROW
BEGIN
    IF :NEW.account_id IS NULL THEN
        SELECT acc_seq.NEXTVAL INTO :NEW.account_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_txn_id_pk
BEFORE INSERT ON bank_transaction
FOR EACH ROW
BEGIN
    IF :NEW.txn_id IS NULL THEN
        SELECT txn_seq.NEXTVAL INTO :NEW.txn_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_ben_id_pk
BEFORE INSERT ON beneficiary
FOR EACH ROW
BEGIN
    IF :NEW.beneficiary_id IS NULL THEN
        SELECT ben_seq.NEXTVAL INTO :NEW.beneficiary_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_loan_id_pk
BEFORE INSERT ON loan
FOR EACH ROW
BEGIN
    IF :NEW.loan_id IS NULL THEN
        SELECT loan_seq.NEXTVAL INTO :NEW.loan_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pay_id_pk
BEFORE INSERT ON loan_payment
FOR EACH ROW
BEGIN
    IF :NEW.payment_id IS NULL THEN
        SELECT pay_seq.NEXTVAL INTO :NEW.payment_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_alert_id_pk
BEFORE INSERT ON fraud_alert
FOR EACH ROW
BEGIN
    IF :NEW.alert_id IS NULL THEN
        SELECT alert_seq.NEXTVAL INTO :NEW.alert_id FROM DUAL;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_audit_id_pk
BEFORE INSERT ON audit_log
FOR EACH ROW
BEGIN
    IF :NEW.log_id IS NULL THEN
        SELECT audit_seq.NEXTVAL INTO :NEW.log_id FROM DUAL;
    END IF;
END;
/
