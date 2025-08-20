--------------------------------------------------------
--  DDL for Table SERVICO
--------------------------------------------------------

  CREATE TABLE "SERVICO" 
   (	"SERVICO_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"CODIGO" VARCHAR2(20 CHAR), 
	"FLAG_ATIVO" CHAR(1 CHAR), 
	"MARGEM_OPER_MIN" NUMBER(7,3), 
	"MARGEM_OPER_META" NUMBER(7,3), 
	"GRUPO_SERVICO_ID" NUMBER(20,0), 
	"FLAG_TEM_COMISSAO" CHAR(1 CHAR) DEFAULT 'S'
   ) ;
