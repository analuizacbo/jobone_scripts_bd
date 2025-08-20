--------------------------------------------------------
--  DDL for Table CAMPANHA
--------------------------------------------------------

  CREATE TABLE "CAMPANHA" 
   (	"CAMPANHA_ID" NUMBER(20,0), 
	"CLIENTE_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"COD_EXT_CAMP" VARCHAR2(20 CHAR), 
	"DATA_INI" DATE, 
	"DATA_FIM" DATE, 
	"FLAG_ATIVO" CHAR(1 CHAR)
   ) ;
