--------------------------------------------------------
--  DDL for Table SOLICIT_ADIANT
--------------------------------------------------------

  CREATE TABLE "SOLICIT_ADIANT" 
   (	"SOLICIT_ADIANT_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"CLIENTE_ID" NUMBER(20,0), 
	"DATA_ADIANT" DATE, 
	"DATA_SOLICIT" DATE, 
	"VALOR_SOLICITADO" NUMBER(20,2), 
	"MOTIVO" VARCHAR2(500 CHAR), 
	"STATUS" VARCHAR2(10 CHAR)
   ) ;
