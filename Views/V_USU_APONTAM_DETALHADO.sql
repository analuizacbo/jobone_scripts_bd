--------------------------------------------------------
--  DDL for View V_USU_APONTAM_DETALHADO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_USU_APONTAM_DETALHADO" ("USUARIO_ID", "EMPRESA_ID", "USUARIO", "PAPEL_ID", "PAPEL", "JOB_ID", "JOB_NUMERO", "JOB_NOME", "CLIENTE", "HORAS", "DATA", "MES_ANO", "DIA", "MES", "ANO", "DIA_SEMANA", "DIA_SEMANA_DESC", "TRIMESTRE", "SEMESTRE", "CUSTO_HORA_CONTABIL", "CUSTO_HORA_GERENCIAL", "CUSTO_TOTAL_CONTABIL", "CUSTO_TOTAL_GERENCIAL", "TIPO") AS 
  SELECT
-----------------------------------------------------------------------
-- View para relatorio de detalhamento de apontamentos (nao esta sendo
--   usada).
-----------------------------------------------------------------------
         ad.usuario_id,
         pa.empresa_id,
         pu.apelido,
         ah.papel_id,
         pa.nome,
         ah.job_id,
         jo.numero,
         jo.numero || ' - ' || job_pkg.nome_retornar(ah.job_id) AS nome_job,
         pc.apelido,
         ah.horas,
         DATA_MOSTRAR(ad.data),
         TO_CHAR(ad.data,'MM/YYYY'),
         TO_CHAR(ad.data,'DD'),
         TO_CHAR(ad.data,'MM'),
         TO_CHAR(ad.data,'YYYY'),
         TO_CHAR(ad.data,'D'),
         dia_semana_mostrar(ad.data),
         TRUNC(TO_NUMBER(TO_CHAR(ad.data,'MM'))/3 + 1),
         TRUNC(TO_NUMBER(TO_CHAR(ad.data,'MM'))/6 + 1),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'CON',TO_CHAR(ad.data,'MM/YYYY')),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'GER',TO_CHAR(ad.data,'MM/YYYY')),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'CON',TO_CHAR(ad.data,'MM/YYYY')) * ah.horas,
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'GER',TO_CHAR(ad.data,'MM/YYYY')) * ah.horas,
         ti.nome
    FROM apontam_data ad,
         apontam_hora ah,
         job jo,
         pessoa pu,
         pessoa pc,
         papel pa,
         tipo_apontam ti
   WHERE ad.apontam_data_id = ah.apontam_data_id
     AND ah.job_id = jo.job_id
     AND ad.usuario_id = pu.usuario_id
     AND jo.cliente_id = pc.pessoa_id
     AND ah.papel_id = pa.papel_id
     AND ah.tipo_apontam_id = ti.tipo_apontam_id
   UNION
  SELECT ad.usuario_id,
         pa.empresa_id,
         pu.apelido,
         ah.papel_id,
         pa.nome,
         0,
         '0',
         ti.nome,
         NVL(pc.apelido,'N/A'),
         ah.horas,
         DATA_MOSTRAR(ad.data),
         TO_CHAR(ad.data,'MM/YYYY'),
         TO_CHAR(ad.data,'DD'),
         TO_CHAR(ad.data,'MM'),
         TO_CHAR(ad.data,'YYYY'),
         TO_CHAR(ad.data,'D'),
         dia_semana_mostrar(ad.data),
         TRUNC(TO_NUMBER(TO_CHAR(ad.data,'MM'))/3 + 1),
         TRUNC(TO_NUMBER(TO_CHAR(ad.data,'MM'))/6 + 1),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'CON',TO_CHAR(ad.data,'MM/YYYY')),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'GER',TO_CHAR(ad.data,'MM/YYYY')),
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'CON',TO_CHAR(ad.data,'MM/YYYY')) * ah.horas,
         APONTAM_PKG.custo_horario_retornar(ad.usuario_id,'GER',TO_CHAR(ad.data,'MM/YYYY')) * ah.horas,
         ti.nome
    FROM apontam_data ad,
         apontam_hora ah,
         pessoa pu,
         pessoa pc,
         papel pa,
         tipo_apontam ti
   WHERE ad.apontam_data_id = ah.apontam_data_id
     AND ah.job_id IS NULL
     AND ah.cliente_id = pc.pessoa_id (+)
     AND ad.usuario_id = pu.usuario_id
     AND ah.papel_id = pa.papel_id
     AND ah.tipo_apontam_id = ti.tipo_apontam_id

;
