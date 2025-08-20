--------------------------------------------------------
--  DDL for View V_HISTORICO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_HISTORICO" ("HISTORICO_ID", "EMPRESA_ID", "USUARIO_ID", "EVENTO_ID", "APELIDO_USUARIO", "NOME_USUARIO", "DATA_EVENTO", "DESC_EVENTO", "COMPLEMENTO", "COD_OBJETO", "DESC_OBJETO", "COD_ACAO", "DESC_ACAO", "IDENTIF_OBJETO", "OBJETO_ID", "JUSTIFICATIVA", "XML_ANTES", "XML_ATUAL") AS 
  SELECT
-----------------------------------------------------------------------
-- lista dados do historico
-----------------------------------------------------------------------
       hi.historico_id,
       hi.empresa_id,
       hi.usuario_id,
       hi.evento_id,
       pe.apelido,
       pe.nome,
       hi.data_evento,
       ev.descricao,
       hi.complemento,
       tb.codigo,
       tb.nome,
       ta.codigo,
       ta.nome,
       hi.identif_objeto,
       hi.objeto_id,
       hi.justificativa,
       hi.xml_antes,
       hi.xml_atual
  FROM historico hi,
       evento ev,
       tipo_objeto tb,
       tipo_acao ta,
       usuario us,
       pessoa pe
 WHERE hi.evento_id = ev.evento_id
   AND hi.usuario_id = us.usuario_id
   AND us.usuario_id = pe.usuario_id
   AND ev.tipo_objeto_id = tb.tipo_objeto_id
   AND ev.tipo_acao_id = ta.tipo_acao_id

;
