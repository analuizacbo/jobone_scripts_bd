--------------------------------------------------------
--  DDL for Table UNIDADE_NEGOCIO
--------------------------------------------------------

  CREATE TABLE "UNIDADE_NEGOCIO" 
   (	"UNIDADE_NEGOCIO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"COD_EXT_UNID_NEG" VARCHAR2(20 CHAR), 
	"FLAG_QUALQUER_JOB" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
