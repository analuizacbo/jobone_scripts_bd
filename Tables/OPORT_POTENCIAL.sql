--------------------------------------------------------
--  DDL for Table OPORT_POTENCIAL
--------------------------------------------------------

  CREATE TABLE "OPORT_POTENCIAL" 
   (	"OPORTUNIDADE_ID" NUMBER(20,0), 
	"SERVICO_ID" NUMBER(20,0), 
	"VALOR" NUMBER(22,2), 
	"FLAG_SEM_VALOR" CHAR(1) DEFAULT 'N'
   ) ;
