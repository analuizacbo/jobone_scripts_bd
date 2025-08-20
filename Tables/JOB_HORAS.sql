--------------------------------------------------------
--  DDL for Table JOB_HORAS
--------------------------------------------------------

  CREATE TABLE "JOB_HORAS" 
   (	"JOB_HORAS_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"CARGO_ID" NUMBER(20,0), 
	"AREA_ID" NUMBER(20,0), 
	"NIVEL" VARCHAR2(5 CHAR), 
	"HORAS_PLANEJ" NUMBER(5,0), 
	"CUSTO_HORA_PDR" NUMBER(32,2), 
	"VENDA_HORA_PDR" NUMBER(32,2), 
	"VENDA_HORA_REV" NUMBER(32,2), 
	"VENDA_FATOR_AJUSTE" NUMBER(10,2)
   ) ;
