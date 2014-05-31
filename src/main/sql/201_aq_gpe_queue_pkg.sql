create or replace package body aq_jms_pkg
is

timeout_exception exception;
pragma exception_init (timeout_exception, -25228);


-- FIXME Add table based logging
procedure say(msg varchar2)
IS
 pragma autonomous_transaction;
begin
  INSERT INTO VT_LOG_QUEUE (MSG) VALUES (msg);
  COMMIT;
  dbms_output.put_line ('<AQ> '||msg);
end;

/******** LOW LEVEL FUNCTIONS ****/
function get_owner 
return varchar2
is
begin
  return sys_context ('userenv', 'current_user');
end get_owner;


function queue_table_exists (p_qtab_name varchar2)
return boolean
is
  l_owner varchar2(30) := get_owner;
  l_exists int;
begin
  select count(*)
    into l_exists
    from all_queue_tables 
   where owner = l_owner
     and queue_table = upper (p_qtab_name);
  
  return l_exists > 0;
end queue_table_exists;


function queue_exists (p_queue_name varchar2)
return boolean
is
  l_owner varchar2(30) := get_owner;
  l_exists int;
begin
  select count(*)
    into l_exists
    from all_queues 
   where owner = l_owner
     and name = upper (p_queue_name);
  
  return l_exists > 0;
end queue_exists;


/********************    ***/


procedure calc_queue_objs_names (
  p_queue_name         varchar2, -- case-insensitive
  p_out_queue_name     out varchar2,
  p_out_queue_name_exc out varchar2,
  p_out_qtab_name      out varchar2,
  p_out_msg_view_name  out varchar2
)
is
begin
  p_out_queue_name      := lower (p_queue_name);
  p_out_queue_name_exc  := p_out_queue_name || '_ex'; -- GG was exc
  p_out_qtab_name       := 'QT_' || p_out_queue_name ;
  p_out_msg_view_name   := p_out_queue_name || '_msgs';
end calc_queue_objs_names;

procedure stop_single_queue (p_single_queue_name varchar2) 
is
  no_such_queue exception;
  pragma exception_init (no_such_queue, -24010);
begin
  dbms_aqadm.stop_queue (
    queue_name         => p_single_queue_name,
    dequeue            => true,
    enqueue            => true
  );
  
  say ('stopped queue '||p_single_queue_name);
exception
  when no_such_queue then
    null;
end stop_single_queue;

-----------------------------------------------------------
procedure drop_single_queue (p_single_queue_name varchar2) 
is
  no_such_queue exception;
  pragma exception_init (no_such_queue, -24010);
begin
  dbms_aqadm.drop_queue (queue_name => p_single_queue_name);
  say ('dropped queue '||p_single_queue_name);
exception
  when no_such_queue then
    null;
end drop_single_queue;

-----------------------------------------------------------
procedure drop_single_queue_table (p_single_queue_table_name varchar2) 
is
  no_such_queue_table exception;
  pragma exception_init (no_such_queue_table, -24002);
begin
  dbms_aqadm.drop_queue_table (queue_table => p_single_queue_table_name);
  say ('dropped queue table '||p_single_queue_table_name);
exception
  when no_such_queue_table then
    null;
end drop_single_queue_table;

-----------------------------------------------------------
procedure drop_queue (
  p_queue_name  varchar2 -- case-insensitive
)
is
  l_queue_name       varchar2(30);
  l_queue_name_exc   varchar2(30);
  l_qtab_name        varchar2(30);
  l_owner            varchar2(30) := get_owner;
  l_dummy1           varchar2(30);
begin
  calc_queue_objs_names (p_queue_name, l_queue_name, l_queue_name_exc, l_qtab_name, l_dummy1);
  
  stop_single_queue (l_queue_name);
  stop_single_queue (l_queue_name_exc);
    
  drop_single_queue (l_queue_name);
  drop_single_queue (l_queue_name_exc);
  
  drop_single_queue_table (l_qtab_name);

end drop_queue;







/*** Queue management functions */
procedure create_vt_queue (
  p_queue_name      varchar2, -- case-insensitive
  p_retry_delay_min number   default 5, -- minutes of invisibility after rollback 
  p_max_retries     int      default 2000000000, -- max number of retries 
  p_force_recreate  varchar2 default 'N'
)
is
  l_queue_name       varchar2(30);
  l_queue_name_exc   varchar2(30);
  l_qtab_name        varchar2(30);
  l_owner            varchar2(30) := get_owner;
  l_retry_delay_secs number := p_retry_delay_min * 60;
  l_dummy1           varchar2(30);
