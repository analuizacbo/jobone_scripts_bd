--------------------------------------------------------
--  DDL for View V_APONTAM_JOB_PESQ
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_APONTAM_JOB_PESQ" ("APONTAM_DATA_ID", "DATA", "USUARIO_ID", "PROFISSIONAL", "PAPEL_ID", "PAPEL", "JOB_ID", "EMPRESA_ID", "CONTRATO_ID", "NUMERO_JOB", "NOME_JOB", "CLIENTE_ID", "CLIENTE", "HORAS", "CUSTO") AS 
  SELECT
-----------------------------------------------------------------------
-- View para pesquisa de apontamentos de jobs
-----------------------------------------------------------------------
       ad.apontam_data_id,
       ad.data,
       us.usuario_id,
       pu.apelido,
       pa.papel_id,
       pa.nome,
       jo.job_id,
       jo.empresa_id,
       jo.contrato_id,
       jo.numero,
       jo.nome,
       jo.cliente_id,
       pc.apelido,
       SUM(ho.horas),
       SUM(ho.custo)
  FROM apontam_data ad,
       apontam_hora ho,
       job jo,
       usuario us,
       papel pa,
       pessoa pc,
       pessoa pu
 WHERE ad.apontam_data_id = ho.apontam_data_id
   AND ad.usuario_id = us.usuario_id
   AND ho.job_id = jo.job_id
   AND ho.papel_id = pa.papel_id
   AND jo.cliente_id = pc.pessoa_id
   AND us.usuario_id = pu.usuario_id
 GROUP BY ad.apontam_data_id,
          ad.data,
          us.usuario_id,
          pu.apelido,
          pa.papel_id,
          pa.nome,
          jo.job_id,
          jo.contrato_id,
          jo.empresa_id,
          jo.numero,
          jo.nome,
          jo.cliente_id,
          pc.apelido

;
