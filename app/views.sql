--- this view is for the admin to see all requests which are not yet settled
create view unsettled_requests as
select *
from settlement
where status = 'requested';

--- sample query to use the above view
select * from unsettled_requests;

