--------------------------------------------------------
--  DDL for Table PESQUISA
--------------------------------------------------------

  CREATE TABLE "PESQUISA" 
   (	"PESQUISA_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"ARQUIVO" VARCHAR2(100 CHAR), 
	"URL" VARCHAR2(1000 CHAR), 
	"DATA" DATE, 
	"FLAG_PUBLICO" CHAR(1 CHAR)
   ) ;
