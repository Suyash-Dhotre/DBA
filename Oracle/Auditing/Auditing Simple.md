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
