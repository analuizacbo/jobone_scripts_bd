--------------------------------------------------------
--  DDL for View V_ATIVIDADES_JOB
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_ATIVIDADES_JOB" ("EMPRESA_ID", "COD_OBJETO", "OBJETO_ID", "ITEM_CRONO_ID", "CLIENTE_APELIDO", "JOB_ID", "JOB_NUMERO", "JOB_DESCRICAO", "ATIVIDADE_TIPO", "TIPO_WORKFLOW", "ATIVIDADE_DESCRICAO", "ATIVIDADE_DESCRICAO_SEM_NUMERO", "ATIVIDADE_NUMERO", "ATIVIDADE_METADADOS", "STATUS", "STATUS_NEGOCIACAO", "PRAZO", "PRAZO_FMT", "PRAZO_INTERNO", "PRAZO_INTERNO_FMT", "SOLICITANTE", "SOLICITANTE_ID", "EQUIPE", "EXECUTORES", "HORAS", "PRODUTO_CLIENTE", "CONTRATO_NUMERO", "CONTRATO_NOME", "DATA_INICIO_PLANEJADA", "DATA_INICIO_PLANEJADA_FMT", "DATA_FIM_PLANEJADA", "DATA_FIM_PLANEJADA_FMT", "RESPONSAVEL_PELO_JOB", "RESPONSAVEL_PELO_JOB_ID", "CONTATO_JOB", "DATA_ENTRADA_JOB", "DATA_ENTRADA_JOB_FMT", "DATA_ENVIO", "DATA_ENVIO_FMT", "DATA_APRESENTACAO", "DATA_APRESENTACAO_FMT", "DATA_GO_LIVE", "DATA_GO_LIVE_FMT", "COMENT_STATUS_AUTOR", "COMENT_STATUS_DATA", "COMENT_STATUS_DATA_FMT", "COMENT_STATUS", "REFACAO") AS 
  SELECT jo.empresa_id,
         ic.cod_objeto,
         ic.objeto_id,
         ic.item_crono_id,
         cl.apelido AS cliente_apelido,
         jo.job_id,
         jo.numero AS job_numero,
         NVL(jo.numero || ' ' || jo.nome,'-') AS job_descricao,
         CASE ic.cod_objeto
           WHEN 'ORDEM_SERVICO' THEN ts.nome
           WHEN 'TAREFA' THEN 'Task'
           WHEN 'BRIEFING' THEN 'Briefing'
           WHEN 'JOB_HORAS' THEN 'Estimativa de Horas'
           WHEN 'FATUR_CONC' THEN 'Conclusão do Faturamento'
           WHEN 'DATA_APR_CLI' THEN 'Apresentação para o Cliente'
           WHEN 'DOCUMENTO' THEN 'Documento'
           WHEN 'ORCAMENTO' THEN 'Orçamento'
           WHEN 'CRONOGRAMA' THEN 'Cronograma'
           WHEN 'CHECKIN_CONC' THEN 'Conclusão do Check-in'
           WHEN 'JOB_CONC' THEN 'Conclusão do Job'
           ELSE '-'
         END AS atividade_tipo,
         NVL(ts.nome,'N/A') AS tipo_workflow,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN DECODE(objeto_id,NULL,'',ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id)|| ' ') || os.descricao
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL  THEN DECODE(objeto_id,NULL,'',TAREFA_PKG.NUMERO_FORMATAR(ta.tarefa_id)|| ' ') || ta.descricao
           WHEN ic.cod_objeto = 'DOCUMENTO' AND ic.objeto_id IS NOT NULL  THEN do.nome
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL  THEN NVL(oc.descricao, 'Descrição Não definida')
           ELSE NVL(ic.nome,'-')
         END AS atividade_descricao,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN os.descricao
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL  THEN ta.descricao
           WHEN ic.cod_objeto = 'DOCUMENTO' AND ic.objeto_id IS NOT NULL  THEN do.nome
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL  THEN NVL(oc.descricao, 'Descrição Não definida')
           ELSE NVL(ic.nome,'-')
         END AS atividade_descricao_sem_numero,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN ORDEM_SERVICO_PKG.NUMERO_FORMATAR(os.ordem_servico_id)
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL THEN TAREFA_PKG.NUMERO_FORMATAR(ta.tarefa_id)
           WHEN ic.cod_objeto = 'DOCUMENTO' AND ic.objeto_id IS NOT NULL THEN '-'
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL THEN ORCAMENTO_PKG.NUMERO_FORMATAR(oc.orcamento_id)
           WHEN ic.objeto_id IS NULL THEN '-'
           ELSE '-'
         END AS atividade_numero,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN
             (SELECT LISTAGG(v.valor_atributo,', ') WITHIN GROUP (ORDER BY m.ordem)
                FROM os_atributo_valor v
                     INNER JOIN metadado m ON m.metadado_id = v.metadado_id
               WHERE m.flag_na_lista = 'S'
                 AND v.ordem_servico_id = os.ordem_servico_id)
           ELSE '-'
         END AS atividade_metadados,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN DECODE(os.status,'CONC','Concluída',dos.descricao || DECODE(ov.flag_recusa, 'S',' (Recusado)',''))
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL THEN dts.descricao
           WHEN ic.cod_objeto = 'BRIEFING' THEN DECODE(bf.status, 'APROV', 'Concluída',dbs.descricao)
           WHEN ic.cod_objeto = 'JOB_HORAS' THEN DECODE(jo.status_horas, 'APROV', 'Concluída', NVL(dhs.descricao,'Não Iniciado'))
           WHEN ic.cod_objeto = 'FATUR_CONC' THEN DECODE(jo.status_fatur, 'A', 'Pendente', 'F', 'Concluída', '-')
           WHEN ic.cod_objeto = 'DATA_APR_CLI' AND ic.data_planej_fim < SYSDATE THEN 'Concluída'
           WHEN ic.cod_objeto = 'DATA_APR_CLI' AND ic.data_planej_fim >= SYSDATE THEN 'Pendente'
           WHEN ic.cod_objeto = 'DOCUMENTO' AND ic.objeto_id IS NOT NULL THEN DECODE(do.status, 'OK', 'Concluída', 'PEND', 'Pendente', '-')
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL THEN DECODE(oc.status, 'APROV', 'Concluída', dms.descricao)
           WHEN ic.cod_objeto = 'CRONOGRAMA' THEN DECODE(cr.status, 'APROV', 'Concluída', dcs.descricao)
           WHEN ic.cod_objeto = 'CHECKIN_CONC' THEN DECODE(jo.status_checkin, 'A', 'Pendente', 'F', 'Concluída', '-')
           WHEN ic.cod_objeto = 'JOB_CONC' THEN DECODE(jo.status, 'CONC', 'Concluída', 'Pendente')
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NULL THEN 'Não Iniciada'
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NULL THEN 'Não Iniciada'
           WHEN ic.cod_objeto = 'DOCUMENTO' AND ic.objeto_id IS NULL THEN 'Não Iniciada'
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NULL THEN 'Não Iniciada'
           WHEN ic.cod_objeto IS NULL AND ic.data_planej_fim < SYSDATE THEN 'Concluída'
           WHEN ic.cod_objeto IS NULL AND ic.data_planej_fim >= SYSDATE THEN 'Pendente'
           ELSE '-'
         END AS status,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL
            AND os.flag_em_negociacao = 'S' THEN 'ANDA'
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL
            AND os.status IN ('DIST','ACEI','EMEX','AVAL')
            AND os.flag_em_negociacao = 'N'
            AND (SELECT COUNT(*) FROM os_negociacao onx
                  WHERE onx.ordem_servico_id = ic.objeto_id
                    AND onx.num_refacao = os.qtd_refacao) = 0 THEN 'DISP'
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL
            AND os.status IN ('DIST','ACEI','EMEX','AVAL')
            AND os.flag_em_negociacao = 'N'
            AND (SELECT COUNT(*) FROM os_negociacao onx
                  WHERE onx.ordem_servico_id = ic.objeto_id
                    AND onx.num_refacao = os.qtd_refacao) > 0 THEN 'CONC'
           ELSE 'N/A'
         END AS status_negociacao,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN os.data_solicitada
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL THEN ta.data_termino
           ELSE NVL(ic.data_planej_fim, jo.data_prev_fim)
         END AS prazo,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN DATA_MOSTRAR(os.data_solicitada)
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL THEN DATA_MOSTRAR(ta.data_termino)
           ELSE DATA_MOSTRAR(NVL(ic.data_planej_fim, jo.data_prev_fim))
         END AS prazo_fmt,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN os.data_interna
           ELSE NULL
         END AS prazo_interno,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN DATA_MOSTRAR(os.data_interna)
           ELSE NULL
         END AS prazo_interno_fmt,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO'
            AND ic.objeto_id IS NOT NULL THEN (SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'SOL')
           WHEN ic.cod_objeto = 'TAREFA'
            AND ic.objeto_id IS NOT NULL THEN (SELECT p.apelido || ' (' || u.funcao || ')'
                                                 FROM pessoa p
                                                      INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                                WHERE p.usuario_id = ta.usuario_de_id)
           WHEN ic.cod_objeto = 'DOCUMENTO'
            AND ic.objeto_id IS NOT NULL THEN (SELECT p.apelido || ' (' || u.funcao || ')'
                                                 FROM pessoa p
                                                      INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                                WHERE p.usuario_id = do.usuario_id)
           WHEN ic.cod_objeto = 'ORCAMENTO'
            AND ic.objeto_id IS NOT NULL THEN (SELECT p.apelido || ' (' || u.funcao || ')'
                                                 FROM pessoa p
                                                      INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                                WHERE p.usuario_id = oc.usuario_autor_id)
           ELSE (SELECT pr.apelido || ' (' || ur.funcao || ')'
            FROM pessoa pr
                 INNER JOIN usuario ur ON pr.usuario_id = ur.usuario_id
                 INNER JOIN job_usuario xr ON xr.usuario_id = ur.usuario_id
                                          AND xr.job_id = jo.job_id
           WHERE xr.flag_responsavel = 'S'
         )
         END AS solicitante,
                  CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO'
            AND ic.objeto_id IS NOT NULL THEN (SELECT MAX(i.usuario_id)
                                              FROM os_usuario i
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'SOL')
           WHEN ic.cod_objeto = 'TAREFA'
            AND ic.objeto_id IS NOT NULL THEN ta.usuario_de_id
           WHEN ic.cod_objeto = 'DOCUMENTO'
            AND ic.objeto_id IS NOT NULL THEN do.usuario_id
           WHEN ic.cod_objeto = 'ORCAMENTO'
            AND ic.objeto_id IS NOT NULL THEN oc.usuario_autor_id
           ELSE (SELECT xr.usuario_id
                   FROM job_usuario xr
                  WHERE xr.job_id = jo.job_id
                    AND xr.flag_responsavel = 'S')
         END AS solicitante_id,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO'
            AND ic.objeto_id IS NOT NULL THEN NVL((SELECT LISTAGG(e.nome,', ') within group (order by e.nome)
                                                     FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN os_usuario o ON o.usuario_id = x.usuario_id
                                                    WHERE o.ordem_servico_id = os.ordem_servico_id
                                                      AND o.tipo_ender = 'EXE'),'-')
           WHEN ic.cod_objeto = 'TAREFA'
            AND ic.objeto_id IS NOT NULL THEN NVL((SELECT LISTAGG(e.nome,', ') within group (order by e.nome)
                                                     FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN tarefa_usuario i on x.usuario_id = i.usuario_para_id
                                                    WHERE i.tarefa_id = ta.tarefa_id),'-')
           WHEN ic.cod_objeto = 'DOCUMENTO'
            AND ic.objeto_id IS NOT NULL THEN NVL((SELECT LISTAGG(e.nome,', ') within group (order by e.nome)
                                                     FROM equipe e
                                                          INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                                                          INNER JOIN task i on x.usuario_id = i.usuario_autor_id
                                                          INNER JOIN tipo_objeto t on t.tipo_objeto_id = i.tipo_objeto_id
                                                    WHERE i.objeto_id = do.documento_id
                                                      AND t.codigo = 'DOCUMENTO'),'-')
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL THEN '-'
           ELSE NVL((SELECT LISTAGG(e.nome,', ') within group (order by e.nome)
                       FROM equipe e
                            INNER JOIN equipe_usuario x ON x.equipe_id = e.equipe_id
                            INNER JOIN item_crono_usu i on x.usuario_id = i.usuario_id
                      WHERE i.item_crono_id = ic.item_crono_id),'-')
         END AS equipe,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO'
            AND ic.objeto_id IS NOT NULL THEN NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM os_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.ordem_servico_id = os.ordem_servico_id
                                               AND i.tipo_ender = 'EXE'),'-')
           WHEN ic.cod_objeto = 'TAREFA'
            AND ic.objeto_id IS NOT NULL THEN NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM tarefa_usuario i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_para_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.tarefa_id = ta.tarefa_id),'-')
           WHEN ic.cod_objeto = 'DOCUMENTO'
            AND ic.objeto_id IS NOT NULL THEN (SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM task i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_autor_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                                   INNER JOIN tipo_objeto t on t.tipo_objeto_id = i.tipo_objeto_id
                                             WHERE i.objeto_id = do.documento_id
                                               AND t.codigo = 'DOCUMENTO')
           WHEN ic.cod_objeto = 'ORCAMENTO' AND ic.objeto_id IS NOT NULL THEN '-'
           ELSE NVL((SELECT LISTAGG(p.apelido || ' (' || u.funcao || ')',', ') within group (order by p.apelido)
                                              FROM item_crono_usu i
                                                   INNER JOIN pessoa p on p.usuario_id = i.usuario_id
                                                   INNER JOIN usuario u on u.usuario_id = p.usuario_id
                                             WHERE i.item_crono_id = ic.item_crono_id),'-')
         END AS executores,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' AND ic.objeto_id IS NOT NULL THEN
                NVL((SELECT SUM(u.horas_planej)
                       FROM os_usuario u
                            INNER JOIN item_crono i ON i.objeto_id = u.ordem_servico_id AND i.cod_objeto = 'ORDEM_SERVICO'
                      WHERE i.item_crono_id = ic.item_crono_id),0)
           WHEN ic.cod_objeto = 'TAREFA' AND ic.objeto_id IS NOT NULL THEN
                NVL((SELECT SUM(u.horas_totais)
                       FROM tarefa_usuario u
                            INNER JOIN item_crono i ON i.objeto_id = u.tarefa_id AND i.cod_objeto = 'TAREFA'
                      WHERE i.item_crono_id = ic.item_crono_id),0)
           ELSE NVL((SELECT SUM(h.horas_totais) FROM item_crono_usu h WHERE h.item_crono_id = ic.item_crono_id),0)
         END AS horas,
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
         NVL(ic.situacao,'-') AS coment_status,
         CASE
            WHEN os.qtd_refacao = '0' OR os.qtd_refacao IS NULL THEN
               '-'
            ELSE
               TO_CHAR(os.qtd_refacao)
          END AS refacao
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
          LEFT JOIN tarefa ta          ON ta.tarefa_id = ic.objeto_id AND ic.cod_objeto = 'TAREFA'
          LEFT JOIN dicionario dts     ON ic.cod_objeto = 'TAREFA'
                                       AND dts.codigo = ta.status
                                       AND dts.tipo = 'status_tarefa'
          LEFT JOIN documento do       ON do.documento_id = ic.objeto_id AND ic.cod_objeto = 'DOCUMENTO'
          LEFT JOIN orcamento oc       ON oc.orcamento_id = ic.objeto_id AND ic.cod_objeto = 'ORCAMENTO'
          LEFT JOIN dicionario dms     ON ic.cod_objeto = 'ORCAMENTO'
                                       AND dms.codigo = oc.status
                                       AND dms.tipo = 'status_orcam'
          LEFT JOIN briefing bf        ON bf.job_id = jo.job_id
                                       AND bf.briefing_id = BRIEFING_PKG.ULTIMO_RETORNAR(jo.job_id)
                                       AND ic.cod_objeto = 'BRIEFING'
          LEFT JOIN dicionario dbs     ON ic.cod_objeto = 'BRIEFING'
                                       AND dbs.codigo = bf.status
                                       AND dbs.tipo = 'status_brief'
          LEFT JOIN dicionario dhs     ON ic.cod_objeto = 'JOB_HORAS'
                                       AND dhs.codigo = jo.status_horas
                                       AND dhs.tipo = 'status_job_horas'
          LEFT JOIN dicionario dcs     ON ic.cod_objeto = 'CRONOGRAMA'
                                       AND dcs.codigo = cr.status
                                       AND dcs.tipo = 'status_crono'
          LEFT JOIN pessoa ui          ON ui.usuario_id = ic.usuario_situacao_id
          LEFT JOIN job_usuario xr     ON xr.job_id = jo.job_id
                                       AND xr.flag_responsavel = 'S'
          LEFT JOIN usuario ur         ON ur.usuario_id = xr.usuario_id
          LEFT JOIN pessoa pr          ON pr.usuario_id = xr.usuario_id
          LEFT JOIN os_evento ov       ON ov.os_evento_id = ordem_servico_pkg.ultimo_evento_retornar(os.ordem_servico_id)
   WHERE ic.cod_objeto IN ('ORDEM_SERVICO','TAREFA')
     AND cr.status <> 'ARQUI'

;
