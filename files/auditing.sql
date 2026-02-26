--Unified Audit trail

select sessionid,os_username,userhost,terminal,authentication_type,dbusername,client_program_name,event_timestamp,action_name,return_code
from unified_audit_trail
order by EVENT_TIMESTAMP DESC fetch first 200 rows only

https://www.oradba.ch/wordpress/2019/09/audit-trail-cleanup-in-oracle-multitenant-environments/
https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_AUDIT_MGMT.html#GUID-53CCE6BF-9F19-4356-9363-0AE83316DB85



--Below policies are Oracle Supplied
select distinct policy_name from audit_unified_policies order by 1;

POLICY_NAME
--------------------------------------------------------------------------------
ORA_ACCOUNT_MGMT
ORA_CIS_RECOMMENDATIONS
ORA_DATABASE_PARAMETER
ORA_DV_AUDPOL
ORA_DV_AUDPOL2
ORA_LOGON_FAILURES
ORA_RAS_POLICY_MGMT
ORA_RAS_SESSION_MGMT
ORA_SECURECONFIG

9 rows selected.

--enabled policies

SELECT * FROM audit_unified_enabled_policies;

select policy_name,audit_option,audit_option_type,object_schema,object_name,object_type,audit_only_toplevel,oracle_supplied
from audit_unified_policies where policy_name='ORA_SECURECONFIG' order by 1,2,3; 

select dbusername,os_username,userhost,client_program_name,event_timestamp,object_schema,object_name,sql_text,system_privilege_used,unified_audit_policies
from unified_audit_trail 
where action_name not in ('LOGON')
and event_timestamp> to_date('20-01-2024 00:00:00','dd-mm-yyyy hh24:mi:ss')
order by event_timestamp desc;


select dbusername,os_username,userhost,client_program_name,event_timestamp,object_schema,object_name,sql_text,system_privilege_used,unified_audit_policies
from unified_audit_trail 
where action_name not in ('LOGON')
and object_schema='HRP_OWNER' 
and event_timestamp between to_date('01-12-2023 00:00:00','dd-mm-yyyy hh24:mi:ss') and to_date('01-01-2024 00:00:00','dd-mm-yyyy hh24:mi:ss')
order by event_timestamp asc;



https://gavinsoorma.com.au/knowledge-base/unified-auditing-getting-started/
https://asktom.oracle.com/ords/f?p=100:11:::::P11_QUESTION_ID:9546719300346136115

CREATE AUDIT POLICY HRP_OWNER_POLICY
  ACTIONS DELETE on HRP_OWNER.D_EMPLOYEE,
          INSERT on HRP_OWNER.D_EMPLOYEE,
          UPDATE on HRP_OWNER.D_EMPLOYEE,
          SELECT on HRP_OWNER.D_EMPLOYEE;
		  
		  
CREATE AUDIT POLICY HRP_OWNER_POLICY
 ACTIONS ALL ON HRP_OWNER.D_EMPLOYEE;
 
--to enable audit policy
AUDIT POLICY HRP_OWNER_POLICY;

--to disable audit policy

NOAUDIT POLICY HRP_OWNER_POLICY;
 
select  'ALTER AUDIT POLICY HRP_OWNER_POLICY ADD ACTIONS ALL ON '|| owner ||'.'||table_name||';' 
from dba_tables
where  owner='HRP_OWNER'
order by table_name asc;

SELECT * FROM audit_unified_enabled_policies;

select policy_name,audit_option,audit_option_type,object_schema,object_name,object_type,audit_only_toplevel,oracle_supplied
from audit_unified_policies where policy_name='HRP_OWNER_POLICY' order by 1,2,3; 



CREATE AUDIT POLICY DASHBOARD_OWNER_POLICY
 ACTIONS ALL ON DASHBOARD_OWNER.SGA_COMMENTARY;
 
AUDIT POLICY DASHBOARD_OWNER_POLICY;
 
--to drop
noaudit policy DASHBOARD_OWNER_POLICY ;
drop audit policy DASHBOARD_OWNER_POLICY;


 
set pages 500
set lines 300
select  'ALTER AUDIT POLICY DASHBOARD_OWNER_POLICY ADD ACTIONS ALL ON '|| owner ||'.'||table_name||';' 
from dba_tables
where  owner='DASHBOARD_OWNER'
union
select  'ALTER AUDIT POLICY DASHBOARD_OWNER_POLICY ADD ACTIONS ALL ON '|| owner ||'.'||view_name||';' 
from dba_views
where  owner='DASHBOARD_OWNER';


select policy_name,audit_option,audit_option_type,object_schema,object_name,object_type,audit_only_toplevel,oracle_supplied
from audit_unified_policies where policy_name='SGA_OWNER_POLICY' order by 1,2,3; 

SELECT policy_name, enabled_option, entity_name
  FROM audit_unified_enabled_policies
  WHERE policy_name = 'SGA_OWNER_POLICY';


--SGA_OWNER.SGA_LABOR_BY_PERSON
CREATE AUDIT POLICY SGA_OWNER_POLICY 
 ACTIONS ALL ON SGA_OWNER.SGA_LABOR_BY_PERSON;
 
--enabled for all users
AUDIT POLICY SGA_OWNER_POLICY;

set pages 100
set lines 300
col OS_USERNAME for a20
col USERHOST for a24
col TERMINAL for a20
col CLIENT_PROGRAM_NAME for a20
col EVENT_TIMESTAMP for a28
col ACTION_NAME for a20
col SQL_TEXT for a30
select os_username,userhost,terminal,client_program_name,event_timestamp,action_name,sql_text
from  unified_audit_trail where object_name='SGA_LABOR_BY_PERSON'
order by event_timestamp asc;

select os_username,userhost,terminal,client_program_name,event_timestamp,action_name,sql_text
from  unified_audit_trail where object_name='SGA_LABOR_BY_PERSON'
order by event_timestamp asc;

--to drop
noaudit policy SGA_OWNER_POLICY ;
drop audit policy SGA_OWNER_POLICY;


********************************
--DWQAS setup

https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/introduction-to-auditing.html#GUID-57897757-4F56-4E7D-9E81-1372AF3ADF1D
https://gavinsoorma.com.au/knowledge-base/unified-auditing-getting-started/
How To Enable The New Unified Auditing In 12c and 19c? (Doc ID 1567006.1)	
How To Enable Unified Audit binaries on RAC Nodes ? (Doc ID 2371837.1)
12c Unified Auditing used with Data Guard (Doc ID 2021747.1)

/* not doing any of these as for now we can use mixed mode instead of pure unified auditing

CREATE TABLESPACE AUDIT_DATA DATAFILE '+SPRC1' SIZE 100M AUTOTEND ON MAXSIZE 30G;

BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION
(
 audit_trail_type => dbms_audit_mgmt.audit_trail_unified,
 audit_trail_location_value => 'AUDIT_DATA'
);
END;
/


--purge audit trail job

BEGIN
DBMS_AUDIT_MGMT.CREATE_PURGE_JOB
 (
  AUDIT_TRAIL_TYPE            => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
  AUDIT_TRAIL_PURGE_INTERVAL  => 24,
  AUDIT_TRAIL_PURGE_NAME      => ‘Unified_Audit_Trail_Purge_Job’,
  USE_LAST_ARCH_TIMESTAMP     => TRUE,
  CONTAINER                   => DBMS_AUDIT_MGMT.CONTAINER_CURRENT
  );
END;
/ 
8?
