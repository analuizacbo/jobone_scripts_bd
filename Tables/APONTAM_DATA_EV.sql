--------------------------------------------------------
--  DDL for Table APONTAM_DATA_EV
--------------------------------------------------------

  CREATE TABLE "APONTAM_DATA_EV" 
   (	"APONTAM_DATA_EV_ID" NUMBER(20,0), 
	"APONTAM_DATA_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DATA_EVENTO" DATE, 
	"MOTIVO" VARCHAR2(500 CHAR), 
	"STATUS_DE" VARCHAR2(20 CHAR), 
	"STATUS_PARA" VARCHAR2(20 CHAR), 
	"COD_ACAO" VARCHAR2(20 CHAR), 
	"FLAG_RECENTE" CHAR(1 CHAR)
   ) ;
