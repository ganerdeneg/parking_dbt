-- Кассчин × өдөр: гаргасан тасалбар, цуглуулсан мөнгө, үнэгүй гаргалт, гараар нээлт
select
    exited_date                                           as kpi_date,
    park_code,
    cashier,
    count(*)                                              as exited_tickets,
    sum(paid_amount)                                      as collected_amount,
    sum(discount_amount)                                  as discount_given,
    count(*) filter (where is_free_exit)                  as free_exits,
    count(*) filter (where is_manual_exit_open)           as manual_exit_opens,
    count(*) filter (where is_plate_changed)              as plate_changes,
    round({{ safe_divide('count(*) filter (where is_free_exit)', 'count(*)') }}, 4) as free_exit_rate
from {{ ref('silver_ticket') }}
where is_exited and cashier is not null
group by all
