import csv
import random
from faker import Faker
import os
from datetime import timedelta

# Initialize Faker
fake = Faker('en_IN')

# Configuration
TOTAL_ROWS = 25
filename = 'spending_limit.csv'

limits = []

for l_id in range(1, TOTAL_ROWS + 1):
    # Random student_id between 1 and 25 as requested
    s_id = random.randint(1, 25)
    
    # Generate a start date within the last month
    start_date = fake.date_between(start_date='-30d', end_date='today')
    
    # End date is usually 30 days after start date (monthly limit)
    end_date = start_date + timedelta(days=30)
    
    # Typical campus monthly spending limit (₹500 to ₹5000)
    remaining_amount = float(random.choice([500, 1000, 1500, 2000, 3000, 5000]))
    
    limits.append([l_id, s_id, start_date, end_date, remaining_amount])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['limit_id', 'student_id', 'start_date', 'end_date', 'remaining_amount'])
    writer.writerows(limits)

# Output the path for your db_seed.py argument
print(full_path.lower())