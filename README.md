# SecureBank — Smart Banking Management System with Database-Based Fraud Detection

**University DBMS Capstone Project — BCSE302L: Database Systems**  
**School of Computer Science Engineering and Information Systems (SCOPE), VIT Vellore**

---

> [!WARNING]
> ### Academic Topic Allocation Discrepancy Notice
> **Important Note for Evaluation / Faculty Verification**:  
> In the official course topic allocation sheet for the laboratory component, student registration number **`24BDE0023`** was originally listed against the domain **`Hospital Management`**. However, per student instructions and current coursework objectives, this project has been fully developed as **`SecureBank — Smart Banking Management System with Database-Based Fraud Detection`**.  
> Please verify and reconcile this topic selection with your faculty instructor.

---

## 1. Project Overview

**SecureBank** is a full-stack, enterprise-modeled college DBMS project designed to simulate core commercial banking operations while delivering an impactful architectural innovation: **native, database-level fraud detection**.

Unlike conventional web applications where business rules and risk evaluations are performed in application memory (leaving data vulnerable to bypass, race conditions, or unhandled exceptions), SecureBank enforces ACID transactions, audit logging, and fraud detection directly inside the **Oracle Database** engine utilizing PL/SQL functions, procedures, explicit cursors, and database triggers.

---

## 2. Key Features & Innovations

### Core Banking Modules
1. **Customer Management**: Complete registration, unique contact constraint verification, search, and 360-degree customer profile view.
2. **Account Management**: Savings, Current, and Salary accounts, real-time ledger balance tracking, and status controls (`ACTIVE`, `BLOCKED`, `CLOSED`).
3. **Transaction Management**: Real cash deposits, cash withdrawals, and inter-account funds transfers powered by atomic PL/SQL procedures.
4. **Beneficiary Whitelisting**: Payee registration with composite uniqueness constraints to avoid duplicate recipient entries.
5. **Loan Management & Amortization**: Application evaluation, risk-based approvals/rejections, repayment recording, and automatic closure upon full amortization.
6. **Immutable Audit Trail**: Chronological event log automatically populated by database triggers on balance and status updates.

### Database-Based Fraud Detection (Innovation)
- **Rule R1 (Absolute High-Value Threshold)**: Any transfer or withdrawal where `amount > ₹1,00,000` is immediately flagged as `SUSPICIOUS`, setting risk level to `HIGH` and raising a `PENDING` fraud alert.
- **Rule R2 (Rapid Balance Drain)**: Any withdrawal or transfer where `amount > ₹50,000` AND `amount > 0.80 * balance` is flagged as `SUSPICIOUS` to catch rapid drainage attempts.
- **Rule R3 (Customer Risk Scoring)**: Evaluated by function `get_customer_risk`. Customers with 3 or more historical fraud alerts are categorized as `HIGH` risk, resulting in automatic loan rejections and account freeze eligibility.
- **Batch Processing Cursor (`check_high_risk_accounts`)**: An explicit PL/SQL cursor that iterates across all unreviewed alerts, audits customer risk, and automatically freezes high-risk accounts.

---

## 3. Technology Stack

- **Database Engine**: Oracle Database 11g Express Edition / Oracle 19c / 21c / 23c.
- **Database Programming**: Oracle SQL and PL/SQL (Procedures, Functions, Cursors, Triggers, Views).
- **Backend Application**: Python 3.10+ with FastAPI.
- **Database Connectivity**: Native `cx_Oracle` (Oracle 11g client) and `python-oracledb` (Oracle 12c+).
- **Frontend Layer**: HTML5, Modern Responsive CSS3, JavaScript, and Jinja2 Templates.
- **Testing Framework**: `pytest` (16 automated verification test cases).

---

## 4. Project Directory Structure

