## MVP

### Deliverables: 

#### Implementation
- The project should contain **at least 3 roles and 3 views**.
- The project should contain **at least 5 functions ( at least 1 function for each role), and 4 triggers.**
- Accessing the functions through a frontend will be commendable.
- Please prepare **at least 5 queries that use different functions and roles and indices**.

#### Final Report Content
- Final Report must contain the following points in pdf. (You can extend your mid term report. Do not repeat the screenshot for the data population)
- Title page with names of the group members and their roll numbers
- Relational design of your database (relations with attribute names, keys, connections) 
- All integrity constraints and general constraints with a brief description
- List of all functions and triggers and how they help in preserving the consistency of the database
- All Roles and list of privileges given to them
- List of views and justification for creating them.
- List of all indices that are created additionally besides default indices. Also, mention a few frequent queries that use those indices. 

### Tentative Tech stack
- FastAPI + psychopg + sqlalchemy for ORM
- some frontend stack

### Roles (3)
- ADMIN
- STUDENT
- VENDOR

Limit function access to specific role(s)

### Functions (5)
- Approve settlement      :  ADMIN
    - Dummy API Call to Bank 
    - update `settlement_status`
- Purchase history        :  STUDENT
- Compare prices          :  STUDENT
- Request Settlement      :  VENDOR
    - TRIGGER on Bill table to update `settlement_id`
- Issue Bill              : VENDOR
    - Update `balance` of student
    

### Queries (5)
- Authentication
- and more

### Split
- init fastapi backend, connector and ORM
- 1 view + one function + 2 trigger
- 1 view + two function + 1 trigger
- 1 view + two function + 1 trigger

## TODO 
- 5 queries using functions implemented for specific roles + appropriate indexes for the queries
- 3 roles + privileges
- Auth
- curate db if needed
- frontend

## Indexes
- Construct appropriate indexes and use it to optimize query execution
- make use of : **Range queries <-> Btree index**. One of our queries can be a range query on some relation returned by a function.