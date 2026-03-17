https://blogs.oracle.com/optimizer/post/what-is-the-difference-between-sql-profiles-and-sql-plan-baselines


explain plan for
update GALTM_PTE.posting_request set posting_dttm=sysdate where id in ( SELECT pr.id FROM GALTM_PTE.Instruction instruction, GALTM_PTE.Journal_Entry journalEntry, GALTM_PTE.Posting_Request pr WHERE instruction.alto_Id = journalEntry.instruction_Id and journalEntry.reversal_flag = 'N' and journalEntry.clearing_return = 'N' and journalEntry.posting_Dttm is not null and journalEntry.sign = 'D' and journalEntry.entry_type = 'BKP' and pr.id=journalentry.posting_request_id and instruction.posted_Datetime is not null  and instruction.orig_Country_Code = 'BR' AND instruction.workflow_Id !='LATAM_PASSTHRU_WORKFLOW' AND instruction.payment_Type_Code not in ('088','089') AND instruction.source_System not in ('SQ01') AND instruction.state not in ('EXPIRED') and (instruction.expired_Overriden is null or instruction.expired_Overriden != 'Y' )) and rownum < 500000 ;

 @?/rdbms/admin/utlxpls.sql
 
 
select inst_id, sql_id, executions, plan_hash_value, last_active_time, trunc(elapsed_time/1000/1000/executions, 2), sql_profile, sql_plan_baseline 
from gv$sql 
where sql_id = 'g130t77uz4q7q';

select distinct 
st.instance_number, 
sql_id, 
st.snap_id, 
to_char(sn.begin_interval_time,'YYYYMMDD HH24:MI') as snaptime, 
       st.plan_hash_value, 
       st.cpu_time_delta, 
       st.elapsed_time_delta, 
       st.EXECUTIONS_delta, 
       round(st.cpu_time_delta/st.EXECUTIONS_delta/1000/1000, 2) cpu_per_execu_second, 
       round(st.ELAPSED_TIME_DELTA/st.EXECUTIONS_delta/1000/1000, 2) elap_per_execu_second 
from dba_hist_sqlstat st, 
     dba_hist_snapshot sn 
where st.snap_id = sn.snap_id 
      and sql_id = 'g130t77uz4q7q' 
      and begin_interval_time > sysdate -18 
--      and st.instance_number = 2 
      and st.EXECUTIONS_delta >= 1 
order by snaptime desc;


--AWR Plan Change --- 
set lines 155 
col execs for 999,999,999 
col avg_etime for 999,999.999 
col avg_lio for 999,999,999.9 
col begin_interval_time for a30 
col node for 99999 
break on plan_hash_value on startup_time skip 1 
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value, 
nvl(executions_delta,0) execs, 
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime, 
(buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio 
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS 
where sql_id = nvl('&sql_id','g130t77uz4q7q') 
and ss.snap_id = S.snap_id 
and ss.instance_number = S.instance_number 
and executions_delta > 0 
order by 1, 2, 3 
/


--use this
set pages 300
set lines 300 
col execs for 999,999,999 
col avg_etime for 999,999.999 
col avg_lio for 999,999,999.9 
col begin_interval_time for a32
col node for 99999 
--break on plan_hash_value on startup_time skip 1 
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value, 
nvl(executions_delta,0) execs, 
round((elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000,3) avg_etime, 
round((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)),2) avg_lio 
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS 
where sql_id = 'dgz0khdyc716q' 
and ss.snap_id = S.snap_id 
and ss.instance_number = S.instance_number 
and executions_delta > 0 
order by 3 desc
/

set serveroutput on
declare
  l_sql_tune_task_id varchar2(100);
begin
  l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id => 'g130t77uz4q7q',
                          scope => dbms_sqltune.scope_comprehensive,
                          time_limit => 600,
                          task_name => 'sql g130t77uz4q7q tuning');
  dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/

-- executing the tuning task

exec dbms_sqltune.execute_tuning_task(task_name => 'sql g130t77uz4q7q tuning');

