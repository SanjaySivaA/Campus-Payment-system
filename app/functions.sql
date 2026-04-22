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

--- query using the above function
select * from get_statement(1); 

