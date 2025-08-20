--------------------------------------------------------
--  DDL for Table OBJETO_CRONO
--------------------------------------------------------

  CREATE TABLE "OBJETO_CRONO" 
   (	"COD_OBJETO" VARCHAR2(20 CHAR), 
	"NOME" VARCHAR2(60 CHAR), 
	"FLAG_UNICO" CHAR(1 CHAR), 
	"FLAG_OBRIGATORIO" CHAR(1 CHAR), 
	"FLAG_REPETICAO" CHAR(1 CHAR) DEFAULT 'N', 
	"ORDEM" NUMBER(5,0), 
	"FASE_NOME" VARCHAR2(60 CHAR), 
	"FASE_ORDEM" NUMBER(5,0)
   ) ;
