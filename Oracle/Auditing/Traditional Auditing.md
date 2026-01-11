# 📘 ORACLE AUDITING – COMPLETE SUMMARY (WITH COMMANDS)

---

## 🔐 Purpose of Auditing

* Track **who did what, when, and how**
* Ensure **security, accountability, compliance**
* Detect **unauthorized or suspicious activities**

---

## 🧩 Types of Auditing in Oracle

---

## 1️⃣ Mandatory Auditing

* Always enabled
* Cannot be disabled
* Stored in **OS audit trail**
* Audits:

  * SYSDBA / SYSOPER logins
  * Database startup & shutdown

📌 **Location**

* Unix: `AUDIT_FILE_DEST`
* Windows: Event Viewer

---

## 2️⃣ Standard Database Auditing

* Enabled using `AUDIT` command
* Controlled by parameter `AUDIT_TRAIL`

### 🔧 Enable Auditing

```sql
SHOW PARAMETER audit_trail;

ALTER SYSTEM SET audit_trail = DB SCOPE=SPFILE;
ALTER SYSTEM SET audit_trail = DB_EXTENDED SCOPE=SPFILE;
ALTER SYSTEM SET audit_trail = OS SCOPE=SPFILE;

SHUTDOWN IMMEDIATE;
STARTUP;
```

### AUDIT_TRAIL Options

| Value        | Description           |
| ------------ | --------------------- |
| NONE / FALSE | Auditing disabled     |
| OS           | Records written to OS |
| DB           | Stored in `SYS.AUD$`  |
| DB_EXTENDED  | SQL text + binds      |
| XML          | XML audit files       |

---

## 🔁 Auditing Modes

### 🔹 BY SESSION

* One record **per session**
* Less audit data
* Default for **object auditing**

### 🔹 BY ACCESS

* One record **per action**
* More detailed
* Default for **system privileges**

---

## 🔄 Success / Failure Options

* `WHENEVER SUCCESSFUL`
* `WHENEVER NOT SUCCESSFUL`
* Default: both

---

## 3️⃣ Privilege Auditing (System Privileges)

### 🔧 Syntax

```sql
AUDIT privilege_name
[BY username]
[BY SESSION | BY ACCESS]
[WHENEVER SUCCESSFUL | WHENEVER NOT SUCCESSFUL];
```

### 🔧 Examples

```sql
AUDIT CREATE SESSION;
AUDIT CREATE SESSION BY hr BY ACCESS;
AUDIT UPDATE ANY TABLE BY hr BY SESSION;
AUDIT UPDATE ANY TABLE BY hr BY ACCESS WHENEVER SUCCESSFUL;
```

### 🔧 Disable Auditing

```sql
NOAUDIT CREATE SESSION;
NOAUDIT UPDATE ANY TABLE BY hr;
```

### 🔍 View Configuration

```sql
SELECT user_name, audit_option, success, failure
FROM DBA_STMT_AUDIT_OPTS;
```

---

## 4️⃣ Schema Object Auditing

### 🔧 Syntax

```sql
AUDIT object_privilege ON schema.object
[BY SESSION | BY ACCESS]
[WHENEVER SUCCESSFUL | WHENEVER NOT SUCCESSFUL];
```

### 🔧 Examples

```sql
AUDIT DELETE ON hr.emp2;
AUDIT DELETE ON hr.emp2 BY ACCESS;
AUDIT DELETE ON hr.emp2 BY SESSION WHENEVER NOT SUCCESSFUL;
```

### 🔧 Disable

```sql
NOAUDIT DELETE ON hr.emp2;
NOAUDIT ALL ON hr.emp2;
```

### 🔍 View Configuration

```sql
SELECT owner, object_name, object_type, ins, upd, del
FROM DBA_OBJ_AUDIT_OPTS;
```

Audit Flags:

* `S` → BY SESSION
* `A` → BY ACCESS
* `-` → Not audited

---

## 5️⃣ Viewing Audit Records

### 🔍 Standard Audit Trail

```sql
SELECT username, action_name, obj_name, timestamp
FROM DBA_AUDIT_TRAIL;
```

### 🔍 Failed Logins

```sql
SELECT username, terminal, timestamp
FROM DBA_AUDIT_SESSION
WHERE returncode <> 0;
```

### 🔍 SQL Text (DB_EXTENDED)

```sql
SELECT username, action_name, sql_text
FROM DBA_AUDIT_TRAIL;
```

---

## 6️⃣ SYSDBA Auditing

