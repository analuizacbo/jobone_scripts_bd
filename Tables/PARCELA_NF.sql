--------------------------------------------------------
--  DDL for Table PARCELA_NF
--------------------------------------------------------

  CREATE TABLE "PARCELA_NF" 
   (	"PARCELA_NF_ID" NUMBER(20,0), 
	"NOTA_FISCAL_ID" NUMBER(20,0), 
	"NUM_PARCELA" NUMBER(3,0), 
	"NUM_TOT_PARCELAS" NUMBER(3,0), 
	"DATA_PARCELA" DATE, 
	"TIPO_NUM_DIAS" CHAR(1 CHAR), 
	"NUM_DIAS" NUMBER(5,0), 
	"VALOR_PARCELA" NUMBER(22,2)
   ) ;
