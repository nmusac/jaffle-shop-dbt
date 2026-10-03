    select
        ID as order_id,
        USER_ID as customer_id,
        order_date,
        status

    from `dbt-tutorial.jaffle_shop.orders`

