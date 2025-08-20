--------------------------------------------------------
--  DDL for Table MLOG$_MV_NEGOCIACAO
--------------------------------------------------------

  CREATE TABLE "MLOG$_MV_NEGOCIACAO" 
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

   COMMENT ON TABLE "MLOG$_MV_NEGOCIACAO"  IS 'snapshot log for master table JOBONE_V4_174.MV_NEGOCIACAO';
