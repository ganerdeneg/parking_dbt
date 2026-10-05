-- Цаг бүрт зогсоолд байсан машины тоо (occupancy). Гараагүй тасалбарыг var-аар хязгаарлана.
{% set max_h = var('open_ticket_max_hours') %}
with spans as (
    select
        park_code,
        area_code,
        ticket_id,
        date_trunc('hour', entered_at) as from_hour,
        date_trunc('hour', coalesce(exited_at, least(entered_at + to_hours({{ max_h }}), current_timestamp::timestamp))) as to_hour
    from {{ ref('silver_ticket') }}
    where entered_at is not null
),
expanded as (
    select park_code, area_code, ticket_id,
           unnest(generate_series(from_hour, to_hour, interval 1 hour)) as ts_hour
    from spans
    where to_hour >= from_hour
),
agg as (
    select
        ts_hour,
        cast(ts_hour as date)     as kpi_date,
        hour(ts_hour)             as hour_of_day,
        park_code,
        area_code,
        count(distinct ticket_id) as vehicles_present
    from expanded
    group by all
)
select
    *,
    max(vehicles_present) over (partition by park_code, area_code, kpi_date) as daily_peak_occupancy
from agg
