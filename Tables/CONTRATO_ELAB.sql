--------------------------------------------------------
--  DDL for Table CONTRATO_ELAB
--------------------------------------------------------

  CREATE TABLE "CONTRATO_ELAB" 
   (	"CONTRATO_ELAB_ID" NUMBER(20,0), 
	"CONTRATO_ID" NUMBER(20,0), 
	"COD_CONTRATO_ELAB" VARCHAR2(20 CHAR), 
	"USUARIO_ID" NUMBER(20,0), 
	"STATUS" VARCHAR2(20 CHAR), 
	"DATA_PRAZO" DATE, 
	"DATA_EXECUCAO" DATE, 
	"MOTIVO" VARCHAR2(500 CHAR), 
	"DATA_MOTIVO" DATE
   ) ;
