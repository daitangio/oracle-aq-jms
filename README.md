oracle-aq-jms
=============

Oracle Advanced Queuing as JMS replacement using spring and gradle

The project is composed of two major module:

+ a java demo project which use jms advanced queue via spring
+ a oracle package called aq_jms_pkg used to create the jms queue.
  The package file (including body declaration and test queues) are stored inside
  src/main/sql


Speed Start
===============

1. Create an oracle  user called "gundam" like the scott/tiger user (or hr user on Oracle XE)
2. Run in the lexicografical order the script under src/main/sql
3. Compile with gradle and run the unit tests

## Core Team Members

* [Giovanni Giorgi](https://github/daitangio)




Oracle Express support (XE)
============================
Oracle Express lack the ability to create PL/SQL "objects" needed by AQ.
In particular trying to execute in PL/SQL something like

  msg := SYS.AQ$_JMS_TEXT_MESSAGE.CONSTRUCT();

results in a "PLS-00302: component ‘CONSTRUCT’ must be declared".
The reason is unclear, but the net effect is JMS types on the XE database are "crippled’.

Anyway we found this [article explaining how to overcome this limitation][oracle-xe-fix].
See also this [thread on Oracle web site][oracle-xe-fix-discussion].
Inside the file 

       src/main/sql/201_aq_gpe_queue_pkg.sql

you can find the testmessage procedure which is able to send a AQ message under Oracle Express.

AQ support under OracleExpress is a bumpy way so plese test every single piece of code if you need it.



References
==============
http://gbowyer.freeshell.org/oracle-aq.html
http://technology.amis.nl/GPE_HEARTBEAT7/08/30/enqueuing-aq-jms-text-message-from-plsql-on-oracle-xe/


[oracle-xe-fix] http://technology.amis.nl/2007/08/30/enqueuing-aq-jms-text-message-from-plsql-on-oracle-xe/
[oracle-xe-fix-discussion] https://community.oracle.com/thread/2588733
