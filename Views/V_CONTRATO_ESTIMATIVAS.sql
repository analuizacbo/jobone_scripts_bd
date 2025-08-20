--------------------------------------------------------
--  DDL for View V_CONTRATO_ESTIMATIVAS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CONTRATO_ESTIMATIVAS" ("CONTRATO_ID", "CONTRATO_HORAS_ID", "AREA_ID", "AREA", "ORDEM_CARGO_USUARIO", "CARGO", "CARGO_ORDEM", "CARGO_ID", "DESCRICAO", "USUARIO", "USUARIO_ID", "NIVEL", "NIVEL_CODIGO", "NIVEL_ORDEM", "DATA", "MES", "MES_NOME", "ANO", "HORAS_PLANEJ", "PRECO_SUGERIDO", "FATOR", "PRECO_UNITARIO", "SERVICO_NOME", "CONTRATO_SERVICO_ID", "SERVICO_DESCRICAO", "SERVICO_DATA_INICIO", "SERVICO_DATA_TERMINO", "SERVICO_EMPRESA_FATURAMENTO", "SERVICO_CODIGO_EXTERNO") AS 
  SELECT NVL(ch.contrato_id,cs.contrato_id) AS contrato_id,
          ch.contrato_horas_id,
          ar.area_id,
          ar.nome AS area,
          DECODE(us.usuario_id,NULL,1,2) AS ordem_cargo_usuario,
          NVL(ca.nome,'-') AS cargo,
          NVL(ca.ordem,0) AS cargo_ordem,
          ch.cargo_id,
          ch.descricao,
          NVL(us.apelido,'-') AS usuario,
          us.usuario_id,
          nv.descricao AS nivel,
          nv.codigo AS nivel_codigo,
          nv.ordem AS nivel_ordem,
          ch.data,
          to_char(ch.data,'MM') AS mes,
          to_char(ch.data,'MON') AS mes_nome,
          to_char(ch.data,'YYYY') AS ano,
          ch.horas_planej,
          ch.venda_hora_pdr AS preco_sugerido,
          ch.venda_fator_ajuste AS fator,
          ch.venda_hora_rev AS preco_unitario,
          NVL(se.nome,'-') AS servico_nome,
          cs.contrato_servico_id,
          NVL(cs.descricao,'-') AS servico_descricao,
          DATA_MOSTRAR(cs.data_inicio) AS servico_data_inicio,
          DATA_MOSTRAR(cs.data_termino) AS servico_data_termino,
          NVL(ef.nome,'-') AS servico_empresa_faturamento,
          NVL(cs.cod_externo,'-') AS servico_codigo_externo
     FROM contrato_servico cs
          FULL JOIN contrato_horas ch ON ch.contrato_servico_id = cs.contrato_servico_id
          LEFT JOIN servico se ON se.servico_id = cs.servico_id
          LEFT JOIN pessoa ef ON ef.pessoa_id = cs.emp_faturar_por_id
          LEFT JOIN area ar ON ar.area_id = ch.area_id
          LEFT JOIN cargo ca ON ca.cargo_id = ch.cargo_id
          LEFT JOIN pessoa us ON us.usuario_id = ch.usuario_id
          LEFT JOIN dicionario nv ON nv.tipo = 'nivel_usuario' AND nv.codigo = ch.nivel

;
