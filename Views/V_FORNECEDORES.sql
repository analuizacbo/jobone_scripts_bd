--------------------------------------------------------
--  DDL for View V_FORNECEDORES
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_FORNECEDORES" ("EMPRESA", "EMPRESA_ID", "PESSOA_ID", "APELIDO", "RAZAO_SOCIAL", "PESSOA_FISICA_JURIDICA", "CNPJ", "INSCR_ESTADUAL", "INSCR_MUNICIPAL", "INSCR_INSS", "CPF", "RG", "RG_ORG_EXP", "RG_DATA_EXP", "RG_UF", "ENDERECO", "NUM_ENDER", "COMPL_ENDER", "ZONA", "BAIRRO", "CEP", "CIDADE", "UF", "PAIS", "DDD_TELEFONE", "NUM_TELEFONE", "DDD_CELULAR", "NUM_CELULAR", "NUM_RAMAL", "WEBSITE", "EMAIL", "NUM_AGENCIA", "NUM_CONTA", "NOME_TITULAR", "CNPJ_CPF_TITULAR", "TIPO_CONTA", "DESC_SERVICOS") AS 
  SELECT em.nome AS empresa,
         em.empresa_id,
         pe.pessoa_id,
         pe.apelido,
         pe.nome AS razao_social,
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
         pe.TIPO_CONTA,
         --pe.perc_bv,
         --pe.tipo_fatur_bv,
         --pe.perc_imposto,
         pe.desc_servicos
    FROM pessoa pe
         INNER JOIN empresa em ON em.empresa_id = pe.empresa_id
   WHERE NOT EXISTS (SELECT 1 FROM relacao r
                      WHERE r.pessoa_filho_id = pe.pessoa_id)
     AND EXISTS     (SELECT 1 FROM tipific_pessoa x
                                   INNER JOIN tipo_pessoa t ON t.tipo_pessoa_id = x.tipo_pessoa_id
                      WHERE x.pessoa_id = pe.pessoa_id
                        AND t.codigo = 'FORNECEDOR')
     AND pe.flag_ativo = 'S'
;
