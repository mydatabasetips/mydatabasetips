/********************************************************************************************************
*******************************  brio_sectrans_process.sql **********************************************
Example: 
/u00/ora/prod/run_sql_script.ksh msaprod /u00/ora/prod/brio_sectrans_process.sql "/ AS SYSDBA"

This SQL replaces Brio Java program to process BrioReportPortal and BrioHRPortal entries
in SECMOD_OWNER.SECTRANS@MSAPROD

Entries are inserted to/deleted from BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod as needed

For BrioHRPortal, hrp_control.hrp_sec_user_maint_pkg.save_user_def/delete_use_def are also executed on DWPROD

SECMOD_OWNER.SECTRANS.APPCLASS -- BrioReportPortal and BrioHRPortal only. BrioBIPortal no longer in scope

SECMOD_OWNER.SECTRANS.ACTION -- 0 for add/update and 1 for delete

BISECURITY_OWNER.BIPORTAL_ACCESS
Portal code 1 - BrioReportPortal/hierarchy
Portal code 4 - BrioReportPortal/mainloc
Portal code 3 - BrioHRPortal

-----------------------------------Troubleshooting--------------------------------------------------------

Uncomment dbms_Output.put_line statements as needed in case of failures for troubleshooting and re-run
for BrioHRPortal failures,look for entries(TRACESTR) in HRP_CONTROL.ERROR_LOG in DWPROD sorted by timestamp

*********************************************************************************************************/

SET ECHO ON
SET TIME ON
SET TIMING ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE 999999

WHENEVER SQLERROR EXIT 1 ROLLBACK;
WHENEVER OSERROR  EXIT 2 ROLLBACK;

SELECT name FROM v$database;

DECLARE
   CURSOR brioReportHr_cur
   IS
   
   SELECT 
		SCT.TRANSID,
		SCT.APPCLASS,
		SCT.USERID,
		SCT.SECDATA,
		SCT.ACTION,
		SCT.NUMRETRY,
		SCT.CREATEDBY,
		UM.USER_EMPLOYEE_ID
	FROM 
		SECMOD_OWNER.SECTRANS SCT,
		SECMOD_OWNER.USERMAST UM
	WHERE
		(
		APPCLASS = 'BrioReportPortal' OR APPCLASS =  'BrioHRPortal'
		)
		AND PROCESSED = 0
		AND CREATEDATE < (SYSDATE - 5 /( 24 * 60))
		AND SCT.GUID=UM.USER_ID
		AND NUMRETRY<=1
		ORDER BY CREATEDATE ASC;

   v_start_time      NUMBER;
   v_end_time        NUMBER;
   v_secdata_cnt 	 NUMBER;
   v_secdata_loop	 NUMBER;
   v_numretry		 NUMBER;
   v_transid		 NUMBER;
   v_appclass		 VARCHAR2(30);
   v_secdata_substr  VARCHAR2(200);
   v_jobClassID	     VARCHAR2(100);
   v_jobClassID_BIPA VARCHAR2(100);
   v_popCtrlType  	 VARCHAR2(100);
   v_hrDeptKey		 VARCHAR2(4000);
   v_trace_str       VARCHAR2(4000);

