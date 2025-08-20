--------------------------------------------------------
--  DDL for Table ARQUIVO_TAREFA
--------------------------------------------------------

  CREATE TABLE "ARQUIVO_TAREFA" 
   (	"ARQUIVO_ID" NUMBER(20,0), 
	"TAREFA_ID" NUMBER(20,0), 
	"TIPO_ARQ_TAREFA" VARCHAR2(20 CHAR), 
	"FLAG_THUMB" CHAR(1 CHAR) DEFAULT 'N', 
	"CHAVE_THUMB" NUMBER(20,0)
   ) ;