### 🔧 Enable

```sql
SHOW PARAMETER audit_sys_operations;

ALTER SYSTEM SET audit_sys_operations = TRUE SCOPE=SPFILE;
STARTUP FORCE;
```

📌 SYS audit records:

* Written to **OS**
* Not visible in `DBA_AUDIT_TRAIL`

---

## 7️⃣ Fine-Grained Auditing (FGA)

* Conditional auditing
* Audits **specific columns & rows**
* Captures **SQL + bind variables**

### 🔧 Create Policy

```sql
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'HR',
    object_name     => 'EMPLOYEES',
    policy_name     => 'audit_salary',
    audit_condition => 'department_id=10',
    audit_column    => 'SALARY',
    statement_types => 'SELECT,UPDATE'
  );
END;
/
```

### 🔍 View FGA Records

```sql
SELECT db_user, sql_text, timestamp
FROM DBA_FGA_AUDIT_TRAIL;
```

### 🔧 Drop Policy

```sql
EXEC DBMS_FGA.DROP_POLICY('HR','EMPLOYEES','audit_salary');
```

---

## 8️⃣ Value-Based Auditing (Triggers)

* Uses **PL/SQL triggers**
* Captures **OLD and NEW values**
* Works at **row level**

### 🔧 Example Trigger

```sql
CREATE OR REPLACE TRIGGER log_emp_trig
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
  INSERT INTO log_emp
  VALUES (:OLD.salary, :NEW.salary);
END;
```

---

## 9️⃣ Autonomous Transaction (For Audit Persistence)

### 🔧 Syntax

```sql
PRAGMA AUTONOMOUS_TRANSACTION;
```

### 🔧 Example

```sql
CREATE OR REPLACE TRIGGER log_emp_trig
AFTER UPDATE ON employees
FOR EACH ROW
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO log_emp VALUES (...);
  COMMIT;
END;
```

📌 Audit data persists even after rollback

---

## 🧹 Audit Maintenance

### 🔧 Manual Purge

```sql
DELETE FROM sys.aud$ WHERE userid = 'HR';
COMMIT;
```

### 🔧 PL/SQL Purge Procedure

```sql
DELETE FROM aud$ WHERE ntimestamp# < SYSDATE - 30;
COMMIT;
```
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
# 🧠 Quick Interview Points

* BY SESSION → 1 record per session
* BY ACCESS → 1 record per action
* SYS auditing → OS only
* FGA audits **result set**
* Triggers capture actual values
* DB_EXTENDED stores SQL text + binds

---

Q/A Interview 

Below are **Oracle Auditing Interview Q&A** — **clear, concise, and command-focused**.
These are commonly asked in **DBA (2–6 yrs)** interviews.

---

# 🔐 ORACLE AUDITING – INTERVIEW Q&A

---

## 1️⃣ What is Oracle Auditing?

**Answer:**
Oracle Auditing records database activities to track **who accessed what, when, and how**, helping in **security, compliance, and accountability**.

---

## 2️⃣ What are the types of auditing in Oracle?

**Answer:**

1. Mandatory Auditing
2. Standard Database Auditing
3. Fine-Grained Auditing (FGA)
4. Value-Based Auditing (Triggers)
5. SYSDBA Auditing
6. Unified Auditing (12c+)

---

## 3️⃣ What is Mandatory Auditing?

**Answer:**

* Always enabled
* Audits SYSDBA/SYSOPER logins, startup & shutdown
* Stored in **OS audit trail**
* Cannot be disabled

---

## 4️⃣ What is AUDIT_TRAIL parameter?

**Answer:**
Controls where audit records are stored.

```sql
SHOW PARAMETER audit_trail;
```

| Value       | Description               |
| ----------- | ------------------------- |
| NONE        | Auditing disabled         |
| OS          | OS audit files            |
| DB          | Stored in SYS.AUD$        |
| DB_EXTENDED | SQL text + bind variables |
| XML         | XML files                 |

---

## 5️⃣ Difference between BY SESSION and BY ACCESS?

| BY SESSION                  | BY ACCESS                     |
| --------------------------- | ----------------------------- |
| One record per session      | One record per action         |
| Less audit data             | More detailed                 |
| Default for object auditing | Default for system privileges |

📌 **Example**

```sql
AUDIT DELETE ON hr.emp2 BY SESSION;
AUDIT DELETE ON hr.emp2 BY ACCESS;
```

---

## 6️⃣ How do you enable database auditing?

**Answer:**

