--------------------------------------------------------
--  DDL for View V_TIMELINE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_TIMELINE" ("STATUS_ALOCACAO", "APELIDO", "USUARIO_ID", "FUNCAO", "ATIVO_DESC", "NOME_ATIVIDADE", "DATA_INI_FMT", "DATA_FIM_FMT", "DATA_INI", "DATA_FIM", "NV_M", "PRE_M", "NOME_FISICO_M", "TIPO_ATIVIDADE", "COD_OBJETO", "FLAG_PLANEJADO", "ITEM_ID", "OBJETO_ID", "FLAG_OS_APROV_AUTO", "TIPO_APONTAM_ID", "JOB_ID", "NOME_JOB", "NUMERO_JOB", "NOME_CLIENTE", "OBS", "NOME_CARGO", "EQUIPE_ID", "STATUS", "CODIGO_STATUS", "FLAG_RECUSADA", "FLAG_ATRASADO", "CLIENTE_ID", "NUM_REFACAO") AS 
  WITH ausente AS
 (SELECT /*+ first_rows (1) */
   'AUSENTE' AS status_alocacao,
   pe.apelido,
   pe.usuario_id,
   us.funcao,
   decode(us.flag_ativo, 'S', 'Ativo', 'N', 'Inativo') AS ativo_desc,
   ta.nome AS nome_atividade,
   data_hora_mostrar(ap.data_ini) AS data_ini_fmt,
   data_hora_mostrar(ap.data_fim) AS data_fim_fmt,
   ap.data_ini AS data_ini,
   ap.data_fim AS data_fim,
   nvl(vo_m.numero, 0) AS nv_m,
   nvl(vo_m.prefixo, 0) AS pre_m,
   nvl(ar_m.nome_fisico, 0) AS nome_fisico_m,
   'AUS' AS tipo_atividade,
   '' AS cod_objeto,
   '' AS flag_planejado,
   ap.apontam_progr_id AS item_id,
   ap.apontam_progr_id AS objeto_id,
   ap.flag_os_aprov_auto AS flag_os_aprov_auto,
   ap.tipo_apontam_id AS tipo_apontam_id,
   0 AS job_id,
   '' AS nome_job,
   '' AS numero_job,
   '' AS nome_cliente,
   ap.obs AS obs,
   ca.nome AS nome_cargo,
   eu.equipe_id,
   '' AS status,
   '' AS codigo_status,
   'N' AS flag_recusada,
   'N' AS flag_atrasado,
   0 AS cliente_id, /*,
           (SELECT listagg(to_char(nvl(h.horas, 0),
                                   '999990D99'),
                           ', ') within GROUP(ORDER BY v.data) AS horas
              FROM (SELECT (trunc(ap.data_fim) - LEVEL + 1) AS data
                      FROM dual
                    CONNECT BY LEVEL <=
                               (trunc(ap.data_fim) -
                               trunc(ap.data_ini) + 1)) v
             INNER JOIN apontam_data d
                ON d.data = v.data
               AND d.usuario_id = ap.usuario_id
             INNER JOIN apontam_hora h
                ON h.apontam_data_id = d.apontam_data_id
             INNER JOIN tipo_apontam t
                ON t.tipo_apontam_id = h.tipo_apontam_id
               AND t.flag_ausencia = 'S') AS horas_fmt*/
   NULL AS num_refacao
    FROM pessoa pe
   INNER JOIN usuario us
      ON us.usuario_id = pe.usuario_id
   INNER JOIN apontam_progr ap
      ON ap.usuario_id = pe.usuario_id
   INNER JOIN tipo_apontam ta
      ON ta.tipo_apontam_id = ap.tipo_apontam_id
   INNER JOIN cargo ca
      ON ca.cargo_id = cargo_pkg.do_usuario_retornar(pe.usuario_id, SYSDATE, NULL)
   INNER JOIN equipe_usuario eu
      ON eu.usuario_id = pe.usuario_id
    LEFT JOIN arquivo_pessoa ap_m
      ON ap_m.pessoa_id = pe.pessoa_id
     AND ap_m.tipo_thumb = 'M'
     AND ap_m.tipo_arq_pessoa = 'FOTO_USU'
    LEFT JOIN arquivo ar_m
      ON ar_m.arquivo_id = ap_m.arquivo_id
    LEFT JOIN volume vo_m
      ON vo_m.volume_id = ar_m.volume_id
   WHERE ta.flag_ausencia = 'S'
     AND eu.flag_membro = 'S'
     AND (trunc(ap.data_ini) >= trunc(add_months(SYSDATE, -1), 'mm') OR
         trunc(ap.data_fim) <= trunc(last_day(add_months(SYSDATE, 2))))),
