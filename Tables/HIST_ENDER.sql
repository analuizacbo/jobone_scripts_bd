--------------------------------------------------------
--  DDL for Table HIST_ENDER
--------------------------------------------------------

  CREATE TABLE "HIST_ENDER" 
   (	"HIST_ENDER_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"TIPO_OBJETO" VARCHAR2(5 CHAR), 
	"OBJETO_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE, 
	"FLAG_MOSTRAR" CHAR(1 CHAR) DEFAULT 'S', 
	"ATUACAO" VARCHAR2(5 CHAR)
   ) ;
