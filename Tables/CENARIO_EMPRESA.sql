--------------------------------------------------------
--  DDL for Table CENARIO_EMPRESA
--------------------------------------------------------

  CREATE TABLE "CENARIO_EMPRESA" 
   (	"CENARIO_EMPRESA_ID" NUMBER(20,0), 
	"CENARIO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"EMP_RESP_CTR_ID" NUMBER(20,0), 
	"VALOR_BUDGET" NUMBER(22,2), 
	"DATA_INICIO_CTR" DATE, 
	"DATA_TERMINO_CTR" DATE, 
	"FLAG_RENOVAVEL" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_CTR_FISICO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