reservado AS
 (
  --Reserva no Cronograma
  SELECT /*+ first_rows (1) */
   'RESERVADO' AS status_alocacao,
    pe.apelido,
    pe.usuario_id,
    us.funcao,
    decode(us.flag_ativo, 'S', 'Ativo', 'N', 'Inativo') AS ativo_desc,
    ic.nome AS nome_atividade,
    data_hora_mostrar(ic.data_planej_ini) AS data_ini_fmt,
    data_hora_mostrar(ic.data_planej_fim) AS data_fim_fmt,
    ic.data_planej_ini AS data_ini,
    ic.data_planej_fim AS data_fim,
    nvl(vo_m.numero, 0) AS nv_m,
    nvl(vo_m.prefixo, 0) AS pre_m,
    nvl(ar_m.nome_fisico, 0) AS nome_fisico_m,
    'RES' AS tipo_atividade,
    ic.cod_objeto AS cod_objeto,
    ic.flag_planejado AS flag_planejado,
    ic.item_crono_id AS item_id,
    ic.item_crono_id AS objeto_id,
    '' AS flag_os_aprov_auto,
    0 AS tipo_apontam_id,
    cr.job_id AS job_id,
    jo.nome AS nome_job,
    jo.numero AS numero_job,
    cl.apelido AS nome_cliente,
    ic.obs AS obs,
    ca.nome AS nome_cargo,
    eu.equipe_id,
    '' AS status,
    '' AS codigo_status,
    'N' AS flag_recusada,
    'N' AS flag_atrasado,
    jo.cliente_id, /*,
              (SELECT listagg(to_char(icu2.horas_diarias,
                                      '999990D99') || '/' ||
                              ltrim(to_char(icu2.horas_totais,
                                            '999990D99')))
                 FROM item_crono     ic2,
                      item_crono_usu icu2
                WHERE ic2.item_crono_id = icu2.item_crono_id
                  AND icu2.usuario_id = pe.usuario_id
                  AND ic2.item_crono_id = ic.item_crono_id) horas_fmt*/
    NULL AS num_refacao
    FROM pessoa pe
   INNER JOIN usuario us
      ON us.usuario_id = pe.usuario_id
   INNER JOIN item_crono_usu icu
      ON icu.usuario_id = pe.usuario_id
   INNER JOIN item_crono ic
      ON ic.item_crono_id = icu.item_crono_id
   INNER JOIN cronograma cr
      ON cr.cronograma_id = ic.cronograma_id
   INNER JOIN job jo
      ON jo.job_id = cr.job_id
   INNER JOIN pessoa cl
      ON cl.pessoa_id = jo.cliente_id
   INNER JOIN cargo ca
      ON ca.cargo_id = cargo_pkg.do_usuario_retornar(pe.usuario_id, SYSDATE, NULL)
   INNER JOIN equipe_usuario eu
      ON eu.usuario_id = pe.usuario_id
    LEFT JOIN arquivo_pessoa ap_m
      ON ap_m.pessoa_id = pe.pessoa_id
     AND ap_m.tipo_thumb = 'M'
     AND ap_m.tipo_arq_pessoa = 'FOTO_USU'
    LEFT JOIN arquivo ar_m
      ON ar_m.arquivo_id = ap_m.arquivo_id
    LEFT JOIN volume vo_m
      ON vo_m.volume_id = ar_m.volume_id
   WHERE ic.objeto_id IS NULL
     AND ic.data_planej_ini IS NOT NULL
     AND ic.data_planej_fim IS NOT NULL
     AND eu.flag_membro = 'S'
     AND (trunc(ic.data_planej_ini) >= trunc(add_months(SYSDATE, -1), 'mm') OR
         trunc(ic.data_planej_fim) <= trunc(last_day(add_months(SYSDATE, 2))))),
