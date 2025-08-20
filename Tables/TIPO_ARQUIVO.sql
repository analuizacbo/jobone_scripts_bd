--------------------------------------------------------
--  DDL for Table TIPO_ARQUIVO
--------------------------------------------------------

  CREATE TABLE "TIPO_ARQUIVO" 
   (	"TIPO_ARQUIVO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"NOME" VARCHAR2(40 CHAR), 
	"TAM_MAX_ARQ" NUMBER(20,0), 
	"QTD_MAX_ARQ" NUMBER(5,0), 
	"EXTENSOES" VARCHAR2(100 CHAR)
   ) ;
