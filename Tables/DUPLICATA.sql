--------------------------------------------------------
--  DDL for Table DUPLICATA
--------------------------------------------------------

  CREATE TABLE "DUPLICATA" 
   (	"DUPLICATA_ID" NUMBER(20,0), 
	"NOTA_FISCAL_ID" NUMBER(20,0), 
	"DATA_VENCIM" DATE, 
	"VALOR_DUPLICATA" NUMBER(22,2), 
	"NUM_PARCELA" NUMBER(3,0), 
	"NUM_TOT_PARCELAS" NUMBER(3,0), 
	"NUM_DUPLICATA" VARCHAR2(10 CHAR)
   ) ;
