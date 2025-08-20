--------------------------------------------------------
--  DDL for Table VOLUME
--------------------------------------------------------

  CREATE TABLE "VOLUME" 
   (	"VOLUME_ID" NUMBER(20,0), 
	"SERVIDOR_ARQUIVO_ID" NUMBER(20,0), 
	"PREFIXO" VARCHAR2(20 CHAR), 
	"NUMERO" NUMBER(5,0), 
	"CAMINHO" VARCHAR2(200 CHAR), 
	"STATUS" CHAR(1 CHAR)
   ) ;
