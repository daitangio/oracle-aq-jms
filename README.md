oracle-aq-jms
=============

Oracle Advanced Queuing as JMS replacement using spring and gradle

The project is composed of two major module:

+ utility jar
+ a oracle package called aq_jms_pkg used to create the jms queue.
  The package file (including body declaration and test queues) are stored inside
  src/main/sql

Speed Start
===============

1. Create an oracle  user called "gundam" like the scott/tiger user (or hr user on Oracle XE)
2. Run in the lexicografical order the script under src/main/sql
3. Compile with gradle and run the unit tests





Oralce expert support (XE)
============================

References
==============
http://gbowyer.freeshell.org/oracle-aq.html
http://technology.amis.nl/GPE_HEARTBEAT7/08/30/enqueuing-aq-jms-text-message-from-plsql-on-oracle-xe/
