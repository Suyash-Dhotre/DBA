# 1️⃣ Custom RDS → Custom RDS using NETWORK_LINK (BEST)

## 🔹 Step 1: Create DB Link on TARGET

```sql
CREATE DATABASE LINK src_custom_rds
CONNECT TO admin IDENTIFIED BY "password"
USING '(DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCP)(HOST=source-custom-endpoint)(PORT=1521))
  (CONNECT_DATA=(SERVICE_NAME=ORCL))
)';
```

Test:

```sql
SELECT * FROM dual@src_custom_rds;
```

---

## 🔹 Step 2: Import via Network (NO DUMP FILE)

### Schema Import

```bash
impdp admin/password \
DIRECTORY=DATA_PUMP_DIR \
NETWORK_LINK=src_custom_rds \
SCHEMAS=HR \
REMAP_SCHEMA=HR:HR_NEW \
REMAP_TABLESPACE=USERS:APP_TS \
PARALLEL=4
```

📌 No export required
📌 Fastest method
📌 Works perfectly on **RDS Custom**


---

# 2️⃣ Custom RDS → Custom RDS using DBMS_FILE_TRANSFER

This method is **ONLY possible on RDS Custom**.

---

## 🔹 Step 1: Create DIRECTORY on BOTH RDSs

```
-- DATA_PUMP_DIR 
-- WILL EXIST ON rds
```

## 🔹 Step 2: Export on SOURCE

```bash
expdp admin/password \
DIRECTORY=DATA_PUMP_DIR \
SCHEMAS=HR \
DUMPFILE=hr.dmp \
LOGFILE=hr_exp.log
```

---

## 🔹 Step 3: Create DB Link from SOURCE → TARGET :: Run on source

```sql
CREATE DATABASE LINK tgt_custom_rds
CONNECT TO admin IDENTIFIED BY "password"
USING '(DESCRIPTION= (ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=target-custom-endpoint)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=ORCL)))';

SELECT * FROM DUAL@tgt_custom_rds;
```

---

## 🔹 Step 4: Transfer File using DBMS_FILE_TRANSFER

```sql
BEGIN
  DBMS_FILE_TRANSFER.PUT_FILE(
    source_directory_object      => 'DATA_PUMP_DIR',
    source_file_name             => 'hr.dmp',
    destination_directory_object => 'DATA_PUMP_DIR',
    destination_file_name        => 'hr.dmp',     
    destination_database         => 'TGT_CUSTOM_RDS'
  );
END;
/
```

Verify: 

```sql
SELECT * FROM dba_directories;

SELECT * FROM TABLE(rdsadmin.rds_file_util.listdir('DATA_PUMP_DIR'));

SELECT rdsadmin.rds_file_util.get_file_size(  p_directory => 'DATA_PUMP_DIR',  p_filename => 'hr.dmp') FROM dual;

SELECT * FROM TABLE(  rdsadmin.rds_file_util.read_text_file(p_directory => 'DATA_PUMP_DIR', p_filename  => 'expdp.log'));
SELECT * FROM TABLE(  rdsadmin.rds_file_util.read_text_file(p_directory => 'DATA_PUMP_DIR', p_filename  => 'impdp.log'));

-- Remove file
EXEC UTL_FILE.FREMOVE('DATA_PUMP_DIR','hr.dmp');

EXEC rdsadmin.rds_file_util.delete_file( p_directory => 'DATA_PUMP_DIR', p_filename  => 'hr.dmp');
```

---

## 🔹 Step 5: Import on TARGET

```bash
impdp admin/password \
DIRECTORY=tgt_dp_dir \
DUMPFILE=hr.dmp \
REMAP_SCHEMA=HR:HR_NEW \
LOGFILE=hr_imp.log
```

---

# 3️⃣ Required Privileges (IMPORTANT)

```sql
GRANT EXECUTE ON DBMS_FILE_TRANSFER TO admin;
GRANT CREATE DATABASE LINK TO admin;
```

---

# 4️⃣ NETWORK_LINK vs DBMS_FILE_TRANSFER (Custom RDS)

| Feature     | NETWORK_LINK | DBMS_FILE_TRANSFER |
| ----------- | ------------ | ------------------ |
| Dump file   | ❌ No         | ✅ Yes              |
| Speed       | Faster       | Slower             |
| Resume      | Yes          | No                 |
| Use case    | Migration    | File movement      |




----
----
#
# 3️⃣ RDS → RDS USING DUMP FILE + S3 (ALTERNATIVE)
#
## 🔹 Export on SOURCE RDS

```bash
expdp admin/password \
DIRECTORY=DATA_PUMP_DIR \
SCHEMAS=HR \
DUMPFILE=hr.dmp \
LOGFILE=hr_exp.log 
```

Upload to S3:

```sql
SELECT * FROM TABLE(rdsadmin.rds_file_util.listdir('DATA_PUMP_DIR')) order by mtime;

select  rdsadmin.rdsadmin_s3_tasks.upload_to_s3(
  p_bucket_name => 'my-S3-bucket',
  p_prefix => 'hr.dump',
  p_s3_prefix => 'exports/s3/loation/dir/'
  p_directory_name => 'DATA_PUMP_DIR')
as task_id from dual;


SELECT * FROM TABLE(rdsadmin.rds_file_util.read_text_file('BDUMP', 'dbtask-<TASK-ID>.log'));
```

---

## 🔹 Download on TARGET RDS

```sql
Select rdsadmin.rdsadmin_s3_tasks.download_from_s3(
  p_bucket_name => 'my-S3-bucket',
  p_s3_prefix => 'exports/s3/loation/dir/hr.dump'
  p_directory_name => 'DATA_PUMP_DIR')
as task_id from dual;


SELECT * FROM TABLE(rdsadmin.rds_file_util.read_text_file('BDUMP', 'dbtask-<TASK-ID>.log'));
SELECT * FROM TABLE(rdsadmin.rds_file_util.listdir('DATA_PUMP_DIR')) order by mtime;
```

Import:

```bash
impdp admin/password \
DIRECTORY=DATA_PUMP_DIR \
DUMPFILE=hr.dmp \
REMAP_SCHEMA=HR:HR_NEW \
PARALLEL=4
```

Note : In Linux run in nohup & -- expdp and impdp using par file




