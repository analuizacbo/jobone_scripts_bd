--------------------------------------------------------
--  DDL for Table EMPRESA
--------------------------------------------------------

  CREATE TABLE "EMPRESA" 
   (	"EMPRESA_ID" NUMBER(20,0), 
	"SERVIDOR_ARQUIVO_ID" NUMBER(20,0), 
	"PAIS_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(60 CHAR), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"COD_EXT_EMPRESA" VARCHAR2(20 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR), 
	"LOCALIDADE" VARCHAR2(10 CHAR)
   ) ;
