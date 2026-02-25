```sql
SET TIME ON 
SET TIMING ON
SET SERVEROUTPUT ON

DECLARE
  --DEFINE THE SCHEMA HERE
  v_schema       VARCHAR2(128) := 'PKANCHERLA'; 
  v_sql          VARCHAR2(2000);
  v_chk NUMBER; 

BEGIN

  --SAFETY CHECKS
  --Check if schema exists, raise error if not

  SELECT COUNT(*) INTO v_chk FROM dba_users
  WHERE username = v_schema ;

  IF v_chk = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Entered Schema does not exist: ' || v_schema);
  END IF;

  --Check if schema is Oracle maintained or in the list of restricted schemas

  SELECT COUNT(*) INTO v_chk  FROM dba_users 
    WHERE username = v_schema  AND (oracle_maintained = 'Y' OR username like '%BES%');

  IF v_chk > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'STOP! You are attempting to drop objects from an Oracle-maintained or restricted schema: ' || v_schema);
  END IF;

  DBMS_OUTPUT.PUT_LINE('Starting object cleanup for schema: ' || v_schema);

  --Check if schema has active connections, abort if connections exist

  SELECT COUNT(*) INTO v_chk FROM v$session
  WHERE username = v_schema or schemaname = v_schema ;

  IF v_chk > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Schema has active connections : ' || v_schema);
  END IF;

  DBMS_OUTPUT.PUT_LINE('Starting object cleanup for schema: ' || v_schema);

  --DROP OBJECTS

  -- Drop Materialized Views
  FOR i IN (SELECT mview_name FROM dba_mviews WHERE owner = v_schema) LOOP
    v_sql := 'DROP MATERIALIZED VIEW "' || v_schema || '"."' || i.mview_name || '" PRESERVE TABLE';

    DBMS_OUTPUT.PUT_LINE('Dropping MView: ' || i.mview_name);
    DBMS_OUTPUT.PUT_LINE(v_sql);

    BEGIN 
       NULL;
       --EXECUTE IMMEDIATE v_sql;
    EXCEPTION 
        WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  -- Drop Tables (Cascade Constraints & Purge)
  FOR i IN (SELECT table_name FROM dba_tables WHERE owner = v_schema) LOOP
    v_sql := 'DROP TABLE "' || v_schema || '"."' || i.table_name || '" CASCADE CONSTRAINTS PURGE';

    DBMS_OUTPUT.PUT_LINE('Dropping table: ' || i.table_name);
    DBMS_OUTPUT.PUT_LINE(v_sql);

    BEGIN 
    NULL;
        --EXECUTE IMMEDIATE v_sql;
    EXCEPTION 
        WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  -- Drop Sequences
  FOR i IN (SELECT sequence_name FROM dba_sequences WHERE sequence_owner = v_schema) LOOP
    v_sql := 'DROP SEQUENCE "' || v_schema || '"."' || i.sequence_name || '"';

    DBMS_OUTPUT.PUT_LINE('Dropping sequence: ' || i.sequence_name);
    DBMS_OUTPUT.PUT_LINE(v_sql);

    BEGIN
     NULL;
     --EXECUTE IMMEDIATE v_sql;
    EXCEPTION 
        WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  -- Drop Code, Triggers, Java
  FOR i IN (SELECT object_name, object_type FROM dba_objects 
            WHERE owner = v_schema  AND object_type IN (
            'VIEW', 'SYNONYM', 'PROCEDURE', 'FUNCTION', 'PACKAGE','TRIGGER', 'JAVA SOURCE', 'JAVA CLASS', 'JAVA RESOURCE')
            ORDER BY object_type) LOOP

    v_sql := 'DROP ' || i.object_type || ' "' || v_schema || '"."' || i.object_name || '"';

    DBMS_OUTPUT.PUT_LINE('Dropping ' || i.object_type || ': ' || i.object_name);
    DBMS_OUTPUT.PUT_LINE(v_sql);

    BEGIN 
      NULL;
      --EXECUTE IMMEDIATE v_sql; 
    EXCEPTION 
        WHEN OTHERS THEN IF SQLCODE != -4043 THEN DBMS_OUTPUT.PUT_LINE('  Failed: ' || SQLERRM); END IF;
    END;
  END LOOP;

  -- Drop Types
  FOR i IN (SELECT object_name FROM dba_objects WHERE owner = v_schema AND object_type = 'TYPE') LOOP
    v_sql := 'DROP TYPE "' || v_schema || '"."' || i.object_name || '" FORCE';

    DBMS_OUTPUT.PUT_LINE('Dropping type: ' || i.object_name);
    DBMS_OUTPUT.PUT_LINE(v_sql);

    BEGIN 
      NULL;
      --EXECUTE IMMEDIATE v_sql;
    EXCEPTION 
        WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Cleanup completed for: ' || v_schema);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Critical Error: ' || SQLERRM);
END;
/
