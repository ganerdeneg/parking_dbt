-- Өдөр × зогсоол × бүс: хувааж төлөлтийн KPI
select
    entered_date                                                   as kpi_date,
    park_code,
    area_code,
    count(*) filter (where payment_count > 0)                      as paid_tickets,
    count(*) filter (where is_split_payment)                       as split_tickets,
    round({{ safe_divide('count(*) filter (where is_split_payment)', 'count(*) filter (where payment_count > 0)') }}, 4) as split_ticket_rate,
    round(avg(payment_count) filter (where payment_count > 0), 2)  as avg_payments_per_ticket,
    max(payment_count)                                             as max_payments_per_ticket,
    round(avg(payment_span_minutes) filter (where is_split_payment), 1) as avg_split_span_minutes,
    count(*) filter (where payment_type_count > 1)                 as mixed_channel_tickets,
    count(*) filter (where payment_status = 'PARTIAL')             as partial_tickets,
    sum(remaining_amount) filter (where payment_status = 'PARTIAL') as partial_remaining_amount,
    count(*) filter (where payment_status = 'OVERPAID')            as overpaid_tickets
from {{ ref('silver_ticket_payment') }}
group by all