-- displaying the recommendations
set long 1000000;
set longchunksize 10000
set pagesize 10000
set linesize 200
select dbms_sqltune.report_tuning_task('sql g130t77uz4q7q tuning') as recommendations from dual;



OUTPUT
*******

RECOMMENDATIONS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GENERAL INFORMATION SECTION
-------------------------------------------------------------------------------
Tuning Task Name   : sql g130t77uz4q7q tuning
Tuning Task Owner  : SYS
Workload Type      : Single SQL Statement
Execution Count    : 2
Current Execution  : EXEC_8550
Execution Type     : TUNE SQL
Scope              : COMPREHENSIVE
Time Limit(seconds): 600
Completion Status  : COMPLETED
Started at         : 06/08/2018 14:22:28
Completed at       : 06/08/2018 14:29:34

-------------------------------------------------------------------------------
Schema Name: GALTM_PTE
SQL ID     : g130t77uz4q7q
SQL Text   : update posting_request set posting_dttm=sysdate where id in (
             SELECT pr.id FROM Instruction instruction, Journal_Entry
             journalEntry, Posting_Request pr
             WHERE instruction.alto_Id = journalEntry.instruction_Id and
             journalEntry.reversal_flag = 'N' and
             journalEntry.clearing_return = 'N' and journalEntry.posting_Dttm
             is not null and journalEntry.sign = 'D' and
             journalEntry.entry_type = 'BKP'
             and pr.id=journalentry.posting_request_id and
             instruction.posted_Datetime is not null
             and instruction.orig_Country_Code = 'BR' AND
             instruction.workflow_Id !='LATAM_PASSTHRU_WORKFLOW' AND
             instruction.payment_Type_Code not in ('088','089')
             AND instruction.source_System not in ('SQ01') AND
             instruction.state not in ('EXPIRED') and
             (instruction.expired_Overriden is null or
             instruction.expired_Overriden != 'Y' )) and rownum < 500000

-------------------------------------------------------------------------------
FINDINGS SECTION (6 findings)
-------------------------------------------------------------------------------

