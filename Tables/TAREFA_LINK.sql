--------------------------------------------------------
--  DDL for Table TAREFA_LINK
--------------------------------------------------------

  CREATE TABLE "TAREFA_LINK" 
   (	"TAREFA_LINK_ID" NUMBER(20,0), 
	"TAREFA_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"TIPO_LINK" VARCHAR2(20 CHAR), 
	"URL" VARCHAR2(500 CHAR), 
	"DESCRICAO" VARCHAR2(200 CHAR)
   ) ;
