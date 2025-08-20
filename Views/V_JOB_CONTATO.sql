--------------------------------------------------------
--  DDL for View V_JOB_CONTATO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOB_CONTATO" ("JOB_ID", "PESSOA_ID", "APELIDO", "NOME") AS 
  SELECT
-----------------------------------------------------------------------
-- para cada job, seleciona os possiveis contados ativos do cliente
-----------------------------------------------------------------------
       jo.job_id,
       co.pessoa_id,
       co.apelido,
       co.nome
  FROM job jo,
       pessoa co,
       relacao re
 WHERE jo.cliente_id = re.pessoa_pai_id
   AND re.pessoa_filho_id = co.pessoa_id
   AND co.flag_ativo = 'S'

;
