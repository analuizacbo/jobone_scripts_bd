--------------------------------------------------------
--  DDL for Table LINK_DIRETO
--------------------------------------------------------

  CREATE TABLE "LINK_DIRETO" 
   (	"LINK_DIRETO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_GERACAO" DATE, 
	"DATA_VALIDADE" DATE, 
	"INTERFACE" VARCHAR2(100 CHAR), 
	"LINK" VARCHAR2(1000 CHAR), 
	"COD_HASH" VARCHAR2(100 CHAR), 
	"CLIENTE_ID" VARCHAR2(1000 CHAR), 
	"TIPO_LINK" VARCHAR2(10 CHAR), 
	"EMPRESA_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0)
   ) ;
