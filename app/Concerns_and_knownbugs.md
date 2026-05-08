- Navigating to `SpendingLimit` by joins during Bill generation is costly
- the small size of the tables limits the use of indexes created. We can use `SET enable_seqscan = OFF;` to test indexes but remember to do `SET enable_seqscan = ON`
- Can `issue_bill` function itself update student balance and weekly balance without any trigger if those checks are passed ?

- `request_settlements` - varchar or int for  `p_vendor_id`
- `update_bills_after_settlement` triggered by `request_settlement`automatically gives a valid `settlement_id` to the bills without an admin approval (before `approve_settlement`) 
