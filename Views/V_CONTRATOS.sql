--------------------------------------------------------
--  DDL for View V_CONTRATOS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CONTRATOS" ("OPORT_NUMERO", "OPORT_NOME", "OPORT_PROSPECT", "OPORT_PRODUTO_CLIENTE_NOME", "OPORT_TIPO_CONTRATO", "OPORT_STATUS", "OPORT_STATUS_AUXILIAR", "OPORT_DATA_STATUS", "OPORT_SERVICOS", "OPORT_VALOR_SERVICOS", "OPORT_STATUS_FMT", "OPORT_DATA_ENTRADA", "OPORT_DATA_ENTRADA_FMT", "OPORT_ABERTO_POR", "OPORT_RESPONSAVEL", "OPORT_ORIGEM", "OPORT_COMPL_ORIGEM", "OPORT_TIPO_NEGOCIO", "OPORT_CONFLITO", "OPORT_CLIENTE_CONFLITO_APELIDO", "OPORT_CONTATO_APELIDO", "OPORT_NUM_PARCELAS", "OPORT_VALOR_PARCELA", "OPORT_DATA_CONCLUSAO", "CONTRATO_NUMERO", "CONTRATO_NOME", "CONTRATO_TIPO_CONTRATO", "CONTRATO_STATUS", "CONTRATO_ID", "CONTRATO_ASSINADO_S_N", "CONTRATO_FISICO", "CONTRATO_DATA_ASSINATURA", "CONTRATO_NUMERO_EXTERNO", "CONTRATO_CONTRATANTE", "CONTRATO_CNPJ", "CONTRATO_VIGENCIA_INICIO", "CONTRATO_VIGENCIA_FIM", "CONTRATO_DURACAO_EM_MESES", "CONTRATO_RENOVAVEL", "CONTRATO_ORDEM_DE_COMPRA", "CONTRATO_EMP_FATURAR_POR_ID", "CONTRATO_EMPRESA_FATURAMENTO", "CONTRATO_COD_EXT_ORDEM", "CONTRATO_SOLICITANTE", "CONTRATO_RESPONSAVEL", "CONTRATO_ENDERECADOS", "CONTRATO_DATA_CONCLUSAO", "CONTRATO_DATA_CANCELAMENTO", "CONTRATO_TIPO_DE_CONTRATO", "CONTRATO_SERVICOS", "CONTRATO_NUMERO_PARCELAS", "CONTRATO_NUMERO_PARCELAS_FATURADAS", "CONTRATO_CONTATO", "EMPRESA_ID", "PRECIF_PROPOSTA_VERIF", "INFO_CLI_VERIF", "INFO_FIS_CLI_VERIF", "HORAS_VERIF", "ALOC_USUARIO_FEITA", "UNIDADE_NEGOCIO_RESP_CONTRATO", "PRECIF_PROPOSTA_STATUS", "INFO_CLIENTE_STATUS", "INFO_FISCAL_CLIENTE_STATUS", "HORAS_VENDIDAS_STATUS", "CONTRATO_FISICO_STATUS", "CONTRATO_FISICO_STATUS_DET", "ALOC_USUARIO_STATUS", "PARCELAMENTO_STATUS", "PRECIF_PROPOSTA_PRAZO", "INFO_CLIENTE_PRAZO", "INFO_FISCAL_CLIENTE_FISC", "VERIF_HORA_PRAZO", "CONTRATO_FISICO_PRAZO", "CONTRATO_FISICO_PRAZO_ACAO", "ALOC_USUARIO_PRAZO", "PARCELAMENTO_PRAZO", "PRECIF_PROPOSTA_PRAZO_COR", "INFO_CLIENTE_PRAZO_COR", "INFO_FISCAL_CLIENTE_FISC_COR", "VERIF_HORA_PRAZO_COR", "CONTRATO_FISICO_PRAZO_COR", "CONTRATO_FISICO_PRAZO_ACAO_COR", "ALOC_USUARIO_PRAZO_COR", "PARCELAMENTO_PRAZO_COR", "RENOVACAO", "VIGENCIA", "GRUPO_PRODUTO_ID", "GRUPO_PRODUTO_NOME", "VALOR_TOTAL_CONTRATO") AS 
  SELECT op.numero AS oport_numero,
       op.nome AS oport_nome,
       pi.apelido AS oport_prospect,
       oc.nome AS oport_produto_cliente_nome,
       decode(op.numero, NULL, NULL, tc.nome) AS oport_tipo_contrato,
       do.descricao AS oport_status,
       CASE
        WHEN op.status <> 'CONC' THEN
         ao.nome
        WHEN op.status = 'CONC' THEN
         decode(op.tipo_conc, 'GAN', 'Ganha', 'PER', 'Perdida', NULL)
        ELSE
         NULL
       END AS oport_status_auxiliar,
       op.data_status AS oport_data_status,
       (SELECT listagg(se.nome, ', ') within GROUP(ORDER BY se.nome)
          FROM oport_servico oe
         INNER JOIN servico se
            ON se.servico_id = oe.servico_id
           AND se.flag_ativo = 'S'
         WHERE oe.oportunidade_id = op.oportunidade_id) AS oport_servicos,
       (SELECT CASE
                WHEN SUM(cs.preco_final) <> 0 THEN
                 SUM(cs.preco_final)
                ELSE
                 SUM(cs.valor_servico)
               END AS oport_valor_servicos
          FROM cenario_servico cs
         WHERE cs.cenario_id = op.cenario_escolhido_id ) AS oport_valor_servicos,
       data_mostrar(op.data_status) AS oport_status_fmt,
       op.data_entrada AS oport_data_entrada,
       data_mostrar(op.data_entrada) AS oport_data_entrada_fmt,
       decode(pu.apelido, NULL, NULL, us.funcao, NULL, NULL, pu.apelido || ' (' || us.funcao || ')') AS oport_aberto_por,
       decode(po.apelido, NULL, NULL, po.apelido || ' (' || uo.funcao || ')') AS oport_responsavel,
       oo.descricao AS oport_origem,
       op.compl_origem AS oport_compl_origem,
       ot.descricao AS oport_tipo_negocio,
       decode(op.flag_conflito, 'S', 'Sim', 'N', 'Não', 'ND') AS oport_conflito,
       cc.apelido AS oport_cliente_conflito_apelido,
       ct.apelido AS oport_contato_apelido,
       ce.num_parcelas AS oport_num_parcelas,
       case WHEN ce.num_parcelas <> 0 THEN
       round((SELECT SUM(c.valor_servico)
                FROM cenario_servico c
               WHERE c.cenario_id = ce.cenario_id) / ce.num_parcelas,
             2)END AS oport_valor_parcela,
       CASE
        WHEN op.status = 'CONC' THEN
         op.data_status
        ELSE
         NULL
       END AS oport_data_conclusao,
       nvl(contrato_pkg.numero_formatar(co.contrato_id), '') AS contrato_numero,
       co.nome AS contrato_nome,
       tc.nome AS contrato_tipo_contrato,
       dc.descricao AS contrato_status,
       co.contrato_id AS contrato_id,
       decode(co.flag_assinado, 'S', 'Sim', 'N', 'Não', 'ND') AS contrato_assinado_s_n,
       decode(co.flag_ctr_fisico, 'S', 'Sim', 'N', 'Não', 'ND') AS contrato_fisico,
       co.data_assinatura AS contrato_data_assinatura,
       co.cod_ext_contrato AS contrato_numero_externo,
       pt.nome AS contrato_contratante,
       pt.cnpj AS contrato_cnpj,
       co.data_inicio AS contrato_vigencia_inicio,
       co.data_termino AS contrato_vigencia_fim,
      (SELECT ceil(months_between(co.data_termino, data_inicio))
          FROM dual) AS contrato_duracao_em_meses,
       decode(co.flag_renovavel, 'S', 'Sim', 'N', 'Não', 'ND') AS contrato_renovavel,
       co.ordem_compra AS contrato_ordem_de_compra,
       co.emp_faturar_por_id AS contrato_emp_faturar_por_id,
       pf.nome AS contrato_empresa_faturamento,
       co.cod_ext_ordem AS contrato_cod_ext_ordem,
       decode(ps.apelido, NULL, 'Não Definido', ps.apelido || ' (' || us.funcao || ')') AS contrato_solicitante,
       decode(pr.apelido, NULL, 'Não Definido', pr.apelido || ' (' || ur.funcao || ')') AS contrato_responsavel,
       (SELECT listagg(nvl(to_char(u.usuario_id), '-'), ', ') within GROUP(ORDER BY u.usuario_id)
          FROM contrato_usuario u
         WHERE u.contrato_id = co.contrato_id) AS contrato_enderecados,
       CASE
        WHEN co.status = 'CONC' THEN
         co.data_status
        ELSE
         NULL
       END AS contrato_data_conclusao,
       CASE
        WHEN co.status = 'CANC' THEN
         co.data_status
        ELSE
         NULL
       END AS contrato_data_cancelamento,
       tc.nome AS contrato_tipo_de_contrato,
       (SELECT listagg(se.nome, ', ') within GROUP(ORDER BY se.nome)
          FROM contrato_servico ce
         INNER JOIN servico se
            ON se.servico_id = ce.servico_id
           AND se.flag_ativo = 'S'
         WHERE ce.contrato_id = co.contrato_id) AS contrato_servicos,
       (SELECT COUNT(1)
          FROM parcela_contrato pc
         WHERE pc.contrato_id = co.contrato_id) AS contrato_numero_parcelas,
       (SELECT COUNT(1)
          FROM parcela_contrato pc
         INNER JOIN parcela_fatur_ctr pf
            ON pf.parcela_contrato_id = pc.parcela_contrato_id
         WHERE pc.contrato_id = co.contrato_id) AS contrato_numero_parcelas_faturadas,
       pe.nome AS contrato_contato,
       co.empresa_id,
       tc.flag_verifi_precif AS precif_proposta_verif,
       pt.flag_cad_verif AS info_cli_verif,
       pt.flag_fis_verif AS info_fis_cli_verif,
       tc.flag_verifi_horas AS horas_verif,
       tc.flag_aloc_usuario AS aloc_usuario_feita,
       (SELECT MIN(un.nome)
          FROM unidade_negocio     un,
               unidade_negocio_usu us
         WHERE un.unidade_negocio_id = us.unidade_negocio_id
           AND us.usuario_id = ur.usuario_id) AS unidade_negocio_resp_contrato,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'PREC') AS precif_proposta_status,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'CLIE') AS info_cliente_status,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'FISC') AS info_fiscal_cliente_status,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'HORA') AS horas_vendidas_status,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'FISI') AS contrato_fisico_status,
       (SELECT CASE max(f.status)
                WHEN 'EMAP' THEN
                 'Pendente Aprovação'
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'REPR' THEN
                 'Reprovado'
                WHEN 'FASS' THEN
                 'Assinado'
                WHEN 'PASS' THEN
                 'Aguardando Assinatura'
                WHEN 'APRO' THEN
                 'Aprovado'
                WHEN 'NASS' THEN
                 'Não será Assinado'
               END
          FROM contrato_fisico f,
               (SELECT cf.contrato_id,
                       MAX(cf.versao) AS versao
                  FROM contrato_fisico cf
                 GROUP BY cf.contrato_id) f2
         WHERE f.contrato_id = co.contrato_id
           AND f.contrato_id = f2.contrato_id
           AND f.versao = f2.versao) AS contrato_fisico_status_det,
       (SELECT CASE e.status
                WHEN 'PEND' THEN
                 'Pendente'
                WHEN 'PRON' THEN
                 'Feito'
                WHEN 'NFEI' THEN
                 'Não será Feito'
               END
          FROM contrato_elab e
         WHERE e.contrato_id = co.contrato_id
           AND e.cod_contrato_elab = 'ALOC') AS aloc_usuario_status,
       decode(co.status_parcel, 'NAOI', 'Não Iniciado', 'PREP', 'Pendente', 'PRON', 'Feito') AS parcelamento_status,
       (SELECT to_date(decode(el.status, 'PEND', data_mostrar(el.data_prazo), NULL), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'PREC') AS precif_proposta_prazo,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'CLIE') AS info_cliente_prazo,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'FISC') AS info_fiscal_cliente_fisc,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'HORA') AS verif_hora_prazo,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'FISI') AS contrato_fisico_prazo,
       (SELECT to_date(data_mostrar(max(f.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_fisico f,
               (SELECT cf.contrato_id,
                       MAX(cf.versao) AS versao
                  FROM contrato_fisico cf
                 GROUP BY cf.contrato_id) f2
         WHERE f.contrato_id = co.contrato_id
           AND f.contrato_id = f2.contrato_id
           AND f.versao = f2.versao) AS contrato_fisico_prazo_acao,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'ALOC') AS aloc_usuario_prazo,
       (SELECT to_date(decode(el.status, 'PRON', NULL, data_mostrar(el.data_prazo)), 'DD/MM/YYYY')
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'PARC') AS parcelamento_prazo,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'PREC') AS precif_proposta_prazo_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'CLIE') AS info_cliente_prazo_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'FISC') AS info_fiscal_cliente_fisc_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'HORA') AS verif_hora_prazo_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'FISI') AS contrato_fisico_prazo_cor,
       (SELECT CASE
                WHEN MAX(f.data_prazo) < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN MAX(f.data_prazo) = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_fisico f
         WHERE f.contrato_id = co.contrato_id) AS contrato_fisico_prazo_acao_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'ALOC') AS aloc_usuario_prazo_cor,
       (SELECT CASE
                WHEN el.data_prazo < trunc(SYSDATE) THEN
                 'vermelho'
                WHEN el.data_prazo = trunc(SYSDATE) THEN
                 'amarelo'
                ELSE
                 'branco'
               END
          FROM contrato_elab el
         WHERE el.contrato_id = co.contrato_id
           AND el.cod_contrato_elab = 'PARC') AS parcelamento_prazo_cor,
       (SELECT data_converter(data_mostrar(co2.data_termino - (SELECT empresa_pkg.parametro_retornar(co.empresa_id,
                                                                                                     'NUM_DIAS_NOTIF_RENOV_CTR')
                                                                 FROM dual)))
          FROM contrato co2
         WHERE co2.contrato_id = co.contrato_id) AS renovacao,
       (SELECT abs(to_date(co2.data_termino) - to_date(SYSDATE))
          FROM contrato co2
         WHERE co2.contrato_id = co.contrato_id) AS vigencia,
       (SELECT listagg(grupo_servico_id, ', ') within GROUP(ORDER BY grupo_servico_id)
          FROM (SELECT DISTINCT gs.grupo_servico_id
                  FROM grupo_servico gs
                  LEFT JOIN servico se
                    ON gs.grupo_servico_id = se.grupo_servico_id
                 INNER JOIN contrato_servico ce
                    ON se.servico_id = ce.servico_id
                   AND ce.contrato_id = co.contrato_id)) AS grupo_produto_id,
       (SELECT listagg(nome, ', ') within GROUP(ORDER BY nome)
          FROM (SELECT DISTINCT gs.nome
                  FROM grupo_servico gs
                  LEFT JOIN servico se
                    ON gs.grupo_servico_id = se.grupo_servico_id
                 INNER JOIN contrato_servico ce
                    ON se.servico_id = ce.servico_id
                   AND ce.contrato_id = co.contrato_id)) AS grupo_produto_nome,
                   (SELECT SUM(ch.horas_planej *
UTIL_PKG.NUM_DECODE(venda_hora_rev,
'C06C35872C9B409A8AB38C7A7E360F3C'))
FROM contrato_horas ch
WHERE contrato_servico_id IN (SELECT contrato_servico_id
                        FROM contrato_servico
                        WHERE contrato_id = co.contrato_id)) AS valor_total_contrato

  FROM contrato co
 INNER JOIN tipo_contrato tc
    ON tc.tipo_contrato_id = co.tipo_contrato_id
 INNER JOIN dicionario dc
    ON dc.codigo = co.status
   AND dc.tipo = 'status_contrato'
 INNER JOIN usuario us
    ON us.usuario_id = co.usuario_solic_id
 INNER JOIN pessoa ps
    ON ps.usuario_id = us.usuario_id
  LEFT JOIN pessoa pe
    ON pe.pessoa_id = co.contato_id
  LEFT JOIN pessoa pt
    ON pt.pessoa_id = co.contratante_id
  LEFT JOIN pessoa pf
    ON pf.pessoa_id = co.emp_faturar_por_id
  LEFT JOIN contrato_usuario cr
    ON cr.contrato_id = co.contrato_id
   AND cr.flag_responsavel = 'S'
  LEFT JOIN usuario ur
    ON ur.usuario_id = cr.usuario_id
  LEFT JOIN pessoa pr
    ON pr.usuario_id = cr.usuario_id
  LEFT JOIN oport_contrato opc
    ON opc.contrato_id = co.contrato_id
  LEFT JOIN oportunidade op
    ON op.oportunidade_id = opc.oportunidade_id
  LEFT JOIN pessoa pi
    ON pi.pessoa_id = op.cliente_id
  LEFT JOIN dicionario do
    ON do.codigo = op.status
   AND do.tipo = 'status_oportunidade'
  LEFT JOIN status_aux_oport ao
    ON ao.status_aux_oport_id = op.status_aux_oport_id
  LEFT JOIN pessoa cc
    ON cc.pessoa_id = op.cliente_conflito_id
  LEFT JOIN pessoa ct
    ON ct.pessoa_id = op.contato_id
  LEFT JOIN usuario usr
    ON usr.usuario_id = op.usuario_solic_id
  LEFT JOIN pessoa pu
    ON pu.usuario_id = usr.usuario_id
  LEFT JOIN oport_usuario ou
    ON ou.oportunidade_id = op.oportunidade_id
   AND ou.flag_responsavel = 'S'
  LEFT JOIN usuario uo
    ON uo.usuario_id = ou.usuario_id
  LEFT JOIN pessoa po
    ON po.usuario_id = ou.usuario_id
  LEFT JOIN produto_cliente oc
    ON oc.produto_cliente_id = op.produto_cliente_id
  LEFT JOIN tipo_contrato tc
    ON tc.tipo_contrato_id = op.tipo_contrato_id
  LEFT JOIN dicionario oo
    ON oo.codigo = op.origem
   AND oo.tipo = 'oportunidade_origem'
  LEFT JOIN dicionario ot
    ON ot.codigo = op.tipo_negocio
   AND ot.tipo = 'oportunidade_tipo_negocio'
  LEFT JOIN cenario ce
    ON ce.oportunidade_id = op.oportunidade_id
   AND ce.flag_padrao = 'S'
;
