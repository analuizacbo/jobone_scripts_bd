--------------------------------------------------------
--  DDL for Table TAREFA_EVENTO
--------------------------------------------------------

  CREATE TABLE "TAREFA_EVENTO" 
   (	"TAREFA_EVENTO_ID" NUMBER(20,0), 
	"TAREFA_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_EVENTO" DATE, 
	"COD_ACAO" VARCHAR2(20 CHAR), 
	"STATUS_DE" VARCHAR2(10 CHAR), 
	"STATUS_PARA" VARCHAR2(10 CHAR), 
	"COMENTARIO" VARCHAR2(1000 CHAR), 
	"MOTIVO" VARCHAR2(100 CHAR)
   ) ;
