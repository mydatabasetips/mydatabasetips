--Unified Audit trail

select sessionid,os_username,userhost,terminal,authentication_type,dbusername,client_program_name,event_timestamp,action_name,return_code
from unified_audit_trail
order by EVENT_TIMESTAMP DESC fetch first 200 rows only

https://www.oradba.ch/wordpress/2019/09/audit-trail-cleanup-in-oracle-multitenant-environments/
https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_AUDIT_MGMT.html#GUID-53CCE6BF-9F19-4356-9363-0AE83316DB85
