SET SERVEROUTPUT ON SIZE UNLIMITED;
DECLARE
    
    v_schema VARCHAR2(12) := 'BES';
    v_sql_statement VARCHAR2(500);
    v_table_count NUMBER := 0;
    v_rows_updated NUMBER;
    
   -- Cursor to select tables with the column 'DELETED_IND' in the current schema
    CURSOR c_tables IS
        SELECT table_name
			FROM all_tab_columns
			WHERE owner=v_schema AND column_name = 'DELETED_IND' AND NULLABLE='Y' 
			ORDER BY table_name;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting update process for DELETED_IND column...');
    
    FOR c_tables_proocess IN c_tables LOOP
  
        v_table_count := v_table_count + 1;
  	    DBMS_OUTPUT.PUT_LINE('##Updating table '||c_tables_proocess.table_name);

        -- Construct the dynamic UPDATE statement
        v_sql_statement := 'UPDATE "' || v_schema||'"."'||c_tables_proocess.table_name || '" SET DELETED_IND = 0 WHERE DELETED_IND IS NULL';

        DBMS_OUTPUT.PUT_LINE(v_sql_statement);
        -- Execute the dynamic statement
        EXECUTE IMMEDIATE v_sql_statement;
        
        -- Get the number of rows updated
        v_rows_updated := SQL%ROWCOUNT;
       
        DBMS_OUTPUT.PUT_LINE('##Table: ' || c_tables_proocess.table_name || ' - ' || v_rows_updated || ' rows updated.');
        
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Committing changes...');
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Total tables processed: ' || v_table_count);
    
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/
