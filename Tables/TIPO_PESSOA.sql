--------------------------------------------------------
--  DDL for Table TIPO_PESSOA
--------------------------------------------------------

  CREATE TABLE "TIPO_PESSOA" 
   (	"TIPO_PESSOA_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"NOME" VARCHAR2(60 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"FLAG_DOCUM" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_TRATA_CONTATO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
