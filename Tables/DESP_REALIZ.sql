--------------------------------------------------------
--  DDL for Table DESP_REALIZ
--------------------------------------------------------

  CREATE TABLE "DESP_REALIZ" 
   (	"DESP_REALIZ_ID" NUMBER(20,0), 
	"ADIANT_DESP_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"TIPO_PRODUTO_ID" NUMBER(20,0), 
	"COMPLEMENTO" VARCHAR2(500 CHAR), 
	"DATA_ENTRADA" DATE, 
	"DATA_DESP" DATE, 
	"VALOR_DESP" NUMBER(20,2), 
	"FORNECEDOR" VARCHAR2(100 CHAR), 
	"NUM_DOC" VARCHAR2(10 CHAR), 
	"SERIE" VARCHAR2(10 CHAR)
   ) ;
