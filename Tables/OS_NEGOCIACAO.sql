--------------------------------------------------------
--  DDL for Table OS_NEGOCIACAO
--------------------------------------------------------

  CREATE TABLE "OS_NEGOCIACAO" 
   (	"OS_NEGOCIACAO_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"ATUACAO_USUARIO" VARCHAR2(10 CHAR), 
	"NUM_REFACAO" NUMBER(5,0), 
	"DATA_EVENTO" DATE, 
	"COD_ACAO" VARCHAR2(20 CHAR), 
	"DESC_ACAO" VARCHAR2(100 CHAR), 
	"DATA_SUGERIDA" DATE, 
	"COMENTARIO" VARCHAR2(2000 CHAR)
   ) ;
