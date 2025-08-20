--------------------------------------------------------
--  DDL for Table TAB_FERIADO
--------------------------------------------------------

  CREATE TABLE "TAB_FERIADO" 
   (	"TAB_FERIADO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(60 CHAR), 
	"FLAG_PADRAO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
