set pages 1000
set lines 200
col category for a16
col SubCategory for a34
col value for a100
select 'DB Config' as Category, '0 - Name' as SubCategory, name as value
from v$database
union all
select 'DB Config', '1 - No of instances', to_char(count(*))
from gv$instance
union all 
select 'DB Config', '2 - Database Version', version
from v$instance
union all
select 'DB Config', '3 - Character Set' ,  to_char(value)
from nls_database_parameters
where PARAMETER = 'NLS_CHARACTERSET'
union all
select 'DB Config', '4 - NLS_Characterset' , to_char(value)
from nls_database_parameters
where PARAMETER = 'NLS_NCHAR_CHARACTERSET'
union all
select  'DB Config', '5 - Application Schemas', rtrim (xmlagg (xmlelement (e,   username  || ',')).extract ('//text()'), ',')
from dba_users
where username not  in (select name from   sys.ku_noexp_tab where obj_type='SCHEMA')
and username not like 'EMR_DBA_%' and username not like 'DBA_%'
and username not like 'DBV_%' and   username not like 'SEC_%'
and username not like 'IFS_%' and username not like 'EMER_%'
and username not like '%AUTOINSTALL%'
--and username not like '%AUD%'
and username not in ('SYSTEM', 'OUTLN', 'PATMON','PATROL', 'OEM_FID' ,'ADMIN_ORAAS', 'SQLTXPLAIN')
union all
select 'DB Config', '6 - Data Guard Protection Mode', protection_mode
from v$database
union all
select 'DB Config', '7 - Archivelog Mode', log_mode
from v$database
union all
select 'DB Options', '1 - Partitioning', decode(count(1), 0, 'NO', 'YES' ) as "Partitioning"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name = 'Partitioning (user)'
union all
select  'DB Options','2 - OLAP', decode(count(1), 0, 'NO', 'YES' ) as "OLAP"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name like 'OLAP%'
union all
select  'DB Options', '3 - Oracle Text', decode(count(1), 0, 'NO', 'YES' ) as "Oracle Text"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name = 'Oracle Text'
union all
select  'DB Options', '4 - Golden Gate', decode(count(1), 0, 'NO', 'YES' ) as "Golden Gate"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name = 'GoldenGate'
union all
select 'DB Options', '5 - RAC', decode(count(1), 0, 'NO', 'YES' ) as "RAC"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name = 'Real Application Clusters (RAC)'
union all
select  'DB Options', '6 - Data Guard', decode(count(1), 0, 'NO', 'YES' ) as "Data Guard"
from DBA_FEATURE_USAGE_STATISTICS
where CURRENTLY_USED = 'TRUE'
and name = 'Data Guard'
union all
select  'DB Options', '7 - DB Links' , decode(count(1), 0, 'NO', 'YES' ) as "DB Links"
from dba_db_links
union all
select  'DB Options', '8 - UTL_FILE Usage',  decode(count(1), 0, 'NO', 'YES' ) as "UTL_FILE Usage"
from dba_source
where upper(text) like '%UTL_FILE%'
and owner not in (select name from   sys.ku_noexp_tab where obj_type='SCHEMA')
and owner not in ('SYSTEM', 'OUTLN', 'PATMON','PATROL', 'OEM_FID' ,'ADMIN_ORAAS','SQLTXPLAIN')
union all
select  'DB Size', '1 - CPU Count', to_char(value)
from v$parameter where upper(name) ='CPU_COUNT'
union all
select  'DB Size', '2 - SGA Size', to_char(max(value)/1024/1024/1024 ) || ' GB'
from v$parameter where upper(name) like  'SGA%'
union all
select  'DB Size', '3 - PGA Size', to_char(max(value)/1024/1024/1024 ) || ' GB'
from v$parameter where upper(name) like  'PGA%'
union all
select  'DB Size', '4 - Memory Target Size', to_char(max(value)/1024/1024/1024 ) || ' GB'
from v$parameter where upper(name) like  'MEMORY_TARGET%'
union all
select  'DB Size', '5 - Concurrent Sessions', to_char(max(current_utilization))
from DBA_HIST_RESOURCE_LIMIT
where resource_name = 'sessions'
union all
select  'DB Size', '6 - Transactions per second', to_char(ceil(max(diff_value/timesec)) )
from (
SELECT round((cast(b.end_interval_time as date) - cast(b.begin_interval_time  as date)) *86400) as timesec,
a.VALUE - LAG (a.VALUE) OVER (PARTITION BY a.dbid,a.instance_number,a.stat_name
ORDER BY a.snap_id) diff_value -- difference in value from previous
FROM dba_hist_sysstat a,    dba_hist_snapshot b
WHERE a.stat_name IN ('user commits', 'user rollbacks')
and a.snap_id = b.snap_id
)
union all
select  'DB Size', '7 - Database block size' , to_char(VALUE)/1024 || ' KB'
from v$parameter where NAME = 'db_block_size'
union all
SELECT 'DB Size', '8 - Redo log size per hour',
decode(max(b.log_mode), 'ARCHIVELOG',  'ARCHIVELOG MODE: ' || max(round(SUM(blocks*block_size)/1024/1024/1024,0)) ||  ' GB', 'NOARCHIVELOG MODE: 0 GB')
FROM v$archived_log a, v$database b
where dest_id  = 1 and thread#=1
GROUP BY  b.log_mode, TRUNC(completion_time)
union all
SELECT  'DB Size', '9 - Redo log switches per hour', to_char(max(count(*)))
FROM   v$log_history a
WHERE  thread#=1
and first_time > sysdate-14
GROUP BY    to_char(first_time, 'yyyy/mm/dd'),
              to_char(first_time, 'hh24')
union all
select 'DB Size', '10 - Database size (file count)', to_char(count(1))
from v$datafile
union all
select 'DB Size', '11 - Database size (allocated)', to_char(round(sum(bytes)/1024/1024/1024))|| ' GB'
from v$datafile
union all
select 'DB Size', '12 - Database size (Actual)', to_char(round(sum(bytes)/1024/1024/1024)) || ' GB'
from dba_segments
order by 1 ,2
/