```sql
ALTER SYSTEM SET audit_trail = DB SCOPE=SPFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
```

---

## 7️⃣ How do you audit user logins?

**Answer:**

```sql
AUDIT CREATE SESSION;
AUDIT CREATE SESSION BY hr BY ACCESS;
```

---

## 8️⃣ How do you audit failed login attempts?

**Answer:**

```sql
AUDIT CREATE SESSION WHENEVER NOT SUCCESSFUL;
```

---

## 9️⃣ How do you audit a specific table?

**Answer:**

```sql
AUDIT SELECT, INSERT, UPDATE, DELETE ON hr.emp2;
```

---

## 🔟 How do you check audited activities?

**Answer:**

```sql
SELECT username, action_name, obj_name, timestamp
FROM DBA_AUDIT_TRAIL;
```

---

## 1️⃣1️⃣ Where are audit records stored?

**Answer:**

* DB → `SYS.AUD$`
* View → `DBA_AUDIT_TRAIL`
* SYS auditing → OS files

---

## 1️⃣2️⃣ How do you audit SYS user actions?

**Answer:**

```sql
ALTER SYSTEM SET audit_sys_operations = TRUE SCOPE=SPFILE;
STARTUP FORCE;
```

📌 Stored in **OS**, not in DBA_AUDIT_TRAIL

---

## 1️⃣3️⃣ What is Fine-Grained Auditing (FGA)?

**Answer:**

* Conditional auditing
* Audits specific columns & rows
* Captures SQL + bind variables
* Uses `DBMS_FGA`

---

## 1️⃣4️⃣ FGA example command?

```sql
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'HR',
    object_name     => 'EMPLOYEES',
    policy_name     => 'audit_salary',
    audit_condition => 'department_id=10',
    audit_column    => 'SALARY',
    statement_types => 'SELECT,UPDATE'
  );
END;
/
```

---

## 1️⃣5️⃣ Where are FGA records stored?

**Answer:**

```sql
SELECT * FROM DBA_FGA_AUDIT_TRAIL;
```

---

## 1️⃣6️⃣ Difference between Standard Auditing and FGA?

| Standard Auditing | FGA                  |
| ----------------- | -------------------- |
| Statement-based   | Conditional          |
| No data values    | Captures SQL + binds |
| All rows          | Selected rows        |

---

## 1️⃣7️⃣ What is Value-Based Auditing?

**Answer:**
Uses **triggers** to capture **OLD and NEW column values** during DML.

---

## 1️⃣8️⃣ Why use PRAGMA AUTONOMOUS_TRANSACTION?

**Answer:**

* Saves audit data even if main transaction rolls back
* Used inside triggers

```sql
PRAGMA AUTONOMOUS_TRANSACTION;
```

---

## 1️⃣9️⃣ What happens if DML fails—will trigger fire?

**Answer:**
❌ No.
AFTER triggers fire **only on successful DML**.

---

## 2️⃣0️⃣ How do you disable auditing?

**Answer:**

```sql
NOAUDIT CREATE SESSION;
NOAUDIT DELETE ON hr.emp2;
```

---

## 2️⃣1️⃣ How do you audit only successful actions?

**Answer:**

```sql
AUDIT UPDATE ON hr.emp2 WHENEVER SUCCESSFUL;
```

---

## 2️⃣2️⃣ How do you purge audit records?

**Answer:**

```sql
DELETE FROM sys.aud$ WHERE ntimestamp# < SYSDATE - 30;
COMMIT;
```

---

## 2️⃣3️⃣ What is DBA_COMMON_AUDIT_TRAIL?

**Answer:**
A **unified view** combining:

* Standard Auditing
* FGA
* Unified Auditing records

---

## 2️⃣4️⃣ What is Unified Auditing?

**Answer:**

* Introduced in 12c
* Centralized audit framework
* Uses audit policies
* Stored in `UNIFIED_AUDIT_TRAIL`

---

## 2️⃣5️⃣ Standard Auditing vs Unified Auditing?

| Standard         | Unified              |
| ---------------- | -------------------- |
| AUDIT command    | CREATE AUDIT POLICY  |
| SYS.AUD$         | Unified audit tables |
| Being deprecated | Recommended          |

---

## 🔚 One-Line Rapid Fire (Very Common)

* **BY SESSION** → 1 record per login
* **BY ACCESS** → 1 record per execution
* **SYS audit** → OS only
* **DB_EXTENDED** → SQL text + binds
* **FGA audits result set**
* **Triggers capture OLD/NEW values**

---




