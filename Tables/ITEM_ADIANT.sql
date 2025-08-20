--------------------------------------------------------
--  DDL for Table ITEM_ADIANT
--------------------------------------------------------

  CREATE TABLE "ITEM_ADIANT" 
   (	"ITEM_ADIANT_ID" NUMBER(20,0), 
	"ADIANT_DESP_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"VALOR_SOLICITADO" NUMBER(20,2), 
	"VALOR_DESPESA" NUMBER(20,2) DEFAULT 0, 
	"VALOR_DEVOLVIDO" NUMBER(20,2) DEFAULT 0
   ) ;
