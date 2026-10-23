"""
Comprehensive Test Suite for SecureBank DBMS.
Tests real Oracle database operations, ACID transfers, fraud detection rules,
stored procedures, functions, constraints, and cursor batch processing.
"""

import sys
import os
import pytest
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from securebank.app.database import (
    execute_query,
    execute_non_query,
    call_procedure,
    test_connection as check_db_connection
)


def test_01_oracle_connection():
    """Verify live Oracle Database connection and query execution."""
    ok, res = check_db_connection()
    assert ok is True, f"Oracle connection failed: {res}"
    assert "db_time" in res


def test_02_valid_deposit():
    """Test depositing funds into an account and verifying balance increment."""
    # Account 1 initial balance
    acc_before = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    initial_bal = float(acc_before["balance"])

    deposit_amount = 2500.00
    call_procedure("deposit_money", [1, deposit_amount, "Automated Test Deposit"])

    acc_after = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    new_bal = float(acc_after["balance"])

    assert new_bal == pytest.approx(initial_bal + deposit_amount, 0.01)

    # Verify audit log was recorded
    audit = execute_query("""
        SELECT * FROM (
            SELECT details FROM audit_log WHERE account_id = 1 ORDER BY log_id DESC
        ) WHERE ROWNUM = 1
    """, fetch_one=True)
    assert audit is not None
    assert "Deposit" in audit["details"]


def test_03_invalid_deposit_amount():
    """Test that zero or negative deposit amounts are rejected by procedure."""
    with pytest.raises(Exception) as excinfo:
        call_procedure("deposit_money", [1, -500.00, "Invalid Deposit"])
    assert "greater than zero" in str(excinfo.value).lower() or "20011" in str(excinfo.value)


def test_04_valid_transfer_acid():
    """Test valid money transfer: atomic debit of sender and credit of receiver."""
    sender_before = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    receiver_before = execute_query("SELECT balance FROM account WHERE account_id = 2", fetch_one=True)

    transfer_amount = 1000.00
    call_procedure("transfer_money", [1, 2, transfer_amount, "Automated ACID Test Transfer"])

    sender_after = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    receiver_after = execute_query("SELECT balance FROM account WHERE account_id = 2", fetch_one=True)

    assert float(sender_after["balance"]) == pytest.approx(float(sender_before["balance"]) - transfer_amount, 0.01)
    assert float(receiver_after["balance"]) == pytest.approx(float(receiver_before["balance"]) + transfer_amount, 0.01)


def test_05_insufficient_balance_transfer_rollback():
    """Test transfer exceeding sender balance: must fail and preserve balances (rollback)."""
    sender_before = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    receiver_before = execute_query("SELECT balance FROM account WHERE account_id = 2", fetch_one=True)

    excessive_amount = float(sender_before["balance"]) + 999999.00

    with pytest.raises(Exception) as excinfo:
        call_procedure("transfer_money", [1, 2, excessive_amount, "Excessive Transfer"])
    assert "insufficient" in str(excinfo.value).lower() or "20005" in str(excinfo.value)

    # Verify balances remained unchanged
    sender_after = execute_query("SELECT balance FROM account WHERE account_id = 1", fetch_one=True)
    receiver_after = execute_query("SELECT balance FROM account WHERE account_id = 2", fetch_one=True)
    assert float(sender_after["balance"]) == float(sender_before["balance"])
    assert float(receiver_after["balance"]) == float(receiver_before["balance"])


def test_06_same_account_transfer_rejected():
    """Test that transfer to the same account is rejected."""
    with pytest.raises(Exception) as excinfo:
        call_procedure("transfer_money", [1, 1, 500.00, "Self Transfer"])
    assert "different" in str(excinfo.value).lower() or "20002" in str(excinfo.value)


def test_07_invalid_recipient_transfer():
    """Test transfer to non-existent recipient account fails cleanly."""
    with pytest.raises(Exception) as excinfo:
        call_procedure("transfer_money", [1, 99999, 100.00, "Transfer to Ghost Account"])
    assert "not found" in str(excinfo.value).lower() or "20006" in str(excinfo.value)


def test_08_fraud_detection_rule_r1():
    """Test Rule R1: Transfer exceeding Rs. 1,00,000 raises a high-risk fraud alert."""
    # Ensure Account 5 has enough balance for high-value transfer
    acc5 = execute_query("SELECT balance FROM account WHERE account_id = 5", fetch_one=True)
    if float(acc5["balance"]) < 150000:
        call_procedure("deposit_money", [5, 200000.00, "Seed high balance for test"])

    alerts_before = execute_query("SELECT COUNT(*) AS cnt FROM fraud_alert", fetch_one=True)["cnt"]

    # Transfer Rs. 1,05,000 (exceeds 1 Lakh threshold)
    call_procedure("transfer_money", [5, 2, 105000.00, "High Value Test Transfer"])

    alerts_after = execute_query("SELECT COUNT(*) AS cnt FROM fraud_alert", fetch_one=True)["cnt"]
    assert alerts_after == alerts_before + 1

    # Verify alert details
    latest_alert = execute_query("""
        SELECT * FROM (
            SELECT reason, risk_level, review_status FROM fraud_alert ORDER BY alert_id DESC
        ) WHERE ROWNUM = 1
    """, fetch_one=True)
    assert latest_alert["risk_level"] == "HIGH"
    assert "1,00,000" in latest_alert["reason"] or "R1" in latest_alert["reason"]
    assert latest_alert["review_status"] == "PENDING"


