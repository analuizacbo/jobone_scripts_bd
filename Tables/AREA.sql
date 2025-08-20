--------------------------------------------------------
--  DDL for Table AREA
--------------------------------------------------------

  CREATE TABLE "AREA" 
   (	"AREA_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(60 CHAR), 
	"FLAG_BRIEFING" CHAR(1 CHAR) DEFAULT 'S', 
	"MODELO_BRIEFING" CLOB, 
	"FLAG_PRODUTIVA" CHAR(1 CHAR) DEFAULT 'S'
   ) ;
