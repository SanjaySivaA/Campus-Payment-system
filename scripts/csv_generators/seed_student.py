import csv
import random
from faker import Faker

# Initialize Faker with the Indian locale
fake = Faker('en_IN')

# Prepare the data list
students = []

for student_id in range(1, 31):
    # Generate separate first and last names
    first_name = fake.first_name()
    last_name = fake.last_name()
    
    # Create a believable email address using both names
    email = f"{first_name.lower()}.{last_name.lower()}{student_id}@campus.edu"
    
    # Generate a realistic Indian phone number
    phone = fake.phone_number()
    
    # Generate a random account balance between 100 and 5000
    balance = round(random.uniform(100.0, 5000.0), 2)
    
    # Generate a dummy password hash
    password_hash = fake.sha256()[:15]
    
    # Append the row exactly in your new requested order
    students.append([student_id, first_name, last_name, email, phone, balance, password_hash])

# Write the data to a CSV file
filename = 'student.csv'
with open(filename, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    
    # Write the header with the updated columns
    writer.writerow(['student_id', 'first_name', 'last_name', 'email', 'phone', 'balance', 'password_hash'])
    
    # Write the 30 generated rows
    writer.writerows(students)

print(f"Successfully generated 30 realistic rows in {filename} with first and last names!")