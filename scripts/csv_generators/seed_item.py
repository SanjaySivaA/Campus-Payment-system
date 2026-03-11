import csv
import os

# Configuration
filename = 'item.csv'

# Category A: Snacks/Juice/Packed (25 items)
eateries = [
    "Masala Dosa", "Veg Maggi", "Cheese Maggi", "Samosa", "Vada Pav", 
    "Bread Omlette", "Veg Sandwich", "Paneer Wrap", "Filter Coffee", "Cold Coffee", 
    "Masala Chai", "Lemon Tea", "Mango Juice", "Watermelon Juice", "Banana Shake", 
    "Lassi", "Butter Milk", "Oreo Biscuit Pack", "Good Day Biscuit", "Hide & Seek Biscuit", 
    "Dairy Milk Chocolate", "Kurkure Masala Munch", "Lay's Classic Salted", "Aloo Bhujia (50g)", "Water Bottle 500ml"
]

# Category B: Xerox/Printing (5 items)
xerox = [
    "B/W Photocopy A4", "Color Printout A4", "Spiral Binding", "Lamination", "Scanning Service"
]

# Category C: Stationaries & Essentials (20 items)
essentials = [
    "Dettol Soap", "Lifebuoy Soap", "Pears Soap", "Colgate Toothpaste", "Pepsodent Toothpaste",
    "Shampoo Sachet (Dove)", "Shampoo Sachet (Clinic Plus)", "Blue Ballpoint Pen", "Black Gel Pen", "Reynolds Trimax",
    "A4 Notebook 200pg", "Spiral Notebook", "Scientific Calculator", "Exam Pad", "Geometry Box",
    "A4 Paper Rim", "Fevistick", "Eraser & Sharpener Set", "Pencil Box", "Sticky Notes"
]

# Combine all lists
all_items_list = eateries + xerox + essentials

# Prepare for CSV
items = []
for i, name in enumerate(all_items_list, 1):
    items.append([i, name])

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['item_id', 'name'])
    writer.writerows(items)

print(full_path.lower())