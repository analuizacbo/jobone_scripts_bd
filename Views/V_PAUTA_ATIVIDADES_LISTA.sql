--------------------------------------------------------
--  DDL for View V_PAUTA_ATIVIDADES_LISTA
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PAUTA_ATIVIDADES_LISTA" ("EMPRESA_ID", "COD_OBJETO", "OBJETO_ID", "ITEM_CRONO_ID", "CLIENTE_ESPECIFICO", "CLIENTE", "CLIENTE_SEM_ACENTO", "JOB_ID", "JOB_DESCRICAO", "JOB_STATUS_CODIGO", "ATIVIDADE_TIPO", "ATIVIDADE_COR_NO_QUADRO", "ATIVIDADE_NUMERO", "ATIVIDADE_DESCRICAO", "ATIVIDADE_DESCRICAO_SEM_NUMERO", "ATIVIDADE_METADADOS", "STATUS", "STATUS_CODIGO", "STATUS_NEGOCIACAO", "PRAZO", "PRAZO_FMT", "PRAZO_COR", "PRAZO_INTERNO", "PRAZO_INTERNO_FMT", "PRAZO_INTERNO_COR", "SOLICITANTE", "SOLICITANTE_DETALHE", "EQUIPE", "EQUIPE_ID", "AREA", "EXECUTORES", "EXECUTORES_DETALHE", "AVALIADOR", "AVALIADOR_DETALHE", "HORAS", "PRODUTO_CLIENTE", "CONTRATO_NUMERO", "CONTRATO_NOME", "DATA_INICIO_PLANEJADA", "DATA_INICIO_PLANEJADA_FMT", "DATA_FIM_PLANEJADA", "DATA_FIM_PLANEJADA_FMT", "RESPONSAVEL_PELO_JOB", "RESPONSAVEL_PELO_JOB_DETALHE", "RESPONSAVEL_PELO_JOB_ID", "CONTATO_JOB", "DATA_ENTRADA_JOB", "DATA_ENTRADA_JOB_FMT", "DATA_ENVIO", "DATA_ENVIO_FMT", "DATA_APRESENTACAO", "DATA_APRESENTACAO_FMT", "DATA_GO_LIVE", "DATA_GO_LIVE_FMT", "EXECUTOR_ID", "EXECUTOR_COR", "COMENT_STATUS_AUTOR", "COMENT_STATUS_DATA", "COMENT_STATUS_DATA_FMT", "COMENT_STATUS", "DATA_CONCLUSAO", "FILTRO_PRAZO", "TIPO_OS_ID", "DATA_ALOC_USUARIO", "INICIAR_SOMENTE_EM", "DATA_INICIO_ND", "REFACAO") AS 
  with cte_equipe_os AS (
    SELECT
      ordem_servico_id,
      LISTAGG(equipe,    ', ') WITHIN GROUP (ORDER BY equipe)    AS equipe,
      LISTAGG('|'||equipe_id||'|') WITHIN GROUP (ORDER BY equipe_id) AS equipe_id
    FROM v_os_equipe
    GROUP BY ordem_servico_id
  ),

  -- 2) Agrega equipes de tarefa
  cte_equipe_tarefa AS (
    SELECT
      tarefa_id,
      LISTAGG(equipe,    ', ') WITHIN GROUP (ORDER BY equipe)    AS equipe,
      LISTAGG('|'||equipe_id||'|') WITHIN GROUP (ORDER BY equipe_id) AS equipe_id
    FROM v_tarefa_equipe
    GROUP BY tarefa_id
),
ordem_servico AS
 (SELECT /*+ first_rows (1) */
   mos.empresa_id,
   mos.cod_objeto,
   mos.objeto_id,
   mos.item_crono_id,
   mos.cliente_especifico AS cliente_especifico,
   nvl((SELECT listagg(gr.nome, ', ') within GROUP(ORDER BY gr.nome)
         FROM grupo gr
        INNER JOIN grupo_pessoa gp
           ON gr.grupo_id = gp.grupo_id
        WHERE gp.pessoa_id = mos.cliente
          AND gr.flag_agrupa_cnpj = 'S'),
       mos.cliente_especifico) AS cliente,
   mos.job_id,
   mos.job_descricao,
   mos.job_status_codigo,
   mos.atividade_tipo,
   mos.atividade_cor_no_quadro,
   ordem_servico_pkg.numero_formatar(mos.objeto_id) AS atividade_numero,
   ordem_servico_pkg.numero_formatar(mos.objeto_id) || ' ' || mos.atividade_descricao_sem_numero AS atividade_descricao,
   mos.atividade_descricao_sem_numero,
   (SELECT listagg(v.valor_atributo, ', ') within GROUP(ORDER BY m.ordem)
      FROM os_atributo_valor v
     INNER JOIN metadado m
        ON m.metadado_id = v.metadado_id
     WHERE m.flag_na_lista = 'S'
       AND v.ordem_servico_id = mos.objeto_id) AS atividade_metadados,
   decode(mos.status,
          'CONC',
          'Concluída',
          'EXEC',
          'Executada',
          util_pkg.desc_retornar('status_os', mos.status) ||
          decode(mos.flag_recusada, 'S', ' (Recusado)', '')) AS status,
   mos.status_codigo,
   CASE
    WHEN mos.flag_em_negociacao = 'S' THEN
     'ANDA'
    WHEN mos.status_codigo IN ('DIST', 'ACEI', 'EMEX', 'AVAL') AND mos.flag_em_negociacao = 'N' AND
         (SELECT COUNT(1)
            FROM os_negociacao onx
           WHERE onx.ordem_servico_id = mos.objeto_id
             AND onx.num_refacao = mos.qtd_refacao) = 0 THEN
     'DISP'
    WHEN mos.status_codigo IN ('DIST', 'ACEI', 'EMEX', 'AVAL') AND mos.flag_em_negociacao = 'N' AND
         (SELECT COUNT(1)
            FROM os_negociacao onx
           WHERE onx.ordem_servico_id = mos.objeto_id
             AND onx.num_refacao = mos.qtd_refacao) > 0 THEN
     'CONC'
    ELSE
     'N/A'
   END AS status_negociacao,
   mos.prazo,
   data_mostrar(mos.prazo) AS prazo_fmt,
   CASE
    WHEN mos.status_codigo IN ('PREP', 'DIST', 'ACEI', 'EMEX', 'AVAL', 'EXEC', 'EMAP', 'STAN') THEN
     CASE
      WHEN mos.prazo <= SYSDATE THEN
       'vermelho'
      WHEN mos.prazo > SYSDATE AND mos.prazo < trunc(SYSDATE + 1) THEN
       'amarelo'
      ELSE
       'branco'
     END
    WHEN mos.status_codigo = 'CONC' AND mos.prazo IS NOT NULL THEN
     'verde'
    ELSE
     'branco'
   END AS prazo_cor,
   mos.prazo_interno,
   data_mostrar(mos.prazo_interno) AS prazo_interno_fmt,
   CASE
    WHEN mos.status_codigo NOT IN ('CONC', 'EXEC') THEN
     CASE
      WHEN mos.prazo_interno <= SYSDATE THEN
       'vermelho'
      WHEN mos.prazo_interno > SYSDATE AND mos.prazo_interno < trunc(SYSDATE + 1) THEN
       'amarelo'
      ELSE
       'branco'
     END
    WHEN (mos.status_codigo = 'CONC' OR mos.status_codigo = 'EXEC') AND mos.prazo_interno IS NOT NULL THEN
     'verde'
    ELSE
     'branco'
   END AS prazo_interno_cor,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'SOL') AS solicitante,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'SOL') AS solicitante_detalhe,
  cte_equipe_os.equipe,
  cte_equipe_os.equipe_id,
   nvl((SELECT DISTINCT listagg(nome, ', ') within GROUP(ORDER BY nome)
         FROM (SELECT DISTINCT a.nome
                 FROM area a
                INNER JOIN cargo c
                   ON c.area_id = a.area_id
                INNER JOIN usuario_cargo x
                   ON x.cargo_id = c.cargo_id
                INNER JOIN os_usuario o
                   ON o.usuario_id = x.usuario_id
                WHERE o.ordem_servico_id = mos.objeto_id
                  AND a.empresa_id = mos.empresa_id
                  AND x.data_fim IS NULL)),
       '-') AS area,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'EXE') AS executores,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|' || decode(i.status_aux, 'PEND','Pendente','PRAZ','Terminarei', 'ATRA', 'Não terminarei', 'Nenhum') || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'EXE') AS executores_detalhe,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'AVA') AS avaliador,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario i
     WHERE i.usuario_id = mu.usuario_id
       AND i.ordem_servico_id = mos.objeto_id
       AND i.tipo_ender = 'AVA') AS avaliador_detalhe,
   nvl((SELECT SUM(u.horas_planej)
         FROM os_usuario u
        WHERE u.ordem_servico_id = mos.objeto_id),
       0) AS horas,
   mos.produto_cliente,
   decode(contrato_pkg.numero_formatar(mos.contrato_numero),
          'ERRO',
          '-',
          contrato_pkg.numero_formatar(mos.contrato_numero)) AS contrato_numero,
   decode(mos.contrato_nome, NULL, '-', mos.contrato_nome) AS contrato_nome,
   mos.data_inicio_planejada AS data_inicio_planejada,
   data_mostrar(mos.data_inicio_planejada_fmt) AS data_inicio_planejada_fmt,
   mos.data_fim_planejada AS data_fim_planejada,
   data_mostrar(mos.data_fim_planejada_fmt) AS data_fim_planejada_fmt,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario  mu,
           job_usuario i
     WHERE i.job_id = mos.job_id
       AND i.usuario_id = mu.usuario_id
       AND i.flag_responsavel = 'S') AS responsavel_pelo_job,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario  mu,
           job_usuario i
     WHERE i.job_id = mos.job_id
       AND i.usuario_id = mu.usuario_id
       AND i.flag_responsavel = 'S') AS responsavel_pelo_job_detalhe,
   nvl((SELECT listagg(ju.usuario_id, ', ')
         FROM mv_usuario  mu,
              job_usuario ju
        WHERE ju.job_id = mos.job_id
          AND ju.usuario_id = mu.usuario_id
          AND ju.flag_responsavel = 'S'),
       0) AS responsavel_pelo_job_id,
   nvl((SELECT p.apelido || decode(p.funcao, NULL, '', ' (' || p.funcao || ')')
         FROM pessoa p
        WHERE p.pessoa_id = mos.contato_id),
       '-') AS contato_job,
   mos.data_entrada_job AS data_entrada_job,
   data_mostrar(mos.data_entrada_job_fmt) AS data_entrada_job_fmt,
   CASE
    WHEN mos.status_codigo IN ('DIST', 'ACEI', 'EMEX', 'EXEC', 'CONC', 'EMAP', 'AVAL') THEN
     ordem_servico_pkg.data_retornar(mos.objeto_id, 'ENVI')
    WHEN mos.status_codigo IN ('DESC', 'PREP', 'CANC', 'STAN') THEN
     NULL
   END AS data_envio,
   CASE
    WHEN mos.status_codigo IN ('DIST', 'ACEI', 'EMEX', 'EXEC', 'CONC', 'EMAP', 'AVAL') THEN
     data_mostrar(ordem_servico_pkg.data_retornar(mos.objeto_id, 'ENVI'))
    WHEN mos.status_codigo IN ('DESC', 'PREP', 'CANC', 'STAN') THEN
     NULL
   END AS data_envio_fmt,
   mos.data_apresentacao AS data_apresentacao,
   data_mostrar(mos.data_apresentacao_fmt) AS data_apresentacao_fmt,
   mos.data_go_live AS data_go_live,
   data_mostrar(mos.data_go_live_fmt) AS data_go_live_fmt,
   (SELECT listagg(mu.usuario_id, ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu,
           os_usuario ou
     WHERE mu.usuario_id = ou.usuario_id
       AND ou.ordem_servico_id = mos.objeto_id
       AND ou.tipo_ender = 'EXE') AS executor_id,
   (SELECT listagg(CASE ou.status
                    WHEN 'EXEC' THEN
                     'cinza'
                    ELSE
                     'branco'
                   END,
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM os_usuario ou,
           mv_usuario mu
     WHERE ou.ordem_servico_id = mos.objeto_id
       AND ou.usuario_id = mu.usuario_id
       AND ou.tipo_ender = 'EXE') AS executor_cor,
   nvl((SELECT p.apelido
         FROM pessoa p
        WHERE p.usuario_id = mos.usuario_situacao_id),
       '-') AS coment_status_autor,
   mos.coment_status_data AS coment_status_data,
   data_mostrar(mos.coment_status_data_fmt) AS coment_status_data_fmt,
   nvl(mos.coment_status, '-') AS coment_status,
   mos.data_conclusao AS data_conclusao,
   mos.filtro_prazo,
   mos.tipo_os_id,
   (SELECT MIN(ou.data)
      FROM os_usuario_data ou
     WHERE ou.ordem_servico_id = mos.objeto_id) AS data_aloc_usuario,
   mos.data_demanda AS iniciar_somente_em,
   CASE
    WHEN mos.data_demanda IS NULL THEN
     'DATA INICIO NAO DEFINIDA'
   END AS data_inicio_nd,
   CASE
    WHEN mos.qtd_refacao = 0 OR mos.qtd_refacao IS NULL THEN
     '-'
    ELSE
     to_char(mos.qtd_refacao)
   END AS refacao
   FROM mv_ordem_servico mos
   LEFT JOIN cte_equipe_os
   ON cte_equipe_os.ordem_servico_id = mos.objeto_id),
tarefa AS
 (SELECT /*+ first_rows (1) */
   mta.empresa_id,
   mta.cod_objeto,
   mta.objeto_id,
   mta.item_crono_id,
   mta.cliente_especifico AS cliente_especifico,
   nvl((SELECT listagg(gr.nome, ', ') within GROUP(ORDER BY gr.nome)
         FROM grupo gr
        INNER JOIN grupo_pessoa gp
           ON gr.grupo_id = gp.grupo_id
        WHERE gp.pessoa_id = mta.cliente
          AND gr.flag_agrupa_cnpj = 'S'),
       mta.cliente_especifico) AS cliente,
   mta.job_id,
   mta.job_descricao,
   mta.job_status_codigo,
   mta.atividade_tipo,
   mta.atividade_cor_no_quadro,
   tarefa_pkg.numero_formatar(mta.objeto_id) AS atividade_numero,
   tarefa_pkg.numero_formatar(mta.objeto_id) || ' ' || mta.atividade_descricao_sem_numero AS atividade_descricao,
   mta.atividade_descricao_sem_numero,
   (SELECT listagg(v.valor_atributo, ', ') within GROUP(ORDER BY m.ordem)
      FROM tarefa_tp_atrib_valor v
     INNER JOIN tarefa_tipo_produto t
        ON t.tarefa_tipo_produto_id = v.tarefa_tipo_produto_id
     INNER JOIN metadado m
        ON m.metadado_id = v.metadado_id
     WHERE m.flag_na_lista = 'S'
       AND t.tarefa_id = mta.objeto_id) AS atividade_metadados,
   util_pkg.desc_retornar('status_tarefa', mta.status) AS status,
   mta.status_codigo,
   mta.status_negociacao,
   mta.prazo,
   data_mostrar(mta.prazo) AS prazo_fmt,
   CASE
    WHEN mta.status_codigo NOT IN ('CONC', 'EXEC') THEN
     CASE
      WHEN mta.prazo <= SYSDATE THEN
       'vermelho'
      WHEN mta.prazo > SYSDATE AND mta.prazo < trunc(SYSDATE + 1) THEN
       'amarelo'
      ELSE
       'branco'
     END
    WHEN (mta.status_codigo = 'CONC' OR mta.status_codigo = 'EXEC') AND mta.prazo IS NOT NULL THEN
     'verde'
    ELSE
     'branco'
   END AS prazo_cor,
   NULL AS prazo_interno,
   NULL AS prazo_interno_fmt,
   'branco' AS prazo_interno_cor,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu
     WHERE mu.usuario_id = mta.solicitante_id) AS solicitante,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario mu
     WHERE mu.usuario_id = mta.solicitante_id) AS solicitante_detalhe,
   cte_equipe_tarefa.equipe,
   cte_equipe_tarefa.equipe_id,
   nvl((SELECT DISTINCT listagg(area_nome, ', ') within GROUP(ORDER BY area_nome)
         FROM (SELECT DISTINCT mu.area_nome
                 FROM mv_usuario mu
                INNER JOIN tarefa_usuario tu
                   ON tu.usuario_para_id = mu.usuario_id
                   OR mu.usuario_id = mta.solicitante_id
                WHERE tu.tarefa_id = mta.objeto_id)),
       '-') AS area,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario z
     WHERE z.usuario_para_id = mu.usuario_id
       AND z.tarefa_id = mta.objeto_id) AS executores,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario z
     WHERE z.usuario_para_id = mu.usuario_id
       AND z.tarefa_id = mta.objeto_id) AS executores_detalhe,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario z
     WHERE z.usuario_para_id = mu.usuario_id
       AND z.tarefa_id = mta.objeto_id) AS avaliador,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '|' || mu.nome_fisico || '|' ||
                   mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario z
     WHERE z.usuario_para_id = mu.usuario_id
       AND z.tarefa_id = mta.objeto_id) AS avaliador_detalhe,
   nvl((SELECT SUM(tu.horas_totais)
         FROM tarefa_usuario tu
        WHERE tu.tarefa_id = mta.objeto_id),
       0) AS horas,
   mta.produto_cliente,
   decode(contrato_pkg.numero_formatar(mta.contrato_numero),
          'ERRO',
          '-',
          contrato_pkg.numero_formatar(mta.contrato_numero)) AS contrato_numero,
   decode(mta.contrato_nome, NULL, '-', mta.contrato_nome) AS contrato_nome,
   mta.data_inicio_planejada AS data_inicio_planejada,
   data_mostrar(mta.data_inicio_planejada_fmt) AS data_inicio_planejada_fmt,
   mta.data_fim_planejada AS data_fim_planejada,
   data_mostrar(mta.data_fim_planejada_fmt) AS data_fim_planejada_fmt,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ')', ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario  mu,
           job_usuario i
     WHERE i.job_id = mta.job_id
       AND i.usuario_id = mu.usuario_id
       AND i.flag_responsavel = 'S') AS responsavel_pelo_job,
   (SELECT listagg(mu.apelido || ' (' || mu.funcao || ') |' || mu.usuario_id || '| ' ||
                   mu.nome_fisico || '|' || mu.prefixo || '|' || mu.numero || '|',
                   ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario  mu,
           job_usuario i
     WHERE i.job_id = mta.job_id
       AND i.usuario_id = mu.usuario_id
       AND i.flag_responsavel = 'S') AS responsavel_pelo_job_detalhe,
   nvl((SELECT listagg(ju.usuario_id, ', ')
         FROM mv_usuario  mu,
              job_usuario ju
        WHERE ju.job_id = mta.job_id
          AND ju.usuario_id = mu.usuario_id
          AND ju.flag_responsavel = 'S'),
       0) AS responsavel_pelo_job_id,
   nvl((SELECT p.apelido || decode(p.funcao, NULL, '', ' (' || p.funcao || ')')
         FROM pessoa p
        WHERE p.pessoa_id = mta.contato_id),
       '-') AS contato_job,
   mta.data_entrada_job AS data_entrada_job,
   data_mostrar(mta.data_entrada_job_fmt) AS data_entrada_job_fmt,
   mta.data_envio AS data_envio,
   data_mostrar(mta.data_envio_fmt) AS data_envio_fmt,
   mta.data_apresentacao AS data_apresentacao,
   data_mostrar(mta.data_apresentacao_fmt) AS data_apresentacao_fmt,
   mta.data_go_live AS data_go_live,
   data_mostrar(mta.data_go_live_fmt) AS data_go_live_fmt,
   (SELECT listagg(mu.usuario_id, ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario tu
     WHERE mu.usuario_id = tu.usuario_para_id
       AND tu.tarefa_id = mta.objeto_id) AS executor_id,
   (SELECT listagg(decode(tu.status, 'EXEC', 'cinza', 'branco'), ', ') within GROUP(ORDER BY mu.apelido)
      FROM mv_usuario     mu,
           tarefa_usuario tu
     WHERE mu.usuario_id = tu.usuario_para_id
       AND tu.tarefa_id = mta.objeto_id) AS executor_cor,
   nvl((SELECT p.apelido
         FROM pessoa p
        WHERE p.usuario_id = mta.usuario_situacao_id),
       '-') AS coment_status_autor,
   mta.coment_status_data AS coment_status_data,
   data_mostrar(mta.coment_status_data_fmt) AS coment_status_data_fmt,
   nvl(mta.coment_status, '-') AS coment_status,
   mta.data_conclusao AS data_conclusao,
   mta.filtro_prazo,
   NULL AS tipo_os_id,
   NULL AS data_aloc_usuario,
   NULL AS iniciar_somente_em,
   NULL AS data_inicio_nd,
   '-' AS refacao
    FROM mv_tarefa mta
   INNER JOIN v_tarefa_equipe te
      ON mta.objeto_id = te.tarefa_id
  LEFT JOIN cte_equipe_tarefa
  ON cte_equipe_tarefa.tarefa_id = mta.objeto_id)
SELECT "EMPRESA_ID","COD_OBJETO","OBJETO_ID","ITEM_CRONO_ID","CLIENTE_ESPECIFICO","CLIENTE",ACENTO_RETIRAR(CLIENTE) AS CLIENTE_SEM_ACENTO,"JOB_ID","JOB_DESCRICAO","JOB_STATUS_CODIGO","ATIVIDADE_TIPO","ATIVIDADE_COR_NO_QUADRO","ATIVIDADE_NUMERO","ATIVIDADE_DESCRICAO","ATIVIDADE_DESCRICAO_SEM_NUMERO","ATIVIDADE_METADADOS","STATUS","STATUS_CODIGO","STATUS_NEGOCIACAO","PRAZO","PRAZO_FMT","PRAZO_COR","PRAZO_INTERNO","PRAZO_INTERNO_FMT","PRAZO_INTERNO_COR","SOLICITANTE","SOLICITANTE_DETALHE","EQUIPE","EQUIPE_ID","AREA","EXECUTORES","EXECUTORES_DETALHE","AVALIADOR","AVALIADOR_DETALHE","HORAS","PRODUTO_CLIENTE","CONTRATO_NUMERO","CONTRATO_NOME","DATA_INICIO_PLANEJADA","DATA_INICIO_PLANEJADA_FMT","DATA_FIM_PLANEJADA","DATA_FIM_PLANEJADA_FMT","RESPONSAVEL_PELO_JOB","RESPONSAVEL_PELO_JOB_DETALHE","RESPONSAVEL_PELO_JOB_ID","CONTATO_JOB","DATA_ENTRADA_JOB","DATA_ENTRADA_JOB_FMT","DATA_ENVIO","DATA_ENVIO_FMT","DATA_APRESENTACAO","DATA_APRESENTACAO_FMT","DATA_GO_LIVE","DATA_GO_LIVE_FMT","EXECUTOR_ID","EXECUTOR_COR","COMENT_STATUS_AUTOR","COMENT_STATUS_DATA","COMENT_STATUS_DATA_FMT","COMENT_STATUS","DATA_CONCLUSAO","FILTRO_PRAZO","TIPO_OS_ID","DATA_ALOC_USUARIO","INICIAR_SOMENTE_EM","DATA_INICIO_ND","REFACAO"
  FROM ordem_servico
UNION ALL
SELECT "EMPRESA_ID","COD_OBJETO","OBJETO_ID","ITEM_CRONO_ID","CLIENTE_ESPECIFICO","CLIENTE",ACENTO_RETIRAR(CLIENTE) AS CLIENTE_SEM_ACENTO,"JOB_ID","JOB_DESCRICAO","JOB_STATUS_CODIGO","ATIVIDADE_TIPO","ATIVIDADE_COR_NO_QUADRO","ATIVIDADE_NUMERO","ATIVIDADE_DESCRICAO","ATIVIDADE_DESCRICAO_SEM_NUMERO","ATIVIDADE_METADADOS","STATUS","STATUS_CODIGO","STATUS_NEGOCIACAO","PRAZO","PRAZO_FMT","PRAZO_COR","PRAZO_INTERNO","PRAZO_INTERNO_FMT","PRAZO_INTERNO_COR","SOLICITANTE","SOLICITANTE_DETALHE","EQUIPE","EQUIPE_ID","AREA","EXECUTORES","EXECUTORES_DETALHE","AVALIADOR","AVALIADOR_DETALHE","HORAS","PRODUTO_CLIENTE","CONTRATO_NUMERO","CONTRATO_NOME","DATA_INICIO_PLANEJADA","DATA_INICIO_PLANEJADA_FMT","DATA_FIM_PLANEJADA","DATA_FIM_PLANEJADA_FMT","RESPONSAVEL_PELO_JOB","RESPONSAVEL_PELO_JOB_DETALHE","RESPONSAVEL_PELO_JOB_ID","CONTATO_JOB","DATA_ENTRADA_JOB","DATA_ENTRADA_JOB_FMT","DATA_ENVIO","DATA_ENVIO_FMT","DATA_APRESENTACAO","DATA_APRESENTACAO_FMT","DATA_GO_LIVE","DATA_GO_LIVE_FMT","EXECUTOR_ID","EXECUTOR_COR","COMENT_STATUS_AUTOR","COMENT_STATUS_DATA","COMENT_STATUS_DATA_FMT","COMENT_STATUS","DATA_CONCLUSAO","FILTRO_PRAZO","TIPO_OS_ID","DATA_ALOC_USUARIO","INICIAR_SOMENTE_EM","DATA_INICIO_ND","REFACAO"
  FROM tarefa
;
