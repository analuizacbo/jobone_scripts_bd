--------------------------------------------------------
--  DDL for View V_DOCUMENTO_TASK
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DOCUMENTO_TASK" ("JOB_ID", "DOCUMENTO_ID", "PAPEL_ID", "NOME_PAPEL", "USUARIOS_ENDER", "STATUS", "TASK_ID", "DATA_FECHAM", "COMENTARIO", "NOME_PESSOA", "PESSOA_ID") AS 
  SELECT
-----------------------------------------------------------------------
-- seleciona as tasks associadas ao documento
-----------------------------------------------------------------------
       do.job_id,
       do.documento_id,
       pa.papel_id,
       pa.nome,
       job_pkg.usuarios_retornar(do.job_id,pa.papel_id),
       documento_pkg.status_task_retornar(ta.task_id),
       ta.task_id,
       task_pkg.data_evento_retornar(ta.task_id,'FECHAMENTO'),
       task_pkg.ult_comentario_retornar(ta.task_id),
       pe.apelido,
       pe.pessoa_id
  FROM documento do,
       task ta,
       tipo_objeto tb,
       papel pa,
       usuario us,
       pessoa pe
 WHERE do.documento_id = ta.objeto_id
   AND ta.tipo_objeto_id = tb.tipo_objeto_id
   AND tb.codigo = 'DOCUMENTO'
   AND ta.papel_resp_id = pa.papel_id
   AND task_pkg.usuario_id_evento_retornar(ta.task_id,'FECHAMENTO') = us.usuario_id (+)
   AND us.usuario_id = pe.usuario_id (+)

;
