// ==========================================================================
// SecureBank - Interactive UI Client Scripts
// ==========================================================================

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
    }
}

// Close modal when clicking on overlay background
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('modal-overlay')) {
        e.target.classList.remove('active');
    }
});

// Auto-dismiss alert banners after 6 seconds
document.addEventListener('DOMContentLoaded', function() {
    const alerts = document.querySelectorAll('.alert-banner');
    alerts.forEach(function(alert) {
        setTimeout(function() {
            alert.style.transition = 'opacity 0.5s ease';
            alert.style.opacity = '0';
            setTimeout(function() { alert.remove(); }, 500);
        }, 6000);
    });
});

// Live Loan EMI Calculator using the Database PL/SQL Function
function calculateEMI() {
    const principal = document.getElementById('calc_principal')?.value;
    const rate = document.getElementById('calc_rate')?.value;
    const term = document.getElementById('calc_term')?.value;

    if (!principal || !rate || !term) return;

    fetch(`/loans/api/calculate-emi?principal=${encodeURIComponent(principal)}&rate=${encodeURIComponent(rate)}&term=${encodeURIComponent(term)}`)
        .then(response => response.json())
        .then(data => {
            if (data.monthly_emi !== undefined) {
                document.getElementById('emi_result_monthly').innerText = '₹ ' + Number(data.monthly_emi).toLocaleString('en-IN', {minimumFractionDigits: 2});
                document.getElementById('emi_result_total').innerText = '₹ ' + Number(data.total_payable).toLocaleString('en-IN', {minimumFractionDigits: 2});
                document.getElementById('emi_result_interest').innerText = '₹ ' + Number(data.total_interest).toLocaleString('en-IN', {minimumFractionDigits: 2});
            }
        })
        .catch(err => console.error("EMI Calculation Error:", err));
}
