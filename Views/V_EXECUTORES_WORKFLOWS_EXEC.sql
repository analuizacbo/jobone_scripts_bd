--------------------------------------------------------
--  DDL for View V_EXECUTORES_WORKFLOWS_EXEC
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_EXECUTORES_WORKFLOWS_EXEC" ("EMPRESA_ID", "JOB_ID", "ORDEM_SERVICO_ID", "CLIENTE", "JOB", "PRODUTO_CLIENTE", "ENTREGA", "TIPO_ENTREGA", "REFACAO", "STATUS", "ITEM", "COMPLEMENTO", "DATA_ENVIO_FMT", "DATA_HORA_ENVIO_FMT", "DATA_ENVIO", "PRAZO_SOLICITADO_FMT", "PRAZO_HORA_SOLICITADO_FMT", "PRAZO_INTERNO_FMT", "PRAZO_INTERNO", "PRAZO_HORA_INTERNO_FMT", "PRAZO_SOLICITADO", "DATA_TERMINO_EXECUCAO_FMT", "DATA_HORA_TERMINO_EXECUCAO_FMT", "DATA_TERMINO_EXECUCAO", "DIAS_PRAZO", "DIAS_ATRASO", "DIAS_TERMINO_EXECUCAO", "USUARIO_EXE", "FUNCAO", "HORAS_TOTAIS", "MOTIVO_RECUSA", "COMPLEMENTO_RECUSA", "ORIGEM_RECUSA", "QUANTIDADE", "HORAS_ESTIMADAS", "DATA_DIST", "AVAL_SOLICITACAO", "AVAL_EXECUCAO", "USUARIO_SOL", "UNIDADE_NEGOCIO_PROJETO_NOME") AS 
  SELECT jo.empresa_id,
       jo.job_id,
       os.ordem_servico_id,
       cl.apelido AS cliente,
       NVL(jo.numero || ' ' || jo.nome,'-') AS job,
       pc.nome AS produto_cliente,
       ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id) || ' ' || os.descricao AS entrega,
       ts.nome AS tipo_entrega,
       re.num_refacao as refacao,
       CASE os.qtd_refacao
          WHEN re.num_refacao THEN dos.descricao
          ELSE 'Concluido'
       END AS status,
       (SELECT LISTAGG(nome,', ') WITHIN GROUP (ORDER BY nome || complemento)
          FROM
              (SELECT DISTINCT tp.nome, ji.complemento
                 FROM os_tipo_produto_ref oir
                 LEFT JOIN job_tipo_produto ji ON ji.job_tipo_produto_id = oir.job_tipo_produto_id
                 LEFT JOIN tipo_produto tp ON tp.tipo_produto_id = ji.tipo_produto_id
                WHERE oir.ordem_servico_id = os.ordem_servico_id)) AS item,
       (SELECT LISTAGG(complemento,', ') WITHIN GROUP (ORDER BY nome || complemento)
          FROM
              (SELECT DISTINCT tp.nome, ji.complemento
                 FROM os_tipo_produto_ref oir
                 LEFT JOIN job_tipo_produto ji ON ji.job_tipo_produto_id = oir.job_tipo_produto_id
                 LEFT JOIN tipo_produto tp ON tp.tipo_produto_id = ji.tipo_produto_id
                WHERE oir.ordem_servico_id = os.ordem_servico_id)) AS complemento,
         DATA_MOSTRAR((SELECT MIN(data_envio) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS data_envio_fmt,
         DATA_HORA_MOSTRAR((SELECT MIN(data_envio) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS data_hora_envio_fmt,
         (SELECT MIN(data_envio) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS data_envio,
         DATA_MOSTRAR((SELECT MAX(data_solicitada) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS prazo_solicitado_fmt,
         DATA_HORA_MOSTRAR((SELECT MAX(data_solicitada) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS prazo_hora_solicitado_fmt,
         DATA_MOSTRAR((SELECT MAX(data_interna) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS prazo_interno_fmt,
     (SELECT MAX(data_interna) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS prazo_interno,
         DATA_HORA_MOSTRAR((SELECT MAX(data_interna) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id)) AS prazo_hora_interno_fmt,
         (SELECT MAX(data_solicitada) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS prazo_solicitado,
         DATA_MOSTRAR(re.data_termino_exec) AS data_termino_execucao_fmt,
         DATA_HORA_MOSTRAR(re.data_termino_exec) AS data_hora_termino_execucao_fmt,
         re.data_termino_exec AS data_termino_execucao,
         (SELECT SUM(dias_prazo_solicitado) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS dias_prazo,
         (SELECT SUM(dias_atraso_solicitado) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS dias_atraso,
         (SELECT SUM(dias_termino_exec) FROM os_refacao WHERE ordem_servico_id = os.ordem_servico_id) AS dias_termino_execucao,
         pu.apelido AS usuario_exe,
         us.funcao,
         (SELECT NVL(SUM(h.horas),0)
            FROM apontam_hora h
                 INNER JOIN apontam_data d ON d.apontam_data_id = h.apontam_data_id
           WHERE h.ordem_servico_id = os.ordem_servico_id
             AND d.usuario_id = ou.usuario_id) AS horas_totais,
         oe.motivo as motivo_recusa,
         oe.comentario as complemento_recusa,
         (SELECT DESCRICAO
            FROM DICIONARIO
           WHERE TIPO='tipo_cliente_agencia'
             AND CODIGO = OE.TIPO_CLIENTE_AGENCIA) AS ORIGEM_RECUSA,
         (SELECT SUM(ot.quantidade)
            FROM os_tipo_produto ot
           WHERE ot.ordem_servico_id = os.ordem_servico_id) as quantidade,
         uf.horas_planej AS horas_estimadas,
       CASE
          WHEN oe.status_para = 'PREP' OR oe.status_para = 'DIST' THEN NULL
          WHEN oe.status_para <> 'PREP' OR oe.status_para <> 'DIST' THEN
             (SELECT MAX(e.data_evento)
                FROM os_evento e
               WHERE e.ordem_servico_id = ou.ordem_servico_id
                 AND e.num_refacao      = re.num_refacao
                 AND e.flag_estim = 'N'
                 AND ((e.status_de = 'DIST' AND e.status_para = 'ACEI') OR
                     (e.status_de = 'DIST' AND e.status_para = 'EMEX')))
         ELSE NULL
       END AS data_dist,
       uf.nota_aval as aval_solicitacao,
       (SELECT UR.NOTA_AVAL
          FROM OS_USUARIO_REFACAO UR,
               USUARIO U
         WHERE UR.ORDEM_SERVICO_ID = os.ordem_servico_id
           AND UR.NUM_REFACAO      = RE.NUM_REFACAO
           AND UR.USUARIO_ID       = U.USUARIO_ID
           AND UR.TIPO_ENDER       = 'SOL') as aval_execucao,
       (SELECT P.APELIDO
          FROM OS_USUARIO_REFACAO UR,
               USUARIO U,
               PESSOA  P
         WHERE UR.ORDEM_SERVICO_ID = os.ordem_servico_id
           AND UR.NUM_REFACAO      = RE.NUM_REFACAO
           AND UR.USUARIO_ID       = U.USUARIO_ID
           AND UR.USUARIO_ID       = P.USUARIO_ID
           AND UR.TIPO_ENDER       = 'SOL'
           ) as usuario_sol,
         un.nome as unidade_negocio_projeto_nome
         FROM os_evento oe
         INNER JOIN ordem_servico os ON oe.ordem_servico_id = os.ordem_servico_id
                                     AND os.OS_EVENTO_ID = oe.os_evento_id
         INNER JOIN tipo_os ts ON ts.tipo_os_id = os.tipo_os_id
         INNER JOIN job jo ON jo.job_id = os.job_id
         INNER JOIN pessoa cl ON cl.pessoa_id = jo.cliente_id
         INNER JOIN produto_cliente pc ON pc.produto_cliente_id = jo.produto_cliente_id
         INNER JOIN dicionario dos     ON dos.codigo = os.status
                                       AND dos.tipo = 'status_os'
         INNER JOIN os_usuario ou ON ou.ordem_servico_id = os.ordem_servico_id
                                     AND ou.tipo_ender = 'EXE'
         INNER JOIN usuario us ON us.usuario_id = ou.usuario_id
         INNER JOIN os_refacao re ON re.ordem_servico_id = os.ordem_servico_id
         LEFT  JOIN os_usuario_refacao uf ON  uf.ordem_servico_id = re.ordem_servico_id
                                          AND uf.num_refacao      = re.num_refacao
                                          AND uf.tipo_ender       = 'EXE'
         LEFT JOIN pessoa pu  ON pu.usuario_id = us.usuario_id
         LEFT JOIN unidade_negocio un ON un.unidade_negocio_id = jo.unidade_negocio_id
         WHERE ou.usuario_id = us.usuario_id

;
