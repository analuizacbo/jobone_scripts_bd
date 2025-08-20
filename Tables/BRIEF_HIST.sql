--------------------------------------------------------
--  DDL for Table BRIEF_HIST
--------------------------------------------------------

  CREATE TABLE "BRIEF_HIST" 
   (	"BRIEF_HIST_ID" NUMBER(20,0), 
	"BRIEFING_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA" DATE, 
	"MOTIVO" VARCHAR2(100 CHAR), 
	"COMPL_MOTIVO" VARCHAR2(1000 CHAR)
   ) ;
