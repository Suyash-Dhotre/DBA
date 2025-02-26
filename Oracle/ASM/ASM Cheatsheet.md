#ASMCMD

| **Command**      | **Use Case**                                   | **Real-Life Example**                                                                 |
|------------------|-----------------------------------------------|---------------------------------------------------------------------------------------|
| `cd`             | Navigate to a directory in ASM.               | `cd +DATA/DB1` → Move to the `DB1` database directory within the `DATA` disk group.    |
| `ls`             | List files/directories.                       | `ls -l` → Check if a newly created control file exists in the current directory.      |
| `du`             | Check disk space usage.                       | `du +DATA/DB1/DATAFILE` → Find space consumed by datafiles in the `DB1` database.      |
| `lsdg`           | List disk groups and their attributes.        | `lsdg` → Verify free space in all disk groups before adding a new tablespace.          |
| `mkdir`          | Create a directory in ASM.                    | `mkdir +RECOVERY/DB2` → Create a directory for `DB2` backups in the `RECOVERY` group.  |
| `rm`             | Delete an ASM file or directory.              | `rm +DATA/old_archivelogs` → Clean up obsolete archived redo logs.                     |
| `cp`             | Copy files between ASM and OS.                | `cp /u01/backup/control01.ctl +DATA/DB1/CONTROLFILE` → Restore a control file.         |
| `mkalias`        | Create a human-readable alias for a file.     | `mkalias +DATA/DB1/TEMPFILE/temp.123.789 'temp01.dbf'` → Simplify tempfile management. |
| `rnalias`        | Remove an alias.                              | `rnalias 'temp01.dbf'` → Delete an alias after migrating to a new tempfile.            |
| `chdg`           | Modify disk group compatibility.              | `chdg -c 'compatible.asm=19.0' DATA` → Prepare for an ASM upgrade.                     |
| `chmod`          | Change file/directory permissions.            | `chmod 755 +DATA/DB1` → Allow group read/execute access to the `DB1` directory.        |
| `lsct`           | List connected databases.                     | `lsct` → Confirm which databases are active during ASM maintenance.                    |
| `lsdsk`          | List disks and their statuses.                | `lsdsk -p --statistics` → Identify a failed disk path (`/dev/sdb1`) for replacement.   |
| `lsattr`         | List disk group attributes.                   | `lsattr -l -G DATA` → Check if `DATA` disk group redundancy is `NORMAL`.               |
| `chgrp`          | Change group ownership.                       | `chgrp dba +DATA/DB1` → Assign ownership to the `dba` group after a team change.       |
| `md_backup`      | Back up ASM metadata.                         | `md_backup -b /backup/asm_meta.bkp -G DATA` → Backup `DATA` disk group metadata.       |
| `md_restore`     | Restore ASM metadata.                         | `md_restore -b /backup/asm_meta.bkp` → Recover metadata after accidental deletion.     |
| `pwd`            | Print current ASM directory path.             | `pwd` → Confirm you’re in `+DATA/DB1` before deleting files.                           |
| `exit`           | Exit ASMCMD.                                  | `exit` → Leave ASMCMD after completing maintenance tasks.                             |
| `help`           | Get command syntax/options.                   | `help remap` → Check syntax for repairing a disk group.                                |
| `remap`          | Repair corrupted blocks on disks.             | `remap DATA DISK1` → Fix bad blocks in `DISK1` of the `DATA` disk group.               |
| `volcreate`      | Create an ASM volume.                         | `volcreate -G DATA -s 100G volume1` → Create a 100GB volume for ACFS file storage.     |
| `voldelete`      | Delete an ASM volume.                         | `voldelete volume1` → Remove an unused volume to reclaim space.                       |
| `volinfo`        | Display volume details.                       | `volinfo volume1` → Verify volume size and status before expanding it.                |
| `volresize`      | Resize a volume.                              | `volresize -G DATA -s 200G volume1` → Expand `volume1` to 200GB for growing data.      |
| `volset`         | Modify volume properties.                     | `volset -G DATA -m redundancy=high volume1` → Set high redundancy for critical data.  |
| `voldisable`     | Disable a volume.                             | `voldisable volume1` → Temporarily disable a volume for maintenance.                  |
| `volenable`      | Enable a volume.                              | `volenable volume1` → Reactivate a volume after maintenance.                          |
| `volstat`        | Monitor volume I/O statistics.                | `volstat -G DATA` → Check I/O performance during peak workload hours.                 |

### Key Scenarios Covered:  
1. **Space Management**: `du`, `lsdg`, `volresize`.  
2. **Disaster Recovery**: `md_backup`, `md_restore`, `cp`.  
3. **Troubleshooting**: `lsdsk`, `remap`, `volstat`.  
4. **Daily Operations**: `ls`, `cd`, `mkdir`, `rm`.  
5. **Upgrades/Compatibility**: `chdg`, `volset`.  


