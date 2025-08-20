--------------------------------------------------------
--  DDL for View V_USUARIOS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_USUARIOS" ("EMPRESA_ID", "USUARIO_ID", "APELIDO", "NOME", "USUARIO_LOGIN", "FUNCAO", "PAPEL_NOME", "AREA", "CARGO_NOME", "CARGO_AREA", "CARGO_NIVEL", "FLAG_EMAIL_BLOQ", "FLAG_ATIVO", "COD_EXT_USUARIO", "DEPARTAMENTO_NOME", "AREA_USUARIO", "CATEGORIA", "TIPO_RELACAO", "COD_FUNCIONARIO", "EMPRESA_PADRAO", "FERIADOS", "DATA_APONTAM_INI", "DATA_APONTAM_FIM", "FLAG_SEM_BLOQ_APONT", "FLAG_SEM_BLOQ_APROV", "SUBMETER_HORAS_APROV", "FLAG_PERMITE_HOME", "MIN_HORAS_APONT_DIA", "NUM_HORAS_PROD_DIA", "FLAG_ADMIN", "FLAG_ADMIN_SISTEMA", "EMAIL") AS 
  SELECT em.empresa_id,
       us.usuario_id,
       pe.apelido,
       pe.nome,
       us.login as usuario_login,
       us.funcao,
       (SELECT LISTAGG(p.nome,', ') WITHIN GROUP (ORDER BY p.nome)
          FROM papel         p,
               area          a,
               usuario_papel up
         WHERE p.empresa_id   = em.empresa_id
           AND p.papel_id     = up.papel_id
           AND p.area_id      = a.area_id
           AND up.usuario_id  = us.usuario_id) AS papel_nome,
       (SELECT LISTAGG(a.nome, ', ') WITHIN GROUP (ORDER BY a.nome)
        FROM (SELECT DISTINCT a.nome
            FROM area a, papel p, usuario_papel up
            WHERE a.empresa_id = em.empresa_id
              AND a.area_id = p.area_id
              AND p.papel_id = up.papel_id
              AND up.usuario_id = us.usuario_id
        ) a) as area,
       (SELECT c.nome
          FROM cargo   c,
               usuario_cargo uc
         WHERE c.cargo_id = uc.cargo_id
           AND c.empresa_id = em.empresa_id
           AND uc.usuario_id = us.usuario_id
           AND uc.data_fim   IS NULL) AS cargo_nome,
        (SELECT ar.nome
          FROM cargo   c,
               usuario_cargo uc,
               area ar
         WHERE c.cargo_id = uc.cargo_id
           AND c.empresa_id = em.empresa_id
           AND uc.usuario_id = us.usuario_id
           AND c.area_id = ar.area_id
           AND uc.data_fim   IS NULL) AS cargo_area,
        (SELECT di.descricao
          FROM cargo   c,
               usuario_cargo uc,
               dicionario di
         WHERE c.cargo_id = uc.cargo_id
           AND c.empresa_id = em.empresa_id
           AND uc.usuario_id = us.usuario_id
           AND di.codigo = uc.nivel
           AND di.tipo = 'nivel_usuario'
           AND uc.data_fim   IS NULL) AS cargo_nivel,
       us.flag_email_bloq,
       us.flag_ativo,
       us.cod_ext_usuario,
       (SELECT de.nome
          FROM departamento de
         WHERE de.departamento_id = us.departamento_id) AS departamento_nome,
       (SELECT ar.nome
          FROM area ar
         WHERE ar.empresa_id = em.empresa_id
           AND ar.area_id    = us.area_id) AS area_usuario,
       us.categoria,
       CASE
          WHEN us.tipo_relacao = 'CPGAGE' THEN
             'Colaborador Pago Pela Agência'
          WHEN us.tipo_relacao = 'CPGCLI' THEN
             'Colaborador Pago Pelo Cliente'
          WHEN us.tipo_relacao = 'FREELA' THEN
             'Freelancer'
       END AS tipo_relacao,
       us.cod_funcionario,
       (SELECT e.nome
          FROM empresa e,
               usuario_empresa ue
         WHERE e.empresa_id    = ue.empresa_id
           AND e.empresa_id    = em.empresa_id
           AND ue.usuario_id   = us.usuario_id
           AND ue.empresa_id   = em.empresa_id
           AND ue.flag_padrao  = 'S') AS empresa_padrao,
       (SELECT LISTAGG(f.nome,', ') WITHIN GROUP (ORDER BY f.nome)
          FROM tab_feriado f
         WHERE f.tab_feriado_id = us.tab_feriado_id
           AND f.empresa_id     = em.empresa_id) AS feriados,
        data_mostrar(us.data_apontam_ini) AS data_apontam_ini,
        data_mostrar(us.data_apontam_fim) AS data_apontam_fim,
        DECODE(us.flag_sem_bloq_apont, 'S', 'Não Bloquear', 'N', 'Bloquear') AS flag_sem_bloq_apont,
        DECODE(us.flag_sem_bloq_aprov, 'S', 'Não Bloquear', 'N', 'Bloquear') AS flag_sem_bloq_aprov,
        DECODE(us.flag_sem_aprov_horas, 'S', 'Não', 'N', 'Sim') AS submeter_horas_aprov,
        us.flag_permite_home,
        CASE
          WHEN numero_mostrar(us.min_horas_apont_dia, 2,'S') IS NULL THEN
            numero_mostrar(EMPRESA_PKG.parametro_retornar(em.empresa_id, 'NUM_MIN_HORAS_APONTADAS_DIA'), 2,'S')
          ELSE
            numero_mostrar(us.min_horas_apont_dia, 2,'S')
        END AS min_horas_apont_dia,
        CASE
          WHEN to_char(us.num_horas_prod_dia) IS NULL THEN
             numero_mostrar(EMPRESA_PKG.parametro_retornar(em.empresa_id, 'NUM_HORAS_PRODUTIVAS'), 2,'S')
          ELSE
             numero_mostrar(us.num_horas_prod_dia, 2, 'S')
         END AS num_horas_prod_dia,
         us.flag_admin,
         us.flag_admin_sistema AS flag_admin_sistema,
         pe.email as email
   FROM usuario         us,
        empresa         em,
        pessoa          pe
  WHERE pe.empresa_id = em.empresa_id
    AND us.usuario_id = pe.usuario_id

;
