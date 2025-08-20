--------------------------------------------------------
--  DDL for View V_DASH_OPER_AUSENCIA
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_AUSENCIA" ("APELIDO", "FUNCAO", "USUARIO_ID", "NOME_FISICO", "PREFIXO", "NUMERO", "DATA_INI", "DATA_INI_FMT", "HORA_INI", "DATA_FIM", "DATA_FIM_FMT", "HORA_FIM", "TIPO_APONTAM", "FLAG_AUSENCIA_FULL", "APONTAM_PROGR_ID", "EQUIPE_ID") AS 
  SELECT pe.apelido,
         us.funcao,
         us.usuario_id,
         ar.nome_fisico,
         vo.prefixo,
         vo.numero,
         au.data_ini,
         DATA_MOSTRAR(au.data_ini) AS data_ini_fmt,
         TO_CHAR(au.data_ini,'HH24:MI') AS hora_ini,
         au.data_fim,
         DATA_MOSTRAR(au.data_fim) AS data_fim_fmt,
         TO_CHAR(au.data_fim,'HH24:MI') AS hora_fim,
         ta.nome AS tipo_apontam,
         ta.flag_ausencia_full,
         au.apontam_progr_id,
         eq.equipe_id
    FROM equipe eq
         INNER JOIN equipe_usuario eu ON eu.equipe_id = eq.equipe_id
         INNER JOIN usuario us ON us.usuario_id = eu.usuario_id
         INNER JOIN pessoa pe ON pe.usuario_id = eu.usuario_id
         INNER JOIN apontam_progr au ON au.usuario_id = eu.usuario_id
         INNER JOIN tipo_apontam ta ON ta.tipo_apontam_id = au.tipo_apontam_id
          LEFT JOIN arquivo_pessoa ap ON ap.pessoa_id = pe.pessoa_id
                    AND ap.tipo_arq_pessoa = 'FOTO_USU'
                    AND ap.tipo_thumb = 'P'
          LEFT JOIN arquivo ar ON ar.arquivo_id = ap.arquivo_id
          LEFT JOIN volume vo ON vo.volume_id = ar.volume_id
   WHERE flag_membro = 'S'
     AND ((TRUNC(au.data_ini) >= TRUNC(SYSDATE) AND TRUNC(au.data_ini) <= UTIL_PKG.DATA_CALCULAR(TRUNC(SYSDATE),'U',4))
          OR
          (TRUNC(au.data_ini) < TRUNC(SYSDATE) AND TRUNC(au.data_fim) >= TRUNC(SYSDATE))
         )
ORDER BY au.data_ini

;
