--------------------------------------------------------
--  DDL for View V_DASH_OPER_TIMESHEET
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_TIMESHEET" ("APELIDO", "FUNCAO", "EMAIL", "NOME_FISICO", "PREFIXO", "NUMERO", "QUANTIDADE_EM_ATRASO", "DATA_DESDE", "EQUIPE_ID") AS 
  SELECT pe.apelido,
         us.funcao,
         pe.email,
         ar.nome_fisico,
         vo.prefixo,
         vo.numero,
         COUNT(*) AS quantidade_em_atraso,
         CASE
           WHEN EXTRACT(YEAR FROM MIN(ad.data)) < EXTRACT(YEAR FROM MIN(SYSDATE))
             THEN DATA_MOSTRAR(MIN(ad.data))
           ELSE TO_CHAR(MIN(ad.data),'dd/mm')
         END AS data_desde,
         eq.equipe_id
    FROM equipe eq
         INNER JOIN equipe_usuario eu ON eu.equipe_id = eq.equipe_id
         INNER JOIN usuario us ON us.usuario_id = eu.usuario_id
         INNER JOIN pessoa pe ON pe.usuario_id = eu.usuario_id
         INNER JOIN apontam_data ad ON ad.usuario_id = eu.usuario_id
          LEFT JOIN arquivo_pessoa ap ON ap.pessoa_id = pe.pessoa_id
                    AND ap.tipo_arq_pessoa = 'FOTO_USU'
                    AND ap.tipo_thumb = 'P'
          LEFT JOIN arquivo ar ON ar.arquivo_id = ap.arquivo_id
          LEFT JOIN volume vo ON vo.volume_id = ar.volume_id
   WHERE flag_membro = 'S'
     AND ad.status IN ('PEND','APON','REPR')
     AND TRUNC(ad.data) < TRUNC(SYSDATE)
GROUP BY pe.apelido,
         us.funcao,
         pe.email,
         ar.nome_fisico,
         vo.prefixo,
         vo.numero,
         eq.equipe_id
ORDER BY pe.apelido

;
