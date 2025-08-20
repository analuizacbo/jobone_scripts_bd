--------------------------------------------------------
--  DDL for View V_OPORTUNIDADES
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_OPORTUNIDADES" ("OPORTUNIDADE_ID", "OPORT_EMPRESA", "OPORT_NUMERO", "OPORT_NOME", "OPORT_CLIENTE_ID", "OPORT_CLIENTE_APELIDO", "OPORT_CLIENTE_CNPJ", "OPORT_CLIENTE_NOME", "OPORT_PRODUTO_CLIENTE_NOME", "OPORT_TIPO_CONTRATO", "OPORT_STATUS", "OPORT_STATUS_AUXILIAR", "OPORT_DATA_STATUS", "OPORT_PRODUTO_CLIENTE_COD_EXT", "OPORT_DATA_ENTRADA", "OPORT_ABERTO_POR", "OPORT_ORIGEM", "OPORT_COMPL_ORIGEM", "OPORT_TIPO_NEGOCIO", "OPORT_CONFLITO", "OPORT_CLIENTE_CONFLITO_APELIDO", "OPORT_CONTATO_APELIDO", "OPORT_PROB_FECHAMENTO", "OPORT_DATA_PROV_FECHAMENTO", "OPORT_DATA_PROV_FECHAMENTO_FMT", "OPORT_ENDERECADOS", "OPORT_DATA_PROX_FOLLOWUP", "OPORT_DATA_PROX_FOLLOWUP_FMT", "OPORT_DATA_ULT_FOLLOWUP", "OPORT_DATA_ULT_FOLLOWUP_FMT", "OPORT_USUARIO_FOLLOWUP", "OPORT_FOLLOWUP_DESCRICAO", "OPORT_FOLLOWUP_MAIOR_90DIAS", "OPORT_CENARIO_NUMERO", "OPORT_CENARIO_NOME", "OPORT_CENARIO_STATUS", "OPORT_CENARIO_STATUS_MARGEM", "OPORT_CENARIO_STATUS_APROV_RC", "OPORT_SERVICOS", "OPORT_VALOR", "OPORT_NUM_PARCELAS", "OPORT_COND_PAGAMENTO", "OPORT_PRAZO_PAGAMENTO", "OPORT_VALOR_PARCELA", "OPORT_TEM_COMISSAO", "OPORT_MOEDA", "OPORT_MOEDA_COTACAO", "OPORT_MOEDA_DATA_COTACAO", "OPORT_DATA_CONCLUSAO", "OPORT_DATA_CONCLUSAO_FMT", "OPORT_CONCLUSAO", "EMPRESA_ID", "OPORT_DATA_GANHA", "OPORT_DATA_CANC", "OPORT_RESPONSAVEL", "OPORT_UN_RESPONSAVEL", "OPORT_POSSUI_CENARIO", "OPORT_PRODUTO_ID", "OPORT_PRODUTO_NOME", "TIPO_NEGOCIO") AS 
  SELECT op.oportunidade_id,
       oe.nome AS oport_empresa,
       op.numero AS oport_numero,
       op.nome AS oport_nome,
       op.cliente_id AS oport_cliente_id,
       co.apelido AS oport_cliente_apelido,
       nvl(co.cnpj, '-') AS oport_cliente_cnpj,
       co.nome AS oport_cliente_nome,
       oc.nome AS oport_produto_cliente_nome,
       tc.nome AS oport_tipo_contrato,
       do.descricao AS oport_status,
       CASE
          WHEN op.status <> 'CONC' THEN ao.nome
          WHEN op.status = 'CONC'  THEN DECODE(op.tipo_conc,'GAN','Ganha','PER','Perdida',NULL)
       ELSE
          NULL
       END AS oport_status_auxiliar,
       op.data_status AS oport_data_status,
       oc.cod_ext_produto AS oport_produto_cliente_cod_ext,
       op.data_entrada AS oport_data_entrada,
       pu.apelido || ' (' || us.funcao || ')' AS oport_aberto_por,
       oo.descricao AS oport_origem,
       op.compl_origem AS oport_compl_origem,
       ot.descricao AS oport_tipo_negocio,
       DECODE(op.flag_conflito,'S','Sim','N','Não','ND') AS oport_conflito,
       cc.apelido AS oport_cliente_conflito_apelido,
       ct.apelido AS oport_contato_apelido,
       it.perc_prob_fech AS oport_prob_fechamento,
       it.data_prov_fech AS oport_data_prov_fechamento,
       DATA_MOSTRAR(it.data_prov_fech) AS oport_data_prov_fechamento_fmt,
       (SELECT listagg('|' || nvl(to_char(u.usuario_id), '-') || '|')
       within GROUP(ORDER BY u.usuario_id)
       FROM   oport_usuario u
       INNER  JOIN pessoa p ON p.usuario_id = u.usuario_id
       WHERE  u.oportunidade_id =  op.oportunidade_id) AS oport_enderecados,
       it.data_prox_int AS oport_data_prox_followup,
       DATA_MOSTRAR(it.data_prox_int) AS oport_data_prox_followup_fmt,
       it.data_interacao AS oport_data_ult_followup,
       DATA_MOSTRAR(it.data_interacao) AS oport_data_ult_followup_fmt,
       pi.apelido || ' (' || ui.funcao || ')' AS oport_usuario_followup,
       it.descricao AS oport_followup_descricao,
       CASE
         WHEN (SYSDATE - it.data_interacao) > 90 THEN 'Sim'
         ELSE 'Não'
       END AS oport_followup_maior_90dias,
       CASE
          WHEN ce.nome IS NULL THEN 'Oportunidade sem Cenário'
          ELSE TO_CHAR(ce.num_cenario)
       END AS oport_cenario_numero,
       CASE
          WHEN ce.nome IS NULL THEN 'Oportunidade sem Cenário'
          ELSE ce.nome
       END AS oport_cenario_nome,
       sce.descricao AS oport_cenario_status,
       smc.descricao AS oport_cenario_status_margem,
       sar.descricao AS oport_cenario_status_aprov_rc,
       (SELECT listagg(gs.nome  || '/' || se.nome, ', ')
           FROM grupo_servico gs
                INNER JOIN servico se ON gs.grupo_servico_id = se.grupo_servico_id
                INNER JOIN cenario_servico cs ON se.servico_id = cs.servico_id
          WHERE cs.cenario_id = ce.cenario_id) AS oport_servicos,
       CASE WHEN
          (SELECT SUM(cs.preco_final)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id) > 0
          THEN
          (SELECT SUM(cs.preco_final)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id)
          ELSE
          (SELECT SUM(cs.valor_servico)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id)
       END AS oport_valor,
       NVL(ce.num_parcelas, 0) AS oport_num_parcelas,
       NVL(ce.cond_pagamento, 0) AS oport_cond_pagamento,
       NVL(ce.prazo_pagamento, 0) AS oport_prazo_pagamento,
       CASE WHEN ce.num_parcelas = 0
          THEN 0
            WHEN
          (SELECT SUM(cs.preco_final)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id) > 0
          THEN
          ROUND(
          (SELECT SUM(cs.preco_final)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id) / ce.num_parcelas,2)
          ELSE
          ROUND(
          (SELECT SUM(cs.valor_servico)
             FROM cenario_servico cs
            WHERE cs.cenario_id = ce.cenario_id) / ce.num_parcelas,2)
       END AS oport_valor_parcela,
       DECODE(ce.flag_comissao_venda,'S','Sim','N','Nâo','ND') AS oport_tem_comissao,
       ce.moeda AS oport_moeda,
       ce.valor_cotacao AS oport_moeda_cotacao,
       ce.data_cotacao AS oport_moeda_data_cotacao,
        CASE
           WHEN op.status = 'CONC' THEN op.data_status
           ELSE NULL
        END AS oport_data_conclusao,
        CASE
           WHEN op.status = 'CONC' THEN DATA_MOSTRAR(op.data_status)
           ELSE NULL
        END AS oport_data_conclusao_fmt,
        DECODE(op.tipo_conc,'GAN','Ganha',
                             'PER','Perdida',
                             'DEC','Declinada',
                             'Sem Oportunidade') AS oport_conclusao,
        oe.empresa_id,
        CASE
          WHEN op.status = 'CONC'
           AND op.tipo_conc = 'GAN' THEN op.data_status
          ELSE NULL
        END AS oport_data_ganha,
        CASE
          WHEN op.status = 'CANC' THEN op.data_status
          ELSE NULL
        END AS oport_data_canc,
        DECODE(po.apelido,NULL,'Não Definido',
                        po.apelido || ' (' || uo.funcao || ')') AS oport_responsavel,
        NVL((SELECT UN.NOME
           FROM UNIDADE_NEGOCIO UN
          WHERE UN.UNIDADE_NEGOCIO_ID = op.UNID_NEGOCIO_RESP_ID),'') AS oport_un_responsavel,
        NVL2(ce.nome, 'Sim', 'Não') AS oport_possui_cenario,
        (SELECT listagg(gs.grupo_servico_id, ', ')
           FROM grupo_servico gs
                INNER JOIN servico se ON gs.grupo_servico_id = se.grupo_servico_id
                INNER JOIN cenario_servico cs ON se.servico_id = cs.servico_id
          WHERE cs.cenario_id = ce.cenario_id) as oport_produto_id,
        (SELECT LISTAGG(gs.nome, ', ') WITHIN GROUP (ORDER BY gs.nome)
           FROM grupo_servico gs
                INNER JOIN servico se ON gs.grupo_servico_id = se.grupo_servico_id
                INNER JOIN cenario_servico cs ON se.servico_id = cs.servico_id
          WHERE cs.cenario_id = ce.cenario_id) as oport_produto_nome,
          op.tipo_negocio
    FROM oportunidade op
         INNER JOIN empresa oe ON oe.empresa_id = op.empresa_id
         --cliente da oportunidade
         INNER JOIN pessoa co ON co.pessoa_id = op.cliente_id
         INNER JOIN dicionario do ON do.codigo = op.status
                    AND do.tipo = 'status_oportunidade'
         --contato oportunidade
         INNER JOIN pessoa ct ON ct.pessoa_id = op.contato_id
         INNER JOIN usuario us ON us.usuario_id = op.usuario_solic_id
         INNER JOIN pessoa pu ON pu.usuario_id = us.usuario_id
         INNER JOIN produto_cliente oc ON oc.produto_cliente_id = op.produto_cliente_id
         INNER JOIN tipo_contrato tc ON tc.tipo_contrato_id = op.tipo_contrato_id
         LEFT JOIN dicionario oo ON oo.codigo = op.origem
                    AND oo.tipo = 'oportunidade_origem'
         LEFT JOIN dicionario ot ON ot.codigo = op.tipo_negocio
                    AND ot.tipo = 'oportunidade_tipo_negocio'
         INNER JOIN interacao it ON it.interacao_id = (SELECT MAX(i.interacao_id)
                                                         FROM interacao i
                                                        WHERE i.oportunidade_id = op.oportunidade_id)
         --usuario_responsavel
         INNER JOIN usuario ui ON ui.usuario_id = it.usuario_resp_id
         INNER JOIN pessoa pi ON pi.usuario_id = ui.usuario_id
         --cenario padrão da oportunidade
         LEFT JOIN cenario ce ON ce.oportunidade_id = op.oportunidade_id
                   AND ce.flag_padrao = 'S'
         --status_cenario
         LEFT JOIN dicionario sce ON sce.codigo = ce.status
                    AND sce.tipo = 'status_cenario'
         --status_margem_cenario
         LEFT JOIN dicionario smc ON smc.codigo = ce.status_margem
                    AND smc.tipo = 'status_margem_cen'
         --sattus_aprovacao_rate_card_cenario
         LEFT JOIN dicionario sar ON sar.codigo = ce.status_aprov_rc
                    AND sar.tipo = 'status_aprov_rc'
         --cliente da oportunidade
         LEFT JOIN status_aux_oport  ao ON ao.status_aux_oport_id = op.status_aux_oport_id
         LEFT JOIN pessoa cc ON cc.pessoa_id = op.cliente_conflito_id
         LEFT JOIN oport_usuario ou ON ou.oportunidade_id = op.oportunidade_id
                   AND ou.flag_responsavel = 'S'
         LEFT JOIN usuario uo ON uo.usuario_id = op.usuario_resp_id
         LEFT JOIN pessoa po ON po.usuario_id = op.usuario_resp_id

;
