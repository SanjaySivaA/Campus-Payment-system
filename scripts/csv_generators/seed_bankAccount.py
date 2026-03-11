import csv
import random
import string

# A list of real Indian banks and their standard 4-letter IFSC prefixes
banks = [
    ("State Bank of India", "SBIN"),
    ("HDFC Bank", "HDFC"),
    ("ICICI Bank", "ICIC"),
    ("Axis Bank", "UTIB"),
    ("Punjab National Bank", "PUNB"),
    ("Bank of Baroda", "BARB"),
    ("Canara Bank", "CNRB"),
    ("Kotak Mahindra Bank", "KKBK"),
    ("Union Bank of India", "UBIN"),
    ("IndusInd Bank", "INDB")
]

# Prepare the data list
bank_accounts = []

for bankaccount_id in range(1, 51):
    # Randomly pick a bank and its prefix
    bank_name, ifsc_prefix = random.choice(banks)
    
    # Generate a realistic account number (typically 10 to 16 digits in India)
    account_no = ''.join(random.choices(string.digits, k=random.randint(10, 16)))
    
    # Generate a standard 11-character IFSC code:
    # 4-letter bank code + '0' + 6-digit branch code
    branch_code = ''.join(random.choices(string.digits, k=6))
    ifsc_code = f"{ifsc_prefix}0{branch_code}"
    
    # Append the row in the exact order requested
    bank_accounts.append([bankaccount_id, bank_name, account_no, ifsc_code])

# Write the data to a CSV file
filename = 'bankaccount.csv'
with open(filename, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    
    # Write the header
    writer.writerow(['bankaccount_id', 'bank_name', 'account_no', 'ifsc_code'])
    
    # Write the 30 generated rows
    writer.writerows(bank_accounts)

print(f"Successfully generated 30 realistic rows in {filename}!")