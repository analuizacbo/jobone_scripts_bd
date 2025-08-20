--------------------------------------------------------
--  DDL for Table GRUPO
--------------------------------------------------------

  CREATE TABLE "GRUPO" 
   (	"GRUPO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"FLAG_AGRUPA_CNPJ" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
