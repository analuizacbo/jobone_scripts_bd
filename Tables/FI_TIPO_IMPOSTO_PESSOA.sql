--------------------------------------------------------
--  DDL for Table FI_TIPO_IMPOSTO_PESSOA
--------------------------------------------------------

  CREATE TABLE "FI_TIPO_IMPOSTO_PESSOA" 
   (	"FI_TIPO_IMPOSTO_PESSOA_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"FI_TIPO_IMPOSTO_ID" NUMBER(20,0), 
	"NOME_SERVICO" VARCHAR2(40 CHAR), 
	"PERC_IMPOSTO" NUMBER(5,2), 
	"FLAG_RETER" CHAR(1 CHAR)
   ) ;
