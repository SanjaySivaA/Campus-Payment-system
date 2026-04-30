--- this query helps the student to get all her purchases above 500 rupees
--- this query makes use of the relation returned by the get_statement function
--- we cannot index on 'virtual' columns of the result set returned by a function

select *
from get_statement(1)
where amount > 500;


--- vendor uses this query to filter bills issued by her

select * 
from bill
where amount > 100 and vendor id = 1;

--- try more useful range based queries to introduce some btree indexes