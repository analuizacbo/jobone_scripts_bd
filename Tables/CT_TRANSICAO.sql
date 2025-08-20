--------------------------------------------------------
--  DDL for Table CT_TRANSICAO
--------------------------------------------------------

  CREATE TABLE "CT_TRANSICAO" 
   (	"CT_TRANSICAO_ID" NUMBER(20,0), 
	"COD_OBJETO" VARCHAR2(20 CHAR), 
	"STATUS_DE" VARCHAR2(20 CHAR), 
	"COD_ACAO" VARCHAR2(20 CHAR), 
	"STATUS_PARA" VARCHAR2(20 CHAR), 
	"FLAG_NOVA_VERSAO" CHAR(1 CHAR), 
	"NAVEGACAO" VARCHAR2(20 CHAR), 
	"DESCRICAO" VARCHAR2(100 CHAR), 
	"TEXTO_BOTAO" VARCHAR2(60 CHAR)
   ) ;
