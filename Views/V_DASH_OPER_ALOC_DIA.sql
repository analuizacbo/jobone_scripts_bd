--------------------------------------------------------
--  DDL for View V_DASH_OPER_ALOC_DIA
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_ALOC_DIA" ("DATA", "PERC_ALOCACAO", "HORAS_TOTAL", "EQUIPE_ID") AS 
  SELECT da.data,
         CASE SUM(da.horas_diarias)
           WHEN 0 THEN 0
           ELSE ROUND(SUM(da.horas_total) /
                SUM(da.horas_diarias) * 100, 0)
         END AS perc_alocacao,
         SUM(da.horas_total) AS horas_total,
         eu.equipe_id
    FROM equipe_usuario eu
         INNER JOIN dia_alocacao da ON da.usuario_id = eu.usuario_id
   WHERE flag_membro = 'S'
     AND TRUNC(da.data) >= TRUNC(SYSDATE)
     AND TRUNC(da.data) <= UTIL_PKG.DATA_CALCULAR(TRUNC(SYSDATE),'U',4)
GROUP BY eu.equipe_id, da.data

;
