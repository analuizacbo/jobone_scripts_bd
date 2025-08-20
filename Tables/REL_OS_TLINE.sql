--------------------------------------------------------
--  DDL for Table REL_OS_TLINE
--------------------------------------------------------

  CREATE TABLE "REL_OS_TLINE" 
   (	"EMPRESA_ID" NUMBER(20,0), 
	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"TIPO_OS_ID" NUMBER(20,0), 
	"USUARIO_EXEC_ID" NUMBER(20,0), 
	"DATA_INTERNA" DATE, 
	"DATA_DEMANDA" DATE, 
	"HORAS_PLANEJ" NUMBER(5,0), 
	"COD_ORI_EST" VARCHAR2(3 CHAR), 
	"SEQUENCIA" NUMBER(5,0), 
	"DATA_ESTIMADA" DATE, 
	"FLAG_ESTIM_ATRASO" CHAR(1 CHAR)
   ) ;
