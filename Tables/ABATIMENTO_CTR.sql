--------------------------------------------------------
--  DDL for Table ABATIMENTO_CTR
--------------------------------------------------------

  CREATE TABLE "ABATIMENTO_CTR" 
   (	"ABATIMENTO_CTR_ID" NUMBER(20,0), 
	"PARCELA_CONTRATO_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"VALOR_ABAT" NUMBER(22,2), 
	"FLAG_DEBITO_CLI" CHAR(1 CHAR), 
	"JUSTIFICATIVA" VARCHAR2(500 CHAR)
   ) ;
