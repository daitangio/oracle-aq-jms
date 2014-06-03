/****GG Create a user called "gundam" to test the AQ ****/
-- user SYS
grant execute on dbms_aq    to gundam;
grant execute on dbms_aqadm to gundam;
GRANT EXECUTE ON dbms_aqin  to gundam;
grant aq_user_role          to gundam;


/
show errors

exit
