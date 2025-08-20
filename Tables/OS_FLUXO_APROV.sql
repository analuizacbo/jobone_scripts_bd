--------------------------------------------------------
--  DDL for Table OS_FLUXO_APROV
--------------------------------------------------------

  CREATE TABLE "OS_FLUXO_APROV" 
   (	"ORDEM_SERVICO_ID" NUMBER(20,0), 
	"TIPO_APROV" VARCHAR2(5 CHAR), 
	"PAPEL_ID" NUMBER(20,0), 
	"SEQ_APROV" NUMBER(5,0), 
	"DATA_APROV" DATE, 
	"USUARIO_APROV_ID" NUMBER(20,0), 
	"FLAG_HABILITADO" CHAR(1 CHAR) DEFAULT 'S', 
	"FLAG_APROV_AUTO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
