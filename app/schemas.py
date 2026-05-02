from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import List, Optional
from enum import Enum

# from pydantic import BaseModel
from datetime import date
from decimal import Decimal

class RoleEnum(str, Enum):
    student = "student"
    vendor = "vendor"
    admin = "admin"

# --------------------------- Authentication Schemas ------------------------------ #

class LoginRequest(BaseModel):
    user_id: int
    password: str
    role: RoleEnum

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None

class StudentCreate(BaseModel):
    student_id: int
    # Enforce max lengths to match your PostgreSQL column limits
    first_name: str = Field(..., max_length=20)
    last_name: str = Field(..., max_length=20)
    email: EmailStr = Field(..., max_length=255) 
    phone: str = Field(..., max_length=15)
    
    # Password doesn't need a max_length here because it gets hashed to 60 chars anyway,
    # but you can add a min_length for security
    password: str = Field(..., min_length=4) 
    spending_limit: Decimal

class VendorCreate(BaseModel):
    vendor_id: int
    name: str = Field(..., max_length=100)
    email: EmailStr = Field(..., max_length=255)
    phone: str = Field(..., max_length=15)
    password: str = Field(..., min_length=4)
# --------------------------------------------------------------------------------- #

# add other schemas

class StatementItem(BaseModel):
    bill_id: int
    date: date
    vendor_id: int
    vendor_name: str
    amount: Decimal

    class Config:
        from_attributes = True  


class SpendingLimitUpdate(BaseModel):
    student_id: int
    spending_limit: Decimal
    message: str

class UnsettledRequest(BaseModel):
    settlement_id: int
    vendor_id: int
    amount: Decimal
    status: str
    date: date

# --- Base Schemas ---

class StudentBase(BaseModel):
    student_id: str
    name: str
    email: EmailStr

class StudentResponse(StudentBase):
    balance: float

# --- Feature 1: Price Comparison ---

class PriceComparisonRequest(BaseModel):
    item_id: int

class VendorPrice(BaseModel):
    vendor_name: str
    price: float

class PriceComparisonResponse(BaseModel):
    item_id: int
    prices: List[VendorPrice]

# --- Feature 2: Purchase History ---

class HistoryRequest(BaseModel):
    student_id: str
    start_date: datetime
    end_date: datetime

class BillItemSchema(BaseModel):
    item_name: str
    quantity: int
    price_at_purchase: float

class BillResponse(BaseModel):
    bill_id: int
    date_time: datetime
    total_amount: float
    vendor_name: str
    items: List[BillItemSchema]