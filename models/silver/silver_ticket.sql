-- Silver: bronze.ticket (raw)-ээс цэвэрлэсэн, dedup хийсэн, бизнес талбартай тасалбар
with src as (
    select *,
        row_number() over (
            partition by id
            order by coalesce(exitedDate, enteredDate) desc nulls last
        ) as _rn
    from {{ source('bronze', 'ticket') }}
),

base as (
    select
        cast(id as integer)                        as ticket_id,
        trim(parkCode)                             as park_code,
        trim(parkName)                             as park_name,
        trim(areaCode)                             as area_code,
        trim(areaName)                             as area_name,
        {{ normalize_plate('numberPlate') }}       as number_plate,
        {{ normalize_plate('aiRecognizedPlate') }} as ai_recognized_plate,
        {{ normalize_plate('changedPlate') }}      as changed_plate,
        nullif(trim(vehicleTypeCode), '')          as vehicle_type_code,
        nullif(trim(vehicleTypeName), '')          as vehicle_type_name,
        nullif(trim(category), '')                 as category,
        nullif(trim(discountName), '')             as discount_name,
        nullif(trim(cashier), '')                  as cashier,
        nullif(trim(freeExited), '')               as free_exit_reason,

        cast(enteredDate as timestamp)     as entered_at,
        cast(arrivedDate as timestamp)     as arrived_at,
        cast(exitedDate as timestamp)      as exited_at,
        cast(paidDate as timestamp)        as paid_at,
        cast(lockedDate as timestamp)      as locked_at,
        cast(expiredDate as timestamp)     as expired_at,
        cast(changedDate as timestamp)     as plate_changed_at,
        enteredDeviceid as entered_device_id,
        exitedDeviceid  as exited_device_id,

        coalesce(cast(parkedMinute as bigint), 0)        as parked_minutes,
        coalesce(cast(estimatedAmount as bigint), 0)     as estimated_amount,
        coalesce(cast(discountAmount as bigint), 0)      as discount_amount,
        coalesce(cast(subtractedAmount as bigint), 0)    as subtracted_amount,
        coalesce(cast(paidAmount as bigint), 0)          as paid_amount,
        coalesce(cast(overPaid as bigint), 0)            as overpaid_amount,
        coalesce(cast(kioskFee as bigint), 0)            as kiosk_fee,
        coalesce(cast(parkingFee as bigint), 0)          as parking_fee,
        coalesce(cast(beforeUnpaidAmount as bigint), 0)  as before_unpaid_amount,

        nullif(trim(enteredOpenedby), '') is not null as is_manual_entry_open,
        nullif(trim(exitedOpenedby), '')  is not null as is_manual_exit_open,
        nullif(trim(contractIds), '')     is not null as is_contract,
        coalesce(cast(discountAssigned as integer), 0) = 1             as is_discount_assigned
    from src
    where _rn = 1
)

select
    *,
    cast(entered_at as date)                       as entered_date,
    cast(exited_at as date)                        as exited_date,
    hour(entered_at)                               as entered_hour,
    isodow(entered_at)                             as entered_dow,      -- 1=Даваа ... 7=Ням
    exited_at is not null                          as is_exited,
    paid_amount > 0                                as is_paid,
    coalesce(lower(free_exit_reason) not in ('0', 'false', 'no'), false) as is_free_exit,
    changed_plate is not null                      as is_plate_changed,
    coalesce(ai_recognized_plate <> number_plate, false) as is_ai_plate_mismatch,
    discount_amount > 0                            as has_discount,

    greatest(estimated_amount - discount_amount - subtracted_amount, 0)               as net_due_amount,
    greatest(estimated_amount - discount_amount - subtracted_amount - paid_amount, 0) as unpaid_amount,

    case
        when parked_minutes is null  then 'unknown'
        when parked_minutes < 15     then '00-15m'
        when parked_minutes < 60     then '15-60m'
        when parked_minutes < 180    then '1-3h'
        when parked_minutes < 480    then '3-8h'
        when parked_minutes < 1440   then '8-24h'
        else '24h+'
    end as duration_bucket
from base
