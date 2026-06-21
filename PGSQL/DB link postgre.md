---
sudo dnf install postgresql17-contrib
---
# 🔗 1. What is DB Link (in simple terms)?

A DB link means:

> Connecting one database to another database and running queries remotely.

---

# 🧩 2. Option 1: `dblink` (Classic way)

## ✔ Enable extension

```sql
CREATE EXTENSION dblink;
```

---

## ✔ Example usage

```sql
SELECT *
FROM dblink(
    'host=192.168.1.10 dbname=remote_db user=postgres password=pass',
    'SELECT id, name FROM employees'
) AS t(id INT, name TEXT);
```

---

## ✔ Key points

* Easy to use
* No need to create foreign tables
* Good for small queries
* Not best for performance-heavy systems

---

# 🚀 3. Option 2: `postgres_fdw` (Recommended)

This is the modern and best approach in PostgreSQL.

PostgreSQL supports **Foreign Data Wrapper (FDW)** which is more powerful than DB link.

---

## ✔ Step 1: Enable extension

```sql
CREATE EXTENSION postgres_fdw;
```

---

## ✔ Step 2: Create foreign server

```sql
CREATE SERVER remote_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host '192.168.1.10', dbname 'remote_db', port '5432');
```

---

## ✔ Step 3: Create user mapping

```sql
CREATE USER MAPPING FOR postgres
SERVER remote_server
OPTIONS (user 'postgres', password 'pass');
```

---

## ✔ Step 4: Import table OR create foreign table

### Import all tables:

```sql
IMPORT FOREIGN SCHEMA public
FROM SERVER remote_server
INTO public;
```

---

### OR manually create foreign table:

```sql
CREATE FOREIGN TABLE employees (
    id INT,
    name TEXT
)
SERVER remote_server
OPTIONS (table_name 'employees');
```

---

## ✔ Step 5: Query like normal table

```sql
SELECT * FROM employees;
```

---

# ⚖️ 4. dblink vs postgres_fdw

| Feature      | dblink         | postgres_fdw                   |
| ------------ | -------------- | ------------------------------ |
| Setup        | Easy           | Slightly complex               |
| Performance  | Medium         | High                           |
| Table access | Manual queries | Direct table access            |
| Best use     | Small tasks    | Production / replication style |
| Optimization | Limited        | Full planner support           |

---
