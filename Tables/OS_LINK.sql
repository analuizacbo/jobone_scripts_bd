--------------------------------------------------------
--  DDL for Table OS_LINK
--------------------------------------------------------

  CREATE TABLE "OS_LINK" 
   (	"OS_LINK_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"URL" VARCHAR2(500 CHAR), 
	"DESCRICAO" VARCHAR2(200 CHAR), 
	"TIPO_LINK" VARCHAR2(20 CHAR), 
	"NUM_REFACAO" NUMBER(5,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE
   ) ;
