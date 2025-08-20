--------------------------------------------------------
--  DDL for View V_OS_EQUIPE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_OS_EQUIPE" ("EQUIPE_ID", "EQUIPE", "ORDEM_SERVICO_ID") AS 
  SELECT DISTINCT
        eq.equipe_id,
        eq.nome as equipe,
        os.ordem_servico_id
   FROM equipe eq,
        equipe_usuario eu,
        os_usuario ou,
        ordem_servico os,
        job jo
  WHERE eq.equipe_id = eu.equipe_id
    AND eu.usuario_id = ou.usuario_id
    AND eu.flag_membro = 'S'
    AND ou.ordem_servico_id = os.ordem_servico_id
    AND os.job_id = jo.job_id
    AND jo.empresa_id = eq.empresa_id

;
