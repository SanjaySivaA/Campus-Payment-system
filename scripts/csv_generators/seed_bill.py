import csv
import random
from faker import Faker
import os

fake = Faker('en_IN')
filename = 'bill.csv'

# 1. Hardcoded data from your bill_item distribution to calculate exact totals
# Format: bill_id: sum of (quantity * selling_price)
bill_calculations = {
    1: (3 * 153.04),
    2: (1 * 30.68) + (3 * 364.34) + (3 * 284.09),
    3: (1 * 129.13) + (2 * 139.40) + (2 * 85.93) + (3 * 58.12),
    4: (1 * 342.80),
    5: (2 * 11.34) + (1 * 33.32),
    6: (2 * 119.42) + (2 * 483.51) + (3 * 285.89) + (2 * 146.25),
    7: (3 * 123.86) + (3 * 65.04) + (3 * 467.30) + (2 * 196.37),
    8: (3 * 31.67) + (2 * 197.53),
    9: (1 * 145.24) + (1 * 66.96) + (3 * 3.85) + (3 * 491.04),
    10: (1 * 124.41) + (3 * 66.12) + (2 * 190.24),
    11: (1 * 66.73) + (1 * 26.16),
    12: (2 * 48.26) + (1 * 70.41) + (3 * 369.29) + (2 * 133.20),
    13: (2 * 511.30) + (2 * 88.92),
    14: (2 * 157.84) + (3 * 4.19) + (1 * 25.41),
    15: (1 * 12.17) + (3 * 514.96) + (1 * 81.90) + (2 * 70.07),
    16: (3 * 11.55) + (2 * 212.93),
    17: (2 * 154.36) + (2 * 469.05),
    18: (2 * 373.62),
    19: (2 * 33.88) + (1 * 257.15),
    20: (2 * 281.43),
    21: (3 * 24.86),
    22: (3 * 83.49) + (3 * 264.51) + (3 * 84.07) + (2 * 477.48),
    23: (2 * 196.15) + (3 * 4.18),
    24: (1 * 67.59) + (2 * 201.85),
    25: (2 * 439.42),
    26: (1 * 236.97) + (2 * 105.30) + (3 * 68.68),
    27: (1 * 441.54),
    28: (1 * 198.62) + (2 * 64.87) + (2 * 63.25),
    29: (1 * 49.67) + (2 * 32.96),
    30: (3 * 390.68) + (3 * 225.97),
    31: (3 * 15.79) + (3 * 31.40) + (1 * 158.85) + (2 * 142.68),
    32: (2 * 94.04) + (3 * 454.26),
    33: (1 * 39.57) + (3 * 6.11) + (1 * 278.49),
    34: (3 * 31.63) + (2 * 151.72) + (1 * 424.31) + (2 * 203.98),
    35: (1 * 490.16),
    36: (2 * 237.13) + (1 * 31.18) + (2 * 274.01) + (3 * 80.54),
    37: (3 * 293.09) + (2 * 300.63) + (3 * 4.19),
    38: (2 * 31.46) + (2 * 11.43),
    39: (3 * 514.44) + (1 * 232.95),
    40: (1 * 458.78)
}

bills = []

for b_id in range(1, 41):
    student_id = random.randint(1, 30)
    vendor_id = random.randint(1, 10)
    
    # Use settlement_id 1-20 or None
    settle_id = random.choice([random.randint(1, 20), ""])
    
    # Calculate exact total from the hardcoded dictionary
    total_amount = round(bill_calculations.get(b_id, 50.00), 2)
    
    status = random.choices(['completed', 'refund'], weights=[95, 5])[0]
    b_date = fake.date_between(start_date='-30d', end_date='today')
    
    bills.append([b_id, student_id, vendor_id, settle_id, total_amount, b_date, status])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['bill_id', 'student_id', 'vendor_id', 'settlement_id', 'total_amount', 'date', 'status'])
    writer.writerows(bills)

print(full_path.lower())