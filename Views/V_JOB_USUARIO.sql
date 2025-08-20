--------------------------------------------------------
--  DDL for View V_JOB_USUARIO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOB_USUARIO" ("JOB_ID", "USUARIO_ID", "EMPRESA_ID", "APELIDO_USUARIO", "NOME_USUARIO", "FLAG_USUARIO_ATIVO", "FUNCAO") AS 
  SELECT
-----------------------------------------------------------------------
-- para cada job, seleciona os usuarios enderecados
-----------------------------------------------------------------------
       ju.job_id,
       ju.usuario_id,
       jo.empresa_id,
       pe.apelido,
       pe.nome,
       us.flag_ativo,
       us.funcao
  FROM job_usuario ju,
       usuario us,
       pessoa pe,
       job jo
 WHERE ju.usuario_id = us.usuario_id
   AND us.usuario_id = pe.usuario_id
   AND ju.job_id = jo.job_id

;
