--------------------------------------------------------
--  DDL for Table MILESTONE
--------------------------------------------------------

  CREATE TABLE "MILESTONE" 
   (	"MILESTONE_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"JOB_ID" NUMBER(20,0), 
	"PAPEL_RESP_ID" NUMBER(20,0), 
	"USUARIO_AUTOR_ID" NUMBER(20,0), 
	"DATA_MILESTONE" DATE, 
	"HORA_INI" VARCHAR2(5 CHAR), 
	"HORA_FIM" VARCHAR2(5 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"DATA_CRIACAO" DATE, 
	"FLAG_FECHADO" CHAR(1 CHAR)
   ) ;
