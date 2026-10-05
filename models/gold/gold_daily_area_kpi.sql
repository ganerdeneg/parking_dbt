-- Өдөр × зогсоол × бүс: урсгал, хугацаа, орлого, хөнгөлөлт, үйл ажиллагааны KPI (entered_date-ээр)
with t as (
    select t.*, tp.payment_total, tp.payment_count, tp.is_split_payment, tp.payment_status, tp.remaining_amount
    from {{ ref('silver_ticket') }} t
    join {{ ref('silver_ticket_payment') }} tp using (ticket_id)
    where t.entered_at is not null
)

select
    t.entered_date                                         as kpi_date,
    t.park_code,
    t.area_code,
    d.park_name,
    d.area_name,

    -- Урсгал
    count(*)                                               as tickets,
    count(*) filter (where is_exited)                      as exited_tickets,
    count(*) filter (where not is_exited)                  as open_tickets,
    count(distinct number_plate)                           as unique_vehicles,

    -- Зогсох хугацаа
    round(avg(parked_minutes), 1)                          as avg_parked_minutes,
    quantile_cont(parked_minutes, 0.5)                     as median_parked_minutes,
    quantile_cont(parked_minutes, 0.9)                     as p90_parked_minutes,

    -- Орлого (тасалбарын түвшинд)
    sum(estimated_amount)                                  as gross_amount,
    sum(discount_amount)                                   as discount_amount,
    sum(subtracted_amount)                                 as subtracted_amount,
    sum(net_due_amount)                                    as net_due_amount,
    sum(paid_amount)                                       as paid_amount,          -- ticket.paidAmount
    sum(payment_total)                                     as payment_total,        -- payment_history нийлбэр (хуваасан төлбөр орно)
    sum(remaining_amount)                                  as remaining_amount,
    sum(unpaid_amount)                                     as unpaid_amount,
    sum(overpaid_amount)                                   as overpaid_amount,
    sum(kiosk_fee)                                         as kiosk_fee,
    round({{ safe_divide('sum(payment_total)', 'sum(net_due_amount)') }}, 4)      as collection_rate,
    round({{ safe_divide('sum(discount_amount)', 'sum(estimated_amount)') }}, 4)  as discount_rate,
    round({{ safe_divide('sum(payment_total)', 'count(*) filter (where payment_count > 0)') }}, 0) as avg_paid_per_ticket,

    -- Төрөл / бүрэлдэхүүн
    count(*) filter (where is_paid)                        as paid_tickets,
    count(*) filter (where payment_status = 'PAID')        as fully_paid_tickets,
    count(*) filter (where payment_status = 'PARTIAL')     as partial_paid_tickets,
    count(*) filter (where payment_status = 'UNPAID')      as unpaid_tickets,
    count(*) filter (where is_split_payment)               as split_payment_tickets,
    count(*) filter (where is_free_exit)                   as free_exit_tickets,
    count(*) filter (where is_contract)                    as contract_tickets,
    count(*) filter (where has_discount)                   as discounted_tickets,
    round({{ safe_divide('count(*) filter (where is_free_exit)', 'count(*)') }}, 4) as free_exit_rate,
    round({{ safe_divide('count(*) filter (where is_contract)', 'count(*)') }}, 4)  as contract_share,

    -- Үйл ажиллагаа / өгөгдлийн чанар
    count(*) filter (where is_manual_entry_open or is_manual_exit_open)            as manual_open_tickets,
    round({{ safe_divide('count(*) filter (where is_manual_entry_open or is_manual_exit_open)', 'count(*)') }}, 4) as manual_open_rate,
    count(*) filter (where is_plate_changed)               as plate_changed_tickets,
    round({{ safe_divide('count(*) filter (where is_plate_changed)', 'count(*)') }}, 4)     as plate_correction_rate,
    round({{ safe_divide('count(*) filter (where is_ai_plate_mismatch)', 'count(*) filter (where ai_recognized_plate is not null)') }}, 4) as ai_plate_mismatch_rate
from t
left join {{ ref('silver_park_area') }} d using (park_code, area_code)
group by all
