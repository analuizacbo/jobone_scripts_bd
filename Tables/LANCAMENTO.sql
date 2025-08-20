--------------------------------------------------------
--  DDL for Table LANCAMENTO
--------------------------------------------------------

  CREATE TABLE "LANCAMENTO" 
   (	"LANCAMENTO_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"DATA_LANCAM" DATE, 
	"DESCRICAO" VARCHAR2(500 CHAR), 
	"VALOR_LANCAM" NUMBER(22,2), 
	"TIPO_MOV" CHAR(1 CHAR), 
	"OPERADOR" VARCHAR2(100 CHAR), 
	"JUSTIFICATIVA" VARCHAR2(500 CHAR)
   ) ;
