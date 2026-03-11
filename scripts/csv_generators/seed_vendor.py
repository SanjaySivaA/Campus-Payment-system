import csv
import sys
import re
import os
from faker import Faker

# Initialize Faker with the Indian locale for phone numbers and hashes
fake = Faker('en_IN')

# Our top 10 curated list of classic campus vendors
campus_vendors = [
    "Manju's Canteen",
    "Amul Parlour",
    "Nescafe",
    "Kappi Cafe",
    "Xerox & Print Shop",
    "Maggi Point",
    "Night Canteen",
    "Raju Omelette Centre",
    "Chai Tapri",
    "Fresh Juice Corner"
]

# Prepare the data list
vendors = []

# Loop exactly 10 times
for vendor_id in range(1, 11):
    # Grab the specific name from our list
    firm_name = campus_vendors[vendor_id - 1]
    
    # Create a clean email address based on the firm name
    first_word = firm_name.split()[0].lower()
    clean_prefix = re.sub(r'[^a-z0-9]', '', first_word)
    email = f"{clean_prefix}.v{vendor_id}@campus.edu"
    
    # Generate a realistic Indian phone number
    phone = fake.phone_number()
    
    # Generate a dummy password hash (taking the first 15 characters)
    password_hash = fake.sha256()[:15]
    
    # Append the row EXACTLY in the order requested:
    vendors.append([vendor_id, firm_name, email, phone, password_hash])

# --- THE FIX IS HERE ---
# Get the absolute directory path where this Python script is stored
script_dir = os.path.dirname(os.path.abspath(__file__))

# Combine the directory path with the filename
# Using 'Vendor.csv' (capital V) to match your Postgres table casing if needed
filename = os.path.join(script_dir, 'Vendor.csv') 

with open(filename, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    
    # Write the header
    writer.writerow(['vendor_id', 'name', 'email', 'phone', 'password_hash'])
    
    # Write the 10 generated rows
    writer.writerows(vendors)

# 1. Print logging info to STDERR (shows up on screen, bypasses pipe)
sys.stderr.write(f"SUCCESS: Generated 10 classic campus vendor records at:\n{filename}\n")

# 2. Print ONLY the absolute filename to STDOUT (pipes directly to db_seed.py)
print(filename)