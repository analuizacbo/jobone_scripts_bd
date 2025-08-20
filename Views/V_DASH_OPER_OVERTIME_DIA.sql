--------------------------------------------------------
--  DDL for View V_DASH_OPER_OVERTIME_DIA
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_OVERTIME_DIA" ("DATA", "TOTAL_HORAS_OVERTIME", "EQUIPE_ID") AS 
  SELECT da.data,
         SUM(da.horas_overtime) AS total_horas_overtime,
         eu.equipe_id
    FROM equipe_usuario eu
         INNER JOIN dia_alocacao da ON da.usuario_id = eu.usuario_id
   WHERE eu.flag_membro = 'S'
     AND TRUNC(da.data) >= TRUNC(SYSDATE)
     AND TRUNC(da.data) <= UTIL_PKG.DATA_CALCULAR(TRUNC(SYSDATE),'U',4)
GROUP BY da.data, eu.equipe_id

;
