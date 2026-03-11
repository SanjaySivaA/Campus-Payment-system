import psycopg2
from psycopg2 import sql
import os
import csv
import sys

# 1. Database connection parameters
DB_HOST = "localhost"
DB_NAME = "campus_payment"
DB_USER = "postgres"
DB_PASS = "postgres123"
DB_PORT = "5432"

conn = None
cursor = None

try:
    # 2. Check for the command line argument
    if len(sys.argv) < 2:
        print("USAGE: python3 db_seed.py <filename.csv>")
        sys.exit(1)

    # The first argument after the script name is the file path
    csv_file_path = sys.argv[1].strip()

    # 3. Deduce table name from the file name
    # Extracts 'Vendor' from 'scripts/Vendor.csv' or just 'Vendor.csv'
    file_base = os.path.basename(csv_file_path)
    table_name = os.path.splitext(file_base)[0]

    # Establish the connection
    conn = psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        port=DB_PORT
    )
    cursor = conn.cursor()
    
    # 4. Process the file
    if os.path.exists(csv_file_path):
        with open(csv_file_path, 'r', encoding='utf-8') as f:
            # Dynamically read columns from the header
            csv_reader = csv.reader(f)
            columns = next(csv_reader)
            
            # Reset file pointer to the beginning for the COPY command
            f.seek(0)
            
            # 5. Construct the COPY query
            # Uses sql.Identifier to safely handle the table and column names
            copy_query = sql.SQL("COPY {table} ({fields}) FROM STDIN WITH CSV HEADER DELIMITER ','").format(
                table=sql.Identifier(table_name),
                fields=sql.SQL(', ').join(map(sql.Identifier, columns))
            )
            
            print(f"Reading from: {csv_file_path}")
            print(f"Targeting table: {table_name}")
            
            # Perform the bulk import
            cursor.copy_expert(sql=copy_query, file=f)
            
            conn.commit()
            print(f"SUCCESS: Successfully imported data into '{table_name}'.")
    else:
        print(f"ERROR: File '{csv_file_path}' not found.")

except psycopg2.Error as e:
    if conn:
        conn.rollback()
    print(f"Database error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
finally:
    if cursor:
        cursor.close()
    if conn:
        conn.close()