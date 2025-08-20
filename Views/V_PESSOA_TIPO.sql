--------------------------------------------------------
--  DDL for View V_PESSOA_TIPO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PESSOA_TIPO" ("PESSOA_ID", "APELIDO_PESSOA", "NOME_PESSOA", "FLAG_ATIVO", "COD_TIPO_PESSOA", "APELIDO_PESSOA_PAI") AS 
  SELECT
-----------------------------------------------------------------------
-- lista os varios tipos de cada pessoa (pessoas sem tipificacao nao
--   aparecem nessa view).
-----------------------------------------------------------------------
       p.pessoa_id,
       p.apelido,
       p.nome,
       p.flag_ativo,
       t.codigo,
       pessoa_pkg.pai_retornar(p.pessoa_id,'AP')
  FROM pessoa p,
       tipific_pessoa tp,
       tipo_pessoa t
 WHERE p.pessoa_id = tp.pessoa_id
   AND tp.tipo_pessoa_id = t.tipo_pessoa_id

;
