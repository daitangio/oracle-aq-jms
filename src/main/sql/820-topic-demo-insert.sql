declare
 r raw(32);
begin
--- Put some data on the topic
r:=aq_jms_pkg.jms_topic_enqueue( 'GPE_TEST_TOPIC','Topic1', 5);

r:=aq_jms_pkg.jms_topic_enqueue( 'GPE_TEST_TOPIC','Topic2', 5);

r:=aq_jms_pkg.jms_topic_enqueue( 'GPE_TEST_TOPIC','Topic3', 5);
rollback;
end;
