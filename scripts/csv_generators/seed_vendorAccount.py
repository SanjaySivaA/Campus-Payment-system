import csv
import random
import os

# 1. Configuration
TOTAL_UNIQUE_BANK_IDS = 50
VENDORS = list(range(1, 11))
filename = 'vendor_account.csv'

# 2. Preparation
# Create a list of all possible bankaccount_ids (1-50) and shuffle them
all_bank_ids = list(range(1, TOTAL_UNIQUE_BANK_IDS + 1))
random.shuffle(all_bank_ids)

vendor_accounts = []

# 3. Step A: Ensure EVERY vendor has at least one account
for v_id in VENDORS:
    b_id = all_bank_ids.pop() # Pull a unique bank ID
    vendor_accounts.append([b_id, v_id])

# 4. Step B: Distribute remaining bank IDs randomly
# This creates the "random fashion" where some vendors get several accounts
while all_bank_ids:
    v_id = random.choice(VENDORS)
    b_id = all_bank_ids.pop()
    vendor_accounts.append([b_id, v_id])

# 5. File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['bankaccount_id', 'vendor_id'])
    writer.writerows(vendor_accounts)

print(f"Generated {len(vendor_accounts)} records in {full_path.lower()}")