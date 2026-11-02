from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, execute_non_query

router = APIRouter(prefix="/beneficiaries", tags=["beneficiaries"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_beneficiaries(request: Request, customer_id: int = None, success: str = None, error: str = None):
    """List beneficiaries with optional filtering by customer."""
    params = {}
    where_clause = ""
    if customer_id:
        where_clause = "WHERE b.customer_id = :cid"
        params["cid"] = customer_id

    sql = f"""
        SELECT b.beneficiary_id, b.customer_id, c.name AS customer_name,
               b.ben_name, b.ben_account_no, b.bank_name, b.status,
               TO_CHAR(b.created_at, 'YYYY-MM-DD') AS created_at
        FROM beneficiary b
        JOIN customer c ON b.customer_id = c.customer_id
        {where_clause}
        ORDER BY b.beneficiary_id ASC
    """
    beneficiaries = execute_query(sql, params)

    cust_sql = "SELECT customer_id, name FROM customer ORDER BY name ASC"
    customers = execute_query(cust_sql)

    return templates.TemplateResponse(request=request, name="beneficiaries.html", context={
        "request": request,
        "beneficiaries": beneficiaries,
        "customers": customers,
        "selected_customer": customer_id or "",
        "success": success,
        "error": error
    })


@router.post("/add")
async def add_beneficiary(
    customer_id: int = Form(...),
    ben_name: str = Form(...),
    ben_account_no: str = Form(...),
    bank_name: str = Form("SecureBank")
):
    """Register a new beneficiary for funds transfer."""
    try:
        sql = """
            INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status)
            VALUES (:cid, :bname, :bacc, :bbank, 'ACTIVE')
        """
        execute_non_query(sql, {
            "cid": customer_id,
            "bname": ben_name.strip(),
            "bacc": ben_account_no.strip(),
            "bbank": bank_name.strip()
        })
        return RedirectResponse(url="/beneficiaries?success=Beneficiary+registered+successfully", status_code=303)
    except Exception as e:
        err = str(e)
        if "uq_ben_account" in err.lower():
            err = "This beneficiary account is already registered for this customer."
        return RedirectResponse(url=f"/beneficiaries?error={err}", status_code=303)


@router.post("/{ben_id}/toggle")
async def toggle_beneficiary(ben_id: int, current_status: str = Form(...)):
    """Toggle beneficiary status between ACTIVE and INACTIVE."""
    try:
        new_status = "INACTIVE" if current_status == "ACTIVE" else "ACTIVE"
        sql = "UPDATE beneficiary SET status = :s WHERE beneficiary_id = :id"
        execute_non_query(sql, {"s": new_status, "id": ben_id})
        return RedirectResponse(url="/beneficiaries?success=Beneficiary+status+updated", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/beneficiaries?error={str(e)}", status_code=303)


@router.post("/{ben_id}/delete")
async def delete_beneficiary(ben_id: int):
    """Remove a beneficiary."""
    try:
        execute_non_query("DELETE FROM beneficiary WHERE beneficiary_id = :id", {"id": ben_id})
        return RedirectResponse(url="/beneficiaries?success=Beneficiary+removed", status_code=303)
    except Exception as e:
        return RedirectResponse(url=f"/beneficiaries?error={str(e)}", status_code=303)
