-- Used to store pl/sql logging
 CREATE TABLE "AQ_LOG"
  (
    "LEVEL" VARCHAR2(1 CHAR) DEFAULT 'I', "MSG" CLOB, "TIME_STAMP" TIMESTAMP (6) DEFAULT systimestamp
  ) nocompress;

 