--------------------------------------------------------
--  DDL for View V_DASH_OPER_ATRASOS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_DASH_OPER_ATRASOS" ("EMPRESA_ID", "EQUIPE_ID", "GRUPO_CLIENTE", "GRUPO_CLIENTE_ID", "APELIDO", "FUNCAO", "USUARIO_ID", "HORAS") AS 
  SELECT
         jo.empresa_id,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO'
            THEN NVL((SELECT LISTAGG(x.equipe_id,', ') WITHIN GROUP (ORDER BY x.equipe_id)
                        FROM equipe_usuario x
                       WHERE x.usuario_id = ou.usuario_id
                         AND x.flag_membro = 'S'),'-')
           WHEN ic.cod_objeto = 'TAREFA'
            THEN NVL((SELECT LISTAGG(x.equipe_id,', ') WITHIN GROUP (ORDER BY x.equipe_id)
                        FROM equipe_usuario x
                       WHERE x.usuario_id = tu.usuario_id
                         AND x.flag_membro = 'S'),'-')
         END AS equipe_id,
         NVL((SELECT LISTAGG(gr.nome,', ') WITHIN GROUP (ORDER BY gr.nome)
                FROM grupo gr
                     INNER JOIN grupo_pessoa gp ON gr.grupo_id = gp.grupo_id
               WHERE gp.pessoa_id = cl.pessoa_id
                 AND gr.flag_agrupa_cnpj = 'S'),cl.apelido) AS grupo_cliente,
         NVL((SELECT LISTAGG(gr.grupo_id,', ') WITHIN GROUP (ORDER BY gr.nome)
                FROM grupo gr
                     INNER JOIN grupo_pessoa gp ON gr.grupo_id = gp.grupo_id
               WHERE gp.pessoa_id = cl.pessoa_id
                 AND gr.flag_agrupa_cnpj = 'S'),cl.pessoa_id) AS grupo_cliente_id,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' THEN op.apelido
           WHEN ic.cod_objeto = 'TAREFA' THEN tp.apelido
         END AS apelido,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' THEN ou.funcao
           WHEN ic.cod_objeto = 'TAREFA' THEN tu.funcao
         END AS funcao,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' THEN ou.usuario_id
           WHEN ic.cod_objeto = 'TAREFA' THEN tu.usuario_id
         END AS usuario_id,
         CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' THEN
                NVL((SELECT SUM(u.horas_planej)
                       FROM os_usuario u
                      WHERE u.ordem_servico_id = ic.objeto_id),0)
           WHEN ic.cod_objeto = 'TAREFA' THEN
                NVL((SELECT SUM(u.horas_totais)
                       FROM tarefa_usuario u
                      WHERE u.tarefa_id = ic.objeto_id),0)
           ELSE NVL((SELECT SUM(h.horas_totais)
                       FROM item_crono_usu h
                      WHERE h.item_crono_id = ic.item_crono_id),0)
         END AS horas
    FROM item_crono ic
         INNER JOIN cronograma cr ON ic.cronograma_id = cr.cronograma_id
         INNER JOIN job jo ON jo.job_id = cr.job_id
         INNER JOIN pessoa cl ON cl.pessoa_id = jo.cliente_id
          LEFT JOIN ordem_servico os ON os.ordem_servico_id = ic.objeto_id AND ic.cod_objeto = 'ORDEM_SERVICO'
          LEFT JOIN os_usuario oi ON oi.ordem_servico_id = os.ordem_servico_id
          LEFT JOIN pessoa op on op.usuario_id = oi.usuario_id
          LEFT JOIN usuario ou on ou.usuario_id = op.usuario_id
          LEFT JOIN tarefa ta ON ta.tarefa_id = ic.objeto_id AND ic.cod_objeto = 'TAREFA'
          LEFT JOIN tarefa_usuario ti ON ti.tarefa_id = ta.tarefa_id
          LEFT JOIN pessoa tp on tp.usuario_id = ti.usuario_para_id
          LEFT JOIN usuario tu on tu.usuario_id = tp.usuario_id
   WHERE ic.cod_objeto IN ('ORDEM_SERVICO','TAREFA')
     AND ic.objeto_id IS NOT NULL
     AND cr.status <> 'ARQUI'
     AND (NVL(os.status,'OK') IN ('DIST','ACEI','EMEX','AVAL')
         OR NVL(ta.status,'OK') = 'EMEX')
     AND jo.status <> 'CANC'
     --AND oi.tipo_ender = 'EXE'
     AND CASE
           WHEN ic.cod_objeto = 'ORDEM_SERVICO' THEN os.data_solicitada
           WHEN ic.cod_objeto = 'TAREFA' THEN ta.data_termino
         END < SYSDATE

;
