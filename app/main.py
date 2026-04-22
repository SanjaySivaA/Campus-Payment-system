from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import schemas, crud
from .database import engine, get_db

app = FastAPI(title="Campus Payment System API")

@app.get("/students/{student_id}", response_model=schemas.StudentResponse)
def read_student(student_id: str, db: Session = Depends(get_db)):
    db_student = crud.get_student(db, student_id=student_id)
    if db_student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return db_student