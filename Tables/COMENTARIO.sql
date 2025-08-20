--------------------------------------------------------
--  DDL for Table COMENTARIO
--------------------------------------------------------

  CREATE TABLE "COMENTARIO" 
   (	"COMENTARIO_ID" NUMBER(20,0), 
	"TIPO_OBJETO_ID" NUMBER(20,0), 
	"OBJETO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"COMENTARIO_PAI_ID" NUMBER(20,0), 
	"CLASSE" VARCHAR2(20 CHAR), 
	"DATA_COMENT" DATE, 
	"COMENTARIO" CLOB
   ) ;
