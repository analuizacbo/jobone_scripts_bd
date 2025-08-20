--------------------------------------------------------
--  DDL for Table OS_TIPO_PRODUTO
--------------------------------------------------------

  CREATE TABLE "OS_TIPO_PRODUTO" 
   (	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"JOB_TIPO_PRODUTO_ID" NUMBER(20,0), 
	"DESCRICAO" CLOB, 
	"NUM_REFACAO" NUMBER(5,0) DEFAULT 0, 
	"TEMPO_EXEC_PREV" NUMBER(6,2), 
	"FATOR_TEMPO_CALC" NUMBER(10,2), 
	"FLAG_BLOQUEADO" CHAR(1 CHAR) DEFAULT 'N', 
	"DATA_ENTRADA" DATE, 
	"OBS" VARCHAR2(200 CHAR), 
	"QUANTIDADE" NUMBER(10,2) DEFAULT 1
   ) ;
