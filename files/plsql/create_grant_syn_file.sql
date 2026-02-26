/**************************************************************************************************************************
This procedure grants privileges on schema objects to UserAccount for Application as needed.
It takes 2 arguments - schema and appuser- example : BES and BESAPP

Usage:

exec create_grant_syn_file('DHSUSER','DHSUSERAPP');
exec create_grant_syn_file('BES','BESAPP');

User running this procedure should have below grants. Having DBA role is NOT enough.

  GRANT SELECT ON "SYS"."DBA_OBJECTS" TO "USERNAME";
  GRANT SELECT ON "SYS"."DBA_ROLES" TO "USERNAME";
  GRANT SELECT ON "SYS"."DBA_DIRECTORIES" TO "USERNAME";
  GRANT READ ON DIRECTORY "DATA_PUMP_DIR" TO "USERNAME";
  GRANT WRITE ON DIRECTORY "DATA_PUMP_DIR" TO "USERNAME";
  
Output file is generated at directory DATA_PUMP_DIR. Code needs to be updated to generate files at a differnt directory
  
This procedure will generate outout like below. Run the generated SQL script to create roles, grants and synonyms.
This part cannot be done through a PL/SQL as running user will not have direct grants on each and every object.

	Generating SQL script at C:\Oracle\admin\hanadev\dpdump/
	Generating create roles for DHSUSER
	Generating grants and create synonyms for DHSUSERAPP on schema DHSUSER
	Run below SQL script to create needed roles, grants and synonyms for DHSUSERAPP on schemaDHSUSER
	C:\Oracle\admin\hanadev\dpdump//create_grant_syn_for_DHSUSERAPP_on_DHSUSER_04_02_2025_20_03_00.sql

***************************************************************************************************************************/
CREATE OR REPLACE PROCEDURE create_grant_syn_file 
(
    v_schema  VARCHAR2,
    v_AppUser  VARCHAR2
) AS

CURSOR grantSyn_cur IS
    SELECT 	OBJECT_NAME, OBJECT_TYPE
	FROM DBA_OBJECTS
	WHERE
		OWNER=v_schema
		AND OBJECT_TYPE IN ('SEQUENCE','TABLE','VIEW','FUNCTION','PACKAGE','PROCEDURE','TYPE')
		ORDER BY OBJECT_TYPE, OBJECT_NAME ASC;
	
v_objectName	VARCHAR2(128);
v_objectType	VARCHAR2(23);
v_trace_str     VARCHAR2(4000);
v_role_cnt		NUMBER;
v_fileHandle  	UTL_FILE.FILE_TYPE;
v_fileName   	VARCHAR2(255);
v_dateTime		VARCHAR2(30);
v_directoryName	VARCHAR2(30) := 'DATA_PUMP_DIR';
v_filePath 		VARCHAR2(300);

BEGIN

	v_dateTime := to_char(sysdate, 'MM_DD_YYYY_HH24_MI_SS');
    v_fileName := 'create_grant_syn_for_'||v_AppUser||'_on_'||v_schema||'_' || v_dateTime;
	--dbms_output.put_line('file name is '|| v_fileName);

	v_fileHandle := utl_file.fopen(v_directoryName, v_fileName || '.sql', 'W');
	utl_file.put_line(v_fileHandle, 'SPOOL ' || v_fileName);
    utl_file.put_line(v_fileHandle, NULL);
    utl_file.put_line(v_fileHandle, 'SET echo ON'); 
	
	SELECT DIRECTORY_PATH INTO v_filePath FROM DBA_DIRECTORIES WHERE DIRECTORY_NAME=v_directoryName;

    dbms_output.put_line('Generating SQL script at '||v_filePath);
    dbms_output.put_line('Generating create roles for '|| v_schema);
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'WRITE';
	--dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
	
 	v_trace_str := 'CREATE ROLE '||v_schema||'WRITE NOT IDENTIFIED;';
	--dbms_output.put_line(v_trace_str);
	--EXECUTE IMMEDIATE v_trace_str;
     utl_file.put_line(v_fileHandle, NULL);
	 utl_file.put_line(v_fileHandle, v_trace_str);
	 
	END IF;
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'READ';
	--dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
	
 	v_trace_str := 'CREATE ROLE '||v_schema||'READ NOT IDENTIFIED;';
	--dbms_output.put_line(v_trace_str);
	--EXECUTE IMMEDIATE v_trace_str;
	 utl_file.put_line(v_fileHandle, NULL);
	 utl_file.put_line(v_fileHandle, v_trace_str);
	END IF;
	
    utl_file.put_line(v_fileHandle, NULL);
    dbms_Output.put_line('Generating grants and create synonyms for ' || v_AppUser|| ' on schema '|| v_schema);
   
   FOR grantSyn_cur_ IN grantSyn_cur
   LOOP
   
    v_objectName:=grantSyn_cur_.OBJECT_NAME;
	v_objectType:=grantSyn_cur_.OBJECT_TYPE;
	
	IF v_objectType IN ('TABLE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT,INSERT,UPDATE,DELETE ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE;';
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'READ;';
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);			
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName||';'; 
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);
	ELSIF v_objectType IN ('VIEW','SEQUENCE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE;';
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);			
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'READ;';
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;	
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName||';'; 
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);
	ELSIF v_objectType IN ('FUNCTION','PACKAGE','PROCEDURE','TYPE') THEN
			--grants
			v_trace_str := 'GRANT EXECUTE ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE;';
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);			
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName||';'; 
			--dbms_output.put_line(v_trace_str);
			--EXECUTE IMMEDIATE v_trace_str;
			--utl_file.put_line(v_fileHandle, NULL);
			utl_file.put_line(v_fileHandle, v_trace_str);
	END IF;
	--utl_file.put_line(v_fileHandle, NULL);
    utl_file.fflush(v_fileHandle);
 END LOOP;
 utl_file.put_line(v_fileHandle, NULL);
 utl_file.put_line(v_fileHandle, 'SPOOL OFF');
 utl_file.fclose(v_fileHandle);   
 
 --Running grants through another PL/SQL will also not work as user lacks direct privilege on each and every object
 --run_grant_syn(v_fileName);
  dbms_output.put_line('Run below SQL script to create needed roles, grants and synonyms for '||v_AppUser||' on schema'||v_schema);
  dbms_output.put_line(v_filePath||'/'||v_fileName||'.sql');
  
 EXCEPTION
  WHEN UTL_FILE.file_open THEN
     UTL_FILE.FCLOSE(v_fileHandle);
     DBMS_OUTPUT.PUT_LINE('Error opening file.');
  WHEN UTL_FILE.write_error THEN
     UTL_FILE.FCLOSE(v_fileHandle);
     DBMS_OUTPUT.PUT_LINE('Error writing to file.');
  WHEN UTL_FILE.internal_error THEN
     UTL_FILE.FCLOSE(v_fileHandle);
     DBMS_OUTPUT.PUT_LINE('Internal UTL_FILE error.');
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(v_fileHandle) THEN
      UTL_FILE.FCLOSE(v_fileHandle);
    END IF;
    DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
	
END;
/