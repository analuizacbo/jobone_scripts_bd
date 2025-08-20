--------------------------------------------------------
--  DDL for View V_CUBO_ITEM_JOB
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CUBO_ITEM_JOB" ("EMPRESA_ID", "EMPRESA_NOME", "EMPRESA_CODIGO", "EMPRESA_COD_EXT", "OPORTUNIDADE_ID", "OPORT_EMPRESA", "OPORT_NUMERO", "OPORT_NOME", "OPORT_CLIENTE_ID", "OPORT_CLIENTE_APELIDO", "OPORT_CLIENTE_NOME", "OPORT_PRODUTO_CLIENTE_NOME", "OPORT_STATUS", "OPORT_STATUS_AUXILIAR", "OPORT_DATA_STATUS", "OPORT_PRODUTO_CLIENTE_COD_EXT", "OPORT_DATA_ENTRADA", "OPORT_ORIGEM", "OPORT_TIPO_NEGOCIO", "OPORT_CONCLUSAO", "CONTRATO_ID", "CONTRATO_NUMERO", "CONTRATO_NOME", "CONTRATO_CLIENTE_ID", "CONTRATO_CLIENTE_APELIDO", "CONTRATO_CLIENTE_NOME", "CONTRATO_CLIENTE_SETOR_NOME", "CONTRATO_CLIENTE_SETOR_CODIGO", "CONTRATO_TIPO_NOME", "CONTRATO_TIPO_COD_EXT", "CONTRATO_EMPR_RESP_ID", "CONTRATO_EMPR_RESP_APELIDO", "CONTRATO_EMPR_RESP_COD_EXT", "JOB_ID", "JOB_NOME", "JOB_NUMERO", "CLIENTE_ID", "CLIENTE_APELIDO", "CLIENTE_NOME", "CLIENTE_DATA_ENTRADA_AGENCIA", "CLIENTE_SETOR_ID", "CLIENTE_SETOR", "CLIENTE_SETOR_CODIGO", "PRODUTO_CLIENTE_ID", "PRODUTO_CLIENTE_NOME", "PRODUTO_CLIENTE_COD_EXT", "CAMPANHA_ID", "CAMPANHA", "CAMPANHA_COD_EXT", "JOB_EMPR_RESP_ID", "JOB_EMPR_RESP_APELIDO", "JOB_EMPR_RESP_COD_EXT", "JOB_TIPO_FINANCEIRO_ID", "JOB_TIPO_FINANCEIRO_NOME", "JOB_UNIDADE_NEGOCIO_ID", "JOB_UNIDADE_NEGOCIO_NOME", "JOB_UNIDADE_NEGOCIO_COD_EXT", "SERVICO_ID", "SERVICO_NOME", "JOB_DATA_ENTRADA", "JOB_DATA_ENTRADA_ANO", "JOB_DATA_ENTRADA_QUARTER", "JOB_DATA_ENTRADA_MES", "JOB_DATA_ENTRADA_MES_EXTENSO", "JOB_DATA_PREV_INI", "JOB_DATA_PREV_FIM", "JOB_DATA_APONT_INI", "JOB_DATA_APONT_FIM", "JOB_DATA_GOLIVE", "JOB_COD_EXT", "JOB_FLAG_CONCORRENCIA", "JOB_STATUS", "JOB_STATUS_AUXILIAR", "JOB_DATA_STATUS", "JOB_COMPLEXIDADE", "ENTREGAVEL_TIPO_PRODUTO_ID", "ENTREGAVEL_NOME", "ENTREGAVEL_COMPLEMENTO", "ENTREGAVEL_CLASSE", "ENTREGAVEL_SUBCLASSE", "ENTREGAVEL_CATEGORIA", "MIDIA_ONLINE", "MIDIA_OFFILINE", "ENTREGUE_CLIENTE", "ENTREGAVEL_CODIGO", "ENTREGAVEL_COD_EXT", "ENTREGAVEL_DATA_ENTRADA", "ENTREGAVEL_DATA_ENTRADA_ANO", "ENTREGAVEL_DATA_ENTRADA_QUARTER", "ENTREGAVEL_DATA_ENTRADA_MES", "ENTREGAVEL_DATA_ENTRADA_MES_EXTENSO", "ENTREGAVEL_DATA_TERMINO", "ENTREGAVEL_DATA_TERMINO_ANO", "ENTREGAVEL_DATA_TERMINO_QUARTER", "ENTREGAVEL_DATA_TERMINO_MES", "ENTREGAVEL_DATA_TERMINO_MES_EXTENSO", "OBJETO_CODIGO", "OBJETO_ID", "OBJETO_NUMERO", "OBJETO_STATUS", "SOLICITANTE", "EXECUTORES", "EQUIPE", "TEMPO_EXECUCAO_INFORMADO", "TEMPO_EXECUCAO_CALCULADO", "QTDE_WORKFLOWS_TASKS", "QTDE_REFACOES", "QTDE_REFACOES_AGENCIA", "QTDE_REFACOES_CLIENTE", "HORAS_GASTAS") AS 
  SELECT --empresa
         jo.empresa_id,
         ep.nome AS empresa_nome,
         ep.codigo AS empresa_codigo,
         ep.cod_ext_empresa AS empresa_cod_ext,
         --oportunidade
         NVL(op.oportunidade_id,-jo.empresa_id) AS oportunidade_id,
         NVL(oe.nome,'Sem Oportunidade') AS oport_empresa,
         NVL(op.numero,'Sem Oportunidade') AS oport_numero,
         NVL(op.nome,'Sem Oportunidade') AS oport_nome,
         NVL(op.cliente_id,-jo.empresa_id) AS oport_cliente_id,
         NVL(co.apelido,'Sem Oportunidade') AS oport_cliente_apelido,
         NVL(co.nome,'Sem Oportunidade') AS oport_cliente_nome,
         NVL(oc.nome,'Sem Oportunidade') AS oport_produto_cliente_nome,
         NVL(do.descricao,'Sem Oportunidade') AS oport_status,
         NVL(ao.nome,'Não Definido') AS oport_status_auxiliar,
         op.data_status AS oport_data_status,
         NVL(oc.cod_ext_produto,'Não Definido') AS oport_produto_cliente_cod_ext,
         op.data_entrada AS oport_data_entrada,
         NVL(oo.descricao,'Sem Oportunidade') AS oport_origem,
         NVL(ot.descricao,'Sem Oportunidade') AS oport_tipo_negocio,
         DECODE(op.tipo_conc,'GAN','Ganha','PER','Perdida','DEC','Declinada','Sem Oportunidade') AS oport_conclusao,
         --contrato
         NVL(jo.contrato_id,-jo.empresa_id) AS contrato_id,
         DECODE(jo.contrato_id,NULL,'Sem Contrato',CONTRATO_PKG.NUMERO_FORMATAR(jo.contrato_id)) AS contrato_numero,
         NVL(ct.nome,'Sem Contrato') AS contrato_nome,
         NVL(ct.contratante_id,-jo.empresa_id) AS contrato_cliente_id,
         NVL(cc.apelido,'Sem Contrato') AS contrato_cliente_apelido,
         NVL(cc.nome,'Sem Contrato') AS contrato_cliente_nome,
         NVL(sc.nome,'Não Definido') AS contrato_cliente_setor_nome,
         NVL(sc.codigo,'Não Definido') AS contrato_cliente_setor_codigo,
         NVL(tc.nome,'Sem Contrato') AS contrato_tipo_nome,
         NVL(tc.cod_ext_tipo, 'Não Definido') AS contrato_tipo_cod_ext,
         NVL(ct.emp_resp_id,-jo.empresa_id) AS contrato_empr_resp_id,
         NVL(cr.apelido,'Sem Contrato') AS contrato_empr_resp_apelido,
         NVL((SELECT MAX(r.cod_ext_resp)
                FROM empr_resp_sist_ext r
               WHERE r.pessoa_id = cr.pessoa_id),'Não Definido') AS contrato_empr_resp_cod_ext,
         --job
         jo.job_id,
         jo.nome AS job_nome,
         jo.numero AS job_numero,
         jo.cliente_id,
         cl.apelido AS cliente_apelido,
         cl.nome AS cliente_nome,
         cl.data_entrada_agencia AS cliente_data_entrada_agencia,
         NVL(sc.setor_id,-jo.empresa_id) AS cliente_setor_id,
         NVL(sc.nome,'Não Definido') AS cliente_setor,
         NVL(sc.codigo,'Não Definido') AS cliente_setor_codigo,
         pc.produto_cliente_id,
         NVL(pc.nome,'Não Definido') AS produto_cliente_nome,
         NVL(pc.cod_ext_produto,'Não Definido') AS produto_cliente_cod_ext,
         NVL(ca.campanha_id,-jo.empresa_id) AS campanha_id,
         NVL(ca.nome,'Não Definido') AS campanha,
         NVL(ca.cod_ext_camp,'Não Definido') AS campanha_cod_ext,
         jo.emp_resp_id AS job_empr_resp_id,
         er.apelido AS job_empr_resp_apelido,
         (SELECT MAX(r.cod_ext_resp)
            FROM empr_resp_sist_ext r
           WHERE r.pessoa_id = er.pessoa_id) AS job_empr_resp_cod_ext,
         tf.tipo_financeiro_id AS job_tipo_financeiro_id,
         NVL(tf.nome,'Não Definido') AS job_tipo_financeiro_nome,
         un.unidade_negocio_id AS job_unidade_negocio_id,
         NVL(un.nome,'Não Definido') AS job_unidade_negocio_nome,
         NVL(un.cod_ext_unid_neg,'Não Definido') AS job_unidade_negocio_cod_ext,
         NVL(se.servico_id,-jo.empresa_id) AS servico_id,
         NVL(se.nome,'Não Definido') AS servico_nome,
         jo.data_entrada AS job_data_entrada,
         TO_CHAR(jo.data_entrada,'YYYY') AS job_data_entrada_ano,
         TO_CHAR(jo.data_entrada,'Q') AS job_data_entrada_quarter,
         TO_CHAR(jo.data_entrada,'MM') AS job_data_entrada_mes,
         MES_MOSTRAR(TO_CHAR(jo.data_entrada,'MM')) AS job_data_entrada_mes_extenso,
         jo.data_prev_ini AS job_data_prev_ini,
         jo.data_prev_fim AS job_data_prev_fim,
         jo.data_apont_ini AS job_data_apont_ini,
         jo.data_apont_fim AS job_data_apont_fim,
         jo.data_golive AS job_data_golive,
         jo.cod_ext_job AS job_cod_ext,
         DECODE(jo.flag_concorrencia,'S','Sim','N','Não','N/D') AS job_flag_concorrencia,
         sj.descricao AS job_status,
         sa.nome AS job_status_auxiliar,
         jo.data_status AS job_data_status,
         cj.descricao AS job_complexidade,
         --item
         tp.tipo_produto_id AS entregavel_tipo_produto_id,
         tp.nome AS entregavel_nome,
         jt.complemento AS entregavel_complemento,
         NVL(cp.nome_classe,'Não Definido') AS entregavel_classe,
         NVL(cp.sub_classe,'Não Definido') AS entregavel_subclasse,
         NVL(ca.descricao,'Não Definido') AS entregavel_categoria,
         DECODE(ca.flag_tp_midia_on,'S','Sim','N','Não','N/D') AS midia_online,
         DECODE(ca.flag_tp_midia_off,'S','Sim','N','Não','N/D') AS midia_offiline,
         DECODE(ca.flag_entregue_cli,'S','Sim','N','Não','N/D') AS entregue_cliente,
         tp.codigo AS entregavel_codigo,
         tp.cod_ext_produto AS entregavel_cod_ext,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN ttp.data_entrada
           ELSE (SELECT MIN(data_entrada)
                   FROM os_tipo_produto t
                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
         END AS entregavel_data_entrada,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ttp.data_entrada,'YYYY')
           ELSE TO_CHAR((SELECT MIN(data_entrada)
            FROM os_tipo_produto t
           WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id),'YYYY')
         END AS entregavel_data_entrada_ano,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ttp.data_entrada,'Q')
           ELSE TO_CHAR((SELECT MIN(data_entrada)
            FROM os_tipo_produto t
           WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id),'Q')
         END AS entregavel_data_entrada_quarter,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ttp.data_entrada,'MM')
           ELSE TO_CHAR((SELECT MIN(data_entrada)
            FROM os_tipo_produto t
           WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id),'MM')
         END AS entregavel_data_entrada_mes,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN MES_MOSTRAR(TO_CHAR(ttp.data_entrada,'MM'))
           ELSE MES_MOSTRAR(TO_CHAR((SELECT MIN(data_entrada)
            FROM os_tipo_produto t
           WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id),'MM'))
         END AS entregavel_data_entrada_mes_extenso,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN ta.data_termino
           ELSE CASE
                  WHEN (SELECT COUNT(*)
                          FROM ordem_servico o
                               INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                         WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id
                           AND o.data_termino IS NULL) > 0
                  THEN NULL
                  ELSE (SELECT MAX(o.data_termino)
                          FROM ordem_servico o
                               INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                         WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
                END
         END AS entregavel_data_termino,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ta.data_termino,'YYYY')
           ELSE TO_CHAR((CASE
                           WHEN (SELECT COUNT(*)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id
                                    AND o.data_termino IS NULL) > 0
                           THEN NULL
                           ELSE (SELECT MAX(o.data_termino)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
                         END),'YYYY')
         END AS entregavel_data_termino_ano,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ta.data_termino,'Q')
           ELSE TO_CHAR((CASE
                           WHEN (SELECT COUNT(*)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id
                                    AND o.data_termino IS NULL) > 0
                           THEN NULL
                           ELSE (SELECT MAX(o.data_termino)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
                         END),'Q')
         END AS entregavel_data_termino_quarter,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TO_CHAR(ta.data_termino,'MM')
           ELSE TO_CHAR((CASE
                           WHEN (SELECT COUNT(*)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id
                                    AND o.data_termino IS NULL) > 0
                           THEN NULL
                           ELSE (SELECT MAX(o.data_termino)
                                   FROM ordem_servico o
                                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                  WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
                         END),'MM')
         END AS entregavel_data_termino_mes,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN MES_MOSTRAR(TO_CHAR(ta.data_termino,'MM'))
           ELSE MES_MOSTRAR(TO_CHAR((CASE
                                       WHEN (SELECT COUNT(*)
                                               FROM ordem_servico o
                                                    INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                              WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id
                                                AND o.data_termino IS NULL) > 0
                                       THEN NULL
                                       ELSE (SELECT MAX(o.data_termino)
                                               FROM ordem_servico o
                                                    INNER JOIN os_tipo_produto t ON t.ordem_servico_id = o.ordem_servico_id
                                              WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
                                     END),'MM'))
         END AS entregavel_data_termino_mes_extenso,
         --workflow ou task
         CASE
           WHEN os.ordem_servico_id IS NULL THEN 'Task'
           ELSE 'Workflow'
         END AS objeto_codigo,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN ta.tarefa_id
           ELSE os.ordem_servico_id
         END AS objeto_id,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN TAREFA_PKG.NUMERO_FORMATAR(ta.tarefa_id)
           ELSE ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id)
         END AS objeto_numero,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN dos.descricao
           ELSE dts.descricao
         END AS objeto_status,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN (SELECT p.apelido || ' (' || u.funcao || ')'
                                                 FROM pessoa p
                                                      INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                                WHERE p.usuario_id = ta.usuario_de_id)
           ELSE (SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'SOL')
         END AS solicitante,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM tarefa_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_para_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.tarefa_id = ta.tarefa_id),'-')
           ELSE NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'EXE'),'-')
         END AS executores,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN NVL((SELECT LISTAGG(nome,', ') within group (order by nome)
                                                     FROM (SELECT DISTINCT e.nome FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN tarefa_usuario i on (x.usuario_id = i.usuario_para_id OR x.usuario_id = ta.usuario_de_id)
                                                    WHERE i.tarefa_id = ta.tarefa_id
                                                      AND x.flag_membro = 'S')),'-')
           ELSE NVL((SELECT DISTINCT LISTAGG(nome,', ') within group (order by nome)
                                                     FROM (SELECT DISTINCT e.nome FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN os_usuario o ON o.usuario_id = x.usuario_id
                                                    WHERE o.ordem_servico_id = os.ordem_servico_id
                                                      AND x.flag_membro = 'S')),'-')
         END AS equipe,
         tp.tempo_exec_info AS tempo_execucao_informado,
         tp.tempo_exec_calc AS tempo_execucao_calculado,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN 1
           ELSE (SELECT COUNT(t.job_tipo_produto_id)
            FROM os_tipo_produto t
           WHERE t.job_tipo_produto_id = jt.job_tipo_produto_id)
         END AS qtde_workflows_tasks,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN CASE ta.flag_devolvida
                            WHEN 'S' THEN 1
                            ELSE 0
                          END
           ELSE (SELECT COUNT(*)
                   FROM os_evento e
                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = e.ordem_servico_id
                        INNER JOIN os_refacao r ON r.ordem_servico_id = t.ordem_servico_id
                                          AND r.num_refacao = e.num_refacao
                  WHERE e.cod_acao = 'REFAZER'
                    AND r.data_conclusao IS NOT NULL
                    AND t.job_tipo_produto_id = jt.job_tipo_produto_id)
         END AS qtde_refacoes,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN CASE ta.flag_devolvida
                            WHEN 'S' THEN 1
                            ELSE 0
                          END
           ELSE (SELECT COUNT(*)
                   FROM os_evento e
                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = e.ordem_servico_id
                        INNER JOIN os_refacao r ON r.ordem_servico_id = t.ordem_servico_id
                                          AND r.num_refacao = e.num_refacao
                  WHERE e.tipo_cliente_agencia = 'AGE'
                    AND e.cod_acao = 'REFAZER'
                    AND r.data_conclusao IS NOT NULL
                    AND t.job_tipo_produto_id = jt.job_tipo_produto_id)
         END AS qtde_refacoes_agencia,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN 0
           ELSE (SELECT COUNT(*)
                   FROM os_evento e
                        INNER JOIN os_tipo_produto t ON t.ordem_servico_id = e.ordem_servico_id
                        INNER JOIN os_refacao r ON r.ordem_servico_id = t.ordem_servico_id
                                          AND r.num_refacao = e.num_refacao
                  WHERE e.tipo_cliente_agencia = 'CLI'
                    AND e.cod_acao = 'REFAZER'
                    AND r.data_conclusao IS NOT NULL
                    AND t.job_tipo_produto_id = jt.job_tipo_produto_id)
         END AS qtde_refacoes_cliente,
         CASE
           WHEN os.ordem_servico_id IS NULL THEN
                (SELECT TRUNC(NVL(SUM(a.horas/(SELECT COUNT(*) FROM tarefa_tipo_produto q WHERE q.tarefa_id = ta.tarefa_id)),0),2)
                   FROM apontam_hora a
                  WHERE a.tarefa_id = ta.tarefa_id)
           ELSE (SELECT TRUNC(NVL(SUM(a.horas/(SELECT COUNT(*) FROM os_tipo_produto q WHERE q.ordem_servico_id = os.ordem_servico_id)),0),2)
                   FROM apontam_hora a
                  WHERE a.ordem_servico_id = os.ordem_servico_id)
         END AS horas_gastas
    FROM job_tipo_produto jt
         INNER JOIN tipo_produto tp ON tp.tipo_produto_id = jt.tipo_produto_id
         INNER JOIN job jo ON jo.job_id = jt.job_id
         INNER JOIN pessoa cl ON cl.pessoa_id = jo.cliente_id
         INNER JOIN pessoa er ON er.pessoa_id = jo.emp_resp_id
         INNER JOIN empresa ep ON ep.empresa_id = jo.empresa_id
         INNER JOIN dicionario sj ON sj.codigo = jo.status AND sj.tipo = 'status_job'
         INNER JOIN status_aux_job sa ON sa.status_aux_job_id = jo.status_aux_job_id
         INNER JOIN dicionario cj ON cj.codigo = jo.complex_job AND cj.tipo = 'complex_job'
          --ALCBO_291124_Verificar_se_precisa_ajuste
          LEFT JOIN categoria ca ON ca.categoria_id = tp.categoria_id
          LEFT JOIN classe_produto cp ON cp.classe_produto_id = ca.classe_produto_id
          --LEFT JOIN dicionario ce ON ce.codigo = tp.categoria AND ce.tipo = 'categoria_tipo_prod'
          LEFT JOIN produto_cliente pc ON pc.produto_cliente_id = jo.produto_cliente_id
          LEFT JOIN campanha ca ON ca.campanha_id = jo.campanha_id
          LEFT JOIN tipo_financeiro tf ON tf.tipo_financeiro_id = jo.tipo_financeiro_id
          LEFT JOIN unidade_negocio un ON un.unidade_negocio_id = jo.unidade_negocio_id
          LEFT JOIN servico se ON se.servico_id = jo.servico_id
          LEFT JOIN contrato ct ON jo.contrato_id = ct.contrato_id
          LEFT JOIN tipo_contrato tc ON tc.tipo_contrato_id = ct.tipo_contrato_id
          LEFT JOIN pessoa cc ON cc.pessoa_id = ct.contratante_id
          LEFT JOIN setor sc ON sc.setor_id = cc.setor_id
          LEFT JOIN pessoa cr ON cr.pessoa_id = ct.emp_resp_id
          LEFT JOIN oport_contrato oc ON oc.contrato_id = ct.contrato_id
          LEFT JOIN oportunidade op ON op.oportunidade_id = oc.oportunidade_id
          LEFT JOIN empresa oe ON oe.empresa_id = op.empresa_id
          LEFT JOIN dicionario do ON do.codigo = op.status AND do.tipo = 'status_oportunidade'
          LEFT JOIN status_aux_oport ao ON ao.status_aux_oport_id = op.status_aux_oport_id
          LEFT JOIN pessoa co ON co.pessoa_id = op.cliente_id
          LEFT JOIN produto_cliente oc ON oc.produto_cliente_id = op.produto_cliente_id
          LEFT JOIN dicionario oo ON oo.codigo = op.origem AND oo.tipo = 'oportunidade_origem'
          LEFT JOIN dicionario ot ON ot.codigo = op.tipo_negocio AND ot.tipo = 'oportunidade_tipo_negocio'
          LEFT JOIN (SELECT o.job_tipo_produto_id, MIN(o.data_entrada) AS data_entrada, MAX(o.ordem_servico_id) AS ordem_servico_id
                       FROM os_tipo_produto o
                            INNER JOIN job_tipo_produto j ON j.job_tipo_produto_id = o.job_tipo_produto_id
                   GROUP BY o.job_tipo_produto_id, j.job_id) otp ON otp.job_tipo_produto_id = jt.job_tipo_produto_id
          LEFT JOIN ordem_servico os ON os.ordem_servico_id = otp.ordem_servico_id
          LEFT JOIN (SELECT t.job_tipo_produto_id, MIN(t.data_entrada) AS data_entrada, MAX(t.tarefa_id) AS tarefa_id
                       FROM tarefa_tipo_produto t
                            INNER JOIN job_tipo_produto j ON j.job_tipo_produto_id = t.job_tipo_produto_id
                   GROUP BY t.job_tipo_produto_id, j.job_id) ttp ON ttp.job_tipo_produto_id = jt.job_tipo_produto_id
          LEFT JOIN tarefa ta ON ta.tarefa_id = ttp.tarefa_id
          LEFT JOIN dicionario dos ON dos.codigo = os.status AND dos.tipo = 'status_os'
          LEFT JOIN dicionario dts ON dts.codigo = ta.status AND dts.tipo = 'status_tarefa'
    WHERE jo.status <> 'CANC'

;
