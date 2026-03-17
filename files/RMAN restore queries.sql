--RMAN


--Shows full backups initiated in past 7 days and successfully completed SELECT

set pages 100
set lines 300
col STARTTIME for a20
col ENDTIME for a20
col INBYTES for a10
col OUTBYTES for a10

SELECT
     TO_CHAR(START_TIME,'YYYY-MM-DD HH24:MI') STARTTIME,
     TO_CHAR(END_TIME,'YYYY-MM-DD HH24:MI') ENDTIME,
     STATUS,
     INPUT_TYPE,
     INPUT_BYTES_DISPLAY INBYTES,
     OUTPUT_BYTES_DISPLAY OUTBYTES
FROM
--RMAN_BSSPRDDB1_BSSPRD.RC_RMAN_BACKUP_JOB_DETAILS
V$RMAN_BACKUP_JOB_DETAILS
WHERE
STATUS LIKE '%COMPLETED%'
AND INPUT_TYPE LIKE '%DB%'
--AND START_TIME > trunc(SYSDATE)-30
ORDER BY START_TIME;

https://www.dba-oracle.com/t_rman_recovery_window_retention.htm

Expired: the backup exists in the RMAN administration, but is no longer available on disk or tape.
obsolete: the backup is no longer required to satisfy the recovery window.
Rman backup retention policy (Doc ID 462978.1)

set pages 100
set lines 300
col STARTTIME for a20
col ENDTIME for a20
col INBYTES for a10
col OUTBYTES for a10

SELECT
     TO_CHAR(START_TIME,'YYYY-MM-DD HH24:MI') STARTTIME,
     TO_CHAR(END_TIME,'YYYY-MM-DD HH24:MI') ENDTIME,
     STATUS,
     INPUT_TYPE,
     INPUT_BYTES_DISPLAY INBYTES,
     OUTPUT_BYTES_DISPLAY OUTBYTES
FROM
RMAN_BSSPRDDB1_BSSPRD.RC_RMAN_BACKUP_JOB_DETAILS
--V$RMAN_BACKUP_JOB_DETAILS
WHERE
STATUS LIKE '%COMPLETED%'
--AND INPUT_TYPE LIKE '%DB%'
--AND START_TIME > trunc(SYSDATE)-30
ORDER BY START_TIME;


set pages 100
set lines 300
col STARTTIME for a20
col ENDTIME for a20
col INBYTES for a10
col OUTBYTES for a10

SELECT
     trunc(START_TIME) BACKUPDATE,
     SUM(OUTPUT_BYTES_DISPLAY) TOTALBYTESPONTHEDAY
FROM
RMAN_BSSPRDDB1_BSSPRD.RC_RMAN_BACKUP_JOB_DETAILS
--V$RMAN_BACKUP_JOB_DETAILS
WHERE
STATUS LIKE '%COMPLETED%'
--AND INPUT_TYPE LIKE '%DB%'
--AND START_TIME > trunc(SYSDATE)-30
GROUP BY trunc(START_TIME)
ORDER BY trunc(START_TIME);



SELECT
     TO_CHAR(START_TIME,'YYYY-MM-DD HH24:MI') STARTTIME,
     TO_CHAR(END_TIME,'YYYY-MM-DD HH24:MI') ENDTIME,
     STATUS,
     INPUT_TYPE,
     INPUT_BYTES_DISPLAY INBYTES,
     OUTPUT_BYTES_DISPLAY OUTBYTES
FROM
--RC_RMAN_BACKUP_JOB_DETAILS
V$RMAN_BACKUP_JOB_DETAILS
WHERE
--STATUS LIKE '%COMPLETED%' AND
INPUT_TYPE LIKE '%DB%'
AND START_TIME > trunc(SYSDATE)-30
ORDER BY START_TIME;


 SELECT TO_CHAR(completion_time, 'YYYY-MON-DD') completion_time, type, round(sum(bytes)/1048576) MB, round(sum(elapsed_seconds)/60) min
 FROM
 (
 SELECT
 CASE
   WHEN s.backup_type='L' THEN 'ARCHIVELOG'
   WHEN s.controlfile_included='YES' THEN 'CONTROLFILE'
   WHEN s.backup_type='D' AND s.incremental_level=0 THEN 'LEVEL0'
   WHEN s.backup_type='I' AND s.incremental_level=1 THEN 'LEVEL1'
 END type,
 TRUNC(s.completion_time) completion_time, p.bytes, s.elapsed_seconds
 FROM v$backup_piece p, v$backup_set s
 WHERE p.status='A' AND p.recid=s.recid
 UNION ALL
 SELECT 'DATAFILECOPY' type, TRUNC(completion_time), output_bytes, 0 elapsed_seconds FROM v$backup_copy_details
 )
 GROUP BY TO_CHAR(completion_time, 'YYYY-MON-DD'), type
 ORDER BY 1 ASC,2,3
 ;

/***********************************************************************************************************************/


/*****Restore Status queries - Start *****/
TTITLE LEFT '% Completed. Aggregate is the overall progress:'
SET LINE 132
SELECT opname, round(sofar/totalwork*100) "% Complete"
  FROM gv$session_longops
 WHERE opname LIKE 'RMAN%'
   AND totalwork != 0
   AND sofar <> totalwork
 ORDER BY 1;
 
 
