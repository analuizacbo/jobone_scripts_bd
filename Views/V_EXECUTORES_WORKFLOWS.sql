--------------------------------------------------------
--  DDL for View V_EXECUTORES_WORKFLOWS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_EXECUTORES_WORKFLOWS" ("EMPRESA_ID", "JOB_ID", "ORDEM_SERVICO_ID", "CLIENTE", "JOB", "PRODUTO_CLIENTE", "ENTREGA", "TIPO_ENTREGA", "REFACAO", "COMPLEX_REFACAO", "STATUS", "TIPO_PRODUTO", "COMPLEMENTO", "DATA_ENVIO_FMT", "DATA_HORA_ENVIO_FMT", "DATA_ENVIO", "PRAZO_SOLICITADO_FMT", "PRAZO_HORA_SOLICITADO_FMT", "PRAZO_SOLICITADO", "PRAZO_HORA_INTERNO_FMT", "PRAZO_INTERNO", "DATA_TERMINO_EXECUCAO_FMT", "DATA_HORA_TERMINO_EXECUCAO_FMT", "DATA_TERMINO_EXECUCAO", "DIAS_PRAZO", "DIAS_ATRASO", "DIAS_TERMINO_EXECUCAO", "EXECUTORES", "HORAS_TOTAIS", "MOTIVO_RECUSA", "COMPLEMENTO_RECUSA", "ORIGEM_RECUSA", "QUANTIDADE", "USUARIO_SOL", "UNIDADE_NEGOCIO_PROJETO_NOME") AS 
  SELECT jo.empresa_id,
         jo.job_id,
         os.ordem_servico_id,
         cl.apelido AS cliente,
         NVL(jo.numero || ' ' || jo.nome,'-') AS job,
         pc.nome AS produto_cliente,
         ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id) || ' ' || os.descricao AS entrega,
         ts.nome AS tipo_entrega,
         oe.num_refacao AS refacao,
         oe.complex_refacao,
         dos.descricao AS status,
         tp.nome AS tipo_produto,
         ji.complemento AS complemento,
         DATA_MOSTRAR(osr.data_envio) AS data_envio_fmt,
         DATA_HORA_MOSTRAR(osr.data_envio) AS data_hora_envio_fmt,
         osr.data_envio,
         DATA_MOSTRAR(osr.data_solicitada) AS prazo_solicitado_fmt,
         DATA_HORA_MOSTRAR(osr.data_solicitada) AS prazo_hora_solicitado_fmt,
         osr.data_solicitada AS prazo_solicitado,
         DATA_HORA_MOSTRAR(osr.data_interna) AS prazo_hora_interno_fmt,
         osr.data_interna AS prazo_interno,
         DATA_MOSTRAR(osr.data_termino_exec) AS data_termino_execucao_fmt,
         DATA_HORA_MOSTRAR(osr.data_termino_exec) AS data_hora_termino_execucao_fmt,
         osr.data_termino_exec AS data_termino_execucao,
         osr.dias_prazo_solicitado AS dias_prazo,
         osr.dias_atraso_solicitado AS dias_atraso,
         osr.DIAS_TERMINO_EXEC AS dias_termino_execucao,
         (SELECT NVL(LISTAGG(p.apelido || ' (' ||
            (SELECT NVL(SUM(h.horas),0)
               FROM apontam_data d
                    LEFT JOIN apontam_hora h ON d.apontam_data_id = h.apontam_data_id
              WHERE d.usuario_id = u.usuario_id
                AND h.ordem_servico_id = os.ordem_servico_id) || ' horas)'
            ,', ') within group (order by p.apelido),'Não Definido')
            FROM os_usuario i
                 INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                 INNER JOIN usuario u on u.usuario_id = p.usuario_id
           WHERE i.ordem_servico_id = os.ordem_servico_id
             AND i.tipo_ender = 'EXE') AS executores,
         (SELECT SUM(h.horas) FROM apontam_hora h
           WHERE h.ordem_servico_id = os.ordem_servico_id) AS horas_totais,
         oe.motivo as motivo_recusa,
         oe.comentario as complemento_recusa,
         (SELECT DESCRICAO
            FROM DICIONARIO
           WHERE TIPO='tipo_cliente_agencia'
             AND CODIGO = OE.TIPO_CLIENTE_AGENCIA) AS ORIGEM_RECUSA,
         (SELECT SUM(ot.quantidade) FROM os_tipo_produto ot WHERE ot.ordem_servico_id = os.ordem_servico_id) as quantidade,
         (SELECT MAX(P.APELIDO)
           FROM OS_USUARIO UR,
                PESSOA P
          WHERE UR.ORDEM_SERVICO_ID = OS.ORDEM_SERVICO_ID
            AND UR.USUARIO_ID       = P.USUARIO_ID) AS usuario_sol,
         un.nome as unidade_negocio_projeto_nome
    FROM os_evento oe
         INNER JOIN ordem_servico os ON oe.ordem_servico_id = os.ordem_servico_id
                                     AND os.os_evento_id = oe.os_evento_id
         INNER JOIN tipo_os ts ON ts.tipo_os_id = os.tipo_os_id
         INNER JOIN os_refacao osr ON osr.ordem_servico_id = oe.ordem_servico_id
                                   AND osr.num_refacao = oe.num_refacao
         INNER JOIN job jo ON jo.job_id = os.job_id
         INNER JOIN pessoa us ON us.usuario_id = oe.usuario_id
         INNER JOIN pessoa cl ON cl.pessoa_id = jo.cliente_id
         INNER JOIN produto_cliente pc ON pc.produto_cliente_id = jo.produto_cliente_id
         INNER JOIN dicionario dos     ON dos.codigo = os.status
                                       AND dos.tipo = 'status_os'
          LEFT JOIN os_tipo_produto_ref oir ON oir.ordem_servico_id = oe.ordem_servico_id
                                           AND oir.num_refacao = oe.num_refacao
          LEFT JOIN job_tipo_produto ji ON ji.job_tipo_produto_id = oir.job_tipo_produto_id
          LEFT JOIN tipo_produto tp ON tp.tipo_produto_id = ji.tipo_produto_id
          LEFT JOIN unidade_negocio un ON un.unidade_negocio_id = jo.unidade_negocio_id

;
