--------------------------------------------------------
--  DDL for View V_ANALISE_ITENS_ORCAMENTO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_ANALISE_ITENS_ORCAMENTO" ("TIPO_LINHA", "ORDEM_LINHA", "EMPRESA", "JOB_NUMERO", "JOB_NOME", "JOB_TIPO", "JOB_PRODUTO", "JOB_DATA_ENTRADA", "JOB_DATA_PREVISTA_INICIO", "JOB_DATA_PREVISTA_FIM", "JOB_STATUS", "STATUS_CHECKIN", "STATUS_CHECKIN_DATA", "STATUS_FATURAMENTO", "STATUS_FATURAMENTO_DATA", "CLIENTE", "ORCAMENTO", "ITEM_TIPO", "ITEM_TIPO_DESCRICAO", "ITEM_NUMERO", "ITEM_DESCRICAO", "ORDEM_GRUPO", "GRUPO", "ORDEM_SUBGRUPO", "SUBGRUPO", "PAGO_PELO_CLIENTE", "CARTA_ACORDO_DESCRICAO", "CARTA_ACORDO_STATUS", "CARTA_ACORDO_OK_VERIFICAR", "CARTA_ACORDO_LEGENDA_RETORNAR", "FORNECEDOR", "TIPO_FATURAMENTO_BV_TIP", "NOTA_FISCAL_NUMERO", "NOTA_FISCAL_SERIE", "VALOR_ITEM_APROVADO", "VALOR_ITEM_FORNECEDOR", "VALOR_ITEM_BV", "VALOR_ITEM_TIP", "VALOR_ITEM_EMITIDO", "VALOR_ITEM_SOBRA", "VALOR_ITEM_SALDO", "VALOR_ITEM_UTILIZADO", "VALOR_CA_APROVADO", "VALOR_CA_FORNECEDOR", "VALOR_CA_BV", "VALOR_CA_TIP", "VALOR_NF_APROVADO", "VALOR_NF_FORNECEDOR", "VALOR_NF_BV", "VALOR_NF_TIP") AS 
  SELECT 'ITEM' AS tipo_linha,
             1 AS ordem_linha,
             em.nome AS empresa,
             jo.numero AS job_numero,
             jo.nome AS job_nome,
             tj.nome AS job_tipo,
             pc.nome AS job_produto,
             DATA_MOSTRAR(jo.data_entrada) AS job_data_entrada,
             DATA_MOSTRAR(jo.data_prev_ini) AS job_data_prevista_inicio,
             DATA_MOSTRAR(jo.data_prev_fim) AS job_data_prevista_fim,
             st.descricao AS job_status,
             DECODE(jo.status_checkin,'A','Aberto','F','Fechado') AS status_checkin,
             DATA_MOSTRAR(jo.data_status_checkin) AS status_checkin_data,
             DECODE(jo.status_fatur,'A','Aberto','F','Fechado') AS status_faturamento,
             DATA_MOSTRAR(jo.data_status_fatur) AS status_faturamento_data,
             cl.apelido AS cliente,
             oc.num_orcamento AS orcamento,
             it.tipo_item AS item_tipo,
             util_pkg.desc_retornar('tipo_item',it.tipo_item) AS item_tipo_descricao,
             it.tipo_item || it. num_seq AS item_numero,
             it.tipo_item || it.num_seq || '. ' || tp.nome || ' ' || it.complemento AS item_descricao,
             it.ordem_grupo,
             it.grupo,
             it.ordem_subgrupo,
             it.subgrupo,
             DECODE(it.flag_pago_cliente,'S','Sim','N','Não') AS pago_pelo_cliente,
             'NA' AS carta_acordo_descricao,
             'NA' AS carta_acordo_status,
             0 AS carta_acordo_ok_verificar,
             'NA' carta_acordo_legenda_retornar,
             'NA' fornecedor,
             'NA' tipo_faturamento_bv_tip,
             'NA' AS nota_fiscal_numero,
             'NA' AS nota_fiscal_serie,
             --ITEM
             it.valor_aprovado AS valor_item_aprovado,
             it.valor_fornecedor AS valor_item_fornecedor,
             item_pkg.valor_realizado_retornar(it.item_id,'BV') AS valor_item_bv,
             item_pkg.valor_realizado_retornar(it.item_id,'TIP') AS valor_item_tip,
             item_pkg.valor_retornar(it.item_id,0,'COM_CA') AS valor_item_emitido,
             item_pkg.valor_retornar(it.item_id,0,'SOBRA') AS valor_item_sobra,
             it.valor_aprovado  - item_pkg.valor_reservado_retornar(it.item_id,'APROVADO') AS valor_item_saldo,
             item_pkg.valor_reservado_retornar(it.item_id,'APROVADO') AS valor_item_utilizado,
             --CARTA_ACORDO
             0 AS valor_ca_aprovado,
             0 AS valor_ca_fornecedor,
             0 AS valor_ca_bv,
             0 AS valor_ca_tip,
             --NOTA_FISCAL
             0 AS valor_nf_aprovado,
             0 AS valor_nf_fornecedor,
             0 AS valor_nf_bv,
             0 AS valor_nf_tip
        FROM item it,
             job jo,
             tipo_produto tp,
             tipo_job tj,
             pessoa cl,
             dicionario st,
             produto_cliente pc,
             empresa em,
             orcamento oc
       WHERE jo.job_id = it.job_id
         AND it.natureza_item = 'CUSTO'
         AND it.tipo_produto_id = tp.tipo_produto_id
         AND tj.tipo_job_id = jo.tipo_job_id
         AND cl.pessoa_id = jo.cliente_id
         AND st.codigo = jo.status
         AND st.tipo = 'status_job'
         AND pc.produto_cliente_id = jo.produto_cliente_id
         AND jo.empresa_id = em.empresa_id
         AND it.orcamento_id = oc.orcamento_id
         AND oc.status = 'APROV'
