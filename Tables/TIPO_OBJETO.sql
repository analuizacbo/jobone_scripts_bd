--------------------------------------------------------
--  DDL for Table TIPO_OBJETO
--------------------------------------------------------

  CREATE TABLE "TIPO_OBJETO" 
   (	"TIPO_OBJETO_ID" NUMBER(20,0), 
	"CODIGO" VARCHAR2(40 CHAR), 
	"NOME" VARCHAR2(100 CHAR), 
	"FLAG_ENDER" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_JOB" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_OS" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_DOC" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
