--------------------------------------------------------
--  DDL for Table USUARIO_CARGO
--------------------------------------------------------

  CREATE TABLE "USUARIO_CARGO" 
   (	"USUARIO_CARGO_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"CARGO_ID" NUMBER(20,0), 
	"DATA_INI" DATE, 
	"DATA_FIM" DATE, 
	"NIVEL" VARCHAR2(5 CHAR)
   ) ;
