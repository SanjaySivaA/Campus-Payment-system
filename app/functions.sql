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