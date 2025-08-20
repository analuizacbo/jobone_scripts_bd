--------------------------------------------------------
--  DDL for Table APONTAM_PROGR
--------------------------------------------------------

  CREATE TABLE "APONTAM_PROGR" 
   (	"APONTAM_PROGR_ID" NUMBER(20,0), 
	"TIPO_APONTAM_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_INI" DATE, 
	"DATA_FIM" DATE, 
	"OBS" VARCHAR2(100 CHAR), 
	"FLAG_OS_APROV_AUTO" CHAR(1 CHAR) DEFAULT 'N'
   ) ;
