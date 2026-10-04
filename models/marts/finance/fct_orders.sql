with 

orders as ( 

    select * from {{ ref('stg_jaffle_shop__orders') }}

),


    payments as (

  select order_id,sum(case when status = 'success' then amount end) as amount
  
  from {{ ref('stg_stripe__payments') }}

  group by 1

    ),

    final as (

select customer_id,a.order_id , amount

from orders a

left join payments b on a.order_id=b.order_id

    )

    select *
    from final












