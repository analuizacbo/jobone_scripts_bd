--------------------------------------------------------
--  DDL for Table CONTRATO_SERVICO
--------------------------------------------------------

  CREATE TABLE "CONTRATO_SERVICO" 
   (	"CONTRATO_SERVICO_ID" NUMBER(20,0), 
	"CONTRATO_ID" NUMBER(20,0), 
	"SERVICO_ID" NUMBER(20,0), 
	"COD_EXTERNO" VARCHAR2(20 CHAR), 
	"COD_EXT_CTRSER" VARCHAR2(20 CHAR), 
	"EMP_FATURAR_POR_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(500 CHAR), 
	"DATA_INICIO" DATE, 
	"DATA_TERMINO" DATE
   ) ;