```text
securebank/
├── app/
│   ├── routes/
│   │   ├── accounts.py          # Account management & status update routes
│   │   ├── audit_logs.py        # System audit trail routes
│   │   ├── beneficiaries.py     # Payee whitelisting routes
│   │   ├── customers.py         # Customer CRUD & 360-degree profile
│   │   ├── fraud_alerts.py      # Fraud queue & batch cursor execution
│   │   ├── loans.py             # Loan application & repayments
│   │   ├── reports.py           # 7 real-time SQL analytical reports
│   │   └── transactions.py     # Deposits, withdrawals, and ACID transfers
│   ├── static/
│   │   ├── css/style.css        # Professional corporate banking stylesheet
│   │   └── js/main.js           # Modal dialogs & live database EMI calculator
│   ├── templates/               # Jinja2 HTML responsive templates
│   ├── database.py              # Oracle connection pool & query abstraction
│   └── main.py                  # FastAPI application entrypoint & dashboard
├── database/
│   ├── 01_create_tables.sql     # DDL for all 8 tables
│   ├── 02_constraints.sql       # Indexes and integrity verification
│   ├── 03_sequences.sql         # Sequences and auto-increment triggers
│   ├── 04_sample_data.sql       # 10+ consistent sample records per table
│   ├── 05_procedures.sql        # 6 PL/SQL stored procedures (transfer, loan, audit)
│   ├── 06_functions.sql         # 4 PL/SQL functions (balance, risk, EMI)
│   ├── 07_cursors.sql           # Explicit batch cursor procedures
│   ├── 08_triggers.sql          # Audit, status, and fraud triggers
│   ├── 09_views.sql             # 4 analytical database views
│   ├── 10_demo_queries.sql      # 17 advanced SQL queries with explanations
│   └── setup_all.sql            # Master all-in-one setup script
├── diagrams/
│   ├── er_diagram.mmd           # Complete Mermaid ER diagram
│   └── relational_schema.md     # Relational schema notation & normalization proof
├── docs/
│   ├── project_report.md        # Complete academic project report
│   ├── setup_guide.md           # Step-by-step installation instructions
│   └── viva_questions.md        # 25+ viva examination questions and answers
├── tests/
│   └── test_banking.py          # Automated test suite (16 tests)
├── .env.example                 # Environment template
├── .env                         # Local configuration file
├── requirements.txt             # Python dependencies
├── run.py                       # Application launcher script
└── README.md                    # Project documentation
```

---

## 5. Quick Start Guide

### Step 1: Create Oracle User
Connect to SQL*Plus as Administrator:
```powershell
$env:ORACLE_SID="XE"
sqlplus "/ as sysdba"
```
Run:
```sql
CREATE USER securebank IDENTIFIED BY securebank;
GRANT CONNECT, RESOURCE, DBA TO securebank;
GRANT UNLIMITED TABLESPACE TO securebank;
EXIT;
```

### Step 2: Initialize Database Objects & Seed Data
Execute the master script in SQL*Plus:
```powershell
cd securebank/database
cmd /c "sqlplus -S securebank/securebank @setup_all.sql < NUL"
```

### Step 3: Install Python Dependencies
```powershell
pip install -r securebank/requirements.txt
```

### Step 4: Run the Application
```powershell
python securebank/run.py
```
Open **`http://127.0.0.1:8000`** in your browser.

---

## 6. Running Verification Tests

Run the full automated test suite:
```powershell
python -m pytest securebank/tests/test_banking.py -v
```
**Test Results Summary**:
- `test_01_oracle_connection`: **PASSED**
- `test_02_valid_deposit`: **PASSED**
- `test_03_invalid_deposit_amount`: **PASSED**
- `test_04_valid_transfer_acid`: **PASSED**
- `test_05_insufficient_balance_transfer_rollback`: **PASSED**
- `test_06_same_account_transfer_rejected`: **PASSED**
- `test_07_invalid_recipient_transfer`: **PASSED**
- `test_08_fraud_detection_rule_r1`: **PASSED**
- `test_09_customer_risk_function_rule_r3`: **PASSED**
- `test_10_loan_processing_risk_check`: **PASSED**
- `test_11_loan_repayment_and_auto_close`: **PASSED**
- `test_12_unique_constraint_enforcement`: **PASSED**
- `test_13_foreign_key_constraint_enforcement`: **PASSED**
- `test_14_check_constraint_negative_balance`: **PASSED**
- `test_15_database_function_emi_calculation`: **PASSED**
- `test_16_cursor_check_high_risk_accounts`: **PASSED**

---

## 7. How to Demonstrate During Viva

1. **Scenario 1 — Normal Deposit**: Go to **Transactions** $\to$ Select Account #1 $\to$ Deposit ₹5,000 $\to$ Observe balance updated and audit log created in **Audit Logs**.
2. **Scenario 2 — Inter-Account Transfer**: Transfer ₹2,000 from Account #1 to Account #2 $\to$ Verify atomic debit and credit.
3. **Scenario 3 — Fraud Rule Trigger**: Transfer ₹1,50,000 from Account #5 to Account #2 $\to$ Notice system flags transaction as `SUSPICIOUS` and raises an unreviewed alert in **Fraud Alerts**.
4. **Scenario 4 — Batch Cursor Freeze**: Click **Run Batch Audit Cursor** on the Fraud Alerts page $\to$ Observe PL/SQL explicit cursor evaluating pending alerts and automatically freezing Account #3 due to 3+ fraud flags.
5. **Scenario 5 — Loan Processing & Repayment**: Apply for loan $\to$ Verify risk check $\to$ Make repayments until balance reaches zero $\to$ Confirm status shifts to `CLOSED`.
