set serveroutput on
prompt ========================================
prompt Creating GPE_HEARTBEAT AND JMS Queues for XE
prompt ========================================

exec aq_jms_pkg.ensure_jmstext_queue_exists('GPE_HEARTBEAT', p_force=>false);
exec aq_jms_pkg.send_heartbeat('test');
commit;

declare
 mp varchar2(2000);
 msg varchar2(2000);
begin

aq_jms_pkg.dequeue (
  p_queue_name      =>'GPE_HEARTBEAT',
  p_message_present => mp, -- Y/N
  p_message         => msg
);
SYS.DBMS_OUTPUT.PUT_LINE('Got Message:' || msg);

end;
/

--exec aq_jms_pkg.send_heartbeat('EXIT');
