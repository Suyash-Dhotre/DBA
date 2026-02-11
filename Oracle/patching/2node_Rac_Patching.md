# ✅ PHASE 1 — Pre-Checks (Mandatory)

Run on any node:

### 1️⃣ Check CRS Health

```bash
crsctl check cluster -all
crsctl stat res -t
```

All resources must be ONLINE.

---

### 2️⃣ Check GI Version

```bash
crsctl query crs softwareversion
```

---

### 3️⃣ Backup OCR

```bash
ocrconfig -showbackup
```

Manual backup:

```bash
ocrconfig -manualbackup
```

---

### 4️⃣ Check ASM Diskgroup Space

```bash
asmcmd lsdg
```

---

### 5️⃣ Check OPatch Version (Both Homes)

```bash
$GRID_HOME/OPatch/opatch version
$ORACLE_HOME/OPatch/opatch version
```

---

# 🚀 PHASE 2 — Rolling GI Patching (Using opatchauto)

We patch Node1 first.

---

# 🔹 Step 1 — Move Services to Node2

```bash
srvctl relocate service -d dbname -s service_name -i dbname1 -t dbname2
```

Stop DB instance on Node1:

```bash
srvctl stop instance -d dbname -i dbname1
```

---

# 🔹 Step 2 — Apply GI Patch on Node1

Unzip patch.

Then run:

```bash
cd patch_dir
$GRID_HOME/OPatch/opatchauto apply
```

This will:

* Stop CRS on Node1
* Patch GI
* Restart CRS

Wait until:

```
OPatchauto successful
```

---

# 🔹 Step 3 — Verify Node1

```bash
crsctl stat res -t
```

Make sure:

* ASM running
* Listener running
* Node1 back online

---

# 🔹 Step 4 — Repeat on Node2

Move services back if needed.

Then on Node2:

```bash
$GRID_HOME/OPatch/opatchauto apply
```

Wait until complete.

---

# ✅ PHASE 3 — Patch Database Home (Rolling)

After BOTH GI nodes patched.

---

### On Node1

```bash
srvctl stop instance -d dbname -i dbname1
cd db_patch_dir
$ORACLE_HOME/OPatch/opatch apply
srvctl start instance -d dbname -i dbname1
```

---

### On Node2

Same steps.

---

# ✅ PHASE 4 — Run datapatch (IMPORTANT)

After both DB homes patched:

Run from ONE node only:

```bash
$ORACLE_HOME/OPatch/datapatch -verbose
```

---

# ✅ PHASE 5 — Post Checks

```sql
SELECT action, status, version FROM dba_registry_sqlpatch;
```

Check cluster:

```bash
crsctl stat res -t
```

Recompile invalid objects:

```sql
@?/rdbms/admin/utlrp.sql
```

---

# 🔥 Enterprise Best Practice

✔ Use out-of-place patching (recommended in 19c)
✔ Ensure patch is rolling applicable
✔ Patch standby cluster first (if Data Guard exists)
✔ Keep maintenance window ready

---

# 🚨 Common Mistakes

❌ Not relocating services
❌ Patching DB before GI
❌ Forgetting datapatch
❌ Not checking CRS after first node

---

# 🧠 Real DBA Tip

Check if patch is rolling supported:

```bash
opatchauto apply -analyze
```

This shows if patch can be applied rolling.