1- SQL Profile Finding (see explain plans section below)
--------------------------------------------------------
  A potentially better execution plan was found for this statement.

  Recommendation (estimated benefit: 98.08%)
  ------------------------------------------
  - Consider accepting the recommended SQL profile.
    execute dbms_sqltune.accept_sql_profile(task_name => 'sql g130t77uz4q7q
            tuning', task_owner => 'SYS', replace => TRUE);

2- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  Predicate "INSTRUCTION"."STATE"<>'EXPIRED' used at line ID 8 of the
  execution plan is an inequality condition on indexed column "STATE". This
  inequality condition prevents the optimizer from selecting indices  on table
  "GALTM_PTE"."INSTRUCTION".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices.

3- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  Predicate "INSTRUCTION"."SOURCE_SYSTEM"<>'SQ01' used at line ID 8 of the
  execution plan is an inequality condition on indexed column "SOURCE_SYSTEM".
  This inequality condition prevents the optimizer from efficiently using
  indices on table "GALTM_PTE"."INSTRUCTION".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices.

4- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  Predicate "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'088' used at line ID 8 of the
  execution plan is an inequality condition on indexed column
  "PAYMENT_TYPE_CODE". This inequality condition prevents the optimizer from
  selecting indices  on table "GALTM_PTE"."INSTRUCTION".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices.

5- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  Predicate "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'089' used at line ID 8 of the
  execution plan is an inequality condition on indexed column
  "PAYMENT_TYPE_CODE". This inequality condition prevents the optimizer from
  selecting indices  on table "GALTM_PTE"."INSTRUCTION".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices.

6- Restructure SQL finding (see plan 1 in explain plans section)
----------------------------------------------------------------
  Predicate "INSTRUCTION"."WORKFLOW_ID"<>'LATAM_PASSTHRU_WORKFLOW' used at
  line ID 8 of the execution plan is an inequality condition on indexed column
  "WORKFLOW_ID". This inequality condition prevents the optimizer from
  selecting indices  on table "GALTM_PTE"."INSTRUCTION".

  Recommendation
  --------------
  - Rewrite the predicate into an equivalent form to take advantage of
    indices.

-------------------------------------------------------------------------------
EXPLAIN PLANS SECTION
-------------------------------------------------------------------------------

1- Original With Adjusted Cost
------------------------------
Plan hash value: 932209772

-------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                          | Name                       | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------------------------
|   0 | UPDATE STATEMENT                   |                            | 25063 |    11M|       |    65M  (1)|217:18:09 |
|   1 |  UPDATE                            | POSTING_REQUEST            |       |       |       |            |          |
|*  2 |   COUNT STOPKEY                    |                            |       |       |       |            |          |
|*  3 |    HASH JOIN                       |                            | 25063 |    11M|    14M|    65M  (1)|217:18:09 |
|   4 |     VIEW                           | VW_NSO_1                   |   104K|    12M|       |    64M  (1)|216:00:12 |
|   5 |      SORT UNIQUE                   |                            |   104K|    13M|  1856M|    64M  (1)|216:00:12 |
|   6 |       NESTED LOOPS                 |                            |    12M|  1602M|       |    64M  (1)|215:33:28 |
|   7 |        NESTED LOOPS                |                            |   100M|  1602M|       |    64M  (1)|215:33:28 |
|*  8 |         TABLE ACCESS BY INDEX ROWID| INSTRUCTION                |    14M|  1077M|       |  7952K  (1)| 26:30:27 |
|*  9 |          INDEX RANGE SCAN          | INSTR_COUNTRY_IDX          |    20M|       |       | 50307   (1)| 00:10:04 |
|* 10 |         INDEX RANGE SCAN           | JOURNAL_ENTRY_INSTR_ID_IDX |     7 |       |       |     3   (0)| 00:00:01 |
|* 11 |        TABLE ACCESS BY INDEX ROWID | JOURNAL_ENTRY              |     1 |    57 |       |     5   (0)| 00:00:01 |
|  12 |     TABLE ACCESS FULL              | POSTING_REQUEST            |    12M|  4206M|       |   173K  (1)| 00:34:40 |
-------------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter(ROWNUM<500000)
   3 - access("ID"="ID")
   8 - filter("INSTRUCTION"."POSTED_DATETIME" IS NOT NULL AND "INSTRUCTION"."SOURCE_SYSTEM"<>'SQ01' AND
              "INSTRUCTION"."WORKFLOW_ID"<>'LATAM_PASSTHRU_WORKFLOW' AND "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'088' AND
              "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'089' AND ("INSTRUCTION"."EXPIRED_OVERRIDEN" IS NULL OR
              "INSTRUCTION"."EXPIRED_OVERRIDEN"<>'Y') AND "INSTRUCTION"."STATE"<>'EXPIRED')
   9 - access("INSTRUCTION"."ORIG_COUNTRY_CODE"='BR')
  10 - access("INSTRUCTION"."ALTO_ID"="JOURNALENTRY"."INSTRUCTION_ID")
  11 - filter("JOURNALENTRY"."POSTING_REQUEST_ID" IS NOT NULL AND "JOURNALENTRY"."POSTING_DTTM" IS NOT NULL AND
              "JOURNALENTRY"."ENTRY_TYPE"='BKP' AND "JOURNALENTRY"."SIGN"='D' AND "JOURNALENTRY"."REVERSAL_FLAG"='N' AND
              "JOURNALENTRY"."CLEARING_RETURN"='N')

2- Using SQL Profile
--------------------
Plan hash value: 1901712880

