--------------------------------------------------------
--  DDL for Table MLOG$_OS_NEGOCIACAO
--------------------------------------------------------

  CREATE TABLE "MLOG$_OS_NEGOCIACAO" 
   (	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"NUM_REFACAO" NUMBER(5,0), 
	"M_ROW$$" VARCHAR2(255), 
	"SEQUENCE$$" NUMBER, 
	"SNAPTIME$$" DATE, 
	"DMLTYPE$$" VARCHAR2(1), 
	"OLD_NEW$$" VARCHAR2(1), 
	"CHANGE_VECTOR$$" RAW(255), 
	"XID$$" NUMBER
   ) ;

   COMMENT ON TABLE "MLOG$_OS_NEGOCIACAO"  IS 'snapshot log for master table JOBONE_V4_174.OS_NEGOCIACAO';
