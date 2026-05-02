# from sqlalchemy.orm import Session
# from sqlalchemy import text

# def execute_as_role(db: Session, role_name: str, query_string: str, params: dict):
#     """
#     Executes a query under a specific PostgreSQL role, reverting back 
#     to the default app user immediately after the transaction.
#     """
#     try:
#         # SET LOCAL only applies to the current transaction. 
#         # It automatically reverts when the transaction is committed or rolled back.
#         db.execute(text(f"SET LOCAL ROLE {role_name}"))
        
#         result = db.execute(text(query_string), params)
#         db.commit()
#         return result
#     except Exception as e:
#         db.rollback()
#         raise e

# def get_student(db: Session, student_id: str):
#     """
#     Fetches a student by their ID using a raw parameterized SQL query.
#     """
#     query = text("""
#         SELECT student_id, name, email, balance 
#         FROM student 
#         WHERE student_id = :student_id
#     """)
    
#     result = db.execute(query, {"student_id": student_id}).mappings().first()
    
#     return result

# def vendor_request_settlement(db: Session, vendor_id: str):
#     query = "SELECT request_settlement(:vendor_id) AS new_id"
#     # Execute as the 'vendor' role
#     result = execute_as_role(db, "vendor_role", query, {"vendor_id": vendor_id})
#     return result.mappings().first()

from . import schemas

def get_user_auth(conn, user_id: int, role: str):
    """
    Fetches the user's password hash based on their role.
    String formatting is safe here because `role` is strictly validated by Pydantic's Enum.
    """
    id_col = f"{role}_id"
    query = f"SELECT {id_col} AS id, password_hash FROM {role} WHERE {id_col} = %s"
    
    with conn.cursor() as cur:
        cur.execute(query, (user_id,))
        return cur.fetchone()

def create_student(conn, student: schemas.StudentCreate, hashed_password: str):
    query = """
        INSERT INTO student (student_id, first_name, last_name, email, phone, balance, password_hash, spending_limit)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING student_id;
    """
    with conn.cursor() as cur:
        cur.execute(query, (
            student.student_id, student.first_name, student.last_name,
            student.email, student.phone, 0.0, hashed_password, student.spending_limit
        ))
        conn.commit()
        return cur.fetchone()['student_id']

def create_vendor(conn, vendor: schemas.VendorCreate, hashed_password: str):
    query = """
        INSERT INTO vendor (vendor_id, name, email, phone, password_hash)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING vendor_id;
    """
    with conn.cursor() as cur:
        cur.execute(query, (
            vendor.vendor_id, vendor.name,
            vendor.email, vendor.phone, hashed_password
        ))
        conn.commit()
        return cur.fetchone()['vendor_id']


def get_statement(conn, student_id: int):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_statement(%s);", (student_id,))
        rows = cur.fetchall()
    return rows


def set_spending_limit(conn, student_id: int, spending_limit):
    with conn.cursor() as cur:
        cur.callproc("set_spending_limit", [student_id, spending_limit])
    conn.commit()

def get_unsettled_requests(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM unsettled_requests;")
        rows = cur.fetchall()
    return rows

