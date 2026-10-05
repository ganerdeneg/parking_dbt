-- ticket.paidAmount ↔ payment_history (хуваасан төлбөрүүдийн нийлбэр) тулгалт
select
    ticket_id,
    park_code,
    area_code,
    entered_date,
    ticket_paid_amount,
    payment_total,
    payment_count,
    is_split_payment,
    ticket_paid_amount - payment_total as difference,
    case
        when ticket_paid_amount = payment_total               then 'MATCHED'
        when payment_count = 0 and ticket_paid_amount > 0     then 'MISSING_PAYMENT'
        when ticket_paid_amount < payment_total               then 'PAYMENT_EXCEEDS_TICKET'
        else 'TICKET_EXCEEDS_PAYMENT'
    end                                as recon_status
from {{ ref('silver_ticket_payment') }}
where ticket_paid_amount > 0 or payment_count > 0
