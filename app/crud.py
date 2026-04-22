from sqlalchemy.orm import Session
from sqlalchemy import text

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