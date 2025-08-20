--------------------------------------------------------
--  DDL for View V_MONITORA_FATURAMENTO_PEND
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_MONITORA_FATURAMENTO_PEND" ("ORCAMENTO_ID", "JOB_ID", "NUMERO_JOB", "NOME_JOB", "PARCELA_ITEM", "VALOR_APROVADO", "DATA_STATUS_MOSTRAR", "VALOR_A_FATURAR", "VALOR_A_FATURAR_MOSTRAR", "ESTIMATIVA_CUSTO", "STATUS_DESC", "CLIENTE_ID", "NOME_CLIENTE", "CONTRATO_ID", "NOME_CONTRATO", "NOME_AUTOR", "NOME_CRIADOR", "GRUPO_CLIENTE", "EMPRESA_FATURAMENTO", "DATA_VENCIMENTO", "EMPRESA_ID") AS 
  WITH select1 AS
 (SELECT /*+ first_rows (1) */
   o.orcamento_id,
   jo.job_id,
   jo.numero AS numero_job,
   jo.numero || ' - ' || jo.nome AS nome_job,
   'Item ' || it.tipo_item || to_char(it.num_seq) || ' ' ||
   substr(char_especial_retirar(REPLACE(tp.nome || ' ' ||
                                        it.complemento,
                                        '"',
                                        ' ')),
          1,
          100) AS parcela_item,
   moeda_mostrar(it.valor_aprovado, 'S') AS valor_aprovado,
   data_mostrar(o.data_status) AS data_status_mostrar,
   it.valor_afaturar AS valor_a_faturar,
   moeda_mostrar(it.valor_afaturar, 'S') AS valor_a_faturar_mostrar,
   decode((SELECT COUNT(1)
            FROM servico s
           WHERE s.servico_id = o.servico_id),
          0,
          orcamento_pkg.numero_formatar(o.orcamento_id),
          (SELECT s.nome
             FROM servico s
            WHERE s.servico_id = o.servico_id) ||
          ' + ' ||
          orcamento_pkg.numero_formatar(o.orcamento_id)) AS estimativa_custo,
   decode(o.status,
          'PREP',
          'Em Preparação',
          'PRON',
          'Pronta',
          'ARQUI',
          'Arquivada',
          'APROV',
          'Aprovada') AS status_desc,
   jo.cliente_id,
   pe.apelido AS nome_cliente,
   jo.contrato_id,
   CASE
     WHEN ct.contrato_id IS NULL THEN
      NULL
     ELSE
      contrato_pkg.numero_formatar(ct.contrato_id) ||
      ' - ' || ct.nome
   END AS nome_contrato,
   pa.nome AS nome_autor,
   (SELECT au.nome
      FROM pessoa        au,
           orcam_usuario ou
     WHERE ou.orcamento_id = o.orcamento_id
       AND au.usuario_id = ou.usuario_id
       AND ou.atuacao = 'CRIA') AS nome_criador,
   (SELECT listagg(g.nome, ', ') within GROUP(ORDER BY g.nome)
      FROM grupo        g,
           grupo_pessoa gp
     WHERE g.grupo_id = gp.grupo_id
       AND gp.pessoa_id = ct.contratante_id
       AND g.empresa_id = ct.empresa_id) AS grupo_cliente,
   (SELECT p.nome
      FROM pessoa p
     WHERE p.pessoa_id = ct.emp_resp_id) AS empresa_faturamento,
   NULL AS data_vencimento,
   pe.empresa_id
    FROM orcamento    o,
         job          jo,
         item         it,
         tipo_produto tp,
         pessoa       pe,
         pessoa       pa,
         contrato     ct
   WHERE pe.pessoa_id = jo.cliente_id
     AND pa.pessoa_id(+) = o.usuario_autor_id
     AND o.job_id = jo.job_id
     AND o.orcamento_id = it.orcamento_id
     AND it.tipo_produto_id = tp.tipo_produto_id
     AND ct.contrato_id(+) = jo.contrato_id
     AND it.valor_afaturar > 0
     AND o.status = 'APROV'
     AND o.flag_despesa = 'N'),
select2 AS
 (SELECT /*+ first_rows (1) */
   o.orcamento_id,
   jo.job_id,
   jo.numero AS numero_job,
   jo.numero || ' - ' || jo.nome AS nome_job,
   'Parcela ' || to_char(pc.num_parcela) AS parcela_item,
   moeda_mostrar(pc.valor_parcela, 'S') valor_aprovado,
   data_mostrar(o.data_status) AS data_status_mostrar,
   NULL AS valor_a_faturar,
   NULL AS valor_a_faturar_mostrar,
   decode((SELECT COUNT(1)
            FROM servico s
           WHERE s.servico_id = o.servico_id),
          0,
          orcamento_pkg.numero_formatar(o.orcamento_id),
          (SELECT s.nome
             FROM contrato_servico c,
                  servico          s
            WHERE c.contrato_id = ct.contrato_id
              AND c.servico_id = s.servico_id
              AND c.contrato_servico_id =
                  pc.contrato_servico_id) || ' + ' ||
          orcamento_pkg.numero_formatar(o.orcamento_id)) AS estimativa_custo,
   decode(o.status,
          'PREP',
          'Em Preparação',
          'PRON',
          'Pronta',
          'ARQUI',
          'Arquivada',
          'APROV',
          'Aprovada') AS status_desc,
   jo.cliente_id,
   pe.apelido AS nome_cliente,
   jo.contrato_id,
   CASE
     WHEN ct.contrato_id IS NULL THEN
      NULL
     ELSE
      contrato_pkg.numero_formatar(ct.contrato_id) ||
      ' - ' || ct.nome
   END AS nome_contrato,
   pa.nome AS nome_autor,
   (SELECT au.nome
      FROM pessoa        au,
           orcam_usuario ou
     WHERE ou.orcamento_id = o.orcamento_id
       AND au.usuario_id = ou.usuario_id
       AND ou.atuacao = 'CRIA') AS nome_criador,
   (SELECT listagg(g.nome, ', ') within GROUP(ORDER BY g.nome)
      FROM grupo        g,
           grupo_pessoa gp
     WHERE g.grupo_id = gp.grupo_id
       AND gp.pessoa_id = ct.contratante_id
       AND g.empresa_id = ct.empresa_id) AS grupo_cliente,
   (SELECT p.nome
      FROM pessoa p
     WHERE p.pessoa_id = ct.emp_resp_id) AS empresa_faturamento,
   pc.data_vencim AS data_vencimento,
   pe.empresa_id
    FROM orcamento        o,
         job              jo,
         pessoa           pe,
         pessoa           pa,
         contrato         ct,
         parcela_contrato pc
   WHERE ct.contrato_id = pc.contrato_id
     AND ct.contrato_id = jo.contrato_id
     AND pe.pessoa_id = jo.cliente_id
     AND o.job_id = jo.job_id
     AND pa.pessoa_id = o.usuario_autor_id
     AND o.status = 'APROV'
     AND o.flag_despesa = 'N'),
