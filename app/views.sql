--- this view is for the admin to see all requests which are not yet settled
create or replace view unsettled_requests as
select *
from settlement
where status = 'requested';

--- sample query to use the above view
select * from unsettled_requests;


--- view for any role to see the inventory
create or replace view my_inventory as 
select * 
from inventory;

select * from my_inventory;

--- students know how much they have left to spend
create or replace view active_student_limits as
select 
    student_id,
    first_name || ' ' || last_name as student_name,
    balance as current_wallet_balance,
    spending_limit as remaining_spending_limit
from student;

select * from active_student_limits where student_id = 1;


--- aggregates bills of the vendor for the current date
create or replace view vendor_daily_sales as
select 
    v.vendor_id,
    v.name as shop_name,
    count(b.bill_id) as total_transactions_today,
    coalesce(sum(b.total_amount), 0) as daily_revenue
from vendor v
left join bill b 
    on v.vendor_id = b.vendor_id 
    and b.date = current_date
    and b.status = 'completed'
group by v.vendor_id, v.name;

select * from vendor_daily_sales where vendor_id = 4;
