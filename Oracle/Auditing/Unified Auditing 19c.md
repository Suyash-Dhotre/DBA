# 🔐 Unified Auditing in Oracle 19c – Notes Summary (With Commands)

---

## 🧠 What is Unified Auditing?

* Oracle’s **modern auditing framework**
* Centralizes all audit records into **AUDSYS.AUD$UNIFIED**
* Replaces traditional auditing (`SYS.AUD$`, OS files, XML)
* Uses **policy-based auditing**
* Supports auditing of **SYS and privileged users**

---

## 🚀 Benefits of Unified Auditing

* Centralized audit log management
* Better performance (single optimized table)
* Policy-based & conditional auditing
* Built-in compliance support (SOX, GDPR, HIPAA)
* Easier purge & maintenance
* Audits SYS operations natively

---

## 🧪 Step 1: Check Unified Auditing Status

```sql
SELECT value 
FROM v$option 
WHERE parameter = 'Unified Auditing';
```

* `FALSE` → Unified Auditing not enabled
* `TRUE` → Enabled

Check traditional auditing:

```sql
SHOW PARAMETER audit_trail;
```

Typical output:

```
audit_trail = DB
```

---

## ⚙️ Step 2: Disable Traditional Auditing

```sql
ALTER SYSTEM SET audit_trail = 'NONE' SCOPE=SPFILE;
SHUTDOWN IMMEDIATE;
```

📌 Required before enabling unified auditing at binary level.

---

## 🔧 Step 3: Enable Unified Auditing (Binary Relink)

Login as **oracle OS user**:

```bash
cd $ORACLE_HOME/rdbms/lib
make -f ins_rdbms.mk uniaud_on ioracle
```

Start database:

```sql
STARTUP;
```

Verify:

```sql
SELECT value 
FROM v$option 
WHERE parameter = 'Unified Auditing';
```

✔ Output should be `TRUE`

---

## 🗃️ Step 4: Move Unified Audit Trail to Dedicated Tablespace

### Create tablespace

```sql
CREATE TABLESPACE audit_data 
DATAFILE '/usr/app/datafiles/CENTRALDB/audit_data.dbf'
SIZE 11M;
```

### Move Unified Audit Trail

```sql
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_location_value => 'AUDIT_DATA'
  );
END;
/
```

### Verify

```sql
SELECT owner, table_name, def_tablespace_name
FROM dba_part_tables
WHERE owner = 'AUDSYS';
```

---

## 👤 Step 5: Create Audit Viewer User

```sql
CREATE USER c##auditor IDENTIFIED BY Welcome_123;

GRANT CREATE SESSION,
      SELECT ANY DICTIONARY,
      SELECT ANY TABLE
TO c##auditor;

GRANT AUDIT_VIEWER TO c##auditor;
```

Test access:

```sql
CONNECT c##auditor/Welcome_123;

SELECT COUNT(*) 
FROM audsys.unified_audit_trail;
```

---

## 🧹 Step 6: Purge Unified Audit Data

### Grant purge privilege

```sql
GRANT AUDIT_ADMIN TO c##auditor;
```

### Manual purge

```sql
BEGIN
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type        => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE,
    container               => DBMS_AUDIT_MGMT.CONTAINER_CURRENT
  );
END;
/
```

---

### 🔁 Automate Purging (Scheduler Job)

```sql
BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_purge_interval => 2,
    audit_trail_purge_name     => 'Unified_Audit_Trail_Purge_Job',
    use_last_arch_timestamp    => TRUE,
    container                  => DBMS_AUDIT_MGMT.CONTAINER_CURRENT
  );
END;
/
```

---

## 🛡️ Step 7: Create Custom Audit Policy

### Create policy

```sql
CREATE AUDIT POLICY policy_for_auditor
  PRIVILEGES CREATE TABLE
  WHEN 'SYS_CONTEXT("USERENV","SESSION_USER") = ''C##AUDITOR'''
  EVALUATE PER SESSION
  CONTAINER = CURRENT;
```

### Enable policy

```sql
AUDIT POLICY policy_for_auditor;
```

---

## 🔎 Step 8: View & Analyze Unified Audit Logs

### View audit records

```sql
SELECT event_timestamp,
       dbusername,
       action_name,
       object_schema,
       object_name
FROM unified_audit_trail
WHERE dbusername = 'C##AUDITOR';
```

### Check enabled policies

```sql
SELECT policy_name,
       enabled_option,
       entity_name,
       success,
       failure
FROM audit_unified_enabled_policies
WHERE policy_name = 'POLICY_FOR_AUDITOR';
```

### Filter last 7 days

```sql
SELECT action_name,
       event_timestamp,
       object_schema,
       object_name
FROM unified_audit_trail
WHERE event_timestamp >= SYSTIMESTAMP - INTERVAL '7' DAY
ORDER BY event_timestamp DESC;
```

