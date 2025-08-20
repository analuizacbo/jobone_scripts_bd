--------------------------------------------------------
--  DDL for Table FI_TIPO_IMPOSTO_FAIXA
--------------------------------------------------------

  CREATE TABLE "FI_TIPO_IMPOSTO_FAIXA" 
   (	"FI_TIPO_IMPOSTO_FAIXA_ID" NUMBER(20,0), 
	"FI_TIPO_IMPOSTO_ID" NUMBER(20,0), 
	"DATA_VIGENCIA_INI" DATE, 
	"DATA_VIGENCIA_FIM" DATE, 
	"VALOR_BASE_INI" NUMBER(22,2), 
	"VALOR_BASE_FIM" NUMBER(22,2), 
	"PERC_IMPOSTO" NUMBER(5,2), 
	"VALOR_DEDUCAO" NUMBER(22,2)
   ) ;