def test_09_customer_risk_function_rule_r3():
    """Test Rule R3: Function get_customer_risk returns HIGH for customers with >= 3 alerts."""
    # Customer 3 in our sample data has 3 alerts
    res = execute_query("SELECT get_customer_risk(3) AS risk FROM DUAL", fetch_one=True)
    assert res["risk"] == "HIGH"

    # Customer 2 has no fraud alerts -> LOW
    res2 = execute_query("SELECT get_customer_risk(2) AS risk FROM DUAL", fetch_one=True)
    assert res2["risk"] == "LOW"


def test_10_loan_processing_risk_check():
    """Test process_loan procedure approvals and rejections based on risk."""
    # Customer 2 (LOW risk) -> should be APPROVED
    call_procedure("process_loan", [2, 75000.00, 8.5, 12])
    latest_loan = execute_query("""
        SELECT * FROM (
            SELECT status FROM loan WHERE customer_id = 2 ORDER BY loan_id DESC
        ) WHERE ROWNUM = 1
    """, fetch_one=True)
    assert latest_loan["status"] == "APPROVED"

    # Customer 3 (HIGH risk due to 3+ fraud alerts) -> should be REJECTED
    call_procedure("process_loan", [3, 50000.00, 8.5, 12])
    rejected_loan = execute_query("""
        SELECT * FROM (
            SELECT status FROM loan WHERE customer_id = 3 ORDER BY loan_id DESC
        ) WHERE ROWNUM = 1
    """, fetch_one=True)
    assert rejected_loan["status"] == "REJECTED"


def test_11_loan_repayment_and_auto_close():
    """Test pay_loan procedure updates repayment and closes loan when paid off."""
    # Create a small approved loan to test auto-close
    res = execute_query("SELECT loan_seq.NEXTVAL AS lid FROM DUAL", fetch_one=True)
    lid = res["lid"]
    execute_non_query("""
        INSERT INTO loan (loan_id, customer_id, loan_amount, interest_rate, loan_term, status)
        VALUES (:lid, 1, 10000.00, 8.5, 6, 'APPROVED')
    """, {"lid": lid})

    # Pay 4,000 -> status remains APPROVED
    call_procedure("pay_loan", [lid, 4000.00])
    l_mid = execute_query("SELECT status FROM loan WHERE loan_id = :lid", {"lid": lid}, fetch_one=True)
    assert l_mid["status"] == "APPROVED"

    # Pay remaining 6,000 -> status must auto-update to CLOSED
    call_procedure("pay_loan", [lid, 6000.00])
    l_end = execute_query("SELECT status FROM loan WHERE loan_id = :lid", {"lid": lid}, fetch_one=True)
    assert l_end["status"] == "CLOSED"


def test_12_unique_constraint_enforcement():
    """Test that duplicate phone number violates UNIQUE constraint (ORA-00001)."""
    with pytest.raises(Exception) as excinfo:
        execute_non_query("""
            INSERT INTO customer (name, phone, email, city)
            VALUES ('Duplicate Test', '9876500001', 'dup@test.com', 'Chennai')
        """)
    err = str(excinfo.value)
    assert "00001" in err or "unique constraint" in err.lower()


def test_13_foreign_key_constraint_enforcement():
    """Test that inserting account with non-existent customer violates FK (ORA-02291)."""
    with pytest.raises(Exception) as excinfo:
        execute_non_query("""
            INSERT INTO account (customer_id, account_type, balance, status)
            VALUES (99999, 'SAVINGS', 1000, 'ACTIVE')
        """)
    err = str(excinfo.value)
    assert "02291" in err or "integrity constraint" in err.lower()


def test_14_check_constraint_negative_balance():
    """Test that negative balance violates CHECK constraint chk_account_balance (ORA-02290)."""
    with pytest.raises(Exception) as excinfo:
        execute_non_query("UPDATE account SET balance = -100 WHERE account_id = 1")
    err = str(excinfo.value)
    assert "02290" in err or "check constraint" in err.lower()


def test_15_database_function_emi_calculation():
    """Verify calculate_loan_emi database function math accuracy."""
    # Principal: 1,00,000, Rate: 12% p.a., Term: 12 months -> EMI is approx Rs. 8,884.88
    res = execute_query("SELECT calculate_loan_emi(100000, 12, 12) AS emi FROM DUAL", fetch_one=True)
    emi = float(res["emi"])
    assert emi == pytest.approx(8884.88, 0.5)


def test_16_cursor_check_high_risk_accounts():
    """Test check_high_risk_accounts cursor procedure blocks high-risk accounts."""
    call_procedure("check_high_risk_accounts", [])
    
    # Customer 3 is high risk, so Account 3 must be BLOCKED
    acc3 = execute_query("SELECT status FROM account WHERE account_id = 3", fetch_one=True)
    assert acc3["status"] == "BLOCKED"
