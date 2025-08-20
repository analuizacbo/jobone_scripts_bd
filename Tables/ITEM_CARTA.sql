--------------------------------------------------------
--  DDL for Table ITEM_CARTA
--------------------------------------------------------

  CREATE TABLE "ITEM_CARTA" 
   (	"ITEM_CARTA_ID" NUMBER(20,0), 
	"CARTA_ACORDO_ID" NUMBER(20,0), 
	"ITEM_ID" NUMBER(20,0), 
	"TIPO_PRODUTO_ID" NUMBER(20,0), 
	"PRODUTO_FISCAL_ID" NUMBER(20,0), 
	"VALOR_APROVADO" NUMBER(22,2), 
	"VALOR_FORNECEDOR" NUMBER(22,2), 
	"QUANTIDADE" NUMBER(10,2), 
	"FREQUENCIA" NUMBER(10,2), 
	"CUSTO_UNITARIO" NUMBER(25,5), 
	"COMPLEMENTO" VARCHAR2(500 CHAR)
   ) ;
