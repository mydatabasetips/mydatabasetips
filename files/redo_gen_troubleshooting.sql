


https://docs.oracle.com/en/database/oracle/oracle-database/18/refrn/V-LOGMNR_CONTENTS.html#GUID-B9196942-07BF-4935-B603-FA875064F5C3
https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_LOGMNR.html#GUID-C1E24B58-CA7A-484D-99B8-BF304B22C412

Simple Steps to use Log Miner for finding high redo log generation (Doc ID 1504755.1)
**Imp -- How To Determine The Cause Of Lots Of Redo Generation Using LogMiner (Doc ID 300395.1) 


set pages 1000
set lines 300
col day for a12
SELECT TRUNC(COMPLETION_TIME,'DD') DAY,
ROUND(SUM(BLOCKS*BLOCK_SIZE)/(1024*1024*1024)) SIZE_GB,
COUNT(*) Archives_Generated
FROM v$archived_log
WHERE TRUNC(COMPLETION_TIME,'DD') > sysdate-15
and CREATOR in ('ARCH','FGRD') 
GROUP BY TRUNC(COMPLETION_TIME,'DD') 
ORDER BY 1;

creator,name,archived,applied,deleted

col name for a75
set pages 100
set lines 300

SELECT NAME,THREAD#,SEQUENCE#,CREATOR,ARCHIVED,APPLIED,DELETED,STATUS FROM V$ARCHIVED_LOG where 
completion_time between  to_timestamp('2022-01-21 10:30:00','yyyy-mm-dd hh24:mi:ss') and  to_timestamp('2022-01-21 11:00:00','yyyy-mm-dd hh24:mi:ss')
and CREATOR in ('ARCH','FGRD') 
order by completion_time asc;


