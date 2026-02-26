https://smarttechways.com/2021/02/18/check-usage-of-temp-tablespace-with-non-cdb-and-pdbs-database/
https://community.oracle.com/tech/apps-infra/discussion/3906290/get-info-about-storage-limit-for-a-pdb
https://techgoeasy.com/oracle-12c-pluggable-database-commands/
https://docs.oracle.com/en/database/oracle/oracle-database/12.2/admin/managing-a-multitenant-environment.html#GUID-93F1E584-D309-4301-82E0-AD0E60D4977C


show pdbs
show con_name
show con_id

A CDB includes the root, the CDB seed, and PDBs.

alter session set container=CDB$ROOT;
alter session set container=PDB$SEED;
alter session set container=DWSTGPDB;

alter session set container=DWDEVPDB;
alter session set container=DIUATPDB;


--Determining Whether a Database is a CDB
SELECT NAME,CDB,CON_ID FROM V$DATABASE;

--Viewing Information About the Containers in a CDB
SELECT NAME, CON_ID, DBID, CON_UID, GUID FROM V$CONTAINERS ORDER BY CON_ID;

--Viewing Information About PDBs
SELECT PDB_ID, PDB_NAME, STATUS FROM DBA_PDBS ORDER BY PDB_ID;

--Viewing the Open Mode of Each PDB
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS;

--Showing the Data Files for Each PDB in a CDB
SELECT p.PDB_ID, p.PDB_NAME, d.FILE_ID, d.TABLESPACE_NAME, d.FILE_NAME
  FROM DBA_PDBS p, CDB_DATA_FILES d
  WHERE p.PDB_ID = d.CON_ID
  ORDER BY p.PDB_ID;
  
--Showing the Temp Files in a CDB
  SELECT CON_ID, FILE_ID, TABLESPACE_NAME, FILE_NAME
  FROM CDB_TEMP_FILES
  ORDER BY CON_ID;

SELECT *  FROM database_properties 
--where property_name like '%PDB%' 
order by property_name;

select * from cdb_properties order by property_name;
where con_id=3 and property_name in ('MAX_SHARED_TEMP_SIZE','MAX_PDB_STORAGE');
