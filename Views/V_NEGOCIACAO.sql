--------------------------------------------------------
--  DDL for View V_NEGOCIACAO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_NEGOCIACAO" ("ORDEM_SERVICO_ID", "NUM_REFACAO", "QTDE") AS 
  SELECT ORDEM_SERVICO_ID,
       NUM_REFACAO,
       QTDE
  FROM MV_NEGOCIACAO

;
