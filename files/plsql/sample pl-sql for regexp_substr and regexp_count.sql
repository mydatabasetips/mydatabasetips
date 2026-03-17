set serveroutput on

DECLARE
v_cnt INTEGER;
v_loop INTEGER;
v_sub_str VARCHAR2(100);
v_secdata VARCHAR2(4000);

BEGIN
SELECT REGEXP_COUNT(SECDATA,':') INTO v_cnt FROM SECMOD_OWNER.SECTRANS where  TRANSID=4405784;
dbms_output.put_line(v_cnt);

SELECT SECDATA INTO v_secdata FROM SECMOD_OWNER.SECTRANS WHERE TRANSID=4405784;

FOR v_loop IN 1..v_cnt+1 LOOP
dbms_output.put_line(v_loop);
v_sub_str:= REGEXP_SUBSTR(v_secdata,'[^:]+',1,v_loop);
dbms_output.put_line(v_sub_str);
END LOOP;
END;


--for BWyatt-Bell
set serveroutput on

DECLARE
v_cnt INTEGER;
v_loop INTEGER;
v_sub_str VARCHAR2(100);
v_secdata VARCHAR2(4000);
v_jobClassID	 VARCHAR2(100);
v_popCtrlType  	 VARCHAR2(100);
v_hrDeptKey		 VARCHAR2(4000);

BEGIN

SELECT SECDATA INTO v_secdata FROM SECMOD_OWNER.SECTRANS WHERE TRANSID=4644837;

v_jobClassID 	:= REGEXP_SUBSTR(v_secdata,'([^~]*)(~|$)',1,1,NULL,1);
v_popCtrlType	:= REGEXP_SUBSTR(v_secdata,'([^~]*)(~|$)',1,2,NULL,1);
v_hrDeptKey		:= REGEXP_SUBSTR(v_secdata,'([^~]*)(~|$)',1,3,NULL,1);

dbms_output.put_line(v_jobClassID);
dbms_output.put_line(v_popCtrlType);
dbms_output.put_line(v_hrDeptKey);


v_hrDeptKey := REPLACE(v_hrDeptKey,'CHI','CHILD_ONLY');
v_hrDeptKey := REPLACE(v_hrDeptKey,'ALL','PRENT_CHILD');
v_hrDeptKey := REPLACE(v_hrDeptKey,'PAR','PARENT_ONLY');
v_hrDeptKey := REPLACE(v_hrDeptKey,'PRENT','PARENT');

dbms_output.put_line(v_hrDeptKey);

END;

set serveroutput on

DECLARE

v_userid		 VARCHAR2(50);
v_username		 VARCHAR2(50);
v_username_up		 VARCHAR2(50);


BEGIN

SELECT userid INTO v_userid FROM SECMOD_OWNER.SECTRANS_NP WHERE TRANSID=4643709;

v_username := '"'||v_userid||'"';
v_username_up := upper(v_username);

dbms_output.put_line(v_userid);
dbms_output.put_line(v_username);
dbms_output.put_line(v_username_up);
END;

set serveroutput on
DECLARE
v_userid		 VARCHAR2(50);
v_username		 VARCHAR2(50);
v_username_up	 VARCHAR2(50);
v_alphanum_flag	 INTEGER;
BEGIN
--SELECT userid INTO v_userid FROM SECMOD_OWNER.SECTRANS_NP WHERE userid='BWyatt-Bell' and APPCLASS =  'BrioHRPortal';
SELECT userid INTO v_userid FROM SECMOD_OWNER.SECTRANS_NP WHERE userid='Jsanford' and APPCLASS =  'BrioHRPortal' order by CREATEDATE desc fetch first 1 row only;
v_alphanum_flag := REGEXP_INSTR(v_userid, '[^[:alnum:]]' );
if REGEXP_INSTR(v_userid, '[^[:alnum:]]' ) > 0
then 
v_username := '"'||v_userid||'"';
v_username_up := upper(v_username);
end if;
dbms_output.put_line(v_userid);
dbms_output.put_line(v_alphanum_flag);
dbms_output.put_line(v_username);
dbms_output.put_line(v_username_up);
END;






