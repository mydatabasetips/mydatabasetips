--Query to find list of schemas having 30+ tables and not having any connections either directly or as schema

SELECT 
    t.owner AS schema_name,
    t.table_cnt AS table_count,
    u.account_status,
    u.last_login,
    u.created
FROM 
    (
        -- 1. Find schemas with > 30 tables (The Candidates)
        SELECT owner, COUNT(*) AS table_cnt
        FROM   dba_tables
        WHERE  owner NOT IN (
               SELECT username FROM dba_users WHERE oracle_maintained = 'Y'
               )
        GROUP BY owner
        HAVING COUNT(*) > 30
    ) t
JOIN dba_users u ON t.owner = u.username
WHERE 
     -- Exclude this schema if ANY valid connection exists for it.
    NOT EXISTS (
        SELECT 1 
        FROM   v$session s
        WHERE  s.type = 'USER'
        AND (
            -- A. Is the Schema itself logged in? (e.g., 'HR')
            s.username = t.owner
            -- B. Is the Companion APP user logged in? (e.g., 'HRAPP')
              OR s.username = t.owner || 'APP'
            -- C. (Optional Safety) Is anyone masquerading as this schema?
            -- This catches 'HRAPP' if they ran "ALTER SESSION SET CURRENT_SCHEMA=HR"
            OR s.schemaname = t.owner
        )
    )
ORDER BY 
    t.table_cnt DESC;
	
--similar result 

with
qry0 
    as 
    (
       select 
        sys_context('USERENV','CON_NAME') container,t.owner,to_char(max(o.last_ddl_time),'YYYY-MM-DD.HH24:MI') last_ddl,count(*) numrecs
        from dba_tables t left outer join all_objects o on t.owner = o.owner and t.table_name = o.object_name and o.object_type = 'TABLE'
        where t.owner in (select username from dba_users where common = 'NO')
        group by sys_context('USERENV','CON_NAME'),t.owner having count(*) >= 30
    ),
    qry1 as 
    (
        select sys_context('USERENV','CON_NAME') container,username,schemaname,count(*) numrecs
        from v$session where schemaname in (select username from dba_users where common = 'NO')
        group by sys_context('USERENV','CON_NAME'),username,schemaname
     )
select 
    a.container,a.owner,a.numrecs tables,a.last_ddl,b.username,b.schemaname,b.numrecs sessions
    from qry0 a left outer join qry1 b on a.container = b.container and b.schemaname like a.owner||'%';
