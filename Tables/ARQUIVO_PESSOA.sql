--------------------------------------------------------
--  DDL for Table ARQUIVO_PESSOA
--------------------------------------------------------

  CREATE TABLE "ARQUIVO_PESSOA" 
   (	"ARQUIVO_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"TIPO_ARQ_PESSOA" VARCHAR2(20 CHAR), 
	"FLAG_THUMB" CHAR(1 CHAR) DEFAULT 'N', 
	"CHAVE_THUMB" NUMBER(20,0), 
	"TIPO_THUMB" VARCHAR2(5 CHAR), 
	"DATA_HORA" DATE
   ) ;
