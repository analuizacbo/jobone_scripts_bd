--------------------------------------------------------
--  DDL for Table COTACAO_PESSOA_ITEM
--------------------------------------------------------

  CREATE TABLE "COTACAO_PESSOA_ITEM" 
   (	"COTACAO_PESSOA_VERSAO_ID" NUMBER(20,0), 
	"COTACAO_ITEM_ID" NUMBER(20,0), 
	"QUANTIDADE" NUMBER(10,2), 
	"FREQUENCIA" NUMBER(10,2), 
	"UNIDADE_FREQ" VARCHAR2(20 CHAR), 
	"CUSTO_UNITARIO" NUMBER(25,5), 
	"VALOR_FORNECEDOR" NUMBER(22,2)
   ) ;
