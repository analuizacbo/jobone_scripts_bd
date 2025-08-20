--------------------------------------------------------
--  DDL for Table FAIXA_APROV_AO
--------------------------------------------------------

  CREATE TABLE "FAIXA_APROV_AO" 
   (	"FAIXA_APROV_ID" NUMBER(20,0), 
	"CLIENTE_ID" NUMBER(20,0), 
	"VALOR_DE" NUMBER(22,2), 
	"VALOR_ATE" NUMBER(22,2), 
	"FLAG_ITENS_A" CHAR(1 CHAR) DEFAULT 'S', 
	"FLAG_ITENS_BC" CHAR(1 CHAR) DEFAULT 'S', 
	"FORNEC_HOMOLOG" CHAR(1 CHAR), 
	"FORNEC_INTERNO" CHAR(1 CHAR), 
	"RESULTADO_DE" NUMBER(5,2), 
	"RESULTADO_ATE" NUMBER(5,2)
   ) ;
