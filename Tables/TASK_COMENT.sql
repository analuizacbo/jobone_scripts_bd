--------------------------------------------------------
--  DDL for Table TASK_COMENT
--------------------------------------------------------

  CREATE TABLE "TASK_COMENT" 
   (	"TASK_COMENT_ID" NUMBER(20,0), 
	"TASK_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA" DATE, 
	"COMENTARIO" VARCHAR2(4000 CHAR)
   ) ;
