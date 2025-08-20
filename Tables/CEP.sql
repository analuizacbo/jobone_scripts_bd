--------------------------------------------------------
--  DDL for Table CEP
--------------------------------------------------------

  CREATE TABLE "CEP" 
   (	"CEP_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(9 CHAR), 
	"LOGRADOURO" VARCHAR2(100 CHAR), 
	"BAIRRO" VARCHAR2(80 CHAR), 
	"LOCALIDADE" VARCHAR2(80 CHAR), 
	"UF" CHAR(2 CHAR), 
	"TIPO" CHAR(3 CHAR), 
	"NUM_INICIO" VARCHAR2(15 CHAR), 
	"NUM_FIM" VARCHAR2(15 CHAR), 
	"PARIDADE" VARCHAR2(1 CHAR)
   ) ;
