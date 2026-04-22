from sqlalchemy.orm import Session
from sqlalchemy import text

def execute_as_role(db: Session, role_name: str, query_string: str, params: dict):
    """
    Executes a query under a specific PostgreSQL role, reverting back 
    to the default app user immediately after the transaction.
    """
    try:
        # SET LOCAL only applies to the current transaction. 
        # It automatically reverts when the transaction is committed or rolled back.
        db.execute(text(f"SET LOCAL ROLE {role_name}"))
        
        result = db.execute(text(query_string), params)
        db.commit()
        return result
    except Exception as e:
        db.rollback()
        raise e

def get_student(db: Session, student_id: str):
    """
    Fetches a student by their ID using a raw parameterized SQL query.
    """
    query = text("""
        SELECT student_id, name, email, balance 
        FROM student 
        WHERE student_id = :student_id
    """)
    
    result = db.execute(query, {"student_id": student_id}).mappings().first()
    
    return result

def vendor_request_settlement(db: Session, vendor_id: str):
    query = "SELECT request_settlement(:vendor_id) AS new_id"
    # Execute as the 'vendor' role
    result = execute_as_role(db, "vendor_role", query, {"vendor_id": vendor_id})
    return result.mappings().first()