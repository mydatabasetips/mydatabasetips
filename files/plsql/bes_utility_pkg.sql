/*---------------------------------------------------------------------------------*/
/*As the name indicates, this package bes_utility_pkg holds all utility procedures

--------------------------procedure create_grant_syn---------------------------------
-------------------This procedure create_grant_syn does below------------------------

1) Grants needed privileges on schema objects to App UserAccount
2) Create synonyms for App UserAccount on schema objects 
   to avoid using fully qualified names in the code.

Whenever new database tables/objects are created or existing objects recreated
under BES, developers should work with DevOps and get this procedure
run so AppUser can see these objects and Application works as intended.

Usage:
This procedure takes 2 arguments: Schema and Appuser like BES and BESAPP

examples
exec BES.bes_utility_pkg.create_grant_syn('BES','BESAPP');
exec HANA.bes_utility_pkg.create_grant_syn('HANA','HANAAPP);
exec PER1BES.bes_utility_pkg.create_grant_syn('PER1BES','PER1BESAPP);
exec TIM1BES.bes_utility_pkg.create_grant_syn('TIM1BES','TIM1BESAPP);

***Use correct schema and AppUser pair, especially in environments/DBs where there are
 multiple schemas. Synonyms can wrongly point to different schema if not paired properly


1)Work with DBA and make sure user running this procedure has below grants

  GRANT EXECUTE ON BES.BES_UTILITY_PKG TO <devopsuser>;

2)Both Schema and AppUser should exist for this procedure to create grants and synonyms
3)Below privileges are granted to schema for this procedure to work, change schema name as needed

  GRANT SELECT ON "SYS"."DBA_OBJECTS" TO "BES";
  GRANT SELECT ON "SYS"."DBA_ROLES" TO "BES";
  GRANT SELECT ON "SYS"."DBA_USERS" TO "BES";
  GRANT CREATE ROLE TO "BES";
  GRANT CREATE ANY SYNONYM TO "BES";
  
----------------------------procedure create_syn------------------------------------
---------------------This procedure create_syn does below---------------------------
1) Create synonyms for personal user accounts on schema objects  to avoid using fully
 qualified names. This is not usually needed and user accounts can create synonyms 
 themselves or access objects through fully qualified names
 
Usage:
This procedure takes 2 arguments: Schema and Appuser like BES and BESAPP

examples
 exec BES.bes_utility_pkg.create_syn('BES','DEVUSERACOUNT');
 exec HANA.bes_utility_pkg.create_syn('HANA','DEVUSERACOUNT');
 exec PER1BES.bes_utility_pkg.create_syn('PER1BES','DEVUSERACOUNT');
 exec TIM1BES.bes_utility_pkg.create_grant_syn('TIM1BES','PER1BESAPP);


*** Using this procedure in environments/DBs where there are multiple schemas can result
in wrongly pointing synonyms. Use with caution.

2)Work with DBA and make sure user running this procedure has below grants

  GRANT EXECUTE ON BES.BES_UTILITY_PKG TO <devopsuser>;

/*---------------------------------------------------------------------------------*/
/*---------------------Package Definition -Start-----------------------------------*/

CREATE OR REPLACE PACKAGE BES.bes_utility_pkg IS
 PROCEDURE create_grant_syn 
 (
   v_schema  VARCHAR2,
   v_AppUser  VARCHAR2
  );
 PROCEDURE create_syn 
 (
   v_schema  VARCHAR2,
   v_UserAccount  VARCHAR2
  );
END bes_utility_pkg;
/
/*---------------------Package Definition -End-------------------------------------*/

/*----------------=-------Package Body -Start--------------------------------------*/
CREATE OR REPLACE PACKAGE BODY BES.bes_utility_pkg IS
/*----------------=------ create_grant_syn -Start- --------------------------------*/
PROCEDURE create_grant_syn 
(
    v_schema  VARCHAR2,
    v_AppUser  VARCHAR2
) IS

