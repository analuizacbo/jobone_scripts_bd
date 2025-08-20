--------------------------------------------------------
--  DDL for Table OS_USUARIO
--------------------------------------------------------

  CREATE TABLE "OS_USUARIO" 
   (	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"TIPO_ENDER" VARCHAR2(5 CHAR), 
	"STATUS" VARCHAR2(20 CHAR), 
	"DATA_STATUS" DATE, 
	"FLAG_LIDO" CHAR(1 CHAR) DEFAULT 'N', 
	"CONTROLE" VARCHAR2(5 CHAR), 
	"HORAS_PLANEJ" NUMBER(10,2), 
	"SEQUENCIA" NUMBER(5,0), 
	"STATUS_AUX" VARCHAR2(20 CHAR), 
	"MOTIVO_PRAZO" VARCHAR2(500 CHAR)
   ) ;
