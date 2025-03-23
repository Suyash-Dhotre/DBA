spool DB_Version_deatils_$ORACLE_SID.txt 
alter session set nls_date_format='dd-mon-yyyy-hh24:mi:ss';
select sysdate from dual;
set echo on
set line 199
col HOST_NAME for a25
col SHUTDOWN_PENDING for a25
col PLATFORM_NAME for a30
select THREAD#,INSTANCE_NAME,HOST_NAME,VERSION,STATUS,DATABASE_STATUS from gv$instance ;
select DBID,NAME,DB_UNIQUE_NAME,OPEN_MODE,DATABASE_ROLE,PROTECTION_MODE,LOG_MODE,CURRENT_SCN from gv$database;
select FORCE_LOGGING,FLASHBACK_ON,PLATFORM_NAME,PLATFORM_ID,DATAGUARD_BROKER from v$database;
select * from v$version;
spool off;

spool Number_of_Objects_for_Each_Schema_$ORACLE_SID.txt
select sysdate from dual;
col OWNER for a30
col OBJECT_NAME for a30
select owner,object_type,count(*) from dba_objects group by owner,object_type order by owner asc;
select distinct tablespace_name,owner from dba_segments order by owner;
spool off;

spool Schema_Size_Details_$ORACLE_SID.txt
select sysdate from dual;
select OWNER,sum(bytes)/1024/1024/1024 from dba_segments group by owner order by owner;
select distinct tablespace_name,owner from dba_segments order by owner;
select OWNER,sum(bytes)/1024/1024/1024 from dba_segments where owner in (select username from dba_users where ORACLE_MAINTAINED='N') group by owner order by owner;
spool off;

---select object_type,count(*) from dba_objects where OWNER not in ('SYS','SYSTEM') group by object_type;
--select object_type,count(*) from dba_objects where OWNER in ('SYS','SYSTEM') group by object_type;

spool Invalid_Object_Deatils_$ORACLE_SID.txt
select sysdate from dual;
select status,count(*) from dba_objects group by status;
select status ,count(*) from dba_tables group by status;
select status ,count(*) from dba_indexes group by status;
select owner,object_name,object_type from dba_objects where STATUS='INVALID' order by object_type;
select owner,object_name,object_type from dba_objects where STATUS='INVALID' and owner in (select username from dba_users where ORACLE_MAINTAINED='N') order by object_type;
select owner,object_name,object_type from dba_objects where STATUS='INVALID' and owner in (select username from dba_users where ORACLE_MAINTAINED='Y') order by object_type;
select owner,object_name,object_type from dba_objects where STATUS='INVALID' and OWNER in ('SYS','SYSTEM');
spool off;


spool DB_Physical_Logical_Size_Details_$ORACLE_SID.txt
select sysdate from dual;
col "Database Size in GB" format a20
col "Free space" format a20
col "Used space" format a20
select  round(sum(used.bytes) / 1024 / 1024 / 1024 ) || '' "Database Size in GB"
,       round(sum(used.bytes) / 1024 / 1024 / 1024 ) -
        round(free.poo / 1024 / 1024 / 1024) || '' "Used space"
,       round(free.poo / 1024 / 1024 / 1024) || '' "Free space"
from    (select bytes
        from    v$datafile
        union   all
        select  bytes
        from    v$tempfile
        union   all
        select  bytes
        from    v$log) used
,       (select sum(bytes) as poo
        from dba_free_space) free
group by free.poo;

select sum(bytes)/1024/1024/1024 "DB_PHYSICAL_SIZE_IN_GB" from dba_data_files;
select sum(bytes)/1024/1024/1024 "DB_LOGICAL_SIZE_IN_GB" from dba_segments;
select sum(bytes)/1024/1024/1024 "DB_FREE_SIZE_IN_GB" from dba_free_space;
spool off;


