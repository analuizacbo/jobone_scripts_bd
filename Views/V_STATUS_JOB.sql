--------------------------------------------------------
--  DDL for View V_STATUS_JOB
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_STATUS_JOB" ("CODIGO", "DESCRICAO", "ORDEM") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do dicionario: status do job
-----------------------------------------------------------------------
       codigo,
       descricao,
       ordem
  FROM dicionario
 WHERE tipo = 'status_job'

;
