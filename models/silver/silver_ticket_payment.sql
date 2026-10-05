-- Тасалбар түвшний төлбөрийн нэгтгэл: 1 тасалбар олон хувааж төлөгдөж болно
with p as (
    select
        ticket_id,
        count(*)                                  as payment_count,
        count(distinct payment_type)              as payment_type_count,
        string_agg(distinct payment_type, ',' order by payment_type) as payment_types,
        sum(paid_amount)                          as payment_total,
        sum(paid_amount) filter (where is_settlement) as settled_total,
        min(paid_at)                              as first_paid_at,
        max(paid_at)                              as last_paid_at
    from {{ ref('silver_payment') }}
    group by ticket_id
)
select
    t.ticket_id,
    t.park_code,
    t.area_code,
    t.entered_date,
    t.net_due_amount,
    t.paid_amount                                        as ticket_paid_amount,
    coalesce(p.payment_count, 0)                         as payment_count,
    coalesce(p.payment_type_count, 0)                    as payment_type_count,
    p.payment_types,
    coalesce(p.payment_total, 0)                         as payment_total,
    coalesce(p.settled_total, 0)                         as settled_total,
    p.first_paid_at,
    p.last_paid_at,
    date_diff('minute', p.first_paid_at, p.last_paid_at) as payment_span_minutes,
    coalesce(p.payment_count, 0) > 1                     as is_split_payment,
    greatest(t.net_due_amount - coalesce(p.payment_total, 0), 0) as remaining_amount,
    case
        when t.net_due_amount = 0 and coalesce(p.payment_total, 0) = 0 then 'NO_CHARGE'
        when coalesce(p.payment_total, 0) = 0                          then 'UNPAID'
        when p.payment_total <  t.net_due_amount                       then 'PARTIAL'
        when p.payment_total =  t.net_due_amount                       then 'PAID'
        else 'OVERPAID'
    end                                                  as payment_status
from {{ ref('silver_ticket') }} t
left join p using (ticket_id)
