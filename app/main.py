# from fastapi import FastAPI, Depends, HTTPException
# from sqlalchemy.orm import Session
# from . import schemas, crud
# from .database import engine, get_db

# app = FastAPI(title="Campus Payment System API")

# @app.get("/students/{student_id}", response_model=schemas.StudentResponse)
# def read_student(student_id: str, db: Session = Depends(get_db)):
#     db_student = crud.get_student(db, student_id=student_id)
#     if db_student is None:
#         raise HTTPException(status_code=404, detail="Student not found")
#     return db_student

# from fastapi import APIRouter, Depends, HTTPException
from fastapi import FastAPI, Depends, HTTPException
from typing import List
from . import crud, schemas
from .database import get_raw_db_conn

# app = APIRouter()

app = FastAPI(title="Campus Payment System API")

@app.get("/")
def read_root():
    return {"message": "API is running"}

@app.get("/students/{student_id}/statement", response_model=List[schemas.StatementItem])
def read_student_statement(student_id: int, conn = Depends(get_raw_db_conn)):
    """
    Retrieves the statement using raw SQL via Psycopg2.
    """
    # Call the raw SQL function
    statement_rows = crud.get_statement(conn, student_id)
    
    if not statement_rows:
        raise HTTPException(status_code=404, detail="No transactions found for this student.")
        
    # FastAPI and Pydantic will automatically parse the RealDictCursor output
    # into the JSON format defined by the StatementItem schema.
    return statement_rows