--
-- CARTA ACORDO
--
UNION
      SELECT 'CARTA ACORDO' AS tipo_linha,
             2 AS ordem_linha,
             em.nome AS empresa,
             jo.numero AS job_numero,
             jo.nome AS job_nome,
             tj.nome AS job_tipo,
             pc.nome AS job_produto,
             DATA_MOSTRAR(jo.data_entrada) AS job_data_entrada,
             DATA_MOSTRAR(jo.data_prev_ini) AS job_data_prevista_inicio,
             DATA_MOSTRAR(jo.data_prev_fim) AS job_data_prevista_fim,
             st.descricao AS job_status,
             DECODE(jo.status_checkin,'A','Aberto','F','Fechado') AS status_checkin,
             DATA_MOSTRAR(jo.data_status_checkin) AS status_checkin_data,
             DECODE(jo.status_fatur,'A','Aberto','F','Fechado') AS status_faturamento,
             DATA_MOSTRAR(jo.data_status_fatur) AS status_faturamento_data,
             cl.apelido AS cliente,
             oc.num_orcamento AS orcamento,
             it.tipo_item AS item_tipo,
             util_pkg.desc_retornar('tipo_item',it.tipo_item) AS item_tipo_descricao,
             it.tipo_item || it. num_seq AS item_numero,
             it.tipo_item || it.num_seq || '. ' || tp.nome || ' ' || it.complemento AS item_descricao,
             it.ordem_grupo,
             it.grupo,
             it.ordem_subgrupo,
             it.subgrupo,
             DECODE(it.flag_pago_cliente,'S','Sim','N','Não') AS pago_pelo_cliente,
             DECODE(ca.status,'EMEMIS','Carta Acordo ','EMITIDA','Carta Acordo ','AO ') ||
                    carta_acordo_pkg.numero_formatar(ca.carta_acordo_id) AS carta_acordo_descricao,
             ca.status AS carta_acordo_status,
             item_pkg.carta_acordo_ok_verificar(it.item_id) AS carta_acordo_ok_verificar,
             carta_acordo_pkg.legenda_retornar(ca.carta_acordo_id) AS carta_acordo_legenda_retornar,
             pe.apelido AS fornecedor,
             DECODE(ca.tipo_fatur_bv,'FAT','A Faturar','ABA','A Abater') AS tipo_faturamento_bv_tip,
             'NA' AS nota_fiscal_numero,
             'NA' AS nota_fiscal_serie,
             --ITEM
             0 AS valor_item_aprovado,
             0 AS valor_item_fornecedor,
             0 AS valor_item_bv,
             0 AS valor_item_tip,
             0 AS valor_item_emitido,
             0 AS valor_item_sobra,
             0 AS valor_item_saldo,
             0 AS valor_item_utilizado,
             --CARTA_ACORDO
             ca.valor_aprovado AS valor_ca_aprovado,
             ca.valor_fornecedor AS valor_ca_fornecedor,
             item_pkg.valor_retornar(it.item_id,ca.carta_acordo_id,'BV') AS valor_ca_bv,
             item_pkg.valor_retornar(it.item_id,ca.carta_acordo_id,'TIP') AS valor_ca_tip,
             --NOTA_FISCAL
             0 AS valor_nf_aprovado,
             0 AS valor_nf_fornecedor,
             0 AS valor_nf_bv,
             0 AS valor_nf_tip
        FROM item it,
             item_carta ic,
             carta_acordo ca,
             job jo,
             pessoa pe,
             tipo_produto tp,
             tipo_job tj,
             pessoa cl,
             dicionario st,
             produto_cliente pc,
             empresa em,
             orcamento oc
       WHERE jo.job_id = it.job_id
         AND it.natureza_item = 'CUSTO'
         AND it.item_id = ic.item_id (+)
         AND ic.carta_acordo_id = ca.carta_acordo_id (+)
         AND ca.fornecedor_id = pe.pessoa_id (+)
         AND it.tipo_produto_id = tp.tipo_produto_id
         AND tj.tipo_job_id = jo.tipo_job_id
         AND cl.pessoa_id = jo.cliente_id
         AND st.codigo = jo.status
         AND st.tipo = 'status_job'
         AND pc.produto_cliente_id = jo.produto_cliente_id
         AND jo.empresa_id = em.empresa_id
         AND it.orcamento_id = oc.orcamento_id
         AND oc.status = 'APROV'