begin
  calc_queue_objs_names (p_queue_name, l_queue_name, l_queue_name_exc, l_qtab_name, l_dummy1);

  if upper(trim(p_force_recreate)) = 'Y' then
    drop_queue (p_queue_name);
  end if;
  
  if queue_table_exists(l_qtab_name) then
    say ('queue table '||l_qtab_name||' already exists');
  else
    dbms_aqadm.create_queue_table(
      queue_table        => l_owner || '.' || l_qtab_name,
      queue_payload_type => 'VT_QUEUE_PAYLOAD', 
      sort_list          => 'PRIORITY,ENQ_TIME',
      multiple_consumers => FALSE,
      message_grouping   => DBMS_AQADM.NONE,
      comment            => 'queue table for VTPIE queue ' || p_queue_name,
      storage_clause     => 'initrans 30'
    );
    say ('created queue table '||l_qtab_name);
  end if;
  
  if queue_exists (l_queue_name) then
    say ('queue '||l_queue_name||' already exists');
  else
    dbms_aqadm.create_queue (
      queue_name         => l_owner || '.' || l_queue_name,
      queue_table        => l_owner || '.' || l_qtab_name,
      retry_delay        => l_retry_delay_secs,
      max_retries        => p_max_retries,
      comment            => 'VTPIE queue'
    );
    say ('created queue '||l_queue_name);
  end if;
  
  dbms_aqadm.alter_queue (
    queue_name   => l_owner || '.' || l_queue_name,
    max_retries  => p_max_retries,
    retry_delay  => l_retry_delay_secs
  );
  say ('altered queue '||l_queue_name);

  if queue_exists (l_queue_name_exc) then
    say ('queue '||l_queue_name_exc||' already exists');
  else
    dbms_aqadm.create_queue (
      queue_name         => l_owner || '.' || l_queue_name_exc,
      queue_table        => l_owner || '.' || l_qtab_name,
      queue_type         => dbms_aqadm.exception_queue,
      comment            => 'exception queue for VTPIE queue "'||l_queue_name||'"'
    );
    say ('created queue '||l_queue_name_exc);
  end if;  

  dbms_aqadm.start_queue (
    queue_name         => l_owner || '.' || l_queue_name,
    dequeue            => true,
    enqueue            => true
  );
  say ('started queue '||l_queue_name);

  dbms_aqadm.start_queue (
    queue_name         => l_owner || '.' || l_queue_name_exc,
    dequeue            => true,
    enqueue            => false
  );
  say ('started queue '||l_queue_name_exc);

  
  -- dbms_aqadm.grant_queue_privilege (
  --  privilege   => 'ALL',
  --  queue_name  => l_queue_name,
  --  grantee     => 'beasadm'
  -- );
  
  -- dbms_aqadm.grant_queue_privilege (
  --  privilege   => 'DEQUEUE',
  --  queue_name  => l_queue_name_exc,
  --  grantee     => 'beasadm'
  -- );
end create_vt_queue;






/************ DEQUEUE UTIL FUNCTION */
function dequeue_util (
  p_queue_name       varchar2,
  p_timeout_secs     int default 600,
  p_message_present  out varchar2, -- Y/N
  p_payload          out nocopy vt_queue_payload
)
return raw
is
  l_queue_name     varchar2(30);
  l_options        dbms_aq.dequeue_options_t;
  l_msg_props      dbms_aq.message_properties_t;
  l_msgid          raw(16);
begin
  p_message_present := 'N';
  l_queue_name      := get_owner||'.'||lower (p_queue_name);
  
  l_options.navigation := dbms_aq.FIRST_MESSAGE;
  if p_timeout_secs = 0 then
    l_options.wait := dbms_aq.NO_WAIT;
  else
    l_options.wait := p_timeout_secs;
  end if;
   
  dbms_aq.dequeue (
    queue_name         => l_queue_name,
    dequeue_options    => l_options,
    message_properties => l_msg_props,
    payload            => p_payload,
    msgid              => l_msgid
  );
  
  dbms_output.put_line ('attempts='||l_msg_props.attempts);
  
  p_message_present := 'Y';
  return l_msgid;
exception
  when timeout_exception then
    p_message_present := 'N';
    return null;
end dequeue_util; 






/** 
  JMS DEQUEUE
  See http://gbowyer.freeshell.org/oracle-aq.html
*/
-----------------------------------------------------------
function jms_enqueue (
  p_queue_name      varchar2,
  p_message varchar2, 
  p_priority number default 100
)
return raw
is
  l_queue_name     varchar2(40);
  l_queue_name_exc varchar2(40);
  l_options        dbms_aq.enqueue_options_t;
  l_msg_props      dbms_aq.message_properties_t;
  l_msgid          raw(32);
  l_msg            sys.aq$_jms_text_message := sys.aq$_jms_text_message.construct();

begin
  l_queue_name      := sys_context ('userenv', 'current_user')||'.'|| p_queue_name;
  l_queue_name_exc  := l_queue_name || '_EX';
  
  l_msg_props.priority := p_priority;
  l_msg_props.exception_queue := l_queue_name_exc;

  l_msg.set_text (p_message);


  --     --payload            => utl_raw.cast_to_raw (p_message),

  dbms_aq.enqueue (
    queue_name         => l_queue_name,
    enqueue_options    => l_options,
    message_properties => l_msg_props,
    payload            => l_msg,
    msgid              => l_msgid 
  );
  
  return l_msgid;
end jms_enqueue;







-----------------------------------------------------------
procedure dequeue (
  p_queue_name      varchar2,
  p_timeout_secs    int default 600,
  p_message_present out varchar2, -- Y/N
  p_message         out varchar2
)
is
  l_queue_name     varchar2(30);
  l_options        dbms_aq.dequeue_options_t;
  l_msg_props      dbms_aq.message_properties_t;
  l_payload        sys.aq$_jms_text_message ; /*raw(2000);*/
  l_msgid          raw(32);
  timeout_exception exception;
  pragma exception_init (timeout_exception, -25228);
