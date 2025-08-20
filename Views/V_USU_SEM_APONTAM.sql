--------------------------------------------------------
--  DDL for View V_USU_SEM_APONTAM
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_USU_SEM_APONTAM" ("USUARIO_ID", "EMPRESA_ID", "NOME", "EMAIL") AS 
  SELECT DISTINCT
-----------------------------------------------------------------------
-- View de INBOX: usuarios que nunca apontaram
-----------------------------------------------------------------------
       us.usuario_id,
       pa.empresa_id,
       pe.apelido,
       pe.email
  FROM usuario us,
       usuario_papel up,
       papel pa,
       pessoa pe
 WHERE us.usuario_id = up.usuario_id
   AND us.flag_ativo = 'S'
   AND up.papel_id = pa.papel_id
   AND pa.flag_apontam_form = 'S'
   AND us.usuario_id = pe.usuario_id
   AND NOT EXISTS (SELECT 1
                     FROM apontam_data ad
                    WHERE ad.usuario_id = us.usuario_id)

;
