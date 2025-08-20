--------------------------------------------------------
--  DDL for Table ORCAM_FLUXO_APROV
--------------------------------------------------------

  CREATE TABLE "ORCAM_FLUXO_APROV" 
   (	"ORCAMENTO_ID" NUMBER(20,0), 
	"PAPEL_ID" NUMBER(20,0), 
	"SEQ_APROV" NUMBER(5,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"STATUS" VARCHAR2(20 CHAR), 
	"DATA_STATUS" DATE, 
	"MOTIVO" VARCHAR2(100 CHAR), 
	"COMPLEMENTO" VARCHAR2(1000 CHAR)
   ) ;
