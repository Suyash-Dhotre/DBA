Here is a **clear production-level step-by-step guide** for **Oracle Standalone Database Patching (Non-RAC)**.

I’ll explain for **Oracle 19c (most common)** using **RU patching with OPatch**.

---

# 🔹 Types of Oracle Patches

* **RU (Release Update)** → Recommended (quarterly patch)
* **RUR** → Patch on top of RU
* **One-off patch**
* **OJVM patch** (Java VM patch)

For production → Always apply latest **RU**.

---

# 🔹 Pre-Checks (Very Important)

## 1️⃣ Check Current Version

```sql
SELECT * FROM v$version;
```

## 2️⃣ Check OPatch Version

```bash
$ORACLE_HOME/OPatch/opatch version
```

Compare with MOS required version.

---

## 3️⃣ Take Backup (Mandatory)

✔ RMAN full backup
✔ ORACLE_HOME backup (tar or filesystem snapshot)
✔ Backup spfile & password file

Example:

```bash
tar -cvf oracle_home_backup.tar $ORACLE_HOME
```

---

## 4️⃣ Check Invalid Objects

```sql
SELECT owner, object_name, object_type
FROM dba_objects
WHERE status='INVALID';
```

---

## 5️⃣ Check Space

Ensure:

* ORACLE_HOME has enough space
* /tmp has space

---

# 🔹 Patching Steps (Standalone DB)

---

## 🛑 Step 1: Stop Listener

```bash
lsnrctl stop
```

---

## 🛑 Step 2: Shutdown Database

```sql
SHUTDOWN IMMEDIATE;
```

---

## 🛑 Step 3: Stop All Oracle Services (if Linux systemctl)

Optional but recommended:

```bash
ps -ef | grep pmon
```

---

## 🔹 Step 4: Unzip Patch

```bash
unzip pXXXXXX_190000_Linux-x86-64.zip
cd 34765931   # example patch directory
```

---

## 🔹 Step 5: Check Conflicts

```bash
$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./
```

If no conflicts → proceed.

---

## 🔹 Step 6: Apply Patch

```bash
$ORACLE_HOME/OPatch/opatch apply
```

Type `y` when prompted.

Wait until:

```
OPatch succeeded.
```

---

## 🔹 Step 7: Start Database in Upgrade Mode

```sql
STARTUP UPGRADE;
```

---

## 🔹 Step 8: Run datapatch (VERY IMPORTANT)

```bash
$ORACLE_HOME/OPatch/datapatch -verbose
```

This updates database SQL components.

---

## 🔹 Step 9: Restart Normally

```sql
SHUTDOWN IMMEDIATE;
STARTUP;
```

---

## 🔹 Step 10: Check Patch Applied

```sql
SELECT action, status, version, bundle_series
FROM dba_registry_sqlpatch;
```

Or:

```bash
$ORACLE_HOME/OPatch/opatch lspatches
```

---

# 🔹 Post Checks

✔ Check invalid objects

```sql
@?/rdbms/admin/utlrp.sql
```

✔ Check alert log
✔ Test application



# List all files held by the 'oracle' user
lsof -u oracle

# Filter for a specific database name or path
lsof | grep <DB_NAME>


