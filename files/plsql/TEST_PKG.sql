--------------------Package Definition -Start-----------------------------------*/

CREATE OR REPLACE PACKAGE DHSUSER.test_pkg IS
 PROCEDURE test_proc 
 (
   v_var1  VARCHAR2,
   v_var2  NUMBER
  );
END test_pkg;
/
/*---------------------Package Definition -End-------------------------------------*/

/*----------------=-------Package Body -Start--------------------------------------*/
CREATE OR REPLACE PACKAGE BODY DHSUSER.test_pkg IS
/*----------------=------ test_proc -Start- --------------------------------*/
PROCEDURE test_proc 
(
    v_var1  VARCHAR2,
    v_var2  NUMBER
) IS

v_trace_str     VARCHAR2(4000);


BEGIN

 v_trace_str := 'INSERT INTO TEST1 VALUES('''||v_var1||''','||v_var2||')';
 dbms_output.put_line(v_trace_str);
 EXECUTE IMMEDIATE v_trace_str;
 
 EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred: ' || SQLERRM);
 
END test_proc;
/*----------------=------ test_proc -End- ----------------------------------*/

END test_pkg;
/*----------------=-------Package Body -End--------------------------------------*/

/
