--------------------------------------------------------
--  DDL for View V_WORKFLOW_STATUS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_WORKFLOW_STATUS" ("EMPRESA_ID", "COD_OBJETO", "OBJETO_ID", "ITEM_CRONO_ID", "CLIENTE_ESPECIFICO_ID", "GRUPO_ID", "CLIENTE_ESPECIFICO", "CLIENTE", "JOB_ID", "JOB_DESCRICAO", "ATIVIDADE_TIPO", "ATIVIDADE_DESCRICAO", "STATUS", "STATUS_CODIGO", "NUM_REFACAO", "STATUS_NEGOCIACAO", "PRAZO", "PRAZO_FMT", "PRAZO_INTERNO", "PRAZO_INTERNO_FMT", "SOLICITANTE", "SOLICITANTE_ID", "EQUIPE", "AREA", "EXECUTORES", "EXECUTORES_ID", "HORAS", "PRODUTO_CLIENTE", "CONTRATO_NUMERO", "CONTRATO_NOME", "DATA_INICIO_PLANEJADA", "DATA_INICIO_PLANEJADA_FMT", "DATA_FIM_PLANEJADA", "DATA_FIM_PLANEJADA_FMT", "RESPONSAVEL_PELO_JOB", "RESPONSAVEL_PELO_JOB_ID", "CONTATO_JOB", "DATA_ENTRADA_JOB", "DATA_ENTRADA_JOB_FMT", "DATA_ENVIO", "DATA_ENVIO_FMT", "DATA_APRESENTACAO", "DATA_APRESENTACAO_FMT", "DATA_GO_LIVE", "DATA_GO_LIVE_FMT", "COMENT_STATUS_AUTOR", "COMENT_STATUS_DATA", "COMENT_STATUS_DATA_FMT", "COMENT_STATUS") AS 
  SELECT jo.empresa_id,
         ic.cod_objeto,
         ic.objeto_id,
         ic.item_crono_id,
         jo.cliente_id AS cliente_especifico_id,
         NVL((SELECT LISTAGG(gr.grupo_id,', ') WITHIN GROUP (ORDER BY gr.grupo_id)
                FROM grupo gr
                     INNER JOIN grupo_pessoa gp ON gr.grupo_id = gp.grupo_id
               WHERE gp.pessoa_id = cl.pessoa_id
                 AND gr.flag_agrupa_cnpj = 'S'),0) AS grupo_id,
         cl.apelido AS cliente_especifico,
         NVL((SELECT LISTAGG(gr.nome,', ') WITHIN GROUP (ORDER BY gr.nome)
                FROM grupo gr
                     INNER JOIN grupo_pessoa gp ON gr.grupo_id = gp.grupo_id
               WHERE gp.pessoa_id = cl.pessoa_id
                 AND gr.flag_agrupa_cnpj = 'S'),cl.apelido) AS cliente,
         jo.job_id,
         NVL(jo.numero || ' ' || jo.nome,'-') AS job_descricao,
         ts.nome AS atividade_tipo,
         DECODE(objeto_id,NULL,'',ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id)|| ' ') || os.descricao AS atividade_descricao,
         dos.descricao || DECODE(ov.flag_recusa, 'S',' (Recusado)','') AS status,
         dos.codigo AS status_codigo,
         os.qtd_refacao AS num_refacao,
         CASE
           WHEN os.flag_em_negociacao = 'S' THEN 'ANDA'
           WHEN os.status IN ('DIST','ACEI','EMEX','AVAL')
            AND os.flag_em_negociacao = 'N'
            AND (SELECT COUNT(*)
                   FROM os_negociacao onx
                  WHERE onx.ordem_servico_id = ic.objeto_id
                    AND onx.num_refacao = os.qtd_refacao) = 0 THEN 'DISP'
           WHEN os.status IN ('DIST','ACEI','EMEX','AVAL')
            AND os.flag_em_negociacao = 'N'
            AND (SELECT COUNT(*)
                   FROM os_negociacao onx
                  WHERE onx.ordem_servico_id = ic.objeto_id
                    AND onx.num_refacao = os.qtd_refacao) > 0 THEN 'CONC'
           ELSE 'N/A'
         END AS status_negociacao,
         os.data_solicitada AS prazo,
         DATA_MOSTRAR(os.data_solicitada) AS prazo_fmt,
         os.data_interna AS prazo_interno,
         DATA_MOSTRAR(os.data_interna) AS prazo_interno_fmt,
         (SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'SOL') AS solicitante,
         (SELECT LISTAGG(i.usuario_id,', ') within group (order by i.usuario_id)
                                              FROM os_usuario i
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'SOL') AS solicitante_id,
         NVL((SELECT DISTINCT LISTAGG(nome,', ') within group (order by nome)
                                                     FROM (SELECT DISTINCT e.nome FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN os_usuario o ON o.usuario_id = x.usuario_id
                                                    WHERE o.ordem_servico_id = os.ordem_servico_id)),'-') AS equipe,
         NVL((SELECT DISTINCT LISTAGG(nome,', ') within group (order by nome)
                                                     FROM (SELECT DISTINCT a.nome
                                                             FROM area a
                                                                  INNER JOIN cargo c ON c.area_id = a.area_id
                                                                  INNER JOIN usuario_cargo x ON x.cargo_id = c.cargo_id
                                                                  INNER JOIN os_usuario o ON o.usuario_id = x.usuario_id
                                                            WHERE o.ordem_servico_id = os.ordem_servico_id
                                                              AND x.data_fim IS NULL)),'-') AS area,
         NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'EXE'),'-') AS executores,
         NVL((SELECT LISTAGG(p.usuario_id,', ') within group (order by p.usuario_id)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'EXE'),'-') AS executores_id,
         NVL((SELECT SUM(u.horas_planej)
                       FROM os_usuario u
                            INNER JOIN item_crono i ON i.objeto_id = u.ordem_servico_id AND i.cod_objeto = 'ORDEM_SERVICO'
                      WHERE i.item_crono_id = ic.item_crono_id),0) AS horas,
         pc.nome AS produto_cliente,
         DECODE(CONTRATO_PKG.NUMERO_FORMATAR(ct.contrato_id), 'ERRO', '-', CONTRATO_PKG.NUMERO_FORMATAR(ct.contrato_id)) AS contrato_numero,
         DECODE(ct.nome, NULL, '-', ct.nome) AS contrato_nome,
         ic.data_planej_ini AS data_inicio_planejada,
         DATA_MOSTRAR(ic.data_planej_ini) AS data_inicio_planejada_fmt,
         ic.data_planej_fim AS data_fim_planejada,
         DATA_MOSTRAR(ic.data_planej_fim) AS data_fim_planejada_fmt,
         NVL(pr.apelido || ' (' || ur.funcao || ')','-') AS responsavel_pelo_job,
         ur.usuario_id AS responsavel_pelo_job_id,
         NVL(cn.apelido || DECODE(cn.funcao,NULL,'',' (' || cn.funcao || ')'),'-') AS contato_job,
         jo.data_entrada AS data_entrada_job,
         DATA_MOSTRAR(jo.data_entrada) AS data_entrada_job_fmt,
         sysdate AS data_envio,
         DATA_MOSTRAR(sysdate) AS data_envio_fmt,
         jo.data_pri_aprov AS data_apresentacao,
         DATA_MOSTRAR(jo.data_pri_aprov) AS data_apresentacao_fmt,
         sysdate AS data_go_live,
         DATA_MOSTRAR(sysdate) AS data_go_live_fmt,
         NVL(ui.apelido,'-') AS coment_status_autor,
         ic.data_situacao AS coment_status_data,
         DATA_MOSTRAR(ic.data_situacao) AS coment_status_data_fmt,
         NVL(ic.situacao,'-') AS coment_status
         --SELECT COUNT(*)
    FROM item_crono ic
         INNER JOIN cronograma cr      ON ic.cronograma_id = cr.cronograma_id
         INNER JOIN job jo             ON jo.job_id = cr.job_id
         INNER JOIN pessoa cl          ON cl.pessoa_id = jo.cliente_id
          LEFT JOIN produto_cliente pc ON pc.produto_cliente_id = jo.produto_cliente_id
          LEFT JOIN contrato ct        ON ct.contrato_id = jo.contrato_id
          LEFT JOIN pessoa cn          ON cn.pessoa_id = jo.contato_id
          LEFT JOIN ordem_servico os   ON os.ordem_servico_id = ic.objeto_id AND ic.cod_objeto = 'ORDEM_SERVICO'
          LEFT JOIN dicionario dos     ON ic.cod_objeto = 'ORDEM_SERVICO'
                                       AND dos.codigo = os.status
                                       AND dos.tipo = 'status_os'
          LEFT JOIN tipo_os ts         ON ts.tipo_os_id = os.tipo_os_id
          LEFT JOIN pessoa ui          ON ui.usuario_id = ic.usuario_situacao_id
          LEFT JOIN job_usuario xr     ON xr.job_id = jo.job_id
                                       AND xr.flag_responsavel = 'S'
          LEFT JOIN usuario ur         ON ur.usuario_id = xr.usuario_id
          LEFT JOIN pessoa pr          ON pr.usuario_id = xr.usuario_id
          LEFT JOIN os_evento ov       ON ov.os_evento_id = ordem_servico_pkg.ultimo_evento_retornar(os.ordem_servico_id)
   WHERE ic.cod_objeto IN ('ORDEM_SERVICO')
     AND ic.cod_objeto IS NOT NULL
     AND cr.status <> 'ARQUI'
     AND jo.status NOT IN ('CANC')

;
