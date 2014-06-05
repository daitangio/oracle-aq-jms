/****GG Create a user called "gundam" to test the AQ 

-- USER SQL
CREATE USER gundam IDENTIFIED BY gundam 
DEFAULT TABLESPACE "USERS"
TEMPORARY TABLESPACE "TEMP";

-- QUOTAS

-- ROLES
GRANT "RESOURCE" TO gundam ;
GRANT "CONNECT" TO gundam ;
ALTER USER gundam DEFAULT ROLE "RESOURCE","CONNECT";

-- SYSTEM PRIVILEGES
GRANT CREATE USER TO gundam ;
GRANT DROP USER TO gundam ;
GRANT UNLIMITED TABLESPACE TO gundam ;

****/
-- As  user SYS run
grant execute on dbms_aq    to gundam;
grant execute on dbms_aqadm to gundam;
GRANT EXECUTE ON dbms_aqin  to gundam;
grant aq_user_role          to gundam;


/
show errors

exit