BEGIN
   --Start overall program timing
   v_start_time := dbms_utility.get_time;
   
   --Loop start for selecting entries from SECTRANS
   FOR brioReportHr_rec IN brioReportHr_cur
   LOOP
	  
	  v_numretry:=brioReportHr_rec.NUMRETRY;
	  v_transid:=brioReportHr_rec.TRANSID;
	  v_appclass:=brioReportHr_rec.APPCLASS;
	    
	  --Action 0 for add or update
	  IF brioReportHr_rec.ACTION = 0
	  THEN
				
		--for BrioReportPortal
		IF brioReportHr_rec.APPCLASS = 'BrioReportPortal' 
		THEN
		
		--Delete existing entries in BIPORTAL_ACCESS
		dbms_Output.put_line('BrioReportPortal: Deleting entries from biportal_access for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS);

		DELETE FROM BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
		WHERE UPPER(USER_ID) = UPPER(brioReportHr_rec.userid) and Portal_Code in (1,4);
		
		IF brioReportHr_rec.SECDATA is NULL
		THEN
			--Nothing to process if SECDATA in NULL, update processed to 1 and set BUILDDATE
			dbms_Output.put_line('BrioReportPortal: Nothing to process, Secdata is null for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS|| ' and transid:'||brioReportHr_rec.TRANSID);
		
		ELSE
			--Get count of hierarchy and/or mainloc entries from secdata, delimiter is :
			v_secdata_cnt:=REGEXP_COUNT(brioReportHr_rec.SECDATA,':');
			
			--dbms_Output.put_line('Secdata value :' || brioReportHr_rec.SECDATA);
			--dbms_Output.put_line('Secdata count :' || v_secdata_cnt);
			
			dbms_Output.put_line('BrioReportPortal :Inserting entries into biportal_access for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS);
			
			--Loop start for processing hierarchy and/or mainloc entries from secdata and insert into BISECURITY_OWNER.BIPORTAL_ACCESS
			
			FOR v_secdata_loop IN 1..v_secdata_cnt+1
			LOOP
			
				v_secdata_substr:= REGEXP_SUBSTR(brioReportHr_rec.SECDATA,'[^:]+',1,v_secdata_loop);
			
				--dbms_Output.put_line('Secdata Loop counter :' || v_secdata_loop);
				--dbms_Output.put_line('Secdata substring :' || v_secdata_substr);
					
				IF INSTR(v_secdata_substr,'ML-H') > 0 
				THEN
				
					INSERT INTO BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
					 (user_id, portal_group_cd, source_cd, create_dt, update_dt, portal_code, empl_id)
					VALUES
					 (brioReportHr_rec.userid,v_secdata_substr,'M',sysdate,sysdate,4,brioReportHr_rec.user_employee_id);
				
				ELSE
					INSERT INTO BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod 
					 (user_id, portal_group_cd, source_cd, create_dt, update_dt, portal_code, empl_id)
					VALUES
					 (brioReportHr_rec.userid,v_secdata_substr,'M',sysdate,sysdate,1,brioReportHr_rec.user_employee_id);
				
				END IF;
			 END LOOP;
			 --Loop end for processing hierarchy and/or mainloc entries from secdata
			 --dbms_Output.put_line('End of Loop for processing hierarchy and/or mainloc entries from secdata');
		 END IF;
		--END IF for brioReportHr_rec.SECDATA NULL check  
		END IF;
		--END IF for BrioReportPortal
		
		--for BrioHRPortal
		IF brioReportHr_rec.APPCLASS = 'BrioHRPortal' 
		THEN
		
			IF brioReportHr_rec.SECDATA is NULL
			THEN
			
				--Delete existing entries in BIPORTAL_ACCESS
				dbms_Output.put_line('BrioHRPortal: Deleting entries form biportal_access for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS);

				DELETE FROM BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
				WHERE UPPER(USER_ID) = UPPER(brioReportHr_rec.userid) and Portal_Code in (3);
				
				--Nothing to process if SECDATA in NULL, update processed to 1 and set BUILDDATE
				dbms_Output.put_line('BrioHRPortal: Nothing to process, Secdata is null for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS|| ' and transid:'||brioReportHr_rec.TRANSID);
			
			ELSE
		    	--for BrioHRPortal, REGEXP_SUBSTR modified to get substrings after null, not the case for BrioReportPortal
				--delimiter is ~
				--BrioHRPortal Secdata can have null v_popCtrlType and not null v_hrDeptKey
				
				v_jobClassID 	:= REGEXP_SUBSTR(brioReportHr_rec.SECDATA,'([^~]*)(~|$)',1,1,NULL,1);
				v_popCtrlType	:= REGEXP_SUBSTR(brioReportHr_rec.SECDATA,'([^~]*)(~|$)',1,2,NULL,1);
				v_hrDeptKey		:= REGEXP_SUBSTR(brioReportHr_rec.SECDATA,'([^~]*)(~|$)',1,3,NULL,1);
				
				--dbms_Output.put_line('for BrioHRPortal -jobClassID :' || v_jobClassID);
				--dbms_Output.put_line('for BrioHRPortal -popCtrlType :' || v_popCtrlType);
				--dbms_Output.put_line('for BrioHRPortal -hrDeptKey before expanding abbrevations:' || v_hrDeptKey);			
				
				v_hrDeptKey := REPLACE(v_hrDeptKey,'CHI','CHILD_ONLY');
				v_hrDeptKey := REPLACE(v_hrDeptKey,'ALL','PRENT_CHILD');
				v_hrDeptKey := REPLACE(v_hrDeptKey,'PAR','PARENT_ONLY');
				v_hrDeptKey := REPLACE(v_hrDeptKey,'PRENT','PARENT');
				
				--dbms_Output.put_line('for BrioHRPortal -hrDeptKey after expanding abbrevations:' || v_hrDeptKey);
				
				--Execute save_user_def on DWPROD
				--save_user_def(pin_username,pin_job_class_cd,pin_pop_ctrl_type,pin_hr_dept_cd_string,pin_operator_username)
				dbms_Output.put_line('Executing save_user_def on DWPROD for :' || brioReportHr_rec.userid ||','||v_jobClassID ||','||v_popCtrlType ||','||v_hrDeptKey ||','||brioReportHr_rec.createdby );
				
				--v_trace_str := 'hrp_sec_user_maint_pkg.save_user_def@dwpdpdb('||brioReportHr_rec.userid||','||v_jobClassID||','||v_popCtrlType||','||v_hrDeptKey||','||brioReportHr_rec.createdby||');';
				--dbms_Output.put_line(v_trace_str);
				--EXECUTE IMMEDIATE v_trace_str;
					
				hrp_sec_user_maint_pkg.save_user_def@dwpdpdb(brioReportHr_rec.userid,v_jobClassID,v_popCtrlType,v_hrDeptKey,brioReportHr_rec.createdby);
				
				--Delete existing entries in BIPORTAL_ACCESS
				dbms_Output.put_line('BrioHRPortal: Deleting entries form biportal_access for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS);

				DELETE FROM BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
				WHERE UPPER(USER_ID) = UPPER(brioReportHr_rec.userid) and Portal_Code in (3);
				
				--Add HRPR_ at the start for inserting into BIPORTAL_ACCESS for BrioHRPortal
				v_jobClassID_BIPA 	:= 'HRPR_'||v_jobClassID;
				
				--dbms_Output.put_line('for BrioHRPortal entry insert into BIPORTAL_ACCESS, HRPR added to jobClassID :' || v_jobClassID_BIPA);
				dbms_Output.put_line('BrioHRPortal :Inserting entries into biportal_access for userid:' || brioReportHr_rec.userid|| ' and AppClass:'|| brioReportHr_rec.APPCLASS);
				
				INSERT INTO BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
						 (user_id, portal_group_cd, source_cd, create_dt, update_dt, portal_code, empl_id)
						VALUES
						 (brioReportHr_rec.userid,v_jobClassID_BIPA,'M',sysdate,sysdate,3,brioReportHr_rec.user_employee_id);
			
			END IF;
			--END IF for brioReportHr_rec.SECDATA NULL check 
		 END IF;
		 --END IF for BrioHRPortal
		END IF; 
		--END IF for ACTION 0
		
		--Action 1 for Deletion
		IF brioReportHr_rec.ACTION = 1
		THEN
			dbms_Output.put_line('Action 1, Deleting records in BIPORTAL_ACCESS for: ' || brioReportHr_rec.APPCLASS||' and '||brioReportHr_rec.userid);
		
			IF brioReportHr_rec.APPCLASS = 'BrioReportPortal' 
			THEN
        
				DELETE FROM BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod
				WHERE UPPER(USER_ID) = UPPER(brioReportHr_rec.userid) and Portal_Code in (1,4);
				
			END IF;
	   
			IF brioReportHr_rec.APPCLASS = 'BrioHrPortal' 
			THEN
        
				DELETE FROM BISECURITY_OWNER.BIPORTAL_ACCESS@metaprod 
				WHERE UPPER(USER_ID) = UPPER(brioReportHr_rec.userid) and Portal_Code in (3);
				
				--Execute delete_user_def on DWPROD
				--delete_user_def(pin_usernamepin_operator_username)
				dbms_Output.put_line('Executing delete_user_def on DWPROD for :' || brioReportHr_rec.userid ||','||brioReportHr_rec.createdby );
			
				hrp_sec_user_maint_pkg.delete_user_def@dwpdpdb(brioReportHr_rec.userid,brioReportHr_rec.createdby);
				--v_trace_str := 'hrp_sec_user_maint_pkg.delete_user_def@dwpdpdb('||brioReportHr_rec.userid||','||brioReportHr_rec.createdby||');';
				--dbms_Output.put_line(v_trace_str);
				--EXECUTE IMMEDIATE v_trace_str;				
							
			END IF;
	  	END IF;
		--END IF for ACTION 1

		--update processed in SECTRANS to 1 and BUILDDATE to SYSDATE after processing the record
		dbms_Output.put_line('Updating processed to 1 in SECTRANS for TRANSID:' || brioReportHr_rec.TRANSID ||' and APPCLASS: '||brioReportHr_rec.APPCLASS);
		
		UPDATE secmod_owner.SECTRANS  SET PROCESSED = '1', BUILDDATE = SYSDATE
		WHERE  TRANSID = brioReportHr_rec.TRANSID AND APPCLASS = brioReportHr_rec.APPCLASS;
		
		COMMIT;
		
	END LOOP;
	--Loop end for processing entries from SECTRANS
	COMMIT;
			
   --
   -- Report overall program timing
   --
   v_end_time := dbms_utility.get_time;
   dbms_output.put_line('Total Elapsed Seconds: ' || (v_end_time - v_start_time)/100);
   
   --Exception - start	 
	EXCEPTION
	WHEN OTHERS THEN
	ROLLBACK;
	   
		--Incrementing Numretry in case of any errors.
		dbms_Output.put_line('Failure! Incrementing NUMRETRY by 1 in SECTRANS for TRANSID:' || v_transid ||' and APPCLASS: '||v_appclass);
		
		IF v_appclass = 'BrioHRPortal'
		THEN
			dbms_Output.put_line('for BrioHRPortal failures,look for ERROR_MSG,TRACESTR in HRP_CONTROL.ERROR_LOG table in DWPROD DB');
		END IF;
		
		UPDATE secmod_owner.SECTRANS  SET NUMRETRY = v_numretry+1  
		WHERE  TRANSID = v_transid AND APPCLASS = v_appclass;
		
		COMMIT;
		 
		v_end_time := dbms_utility.get_time;
		dbms_output.put_line('Total Elapsed Seconds: ' || (v_end_time - v_start_time)/100);
		raise_application_error(-20000, v_trace_str); 
	--Exception - end
     
END;
/