spool Tablespace_ALL_Files_Diskgroup_Details_$ORACLE_SID.txt
select sysdate from dual;
set linesize 199 pages 100 trimspool on numwidth 14
col name format a30
col owner format a15
col "Used (M)" format a15
col "Used %" format a15
col "Size (M)" format a15
col "FREE (GB)" format a15
SELECT d.status "Status", d.tablespace_name "Name",
      TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "Size (M)",
        TO_CHAR(NVL(a.bytes - NVL(f.bytes, 0), 0)/1024/1024,'99999999.999') "Used (M)",
        TO_CHAR(NVL((a.bytes - NVL(f.bytes, 0)) / a.bytes * 100, 0), '990.00') "Used %",
        TO_CHAR(NVL(f.bytes / 1024 / 1024 / 1024, 0),'99999990.900') "FREE (GB)"
        FROM sys.dba_tablespaces d,
        (select tablespace_name, sum(bytes) bytes from dba_data_files group by tablespace_name) a,
        (select tablespace_name, sum(bytes) bytes from dba_free_space group by tablespace_name) f WHERE
        d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = f.tablespace_name(+) AND NOT
        (d.extent_management like 'LOCAL' AND d.contents like 'TEMPORARY')
UNION ALL
SELECT d.status
        "Status", d.tablespace_name "Name",
        TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "Size (M)",
        TO_CHAR(NVL(t.bytes,0)/1024/1024,'99999999.999') "Used (M)",
        TO_CHAR(NVL(t.bytes / a.bytes * 100, 0), '990.00') "Used %",
        TO_CHAR(NVL(t.bytes / 1024 / 1024 / 1024, 0),'99999990.900') "FREE (GB)"
        FROM sys.dba_tablespaces d,
        (select tablespace_name, sum(bytes) bytes from dba_temp_files group by tablespace_name) a,
        (select tablespace_name, sum(bytes_cached) bytes from v$temp_extent_pool group by tablespace_name) t
        WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = t.tablespace_name(+) AND
        d.extent_management like 'LOCAL' AND d.contents like 'TEMPORARY' order by 2;

set line 199
col FILE_NAME for a60
select FILE_NAME,BYTES/1024/1024/1024,status,AUTOEXTENSIBLE,MAXBYTES/1024/1024/1024 from dba_temp_files;
select TABLESPACE_NAME,FILE_NAME,BYTES/1024/1024/1024 "SIZE_IN_GB",status,AUTOEXTENSIBLE,MAXBYTES/1024/1024/1024 "MAXBYTES_SIZE_IN_GB" from dba_data_files;
col name for a60
select name from v$controlfile;
col member for a50
set line 300 pages 300
select l.group#,l.thread#,f.member,l.archived,l.status,(bytes/1024/1024) "Size (MB)"
from v$log l,v$logfile f where f.group# = l.group# order by 1,2;
select GROUP#,STATUS,TYPE,MEMBER from v$logfile;

set lines 199 pages 199
select GROUP_NUMBER,NAME,STATE,TOTAL_MB/1024 TOTAL_GB,FREE_MB/1024 FREE_GB,HOT_USED_MB/1024
HOT_USED_GB, COLD_USED_MB/1024 COLD_USED_GB,REQUIRED_MIRROR_FREE_MB/1024
REQUIRED_MIRROR_FREE_GB,USABLE_FILE_MB/1024  USABLE_FILE_GB from v$asm_diskgroup;

set line 199 pages 9999
col PATH for a45
select GROUP_NUMBER,DISK_NUMBER,MOUNT_STATUS,HEADER_STATUS,STATE,OS_MB,TOTAL_MB,FREE_MB,NAME,PATH from v$asm_disk ;
spool off;






spool DB_Link_Details_$ORACLE_SID.txt
select sysdate from dual;
set line 199 pages 9999
col host for a30
col db_link for a25
col USERNAME for a25
col OWNER for a20
set long 99999
select * from dba_db_links;

col OWNER for a25
col SYNONYM_NAME for a35
col TABLE_OWNER for a25
col TABLE_NAME for a35
col DB_LINK for a30
select * from dba_synonyms where DB_LINK is not null;
spool off;





