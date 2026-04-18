from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import List, Optional

# --- Base Schemas ---

class StudentBase(BaseModel):
    student_id: str
    name: str
    email: EmailStr

class StudentResponse(StudentBase):
    balance: float

    class Config:
        from_attributes = True  # Allows Pydantic to read SQLAlchemy models

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

    class Config:
        from_attributes = True