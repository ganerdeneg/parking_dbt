-- Зогсоол / бүсийн dimension (хамгийн сүүлийн нэрийг авна)
select
    park_code,
    area_code,
    arg_max(park_name, entered_at) as park_name,
    arg_max(area_name, entered_at) as area_name,
    min(entered_at)                as first_seen_at,
    max(entered_at)                as last_seen_at
from {{ ref('silver_ticket') }}
group by park_code, area_code
