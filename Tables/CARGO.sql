--------------------------------------------------------
--  DDL for Table CARGO
--------------------------------------------------------

  CREATE TABLE "CARGO" 
   (	"CARGO_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"AREA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR) DEFAULT 'S', 
	"ORDEM" NUMBER(5,0), 
	"QTD_VAGAS_APROV" NUMBER(10,0), 
	"FLAG_ALOC_USU_CTR" CHAR(1 CHAR) DEFAULT 'S'
   ) ;
