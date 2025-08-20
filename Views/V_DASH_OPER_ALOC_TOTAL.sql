--------------------------------------------------------
--  DDL for View V_DASH_OPER_ALOC_TOTAL
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_ALOC_TOTAL" ("PERC_ALOCACAO", "TOTAL_HORAS_DISPONIVEIS", "TOTAL_HORAS", "TOTAL_HORAS_LIVRE", "TOTAL_HORAS_OVERTIME", "EQUIPE_ID") AS 
  SELECT ROUND(SUM(da.horas_total) /
         SUM(da.horas_diarias) * 100, 0) AS perc_alocacao,
         SUM(da.horas_diarias) AS total_horas_disponiveis,
         SUM(da.horas_total) AS total_horas,
         SUM(da.horas_livre) AS total_horas_livre,
         SUM(da.horas_overtime) AS total_horas_overtime,
         eq.equipe_id
    FROM equipe eq
         INNER JOIN equipe_usuario eu ON eu.equipe_id = eq.equipe_id
         INNER JOIN dia_alocacao da ON da.usuario_id = eu.usuario_id
   WHERE flag_membro = 'S'
     AND TRUNC(da.data) >= TRUNC(SYSDATE)
     AND TRUNC(da.data) <= UTIL_PKG.DATA_CALCULAR(TRUNC(SYSDATE),'U',4)
GROUP BY eq.equipe_id

;
