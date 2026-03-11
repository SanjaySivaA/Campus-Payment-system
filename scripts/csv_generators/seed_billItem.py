import csv
import random
import os

# Configuration
filename = 'bill_item.csv'

# Your specific Inventory Data: {item_id: [list of costs from your table]}
inventory_map = {
    50: [284.00, 197.00], 9: [58.00, 26.00, 12.00], 42: [152.00, 445.00],
    11: [108.00], 19: [82.00, 129.00], 17: [135.00, 67.00, 68.00],
    5: [89.00, 61.00], 26: [47.00, 24.00, 6.00], 32: [34.00, 232.00, 275.00],
    28: [16.00, 12.00, 4.00], 44: [226.00], 25: [53.00, 143.00, 44.00, 86.00],
    40: [499.00], 2: [46.00], 36: [444.00], 21: [121.00, 52.00],
    6: [68.00], 48: [470.00], 35: [408.00], 49: [359.00],
    41: [310.00], 29: [11.00], 15: [144.00, 38.00, 39.00, 134.00],
    34: [205.00], 16: [70.00, 87.00], 31: [65.00, 190.00], 27: [21.00, 4.00],
    46: [275.00, 48.00], 43: [149.00], 45: [261.00], 18: [32.00],
    37: [193.00], 14: [94.00, 21.00], 3: [26.00]
}

bill_items = []
available_item_ids = list(inventory_map.keys())

# Assuming 40 bills exist
for b_id in range(1, 41):
    # Randomly pick 1 to 4 unique items per bill
    num_items = random.randint(1, 4)
    selected_items = random.sample(available_item_ids, num_items)
    
    for i_id in selected_items:
        base_cost = random.choice(inventory_map[i_id])
        
        # Selling price: cost +/- 5% to keep it very close
        margin = base_cost * random.uniform(-0.05, 0.05)
        selling_price = round(base_cost + margin, 2)
        
        qty = random.randint(1, 3)
        bill_items.append([b_id, i_id, qty, f"{selling_price:.2f}"])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['bill_id', 'item_id', 'quantity', 'selling_price'])
    writer.writerows(bill_items)

print(full_path.lower())