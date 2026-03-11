import csv
import random
from faker import Faker
import os

# Initialize Faker
fake = Faker('en_IN')

# Configuration
TOTAL_ROWS = 20
filename = 'settlement.csv'

settlements = []

for s_id in range(1, TOTAL_ROWS + 1):
    v_id = random.randint(1, 10)
    a_id = random.randint(1, 5)
    
    # Randomly choose status
    status = random.choice(['requested', 'paid'])
    
    # Realistic settlement amounts for a campus stall
    amount = float(random.randint(500, 5000))
    
    # Generate dates from the last month
    s_date = fake.date_between(start_date='-30d', end_date='today')
    
    settlements.append([s_id, v_id, a_id, status, amount, s_date])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['settlement_id', 'vendor_id', 'admin_id', 'status', 'amount', 'date'])
    writer.writerows(settlements)

# Print the path for your db_seed.py argument
print(full_path.lower())