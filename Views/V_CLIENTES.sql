--------------------------------------------------------
--  DDL for View V_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_CLIENTES" ("EMPRESA", "EMPRESA_ID", "PESSOA_ID", "APELIDO", "RAZAO_SOCIAL", "GRUPO_CLIENTE", "EMPRESA_RESP_JOB_PADRAO", "EMPRESA_FATUR_PADRAO", "PESSOA_FISICA_JURIDICA", "CNPJ", "INSCR_ESTADUAL", "INSCR_MUNICIPAL", "INSCR_INSS", "CPF", "RG", "RG_ORG_EXP", "RG_DATA_EXP", "RG_UF", "ENDERECO", "NUM_ENDER", "COMPL_ENDER", "ZONA", "BAIRRO", "CEP", "CIDADE", "UF", "PAIS", "DDD_TELEFONE", "NUM_TELEFONE", "DDD_CELULAR", "NUM_CELULAR", "NUM_RAMAL", "WEBSITE", "EMAIL", "NUM_AGENCIA", "NUM_CONTA", "NOME_TITULAR", "CNPJ_CPF_TITULAR", "TIPO_CONTA") AS 
  SELECT em.nome AS empresa,
         em.empresa_id,
         pe.pessoa_id,
         pe.apelido,
         pe.nome AS razao_social,
       NVL((SELECT LISTAGG(gr.nome,', ') WITHIN GROUP (ORDER BY gr.nome)
                FROM grupo gr
                     INNER JOIN grupo_pessoa gp ON gr.grupo_id = gp.grupo_id
               WHERE gp.pessoa_id = pe.pessoa_id
                 AND gr.flag_agrupa_cnpj = 'S'),'-') AS grupo_cliente,
         NVL(er.apelido,'Não Definido') AS empresa_resp_job_padrao,
         NVL(ef.apelido,'Não Definido') AS empresa_fatur_padrao,
         DECODE(pe.flag_pessoa_jur,'S','Jurídica','N','Física','Não Definido') AS pessoa_fisica_juridica,
         pe.CNPJ,
         pe.INSCR_ESTADUAL,
         pe.INSCR_MUNICIPAL,
         pe.INSCR_INSS,
         pe.CPF,
         pe.RG,
         pe.RG_ORG_EXP,
         pe.RG_DATA_EXP,
         pe.RG_UF,
         PE.ENDERECO,
         pe.NUM_ENDER,
         pe.COMPL_ENDER,
         pe.ZONA,
         pe.BAIRRO,
         pe.CEP,
         pe.CIDADE,
         pe.UF,
         pe.PAIS,
         pe.DDD_TELEFONE,
         pe.NUM_TELEFONE,
         pe.DDD_CELULAR,
         pe.NUM_CELULAR,
         pe.NUM_RAMAL,
         pe.WEBSITE,
         pe.EMAIL,
         pe.NUM_AGENCIA,
         pe.NUM_CONTA,
         pe.NOME_TITULAR,
         pe.CNPJ_CPF_TITULAR,
         pe.TIPO_CONTA
    FROM pessoa pe
         INNER JOIN empresa em ON em.empresa_id = pe.empresa_id
         LEFT JOIN pessoa er ON er.pessoa_id = pe.emp_resp_pdr_id
         LEFT JOIN pessoa ef ON ef.pessoa_id = pe.emp_fatur_pdr_id
   WHERE NOT EXISTS (SELECT 1 FROM relacao r
                      WHERE r.pessoa_filho_id = pe.pessoa_id)
     AND EXISTS     (SELECT 1 FROM tipific_pessoa x
                                   INNER JOIN tipo_pessoa t ON t.tipo_pessoa_id = x.tipo_pessoa_id
                      WHERE x.pessoa_id = pe.pessoa_id
                        AND t.codigo = 'CLIENTE')
     AND pe.flag_ativo = 'S'
;