---

## 🧾 Unified vs Traditional Auditing (Quick Table)

| Feature      | Traditional | Unified   |
| ------------ | ----------- | --------- |
| Centralized  | ❌           | ✅         |
| Policy-based | ❌           | ✅         |
| SYS auditing | Partial     | Full      |
| SQL & binds  | Limited     | Native    |
| Purge        | Manual      | Automated |
| Compliance   | Weak        | Strong    |

---

## ⚠️ Important Notes (Exam / Interview)

* ❌ Cannot truncate `AUDSYS.AUD$UNIFIED`
* ✔ Always use `DBMS_AUDIT_MGMT` for purge
* ✔ Separate tablespace is best practice
* ✔ Unified auditing is **future-proof**
* ✔ Traditional auditing is deprecated

---

## 🧠 One-Line Interview Summary

> *Unified Auditing in Oracle 19c provides centralized, policy-based auditing using the AUDSYS.AUD$UNIFIED table, improving security, performance, and compliance compared to traditional auditing.*

---



<br>
<br>
<br>
<br>
<br>
<br>

-----

# 🔐 Disable Unified Auditing

(Oracle On-Prem vs AWS RDS)

---

## 1️⃣ On-Prem Oracle (Bare Metal / VM)

### ✅ You **CAN disable** Unified Auditing on-prem

### 🔍 First check current mode

```sql
SELECT value
FROM v$option
WHERE parameter = 'Unified Auditing';
```

| Result | Meaning                           |
| ------ | --------------------------------- |
| TRUE   | Unified auditing compiled/enabled |
| FALSE  | Disabled at binary level          |

---

## 🔴 Case A: Database in **Mixed Mode** (Most common)

👉 Unified auditing is enabled but **traditional auditing still exists**

### ✅ Disable Unified Auditing (switch back to traditional)

#### Step 1: Shutdown database

```bash
sqlplus / as sysdba
SHUTDOWN IMMEDIATE;
```

#### Step 2: Relink Oracle binary

```bash
cd $ORACLE_HOME/rdbms/lib
make -f ins_rdbms.mk uniaud_off ioracle
```

#### Step 3: Start database

```bash
STARTUP;
```

#### Step 4: Verify

```sql
SELECT value
FROM v$option
WHERE parameter = 'Unified Auditing';
```

✔ Should return `FALSE`

---

## 🔴 Case B: Database in **Pure Unified Auditing Mode**

⚠️ Traditional auditing **cannot be used at all** until unified auditing is disabled.

Steps are **same as above**:

```bash
make -f ins_rdbms.mk uniaud_off ioracle
```

---

## 🧠 Important Notes (On-Prem)

| Item               | Info                      |
| ------------------ | ------------------------- |
| Restart required   | ✅ Yes                     |
| OS access required | ✅ Yes                     |
| AUD$UNIFIED data   | Remains unless purged     |
| Traditional audit  | Works again after disable |

---

## 2️⃣ AWS RDS for Oracle

### ❌ You **CANNOT disable Unified Auditing** in RDS

#### Why?

* No OS access
* No `$ORACLE_HOME`
* Binary relinking not allowed
* Oracle manages the database engine

---

## 🔍 What *can* you control in RDS?

| Control                      | Allowed? |
| ---------------------------- | -------- |
| Disable unified auditing     | ❌ No     |
| Create/Drop audit policies   | ✅ Yes    |
| Disable traditional auditing | ✅ Yes    |
| Purge audit records          | ✅ Yes    |

---

## ⚙️ RDS: Best Possible Alternative

### Disable traditional auditing (recommended)

```sql
ALTER SYSTEM SET audit_trail = NONE SCOPE=BOTH;
```

(Through RDS parameter group)

---

### Disable Unified Audit Policies (effectively “off”)

```sql
NOAUDIT POLICY rds_login_audit;
```

or drop policy:

```sql
DROP AUDIT POLICY rds_login_audit;
```

➡ This **stops audit generation**, but unified auditing engine still exists.

---

### Verify Unified Auditing (Always ON in RDS)

```sql
SELECT value
FROM v$option
WHERE parameter = 'Unified Auditing';
```

✔ Always `TRUE`

---

## 🆚 On-Prem vs RDS (Interview Table)

| Feature                  | On-Prem | AWS RDS     |
| ------------------------ | ------- | ----------- |
| Disable unified auditing | ✅ Yes   | ❌ No        |
| Binary relinking         | ✅ Yes   | ❌ No        |
| `uniaud_off`             | Allowed | Not allowed |
| Control audit policies   | ✅ Yes   | ✅ Yes       |
| Restart required         | Yes     | No          |

---

## 🎯 Interview One-Liner (Must Remember)

> **Unified auditing can be disabled on-prem by relinking Oracle binaries using `uniaud_off`, but in AWS RDS unified auditing cannot be disabled—only audit policies can be turned off.**

