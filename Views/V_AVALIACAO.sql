--------------------------------------------------------
--  DDL for View V_AVALIACAO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_AVALIACAO" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: avaliacao
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'avaliacao'

;
