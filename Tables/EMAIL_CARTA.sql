--------------------------------------------------------
--  DDL for Table EMAIL_CARTA
--------------------------------------------------------

  CREATE TABLE "EMAIL_CARTA" 
   (	"EMAIL_CARTA_ID" NUMBER(20,0), 
	"CARTA_ACORDO_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"DATA_EMAIL" DATE, 
	"ENVIAR_PARA" VARCHAR2(100 CHAR), 
	"ASSUNTO" VARCHAR2(100 CHAR), 
	"ENVIADO_POR" VARCHAR2(100 CHAR), 
	"RESPONDER_PARA" VARCHAR2(100 CHAR)
   ) ;
