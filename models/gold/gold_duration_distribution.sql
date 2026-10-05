-- Сар × зогсоол × бүс × хугацааны интервал
with agg as (
    select
        date_trunc('month', entered_date)::date as month,
        park_code,
        area_code,
        duration_bucket,
        count(*)                   as tickets,
        sum(paid_amount)           as paid_amount,
        round(avg(paid_amount), 0) as avg_paid_amount
    from {{ ref('silver_ticket') }}
    where entered_at is not null
    group by all
)
select
    *,
    round(tickets * 1.0 / sum(tickets) over (partition by month, park_code, area_code), 4) as ticket_share
from agg