begin
  l_queue_name      := sys_context ('userenv', 'current_user')||'.'|| p_queue_name;
  
  l_options.navigation := dbms_aq.FIRST_MESSAGE;
  if p_timeout_secs = 0 then
    l_options.wait := dbms_aq.NO_WAIT;
  else
    l_options.wait := p_timeout_secs;
  end if;
   
  dbms_aq.dequeue (
    queue_name         => l_queue_name,
    dequeue_options    => l_options,
    message_properties => l_msg_props,
    payload            => l_payload,
    msgid              => l_msgid
  );
  
  say ('attempts='||l_msg_props.attempts);
  
  p_message_present := 'Y';
  --p_message := utl_raw.cast_to_varchar2 (l_payload);
  -- GG see http://docs.oracle.com/cd/B19306_01/appdev.102/b14258/t_jms.htm#i996967u
  p_message := l_payload.text_vc;
exception
  when timeout_exception then
    p_message_present := 'N';
    p_message := 'if you are reading me you have done something wrong';
end dequeue;

-----------------------------------------------------------
procedure enqueue_test (p_queue_name varchar2, p_prefix varchar2, p_n number) 
is
  l_msg varchar2(100 char);
  l_msgid raw(32);
begin
  for i in 1..p_n loop
    l_msg := p_prefix || ' ' || i || ' ' || to_char (sysdate, 'dd/mm/yyyy hh24:mi:ss');
    l_msgid := jms_enqueue (p_queue_name,l_msg);
    say ('enqueued '||l_msg||' -> '||l_msgid);
  end loop;
end enqueue_test;

-----------------------------------------------------------
/** GG Eval also DBMS_AQADM.PURGE_QUEUE_TABLE
*/
procedure empty_queue(p_queue_name      varchar2)
is
  l_message_present varchar2(1 char);
  l_message varchar2 (1000 char);
  c         NUMBER(9) :=0;
begin
  loop
    dequeue (p_queue_name, 0, l_message_present, l_message);
    c :=c+1;
    exit when l_message_present = 'N';
  end loop;
  commit;
   say ('Empty queue: '|| p_queue_name ||  ' Removed ' || (c-1) || ' Messages');
end empty_queue;
  

/*** Support functions  */
procedure create_public_synonym (name in varchar2) is 
    NO_SUCH_SYNONYM EXCEPTION;
    PRAGMA EXCEPTION_INIT(NO_SUCH_SYNONYM, -1432);
  begin
    begin
      execute immediate 'drop public synonym ' || name;
    exception
      when NO_SUCH_SYNONYM then
        null;
    end;
    execute immediate 'create public synonym ' || name || ' for ' || name; 
  end create_public_synonym;
  
  procedure exec_ignore (p_exec varchar2)
  is
  begin
    execute immediate p_exec;
  exception
    when others then
      say ('ignore exception '||sqlerrm||' on '||p_exec);
  end exec_ignore;
/*** */


procedure ensure_jmstext_queue_exists(p_qname varchar2, p_force boolean default false)
is
	l_queue_tablespace varchar2(24) default 'USERS';
	l_extent_size  	   varchar2(24) default '100K';
	l_retry_delay_minutes number default 0;
	l_queue_long_name     varchar2(61);
	l_exc_queue_long_name varchar2(61);
	l_queue_table         varchar2(30);
	l_queue_user          varchar2(30)  := user;
	l_check_table_queue   number(1);