------------------------------------------------------------------------------------------------------------------
| Id  | Operation                          | Name                | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------------------
|   0 | UPDATE STATEMENT                   |                     | 25063 |    11M|       |  1251K  (1)| 04:10:16 |
|   1 |  UPDATE                            | POSTING_REQUEST     |       |       |       |            |          |
|*  2 |   COUNT STOPKEY                    |                     |       |       |       |            |          |
|   3 |    NESTED LOOPS                    |                     | 25063 |    11M|       |  1251K  (1)| 04:10:16 |
|   4 |     VIEW                           | VW_NSO_1            |   104K|    12M|       |  1145K  (1)| 03:49:07 |
|   5 |      SORT UNIQUE                   |                     |   104K|    13M|  1856M|  1145K  (1)| 03:49:07 |
|   6 |       NESTED LOOPS                 |                     |    12M|  1602M|       |  1011K  (1)| 03:22:23 |
|   7 |        NESTED LOOPS                |                     |    12M|  1602M|       |  1011K  (1)| 03:22:23 |
|*  8 |         TABLE ACCESS BY INDEX ROWID| JOURNAL_ENTRY       |  9394 |   522K|       |   983K  (1)| 03:16:44 |
|*  9 |          INDEX SKIP SCAN           | JE_UPDATE_QUERY_IDX |  9394 |       |       |   980K  (1)| 03:16:08 |
|* 10 |         INDEX UNIQUE SCAN          | INSTRUCTION_PK      |     1 |       |       |     2   (0)| 00:00:01 |
|* 11 |        TABLE ACCESS BY INDEX ROWID | INSTRUCTION         |  1315 |   101K|       |     3   (0)| 00:00:01 |
|* 12 |     INDEX UNIQUE SCAN              | POSTING_REQUEST_PK  |     1 |   349 |       |     2   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter(ROWNUM<500000)
   8 - filter("JOURNALENTRY"."POSTING_DTTM" IS NOT NULL AND "JOURNALENTRY"."SIGN"='D' AND
              "JOURNALENTRY"."REVERSAL_FLAG"='N' AND "JOURNALENTRY"."CLEARING_RETURN"='N')
   9 - access("JOURNALENTRY"."ENTRY_TYPE"='BKP')
       filter("JOURNALENTRY"."POSTING_REQUEST_ID" IS NOT NULL AND "JOURNALENTRY"."ENTRY_TYPE"='BKP')
  10 - access("INSTRUCTION"."ALTO_ID"="JOURNALENTRY"."INSTRUCTION_ID")
  11 - filter("INSTRUCTION"."POSTED_DATETIME" IS NOT NULL AND "INSTRUCTION"."ORIG_COUNTRY_CODE"='BR' AND
              "INSTRUCTION"."SOURCE_SYSTEM"<>'SQ01' AND "INSTRUCTION"."WORKFLOW_ID"<>'LATAM_PASSTHRU_WORKFLOW' AND
              "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'088' AND "INSTRUCTION"."PAYMENT_TYPE_CODE"<>'089' AND
              ("INSTRUCTION"."EXPIRED_OVERRIDEN" IS NULL OR "INSTRUCTION"."EXPIRED_OVERRIDEN"<>'Y') AND
              "INSTRUCTION"."STATE"<>'EXPIRED')
  12 - access("ID"="ID")

-------------------------------------------------------------------------------

************************************************


select inst_id, sql_id, executions, plan_hash_value, last_active_time, trunc(elapsed_time/1000/1000/executions, 2), sql_profile, sql_plan_baseline 
from gv$sql 
where sql_id = 'g130t77uz4q7q';

execute dbms_sqltune.accept_sql_profile(task_name => 'sql g130t77uz4q7q tuning', task_owner => 'SYS', replace => TRUE);


---

SQL> exec dbms_stats.gather_table_stats('GALTM_PTE','POSTING_REQUEST',degree=>4,cascade=>true);

PL/SQL procedure successfully completed.


set lines 300
col sql_text for a100
col created for a30
col category for a10

select NAME,CATEGORY,SQL_TEXT,CREATED,TYPE,STATUS,FORCE_MATCHING from dba_sql_profiles;


BEGIN
  DBMS_SQLTUNE.DROP_SQL_PROFILE ( 
    name => 'SYS_SQLPROF_0163e0df49c20001' 
);
END;
/


*********************************

set pages 300
set lines 300
col sql_profile for a10
col sql_plan_baseline for a10

