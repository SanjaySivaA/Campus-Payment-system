import csv
import random
import os
from datetime import datetime

# Configuration
TOTAL_RECORDS = 60 # Average of 6 items per vendor
filename = 'inventory.csv'

inventory_data = []

# To ensure variety, we'll pick random item/vendor pairs
# using a set to avoid duplicate (item_id, vendor_id) pairs if needed
seen_pairs = set()

for i in range(1, TOTAL_RECORDS + 1):
    v_id = random.randint(1, 10)
    item_id = random.randint(1, 50)
    
    # Simple logic: snacks are cheaper, stationery/groceries vary
    if item_id <= 25: # Eateries
        cost = float(random.randint(10, 150))
    elif item_id <= 30: # Xerox
        cost = float(random.randint(2, 50))
    else: # Essentials
        cost = float(random.randint(5, 500))
        
    in_stock = random.choices([True, False], weights=[85, 15])[0]
    
    # Current timestamp for last_update_time
    last_update = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    inventory_data.append([i, item_id, v_id, cost, in_stock, last_update])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['inventory_id', 'item_id', 'vendor_id', 'cost', 'in_stock', 'last_update_time'])
    writer.writerows(inventory_data)

print(full_path.lower())