--------------------------------------------------------
--  DDL for Table STATUS_AUX_JOB
--------------------------------------------------------

  CREATE TABLE "STATUS_AUX_JOB" 
   (	"STATUS_AUX_JOB_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"COD_STATUS_PAI" VARCHAR2(10 CHAR), 
	"NOME" VARCHAR2(40 CHAR), 
	"ORDEM" NUMBER(5,0), 
	"FLAG_PADRAO" CHAR(1 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR)
   ) ;
