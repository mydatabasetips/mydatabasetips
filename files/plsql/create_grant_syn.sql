/**************************************************************************************************
This procedure grants privileges on schema objects to UserAccount for Application as needed.
It takes 2 arguments - schema and appuser- example : BES and BESAPP

Usage:

exec create_grant_syn('DHSUSER','DHSUSERAPP');

Make sure to user running this procedure has below direct grants
These are needed despite user having DBA role.

grant select on sys.dba_objects to pkancherla;
grant select on sys.dba_roles to pkancherla;
grant create role to pkancherla;

***Important***
This procedure doesn't work as user doesn't have direct permissions on schema objects. 
Issuing grants through a PL/SQL code will not work so user has to grant them directly
As better approach is to create a spooled SQL file with needed grants and execute it

****************************************************************************************************/

CREATE OR REPLACE PROCEDURE create_grant_syn 
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

BEGIN

    dbms_output.put_line('Creating roles for '|| v_schema);
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'WRITE';
	dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
	
 	v_trace_str := 'CREATE ROLE '||v_schema||'WRITE NOT IDENTIFIED ';
	dbms_output.put_line(v_trace_str);
	EXECUTE IMMEDIATE v_trace_str;
	END IF;
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'READ';
	dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
	
 	v_trace_str := 'CREATE ROLE '||v_schema||'READ NOT IDENTIFIED ';
	dbms_output.put_line(v_trace_str);
	EXECUTE IMMEDIATE v_trace_str;
	END IF;
	
   dbms_Output.put_line('Creating grants and synonyms for ' || v_AppUser|| ' on schema '|| v_schema);
   
   FOR grantSyn_cur_ IN grantSyn_cur
   LOOP
   
    v_objectName:=grantSyn_cur_.OBJECT_NAME;
	v_objectType:=grantSyn_cur_.OBJECT_TYPE;
	
	IF v_objectType IN ('TABLE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT,INSERT,UPDATE,DELETE ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'READ ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	ELSIF v_objectType IN ('VIEW','SEQUENCE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			v_trace_str := 'GRANT SELECT ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'READ ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	ELSIF v_objectType IN ('FUNCTION','PACKAGE','PROCEDURE','TYPE') THEN
			--grants
			v_trace_str := 'GRANT EXECUTE ON '||v_schema||'.'||v_objectName||' TO '||v_schema||'WRITE ';
			dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM '||v_AppUser||'.'||v_objectName||' FOR '||v_schema||'.'||v_objectName; 
			dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	END IF;
 END LOOP;
END;

/