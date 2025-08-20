--------------------------------------------------------
--  DDL for Table ABATIMENTO
--------------------------------------------------------

  CREATE TABLE "ABATIMENTO" 
   (	"ABATIMENTO_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"CARTA_ACORDO_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"SOBRA_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"VALOR_ABAT" NUMBER(22,2), 
	"FLAG_DEBITO_CLI" CHAR(1 CHAR), 
	"JUSTIFICATIVA" VARCHAR2(500 CHAR)
   ) ;
