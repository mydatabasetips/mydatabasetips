  
  CREATE OR REPLACE EDITIONABLE PACKAGE "BES"."BESDC_UTIL_RESET_PKG" AS

	PROCEDURE reset_all_bes_sequences (p_owner IN VARCHAR2 DEFAULT 'BES');
	PROCEDURE reset_sequence (p_owner IN VARCHAR2, p_seq_name IN VARCHAR2, p_pk IN VARCHAR2, p_table IN VARCHAR2);
	PROCEDURE check_all_sequences (p_owner IN VARCHAR2) ;
    PROCEDURE reset_target_all (in_just_target	IN	NUMBER	DEFAULT 0);
	PROCEDURE disable_constraints;
	PROCEDURE enable_constraints (in_type VARCHAR2 default NULL);
	PROCEDURE set_deleted_ind_to_default;
	
  END BESDC_UTIL_RESET_PKG;
  /

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "BES"."BESDC_UTIL_RESET_PKG" AS
  /* =============================================================================
     MODIFICATION HISTORY
     DATE        ANALYST         DESCRIPTION
     ----------  --------------  -------------------------------------------------
     04/08/2022  UNISYS (LSP)    Initial version
	 04/26/2024	 EWORLD (LSP)	 Fixed bug where certain sequences were not being reset because PK column name is not consistent
     =============================================================================*/
   
