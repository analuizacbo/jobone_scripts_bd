--------------------------------------------------------
--  DDL for Table CONTRATO_SERV_VALOR
--------------------------------------------------------

  CREATE TABLE "CONTRATO_SERV_VALOR" 
   (	"CONTRATO_SERV_VALOR_ID" NUMBER(20,0), 
	"CONTRATO_SERVICO_ID" NUMBER(20,0), 
	"EMP_RESP_ID" NUMBER(20,0), 
	"USUARIO_ID" NUMBER(20,0), 
	"DATA_REFER" DATE, 
	"VALOR_SERVICO" NUMBER(22,2), 
	"FLAG_OPORT" CHAR(1 CHAR), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"UNID_NEGOCIO_RESP_ID" NUMBER(20,0)
   ) ;
