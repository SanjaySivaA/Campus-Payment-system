from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import List, Optional

# from pydantic import BaseModel
from datetime import date
from decimal import Decimal


# add other schemas

class StatementItem(BaseModel):
    bill_id: int
    date: date
    vendor_id: int
    vendor_name: str
    amount: Decimal

    class Config:
        from_attributes = True  

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