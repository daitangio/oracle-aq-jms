
--set echo on
set serveroutput on

/**
GPE QUEUE Management package

This package is loosely  based on the queue test package
The basic idea is to have a pl/sql package which will push data on queue,
 and a stored procedure entrypoint will put the java side in wait state.


Queue table identifer must sit around 24 chars

 */
 
 
 
create or replace package aq_jms_pkg
is

  TYPE t_rowid_array IS TABLE OF ROWID   INDEX BY BINARY_INTEGER;
  AQUEUE_ENQUEUE_ARRAY_LIMIT CONSTANT NUMBER DEFAULT 1000;
  INSERT_PARALLEL_LEVEL   CONSTANT NUMBER DEFAULT 2; -- Try 4 on Exadata

-- -   TYPE mypayment IS REF CURSOR RETURN vt_bulk_payments%ROWTYPE;

  procedure create_vt_queue (
    p_queue_name      varchar2, -- case-insensitive
    p_retry_delay_min number   default 5, -- minutes of invisibility after rollback 
    p_max_retries     int      default 2000000000, -- max number of retries 
    p_force_recreate  varchar2 default 'N'
  );


  -- se non ci sono messaggi in coda:
  --   p_timeout_secs = 0 => ritorna immediatamente 
  --   p_timeout_secs > 0 => ritorna al primo messaggio con timeout
  -- p_message_present = 'Y' => un messaggio e' stato ritornato
  -- p_message => il messaggio (valido solo se p_message_present = 'Y')
  --
  -- commit => il messaggio viene eliminato dalla coda
  -- rollback => il messaggio rimane in coda
  procedure dequeue (
    p_queue_name      varchar2,
    p_timeout_secs    int default 600,
    p_message_present out varchar2, -- Y/N
    p_message         out varchar2
  );

  

  -- accoda un messaggio jms
  function jms_enqueue (
    p_queue_name      varchar2,
    p_message varchar2, 
    p_priority number default 100
  )
  return raw;
  
  function jms_topic_enqueue (
    p_queue_name      varchar2,
    p_message varchar2, 
    p_priority number default 100
  ) return raw;
  
  
  -- accoda p_n messaggi col prefisso dato
  procedure enqueue_test (
    p_queue_name varchar2,
    p_prefix varchar2, 
    p_n number
  );
  
  -- svuota la coda
  procedure empty_queue(p_queue_name      varchar2);



   --GG Crea una coda testuale se non esiste già
   --
   procedure ensure_jmstext_queue_exists(p_qname varchar2, p_force boolean default false);

   procedure ensure_jmsobject_queue_exists(p_qname varchar2, p_force boolean default false);

  procedure drop_single_queue (p_single_queue_name varchar2) ; 
  procedure drop_single_queue_table (p_single_queue_table_name varchar2) ;
  procedure stop_single_queue (p_single_queue_name varchar2) ;



end aq_jms_pkg;

/
show errors
