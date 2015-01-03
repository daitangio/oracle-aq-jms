--------------------------------------------------------
--  File created - Sunday-January-04-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table DATA_DRIVEN_TEST
--------------------------------------------------------

  CREATE TABLE "GUNDAM"."DATA_DRIVEN_TEST" 
   (	"ID" NUMBER(18,0), 
	"MSG" VARCHAR2(2048 BYTE) DEFAULT 'Just here at ' || systimestamp
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;

   COMMENT ON COLUMN "GUNDAM"."DATA_DRIVEN_TEST"."ID" IS 'PK';
   COMMENT ON TABLE "GUNDAM"."DATA_DRIVEN_TEST"  IS 'For data driven trigger';
--------------------------------------------------------
--  DDL for Index DATA_DRIVEN_TEST_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "GUNDAM"."DATA_DRIVEN_TEST_PK" ON "GUNDAM"."DATA_DRIVEN_TEST" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;
--------------------------------------------------------
--  Constraints for Table DATA_DRIVEN_TEST
--------------------------------------------------------

  ALTER TABLE "GUNDAM"."DATA_DRIVEN_TEST" ADD CONSTRAINT "DATA_DRIVEN_TEST_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS"  ENABLE;
  ALTER TABLE "GUNDAM"."DATA_DRIVEN_TEST" MODIFY ("MSG" NOT NULL ENABLE);
  ALTER TABLE "GUNDAM"."DATA_DRIVEN_TEST" MODIFY ("ID" NOT NULL ENABLE);
--------------------------------------------------------
--  DDL for Trigger DATA_DRIVEN_HEARBEAT
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "GUNDAM"."DATA_DRIVEN_HEARBEAT" 
AFTER INSERT OR DELETE ON DATA_DRIVEN_TEST 
FOR EACH ROW
BEGIN
 if inserting then
    aq_jms_pkg.send_heartbeat('Added   line on data_driven_test MSG=' || :NEW.MSG || ' by ' || User);
  elsif deleting then
    aq_jms_pkg.send_heartbeat('Deleted line on data_driven_test MSG=' || :OLD.MSG || ' by ' || User);
  end if;
END;
/
ALTER TRIGGER "GUNDAM"."DATA_DRIVEN_HEARBEAT" ENABLE;
