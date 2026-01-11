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

# 🧠 Quick Interview Points

* BY SESSION → 1 record per session
* BY ACCESS → 1 record per action
* SYS auditing → OS only
* FGA audits **result set**
* Triggers capture actual values
* DB_EXTENDED stores SQL text + binds






