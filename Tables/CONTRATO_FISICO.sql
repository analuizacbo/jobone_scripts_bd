--------------------------------------------------------
--  DDL for Table CONTRATO_FISICO
--------------------------------------------------------

  CREATE TABLE "CONTRATO_FISICO" 
   (	"CONTRATO_FISICO_ID" NUMBER(20,0), 
	"CONTRATO_ID" NUMBER(20,0), 
	"USUARIO_ELAB_ID" NUMBER(20,0), 
	"USUARIO_MOTIVO_ID" NUMBER(20,0), 
	"VERSAO" NUMBER(5,0), 
	"STATUS" VARCHAR2(20 CHAR), 
	"DESCRICAO" VARCHAR2(500 CHAR), 
	"DATA_PRAZO" DATE, 
	"DATA_ELAB" DATE, 
	"MOTIVO" VARCHAR2(500 CHAR), 
	"DATA_MOTIVO" DATE
   ) ;