TTITLE LEFT 'Channels waiting:'
COL client_info FORMAT A15 TRUNC
COL event FORMAT A20 TRUNC
COL state FORMAT A7
COL wait FORMAT 999.90 HEAD "Min waiting"
SELECT s.sid, p.spid, s.client_info, status, event, state, seconds_in_wait/60 wait
  FROM gv$process p, gv$session s
 WHERE p.addr = s.paddr
   AND client_info LIKE 'rman%';
   
   
   
TTITLE LEFT 'Files currently being written to:'
COL filename FORMAT a50
SELECT filename, bytes, io_count
  FROM v$backup_async_io
 WHERE status='IN PROGRESS';


TTITLE OFF
SET HEAD OFF
SELECT 'Throughput: '||
       ROUND(SUM(v.value/1024/1024),1) || ' Meg so far @ ' ||
       ROUND(SUM(v.value     /1024/1024)/NVL((SELECT MIN(elapsed_seconds)
            FROM v$session_longops
            WHERE opname          LIKE 'RMAN: aggregate input'
              AND sofar           != TOTALWORK
              AND elapsed_seconds IS NOT NULL
       ),SUM(v.value     /1024/1024)),2) || ' Meg/sec'
 FROM gv$sesstat v, v$statname n, gv$session s
WHERE v.statistic# = n.statistic#
  AND n.name       = 'physical write total bytes'
  AND v.sid        = s.sid
  AND v.inst_id    = s.inst_id
  AND s.program LIKE 'rman@%'
GROUP BY n.name
/
SET HEAD ON

/*****Restore Status queries - End *****/


**** RMAN INFO ****

Set lines 200
Set pages 300
col SCHEMANAME for a15
col OSUSER for a15
col MACHINE for a18
col SPID for 99999999
select to_char(sysdate -(LAST_CALL_ET/86400),'DD-MON-YY hh24:mi:ss') LAST_CALL, s.status, s.process,s.program, s.schemaname,
s.sid, s.serial#, p.spid, s.osuser, S.machine, S.terminal, to_char(S.logon_time,'DD-MM-YYYY hh24.mi.ss') LOGON_TIME 
from gv$session S,
dba_users U,
gv$process P
where P.ADDR = S.PADDR
and S.user# = U.user_id
and s.type ='USER'
and s.username is not null
and s.program like '%rman%' 
order by LOGON_TIME asc ;


set pages 1000
set lines 400
col EVENT for a30
col HANDLE for a25
col PIN_ADDR for a25

select a.sid Waiter,b.SERIAL#,a.event,a.p1raw,
substr(rawtohex(a.p1),1,30) Handle,
substr(rawtohex(a.p2),1,30) Pin_addr
from v$session_wait a,v$session b where a.sid=b.sid
and a.wait_time=0 and b.program like '%rman%';

select a.* 
from v$session_wait a,v$session b where a.sid=b.sid
and a.wait_time=0 and b.program like '%rman%';


select * from gv$session where program like '%rman%';


	select 'alter system kill session '''||sid||','||serial#||',@'||inst_id||''' immediate;'
	from gv$session where program like '%rman%' order by LOGON_TIME asc;


connect target sys/temp_pwd1A@dwpdcdb
connect catalog rman_ash_dwpdcdb/rman_ash@RCATPDB
run {
allocate channel for maintenance type type sbt PARMS='SBT_LIBRARY=/acfs01/dbaas_acfs/dwpdcdb/opc/libopc.so,SBT_PARMS=(OPC_PFILE=/acfs01/dbaas_acfs/dwpdcdb/opc/opcdwpdcdb.ora)';
DELETE FORCE NOPROMPT BACKUP COMPLETED BEFORE 'SYSDATE-900';
}

nohup rman cmdfile=/u00/ora/prod/dwpdcdb_delete.rman log=/u00/ora/files/dwpdcdb_delete.out &

nohup rman cmdfile=/u00/ora/prod/dwpdcdb_delete_wocat.rman log=/u00/ora/files/dwpdcdb_delete_rman.out &


cat /u00/ora/files/dwpdcdb_delete.rman
	
connect target sys/temp_pwd1A@dwpdcdb
connect catalog rman_ash_dwpdcdb/rman_ash@RCATPDB
allocate channel for maintenance device type sbt PARMS='SBT_LIBRARY=/acfs01/dbaas_acfs/dwpdcdb/opc/libopc.so,SBT_PARMS=(OPC_PFILE=/acfs01/dbaas_acfs/dwpdcdb/opc/opcdwpdcdb.ora)';
delete force noprompt obsolete recovery window of 35 days;
delete force noprompt expired backup;
crosscheck backup;
release channel;
exit;

[oracle@exasod-prod-rppit2 files]$ cat /u00/ora/prod/dwpdcdb_delete_wocat.rman
connect target sys/temp_pwd1A@dwpdcdb
ALLOCATE CHANNEL FOR MAINTENANCE DEVICE TYPE DISK;
allocate channel for maintenance device type sbt PARMS='SBT_LIBRARY=/acfs01/dbaas_acfs/dwpdcdb/opc/libopc.so,SBT_PARMS=(OPC_PFILE=/acfs01/dbaas_acfs/dwpdcdb/opc/opcdwpdcdb.ora)';
delete force noprompt obsolete recovery window of 35 days;
delete force noprompt expired backup;
crosscheck backup;
release channel;
exit;

nohup /u00/ora/prod/oracle_backup.sh dwpdcdb1 /u00/ora/prod/oracle_backup_dwpdcdb1_arch &
