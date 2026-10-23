# SecureBank — DBMS Viva Examination Preparation Guide

This document contains 25+ essential viva examination questions and answers covering database design, relational theory, SQL, PL/SQL, ACID transactions, and fraud detection implementation in SecureBank.

---

### Q1: What is the main innovation of the SecureBank project?
**Answer**: SecureBank implements **database-based, rule-driven fraud detection**. Rather than evaluating financial transaction risk purely in web application code (which can be bypassed or fail during server crashes), the fraud detection rules (Rules R1, R2, and R3) are embedded directly within the Oracle Database engine using PL/SQL functions, triggers, and stored procedures. Suspicious transactions are automatically intercepted, flagged, and written to a dedicated `FRAUD_ALERT` table.

---

### Q2: What are the tables in your database and how are they related?
**Answer**: There are 8 tables normalized to 3NF/BCNF:
1. `CUSTOMER`: Holds personal and contact details.
2. `ACCOUNT`: Linked to `CUSTOMER` (1:N) via `customer_id`.
3. `BANK_TRANSACTION`: Linked to `ACCOUNT` (1:N) via `account_id`.
4. `BENEFICIARY`: Linked to `CUSTOMER` (1:N) via `customer_id`.
5. `LOAN`: Linked to `CUSTOMER` (1:N) via `customer_id`.
6. `LOAN_PAYMENT`: Linked to `LOAN` (1:N) via `loan_id`.
7. `FRAUD_ALERT`: Linked to `BANK_TRANSACTION` (1:N) via `txn_id`.
8. `AUDIT_LOG`: Linked to `ACCOUNT` (1:N) via `account_id`.

---

### Q3: Why is the transaction table named `BANK_TRANSACTION` instead of `TRANSACTION`?
**Answer**: In Oracle SQL, `TRANSACTION` is a reserved SQL keyword used for transaction control (e.g. `SET TRANSACTION READ ONLY`). Attempting to create a table named `TRANSACTION` causes `ORA-00903: invalid table name`. Renaming it to `BANK_TRANSACTION` completely eliminates naming conflicts while adhering to enterprise naming standards.

---

### Q4: How does your database ensure ACID properties during money transfers?
**Answer**: Through the stored procedure `transfer_money`:
- **Atomicity**: The procedure debits the sender and credits the receiver in a single logical unit. If an error occurs (such as an invalid recipient or network failure), the entire operation executes `ROLLBACK`, guaranteeing that money is never deducted without being credited.
- **Consistency**: CHECK constraints (`balance >= 0`) guarantee an account balance never drops below zero.
- **Isolation**: Row-level locking using `SELECT ... FOR UPDATE` prevents race conditions or double-spending if two concurrent transfers access the same account simultaneously.
- **Durability**: A successful transfer issues a database `COMMIT`, persisting changes to Oracle redo logs.

---

### Q5: What specific fraud rules are implemented in SecureBank?
**Answer**:
- **Rule R1**: Any withdrawal or transfer with an `amount > ₹1,00,000` is flagged as `SUSPICIOUS`, risk level `HIGH`.
- **Rule R2**: Any withdrawal or transfer with an `amount > ₹50,000` that also exceeds **80% of current account balance** is flagged as `SUSPICIOUS` (detecting sudden account drainage).
- **Rule R3**: Evaluated by function `get_customer_risk`. If a customer accumulates **3 or more fraud alerts**, their risk rating becomes `HIGH`, which automatically rejects new loan applications and flags their accounts for blocking.

---

### Q6: What is the difference between a Stored Procedure and a Database Function?
**Answer**:
- **Function**: Designed to compute and return a single scalar value. Can be invoked directly inside SQL queries (e.g., `SELECT get_customer_risk(customer_id) FROM customer;`). Must not perform direct database commits or rollbacks.
- **Procedure**: Designed to perform action-oriented business workflows (e.g., `transfer_money`, `process_loan`). Can perform multiple DML operations (`INSERT`, `UPDATE`, `DELETE`), manage transaction boundaries (`COMMIT`, `ROLLBACK`), and return multiple values via `OUT` parameters.

---

### Q7: What is an Explicit Cursor and where is it used in SecureBank?
**Answer**: A cursor is a pointer to the private SQL area in Oracle memory that holds the result set of a multi-row query.  
In SecureBank, procedure `check_high_risk_accounts` uses an **explicit cursor** (`c_alert`) to iterate through all `PENDING` fraud alerts one row at a time. For each alert, it calls `get_customer_risk`. If the customer's risk is `HIGH`, it executes an update to freeze the account (`status = 'BLOCKED'`) and logs the action into `AUDIT_LOG`.

