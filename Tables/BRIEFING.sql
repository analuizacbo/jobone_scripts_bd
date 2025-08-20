--------------------------------------------------------
--  DDL for Table BRIEFING
--------------------------------------------------------

  CREATE TABLE "BRIEFING" 
   (	"BRIEFING_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"NUMERO" NUMBER(5,0), 
	"REQUISICAO_CLIENTE" CLOB, 
	"DATA_REQUISICAO" DATE, 
	"REVISOES" CLOB, 
	"STATUS" VARCHAR2(10 CHAR), 
	"DATA_STATUS" DATE, 
	"DATA_APROV_LIMITE" DATE, 
	"FLAG_COM_APROV" CHAR(1 CHAR) DEFAULT 'N', 
	"NOTA_AVAL" NUMBER(5,0)
   ) ;
