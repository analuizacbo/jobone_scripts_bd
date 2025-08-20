--------------------------------------------------------
--  DDL for Table OS_USUARIO_REFACAO
--------------------------------------------------------

  CREATE TABLE "OS_USUARIO_REFACAO" 
   (	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"TIPO_ENDER" VARCHAR2(5 CHAR), 
	"NUM_REFACAO" NUMBER(5,0), 
	"NOTA_AVAL" NUMBER(5,0), 
	"DATA_AVAL" DATE, 
	"HORAS_PLANEJ" NUMBER(20,2), 
	"DATA_TERMINO" DATE, 
	"COMENTARIO" VARCHAR2(4000 CHAR), 
	"MOTIVO_PRAZO" VARCHAR2(500 CHAR), 
	"STATUS_AUX" VARCHAR2(20 CHAR)
   ) ;
