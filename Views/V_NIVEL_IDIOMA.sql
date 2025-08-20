--------------------------------------------------------
--  DDL for View V_NIVEL_IDIOMA
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_NIVEL_IDIOMA" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: nivel do idioma
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'nivel_idioma'

;
