--------------------------------------------------------
--  DDL for Table DICIONARIO
--------------------------------------------------------

  CREATE TABLE "DICIONARIO" 
   (	"TIPO" VARCHAR2(50 CHAR), 
	"CODIGO" VARCHAR2(50 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"OBS" VARCHAR2(4000 CHAR), 
	"FLAG_ALTERAR" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