/* =============================================================================
   PRIVATE PROCEDURES FUNCTIONS
   =============================================================================*/


  PROCEDURE reset_all_bes_sequences (p_owner IN VARCHAR2 DEFAULT 'BES')
  AS
	CURSOR get_sequences IS
		select c.owner, c.constraint_name, c.constraint_type, c.table_name, cc.column_name, cc.position, s.sequence_name, s.increment_by, s.last_number
        from all_constraints c  join all_cons_columns cc on (c.owner = cc.owner and c.constraint_name = cc.constraint_name)
                                left outer join all_sequences s on (s.sequence_owner = cc.owner 
                                    and case when c.table_name = 'CASE_BASIC' then 'CASE_BASIC_ID_SEQ' when c.table_name = 'CLIENT_ALIAS' then 'CLIENT_ALIAS_ID_SEQ' 
                                             when c.table_name = 'ELIGIBILITY_WORK_REQUIREMENT' then 'ELIGIBILITY_WORK_REQUIREMENT_ID_SEQ' 
                                             when c.table_name = 'INTERVIEW_WRAP_UP_DOC' then 'INTERVIEW_WRAP_UP_DOC_ID_SEQ'
                                             when c.table_name = 'VOTER_REGISTRATION' then 'VOTER_REGISTRATION_ID_SEQ'
                                        else cc.column_name||'_SEQ' end = s.sequence_name)
        where c.owner = 'BES' and c.constraint_type = 'P'
          and c.table_name in (select table_name from all_tables where owner = 'BES' and table_name not like 'L_%' and table_name not in ('flyway_schema_history','CODE_TABLE_VERSION','SETTING','SCHEDULER_DATE') 
                                                                   and table_name not like 'T_%' and table_name not like 'HARI_%' and table_name not like 'SECURITY%' and table_name not like 'BATCH%'
                                                                   and table_name not like 'BES_HANA%')
        order by c.table_name; 
  
  	TYPE seq_tab
		IS TABLE OF get_sequences%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_seq_tab		seq_tab;
	
  BEGIN

	OPEN get_sequences;
	FETCH get_sequences BULK COLLECT INTO l_seq_tab;
	CLOSE get_sequences;

	FOR i IN 1..l_seq_tab.COUNT LOOP
		reset_sequence (p_owner, l_seq_tab(i).sequence_name, l_seq_tab(i).column_name, l_seq_tab(i).table_name);
	END LOOP;		
  
  EXCEPTION 
	WHEN others THEN
		RAISE;
  END reset_all_bes_sequences;
  

  PROCEDURE reset_sequence (p_owner IN VARCHAR2, p_seq_name IN VARCHAR2, p_pk IN VARCHAR2, p_table IN VARCHAR2) 
  AS	
	v_count				NUMBER;
	v_sql				VARCHAR2(100);
  BEGIN
	v_sql := 'select max(' || p_pk || ') from '||p_owner||'.' || p_table;
	execute immediate v_sql INTO v_count;

	IF v_count > 1 THEN
		v_count := v_count + 1 + 50000;
	
		v_sql := 'alter sequence '||p_owner||'.' || p_seq_name || ' restart start with ' || v_count;
		--dbms_output.put_line(v_sql);
		execute immediate v_sql;
	END IF;

  EXCEPTION 
	WHEN others THEN
		RAISE;
  END reset_sequence;
 
 
  PROCEDURE check_all_sequences (p_owner IN VARCHAR2) 
  AS
 
	CURSOR get_sequences IS
		select c.owner, c.constraint_name, c.constraint_type, c.table_name, cc.column_name, cc.position, s.sequence_name, s.increment_by, s.last_number
        from all_constraints c  join all_cons_columns cc on (c.owner = cc.owner and c.constraint_name = cc.constraint_name)
                                join all_sequences s on (s.sequence_owner = cc.owner and case when c.table_name = 'CASE_BASIC' then 'CASE_BASIC_ID_SEQ' when c.table_name = 'CLIENT_ALIAS' then 'CLIENT_ALIAS_ID_SEQ' when c.table_name = 'ELIGIBILITY_WORK_REQUIREMENT' then 'ELIGIBILITY_WORK_REQUIREMENT_ID_SEQ' else cc.column_name||'_SEQ' end = s.sequence_name)
        where c.owner = p_owner and c.constraint_type = 'P'
          and c.table_name in (select table_name from all_tables where owner = p_owner and table_name not like 'L_%' and table_name not in ('flyway_schema_history','CODE_TABLE_VERSION','SETTING','SCHEDULER_DATE') 
                                                                   and table_name not like 'T_%' and table_name not like 'HARI_%' and table_name not like 'SECURITY%')
        order by c.table_name; 
  
  	TYPE seq_tab
		IS TABLE OF get_sequences%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_seq_tab			seq_tab;
	v_count				NUMBER;
	v_sql				VARCHAR2(100);
  BEGIN

	OPEN get_sequences;
	FETCH get_sequences BULK COLLECT INTO l_seq_tab;
	CLOSE get_sequences;

	FOR i IN 1..l_seq_tab.COUNT LOOP
		reset_sequence (p_owner, l_seq_tab(i).sequence_name, l_seq_tab(i).column_name, l_seq_tab(i).table_name);
		v_sql := 'select max(' || l_seq_tab(i).column_name || ') from '||p_owner||'.' || l_seq_tab(i).table_name;
		execute immediate v_sql INTO v_count;

		IF v_count >= l_seq_tab(i).last_number THEN
			dbms_output.put_line('ERROR: '||l_seq_tab(i).sequence_name||'  last_number='||l_seq_tab(i).last_number||'  max(id)='||v_count);
		END IF;
	END LOOP;		
  
  EXCEPTION 
	WHEN others THEN
		RAISE;
  END check_all_sequences;


  /* =============================================================================
     RESET_TARGET_ALL
     MODIFICATION HISTORY
     DATE        ANALYST         DESCRIPTION
     ----------  --------------  -------------------------------------------------
     01/31/2025  EWORLD (LSP)    Procedure for reseting all target tables via truncate
	 02/04/2025	 EWORLD (LSP)	 Added back enable of PK (because otherwise index is not enabled)
     =============================================================================*/
  PROCEDURE reset_target_all (in_just_target	IN	NUMBER	DEFAULT 0)
  AS
	CURSOR get_list_of_tables_cur IS
		select table_name from all_tables a
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and table_name not in ('CASE_NUMBER','CODE_TABLE_VERSION','IDEMPOTENCY','SCHEDULER_DATE','SECURITY_ROLE','SECURITY_ROLE_PERMISSION','SECURITY_USER_ROLE','SETTING','SUPERVISION_GROUP','SUPERVISION_GROUP_USER','flyway_schema_history')
          and table_name not like 'L_%'
		  and tablespace_name is not null
		order by table_name;

	CURSOR get_list_of_cons_cur IS
		with temp as (select table_name from all_tables where owner = 'BES')
		select a.table_name, constraint_name, constraint_type, status from all_constraints a join temp b on (a.table_name = b.table_name)
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and a.table_name not in ('CASE_NUMBER','CODE_TABLE_VERSION','IDEMPOTENCY','SCHEDULER_DATE','SECURITY_ROLE','SECURITY_ROLE_PERMISSION','SECURITY_USER_ROLE','SETTING','SUPERVISION_GROUP','SUPERVISION_GROUP_USER','flyway_schema_history')
          and a.table_name not like 'L_%'
		order by constraint_name;

	CURSOR get_list_of_pk_cur IS
		select table_name, constraint_name, constraint_type, status from all_constraints a
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
          and constraint_type = 'P' and status = 'DISABLED'
		order by constraint_name;
		
	CURSOR get_list_of_partitions_cur IS
		select table_name, partition_name from all_tab_partitions
		where table_owner = 'BES'
		order by 1,2;
		
	TYPE list_of_tables_tab
		IS TABLE OF get_list_of_tables_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_table_list 		list_of_tables_tab;

	TYPE list_of_cons_tab
		IS TABLE OF get_list_of_cons_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_cons_list 		list_of_cons_tab;
	
	TYPE list_of_partitions_tab
		IS TABLE OF get_list_of_partitions_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_part_list 		list_of_partitions_tab;
	
	v_sql				VARCHAR2(1000);
	v_count				NUMBER;
	v_error				NUMBER;
  BEGIN

	disable_constraints;

	OPEN get_list_of_cons_cur;
	FETCH get_list_of_cons_cur BULK COLLECT INTO l_cons_list;
	CLOSE get_list_of_cons_cur;
	
	--Check that all constraints are disabled
	dbms_output.put_line('Checking that all constraints for BES schema are disabled');
	v_error	:= 0;
	FOR ix IN 1 .. l_cons_list.COUNT
	LOOP
		IF l_cons_list(ix).status = 'ENABLED' THEN 
			v_sql := 'OOPS....: Table '||l_cons_list(ix).table_name||' has constraint '||l_cons_list(ix).constraint_name||' still ENABLED. Please investigate';
			execute immediate v_sql;
			v_error	:= 1;
		END IF;
	END LOOP;
	l_cons_list.DELETE;
	IF v_error = 0 THEN 
		dbms_output.put_line('....Done');
	END IF;

	OPEN get_list_of_tables_cur;
	FETCH get_list_of_tables_cur BULK COLLECT INTO l_table_list;
	CLOSE get_list_of_tables_cur;
	
	--Delete data from tables
	dbms_output.put_line('Deleting data for tables in BES schema');
	FOR ix IN 1 .. l_table_list.COUNT
	LOOP
		IF l_table_list(ix).table_name IN ('SECURITY_USER','SECURITY_USER_UNIT') THEN 
			v_sql := 'delete from bes.'||l_table_list(ix).table_name||' where '||l_table_list(ix).table_name||'_ID < 0';
		ELSE 
			v_sql := 'truncate table bes.'||l_table_list(ix).table_name||' reuse storage';
		END IF;
		execute immediate v_sql;
	END LOOP;

