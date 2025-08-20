--------------------------------------------------------
--  DDL for Table XML_LOG
--------------------------------------------------------

  CREATE TABLE "XML_LOG" 
   (	"XML_LOG_ID" NUMBER(20,0), 
	"DATA" DATE, 
	"TEXTO_XML" CLOB, 
	"SISTEMA_ORIGEM" VARCHAR2(40 CHAR), 
	"SISTEMA_DESTINO" VARCHAR2(40 CHAR), 
	"COD_OBJETO" VARCHAR2(40 CHAR), 
	"COD_ACAO" VARCHAR2(40 CHAR), 
	"RETORNO_XML" CLOB, 
	"OBJETO_ID" NUMBER(20,0)
   ) ;
