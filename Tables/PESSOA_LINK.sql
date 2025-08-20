--------------------------------------------------------
--  DDL for Table PESSOA_LINK
--------------------------------------------------------

  CREATE TABLE "PESSOA_LINK" 
   (	"PESSOA_LINK_ID" NUMBER(20,0), 
	"PESSOA_ID" NUMBER(20,0), 
	"URL" VARCHAR2(500 CHAR), 
	"DESCRICAO" VARCHAR2(1000 CHAR), 
	"TIPO_LINK" VARCHAR2(50 CHAR), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_ENTRADA" DATE DEFAULT SYSDATE
   ) ;
