--------------------------------------------------------
--  DDL for View V_JOB_USUARIO_QTD
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOB_USUARIO_QTD" ("JOB_ID", "USUARIO_ID", "EMPRESA_ID", "AREA_ID", "NOME_AREA", "APELIDO_USUARIO", "NOME_USUARIO", "FLAG_USUARIO_ATIVO", "NUMERO_ENDERECAMENTOS", "FUNCAO") AS 
  SELECT
-----------------------------------------------------------------------
-- para cada job, seleciona os usuarios enderecados, com as qtds de
-- endereçamentos.
-----------------------------------------------------------------------
       ju.job_id,
       ju.usuario_id,
       jo.empresa_id,
       ar.area_id,
       ar.nome,
       pe.apelido,
       pe.nome,
       us.flag_ativo,
       USUARIO_PKG.NUMERO_ENDERECAMENTOS_RETORNAR(ju.usuario_id,jo.empresa_id),
       us.funcao
  FROM job_usuario ju,
       usuario us,
       pessoa pe,
       area ar,
       job jo
 WHERE ju.usuario_id = us.usuario_id
   AND ju.job_id = jo.job_id
   AND us.usuario_id = pe.usuario_id
   AND us.area_id = ar.area_id

;
