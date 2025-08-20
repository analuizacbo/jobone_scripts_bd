--------------------------------------------------------
--  DDL for Table JOB_USUARIO
--------------------------------------------------------

  CREATE TABLE "JOB_USUARIO" 
   (	"JOB_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"FLAG_LIDO" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_RESPONSAVEL" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_COMISSIONADO" CHAR(1 CHAR) DEFAULT 'N', 
	"CONTROLE" VARCHAR2(5 CHAR)
   ) ;
