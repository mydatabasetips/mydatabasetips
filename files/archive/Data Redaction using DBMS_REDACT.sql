

Data Redaction using DBMS_REDACT


--Be aware that Data Redaction does not place any restriction on the WHERE clause of ad hoc SQL, so the WHERE clause can be used in an iterative fashion to infer the actual data even when there is a Data Redaction policy on the queried column and only the redacted value is displayed.
--Remember that for user SYS and users who have the EXEMPT REDACTION POLICY privilege (usually with DBA privilege), all of the Data Redaction policies are bypassed, so the results of their queries are not redacted. 

https://www.funoracleapps.com/2021/01/what-is-oracle-data-redaction-with.html

https://docs.oracle.com/en/database/oracle/oracle-database/19/asoag/introduction-to-oracle-data-redaction.html

Some examples of implementing Data Redaction using DBMS_REDACT (Doc ID 1588270.1)

--through SYS or a differnt user
grant execute on dbms_redact to PKANCHERLA;

-as pkancherla
create table emptest (empid number, ename varchar2(20), ssn varchar2(11), salary number(10,3));

insert into emptest values ( 100,'emp1','001-99-0001',81000);
insert into emptest values ( 200,'emp2','001-99-0002',82000);
insert into emptest values ( 300,'emp3','001-99-0003',83000);
insert into emptest values ( 400,'emp4','001-99-0004',84000);
insert into emptest values ( 500,'emp5','001-99-0005',85000);
insert into emptest values ( 600,'emp6','001-99-0006',86000);
insert into emptest values ( 700,'emp7','001-99-0007',87000);
insert into emptest values ( 800,'emp8','001-99-0008',88000);
insert into emptest values ( 900,'emp9','001-99-0009',89000);

commit;

 begin
     dbms_redact.add_policy
	 (
       object_schema => 'PKANCHERLA',
       object_name   => 'EMPTEST',
       column_name   => 'SALARY',
       policy_name   => 'REDACT_PKANCHERLA_EMPTEST',
       function_type => DBMS_REDACT.FULL,
       expression    => '1=1',
	   policy_description  => 'Redaction policy on PKANCHERLA.EMPTEST.SALARY'
	  );
  end;
/

begin
       dbms_redact.drop_policy(
         object_schema => 'PKANCHERLA',
         object_name   => 'EMPTEST',
         policy_name   => 'REDACT_PKANCHERLA_EMPTEST');
  end;
/

select * from redaction_policies;

--Create test user, role

create user testempuser identified by testempuser;
create role testemprole;
grant create session,alter session to testemprole;
grant connect,resource,testemprole to testempuser;
grant select on PKANCHERLA.emptest to testempuser;

conn testempuser/testempuser
select * from PKANCHERLA.emptest;

select * from PKANCHERLA.emptest where empid=100;

--drop test user,role

drop role testemprole;
drop user testempuser cascade;