--	OPEN get_list_of_partitions_cur;
--	FETCH get_list_of_partitions_cur BULK COLLECT INTO l_part_list;
--	CLOSE get_list_of_partitions_cur;
	
--	FOR ix IN 1 .. l_part_list.COUNT
--	LOOP
--		v_sql := 'alter table intm.'||l_part_list(ix).table_name||' truncate partition '||l_part_list(ix).partition_name;
--		execute immediate v_sql;
--	END LOOP;

	IF in_just_target = 1 THEN 
		--Checking for data to delete from T_CONVERSION_STATS 
		dbms_output.put_line('Checking to remove data from T_CONVERSION_STATS for target load');
		v_sql := 'select count(1) from intm.t_conversion_stats where step_phase = ''3 - LOAD_TARGET''';
		execute immediate v_sql into v_count;
		IF v_count > 0 THEN 
			v_sql := 'delete from intm.t_conversion_stats where step_phase = ''3 - LOAD_TARGET''';
			execute immediate v_sql;
		END IF;
		dbms_output.put_line('....Done');

		--Checking for data to delete from T_ERROR_LOG
		dbms_output.put_line('Checking to remove data from T_ERROR_LOG for target load');
		v_sql := 'select count(1) from intm.t_error_log where instr(upper(error_location),''LOAD_TARGET'') > 0';
		execute immediate v_sql into v_count;
		IF v_count > 0 THEN 
			v_sql := 'delete from intm.t_error_log where instr(upper(error_location),''LOAD_TARGET'') > 0';
			execute immediate v_sql;
		END IF;
		dbms_output.put_line('....Done');
	END IF;
	
	--Verify table counts
	v_error := 0;
	dbms_output.put_line('Checking table counts after delete');
	IF l_table_list.COUNT = 0 THEN 
		dbms_output.put_line('OOPS....: Tables are missing?');
	ELSE 
		FOR ix IN 1 .. l_table_list.COUNT
		LOOP
			v_sql := 'select count(1) from bes.'||l_table_list(ix).table_name;
			execute immediate v_sql into v_count;
			
			IF l_table_list(ix).table_name in ('SECURITY_USER') THEN 
				IF v_count = 0 THEN 
					dbms_output.put_line('OOPS....: Table bes.'||l_table_list(ix).table_name||' has zero (0) records but needs data. Please investigate.');
					v_error := 1;
				END IF;
			ELSE 
				IF v_count <> 0 THEN 
					dbms_output.put_line(RPAD('OOPS....: Table intm.'||l_table_list(ix).table_name||' still has records but should not.',87,' ')||' Please investigate.');
					v_error := 1;
				END IF;
			END IF;
		END LOOP;
	END IF;
	IF v_error = 0 THEN 
		dbms_output.put_line('.....OK: Done checking table counts. Good to go.');
		dbms_output.put_line('NOTE: Constraints are disabled. Leaving them that way. Enable constraints after target load in complete.');
	END IF;
	
	--Enable PK constraints
	enable_constraints('P');
	
  EXCEPTION 
	WHEN others THEN
		dbms_output.put_line(SUBSTR(SQLERRM,1,64));
		dbms_output.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		dbms_output.put_line('Failed on vsql = '||v_sql);
  END reset_target_all;


   /* =============================================================================
     DISABLE_CONSTRAINTS
     MODIFICATION HISTORY
     DATE        ANALYST         DESCRIPTION
     ----------  --------------  -------------------------------------------------
     04/24/2025  EWORLD (LSP)    Procedure for disabling all constraints in BES schema
     =============================================================================*/
  PROCEDURE disable_constraints
  AS

	CURSOR get_list_of_cons_cur IS
		with temp as (select table_name from all_tables where owner = 'BES')
		select a.table_name, constraint_name, constraint_type, status from all_constraints a join temp b on (a.table_name = b.table_name)
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and a.table_name not in ('CASE_NUMBER','CODE_TABLE_VERSION','IDEMPOTENCY','SCHEDULER_DATE','SECURITY_ROLE','SECURITY_ROLE_PERMISSION','SECURITY_USER_ROLE','SETTING','SUPERVISION_GROUP','SUPERVISION_GROUP_USER','flyway_schema_history')
          and a.table_name not like 'L_%'
		order by constraint_name;

	TYPE list_of_cons_tab
		IS TABLE OF get_list_of_cons_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_cons_list 		list_of_cons_tab;

	v_sql				VARCHAR2(1000);
  BEGIN

	OPEN get_list_of_cons_cur;
	FETCH get_list_of_cons_cur BULK COLLECT INTO l_cons_list;
	CLOSE get_list_of_cons_cur;
	
	--Disable all constraints
	dbms_output.put_line('Disabling all constraints for BES schema');
	FOR ix IN 1 .. l_cons_list.COUNT
	LOOP
		IF l_cons_list(ix).constraint_type = 'P' THEN
			v_sql := 'alter table bes.'||l_cons_list(ix).table_name||' disable constraint '||l_cons_list(ix).constraint_name||' cascade';
		ELSE 
			v_sql := 'alter table bes.'||l_cons_list(ix).table_name||' disable constraint '||l_cons_list(ix).constraint_name;
		END IF;
		execute immediate v_sql;
	END LOOP;
	l_cons_list.DELETE;
	
  EXCEPTION 
	WHEN others THEN
		dbms_output.put_line(SUBSTR(SQLERRM,1,64));
		dbms_output.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		dbms_output.put_line('Failed on vsql = '||v_sql);
  END disable_constraints;
  
 
   /* =============================================================================
     ENABLE_CONSTRAINTS
     MODIFICATION HISTORY
     DATE        ANALYST         DESCRIPTION
     ----------  --------------  -------------------------------------------------
     02/04/2025  EWORLD (LSP)    Procedure for enabling all disabled constraints in BES schema
	 04/24/2025	 EWORLD (LSP)	 Added parameter to only enable constraints of a specific type
     =============================================================================*/
  PROCEDURE enable_constraints (in_type VARCHAR2 default NULL)
  AS

	CURSOR get_list_of_cons_cur IS
		select table_name, constraint_name, constraint_type, status from all_constraints a
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and status = 'DISABLED'
		order by constraint_name;

	CURSOR get_list_of_cons_param_cur (in_type VARCHAR2) IS
		select table_name, constraint_name, constraint_type, status from all_constraints a
		where owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and status = 'DISABLED'
		  and constraint_type = in_type
		order by constraint_name;

	TYPE list_of_cons_tab
		IS TABLE OF get_list_of_cons_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_cons_list 		list_of_cons_tab;

	v_sql				VARCHAR2(1000);
  BEGIN

	IF in_type IS NULL THEN 
		OPEN get_list_of_cons_cur;
		FETCH get_list_of_cons_cur BULK COLLECT INTO l_cons_list;
		CLOSE get_list_of_cons_cur;
		
		dbms_output.put_line('Enabling constraints for BES schema');
	ELSE 
		OPEN get_list_of_cons_param_cur (in_type);
		FETCH get_list_of_cons_param_cur BULK COLLECT INTO l_cons_list;
		CLOSE get_list_of_cons_param_cur;
		
		dbms_output.put_line('Enabling constraints for BES schema of type '||in_type);
	END IF;
	
	--Enable all disabled constraints
	FOR ix IN 1 .. l_cons_list.COUNT
	LOOP
		v_sql := 'alter table bes.'||l_cons_list(ix).table_name||' enable constraint '||l_cons_list(ix).constraint_name;
		execute immediate v_sql;
	END LOOP;
	l_cons_list.DELETE;
	dbms_output.put_line('....Done');
	
  EXCEPTION 
	WHEN others THEN
		dbms_output.put_line(SUBSTR(SQLERRM,1,64));
		dbms_output.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		dbms_output.put_line('Failed on vsql = '||v_sql);
  END enable_constraints;

   /* =============================================================================
     SET_DELETED_IND_TO_DEFAULT
     MODIFICATION HISTORY
     DATE        ANALYST         DESCRIPTION
     ----------  --------------  -------------------------------------------------
     05/02/2025  EWORLD (LSP)    Procedure for enabling setting DELETED_IND field in all tables to default (0)
     =============================================================================*/
  PROCEDURE set_deleted_ind_to_default
  AS

	CURSOR get_list_of_tables_cur IS
		select a.table_name from all_tables a join all_tab_columns b on (a.owner = b.owner and a.table_name = b.table_name)
		where a.owner = 'BES' and not exists (select 1 from all_objects b where a.owner = b.owner and a.table_name = b.object_name and b.object_type = 'MATERIALIZED VIEW')
		  and b.column_name = 'DELETED_IND'
		  and tablespace_name is not null
		order by a.table_name;
		
	TYPE list_of_tables_tab
		IS TABLE OF get_list_of_tables_cur%ROWTYPE
		INDEX BY PLS_INTEGER
	;
    l_tab_list 			list_of_tables_tab;

	v_sql				VARCHAR2(1000);
  BEGIN

	OPEN get_list_of_tables_cur;
	FETCH get_list_of_tables_cur BULK COLLECT INTO l_tab_list;
	CLOSE get_list_of_tables_cur;
	
	dbms_output.put_line('Retrieved list of tables with DELETED_IND field');
	dbms_output.put_line('..Processing each table with a DELETED_IND field');
	
	--Set default for each DELETED_IND
	FOR ix IN 1 .. l_tab_list.COUNT
	LOOP
		v_sql := 'update bes.'||l_tab_list(ix).table_name||' set DELETED_IND = 0';
		execute immediate v_sql;
		execute immediate 'COMMIT';
	END LOOP;
	l_tab_list.DELETE;
	
	dbms_output.put_line('....Done');
	
  EXCEPTION 
	WHEN others THEN
		dbms_output.put_line(SUBSTR(SQLERRM,1,64));
		dbms_output.put_line(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		dbms_output.put_line('Failed on vsql = '||v_sql);
  END set_deleted_ind_to_default;
  

END BESDC_UTIL_RESET_PKG;

/