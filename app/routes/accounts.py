from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, execute_non_query

router = APIRouter(prefix="/accounts", tags=["accounts"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_accounts(
    request: Request,
    status: str = None,
    acc_type: str = None,
    success: str = None,
    error: str = None
):
    """List bank accounts with filtering by status and account type."""
    conditions = []
    params = {}

    if status and status != "ALL":
        conditions.append("a.status = :status")
        params["status"] = status
    if acc_type and acc_type != "ALL":
        conditions.append("a.account_type = :acc_type")
        params["acc_type"] = acc_type

    where_clause = "WHERE " + " AND ".join(conditions) if conditions else ""

    sql = f"""
        SELECT a.account_id, a.customer_id, c.name AS customer_name,
               c.phone, a.account_type, a.balance, a.status,
               TO_CHAR(a.created_at, 'YYYY-MM-DD') AS created_at
        FROM account a
        JOIN customer c ON a.customer_id = c.customer_id
        {where_clause}
        ORDER BY a.account_id ASC
    """
    accounts = execute_query(sql, params)

    # Also fetch all customers for the "Open New Account" dropdown
    cust_sql = "SELECT customer_id, name, phone FROM customer ORDER BY name ASC"
    customers = execute_query(cust_sql)

    return templates.TemplateResponse("accounts.html", {
        "request": request,
        "accounts": accounts,
        "customers": customers,
        "selected_status": status or "ALL",
        "selected_type": acc_type or "ALL",
        "success": success,
        "error": error
    })


@router.post("/add")
async def open_account(
    customer_id: int = Form(...),
    account_type: str = Form(...),
    initial_deposit: float = Form(0.0)
):
    """Open a new bank account with optional initial deposit."""
    try:
        if initial_deposit < 0:
            return RedirectResponse(url="/accounts?error=Initial+deposit+cannot+be+negative", status_code=303)

        sql = """
            INSERT INTO account (customer_id, account_type, balance, status)
            VALUES (:cid, :atype, :bal, 'ACTIVE')
        """
        execute_non_query(sql, {
            "cid": customer_id,
            "atype": account_type,
            "bal": initial_deposit
        })
        return RedirectResponse(url="/accounts?success=Bank+account+opened+successfully", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/accounts?error={str(e)}", status_code=303)


@router.post("/{account_id}/status")
async def update_account_status(
    account_id: int,
    status: str = Form(...)
):
    """Update status of an account (ACTIVE, BLOCKED, CLOSED)."""
    try:
        sql = "UPDATE account SET status = :status WHERE account_id = :id"
        execute_non_query(sql, {"status": status, "id": account_id})
        return RedirectResponse(url="/accounts?success=Account+status+updated+successfully", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/accounts?error={str(e)}", status_code=303)
