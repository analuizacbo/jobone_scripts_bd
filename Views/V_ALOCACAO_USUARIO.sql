--------------------------------------------------------
--  DDL for View V_ALOCACAO_USUARIO
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_ALOCACAO_USUARIO" ("NOME_EMPRESA", "USUARIO_ID", "APELIDO", "FUNCAO", "CARGO_NOME", "USUARIO_UNID_NEG", "DATA_ALOCACAO", "MES_ALOCACAO", "ANO_ALOCACAO", "DIA_SEMANA", "HORAS_DIARIAS", "HORAS_TOTAL", "HORAS_RESERVADO", "HORAS_ALOCADO", "HORAS_AUSENCIA", "HORAS_OVERTIME", "HORAS_LIVRE") AS 
  SELECT 
    em.nome AS nome_empresa,
    pe.usuario_id AS usuario_id,
    pe.apelido AS apelido,
    us.funcao AS funcao,
    NVL(
        (SELECT ca.nome 
         FROM cargo ca 
         WHERE ca.cargo_id = cargo_pkg.do_usuario_retornar(us.usuario_id, SYSDATE, pe.empresa_id)), 
        'N/A'
    ) AS cargo_nome,
    NVL(un.nome, 'N/A') AS usuario_unid_neg,
    di.data AS data_alocacao,                   
    di.mes AS mes_alocacao,                    
    di.ano AS ano_alocacao,                    
    di.dia_semana AS dia_semana,             
    di.horas_diarias AS horas_diarias,          
    di.horas_total AS horas_total,            
    di.horas_reservado AS horas_reservado,        
    di.horas_alocado AS horas_alocado,          
    di.horas_ausencia AS horas_ausencia,         
    di.horas_overtime AS horas_overtime,         
    di.horas_livre AS horas_livre
FROM 
    pessoa pe
INNER JOIN 
    usuario us ON us.usuario_id = pe.usuario_id
INNER JOIN 
    dia_alocacao di ON di.usuario_id = us.usuario_id
INNER JOIN 
    empresa em ON em.empresa_id = usuario_pkg.empresa_padrao_retornar(us.usuario_id)
LEFT JOIN 
    unidade_negocio un ON un.unidade_negocio_id = usuario_pkg.unid_negocio_retornar(us.usuario_id, em.empresa_id, NULL, NULL)
;
