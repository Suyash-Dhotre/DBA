---

# Q/A Interview 

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
