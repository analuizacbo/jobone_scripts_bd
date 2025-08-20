--------------------------------------------------------
--  DDL for View V_DASH_OPER_ALOC_USUARIO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_ALOC_USUARIO" ("EQUIPE_ID", "USUARIO_ID", "DATA", "APELIDO", "FUNCAO", "NOME_FISICO", "PREFIXO", "NUMERO", "HORAS_DIARIAS", "PERC_ALOCACAO", "SALDO_HORAS", "HORAS_RESERVADO", "HORAS_ALOCADO", "HORAS_AUSENCIA") AS 
  SELECT eq.equipe_id,
         eu.usuario_id,
         da.data,
         pe.apelido,
         us.funcao,
         ar.nome_fisico,
         vo.prefixo,
         vo.numero,
         MAX(da.horas_diarias) AS horas_diarias,
         CASE da.horas_diarias
           WHEN 0 THEN 0
           ELSE ROUND(SUM(da.horas_total) /
                SUM(da.horas_diarias) * 100, 0)
         END AS perc_alocacao,
         SUM(da.horas_livre) - SUM(da.horas_overtime) AS saldo_horas,
         SUM(da.horas_reservado) AS horas_reservado,
         SUM(da.horas_alocado) AS horas_alocado,
         SUM(da.horas_ausencia) AS horas_ausencia
    FROM equipe eq
         INNER JOIN equipe_usuario eu ON eu.equipe_id = eq.equipe_id
         INNER JOIN dia_alocacao da ON da.usuario_id = eu.usuario_id
         INNER JOIN usuario us ON us.usuario_id = eu.usuario_id
         INNER JOIN pessoa pe ON pe.usuario_id = eu.usuario_id
          LEFT JOIN arquivo_pessoa ap ON ap.pessoa_id = pe.pessoa_id
                    AND ap.tipo_arq_pessoa = 'FOTO_USU'
                    AND ap.tipo_thumb = 'P'
          LEFT JOIN arquivo ar ON ar.arquivo_id = ap.arquivo_id
          LEFT JOIN volume vo ON vo.volume_id = ar.volume_id
   WHERE flag_membro = 'S'
     AND TRUNC(da.data) >= TRUNC(SYSDATE)
     AND TRUNC(da.data) <= UTIL_PKG.DATA_CALCULAR(TRUNC(SYSDATE),'U',4)
GROUP BY eq.equipe_id, eu.usuario_id, da.data, da.horas_diarias,
         pe.apelido, us.funcao, ar.nome_fisico,
         vo.prefixo, vo.numero

;
