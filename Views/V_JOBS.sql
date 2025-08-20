--------------------------------------------------------
--  DDL for View V_JOBS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOBS" ("JOB_ID", "EMPRESA_ID", "NUMERO", "NOME", "TIPO_JOB_NOME", "GRUPO_CLIENTE", "CRONOGRAMA_ID", "DATA_PLANEJ_FIM_FMT", "DATA_HOJE_FMT", "QTDE_ENTREGA_ATRASO", "CONTATO", "CLIENTE_PROJETO", "CLIENTE_CNPJ", "PRODUTO_CLIENTE", "CAMPANHA", "SERVICO", "UNIDADE_NEGOCIO", "TIPO_FINANCEIRO", "TIPO_PROJETO", "COMPLEXIDADE", "EMPRESA_RESPONSAVEL", "DATA_ENTRADA", "DATA_INICIO", "DATA_FIM", "DATA_APRESENTACAO_CLIENTE", "DATA_GOLIVE", "PERIODO_PLANEJADO_OFICIAL", "STATUS", "STATUS_ESTENDIDO", "STATUS_DATA", "STATUS_AUTOR", "STATUS_BRIEFING", "STATUS_CRONOGRAMA", "STATUS_ESTIMATIVA_HORAS", "STATUS_CHECKIN", "STATUS_FATUR", "CONTEXTO_ALTERACAO_CRONOGRAMA", "CONCORRENTES", "CONCORRENTE", "GANHA_PERDIDA", "RESPONSAVEL_PROJETO", "BUDGET", "RECEITA_PREVISTA_CONTRATO", "CONTRATO_FATURAMENTO", "ITENS_A_PAGOS_PELO_CLIENTE", "BLOQUEAIA_NEGOCIACAO_BV_TP", "USA_BV_PADRAO_FORNECEDOR", "FATURAR_PROJETO_POR", "NUMERO_CONTRATO", "DESCRICAO_CONTRATO", "RESPONSAVEL_PELO_CONTRATO", "STATUS_CONTRATO", "VIGENCIA_CONTRATO_INICIO", "VIGENCIA_CONTRATO_FIM", "TIPO_CONTRATO", "JOB_ENDERECADOS", "JOB_USUARIO_ID", "GRUPO_PRODUTO_ID", "GRUPO_PRODUTO_NOME", "COD_EXT_JOB") AS 
  SELECT jo.job_id,
       jo.empresa_id,
       jo.numero,
       jo.nome,
       tj.nome AS tipo_job_nome,
       nvl((SELECT listagg(g.nome, ', ') within GROUP(ORDER BY g.nome)
             FROM grupo_pessoa gp,
                  grupo        g
            WHERE gp.grupo_id = g.grupo_id
              AND gp.pessoa_id = pe.pessoa_id),
           pe.apelido) AS grupo_cliente,
       nvl((SELECT MAX(c1.cronograma_id)
             FROM cronograma c1
            WHERE c1.job_id = jo.job_id
              AND c1.status IN ('PREP', 'APROV')),
           0) AS cronograma_id,
       (SELECT data_mostrar(MAX(ic.data_planej_fim))
          FROM cronograma cr,
               item_crono ic
         WHERE cr.job_id = jo.job_id
           AND ic.cronograma_id = cr.cronograma_id
           AND ic.cod_objeto = 'JOB_CONC'
           AND cr.cronograma_id =
               (SELECT MAX(c1.cronograma_id)
                  FROM cronograma c1
                 WHERE c1.job_id = jo.job_id
                   AND c1.status IN
                       ('PREP', 'APROV'))) AS data_planej_fim_fmt,
       data_mostrar(SYSDATE) AS data_hoje_fmt,
       (SELECT COUNT(*)
          FROM ordem_servico os
         WHERE os.job_id = jo.job_id
           AND os.data_solicitada < SYSDATE
           AND EXISTS
         (SELECT 1
                  FROM item_crono it
                 WHERE it.cod_objeto =
                       'ORDEM_SERVICO'
                   AND it.objeto_id =
                       os.ordem_servico_id)) + CASE
         WHEN job_pkg.sla_data_termino_retornar(jo.job_id) IS NOT NULL AND
              job_pkg.sla_data_termino_retornar(jo.job_id) >
              job_pkg.sla_data_limite_retornar(jo.job_id) THEN
          1
         ELSE
          0
       END + CASE
         WHEN job_pkg.sla_data_termino_retornar(jo.job_id) IS NULL AND
              job_pkg.sla_data_limite_retornar(jo.job_id) IS NOT NULL AND
              job_pkg.sla_data_limite_retornar(jo.job_id) >
              SYSDATE THEN
          1
         ELSE
          0
       END AS qtde_entrega_atraso,
       pc.nome AS contato,
       pe.apelido AS cliente_projeto,
       CNPJ_PKG.mostrar(pe.cnpj, jo.empresa_id) AS cliente_cnpj,
       pr.nome AS produto_cliente,
       ca.nome AS campanha,
       se.nome AS servico,
       un.nome AS unidade_negocio,
       tf.nome AS tipo_financeiro,
       tj.nome AS tipo_projeto,
       jo.complex_job AS complexidade,
       er.nome AS empresa_responsavel,
       jo.data_entrada AS data_entrada,
       jo.data_prev_ini AS data_inicio,
       jo.data_prev_fim AS data_fim,
       jo.data_pri_aprov AS data_apresentacao_cliente,
       jo.data_golive AS data_golive,
       decode(jo.tipo_data_prev,
              'EST',
              'Planejado',
              'OFI',
              'Oficial',
              jo.tipo_data_prev) AS periodo_planejado_oficial,
       jo.status AS status,
       (SELECT s.nome
          FROM status_aux_job s
         WHERE s.status_aux_job_id =
               jo.status_aux_job_id
           AND s.empresa_id = jo.empresa_id) AS status_estendido,
       jo.data_status AS status_data,
       (SELECT v.apelido_usuario
          FROM v_historico v,
               (SELECT v1.objeto_id,
                       v1.evento_id,
                       MAX(v1.data_evento) AS data_evento
                  FROM v_historico v1,
                       evento      ev,
                       tipo_acao   ta
                 WHERE v1.usuario_id =
                       jp.usuario_id
                   AND v1.evento_id = ev.evento_id
                   AND ev.tipo_acao_id =
                       ta.tipo_acao_id
                   AND ta.codigo = 'ALTERAR'
                   AND v1.cod_objeto = 'JOB'
                   AND v1.objeto_id = jo.job_id
                   AND v1.empresa_id =
                       jo.empresa_id
                 GROUP BY v1.objeto_id,
                          v1.evento_id) v2
         WHERE v.objeto_id = v2.objeto_id
           AND v.data_evento = v2.data_evento
           AND v.evento_id = 6) AS status_autor,
       CASE
         WHEN br.flag_com_aprov = 'S' THEN
          util_pkg.desc_retornar('status_brief',
                                 br.status)
         ELSE
          CASE
            WHEN br.status = 'APROV' THEN
             'Pronto'
            ELSE
             util_pkg.desc_retornar('status_brief',
                                    br.status)
          END
       END AS status_briefing,
       CASE
         WHEN cr.flag_com_aprov = 'S' THEN
          util_pkg.desc_retornar('status_crono',
                                 cr.status)
         ELSE
          CASE
            WHEN cr.status IS NULL THEN
             'Não Iniciado'
            WHEN cr.status = 'APROV' THEN
             'Pronto'
            ELSE
             util_pkg.desc_retornar('status_crono',
                                    cr.status)
          END
       END AS status_cronograma,
       CASE
         WHEN jo.flag_com_aprov_horas = 'S' THEN
          util_pkg.desc_retornar('status_job_horas',
                                 jo.status_horas)
         ELSE
          CASE
            WHEN jo.status_horas = 'APROV' THEN
             'Pronta'
            ELSE
             util_pkg.desc_retornar('status_job_horas',
                                    jo.status_horas)
          END
       END AS status_estimativa_horas,
       jo.status_checkin AS status_checkin,
       jo.status_fatur,
       cc.nome AS contexto_alteracao_cronograma,
       jo.contra_quem AS concorrentes,
       decode(jo.flag_concorrencia,
              'S',
              'Sim',
              'N',
              'Não') AS concorrente,
       decode(jo.flag_conc_perdida,
              NULL,
              'Não Definido',
              'S',
              'Perdido',
              'N',
              'Ganho') AS ganha_perdida,
       decode(jp.apelido,
              NULL,
              'Não Definido',
              jp.apelido || ' (' || jp.funcao || ')') AS responsavel_projeto,
       jo.budget AS budget,
       jo.receita_prevista AS receita_prevista_contrato,
       cf.nome AS contrato_faturamento,
       jo.flag_pago_cliente AS itens_a_pagos_pelo_cliente,
       jo.flag_bloq_negoc AS bloqueaia_negociacao_bv_tp,
       jo.flag_bv_fornec AS usa_bv_padrao_fornecedor,
       (SELECT p.nome
          FROM pessoa p
         WHERE p.pessoa_id = jo.emp_faturar_por_id
           AND p.empresa_id = jo.empresa_id) AS faturar_projeto_por,
       CASE
         WHEN ct.contrato_id IS NOT NULL THEN
          contrato_pkg.numero_formatar(ct.contrato_id)
         ELSE
          NULL
       END AS numero_contrato,
       ct.nome AS descricao_contrato,
       decode(ca.apelido,
              NULL,
              'Não Definido',
              ca.apelido || ' (' || ca.funcao || ')') AS responsavel_pelo_contrato,
       ct.status AS status_contrato,
       ct.data_inicio AS vigencia_contrato_inicio,
       ct.data_termino AS vigencia_contrato_fim,
       tc.nome AS tipo_contrato,
       (SELECT listagg(nvl(to_char(u.usuario_id),
                           '-'),
                       ', ') within GROUP(ORDER BY u.usuario_id)
          FROM job_usuario u
         WHERE u.job_id = jo.job_id) AS job_enderecados,
       jp.usuario_id AS job_usuario_id,
       (SELECT gs.grupo_servico_id
       FROM grupo_servico gs
       where grupo_servico_id = se.grupo_servico_id) as grupo_produto_id,
       (SELECT gs.nome
       FROM grupo_servico gs
       where grupo_servico_id = se.grupo_servico_id) as grupo_produto_nome,
       jo.cod_ext_job
  FROM job jo,
       tipo_job tj,
       pessoa pe,
       contrato ct,
       tipo_contrato tc,
       pessoa pc,
       produto_cliente pr,
       campanha ca,
       servico se,
       unidade_negocio un,
       tipo_financeiro tf,
       pessoa er,
       contexto_crono cc,
       pessoa cf,
       (SELECT c.cronograma_id,
               c.job_id,
               c.status,
               c.flag_com_aprov
          FROM cronograma c
         WHERE c.status <> 'ARQUI') cr,
       (SELECT b.briefing_id,
               b.job_id,
               b.status,
               b.flag_com_aprov
          FROM briefing b
         WHERE b.status <> 'ARQUI') br,
       (SELECT j.job_id,
               u.usuario_id,
               u.funcao,
               p.apelido
          FROM job_usuario j,
               usuario     u,
               pessoa      p
         WHERE j.usuario_id = u.usuario_id
           AND j.usuario_id = p.usuario_id
           AND j.flag_responsavel = 'S') jp,
       (SELECT c.contrato_id,
               u.funcao,
               p.apelido
          FROM contrato_usuario c,
               usuario          u,
               pessoa           p
         WHERE c.usuario_id = u.usuario_id
           AND c.usuario_id = p.usuario_id
           AND c.flag_responsavel = 'S') ca
 WHERE jo.tipo_job_id = tj.tipo_job_id
   AND jo.cliente_id = pe.pessoa_id
   AND ct.contrato_id(+) = jo.contrato_id
   AND tc.tipo_contrato_id(+) =
       ct.tipo_contrato_id
   AND pc.pessoa_id(+) = jo.contato_id
   AND pr.produto_cliente_id(+) =
       jo.produto_cliente_id
   AND ca.campanha_id(+) = jo.campanha_id
   AND se.servico_id(+) = jo.servico_id
   AND un.unidade_negocio_id(+) =
       jo.unidade_negocio_id
   AND tf.tipo_financeiro_id(+) =
       jo.tipo_financeiro_id
   AND er.pessoa_id(+) = jo.emp_resp_id
   AND cc.contexto_crono_id(+) =
       jo.contexto_crono_id
   AND cf.pessoa_id(+) = jo.contato_fatur_id
   AND cr.job_id(+) = jo.job_id
   AND br.job_id(+) = jo.job_id
   AND jp.job_id(+) = jo.job_id
   AND ca.contrato_id(+) = ct.contrato_id

;