spool Users_Accounts_and_Profile_Details_$ORACLE_SID.txt
select sysdate from dual;
set line 199
col username for a25
col PROFILE for a20
col LIMIT for a30
select username,account_status ,PROFILE,CREATED,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE from dba_users order by username;
select username,account_status ,PROFILE,CREATED,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE from dba_users where ORACLE_MAINTAINED='N' order by username;
select username,account_status ,PROFILE,CREATED,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE from dba_users where ORACLE_MAINTAINED='Y' order by username;
select distinct profile from dba_users;
select * from dba_profiles order by profile;
spool off;




spool DBA_Components_Deatils_$ORACLE_SID.txt
select sysdate from dual;
col COMP_NAME for a40
select COMP_ID,COMP_NAME,VERSION,STATUS from dba_registry order by comp_name;
spool off;




spool Database_Character_Details_$ORACLE_SID.txt
select sysdate from dual;
col PARAMETER for a35
col VALUE for a30
select * from NLS_DATABASE_PARAMETERS where parameter='NLS_CHARACTERSET';
select * from nls_database_parameters;
show parameter nls
spool off;




spool DB_Patch_Details_$ORACLE_SID.txt
select sysdate from dual;
--for before 19c database
set line 199
col LOGFILE for a50
col BUNDLE_SERIES for a15
col status for a25
col action_time for a30
col flags for a10
select patch_id,patch_uid,ACTION,VERSION,BUNDLE_SERIES,BUNDLE_ID,action_time,flags,LOGFILE from dba_registry_sqlpatch;

-- from 19c database
set line 199
col patch_type for a10
col status for a15
col action_time for a30
col flags for a10
col patch_directory for a30
col description for a35
col source_version for a18
col target_version for a18
select patch_id,patch_uid,patch_type,action,status,action_time,flags,description,source_version,target_version from dba_registry_sqlpatch;
spool off;




spool Timezone_Information_$ORACLE_SID.txt
select sysdate from dual;
select * from v$timezone_file;
col PROPERTY_NAME for a30
col VALUE for a30
select property_name, substr(property_value, 1, 30) value from database_properties where property_name like 'DST_%' order by property_name;
spool off;





spool SQL_Profile_Information_$ORACLE_SID.txt
select sysdate from dual;
col SQL_TEXT for a40
col CATEGORY for a15
SELECT NAME,type,SQL_TEXT,CATEGORY,STATUS FROM DBA_SQL_PROFILES;
spool off;





spool Statistics_of_Tables_Deatils_$ORACLE_SID.txt
select sysdate from dual;
---Verify statistics on a table
col owner for a30
col table_name for a35
col last_analyzed for a30
Select owner,table_name,stale_stats,last_analyzed from dba_tab_statistics where stale_stats='YES'  order by owner;
Select owner,table_name,stale_stats,last_analyzed from dba_tab_statistics where  stale_stats='YES'  and owner in (select username from dba_users where ORACLE_MAINTAINED='N') order by owner;
Select owner,table_name,stale_stats,last_analyzed from dba_tab_statistics order by owner;
Select owner,table_name,stale_stats,last_analyzed from dba_tab_statistics where owner in (select username from dba_users where ORACLE_MAINTAINED='N') order by owner;
spool off;





spool DB_Schedule_jobs_Details_$ORACLE_SID.txt
select sysdate from dual;
---Verify dbms jobs
col owner for a15
col job_name for a40
col state for a25
col NEXT_RUN_DATE for a40
select owner,job_name,state,NEXT_RUN_DATE from dba_scheduler_jobs;
col job_action for a100
select job_name,job_action from dba_scheduler_jobs;
spool off;


spool schema_object_count.txt
select owner, object_type, count(*) from dba_objects group by owner, object_type order by owner;
spool off;


spool DB_ALL_Parameters_Details_$ORACLE_SID.txt
select sysdate from dual;
show parameter 
spool off;

spool DG_Details_$ORACLE_SID.txt 
set lines 199 pages 199
select GROUP_NUMBER,NAME,STATE,TOTAL_MB/1024 TOTAL_GB,FREE_MB/1024 FREE_GB,HOT_USED_MB/1024
HOT_USED_GB, COLD_USED_MB/1024 COLD_USED_GB,REQUIRED_MIRROR_FREE_MB/1024
REQUIRED_MIRROR_FREE_GB,USABLE_FILE_MB/1024  USABLE_FILE_GB from v$asm_diskgroup;
spool off;


