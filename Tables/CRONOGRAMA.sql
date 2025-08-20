--------------------------------------------------------
--  DDL for Table CRONOGRAMA
--------------------------------------------------------

  CREATE TABLE "CRONOGRAMA" 
   (	"CRONOGRAMA_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"USUARIO_STATUS_ID" NUMBER(20,0), 
	"NUMERO" NUMBER(5,0), 
	"STATUS" VARCHAR2(10 CHAR), 
	"DATA_STATUS" DATE, 
	"DATA_APROV_LIMITE" DATE, 
	"DATA_CRIACAO" DATE, 
	"FLAG_COM_APROV" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
