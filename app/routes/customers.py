from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, execute_non_query

router = APIRouter(prefix="/customers", tags=["customers"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_customers(request: Request, search: str = None, success: str = None, error: str = None):
    """List all customers with optional search filtering by name, city, or phone."""
    if search:
        search_param = f"%{search.strip().lower()}%"
        sql = """
            SELECT c.customer_id, c.name, c.phone, c.email, c.address, c.city,
                   TO_CHAR(c.created_at, 'YYYY-MM-DD') AS created_at,
                   COUNT(a.account_id) AS account_count,
                   NVL(SUM(a.balance), 0) AS total_balance
            FROM customer c
            LEFT JOIN account a ON c.customer_id = a.customer_id
            WHERE LOWER(c.name) LIKE :s OR LOWER(c.city) LIKE :s OR c.phone LIKE :s
            GROUP BY c.customer_id, c.name, c.phone, c.email, c.address, c.city, c.created_at
            ORDER BY c.customer_id ASC
        """
        customers = execute_query(sql, {"s": search_param})
    else:
        sql = """
            SELECT c.customer_id, c.name, c.phone, c.email, c.address, c.city,
                   TO_CHAR(c.created_at, 'YYYY-MM-DD') AS created_at,
                   COUNT(a.account_id) AS account_count,
                   NVL(SUM(a.balance), 0) AS total_balance
            FROM customer c
            LEFT JOIN account a ON c.customer_id = a.customer_id
            GROUP BY c.customer_id, c.name, c.phone, c.email, c.address, c.city, c.created_at
            ORDER BY c.customer_id ASC
        """
        customers = execute_query(sql)

    return templates.TemplateResponse("customers.html", {
        "request": request,
        "customers": customers,
        "search": search or "",
        "success": success,
        "error": error
    })


@router.post("/add")
async def add_customer(
    name: str = Form(...),
    phone: str = Form(...),
    email: str = Form(None),
    address: str = Form(None),
    city: str = Form(None),
    dob: str = Form(None)
):
    """Add a new customer to the database."""
    try:
        if len(phone.strip()) < 10:
            return RedirectResponse(url="/customers?error=Phone+number+must+be+at+least+10+digits", status_code=303)

        sql = """
            INSERT INTO customer (name, phone, email, address, city, date_of_birth)
            VALUES (:name, :phone, :email, :address, :city, 
                    CASE WHEN :dob IS NOT NULL THEN TO_DATE(:dob, 'YYYY-MM-DD') ELSE NULL END)
        """
        execute_non_query(sql, {
            "name": name.strip(),
            "phone": phone.strip(),
            "email": email.strip() if email else None,
            "address": address.strip() if address else None,
            "city": city.strip() if city else None,
            "dob": dob.strip() if dob else None
        })
        return RedirectResponse(url="/customers?success=Customer+created+successfully", status_code=303)
    except Exception as e:
        err_msg = str(e)
        if "unique constraint" in err_msg.lower():
            if "uq_customer_phone" in err_msg.lower():
                err_msg = "A customer with this phone number already exists."
            elif "uq_customer_email" in err_msg.lower():
                err_msg = "A customer with this email address already exists."
        return RedirectResponse(url=f"/customers?error={err_msg}", status_code=303)


@router.get("/{customer_id}", response_class=HTMLResponse)
async def view_customer_profile(request: Request, customer_id: int):
    """Detailed view of a customer including all accounts, beneficiaries, and loans."""
    cust_sql = """
        SELECT customer_id, name, phone, email, address, city,
               TO_CHAR(date_of_birth, 'YYYY-MM-DD') AS dob,
               TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI') AS created_at
        FROM customer
        WHERE customer_id = :id
    """
    customer = execute_query(cust_sql, {"id": customer_id}, fetch_one=True)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    accounts_sql = """
        SELECT account_id, account_type, balance, status,
               TO_CHAR(created_at, 'YYYY-MM-DD') AS created_at
        FROM account
        WHERE customer_id = :id
        ORDER BY account_id ASC
    """
    accounts = execute_query(accounts_sql, {"id": customer_id})

    loans_sql = """
        SELECT loan_id, loan_amount, interest_rate, loan_term, status,
               TO_CHAR(application_date, 'YYYY-MM-DD') AS app_date
        FROM loan
        WHERE customer_id = :id
        ORDER BY loan_id ASC
    """
    loans = execute_query(loans_sql, {"id": customer_id})

    ben_sql = """
        SELECT beneficiary_id, ben_name, ben_account_no, bank_name, status
        FROM beneficiary
        WHERE customer_id = :id
        ORDER BY beneficiary_id ASC
    """
    beneficiaries = execute_query(ben_sql, {"id": customer_id})

    # Risk level from DB function
    risk_sql = "SELECT get_customer_risk(:id) AS risk_level FROM DUAL"
    risk_res = execute_query(risk_sql, {"id": customer_id}, fetch_one=True)
    customer_risk = risk_res["risk_level"] if risk_res else "LOW"

    return templates.TemplateResponse("customer_profile.html", {
        "request": request,
        "customer": customer,
        "accounts": accounts,
        "loans": loans,
        "beneficiaries": beneficiaries,
        "customer_risk": customer_risk
    })


@router.post("/{customer_id}/edit")
async def edit_customer(
    customer_id: int,
    name: str = Form(...),
    phone: str = Form(...),
    email: str = Form(None),
    address: str = Form(None),
    city: str = Form(None)
):
    """Update customer details."""
    try:
        sql = """
            UPDATE customer 
            SET name = :name, phone = :phone, email = :email, 
                address = :address, city = :city
            WHERE customer_id = :id
        """
        execute_non_query(sql, {
            "name": name.strip(),
            "phone": phone.strip(),
            "email": email.strip() if email else None,
            "address": address.strip() if address else None,
            "city": city.strip() if city else None,
            "id": customer_id
        })
        return RedirectResponse(url=f"/customers/{customer_id}?success=Profile+updated+successfully", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/customers/{customer_id}?error={str(e)}", status_code=303)


@router.post("/{customer_id}/delete")
async def delete_customer(customer_id: int):
    """Delete a customer record (Cascades to accounts and loans)."""
    try:
        sql = "DELETE FROM customer WHERE customer_id = :id"
        execute_non_query(sql, {"id": customer_id})
        return RedirectResponse(url="/customers?success=Customer+deleted+successfully", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/customers?error={str(e)}", status_code=303)
