
-- Topic example queue (direct use)
set serveroutput on;

begin
aq_jms_pkg.stop_single_queue ('GPE_TEST_TOPIC');
aq_jms_pkg.drop_single_queue ('GPE_TEST_TOPIC');
aq_jms_pkg.drop_single_queue_table('GPE_TEST_TOPIC');

dbms_aqadm.create_queue_table(
     queue_table=> 'GPE_TEST_TOPIC',
     queue_payload_type=>'sys.aq$_jms_text_message',
     sort_list          => 'PRIORITY,ENQ_TIME',     
     multiple_consumers=>true, /* TOPIC */
     comment            => 'demo topic queue',
     storage_clause     => 'initrans 30'
);

 dbms_aqadm.create_queue (
      queue_name         => 'GPE_TEST_TOPIC',
      queue_table        => 'GPE_TEST_TOPIC',
      retry_delay        => 120, /*Secs*/
      max_retries        => 3,
      comment            => 'Topic test queue'
    );

dbms_aqadm.start_queue (
    queue_name         => 'GPE_TEST_TOPIC',
    dequeue            => true,
    enqueue            => true
  );
commit;  
end;
/

show errors



