# 📊 Oracle Data Pump Parameters Table (EXPDP & IMPDP)

## 1️⃣ Common Parameters (Used in BOTH EXPDP & IMPDP)

| Parameter         | Possible Values          | Used In | Purpose / When to Use                  |
| ----------------- | ------------------------ | ------- | -------------------------------------- |
| `DIRECTORY`       | Directory object name    | Both    | **Mandatory** – location of dump files |
| `DUMPFILE`        | `file.dmp`, `exp_%U.dmp` | Both    | Dump file name (`%U` for parallel)     |
| `LOGFILE`         | `exp.log`                | Both    | Log file for job                       |
| `PARALLEL`        | `1–128`                  | Both    | Improve performance                    |
| `JOB_NAME`        | Any string               | Both    | Name job for monitoring                |
| `REUSE_DUMPFILES` | `YES / NO`               | Both    | Overwrite existing dump                |
| `STATUS`          | seconds (e.g. `60`)      | Both    | Display job progress                   |
| `CLUSTER`         | `YES / NO`               | Both    | RAC control                            |

---

## 2️⃣ EXPDP (Export) Parameters

| Parameter             | Values Allowed                           | Purpose / When Used         |
| --------------------- | ---------------------------------------- | --------------------------- |
| `FULL`                | `Y / N`                                  | Full database export        |
| `SCHEMAS`             | `HR,SCOTT`                               | Export specific schemas     |
| `TABLES`              | `HR.EMP,HR.DEPT`                         | Export tables               |
| `TABLESPACES`         | `USERS`                                  | Export tablespace           |
| `CONTENT`             | `ALL / DATA_ONLY / METADATA_ONLY`        | Control data vs metadata    |
| `COMPRESSION`         | `ALL / DATA_ONLY / METADATA_ONLY / NONE` | Reduce dump size            |
| `ENCRYPTION`          | `ALL / DATA_ONLY / METADATA_ONLY`        | Encrypt dump                |
| `ENCRYPTION_PASSWORD` | Password                                 | Required if encryption used |
| `FLASHBACK_TIME`      | `SYSTIMESTAMP`                           | Consistent export           |
| `FLASHBACK_SCN`       | SCN number                               | Point-in-time export        |
| `FILESIZE`            | `5G`, `10G`                              | Split large dumps           |
| `EXCLUDE`             | `INDEX,STATISTICS`                       | Skip objects                |
| `INCLUDE`             | `TABLE,VIEW`                             | Include objects             |
| `QUERY`               | SQL WHERE clause                         | Row filtering               |
| `ESTIMATE`            | `BLOCKS / STATISTICS`                    | Size estimate               |
| `ESTIMATE_ONLY`       | `YES / NO`                               | Estimate without export     |

---

## 3️⃣ IMPDP (Import) Parameters

| Parameter             | Values Allowed                       | Purpose / When Used    |
| --------------------- | ------------------------------------ | ---------------------- |
| `SCHEMAS`             | `HR`                                 | Import schemas         |
| `TABLES`              | `HR.EMP`                             | Import tables          |
| `FULL`                | `Y / N`                              | Full import            |
| `CONTENT`             | `ALL / DATA_ONLY / METADATA_ONLY`    | Control import content |
| `REMAP_SCHEMA`        | `HR:HR_NEW`                          | Schema rename          |
| `REMAP_TABLESPACE`    | `USERS:DATA_TS`                      | Tablespace change      |
| `TABLE_EXISTS_ACTION` | `SKIP / APPEND / REPLACE / TRUNCATE` | If table exists        |
| `TRANSFORM`           | `DISABLE_ARCHIVE_LOGGING:Y`          | Improve speed          |
| `EXCLUDE`             | `INDEX,CONSTRAINT`                   | Skip objects           |
| `INCLUDE`             | `TABLE`                              | Selective import       |
| `DATA_OPTIONS`        | `SKIP_CONSTRAINT_ERRORS`             | Ignore errors          |
| `PARALLEL`            | `1–128`                              | Faster import          |
| `NETWORK_LINK`        | DB link name                         | Direct DB→DB import    |

---

## 4️⃣ RDS-Specific Parameters & Rules

| Item           | Value                  |
| -------------- | ---------------------- |
| Directory      | `DATA_PUMP_DIR` (ONLY) |
| User           | `admin`                |
| OS Access      | ❌ Not allowed          |
| Full Export    | ❌ Not allowed          |
| SYS User       | ❌ Not allowed          |
| S3 Integration | ✅ Allowed              |

---

# ✅ MOST USED PARAMETERS (REAL-LIFE SUMMARY)

## 🔹 90% DBA Uses These 👇

### Export

```bash
expdp user/pass \
DIRECTORY=DATA_PUMP_DIR \
SCHEMAS=APP \
DUMPFILE=app_%U.dmp \
LOGFILE=app.log \
PARALLEL=4 \
COMPRESSION=ALL

--
expdp hr TABLES=employee_data DIRECTORY=dpump_dir DUMPFILE=dpcd2be1.dmp ENCRYPTION=ALL ENCRYPTION_PWD_PROMPT=YES

```

### Import

```bash
impdp user/pass \
DIRECTORY=DATA_PUMP_DIR \
DUMPFILE=app_%U.dmp \
LOGFILE=imp.log \
REMAP_SCHEMA=APP:APP_NEW \
REMAP_TABLESPACE=USERS:APP_TS \
TABLE_EXISTS_ACTION=REPLACE \
PARALLEL=4 \
TRANSFORM=OID:n

--
impdp hr DIRECTORY=dpump_dir DUMPFILE=dpcd2be1.dmp ENCRYPTION_PWD_PROMPT=YES
```

---

## 🔹 Most Important Parameters (Remember for Interview)

| Parameter             | Why Important           |
| --------------------- | ----------------------- |
| `DIRECTORY`           | Mandatory               |
| `DUMPFILE`            | Core file               |
| `SCHEMAS`             | Most common export      |
| `PARALLEL`            | Performance             |
| `REMAP_SCHEMA`        | Migration               |
| `REMAP_TABLESPACE`    | Environment change      |
| `TABLE_EXISTS_ACTION` | Avoid failures          |
| `COMPRESSION`         | Save space              |
| `FLASHBACK_TIME`      | Consistency             |
| `NETWORK_LINK`        | Zero-downtime migration |

---

## 🔹 When to Use What (Quick Guide)

| Scenario      | Key Parameters                     |
| ------------- | ---------------------------------- |
| Prod → Test   | `REMAP_SCHEMA`, `REMAP_TABLESPACE` |
| Large DB      | `PARALLEL`, `FILESIZE`             |
| No downtime   | `NETWORK_LINK`                     |
| RDS Migration | `DATA_PUMP_DIR`, S3                |
| Space issue   | `COMPRESSION=ALL`                  |
| Partial data  | `QUERY`                            |
