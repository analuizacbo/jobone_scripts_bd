--------------------------------------------------------
--  DDL for Table ERRO_LOG
--------------------------------------------------------

  CREATE TABLE "ERRO_LOG" 
   (	"ERRO_LOG_ID" NUMBER(20,0), 
	"DATA" DATE, 
	"NOME_PROGRAMA" VARCHAR2(100 CHAR), 
	"COD_ERRO" VARCHAR2(20 CHAR), 
	"MSG_ERRO" VARCHAR2(255 CHAR)
   ) ;
