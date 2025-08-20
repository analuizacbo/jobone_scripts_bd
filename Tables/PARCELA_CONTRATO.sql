--------------------------------------------------------
--  DDL for Table PARCELA_CONTRATO
--------------------------------------------------------

  CREATE TABLE "PARCELA_CONTRATO" 
   (	"PARCELA_CONTRATO_ID" NUMBER(20,0), 
	"CONTRATO_ID" NUMBER(20,0), 
	"NUM_PARCELA" NUMBER(5,0), 
	"DATA_VENCIM" DATE, 
	"VALOR_PARCELA" NUMBER(22,2), 
	"CONTRATO_SERVICO_ID" NUMBER(20,0)
   ) ;