os AS
 (
  -- Alocacao em ordem_servico
  SELECT /*+ first_rows (1) */
   CASE
     WHEN os.qtd_refacao > 0 AND ou.num_refacao <> os.qtd_refacao THEN
      'CONCLUIDO'
     ELSE
      CASE
       WHEN os.status = 'PREP' THEN
        'PRE-ALOCADO'
       WHEN os.status = 'STAN' THEN
        'PRE-ALOCADO'
       WHEN os.status = 'DIST' AND os.qtd_refacao > 0 THEN
        'PRE-ALOCADO'
       WHEN os.status = 'DIST' THEN
        'PRE-ALOCADO'
       WHEN os.status = 'ACEI' THEN
        'ALOCADO'
       WHEN os.status = 'EMEX' THEN
        'ALOCADO'
       WHEN os.status = 'AVAL' THEN
        'CONCLUIDO'
       WHEN os.status = 'EXEC' THEN
        'CONCLUIDO'
       WHEN os.status = 'EMAP' THEN
        'CONCLUIDO'
       WHEN os.status = 'CONC' THEN
        'CONCLUIDO'
      END
    END AS status_alocacao,
    pe.apelido,
    pe.usuario_id,
    us.funcao,
    decode(us.flag_ativo, 'S', 'Ativo', 'N', 'Inativo') AS ativo_desc,
    ic.nome AS nome_atividade,
    data_hora_mostrar(ou.data_inicio) AS data_ini_fmt,
    data_hora_mostrar(ou.data_termino) AS data_fim_fmt,
    ou.data_inicio AS data_ini,
    ou.data_termino AS data_fim,
    nvl(vo_m.numero, 0) AS nv_m,
    nvl(vo_m.prefixo, 0) AS pre_m,
    nvl(ar_m.nome_fisico, 0) AS nome_fisico_m,
    'ALO' AS tipo_atividade,
    ic.cod_objeto AS cod_objeto,
    ic.flag_planejado AS flag_planejado,
    ic.item_crono_id AS item_id,
    ic.objeto_id AS objeto_id,
    '' AS flag_os_aprov_auto,
    0 AS tipo_apontam_id,
    cr.job_id AS job_id,
    jo.nome AS nome_job,
    jo.numero AS numero_job,
    cl.apelido AS nome_cliente,
    ic.obs AS obs,
    ca.nome AS nome_cargo,
    eu.equipe_id,
    st.descricao AS status,
    os.status AS codigo_status,
    os.flag_recusada AS flag_recusada,
    CASE
     WHEN os.data_interna < SYSDATE AND
          os.status NOT IN ('EXEC', 'AVAL', 'EMAP', 'CANC', 'CONC', 'DESC') THEN
      'AT'
     ELSE
      'NN'
    END AS flag_atrasado,
    jo.cliente_id, /*,
                 (select listagg(to_char(oud.data,'dd') || '|' || oud.horas, ', ' ON OVERFLOW TRUNCATE '* Mais registros *')
                 WITHIN GROUP (ORDER BY oud.data)
                 FROM os_usuario_data oud,
                      ordem_servico   os2,
                      item_crono      ic2
                WHERE oud.ordem_servico_id =
                      os2.ordem_servico_id
                  AND os2.ordem_servico_id = ic2.objeto_id
                  AND ic2.cod_objeto LIKE 'ORDEM_SERVICO'
                  AND ic2.objeto_id = ic.objeto_id
                  AND os2.job_id = cr.job_id
                  AND oud.usuario_id = pe.usuario_id
                  AND oud.data <= data_converter(sysdate)
                  AND oud.data >= data_converter(sysdate)) as horas_fmt*/
    ou.num_refacao
    FROM pessoa pe
   INNER JOIN usuario us
      ON us.usuario_id = pe.usuario_id
   INNER JOIN (SELECT MIN(ou1.data) AS data_inicio,
                      MAX(ou1.data) AS data_termino,
                      os1.data_execucao,
                      ou1.ordem_servico_id,
                      ou1.usuario_id,
                      ou1.num_refacao
                 FROM os_usuario_data ou1,
                      ordem_servico   os1
                WHERE os1.ordem_servico_id = ou1.ordem_servico_id
                  AND (NOT EXISTS (SELECT 1
                                     FROM os_usuario_data ou2
                                    WHERE ou2.ordem_servico_id = ou1.ordem_servico_id
                                      AND ou2.usuario_id = ou1.usuario_id
                                      AND ou2.horas > 0) OR ou1.horas > 0)
                GROUP BY os1.data_execucao,
                         ou1.ordem_servico_id,
                         ou1.usuario_id,
                         ou1.num_refacao) ou
      ON ou.usuario_id = us.usuario_id
   INNER JOIN item_crono ic
      ON ic.objeto_id = ou.ordem_servico_id
     AND ic.cod_objeto = 'ORDEM_SERVICO'
   INNER JOIN cronograma cr
      ON cr.cronograma_id = ic.cronograma_id
     AND cr.cronograma_id = cronograma_pkg.ultimo_retornar(cr.job_id)
   INNER JOIN ordem_servico os
      ON os.ordem_servico_id = ic.objeto_id
   INNER JOIN os_refacao oe
      ON oe.ordem_servico_id = os.ordem_servico_id
     AND oe.num_refacao = ou.num_refacao
   INNER JOIN dicionario st
      ON st.tipo = 'status_os'
     AND st.codigo = os.status
   INNER JOIN job jo
      ON jo.job_id = cr.job_id
   INNER JOIN pessoa cl
      ON cl.pessoa_id = jo.cliente_id
   INNER JOIN cargo ca
      ON ca.cargo_id = cargo_pkg.do_usuario_retornar(pe.usuario_id, SYSDATE, NULL)
   INNER JOIN equipe_usuario eu
      ON eu.usuario_id = pe.usuario_id
    LEFT JOIN arquivo_pessoa ap_m
      ON ap_m.pessoa_id = pe.pessoa_id
     AND ap_m.tipo_thumb = 'M'
     AND ap_m.tipo_arq_pessoa = 'FOTO_USU'
    LEFT JOIN arquivo ar_m
      ON ar_m.arquivo_id = ap_m.arquivo_id
    LEFT JOIN volume vo_m
      ON vo_m.volume_id = ar_m.volume_id
   WHERE eu.flag_membro = 'S'
     AND os.status <> 'STAN'
  /*AND (TRUNC(ou.data_inicio) >= to_date(trunc(sysdate,'YYYY')- interval '1' year)
  or TRUNC(ou.data_termino) <= to_date(trunc(sysdate,'YYYY')+ interval '1' year))*/
  --AND TRUNC(ou.data_inicio) >= to_date(trunc(sysdate,'YYYY') - interval '1' year)
  --AND TRUNC(ou.data_termino) <= to_date(trunc(sysdate,'YYYY')+ interval '1' year)
  ),
