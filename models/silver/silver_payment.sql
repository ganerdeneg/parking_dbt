-- Silver: bronze.payment_history (raw)-ээс dedup (requestId, paymentType) + тасалбартай баяжуулсан төлбөр
with src as (
    select *,
        row_number() over (
            partition by requestId, paymentType
            order by updatedDate desc, id desc
        ) as _rn
    from {{ source('bronze', 'payment_history') }}
)

select
    cast(p.id as integer)                       as payment_id,
    p.requestId                                 as request_id,
    upper(trim(p.paymentType))                  as payment_type,
    coalesce(cast(p.paidAmount as bigint), 0)   as paid_amount,
    coalesce(cast(p.parkingFee as bigint), 0)   as parking_fee,
    cast(p.paidDate as timestamp)               as paid_at,
    cast(p.paidDate as date)                    as paid_date,
    hour(cast(p.paidDate as timestamp))         as paid_hour,
    p.cashId                                    as cash_id,
    cast(p.ticketId as integer)                 as ticket_id,
    p.posDeviceId                               as pos_device_id,
    nullif(trim(p.customerTin), '')             as customer_tin,
    nullif(trim(p.customerTin), '') is not null as is_organization,  -- ТТД-тэй (байгууллагын) баримт
    coalesce(cast(p.isSettlement as integer), 0) = 1             as is_settlement,
    t.park_code,
    coalesce(nullif(trim(p.areaCode), ''), t.area_code) as area_code,
    t.number_plate,
    p.createdBy                                 as created_by,
    p.createdDate                               as created_at,
    p.updatedDate                               as updated_at
from src p
left join {{ ref('silver_ticket') }} t on t.ticket_id = cast(p.ticketId as integer)
where p._rn = 1
