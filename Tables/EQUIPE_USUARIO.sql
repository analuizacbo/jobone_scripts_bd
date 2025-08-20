--------------------------------------------------------
--  DDL for Table EQUIPE_USUARIO
--------------------------------------------------------

  CREATE TABLE "EQUIPE_USUARIO" 
   (	"EQUIPE_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"FLAG_MEMBRO" CHAR(1 CHAR) DEFAULT 'S', 
	"FLAG_RESPONSAVEL" CHAR(1 CHAR) DEFAULT 'N', 
	"FLAG_GUIDE" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
