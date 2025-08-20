--------------------------------------------------------
--  DDL for Table NOTIFICA_FILA_EMAIL
--------------------------------------------------------

  CREATE TABLE "NOTIFICA_FILA_EMAIL" 
   (	"NOTIFICA_FILA_EMAIL_ID" NUMBER(20,0), 
	"NOTIFICA_FILA_ID" NUMBER(20,0), 
	"NOME_PARA" VARCHAR2(100 CHAR), 
	"EMAILS_PARA" VARCHAR2(500 CHAR), 
	"FLAG_ENVIADO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
