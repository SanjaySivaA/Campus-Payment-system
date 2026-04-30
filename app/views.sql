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

