-- Сар × зогсоол: нэгдсэн KPI + өмнөх сартай харьцуулсан өсөлт (MoM)
with m as (
    select
        date_trunc('month', kpi_date)::date as month,
        park_code,
        any_value(park_name)                as park_name,
        sum(tickets)                        as tickets,
        sum(unique_vehicles)                as vehicle_days,
        sum(gross_amount)                   as gross_amount,
        sum(discount_amount)                as discount_amount,
        sum(net_due_amount)                 as net_due_amount,
        sum(paid_amount)                    as paid_amount,
        sum(unpaid_amount)                  as unpaid_amount,
        sum(free_exit_tickets)              as free_exit_tickets
    from {{ ref('gold_daily_area_kpi') }}
    group by all
)
select
    *,
    round(paid_amount * 1.0 / nullif(net_due_amount, 0), 4)  as collection_rate,
    round(paid_amount * 1.0 / nullif(tickets, 0), 0)         as revenue_per_ticket,
    round((paid_amount - lag(paid_amount) over w) * 1.0 / nullif(lag(paid_amount) over w, 0), 4) as revenue_mom_growth,
    round((tickets - lag(tickets) over w) * 1.0 / nullif(lag(tickets) over w, 0), 4)             as tickets_mom_growth
from m
window w as (partition by park_code order by month)
