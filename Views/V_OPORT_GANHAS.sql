--------------------------------------------------------
--  DDL for View V_OPORT_GANHAS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_OPORT_GANHAS" ("OPORTUNDIADE_ID", "CONTRATO_ID", "OPORT_EMPRESA_GRUPO", "OPORT_CLIENTE", "OPORT_NUMERO", "OPORT_NOME", "OPORT_CENARIO_ESCOLHIDO_NUMERO", "OPORT_CENARIO_ESCOLHIDO_NOME", "OPORT_SERVICOS", "OPORT_NUM_PARCELAS", "OPORT_VALOR", "OPORT_USUARIO_RESPONSAVEL", "OPORT_DATA_ENTRADA", "OPORT_DATA_ATU_STATUS", "OPORT_TIPO_NEGOCIO", "OPORT_ORIGEM", "CONTRATO_NUMERO", "CONTRATO_NOME", "CONTRATO_TIPO", "CONTRATO_USUARIO_RESPONSAVEL", "CONTRATO_DATA_ENTRADA", "CONTRATO_DATA_INICIO", "CONTRATO_DATA_TERMINO", "CONTRATO_RENOVAVEL", "CONTRATO_EMPRESA_RESPONSAVEL", "CONTRATO_CODIGO_EXTERNO", "CONTRATO_UNIDADE_NEGOCIO_USU_RESP", "CONTRATO_STATUS", "CONTRATO_DATA_STATUS") AS 
  SELECT op.oportunidade_id,
         ct.contrato_id,
         ep.nome AS oport_empresa_grupo,
         pe.nome AS oport_cliente,
         op.numero AS oport_numero,
         op.nome AS oport_nome,
         ce.num_cenario AS oport_cenario_escolhido_numero,
         ce.nome AS oport_cenario_escolhido_nome,
         (SELECT LISTAGG(se1.nome,', ') within group (order by se1.nome)
           FROM cenario_servico cs1
                INNER JOIN servico se1 ON se1.servico_id = cs1.servico_id
          WHERE cs1.cenario_id = op.cenario_escolhido_id) AS oport_servicos,
          ce.num_parcelas AS oport_num_parcelas,
          op.valor_oportun AS oport_valor,
          NVL((SELECT pe2.apelido || ' (' || us2.funcao || ') '
            FROM oport_usuario ou2
                 INNER JOIN pessoa pe2 ON pe2.usuario_id = ou2.usuario_id
                 INNER JOIN usuario us2 ON us2.usuario_id = ou2.usuario_id
           WHERE ou2.oportunidade_id = op.oportunidade_id
             AND ou2.flag_responsavel = 'S'),'Não definido') AS oport_usuario_responsavel,
         DATA_MOSTRAR(op.data_entrada) AS oport_data_entrada,
         DATA_MOSTRAR(op.data_status) AS oport_data_atu_status,
         tn.descricao AS oport_tipo_negocio,
         oi.descricao AS oport_origem,
         CONTRATO_PKG.NUMERO_FORMATAR(ct.contrato_id) AS contrato_numero,
         ct.nome AS contrato_nome,
         tc.nome AS contrato_tipo,
         NVL((SELECT LISTAGG(pe3.apelido || ' (' || us3.funcao || ') ',', ') within group (order by pe3.apelido)
            FROM contrato_usuario ou3
                 INNER JOIN pessoa pe3 ON pe3.usuario_id = ou3.usuario_id
                 INNER JOIN usuario us3 ON us3.usuario_id = ou3.usuario_id
           WHERE ou3.contrato_id = ct.contrato_id
             AND ou3.flag_responsavel = 'S'),'Não definido') AS contrato_usuario_responsavel,
         DATA_MOSTRAR(ct.data_entrada) AS contrato_data_abertura,
         DATA_MOSTRAR(ct.data_inicio) AS contrato_data_inicio,
         DATA_MOSTRAR(ct.data_termino) AS contrato_data_termino,
         DECODE(ct.flag_renovavel,'S','Sim','N','Não') AS contrato_renovavel,
         er.apelido AS contrato_empresa_responsavel,
         ct.cod_ext_contrato AS contrato_codigo_externo,
         NVL((SELECT LISTAGG(un4.nome,', ') within group (order by un4.nome)
            FROM contrato_usuario ou4
                 INNER JOIN unidade_negocio_usu uu4 ON uu4.usuario_id = ou4.usuario_id
                 INNER JOIN unidade_negocio un4 ON un4.unidade_negocio_id = uu4.unidade_negocio_id
           WHERE ou4.contrato_id = ct.contrato_id --ct.contrato_id
             AND ou4.flag_responsavel = 'S'),'Não definido') AS contrato_unidade_negocio_usu_resp,
         sc.descricao AS contrato_status,
         DATA_MOSTRAR(ct.data_status) AS contrato_data_status
    FROM oportunidade op
         INNER JOIN oport_contrato oc ON oc.oportunidade_id = op.oportunidade_id
         INNER JOIN contrato ct ON ct.contrato_id = oc.contrato_id
         INNER JOIN empresa ep ON ep.empresa_id = op.empresa_id
         INNER JOIN pessoa pe ON pe.pessoa_id = op.cliente_id
         INNER JOIN cenario ce ON ce.cenario_id = op.cenario_escolhido_id
         INNER JOIN dicionario tn ON tn.codigo = op.tipo_negocio
                                  AND tn.tipo = 'oportunidade_tipo_negocio'
         INNER JOIN dicionario oi ON oi.codigo = op.origem
                                  AND oi.tipo = 'oportunidade_origem'
         INNER JOIN tipo_contrato tc ON tc.tipo_contrato_id = ct.tipo_contrato_id
         INNER JOIN pessoa er ON er.pessoa_id = ct.emp_resp_id
         INNER JOIN dicionario sc ON sc.codigo = ct.status
                                  AND sc.tipo = 'status_contrato'
   WHERE op.status = 'CONC'
     AND op.tipo_conc = 'GAN'

;