select inst_id, sql_id, executions, plan_hash_value, last_active_time, trunc(elapsed_time/1000/1000/executions, 2), sql_profile, sql_plan_baseline
from gv$sql
where sql_id = 'ay50upgv7agc6';

    INST_ID SQL_ID         EXECUTIONS PLAN_HASH_VALUE LAST_ACTIVE_TIME   TRUNC(ELAPSED_TIME/1000/1000/EXECUTIONS,2) SQL_PROFIL SQL_PLAN_B
----------- ------------- ----------- --------------- ------------------ ------------------------------------------ ---------- ----------
          2 ay50upgv7agc6           1       927731952 06-JAN-23                                                4467
          2 ay50upgv7agc6           1      3482512501 06-JAN-23                                               13240




col execs for 999,999,999
col etime for 999,999,999.9
col avg_etime for 999,999.999
col avg_cpu_time for 999,999.999
col avg_lio for 999,999,999.9
col avg_pio for 9,999,999.9
col begin_interval_time for a30
col node for 99999
break on plan_hash_value on startup_time skip 1
select sql_id, plan_hash_value, 
sum(execs) execs, 
-- sum(etime) etime, 
sum(etime)/sum(execs) avg_etime, 
sum(cpu_time)/sum(execs) avg_cpu_time,
sum(lio)/sum(execs) avg_lio, 
sum(pio)/sum(execs) avg_pio
from (
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
elapsed_time_delta/1000000 etime,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
buffer_gets_delta lio,
disk_reads_delta pio,
cpu_time_delta/1000000 cpu_time,
(buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_cpu_time
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS
where sql_id = nvl('&sql_id','ay50upgv7agc6')
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number 
-- and executions_delta > 0
)
group by sql_id, plan_hash_value
order by 5
/


SQL_ID        PLAN_HASH_VALUE        EXECS    AVG_ETIME AVG_CPU_TIME        AVG_LIO      AVG_PIO
------------- --------------- ------------ ------------ ------------ -------------- ------------
ay50upgv7agc6       927731952            1    4,466.755    2,305.400      447,743.0 ############
ay50upgv7agc6      3482512501            1   11,859.111   10,570.545 ##############      8,412.0

set lines 155
col execs for 999,999,999
col min_etime for 999,999.99
col max_etime for 999,999.99
col avg_etime for 999,999.999
col avg_lio for 999,999,999.9
col norm_stddev for 999,999.9999
col begin_interval_time for a30
col node for 99999
break on plan_hash_value on startup_time skip 1
select * from (
select sql_id, sum(execs), min(avg_etime) min_etime, max(avg_etime) max_etime, stddev_etime/min(avg_etime) norm_stddev
from (
select sql_id, plan_hash_value, execs, avg_etime,
stddev(avg_etime) over (partition by sql_id) stddev_etime 
from (
select sql_id, plan_hash_value,
sum(nvl(executions_delta,0)) execs,
(sum(elapsed_time_delta)/decode(sum(nvl(executions_delta,0)),0,1,sum(executions_delta))/1000000) avg_etime
-- sum((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta))) avg_lio
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS
where ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number 
and executions_delta > 0
and elapsed_time_delta > 0
and s.snap_id > nvl('&earliest_snap_id',0)
group by sql_id, plan_hash_value
)
)
group by sql_id, stddev_etime
)
where norm_stddev > nvl(to_number('&min_stddev'),2)
and max_etime > nvl(to_number('&min_etime'),.1)
order by norm_stddev
/


https://github.com/fatdba/Oracle-Database-Scripts/blob/main/sqlflip1.sql
https://github.com/fatdba/Oracle-Database-Scripts/blob/main/sqlflip2.sql
https://blog.pythian.com/pro-active-awr-data-mining-to-find-change-in-sql-execution-plan/


***********05/02/2023 and 06/06/2023


NBO_ETL_MenuPlan_Stg running long


--this was the ETL query


select * from ETL_OWNER.S_ETL_WORKFLOW_DATA
where WORKFLOW_NAME='s_m_DIU_F_NBO_MENU_PLAN_DTL_StageSource'
order by START_TIME desc;

