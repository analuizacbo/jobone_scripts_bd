--------------------------------------------------------
--  DDL for View V_PAUTA_ATIVIDADES_USUARIO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PAUTA_ATIVIDADES_USUARIO" ("ITEM_CRONO_ID", "OBJETO_ID", "COD_OBJETO", "JOB_ID", "STATUS", "DATA_CONCLUSAO", "USUARIO_ID", "TIPO_ENDER", "ENDERECADO_NOME", "ENDERECADO_AREA", "NOME_FISICO", "NUMERO", "PREFIXO", "DIRETORIO", "HORAS", "COR_EXECUTOR", "RESPONSAVEL_ID", "RESPONSAVEL_JOB_ID", "RESPONSAVEL_PELO_JOB") AS 
  WITH responsaveis_job AS
 (SELECT ju.usuario_id AS responsavel_id,
         ju.job_id AS responsavel_job_id,
         mu.apelido || ' (' || mu.funcao || ')' AS responsavel_pelo_job
    FROM job_usuario ju
    JOIN mv_usuario mu
      ON ju.usuario_id = mu.usuario_id
   WHERE ju.flag_responsavel = 'S'),
cte_item_crono AS
 (SELECT va.item_crono_id,
         va.objeto_id,
         va.cod_objeto,
         va.job_id,
         va.status         AS status,
         va.data_conclusao AS data_conclusao
    FROM v_pauta_atividades va),
cte_executores_os AS
 (SELECT mos.item_crono_id AS item_crono_os,
         mu.usuario_id,
         osu.ordem_servico_id,
         osu.tipo_ender,
         (mu.apelido || ' (' || mu.funcao || ')') AS enderecado_nome,
         mu.area_nome AS enderecado_area,
         mu.nome_fisico,
         mu.numero,
         mu.prefixo,
         mu.caminho AS diretorio,
         nvl((SELECT SUM(u.horas_planej)
               FROM os_usuario u
              WHERE u.ordem_servico_id = mos.objeto_id),
             0) AS horas,
         DECODE(osu.status, 'EXEC', 'cinza', 'branco') as cor_executor
    FROM mv_usuario mu
   INNER JOIN os_usuario osu
      ON mu.usuario_id = osu.usuario_id
     AND osu.tipo_ender IN ('AVA', 'EXE', 'SOL')
   INNER JOIN mv_ordem_servico mos
      ON osu.ordem_servico_id = mos.objeto_id),
cte_executores_ta AS
 (SELECT mta.item_crono_id AS item_crono_ta,
         mu.usuario_id,
         tu.tarefa_id,
         'EXE' AS tipo_ender,
         (mu.apelido || ' (' || mu.funcao || ')') AS enderecado_nome,
         mu.area_nome AS enderecado_area,
         mu.nome_fisico,
         mu.numero,
         mu.prefixo,
         mu.caminho AS diretorio,
         nvl((SELECT SUM(tu.horas_totais)
               FROM tarefa_usuario tu
              WHERE tu.tarefa_id = mta.objeto_id),
             0) AS horas,
         DECODE(tu.status, 'EXEC', 'cinza', 'branco') as cor_executor
    FROM mv_usuario mu
   INNER JOIN tarefa_usuario tu
      ON mu.usuario_id = tu.usuario_para_id
   INNER JOIN mv_tarefa mta
      ON tu.tarefa_id = mta.objeto_id)

SELECT ic."ITEM_CRONO_ID",
       ic."OBJETO_ID",
       ic."COD_OBJETO",
       ic."JOB_ID",
       ic."STATUS",
       ic."DATA_CONCLUSAO",
       coalesce(os.usuario_id, ta.usuario_id) AS usuario_id,
       coalesce(os.tipo_ender, ta.tipo_ender) AS tipo_ender,
       coalesce(os.enderecado_nome, ta.enderecado_nome) AS enderecado_nome,
       coalesce(os.enderecado_area, ta.enderecado_area) AS enderecado_area,
       coalesce(os.nome_fisico, ta.nome_fisico) AS nome_fisico,
       coalesce(os.numero, ta.numero) AS numero,
       coalesce(os.prefixo, ta.prefixo) AS prefixo,
       coalesce(os.diretorio, ta.diretorio) AS diretorio,
       coalesce(os.horas, ta.horas) AS horas,
       coalesce(os.cor_executor, ta.cor_executor) AS cor_executor,
       rj."RESPONSAVEL_ID",
       rj."RESPONSAVEL_JOB_ID",
       rj."RESPONSAVEL_PELO_JOB"
  FROM cte_item_crono ic
  LEFT JOIN cte_executores_os os
    ON ic.item_crono_id = os.item_crono_os
   AND ic.objeto_id = os.ordem_servico_id
  LEFT JOIN cte_executores_ta ta
    ON ic.item_crono_id = ta.item_crono_ta
   AND ic.objeto_id = ta.tarefa_id
  LEFT JOIN responsaveis_job rj
    ON ic.job_id = rj.responsavel_job_id

;
