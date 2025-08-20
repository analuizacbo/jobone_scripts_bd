--------------------------------------------------------
--  DDL for Table PARCELA
--------------------------------------------------------

  CREATE TABLE "PARCELA" 
   (	"PARCELA_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"TIPO_PARCELA" VARCHAR2(10 CHAR), 
	"NUM_PARCELA" NUMBER(3,0), 
	"NUM_TOT_PARCELAS" NUMBER(3,0), 
	"DATA_NOTIF_FATUR" DATE, 
	"DATA_PARCELA" DATE, 
	"VALOR_PARCELA" NUMBER(22,2)
   ) ;
