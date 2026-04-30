--- this query helps the student to get all her purchases above 500 rupees
--- this query makes use of the relation returned by the get_statement function
--- we cannot index on 'virtual' columns of the result set returned by a function

select *
from get_statement(1)  -- this argument (student_id) is recieved from the request from the frontend
where amount > 500;


--- vendor uses this query to filter bills issued by her

select * 
from bill
where amount > 100 and vendor id = 1;

-- some useful indexes
CREATE INDEX idx_bill_student_id ON bill USING btree (student_id);
create index idx_bill_total_amount on bill using btree(total_amount);


-- force the planner to use an index
-- SET enable_seqscan = OFF; 

EXPLAIN ANALYZE
SELECT * FROM student
WHERE student_id = 3;

-- enable seq. scan
-- SET enable_seqscan = ON;

--- try more useful range based queries to introduce some btree indexes
--- those indexes also can be added here

-- Update the tables to ensure they can hold the bcrypt hashes
ALTER TABLE Student ALTER COLUMN password_hash TYPE VARCHAR(255);
ALTER TABLE Vendor ALTER COLUMN password_hash TYPE VARCHAR(255);
ALTER TABLE Admin ALTER COLUMN password_hash TYPE VARCHAR(255);
