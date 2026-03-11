import csv
import random
import os

# 1. Configuration
TOTAL_STUDENTS = 30
TOTAL_ROWS = 36
filename = 'student_account.csv'

# List of IDs to exclude (already used by vendors)
excluded_ids = {19, 39, 8, 11, 37, 24, 28, 35, 33, 49, 50, 7, 12, 10}

# 2. Generate available bankaccount_ids
# Assuming a reasonable range for student bank accounts (e.g., 100 to 500)
# to ensure they don't collide with the vendor range (1-50)
available_bank_ids = [i for i in range(100, 501) if i not in excluded_ids]
random.shuffle(available_bank_ids)

student_accounts = []
student_ids = list(range(1, TOTAL_STUDENTS + 1))

# 3. Step A: Ensure every student (1-30) has at least one account
for s_id in student_ids:
    b_id = available_bank_ids.pop()
    student_accounts.append([b_id, s_id])

# 4. Step B: Add the remaining 6 rows randomly
for _ in range(TOTAL_ROWS - TOTAL_STUDENTS):
    s_id = random.randint(1, TOTAL_STUDENTS)
    b_id = available_bank_ids.pop()
    student_accounts.append([b_id, s_id])

# 5. File Generation
script_dir = os.path.dirname(os.path.abspath(__file__))
full_path = os.path.join(script_dir, filename)

with open(full_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['bankaccount_id', 'student_id'])
    writer.writerows(student_accounts)

print(full_path.lower())