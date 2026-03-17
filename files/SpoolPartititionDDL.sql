set serveroutput on
DECLARE
--variable declaration
v_table_name 			VARCHAR2(100);
v_tab_owner 			VARCHAR2(25);
v_part_flag 			VARCHAR2(5);
v_part_col 				VARCHAR2(100);
f_file_handle         	UTL_FILE.FILE_TYPE;
v_directory_name     	VARCHAR2(30) := 'PART_SCRIPT_DIR';
v_file_name          	VARCHAR2(100);
v_long_high_value		LONG;
v_char_high_value		VARCHAR2(10);

CURSOR sm_hist_partlist_cur
  IS
SELECT TABLENAME,PART_COL
  FROM PKANCHERLA.SM_HIST_PARTLIST
  ORDER BY TABLENAME ASC;

 
/*
mkdir -p /oraback/exp/ditstcdb/partscripts
create or replace directory PART_SCRIPT_DIR as '/oraback/exp/ditstcdb/partscripts';

mkdir -p /u00/ora/files/ditstx9m/partscripts
create or replace directory PART_SCRIPT_DIR as '/u00/ora/files/ditstx9m/partscripts';

mkdir -p /u00/ora/files/diprdcdb1/partscripts
create or replace directory PART_SCRIPT_DIR as '/u00/ora/files/diprdcdb1/partscripts';

*/

BEGIN
--Set table variable value here
v_table_name := 'SM_ENT_COGS_CALC_RSLT_ARCH_T';
--v_table_name := 'SM_ENT_COGS_CALC_RSLT';
v_tab_owner := 'SM_HIST';
   
FOR sm_hist_partlist_rec IN sm_hist_partlist_cur
LOOP

v_table_name:=sm_hist_partlist_rec.TABLENAME;
--v_part_col := 'SNPSHT_FISC_YR_PD_NBR';
v_part_col :=sm_hist_partlist_rec.PART_COL;

SELECT PARTITIONED INTO v_part_flag FROM DBA_TABLES WHERE TABLE_NAME = v_table_name and OWNER = v_tab_owner;
dbms_output.put_line(v_part_flag);

IF v_part_flag = 'NO' 
THEN	
	dbms_output.put_line(v_table_name||' is not partitioned, run through partitioning logic');
	
	v_file_name := 'create_part';
	v_file_name := v_file_name || '_' || v_tab_owner || '_' || v_table_name ||'_' ||  to_char(sysdate, 'MM_DD_YYYY_HH24_MI_SS');
	f_file_handle := utl_file.fopen(v_directory_name, v_file_name || '.sql', 'W');

	dbms_output.put_line(v_file_name);
	--dbms_output.put_line(f_file_handle);

	utl_file.put_line(f_file_handle, 'SPOOL ' || v_file_name);
	utl_file.put_line(f_file_handle, NULL);
	utl_file.put_line(f_file_handle, 'SET echo ON'); 
	utl_file.put_line(f_file_handle, 'SET time ON timing on define off'); 
	utl_file.put_line(f_file_handle, NULL);

	--dbms_output.put_line('ALTER TABLE '||v_tab_owner||'.'||v_table_name||' MODIFY PARTITION BY RANGE ('||v_part_col||')');
	utl_file.put_line(f_file_handle, 'ALTER TABLE '||v_tab_owner||'.'||v_table_name||' MODIFY PARTITION BY RANGE ('||v_part_col||')');

	--dbms_output.put_line('( ');
	utl_file.put_line(f_file_handle, '( ');
			
	FOR v_yearloop IN 2012..2025
	LOOP
	--dbms_output.put_line(v_yearloop);
	
	IF v_yearloop = 2012
	THEN
	FOR v_monthloop IN 8..12
		LOOP
		--dbms_output.put_line(v_monthloop);
		IF v_monthloop < 9
		THEN
			--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		ELSIF v_monthloop = 9 THEN
		    --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		ELSIF ( v_monthloop = 10 or v_monthloop = 11 ) THEN
		    --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		--  if v_monthloop = 12
		ELSE
			--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		END IF;
		--below is end month loop
		END LOOP;
	ELSE
		FOR v_monthloop IN 1..12
		LOOP
		--dbms_output.put_line(v_monthloop);
		--month loop less than 9 for adding 0 in front of month
		IF v_monthloop < 9
		THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		ELSIF v_monthloop = 9 THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		ELSIF ( v_monthloop = 10 or v_monthloop = 11 ) THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		--  if v_monthloop = 12
		ELSE
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
     		    utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
			--removed compress clause
				IF ( v_monthloop = 12 and v_yearloop = 2025 )
				THEN
				--no comma for last month
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA');
				ELSE
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		--below is end of IF v_monthloop < 9
		END IF;
		--below is end  v_monthloop IN 1..12
		END LOOP;
		--below is end of IF v_yearloop = 2012
		END IF;
	--below is v_yearloop loop
	END LOOP;
	--dbms_output.put_line(');');
	utl_file.put_line(f_file_handle,');');
	utl_file.put_line(f_file_handle, NULL);
	utl_file.fflush(f_file_handle);
	utl_file.fclose(f_file_handle);
