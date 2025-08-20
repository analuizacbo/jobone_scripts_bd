--------------------------------------------------------
--  DDL for View V_USU_PAPEL_ENDER
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_USU_PAPEL_ENDER" ("USUARIO_ID", "EMPRESA_ID", "APELIDO_USUARIO", "PAPEL_ID", "AREA_ID", "NOME_AREA", "NOME_PAPEL", "ORDEM_PAPEL", "FLAG_USUARIO_ATIVO", "NUMERO_ENDERECAMENTOS", "NUMERO_TASKS") AS 
  SELECT
-----------------------------------------------------------------------
-- lista usuarios ativos associados a papeis enderecaveis.
-----------------------------------------------------------------------
       us.usuario_id,
       pa.empresa_id,
       pe.apelido,
       up.papel_id,
       pa.area_id,
       ar.nome,
       pa.nome,
       pa.ordem,
       us.flag_ativo,
       USUARIO_PKG.NUMERO_ENDERECAMENTOS_RETORNAR(us.usuario_id,pa.empresa_id) AS numero_enderecamentos,
       0
      -- USUARIO_PKG.NUMERO_TASKS_RETORNAR(us.usuario_id,pa.empresa_id) AS numero_tasks
  FROM usuario_papel up,
       usuario us,
       papel pa,
       pessoa pe,
       area ar
 WHERE up.usuario_id = us.usuario_id
   AND us.usuario_id = pe.usuario_id
   AND up.papel_id = pa.papel_id
   AND pa.area_id = ar.area_id
   AND pa.flag_ender = 'S'
   AND us.flag_ativo = 'S'

;
