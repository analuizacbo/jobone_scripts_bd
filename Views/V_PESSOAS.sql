--------------------------------------------------------
--  DDL for View V_PESSOAS
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "V_PESSOAS" ("EMPRESA_ID", "PESSOA_ID", "USUARIO_ID", "APELIDO", "NOME", "GRUPO_CLIENTE", "TIPO_PESSOA", "PUBLICO_PRIVADO", "CONTATO", "CONTATO_DE", "POSSUI_DOCUMENTO", "CARGO", "PRODUTO_CLIENTE", "CODIGO_EXTERNO_PESSOA", "PESSOA", "SIMPLES_NACIONAL", "CPOM", "CNPJ", "CPF", "INSCRICAO_ESTADUAL", "INSCRICAO_MUNICIPAL", "INSCRICAO_INSS", "RG", "DIAS_FATURAMENTO", "PAGTO_CLIENTE", "CODIGO_PROJETO", "NUMERO_PRIMEIRO_PROJETO", "DATA_ENTRADA_AGENCIA", "EMPRESA_PROJETO_PADRAO", "EMPRESA_FATURAMENTO_PADRAO", "SETOR", "NIVEL_EXCELENCIA", "FORNECEDOR_INTERNO", "PESSOA_ATIVA", "EMPRESA_RESPONSAVEL_PROJETO", "CODIGO_EXTERNO_EMPRESA_RESP", "EMPRESA_UTILIZADA_FATURAMENTO", "CODIGO_EXTERNO_EMPRESA_FATUR", "BANCO", "NUMERO_AGENCIA", "NUMERO_CONTA", "TIPO_CONTA", "DOC_DADOS_BANCARIOS", "TITULAR", "ENDERECO", "CIDADE", "UF", "CEP", "PAIS", "DDD_TELEFONE", "NUM_TELEFONE", "RAMAL", "DDD_CELULAR", "NUM_CELULAR", "EMAIL", "URL", "CADASTRO_VERIFICADO", "INFO_FISCAL_VERIFICADA", "OBSERVACAO", "FLAG_ADMIN", "FLAG_ADMIN_SISTEMA", "COD_EXTERNO_PESSOA", "DATA_CRIACAO", "DATA_ALTERACAO", "STATUS_HOMOLOG", "QUALIFICADO", "VALIDADE_HOMOLOG", "SERVICOS", "IMPOSTO_FORNECEDOR", "BV_PADRAO", "FORNEC_HOMOLOG", "CHAVE_PIX") AS 
  SELECT pe.empresa_id AS empresa_id,
       pe.pessoa_id AS pessoa_id,
       pe.usuario_id AS usuario_id,
       pe.apelido AS apelido,
       pe.nome AS nome,
       (SELECT listagg(gr.nome, ', ') within GROUP(ORDER BY gr.nome)
          FROM grupo gr
         INNER JOIN grupo_pessoa gp
            ON gp.grupo_id = gr.grupo_id
           AND gp.pessoa_id = pe.pessoa_id
         WHERE gr.empresa_id = pe.empresa_id) AS grupo_cliente,
       (SELECT listagg(tp.nome, ', ') within GROUP(ORDER BY tp.nome)
          FROM tipo_pessoa tp
         INNER JOIN tipific_pessoa ip
            ON tp.tipo_pessoa_id = ip.tipo_pessoa_id
           AND ip.pessoa_id = pe.pessoa_id) AS tipo_pessoa,
       decode(pe.tipo_publ_priv, 'PRIV', 'Privado', 'PUBL', 'Público') AS publico_privado,
       CASE
        WHEN (SELECT COUNT(1)
                FROM pessoa  p,
                     relacao r
               WHERE r.pessoa_filho_id = pe.pessoa_id
                 AND p.empresa_id = pe.empresa_id
                 AND r.pessoa_pai_id = p.pessoa_id
                 AND p.flag_ativo = 'S') = 0 THEN
         'N'
        ELSE
         'S'
       END contato,
       (SELECT listagg(p.apelido, ', ') within GROUP(ORDER BY p.apelido)
          FROM pessoa  p,
               relacao r
         WHERE r.pessoa_filho_id = pe.pessoa_id
           AND p.empresa_id = pe.empresa_id
           AND r.pessoa_pai_id = p.pessoa_id
           AND p.flag_ativo = 'S') AS contato_de,
       pe.flag_sem_docum AS possui_documento,
       pe.funcao AS cargo,
       (SELECT listagg(pc.nome, ', ' ON overflow truncate) within GROUP(ORDER BY pc.nome)
          FROM produto_cliente pc
         WHERE pc.pessoa_id = pe.pessoa_id) AS produto_cliente,
       pe.cod_ext_pessoa AS codigo_externo_pessoa,
       pe.flag_pessoa_jur AS pessoa,
       pe.flag_simples AS simples_nacional,
       pe.flag_cpom AS cpom,
       pe.cnpj AS cnpj,
       pe.cpf AS cpf,
       pe.inscr_estadual AS inscricao_estadual,
       pe.inscr_municipal AS inscricao_municipal,
       pe.inscr_inss AS inscricao_inss,
       pe.rg AS rg,
       pe.num_dias_fatur AS dias_faturamento,
       pe.flag_pago_cliente AS pagto_cliente,
       pe.cod_job AS codigo_projeto,
       pe.num_primeiro_job AS numero_primeiro_projeto,
       pe.data_entrada_agencia AS data_entrada_agencia,
       (SELECT e.apelido
          FROM pessoa e
         WHERE e.pessoa_id = pe.emp_resp_pdr_id) AS empresa_projeto_padrao,
       (SELECT e.apelido
          FROM pessoa e
         WHERE e.pessoa_id = pe.emp_fatur_pdr_id) AS empresa_faturamento_padrao,
       (SELECT s.nome
          FROM setor s
         WHERE s.setor_id = pe.setor_id
           AND s.empresa_id = pe.empresa_id) AS setor,
       --pe.perc_bv AS bv_padrao,
       --pe.perc_imposto AS imposto_fornecedor, -- Imposto do Fornecedor,
       (SELECT round(nvl(AVG(nota), 0), 1)
          FROM aval_fornec af
         WHERE af.pessoa_id = pe.pessoa_id
           AND af.tipo_aval = 'EXC') AS nivel_excelencia,
       /*(SELECT round(nvl(AVG(nota), 0), 1)
        FROM aval_fornec af
       WHERE af.pessoa_id = pe.pessoa_id
         AND af.tipo_aval = 'PAR') AS nivel_parceria,*/
       --pe.desc_servicos AS servicos, --Serviços,
       pe.flag_fornec_interno AS fornecedor_interno, --Fornecedor Interno (S/N),
       pe.flag_ativo AS pessoa_ativa, --Pessoa Ativa (S/N),
       pe.flag_emp_resp AS empresa_responsavel_projeto, --Empresa Responsável pelo Projeto (S/N),
       (SELECT MAX(e.cod_ext_resp)
          FROM empr_resp_sist_ext e
         WHERE e.pessoa_id = pe.pessoa_id) AS codigo_externo_empresa_resp,
       pe.flag_emp_fatur AS empresa_utilizada_faturamento, --Empresa Utilizada no Faturamento (S/N),
       (SELECT MAX(e.cod_ext_fatur)
          FROM empr_fatur_sist_ext e
         WHERE e.pessoa_id = pe.pessoa_id) AS codigo_externo_empresa_fatur,
       (SELECT bc.nome
          FROM fi_banco bc
         WHERE bc.fi_banco_id = pe.fi_banco_id) AS banco,
       pe.num_agencia AS numero_agencia,
       pe.num_conta AS numero_conta,
       pe.tipo_conta AS tipo_conta,
       pe.cnpj_cpf_titular AS doc_dados_bancarios, --CPF/CNPJ dos Dados Bancários,
       pe.nome_titular AS titular, --Titular,
       pe.endereco || ' ' || pe.num_ender || ' ' || pe.compl_ender || ' ' || pe.zona || ' ' ||
       pe.bairro AS endereco,
       pe.cidade AS cidade,
       pe.uf AS uf,
       pe.cep AS cep,
       pe.pais AS pais,
       pe.ddd_telefone AS ddd_telefone,
       pe.num_telefone AS num_telefone,
       pe.num_ramal AS ramal,
       pe.ddd_celular AS ddd_celular,
       pe.num_celular AS num_celular,
       pe.email AS email,
       pe.website AS url,
       pe.flag_cad_verif AS cadastro_verificado,
       pe.flag_fis_verif AS info_fiscal_verificada,
       pe.obs AS observacao,
       (SELECT us.flag_admin
          FROM usuario us
         WHERE pe.usuario_id = us.usuario_id) AS flag_admin,
       (SELECT us.flag_admin_sistema
          FROM usuario us
         WHERE pe.usuario_id = us.usuario_id) AS flag_admin_sistema,
       (SELECT listagg(ti.nome || ': ' || ps.cod_ext_pessoa, ', ') within GROUP(ORDER BY ti.nome)
          FROM pessoa_sist_ext ps
         INNER JOIN tipo_pessoa ti
            ON ti.tipo_pessoa_id = ps.tipo_pessoa_id
         WHERE ps.pessoa_id = pe.pessoa_id) AS cod_externo_pessoa,
       (SELECT MIN(data_evento)
          FROM historico h
         WHERE h.evento_id = (SELECT e.evento_id
                                FROM evento e
                               WHERE e.descricao = 'Inclusão de Pessoa')
           AND h.objeto_id = pe.pessoa_id) AS data_criacao,
       (SELECT MAX(data_evento)
          FROM historico
         WHERE evento_id = (SELECT evento_id
                              FROM evento
                             WHERE descricao = 'Alteração de Pessoa')
           AND objeto_id = pe.pessoa_id) AS data_alteracao,
       -- Último status homologação
       (SELECT ph1.status_para
          FROM pessoa_homolog ph1
         WHERE ph1.pessoa_id = pe.pessoa_id
           AND ph1.data_hora = (SELECT MAX(ph2.data_hora)
                                  FROM pessoa_homolog ph2
                                 WHERE ph2.pessoa_id = pe.pessoa_id)
         FETCH FIRST 1 ROW ONLY) AS status_homolog,
       CASE
        WHEN pe.flag_qualificado = 'S' THEN
         'S'
        ELSE
         'N'
       END AS qualificado,
       -- Última data validade homologação
       (SELECT MAX(ph.data_hora)
          FROM pessoa_homolog ph
         WHERE ph.pessoa_id = pe.pessoa_id) AS validade_homolog,
       CASE
        WHEN pe.desc_servicos IS NOT NULL THEN
         pe.desc_servicos
        ELSE
         (SELECT listagg(r.nome, ', ') within GROUP(ORDER BY r.nome)
            FROM pessoa_tipo_produto p,
                 tipo_produto        r
           WHERE r.tipo_produto_id = p.tipo_produto_id
             AND p.pessoa_id = pe.pessoa_id)
       END AS servicos,
       (SELECT ph.perc_imposto
          FROM pessoa_homolog ph
         WHERE ph.pessoa_id = pe.pessoa_id
           AND ph.data_hora = (SELECT MAX(ph2.data_hora)
                                 FROM pessoa_homolog ph2
                                WHERE ph2.pessoa_id = pe.pessoa_id)
         FETCH FIRST 1 ROW ONLY) AS imposto_fornecedor,
       (SELECT ph.perc_bv
          FROM pessoa_homolog ph
         WHERE ph.pessoa_id = pe.pessoa_id
           AND ph.data_hora = (SELECT MAX(ph2.data_hora)
                                 FROM pessoa_homolog ph2
                                WHERE ph2.pessoa_id = pe.pessoa_id)
         FETCH FIRST 1 ROW ONLY) AS bv_padrao,
       CASE
        WHEN pe.status_fornec_homolog = 'HMLG' THEN
         'S'
        ELSE
         'N'
       END AS fornec_homolog,
       pe.chave_pix as chave_pix
  FROM pessoa pe

;
