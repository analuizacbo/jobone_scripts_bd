--------------------------------------------------------
--  DDL for Table OPORT_USUARIO
--------------------------------------------------------

  CREATE TABLE "OPORT_USUARIO" 
   (	"OPORTUNIDADE_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"CONTROLE" VARCHAR2(5 CHAR), 
	"FLAG_COMISSIONADO" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_RESPONSAVEL" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
