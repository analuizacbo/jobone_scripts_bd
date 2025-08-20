--------------------------------------------------------
--  DDL for Table ITEM_HIST
--------------------------------------------------------

  CREATE TABLE "ITEM_HIST" 
   (	"ITEM_HIST_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DATA" DATE, 
	"CODIGO" VARCHAR2(20 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"COMPLEMENTO" VARCHAR2(500 CHAR)
   ) ;
