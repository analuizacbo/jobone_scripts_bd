--------------------------------------------------------
--  DDL for View V_JOB_DOCUMENTO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_JOB_DOCUMENTO" ("JOB_ID", "DOCUMENTO_ID", "TIPO_DOCUMENTO_ID", "NOME_TIPO_DOC", "COD_TIPO_DOC", "NOME_DOC", "DESCRICAO_DOC", "COMENTARIO_VERSAO", "COMENTARIO_CONSOL", "VERSAO", "FLAG_ATUAL", "TIPO_FLUXO", "STATUS", "ARQUIVO_ID", "VOLUME_ID", "NUMERO_VOLUME", "CAMINHO", "NOME_ORIGINAL", "NOME_FISICO", "MIME_TYPE", "TAMANHO", "DATA_CRIACAO", "NOME_PESSOA", "PESSOA_ID", "FLAG_CONSOLIDAR", "QTD_ARQUIVO", "PAPEL_ID", "NOME_PAPEL") AS 
  SELECT
-----------------------------------------------------------------------
-- seleciona os documentos de cada job
-----------------------------------------------------------------------
       do.job_id,
       do.documento_id,
       td.tipo_documento_id,
       td.nome,
       td.codigo,
       do.nome,
       do.descricao,
       do.comentario,
       do.consolidacao,
       do.versao,
       do.flag_atual,
       do.tipo_fluxo,
       documento_pkg.status_retornar(do.documento_id),
       aq.arquivo_id,
       aq.volume_id,
       vo.numero,
       vo.caminho || '/' || vo.prefixo,
       aq.nome_original,
       aq.nome_fisico,
       aq.mime_type,
       aq.tamanho,
       aq.data_criacao,
       pe.apelido,
       pe.pessoa_id,
       DECODE(do.status,'PEND','S','N'),
       documento_pkg.qtd_arquivo_retornar(do.documento_id),
       pa.papel_id,
       pa.nome
  FROM documento do,
       tipo_documento td,
       arquivo aq,
       pessoa pe,
       volume vo,
       papel pa
 WHERE do.tipo_documento_id = td.tipo_documento_id
   AND do.papel_resp_id = pa.papel_id
   AND do.usuario_id = pe.usuario_id
   AND documento_pkg.prim_arquivo_id_retornar(do.documento_id) = aq.arquivo_id (+)
   AND aq.volume_id = vo.volume_id (+)

;
