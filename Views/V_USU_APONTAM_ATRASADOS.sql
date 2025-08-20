--------------------------------------------------------
--  DDL for View V_USU_APONTAM_ATRASADOS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_USU_APONTAM_ATRASADOS" ("USUARIO_ID", "EMPRESA_ID", "NOME", "EMAIL", "BLOQUEADO", "DATA_ULT_APONTAM", "NUM_DIAS_PEND") AS 
  SELECT DISTINCT
-----------------------------------------------------------------------
-- View de INBOX: usuarios c/ apontamentos atrasados
-----------------------------------------------------------------------
       us.usuario_id,
       pa.empresa_id,
       pe.apelido,
       pe.email,
       DECODE(apontam_pkg.em_dia_verificar(us.usuario_id,'APONT'),1,'N',0,'S'),
       apontam_pkg.data_ult_apontam_retornar(us.usuario_id),
       apontam_pkg.num_dias_status_retornar(us.usuario_id,'PEND')
  FROM usuario us,
       pessoa pe,
       usuario_papel up,
       papel pa
 WHERE apontam_pkg.num_dias_status_retornar(us.usuario_id,'PEND') >=
       TO_NUMBER(empresa_pkg.parametro_retornar(usuario_pkg.empresa_padrao_retornar(us.usuario_id),
                                               'NUM_DIAS_UTEIS_SEM_APONTAM') )
   AND us.flag_ativo = 'S'
   AND us.usuario_id = pe.usuario_id
   AND us.usuario_id = up.usuario_id
   AND up.papel_id = pa.papel_id
   AND pa.flag_apontam_form = 'S'

;
