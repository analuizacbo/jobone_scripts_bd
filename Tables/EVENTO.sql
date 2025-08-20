--------------------------------------------------------
--  DDL for Table EVENTO
--------------------------------------------------------

  CREATE TABLE "EVENTO" 
   (	"EVENTO_ID" NUMBER(20,0), 
	"TIPO_OBJETO_ID" NUMBER(20,0), 
	"TIPO_ACAO_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"MODULO" VARCHAR2(40 CHAR), 
	"CLASSE" VARCHAR2(10 CHAR) DEFAULT 'INFO', 
	"FLAG_TEM_MOTIVO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
