--------------------------------------------------------
--  DDL for Table SOBRA
--------------------------------------------------------

  CREATE TABLE "SOBRA" 
   (	"SOBRA_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"CARTA_ACORDO_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"TIPO_SOBRA" VARCHAR2(10 CHAR), 
	"JUSTIFICATIVA" VARCHAR2(500 CHAR), 
	"VALOR_SOBRA" NUMBER(22,2), 
	"VALOR_CRED_CLIENTE" NUMBER(22,2), 
	"FLAG_DENTRO_CA" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
