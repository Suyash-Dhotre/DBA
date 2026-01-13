# Unified auditing

``` SQL
SELECT value FROM v$option WHERE parameter = 'Unified Auditing';
select * from audit_unified_policies;
select * from audit_unified_enabled_policies;

select * from UNIFIED_AUDIT_TRAIL;

Create Audit policy TESTPOLICY  Actions all;

audit policy TESTPOLICY by HR;
noaudit policy TESTPOLICY by HR;

drop Audit policy TESTPOLICY;
```

# Traditional auditing

``` SQL

SHOW PARAMETER audit_trail; -- DB, DB_EXTENDED

select * from DBA_STMT_AUDIT_OPTS;

-- all system privilege auditing
AUDIT ALL;
NOAUDIT ALL;

-- all system privilege auditing (alternative syntax)
AUDIT ALL PRIVILEGES;
NOAUDIT ALL PRIVILEGES;

--Login auditing (global only)
AUDIT CREATE SESSION;
NOAUDIT CREATE SESSION;

-- system privilege UPDATE ANY TABLE auditing
AUDIT UPDATE ANY TABLE;
NOAUDIT UPDATE ANY TABLE;

-- object-level DELETE auditing on table hr.emp2
AUDIT DELETE ON hr.emp2;
NOAUDIT DELETE ON hr.emp2;

-- all object-level auditing on table hr.emp2
AUDIT ALL ON hr.emp2;
NOAUDIT ALL ON hr.emp2;

-- object-level UPDATE auditing on hr.employees by user hr
AUDIT UPDATE ON hr.employees BY hr;
NOAUDIT UPDATE ON hr.employees BY hr;


select * from DBA_AUDIT_TRAIL;



Note : Can be add below
== BY SESSION
One record per session
Less audit data
Default for object auditing
== BY ACCESS
One record per action
More detailed
Default for system privileges


```

Move Unified Audit Trail
```SQL
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_location_value => 'AUDIT_DATA'
  );
END;
/
```


# auditing oracle DB


Show parameter audit;
	none - Database auditing is disabled
	os - Enabled, audit logs are stored at OS level, not inside the database
	db  - Enabled, audit records are stored inside database (SYS.AUD$ table)
	db,extended - Same as db but populates SQL_BIND & SQL_TEXT too
	xml - Enabled, audit records are stored at OS level in XML format
	xml,extended - Same as xml but populates SQL_BIND & SQL_TEXT too

```SQL
-- check tablespace_name where aud$ and FGA_LOG$ reside
col owner for a10;
col segment_name for a10;
col tablespace_name for a15;
select owner, segment_name, segment_type, tablespace_name, 
  bytes/1024/1024 as MB 
from dba_segments 
where segment_name in ('AUD$','FGA_LOG$');


-- move aud$ and FGA_LOG$ to USERS tablespace
BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
audit_trail_location_value => 'USERS');
END;
/

-- move aud$ to USERS tablespace
BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD
audit_trail_location_value => 'USERS');
END;
/

-- move FGA_LOG$ to USERS tablespace
BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD
audit_trail_location_value => 'USERS');
END;
/
```


----- Schema and user level auditing
```SQL
- Audit the select table and update table query issued by user 'hr' or 'oe'
AUDIT SELECT TABLE, UPDATE TABLE  BY hr, oe;

- Run the script to create audit statement to enable auditing on table on particular schema
select 'audit select on ' || owner.table_name || '  by access ' from dba_tables where owner='target_schema; -- (Traditional)
AUDIT ALL ON hr.employees_seq; -- (Traditional)

CREATE AUDIT POLICY mypolicy ACTIONS CHANGE PASSWORD; --(unified)
AUDIT POLICY mypolicy;

- This will show you audit recored stored in the database - all standard audits
SELECT * FROM DBA_AUDIT_TRAIL;
 
- When unified auditing is enabled 
SELECT * FROM UNIFIED_AUDIT_TRAIL;
SELECT policy_name, enabled_option, entity_name, success, failure FROM audit_unified_enabled_policies;

- stop auditing 
NOAUDIT SELECT TABLE BY hr; -- (Traditional)

NOAUDIT POLICY mypolicy; --(unified) (all user)
NOAUDIT POLICY mypolicy BY HR ; --(unified) (all user)
```


