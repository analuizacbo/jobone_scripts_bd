--------------------------------------------------------
--  DDL for Table REGRA_COENDER
--------------------------------------------------------

  CREATE TABLE "REGRA_COENDER" 
   (	"REGRA_COENDER_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"GRUPO_ID" NUMBER(20,0), 
	"CLIENTE_ID" NUMBER(20,0), 
	"PRODUTO_CLIENTE_ID" NUMBER(20,0), 
	"TIPO_JOB_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR) DEFAULT 'S', 
	"COMENTARIO" VARCHAR2(200 CHAR)
   ) ;
