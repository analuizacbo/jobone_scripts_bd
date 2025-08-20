--------------------------------------------------------
--  DDL for Table DICION_EMP
--------------------------------------------------------

  CREATE TABLE "DICION_EMP" 
   (	"DICION_EMP_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"GRUPO" VARCHAR2(20 CHAR), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"FLAG_ATIVO" CHAR(1 CHAR)
   ) ;
