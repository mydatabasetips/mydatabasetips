set pages 200
set lines 300

spool disable_con.sql

select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a
where a.constraint_type = 'R' and a.status='ENABLED'
and a.owner='SM_HIST'
and a.table_name in 
(
'STG_ENT_MFR_VDA_INVCD'
)order by a.table_name;


select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_HIST'
and b.table_name in 
(
'STG_ENT_MFR_VDA_INVCD'
)
order by a.table_name;

spool off


spool enable_con.sql


select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a
where a.constraint_type = 'R' and a.status='ENABLED'
and a.owner='SM_HIST'
and a.table_name in 
(
select tablename from PKANCHERLA.SM_HIST_PARTLIST
where partitioned='NO'
)order by a.table_name;;


select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constrain '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_HIST'
and b.table_name in 
(
select tablename from PKANCHERLA.SM_HIST_PARTLIST
where partitioned='NO'
)
order by a.table_name;

spool off