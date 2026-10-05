-- Сар × зогсоол: төлбөрийн сувгийн эзлэх хувь (share)
with m as (
    select
        date_trunc('month', paid_date)::date as month,
        park_code,
        payment_type,
        count(*)         as transactions,
        sum(paid_amount) as paid_amount
    from {{ ref('silver_payment') }}
    group by all
)
select
    *,
    round(paid_amount * 1.0 / nullif(sum(paid_amount) over (partition by month, park_code), 0), 4)   as amount_share,
    round(transactions * 1.0 / nullif(sum(transactions) over (partition by month, park_code), 0), 4) as txn_share
from m
