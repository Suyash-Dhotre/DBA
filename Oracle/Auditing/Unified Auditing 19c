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

