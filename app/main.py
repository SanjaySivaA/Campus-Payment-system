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
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from datetime import timedelta

from . import crud, schemas, auth
from .database import get_raw_db_conn

# app = APIRouter()

app = FastAPI(title="Campus Payment System API")

origins = [
    "http://localhost:3000", # Typical React/Next.js port
    "http://localhost:5173", # Typical Vite/Vue port
    "http://localhost:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,       # Domains allowed to communicate with this API
    allow_credentials=True,      # Allows cookies/authorization headers to be sent
    allow_methods=["*"],         # Allows all HTTP methods (GET, POST, PUT, DELETE, etc.)
    allow_headers=["*"],         # Allows all headers (Crucial for passing the JWT Bearer token)
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# test endpoint 
@app.get("/")
def read_root():
    return {"message": "API is running"}

# statements' endpoint
@app.get("/students/{student_id}/statement", response_model=List[schemas.StatementItem])
def read_student_statement(student_id: int, conn = Depends(get_raw_db_conn)):
    """
    Retrieves the statement using raw SQL via Psycopg2.
    """
    # Call the raw SQL function
    statement_rows = crud.get_statement(conn, student_id)
    
    # return empty array if no bills/ invalid student_id (only valid student_id s are sent from frontend)
    if not statement_rows:
        return []  
        
    # FastAPI and Pydantic will automatically parse the RealDictCursor output
    # into the JSON format defined by the StatementItem schema.
    return statement_rows

# to set spending limit
@app.put("/students/{student_id}/spending-limit")
def update_spending_limit(student_id: int, data: schemas.SpendingLimitUpdate, conn = Depends(get_raw_db_conn)):
    try:
        crud.set_spending_limit(conn, student_id, data.spending_limit)
        return {
            "student_id": student_id,
            "spending_limit": data.spending_limit,
            "message": "Spending limit updated successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# endpoint to get unsettled requests view
@app.get("/admin/unsettled-requests", response_model=List[schemas.UnsettledRequest])
def read_unsettled_requests(conn = Depends(get_raw_db_conn)):
    try:
        rows = crud.get_unsettled_requests(conn)
        return rows   
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ----------------- Authentication endpoints begin --------------------------------------- #

@app.post("/signup/student", status_code=status.HTTP_201_CREATED)
def signup_student(student: schemas.StudentCreate, conn = Depends(get_raw_db_conn)):
    print(f"DEBUG: Password string received: '{student.password}'")
    print(f"DEBUG: Password length: {len(student.password)}")
    hashed_pw = auth.get_password_hash(student.password)
    try:
        student_id = crud.create_student(conn, student, hashed_pw)
        return {"message": "Student account created successfully", "student_id": student_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/signup/vendor", status_code=status.HTTP_201_CREATED)
def signup_vendor(vendor: schemas.VendorCreate, conn = Depends(get_raw_db_conn)):
    hashed_pw = auth.get_password_hash(vendor.password)
    try:
        vendor_id = crud.create_vendor(conn, vendor, hashed_pw)
        return {"message": "Vendor account created successfully", "vendor_id": vendor_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/login", response_model=schemas.Token)
def login(req: schemas.LoginRequest, conn = Depends(get_raw_db_conn)):
    # Look up the user in the correct table based on their role
    user = crud.get_user_auth(conn, user_id=req.user_id, role=req.role.value)
    
    # Verify existence and password
    if not user or not auth.verify_password(req.password, user['password_hash']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect ID or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Embed the role directly in the JWT token payload
    access_token = auth.create_access_token(
        data={"sub": str(user['id']), "role": req.role.value}, 
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

# ----------------- Authentication endpoints end --------------------------------------- #