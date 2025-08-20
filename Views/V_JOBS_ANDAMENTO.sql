--------------------------------------------------------
--  DDL for View V_JOBS_ANDAMENTO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOBS_ANDAMENTO" ("JOB_ID", "EMPRESA_ID", "USUARIO_ID", "NUMERO_JOB", "NOME_JOB", "DESCRICAO", "BUDGET", "CLIENTE_ID", "NOME_CLIENTE", "DATA_ENTRADA", "NOME_TIPO_JOB") AS 
  SELECT
-----------------------------------------------------------------------
-- view de acompanhamento de jobs em andamento enderecados ao usuario,
-----------------------------------------------------------------------
       jo.job_id,
       jo.empresa_id,
       ju.usuario_id,
       jo.numero,
       jo.nome,
       jo.descricao,
       jo.budget,
       pe.pessoa_id,
       pe.apelido,
       jo.data_entrada,
       tp.nome
  FROM job jo,
       pessoa pe,
       job_usuario ju,
       tipo_job tp
 WHERE jo.cliente_id = pe.pessoa_id
   AND jo.status =  'ANDA'
   AND jo.job_id = ju.job_id
   AND jo.tipo_job_id = tp.tipo_job_id

;
