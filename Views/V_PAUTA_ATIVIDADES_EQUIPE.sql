--------------------------------------------------------
--  DDL for View V_PAUTA_ATIVIDADES_EQUIPE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PAUTA_ATIVIDADES_EQUIPE" ("ITEM_CRONO_ID", "EQUIPE_ID", "EQUIPE", "EMPRESA_ID") AS 
  WITH cte_os AS
 (SELECT /*+ USE_HASH(va osu) USE_HASH(osu eu) */
   va.item_crono_id,
   eu.equipe_id,
   eu.usuario_id,
   va.empresa_id
    FROM v_pauta_atividades va
    JOIN os_usuario osu
      ON va.objeto_id = osu.ordem_servico_id
    JOIN equipe_usuario eu
      ON osu.usuario_id = eu.usuario_id
   WHERE va.cod_objeto = 'ORDEM_SERVICO'
     AND va.objeto_id IS NOT NULL),
cte_tarefa AS
 (SELECT /*+ USE_HASH(va tu) USE_HASH(tu eu) */
   va.item_crono_id,
   eu.equipe_id,
   eu.usuario_id,
   va.empresa_id
    FROM v_pauta_atividades va
    JOIN tarefa_usuario tu
      ON va.objeto_id = tu.tarefa_id
    JOIN equipe_usuario eu
      ON tu.usuario_para_id = eu.usuario_id
   WHERE va.cod_objeto = 'TAREFA'
     AND va.objeto_id IS NOT NULL),
cte_uniao AS
 (SELECT *
    FROM cte_os
  UNION ALL
  SELECT *
    FROM cte_tarefa)
SELECT /*+ USE_HASH(cte eq) */
DISTINCT cte.item_crono_id,
         eq.equipe_id,
         eq.nome AS equipe,
         eq.empresa_id
  FROM cte_uniao cte
  JOIN equipe eq
    ON cte.equipe_id = eq.equipe_id
 WHERE eq.empresa_id = cte.empresa_id

;
