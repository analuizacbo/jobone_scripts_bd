--------------------------------------------------------
--  DDL for Table EVENTO_MOTIVO
--------------------------------------------------------

  CREATE TABLE "EVENTO_MOTIVO" 
   (	"EVENTO_MOTIVO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"EVENTO_ID" NUMBER(20,0), 
	"TIPO_OS_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"TIPO_CLIENTE_AGENCIA" VARCHAR2(3 CHAR)
   ) ;
