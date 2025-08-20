--------------------------------------------------------
--  DDL for Table OPORT_SERVICO
--------------------------------------------------------

  CREATE TABLE "OPORT_SERVICO" 
   (	"OPORT_SERVICO_ID" NUMBER(20,0), 
	"OPORTUNIDADE_ID" NUMBER(20,0), 
	"EMPRESA_ID" NUMBER(20,0), 
	"SERVICO_ID" NUMBER(20,0), 
	"VALOR_SERVICO" NUMBER(22,2), 
	"EMP_RESP_ID" NUMBER(20,0), 
	"USUARIO_RESP_ID" NUMBER(20,0), 
	"UNID_NEGOCIO_RESP_ID" NUMBER(20,0), 
	"DESCRICAO" VARCHAR2(100)
   ) ;
