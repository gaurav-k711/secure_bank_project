# SecureBank — Formal Relational Schema and Normalization

## 1. Relational Schema Definition

Primary Keys are denoted with **`PK`**, and Foreign Keys are denoted with **`FK`**.

```text
CUSTOMER (
    customer_id PK,
    name,
    phone UNIQUE,
    email UNIQUE,
    address,
    city,
    date_of_birth,
    created_at
)

ACCOUNT (
    account_id PK,
    customer_id FK -> CUSTOMER(customer_id),
    account_type,
    balance,
    status,
    created_at
)

BANK_TRANSACTION (
    txn_id PK,
    account_id FK -> ACCOUNT(account_id),
    txn_type,
    amount,
    txn_date,
    status,
    description
)

BENEFICIARY (
    beneficiary_id PK,
    customer_id FK -> CUSTOMER(customer_id),
    ben_name,
    ben_account_no,
    bank_name,
    status,
    created_at,
    UNIQUE(customer_id, ben_account_no)
)

LOAN (
    loan_id PK,
    customer_id FK -> CUSTOMER(customer_id),
    loan_amount,
    interest_rate,
    loan_term,
    status,
    application_date
)

LOAN_PAYMENT (
    payment_id PK,
    loan_id FK -> LOAN(loan_id),
    amount_paid,
    payment_date,
    payment_status
)

FRAUD_ALERT (
    alert_id PK,
    txn_id FK -> BANK_TRANSACTION(txn_id),
    reason,
    risk_level,
    review_status,
    alert_date,
    reviewed_at
)

AUDIT_LOG (
    log_id PK,
    account_id FK -> ACCOUNT(account_id),
    table_name,
    action_type,
    action_time,
    details
)
```

---

## 2. Foreign Key Referential Integrity Constraints

| Constraint Name | Child Table | Foreign Key Column | Parent Table | Referenced Column | On Delete Action |
|---|---|---|---|---|---|
| `fk_account_customer` | `ACCOUNT` | `customer_id` | `CUSTOMER` | `customer_id` | `CASCADE` |
| `fk_txn_account` | `BANK_TRANSACTION` | `account_id` | `ACCOUNT` | `account_id` | `RESTRICT / NO ACTION` |
| `fk_ben_customer` | `BENEFICIARY` | `customer_id` | `CUSTOMER` | `customer_id` | `CASCADE` |
| `fk_loan_customer` | `LOAN` | `customer_id` | `CUSTOMER` | `customer_id` | `CASCADE` |
| `fk_payment_loan` | `LOAN_PAYMENT` | `loan_id` | `LOAN` | `loan_id` | `CASCADE` |
| `fk_alert_txn` | `FRAUD_ALERT` | `txn_id` | `BANK_TRANSACTION` | `txn_id` | `CASCADE` |
| `fk_audit_account` | `AUDIT_LOG` | `account_id` | `ACCOUNT` | `account_id` | `SET NULL` |

---

## 3. Database Normalization Analysis

### First Normal Form (1NF)
- **Criterion**: Every attribute contains only atomic (indivisible) values. No repeating groups or multi-valued attributes.
- **Verification**:
  - In `CUSTOMER`, attributes such as `name`, `phone`, `city` contain single discrete scalar values.
  - Multi-valued attributes like multiple bank accounts or phone numbers are decomposed into distinct relation instances (`ACCOUNT`, separate rows).
  - No comma-separated strings or nested arrays exist in any column.
- **Verdict**: The schema strictly satisfies **1NF**.

### Second Normal Form (2NF)
- **Criterion**: The relation is in 1NF and contains no partial functional dependencies (every non-prime attribute is fully functionally dependent on the entire primary key).
- **Verification**:
  - All 8 tables utilize single-attribute synthetic/surrogate primary keys (`customer_id`, `account_id`, `txn_id`, `beneficiary_id`, `loan_id`, `payment_id`, `alert_id`, `log_id`).
  - Because no primary key is composite, partial functional dependencies are mathematically impossible ($X \to Y$ where $X \subset PK$).
- **Verdict**: The schema strictly satisfies **2NF**.

### Third Normal Form (3NF)
- **Criterion**: The relation is in 2NF and contains no transitive dependencies (no non-prime attribute is functionally dependent on another non-prime attribute, i.e., $X \to Y$ only where $X$ is a superkey or $Y$ is a prime attribute).
- **Verification**:
  - In `ACCOUNT`, `balance` and `status` depend solely on `account_id`. The customer's city and contact information are not repeated in `ACCOUNT`; only `customer_id` is maintained as a foreign key.
  - In `LOAN_PAYMENT`, `amount_paid` depends directly on `payment_id`. The loan's interest rate or borrower's name is not duplicated here; it is queried via the foreign key `loan_id`.
  - In `FRAUD_ALERT`, `reason`, `risk_level`, and `review_status` depend strictly on `alert_id`. The transaction's timestamp and amount are not duplicated.
- **Verdict**: The schema strictly satisfies **3NF**.

### Boyce-Codd Normal Form (BCNF)
- **Criterion**: For every functional dependency $X \to Y$, $X$ must be a superkey.
- **Verification**:
  - In `CUSTOMER`, `customer_id \to \{name, phone, email, address, city, date\_of\_birth, created\_at\}`. `customer_id` is the primary key and superkey.
  - While candidate keys `phone` and `email` also uniquely identify the tuple, each candidate key is a valid superkey with a unique constraint.
- **Verdict**: The schema satisfies **BCNF**.
