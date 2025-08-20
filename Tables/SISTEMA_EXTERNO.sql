--------------------------------------------------------
--  DDL for Table SISTEMA_EXTERNO
--------------------------------------------------------

  CREATE TABLE "SISTEMA_EXTERNO" 
   (	"SISTEMA_EXTERNO_ID" NUMBER(20,0), 
	"TIPO_INTEGRACAO_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"NOME" VARCHAR2(60 CHAR), 
	"TIPO_SISTEMA" VARCHAR2(10 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
