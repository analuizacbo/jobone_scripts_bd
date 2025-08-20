--------------------------------------------------------
--  DDL for View V_HORAS_ALOC_CTR_X_TIMESHEET
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_HORAS_ALOC_CTR_X_TIMESHEET" ("CONTRATO_NUMERO", "CONTRATO_ID", "MES", "ANO", "CARGO", "CARGO_ID", "CARGO_NIVEL", "NIVEL", "HORAS_PLANEJADAS_NAO_SOMAR", "USUARIO_NOME", "USUARIO_ID", "CARGO_USUARIO", "CARGO_USUARIO_ID", "NIVEL_USUARIO", "NIVEL_USUARIO_CODIGO", "HORAS_ALOCADAS", "HORAS_APONTADAS", "HORAS_ALOCADAS_SALDO") AS 
  WITH
  HORAS_ALOCADAS AS (
    SELECT CONTRATO_PKG.NUMERO_FORMATAR(ct.contrato_id) AS ct_numero,
           ct.contrato_id AS ct_contrato_id,
           ch.data,
           TO_CHAR(ch.data, 'MM') AS ct_mes,
           TO_CHAR(ch.data, 'YYYY') AS ct_ano,
           cg.nome AS ct_cargo,
           cg.cargo_id AS ct_cargo_id,
           niv.descricao AS ct_cargo_nivel,
           niv.codigo AS ct_nivel,
           cgu.nome AS ct_cargo_usuario,
           cgu.cargo_id AS ct_cargo_usuario_id,
           nivu.descricao AS ct_cargo_nivel_usuario,
           nivu.codigo AS ct_nivel_usuario,
           ch.horas_planej AS ct_horas_planejadas,
           pe.apelido AS ct_usuario,
           cu.horas_aloc AS ct_horas_alocadas,
           cu.usuario_id AS ct_usuario_id
      FROM contrato_horas ch
           INNER JOIN contrato_horas_usu cu ON cu.contrato_horas_id = ch.contrato_horas_id
           INNER JOIN cargo cg ON cg.cargo_id = ch.cargo_id
           INNER JOIN dicionario niv ON niv.codigo = NVL(ch.nivel,'NA') AND niv.tipo = 'nivel_usuario'
           INNER JOIN contrato ct ON ct.contrato_id = ch.contrato_id
           LEFT JOIN contrato_horas_usu cu ON cu.contrato_horas_id = ch.contrato_horas_id
           LEFT JOIN cargo cgu ON cgu.cargo_id = CARGO_PKG.do_usuario_retornar(cu.usuario_id,ch.data,NULL)
           LEFT JOIN dicionario nivu ON nivu.codigo = NVL(CARGO_PKG.nivel_usuario_retornar(cu.usuario_id,ch.data,NULL),'NA') AND nivu.tipo = 'nivel_usuario'
           LEFT JOIN pessoa pe ON pe.usuario_id = cu.usuario_id
  ),
  HORAS_APONTADAS AS (
    SELECT CONTRATO_PKG.NUMERO_FORMATAR(ct.contrato_id) AS ts_numero,
           SUM(ah.horas) AS ts_horas_apontadas,
           ad.cargo_id AS ts_cargo_id,
           cg.nome AS ts_cargo,
           NVL(ad.nivel, 'NA') AS ts_nivel,
           niv.descricao AS ts_cargo_nivel,
           jo.contrato_id AS ts_contrato_id,
           ad.usuario_id AS ts_usuario_id,
           pe.apelido AS ts_usuario,
           TO_CHAR(ad.data, 'MM') AS ts_mes,
           TO_CHAR(ad.data, 'YYYY') AS ts_ano
      FROM apontam_hora ah
           INNER JOIN apontam_data ad ON ad.apontam_data_id = ah.apontam_data_id
           INNER JOIN cargo cg ON cg.cargo_id = ad.cargo_id
           INNER JOIN dicionario niv ON niv.codigo = ad.nivel AND niv.tipo = 'nivel_usuario'
           INNER JOIN job jo ON jo.job_id = ah.job_id
           INNER JOIN pessoa pe ON pe.usuario_id = ad.usuario_id
           INNER JOIN contrato ct ON ct.contrato_id = ah.contrato_id
            LEFT JOIN ordem_servico os ON os.ordem_servico_id = ah.ordem_servico_id
            LEFT JOIN tipo_os ts ON ts.tipo_os_id = os.tipo_os_id
            LEFT JOIN tipo_financeiro tf ON tf.tipo_financeiro_id = os.tipo_financeiro_id
     WHERE jo.contrato_id IS NOT NULL
       AND (ah.ordem_servico_id IS NULL OR
            ts.flag_tem_tipo_finan = 'N' OR
            tf.flag_consid_hr_os_ctr = 'S')
     GROUP BY ct.contrato_id, ad.cargo_id, cg.nome, ad.nivel, niv.descricao,
           jo.contrato_id, ad.usuario_id, pe.apelido,
           TO_CHAR(ad.data, 'MM'), TO_CHAR(ad.data, 'YYYY')
  )
  SELECT NVL(ha.ct_numero, ht.ts_numero) AS contrato_numero,
         NVL(ha.ct_contrato_id, ht.ts_contrato_id) AS contrato_id,
         NVL(ha.ct_mes, ht.ts_mes) AS mes,
         NVL(ha.ct_ano, ht.ts_ano) AS ano,
         NVL(ha.ct_cargo, ht.ts_cargo) AS cargo,
         NVL(ha.ct_cargo_id, ht.ts_cargo_id) AS cargo_id,
         NVL(ha.ct_cargo_nivel, ht.ts_cargo_nivel) AS cargo_nivel,
         NVL(ha.ct_nivel, ht.ts_nivel) AS nivel,
         NVL(ha.ct_horas_planejadas, 0) AS horas_planejadas_nao_somar,
         NVL(ha.ct_usuario,ts_usuario) AS usuario_nome,
         NVL(ha.ct_usuario_id, ht.ts_usuario_id) AS usuario_id,
         NVL(ht.ts_cargo, ha.ct_cargo_usuario) AS cargo_usuario,
         NVL(ht.ts_cargo_id, ha.ct_cargo_usuario_id) AS cargo_usuario_id,
         NVL(ht.ts_cargo_nivel, ha.ct_cargo_nivel_usuario) AS nivel_usuario,
         NVL(ht.ts_nivel, ha.ct_nivel_usuario) AS nivel_usuario_codigo,
         NVL(ha.ct_horas_alocadas, 0) AS horas_alocadas,
         NVL(ht.ts_horas_apontadas,0) AS horas_apontadas,
         NVL(ha.ct_horas_alocadas, 0) - NVL(ht.ts_horas_apontadas,0) AS horas_alocadas_saldo
    FROM HORAS_ALOCADAS ha
         FULL JOIN HORAS_APONTADAS ht
                ON ha.ct_mes = ht.ts_mes
               AND ha.ct_ano = ht.ts_ano
               AND ha.ct_usuario_id = ht.ts_usuario_id
               AND ha.ct_contrato_id = ht.ts_contrato_id

;
