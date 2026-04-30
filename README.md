# Campus-Payment-system
This is the repo for our DS3020 course project<br>
The documentation is added in `docs`<br>

### Instructions to handle the backup file
- [`campus_payment_backup.sql`](./campus_payment_backup.sql) is the backup script where we dump the latest version of db
- run
    ``` 
    dropdb campus_payment
    createdb campus_payment
    psql -U postgres -d campus_payment -f campus_payment_backup.sql 
    ```
    no conflicts will be there since the old local db is dropped and new one is created 
- this may add new functions, views, indexes etc. to your database and you may lose existing ones (stash them)
- add the objects in [`functions.sql`](./app/functions.sql), [`queries.sql`](./app/queries.sql) and [`views.sql`](./app/views.sql) to your local db if any relevant objects are missed in the dump file (cross check using `\df`, `\dv`, `\dt`,`\di`).<br> This can be done by `psql -U postgres -d campus_payment -f file_name.sql`
- it is recommended to use `CREATE OR REPLACE...` for object definitions to minimize conflicts

