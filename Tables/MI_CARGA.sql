--------------------------------------------------------
--  DDL for Table MI_CARGA
--------------------------------------------------------

  CREATE TABLE "MI_CARGA" 
   (	"MI_CARGA_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"NOME_USUARIO" VARCHAR2(100 CHAR), 
	"DATA_CARGA" DATE, 
	"DESCRICAO" VARCHAR2(200 CHAR), 
	"TIPO" VARCHAR2(60 CHAR), 
	"ARQUIVO" VARCHAR2(100 CHAR), 
	"ANO" NUMBER(10,0)
   ) ;
