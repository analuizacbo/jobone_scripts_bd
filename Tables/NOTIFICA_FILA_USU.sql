--------------------------------------------------------
--  DDL for Table NOTIFICA_FILA_USU
--------------------------------------------------------

  CREATE TABLE "NOTIFICA_FILA_USU" 
   (	"NOTIFICA_FILA_USU_ID" NUMBER(20,0), 
	"NOTIFICA_FILA_ID" NUMBER(20,0), 
	"NOME_PARA" VARCHAR2(100 CHAR), 
	"USUARIO_PARA_ID" NUMBER(20,0), 
	"FLAG_LIDO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
