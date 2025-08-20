--------------------------------------------------------
--  DDL for Table TAREFA_USUARIO
--------------------------------------------------------

  CREATE TABLE "TAREFA_USUARIO" 
   (	"TAREFA_ID" NUMBER(20,0), 
	"USUARIO_PARA_ID" NUMBER(20,0), 
	"CONTROLE" VARCHAR2(5 CHAR), 
	"STATUS" VARCHAR2(20 CHAR), 
	"DATA_STATUS" DATE, 
	"HORAS_TOTAIS" NUMBER(10,2)
   ) ;