--
-- NOTA FISCAL
--
UNION
      SELECT 'NOTA FISCAL' AS tipo_linha,
             3 AS ordem_linha,
             em.nome AS empresa,
             jo.numero AS job_numero,
             jo.nome AS job_nome,
             tj.nome AS job_tipo,
             pc.nome AS job_produto,
             DATA_MOSTRAR(jo.data_entrada) AS job_data_entrada,
             DATA_MOSTRAR(jo.data_prev_ini) AS job_data_prevista_inicio,
             DATA_MOSTRAR(jo.data_prev_fim) AS job_data_prevista_fim,
             st.descricao AS job_status,
             DECODE(jo.status_checkin,'A','Aberto','F','Fechado') AS status_checkin,
             DATA_MOSTRAR(jo.data_status_checkin) AS status_checkin_data,
             DECODE(jo.status_fatur,'A','Aberto','F','Fechado') AS status_faturamento,
             DATA_MOSTRAR(jo.data_status_fatur) AS status_faturamento_data,
             cl.apelido AS cliente,
             oc.num_orcamento AS orcamento,
             it.tipo_item AS item_tipo,
             util_pkg.desc_retornar('tipo_item',it.tipo_item) AS item_tipo_descricao,
             it.tipo_item || it. num_seq AS item_numero,
             it.tipo_item || it.num_seq || '. ' || tp.nome || ' ' || it.complemento AS item_descricao,
             it.ordem_grupo,
             it.grupo,
             it.ordem_subgrupo,
             it.subgrupo,
             DECODE(it.flag_pago_cliente,'S','Sim','N','Não') AS pago_pelo_cliente,
             'NA' AS carta_acordo_descricao,
             'NA' AS carta_acordo_status,
             0 AS carta_acordo_ok_verificar,
             'NA' carta_acordo_legenda_retornar,
             'NA' fornecedor,
             'NA' tipo_faturamento_bv_tip,
             nf.num_doc AS nota_fiscal_numero,
             nf.serie AS nota_fiscal_serie,
             --ITEM
             0 AS valor_item_aprovado,
             0 AS valor_item_fornecedor,
             0 AS valor_item_bv,
             0 AS valor_item_tip,
             0 AS valor_item_emitido,
             0 AS valor_item_sobra,
             0 AS valor_item_saldo,
             0 AS valor_item_utilizado,
             --CARTA_ACORDO
             0 AS valor_ca_aprovado,
             0 AS valor_ca_fornecedor,
             0 AS valor_ca_bv,
             0 AS valor_ca_tip,
             --NOTA_FISCAL
             io.valor_aprovado AS valor_nf_aprovado,
             io.valor_fornecedor AS valor_nf_fornecedor,
             io.valor_bv AS valor_nf_bv,
             io.valor_tip AS valor_nf_tip
        FROM item it,
             item_nota io,
             nota_fiscal nf,
             job jo,
             pessoa pe,
             tipo_produto tp,
             tipo_job tj,
             pessoa cl,
             dicionario st,
             produto_cliente pc,
             empresa em,
             orcamento oc
       WHERE jo.job_id = it.job_id
         AND it.natureza_item = 'CUSTO'
         AND it.item_id = io.item_id (+)
         AND io.nota_fiscal_id = nf.nota_fiscal_id (+)
         AND nf.emp_emissora_id = pe.pessoa_id (+)
         AND it.tipo_produto_id = tp.tipo_produto_id
         AND tj.tipo_job_id = jo.tipo_job_id
         AND cl.pessoa_id = jo.cliente_id
         AND st.codigo = jo.status
         AND st.tipo = 'status_job'
         AND pc.produto_cliente_id = jo.produto_cliente_id
         AND jo.empresa_id = em.empresa_id
         AND it.orcamento_id = oc.orcamento_id
         AND oc.status = 'APROV'
ORDER BY 4, 17, 20, 2

;