--on 05/02 it showed target_rows as 0 from 04/12 to 05/01 -- He mentioned it hasn't been doing its entire workflow due to issues with NBO.
--same on 06/06 - more records to be procesed
--this is only one observation but use below query to find out how many times updates were run
--no of executions on 05/02 and 06/06 were very high compared to previous runs and job is taking more time because of it.
--use this for no of executions per hour and avge execution time stats
set pages 300
set lines 300 
col execs for 999,999,999 
col avg_etime for 999,999.999 
col avg_lio for 999,999,999.9 
col begin_interval_time for a32
col node for 99999 
--break on plan_hash_value on startup_time skip 1 
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value, 
nvl(executions_delta,0) execs, 
round((elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000,3) avg_etime, 
round((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)),2) avg_lio 
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS 
where sql_id = 'gvcj1amzb4jdv' 
and ss.snap_id = S.snap_id 
and ss.instance_number = S.instance_number 
and executions_delta > 0 
order by 3 desc
/


---08/09/2023

DIPROD SM_ENT_JE_PDOC_COGS_UPDT running long

UPDATE SM_ENT_COGS_CALC_RSLT SECCR
   SET SECCR.SAP_JE_DOC_NBR = :B3,
       SECCR.SAP_JE_SPL_RECORD_ID = :B2,
       SECCR.UPDT_TS = SYSDATE
 WHERE     SECCR.COGS_CALC_SEQ_NBR = :B1
       AND (    SECCR.SAP_JE_DOC_NBR IS NULL
            AND SECCR.SAP_JE_SPL_RECORD_ID IS NULL)
			
sql id a432rybk00kj9


--use this for no of executions per hour and avge execution time stats
set pages 300
set lines 300 
col execs for 999,999,999 
col avg_etime for 999,999.999 
col avg_lio for 999,999,999.9 
col begin_interval_time for a32
col node for 99999 
--break on plan_hash_value on startup_time skip 1 
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value, 
nvl(executions_delta,0) execs, 
round((elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000,3) avg_etime, 
round((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)),2) avg_lio 
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS 
where sql_id = 'a432rybk00kj9' 
and ss.snap_id = S.snap_id 
and ss.instance_number = S.instance_number 
and executions_delta > 0 
order by 3 desc
/


  SNAP_ID   NODE BEGIN_INTERVAL_TIME              SQL_ID        PLAN_HASH_VALUE        EXECS    AVG_ETIME        AVG_LIO
---------- ------ -------------------------------- ------------- --------------- ------------ ------------ --------------
     32914      1 09-AUG-23 09.00.27.606000000 AM  a432rybk00kj9      2885752458      394,748         .009           92.7
     32913      1 09-AUG-23 08.00.02.436000000 AM  a432rybk00kj9      2885752458      655,377         .006           91.1
     32912      1 09-AUG-23 07.00.15.188000000 AM  a432rybk00kj9      2885752458      469,108         .008           93.1
     32911      1 09-AUG-23 06.00.02.582000000 AM  a432rybk00kj9      2885752458       44,019         .008           78.0
     32910      1 09-AUG-23 05.00.32.879000000 AM  a432rybk00kj9      2885752458      614,604         .006           91.4
     32909      1 09-AUG-23 04.00.07.784000000 AM  a432rybk00kj9      2885752458      259,192         .014           92.3
     32908      1 09-AUG-23 03.00.41.904000000 AM  a432rybk00kj9      2885752458      334,287         .011           93.7
     32907      1 09-AUG-23 02.00.13.830000000 AM  a432rybk00kj9      2885752458      528,437         .007           91.4
     32906      1 09-AUG-23 01.00.12.826000000 AM  a432rybk00kj9      2885752458      882,622         .004           91.5
     32905      1 09-AUG-23 12.00.27.596000000 AM  a432rybk00kj9      2885752458      763,279         .004           92.0
     32881      1 08-AUG-23 12.00.48.537000000 AM  a432rybk00kj9      2885752458    3,982,336         .000            4.1
     32880      1 07-AUG-23 11.00.25.298000000 PM  a432rybk00kj9      2885752458    4,187,851         .000            4.1
     32858      1 07-AUG-23 01.00.37.465000000 AM  a432rybk00kj9      2885752458    1,748,667         .001            4.1
     32857      1 07-AUG-23 12.00.12.377000000 AM  a432rybk00kj9      2885752458    5,304,178         .001            4.1
     32856      1 06-AUG-23 11.00.17.366000000 PM  a432rybk00kj9      2885752458    1,117,288         .001            4.1
     32834      1 06-AUG-23 01.00.17.295000000 AM  a432rybk00kj9      2885752458    2,954,803         .000            4.1
     32833      1 06-AUG-23 12.00.30.882000000 AM  a432rybk00kj9      2885752458    5,215,390         .000            4.1
	 
