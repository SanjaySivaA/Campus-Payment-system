--
-- PostgreSQL database dump
--

\restrict fX3m2M0PvPyMgseJBG7oZUnT00I32r6hhDUeqhAbkIeep1lSSoJnkrYJtdKlKJH

-- Dumped from database version 14.22 (Ubuntu 14.22-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.22 (Ubuntu 14.22-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: approve_settlement(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.approve_settlement(p_settlement_id integer, p_admin_id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_current_status VARCHAR;
BEGIN
    -- Authorization Check: Ensure the database user is the admin_role
    -- Alternatively, you can verify if the provided p_admin_id exists in the Admin table
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = p_admin_id) THEN
        RAISE EXCEPTION 'Unauthorized: Invalid Admin ID (%).', p_admin_id;
    END IF;

    -- 1. Check if the settlement exists and get its current status
    SELECT status INTO v_current_status 
    FROM Settlement 
    WHERE settlement_id = p_settlement_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Settlement ID % does not exist.', p_settlement_id;
    ELSIF v_current_status = 'paid' THEN
        RAISE EXCEPTION 'Settlement ID % has already been paid.', p_settlement_id;
    END IF;

    -- 2. Dummy API Call to Bank
    RAISE NOTICE 'Initiating transfer for Settlement ID %...', p_settlement_id;
    PERFORM pg_sleep(1.5); -- Simulates network delay for the bank API
    RAISE NOTICE 'Bank transfer successful.';

    -- 3. Update the settlement status and assign the admin
    UPDATE Settlement
    SET status = 'paid',
        admin_id = p_admin_id
    WHERE settlement_id = p_settlement_id;

END;
$$;


ALTER FUNCTION public.approve_settlement(p_settlement_id integer, p_admin_id integer) OWNER TO postgres;

--
-- Name: compare_prices(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.compare_prices(p_item_id integer) RETURNS TABLE(vendor_id integer, vendor_name character varying, cost numeric, in_stock boolean, last_updated timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
	return query
	select i.vendor_id, v.name as vendor_name, i.cost, i.in_stock bool, i.last_update_time
	from inventory i
	join vendor v using (vendor_id)
	where i.item_id = p_item_id;
end;
$$;


ALTER FUNCTION public.compare_prices(p_item_id integer) OWNER TO postgres;

--
-- Name: deduct_spending_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.deduct_spending_limit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Deduct the bill amount directly from the student's spending_limit attribute
    UPDATE Student
    SET spending_limit = spending_limit - NEW.total_amount
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.deduct_spending_limit() OWNER TO postgres;

--
-- Name: get_statement(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_statement(p_student_id integer) RETURNS TABLE(bill_id integer, date date, vendor_id integer, vendor_name character varying, amount numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
	return query
	select b.bill_id , b.date, v.vendor_id, v.name as vendor_name, b.total_amount
	from bill b
	join vendor v using (vendor_id)
	where b.student_id = p_student_id;
end;
$$;


ALTER FUNCTION public.get_statement(p_student_id integer) OWNER TO postgres;

--
-- Name: issue_bill(integer, integer, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.issue_bill(p_student_id integer, p_vendor_id integer, p_total_amount numeric) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_current_balance NUMERIC;
    v_spending_limit NUMERIC;
    v_new_bill_id INT;
BEGIN
    -- Authorization Check: Ensure a valid vendor is issuing this
    IF NOT EXISTS (SELECT 1 FROM Vendor WHERE vendor_id = p_vendor_id) THEN
         RAISE EXCEPTION 'Unauthorized: Invalid Vendor ID (%).', p_vendor_id;
    END IF;

    -- 1. Get the student's balance and spending limit
    -- Assuming spending_limit was added via: ALTER TABLE Student ADD COLUMN spending_limit NUMERIC DEFAULT 5000.00;
    SELECT balance, spending_limit INTO v_current_balance, v_spending_limit
    FROM Student 
    WHERE student_id = p_student_id;

    IF v_current_balance IS NULL THEN
        RAISE EXCEPTION 'Student ID % not found.', p_student_id;
    END IF;

    -- 2. Apply the Business Rules
    -- Rule A: Check Spending Limit
    IF p_total_amount > v_spending_limit THEN
         RAISE EXCEPTION 'Transaction Denied: Bill amount (%) exceeds the student''s spending limit (%).', p_total_amount, v_spending_limit;
    END IF;

    -- Rule B: Check Actual Balance
    IF v_current_balance < p_total_amount THEN
        RAISE EXCEPTION 'Insufficient funds. Student balance is %, but bill is %.', v_current_balance, p_total_amount;
    END IF;

    -- 3. Insert the new bill 
    INSERT INTO Bill (student_id, vendor_id, total_amount, date, status)
    VALUES (p_student_id, p_vendor_id, p_total_amount, CURRENT_DATE, 'completed')
    RETURNING bill_id INTO v_new_bill_id;

    -- (The trigger we wrote earlier 'after_bill_insert' will automatically deduct the balance here)

    RETURN v_new_bill_id;
END;
$$;


ALTER FUNCTION public.issue_bill(p_student_id integer, p_vendor_id integer, p_total_amount numeric) OWNER TO postgres;

--
-- Name: process_student_recharge(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.process_student_recharge() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Add the recharge amount to the student's active balance
    UPDATE Student
    SET balance = balance + NEW.amount
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.process_student_recharge() OWNER TO postgres;

--
-- Name: request_settlement(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.request_settlement(p_vendor_id integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
    INSERT INTO Settlement (vendor_id, admin_id,status, amount, date)
    VALUES (p_vendor_id, 1,'requested', v_total_amount, CURRENT_DATE)
    RETURNING settlement_id INTO v_new_settlement_id;

    RETURN v_new_settlement_id;
    
    -- The trigger will automatically fire here to update the Bill table!
END;
$$;


ALTER FUNCTION public.request_settlement(p_vendor_id integer) OWNER TO postgres;

--
-- Name: request_settlement(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.request_settlement(p_vendor_id character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.request_settlement(p_vendor_id character varying) OWNER TO postgres;

--
-- Name: set_spending_limit(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_spending_limit(p_student_id integer, p_spending_limit integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

BEGIN
    UPDATE student
    SET spending_limit = p_spending_limit
    WHERE student_id = p_student_id;
END;

$$;


ALTER FUNCTION public.set_spending_limit(p_student_id integer, p_spending_limit integer) OWNER TO postgres;

--
-- Name: trigger_update_student_balance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_update_student_balance() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Deduct the bill's total amount from the student's balance
    UPDATE Student
    SET balance = balance - NEW.total_amount
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_update_student_balance() OWNER TO postgres;

--
-- Name: update_bills_after_settlement(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_bills_after_settlement() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- NEW is a special record containing the newly inserted row's data
    UPDATE Bill
    SET settlement_id = NEW.settlement_id
    WHERE vendor_id = NEW.vendor_id AND settlement_id IS NULL;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_bills_after_settlement() OWNER TO postgres;

--
-- Name: update_vendor_inventory(integer, integer, numeric, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_vendor_inventory(p_vendor_id integer, p_item_id integer, p_new_cost numeric, p_in_stock boolean) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    rows_affected INT;
BEGIN
    -- 1. Try to update the existing inventory row
    UPDATE inventory
    SET 
        cost = p_new_cost,
        in_stock = p_in_stock,
        last_update_time = CURRENT_TIMESTAMP
    WHERE vendor_id = p_vendor_id 
      AND item_id = p_item_id;

    -- 2. Check if the update actually modified any rows
    GET DIAGNOSTICS rows_affected = ROW_COUNT;

    -- 3. If no rows were updated, it means the item isn't in their inventory yet
    IF rows_affected = 0 THEN
        INSERT INTO inventory (vendor_id, item_id, cost, in_stock, last_update_time)
        VALUES (p_vendor_id, p_item_id, p_new_cost, p_in_stock, CURRENT_TIMESTAMP);
        
        RETURN 'Success: New item added to inventory.';
    ELSE
        RETURN 'Success: Inventory updated.';
    END IF;
END;
$$;


ALTER FUNCTION public.update_vendor_inventory(p_vendor_id integer, p_item_id integer, p_new_cost numeric, p_in_stock boolean) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    student_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(50),
    phone character varying(15),
    balance numeric(10,2) DEFAULT 0,
    password_hash character varying(255),
    spending_limit numeric(10,2),
    CONSTRAINT student_balance_check CHECK ((balance >= (0)::numeric))
);


ALTER TABLE public.student OWNER TO postgres;

--
-- Name: active_student_limits; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_student_limits AS
 SELECT student.student_id,
    (((student.first_name)::text || ' '::text) || (student.last_name)::text) AS student_name,
    student.balance AS current_wallet_balance,
    student.spending_limit AS remaining_spending_limit
   FROM public.student;


ALTER TABLE public.active_student_limits OWNER TO postgres;

--
-- Name: admin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin (
    admin_id integer NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    password_hash character varying(255)
);


ALTER TABLE public.admin OWNER TO postgres;

--
-- Name: bank_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bank_account (
    bankaccount_id integer NOT NULL,
    bank_name character varying(50),
    account_number character varying(50),
    ifsc_code character varying(50)
);


ALTER TABLE public.bank_account OWNER TO postgres;

--
-- Name: bill_bill_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bill_bill_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bill_bill_id_seq OWNER TO postgres;

--
-- Name: bill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bill (
    bill_id integer DEFAULT nextval('public.bill_bill_id_seq'::regclass) NOT NULL,
    student_id integer NOT NULL,
    vendor_id integer NOT NULL,
    settlement_id integer,
    total_amount numeric(10,2) NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(20) NOT NULL,
    CONSTRAINT bill_status_check CHECK (((status)::text = ANY ((ARRAY['completed'::character varying, 'refund'::character varying])::text[]))),
    CONSTRAINT bill_total_amount_check CHECK ((total_amount > (0)::numeric))
);


ALTER TABLE public.bill OWNER TO postgres;

--
-- Name: bill_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bill_item (
    bill_id integer NOT NULL,
    item_id integer NOT NULL,
    quantity integer NOT NULL,
    selling_price numeric(10,2) NOT NULL,
    CONSTRAINT bill_item_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.bill_item OWNER TO postgres;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory (
    inventory_id integer NOT NULL,
    item_id integer NOT NULL,
    vendor_id integer NOT NULL,
    cost numeric(10,2) NOT NULL,
    in_stock boolean DEFAULT true,
    last_update_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT inventory_cost_check CHECK ((cost >= (0)::numeric))
);


ALTER TABLE public.inventory OWNER TO postgres;

--
-- Name: inventory_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.inventory ALTER COLUMN inventory_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.inventory_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item (
    item_id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.item OWNER TO postgres;

--
-- Name: my_inventory; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.my_inventory AS
 SELECT inventory.inventory_id,
    inventory.item_id,
    inventory.vendor_id,
    inventory.cost,
    inventory.in_stock,
    inventory.last_update_time
   FROM public.inventory;


ALTER TABLE public.my_inventory OWNER TO postgres;

--
-- Name: recharge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recharge (
    recharge_id integer NOT NULL,
    student_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT recharge_amount_check CHECK ((amount > (0)::numeric))
);


ALTER TABLE public.recharge OWNER TO postgres;

--
-- Name: recharge_recharge_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.recharge ALTER COLUMN recharge_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.recharge_recharge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: settlement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settlement (
    settlement_id integer NOT NULL,
    vendor_id integer NOT NULL,
    admin_id integer NOT NULL,
    status character varying(20) NOT NULL,
    amount numeric(12,2) NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT settlement_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT settlement_status_check CHECK (((status)::text = ANY ((ARRAY['requested'::character varying, 'paid'::character varying])::text[])))
);


ALTER TABLE public.settlement OWNER TO postgres;

--
-- Name: settlement_settlement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.settlement ALTER COLUMN settlement_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.settlement_settlement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: student_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_account (
    bankaccount_id integer NOT NULL,
    student_id integer NOT NULL
);


ALTER TABLE public.student_account OWNER TO postgres;

--
-- Name: unsettled_requests; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.unsettled_requests AS
 SELECT settlement.settlement_id,
    settlement.vendor_id,
    settlement.admin_id,
    settlement.status,
    settlement.amount,
    settlement.date
   FROM public.settlement
  WHERE ((settlement.status)::text = 'requested'::text);


ALTER TABLE public.unsettled_requests OWNER TO postgres;

--
-- Name: vendor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor (
    vendor_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(20),
    password_hash character varying(255) NOT NULL
);


ALTER TABLE public.vendor OWNER TO postgres;

--
-- Name: vendor_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor_account (
    bankaccount_id integer NOT NULL,
    vendor_id integer NOT NULL
);


ALTER TABLE public.vendor_account OWNER TO postgres;

--
-- Name: vendor_daily_sales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vendor_daily_sales AS
 SELECT v.vendor_id,
    v.name AS shop_name,
    count(b.bill_id) AS total_transactions_today,
    COALESCE(sum(b.total_amount), (0)::numeric) AS daily_revenue
   FROM (public.vendor v
     LEFT JOIN public.bill b ON (((v.vendor_id = b.vendor_id) AND (b.date = CURRENT_DATE) AND ((b.status)::text = 'completed'::text))))
  GROUP BY v.vendor_id, v.name;


ALTER TABLE public.vendor_daily_sales OWNER TO postgres;

--
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin (admin_id, first_name, last_name, password_hash) FROM stdin;
1	Rahul	Desai	e99a18c428cb38d5f260853678922e03
2	Priya	Menon	87d9bb400c0634691f0e3baaf1e2fd0d
3	Amit	Singhania	a3f0f7ee1b82e2e7b85ccb6b7a5a3a41
4	Neha	Reddy	c4ca4238a0b923820dcc509a6f75849b
5	Vikram	Malhotra	c81e728d9d4c2f636f067f89cc14862c
\.


--
-- Data for Name: bank_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bank_account (bankaccount_id, bank_name, account_number, ifsc_code) FROM stdin;
1	Punjab National Bank	777105802166	PUNB0869603
2	Punjab National Bank	315692151496663	PUNB0802314
3	State Bank of India	11207238756	SBIN0483370
4	ICICI Bank	25877679859	ICIC0164716
5	ICICI Bank	7835936307829964	ICIC0252593
6	Punjab National Bank	34735607306	PUNB0600194
7	Axis Bank	8295754563898	UTIB0118608
8	Axis Bank	8375867201719	UTIB0516714
9	Kotak Mahindra Bank	825774068385984	KKBK0106469
10	Bank of Baroda	60683425052	BARB0388905
11	ICICI Bank	0265674309274	ICIC0652089
12	HDFC Bank	51499794438091	HDFC0905554
13	State Bank of India	1531577919	SBIN0537296
14	State Bank of India	8957991434773547	SBIN0801388
15	Canara Bank	9228678177	CNRB0724652
16	Axis Bank	172895140757	UTIB0498709
17	State Bank of India	89832363575	SBIN0135148
18	Axis Bank	9785458465874831	UTIB0714324
19	Kotak Mahindra Bank	0302872899	KKBK0649110
20	Punjab National Bank	71172431949	PUNB0619288
21	ICICI Bank	468037089918601	ICIC0008408
22	Union Bank of India	79282575897540	UBIN0189602
23	State Bank of India	8851522882220993	SBIN0771575
24	State Bank of India	631830864866518	SBIN0220593
25	Kotak Mahindra Bank	95047839863	KKBK0473309
26	Canara Bank	27209380056	CNRB0175599
27	Kotak Mahindra Bank	8900481016636298	KKBK0996368
28	Bank of Baroda	70703845172	BARB0384466
29	Punjab National Bank	11224436415546	PUNB0509217
30	HDFC Bank	865579999003	HDFC0550621
31	State Bank of India	17505200396	SBIN0508035
32	Punjab National Bank	214345497515766	PUNB0714555
33	ICICI Bank	3806052096	ICIC0982470
34	Canara Bank	6517437249	CNRB0223453
35	Punjab National Bank	5319093346	PUNB0750859
36	Canara Bank	906491051276335	CNRB0494912
37	Union Bank of India	56329001567393	UBIN0315904
38	Punjab National Bank	2431809371	PUNB0390843
39	Axis Bank	267242726484	UTIB0073616
40	Union Bank of India	06645899651728	UBIN0135052
41	IndusInd Bank	52773859565	INDB0512367
42	HDFC Bank	1555033560315	HDFC0073916
43	Kotak Mahindra Bank	898673125037	KKBK0997513
44	Union Bank of India	035207955361	UBIN0111550
45	Union Bank of India	74489499389647	UBIN0939229
46	State Bank of India	407525864838166	SBIN0335506
47	Union Bank of India	3455810008	UBIN0981174
48	State Bank of India	783383789538615	SBIN0950288
49	HDFC Bank	88049677444582	HDFC0188970
50	Kotak Mahindra Bank	2039544184557	KKBK0102081
\.


--
-- Data for Name: bill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bill (bill_id, student_id, vendor_id, settlement_id, total_amount, date, status) FROM stdin;
13	25	60	27	1200.44	2026-02-13	completed
1	16	60	27	459.12	2026-02-14	completed
21	17	60	27	74.58	2026-02-20	completed
35	21	60	27	490.16	2026-02-12	completed
41	60	60	27	150.50	2026-05-02	completed
42	60	60	27	150.50	2026-05-08	completed
43	60	60	27	150.50	2026-05-08	completed
9	29	60	27	1696.87	2026-02-10	completed
10	3	60	27	703.25	2026-03-09	completed
12	2	60	27	1541.20	2026-03-11	completed
14	13	60	27	353.66	2026-03-09	completed
22	23	60	27	2251.17	2026-03-05	completed
30	27	60	27	1849.95	2026-03-09	completed
33	24	60	27	336.39	2026-02-24	completed
34	7	60	27	1230.60	2026-03-09	completed
36	10	60	27	1295.08	2026-02-16	completed
38	16	60	27	85.78	2026-03-01	completed
2	14	6	11	1975.97	2026-02-24	completed
3	10	2	11	754.15	2026-02-19	completed
4	3	3	13	342.80	2026-03-08	completed
5	19	9	17	56.00	2026-03-01	completed
6	9	8	16	2356.03	2026-02-22	completed
40	9	60	27	458.78	2026-02-19	completed
8	27	2	16	490.07	2026-03-11	completed
37	60	60	27	1493.10	2026-03-02	completed
44	60	60	27	150.50	2026-05-08	completed
11	10	8	18	92.89	2026-02-23	completed
45	60	60	27	150.50	2026-05-08	completed
46	1	60	27	150.50	2026-05-08	completed
47	1	60	27	150.50	2026-05-08	completed
15	7	7	15	1779.09	2026-02-27	completed
16	30	8	17	460.51	2026-02-20	completed
17	23	7	4	1246.82	2026-02-28	completed
48	1	60	27	150.50	2026-05-08	completed
19	13	1	19	324.91	2026-02-15	completed
20	3	9	19	562.86	2026-02-12	completed
49	60	60	\N	100.00	2026-05-08	completed
50	1	4	\N	150.50	2026-05-08	completed
23	16	2	6	404.84	2026-03-06	completed
24	30	3	10	471.29	2026-03-10	completed
25	10	7	14	878.84	2026-02-10	completed
26	8	10	19	653.61	2026-03-05	completed
28	13	1	3	454.86	2026-02-25	completed
29	23	6	16	115.59	2026-02-23	completed
31	11	9	13	585.78	2026-03-02	completed
32	13	2	7	1550.86	2026-02-16	completed
39	14	5	18	1776.27	2026-03-10	completed
7	60	10	13	2361.34	2026-02-27	completed
18	60	9	15	747.24	2026-03-08	completed
27	14	1	24	441.54	2026-03-06	completed
\.


--
-- Data for Name: bill_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bill_item (bill_id, item_id, quantity, selling_price) FROM stdin;
\.


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory (inventory_id, item_id, vendor_id, cost, in_stock, last_update_time) FROM stdin;
1	50	6	284.00	t	2026-03-12 01:32:42
2	9	6	58.00	f	2026-03-12 01:32:42
3	42	9	152.00	t	2026-03-12 01:32:42
4	11	9	108.00	t	2026-03-12 01:32:42
5	19	7	82.00	t	2026-03-12 01:32:42
6	17	6	135.00	t	2026-03-12 01:32:42
7	5	8	89.00	t	2026-03-12 01:32:42
8	26	9	47.00	t	2026-03-12 01:32:42
9	32	3	34.00	t	2026-03-12 01:32:42
10	28	2	16.00	t	2026-03-12 01:32:42
11	44	4	226.00	f	2026-03-12 01:32:42
12	25	5	53.00	t	2026-03-12 01:32:42
13	32	3	232.00	t	2026-03-12 01:32:42
14	40	3	499.00	f	2026-03-12 01:32:42
15	2	8	46.00	t	2026-03-12 01:32:42
16	36	4	444.00	t	2026-03-12 01:32:42
17	21	10	121.00	t	2026-03-12 01:32:42
18	5	5	61.00	t	2026-03-12 01:32:42
19	25	8	143.00	t	2026-03-12 01:32:42
20	6	2	68.00	t	2026-03-12 01:32:42
21	48	4	470.00	t	2026-03-12 01:32:42
22	9	10	26.00	f	2026-03-12 01:32:42
23	28	8	12.00	t	2026-03-12 01:32:42
24	28	10	4.00	t	2026-03-12 01:32:42
25	35	7	408.00	t	2026-03-12 01:32:42
26	49	7	359.00	f	2026-03-12 01:32:42
27	41	1	310.00	t	2026-03-12 01:32:42
28	29	6	11.00	t	2026-03-12 01:32:42
29	15	9	144.00	t	2026-03-12 01:32:42
30	34	2	205.00	t	2026-03-12 01:32:42
31	25	9	44.00	t	2026-03-12 01:32:42
32	16	3	70.00	t	2026-03-12 01:32:42
33	21	3	52.00	t	2026-03-12 01:32:42
34	19	7	129.00	t	2026-03-12 01:32:42
35	42	2	445.00	t	2026-03-12 01:32:42
36	25	5	86.00	t	2026-03-12 01:32:42
37	15	8	38.00	t	2026-03-12 01:32:42
38	31	3	65.00	t	2026-03-12 01:32:42
39	27	1	21.00	t	2026-03-12 01:32:42
40	46	6	275.00	t	2026-03-12 01:32:42
41	43	7	149.00	t	2026-03-12 01:32:42
42	26	8	24.00	t	2026-03-12 01:32:42
43	45	8	261.00	t	2026-03-12 01:32:42
44	18	10	32.00	f	2026-03-12 01:32:42
45	31	1	190.00	t	2026-03-12 01:32:42
46	46	3	48.00	f	2026-03-12 01:32:42
47	37	3	193.00	f	2026-03-12 01:32:42
48	16	5	87.00	t	2026-03-12 01:32:42
49	17	3	67.00	t	2026-03-12 01:32:42
50	14	9	94.00	t	2026-03-12 01:32:42
51	15	7	39.00	f	2026-03-12 01:32:42
52	3	8	26.00	t	2026-03-12 01:32:42
53	17	6	68.00	t	2026-03-12 01:32:42
54	14	10	21.00	t	2026-03-12 01:32:42
55	50	1	197.00	t	2026-03-12 01:32:42
56	15	4	134.00	t	2026-03-12 01:32:42
57	26	10	6.00	f	2026-03-12 01:32:42
58	9	6	12.00	t	2026-03-12 01:32:42
59	32	2	275.00	t	2026-03-12 01:32:42
60	27	2	4.00	t	2026-03-12 01:32:42
61	50	5	2.00	t	2026-04-23 02:20:27.942044
63	2	60	25.00	t	2026-05-08 10:28:18.797984
64	6	60	20.00	f	2026-05-08 10:28:28.424166
62	1	60	20.00	t	2026-05-08 13:24:52.941429
\.


--
-- Data for Name: item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item (item_id, name) FROM stdin;
1	Masala Dosa
2	Veg Maggi
3	Cheese Maggi
4	Samosa
5	Vada Pav
6	Bread Omlette
7	Veg Sandwich
8	Paneer Wrap
9	Filter Coffee
10	Cold Coffee
11	Masala Chai
12	Lemon Tea
13	Mango Juice
14	Watermelon Juice
15	Banana Shake
16	Lassi
17	Butter Milk
18	Oreo Biscuit Pack
19	Good Day Biscuit
20	Hide & Seek Biscuit
21	Dairy Milk Chocolate
22	Kurkure Masala Munch
23	Lay's Classic Salted
24	Aloo Bhujia (50g)
25	Water Bottle 500ml
26	B/W Photocopy A4
27	Color Printout A4
28	Spiral Binding
29	Lamination
30	Scanning Service
31	Dettol Soap
32	Lifebuoy Soap
33	Pears Soap
34	Colgate Toothpaste
35	Pepsodent Toothpaste
36	Shampoo Sachet (Dove)
37	Shampoo Sachet (Clinic Plus)
38	Blue Ballpoint Pen
39	Black Gel Pen
40	Reynolds Trimax
41	A4 Notebook 200pg
42	Spiral Notebook
43	Scientific Calculator
44	Exam Pad
45	Geometry Box
46	A4 Paper Rim
47	Fevistick
48	Eraser & Sharpener Set
49	Pencil Box
50	Sticky Notes
\.


--
-- Data for Name: recharge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recharge (recharge_id, student_id, amount, date) FROM stdin;
1	4	200.00	2026-02-25
2	16	500.00	2026-01-13
3	10	200.00	2026-02-14
4	23	1500.00	2026-01-15
5	3	100.00	2026-03-10
6	14	200.00	2026-02-07
7	19	2000.00	2026-02-14
8	12	100.00	2026-03-08
9	16	2000.00	2026-02-22
10	16	500.00	2026-01-17
11	21	1500.00	2026-01-19
12	16	500.00	2026-02-27
13	20	1000.00	2026-02-03
14	27	100.00	2026-02-23
15	15	2000.00	2026-01-11
16	18	200.00	2026-02-05
17	14	2000.00	2026-01-30
18	29	2000.00	2026-02-26
19	6	500.00	2026-01-14
20	29	200.00	2026-02-05
21	10	1000.00	2026-01-20
22	29	2000.00	2026-02-08
23	19	1500.00	2026-03-10
24	18	1500.00	2026-01-24
25	30	1500.00	2026-02-13
26	3	200.00	2026-01-11
27	2	100.00	2026-02-24
28	27	500.00	2026-02-05
29	11	2000.00	2026-01-20
30	17	1500.00	2026-02-28
31	20	1500.00	2026-02-12
32	22	1000.00	2026-01-31
33	4	2000.00	2026-01-15
34	22	1000.00	2026-02-19
35	24	200.00	2026-03-05
36	2	1500.00	2026-01-28
37	8	200.00	2026-01-23
38	12	2000.00	2026-02-20
39	18	1000.00	2026-02-04
40	23	100.00	2026-01-13
41	60	500.00	2026-05-08
44	60	500.00	2026-05-08
\.


--
-- Data for Name: settlement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settlement (settlement_id, vendor_id, admin_id, status, amount, date) FROM stdin;
1	4	5	paid	1884.00	2026-03-03
2	1	1	paid	1049.00	2026-02-25
4	5	3	requested	3473.00	2026-02-17
5	4	1	requested	2257.00	2026-02-25
6	6	3	paid	1160.00	2026-02-12
7	6	2	paid	2641.00	2026-03-05
8	2	5	paid	2089.00	2026-02-22
9	3	5	requested	3083.00	2026-02-27
10	3	3	paid	2539.00	2026-02-14
11	1	1	requested	2895.00	2026-02-16
12	1	2	requested	1758.00	2026-02-13
13	1	5	requested	4156.00	2026-03-09
14	4	5	requested	4722.00	2026-02-15
15	2	2	requested	4335.00	2026-02-24
16	9	3	paid	1397.00	2026-02-27
17	2	4	requested	1816.00	2026-03-03
18	7	3	requested	4498.00	2026-02-17
19	4	2	paid	1402.00	2026-03-08
20	8	1	requested	1409.00	2026-02-28
3	7	1	paid	745.00	2026-03-05
24	1	1	requested	441.54	2026-05-08
25	60	1	requested	1475.36	2026-05-08
26	60	1	requested	14048.33	2026-05-08
27	60	1	requested	16724.13	2026-05-08
\.


--
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student (student_id, first_name, last_name, email, phone, balance, password_hash, spending_limit) FROM stdin;
2	Chasmum	Choudhary	chasmumchoudhary2@campus.edu	01279746810	1947.39	755706149089e26	\N
3	Gagan	Bir	gaganbir3@campus.edu	+911947126645	844.70	d1ccc7a1705dd30	\N
4	Madhavi	Kalita	madhavikalita4@campus.edu	+910626873372	2480.07	66e1866a206ed7b	\N
5	Damyanti	Ray	damyantiray5@campus.edu	+915633380683	1274.07	170389c2f610de4	\N
6	Lakshmi	Luthra	lakshmiluthra6@campus.edu	03878639549	778.37	a4bc9708dc04b58	\N
7	Yashoda	Saha	yashodasaha7@campus.edu	03171370031	1239.90	aea63b7a54d1e7c	\N
8	Urishilla	Bora	urishillabora8@campus.edu	2632586494	149.34	01f890bbcbb9e2c	\N
9	Pranit	Merchant	pranitmerchant9@campus.edu	07141691161	3645.40	4869bec7930f180	\N
10	Dayita	Sandhu	dayitasandhu10@campus.edu	4479269973	4828.82	3eb74c0a1c4b646	\N
11	Chaaya	Nayar	chaayanayar11@campus.edu	05504695285	846.72	f893f0e75a1c417	\N
12	Prisha	Badal	prishabadal12@campus.edu	+917806702846	1206.64	553fe8408c174d4	\N
13	Ayush	Bhatti	ayushbhatti13@campus.edu	+914412403077	3260.63	c67e13864a30b9f	\N
14	Kavya	Nagy	kavyanagy14@campus.edu	4647431506	3950.36	c0440b246be3b4d	\N
15	Ojas	Sarma	ojassarma15@campus.edu	+916713288684	4925.50	14b8af8e5c94184	\N
16	Caleb	Parmer	calebparmer16@campus.edu	4003421171	2226.94	6048b47fd19fbdb	\N
17	Harsh	Sehgal	harshsehgal17@campus.edu	3795879519	457.78	93260eafd86bf05	\N
18	Wriddhish	Nanda	wriddhishnanda18@campus.edu	3844360656	3938.60	522a7e3f30d38ef	\N
19	Chaaya	Chopra	chaayachopra19@campus.edu	9695660490	3974.97	c0486c1e79f8ac0	\N
20	Xavier	Jaggi	xavierjaggi20@campus.edu	0715727665	4815.33	0686ccdc2e3ce34	\N
21	Harita	Suri	haritasuri21@campus.edu	3648404627	3749.12	9adad953e91e77d	\N
22	Saksham	Narasimhan	sakshamnarasimhan22@campus.edu	01016457497	3192.78	a984088739246b7	\N
23	Aarnav	Mahajan	aarnavmahajan23@campus.edu	+913666187046	4649.94	f6642d3d7232f74	\N
24	Girindra	Kade	girindrakade24@campus.edu	8039007710	3905.67	74ed789e08721ca	\N
25	Gayathri	Dora	gayathridora25@campus.edu	+917823614493	536.64	1611555eb376db8	\N
26	Tanmayi	Nadkarni	tanmayinadkarni26@campus.edu	06208023950	4144.40	800e5cd45e90022	\N
27	Mugdha	Anne	mugdhaanne27@campus.edu	+915827700104	4376.72	4fc415e590932b8	\N
28	Aadi	Sagar	aadisagar28@campus.edu	1551619858	619.60	e1225c3e85619f0	\N
29	Yatan	Raja	yatanraja29@campus.edu	+916758755101	181.67	7ab4666d835fd21	\N
30	Mahika	Raghavan	mahikaraghavan30@campus.edu	05519527643	2123.93	60ee6ad51b90c91	\N
60	Sasi	chettan	sasi1@gmail.com	9999999999	900.00	$2b$12$qpxreZpd6oGmm35.SlroseJMSxWlglamSvdP47tElveg2qN0sFt/a	900.00
1	Falguni	Bhakta	falgunibhakta1@campus.edu	00485130964	630.66	4fb9e6e97d0d903	500.00
55	Madhav	P Nair	madhavpnair707@gmail.com	8921799258	0.00	$2b$12$xg4TEWZKZx.HUlQGO0LF1eH1z7ya0ph1cRiN0KGOjTyszT5P8WlTu	1000.00
\.


--
-- Data for Name: student_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_account (bankaccount_id, student_id) FROM stdin;
172	1
273	2
450	3
399	4
488	5
143	6
205	7
280	8
475	9
316	10
261	11
299	12
451	13
377	14
129	15
229	16
458	17
314	18
445	19
336	20
184	21
240	22
206	23
341	24
270	25
372	26
420	27
432	28
307	29
397	30
392	3
217	10
309	30
376	11
194	9
122	6
\.


--
-- Data for Name: vendor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor (vendor_id, name, email, phone, password_hash) FROM stdin;
1	Manju's Canteen	manjus.v1@campus.edu	+915775391922	e007c249dbeda53
2	Amul Parlour	amul.v2@campus.edu	03992156538	a7f082e80856e45
3	Nescafe	nescafe.v3@campus.edu	+918853358298	6729b1de6ecfb08
4	Kappi Cafe	kappi.v4@campus.edu	9448298065	8985c021e0a4579
5	Xerox & Print Shop	xerox.v5@campus.edu	+917611631734	2f6a764e6d505b7
6	Maggi Point	maggi.v6@campus.edu	5263098527	986dbf6cbf50c56
7	Night Canteen	night.v7@campus.edu	9391260306	e4bec94e8d08339
8	Raju Omelette Centre	raju.v8@campus.edu	+914586080851	40f6f25b18597a3
9	Chai Tapri	chai.v9@campus.edu	8259499401	cdecc2218f8d1d8
10	Fresh Juice Corner	fresh.v10@campus.edu	2348263324	98f815366286ac2
60	suku's canteen	suku@gmail.com	8888888888	$2b$12$K45d/NYu5m7KSyV83djRK.7vUGtO43a96IUXx7PPQxzY4.0W2Tqc.
\.


--
-- Data for Name: vendor_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor_account (bankaccount_id, vendor_id) FROM stdin;
19	1
39	2
8	3
11	4
37	5
24	6
28	7
35	8
33	9
49	10
50	1
7	4
12	10
10	9
\.


--
-- Name: bill_bill_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bill_bill_id_seq', 50, true);


--
-- Name: inventory_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventory_inventory_id_seq', 65, true);


--
-- Name: recharge_recharge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recharge_recharge_id_seq', 44, true);


--
-- Name: settlement_settlement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.settlement_settlement_id_seq', 27, true);


--
-- Name: admin admin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT admin_pkey PRIMARY KEY (admin_id);


--
-- Name: bank_account bank_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_account
    ADD CONSTRAINT bank_account_pkey PRIMARY KEY (bankaccount_id);


--
-- Name: bill_item bill_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_item
    ADD CONSTRAINT bill_item_pkey PRIMARY KEY (bill_id, item_id);


--
-- Name: bill bill_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill
    ADD CONSTRAINT bill_pkey PRIMARY KEY (bill_id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (item_id);


--
-- Name: recharge recharge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recharge
    ADD CONSTRAINT recharge_pkey PRIMARY KEY (recharge_id);


--
-- Name: settlement settlement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlement
    ADD CONSTRAINT settlement_pkey PRIMARY KEY (settlement_id);


--
-- Name: student_account student_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_account
    ADD CONSTRAINT student_account_pkey PRIMARY KEY (bankaccount_id);


--
-- Name: student student_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_email_key UNIQUE (email);


--
-- Name: student student_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_phone_key UNIQUE (phone);


--
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (student_id);


--
-- Name: vendor_account vendor_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_account
    ADD CONSTRAINT vendor_account_pkey PRIMARY KEY (bankaccount_id);


--
-- Name: vendor vendor_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_email_key UNIQUE (email);


--
-- Name: vendor vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (vendor_id);


--
-- Name: idx_bill_student_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bill_student_id ON public.bill USING btree (student_id);


--
-- Name: idx_bill_total_amount; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bill_total_amount ON public.bill USING btree (total_amount);


--
-- Name: idx_bill_unsettled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bill_unsettled ON public.bill USING btree (vendor_id) WHERE (settlement_id IS NULL);


--
-- Name: idx_inventory_item_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventory_item_lookup ON public.inventory USING btree (item_id) INCLUDE (vendor_id, cost, in_stock);


--
-- Name: idx_student_email_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_email_hash ON public.student USING hash (email);


--
-- Name: idx_student_student_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_student_id ON public.student USING btree (student_id);


--
-- Name: bill after_bill_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_bill_insert AFTER INSERT ON public.bill FOR EACH ROW EXECUTE FUNCTION public.trigger_update_student_balance();


--
-- Name: recharge after_recharge_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_recharge_insert AFTER INSERT ON public.recharge FOR EACH ROW EXECUTE FUNCTION public.process_student_recharge();


--
-- Name: settlement trigger_settlement_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_settlement_insert AFTER INSERT ON public.settlement FOR EACH ROW EXECUTE FUNCTION public.update_bills_after_settlement();


--
-- Name: bill trigger_update_spending_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_spending_limit AFTER INSERT ON public.bill FOR EACH ROW EXECUTE FUNCTION public.deduct_spending_limit();


--
-- Name: settlement fk_admin; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlement
    ADD CONSTRAINT fk_admin FOREIGN KEY (admin_id) REFERENCES public.admin(admin_id) ON DELETE CASCADE;


--
-- Name: bill_item fk_bill; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_item
    ADD CONSTRAINT fk_bill FOREIGN KEY (bill_id) REFERENCES public.bill(bill_id) ON DELETE CASCADE;


--
-- Name: bill_item fk_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill_item
    ADD CONSTRAINT fk_item FOREIGN KEY (item_id) REFERENCES public.item(item_id) ON DELETE CASCADE;


--
-- Name: inventory fk_item; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT fk_item FOREIGN KEY (item_id) REFERENCES public.item(item_id) ON DELETE CASCADE;


--
-- Name: bill fk_settlement; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill
    ADD CONSTRAINT fk_settlement FOREIGN KEY (settlement_id) REFERENCES public.settlement(settlement_id) ON DELETE SET NULL;


--
-- Name: bill fk_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill
    ADD CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES public.student(student_id) ON DELETE CASCADE;


--
-- Name: recharge fk_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recharge
    ADD CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES public.student(student_id) ON DELETE CASCADE;


--
-- Name: student_account fk_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_account
    ADD CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES public.student(student_id) ON DELETE CASCADE;


--
-- Name: bill fk_vendor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bill
    ADD CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendor(vendor_id) ON DELETE CASCADE;


--
-- Name: inventory fk_vendor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendor(vendor_id) ON DELETE CASCADE;


--
-- Name: settlement fk_vendor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settlement
    ADD CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendor(vendor_id) ON DELETE CASCADE;


--
-- Name: vendor_account fk_vendor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor_account
    ADD CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES public.vendor(vendor_id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO student_role;
GRANT USAGE ON SCHEMA public TO vendor_role;
GRANT USAGE ON SCHEMA public TO admin_role;


--
-- Name: FUNCTION approve_settlement(p_settlement_id integer, p_admin_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.approve_settlement(p_settlement_id integer, p_admin_id integer) TO admin_role;


--
-- Name: FUNCTION compare_prices(p_item_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.compare_prices(p_item_id integer) TO student_role;


--
-- Name: FUNCTION get_statement(p_student_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_statement(p_student_id integer) TO student_role;


--
-- Name: FUNCTION issue_bill(p_student_id integer, p_vendor_id integer, p_total_amount numeric); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.issue_bill(p_student_id integer, p_vendor_id integer, p_total_amount numeric) TO student_role;
GRANT ALL ON FUNCTION public.issue_bill(p_student_id integer, p_vendor_id integer, p_total_amount numeric) TO vendor_role;


--
-- Name: FUNCTION request_settlement(p_vendor_id character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.request_settlement(p_vendor_id character varying) TO vendor_role;


--
-- Name: FUNCTION set_spending_limit(p_student_id integer, p_spending_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_spending_limit(p_student_id integer, p_spending_limit integer) TO student_role;


--
-- Name: FUNCTION update_vendor_inventory(p_vendor_id integer, p_item_id integer, p_new_cost numeric, p_in_stock boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_vendor_inventory(p_vendor_id integer, p_item_id integer, p_new_cost numeric, p_in_stock boolean) TO vendor_role;


--
-- Name: TABLE student; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.student TO student_role;
GRANT SELECT ON TABLE public.student TO vendor_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.student TO admin_role;


--
-- Name: COLUMN student.spending_limit; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE(spending_limit) ON TABLE public.student TO student_role;


--
-- Name: TABLE active_student_limits; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.active_student_limits TO admin_role;


--
-- Name: TABLE admin; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.admin TO admin_role;


--
-- Name: TABLE bank_account; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.bank_account TO admin_role;


--
-- Name: SEQUENCE bill_bill_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.bill_bill_id_seq TO student_role;
GRANT SELECT,USAGE ON SEQUENCE public.bill_bill_id_seq TO vendor_role;
GRANT ALL ON SEQUENCE public.bill_bill_id_seq TO admin_role;


--
-- Name: TABLE bill; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.bill TO student_role;
GRANT SELECT ON TABLE public.bill TO vendor_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.bill TO admin_role;


--
-- Name: TABLE bill_item; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.bill_item TO admin_role;


--
-- Name: TABLE inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.inventory TO student_role;
GRANT SELECT,INSERT,UPDATE ON TABLE public.inventory TO vendor_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.inventory TO admin_role;


--
-- Name: SEQUENCE inventory_inventory_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.inventory_inventory_id_seq TO student_role;
GRANT SELECT,USAGE ON SEQUENCE public.inventory_inventory_id_seq TO vendor_role;
GRANT ALL ON SEQUENCE public.inventory_inventory_id_seq TO admin_role;


--
-- Name: TABLE item; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.item TO admin_role;


--
-- Name: TABLE my_inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.my_inventory TO admin_role;


--
-- Name: TABLE recharge; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.recharge TO student_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.recharge TO admin_role;


--
-- Name: SEQUENCE recharge_recharge_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.recharge_recharge_id_seq TO student_role;
GRANT SELECT,USAGE ON SEQUENCE public.recharge_recharge_id_seq TO vendor_role;
GRANT ALL ON SEQUENCE public.recharge_recharge_id_seq TO admin_role;


--
-- Name: TABLE settlement; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.settlement TO vendor_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.settlement TO admin_role;


--
-- Name: SEQUENCE settlement_settlement_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.settlement_settlement_id_seq TO student_role;
GRANT SELECT,USAGE ON SEQUENCE public.settlement_settlement_id_seq TO vendor_role;
GRANT ALL ON SEQUENCE public.settlement_settlement_id_seq TO admin_role;


--
-- Name: TABLE student_account; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.student_account TO admin_role;


--
-- Name: TABLE unsettled_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.unsettled_requests TO admin_role;


--
-- Name: TABLE vendor; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vendor TO student_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor TO admin_role;
GRANT SELECT ON TABLE public.vendor TO vendor_role;


--
-- Name: TABLE vendor_account; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor_account TO admin_role;


--
-- Name: TABLE vendor_daily_sales; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor_daily_sales TO admin_role;


--
-- PostgreSQL database dump complete
--

\unrestrict fX3m2M0PvPyMgseJBG7oZUnT00I32r6hhDUeqhAbkIeep1lSSoJnkrYJtdKlKJH