---

### Q8: What database triggers are implemented and what are their events?
**Answer**:
1. **`trg_audit_account_changes`**: Event is `AFTER UPDATE OF balance, status ON account FOR EACH ROW`. Automatically logs previous and new balances and status changes to `AUDIT_LOG`.
2. **`trg_prevent_closed_account_txn`**: Event is `BEFORE INSERT ON bank_transaction FOR EACH ROW`. Checks if the target account is `CLOSED`. If closed, raises an application error (`ORA-20061`).
3. **`trg_auto_fraud_detection`**: Event is `AFTER INSERT ON bank_transaction FOR EACH ROW`. When a transaction is inserted with status `SUSPICIOUS`, the trigger automatically creates an alert record in `FRAUD_ALERT`.
4. **Auto-Increment Triggers**: `BEFORE INSERT` triggers on each table that assign `NEXTVAL` from sequences if the primary key is null.

---

### Q9: What is a Mutating Table error (ORA-04091) and how did you prevent it?
**Answer**: In Oracle, a row-level trigger that attempts to query or modify the exact same table that fired the trigger encounters `ORA-04091: table is mutating`.  
In SecureBank, we prevented this by clean separation of concerns:
- The balance update trigger `trg_audit_account_changes` fires on `ACCOUNT` and writes to `AUDIT_LOG` (a completely different table).
- The fraud alert trigger `trg_auto_fraud_detection` fires on `BANK_TRANSACTION` and writes to `FRAUD_ALERT` (a different table).
- Balance adjustments during transfers are performed directly inside the stored procedure `transfer_money`, completely avoiding circular trigger mutations.

---

### Q10: What is normalization and to what normal form is your database designed?
**Answer**: Normalization is the systematic process of organizing database relations to eliminate data redundancy and prevent insertion, update, and deletion anomalies.  
SecureBank is normalized to **Third Normal Form (3NF) and BCNF**:
- **1NF**: Every column contains atomic scalar values.
- **2NF**: Single-attribute surrogate primary keys eliminate partial dependencies.
- **3NF**: Non-key attributes depend only on the primary key, eliminating transitive dependencies.

---

### Q11: Why use Sequences instead of `MAX(id) + 1`?
**Answer**: Using `SELECT MAX(id) + 1` in multi-user applications causes fatal race conditions where two concurrent users generate the identical ID, leading to primary key violations (`ORA-00001`). Oracle Sequences generate guaranteed unique numbers in shared memory with ultra-fast sequential allocation and no row locking.

---

### Q12: How does the loan repayment logic work?
**Answer**: When a payment is made using procedure `pay_loan(p_loan_id, p_amount)`:
1. It validates the loan exists and has status `APPROVED`.
2. Inserts a record into `LOAN_PAYMENT`.
3. Calculates `SUM(amount_paid)` for that loan.
4. If total repaid $\ge$ principal loan amount, it updates `loan.status = 'CLOSED'`.
5. Records the milestone in `AUDIT_LOG` and commits.

---

### Q13: How is the loan EMI calculated?
**Answer**: Computed inside Oracle by function `calculate_loan_emi` using the standard banking formula:
$$EMI = \frac{P \times r \times (1+r)^n}{(1+r)^n - 1}$$
where $P$ is principal, $r$ is monthly interest rate ($\text{annual\_rate} / 1200$), and $n$ is term in months.

---

### Q14: What happens when a user attempts to withdraw more than their balance?
**Answer**: Two layers of defense prevent overdrafts:
1. **Procedural Check**: In `withdraw_money`, if `v_balance < p_amount`, the procedure raises application error `-20024: Insufficient funds`.
2. **Database Constraint**: `account` table has constraint `chk_account_balance CHECK (balance >= 0)`. Even if raw SQL bypassed the procedure, Oracle rejects any update resulting in a negative balance with `ORA-02290: check constraint violated`.

---

### Q15: How does the application connect to Oracle from Python?
**Answer**: SecureBank utilizes `cx_Oracle` (for Oracle Database 11g XE) and `oracledb` (for Oracle 12c+). Connection credentials and DSN are managed through environment variables (`.env`). The backend utilizes a Python context manager (`get_db()`) that handles cursor creation, execution, automatic commit on success, and automatic rollback on exceptions.
