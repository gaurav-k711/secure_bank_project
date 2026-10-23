-- ============================================================================
-- SecureBank DBMS Project - 07_cursors.sql
-- Description: PL/SQL Cursors for multi-record batch processing.
-- Iterates over pending alerts and applies rule-based account restrictions.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Cursor Procedure 1: check_high_risk_accounts
-- Uses an explicit cursor to process all pending fraud alerts one by one.
-- If the customer's risk is evaluated as HIGH (3+ alerts), their account status
-- is immediately updated to BLOCKED to prevent financial loss.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE check_high_risk_accounts 
IS
    -- Explicit cursor definition
    CURSOR c_alert IS
        SELECT f.alert_id, 
               f.reason, 
               t.account_id, 
               a.customer_id, 
               c.name AS customer_name,
               a.balance
        FROM fraud_alert f
        JOIN bank_transaction t ON f.txn_id = t.txn_id
        JOIN account a ON t.account_id = a.account_id
        JOIN customer c ON a.customer_id = c.customer_id
        WHERE f.review_status = 'PENDING';

    r c_alert%ROWTYPE;
    v_risk VARCHAR2(20);
    v_processed_count NUMBER := 0;
    v_blocked_count   NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('SECUREBANK BATCH AUDIT: Processing Pending Fraud Alerts...');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    OPEN c_alert;
    LOOP
        FETCH c_alert INTO r;
        EXIT WHEN c_alert%NOTFOUND;
        
        v_processed_count := v_processed_count + 1;
        v_risk := get_customer_risk(r.customer_id);

        IF v_risk = 'HIGH' THEN
            -- Automatically block high risk accounts
            UPDATE account
            SET status = 'BLOCKED'
            WHERE account_id = r.account_id;

            v_blocked_count := v_blocked_count + 1;

            INSERT INTO audit_log (account_id, table_name, action_type, details)
            VALUES (r.account_id, 'ACCOUNT', 'UPDATE', 
                    'Account automatically BLOCKED by batch cursor. High risk customer #' || r.customer_id || ' (' || r.customer_name || ')');

            DBMS_OUTPUT.PUT_LINE('[ACTION REQUIRED] Alert #' || r.alert_id || ' -> Customer: ' || r.customer_name || 
                                 ' | Risk: HIGH | Account #' || r.account_id || ' BLOCKED.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[INSPECTION] Alert #' || r.alert_id || ' -> Customer: ' || r.customer_name || 
                                 ' | Risk: ' || v_risk || ' | Waiting for manual compliance review.');
        END IF;
    END LOOP;
    CLOSE c_alert;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('BATCH RUN COMPLETE: ' || v_processed_count || ' alerts evaluated, ' || v_blocked_count || ' accounts blocked.');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        IF c_alert%ISOPEN THEN
            CLOSE c_alert;
        END IF;
        ROLLBACK;
        RAISE;
END check_high_risk_accounts;
/

-- ----------------------------------------------------------------------------
-- Cursor Procedure 2: generate_balance_report
-- Demonstrates parameterized cursor with loop calculation of account totals.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE generate_balance_report (
    p_min_balance IN NUMBER DEFAULT 50000
) 
IS
    CURSOR c_large_accounts (cp_min NUMBER) IS
        SELECT a.account_id, c.name, a.account_type, a.balance, a.status
        FROM account a
        JOIN customer c ON a.customer_id = c.customer_id
        WHERE a.balance >= cp_min
        ORDER BY a.balance DESC;

    v_rec c_large_accounts%ROWTYPE;
    v_total NUMBER(16, 2) := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Accounts with balance >= Rs. ' || p_min_balance || ':');
    DBMS_OUTPUT.PUT_LINE('ACC_ID  | CUSTOMER NAME         | TYPE     | BALANCE       | STATUS');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');

    OPEN c_large_accounts(p_min_balance);
    LOOP
        FETCH c_large_accounts INTO v_rec;
        EXIT WHEN c_large_accounts%NOTFOUND;

        v_total := v_total + v_rec.balance;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_rec.account_id, 8) || '| ' || 
                             RPAD(v_rec.name, 22) || '| ' || 
                             RPAD(v_rec.account_type, 9) || '| ' || 
                             LPAD(TO_CHAR(v_rec.balance, '999,999.99'), 14) || '| ' || 
                             v_rec.status);
    END LOOP;
    CLOSE c_large_accounts;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total holding balance across filtered accounts: Rs. ' || TO_CHAR(v_total, '999,999,999.99'));
END generate_balance_report;
/
