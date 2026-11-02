from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, call_procedure

router = APIRouter(prefix="/loans", tags=["loans"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_loans(request: Request, status: str = None, success: str = None, error: str = None):
    """List all loans with remaining balance and repayment history."""
    params = {}
    where_clause = ""
    if status and status != "ALL":
        where_clause = "WHERE status = :st"
        params["st"] = status

    sql = f"""
        SELECT loan_id, customer_id, customer_name, loan_amount,
               interest_rate, loan_term, status,
               TO_CHAR(application_date, 'YYYY-MM-DD') AS app_date,
               total_paid, remaining_balance, repayment_percentage
        FROM v_loan_summary
        {where_clause}
        ORDER BY loan_id DESC
    """
    loans = execute_query(sql, params)

    # Customers for application form
    customers = execute_query("SELECT customer_id, name FROM customer ORDER BY name ASC")

    # Approved loans for repayment modal
    approved_loans = execute_query("SELECT loan_id, customer_name, loan_amount, remaining_balance FROM v_loan_summary WHERE status = 'APPROVED' ORDER BY loan_id ASC")

    return templates.TemplateResponse(request=request, name="loans.html", context={
        "request": request,
        "loans": loans,
        "customers": customers,
        "approved_loans": approved_loans,
        "selected_status": status or "ALL",
        "success": success,
        "error": error
    })


@router.post("/apply")
async def apply_loan(
    customer_id: int = Form(...),
    loan_amount: float = Form(...),
    interest_rate: float = Form(8.5),
    loan_term: int = Form(12)
):
    """Process loan application through process_loan PL/SQL procedure."""
    try:
        call_procedure("process_loan", [customer_id, loan_amount, interest_rate, loan_term])
        
        # Check decision
        res = execute_query("""
            SELECT status FROM (
                SELECT status FROM loan WHERE customer_id = :cid ORDER BY loan_id DESC
            ) WHERE ROWNUM = 1
        """, {"cid": customer_id}, fetch_one=True)

        loan_status = res.get("status") if res else "SUBMITTED"
        if loan_status == "REJECTED":
            return RedirectResponse(
                url="/loans?error=Loan+application+was+REJECTED+by+database+due+to+HIGH+customer+fraud+risk+(Rule+R3).",
                status_code=303
            )
        else:
            return RedirectResponse(
                url="/loans?success=Loan+application+evaluated+and+APPROVED+successfully!",
                status_code=303
            )
    except Exception as e:
        return RedirectResponse(url=f"/loans?error={str(e)}", status_code=303)


@router.post("/repay")
async def repay_loan(
    loan_id: int = Form(...),
    amount: float = Form(...)
):
    """Record loan payment using pay_loan PL/SQL procedure."""
    try:
        call_procedure("pay_loan", [loan_id, amount])
        return RedirectResponse(
            url=f"/loans?success=Payment+of+Rs.+{amount:,.2f}+recorded+successfully.",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/loans?error={str(e)}", status_code=303)


@router.get("/api/calculate-emi")
async def calculate_emi(principal: float, rate: float, term: int):
    """Calculate monthly loan installment using database calculate_loan_emi function."""
    try:
        sql = "SELECT calculate_loan_emi(:p, :r, :t) AS emi FROM DUAL"
        res = execute_query(sql, {"p": principal, "r": rate, "t": term}, fetch_one=True)
        emi = res.get("emi", 0) if res else 0
        total_payable = round(emi * term, 2)
        total_interest = round(total_payable - principal, 2)
        return JSONResponse({
            "principal": principal,
            "rate": rate,
            "term_months": term,
            "monthly_emi": emi,
            "total_payable": total_payable,
            "total_interest": total_interest
        })
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=400)


@router.get("/{loan_id}/payments")
async def get_loan_payments(loan_id: int):
    """API endpoint to get payments for a given loan."""
    sql = """
        SELECT payment_id, amount_paid, 
               TO_CHAR(payment_date, 'YYYY-MM-DD HH24:MI') AS payment_date,
               payment_status
        FROM loan_payment
        WHERE loan_id = :lid
        ORDER BY payment_id ASC
    """
    payments = execute_query(sql, {"lid": loan_id})
    return JSONResponse(payments)
