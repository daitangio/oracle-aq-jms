set serveroutput on
prompt ========================================
prompt Creating GPE_COMMANDER AND JMS Queues
prompt ========================================

-- exec aq_jms_pkg.ensure_jmstext_queue_exists('GPE_HEARTBEAT', p_force=>false);
exec aq_jms_pkg.ensure_jmstext_queue_exists('GPE_COMMANDER');


exec aq_jms_pkg.ensure_jmstext_queue_exists('GPE_COMMANDER_jj');

-- Basic JMS Object-based Queue 
exec aq_jms_pkg.ensure_jmsobject_queue_exists('FILE_NOTIFICATION');
exec aq_jms_pkg.ensure_jmsobject_queue_exists('BULK_RECIPIENT');




-- exec aq_jms_pkg.create_vt_queue( p_queue_name => 'GPE_BULK_PAYMENTS', p_retry_delay_min => 3, p_max_retries =>3, p_force_recreate=>'N');
commit;
