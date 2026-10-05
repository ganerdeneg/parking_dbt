-- Машин (улсын дугаар) түвшний KPI: давтамж, зарцуулалт, өр, сегмент
{% set seg_days = var('vehicle_segment_days') %}
with t as (select * from {{ ref('silver_ticket') }} where number_plate is not null),
ref_date as (select max(entered_at) as as_of from t)

select
    t.number_plate,
    any_value(t.vehicle_type_name)                         as vehicle_type_name,
    count(*)                                               as total_visits,
    count(distinct t.park_code)                            as distinct_parks,
    min(t.entered_at)                                      as first_visit_at,
    max(t.entered_at)                                      as last_visit_at,
    count(*) filter (where t.entered_at >= r.as_of - to_days({{ seg_days }})) as visits_last_n_days,
    sum(t.paid_amount)                                     as total_paid,
    sum(t.unpaid_amount)                                   as total_unpaid,
    round(avg(t.parked_minutes), 1)                        as avg_parked_minutes,
    bool_or(t.is_contract)                                 as has_contract,
    case
        when count(*) filter (where t.entered_at >= r.as_of - to_days({{ seg_days }})) >= 10 then 'frequent'
        when count(*) filter (where t.entered_at >= r.as_of - to_days({{ seg_days }})) >= 3  then 'regular'
        when count(*) filter (where t.entered_at >= r.as_of - to_days({{ seg_days }})) >= 1  then 'occasional'
        else 'inactive'
    end                                                    as frequency_segment
from t
cross join ref_date r
group by t.number_plate