task AS
 (
  -- Alocacao em tarefa
  SELECT /*+ first_rows (1) */
   CASE ta.status
     WHEN 'EMEX' THEN
      'ALOCADO'
     WHEN 'EXEC' THEN
      'CONCLUIDO'
     WHEN 'CONC' THEN
      'CONCLUIDO'
    END AS status_alocacao,
    pe.apelido,
    pe.usuario_id,
    us.funcao,
    decode(us.flag_ativo, 'S', 'Ativo', 'N', 'Inativo') AS ativo_desc,
    ic.nome AS nome_atividade,
    data_hora_mostrar(ou.data_inicio) AS data_ini_fmt,
    data_hora_mostrar(ou.data_termino) AS data_fim_fmt,
    ou.data_inicio AS data_ini,
    ou.data_termino AS data_fim,
    nvl(vo_m.numero, 0) AS nv_m,
    nvl(vo_m.prefixo, 0) AS pre_m,
    nvl(ar_m.nome_fisico, 0) AS nome_fisico_m,
    'ALO' AS tipo_atividade,
    ic.cod_objeto AS cod_objeto,
    ic.flag_planejado AS flag_planejado,
    ic.item_crono_id AS item_id,
    ic.objeto_id AS objeto_id,
    '' AS flag_os_aprov_auto,
    0 AS tipo_apontam_id,
    jo.job_id AS job_id,
    jo.nome AS nome_job,
    jo.numero AS numero_job,
    cl.apelido AS nome_cliente,
    ic.obs AS obs,
    ca.nome AS nome_cargo,
    eu.equipe_id,
    st.descricao AS status,
    ta.status AS codigo_status,
    CASE
     WHEN ta.status = 'RECU' THEN
      'S'
     ELSE
      'N'
    END AS flag_recusada,
    CASE
     WHEN ta.data_termino < SYSDATE AND ta.status NOT IN ('EXEC', 'CANC', 'CONC') THEN
      'AT'
     ELSE
      'NN'
    END AS flag_atrasado,
    jo.cliente_id, /*,
              (select listagg(to_char(tud.data,'dd') || '|' || tud.horas, ', ' ON OVERFLOW TRUNCATE '* Mais registros *')
              WITHIN GROUP (ORDER BY tud.data)
                 FROM tarefa_usuario      tu,
                      tarefa_usuario_data tud
                WHERE tu.usuario_para_id = tud.usuario_para_id
                  AND tu.usuario_para_id = us.usuario_id
                  AND tu.tarefa_id = ta.tarefa_id
                  AND tud.usuario_para_id = us.usuario_id
                  AND tud.tarefa_id = ta.tarefa_id
                  AND tud.data <= data_converter(sysdate)
                  AND tud.data >= data_converter(sysdate)) as horas_fmt*/
    NULL AS num_refacao
    FROM pessoa pe
   INNER JOIN usuario us
      ON us.usuario_id = pe.usuario_id
   INNER JOIN (SELECT MIN(ou.data) AS data_inicio,
                      MAX(ou.data) AS data_termino,
                      ta.data_execucao,
                      ou.tarefa_id,
                      ou.usuario_para_id
                 FROM tarefa_usuario_data ou,
                      tarefa              ta
                WHERE ta.tarefa_id = ou.tarefa_id
                  AND (NOT EXISTS (SELECT 1
                                     FROM tarefa_usuario_data ou2
                                    WHERE ou2.tarefa_id = ou.tarefa_id
                                      AND ou2.usuario_para_id = ou.usuario_para_id
                                      AND ou2.horas > 0) OR ou.horas > 0)
                GROUP BY ta.data_execucao,
                         ou.tarefa_id,
                         ou.usuario_para_id) ou
      ON ou.usuario_para_id = us.usuario_id
   INNER JOIN item_crono ic
      ON ic.objeto_id = ou.tarefa_id
     AND ic.cod_objeto = 'TAREFA'
   INNER JOIN tarefa ta
      ON ta.tarefa_id = ic.objeto_id
   INNER JOIN dicionario st
      ON st.tipo = 'status_tarefa'
     AND codigo = ta.status
   INNER JOIN cronograma cr
      ON cr.cronograma_id = ic.cronograma_id
     AND cr.cronograma_id = cronograma_pkg.ultimo_retornar(cr.job_id)
   INNER JOIN job jo
      ON jo.job_id = cr.job_id
   INNER JOIN pessoa cl
      ON cl.pessoa_id = jo.cliente_id
   INNER JOIN cargo ca
      ON ca.cargo_id = cargo_pkg.do_usuario_retornar(pe.usuario_id, SYSDATE, NULL)
   INNER JOIN equipe_usuario eu
      ON eu.usuario_id = pe.usuario_id
    LEFT JOIN arquivo_pessoa ap_m
      ON ap_m.pessoa_id = pe.pessoa_id
     AND ap_m.tipo_thumb = 'M'
     AND ap_m.tipo_arq_pessoa = 'FOTO_USU'
    LEFT JOIN arquivo ar_m
      ON ar_m.arquivo_id = ap_m.arquivo_id
    LEFT JOIN volume vo_m
      ON vo_m.volume_id = ar_m.volume_id
   WHERE eu.flag_membro = 'S'
  --AND ou.data_termino BETWEEN
  --trunc(add_months(SYSDATE, -1), 'mm') AND trunc(last_day(add_months(SYSDATE, 2))))
  --AND TRUNC(ou.data_inicio) >= to_date(trunc(sysdate,'YYYY') - interval '1' year))
  )
