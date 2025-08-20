--------------------------------------------------------
--  DDL for Table PRODUTO_CLIENTE
--------------------------------------------------------

  CREATE TABLE "PRODUTO_CLIENTE" 
   (	"PRODUTO_CLIENTE_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"COD_EXT_PRODUTO" VARCHAR2(20 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR) DEFAULT 'S'
   ) ;