select3 AS
 (SELECT /*+ first_rows (1) */
   NULL AS orcamento_id,
   NULL AS job_id,
   NULL AS numero_job,
   NULL AS nome_job,
   'Parcela ' || to_char(pc.num_parcela) AS parcela_item,
   moeda_mostrar(pc.valor_parcela, 'S') valor_aprovado,
   NULL AS data_status_mostrar,
   (contrato_pkg.valor_parcela_retornar(pc.parcela_contrato_id,'AFATURAR'))
   AS valor_a_faturar,
   NULL AS valor_a_faturar_mostrar,
   (SELECT s.nome
      FROM servico          s,
           contrato_servico cs
     WHERE s.servico_id = cs.servico_id
       AND cs.contrato_id = ct.contrato_id
       AND cs.contrato_servico_id =
           pc.contrato_servico_id) AS estimativa_custo,
   NULL AS status_desc,
   ct.contratante_id,
   pe.apelido AS nome_cliente,
   ct.contrato_id,
   CASE
     WHEN ct.contrato_id IS NULL THEN
      NULL
     ELSE
      contrato_pkg.numero_formatar(ct.contrato_id) ||
      ' - ' || ct.nome
   END AS nome_contrato,
   NULL AS nome_autor,
   NULL AS nome_criador,
   (SELECT listagg(g.nome, ', ') within GROUP(ORDER BY g.nome)
      FROM grupo        g,
           grupo_pessoa gp
     WHERE g.grupo_id = gp.grupo_id
       AND gp.pessoa_id = ct.contratante_id
       AND g.empresa_id = ct.empresa_id) AS grupo_cliente,
   (SELECT p.nome
      FROM pessoa p
     WHERE p.pessoa_id = ct.emp_resp_id) AS empresa_faturamento,
   pc.data_vencim AS data_vencimento,
   pe.empresa_id
    FROM job              jo,
         contrato         ct,
         parcela_contrato pc,
         pessoa           pe
   WHERE ct.contrato_id = pc.contrato_id
     AND pe.pessoa_id = ct.contratante_id
     AND jo.contrato_id(+) = ct.contrato_id
     AND contrato_pkg.status_parcela_retornar(pc.parcela_contrato_id) =
         'PEND')
SELECT "ORCAMENTO_ID","JOB_ID","NUMERO_JOB","NOME_JOB","PARCELA_ITEM","VALOR_APROVADO","DATA_STATUS_MOSTRAR","VALOR_A_FATURAR","VALOR_A_FATURAR_MOSTRAR","ESTIMATIVA_CUSTO","STATUS_DESC","CLIENTE_ID","NOME_CLIENTE","CONTRATO_ID","NOME_CONTRATO","NOME_AUTOR","NOME_CRIADOR","GRUPO_CLIENTE","EMPRESA_FATURAMENTO","DATA_VENCIMENTO","EMPRESA_ID"
  FROM select1
UNION ALL
SELECT "ORCAMENTO_ID","JOB_ID","NUMERO_JOB","NOME_JOB","PARCELA_ITEM","VALOR_APROVADO","DATA_STATUS_MOSTRAR","VALOR_A_FATURAR","VALOR_A_FATURAR_MOSTRAR","ESTIMATIVA_CUSTO","STATUS_DESC","CLIENTE_ID","NOME_CLIENTE","CONTRATO_ID","NOME_CONTRATO","NOME_AUTOR","NOME_CRIADOR","GRUPO_CLIENTE","EMPRESA_FATURAMENTO","DATA_VENCIMENTO","EMPRESA_ID"
  FROM select2
UNION ALL
SELECT "ORCAMENTO_ID","JOB_ID","NUMERO_JOB","NOME_JOB","PARCELA_ITEM","VALOR_APROVADO","DATA_STATUS_MOSTRAR","VALOR_A_FATURAR","VALOR_A_FATURAR_MOSTRAR","ESTIMATIVA_CUSTO","STATUS_DESC","CONTRATANTE_ID","NOME_CLIENTE","CONTRATO_ID","NOME_CONTRATO","NOME_AUTOR","NOME_CRIADOR","GRUPO_CLIENTE","EMPRESA_FATURAMENTO","DATA_VENCIMENTO","EMPRESA_ID"
  FROM select3

;
