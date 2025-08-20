--------------------------------------------------------
--  DDL for Table FAIXA_APROV
--------------------------------------------------------

  CREATE TABLE "FAIXA_APROV" 
   (	"FAIXA_APROV_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"TIPO_FAIXA" VARCHAR2(20 CHAR), 
	"FLAG_SEQUENCIAL" CHAR(1 CHAR) DEFAULT 'S', 
	"FLAG_ATIVO" CHAR(1 CHAR) DEFAULT 'S', 
	"COMENTARIO" VARCHAR2(200 CHAR)
   ) ;