CURSOR grantSyn_cur IS
    SELECT 	OBJECT_NAME, OBJECT_TYPE
	FROM DBA_OBJECTS
	WHERE
		OWNER=v_schema
		AND OBJECT_TYPE IN ('SEQUENCE','TABLE','VIEW','FUNCTION','PACKAGE','PROCEDURE','TYPE')
		--ORDER BY OBJECT_TYPE, OBJECT_NAME ASC;
		ORDER BY OBJECT_NAME ASC;

	
v_objectName	VARCHAR2(128);
v_objectType	VARCHAR2(23);
v_trace_str     VARCHAR2(4000);
v_role_cnt		NUMBER;
v_user_check 	NUMBER;

BEGIN

    SELECT COUNT(*) INTO v_user_check FROM DBA_USERS WHERE USERNAME=v_schema OR USERNAME=v_AppUser;
	
	IF v_user_check <> 2 THEN
		dbms_output.put_line('Error!! No Grants created');
		dbms_output.put_line('Create Schema '|| v_schema ||' and App User'|| v_AppUser || ' before running grants procedure');
		RETURN;
	END IF;

	dbms_output.put_line('Creating roles for '|| v_schema);
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'WRITE';
	--dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
		v_trace_str := 'CREATE ROLE '||v_schema||'WRITE NOT IDENTIFIED ';
		--dbms_output.put_line(v_trace_str);
		EXECUTE IMMEDIATE v_trace_str;
		v_trace_str := 'GRANT '||v_schema||'WRITE TO '||v_AppUser;
		EXECUTE IMMEDIATE v_trace_str;
	END IF;
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'READ';
	--dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
		v_trace_str := 'CREATE ROLE '||v_schema||'READ NOT IDENTIFIED ';
		--dbms_output.put_line(v_trace_str);
		EXECUTE IMMEDIATE v_trace_str;
		v_trace_str := 'GRANT '||v_schema||'READ TO '||v_AppUser;
		EXECUTE IMMEDIATE v_trace_str;
	END IF;
	
	SELECT COUNT(*) INTO v_role_cnt FROM DBA_ROLES WHERE ROLE=v_schema||'EXECUTE';
	--dbms_output.put_line(v_role_cnt);

	IF v_role_cnt = 0 THEN
		v_trace_str := 'CREATE ROLE '||v_schema||'EXECUTE NOT IDENTIFIED ';
		--dbms_output.put_line(v_trace_str);
		EXECUTE IMMEDIATE v_trace_str;
		v_trace_str := 'GRANT '||v_schema||'READ TO '||v_AppUser;
		EXECUTE IMMEDIATE v_trace_str;
	END IF;
	 
   dbms_Output.put_line('Creating grants and synonyms for ' || v_AppUser|| ' on schema '|| v_schema);
   
   FOR grantSyn_cur_ IN grantSyn_cur
   LOOP
   
   --Begin...end block to continue loop in case of failing statement - start
   BEGIN
   
    v_objectName:=grantSyn_cur_.OBJECT_NAME;
	v_objectType:=grantSyn_cur_.OBJECT_TYPE;
	
	--dbms_output.put_line(v_objectName);
	
	IF v_objectType IN ('TABLE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT,INSERT,UPDATE,DELETE ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'WRITE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			v_trace_str := 'GRANT SELECT ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'READ ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM "'||v_AppUser||'"."'||v_objectName||'" FOR "'||v_schema||'"."'||v_objectName||'"'; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	ELSIF v_objectType IN ('VIEW','SEQUENCE') THEN
	        --grants
			v_trace_str := 'GRANT SELECT ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'WRITE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			v_trace_str := 'GRANT SELECT ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'READ ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM "'||v_AppUser||'"."'||v_objectName||'" FOR "'||v_schema||'"."'||v_objectName||'"'; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	ELSIF v_objectType IN ('FUNCTION','PACKAGE','PROCEDURE','TYPE') THEN
			--grants
			v_trace_str := 'GRANT EXECUTE ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'WRITE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
			--synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM "'||v_AppUser||'"."'||v_objectName||'" FOR "'||v_schema||'"."'||v_objectName||'"'; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
			--Granting execute privileges to EXECUTE role
			v_trace_str := 'GRANT EXECUTE ON "'||v_schema||'"."'||v_objectName||'" TO '||v_schema||'EXECUTE ';
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;	
	END IF;
	
	EXCEPTION
	WHEN OTHERS THEN
	   DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred: ' || SQLERRM);
	   DBMS_OUTPUT.PUT_LINE('Failed Statement: ' || v_trace_str);
	   
    --Begin...end block to continue loop in case of failing statement - end
	END;
 END LOOP;
 
 EXCEPTION
	WHEN OTHERS THEN
	   DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred: ' || SQLERRM);
	   DBMS_OUTPUT.PUT_LINE('Failed Statement: ' || v_trace_str);
 
END create_grant_syn;
/*----------------=------ create_grant_syn -End- ----------------------------------*/

/*----------------=------ create_syn -Start- --------------------------------*/
PROCEDURE create_syn 
(
    v_schema  VARCHAR2,
    v_UserAccount  VARCHAR2
) IS

CURSOR createSyn_cur IS
    SELECT 	OBJECT_NAME, OBJECT_TYPE
	FROM DBA_OBJECTS
	WHERE
		OWNER=v_schema
		AND OBJECT_TYPE IN ('SEQUENCE','TABLE','VIEW','FUNCTION','PACKAGE','PROCEDURE','TYPE')
		ORDER BY OBJECT_TYPE, OBJECT_NAME ASC;
	
v_objectName	VARCHAR2(128);
v_objectType	VARCHAR2(23);
v_trace_str     VARCHAR2(4000);
v_user_check 	NUMBER;

BEGIN

    SELECT COUNT(*) INTO v_user_check FROM DBA_USERS WHERE USERNAME=v_schema OR USERNAME=v_UserAccount;
	
	IF v_user_check <> 2 THEN
		dbms_output.put_line('Error!! No Synonyms created');
		dbms_output.put_line('Create Schema '|| v_schema ||' and  User'|| v_UserAccount || ' before running synonyms procedure');
		RETURN;
	END IF;

   dbms_Output.put_line('Creating synonyms for ' || v_UserAccount|| ' on schema '|| v_schema);
   
   FOR createSyn_cur_ IN createSyn_cur
   LOOP
   
   --Begin...end block to continue loop in case of failing statement - start
   BEGIN
   
    v_objectName:=createSyn_cur_.OBJECT_NAME;
	v_objectType:=createSyn_cur_.OBJECT_TYPE;
	
	IF v_objectType IN ('TABLE','VIEW','SEQUENCE','FUNCTION','PACKAGE','PROCEDURE','TYPE') THEN
			--User should have been granted read access through role 
			--create synonyms
			v_trace_str := 'CREATE OR REPLACE SYNONYM "'||v_UserAccount||'"."'||v_objectName||'" FOR "'||v_schema||'"."'||v_objectName||'"'; 
			--dbms_output.put_line(v_trace_str);
			EXECUTE IMMEDIATE v_trace_str;
	END IF;
	
	EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred: ' || SQLERRM);
		DBMS_OUTPUT.PUT_LINE('Failed Statement: ' || v_trace_str);
   --Begin...end block to continue loop in case of failing statement - end
	END;
	
   END LOOP;
 
 EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred: ' || SQLERRM);
		DBMS_OUTPUT.PUT_LINE('Failed Statement: ' || v_trace_str);
 
END create_syn;
/*----------------=------ create_syn -End- ----------------------------------*/

END bes_utility_pkg;
/*----------------=-------Package Body -End--------------------------------------*/

/