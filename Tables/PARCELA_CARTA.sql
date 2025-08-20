--------------------------------------------------------
--  DDL for Table PARCELA_CARTA
--------------------------------------------------------

  CREATE TABLE "PARCELA_CARTA" 
   (	"PARCELA_CARTA_ID" NUMBER(20,0), 
	"CARTA_ACORDO_ID" NUMBER(20,0), 
	"NUM_PARCELA" NUMBER(3,0), 
	"NUM_TOT_PARCELAS" NUMBER(3,0), 
	"DATA_PARCELA" DATE, 
	"TIPO_NUM_DIAS" CHAR(1 CHAR) DEFAULT 'C', 
	"NUM_DIAS" NUMBER(5,0), 
	"VALOR_PARCELA" NUMBER(22,2)
   ) ;
