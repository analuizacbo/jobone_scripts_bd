--------------------------------------------------------
--  DDL for Table EQUIPE
--------------------------------------------------------

  CREATE TABLE "EQUIPE" 
   (	"EQUIPE_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"NOME" VARCHAR2(100 CHAR), 
	"FLAG_EM_DIST_OS" CHAR(1 CHAR) DEFAULT 'N', 
	"TIPO_TAREFA_ID" NUMBER(20,0)
   ) ;
