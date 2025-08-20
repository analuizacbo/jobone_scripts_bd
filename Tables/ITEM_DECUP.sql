--------------------------------------------------------
--  DDL for Table ITEM_DECUP
--------------------------------------------------------

  CREATE TABLE "ITEM_DECUP" 
   (	"ITEM_DECUP_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"FORNECEDOR_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(500 CHAR), 
	"CUSTO_FORNEC" NUMBER(22,2), 
	"ORDEM_DECUP" NUMBER(5,0)
   ) ;
