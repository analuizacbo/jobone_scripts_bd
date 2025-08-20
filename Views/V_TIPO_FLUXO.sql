--------------------------------------------------------
--  DDL for View V_TIPO_FLUXO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_TIPO_FLUXO" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: tipo de fluxo dos documentos
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'tipo_fluxo'

;
