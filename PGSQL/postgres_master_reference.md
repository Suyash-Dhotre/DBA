# 🐘 PostgreSQL — Master DBA Reference
### Complete Parameter Guide · Architecture · Memory Tricks · Interview Ready

> **Legend used throughout this file**
> 🔴 Static — needs server **restart** to apply
> 🟢 Dynamic — apply with `SELECT pg_reload_conf();` or `SET param = val;`
> ⚡ Session — can be overridden per session with `SET`
> 🔵 initdb — set only at cluster initialization (`initdb`), never changed after
> ⭐ Must Know — high-priority parameter for DBA exam / interviews
> 🚫 Deprecated — removed or replaced in a newer version
> 🆕 New — added in a specific PostgreSQL version

---

## 📖 Table of Contents

1. [Architecture Flow — The Full Picture](#1-architecture-flow--the-full-picture)
2. [Memory Parameters](#2-memory-parameters)
3. [WAL Parameters](#3-wal-parameters)
4. [Checkpoint Parameters](#4-checkpoint-parameters)
5. [Background Writer Parameters](#5-background-writer-bgwriter-parameters)
6. [Autovacuum Parameters](#6-autovacuum-parameters)
7. [Connection Parameters](#7-connection-parameters)
8. [Planner / Optimizer Parameters](#8-planner--optimizer-parameters)
9. [Replication Parameters](#9-replication-parameters)
10. [Logging Parameters](#10-logging-parameters)
11. [Safety / Durability Parameters](#11-safety--durability-parameters)
12. [Lock & Timeout Parameters](#12-lock--timeout-parameters)
13. [Parallel Query Parameters](#13-parallel-query-parameters)
14. [Extension & Library Parameters](#14-extension--library-parameters)
15. [Auditing Parameters](#15-auditing-parameters)
16. [Process Map — Who Uses What](#16-process-map--who-uses-what)
17. [What Happens Step-by-Step](#17-what-happens-step-by-step)
18. [Top 30 Must Memorize](#18-top-30-must-memorize)
19. [Interview One-Liners](#19-interview-one-liners)
20. [Final Memory Tricks](#20-final-memory-tricks)

---

## 1. Architecture Flow — The Full Picture

```
Your App / psql
      │
      ▼  TCP:5432
 ┌─────────────┐
 │  POSTMASTER │  ← listens for connections, forks backend per client
 └──────┬──────┘     params: port, max_connections
        │ forks
        ▼
 ┌─────────────────────────────────┐
 │          BACKEND PROCESS        │  ← one per connected client
 │  Parser → Rewriter → Planner   │    params: work_mem, statement_timeout
 │         → Executor             │
 └────────────┬────────────────────┘
              │ reads/writes 8KB pages
              ▼
 ┌─────────────────────────────────┐
 │         SHARED BUFFERS          │  ← main RAM cache for data pages
 │   (shared across ALL processes) │    param: shared_buffers
 └──────┬──────────────────────────┘
        │ if page not in cache → read from disk (slow path)
        │ if page modified → mark dirty
        ▼
 ┌─────────────────────────────────┐
 │          WAL BUFFER             │  ← change records in RAM before disk
 └──────┬──────────────────────────┘    param: wal_buffers
        │ WAL Writer flushes to disk
        ▼
 ┌─────────────────────────────────┐
 │    pg_wal/ (WAL Segment Files)  │  ← durable change journal on disk
 │    000000010000000000000001     │    16MB each by default
 └──────┬──────────────────────────┘    params: wal_level, max_wal_size
        │
        ├─────────────────────────► ARCHIVER copies to archive location
        │                            params: archive_mode, archive_command
        │
        ├─────────────────────────► WAL SENDER streams to replicas
        │                            params: max_wal_senders, wal_keep_size
        │
        ▼ COMMIT received
 ┌─────────────────────────────────┐
 │         CHECKPOINTER            │  ← flushes dirty shared_buffers → disk
 └──────┬──────────────────────────┘    params: checkpoint_timeout, max_wal_size
        │
        ▼
 ┌─────────────────────────────────┐
 │   base/{db_oid}/{relfilenode}   │  ← actual data files on disk
 │   + _fsm (free space map)      │
 │   + _vm  (visibility map)      │
 └─────────────────────────────────┘

 Background always running:
 ┌────────────────┐ ┌────────────────┐ ┌───────────────────┐
 │  BGWRITER      │ │  AUTOVACUUM    │ │  STATS COLLECTOR  │
 │  proactively   │ │  Launcher +    │ │  (PG < 15)        │
 │  flushes dirty │ │  Workers clean │ │  feeds pg_stat_*  │
 │  pages         │ │  dead tuples   │ │  views            │
 └────────────────┘ └────────────────┘ └───────────────────┘
```

### The Golden Rule
> **WAL first → Page later → Checkpoint balances → Autovacuum cleans → Replica replays**

---

## 2. Memory Parameters

> **Concept:** Two pools — SHARED (allocated once at startup, shared by all) and LOCAL (per backend session).

### 2A. Shared Memory — Allocated at Server Startup

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `shared_buffers` ⭐ | Static | `128MB` | **25% of RAM** | 🔴 YES | YES — #1 setting | Main data page cache. Most important memory parameter. Low = constant disk I/O. |
| `wal_buffers` ⭐ | Static | `-1` (auto) | `64MB` heavy writes | 🔴 YES | No (auto is fine) | WAL records in RAM before flush. Auto = 1/32 of shared_buffers, max 16MB. |
| `huge_pages` | Static | `try` | `on` for large RAM | 🔴 YES | No | Use 2MB OS hugepages. Reduces TLB pressure. `try` = use if available, no error if not. |
| `huge_page_size` 🆕 PG14 | Static | `0` (OS default) | OS default | 🔴 YES | No | Size of huge pages when huge_pages=on. 0 = let OS decide. |
| `max_locks_per_transaction` | Static | `64` | Increase if errors | 🔴 YES | No | Lock hash table slots per transaction. Total = this × (max_connections + max_prepared). |
| `max_pred_locks_per_transaction` | Static | `64` | Leave default | 🔴 YES | No | Predicate lock table size (for SERIALIZABLE isolation). |
| `shared_memory_type` 🆕 PG12 | Static | `mmap` | OS default | 🔴 YES | No | Which OS shared memory API to use: mmap, sysv, windows. |

### 2B. Local / Per-Session Memory

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `work_mem` ⭐ | Dynamic ⚡ | `4MB` | `4–16MB` OLTP / `256MB+` analytics per session | 🟢 NO | YES | Memory per sort/hash operation. ONE query can use this MULTIPLE TIMES. Risk: work_mem × connections × ops = OOM! |
| `maintenance_work_mem` ⭐ | Dynamic ⚡ | `64MB` | `512MB–2GB` | 🟢 NO | YES for large tables | Memory for VACUUM, CREATE INDEX, REINDEX, ALTER TABLE. Larger = faster index builds. |
| `autovacuum_work_mem` | Dynamic | `-1` | `256MB` | 🟢 NO | No | Memory per autovacuum worker. -1 = inherits maintenance_work_mem. Set explicitly to isolate autovacuum from manual maintenance. |
| `temp_buffers` | Dynamic ⚡ | `8MB` | `32MB` if using temp tables | 🟢 NO | No | Buffers for TEMPORARY TABLES per session. Must SET before first temp table use in session. |
| `logical_decoding_work_mem` 🆕 PG13 | Dynamic | `64MB` | `256MB` | 🟢 NO | No | Memory for logical replication decoding before spilling to disk. Increase to reduce decode spills. |
| `hash_mem_multiplier` 🆕 PG13 | Dynamic ⚡ | `2.0` | Leave default | 🟢 NO | No | Hash joins can use work_mem × this value. PG13+ allows hash joins more memory than sort. |
| `effective_cache_size` ⭐ | Dynamic ⚡ | `4GB` | **75% of RAM** | 🟢 NO | YES | NOT an allocation! Hint to the planner about total available cache (shared_buffers + OS cache). Wrong value = bad plans. |

### 2C. Memory Summary — Quick Rules

```
Total RAM = 32GB server example:
  shared_buffers        = 8GB    (25% — cache most-used pages)
  effective_cache_size  = 24GB   (75% — planner hint only, no allocation)
  maintenance_work_mem  = 1GB    (for fast VACUUM / CREATE INDEX)
  work_mem              = 8MB    (keep low on high-connection OLTP)
  wal_buffers           = 64MB   (override auto for heavy writes)
  Remaining RAM         = OS page cache + process overhead
```

> ⚠️ **work_mem trap:** If `work_mem = 256MB` and you have 100 connections each running 3-node sort plans → 100 × 3 × 256MB = **75 GB** worst case. The default of 4MB is conservative for a reason. Use `SET work_mem` per session for analytics instead of a global high value.

---

## 3. WAL Parameters

> **Concept:** WAL = Write-Ahead Log. Changes are written to WAL *before* the data page is modified. Crash? Replay WAL. Replica? Stream WAL. PITR? Archive WAL.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `wal_level` ⭐ | Static | `replica` | `replica` or `logical` | 🔴 YES | YES | Controls how much info goes into WAL. `minimal` = crash recovery only. `replica` = + streaming replication + PITR. `logical` = + logical decoding/replication. Never downgrade without stopping replicas first. |
| `wal_buffers` ⭐ | Static | `-1` (auto) | `64MB` | 🔴 YES | No | WAL records held in RAM before flushing. Auto = 1/32 of shared_buffers. Override if you see WAL write wait events. |
| `wal_writer_delay` | Dynamic | `200ms` | Leave default | 🟢 NO | No | How often WAL Writer wakes up to flush if not triggered by commits. |
| `wal_writer_flush_after` | Dynamic | `1MB` | Leave default | 🟢 NO | No | Flush WAL to OS if this much WAL is pending (even before delay). Prevents large bursts. |
| `wal_skip_threshold` 🆕 PG13 | Dynamic | `2MB` | Leave default | 🟢 NO | No | Skip WAL for small CREATE TABLE AS / COPY into unlogged-equivalent temp tables below this size. |
| `wal_init_zero` | Static | `on` | Leave default | 🔴 YES | No | Pre-fill new WAL segment files with zeros (reduces fragmentation on some OSes). |
| `wal_recycle` | Static | `on` | Leave default | 🔴 YES | No | Recycle old WAL segments by renaming instead of deleting+creating. Minor I/O saving. |
| `wal_compression` | Dynamic | `off` | `on` if disk/network tight | 🟢 NO | No | Compress WAL full-page images. Saves disk/network, costs CPU. `pglz` (PG10+) or `lz4`/`zstd` (PG15+). |
| `wal_log_hints` | Static | `off` | `on` if using pg_rewind | 🔴 YES | No | Write full page to WAL on first modification after checkpoint, even for non-critical hints. Required for `pg_rewind`. |
| `wal_keep_size` ⭐ | Dynamic | `0` | Cover replica lag | 🟢 NO | YES if replicas exist | Minimum MB of past WAL segments to retain for replicas. Replaced `wal_keep_segments` in PG13. Set enough to cover replica lag time × WAL generation rate. |
| `wal_keep_segments` 🚫 PG13 | — | — | Use `wal_keep_size` | — | REMOVED | Replaced by `wal_keep_size` in PostgreSQL 13. Number of segments → size in MB. |
| `wal_sender_timeout` | Dynamic | `60s` | `60s` | 🟢 NO | No | WAL sender declares replica dead if no reply within this time. |
| `wal_receiver_timeout` | Dynamic | `60s` | `60s` | 🟢 NO | No | Replica declares connection dead if no WAL received within this time. |
| `wal_receiver_status_interval` | Dynamic | `10s` | Leave default | 🟢 NO | No | How often replica reports its position back to primary. |
| `archive_mode` ⭐ | Static | `off` | `on` in production | 🔴 YES | YES for PITR | Enable WAL archiving. `on` = archive while running. `always` = archive even on standby (for cascading). |
| `archive_command` ⭐ | Dynamic | `''` | `pgbackrest ...` or `cp %p /archive/%f` | 🟢 NO | YES if archive_mode=on | Shell command to copy a WAL segment to archive. `%p` = full path, `%f` = filename. Must return 0 on success. |
| `archive_cleanup_command` | Dynamic | `''` | `pg_archivecleanup ...` | 🟢 NO | No | Command run at checkpoint to clean up old archived WAL no longer needed for recovery. |
| `archive_timeout` | Dynamic | `0` | `60` on low-activity servers | 🟢 NO | No | Force-switch WAL segment after N seconds of no activity. Ensures standby isn't stale. 0 = disabled. |
| `restore_command` | Static | `''` | `pgbackrest ... restore` | 🔴 YES | YES during recovery | Command to retrieve archived WAL segment during PITR recovery. Used in recovery.conf (PG11-) or postgresql.conf (PG12+). |
| `recovery_target_time` | Static | `''` | e.g. `'2024-01-15 14:30:00'` | Recovery only | PITR only | Recover up to this timestamp. Used in recovery. |
| `recovery_target_lsn` 🆕 PG10 | Static | `''` | Specific LSN | Recovery only | PITR only | Recover up to a specific WAL LSN position. |

### WAL Levels — What Each Enables

```
minimal  → crash recovery only. No replication. Skips WAL for some bulk ops.
           ⚠️ Cannot create replicas or use pg_basebackup with this level.
           
replica  → DEFAULT. Everything needed for streaming replication + PITR.
           Includes full-page writes after checkpoint.
           
logical  → Everything in replica + extra info for logical decoding.
           Required for: pg_logical, pgoutput plugin, Debezium, AWS DMS (CDC).
           Slight WAL size increase (~20-30%).
```

### WAL Lifecycle

```
1. Generated  → written to WAL buffer (wal_buffers)
2. Flushed    → WAL Writer writes to pg_wal/ segment file
3. Used for   → crash recovery, streaming to replicas, logical decoding
4. Archived   → archive_command copies segment to safe location (PITR)
5. Recycled   → after checkpoint AND archived AND not needed by any replica/slot
              Controlled by: max_wal_size, min_wal_size, wal_keep_size
              BLOCKED by: active replication slots (DANGER!)
```

> 🚨 **Inactive replication slot danger:** A slot no longer connected will prevent WAL recycling forever. `pg_wal/` fills disk → PostgreSQL crashes. Always monitor: `SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS lag FROM pg_replication_slots;`

---

## 4. Checkpoint Parameters

> **Concept:** A checkpoint = "everything dirty in shared_buffers is now safely on disk." After a crash, recovery only replays WAL *from the last checkpoint*. Frequent checkpoints = fast recovery but high I/O. Infrequent = low I/O but slow recovery.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `checkpoint_timeout` ⭐ | Dynamic | `5min` | `15–30min` production | 🟢 NO | YES | Max time between automatic checkpoints. Increase to reduce I/O. Trade-off: longer crash recovery time. |
| `checkpoint_completion_target` ⭐ | Dynamic | `0.9` | `0.9` | 🟢 NO | YES | Spread checkpoint writes over this fraction of checkpoint_timeout. 0.9 = use 90% of the window → avoids I/O spikes. Old default was 0.5 — change it if you see this. |
| `max_wal_size` ⭐ | Dynamic | `1GB` | `4–8GB` production | 🟢 NO | YES | Force a checkpoint if WAL grows larger than this. Low value = too many forced checkpoints. High value = less I/O but longer recovery time. |
| `min_wal_size` | Dynamic | `80MB` | `1GB` production | 🟢 NO | No | Minimum WAL kept recycled (not deleted). Reduces file creation overhead during bursty writes. |
| `checkpoint_warning` | Dynamic | `30s` | `5s` | 🟢 NO | No | Warn in server log if checkpoints are occurring more frequently than this. Useful alert: too low max_wal_size. |
| `checkpoint_flush_after` | Dynamic | `256kB` | Leave default | 🟢 NO | No | After writing this many dirty pages during checkpoint, hint OS to flush to disk. Prevents large OS write-back bursts. |

### How Checkpoint Completion Target Works

```
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9

→ Checkpointer writes dirty pages spread over: 15min × 0.9 = 13.5 minutes
→ The last 1.5 minutes are a "finishing up" buffer
→ Result: smooth I/O instead of a spike at minute 15

If 0.5 (old default):
→ Writes all dirty pages in 7.5 minutes → big I/O spike → set to 0.9!
```

### What Triggers a Checkpoint

```
1. checkpoint_timeout elapsed  (timed checkpoint)
2. WAL size reaches max_wal_size  (forced checkpoint)  ← seen in logs as "checkpoints_req"
3. pg_checkpoint() called manually
4. CHECKPOINT SQL command
5. Server start / shutdown
6. pg_basebackup running

Monitor:  SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
          checkpoints_req >> checkpoints_timed → increase max_wal_size
```

---

## 5. Background Writer (bgwriter) Parameters

> **Concept:** bgwriter proactively writes dirty shared_buffers pages to disk *before* the checkpointer needs to. Reduces I/O spikes at checkpoint time. Also reduces stalls when backends need a clean buffer slot.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `bgwriter_delay` | Dynamic | `200ms` | Leave default | 🟢 NO | No | How long bgwriter sleeps between activity rounds. |
| `bgwriter_lru_maxpages` | Dynamic | `100` | Increase if maxwritten_clean > 0 | 🟢 NO | No | Max pages bgwriter writes per round. If 0 = disabled (not recommended). |
| `bgwriter_lru_multiplier` | Dynamic | `2.0` | Leave default | 🟢 NO | No | Predict how many clean buffers will be needed in the next round. Multiplied by recent demand. |
| `bgwriter_flush_after` | Dynamic | `512kB` | Leave default | 🟢 NO | No | Hint OS to flush written data to storage after this many bytes. Prevents large OS dirty page buildup. |

### How to Tell If bgwriter Is Struggling

```sql
SELECT buffers_clean,         -- pages bgwriter wrote
       maxwritten_clean,      -- times bgwriter hit its per-round limit
       buffers_alloc,         -- times a backend needed a new buffer
       buffers_backend        -- times a BACKEND had to write a dirty page itself
FROM pg_stat_bgwriter;

-- maxwritten_clean > 0 regularly → bgwriter_lru_maxpages too low
-- buffers_backend high → bgwriter not writing fast enough → backends doing its job
```

---

## 6. Autovacuum Parameters

> **Concept:** PostgreSQL never overwrites rows — UPDATE creates a new version, DELETE marks old as dead (MVCC). Dead versions must be cleaned up or tables bloat forever. Autovacuum is the automatic cleanup crew. NEVER disable it.

### Core Autovacuum Control

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `autovacuum` ⭐ | Dynamic | `on` | `on` always | 🟢 NO | **CRITICAL** | Master on/off switch. Disabling causes table bloat, performance collapse, and eventual transaction ID wraparound shutdown. |
| `autovacuum_max_workers` ⭐ | Static | `3` | `5–10` busy systems | 🔴 YES | YES | Max concurrent autovacuum worker processes. One worker per table at a time. |
| `autovacuum_naptime` | Dynamic | `1min` | `30s` busy systems | 🟢 NO | No | How often the autovacuum launcher scans all tables to find which need cleaning. |

### Trigger Thresholds — When Does Autovacuum Fire?

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `autovacuum_vacuum_threshold` | Dynamic | `50` | Leave at 50 | 🟢 NO | No | Minimum dead tuples before vacuum considered. Base added to scale_factor result. |
| `autovacuum_vacuum_scale_factor` ⭐ | Dynamic | `0.2` | **`0.01` for large tables** | 🟢 NO | YES | Fraction of table that must be dead before vacuum fires. 0.2 = 20% dead rows on a 1M row table = 200K dead rows before vacuum! Lower for large tables. |
| `autovacuum_analyze_threshold` | Dynamic | `50` | Leave at 50 | 🟢 NO | No | Minimum changed rows before ANALYZE (stats update) is triggered. |
| `autovacuum_analyze_scale_factor` | Dynamic | `0.1` | `0.01` large tables | 🟢 NO | No | Fraction of table changed before ANALYZE fires. |
| `autovacuum_vacuum_insert_threshold` 🆕 PG13 | Dynamic | `1000` | Leave default | 🟢 NO | No | NEW in PG13: trigger vacuum for tables with only inserts (to set visibility map bits). Previously inserts alone never triggered vacuum. |
| `autovacuum_vacuum_insert_scale_factor` 🆕 PG13 | Dynamic | `0.2` | Leave default | 🟢 NO | No | Fraction of inserted rows that triggers an insert-vacuum. Pairs with above. |

### Vacuum Formula (Memorize This!)

```
Vacuum fires when:
  n_dead_tup > autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor × n_live_tup)

Example — default settings, table with 10 million rows:
  threshold = 50 + (0.2 × 10,000,000) = 2,000,050 dead tuples
  ← 2 MILLION dead tuples before vacuum starts!

Fix for large tables (override per table):
  ALTER TABLE large_orders SET (
    autovacuum_vacuum_scale_factor = 0.01,   -- trigger at 1% = 100K dead rows
    autovacuum_analyze_scale_factor = 0.005
  );
```

### Anti-Wraparound Vacuum (XID Safety)

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `autovacuum_freeze_max_age` ⭐ | Static | `200000000` | Leave default | 🔴 YES | CRITICAL | Max transaction ID age before autovacuum MUST run FREEZE (regardless of dead tuple count). Prevents XID wraparound. Never set above 2 billion. |
| `autovacuum_multixact_freeze_max_age` | Static | `400000000` | Leave default | 🔴 YES | No | Same as above but for multixact IDs (shared row locks). |
| `vacuum_freeze_min_age` | Dynamic | `50000000` | Leave default | 🟢 NO | No | Minimum XID age before vacuum will freeze a row. Avoids premature freezing of recently-changed rows. |
| `vacuum_freeze_table_age` | Dynamic | `150000000` | Leave default | 🟢 NO | No | When a table reaches this XID age, a full-table aggressive vacuum (freeze scan) is triggered. |
| `vacuum_failsafe_age` 🆕 PG14 | Dynamic | `1600000000` | Leave default | 🟢 NO | No | NEW in PG14: if XID age reaches this, vacuum ignores cost limits and runs at full speed to prevent wraparound. Safety valve. |

### Autovacuum Cost Throttling (I/O Control)

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `autovacuum_vacuum_cost_delay` ⭐ | Dynamic | `2ms` | `0` for SSD / `2ms` HDD | 🟢 NO | YES | Sleep this long after hitting cost limit. 0 = no throttling. Increase to reduce I/O impact on production. |
| `autovacuum_vacuum_cost_limit` | Dynamic | `-1` | `400–800` | 🟢 NO | No | Cost budget per round before sleeping. -1 = inherits vacuum_cost_limit (200). Increase for faster autovacuum on fast storage. |
| `vacuum_cost_delay` | Dynamic ⚡ | `0` | Leave default for manual | 🟢 NO | No | Cost delay for manual VACUUM. 0 = run at full speed. |
| `vacuum_cost_page_hit` | Dynamic | `1` | Leave default | 🟢 NO | No | Cost of reading a page already in shared_buffers during vacuum. |
| `vacuum_cost_page_miss` | Dynamic | `2` | Leave default | 🟢 NO | No | Cost of reading a page from disk during vacuum. |
| `vacuum_cost_page_dirty` | Dynamic | `20` | Leave default | 🟢 NO | No | Cost of dirtying a clean page during vacuum (expensive because it now needs flushing). |
| `vacuum_cost_limit` | Dynamic | `200` | Leave default | 🟢 NO | No | Global cost budget per round for manual vacuum (not autovacuum, which uses autovacuum_vacuum_cost_limit). |

### Monitor Autovacuum

```sql
-- Tables with high dead tuples (need vacuum soon):
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup * 100.0 / nullif(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Live vacuum progress:
SELECT p.relid::regclass AS table, p.phase,
       p.heap_blks_scanned, p.heap_blks_total,
       p.dead_item_ids
FROM pg_stat_progress_vacuum p;

-- XID wraparound risk (urgent if xid_age > 1.8 billion):
SELECT datname, age(datfrozenxid) AS xid_age,
       2100000000 - age(datfrozenxid) AS xids_remaining
FROM pg_database ORDER BY xid_age DESC;
```

---

## 7. Connection Parameters

> **Concept:** PostgreSQL is process-per-connection. 500 connections = 500 processes. Use a connection pooler (PgBouncer) for high connection counts.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `port` | Static | `5432` | Leave default | 🔴 YES | YES | TCP port PostgreSQL listens on. |
| `max_connections` ⭐ | Static | `100` | `≤ 200` direct. Use PgBouncer. | 🔴 YES | YES | Max client connections. Each connection = 1 process + ~5–10MB RAM overhead. High value + high work_mem = OOM risk. |
| `superuser_reserved_connections` | Static | `3` | Leave at 3 | 🔴 YES | YES | Slots reserved for superuser even when max_connections is full. Lets DBA connect to a saturated server. |
| `listen_addresses` | Static | `localhost` | `*` or specific IP | 🔴 YES | YES | Which IPs to listen on. `*` = all. Must also configure pg_hba.conf. |
| `unix_socket_directories` | Static | `/var/run/postgresql` | Leave default | 🔴 YES | No | Directory for Unix domain socket file. Local psql connections use this (faster than TCP). |
| `max_prepared_transactions` | Static | `0` | `max_connections` if using 2PC | 🔴 YES | No | Enable two-phase commit (BEGIN; PREPARE TRANSACTION). 0 = disabled. Set equal to max_connections if using distributed transactions. |
| `authentication_timeout` | Dynamic | `60s` | `30s` | 🟢 NO | No | Max time for client to complete authentication. Prevents hanging half-open connections. |
| `idle_in_transaction_session_timeout` ⭐ 🆕 PG9.6 | Dynamic ⚡ | `0` | `5min` or `300000` | 🟢 NO | YES | Kill sessions idle inside a transaction longer than this. Open transactions block VACUUM and cause bloat. 0 = disabled. |
| `idle_session_timeout` 🆕 PG14 | Dynamic ⚡ | `0` | Optional | 🟢 NO | No | NEW in PG14: kill completely idle sessions (not in transaction) after N ms. 0 = disabled. |
| `tcp_keepalives_idle` | Dynamic | `0` (OS) | `60` | 🟢 NO | No | Seconds before TCP keepalive probes. Detects dead clients faster. 0 = OS default. |
| `tcp_keepalives_interval` | Dynamic | `0` (OS) | `10` | 🟢 NO | No | Seconds between keepalive probes. |
| `tcp_keepalives_count` | Dynamic | `0` (OS) | `6` | 🟢 NO | No | Number of unacknowledged keepalives before giving up. |

### pg_hba.conf — Connection Authentication

```
File: $PGDATA/pg_hba.conf
Applied: SELECT pg_reload_conf();  (no restart needed)

Format: TYPE  DATABASE  USER  ADDRESS  METHOD

Examples:
  local   all  postgres              peer          # OS user postgres → DB user postgres
  host    all  all  127.0.0.1/32    scram-sha-256  # local TCP, password auth
  host    mydb app  10.0.0.0/8     scram-sha-256  # app server subnet
  host    all  all  0.0.0.0/0      reject          # deny everything else

Methods:
  trust         → no password (dev only, never production)
  peer          → Linux only: OS username must match DB username
  ident         → Like peer but over TCP (rarely used)
  md5           → MD5-hashed password (less secure, legacy)
  scram-sha-256 → RECOMMENDED since PG10. Strong password auth.
  ldap          → LDAP server authentication
  radius        → RADIUS server authentication
  cert          → SSL client certificate
  reject        → always reject (use as catch-all deny rule)
```

---

## 8. Planner / Optimizer Parameters

> **Concept:** PostgreSQL uses a Cost-Based Optimizer (CBO). It estimates the "cost" of different execution plans and picks the cheapest. These parameters teach the planner about your hardware's cost characteristics.

### Cost Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `seq_page_cost` | Dynamic ⚡ | `1.0` | Leave at 1.0 | 🟢 NO | No | Baseline cost unit for reading a page sequentially. All other costs are relative to this. |
| `random_page_cost` ⭐ | Dynamic ⚡ | `4.0` | **`1.1` for SSD, `4.0` for HDD** | 🟢 NO | YES | Cost of a random disk read. High value → planner avoids index scans (prefers seq scans). SSD users MUST lower this. |
| `cpu_tuple_cost` | Dynamic ⚡ | `0.01` | Leave default | 🟢 NO | No | Cost to process each row in the result. |
| `cpu_index_tuple_cost` | Dynamic ⚡ | `0.005` | Leave default | 🟢 NO | No | Cost to process each index entry during index scan. |
| `cpu_operator_cost` | Dynamic ⚡ | `0.0025` | Leave default | 🟢 NO | No | Cost to evaluate an operator or function. |
| `parallel_tuple_cost` | Dynamic ⚡ | `0.1` | Leave default | 🟢 NO | No | Cost of transferring a row from worker to leader in parallel query. |
| `parallel_setup_cost` | Dynamic ⚡ | `1000` | Leave default | 🟢 NO | No | One-time cost to start up parallel workers. Prevents parallelism for tiny queries. |
| `effective_cache_size` ⭐ | Dynamic ⚡ | `4GB` | **75% of RAM** | 🟢 NO | YES | Hint to planner: total cache available. Higher → planner prefers index scans. **NOT an allocation.** |

### Statistics Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `default_statistics_target` ⭐ | Dynamic ⚡ | `100` | `200–500` for complex queries | 🟢 NO | YES | Number of histogram buckets per column. Higher = better estimates = better plans. Costs more ANALYZE time. Override per column: `ALTER TABLE t ALTER COLUMN c SET STATISTICS 500;` |

### Plan Toggle Parameters (Debugging Only)

| Parameter | Type | Default | Note |
|---|---|---|---|
| `enable_seqscan` | Dynamic ⚡ | `on` | `SET enable_seqscan = off` to force index scan in session (debugging only) |
| `enable_indexscan` | Dynamic ⚡ | `on` | Toggle index scans |
| `enable_indexonlyscan` | Dynamic ⚡ | `on` | Toggle index-only scans |
| `enable_bitmapscan` | Dynamic ⚡ | `on` | Toggle bitmap scans |
| `enable_hashjoin` | Dynamic ⚡ | `on` | Toggle hash join |
| `enable_mergejoin` | Dynamic ⚡ | `on` | Toggle merge join |
| `enable_nestloop` | Dynamic ⚡ | `on` | Toggle nested loop join |
| `enable_hashagg` | Dynamic ⚡ | `on` | Toggle hash aggregate |
| `enable_sort` | Dynamic ⚡ | `on` | Toggle explicit sort steps |
| `enable_incremental_sort` 🆕 PG13 | Dynamic ⚡ | `on` | Toggle incremental sort (partially sorted input) |
| `enable_memoize` 🆕 PG14 | Dynamic ⚡ | `on` | Toggle memoize node (cache inner-side results in nested loop) |

> ⚠️ These toggles are for **session-level debugging only**. Never change them globally in postgresql.conf. The planner is usually right — use EXPLAIN ANALYZE to understand why it chose a plan.

### JIT Compilation (PG11+)

| Parameter | Type | Default | Recommended | Restart? | Note |
|---|---|---|---|---|---|
| `jit` 🆕 PG11 | Dynamic ⚡ | `on` | `on` for analytics, `off` for OLTP | 🟢 NO | JIT-compile query expressions using LLVM. Speeds up CPU-heavy analytics. Adds latency for short OLTP queries. |
| `jit_above_cost` 🆕 PG11 | Dynamic ⚡ | `100000` | Increase for pure OLTP | 🟢 NO | Only JIT-compile queries more expensive than this cost threshold. |
| `jit_optimize_above_cost` 🆕 PG11 | Dynamic ⚡ | `500000` | Leave default | 🟢 NO | Cost threshold above which JIT applies more expensive optimizations. |

---

## 9. Replication Parameters

> **Concept:** Primary streams WAL to replicas via WAL Sender processes. Replica applies via WAL Receiver + startup process. Logical replication uses a subscription model and can replicate selected tables.

### Primary-Side Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `wal_level` ⭐ | Static | `replica` | `replica` or `logical` | 🔴 YES | YES | Must be ≥ `replica` for streaming replication. |
| `max_wal_senders` ⭐ | Static | `10` | `replicas + slots + 2` buffer | 🔴 YES | YES | Max simultaneous WAL sender processes. Each replica + pg_basebackup + replication slot = 1 sender. |
| `max_replication_slots` ⭐ | Static | `10` | Match expected slots | 🔴 YES | YES | Max replication slots (physical + logical). Set ≥ expected subscribers/replicas. |
| `wal_keep_size` ⭐ | Dynamic | `0` | Cover replica lag | 🟢 NO | YES if no slots | Minimum WAL to keep for replicas not using slots. `0` = rely on slots or archive only. |
| `synchronous_standby_names` | Dynamic | `''` | List standby names for sync | 🟢 NO | No | Comma-separated replica names that must confirm WAL before commit returns. Empty = async replication. Format: `FIRST 1 (replica1, replica2)` |
| `synchronous_commit` ⭐ | Dynamic ⚡ | `on` | See note | 🟢 NO | YES | `on` = wait for local WAL flush. `remote_write` = wait for replica to receive. `remote_apply` = wait for replica to apply. `off` = async (small data loss risk). |
| `hot_standby_feedback` | Dynamic | `off` | `on` if long replica queries | 🟢 NO | No | Replica tells primary its oldest active XID. Prevents primary from vacuuming rows the replica query still needs. Stops "query was cancelled due to conflict" errors on replica. May cause primary table bloat. |

### Replica-Side Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `hot_standby` | Static | `on` | `on` always | 🔴 YES | YES | Allow queries on the standby server during recovery. If `off`, replica is completely read-only (no queries at all). |
| `primary_conninfo` | Static | `''` | Connection string | 🔴 YES (PG12-) / 🟢 (PG13+) | YES on replica | Connection string to primary: `host=primary port=5432 user=replicator`. In recovery.conf (PG11-) or postgresql.conf (PG12+). |
| `primary_slot_name` | Static | `''` | Use physical slot name | 🔴 YES | No | Name of replication slot on primary to use. Ensures primary keeps WAL for this replica. |
| `recovery_target` | Static | `''` | PITR only | 🔴 YES | No | `immediate` = stop ASAP after consistency. For PITR only. |
| `recovery_target_time` | Static | `''` | Timestamp | Recovery only | PITR | Recover to this timestamp. |
| `recovery_target_lsn` 🆕 PG10 | Static | `''` | LSN value | Recovery only | PITR | Recover to this WAL LSN position. |
| `recovery_target_name` | Static | `''` | Restore point name | Recovery only | PITR | Recover to a named restore point created by `pg_create_restore_point()`. |
| `recovery_target_inclusive` | Static | `on` | Leave default | Recovery only | PITR | Include (on) or stop before (off) the recovery target. |
| `recovery_target_action` 🆕 PG9.5 | Static | `pause` | `promote` or `pause` | Recovery only | PITR | What to do when recovery target reached: `pause`, `promote`, or `shutdown`. |
| `recovery_min_apply_delay` | Dynamic | `0` | e.g. `1h` for delayed replica | 🟢 NO | No | Delay applying WAL on standby by this duration. Creates a "delayed replica" as DR protection against accidental deletes. |
| `restore_command` | Static | `''` | Archive fetch command | 🔴 YES | YES for PITR | Command to retrieve archived WAL segment during recovery. |

### Logical Replication Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `max_logical_replication_workers` 🆕 PG10 | Static | `4` | Match subscriptions | 🔴 YES | YES for logical replication | Max parallel logical replication workers (apply workers + table sync workers). |
| `max_sync_workers_per_subscription` 🆕 PG10 | Dynamic | `2` | Leave default | 🟢 NO | No | Max parallel workers for initial table sync when a subscription is created. |
| `wal_level` | Static | `replica` | `logical` for logical replication | 🔴 YES | YES | Must be `logical` to use logical replication or logical decoding. |

### Monitor Replication

```sql
-- Primary: check replica lag
SELECT application_name, state, client_addr,
       write_lag, flush_lag, replay_lag,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)) AS lag_bytes
FROM pg_stat_replication;

-- Replica: check how far behind
SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;
SELECT pg_is_in_recovery();  -- true = this is a replica

-- Replication slots (watch for inactive slots!):
SELECT slot_name, slot_type, active,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal
FROM pg_replication_slots;
-- retained_wal growing → inactive slot → DROP REPLICATION SLOT 'name';

-- Logical subscriptions (on subscriber):
SELECT subname, subenabled, subslotname FROM pg_subscription;
SELECT * FROM pg_stat_subscription;
```

---

## 10. Logging Parameters

> **Concept:** Proper logging is the DBA's black box. Set these from day one. Log too little = blind during incidents. Log too much = fills disk and hurts performance.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `logging_collector` | Static | `off` | `on` production | 🔴 YES | YES | Capture server log output to files. Required for log_directory to work. |
| `log_destination` | Dynamic | `stderr` | `csvlog` or `jsonlog` | 🟢 NO | YES | Where logs go: `stderr`, `csvlog`, `jsonlog` (PG15+), `syslog`, `eventlog` (Windows). Use `csvlog` for pgBadger, `jsonlog` for ELK/Splunk. |
| `log_directory` | Dynamic | `log` | `/var/log/postgresql` | 🟢 NO | No | Directory for log files. Relative to $PGDATA or absolute path. |
| `log_filename` | Dynamic | `postgresql-%Y-%m-%d.log` | `postgresql-%a.log` for 7-day rolling | 🟢 NO | No | Log filename pattern. `%a` = day-of-week → auto-rotates, keeps 7 days. |
| `log_rotation_age` | Dynamic | `1d` | `1d` | 🟢 NO | No | Rotate log file after this time. |
| `log_rotation_size` | Dynamic | `10MB` | `100MB` | 🟢 NO | No | Rotate log file when it exceeds this size. 0 = size-based rotation disabled. |
| `log_line_prefix` ⭐ | Dynamic | `%m [%p] ` | `'%m [%p] %u@%d [%a] host=%h '` | 🟢 NO | YES | Prefix for each log line. Key tokens: `%m` = timestamp, `%p` = PID, `%u` = user, `%d` = database, `%a` = app name, `%h` = client host, `%r` = client IP:port, `%e` = error code. |
| `log_timezone` | Static | system | `UTC` | 🔴 YES | No | Timezone for log timestamps. UTC recommended for consistency across time zones. |
| `log_min_messages` | Dynamic | `warning` | `warning` | 🟢 NO | No | Minimum severity to log: `DEBUG5 ... DEBUG1 INFO NOTICE WARNING ERROR LOG FATAL PANIC`. |
| `log_min_error_statement` | Dynamic | `error` | `error` | 🟢 NO | No | Minimum error level that causes the failing SQL statement to be logged. |
| `log_min_duration_statement` ⭐ | Dynamic ⚡ | `-1` | **`1000`** (1 second) | 🟢 NO | YES | Log any query slower than this many milliseconds. `-1` = disabled. `0` = log ALL queries (too verbose for production). **Most important logging parameter for performance.** |
| `log_min_duration_sample` 🆕 PG13 | Dynamic ⚡ | `-1` | Optional | 🟢 NO | No | NEW in PG13: log a random sample of queries slower than this, at rate log_transaction_sample_rate. Lighter than logging all slow queries. |
| `log_transaction_sample_rate` 🆕 PG13 | Dynamic ⚡ | `0` | Optional | 🟢 NO | No | NEW in PG13: fraction (0.0–1.0) of transactions to log all statements from. 0 = none, 1 = all. |
| `log_statement` ⭐ | Dynamic ⚡ | `none` | `ddl` production | 🟢 NO | YES | Log SQL statements: `none`, `ddl` (CREATE/ALTER/DROP), `mod` (+ INSERT/UPDATE/DELETE), `all`. `all` is only for debugging — high volume! |
| `log_checkpoints` ⭐ | Dynamic | `off` | `on` | 🟢 NO | YES | Log checkpoint start/completion with I/O statistics. Essential for tuning checkpoint parameters. |
| `log_connections` ⭐ | Dynamic | `off` | `on` | 🟢 NO | YES | Log every new connection with user, database, application, IP. |
| `log_disconnections` ⭐ | Dynamic | `off` | `on` | 🟢 NO | YES | Log session end with total session duration. Pair with log_connections. |
| `log_lock_waits` ⭐ | Dynamic | `off` | `on` | 🟢 NO | YES | Log when a query waits longer than `deadlock_timeout` for a lock. Essential for diagnosing lock contention. |
| `log_autovacuum_min_duration` ⭐ | Dynamic | `-1` | **`250`** | 🟢 NO | YES | Log autovacuum runs longer than N ms. `-1` = disabled. `0` = log all. `250` = catch slow vacuums without too much noise. |
| `log_temp_files` ⭐ | Dynamic | `-1` | **`0`** | 🟢 NO | YES | Log temp files larger than N KB. `-1` = disabled. `0` = log ALL temp files. Temp files = `work_mem` too small → disk spill. |
| `log_error_verbosity` | Dynamic | `default` | `default` | 🟢 NO | No | `terse`, `default`, or `verbose`. Verbose includes file/function/line in error messages. |
| `log_hostname` | Dynamic | `off` | `off` | 🟢 NO | No | Resolve client IP to hostname in logs. Can slow down connection logging significantly (DNS lookup per connection). |
| `log_duration` | Dynamic ⚡ | `off` | `off` (use log_min_duration_statement) | 🟢 NO | No | Log duration of EVERY statement. Different from log_min_duration_statement (which only logs above threshold). Avoid in production. |
| `log_replication_commands` 🆕 PG9.5 | Dynamic | `off` | `on` if using replication | 🟢 NO | No | Log replication-related commands (IDENTIFY_SYSTEM, START_REPLICATION, etc.). |

### Recommended Production Logging Block

```ini
# postgresql.conf — recommended logging setup
logging_collector           = on
log_destination             = csvlog             # or jsonlog (PG15+)
log_directory               = /var/log/postgresql
log_filename                = 'postgresql-%a.log' # 7-day rolling
log_rotation_age            = 1d
log_rotation_size           = 100MB
log_line_prefix             = '%m [%p] %u@%d [%a] host=%h '
log_min_duration_statement  = 1000               # log queries > 1 second
log_checkpoints             = on
log_connections             = on
log_disconnections          = on
log_lock_waits              = on
log_temp_files              = 0                  # log all temp file creation
log_autovacuum_min_duration = 250
log_statement               = ddl                # capture schema changes
```

---

## 11. Safety / Durability Parameters

> **Concept:** These parameters guarantee your data survives crashes. They are ON by default for a reason. Turning them off for "performance" risks data corruption.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `fsync` ⭐ | Dynamic | `on` | `on` **ALWAYS** | 🟢 NO | **CRITICAL** | Ensures WAL and data pages are physically flushed to disk. `off` = massive data corruption risk on crash. Only ever set `off` for throwaway data (e.g., pg_regress). |
| `synchronous_commit` ⭐ | Dynamic ⚡ | `on` | `on` (default). `off` only for bulk loads | 🟢 NO | YES | `on` = commit only returns after WAL is on disk. `off` = commit returns before WAL is flushed (up to ~200ms data loss on crash). `remote_write`/`remote_apply` for synchronous replication. |
| `full_page_writes` ⭐ | Dynamic | `on` | `on` **ALWAYS** | 🟢 NO | **CRITICAL** | After a checkpoint, writes the entire 8KB page to WAL on first modification. Protects against "torn pages" (partial 8KB writes if OS blocks are smaller). Only turn off if using atomic write storage (rare). |
| `data_checksums` | 🔵 initdb | `off` | **`on`** (set at initdb) | 🔵 initdb | YES in production | Compute and verify checksums on every 8KB page read. Detects silent data corruption. **Enable at `initdb` time: `initdb --data-checksums`.** Enabling later: `pg_checksums --enable` (PG12+, requires server stop). |
| `wal_sync_method` | Static | OS-default | Leave default | 🔴 YES | No | How WAL is synced to disk: `fsync`, `fdatasync`, `open_sync`, `open_datasync`. PostgreSQL auto-picks the best for your OS. |
| `zero_damaged_pages` | Dynamic | `off` | `off` (use only for emergency) | 🟢 NO | No | Silently zero out corrupt pages instead of throwing an error. **Use only as last resort to salvage data from a corrupted database.** |
| `ignore_checksum_failure` | Dynamic | `off` | `off` (emergency only) | 🟢 NO | No | Continue reading a page even if its checksum fails. Use only to recover data from a corrupt database. |
| `wal_init_zero` | Static | `on` | Leave default | 🔴 YES | No | Pre-fill new WAL segment with zeros. Ensures allocated space on disk before writing. |
| `wal_log_hints` | Static | `off` | `on` if using pg_rewind | 🔴 YES | No | Required for `pg_rewind` (re-sync a former primary as a replica after failover without pg_basebackup). |

### Durability Levels (synchronous_commit)

```
synchronous_commit = off
  → Fastest. Up to ~200ms of committed transactions lost on crash.
  → Safe for: session data, caches, analytics staging, bulk loads.

synchronous_commit = local (or on)
  → DEFAULT. Commit returns after WAL written to local disk.
  → Data safe on primary crash.

synchronous_commit = remote_write
  → Commit returns after replica has received and written WAL (not fsynced).
  → Protects against primary crash even if replica hasn't applied yet.

synchronous_commit = remote_apply
  → Commit returns after replica has APPLIED the WAL (query can see the data).
  → Strongest guarantee. Slowest. Good for zero-lag read replicas.

Must set synchronous_standby_names to enable remote_write / remote_apply.
```

---

## 12. Lock & Timeout Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `deadlock_timeout` | Dynamic | `1s` | `1s` | 🟢 NO | No | Time to wait before checking if a lock wait has become a deadlock. Lower = faster detection, more CPU overhead. |
| `lock_timeout` ⭐ | Dynamic ⚡ | `0` | `5s` on production | 🟢 NO | YES | Abort if waiting for a lock longer than this. 0 = wait forever. Set per session: `SET lock_timeout = '5s';` Essential for DDL operations (ALTER TABLE). |
| `statement_timeout` ⭐ | Dynamic ⚡ | `0` | `30s` or per-role | 🟢 NO | YES | Abort any single SQL statement running longer than this. 0 = no limit. Set per role: `ALTER ROLE app SET statement_timeout = '30s';` |
| `idle_in_transaction_session_timeout` ⭐ | Dynamic ⚡ | `0` | `5min` | 🟢 NO | YES | Kill sessions idle inside an open transaction. Open transactions hold locks + prevent VACUUM. |
| `idle_session_timeout` 🆕 PG14 | Dynamic ⚡ | `0` | Optional | 🟢 NO | No | Kill completely idle sessions (not in transaction). Cleans up abandoned connections. |
| `transaction_timeout` 🆕 PG17 | Dynamic ⚡ | `0` | Optional | 🟢 NO | No | NEW in PG17: abort transaction if it runs longer than this total time (including idle-in-transaction time). Stronger than statement_timeout alone. |
| `max_locks_per_transaction` | Static | `64` | Increase if errors seen | 🔴 YES | No | Hash table size for lock tracking. Increase if: "ERROR: out of shared memory" during lock-heavy transactions. |
| `max_pred_locks_per_transaction` | Static | `64` | Leave default | 🔴 YES | No | Predicate lock table size for SERIALIZABLE transactions. |
| `lock_manager_timeout` 🆕 PG18 | Dynamic | `0` | Leave default | 🟢 NO | No | NEW in PG18: timeout for internal lock manager waits. |

### Check Lock Contention

```sql
-- Who is blocking whom:
SELECT blocked.pid, blocked.usename,
       left(blocked.query, 60) AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.usename AS blocking_user,
       left(blocking.query, 60) AS blocking_query,
       now() - blocked.query_start AS wait_time
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY wait_time DESC;

-- All current locks:
SELECT locktype, relation::regclass, mode, granted, pid
FROM pg_locks
WHERE NOT granted
ORDER BY pid;
```

---

## 13. Parallel Query Parameters

> **Concept:** For large queries (analytics, big aggregations), PostgreSQL can use multiple CPU cores by splitting work across parallel worker processes. Added in PG9.6, improved significantly each release.

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `max_worker_processes` ⭐ | Static | `8` | `= CPU cores` | 🔴 YES | YES | Max background worker processes total (parallel query workers + autovacuum + custom workers). |
| `max_parallel_workers` ⭐ 🆕 PG10 | Dynamic | `8` | `= CPU cores / 2` | 🟢 NO | YES | Max workers available for parallel query at any moment (subset of max_worker_processes). |
| `max_parallel_workers_per_gather` ⭐ 🆕 PG9.6 | Dynamic ⚡ | `2` | `4` analytics / `0` OLTP | 🟢 NO | YES | Max parallel workers per single query node. 0 = disable parallel query entirely. |
| `max_parallel_maintenance_workers` 🆕 PG11 | Dynamic | `2` | `4` | 🟢 NO | No | NEW in PG11: max parallel workers for CREATE INDEX, VACUUM. Set to number of available CPUs. |
| `parallel_leader_participation` 🆕 PG11 | Dynamic ⚡ | `on` | Leave default | 🟢 NO | No | Allow query leader to also participate in parallel work (not just coordinate). |
| `min_parallel_table_scan_size` 🆕 PG9.6 | Dynamic ⚡ | `8MB` | Leave default | 🟢 NO | No | Minimum table size before parallel sequential scan is considered. |
| `min_parallel_index_scan_size` 🆕 PG9.6 | Dynamic ⚡ | `512kB` | Leave default | 🟢 NO | No | Minimum index size before parallel index scan is considered. |
| `force_parallel_mode` 🚫 PG16 | Dynamic ⚡ | `off` | Replaced by debug_parallel_query | — | No | REMOVED in PG16. Replaced by `debug_parallel_query`. |
| `debug_parallel_query` 🆕 PG16 | Dynamic ⚡ | `off` | Debug only | 🟢 NO | No | NEW in PG16: force all queries to use parallel mode (testing only). |

---

## 14. Extension & Library Parameters

| Parameter | Type | Default | Recommended | Restart? | Mandatory? | Note |
|---|---|---|---|---|---|---|
| `shared_preload_libraries` ⭐ | Static | `''` | See below | 🔴 YES | YES | Comma-separated list of libraries loaded at server start. Required for: `pg_stat_statements`, `pgaudit`, `auto_explain`, `pg_prewarm`. Changes require restart. |
| `session_preload_libraries` | Dynamic | `''` | Leave default | 🟢 NO | No | Libraries loaded at session start. Rarely needed. |
| `local_preload_libraries` | Dynamic | `''` | Leave default | 🟢 NO | No | Libraries a non-superuser can load. Listed in $libdir/plugins/. |
| `dynamic_library_path` | Dynamic | `'$libdir'` | Leave default | 🟢 NO | No | Search path for loadable modules. |

### Key shared_preload_libraries Values

```ini
shared_preload_libraries = 'pg_stat_statements, pgaudit, auto_explain, pg_prewarm'

# pg_stat_statements  → ALWAYS add. Query performance tracking.
# pgaudit             → Compliance-grade SQL auditing.
# auto_explain        → Auto-log EXPLAIN plans for slow queries.
# pg_prewarm          → Pre-warm shared_buffers after restart.
# timescaledb         → Time-series extension (if used).
# pgvector            → Vector similarity search (PG AI workloads).
```

### auto_explain Parameters (PG8.4+)

| Parameter | Type | Default | Recommended | Note |
|---|---|---|---|---|
| `auto_explain.log_min_duration` | Dynamic | `-1` | `1000` | Log EXPLAIN for queries slower than N ms. |
| `auto_explain.log_analyze` | Dynamic | `off` | `on` | Include EXPLAIN ANALYZE (actual times). Adds overhead. |
| `auto_explain.log_buffers` | Dynamic | `off` | `on` | Include buffer usage stats in plan. |
| `auto_explain.log_format` | Dynamic | `text` | `json` | Plan output format. |
| `auto_explain.log_nested_statements` | Dynamic | `off` | `off` | Log plans inside PL/pgSQL functions. |

---

## 15. Auditing Parameters

> **Concept:** pgAudit extension provides compliance-grade SQL auditing. Requires adding to shared_preload_libraries + restart.

| Parameter | Type | Default | Recommended | Restart? | Note |
|---|---|---|---|---|---|
| `pgaudit.log` | Dynamic | `none` | `'ddl, write, role'` | 🟢 NO (after preload) | Classes to audit: READ, WRITE, FUNCTION, ROLE, DDL, MISC, ALL. Comma-separated. |
| `pgaudit.log_catalog` | Dynamic | `on` | `off` for less noise | 🟢 NO | Log queries against pg_catalog tables. Usually too verbose. |
| `pgaudit.log_parameter` | Dynamic | `off` | `on` | 🟢 NO | Include bind parameters in log. Essential for full audit trail. |
| `pgaudit.log_parameter_max_size` 🆕 PG16 | Dynamic | `0` | Leave default | 🟢 NO | Max size of logged parameter values. 0 = unlimited. |
| `pgaudit.log_relation` | Dynamic | `off` | `on` | 🟢 NO | Separate log entry per relation (table/view) per statement. |
| `pgaudit.log_rows` 🆕 pgAudit 1.7 | Dynamic | `off` | `on` if needed | 🟢 NO | Log row data affected by READ/WRITE statements. Very verbose. |
| `pgaudit.log_statement_once` | Dynamic | `off` | `off` | 🟢 NO | Log statement text only once even if multiple objects accessed. |
| `pgaudit.role` | Dynamic | `''` | `pgaudit_role` | 🟢 NO | Role for object-level audit. Objects granted to this role are audited. |
| `pgaudit.log_level` | Dynamic | `log` | `log` | 🟢 NO | Severity level for audit log entries. |
| `pgaudit.log_client` | Dynamic | `off` | `off` | 🟢 NO | Whether to send audit logs to the client as NOTICE messages. |

### Auditing Setup Checklist

```ini
# Step 1: postgresql.conf
shared_preload_libraries = 'pg_stat_statements, pgaudit'
pgaudit.log = 'ddl, write, role'
pgaudit.log_parameter = on
pgaudit.log_relation = on
log_connections = on
log_disconnections = on
log_line_prefix = '%m [%p] %u@%d [%a] host=%h '

# Step 2: Restart PostgreSQL

# Step 3: In each database
# CREATE EXTENSION pgaudit;

# Step 4: Object-level (optional - audit specific tables only)
# CREATE ROLE pgaudit_role NOLOGIN;
# GRANT SELECT, INSERT, UPDATE, DELETE ON sensitive_table TO pgaudit_role;
# ALTER SYSTEM SET pgaudit.role = 'pgaudit_role';
# SELECT pg_reload_conf();
```

---

## 16. Process Map — Who Uses What

> The most important relationships in PostgreSQL: which process, which memory, which parameters, which view.

| Process | What It Does | Memory It Uses | Key Parameters | Monitor With |
|---|---|---|---|---|
| **Postmaster** | Accepts connections, forks backends, watches workers | minimal | `port` 🔴, `max_connections` 🔴, `listen_addresses` 🔴 | `pg_stat_activity` (count) |
| **Backend** | Runs your SQL: parse → plan → execute | `work_mem`, `temp_buffers` (per session) | `work_mem` 🟢, `statement_timeout` 🟢, `lock_timeout` 🟢 | `pg_stat_activity` |
| **WAL Writer** | Flushes WAL buffer → pg_wal/ | `wal_buffers` (shared) | `wal_writer_delay` 🟢, `synchronous_commit` 🟢, `wal_level` 🔴 | `pg_stat_wal` (PG14+) |
| **Checkpointer** | Writes dirty shared_buffers → data files | shared_buffers (reads dirty pages) | `checkpoint_timeout` 🟢, `max_wal_size` 🟢, `checkpoint_completion_target` 🟢 | `pg_stat_bgwriter` |
| **Background Writer** | Proactively flushes dirty pages before checkpoint | shared_buffers (reads dirty pages) | `bgwriter_delay` 🟢, `bgwriter_lru_maxpages` 🟢 | `pg_stat_bgwriter` |
| **Autovacuum Launcher** | Schedules vacuum workers for dirty tables | minimal | `autovacuum_naptime` 🟢, `autovacuum_max_workers` 🔴 | `pg_stat_user_tables` |
| **Autovacuum Worker** | VACUUMs + ANALYZEs specific tables | `autovacuum_work_mem` (or maintenance_work_mem) | `autovacuum_vacuum_scale_factor` 🟢, `autovacuum_vacuum_cost_delay` 🟢 | `pg_stat_progress_vacuum` |
| **WAL Sender** | Streams WAL to replica/slot | minimal | `max_wal_senders` 🔴, `wal_keep_size` 🟢, `synchronous_standby_names` 🟢 | `pg_stat_replication` |
| **WAL Receiver** | Receives WAL from primary, writes to pg_wal/ | minimal | `primary_conninfo` 🔴, `wal_receiver_timeout` 🟢 | `pg_stat_wal_receiver` |
| **Archiver** | Copies WAL segments to archive location | minimal | `archive_mode` 🔴, `archive_command` 🟢, `archive_timeout` 🟢 | `pg_stat_archiver` |
| **Logical Replication Worker** | Applies logical changes on subscriber | `logical_decoding_work_mem` | `max_logical_replication_workers` 🔴 | `pg_stat_subscription` |

---

## 17. What Happens Step-by-Step

### UPDATE Statement Full Trace

```
UPDATE orders SET status = 'shipped' WHERE id = 42;

1. PARSE      → SQL text → parse tree (syntax check)
2. REWRITE    → apply any rules / expand views
3. PLAN       → planner checks pg_statistics, decides plan
               (index scan on orders_pkey? seq scan?)
               Cost factors: random_page_cost, seq_page_cost, effective_cache_size
4. EXECUTE    → executor fetches page from shared_buffers (or disk if cold)
5. WAL RECORD → change description written to wal_buffers (xmin, xmax, old/new tuple)
6. PAGE DIRTY → shared_buffers page marked dirty (contains new tuple + old dead tuple)
7. COMMIT     → WAL Writer flushes wal_buffers → pg_wal/ on disk
               → If synchronous_commit=on: blocks until WAL is durable on disk
               → COMMIT ACK sent to client
8. BACKGROUND → bgwriter trickles dirty page to disk (base/)
9. CHECKPOINT → checkpointer writes remaining dirty pages to disk + writes checkpoint WAL record
               → WAL before checkpoint LSN can now be recycled (if archived + no slots need it)
10. AUTOVACUUM → later, autovacuum worker finds dead old tuple, marks space reusable in FSM + VM
```

### What Happens on Crash + Restart

```
1. PostgreSQL starts
2. Reads pg_control file → finds last checkpoint LSN
3. Opens pg_wal/ → finds WAL from that checkpoint LSN onwards
4. Replays WAL records → reconstructs all pages to consistent state
5. Rolls back any transactions that were in-progress at crash
6. Opens for connections

Recovery time ∝ WAL since last checkpoint (max = checkpoint_timeout × max_wal_size)
→ Tune checkpoint_timeout to balance recovery speed vs I/O
```

### When Can WAL Be Recycled?

```
A WAL segment can be recycled ONLY when ALL of these are true:

✓ A checkpoint has passed BEYOND this segment's LSN
✓ The segment is NOT needed by any replica (wal_keep_size, replication slots)
✓ The segment IS archived (if archive_mode=on, archive_command succeeded)
✓ No active replication slot's restart_lsn is at or before this segment

Block any ONE of these → WAL is retained → pg_wal/ grows → disk fills.
```

---

## 18. Top 30 Must Memorize

> Learn these in order — most critical first.

| # | Parameter | Why It's Critical |
|---|---|---|
| 1 | `shared_buffers` | Main data cache. Low = constant disk I/O. Set to 25% RAM. |
| 2 | `work_mem` | Sort/hash memory per operation. Multiply by connections × ops for RAM impact. |
| 3 | `maintenance_work_mem` | Speed of VACUUM and CREATE INDEX. Critical for maintenance windows. |
| 4 | `max_connections` | Too high + high work_mem = OOM. Use PgBouncer. |
| 5 | `effective_cache_size` | Planner hint. Wrong value = bad plans. Set to 75% RAM. |
| 6 | `random_page_cost` | Must set to 1.1 for SSD. Default 4.0 = assumes spinning disk. |
| 7 | `wal_level` | Must be `replica` for streaming replication, `logical` for logical. |
| 8 | `archive_mode` + `archive_command` | WAL archiving for PITR. Enable on ALL production systems. |
| 9 | `max_wal_size` | Controls checkpoint frequency. Low = too many forced checkpoints. |
| 10 | `checkpoint_timeout` | Trade-off: I/O vs crash recovery time. |
| 11 | `checkpoint_completion_target` | Must be 0.9. Prevents I/O spikes. |
| 12 | `autovacuum` | NEVER disable. Disabling causes bloat, then shutdown. |
| 13 | `autovacuum_max_workers` | More workers = parallel cleanup of busy tables. |
| 14 | `autovacuum_vacuum_scale_factor` | Lower to 0.01 for large tables. Default 0.2 is too high. |
| 15 | `autovacuum_freeze_max_age` | XID wraparound protection. Never touch without deep understanding. |
| 16 | `fsync` | **Never turn off in production.** Data corruption on crash. |
| 17 | `full_page_writes` | Torn page protection. Never turn off. |
| 18 | `synchronous_commit` | On = safe. Off = faster with small data loss risk. |
| 19 | `data_checksums` | Enable at initdb. Detects silent hardware corruption. |
| 20 | `log_min_duration_statement` | Your #1 slow query detector. Set to 1000. |
| 21 | `log_checkpoints` | Essential for checkpoint tuning. Turn on. |
| 22 | `log_connections` | Audit: who logged in and when. Turn on. |
| 23 | `log_autovacuum_min_duration` | Catch slow vacuum operations. Set to 250. |
| 24 | `log_temp_files` | Detect work_mem spills to disk. Set to 0. |
| 25 | `hot_standby` | Allow read queries on replica. Always on. |
| 26 | `max_wal_senders` | Must be ≥ number of replicas. |
| 27 | `wal_keep_size` | Keep WAL for replicas not using slots. |
| 28 | `idle_in_transaction_session_timeout` | Kill stale transactions that block VACUUM. |
| 29 | `shared_preload_libraries` | How extensions like pg_stat_statements are loaded. |
| 30 | `statement_timeout` + `lock_timeout` | Prevent runaway queries and lock pile-ups. |

---

## 19. Interview One-Liners

```
Q: What is WAL?
A: Write-Ahead Log. Every change is written to WAL before touching the data page.
   Guarantees crash recovery, enables replication and PITR.

Q: What is a checkpoint?
A: A point where all dirty shared_buffers pages are flushed to disk.
   After a crash, PostgreSQL only replays WAL from the last checkpoint.
   Checkpoints reduce recovery time but increase I/O.

Q: What is MVCC?
A: Multi-Version Concurrency Control. UPDATE creates a new row version,
   old versions stay visible to older transactions. Readers never block writers.
   Old versions become dead tuples, cleaned by VACUUM.

Q: Why is work_mem dangerous to set high globally?
A: It's per operation, not per session or server.
   One query with 5 sort nodes × 100 connections × 256MB = 128GB potential RAM usage.

Q: What is the difference between VACUUM and VACUUM FULL?
A: Regular VACUUM reclaims space for reuse IN the same file, without shrinking it.
   VACUUM FULL rewrites the entire table into a new compact file.
   VACUUM FULL needs an exclusive lock; regular VACUUM doesn't.

Q: What happens when a replication slot is inactive?
A: It retains all WAL from its restart_lsn onward. pg_wal/ fills up → database crashes.
   Always monitor slot lag and drop unused slots.

Q: What does transaction ID wraparound mean?
A: Transaction IDs are 32-bit. After ~2 billion, they wrap around.
   Old rows become invisible (future transactions). Data loss!
   Autovacuum FREEZE prevents it by replacing xmin with a "frozen" eternal marker.

Q: What is the visibility map?
A: A file per table tracking which 8KB pages have ALL rows visible to ALL transactions.
   VACUUM uses it to skip clean pages. Enables Index-Only Scans.

Q: What is the difference between wal_level replica and logical?
A: replica = streaming replication + PITR.
   logical = replica + extra info for logical decoding (table-level replication, Debezium).

Q: Why does checkpoint_completion_target matter?
A: It spreads checkpoint writes over a fraction of checkpoint_timeout.
   Without it (e.g., 0.5), all dirty pages flush in half the interval → I/O spike.
   0.9 = use 90% of the window → smooth I/O.

Q: What does idle_in_transaction_session_timeout protect against?
A: Open transactions hold locks and prevent VACUUM from reclaiming dead tuples.
   Setting this kills forgotten open transactions, preventing bloat and lock pile-ups.

Q: What is hot_standby_feedback?
A: The replica tells the primary its oldest XID. Prevents primary from vacuuming rows
   the replica's long queries still need. Avoids "query was cancelled" errors on replica.
   Trade-off: may cause table bloat on primary.

Q: What is the FSM (Free Space Map)?
A: A compact structure tracking free space in each 8KB page.
   INSERT checks FSM to find pages with room, avoiding full page scans.
   VACUUM updates FSM after reclaiming space.

Q: How do you find unused indexes?
A: SELECT indexname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0;
   idx_scan = 0 since last stats reset = index was never used.

Q: What parameters changed in PostgreSQL 13?
A: wal_keep_segments → wal_keep_size (MB instead of segment count).
   autovacuum_vacuum_insert_threshold added (vacuum tables with only inserts).
   log_min_duration_sample and log_transaction_sample_rate added (sampled logging).
```

---

## 20. Final Memory Tricks

### The Four Flows (memorize these sequences)

```
WRITE FLOW (INSERT/UPDATE/DELETE):
  App → Backend → shared_buffers (dirty page) + wal_buffers → WAL Writer → pg_wal/
  → COMMIT → bgwriter+checkpointer → base/ data files

VACUUM FLOW:
  Dead tuples → autovacuum worker → mark pages reusable (FSM) + set visible bits (VM)
  → periodic FREEZE → prevent XID wraparound

CRASH RECOVERY FLOW:
  Crash → Restart → read pg_control → find last checkpoint LSN
  → replay WAL from checkpoint → roll back in-progress xacts → open for connections

REPLICATION FLOW:
  Commit on primary → WAL → WAL Sender → WAL Receiver on replica → pg_wal/
  → startup process applies → replica data files updated
```

### Static vs Dynamic — Quick Test

```
Ask yourself: "Can this change while customers are using the database?"

YES (Dynamic 🟢) → memory per query, timeouts, logging, autovacuum tuning,
                    planner hints, checkpoint intervals
NO  (Static 🔴)  → max_connections, shared_buffers, port, wal_level,
                    archive_mode, autovacuum_max_workers, max_wal_senders
NEVER (initdb 🔵) → data_checksums, block_size, wal_block_size
```

### The "Must Be ON" Safety Set

```
fsync               = on    ← never off in production (data corruption)
full_page_writes    = on    ← never off in production (torn pages)
autovacuum          = on    ← never off (bloat, wraparound)
data_checksums              ← enable at initdb (detects corruption)
archive_mode        = on    ← enable from day 1 (you'll need PITR someday)
log_connections     = on    ← you need to know who connected
log_checkpoints     = on    ← you need to tune checkpoints
```

### Quick Tuning Formula for a New Server

```
Given: 32GB RAM, SSD, OLTP, 150 connections

shared_buffers             = 8GB          (32 × 0.25)
effective_cache_size       = 24GB         (32 × 0.75)
maintenance_work_mem       = 1GB          (large tables → fast VACUUM/INDEX)
work_mem                   = 8MB          (OLTP: keep low, 150 × 5 sorts × 8MB = 6GB max)
wal_buffers                = 64MB
max_connections            = 150
random_page_cost           = 1.1          (SSD!)
checkpoint_timeout         = 15min
max_wal_size               = 4GB
checkpoint_completion_target = 0.9
autovacuum_vacuum_scale_factor = 0.05     (lower than 0.2 default)
autovacuum_vacuum_cost_delay = 0          (don't throttle on SSD)
log_min_duration_statement = 1000
log_checkpoints            = on
log_connections            = on
log_lock_waits             = on
log_temp_files             = 0
log_autovacuum_min_duration = 250
shared_preload_libraries   = 'pg_stat_statements, pgaudit'
```

### Deprecated / Changed Parameters (Version Reference)

| Old Parameter | Removed In | Replacement | Notes |
|---|---|---|---|
| `wal_keep_segments` | PG13 | `wal_keep_size` | Unit changed from segment count to MB |
| `recovery.conf` | PG12 | `postgresql.conf` / `standby.signal` | All recovery params moved to main config |
| `trigger_file` | PG12 | `promote_trigger_file` | Renamed for clarity |
| `force_parallel_mode` | PG16 | `debug_parallel_query` | Renamed |
| `stats_temp_directory` | PG15 | — | Stats moved to shared memory in PG15 |
| `vacuum_cleanup_index_scale_factor` | PG14 | — | Removed; vacuum always cleans index |
| `default_with_oids` | PG12 | — | OIDs removed from user tables in PG12 |
| `sql_inheritance` | PG10 | — | Always on, parameter removed |
| `operator_precedence_warning` | PG14 | — | Removed |

### Version-by-Version Key Additions

```
PG9.5  → Row Level Security (RLS), UPSERT (INSERT ... ON CONFLICT)
PG9.6  → Parallel query (max_parallel_workers_per_gather),
          idle_in_transaction_session_timeout
PG10   → Logical replication built-in, max_parallel_workers,
          recovery_target_lsn, scram-sha-256 auth
PG11   → Parallel CREATE INDEX, max_parallel_maintenance_workers,
          stored procedures (CREATE PROCEDURE ... CALL), partition pruning
PG12   → recovery.conf removed (merged into postgresql.conf),
          pg_checksums tool, generated columns, CTE materialization control
PG13   → wal_keep_size replaces wal_keep_segments,
          autovacuum_vacuum_insert_threshold added,
          log_min_duration_sample, hash_mem_multiplier, logical_decoding_work_mem
PG14   → vacuum_failsafe_age, idle_session_timeout, enable_memoize,
          pg_stat_wal view, multirange types, LZ4/ZSTD WAL compression
PG15   → pg_stat_* views moved to shared memory (no more stats_temp_directory),
          jsonlog log destination, merge command, two_phase logical replication
PG16   → debug_parallel_query, pg_stat_io view, logical replication from standby,
          pgaudit.log_parameter_max_size
PG17   → transaction_timeout, pg_combinebackup, incremental backup support
PG18   → lock_manager_timeout (planned)
```

---

*PostgreSQL Master DBA Reference — Parameters · Architecture · Processes · Memory · Auditing*
*🔴 Static (restart) · 🟢 Dynamic (reload/SET) · ⚡ Session-settable · 🔵 initdb only · ⭐ Must Know · 🚫 Deprecated · 🆕 Added in version*
