    select
        ID as order_id,
        USER_ID as customer_id,
        order_date,
        status as order_status

    from {{ source('jaffle_shop', 'orders') }}

