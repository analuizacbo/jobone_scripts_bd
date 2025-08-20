--------------------------------------------------------
--  DDL for Table ITEM_SOBRA
--------------------------------------------------------

  CREATE TABLE "ITEM_SOBRA" 
   (	"ITEM_SOBRA_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"SOBRA_ID" NUMBER(20,0), 
	"VALOR_SOBRA_ITEM" NUMBER(22,2), 
	"VALOR_CRED_ITEM" NUMBER(22,2), 
	"FLAG_ABATE_FATUR" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
