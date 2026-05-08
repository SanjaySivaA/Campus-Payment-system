# # from sqlalchemy import create_engine
# # from sqlalchemy.ext.declarative import declarative_base
# # from sqlalchemy.orm import sessionmaker

# # # Replace with your actual credentials from the project report
# # SQLALCHEMY_DATABASE_URL = "postgresql://user:password@localhost/campus_payment"

# # engine = create_engine(SQLALCHEMY_DATABASE_URL)
# # SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# # Base = declarative_base()

# # def get_db():
# #     db = SessionLocal()
# #     try:
# #         yield db
# #     finally:
# #         db.close()

# import psycopg2
# import dotenv
# import os
# from psycopg2.extras import RealDictCursor
# from dotenv import load_dotenv


# load_dotenv()

# # use actual db credentials in .env
# DB_URL = os.getenv("DB_URL")

# def get_raw_db_conn():
#     """Yields a raw PostgreSQL connection that returns rows as dictionaries."""
#     conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
#     try:
#         yield conn
#         print('db connected')
#     finally:
#         print('db closed')
#         conn.close()

import psycopg2
import os
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
from fastapi import Depends, HTTPException
from .auth import get_current_role

load_dotenv()

# Base DB URL for public endpoints (login, signup)
DB_URL = os.getenv("DB_URL")

# Role-specific URLs for protected endpoints
STUDENT_DB_URL = os.getenv("STUDENT_DB_URL")
VENDOR_DB_URL = os.getenv("VENDOR_DB_URL")
ADMIN_DB_URL = os.getenv("ADMIN_DB_URL")

def get_raw_db_conn():
    """Used strictly for public endpoints like login and signup."""
    conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
    try:
        yield conn
        print('Raw DB connected')
    finally:
        print('Raw DB closed')
        conn.close()


def get_role_db_conn(role: str = Depends(get_current_role)):
    """Yields a DB connection dynamically based on the JWT token's role."""
    if role == "student":
        db_url = STUDENT_DB_URL
    elif role == "vendor":
        db_url = VENDOR_DB_URL
    elif role == "admin":
        db_url = ADMIN_DB_URL
    else:
        raise HTTPException(status_code=403, detail="Invalid user role")

    if not db_url:
        raise HTTPException(status_code=500, detail=f"Database URL for {role} is missing in .env")

    conn = psycopg2.connect(db_url, cursor_factory=RealDictCursor)
    try:
        yield conn
        print(f'Role DB connected as: {role}')
    finally:
        print(f'Role DB closed: {role}')
        conn.close()