begin

 l_queue_long_name     := upper(p_qname) ;
 l_exc_queue_long_name := upper(p_qname) || '_EX';
 l_queue_table         := 'QT_' || upper(p_qname) ;	
	

 select count(*) into l_check_table_queue from all_tables
 where owner=user and table_name=upper(l_queue_table);
 
 if p_force =false and l_check_table_queue = 1 then
    say ('Queue table ' ||l_queue_table ||  ' already exist. Nothing to be done.');
    return;
 end if ;


 exec_ignore ('begin dbms_aqadm.stop_queue('''||l_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.stop_queue('''||l_exc_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue('''||l_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue('''||l_exc_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue_table('''||l_queue_table||'''); end;');

 dbms_aqadm.create_queue_table(
   queue_table        => l_queue_table,
   
   queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE', 
   -- Note: Raw does not work with JMS java. you got null pointer exception 
   -- onto  oracle.jms.AQjmsConsumer.<init>(AQjmsConsumer.java:359)
   -- queue_payload_type => 'RAW', 
   sort_list          => 'PRIORITY,ENQ_TIME',
   multiple_consumers => FALSE,
   message_grouping   => DBMS_AQADM.NONE,
   comment            => 'queue table for ' || p_qname,
   storage_clause     => ' tablespace ' || l_queue_tablespace || ' ' ||
                         ' pctfree 5 initrans 5 maxtrans 255 ' ||
                         ' storage (  initial ' || l_extent_size || 
                                    ' next '    || l_extent_size || 
                                    ' pctincrease 0 ' ||
                                    ' minextents  1 ' ||
                                    ' maxextents  unlimited ) '
 );

 dbms_aqadm.create_queue (
   queue_name         => l_queue_long_name,
   queue_table        => l_queue_table,
   queue_type         => DBMS_AQADM.NORMAL_QUEUE,
   max_retries        => 2000000000,
   retry_delay        => 60 * l_retry_delay_minutes,
   comment            => p_qname || ' queue');

 dbms_aqadm.create_queue (
   queue_name         => l_exc_queue_long_name,
   queue_table        => l_queue_table,
   queue_type         => DBMS_AQADM.EXCEPTION_QUEUE,
   comment            => p_qname || ' exception queue');

 dbms_aqadm.start_queue (
   queue_name         => l_queue_long_name,
   dequeue            => TRUE,
   enqueue            => TRUE);

 dbms_aqadm.start_queue (
   queue_name         => l_exc_queue_long_name,
   dequeue            => TRUE,
   enqueue            => FALSE);

 if l_queue_user != user then
   dbms_aqadm.grant_queue_privilege (
     privilege    => 'ALL',
     queue_name   => l_queue_long_name,
     grantee      => l_queue_user,
     grant_option => FALSE);
  end if;

  /** GG Eval if you want some synonym for security reason */   
  -- -- public synonyms 
  -- --create_public_synonym (queue_long_name);
  -- --create_public_synonym (exc_queue_long_name);
  -- --create_public_synonym (queue_table);
  -- if l_queue_user != user then
  --   execute immediate 'grant select on ' || l_queue_table || ' to ' || l_queue_user;
  -- end if;


end ensure_jmstext_queue_exists;


procedure ensure_jmsobject_queue_exists(p_qname varchar2, p_force boolean default false)
is
	l_queue_tablespace varchar2(24) default 'USERS';
	l_extent_size  	   varchar2(24) default '100K';
	l_retry_delay_minutes number default 0;
	l_queue_long_name     varchar2(61);
	l_exc_queue_long_name varchar2(61);
	l_queue_table         varchar2(30);
	l_queue_user          varchar2(30)  := user;
	l_check_table_queue   number(1);

begin

 l_queue_long_name     := upper(p_qname) ;
 l_exc_queue_long_name := upper(p_qname) || '_EX';
 l_queue_table         := 'QT_' || upper(p_qname) ;	
	

 select count(*) into l_check_table_queue from all_tables
 where owner=user and table_name=upper(l_queue_table);
 
 if p_force =false and l_check_table_queue = 1 then
    say ('Queue table ' ||l_queue_table ||  ' already exist. Nothing to be done.');
    return;
 end if ;


 exec_ignore ('begin dbms_aqadm.stop_queue('''||l_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.stop_queue('''||l_exc_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue('''||l_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue('''||l_exc_queue_long_name||'''); end;');
 exec_ignore ('begin dbms_aqadm.drop_queue_table('''||l_queue_table||'''); end;');

 dbms_aqadm.create_queue_table(
   queue_table        => l_queue_table,
   
   queue_payload_type => 'SYS.AQ$_JMS_OBJECT_MESSAGE', 
   -- Note: Raw does not work with JMS java. you got null pointer exception 
   -- onto  oracle.jms.AQjmsConsumer.<init>(AQjmsConsumer.java:359)
   -- queue_payload_type => 'RAW', 
   sort_list          => 'PRIORITY,ENQ_TIME',
   multiple_consumers => FALSE,
   message_grouping   => DBMS_AQADM.NONE,
   comment            => 'queue table for ' || p_qname,
   storage_clause     => ' tablespace ' || l_queue_tablespace || ' ' ||
                         ' pctfree 5 initrans 5 maxtrans 255 ' ||
                         ' storage (  initial ' || l_extent_size || 
                                    ' next '    || l_extent_size || 
                                    ' pctincrease 0 ' ||
                                    ' minextents  1 ' ||
                                    ' maxextents  unlimited ) '
 );

 dbms_aqadm.create_queue (
   queue_name         => l_queue_long_name,
   queue_table        => l_queue_table,
   queue_type         => DBMS_AQADM.NORMAL_QUEUE,
   max_retries        => 2000000000,
   retry_delay        => 60 * l_retry_delay_minutes,
   comment            => p_qname || ' queue');

 dbms_aqadm.create_queue (
   queue_name         => l_exc_queue_long_name,
   queue_table        => l_queue_table,
   queue_type         => DBMS_AQADM.EXCEPTION_QUEUE,
   comment            => p_qname || ' exception queue');

 dbms_aqadm.start_queue (
   queue_name         => l_queue_long_name,
   dequeue            => TRUE,
   enqueue            => TRUE);

 dbms_aqadm.start_queue (
   queue_name         => l_exc_queue_long_name,
   dequeue            => TRUE,
   enqueue            => FALSE);

 if l_queue_user != user then
   dbms_aqadm.grant_queue_privilege (
     privilege    => 'ALL',
     queue_name   => l_queue_long_name,
     grantee      => l_queue_user,
     grant_option => FALSE);
  end if;

  /** GG Eval if you want some synonym for security reason */   
  -- -- public synonyms 
  -- --create_public_synonym (queue_long_name);
  -- --create_public_synonym (exc_queue_long_name);
  -- --create_public_synonym (queue_table);
  -- if l_queue_user != user then
  --   execute immediate 'grant select on ' || l_queue_table || ' to ' || l_queue_user;
  -- end if;


end ensure_jmsobject_queue_exists;





/**
Core work
*/




/**
 Must return a ordered subselect which maps the
 vt_bulk_payments table columns
*/
function get_bulk_payments_sql(
	 aq_msg_id IN NUMBER,
         bankCode  IN VARCHAR2 ,
         bulkDate  IN DATE ,
         bulkCode  IN NUMBER	 
)
   RETURN CLOB
IS
 get_bulk_payments_cache CLOB;
 CURSOR remapCursor IS
  SELECT  
        C || decode(REMAP,NULL, NULL, ( ' as ' || REMAP) ) AS MX
  FROM vt_bulk_payments_COLUMN_MAP WHERE FUNC ='SEND_BULK_PAYMENTS_FULL'
  order by "COLUMN_ORDER";

  remapLine remapCursor%ROWTYPE;
  actual_query CLOB;
  

BEGIN

  --if get_bulk_payments_cache is null then
      say(' Building query cache for SEND_BULK_PAYMENTS_FULL');
      
      get_bulk_payments_cache := '  select ' || aq_msg_id ||'  as AQ_ID_BATCH,
    ''SEND_BULK_PAYMENTS_FULL'' AS PID ,
       to_date( ''' || TO_CHAR(bulkDate,'ddMMyy') || ''', ''ddMMyy'')  AS ITEM_TECH_DATE,
     '||  bulkCode || ' as ITEM_TECH_CODE,
     sysdate as  MSG_LOAD_DATE,
    ALLPAYMENTS.*
    FROM 
    (SELECT dp.rowid as DP_ROWID
' ;
      
      -- Fill in mega query: part1 mapping columns....
      open remapCursor;
      loop 
        fetch remapCursor into remapLine;
      	EXIT WHEN remapCursor%NOTFOUND;
      	get_bulk_payments_cache := get_bulk_payments_cache || ',' || remapLine.MX;
      	-- say(' ' || get_bulk_payments_cache );
      end loop;

      get_bulk_payments_cache := get_bulk_payments_cache || '

';

      get_bulk_payments_cache := get_bulk_payments_cache || ' FROM VT_DISPOSIZIONI dp LEFT OUTER JOIN VT_ORDINANTI_DISPOSIZIONI od ON dp.COD_BANCA = od.COD_BANCA
   AND dp.DATA_ORDINANTE                                                                              =
   od.DATA_ORDINANTE AND dp.COD_TECNICO_ORDINANTE                                                     =
   od.COD_TECNICO_ORDINANTE LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO pic ON od.COD_BANCA           = pic.COD_BANCA
   AND od.DATA_PARTY_ID                                                                               =
   pic.DATA_PARTY_ID AND od.COD_TECNICO_PARTY_ID                                                      =
   pic.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO ppic ON pic.COD_BANCA          = ppic.COD_BANCA
   AND pic.DATA_PARTY_ID                                                                              =
   ppic.DATA_PARTY_ID AND pic.COD_TECNICO_PARTY_ID                                                    =
   ppic.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_CONTROPARTI_DISPOSIZIONI cp ON dp.COD_BANCA           = cp.COD_BANCA
   AND dp.DATA_CONTROPARTE                                                                            =
   cp.DATA_CONTROPARTE AND dp.COD_TECNICO_CONTROPARTE                                                 =
   cp.COD_TECNICO_CONTROPARTE LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO pid ON cp.COD_BANCA         = pid.COD_BANCA
   AND cp.DATA_PARTY_ID                                                                               =
   pid.DATA_PARTY_ID AND cp.COD_TECNICO_PARTY_ID                                                      =
   pid.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO ppid ON pid.COD_BANCA          = ppid.COD_BANCA
   AND pid.DATA_PARTY_ID                                                                              =
   ppid.DATA_PARTY_ID AND pid.COD_TECNICO_PARTY_ID                                                    =
   ppid.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_DISPOS_SEPA sp ON dp.COD_BANCA                        = sp.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   sp.DATA_DISPOSIZIONE AND dp.COD_TECNICO_DISPOSIZIONE                                               =
   sp.COD_TECNICO_DISPOSIZIONE LEFT OUTER JOIN VT_DISPOS_MANDATI md ON dp.COD_BANCA                   = md.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   md.DATA_DISPOSIZIONE AND dp.cod_tecnico_disposizione                                               =
   md.cod_tecnico_disposizione LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO csi ON md.COD_BANCA        = csi.COD_BANCA
   AND md.data_PARTY_ID_FIRM                                                                          =
   csi.DATA_PARTY_ID AND md.COD_TECNICO_PARTY_ID_FIRM                                                 =
   csi.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO csiprvt ON csi.COD_BANCA       =
   csiprvt.COD_BANCA AND csi.DATA_PARTY_ID                                                            =
   csiprvt.DATA_PARTY_ID AND csi.COD_TECNICO_PARTY_ID                                                 =
   csiprvt.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_FILE_DISPOSIZIONI fd ON dp.COD_BANCA               = fd.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           = fd.DATA_FILE
   AND dp.COD_TECNICO_FILE                                                                            =
   fd.COD_TECNICO_FILE LEFT OUTER JOIN VT_DISPOS_ORIGINAL DO ON dp.COD_BANCA                          = do.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   do.DATA_DISPOSIZIONE AND dp.COD_TECNICO_DISPOSIZIONE                                               =
   do.COD_TECNICO_DISPOSIZIONE LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO pido ON do.COD_BANCA       = pido.COD_BANCA
   AND do.DATA_PARTY_ID                                                                               =
   pido.DATA_PARTY_ID AND do.COD_TECNICO_PARTY_ID                                                     =
   pido.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO ppido ON pido.COD_BANCA       = ppido.COD_BANCA
   AND pido.DATA_PARTY_ID                                                                             =
   ppido.DATA_PARTY_ID AND pido.COD_TECNICO_PARTY_ID                                                  =
   ppido.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_DISPOS_ORIG_FINALE og ON dp.COD_BANCA                = og.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   og.DATA_DISPOSIZIONE AND dp.COD_TECNICO_DISPOSIZIONE                                               =
   og.COD_TECNICO_DISPOSIZIONE LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO pigc ON og.COD_BANCA       = pigc.COD_BANCA
   AND og.DATA_PARTY_ID_ORDIN_ORIG                                                                    =
   pigc.DATA_PARTY_ID AND og.COD_TECNICO_PARTY_ID_ORDIN_ORI                                           =
   pigc.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO ppigc ON pigc.COD_BANCA       = ppigc.COD_BANCA
   AND pigc.DATA_PARTY_ID                                                                             =
   ppigc.DATA_PARTY_ID AND pigc.COD_TECNICO_PARTY_ID                                                  =
   ppigc.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO pigd ON og.COD_BANCA        = pigd.COD_BANCA
   AND og.DATA_PARTY_ID_CONTROP_FINALE                                                                =
   pigd.DATA_PARTY_ID AND og.COD_TECNICO_PARTY_ID_CONTROP_F                                           =
   pigd.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO ppigd ON pigd.COD_BANCA       = ppigd.COD_BANCA
   AND pigd.DATA_PARTY_ID                                                                             =
   ppigd.DATA_PARTY_ID AND pigd.COD_TECNICO_PARTY_ID                                                  =
   ppigd.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO mdpii ON md.COD_BANCA       = mdpii.COD_BANCA
   AND md.data_PARTY_ID_FIRM_ORIG                                                                     =
   mdpii.DATA_PARTY_ID AND md.COD_TECNICO_PARTY_ID_FIRM_ORIG                                          =
   mdpii.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO mdppii ON mdpii.COD_BANCA    =
   mdppii.COD_BANCA AND mdpii.DATA_PARTY_ID                                                           =
   mdppii.DATA_PARTY_ID AND mdpii.COD_TECNICO_PARTY_ID                                                =
   mdppii.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_IDENTIFICATION_ISO odgpii ON md.COD_BANCA     =
   odgpii.COD_BANCA AND md.ORGDBT_DATE                                                                =
   odgpii.DATA_PARTY_ID AND md.ORGDBT_SEQ                                                             =
   odgpii.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_PARTY_PRIVATE_IDENT_ISO odgppii ON odgpii.COD_BANCA =
   odgppii.COD_BANCA AND odgpii.DATA_PARTY_ID                                                         =
   odgppii.DATA_PARTY_ID AND odgpii.COD_TECNICO_PARTY_ID                                              =
   odgppii.COD_TECNICO_PARTY_ID LEFT OUTER JOIN VT_DISPOS_EMBARGO_FEEDBACK embf ON dp.COD_BANCA       = embf.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   embf.DATA_DISPOSIZIONE AND dp.COD_TECNICO_DISPOSIZIONE                                             =
   embf.COD_TECNICO_DISPOSIZIONE LEFT OUTER JOIN VT_DISPOS_ID_ALTERNATIVI alt ON dp.COD_BANCA         = alt.COD_BANCA
   AND dp.DATA_DISPOSIZIONE                                                                           =
   alt.DATA_DISPOSIZIONE AND dp.COD_TECNICO_DISPOSIZIONE                                              =
   alt.COD_TECNICO_DISPOSIZIONE ';

  --end if;

  actual_query := get_bulk_payments_cache || '

   WHERE dp.COD_BANCA       = '''|| bankCode ||''' AND
   dp.DATA_DISTINTA         = :bulkDate AND
   dp.COD_TECNICO_DISTINTA  = '||bulkCode||'
    ) ALLPAYMENTS
   ';   
  return actual_query;


END;

/*
PROCEDURE TEST_42
IS
 select_part CLOB;
 d DATE default sysdate;
 aq_msg_id NUMBER;

 start_cpu_time NUMBER;
 end_cpu_time NUMBER;
 l_sec_taken    NUMBER;
 l_elements_sent NUMBER;
BEGIN


	-- declare
	--   p_message_present  varchar2(1);
	--   p_payload          vt_bulk_payments%ROWTYPE;
	-- begin
	-- say('Testing dequeue 1 msg....');
	-- DEQUEUE_BULK_PAYMENTS(
	--   p_timeout_secs     =>1,
	--   p_message_present  =>p_message_present,
	--   p_payload =>p_payload         
        -- );
	-- if p_message_present = 'Y' then
	--  say('Payload: Bulkid: ' || p_payload.AQ_ID_BATCH);
	--  say('Item tech code : ' || p_payload.ITEM_TECH_CODE);
	-- end if;
        -- end;
	
	
	-- Find out data

	-- select_part := get_bulk_payments_sql(   2323 , 'C0' , sysdate, 9000 );
	-- say(select_part);
	-- --sbms_output.put_line(insert_signature);
	-- say('Executing...');	
	-- execute immediate select_part using d;
	say('Ready to test send...');


	for dataFinder in (select * FROM (
	       select * FROM(
	       SELECT count(*) AS N, DATA_DISTINTA, COD_TECNICO_DISTINTA
	       FROM VT_DISPOSIZIONI dp 
	       WHERE dp.COD_BANCA                                                    = 'C0' 
	       group by DATA_DISTINTA, COD_TECNICO_DISTINTA
	       order by DATA_DISTINTA DESC, N DESC)
	       WHERE N<=200)
	       	 where rownum <=1) 
	loop

	         say('-----------------------------------------------------------------------------------------');
		 say('Input:' || dataFinder.COD_TECNICO_DISTINTA || ' ' || dataFinder.DATA_DISTINTA || ' Load:' || dataFinder.N);
	         start_cpu_time := dbms_utility.GET_CPU_TIME;


		 -- Phase2
		 SEND_BULK_PAYMENTS_FULL(
		 		 bankCode => 'C0',
		 		 bulkDate => dataFinder.DATA_DISTINTA ,
				 bulkCode => dataFinder.COD_TECNICO_DISTINTA,
				 aq_msg_id =>aq_msg_id,
				 elements_sent => l_elements_sent);
		 end_cpu_time := dbms_utility.GET_CPU_TIME;
		 l_sec_taken := ((end_cpu_time - start_cpu_time)/100);

		 say('CPU Time (in seconds)= '
                          || l_sec_taken);

		 say('Elem/sec:' ||  (l_elements_sent / l_sec_taken) );

		 say('Generated partition: '|| aq_msg_id);		 
        end loop;



END TEST_42;
*/


/****** Support functions *****/
procedure enqueue_array (
  p_queue_name     varchar2,
  p_payload_array  vt_queue_payload_array,
  p_array_size     int,
  p_priority       number default 100
)
is
  l_aq_msg_id     raw(16);
  l_row_unique_id number;
  l_payload       vt_queue_payload;
  l_num_enqueued int;
  ---
  l_queue_name     varchar2(61);
  l_queue_name_exc varchar2(61);
  l_options        dbms_aq.enqueue_options_t;
  l_msg_props      dbms_aq.message_properties_t;
  l_msg_props_array dbms_aq.message_properties_array_t;
  l_msgid          raw(32);
  l_msgid_array    dbms_aq.msgid_array_t;
begin
  if p_array_size = 0 then
    return;
  end if;

  l_queue_name      := get_owner ||'.'||lower (p_queue_name);
  l_queue_name_exc  := l_queue_name || '_ex'; --GG Was exc
  
  l_msg_props.priority := p_priority;
  l_msg_props.exception_queue := l_queue_name_exc;
 
  l_msg_props_array := dbms_aq.message_properties_array_t();
  l_msg_props_array.extend(p_array_size);

  l_msgid_array := dbms_aq.msgid_array_t();
  l_msgid_array.extend(p_array_size);

  for i in 1..p_array_size loop
    l_msg_props_array(i) := l_msg_props;
  end loop;

  l_num_enqueued := dbms_aq.enqueue_array (
    queue_name               => l_queue_name,
    enqueue_options          => l_options,
    array_size               => p_array_size,
    message_properties_array => l_msg_props_array,
    payload_array            => p_payload_array,
    msgid_array              => l_msgid_array 
  );
    
end enqueue_array;


procedure enqueue_batch (
  p_queue_name varchar2,
  aq_msg_id number,
  elements_sent OUT number
)
is
  l_buffer vt_queue_payload_array := vt_queue_payload_array();
  l_buffer_size     int := 0;
  l_buffer_size_max int := AQUEUE_ENQUEUE_ARRAY_LIMIT;
  l_stuff_sent      int :=0;

  procedure flush_buffer
  is
  begin
    enqueue_array (
      p_queue_name     => p_queue_name,
      p_payload_array  => l_buffer,
      p_array_size     => l_buffer_size,
      p_priority       => 100
    );
    l_buffer_size := 0;
  end flush_buffer;

begin


  -- array processing
  l_buffer.extend(l_buffer_size_max);
  for i in 1..l_buffer_size_max loop
    l_buffer(i) := vt_queue_payload(null);
  end loop;

  for r in (  select ROWID FROM vt_bulk_payments WHERE AQ_ID_BATCH= AQ_ID_BATCH )
  loop
    l_buffer_size := l_buffer_size + 1;
    l_buffer(l_buffer_size).row_id := rowidtochar(r.rowid);
    if l_buffer_size = l_buffer_size_max then
      l_stuff_sent := l_stuff_sent+l_buffer_size;
      flush_buffer; -- flush_buffer resets l_buffer_size
    end if;
  end loop;
  l_stuff_sent := l_stuff_sent+l_buffer_size;
  flush_buffer;
  commit;
  say('[Enqueue_Buffer] Sent ' || l_stuff_sent ||' elements');
  elements_sent := l_stuff_sent;
end enqueue_batch; 




/** Una partzione= 1 distinta che ha n disposizioni
  */
PROCEDURE SEND_BULK_PAYMENTS_FULL(
         bankCode IN VARCHAR2 ,
         bulkDate IN DATE ,
         bulkCode IN NUMBER ,
         aq_msg_id  OUT NUMBER,
	 elements_sent OUT NUMBER )
IS
 select_part CLOB;
  l_add_par  VARCHAR2(2000);
begin
  -- Do core query and store results into 
  -- vt_bulk_payments_AQK_I
  select SEQ_AQ_ID_BATCH.nextVal into  aq_msg_id  from dual;

    -- sia 10 la AQ_ID_BATCH

    -- alter table vt_bulk_payments drop partition test ;
    -- Ok qui non facciamo il quote dell'input ma l'input è sano.

    l_add_par := 'alter table vt_bulk_payments add partition p'||aq_msg_id||'  values (' || aq_msg_id ||')'; 
    say(l_add_par);
    execute immediate l_add_par ;
       

    select_part := get_bulk_payments_sql( aq_msg_id ,bankCode, bulkDate, bulkCode );
    say('Doing mega insert');
    execute immediate ('alter session enable parallel dml');
    execute immediate ('insert /*+ append parallel(' || INSERT_PARALLEL_LEVEL  || ') */ into vt_bulk_payments partition ( p'||aq_msg_id|| ')' || select_part) using  bulkDate;
    commit;
    execute immediate ('alter session disable parallel dml');
    say('Ok enqueuing data....');
    enqueue_batch('GPE_BULK_PAYMENTS',aq_msg_id, elements_sent);
        

end SEND_BULK_PAYMENTS_FULL;
 

PROCEDURE TRUNCATE_OLD_PARTITIONS(partitionNumber IN NUMBER default NULL)
IS
 pn NUMBER;
BEGIN
 if partitionNumber IS NULL then
   select min(AQ_ID_BATCH) into pn from vt_bulk_payments ;
   say('Oldest partition [Auto]:' || pn);
 else
  pn := partitionNumber;
  say('Oldest partition [User Input]:' || pn);
 end if; 	
 
 execute immediate 'alter table vt_bulk_payments drop partition p' ||pn;
END TRUNCATE_OLD_PARTITIONS;



/**
 Single dequeue
  */
PROCEDURE DEQUEUE_BULK_PAYMENTS_C(
  p_timeout_secs     int default 600,
  p_message_present  out varchar2, -- Y/N 
  p_payload          out mypayment  
)
IS
  l_aq_msg_id raw(16);
  l_payload   vt_queue_payload;
begin

  l_aq_msg_id := dequeue_util (
    p_queue_name      => 'GPE_BULK_PAYMENTS',
    p_timeout_secs    => p_timeout_secs,
    p_message_present => p_message_present,
    p_payload         => l_payload
  );

  if p_message_present = 'N' then
    return;
  end if;


  open p_payload FOR
  select  *  from vt_bulk_payments 
  where rowid=chartorowid(l_payload.row_id);


END DEQUEUE_BULK_PAYMENTS_C;


/** Multi object dequeue */
PROCEDURE DEQUEUE_BULK_PAYMENTS(
  p_timeout_secs     int default 600,
  p_message_present  out varchar2, -- Y/N 
  p_payload          out mypayment  
)
IS
  l_aq_msg_id1 raw(16);
  l_aq_msg_id2 raw(16);
  l_payload1   vt_queue_payload;
  l_payload2   vt_queue_payload;
begin

  l_aq_msg_id1 := dequeue_util (
    p_queue_name      => 'GPE_BULK_PAYMENTS',
    p_timeout_secs    => p_timeout_secs,
    p_message_present => p_message_present,
    p_payload         => l_payload1
  );

  l_aq_msg_id2 := dequeue_util (
    p_queue_name      => 'GPE_BULK_PAYMENTS',
    p_timeout_secs    => p_timeout_secs,
    p_message_present => p_message_present,
    p_payload         => l_payload2
  );


  open p_payload FOR
       select  *  from vt_bulk_payments 
       where rowid=chartorowid(l_payload1.row_id)
             OR rowid=chartorowid(l_payload2.row_id) ;


END DEQUEUE_BULK_PAYMENTS;


PROCEDURE DEQUEUE_BULK_PAYMENTS_R(
  p_timeout_secs     int default 600,
  p_message_present  out varchar2, -- Y/N 
  p_rowid          out rowid
)
IS 
  l_payload   vt_queue_payload;
  l_aq_msg_id raw(16);
begin

  l_aq_msg_id := dequeue_util (
    p_queue_name      => 'GPE_BULK_PAYMENTS',
    p_timeout_secs    => p_timeout_secs,
    p_message_present => p_message_present,
    p_payload         => l_payload
  );

  if p_message_present = 'N' then
    p_rowid :=NULL;
    return;
  end if;
  select chartorowid(l_payload.row_id)
   into p_rowid from dual;

END;




---- XE Tester
http://gbowyer.freeshell.org/oracle-aq.html
procedure testmessage 
IS
  msg SYS.AQ$_JMS_TEXT_MESSAGE;
  msg_hdr SYS.AQ$_JMS_HEADER;
  msg_agent SYS.AQ$_AGENT;
  msg_proparray SYS.AQ$_JMS_USERPROPARRAY;
  msg_property SYS.AQ$_JMS_USERPROPERTY;
  queue_options DBMS_AQ.ENQUEUE_OPTIONS_T;
  msg_props DBMS_AQ.MESSAGE_PROPERTIES_T;
  msg_id RAW(16);
  dummy VARCHAR2(4000);
  l_queue_name     varchar2(30);
begin
  msg_agent := SYS.AQ$_AGENT(' ', null, 0);
  msg_proparray := SYS.AQ$_JMS_USERPROPARRAY();
  msg_proparray.EXTEND(1);
  msg_property := SYS.AQ$_JMS_USERPROPERTY('JMS_OracleDeliveryMode', 100, '2', NULL, 27);
  msg_proparray(1) := msg_property;

  msg_hdr := SYS.AQ$_JMS_HEADER(msg_agent,null,'<USERNAME>',null,null,null,msg_proparray);
  msg := SYS.AQ$_JMS_TEXT_MESSAGE(msg_hdr,null,null,null);
  msg.text_vc := 'Aqueue Poc Heartbeat';
  msg.text_len := length(msg.text_vc);
  
  l_queue_name      := sys_context ('userenv', 'current_user')||'.'||'GPE_HEARTBEAT_QUEUE';
  DBMS_AQ.ENQUEUE( queue_name => l_queue_name
                 , enqueue_options => queue_options
                 , message_properties => msg_props
                 , payload => msg
                 , msgid => msg_id);
end testmessage;


end aq_jms_pkg;

/
show errors



