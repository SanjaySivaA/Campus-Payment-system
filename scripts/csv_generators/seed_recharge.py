import csv
import random
from faker import Faker
import os
import sys

# Initialize Faker with Indian locale for realistic date generation
fake = Faker('en_IN')

# Prepare the data list
recharges = []

# Generate exactly 40 recharge records
for recharge_id in range(1, 41):
    # Random student_id between 1 and 30 (inclusive)
    student_id = random.randint(1, 30)
    
    # Typical recharge amounts (multiples of 10 or 50 look more realistic)
    amount = float(random.choice([100, 200, 500, 1000, 1500, 2000]))
    
    # Generate a random date within the last 6 months
    recharge_date = fake.date_between(start_date='-60d', end_date='today')
    
    # Append row in the order: recharge_id, student_id, amount, date
    recharges.append([recharge_id, student_id, amount, recharge_date])

# Define the filename - must match your table name 'Recharge' for the importer
filename = 'recharge.csv'

# Ensure the file is saved in the same directory as the script
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    # Write header matching your table columns
    writer.writerow(['recharge_id', 'student_id', 'amount', 'date'])
    writer.writerows(recharges)

# Output only the filename/path so you know what to pass to your db_seed.py
print(full_path)