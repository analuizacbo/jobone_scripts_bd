--------------------------------------------------------
--  DDL for Table TIPO_DADO
--------------------------------------------------------

  CREATE TABLE "TIPO_DADO" 
   (	"TIPO_DADO_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(10 CHAR), 
	"NOME" VARCHAR2(60 CHAR), 
	"TAM_MAX" NUMBER(5,0), 
	"FLAG_TEM_TAM" CHAR(1 CHAR) DEFAULT 'N', 
	"MASCARA" VARCHAR2(20 CHAR)
   ) ;
