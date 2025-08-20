--------------------------------------------------------
--  DDL for View V_ESTADO_CIVIL
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_ESTADO_CIVIL" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: estado civil
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'estado_civil'

;
