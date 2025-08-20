--------------------------------------------------------
--  DDL for View V_TAREFA_EQUIPE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_TAREFA_EQUIPE" ("EQUIPE_ID", "EQUIPE", "TAREFA_ID") AS 
  SELECT DISTINCT
        eq.equipe_id,
        eq.nome as equipe,
        ta.tarefa_id
   FROM equipe eq,
        equipe_usuario eu,
        tarefa_usuario tu,
        tarefa ta
  WHERE eq.equipe_id = eu.equipe_id
    AND (eu.usuario_id = tu.usuario_para_id OR eu.usuario_id = ta.usuario_de_id)
    AND eu.flag_membro = 'S'
    AND tu.tarefa_id = ta.tarefa_id
    AND ta.empresa_id = eq.empresa_id

;