--You could see drastic degradation in avge execution time. There was a session creating partitoins. It was commmited and the update/session completed fast

--SQLSTATS
https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-SQLSTATS.html#GUID-495DD17D-6741-433F-871D-C965EB221DA9

--below query shows data from the time it ran

select sql_id, plan_hash_value,EXECUTIONS,DELTA_EXECUTION_COUNT,
round((elapsed_time/decode(nvl(executions,0),0,1,executions))/1000000,3) avg_etime, 
round((buffer_gets/decode(nvl(buffer_gets,0),0,1,executions)),2) avg_lio 
from GV$SQLSTATS
where sql_id = 'a432rybk00kj9';


SQL_ID        PLAN_HASH_VALUE EXECUTIONS DELTA_EXECUTION_COUNT    AVG_ETIME        AVG_LIO
------------- --------------- ---------- --------------------- ------------ --------------
a432rybk00kj9      2885752458    4392201               2828883         .003           39.4

--below query shows data from the time after last AWR snapshot. You can see considerable improvement in avg_etime
--AWR snapshot interval is 1 hour and tihis update has been running for 10+ hours. 
--DELTA_EXECUTION_COUNT is >50% of EXECUTIONS which means it did more work in past 1 hour (or less) than previous 9 hours

select sql_id, plan_hash_value,EXECUTIONS,DELTA_EXECUTION_COUNT,
round((DELTA_ELAPSED_TIME/decode(nvl(DELTA_EXECUTION_COUNT,0),0,1,DELTA_EXECUTION_COUNT))/1000000,3) avg_etime, 
round((DELTA_BUFFER_GETS/decode(nvl(DELTA_--BUFFER_GETS,0),0,1,DELTA_EXECUTION_COUNT)),2) avg_lio 
from GV$SQLSTATS
where sql_id = 'a432rybk00kj9';

SQL_ID        PLAN_HASH_VALUE EXECUTIONS DELTA_EXECUTION_COUNT    AVG_ETIME        AVG_LIO
------------- --------------- ---------- --------------------- ------------ --------------
a432rybk00kj9      2885752458    4392201               2828883         .001           10.4




09/07/2023 DWPROD

g4523tv0z9247


set pages 300
set lines 300 
col execs for 999,999,999 
col avg_etime for 999,999.999 
col avg_lio for 999,999,999.9 
col begin_interval_time for a32
col node for 99999 
--break on plan_hash_value on startup_time skip 1 
select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value, 
nvl(executions_delta,0) execs, 
round((elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000,3) avg_etime, 
round((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)),2) avg_lio 
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS 
where sql_id = 'g4523tv0z9247' 
and ss.snap_id = S.snap_id 
and ss.instance_number = S.instance_number 
and executions_delta > 0 
order by 3 desc
/


--- 06/17/2024 DWPROD

set serveroutput on
declare
  l_sql_tune_task_id varchar2(100);
begin
  l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id => '8hfazky46nncy',
                          scope => dbms_sqltune.scope_comprehensive,
                          time_limit => 600,
                          task_name => 'sql_8hfazky46nncy_tuning');
  dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/


-- executing the tuning task

exec dbms_sqltune.execute_tuning_task(task_name => 'sql_8hfazky46nncy_tuning');

-- displaying the recommendations
set long 1000000;
set longchunksize 10000
set pagesize 10000
set linesize 200
select dbms_sqltune.report_tuning_task('sql_8hfazky46nncy_tuning') as recommendations from dual;

