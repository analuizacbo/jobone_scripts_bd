--------------------------------------------------------
--  DDL for Table OS_AFAZER
--------------------------------------------------------

  CREATE TABLE "OS_AFAZER" 
   (	"OS_AFAZER_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(200 CHAR), 
	"DATA" DATE, 
	"FLAG_FEITO" CHAR(1 CHAR), 
	"ORDEM" NUMBER(10,0)
   ) ;
