-- Гараг × цаг: дундаж орох урсгал → оргил цаг тодорхойлох
with hourly as (
    select park_code, area_code, entered_date, entered_dow, entered_hour, count(*) as entries
    from {{ ref('silver_ticket') }}
    where entered_at is not null
    group by all
),
agg as (
    select
        park_code,
        area_code,
        entered_dow                    as day_of_week,     -- 1=Даваа ... 7=Ням
        entered_hour                   as hour_of_day,
        count(distinct entered_date)   as observed_days,
        sum(entries)                   as total_entries,
        round(avg(entries), 2)         as avg_entries,
        max(entries)                   as max_entries
    from hourly
    group by all
)
select
    *,
    rank() over (partition by park_code, area_code, day_of_week order by avg_entries desc) as hour_rank_in_day
from agg
