# from sqlalchemy import create_engine
# from sqlalchemy.ext.declarative import declarative_base
# from sqlalchemy.orm import sessionmaker

# # Replace with your actual credentials from the project report
# SQLALCHEMY_DATABASE_URL = "postgresql://user:password@localhost/campus_payment"

# engine = create_engine(SQLALCHEMY_DATABASE_URL)
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# Base = declarative_base()

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()

import psycopg2
import dotenv
import os
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv


load_dotenv()

# use actual db credentials in .env
DB_URL = os.getenv("DB_URL")

def get_raw_db_conn():
    """Yields a raw PostgreSQL connection that returns rows as dictionaries."""
    conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
    try:
        yield conn
        print('db connected')
    finally:
        print('db closed')
        conn.close()