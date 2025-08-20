--------------------------------------------------------
--  DDL for Table TAREFA_AFAZER
--------------------------------------------------------

  CREATE TABLE "TAREFA_AFAZER" 
   (	"TAREFA_AFAZER_ID" NUMBER(20,0), 
	"TAREFA_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(200 CHAR), 
	"DATA" DATE, 
	"FLAG_FEITO" CHAR(1 CHAR), 
	"ORDEM" NUMBER(10,0)
   ) ;
