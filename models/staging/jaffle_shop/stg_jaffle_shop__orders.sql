    select
        ID as order_id,
        USER_ID as customer_id,
        order_date,
        status

    from {{ source('jaffle_shop', 'orders') }}

