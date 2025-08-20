--------------------------------------------------------
--  DDL for View V_HORAS_VEND_CONTR_UTIL
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_HORAS_VEND_CONTR_UTIL" ("OP_EMPRESA", "OP_CLIENTE", "OP_NUMERO", "OP_NOME", "OP_ORIGEM", "OP_TIPO_NEGOCIO", "OP_CONFLITO_CLIENTE_CASA", "OP_SERVICO", "OP_SERVICO_VALOR", "OP_SERVICO_DURACAO", "OP_SERVICO_HONORARIO", "OP_SERVICO_TAXA", "OP_SERVICO_MES_INICIO", "OP_AREA", "OP_CARGO", "OP_CARGO_NIVEL", "OP_CARGO_NOME_ALTERNATIVO", "OP_HORAS_TOTAIS", "OP_CUSTO_HORAS", "OP_CUSTO_TOTAL", "OP_PRECO_VENDA", "OP_PRECO_FINAL", "CT_EMPRESA", "CT_CLIENTE", "CT_NUMERO", "CT_NOME", "CT_TIPO_CONTRATO", "CT_DATA_ENTRADA", "CT_DATA_TERMINO", "CT_STATUS", "CT_HORAS_PLANEJ", "CT_CUSTO_HORA_PDR", "CT_VENDA_HORA_PDR", "CT_VENDA_HORA_REV", "CT_AREA", "CT_CARGO", "CT_CARGO_NIVEL", "CT_CARGO_NOME_ALTERNATIVO", "CT_CARGO_ID", "CT_NIVEL", "CT_OPORTUNIDADE_ID", "CT_SERVICO_ID", "TS_HORAS_UTILIZADAS") AS 
  WITH
  HORAS_VENDIDAS AS (
  SELECT pe.nome AS op_cliente, op.numero AS op_numero, op.nome AS op_nome, ori.descricao AS op_origem, tne.descricao AS op_tipo_negocio,
         DECODE(op.flag_conflito,'S','Sim','N','Não','N/A') AS op_conflito_cliente_casa,
         se.nome AS op_servico, cs.valor_servico AS op_servico_valor, cs.duracao_meses AS op_servico_duracao,
         cs.honorario AS op_servico_honorario, cs.taxa AS op_servico_taxa, cs.mes_ano_inicio AS op_servico_mes_inicio,
         ar.nome AS op_area, cg.nome as op_cargo, niv.descricao AS op_cargo_nivel, ch.nome_alternativo AS op_cargo_nome_alternativo,
         ch.horas_totais AS op_horas_totais, ch.custo_hora AS op_custo_horas, ch.custo_total AS op_custo_total,
         ch.preco_venda AS op_preco_venda, ch.preco_final AS op_preco_final,
         cg.cargo_id AS op_cargo_id, ch.nivel AS op_nivel, op.oportunidade_id AS op_oportunidade_id, se.servico_id AS op_servico_id,
         em.nome AS op_empresa
    FROM cenario ce
         INNER JOIN oportunidade op ON op.oportunidade_id = ce.oportunidade_id
         INNER JOIN cenario_servico cs ON cs.cenario_id = ce.cenario_id
         INNER JOIN cenario_servico_horas ch ON ch.cenario_servico_id = cs.cenario_servico_id
         INNER JOIN dicionario ori ON ori.codigo = op.origem AND ori.tipo = 'oportunidade_origem'
         INNER JOIN dicionario tne ON tne.codigo = op.tipo_negocio AND tne.tipo = 'oportunidade_tipo_negocio'
         INNER JOIN servico se ON se.servico_id = cs.servico_id
         INNER JOIN area ar ON ar.area_id = ch.area_id
         INNER JOIN cargo cg ON cg.cargo_id = ch.cargo_id
         INNER JOIN dicionario niv ON niv.codigo = ch.nivel AND niv.tipo = 'nivel_usuario'
         INNER JOIN pessoa pe ON pe.pessoa_id = op.cliente_id
         INNER JOIN empresa em ON em.empresa_id = op.empresa_id
   WHERE op.status = 'CONC'
     AND op.tipo_conc = 'GAN'
     AND ce.flag_padrao = 'S'),
  HORAS_CONTRATADAS AS (
  SELECT pe.nome AS ct_cliente, CONTRATO_PKG.NUMERO_FORMATAR(ct.numero) AS ct_numero, ct.nome AS ct_nome,
         tc.nome AS ct_tipo_contrato, ct.data_entrada AS ct_data_entrada, ct.data_termino AS ct_data_termino, ct.status AS ct_status,
         ch.horas_planej AS ct_horas_planej,
         UTIL_PKG.NUM_DECODE(ch.custo_hora_pdr,'C06C35872C9B409A8AB38C7A7E360F3C') AS ct_custo_hora_pdr,
         UTIL_PKG.NUM_DECODE(ch.venda_hora_pdr,'C06C35872C9B409A8AB38C7A7E360F3C') AS ct_venda_hora_pdr,
         UTIL_PKG.NUM_DECODE(ch.venda_hora_rev,'C06C35872C9B409A8AB38C7A7E360F3C') AS ct_venda_hora_rev,
         ar.nome AS ct_area, cg.nome as ct_cargo, niv.descricao AS ct_cargo_nivel, ch.descricao AS ct_cargo_nome_alternativo,
         cg.cargo_id AS ct_cargo_id, ch.nivel AS ct_nivel, oc.oportunidade_id AS ct_oportunidade_id, oc.contrato_id AS ct_contrato_id,
         cs.servico_id AS ct_servico_id, em.nome AS ct_empresa
    FROM contrato_horas ch
         INNER JOIN area ar ON ar.area_id = ch.area_id
         INNER JOIN cargo cg ON cg.cargo_id = ch.cargo_id
         INNER JOIN dicionario niv ON niv.codigo = ch.nivel AND niv.tipo = 'nivel_usuario'
         INNER JOIN contrato_servico cs ON cs.contrato_servico_id = ch.contrato_servico_id
         INNER JOIN contrato ct ON ct.contrato_id = ch.contrato_id
         INNER JOIN pessoa pe ON pe.pessoa_id = ct.contratante_id
         INNER JOIN tipo_contrato tc ON tc.tipo_contrato_id = ct.tipo_contrato_id
         INNER JOIN empresa em ON em.empresa_id = ct.empresa_id
          LEFT JOIN oport_contrato oc ON oc.contrato_id = ch.contrato_id),
  HORAS_UTILIZADAS AS (
  SELECT SUM(horas) as ts_horas_utilizadas, ad.cargo_id AS ts_cargo_id, NVL(ad.nivel,'NA') AS ts_nivel,
         jo.contrato_id AS ts_contrato_id, jo.servico_id AS ts_servico_id
    FROM apontam_hora ah
         INNER JOIN apontam_data ad ON ad.apontam_data_id = ah.apontam_data_id
         INNER JOIN cargo cg ON cg.cargo_id = ad.cargo_id
         INNER JOIN job jo ON jo.job_id = ah.job_id
   WHERE jo.contrato_id IS NOT NULL
     AND jo.servico_id IS NOT NULL
   GROUP BY ad.cargo_id, ad.nivel, jo.contrato_id, jo.servico_id)
  SELECT op_empresa, op_cliente, hv.op_numero, hv.op_nome, hv.op_origem, hv.op_tipo_negocio,
         hv.op_conflito_cliente_casa,
         hv.op_servico, hv.op_servico_valor, hv.op_servico_duracao,
         hv.op_servico_honorario, hv.op_servico_taxa, hv.op_servico_mes_inicio,
         hv.op_area, hv.op_cargo, hv.op_cargo_nivel, hv.op_cargo_nome_alternativo,
         hv.op_horas_totais, hv.op_custo_horas, hv.op_custo_total,
         hv.op_preco_venda, hv.op_preco_final,
         hc.ct_empresa, hc.ct_cliente, hc.ct_numero, hc.ct_nome,
         hc.ct_tipo_contrato, hc.ct_data_entrada, hc.ct_data_termino, hc.ct_status,
         hc.ct_horas_planej, hc.ct_custo_hora_pdr, hc.ct_venda_hora_pdr, hc.ct_venda_hora_rev,
         hc.ct_area, hc.ct_cargo, hc.ct_cargo_nivel, hc.ct_cargo_nome_alternativo,
         hc.ct_cargo_id, hc.ct_nivel, hc.ct_oportunidade_id, hc.ct_servico_id,
         hu.ts_horas_utilizadas
    FROM horas_vendidas hv
         FULL JOIN horas_contratadas hc
                     ON hc.ct_cargo_id = hv.op_cargo_id
                    AND hc.ct_nivel = hv.op_nivel
                    AND hc.ct_oportunidade_id = hv.op_oportunidade_id
                    AND hc.ct_servico_id = hv.op_servico_id
         INNER JOIN horas_utilizadas hu
                     ON hu.ts_cargo_id = hc.ct_cargo_id
                    AND hu.ts_nivel = hc.ct_nivel
                    AND hu.ts_contrato_id = hc.ct_contrato_id
                    AND hu.ts_servico_id = hc.ct_servico_id

;