spool Roles_details_$ORACLE_SID.txt
Select role from dba_roles where ORACLE_MAINTAINED='N';
Select role from dba_roles;
spool off;


spool ROW_COUNT_$ORACLE_SID.txt
select sysdate from dual;
col owner for a25
col table_name for a35
col NUM_ROWS for a25
col num_rows for 9999999999999999
set pages 9999
set lines 2000 long 2000
select owner,table_name,NUM_ROWS from dba_tables where owner in (select username from dba_users where profile='BM_SERVACCT_PROFILE') order by owner;
spool off;

spool TABLE_ROW_COUNT_$ORACLE_SID.txt
select sysdate from dual;
col owner for a25
col table_name for a35
col NUM_ROWS for a25
col num_rows for 9999999999999999
set pages 9999
set lines 2000 long 2000
select owner,table_name,NUM_ROWS from dba_tables where owner in (select username from dba_users where ORACLE_MAINTAINED='N') order by owner;
spool off;






spool default_tablespace_$ORACLE_SID.txt
select sysdate from dual;
col owner for a25
col table_name for a35
col NUM_ROWS for a25
col num_rows for 9999999999999999
set pages 9999
set lines 2000 long 2000
select username,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE,undo_tablespace from dba_users where ORACLE_MAINTAINED='N';
spool off;

spool Tablespace_all_size.txt
set echo off
set pagesize 80
set heading on
set trimspool on
set linesize 100
col CurMb format 99999999.9
col MaxMb format 99999999.9
col TotalUsed format 99999999.9
col TotalFree format 9999999.9
col UPercent format 999999.9
compute sum of CurMb on report
compute sum of MaxMb on report
compute sum of TotalUsed on report
compute sum of TotalFree on report

break on report

SELECT   a.tablespace_name, SUM (a.BYTES) / 1024 / 1024 "CurMb",
         SUM (DECODE (a.maxbytes,
                      0, a.BYTES / 1024 / 1024,
                      a.maxbytes / 1024 / 1024
                     )
             ) "MaxMb",
         (SUM (a.BYTES) / 1024 / 1024 - ROUND (b."Free" / 1024 / 1024)
         ) "TotalUsed",
         (  SUM (DECODE (a.maxbytes,
                         0, a.BYTES / 1024 / 1024,
                         a.maxbytes / 1024 / 1024
                        )
                )
          - (SUM (a.BYTES) / 1024 / 1024 - ROUND (b."Free" / 1024 / 1024))
         ) "TotalFree",
         ROUND (  100
                * (SUM (a.BYTES) / 1024 / 1024
                   - ROUND (b."Free" / 1024 / 1024)
                  )
                / (SUM (DECODE (a.maxbytes,
                                0, a.BYTES / 1024 / 1024,
                                a.maxbytes / 1024 / 1024
                               )
                       )
                  )
               ) "UPercent"  FROM dba_data_files a,
         (SELECT   c.tablespace_name, SUM (NVL (b.BYTES, 0)) "Free"
              FROM dba_tablespaces c, dba_free_space b
             WHERE c.tablespace_name = b.tablespace_name(+)
          GROUP BY c.tablespace_name) b
   WHERE a.tablespace_name = b.tablespace_name
GROUP BY a.tablespace_name, b."Free" / 1024
ORDER BY ROUND (  100
                * (SUM (a.BYTES) / 1024 / 1024
                   - ROUND (b."Free" / 1024 / 1024)
                  )
                / (SUM (DECODE (a.maxbytes,
                                0, a.BYTES / 1024 / 1024,
                                a.maxbytes / 1024 / 1024
                               )
                       )
                  )
               ) DESC
/ 

spool off;

spool standby_dest.txt

col DESTINATION for a30
select inst_id, dest_id "ID",destination,status,error,target,schedule,process,mountid  mid
from gv$archive_dest
where dest_id < 4
order by dest_id;

spool off;



spool recover_file.txt 
select * from  v$recover_file;
select distinct status from v$datafile;
select distinct status from v$datafile_header;
spool off;






