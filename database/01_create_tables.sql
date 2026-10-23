-- ============================================================================
-- SecureBank DBMS Project - 01_create_tables.sql
-- Description: Drop and create all 8 core relational tables with Oracle DDL.
-- Compatible with Oracle Database 11g XE, 12c, 19c, 21c, and 23c.
-- ============================================================================

-- Drop tables in reverse dependency order to avoid FK constraint violations
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE audit_log CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE fraud_alert CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE loan_payment CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE loan CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE beneficiary CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE bank_transaction CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE account CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE customer CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 1. CUSTOMER TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE customer (
    customer_id      NUMBER(10)        NOT NULL,
    name             VARCHAR2(100)     NOT NULL,
    phone            VARCHAR2(20)      NOT NULL,
    email            VARCHAR2(100),
    address          VARCHAR2(200),
    city             VARCHAR2(50),
    date_of_birth    DATE,
    created_at       DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_phone UNIQUE (phone),
    CONSTRAINT uq_customer_email UNIQUE (email),
    CONSTRAINT chk_customer_phone CHECK (LENGTH(phone) >= 10)
);

-- ----------------------------------------------------------------------------
-- 2. ACCOUNT TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE account (
    account_id       NUMBER(10)        NOT NULL,
    customer_id      NUMBER(10)        NOT NULL,
    account_type     VARCHAR2(20)      NOT NULL,
    balance          NUMBER(14, 2)     DEFAULT 0 NOT NULL,
    status           VARCHAR2(20)      DEFAULT 'ACTIVE' NOT NULL,
    created_at       DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_account PRIMARY KEY (account_id),
    CONSTRAINT fk_account_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT chk_account_type CHECK (account_type IN ('SAVINGS', 'CURRENT', 'SALARY')),
    CONSTRAINT chk_account_balance CHECK (balance >= 0),
    CONSTRAINT chk_account_status CHECK (status IN ('ACTIVE', 'BLOCKED', 'CLOSED'))
);

-- ----------------------------------------------------------------------------
-- 3. BANK_TRANSACTION TABLE (Safely avoids reserved word 'TRANSACTION')
-- ----------------------------------------------------------------------------
CREATE TABLE bank_transaction (
    txn_id           NUMBER(10)        NOT NULL,
    account_id       NUMBER(10)        NOT NULL,
    txn_type         VARCHAR2(20)      NOT NULL,
    amount           NUMBER(14, 2)     NOT NULL,
    txn_date         DATE              DEFAULT SYSDATE NOT NULL,
    status           VARCHAR2(20)      DEFAULT 'SUCCESS' NOT NULL,
    description      VARCHAR2(255),
    CONSTRAINT pk_bank_transaction PRIMARY KEY (txn_id),
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) 
        REFERENCES account(account_id),
    CONSTRAINT chk_txn_type CHECK (txn_type IN ('DEPOSIT', 'WITHDRAW', 'TRANSFER')),
    CONSTRAINT chk_txn_amount CHECK (amount > 0),
    CONSTRAINT chk_txn_status CHECK (status IN ('SUCCESS', 'SUSPICIOUS', 'FAILED'))
);

-- ----------------------------------------------------------------------------
-- 4. BENEFICIARY TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE beneficiary (
    beneficiary_id   NUMBER(10)        NOT NULL,
    customer_id      NUMBER(10)        NOT NULL,
    ben_name         VARCHAR2(100)     NOT NULL,
    ben_account_no   VARCHAR2(30)      NOT NULL,
    bank_name        VARCHAR2(80)      DEFAULT 'SecureBank' NOT NULL,
    status           VARCHAR2(20)      DEFAULT 'ACTIVE' NOT NULL,
    created_at       DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_beneficiary PRIMARY KEY (beneficiary_id),
    CONSTRAINT fk_ben_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT uq_ben_account UNIQUE (customer_id, ben_account_no),
    CONSTRAINT chk_ben_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

-- ----------------------------------------------------------------------------
-- 5. LOAN TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE loan (
    loan_id          NUMBER(10)        NOT NULL,
    customer_id      NUMBER(10)        NOT NULL,
    loan_amount      NUMBER(14, 2)     NOT NULL,
    interest_rate    NUMBER(5, 2)      DEFAULT 8.5 NOT NULL,
    loan_term        NUMBER(4)         DEFAULT 12 NOT NULL,
    status           VARCHAR2(20)      DEFAULT 'PENDING' NOT NULL,
    application_date DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_loan PRIMARY KEY (loan_id),
    CONSTRAINT fk_loan_customer FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT chk_loan_amount CHECK (loan_amount > 0),
    CONSTRAINT chk_loan_interest CHECK (interest_rate BETWEEN 1 AND 30),
    CONSTRAINT chk_loan_term CHECK (loan_term > 0),
    CONSTRAINT chk_loan_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CLOSED'))
);

-- ----------------------------------------------------------------------------
-- 6. LOAN_PAYMENT TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE loan_payment (
    payment_id       NUMBER(10)        NOT NULL,
    loan_id          NUMBER(10)        NOT NULL,
    amount_paid      NUMBER(14, 2)     NOT NULL,
    payment_date     DATE              DEFAULT SYSDATE NOT NULL,
    payment_status   VARCHAR2(20)      DEFAULT 'COMPLETED' NOT NULL,
    CONSTRAINT pk_loan_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_loan FOREIGN KEY (loan_id) 
        REFERENCES loan(loan_id) ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (amount_paid > 0),
    CONSTRAINT chk_payment_status CHECK (payment_status IN ('COMPLETED', 'FAILED'))
);

-- ----------------------------------------------------------------------------
-- 7. FRAUD_ALERT TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE fraud_alert (
    alert_id         NUMBER(10)        NOT NULL,
    txn_id           NUMBER(10)        NOT NULL,
    reason           VARCHAR2(255)     NOT NULL,
    risk_level       VARCHAR2(20)      DEFAULT 'HIGH' NOT NULL,
    review_status    VARCHAR2(20)      DEFAULT 'PENDING' NOT NULL,
    alert_date       DATE              DEFAULT SYSDATE NOT NULL,
    reviewed_at      DATE,
    CONSTRAINT pk_fraud_alert PRIMARY KEY (alert_id),
    CONSTRAINT fk_alert_txn FOREIGN KEY (txn_id) 
        REFERENCES bank_transaction(txn_id) ON DELETE CASCADE,
    CONSTRAINT chk_alert_risk CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
    CONSTRAINT chk_alert_review CHECK (review_status IN ('PENDING', 'REVIEWED', 'FALSE_ALARM', 'CONFIRMED'))
);

-- ----------------------------------------------------------------------------
-- 8. AUDIT_LOG TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE audit_log (
    log_id           NUMBER(10)        NOT NULL,
    account_id       NUMBER(10),
    table_name       VARCHAR2(50)      NOT NULL,
    action_type      VARCHAR2(20)      NOT NULL,
    action_time      DATE              DEFAULT SYSDATE NOT NULL,
    details          VARCHAR2(400),
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id),
    CONSTRAINT fk_audit_account FOREIGN KEY (account_id) 
        REFERENCES account(account_id) ON DELETE SET NULL,
    CONSTRAINT chk_audit_action CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE', 'REVIEW'))
);