--below is else of v_part_flag=NO
ELSE
	SELECT HIGH_VALUE INTO v_long_high_value FROM DBA_TAB_PARTITIONS WHERE TABLE_NAME = v_table_name and TABLE_OWNER = v_tab_owner and PARTITION_POSITION=1;
	v_char_high_value := substr(v_long_high_value,2,6);
    dbms_output.put_line(v_char_high_value);
	
	IF ( v_char_high_value <> '201209' )
	THEN
	
	v_file_name := 'create_part';
	v_file_name := v_file_name || '_' || v_tab_owner || '_' || v_table_name ||'_' ||  to_char(sysdate, 'MM_DD_YYYY_HH24_MI_SS');
	f_file_handle := utl_file.fopen(v_directory_name, v_file_name || '.sql', 'W');

	dbms_output.put_line(v_file_name);
	--dbms_output.put_line(f_file_handle);

	utl_file.put_line(f_file_handle, 'SPOOL ' || v_file_name);
	utl_file.put_line(f_file_handle, NULL);
	utl_file.put_line(f_file_handle, 'SET echo ON'); 
	utl_file.put_line(f_file_handle, 'SET time ON timing on define off'); 
	utl_file.put_line(f_file_handle, NULL);

	--dbms_output.put_line('ALTER TABLE '||v_tab_owner||'.'||v_table_name||' MODIFY PARTITION BY RANGE ('||v_part_col||')');
	utl_file.put_line(f_file_handle, 'ALTER TABLE '||v_tab_owner||'.'||v_table_name||' MODIFY PARTITION BY RANGE ('||v_part_col||')');

	--dbms_output.put_line('( ');
	utl_file.put_line(f_file_handle, '( ');
			
	FOR v_yearloop IN 2012..2025
	LOOP	
	--dbms_output.put_line(v_yearloop);
	
	IF v_yearloop = 2012
	THEN
	FOR v_monthloop IN 8..12
		LOOP
		--dbms_output.put_line(v_monthloop);
		IF v_monthloop < 9
		THEN
			--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		ELSIF v_monthloop = 9 THEN
		    --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		ELSIF ( v_monthloop = 10 or v_monthloop = 11 ) THEN
		    --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		--  if v_monthloop = 12
		ELSE
			--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
		END IF;
		--below is end month loop
		END LOOP;
	ELSE
		FOR v_monthloop IN 1..12
		LOOP
		--dbms_output.put_line(v_monthloop);
		--month loop less than 9 for adding 0 in front of month
		IF v_monthloop < 9
		THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||'0'||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		ELSIF v_monthloop = 9 THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||'0'||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		ELSIF ( v_monthloop = 10 or v_monthloop = 11 ) THEN
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
				--compress clause until 202305
				IF ( v_yearloop = 2023 and v_monthloop <= 5 )
				THEN
				  --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
 				  utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
				ELSE
				 --removed compress clause
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||v_yearloop||to_char(to_number(v_monthloop)+1)||') TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		--  if v_monthloop = 12
		ELSE
			IF ( v_yearloop < 2023 )
			THEN
				--dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
     		    utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) COMPRESS FOR QUERY HIGH TABLESPACE SM_HIST_DATA,');
			ELSE
			--removed compress clause
				IF ( v_monthloop = 12 and v_yearloop = 2025 )
				THEN
				--no comma for last month
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA');
				ELSE
				 --dbms_output.put_line('PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA,');
				 utl_file.put_line(f_file_handle,'PARTITION '||v_part_col||'_'||v_yearloop||v_monthloop||' VALUES LESS THAN ('||to_char(to_number(v_yearloop)+1)||'01) TABLESPACE SM_HIST_DATA,');
				END IF;
			END IF;
		--below is end of IF v_monthloop < 9
		END IF;
		--below is end  v_monthloop IN 1..12
		END LOOP;
		--below is end of IF v_yearloop = 2012
		END IF;
	--below is v_yearloop loop
	END LOOP;
	--dbms_output.put_line(');');
	utl_file.put_line(f_file_handle,');');
	utl_file.put_line(f_file_handle, NULL);
	utl_file.fflush(f_file_handle);
	utl_file.fclose(f_file_handle);
	--below is end of IF ( v_char_high_value <> '201209' )
   END IF;
--below is end of IF v_part_flag = 'NO' 
END IF;
--below is end of sm_hist_partlist_cur loop
END LOOP;
END;
