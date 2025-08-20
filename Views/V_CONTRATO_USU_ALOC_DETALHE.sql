--------------------------------------------------------
--  DDL for View V_CONTRATO_USU_ALOC_DETALHE
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CONTRATO_USU_ALOC_DETALHE" ("USUARIO_ID", "CONTRATO_ID", "NUMERO", "DESCRICAO", "CLIENTE_NOME", "SERVICO", "HORA_ALOC_PLANEJADA", "MES", "ANO", "MES_ANO", "GRUPO_PRODUTO_NOME") AS 
  select chu.usuario_id,
       co.contrato_id,
       contrato_pkg.numero_formatar(co.contrato_id) as numero,
--co.motivo_desc as descricao,
co.nome as descricao,
pe.apelido as cliente_nome,
ser.nome as servico,
chu.horas_aloc as hora_aloc_planejada,
to_char(ch.data,'MM') as mes,
to_char(ch.data,'YYYY') as ano,
to_char(ch.data, 'MON/YYYY', 'nls_language ="BRAZILIAN PORTUGUESE"')as mes_ano,
(
  SELECT LISTAGG(nome, ', ') WITHIN GROUP (ORDER BY nome)
  FROM (
    SELECT DISTINCT gs.nome
    FROM contrato_horas ch
    LEFT JOIN contrato_servico cs ON cs.contrato_servico_id = ch.contrato_servico_id
    LEFT JOIN servico se ON se.servico_id = cs.servico_id
    LEFT JOIN contrato_horas_usu cu ON cu.contrato_horas_id = ch.contrato_horas_id
    LEFT JOIN grupo_servico gs ON gs.grupo_servico_id = se.grupo_servico_id
    WHERE ch.contrato_id = co.contrato_id AND cu.usuario_id = chu.usuario_id
  )
) AS grupo_produto_nome
from contrato co,
     contrato_horas ch,
     contrato_horas_usu chu,
     contrato_servico cons,
     servico ser,
     pessoa pe
where co.contrato_id = cons.contrato_id
and co.contrato_id = ch.contrato_id
and ch.contrato_horas_id = chu.contrato_horas_id
and ch.contrato_servico_id = cons.contrato_servico_id
and cons.servico_id = ser.servico_id
and pe.pessoa_id = co.contratante_id

;
