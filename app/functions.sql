-- 1. Requesting Settlement (Vendor) 

CREATE OR REPLACE FUNCTION request_settlement(p_vendor_id VARCHAR)
RETURNS INT AS $$
DECLARE
    v_total_amount FLOAT;
    v_new_settlement_id INT;
BEGIN
    -- 1. Calculate the total of all unsettled bills for this vendor
    SELECT COALESCE(SUM(total_amount), 0) INTO v_total_amount
    FROM Bill
    WHERE vendor_id = p_vendor_id AND settlement_id IS NULL;

    -- 2. Guard clause: Prevent empty settlements
    IF v_total_amount = 0 THEN
        RAISE EXCEPTION 'No unsettled bills found for this vendor.';
    END IF;

    -- 3. Create the settlement record
    -- Note: admin_id is left NULL here since it hasn't been processed by an admin yet
    INSERT INTO Settlement (vendor_id, status, amount, date)
    VALUES (p_vendor_id, 'PENDING', v_total_amount, CURRENT_DATE)
    RETURNING settlement_id INTO v_new_settlement_id;

    RETURN v_new_settlement_id;
    
    -- The trigger will automatically fire here to update the Bill table!
END;
$$ LANGUAGE plpgsql;


-- Associated trigger

-- Step A: Define the logic that executes when the trigger fires
CREATE OR REPLACE FUNCTION update_bills_after_settlement()
RETURNS TRIGGER AS $$
BEGIN
    -- NEW is a special record containing the newly inserted row's data
    UPDATE Bill
    SET settlement_id = NEW.settlement_id
    WHERE vendor_id = NEW.vendor_id AND settlement_id IS NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step B: Bind the function to the Settlement table
CREATE TRIGGER trigger_settlement_insert
AFTER INSERT ON Settlement
FOR EACH ROW
EXECUTE FUNCTION update_bills_after_settlement();


-------------------------------------------------------------------------------------------------------

--- function to get the purchase history of the student given his student_id
create function get_statement(p_student_id INT)
returns table (bill_id int, date date, vendor_id int, vendor_name varchar(50), amount numeric)
as $$
begin
	return query
	select b.bill_id , b.date, v.vendor_id, v.name as vendor_name, b.total_amount
	from bill b
	join vendor v using (vendor_id)
	where b.student_id = p_student_id;
end;
$$ language plpgsql;

--- sample query using the above function
select * from get_statement(1); 

--------------------------------------------------------------------------------------------------

-- function to compare the prices of a given item across different vendors
create function compare_prices(p_item_id int)
returns table (vendor_id int, vendor_name varchar(50), cost numeric, in_stock bool, last_updated timestamp without time zone)
as $$
begin
	return query
	select i.vendor_id, v.name as vendor_name, i.cost, i.in_stock bool, i.last_update_time
	from inventory i
	join vendor v using (vendor_id)
	where i.item_id = p_item_id;
end;
$$ language plpgsql;

-- sample query using the above function
select * from compare_prices(50);

--------------------------------------------------------------------------------------------------

-- function to approve settlements
CREATE OR REPLACE FUNCTION approve_settlement(p_settlement_id INT, p_admin_id INT)
RETURNS VOID AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    -- Check if the settlement exists and get its current status
    SELECT status INTO v_current_status 
    FROM Settlement 
    WHERE settlement_id = p_settlement_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Settlement ID % does not exist.', p_settlement_id;
    ELSIF v_current_status = 'paid' THEN
        RAISE EXCEPTION 'Settlement ID % has already been paid.', p_settlement_id;
    END IF;

    -- Dummy API Call to Bank
    RAISE NOTICE 'Initiating transfer for Settlement ID %...', p_settlement_id;
    PERFORM pg_sleep(1.5); -- Simulates network delay for the bank API
    RAISE NOTICE 'Bank transfer successful.';

    -- Update the settlement status and assign the admin
    UPDATE Settlement
    SET status = 'paid',
        admin_id = p_admin_id
    WHERE settlement_id = p_settlement_id;

END;
$$ LANGUAGE plpgsql;

-- Sample query to use the function:
select approve_settlement(3, 1);

--------------------------------------------------------------------------------------------------

-- function to update student's bank balance
CREATE OR REPLACE FUNCTION trigger_update_student_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Deduct the bill's total amount from the student's balance
    UPDATE Student
    SET balance = balance - NEW.total_amount
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Bind the trigger to the Bill table
CREATE TRIGGER after_bill_insert
AFTER INSERT ON Bill
FOR EACH ROW
EXECUTE FUNCTION trigger_update_student_balance();
