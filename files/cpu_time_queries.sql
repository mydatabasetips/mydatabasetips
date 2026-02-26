SELECT   mymodule "Module", SUM (cpu_time) "CPU Time", SUM (wait_time) "Wait Time",
         SUM (cpu_time) + SUM (wait_time) "Total Time"
    FROM (SELECT a.module mymodule,
                 (CASE (session_state)
                     WHEN 'ON CPU'
                        THEN wait_time / 100
                  END
                 ) cpu_time,
                 (CASE (session_state)
                     WHEN 'WAITING'
                        THEN time_waited / 100
                  END
                 ) wait_time
            FROM dba_hist_active_sess_history a, dba_hist_snapshot b
        --   WHERE b.end_interval_time > sysdate-1
            WHERE b.end_interval_time > to_date('2023-02-02 09:50:00','yyyy-mm-dd hh24:mi:ss')
         AND b.end_interval_time <= sysdate 
             AND a.snap_id = b.snap_id
             AND a.user_id NOT IN (0, 5)
             AND a.instance_number = b.instance_number)
GROUP BY mymodule
 HAVING SUM (cpu_time) + SUM (wait_time) > 0
ORDER BY 2 DESC

--Timeframe
SELECT   mymodule "Module", SUM (cpu_time) "CPU Time", SUM (wait_time) "Wait Time",
         SUM (cpu_time) + SUM (wait_time) "Total Time"
    --FROM (SELECT a.program mymodule,
	--FROM (SELECT a.machine mymodule,
	FROM (SELECT a.module mymodule,
                 (CASE (session_state)
                     WHEN 'ON CPU'
                        THEN wait_time / 100
                  END
                 ) cpu_time,
                 (CASE (session_state)
                     WHEN 'WAITING'
                        THEN time_waited / 100
                  END
                 ) wait_time
            FROM dba_hist_active_sess_history a, dba_hist_snapshot b
        --WHERE a.sample_time >= to_date('2023-02-09 10:30:00','yyyy-mm-dd hh24:mi:ss')
          --and a.sample_time  < to_date('2023-02-09 12:30:00','yyyy-mm-dd hh24:mi:ss')
		  WHERE a.sample_time >= to_date('2023-02-09 11:40:00','yyyy-mm-dd hh24:mi:ss')
            and a.sample_time  < to_date('2023-02-09 11:50:00','yyyy-mm-dd hh24:mi:ss')
         AND b.end_interval_time <= sysdate 
             AND a.snap_id = b.snap_id
             AND a.user_id NOT IN (0, 5)
             AND a.instance_number = b.instance_number)
GROUP BY mymodule
HAVING SUM (cpu_time) + SUM (wait_time) > 0
ORDER BY 2 DESC



select * from dba_hist_active_sess_history a 
where session_id in (1222,426,1276,4493)
and a.sample_time >= to_date('2023-02-02 10:30:00','yyyy-mm-dd hh24:mi:ss')
            and a.sample_time  < to_date('2023-02-02 11:31:00','yyyy-mm-dd hh24:mi:ss')
            
select * from dba_hist_sqltext  where sql_id='bfp171ckm0kjt';

Parallel servers


https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/managing-resources-with-oracle-database-resource-manager.html#GUID-B4256D06-2223-49A1-A939-9BE9706498BC

NAME                            TYPE    VALUE 
------------------------------- ------- ----- 
cpu_count                       integer 24    
cpu_min_count                   string  24    
parallel_threads_per_cpu        integer 1     
resource_manager_cpu_allocation integer 0     
NAME                            TYPE    VALUE  
------------------------------- ------- ------ 
awr_pdb_max_parallel_slaves     integer 10     
containers_parallel_degree      integer 65535  
fast_start_parallel_rollback    string  LOW    
max_datapump_parallel_per_job   string  50     
optimizer_ignore_parallel_hints boolean FALSE  
parallel_adaptive_multi_user    boolean FALSE  
parallel_degree_limit           string  CPU    
parallel_degree_policy          string  MANUAL 
parallel_execution_message_size integer 16384  
parallel_force_local            boolean FALSE  
parallel_instance_group         string         
parallel_max_servers            integer 600    
parallel_min_degree             string  1      
parallel_min_percent            integer 0      
parallel_min_servers            integer 48     
parallel_min_time_threshold     string  AUTO   
parallel_servers_target         integer 192    
parallel_threads_per_cpu        integer 1      
recovery_parallelism            integer 0      


--Memory stats and advisories

https://db.geeksinsight.com/tools-scripts/memory-advisories/


show parameter db_cache_advice
show parameter statistics_level

SELECT component, current_size/1024/1024 as size_mb, min_size/1024/1024 as min_size_mb
FROM v$sga_dynamic_components
WHERE current_size > 0
ORDER BY component;


COMPONENT                                                           SIZE_MB MIN_SIZE_MB
---------------------------------------------------------------- ---------- -----------
DEFAULT buffer cache                                                 146432      146432
In-Memory Area                                                         1536           0
Shared IO Pool                                                          512         512
java pool                                                              3072        3072
large pool                                                             1024        1024
shared pool                                                           50176       49152
streams pool                                                           1024        1024

7 rows selected. 

SELECT sga_size, sga_size_factor, estd_db_time_factor
FROM v$sga_target_advice
ORDER BY sga_size ASC;

SELECT round(PGA_TARGET_FOR_ESTIMATE/1024/1024) target_mb,
		ESTD_PGA_CACHE_HIT_PERCENTAGE cache_hit_perc,
		ESTD_OVERALLOC_COUNT
	 FROM   v$pga_target_advice;
	 
            

