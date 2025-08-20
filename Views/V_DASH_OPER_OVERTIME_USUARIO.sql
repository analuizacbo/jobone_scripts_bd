--------------------------------------------------------
--  DDL for View V_DASH_OPER_OVERTIME_USUARIO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_OVERTIME_USUARIO" ("USUARIO_ID", "DATA", "APELIDO", "FUNCAO", "NOME_FISICO", "PREFIXO", "NUMERO", "TOTAL_HORAS_OVERTIME", "EQUIPE_ID", "CARGO_ID", "CARGO_NOME", "HORAS_LIVRES_MESMO_CARGO") AS 
  SELECT eu.usuario_id,
       da.data,
       pe.apelido,
       us.funcao,
       ar.nome_fisico,
       vo.prefixo,
       vo.numero,
       SUM(da.horas_overtime) AS total_horas_overtime,
       eu.equipe_id,
       ca.cargo_id,
       ca.nome AS cargo_nome,
       nvl((SELECT SUM(d.horas_livre)
             FROM dia_alocacao d
            INNER JOIN equipe_usuario e
               ON e.usuario_id = d.usuario_id
            WHERE d.data = da.data
              AND e.equipe_id = eu.equipe_id
              AND cargo_pkg.do_usuario_retornar(e.usuario_id, SYSDATE, NULL) =
                  cargo_pkg.do_usuario_retornar(eu.usuario_id, SYSDATE, NULL)
              AND d.usuario_id <> eu.usuario_id),
           0) AS horas_livres_mesmo_cargo
  FROM equipe_usuario eu
 INNER JOIN dia_alocacao da
    ON da.usuario_id = eu.usuario_id
 INNER JOIN usuario us
    ON us.usuario_id = eu.usuario_id
 INNER JOIN pessoa pe
    ON pe.usuario_id = eu.usuario_id
 INNER JOIN cargo ca
    ON ca.cargo_id = cargo_pkg.do_usuario_retornar(eu.usuario_id, SYSDATE, NULL)
  LEFT JOIN arquivo_pessoa ap
    ON ap.pessoa_id = pe.pessoa_id
   AND ap.tipo_arq_pessoa = 'FOTO_USU'
   AND ap.tipo_thumb = 'P'
  LEFT JOIN arquivo ar
    ON ar.arquivo_id = ap.arquivo_id
  LEFT JOIN volume vo
    ON vo.volume_id = ar.volume_id
 WHERE eu.flag_membro = 'S'
   AND trunc(da.data) >= trunc(SYSDATE)
   AND trunc(da.data) <= util_pkg.data_calcular(trunc(SYSDATE), 'U', 4)
   AND da.horas_overtime > 0
 GROUP BY da.data,
          eu.usuario_id,
          da.data,
          da.horas_diarias,
          pe.apelido,
          us.funcao,
          ar.nome_fisico,
          vo.prefixo,
          vo.numero,
          eu.equipe_id,
          ca.cargo_id,
          ca.nome

;
