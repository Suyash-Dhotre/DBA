
```
                         +-----------------------------+
                         |          Client             |
                         |  (Application/User)         |
                         +-----------------------------+
                                      |
                                      v
                         +-----------------------------+
                         |  Oracle Listener / Net      |
                         |  (Accepts client connections|
                         |   & forwards to DB process) |
                         +-----------------------------+
                                      |
                                      v
          +--------------------------------------------------+
          |           Oracle Server Process (SGA + PGA)     |
          |  (Handles SQL, transactions, memory management)|
          +--------------------------------------------------+
                       |                 |
                       v                 v
         +----------------+       +------------------+
         | System Global  |       | Program Global   |
         | Area (SGA)     |       | Area (PGA)       |
         +----------------+       +------------------+
         | - Database Buffers      | - Session memory |
         | - Redo Log Buffers      | - Sorts / Hash  |
         | - Shared Pool           |   operations    |
         | - Large Pool            | - PL/SQL exec   |
         | - Java Pool             |                  |
         | - Streams Pool          |                  |
         +----------------+---------------------------+
                       |
                       v
          +-----------------------------------------+
          | Background Processes                     |
          +-----------------------------------------+
          | DBWR (Database Writer)   | Flushes dirty buffers to disk        |
          | LGWR (Log Writer)       | Writes redo log buffer to redo logs |
          | CKPT (Checkpointer)     | Updates datafile headers            |
          | SMON (System Monitor)   | Performs recovery                     |
          | PMON (Process Monitor)  | Cleans failed processes               |
          | ARC (Archiver)          | Archives redo logs                    |
          | RECO (Recoverer)        | Resolves distributed transactions    |
          | Others: MMAN, WLM, etc. | Memory & resource management         |
          +-----------------------------------------+
                       |
                       v
          +-------------------------------+
          | Disk / Storage                |
          +-------------------------------+
          | - Data Files (tables & idx)  |
          | - Redo Logs (online redo)    |
          | - Archived Logs              |
          | - Control Files              |
          | - Temp Tablespaces           |
          | - Undo Tablespaces           |
          +-------------------------------+
```

---

### ✅ Key Notes:

**Memory Areas:**

* **SGA (System Global Area)** → Shared across all users; contains:

  * Database Buffers → Caches table/index blocks
  * Redo Log Buffers → Holds redo entries
  * Shared Pool → Caches SQL statements, dictionary info
  * Large Pool → For RMAN, parallel execution
  * Java Pool → For Java execution
  * Streams Pool → For Streams replication
* **PGA (Program Global Area)** → Private memory per session/process:

  * Sorts, joins, session variables, PL/SQL execution

**Background Processes:**

* **DBWR** → Writes modified blocks from SGA to data files.
* **LGWR** → Writes redo log buffer to redo log files.
* **CKPT** → Updates datafile headers after checkpoints.
* **SMON** → System recovery, instance recovery.
* **PMON** → Cleans up failed processes/resources.
* **ARC** → Archives redo logs for backup/recovery.
* **RECO** → Resolves distributed transactions.
* **Other processes** → Resource and memory management.

**Disk Storage:**

* **Data files** → Stores user & system data.
* **Redo logs** → Tracks all changes for recovery.
* **Archived redo logs** → Backup of redo logs.
* **Control files** → Metadata about database structure.
* **Temp tablespaces** → Temporary work areas.
* **Undo tablespaces** → For rollback and read consistency.