******************************

select owner,table_name,last_analyzed from dba_tables
where owner in ('SM_OWNER','EDW','SM_STAGE')
and table_name in 
(
'F_PURCHASE_POS_DTL',
'D_PRODUCT',
'D_DISTRIBUTOR',
'D_PURCHASING_UNIT',
'D_VENDOR_PRODUCT',
'D_INVOICE_CUSTOMER',
'D_DISTRIBUTOR_PRODUCT',
'D_MANUFACTURER_PRODUCT',
'D_PURCHASE_POS_STATUS',
'S_BE_CONSOLIDATED_ROLLUP',
'D_DAY_INVOICE'
);

SM_STAGE	S_BE_CONSOLIDATED_ROLLUP	16-JUN-24
EDW			D_DISTRIBUTOR				16-JUN-24
EDW			D_PRODUCT					16-JUN-24
SM_OWNER	D_DISTRIBUTOR				16-JUN-24
SM_OWNER	D_DISTRIBUTOR_PRODUCT		16-JUN-24
SM_OWNER	D_INVOICE_CUSTOMER			16-JUN-24
SM_OWNER	D_MANUFACTURER_PRODUCT		16-JUN-24
SM_OWNER	D_PRODUCT					16-JUN-24
SM_OWNER	D_PURCHASE_POS_STATUS		16-JUN-24
SM_OWNER	D_PURCHASING_UNIT			16-JUN-24
SM_OWNER	D_VENDOR_PRODUCT			16-JUN-24
SM_OWNER	F_PURCHASE_POS_DTL			17-JUN-24



set serveroutput on
declare
  l_sql_tune_task_id varchar2(100);
begin
  l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id => '8hfazky46nncy',
                          scope => dbms_sqltune.scope_comprehensive,
                          time_limit => 600,
                          task_name => 'sql_8hfazky46nncy_tuning');
  dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/


exec DBMS_SQLTUNE.DROP_TUNING_TASK('sql_8hfazky46nncy_tuning');

-- executing the tuning task

exec dbms_sqltune.execute_tuning_task(task_name => 'sql_8hfazky46nncy_tuning');

-- displaying the recommendations
set long 1000000;
set longchunksize 10000
set pagesize 10000
set linesize 200
select dbms_sqltune.report_tuning_task('sql_8hfazky46nncy_tuning') as recommendations from dual;

execute dbms_sqltune.accept_sql_profile(task_name =>'sql_8hfazky46nncy_tuning', task_owner => 'PKANCHERLA', replace => TRUE);

--Get the address and hash_value of the sql_id:
select ADDRESS, HASH_VALUE from V$SQLAREA where SQL_Id='8hfazky46nncy';
ADDRESS          HASH_VALUE
---------------- ----------
000000007BB5B498 3719364824

--Now purge the sql statement 
exec DBMS_SHARED_POOL.PURGE ('ADDRESS,HASH_VALUE','C');

exec sys.DBMS_SHARED_POOL.PURGE ('000000007BB5B498,3719364824','C');

PL/SQL procedure successfully completed.

--Check again
select ADDRESS, HASH_VALUE from V$SQLAREA where SQL_Id='8hfazky46nncy';




--07/08/2024



set serveroutput on
declare
  l_sql_tune_task_id varchar2(100);
begin
  l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id => '1rn4z3zn1a5ma',
                          scope => dbms_sqltune.scope_comprehensive,
                          time_limit => 600,
                          task_name => 'sql_1rn4z3zn1a5ma_tuning');
  dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/


-- executing the tuning task

exec dbms_sqltune.execute_tuning_task(task_name => 'sql_1rn4z3zn1a5ma_tuning');

-- displaying the recommendations
set long 1000000;
set longchunksize 10000
set pagesize 10000
set linesize 200
select dbms_sqltune.report_tuning_task('sql_8hfazky46nncy_tuning') as recommendations from dual;

execute dbms_sqltune.accept_sql_profile(task_name =>'sql_8hfazky46nncy_tuning', task_owner => 'PKANCHERLA', replace => TRUE);




