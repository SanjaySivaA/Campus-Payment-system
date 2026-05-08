--------------------RBAC-------------------------------------

-- groups
CREATE ROLE student_role NOLOGIN;
CREATE ROLE vendor_role NOLOGIN;
CREATE ROLE admin_role NOLOGIN;

-- Grant access to the default 'public' schema for all roles
GRANT USAGE ON SCHEMA public TO student_role, vendor_role, admin_role;


-- Table Permissions
GRANT SELECT ON Student,Vendor, Inventory TO student_role;
GRANT SELECT, UPDATE(spending_limit) ON Student TO student_role;
GRANT INSERT, SELECT ON Bill, Recharge TO student_role;

-- If Bill and Recharge use SERIAL primary keys, they need access to the sequences to auto-increment the IDs!
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO student_role;

-- Function Permissions
GRANT EXECUTE ON FUNCTION get_statement(INT) TO student_role;
GRANT EXECUTE ON FUNCTION compare_prices(INT) TO student_role;
GRANT EXECUTE ON FUNCTION set_spending_limit(INT, INT) TO student_role;


---------------VENDOR-------------------------------------
-- Table Permissions
GRANT SELECT ON Student, Bill,Vendor TO vendor_role;
GRANT SELECT, UPDATE,INSERT ON Inventory TO vendor_role;
GRANT INSERT, SELECT ON Settlement TO vendor_role;

-- Sequence permissions for generating new settlements
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO vendor_role;

-- Function Permissions
GRANT EXECUTE ON FUNCTION request_settlement(VARCHAR) TO vendor_role;
GRANT EXECUTE ON FUNCTION update_vendor_inventory(INT, INT, NUMERIC, BOOLEAN) TO vendor_role;
GRANT EXECUTE ON FUNCTION issue_bill(INT, INT, NUMERIC) TO vendor_role;



-- Table Permissions (Admins get broad access to manage the system)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO admin_role;

-- Function Permissions
GRANT EXECUTE ON FUNCTION approve_settlement(INT, INT) TO admin_role;



-- ==========================================
-- PROXY API USERS
-- ==========================================

-- 1. Create the backend login accounts with passwords
CREATE USER student_api WITH PASSWORD 'student_password_123';
CREATE USER vendor_api WITH PASSWORD 'vendor_password_123';
CREATE USER admin_api WITH PASSWORD 'admin_password_123';

-- 2. Hand them the "badges" (assign the group roles to the proxy users)
GRANT student_role TO student_api;
GRANT vendor_role TO vendor_api;
GRANT admin_role TO admin_api;