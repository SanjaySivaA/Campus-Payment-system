import csv
import os

# Configuration
filename = 'admin.csv'

# Exact data from your database dump to maintain consistency
admin_data = [
    [1, "Rahul", "Desai", "e99a18c428cb38d5f260853678922e03"],
    [2, "Priya", "Menon", "87d9bb400c0634691f0e3baaf1e2fd0d"],
    [3, "Amit", "Singhania", "a3f0f7ee1b82e2e7b85ccb6b7a5a3a41"],
    [4, "Neha", "Reddy", "c4ca4238a0b923820dcc509a6f75849b"],
    [5, "Vikram", "Malhotra", "c81e728d9d4c2f636f067f89cc14862c"]
]

# File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    # Header matching your table columns
    writer.writerow(['admin_id', 'first_name', 'last_name', 'password_hash'])
    writer.writerows(admin_data)

print(f"File generated at: {full_path.lower()}")