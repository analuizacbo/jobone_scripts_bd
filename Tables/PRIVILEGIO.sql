--------------------------------------------------------
--  DDL for Table PRIVILEGIO
--------------------------------------------------------

  CREATE TABLE "PRIVILEGIO" 
   (	"PRIVILEGIO_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(30 CHAR), 
	"NOME" VARCHAR2(100 CHAR), 
	"DESCRICAO" VARCHAR2(255 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"GRUPO" VARCHAR2(20 CHAR), 
	"MODULO" VARCHAR2(40 CHAR)
   ) ;
