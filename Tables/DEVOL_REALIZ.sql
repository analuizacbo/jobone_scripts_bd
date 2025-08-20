--------------------------------------------------------
--  DDL for Table DEVOL_REALIZ
--------------------------------------------------------

  CREATE TABLE "DEVOL_REALIZ" 
   (	"DEVOL_REALIZ_ID" NUMBER(20,2), 
	"ADIANT_DESP_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"DATA_DEVOL" DATE, 
	"FORMA_DEVOL" VARCHAR2(10 CHAR), 
	"VALOR_DEVOL" NUMBER(20,2), 
	"COMPLEMENTO" VARCHAR2(200 CHAR)
   ) ;
