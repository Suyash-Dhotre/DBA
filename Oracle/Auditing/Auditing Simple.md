# Unified auditing

``` SQL
SELECT value FROM v$option WHERE parameter = 'Unified Auditing';
select * from audit_unified_policies;
select * from audit_unified_enabled_policies;

select * from UNIFIED_AUDIT_TRAIL;

Create Audit policy TESTPOLICY  Actions all;

audit policy TESTPOLICY by HR;
noaudit policy TESTPOLICY by HR;

Drio Audit policy TESTPOLICY;
```

# Traditional auditing

''' SQL


...
