--------------------------------------------------------
--  DDL for View V_UNIDADE_FREQ
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_UNIDADE_FREQ" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: unidade de frequencia
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'unidade_freq'

;
