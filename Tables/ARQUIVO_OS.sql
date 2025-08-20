--------------------------------------------------------
--  DDL for Table ARQUIVO_OS
--------------------------------------------------------

  CREATE TABLE "ARQUIVO_OS" 
   (	"ARQUIVO_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"TIPO_ARQ_OS" VARCHAR2(20 CHAR), 
	"FLAG_THUMB" CHAR(1 CHAR) DEFAULT 'N', 
	"CHAVE_THUMB" NUMBER(20,0), 
	"NUM_REFACAO" NUMBER(5,0)
   ) ;