select 'exec dbms_logmnr.add_logfile(logfilename => '''||name||''');'  FROM V$ARCHIVED_LOG where 
completion_time between  to_timestamp('2022-01-21 10:30:00','yyyy-mm-dd hh24:mi:ss') and  to_timestamp('2022-01-21 11:00:00','yyyy-mm-dd hh24:mi:ss')
and CREATOR in ('ARCH','FGRD') 
order by completion_time asc;

select 'exec dbms_logmnr.add_logfile(logfilename => '''||name||''', OPTIONS => DBMS_LOGMNR.NEW);'  FROM V$ARCHIVED_LOG where 
completion_time between  to_timestamp('2022-01-21 10:30:00','yyyy-mm-dd hh24:mi:ss') and  to_timestamp('2022-01-21 11:00:00','yyyy-mm-dd hh24:mi:ss')
and CREATOR in ('ARCH','FGRD') 
order by completion_time asc;

	set heading on
	set pagesize 5000
	col scn format 9999999999999999
	set numformat 9999999999999999999999 LONG 50000
	alter session set nls_date_format='dd-mon-yyyy hh24:mi:ss';	
	
	
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_2_seq_22478.277.1094553273');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_1_seq_25100.1494.1094553397');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_2_seq_22479.378.1094553809');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_1_seq_25101.834.1094553857');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_1_seq_25102.592.1094554321');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_2_seq_22480.919.1094554337');
exec dbms_logmnr.add_logfile(logfilename => '+REDO/ARFCNFT/ARCHIVELOG/2022_01_21/thread_1_seq_25103.1386.1094554773');

exec dbms_logmnr.start_logmnr(options => dbms_logmnr.dict_from_online_catalog + dbms_logmnr.no_rowid_in_stmt);


col username for a10
col seg_owner for a10
col seg_name for a35
select distinct operation,username,seg_owner from v$logmnr_contents ;

select seg_name,operation,count(*) cnt from v$logmnr_contents where seg_owner='FLEXAR' group by seg_name,operation order by cnt desc 
fetch first 100 rows only;

SELECT username AS USR, 
     (XIDUSN || '.' || XIDSLT || '.' || XIDSQN) AS XID, 
     operation, 
     SQL_REDO, 
     SQL_UNDO 
     FROM V$LOGMNR_CONTENTS 
     WHERE seg_owner ='FLEXAR' fetch first 100 rows only;

 select distinct sql_redo from v$logmnr_contents;

exec dbms_logmnr.end_logmnr();   



***************************

How to identify the causes of High Redo Generation (Doc ID 2265722.1)
set pages 1000
set lines 300
col program for a80
col module for a40

select 
   ss.sid,
   'redo size:'||ss.value,
   s.program,
   s.module
from 
   v$statname 
   sn,v$sesstat 
   ss,v$session s
where 
   ss.statistic#=sn.statistic# 
and
   sn.name='redo size' 
and
   s.sid=ss.sid 
and
   ss.value>0
order by ss.value desc
 fetch first 100 rows only ;
 
  SELECT s.sid,
         sn.SERIAL#,
         n.name,
         ROUND (VALUE / 1024 / 1024, 2) redo_mb,
         sn.username,
         sn.status,
         sn.program,
         sn.TYPE,
         sn.module,
         sn.sql_id
    FROM v$sesstat s
         JOIN v$statname n ON n.statistic# = s.statistic#
         JOIN v$session sn ON sn.sid = s.sid
   WHERE n.name LIKE 'redo size' AND s.VALUE != 0
ORDER BY redo_mb DESC
 fetch first 100 rows only;

col MODULE for a25
select s.sid,sn.SERIAL#,n.name, round(value/1024/1024,2) redo_mb, sn.username,sn.status,substr (sn.program,1,21)
"program", sn.type, sn.module,sn.sql_id
from v$sesstat s join v$statname n on n.statistic# = s.statistic#
join v$session sn on sn.sid = s.sid where n.name like 'redo size' and s.value!=0 order by
redo_mb desc
fetch first 100 rows only;

/**
Troubleshooting High Redo Generation Issues (Doc ID 782935.1)
How to Find Sessions Generating Lots of Redo or Archive logs (Doc ID 167492.1)

set pages 100
set lines300
col username for a15
col program for a45
SELECT s.sid, s.serial#, s.username, s.program,
           i.block_changes
           FROM v$session s, v$sess_io i
           WHERE s.sid = i.sid
           ORDER BY 5 desc, 1, 2, 3, 4;
		 
		 
Simple Steps to use Log Miner for finding high redo log generation (Doc ID 1504755.1)
**Imp -- How To Determine The Cause Of Lots Of Redo Generation Using LogMiner (Doc ID 300395.1)
**Imp --How to identify the causes of High Redo Generation (Doc ID 2265722.1)
Production Databases Not Creating AWR Snapshots (Doc ID 2695000.1)
*/

--Get Timing from hourly gen rate  query

--To find segments
set pages 100
set lines 300
col OBJECT_NAME for a30
SELECT to_char(begin_interval_time,'YYYY-MM-DD HH24:MI') snap_time,
dhso.object_name,
sum(db_block_changes_delta) BLOCK_CHANGED
FROM dba_hist_seg_stat dhss,
dba_hist_seg_stat_obj dhso,
dba_hist_snapshot dhs
WHERE dhs.snap_id = dhss.snap_id
AND dhs.instance_number = dhss.instance_number
AND dhss.obj# = dhso.obj#
AND dhss.dataobj# = dhso.dataobj#
--Need to modify the time as per the above query where more redo log switch happened (keep it for 1 hour)
AND begin_interval_time BETWEEN to_date('2022-01-21 00:30','YYYY-MM-DD HH24:MI')
--Need to modify the time as per the above query where more redo log switch happened (interval shld be only 1 hour)
AND to_date('2022-01-21 11:00','YYYY-MM-DD HH24:MI') 
GROUP BY to_char(begin_interval_time,'YYYY-MM-DD HH24:MI'),
dhso.object_name
HAVING sum(db_block_changes_delta) > 0
ORDER BY sum(db_block_changes_delta) asc ;

-- Then : What SQL was causing redo log generation :

col sql for a80
set pages 100

SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24:MI') WHEN,
dbms_lob.substr(sql_text,4000,1) SQL,
dhss.instance_number INST_ID,
dhss.sql_id,
executions_delta exec_delta,
rows_processed_delta rows_proc_delta
FROM dba_hist_sqlstat dhss,
dba_hist_snapshot dhs,
dba_hist_sqltext dhst
--Update the segment name as per the result of previous query result
WHERE 
--upper(dhst.sql_text) LIKE '%SMTB_USER_DBLOG%' AND
--ltrim(upper(dhst.sql_text)) NOT LIKE 'SELECT%' AND
dhss.snap_id=dhs.snap_id
AND dhss.instance_number=dhs.instance_number
AND dhss.sql_id=dhst.sql_id
--Update time frame as required
AND begin_interval_time BETWEEN to_date('2022-01-21 00:00','YYYY-MM-DD HH24:MI')
--Update time frame as required
AND to_date('2022-01-21 11:00','YYYY-MM-DD HH24:MI') 
order by executions_delta ;



--block changes by a session

col username for a15

SELECT s.sid, s.serial#, s.username, s.program,
          i.block_changes
         FROM v$session s, v$sess_io i
        WHERE s.sid = i.sid
   ORDER BY 5 asc, 1, 2, 3, 4;

select count(*),to_char(COMPLETION_TIME, 'YYYY-MM-DD') "Day", archived 
from v$archived_log
group by to_char(COMPLETION_TIME, 'YYYY-MM-DD'),archived
order by 2,3;

--Run below query to know the session generating high redo at any specific time.

col program for a10
col username for a10
select to_char(sysdate,'hh24:mi'), username, program , a.sid, a.serial#, b.name, c.value
from v$session a, v$statname b, v$sesstat c
where b.STATISTIC# =c.STATISTIC#
and c.sid=a.sid and b.name like 'redo%'
order by value;

