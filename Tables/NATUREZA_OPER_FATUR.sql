--------------------------------------------------------
--  DDL for Table NATUREZA_OPER_FATUR
--------------------------------------------------------

  CREATE TABLE "NATUREZA_OPER_FATUR" 
   (	"NATUREZA_OPER_FATUR_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"FLAG_BV" CHAR(1 CHAR), 
	"FLAG_PADRAO" CHAR(1 CHAR), 
	"FLAG_SERVICO" CHAR(1 CHAR) DEFAULT 'N', 
	"ORDEM" NUMBER(5,0)
   ) ;