---

<br>
<br>
<br>
<br>
<br>
<br>

---

# 🔧 1️⃣ What does

```bash
make -f ins_rdbms.mk uniaud_on ioracle
```

**actually do?**

---

## 📌 Background (Why this command exists)

Oracle supports **two modes** of Unified Auditing:

1. **Mixed Mode (default in many installs)**

   * Traditional auditing + unified auditing both exist
   * Unified auditing **not fully enforced**
   * SYS actions may still go to OS

2. **Pure Unified Auditing Mode**

   * Traditional auditing completely disabled
   * All auditing goes to **AUDSYS.AUD$UNIFIED**
   * Required for **full compliance**

⚠️ Oracle binaries are compiled **without pure unified auditing by default** in many installations.

---

## 🔍 What this command does internally

```bash
make -f ins_rdbms.mk uniaud_on ioracle
```

| Part              | Meaning                                  |
| ----------------- | ---------------------------------------- |
| `make`            | GNU build tool                           |
| `-f ins_rdbms.mk` | Uses Oracle’s RDBMS makefile             |
| `uniaud_on`       | Target that **enables unified auditing** |
| `ioracle`         | Rebuilds the Oracle database executable  |

---

## 🧠 In simple words

> **This command relinks the Oracle binary to permanently enable Pure Unified Auditing.**

It:

* Links Oracle executable with unified auditing libraries
* Disables traditional auditing at binary level
* Forces all audit records into `AUD$UNIFIED`
* Makes Unified Auditing **non-optional**

---

## 🔴 Why database restart is required?

Because:

* You are **changing the Oracle executable**
* Memory & background processes must reload new binaries

---

## 📌 When do you need this command?

| Scenario                  | Required?          |
| ------------------------- | ------------------ |
| Fresh 19c install         | Sometimes          |
| Upgraded DB (11g/12c)     | ✅ YES              |
| On-prem / VM / Bare metal | ✅ YES              |
| Oracle Cloud / RDS        | ❌ NO (not allowed) |

---

# ☁️ 2️⃣ Unified Auditing in AWS RDS (Very Important)

---

## ❌ Can you run `make -f ins_rdbms.mk uniaud_on ioracle` in RDS?

### 🚫 NO — NEVER

Reasons:

* No OS access in RDS
* No `$ORACLE_HOME`
* No permission to relink binaries
* Managed Oracle service

---

## ✅ How Unified Auditing works in RDS

✔ Unified Auditing is **already enabled in Mixed Mode**
✔ Oracle controls binaries
✔ You can **USE** unified auditing, not **recompile** it

---

## 🔍 Check Unified Auditing in RDS

```sql
SELECT value
FROM v$option
WHERE parameter = 'Unified Auditing';
```

✔ Always returns `TRUE` in RDS

---

## ⚙️ Enable / Use Unified Auditing in RDS (Correct Way)

### 1️⃣ Disable traditional auditing (optional but recommended)

```sql
ALTER SYSTEM SET audit_trail = NONE SCOPE=BOTH;
```

(RDS allows this via parameter group)

---

### 2️⃣ Verify Unified Audit Trail

```sql
SELECT COUNT(*)
FROM unified_audit_trail;
```

---

### 3️⃣ Create Unified Audit Policy

```sql
CREATE AUDIT POLICY rds_login_audit
  ACTIONS LOGON, LOGOFF;
```

Enable it:

```sql
AUDIT POLICY rds_login_audit;
```

---

### 4️⃣ Audit DDL / Privileges

```sql
CREATE AUDIT POLICY ddl_audit
  PRIVILEGES CREATE TABLE, DROP TABLE;

AUDIT POLICY ddl_audit;
```

---

### 5️⃣ View Audit Records

```sql
SELECT event_timestamp,
       dbusername,
       action_name
FROM unified_audit_trail
ORDER BY event_timestamp DESC;
```

---

## 🧹 Purging Unified Audit in RDS

✔ Allowed (with restrictions)

```sql
BEGIN
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED
  );
END;
/
```

---

## 🆚 On-Prem vs RDS (Interview Gold)

| Feature          | On-Prem            | RDS             |
| ---------------- | ------------------ | --------------- |
| OS access        | Yes                | No              |
| Binary relink    | Yes                | No              |
| `uniaud_on`      | Required           | Not allowed     |
| Unified Auditing | Pure mode possible | Mixed mode only |
| AUD$UNIFIED      | Yes                | Yes             |

---

## 🧠 Interview One-Liner (Very Important)

> **In on-prem Oracle, `make -f ins_rdbms.mk uniaud_on ioracle` relinks the Oracle binary to enable pure unified auditing, while in AWS RDS unified auditing is already enabled in mixed mode and binary relinking is not permitted.**