SELECT "STATUS_ALOCACAO","APELIDO","USUARIO_ID","FUNCAO","ATIVO_DESC","NOME_ATIVIDADE","DATA_INI_FMT","DATA_FIM_FMT","DATA_INI","DATA_FIM","NV_M","PRE_M","NOME_FISICO_M","TIPO_ATIVIDADE","COD_OBJETO","FLAG_PLANEJADO","ITEM_ID","OBJETO_ID","FLAG_OS_APROV_AUTO","TIPO_APONTAM_ID","JOB_ID","NOME_JOB","NUMERO_JOB","NOME_CLIENTE","OBS","NOME_CARGO","EQUIPE_ID","STATUS","CODIGO_STATUS","FLAG_RECUSADA","FLAG_ATRASADO","CLIENTE_ID","NUM_REFACAO"
  FROM ausente
UNION ALL
SELECT "STATUS_ALOCACAO","APELIDO","USUARIO_ID","FUNCAO","ATIVO_DESC","NOME_ATIVIDADE","DATA_INI_FMT","DATA_FIM_FMT","DATA_INI","DATA_FIM","NV_M","PRE_M","NOME_FISICO_M","TIPO_ATIVIDADE","COD_OBJETO","FLAG_PLANEJADO","ITEM_ID","OBJETO_ID","FLAG_OS_APROV_AUTO","TIPO_APONTAM_ID","JOB_ID","NOME_JOB","NUMERO_JOB","NOME_CLIENTE","OBS","NOME_CARGO","EQUIPE_ID","STATUS","CODIGO_STATUS","FLAG_RECUSADA","FLAG_ATRASADO","CLIENTE_ID","NUM_REFACAO"
  FROM reservado
