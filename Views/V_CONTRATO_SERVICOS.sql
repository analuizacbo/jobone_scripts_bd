--------------------------------------------------------
--  DDL for View V_CONTRATO_SERVICOS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CONTRATO_SERVICOS" ("CONTRATO_EMPRESA_ID", "CONTRATO_DATA_ENTRADA", "CONTRATO_RESPONSAVEL", "CONTRATO_NUMERO", "CONTRATO_NOME", "CONTRATO_CLIENTE", "CONTRATO_TIPO_CONTRATO", "CONTRATO_DATA_ASSINATURA", "CONTRATO_VIGENCIA_INICIO", "CONTRATO_VIGENCIA_FIM", "CONTRATO_DURACAO_EM_MESES", "CONTRATO_CODIGO_EXTERNO", "CONTRATO_EMP_FATURAR_POR_ID", "CONTRATO_EMPRESA_FATURAMENTO", "CONTRATO_NUMERO_EXTERNO", "CONTRATO_RENOVAVEL", "CONTRATO_FISICO", "CONTRATO_ASSINADO_S_N", "CONTRATO_STATUS", "CONTRATO_ORDEM_DE_COMPRA", "CONTRATO_COD_EXT_ORDEM", "CONTRATO_CONTATO", "CONTRATO_ID", "CONTRATO_ENDERECADOS", "CONTRATO_DATA_CONCLUSAO", "CONTRATO_COD_EXTERNO", "CONTRATO_DESCRICAO_SERVICOS", "CONTRATO_NUMERO_PARCELAS", "CONTRATO_VALOR_TOTAL_SERVICO", "CONTRATO_STATUS_PARCELAMENTO", "CONTRATO_NUMERO_PARCELAS_FATURADAS", "CONTRATO_QTDE_PARCELAS_PEND", "CONTRATO_COD_EXT_INTEGRACAO", "OPORT_NUMERO", "OPORT_DESCRICAO", "OPORT_PROSPECT", "OPORT_CONFLITO", "OPORT_CLIENTE_CONFLITO_APELIDO", "OPORT_CONTATO_APELIDO", "OPORT_PRODUTO_CLIENTE_NOME", "OPORT_ORIGEM", "OPORT_TIPO_NEGOCIO", "OPORT_COMPL_ORIGEM", "OPORT_TIPO_CONTRATO", "OPORT_DATA_STATUS", "OPORT_STATUS", "OPORT_STATUS_AUXILIAR", "OPORT_ABERTO_POR", "OPORT_DATA_ENTRADA", "OPORT_DATA_FECHAMENTO", "OPORT_RESPONSAVEL_CONDUCAO", "CENARIO_VALOR_SERVICO_EMP_RESP", "OPORT_RESPONSAVEL", "OPORT_UN_RESPONSAVEL") AS 
  SELECT   co.empresa_id                                                                         AS contrato_empresa_id,
         co.data_entrada                                                                       AS contrato_data_entrada,
         DECODE(pr.apelido,NULL,'Não Definido',pr.apelido || ' (' || ur.funcao || ')')         AS contrato_responsavel,
         CONTRATO_PKG.numero_formatar(co.contrato_id)                                          AS contrato_numero,
         co.nome                                                                               AS contrato_nome,
         pt.nome                                                                               AS contrato_cliente,
         tc.nome                                                                               AS contrato_tipo_contrato,
         co.data_assinatura                                                                    AS contrato_data_assinatura,
         co.data_inicio                                                                        AS contrato_vigencia_inicio,
         co.data_termino                                                                       AS contrato_vigencia_fim,
         (SELECT CEIL(MONTHS_BETWEEN(co.data_termino, co.data_inicio)) FROM DUAL)              AS contrato_duracao_em_meses,
         co.cod_ext_contrato                                                                   AS contrato_codigo_externo,
         ce.EMP_FATURAR_POR_ID                                                                 AS contrato_emp_faturar_por_id,
         pf.nome                                                                               AS contrato_empresa_faturamento,
         co.cod_ext_contrato                                                                   AS contrato_numero_externo,
         DECODE(co.flag_renovavel,'S','Sim','N','Não','ND')                                    AS contrato_renovavel,
         DECODE(co.flag_ctr_fisico,'S','Sim','N','Não','ND')                                   AS contrato_fisico,
         DECODE(co.flag_assinado,'S','Sim','N','Não','ND')                                     AS contrato_assinado_s_n,
         dc.descricao                                                                          AS contrato_status,
         co.ordem_compra                                                                       AS contrato_ordem_de_compra,
         co.cod_ext_ordem                                                                      AS contrato_cod_ext_ordem,
         pe.nome                                                                               AS contrato_contato,
         co.contrato_id                                                                        AS contrato_id,
         (SELECT LISTAGG(NVL(TO_CHAR(u.usuario_id),'-'),', ')
                 WITHIN GROUP (ORDER BY u.usuario_id)
            FROM contrato_usuario u WHERE u.contrato_id = co.contrato_id)                      AS contrato_enderecados,
         CASE
           WHEN co.status = 'CONC' THEN co.data_status
           ELSE NULL
         END                                                                                   AS contrato_data_conclusao,
         -- CONTRATO X SERVIÇO
         ce.cod_externo                                                                        AS contrato_cod_externo,
         se.nome                                                                               AS contrato_descricao_servicos,
         (SELECT count(pc.num_parcela)
            FROM parcela_contrato pc
           WHERE pc.contrato_id = co.contrato_id
             AND pc.contrato_servico_id (+) = ce.contrato_servico_id)                          AS contrato_numero_parcelas,
         (SELECT SUM(pc.valor_parcela)
            FROM parcela_contrato pc
           WHERE pc.contrato_id = co.contrato_id
             AND pc.contrato_servico_id (+) = ce.contrato_servico_id)                          AS contrato_valor_total_servico,
         DECODE(co.status_parcel, 'PREP', 'Preparação',
                                  'PRON', 'Pronto',
                                  'NAOI', 'Não informado')                                     AS contrato_status_parcelamento,
         (SELECT COUNT(1)
            FROM parcela_contrato pc
           INNER JOIN contrato_servico  cr ON  cr.contrato_id = pc.contrato_id
                                           AND cr.contrato_servico_id = pc.contrato_servico_id
           INNER JOIN parcela_fatur_ctr pf ON  pf.parcela_contrato_id = pc.parcela_contrato_id
           WHERE pc.contrato_id = co.contrato_id
             AND pc.contrato_servico_id = ce.contrato_servico_id)                              AS contrato_numero_parcelas_faturadas,
         (SELECT COUNT(1)
            FROM parcela_contrato pc
           INNER JOIN contrato_servico  cr ON  cr.contrato_id = pc.contrato_id
                                           AND cr.contrato_servico_id = pc.contrato_servico_id
           WHERE NOT EXISTS (SELECT 1
                               FROM parcela_fatur_ctr pf
                              WHERE pc.parcela_contrato_id = pf.parcela_contrato_id
                                AND cr.contrato_servico_id = pc.contrato_servico_id)
             AND pc.contrato_id         = co.contrato_id
             AND pc.contrato_servico_id = ce.contrato_servico_id)                              AS contrato_qtde_parcelas_pend,
         (SELECT LISTAGG(ce.cod_ext_ctrser, ', ') WITHIN GROUP (ORDER BY ce.cod_ext_ctrser)
            FROM contrato_servico  ce
            INNER JOIN servico      se ON se.servico_id       = ce.servico_id
                                       AND se.flag_ativo = 'S'
           WHERE ce.contrato_id      = co.contrato_id)                                         AS contrato_cod_ext_integracao,
        -- OPORTUNIDADE
        op.numero                                                                              AS oport_numero,
        op.nome                                                                                AS oport_descricao,
        pi.apelido                                                                             AS oport_prospect,
        DECODE(op.flag_conflito,'S','Sim','N','Não','ND')                                      AS oport_conflito,
        cc.apelido                                                                             AS oport_cliente_conflito_apelido,
        ct.apelido                                                                             AS oport_contato_apelido,
        oc.nome                                                                                AS oport_produto_cliente_nome,
        oo.descricao                                                                           AS oport_origem,
        ot.descricao                                                                           AS oport_tipo_negocio,
        op.compl_origem                                                                        AS oport_compl_origem,
        tc.nome                                                                                AS oport_tipo_contrato,
        op.data_status                                                                         AS oport_data_status,
        do.descricao                                                                           AS oport_status,
        ao.nome                                                                                AS oport_status_auxiliar,
        pu.apelido || ' (' || us.funcao || ')'                                                 AS oport_aberto_por,
        op.data_entrada                                                                        AS oport_data_entrada,
        op.data_prov_fech                                                                      AS oport_data_fechamento,
        DECODE(po.apelido,NULL,'Não Definido',po.apelido || ' (' || uo.funcao || ')')          AS oport_responsavel_conducao,
        -- oportunidade x cenario
        ces.valor_servico                                                                      AS cenario_valor_servico_emp_resp,
        DECODE(por.apelido,NULL,'Não Definido',por.apelido || ' (' || uor.funcao || ')')       AS oport_responsavel,
        NVL((SELECT UN.NOME
           FROM UNIDADE_NEGOCIO UN
          WHERE UN.UNIDADE_NEGOCIO_ID = op.unid_negocio_resp_id), '')                          AS oport_un_responsavel
         FROM contrato             co
        INNER JOIN tipo_contrato   tc                                                          ON tc.tipo_contrato_id    = co.tipo_contrato_id
        INNER JOIN usuario         us                                                          ON us.usuario_id          = co.usuario_solic_id
        INNER JOIN dicionario      dc                                                          ON dc.codigo              = co.status                                                                                       AND dc.tipo               = 'status_contrato'
        INNER JOIN contrato_servico ce                                                         ON ce.contrato_id         = co.contrato_id
        INNER JOIN servico          se                                                         ON se.servico_id          = ce.servico_id                                                                                               AND se.flag_ativo         = 'S'
        LEFT JOIN pessoa           ps                                                          ON ps.usuario_id          = us.usuario_id
        LEFT JOIN pessoa           pe                                                          ON pe.pessoa_id           = co.contato_id
        LEFT JOIN pessoa           pf                                                          ON pf.pessoa_id           = ce.emp_faturar_por_id
        LEFT JOIN contrato_usuario cr                                                          ON cr.contrato_id         = co.contrato_id                                                                                          AND cr.flag_responsavel   = 'S'
        LEFT JOIN usuario          ur                                                          ON ur.usuario_id          = cr.usuario_id
        LEFT JOIN pessoa           pr                                                          ON pr.usuario_id          = cr.usuario_id
        LEFT JOIN pessoa           pt                                                          ON pt.pessoa_id           = co.contratante_id
        LEFT JOIN oport_contrato   opc                                                         ON opc.contrato_id        = co.contrato_id
        LEFT JOIN oportunidade     op                                                          ON op.oportunidade_id     = opc.oportunidade_id
        LEFT JOIN pessoa           pi                                                          ON pi.pessoa_id           = op.cliente_id
        LEFT JOIN dicionario       do                                                          ON do.codigo              = op.status                                                                                        AND do.tipo               = 'status_oportunidade'
        LEFT JOIN status_aux_oport ao                                                          ON ao.status_aux_oport_id = op.status_aux_oport_id
        LEFT JOIN pessoa           cc                                                          ON cc.pessoa_id           = op.cliente_conflito_id
        LEFT JOIN pessoa           ct                                                          ON ct.pessoa_id           = op.contato_id
        LEFT JOIN usuario          usr                                                         ON usr.usuario_id         = op.usuario_solic_id
        LEFT JOIN pessoa           pu                                                          ON pu.usuario_id          = usr.usuario_id
        LEFT JOIN oport_usuario    ou                                                          ON ou.oportunidade_id     = op.oportunidade_id                                                                                           AND ou.flag_responsavel   = 'S'
        LEFT JOIN usuario          uo                                                          ON uo.usuario_id          = ou.usuario_id
        LEFT JOIN pessoa           po                                                          ON po.usuario_id          = ou.usuario_id
        LEFT JOIN produto_cliente  oc                                                          ON oc.produto_cliente_id  = op.produto_cliente_id
        LEFT JOIN tipo_contrato    tc                                                          ON tc.tipo_contrato_id    = op.tipo_contrato_id
        LEFT JOIN dicionario       oo                                                          ON oo.codigo              = op.origem                                                                                          AND oo.tipo               = 'oportunidade_origem'
        LEFT JOIN dicionario       ot                                                          ON ot.codigo              = op.tipo_negocio                                                                                           AND ot.tipo               = 'oportunidade_tipo_negocio'
        LEFT JOIN cenario          cn                                                          ON cn.oportunidade_id     = op.oportunidade_id                                                                                           AND cn.flag_padrao        = 'S'
        LEFT JOIN cenario_servico  ces                                                         ON ces.servico_id         = se.servico_id                                                                                        AND ces.cenario_id        = cn.cenario_id
        LEFT JOIN pessoa           por                                                         ON por.usuario_id         = op.usuario_resp_id
        LEFT JOIN usuario          uor                                                         ON uor.usuario_id         = op.usuario_resp_id

;
