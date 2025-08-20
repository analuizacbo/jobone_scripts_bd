--------------------------------------------------------
--  DDL for View V_CONTRATO_CONSUMO_RESUMO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CONTRATO_CONSUMO_RESUMO" ("AREA_ID", "CARGO_ID", "ORDEM", "USUARIO_ID", "AREA", "CARGO", "NIVEL", "DESCRICAO_CLIENTE", "USUARIO", "HORAS_PLANEJ", "HORAS_GASTAS") AS 
  SELECT area_id,
         cargo_id,
         ordem,
         usuario_id,
         area,
         cargo,
         nivel,
         descricao_cliente,
         usuario,
         SUM(horas_planej) AS horas_planej,
         SUM(horas_gastas) AS horas_gastas
    FROM
(
  SELECT ar.area_id,
         ca.cargo_id,
         ni.ordem,
         pe.usuario_id,
         ar.nome AS area,
         NVL(ca.nome, '-') AS cargo,
         NVL(ni.descricao,'-') AS nivel,
         ch.descricao AS descricao_cliente,
         NVL(pe.apelido,'-') AS usuario,
         SUM(ch.horas_planej) AS horas_planej,
         0 AS horas_gastas
    FROM contrato_horas ch
         INNER JOIN area ar ON ar.area_id = ch.area_id
          LEFT JOIN cargo ca ON ca.cargo_id = ch.cargo_id
          LEFT JOIN pessoa pe ON pe.usuario_id = ch.usuario_id
          LEFT JOIN dicionario ni ON ni.tipo = 'nivel_usuario' AND ni.codigo = ch.nivel
   WHERE ch.contrato_id = 3
GROUP BY ar.area_id,
         ca.cargo_id,
         ni.ordem,
         pe.usuario_id,
         ar.nome,
         ca.nome,
         ni.descricao,
         ch.descricao,
         pe.apelido
UNION ALL
  SELECT ar.area_id,
         ca.cargo_id,
         ni.ordem,
         0 AS usuario_id,
         NVL(ar.nome,'-') AS area,
         NVL(ca.nome,'-') AS cargo,
         NVL(ni.descricao,'-') AS nivel,
         '' AS descricao_cliente,
         '' AS usuario,
         0 AS horas_planej,
         SUM(ah.horas) AS horas_gastas
    FROM apontam_data ad
         INNER JOIN apontam_hora ah ON ah.apontam_data_id = ad.apontam_data_id
          LEFT JOIN area ar ON ad.area_cargo_id = ar.area_id
          LEFT JOIN cargo ca ON ca.cargo_id = ad.cargo_id
          LEFT JOIN dicionario ni ON ni.tipo = 'nivel_usuario' AND ni.codigo = ad.nivel
          LEFT JOIN ordem_servico os ON os.ordem_servico_id = ah.ordem_servico_id
          LEFT JOIN tipo_financeiro tf ON tf.tipo_financeiro_id = os.tipo_financeiro_id
   WHERE ah.job_id IN (SELECT job_id FROM job WHERE contrato_id = 3)
     AND tf.flag_consid_hr_os_ctr = 'S'
     AND NOT EXISTS (SELECT 1 FROM contrato_horas WHERE usuario_id = ad.usuario_id)
GROUP BY ar.area_id,
         ca.cargo_id,
         ni.ordem,
         ar.nome,
         ca.nome,
         ni.descricao
UNION ALL
  SELECT ar.area_id,
         0 AS cargo_id,
         0 AS ordem,
         ad.usuario_id,
         NVL(ar.nome,'-') AS area,
         '-' AS cargo,
         '-' AS nivel,
         '' AS descricao_cliente,
         pe.apelido AS usuario,
         0 AS horas_planej,
         SUM(ah.horas) AS horas_gastas
    FROM apontam_data ad
         INNER JOIN apontam_hora ah ON ah.apontam_data_id = ad.apontam_data_id
         INNER JOIN pessoa pe ON pe.usuario_id = ad.usuario_id
          LEFT JOIN area ar ON ad.area_cargo_id = ar.area_id
          LEFT JOIN ordem_servico os ON os.ordem_servico_id = ah.ordem_servico_id
          LEFT JOIN tipo_financeiro tf ON tf.tipo_financeiro_id = os.tipo_financeiro_id
   WHERE ah.job_id IN (SELECT job_id FROM job WHERE contrato_id = 3)
     AND tf.flag_consid_hr_os_ctr = 'S'
     AND EXISTS (SELECT 1 FROM contrato_horas WHERE usuario_id = ad.usuario_id)
GROUP BY ar.area_id,
         ad.usuario_id,
         ar.nome,
         pe.apelido
)
GROUP BY area_id,
         cargo_id,
         ordem,
         usuario_id,
         area,
         cargo,
         nivel,
         descricao_cliente,
         usuario
ORDER BY area,cargo,ordem

;
