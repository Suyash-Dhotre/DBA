## ASMCMD

| **Command**  | **Use Case**                                  | **Flag 1** | **Parameter 1**        | **Flag 2**       | **Parameter 2**       | **Real-Life Example**                                                                 |
|--------------|-----------------------------------------------|------------|------------------------|------------------|-----------------------|---------------------------------------------------------------------------------------|
| `ls`         | List files/directories.                       | `-l`       | (Long format)          | —                | —                     | `ls -l +DATA/DB1` → List details of files in `+DATA/DB1`.                             |
| `lsdg`       | List disk groups and attributes.              | `-g`       | `<dg_name>`            | —                | —                     | `lsdg -g DATA` → Display details of the `DATA` disk group.                            |
| `md_backup`  | Back up ASM metadata.                         | `-b`       | `<backup_file>`        | `-G`             | `<dg_name>`           | `md_backup -b /backup/asm_meta.bkp -G DATA` → Backup metadata for the `DATA` group.   |
| `md_restore` | Restore ASM metadata.                         | `-b`       | `<backup_file>`        | `-t`             | `<time>` (optional)   | `md_restore -b /backup/asm_meta.bkp` → Restore metadata from backup.                  |
| `lsdsk`      | List disks and statuses.                      | `-p`       | (Show disk paths)       | `--statistics`   | (Include I/O stats)   | `lsdsk -p --statistics` → List disks with paths and I/O statistics.                   |
| `lsattr`     | List disk group attributes.                   | `-l`       | (List all attributes)   | `-G`             | `<dg_name>`           | `lsattr -l -G DATA` → Show all attributes of the `DATA` disk group.                   |
| `volcreate`  | Create an ASM volume.                         | `-G`       | `<dg_name>`            | `-s`             | `<size>`              | `volcreate -G DATA -s 100G volume1` → Create a 100GB volume in the `DATA` group.      |
| `volresize`  | Resize a volume.                              | `-G`       | `<dg_name>`            | `-s`             | `<new_size>`          | `volresize -G DATA -s 200G volume1` → Expand `volume1` to 200GB.                      |
| `volset`     | Modify volume properties.                     | `-G`       | `<dg_name>`            | `-m`             | `<property=value>`    | `volset -G DATA -m redundancy=high volume1` → Set high redundancy for `volume1`.      |
| `chdg`       | Modify disk group compatibility.              | `-c`       | `<attribute=value>`    | —                | —                     | `chdg -c 'compatible.asm=19.0' DATA` → Set ASM compatibility to 19.0 for `DATA`.      |
| `du`         | Check disk space usage.                       | `-H`       | (Human-readable)       | `-k`             | (Size in KB)          | `du -H +DATA/DB1` → Show space usage in GB/MB for `DB1`.                              |
| `cp`         | Copy files between ASM and OS.                | `-i`       | (Interactive mode)     | `-f`             | (Force overwrite)     | `cp -i /backup/control.ctl +DATA/DB1` → Copy with confirmation prompts.              |
| `rm`         | Delete ASM files/directories.                 | `-r`       | (Recursive delete)     | —                | —                     | `rm -r +DATA/old_backups` → Delete the `old_backups` directory recursively.          |
| `chmod`      | Change permissions.                           | `-R`       | (Recursive)            | —                | —                     | `chmod -R 750 +DATA/DB1` → Recursively set permissions for `DB1`.                    |
| `volstat`    | Monitor volume I/O stats.                     | `-i`       | `<interval_seconds>`   | `-c`             | `<count>`             | `volstat -i 5 -c 10` → Display I/O stats every 5 seconds for 10 iterations.          |
| `remap`      | Repair corrupted blocks.                      | `-d`       | `<diskgroup>`          | `-D`             | `<disk>`              | `remap -d DATA -D DISK1` → Repair blocks in `DISK1` of the `DATA` group.             |

---

### **Notes**:
1. **Common Flags**:
   - `-G`: Specifies a disk group.
   - `-s`: Specifies size (e.g., `100G` for 100GB).
   - `-l`: Long/verbose output.
   - `-r`: Recursive operation (e.g., `rm -r`).
   - `-i`: Interactive mode (confirmation prompts).

2. **Command-Specific Flags**:
   - `volstat -i` and `-c`: Used for interval and count in performance monitoring.
   - `volset -m`: Modifies volume metadata properties (e.g., redundancy).
   - `lsdsk --statistics`: Adds I/O statistics to disk listings.

3. **Boolean Flags** (no parameters):
   - `-p` in `lsdsk`: Show disk paths.
   - `-H` in `du`: Human-readable format.

---

### **Examples with Multiple Flags**:
1. **Backup with Metadata**:
   ```bash
   md_backup -b /backup/asm_meta.bkp -G DATA -v
   ```
   - `-b`: Backup file path.
   - `-G`: Disk group name.
   - `-v`: Verbose mode (optional).

2. **Recursive Delete**:
   ```bash
   rm -r +DATA/obsolete_files
   ```
   - `-r`: Recursive deletion.

3. **Monitor Volume Stats**:
   ```bash
   volstat -G DATA -i 2 -c 20
   ```
   - `-G`: Disk group.
   - `-i`: Interval (2 seconds).
   - `-c`: Count (20 iterations).