UNION ALL
SELECT "STATUS_ALOCACAO","APELIDO","USUARIO_ID","FUNCAO","ATIVO_DESC","NOME_ATIVIDADE","DATA_INI_FMT","DATA_FIM_FMT","DATA_INI","DATA_FIM","NV_M","PRE_M","NOME_FISICO_M","TIPO_ATIVIDADE","COD_OBJETO","FLAG_PLANEJADO","ITEM_ID","OBJETO_ID","FLAG_OS_APROV_AUTO","TIPO_APONTAM_ID","JOB_ID","NOME_JOB","NUMERO_JOB","NOME_CLIENTE","OBS","NOME_CARGO","EQUIPE_ID","STATUS","CODIGO_STATUS","FLAG_RECUSADA","FLAG_ATRASADO","CLIENTE_ID","NUM_REFACAO"
  FROM os
UNION ALL
SELECT "STATUS_ALOCACAO","APELIDO","USUARIO_ID","FUNCAO","ATIVO_DESC","NOME_ATIVIDADE","DATA_INI_FMT","DATA_FIM_FMT","DATA_INI","DATA_FIM","NV_M","PRE_M","NOME_FISICO_M","TIPO_ATIVIDADE","COD_OBJETO","FLAG_PLANEJADO","ITEM_ID","OBJETO_ID","FLAG_OS_APROV_AUTO","TIPO_APONTAM_ID","JOB_ID","NOME_JOB","NUMERO_JOB","NOME_CLIENTE","OBS","NOME_CARGO","EQUIPE_ID","STATUS","CODIGO_STATUS","FLAG_RECUSADA","FLAG_ATRASADO","CLIENTE_ID","NUM_REFACAO"
  FROM task

;
