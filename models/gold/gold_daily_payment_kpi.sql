-- Өдөр × зогсоол × бүс × төлбөрийн төрөл: бодит орж ирсэн мөнгө (paid_date-ээр)
select
    paid_date                                     as kpi_date,
    park_code,
    area_code,
    payment_type,
    count(*)                                      as transactions,
    count(distinct ticket_id)                     as tickets_paid,
    sum(paid_amount)                              as paid_amount,
    sum(parking_fee)                              as parking_fee,
    round(avg(paid_amount), 0)                    as avg_transaction_amount,
    sum(paid_amount) filter (where is_settlement)     as settled_amount,
    sum(paid_amount) filter (where not is_settlement) as unsettled_amount,
    round({{ safe_divide('sum(paid_amount) filter (where is_settlement)', 'sum(paid_amount)') }}, 4) as settlement_rate,
    count(*) filter (where is_organization)       as organization_receipts,
    count(distinct pos_device_id)                 as active_pos_devices,
    count(distinct cash_id)                       as cash_sessions
from {{ ref('silver_payment') }}
group by all
