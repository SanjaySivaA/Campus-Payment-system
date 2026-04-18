from sqlalchemy import Column, String, Float, Integer
from .database import Base

class Student(Base):
    __tablename__ = "student"

    student_id = Column(String, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True)
    balance = Column(Float, default=0.0)