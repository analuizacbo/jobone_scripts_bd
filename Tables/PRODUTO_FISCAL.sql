--------------------------------------------------------
--  DDL for Table PRODUTO_FISCAL
--------------------------------------------------------

  CREATE TABLE "PRODUTO_FISCAL" 
   (	"PRODUTO_FISCAL_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(60 CHAR), 
	"CATEGORIA" VARCHAR2(20 CHAR), 
	"COD_EXT_PRODUTO" VARCHAR2(20 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR)
   ) ;
