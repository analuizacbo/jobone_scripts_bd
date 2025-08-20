--------------------------------------------------------
--  DDL for View V_APONTAM_ADMIN_PESQ
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_APONTAM_ADMIN_PESQ" ("APONTAM_DATA_ID", "DATA", "USUARIO_ID", "PROFISSIONAL", "PAPEL_ID", "EMPRESA_ID", "PAPEL", "HORAS", "CUSTO") AS 
  SELECT
-----------------------------------------------------------------------
-- View para pesquisa de apontamentos de horas admin (nao esta sendo
--   usada).
-----------------------------------------------------------------------
       ad.apontam_data_id,
       ad.data,
       us.usuario_id,
       pe.apelido,
       pa.papel_id,
       pa.empresa_id,
       pa.nome,
       SUM(ho.horas),
       SUM(ho.custo)
  FROM apontam_data ad,
       apontam_hora ho,
       usuario us,
       papel pa,
       pessoa pe
 WHERE ad.apontam_data_id = ho.apontam_data_id
   AND ho.job_id IS NULL
   AND ad.usuario_id = us.usuario_id
   AND ho.papel_id = pa.papel_id
   AND ho.horas > 0
   AND us.usuario_id = pe.usuario_id
 GROUP BY ad.apontam_data_id,
          ad.data,
          us.usuario_id,
          pe.apelido,
          pa.papel_id,
          pa.empresa_id,
          pa.nome

;
