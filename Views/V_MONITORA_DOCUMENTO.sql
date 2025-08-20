--------------------------------------------------------
--  DDL for View V_MONITORA_DOCUMENTO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_MONITORA_DOCUMENTO" ("USUARIO_ID", "EMPRESA_ID", "CONTRATO_ID", "JOB_ID", "NUMERO_JOB", "NOME_JOB", "CLIENTE_ID", "NOME_CLIENTE", "DOCUMENTO_ID", "NOME_DOCUMENTO", "VERSAO", "DATA_CRIACAO", "AUTOR_ID", "NOME_AUTOR", "STATUS", "FLAG_CONSOLIDAR") AS 
  SELECT
 -----------------------------------------------------------------------
 -- view de monitoracao de documentos do job (ainda nao consolidados).
 -----------------------------------------------------------------------
        ju.usuario_id,
        jo.empresa_id,
        jo.contrato_id,
        jo.job_id,
        jo.numero,
        jo.nome,
        pe.pessoa_id,
        pe.apelido,
        do.documento_id,
        td.nome || ' - ' || do.nome,
        do.versao,
        do.data_versao,
        pd.pessoa_id,
        pd.apelido,
        documento_pkg.status_retornar(do.documento_id),
        DECODE(vt.objeto_id, NULL , 'S', 'N')
   FROM job jo,
        pessoa pe,
        documento do,
        tipo_documento td,
        pessoa pd,
        job_usuario ju,
        (SELECT DISTINCT ta.objeto_id
           FROM task ta,
                tipo_objeto tb
          WHERE ta.flag_fechado = 'N'
            AND ta.tipo_objeto_id = tb.tipo_objeto_id
            AND tb.codigo = 'DOCUMENTO') vt
  WHERE jo.cliente_id = pe.pessoa_id
    AND jo.status = 'ANDA'
    AND jo.job_id = do.job_id
    AND do.status = 'PEND'
    AND do.tipo_documento_id = td.tipo_documento_id
    AND do.usuario_id = pd.usuario_id
    AND do.job_id = ju.job_id
    AND do.documento_id = vt.objeto_id (+)
    AND EXISTS (SELECT 1
                  FROM usuario_papel up
                 WHERE up.usuario_id = ju.usuario_id
                   AND up.papel_id = do.papel_resp_id)

;
