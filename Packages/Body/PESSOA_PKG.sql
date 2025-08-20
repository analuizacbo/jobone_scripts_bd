--------------------------------------------------------
--  DDL for Package Body PESSOA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PESSOA_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2004
  -- DESCRICAO: Inclusão de PESSOA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/08/2005  Consistencias no preenchimento do CEP, CPF E CNPJ
  -- Silvia            03/09/2007  Flag pago cliente
  -- Silvia            16/02/2009  Consistencia de imposto do fornecedor
  -- Silvia            08/06/2009  Novos parametros de percentuais de encargos.
  -- Silvia            10/01/2012  Novos parametros de numeracao do job.
  -- Silvia            12/06/2013  Novos parametros flag_emp_resp, emp_fatur_pdr_id,
  --                               emp_resp_pdr_id. Retirada da sigla_padrao.
  -- Silvia            24/04/2014  Obrigatoriedade de empresa padrao para Clientes.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            03/12/2014  Novo parametro data de entrada na agencia.
  -- Silvia            10/03/2015  Retirada de flag_emp_grupo.
  -- Silvia            06/07/2015  Retirada de parametros nivel_excelencia/nivel_parceria,
  --                               Novo flag_fornec_homolog
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            27/12/2016  Novos parametros flag_simples e flag_cpom
  -- Silvia            20/06/2017  Tabela de paises.
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            06/12/2018  Consistencia do codigo do job.
  -- Silvia            26/02/2019  Novo parametro setor.
  -- Silvia            23/09/2019  Retirada do grupo_id.
  -- Silvia            04/11/2019  Edicao temporaria do campo cod_ext_pessoa p/ Inpress
  -- Silvia            26/03/2021  Novos parametros para codigo externo
  -- Silvia            13/05/2021  Teste de param p/ obrigar setor
  -- Silvia            07/04/2022  Novo parametro tipo_publ_priv
  -- Silvia            08/09/2022  Novo parametro para obrigar email (cadastro de contato)
  -- Silvia            13/12/2022  Teste de param p/ obrigar codigo do job.
  -- Silvia            20/12/2022  Novo parametro flag_testa_codjob que permite desligar o teste
  --                               para cadastro de cliente via oportunidade.
  --Ana Luiza          04/11/2024  Tratamento complemento endereco
  -- Ana Luiza         25/10/2024  Adicao novo parametro de chave_pix
  -- Rafael            10/06/2025  Removido dos parametros e da tabela de Pessoa ( sexo, data_nascimento, 
  --                               Estado_civil, funcao, flag_fornec_homolog, perc_bv, tipo_fatur_bv, perc_imposto, ddd_fax, num_fax) 
  -- Rafael            10/06/2025  incluido novos parametros de p_regime_tributario até p_aval_ai
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_apelido                IN pessoa.apelido%TYPE,
  p_nome                   IN pessoa.nome%TYPE,
  p_flag_pessoa_jur        IN VARCHAR2,
  p_flag_cpom              IN VARCHAR2,
  p_cnpj                   IN pessoa.cnpj%TYPE,
  p_inscr_estadual         IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal        IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss             IN pessoa.inscr_inss%TYPE,
  p_cpf                    IN pessoa.cpf%TYPE,
  p_rg                     IN pessoa.rg%TYPE,
  p_rg_org_exp             IN pessoa.rg_org_exp%TYPE,
  p_rg_uf                  IN pessoa.rg_uf%TYPE,
  p_rg_data_exp            IN VARCHAR2,
  p_flag_sem_docum         IN VARCHAR2,
  p_endereco               IN pessoa.endereco%TYPE,
  p_num_ender              IN pessoa.num_ender%TYPE,
  p_compl_ender            IN pessoa.compl_ender%TYPE,
  p_bairro                 IN pessoa.bairro%TYPE,
  p_cep                    IN pessoa.cep%TYPE,
  p_cidade                 IN pessoa.cidade%TYPE,
  p_uf                     IN pessoa.uf%TYPE,
  p_pais                   IN pessoa.pais%TYPE,
  p_website                IN pessoa.website%TYPE,
  p_email                  IN pessoa.email%TYPE,
  p_ddd_telefone           IN pessoa.ddd_telefone%TYPE,
  p_num_telefone           IN pessoa.num_telefone%TYPE,
  p_num_ramal              IN pessoa.num_ramal%TYPE,
  p_ddd_celular            IN pessoa.ddd_celular%TYPE,
  p_num_celular            IN pessoa.num_celular%TYPE,
  p_obs                    IN pessoa.obs%TYPE,
  p_fi_banco_id            IN pessoa.fi_banco_id%TYPE,
  p_num_agencia            IN pessoa.num_agencia%TYPE,
  p_num_conta              IN pessoa.num_conta%TYPE,
  p_tipo_conta             IN pessoa.tipo_conta%TYPE,
  p_nome_titular           IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular       IN pessoa.cnpj_cpf_titular%TYPE,
  p_vetor_tipo_pessoa      IN VARCHAR2,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_num_dias_fatur         IN VARCHAR2,
  p_tipo_num_dias_fatur    IN pessoa.tipo_num_dias_fatur%TYPE,
  p_flag_fornec_interno    IN VARCHAR2,
  p_flag_emp_resp          IN VARCHAR2,
  p_flag_emp_fatur         IN VARCHAR2,
  p_flag_pago_cliente      IN VARCHAR2,
  p_flag_cli_aprov_os      IN VARCHAR2,
  p_flag_cli_aval_os       IN VARCHAR2,
  p_cod_job                IN pessoa.cod_job%TYPE,
  p_num_primeiro_job       IN VARCHAR2,
  p_data_entrada_agencia   IN VARCHAR2,
  p_emp_resp_pdr_id        IN pessoa.emp_resp_pdr_id%TYPE,
  p_emp_fatur_pdr_id       IN pessoa.emp_fatur_pdr_id%TYPE,
  p_setor_id               IN pessoa.setor_id%TYPE,
  p_cod_ext_pessoa         IN VARCHAR2,
  p_cod_ext_resp           IN VARCHAR2,
  p_cod_ext_fatur          IN VARCHAR2,
  p_tipo_publ_priv         IN VARCHAR2,
  p_flag_obriga_email      IN VARCHAR2,
  p_flag_testa_codjob      IN VARCHAR2,
  p_chave_pix              IN VARCHAR2,
  p_regime_tributario      IN VARCHAR2,
  p_tipo_num_cotacoes      IN VARCHAR2,
  p_num_cotacoes           IN VARCHAR2,
  --Qualificacao
  p_nivel_qualidade IN VARCHAR2,
  p_nivel_parceria  IN VARCHAR2,
  p_nivel_relac     IN VARCHAR2,
  p_nivel_custo     IN pessoa.nivel_custo%TYPE,
  p_parcela         IN pessoa.parcela%TYPE,
  p_porte           IN pessoa.porte%TYPE,
  p_aval_ai         IN pessoa.aval_ai%TYPE,
  --homologacao
  p_status_para       IN pessoa_homolog.status_para%TYPE,
  p_perc_bv           IN pessoa_homolog.perc_bv%TYPE,
  p_tipo_fatur_bv     IN pessoa_homolog.tipo_fatur_bv%TYPE,
  p_flag_tem_bv       IN pessoa_homolog.flag_tem_bv%TYPE,
  p_perc_imposto      IN pessoa_homolog.perc_imposto%TYPE,
  p_flag_nota_cobert  IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_flag_tem_cobert   IN pessoa_homolog.flag_tem_cobert%TYPE,
  p_condicao_pagto_id IN pessoa_homolog.condicao_pagto_id%TYPE,
  p_obs_fornec        IN pessoa_homolog.obs%TYPE,
  p_data_validade     IN VARCHAR2,
  p_aval_ai_fornec    IN pessoa_homolog.aval_ai%TYPE,
  --
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_pessoa_homolog_id OUT pessoa_homolog.pessoa_homolog_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_exception                  EXCEPTION;
  v_delimitador                CHAR(1);
  v_pessoa_id                  pessoa.pessoa_id%TYPE;
  v_pessoa_homolog_id          pessoa_homolog.pessoa_homolog_id%TYPE;
  v_cpf                        pessoa.cpf%TYPE;
  v_cnpj                       pessoa.cnpj%TYPE;
  v_pais                       pessoa.pais%TYPE;
  v_vetor_tipo_pessoa          VARCHAR2(2000);
  v_tipo_pessoa_id             tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_tipo_pessoa            tipo_pessoa.codigo%TYPE;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_num_dias_fatur             pessoa.num_dias_fatur%TYPE;
  v_cnpj_cpf_titular           pessoa.cnpj_cpf_titular%TYPE;
  v_num_primeiro_job           pessoa.num_primeiro_job%TYPE;
  v_data_entrada_agencia       pessoa.data_entrada_agencia%TYPE;
  v_flag_qualificado           pessoa.flag_qualificado%TYPE;
  v_perc_imposto2              fi_tipo_imposto_pessoa.perc_imposto%TYPE;
  v_flag_pessoa_impostos_zerar VARCHAR2(10);
  v_qt_org_pub                 INTEGER;
  v_qt_estrang                 INTEGER;
  v_qt_cliente                 INTEGER;
  v_qt_fornec                  INTEGER;
  v_qt_interno                 INTEGER;
  v_flag_admin                 usuario.flag_admin%TYPE;
  v_lbl_job                    VARCHAR2(100);
  v_vetor_natureza_item_id     VARCHAR2(1000);
  v_vetor_tipo_produto_id      VARCHAR2(1000);
  v_vetor_valor_padrao         VARCHAR2(1000);
  v_tipo_produto_id            pessoa_tipo_produto.tipo_produto_id%TYPE;
  v_natureza_item_id           pessoa_nitem_pdr.natureza_item_id%TYPE;
  v_valor_padrao               pessoa_nitem_pdr.valor_padrao%TYPE;
  v_num_cotacoes               pessoa.num_cotacoes%TYPE;
  v_nivel_qualidade            pessoa.nivel_qualidade%TYPE;
  v_nivel_parceria             pessoa.nivel_parceria%TYPE;
  v_nivel_relac                pessoa.nivel_relac%TYPE;
  v_valor_padrao_char          VARCHAR2(50);
  v_nome_natureza              natureza_item.nome%TYPE;
  v_mod_calculo                natureza_item.mod_calculo%TYPE;
  v_desc_calculo               VARCHAR2(100);
  v_xml_atual                  CLOB;
  v_sistema_externo_id         sistema_externo.sistema_externo_id%TYPE;
  v_obriga_setor_cli           VARCHAR2(10);
  v_pdr_num_job                VARCHAR2(50);
  --
 BEGIN
  v_qt                   := 0;
  p_pessoa_id            := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_obriga_setor_cli     := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_SETOR_CLIENTE');
  v_pdr_num_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_JOB');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE flag_ativo = 'S'
     AND tipo_sistema = 'FIN';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_vetor_tipo_pessoa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação de pelo menos um tipo de pessoa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_apelido) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do apelido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome/razão social é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_pessoa)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo não pode ter mais que 20 caracteres (' || p_cod_ext_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_publ_priv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento de Público/Privado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_publ_priv', TRIM(p_tipo_publ_priv)) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo Público/Privado inválido (' || p_tipo_publ_priv || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias adicionais
  --
  IF flag_validar(p_flag_emp_resp) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag empresa responsável inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_emp_fatur) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag empresa de faturamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_resp)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo da empresa de responsável não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_resp || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_fatur)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo da empresa de faturamento não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_sistema_externo_id IS NULL AND
     (TRIM(p_cod_ext_resp) IS NOT NULL OR TRIM(p_cod_ext_resp) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe sistema financeiro ativo para armazenar os códigos externos.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_flag_pessoa_jur) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação de pessoa física ou jurídica é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pessoa_jur) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de pessoa jurídica inválido.';
   RAISE v_exception;
  END IF;
  --SE PESSOA JURIDICA
  IF p_flag_pessoa_jur = 'S'
  THEN
   --
   IF flag_validar(p_flag_cpom) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag CPOM inválido.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_flag_sem_docum, 'N') <> 'S'
   THEN
    IF rtrim(p_cnpj) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do CNPJ é obrigatório.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF rtrim(p_cpf) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O CPF só deve ser fornecido para pessoas físicas.';
    RAISE v_exception;
   END IF;
   --
   IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CNPJ inválido.';
    RAISE v_exception;
   END IF;
   --
   v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
   --
   IF TRIM(p_inscr_estadual) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição Estadual é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_inscr_municipal) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição Municipal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_inscr_inss) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição INSS é obrigatório.';
    RAISE v_exception;
   END IF; --Flag_sem_doc = N;
   --
  END IF; -- FIM Pessoa juridica;
  --ALCBO_020725
  --SE PESSOA FISICA
  IF p_flag_pessoa_jur = 'N'
  THEN
   --
   IF rtrim(p_cnpj) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O CNPJ só deve ser fornecido para pessoas jurídicas.';
    RAISE v_exception;
   END IF;
   --
   IF cpf_pkg.validar(p_cpf, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CPF inválido.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_uf IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_org_exp IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Órgão Expedidor do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_data_exp IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de expedição do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_rg_data_exp) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de expedição do RG inválida.';
    RAISE v_exception;
   END IF;
   --
   v_cpf := cpf_pkg.converter(p_cpf, p_empresa_id);
   --
   --Se flag_sem_documento marcada e for fisico
   IF nvl(p_flag_sem_docum, 'N') <> 'S'
   THEN
    IF v_cpf IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do CPF é obrigatório.';
     RAISE v_exception;
    END IF;
    --
   END IF; --flag_sem documento = N
   --
  END IF; --fim pessoa fisica
  --
  /*
  IF p_flag_pessoa_jur = 'S' AND flag_validar(p_flag_cpom) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag CPOM inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_pessoa_jur = 'S' AND rtrim(p_cpf) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O CPF só deve ser fornecido para pessoas físicas.';
   RAISE v_exception;
   --
  END IF;
  --
  IF p_flag_pessoa_jur = 'N' AND rtrim(p_cnpj) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O CNPJ só deve ser fornecido para pessoas jurídicas.';
   RAISE v_exception;
  END IF;
  --
  --
  IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CNPJ inválido.';
   RAISE v_exception;
  END IF;
  --
  v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
  --
  IF cpf_pkg.validar(p_cpf, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CPF inválido.';
   RAISE v_exception;
  END IF;
  --
  v_cpf := cpf_pkg.converter(p_cpf, p_empresa_id);
  --
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'S' AND v_cnpj IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do CNPJ é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'N' AND v_cpf IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do CPF é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_020725
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'N' AND p_rg IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do RG é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'N' AND p_rg_uf IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sigla do estado do RG é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_rg_uf) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_rg_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado do RG inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'N' AND p_rg_org_exp IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Órgão Expedidor do RG é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_flag_sem_docum, 'N') <> 'S' AND p_flag_pessoa_jur = 'N' AND p_rg_data_exp IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de expedição do RG é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_rg_data_exp) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de expedição do RG inválida.';
   RAISE v_exception;
  END IF;
  */
  --
  IF nvl(p_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_num_agencia) IS NULL OR TRIM(p_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta ' ||
                  '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                  'devem ser informados quando se tratar de outra pessoa).';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_fi_banco_id, 0) = 0 AND
     (TRIM(p_num_agencia) IS NOT NULL OR TRIM(p_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco ' ||
                 '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                 'devem ser informados quando se tratar de outra pessoa).';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cnpj_cpf_titular) IS NOT NULL
  THEN
   IF cnpj_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
   THEN
    IF cpf_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'CNPJ/CPF do titular da conta inválido.';
     RAISE v_exception;
    ELSE
     v_cnpj_cpf_titular := cpf_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
    END IF;
   ELSE
    v_cnpj_cpf_titular := cnpj_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
   END IF;
   --
   IF TRIM(p_nome_titular) IS NULL OR v_cnpj_cpf_titular = v_cnpj OR v_cnpj_cpf_titular = v_cpf
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  ELSE
   v_cnpj_cpf_titular := NULL;
   --
   IF TRIM(p_nome_titular) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_251024
  IF TRIM(p_chave_pix) IS NOT NULL
  THEN
   IF pessoa_pkg.chave_pix_validar(TRIM(p_chave_pix)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Chave pix inválida (' || TRIM(p_chave_pix) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF inteiro_validar(p_num_ender) = 0 OR to_number(p_num_ender) > 999999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do endereço inválido.';
   RAISE v_exception;
  END IF;
  --
  v_pais := TRIM(upper(acento_retirar(p_pais)));
  --
  IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL', 'BRA', 'BR')
  THEN
   v_pais := 'BRASIL';
  END IF;
  --
  IF v_pais IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pais
    WHERE upper(nome) = upper(v_pais);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'País inválido (' || p_pais || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cep) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.validar(p_cep) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND TRIM(p_cidade) IS NOT NULL AND
     (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.municipio_validar(p_uf, p_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do endereço inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_obriga_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_obriga_email = 'S' AND TRIM(p_email) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Email é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_conta) IS NOT NULL AND p_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_testa_codjob) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag testa código do job inválido.';
   RAISE v_exception;
  END IF;
  --
  -- consistencias para clientes
  --
  IF inteiro_validar(p_num_dias_fatur) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias para faturamento do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur := to_number(p_num_dias_fatur);
  --
  IF p_tipo_num_dias_fatur NOT IN ('C', 'U')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de dias para faturamento do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pago_cliente) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pago pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_primeiro_job) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do primeiro ' || v_lbl_job || ' do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  v_num_primeiro_job := to_number(p_num_primeiro_job);
  --
  IF data_validar(p_data_entrada_agencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada na ' || v_lbl_agencia_singular || ' inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_entrada_agencia := data_converter(p_data_entrada_agencia);
  --
  IF nvl(p_emp_resp_pdr_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_resp_pdr_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável padrão não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_emp_fatur_pdr_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_fatur_pdr_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa para faturamento padrão não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_setor_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM setor
    WHERE setor_id = p_setor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse setor não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- consistencias para fornecedores
  --
  /*IF length(p_desc_servicos) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição dos produtos prestados pelo fornecedor ' ||
                 'não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;*/
  --
  IF flag_validar(p_flag_fornec_interno) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag fornecedor interno inválido.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_flag_admin = 'N'
  THEN
   -- nao e administrador. Precisa consistir duplicidade.
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE cnpj = v_cnpj
      AND empresa_id = p_empresa_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse CNPJ já existe (' || v_cnpj || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE cpf = v_cpf
      AND empresa_id = p_empresa_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse CPF já existe (' || v_cpf || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cod_job) IS NOT NULL
  THEN
   IF instr(TRIM(p_cod_job), ' ') > 0 OR instr(TRIM(p_cod_job), '%') > 0 OR
      lower(TRIM(p_cod_job)) <> acento_retirar(TRIM(p_cod_job))
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter caracteres em branco, ' ||
                  'com acentuação ou % (' || upper(p_cod_job) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_041124
  IF length(TRIM(p_compl_ender)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 100 caracteres (' ||
                 p_compl_ender || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos dados de entrada
  ------------------------------------------------------------
  -- aqui
  v_nivel_qualidade := nvl(numero_converter(p_nivel_qualidade), 0);
  v_nivel_parceria  := nvl(taxa_converter(p_nivel_parceria), 0);
  v_nivel_relac     := nvl(taxa_converter(p_nivel_relac), 0);
  -- Calcula o flag_qualificado (se houver alguma qualificacao então S senão N)
  IF (p_nivel_qualidade > 0 OR p_nivel_parceria > 0 OR p_nivel_relac > 0 OR p_nivel_custo > 0 OR
     p_parcela > 0 OR (p_porte IS NOT NULL AND upper(p_porte) <> 'ND') OR p_aval_ai IS NOT NULL)
  THEN
   v_flag_qualificado := 'S';
  ELSE
   v_flag_qualificado := 'N';
  END IF;
 
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT seq_pessoa.nextval
    INTO v_pessoa_id
    FROM dual;
  --
  INSERT INTO pessoa
   (empresa_id,
    apelido,
    pessoa_id,
    nome,
    cnpj,
    inscr_estadual,
    inscr_municipal,
    inscr_inss,
    flag_pessoa_jur,
    flag_sem_docum,
    rg,
    rg_org_exp,
    rg_uf,
    rg_data_exp,
    cpf,
    endereco,
    num_ender,
    compl_ender,
    bairro,
    cep,
    cidade,
    uf,
    pais,
    website,
    email,
    ddd_telefone,
    num_telefone,
    num_ramal,
    ddd_celular,
    num_celular,
    obs,
    fi_banco_id,
    num_agencia,
    num_conta,
    tipo_conta,
    nome_titular,
    cnpj_cpf_titular,
    num_dias_fatur,
    tipo_num_dias_fatur,
    --desc_servicos,
    flag_emp_fatur,
    flag_emp_resp,
    flag_ativo,
    flag_pago_cliente,
    flag_fornec_interno,
    flag_cli_aval_os,
    flag_cli_aprov_os,
    cod_job,
    num_primeiro_job,
    data_entrada_agencia,
    emp_resp_pdr_id,
    emp_fatur_pdr_id,
    setor_id,
    flag_cpom,
    cod_ext_pessoa,
    tipo_publ_priv,
    chave_pix,
    flag_qualificado /*,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            regime_tributario ,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            tipo_num_cotacoes,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            num_cotacoes,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            nivel_qualidade,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            nivel_parceria,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            nivel_relac,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            nivel_custo,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            parcela,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            porte,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            aval_ai,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            flag_qualificado,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            status_fornec_homolog*/)
  VALUES
   (p_empresa_id,
    TRIM(p_apelido),
    v_pessoa_id,
    TRIM(p_nome),
    v_cnpj,
    TRIM(p_inscr_estadual),
    TRIM(p_inscr_municipal),
    TRIM(p_inscr_inss),
    p_flag_pessoa_jur,
    nvl(p_flag_sem_docum, 'N'),
    p_rg,
    p_rg_org_exp,
    upper(TRIM(p_rg_uf)),
    data_converter(p_rg_data_exp),
    v_cpf,
    TRIM(p_endereco),
    p_num_ender,
    TRIM(p_compl_ender),
    TRIM(p_bairro),
    cep_pkg.converter(rtrim(p_cep)),
    TRIM(p_cidade),
    upper(TRIM(p_uf)),
    v_pais,
    TRIM(p_website),
    TRIM(p_email),
    p_ddd_telefone,
    p_num_telefone,
    p_num_ramal,
    p_ddd_celular,
    p_num_celular,
    TRIM(p_obs),
    zvl(p_fi_banco_id, NULL),
    p_num_agencia,
    p_num_conta,
    TRIM(p_tipo_conta),
    TRIM(p_nome_titular),
    v_cnpj_cpf_titular,
    v_num_dias_fatur,
    nvl(p_tipo_num_dias_fatur, 'C'),
    p_flag_emp_fatur,
    p_flag_emp_resp,
    'S',
    p_flag_pago_cliente,
    p_flag_fornec_interno,
    p_flag_cli_aval_os,
    p_flag_cli_aprov_os,
    TRIM(upper(p_cod_job)),
    v_num_primeiro_job,
    v_data_entrada_agencia,
    zvl(p_emp_resp_pdr_id, NULL),
    zvl(p_emp_fatur_pdr_id, NULL),
    zvl(p_setor_id, NULL),
    p_flag_cpom,
    TRIM(p_cod_ext_pessoa),
    TRIM(p_tipo_publ_priv),
    TRIM(p_chave_pix),
    v_flag_qualificado /*,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_regime_tributario ,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_tipo_num_cotacoes,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_num_cotacoes,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_nivel_qualidade,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_nivel_parceria,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_nivel_relac,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_nivel_custo,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_parcela,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_porte,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_aval_ai,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            v_flag_qualificado,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'PEND'*/); -- no ato de adicionar será PEND e após cadastro de homologacao mudará
  --
  ------------------------------------------------------------
  -- tratamento dos codigos externos
  ------------------------------------------------------------
  IF v_sistema_externo_id IS NOT NULL
  THEN
   IF TRIM(p_cod_ext_fatur) IS NOT NULL
   THEN
    INSERT INTO empr_fatur_sist_ext
     (sistema_externo_id,
      pessoa_id,
      cod_ext_fatur)
    VALUES
     (v_sistema_externo_id,
      v_pessoa_id,
      TRIM(p_cod_ext_fatur));
   END IF;
   --
   IF TRIM(p_cod_ext_resp) IS NOT NULL
   THEN
    INSERT INTO empr_resp_sist_ext
     (sistema_externo_id,
      pessoa_id,
      cod_ext_resp)
    VALUES
     (v_sistema_externo_id,
      v_pessoa_id,
      TRIM(p_cod_ext_resp));
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de naturezas do item
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_natureza_item_id := rtrim(p_vetor_natureza_item_id);
  v_vetor_valor_padrao     := rtrim(p_vetor_valor_padrao);
  --
  WHILE nvl(length(rtrim(v_vetor_natureza_item_id)), 0) > 0
  LOOP
   v_natureza_item_id  := nvl(to_number(prox_valor_retornar(v_vetor_natureza_item_id, v_delimitador)),
                              0);
   v_valor_padrao_char := prox_valor_retornar(v_vetor_valor_padrao, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa (' ||
                  to_char(v_natureza_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          util_pkg.desc_retornar('mod_calculo', mod_calculo),
          mod_calculo
     INTO v_nome_natureza,
          v_desc_calculo,
          v_mod_calculo
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id;
   --
   IF v_mod_calculo = 'NA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não se aplica para cálculos (' || v_nome_natureza || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_valor_padrao_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' ||
                  v_valor_padrao_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_padrao := numero_converter(v_valor_padrao_char);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa_nitem_pdr
    WHERE pessoa_id = v_pessoa_id
      AND natureza_item_id = v_natureza_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem naturezas repetidas (' || v_nome_natureza || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO pessoa_nitem_pdr
    (pessoa_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_pessoa_id,
     v_natureza_item_id,
     v_valor_padrao);
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipos de produtos
  ------------------------------------------------------------
  v_delimitador           := '|';
  v_vetor_tipo_produto_id := rtrim(p_vetor_tipo_produto_id);
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_produto_id)), 0) > 0
  LOOP
   v_tipo_produto_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador)),
                            0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de produto não existe (' || to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa_tipo_produto
    WHERE pessoa_id = v_pessoa_id
      AND tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem tipo produto repetidos (' || v_tipo_produto_id || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO pessoa_tipo_produto
    (pessoa_id,
     tipo_produto_id)
   VALUES
    (v_pessoa_id,
     v_tipo_produto_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- demais atualizacoes
  ------------------------------------------------------------
  --
  v_flag_pessoa_impostos_zerar := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                 'FLAG_PESSOA_IMPOSTOS_ZERAR');
  IF v_flag_pessoa_impostos_zerar = 'S'
  THEN
   v_perc_imposto2 := 0;
  ELSE
   v_perc_imposto2 := NULL;
  END IF;
  --
  -- cria os impostos usados por fornecedores
  INSERT INTO fi_tipo_imposto_pessoa
   (fi_tipo_imposto_pessoa_id,
    fi_tipo_imposto_id,
    pessoa_id,
    perc_imposto,
    flag_reter,
    nome_servico)
   SELECT seq_fi_tipo_imposto_pessoa.nextval,
          fi_tipo_imposto_id,
          v_pessoa_id,
          v_perc_imposto2,
          'N',
          NULL
     FROM fi_tipo_imposto
    WHERE flag_incide_ent = 'S';
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipos de pessoa
  ------------------------------------------------------------
  v_delimitador       := '|';
  v_vetor_tipo_pessoa := p_vetor_tipo_pessoa;
  v_qt_org_pub        := 0;
  v_qt_estrang        := 0;
  v_qt_cliente        := 0;
  v_qt_fornec         := 0;
  v_qt_interno        := 0;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa, v_delimitador));
   --
   SELECT codigo
     INTO v_cod_tipo_pessoa
     FROM tipo_pessoa
    WHERE tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_cod_tipo_pessoa = 'CLIENTE'
   THEN
    v_qt_cliente := v_qt_cliente + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'FORNECEDOR'
   THEN
    v_qt_fornec := v_qt_fornec + 1;
    --
    --aqui
    pessoa_pkg.homologacao_adicionar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     v_pessoa_id,
                                     p_condicao_pagto_id,
                                     p_status_para,
                                     p_data_validade,
                                     p_perc_bv,
                                     p_tipo_fatur_bv,
                                     p_flag_tem_bv,
                                     p_perc_imposto,
                                     p_flag_nota_cobert,
                                     p_flag_tem_cobert,
                                     p_obs_fornec,
                                     p_aval_ai_fornec,
                                     'N',
                                     v_pessoa_homolog_id,
                                     p_erro_cod,
                                     p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   
   
   END IF;
   --
   IF v_cod_tipo_pessoa IN ('ORG_PUB_MUN', 'ORG_PUB_EST', 'ORG_PUB_FED')
   THEN
    v_qt_org_pub := v_qt_org_pub + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'ESTRANGEIRO'
   THEN
    v_qt_estrang := v_qt_estrang + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'INTERNO'
   THEN
    v_qt_interno := v_qt_interno + 1;
   END IF;
   --
   --
   INSERT INTO tipific_pessoa
    (pessoa_id,
     tipo_pessoa_id)
   VALUES
    (v_pessoa_id,
     v_tipo_pessoa_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
  IF v_qt_estrang > 0 AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR'))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Foi indicada pessoa no estrangeiro com endereço no Brasil.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_pessoa_jur = 'N' AND v_qt_org_pub > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa física não pode ser associada ao tipo "orgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada a mais de um tipo de orgão público.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 0 AND v_qt_estrang > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada ao tipo "orgão público" ' ||
                 'e "estrangeiro" ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_fornec = 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos devem ser associados ao tipo de pessoa "fornecedor".';
   RAISE v_exception;
  END IF;
  --ALCBO_020725
  -- Consistencia para clientes 
  IF v_qt_cliente > 0
  THEN
   -- consistencia de cod job (exceto contatos de cliente ou teste desligado
   -- via parametro de entrada)
   IF TRIM(p_cod_job) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" o preenchimento ' || 'do Código do ' || v_lbl_job ||
                  ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_pdr_num_job) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" o preenchimento ' || 'do Número do ' || v_lbl_job ||
                  ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_cod_job) IS NULL AND v_pdr_num_job = 'SEQUENCIAL_POR_CLIENTE' AND
      p_flag_testa_codjob = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" o preenchimento ' || 'do Código do ' || v_lbl_job ||
                  ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_num_primeiro_job) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" o preenchimento ' ||
                  'do Número do Primeiro Job é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_data_entrada_agencia IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" a Data de Entrada na Agência é obrigatório.';
    RAISE v_exception;
   END IF;
   -- consistencia de empresa resp (exceto contatos de cliente)
   IF nvl(p_emp_resp_pdr_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" a empresa responsável padrão deve ser informada.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_emp_fatur_pdr_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" a empresa responsável para faturamento padrão deve ser informada.';
    RAISE v_exception;
   END IF;
   --
   IF v_obriga_setor_cli = 'S' AND nvl(p_setor_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente", o preenchimento do setor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_fornec_interno = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "cliente".';
    RAISE v_exception;
   END IF;
   --
  END IF;
  --
  IF v_qt_org_pub > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "órgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_estrang > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "estrangeiro".';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio (a verificacao ficou p/ o final,
  -- pois ela depende dos tipos dessa pessoa que estao gravados no banco)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', v_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('PESSOA_ATUALIZAR_OPCIONAL',
                           p_empresa_id,
                           v_pessoa_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_pessoa_id := v_pessoa_id;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- adicionar
 --
 --
 PROCEDURE basico_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2004
  -- DESCRICAO: subrotina que inclui dados basicos de PESSOA (fornecedor).
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/02/2009  Consistencia de imposto do fornecedor
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            27/12/2016  Novos parametros flag_simples e flag_cpom
  -- Ana Luiza         04/11/2024  Tratamento complemento endereco
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_incluir      IN VARCHAR2,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_flag_simples      IN VARCHAR2,
  p_flag_cpom         IN VARCHAR2,
  p_cnpj              IN pessoa.cnpj%TYPE,
  p_inscr_estadual    IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal   IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss        IN pessoa.inscr_inss%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_fi_banco_id       IN pessoa.fi_banco_id%TYPE,
  p_num_agencia       IN pessoa.num_agencia%TYPE,
  p_num_conta         IN pessoa.num_conta%TYPE,
  p_tipo_conta        IN pessoa.tipo_conta%TYPE,
  p_nome_titular      IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular  IN pessoa.cnpj_cpf_titular%TYPE,
  p_tipo_fatur_bv     IN VARCHAR2,
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_exception                  EXCEPTION;
  v_delimitador                CHAR(1);
  v_pessoa_id                  pessoa.pessoa_id%TYPE;
  v_cnpj                       pessoa.cnpj%TYPE;
  v_cpf                        pessoa.cpf%TYPE;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_cnpj_cpf_titular           pessoa.cnpj_cpf_titular%TYPE;
  v_perc_imposto2              fi_tipo_imposto_pessoa.perc_imposto%TYPE;
  v_flag_pessoa_impostos_zerar VARCHAR2(10);
  v_xml_atual                  CLOB;
  --
 BEGIN
  v_qt                   := 0;
  p_pessoa_id            := 0;
  v_pessoa_id            := 0;
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_incluir) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag incluir inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_apelido) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do apelido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome/razão social é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_simples) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag simples inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_cpom) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag CPOM inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cnpj) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do CNPJ é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CNPJ inválido.';
   RAISE v_exception;
  END IF;
  --
  v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
  --
  IF nvl(p_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_num_agencia) IS NULL OR TRIM(p_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta ' ||
                  '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                  'devem ser informados quando se tratar de outra pessoa).';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_fi_banco_id, 0) = 0 AND
     (TRIM(p_num_agencia) IS NOT NULL OR TRIM(p_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco ' ||
                 '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                 'devem ser informados quando se tratar de outra pessoa).';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cnpj_cpf_titular) IS NOT NULL
  THEN
   IF cnpj_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
   THEN
    IF cpf_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'CNPJ/CPF do titular da conta inválido.';
     RAISE v_exception;
    ELSE
     v_cnpj_cpf_titular := cpf_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
    END IF;
   ELSE
    v_cnpj_cpf_titular := cnpj_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
   END IF;
   --
   IF TRIM(p_nome_titular) IS NULL OR v_cnpj_cpf_titular = v_cnpj OR v_cnpj_cpf_titular = v_cpf
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  ELSE
   v_cnpj_cpf_titular := NULL;
   --
   IF TRIM(p_nome_titular) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_endereco) IS NULL OR TRIM(p_cep) IS NULL OR TRIM(p_cidade) IS NULL OR
     TRIM(p_uf) IS NULL OR TRIM(p_bairro) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Endereço incompleto.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_ender) = 0 OR to_number(p_num_ender) > 999999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do endereço inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cep) IS NOT NULL AND cep_pkg.validar(p_cep) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CEP inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND TRIM(p_cidade) IS NOT NULL
  THEN
   IF cep_pkg.municipio_validar(p_uf, p_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do endereço inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_tipo_conta) IS NOT NULL AND p_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias para fornecedores
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
 
  --
  /*
  IF v_perc_imposto IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O percentual de imposto do fornecedor deve ser preenchido.';
     RAISE v_exception;
  END IF;*/
  --
  v_flag_pessoa_impostos_zerar := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                 'FLAG_PESSOA_IMPOSTOS_ZERAR');
  IF v_flag_pessoa_impostos_zerar = 'S'
  THEN
   v_perc_imposto2 := 0;
  ELSE
   v_perc_imposto2 := NULL;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE cnpj = v_cnpj
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse CNPJ já existe (' || v_cnpj || ').';
   RAISE v_exception;
  END IF;
  --ALCBO_041124
  IF length(TRIM(p_compl_ender)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 100 caracteres (' ||
                 p_compl_ender || ').';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_incluir = 'S'
  THEN
   SELECT seq_pessoa.nextval
     INTO v_pessoa_id
     FROM dual;
   --
   INSERT INTO pessoa
    (empresa_id,
     apelido,
     pessoa_id,
     nome,
     cnpj,
     inscr_estadual,
     inscr_municipal,
     inscr_inss,
     flag_pessoa_jur,
     flag_sem_docum,
     endereco,
     num_ender,
     compl_ender,
     bairro,
     cep,
     cidade,
     uf,
     obs,
     fi_banco_id,
     num_agencia,
     num_conta,
     tipo_conta,
     nome_titular,
     cnpj_cpf_titular,
     flag_emp_fatur,
     flag_emp_resp,
     flag_ativo,
     flag_pago_cliente,
     flag_simples,
     flag_cpom)
   VALUES
    (p_empresa_id,
     TRIM(p_apelido),
     v_pessoa_id,
     TRIM(p_nome),
     v_cnpj,
     TRIM(p_inscr_estadual),
     TRIM(p_inscr_municipal),
     TRIM(p_inscr_inss),
     'S',
     'N',
     TRIM(p_endereco),
     p_num_ender,
     TRIM(p_compl_ender),
     TRIM(p_bairro),
     cep_pkg.converter(TRIM(p_cep)),
     p_cidade,
     upper(TRIM(p_uf)),
     TRIM(p_obs),
     zvl(p_fi_banco_id, NULL),
     p_num_agencia,
     p_num_conta,
     TRIM(p_tipo_conta),
     TRIM(p_nome_titular),
     v_cnpj_cpf_titular,
     'N',
     'N',
     'S',
     'N',
     p_flag_simples,
     p_flag_cpom);
   --
   -- cria a pessoa como fornecedor
   INSERT INTO tipific_pessoa
    (pessoa_id,
     tipo_pessoa_id)
    SELECT v_pessoa_id,
           tipo_pessoa_id
      FROM tipo_pessoa
     WHERE codigo = 'FORNECEDOR';
   --
   -- cria os impostos usados por fornecedores
   INSERT INTO fi_tipo_imposto_pessoa
    (fi_tipo_imposto_pessoa_id,
     fi_tipo_imposto_id,
     pessoa_id,
     perc_imposto,
     flag_reter,
     nome_servico)
    SELECT seq_fi_tipo_imposto_pessoa.nextval,
           fi_tipo_imposto_id,
           v_pessoa_id,
           v_perc_imposto2,
           'N',
           NULL
      FROM fi_tipo_imposto
     WHERE flag_incide_ent = 'S';
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            v_pessoa_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := TRIM(p_nome);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'INCLUIR',
                    v_identif_objeto,
                    v_pessoa_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  p_pessoa_id := v_pessoa_id;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END; -- basico_adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2004
  -- DESCRICAO: Atualização de PESSOA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/08/2005  Consistencias no preenchimento do CEP, CPF E CNPJ
  -- Silvia            01/08/2007  Alteracao de consistencias de privilegio.
  -- Silvia            03/09/2007  Flag pago cliente
  -- Silvia            16/02/2009  Consistencia de imposto do fornecedor
  -- Silvia            08/06/2009  Novos parametros de percentuais de encargos.
  -- Silvia            10/01/2012  Novos parametros de numeracao do job.
  -- Silvia            12/06/2013  Novos parametros flag_emp_resp, emp_fatur_pdr_id,
  --                               emp_resp_pdr_id. Retirada da sigla_padrao.
  -- Silvia            24/04/2014  Obrigatoriedade de empresa padrao para Clientes.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            03/12/2014  Novo parametro data de entrada na agencia.
  -- Silvia            10/03/2015  Retirada de flag_emp_grupo.
  -- Silvia            06/07/2015  Retirada de parametros nivel_excelencia/nivel_parceria,
  --                               Novo flag_fornec_homolog
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            27/12/2016  Novos parametros flag_simples e flag_cpom
  -- Silvia            20/06/2017  Tabela de paises.
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            06/12/2018  Consistencia do codigo do job.
  -- Silvia            26/02/2019  Novo parametro setor.
  -- Silvia            23/09/2019  Retirada do grupo_id.
  -- Silvia            04/11/2019  Edicao temporaria do campo cod_ext_pessoa p/ Inpress
  -- Silvia            26/03/2021  Novos parametros para codigo externo
  -- Silvia            13/05/2021  Teste de param p/ obrigar setor
  -- Silvia            07/04/2022  Novo parametro tipo_publ_priv
  -- Silvia            08/09/2022  Novo parametro para obrigar email (cadastro de contato)
  -- Silvia            13/12/2022  Teste de param p/ obrigar codido do job.
  --Ana Luiza          04/11/2024  Tratamento complemento endereco
  -- Rafael            10/06/2025  Removido dos parametros e da tabela de Pessoa ( sexo, data_nascimento, 
  --                               Estado_civil, funcao, flag_fornec_homolog, perc_bv, tipo_fatur_bv, perc_imposto, ddd_fax, num_fax)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_pessoa_id              IN pessoa.pessoa_id%TYPE,
  p_apelido                IN pessoa.apelido%TYPE,
  p_nome                   IN pessoa.nome%TYPE,
  p_flag_pessoa_jur        IN VARCHAR2,
  p_flag_cpom              IN VARCHAR2,
  p_cnpj                   IN pessoa.cnpj%TYPE,
  p_inscr_estadual         IN pessoa.inscr_estadual%TYPE,
  p_inscr_municipal        IN pessoa.inscr_municipal%TYPE,
  p_inscr_inss             IN pessoa.inscr_inss%TYPE,
  p_cpf                    IN pessoa.cpf%TYPE,
  p_rg                     IN pessoa.rg%TYPE,
  p_rg_org_exp             IN pessoa.rg_org_exp%TYPE,
  p_rg_uf                  IN pessoa.rg_uf%TYPE,
  p_rg_data_exp            IN VARCHAR2,
  p_flag_sem_docum         IN VARCHAR2,
  p_endereco               IN pessoa.endereco%TYPE,
  p_num_ender              IN pessoa.num_ender%TYPE,
  p_compl_ender            IN pessoa.compl_ender%TYPE,
  p_bairro                 IN pessoa.bairro%TYPE,
  p_cep                    IN pessoa.cep%TYPE,
  p_cidade                 IN pessoa.cidade%TYPE,
  p_uf                     IN pessoa.uf%TYPE,
  p_pais                   IN pessoa.pais%TYPE,
  p_website                IN pessoa.website%TYPE,
  p_email                  IN pessoa.email%TYPE,
  p_ddd_telefone           IN pessoa.ddd_telefone%TYPE,
  p_num_telefone           IN pessoa.num_telefone%TYPE,
  p_num_ramal              IN pessoa.num_ramal%TYPE,
  p_ddd_celular            IN pessoa.ddd_celular%TYPE,
  p_num_celular            IN pessoa.num_celular%TYPE,
  p_obs                    IN pessoa.obs%TYPE,
  p_fi_banco_id            IN pessoa.fi_banco_id%TYPE,
  p_num_agencia            IN pessoa.num_agencia%TYPE,
  p_num_conta              IN pessoa.num_conta%TYPE,
  p_tipo_conta             IN pessoa.tipo_conta%TYPE,
  p_nome_titular           IN pessoa.nome_titular%TYPE,
  p_cnpj_cpf_titular       IN pessoa.cnpj_cpf_titular%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_num_dias_fatur         IN VARCHAR2,
  p_tipo_num_dias_fatur    IN pessoa.tipo_num_dias_fatur%TYPE,
  p_flag_fornec_interno    IN VARCHAR2,
  p_flag_emp_resp          IN VARCHAR2,
  p_flag_emp_fatur         IN VARCHAR2,
  p_flag_pago_cliente      IN VARCHAR2,
  p_cod_job                IN pessoa.cod_job%TYPE,
  p_num_primeiro_job       IN VARCHAR2,
  p_data_entrada_agencia   IN VARCHAR2,
  p_emp_resp_pdr_id        IN pessoa.emp_resp_pdr_id%TYPE,
  p_emp_fatur_pdr_id       IN pessoa.emp_fatur_pdr_id%TYPE,
  p_setor_id               IN pessoa.setor_id%TYPE,
  p_cod_ext_pessoa         IN VARCHAR2,
  p_cod_ext_resp           IN VARCHAR2,
  p_cod_ext_fatur          IN VARCHAR2,
  p_tipo_publ_priv         IN VARCHAR2,
  p_flag_obriga_email      IN VARCHAR2,
  p_chave_pix              IN VARCHAR2,
  p_tipo_num_cotacoes      IN VARCHAR2,
  p_num_cotacoes           IN VARCHAR2,
  p_flag_cli_aprov_os      IN VARCHAR2,
  p_flag_cli_aval_os       IN VARCHAR2,
  p_regime_tributario      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_delimitador            CHAR(1);
  v_cpf                    pessoa.cpf%TYPE;
  v_cnpj                   pessoa.cnpj%TYPE;
  v_pais                   pessoa.pais%TYPE;
  v_vetor_tipo_pessoa      VARCHAR2(2000);
  v_tipo_pessoa_id         tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_tipo_pessoa        tipo_pessoa.codigo%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_num_dias_fatur         pessoa.num_dias_fatur%TYPE;
  v_cnpj_cpf_titular       pessoa.cnpj_cpf_titular%TYPE;
  v_num_primeiro_job       pessoa.num_primeiro_job%TYPE;
  v_data_entrada_agencia   pessoa.data_entrada_agencia%TYPE;
  v_flag_fornec_interno    pessoa.flag_fornec_interno%TYPE;
  v_nome_anterior          pessoa.nome%TYPE;
  v_pessoa_pai_id          relacao.pessoa_pai_id%TYPE;
  v_qt_org_pub             INTEGER;
  v_qt_estrang             INTEGER;
  v_qt_cliente             INTEGER;
  v_qt_fornec              INTEGER;
  v_qt_interno             INTEGER;
  v_flag_admin             usuario.flag_admin%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_vetor_natureza_item_id VARCHAR2(1000);
  v_vetor_valor_padrao     VARCHAR2(1000);
  v_natureza_item_id       pessoa_nitem_pdr.natureza_item_id%TYPE;
  v_valor_padrao           pessoa_nitem_pdr.valor_padrao%TYPE;
  v_valor_padrao_char      VARCHAR2(50);
  v_nome_natureza          natureza_item.nome%TYPE;
  v_mod_calculo            natureza_item.mod_calculo%TYPE;
  v_desc_calculo           VARCHAR2(100);
  v_tipo_pessoa            tipo_pessoa.codigo%TYPE;
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  v_parametros             VARCHAR2(500);
  v_sistema_externo_id     sistema_externo.sistema_externo_id%TYPE;
  v_obriga_setor_cli       VARCHAR2(10);
  v_pdr_num_job            VARCHAR2(50);
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_obriga_setor_cli     := empresa_pkg.parametro_retornar(p_empresa_id, 'OBRIGAR_SETOR_CLIENTE');
  v_pdr_num_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_JOB');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE flag_ativo = 'S'
     AND tipo_sistema = 'FIN';
  --
  --RP_170625
  SELECT nvl(MAX(CASE
                  WHEN tpe.codigo = 'FORNECEDOR' THEN
                   'FORNECEDOR'
                 END),
             'NA')
    INTO v_tipo_pessoa
    FROM tipific_pessoa tp
   INNER JOIN tipo_pessoa tpe
      ON tpe.tipo_pessoa_id = tp.tipo_pessoa_id
   WHERE tp.pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  -- (PESOA_A - privilegio virtual - nao existe na tabela privilegio)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_A', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_fornec_interno,
         nome
    INTO v_flag_fornec_interno,
         v_nome_anterior
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se a pessoa é contato de alguma empresa (pessoa filho).
  SELECT MAX(pessoa_pai_id)
    INTO v_pessoa_pai_id
    FROM relacao
   WHERE pessoa_filho_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_apelido) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do apelido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome/razão social é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_publ_priv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento de Público/Privado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_publ_priv', TRIM(p_tipo_publ_priv)) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo Público/Privado inválido (' || p_tipo_publ_priv || ').';
   RAISE v_exception;
  END IF;
  --
  --SE PESSOA JURIDICA
  IF p_flag_pessoa_jur = 'S'
  THEN
   --
   IF flag_validar(p_flag_cpom) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag CPOM inválido.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_flag_sem_docum, 'N') <> 'S'
   THEN
    IF rtrim(p_cnpj) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do CNPJ é obrigatório.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF rtrim(p_cpf) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O CPF só deve ser fornecido para pessoas físicas.';
    RAISE v_exception;
   END IF;
   --
   IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CNPJ inválido.';
    RAISE v_exception;
   END IF;
   --
   v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
   --
   IF TRIM(p_inscr_estadual) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição Estadual é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_inscr_municipal) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição Municipal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_inscr_inss) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da Inscrição INSS é obrigatório.';
    RAISE v_exception;
   END IF; --Flag_sem_doc = N;
   --
  END IF; -- FIM Pessoa juridica;
  --ALCBO_020725
  --SE PESSOA FISICA
  IF p_flag_pessoa_jur = 'N'
  THEN
   --
   IF rtrim(p_cnpj) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O CNPJ só deve ser fornecido para pessoas jurídicas.';
    RAISE v_exception;
   END IF;
   --
   IF cpf_pkg.validar(p_cpf, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CPF inválido.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_uf IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_org_exp IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Órgão Expedidor do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_rg_data_exp IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de expedição do RG é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_rg_data_exp) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de expedição do RG inválida.';
    RAISE v_exception;
   END IF;
   --
   v_cpf := cpf_pkg.converter(p_cpf, p_empresa_id);
   --
   --Se flag_sem_documento marcada e for fisico
   IF nvl(p_flag_sem_docum, 'N') <> 'S'
   THEN
    IF v_cpf IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do CPF é obrigatório.';
     RAISE v_exception;
    END IF;
    --
   END IF; --flag_sem documento = N
   --
  END IF; --fim pessoa fisica
  --
  --
  IF nvl(p_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_num_agencia) IS NULL OR TRIM(p_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta ' ||
                  '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                  'devem ser informados quando se tratar de outra pessoa).';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_fi_banco_id, 0) = 0 AND
     (TRIM(p_num_agencia) IS NOT NULL OR TRIM(p_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco ' ||
                 '(OBS: O nome do titular da conta e o CNPJ/CPF só ' ||
                 'devem ser informados quando se tratar de outra pessoa).';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cnpj_cpf_titular) IS NOT NULL
  THEN
   IF cnpj_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
   THEN
    IF cpf_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'CNPJ/CPF do titular da conta inválido.';
     RAISE v_exception;
    ELSE
     v_cnpj_cpf_titular := cpf_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
    END IF;
   ELSE
    v_cnpj_cpf_titular := cnpj_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
   END IF;
   --
   IF TRIM(p_nome_titular) IS NULL OR v_cnpj_cpf_titular = v_cnpj OR v_cnpj_cpf_titular = v_cpf
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  ELSE
   v_cnpj_cpf_titular := NULL;
   --
   IF TRIM(p_nome_titular) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O nome do titular da conta e o CNPJ/CPF devem ser informados em conjunto, ' ||
                  'apenas quando se tratar de outra pessoa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --ALCBO_251024
  IF TRIM(p_chave_pix) IS NOT NULL
  THEN
   IF pessoa_pkg.chave_pix_validar(TRIM(p_chave_pix)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Chave pix inválida (' || TRIM(p_chave_pix) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF inteiro_validar(p_num_ender) = 0 OR to_number(p_num_ender) > 999999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do endereço inválido.';
   RAISE v_exception;
  END IF;
  --
  v_pais := TRIM(upper(acento_retirar(p_pais)));
  --
  IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL', 'BRA', 'BR')
  THEN
   v_pais := 'BRASIL';
  END IF;
  --
  IF v_pais IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pais
    WHERE upper(nome) = upper(v_pais);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'País inválido (' || p_pais || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cep) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.validar(p_cep) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND TRIM(p_cidade) IS NOT NULL AND
     (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.municipio_validar(p_uf, p_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do endereço inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_obriga_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_obriga_email = 'S' AND TRIM(p_email) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Email é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_conta) IS NOT NULL AND p_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencias para clientes
  --
  IF inteiro_validar(p_num_dias_fatur) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias para faturamento do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur := to_number(p_num_dias_fatur);
  --
  IF p_tipo_num_dias_fatur NOT IN ('C', 'U')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de dias para faturamento do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pago_cliente) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pago pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_primeiro_job) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do primeiro ' || v_lbl_job || ' do cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  v_num_primeiro_job := to_number(p_num_primeiro_job);
  --
  IF data_validar(p_data_entrada_agencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada na ' || v_lbl_agencia_singular || ' inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_entrada_agencia := data_converter(p_data_entrada_agencia);
  --
  IF nvl(p_emp_resp_pdr_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_resp_pdr_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa responsável padrão não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_emp_fatur_pdr_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_fatur_pdr_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa empresa para faturamento padrão não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_setor_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM setor
    WHERE setor_id = p_setor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse setor não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- consistencias para fornecedores
  --
  /*IF length(p_desc_servicos) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição dos produtos prestados pelo fornecedor ' ||
                 'não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;*/
  --
  IF flag_validar(p_flag_fornec_interno) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag fornecedor interno inválido.';
   RAISE v_exception;
  END IF;
  --
  /*
  IF v_flag_fornec_interno <> p_flag_fornec_interno THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A indicação de fornecedor interno não pode ser modificada.';
     RAISE v_exception;
  END IF;*/
  --
  -- consistencias adicionais
  --
  IF flag_validar(p_flag_emp_resp) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag empresa responsável inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_emp_fatur) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag empresa de faturamento inválido.';
   RAISE v_exception;
  END IF;
  --
  /*IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF; */
  --
  IF length(TRIM(p_cod_ext_pessoa)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo não pode ter mais que 20 caracteres (' || p_cod_ext_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_resp)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo da empresa de responsável não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_resp || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_fatur)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo da empresa de faturamento não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_sistema_externo_id IS NULL AND
     (TRIM(p_cod_ext_resp) IS NOT NULL OR TRIM(p_cod_ext_resp) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe sistema financeiro ativo para armazenar os códigos externos.';
   RAISE v_exception;
  END IF;
  --
  IF v_sistema_externo_id IS NULL AND
     (TRIM(p_cod_ext_fatur) IS NOT NULL OR TRIM(p_cod_ext_fatur) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe sistema financeiro ativo para armazenar os códigos externos.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_flag_admin = 'N'
  THEN
   -- nao e administrador. Precisa consistir duplicidade.
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE cnpj = v_cnpj
      AND pessoa_id <> p_pessoa_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse CNPJ já existe (' || v_cnpj || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE cpf = v_cpf
      AND pessoa_id <> p_pessoa_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse CPF já existe (' || v_cpf || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cod_job) IS NOT NULL
  THEN
   IF instr(TRIM(p_cod_job), ' ') > 0 OR instr(TRIM(p_cod_job), '%') > 0 OR
      lower(TRIM(p_cod_job)) <> acento_retirar(TRIM(p_cod_job))
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter caracteres em branco, ' ||
                  'com acentuação ou % (' || upper(p_cod_job) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --ALCBO_041124
  IF length(TRIM(p_compl_ender)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 100 caracteres (' ||
                 p_compl_ender || ').';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET apelido              = TRIM(p_apelido),
         nome                 = TRIM(p_nome),
         cnpj                 = v_cnpj,
         inscr_estadual       = TRIM(p_inscr_estadual),
         inscr_municipal      = TRIM(p_inscr_municipal),
         inscr_inss           = TRIM(p_inscr_inss),
         flag_pessoa_jur      = p_flag_pessoa_jur,
         flag_sem_docum       = nvl(p_flag_sem_docum, 'N'),
         rg                   = p_rg,
         rg_org_exp           = p_rg_org_exp,
         rg_uf                = upper(TRIM(p_rg_uf)),
         rg_data_exp          = data_converter(p_rg_data_exp),
         cpf                  = v_cpf,
         endereco             = TRIM(p_endereco),
         num_ender            = p_num_ender,
         compl_ender          = TRIM(p_compl_ender),
         bairro               = TRIM(p_bairro),
         cep                  = cep_pkg.converter(TRIM(p_cep)),
         cidade               = TRIM(p_cidade),
         uf                   = upper(TRIM(p_uf)),
         pais                 = v_pais,
         website              = TRIM(p_website),
         email                = TRIM(p_email),
         ddd_telefone         = p_ddd_telefone,
         num_telefone         = p_num_telefone,
         num_ramal            = p_num_ramal,
         ddd_celular          = p_ddd_celular,
         num_celular          = p_num_celular,
         obs                  = TRIM(p_obs),
         fi_banco_id          = zvl(p_fi_banco_id, NULL),
         num_agencia          = p_num_agencia,
         num_conta            = p_num_conta,
         tipo_conta           = TRIM(p_tipo_conta),
         nome_titular         = TRIM(p_nome_titular),
         cnpj_cpf_titular     = v_cnpj_cpf_titular,
         num_dias_fatur       = v_num_dias_fatur,
         tipo_num_dias_fatur  = nvl(p_tipo_num_dias_fatur, 'C'),
         flag_fornec_interno  = p_flag_fornec_interno,
         flag_emp_fatur       = p_flag_emp_fatur,
         flag_emp_resp        = p_flag_emp_resp,
         flag_pago_cliente    = p_flag_pago_cliente,
         cod_job              = TRIM(upper(p_cod_job)),
         num_primeiro_job     = v_num_primeiro_job,
         data_entrada_agencia = v_data_entrada_agencia,
         emp_resp_pdr_id      = zvl(p_emp_resp_pdr_id, NULL),
         emp_fatur_pdr_id     = zvl(p_emp_fatur_pdr_id, NULL),
         setor_id             = zvl(p_setor_id, NULL),
         flag_cpom            = p_flag_cpom,
         cod_ext_pessoa       = TRIM(p_cod_ext_pessoa),
         tipo_publ_priv       = TRIM(p_tipo_publ_priv),
         chave_pix            = TRIM(p_chave_pix), --ALCBO_251024
         tipo_num_cotacoes    = p_tipo_num_cotacoes,
         num_cotacoes         = p_num_cotacoes,
         flag_cli_aprov_os    = p_flag_cli_aprov_os,
         flag_cli_aval_os     = p_flag_cli_aval_os,
         regime_tributario = CASE -- RP_170625
                              WHEN v_tipo_pessoa = 'FORNECEDOR' THEN
                               p_regime_tributario -- recebe o valor que vem da procedure
                              ELSE
                               'NA' -- caso NÃO seja FORNECEDOR, grava NA
                             END
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- tratamento dos codigos externos
  ------------------------------------------------------------
  IF v_sistema_externo_id IS NOT NULL
  THEN
   DELETE FROM empr_fatur_sist_ext
    WHERE sistema_externo_id = v_sistema_externo_id
      AND pessoa_id = p_pessoa_id;
   --
   DELETE FROM empr_resp_sist_ext
    WHERE sistema_externo_id = v_sistema_externo_id
      AND pessoa_id = p_pessoa_id;
   --
   IF TRIM(p_cod_ext_fatur) IS NOT NULL
   THEN
    INSERT INTO empr_fatur_sist_ext
     (sistema_externo_id,
      pessoa_id,
      cod_ext_fatur)
    VALUES
     (v_sistema_externo_id,
      p_pessoa_id,
      TRIM(p_cod_ext_fatur));
   END IF;
   --
   IF TRIM(p_cod_ext_resp) IS NOT NULL
   THEN
    INSERT INTO empr_resp_sist_ext
     (sistema_externo_id,
      pessoa_id,
      cod_ext_resp)
    VALUES
     (v_sistema_externo_id,
      p_pessoa_id,
      TRIM(p_cod_ext_resp));
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de naturezas do item
  ------------------------------------------------------------
  DELETE FROM pessoa_nitem_pdr
   WHERE pessoa_id = p_pessoa_id;
  --
  v_delimitador            := '|';
  v_vetor_natureza_item_id := rtrim(p_vetor_natureza_item_id);
  v_vetor_valor_padrao     := rtrim(p_vetor_valor_padrao);
  --
  WHILE nvl(length(rtrim(v_vetor_natureza_item_id)), 0) > 0
  LOOP
   v_natureza_item_id  := nvl(to_number(prox_valor_retornar(v_vetor_natureza_item_id, v_delimitador)),
                              0);
   v_valor_padrao_char := prox_valor_retornar(v_vetor_valor_padrao, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa (' ||
                  to_char(v_natureza_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          util_pkg.desc_retornar('mod_calculo', mod_calculo),
          mod_calculo
     INTO v_nome_natureza,
          v_desc_calculo,
          v_mod_calculo
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_id;
   --
   IF v_mod_calculo = 'NA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não se aplica para cálculos (' || v_nome_natureza || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_valor_padrao_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' ||
                  v_valor_padrao_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_padrao := numero_converter(v_valor_padrao_char);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa_nitem_pdr
    WHERE pessoa_id = p_pessoa_id
      AND natureza_item_id = v_natureza_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem naturezas repetidas (' || v_nome_natureza || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO pessoa_nitem_pdr
    (pessoa_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (p_pessoa_id,
     v_natureza_item_id,
     v_valor_padrao);
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipos de pessoa
  ------------------------------------------------------------
  /* v_delimitador       := '|';
  v_vetor_tipo_pessoa := p_vetor_tipo_pessoa;
  v_qt_org_pub        := 0;
  v_qt_estrang        := 0;
  v_qt_cliente        := 0;
  v_qt_fornec         := 0;
  v_qt_interno        := 0;
  --
  DELETE FROM tipific_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa, v_delimitador));
   --
   SELECT codigo
     INTO v_cod_tipo_pessoa
     FROM tipo_pessoa
    WHERE tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_cod_tipo_pessoa = 'CLIENTE' THEN
    v_qt_cliente := v_qt_cliente + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'FORNECEDOR' THEN
    v_qt_fornec := v_qt_fornec + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa IN ('ORG_PUB_MUN', 'ORG_PUB_EST', 'ORG_PUB_FED') THEN
    v_qt_org_pub := v_qt_org_pub + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'ESTRANGEIRO' THEN
    v_qt_estrang := v_qt_estrang + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'INTERNO' THEN
    v_qt_interno := v_qt_interno + 1;
   END IF;
   --
   --
   INSERT INTO tipific_pessoa
    (pessoa_id,
     tipo_pessoa_id)
   VALUES
    (p_pessoa_id,
     v_tipo_pessoa_id);
  END LOOP;*/
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
  IF v_qt_estrang > 0 AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR'))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Foi indicada pessoa no estrangeiro com endereço no Brasil.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_pessoa_jur = 'N' AND v_qt_org_pub > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa física não pode ser associada ao tipo "orgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada a mais de um tipo de orgão público.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 0 AND v_qt_estrang > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada ao tipo "orgão público" ' ||
                 'e "estrangeiro" ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_fornec = 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos devem ser associados ao tipo de pessoa "fornecedor".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_cliente > 0
  THEN
   IF v_obriga_setor_cli = 'S' AND nvl(v_pessoa_pai_id, 0) = 0 AND nvl(p_setor_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente", o preenchimento do setor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_fornec_interno = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "cliente".';
    RAISE v_exception;
   END IF;
   --
   -- consistencia de cod job (exceto contatos de cliente)
   IF nvl(v_pessoa_pai_id, 0) = 0 AND TRIM(p_cod_job) IS NULL AND
      v_pdr_num_job = 'SEQUENCIAL_POR_CLIENTE'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" o preenchimento ' || 'do Código do ' || v_lbl_job ||
                  ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   -- consistencia de empresa resp (exceto contatos de cliente)
   IF nvl(v_pessoa_pai_id, 0) = 0 AND nvl(p_emp_resp_pdr_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente" a empresa responsável padrão deve ser informada.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_qt_org_pub > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "órgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_estrang > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "estrangeiro".';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF TRIM(v_nome_anterior) <> TRIM(p_nome)
  THEN
   -- se a razao social mudou, passa via parametro
   v_parametros := TRIM(v_nome_anterior);
  END IF;
  --
  it_controle_pkg.integrar('PESSOA_ATUALIZAR_OPCIONAL',
                           p_empresa_id,
                           p_pessoa_id,
                           v_parametros,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- atualizar
 --
 --
 PROCEDURE contato_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 10/06/2025
  -- DESCRICAO: Inclusão de CONTATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_funcao            IN pessoa.funcao%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_ddd_telefone      IN pessoa.ddd_telefone%TYPE,
  p_num_telefone      IN pessoa.num_telefone%TYPE,
  p_num_ramal         IN pessoa.num_ramal%TYPE,
  p_ddd_cel_part      IN pessoa.ddd_cel_part%TYPE,
  p_num_cel_part      IN pessoa.num_cel_part%TYPE,
  p_ddd_celular       IN pessoa.ddd_celular%TYPE,
  p_num_celular       IN pessoa.num_celular%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_pais              IN pessoa.pais%TYPE,
  p_pessoa_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_pessoa_id      pessoa.pessoa_id%TYPE;
  v_pais           pessoa.pais%TYPE;
  v_tipo_pessoa_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  v_pdr_num_job    VARCHAR2(50);
  --
 BEGIN
  v_qt                   := 0;
  p_pessoa_id            := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_pdr_num_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_JOB');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_pessoa_pai_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato de é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_pessoa_pai_id IS NOT NULL AND p_pessoa_pai_id > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_pessoa_pai_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa pessoa pai não existe existe (' || to_char(p_pessoa_pai_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- verifica se a pessoa pai ja tem um contato com esse nome
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa  pe,
          relacao re
    WHERE re.pessoa_pai_id = p_pessoa_pai_id
      AND re.pessoa_filho_id = pe.pessoa_id
      AND acento_retirar(pe.apelido) = acento_retirar(TRIM(p_apelido));
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse apelido de contato já existe (' || p_apelido || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_apelido) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do apelido é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_pais := TRIM(upper(acento_retirar(p_pais)));
  --
  IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL', 'BRA', 'BR')
  THEN
   v_pais := 'BRASIL';
  END IF;
  --
  IF v_pais IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pais
    WHERE upper(nome) = upper(v_pais);
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'País inválido (' || p_pais || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_cep) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.validar(p_cep) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_uf) IS NOT NULL AND TRIM(p_cidade) IS NOT NULL AND
     (v_pais IS NULL OR upper(v_pais) = 'BRASIL')
  THEN
   IF cep_pkg.municipio_validar(p_uf, p_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do endereço inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF email_validar(p_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  IF p_pessoa_pai_id IS NOT NULL AND p_pessoa_pai_id > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_pessoa_pai_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa pessoa pai não existe existe (' || to_char(p_pessoa_pai_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- verifica se a pessoa pai ja tem um contato com esse nome
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa  pe,
          relacao re
    WHERE re.pessoa_pai_id = p_pessoa_pai_id
      AND re.pessoa_filho_id = pe.pessoa_id
      AND acento_retirar(pe.apelido) = acento_retirar(TRIM(p_apelido));
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse apelido de contato já existe (' || p_apelido || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(TRIM(p_compl_ender)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 100 caracteres (' ||
                 p_compl_ender || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_pessoa.nextval
    INTO v_pessoa_id
    FROM dual;
  --
  INSERT INTO pessoa
   (empresa_id,
    pessoa_id,
    flag_ativo,
    apelido,
    nome,
    funcao,
    obs,
    flag_pessoa_jur,
    ddd_telefone,
    num_telefone,
    num_ramal,
    ddd_cel_part,
    num_cel_part,
    ddd_celular,
    num_celular,
    email,
    cep,
    endereco,
    num_ender,
    compl_ender,
    bairro,
    cidade,
    uf,
    pais)
  VALUES
   (p_empresa_id,
    v_pessoa_id,
    'S', --flag_ativo
    TRIM(p_apelido),
    TRIM(p_nome),
    TRIM(p_funcao),
    TRIM(p_obs),
    'N',
    p_ddd_telefone,
    p_num_telefone,
    p_num_ramal,
    p_ddd_cel_part,
    p_num_cel_part,
    p_ddd_celular,
    p_num_celular,
    TRIM(p_email),
    cep_pkg.converter(rtrim(p_cep)),
    TRIM(p_endereco),
    p_num_ender,
    TRIM(p_compl_ender),
    TRIM(p_bairro),
    TRIM(p_cidade),
    upper(TRIM(p_uf)),
    v_pais);
  --
  ------------------------------------------------------------
  -- tratamento dos codigos externos
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- tratamento do vetor de naturezas do item
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- demais atualizacoes
  ------------------------------------------------------------
  IF p_pessoa_pai_id IS NOT NULL AND p_pessoa_pai_id > 0
  THEN
   --
   INSERT INTO relacao
    (pessoa_pai_id,
     pessoa_filho_id)
   VALUES
    (p_pessoa_pai_id,
     v_pessoa_id);
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio (a verificacao ficou p/ o final,
  -- pois ela depende dos tipos dessa pessoa que estao gravados no banco)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', v_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_pessoa_id := v_pessoa_id;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- contato_adicionar
 --
 --
 --
 PROCEDURE contato_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 10/06/2025
  -- DESCRICAO: Atualização do CONTATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN relacao.pessoa_pai_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_apelido           IN pessoa.apelido%TYPE,
  p_nome              IN pessoa.nome%TYPE,
  p_funcao            IN pessoa.funcao%TYPE,
  p_obs               IN pessoa.obs%TYPE,
  p_ddd_telefone      IN pessoa.ddd_telefone%TYPE,
  p_num_telefone      IN pessoa.num_telefone%TYPE,
  p_num_ramal         IN pessoa.num_ramal%TYPE,
  p_ddd_cel_part      IN pessoa.ddd_cel_part%TYPE,
  p_num_cel_part      IN pessoa.num_cel_part%TYPE,
  p_ddd_celular       IN pessoa.ddd_celular%TYPE,
  p_num_celular       IN pessoa.num_celular%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_cep               IN pessoa.cep%TYPE,
  p_endereco          IN pessoa.endereco%TYPE,
  p_num_ender         IN pessoa.num_ender%TYPE,
  p_compl_ender       IN pessoa.compl_ender%TYPE,
  p_bairro            IN pessoa.bairro%TYPE,
  p_cidade            IN pessoa.cidade%TYPE,
  p_uf                IN pessoa.uf%TYPE,
  p_pais              IN pessoa.pais%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_pais_norm      pessoa.pais%TYPE;
 BEGIN
  ------------------------------------------------------------
  -- validações
  ------------------------------------------------------------
  IF rtrim(p_pessoa_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato de é obrigatório.';
   RAISE v_exception;
  END IF;
 
  IF rtrim(p_apelido) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apelido é obrigatório.';
   RAISE v_exception;
  END IF;
 
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nome é obrigatório.';
   RAISE v_exception;
  END IF;
 
  v_pais_norm := TRIM(upper(acento_retirar(p_pais)));
  IF upper(v_pais_norm) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL', 'BRA', 'BR')
  THEN
   v_pais_norm := 'BRASIL';
  END IF;
 
  IF v_pais_norm IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pais
    WHERE upper(nome) = upper(v_pais_norm);
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'País inválido (' || p_pais || ').';
    RAISE v_exception;
   END IF;
  END IF;
 
  IF TRIM(p_cep) IS NOT NULL AND (v_pais_norm IS NULL OR upper(v_pais_norm) = 'BRASIL')
  THEN
   IF cep_pkg.validar(p_cep) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido.';
    RAISE v_exception;
   END IF;
  END IF;
 
  IF TRIM(p_uf) IS NOT NULL AND (v_pais_norm IS NULL OR upper(v_pais_norm) = 'BRASIL')
  THEN
   IF util_pkg.desc_retornar('estado', TRIM(p_uf)) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida.';
    RAISE v_exception;
   END IF;
  END IF;
 
  IF TRIM(p_uf) IS NOT NULL AND TRIM(p_cidade) IS NOT NULL AND
     (v_pais_norm IS NULL OR upper(v_pais_norm) = 'BRASIL')
  THEN
   IF cep_pkg.municipio_validar(p_uf, p_cidade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município inválido.';
    RAISE v_exception;
   END IF;
  END IF;
 
  IF email_validar(p_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
 
  IF length(TRIM(p_compl_ender)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complemento do endereço excede o limite de 100 caracteres.';
   RAISE v_exception;
  END IF;
 
  ------------------------------------------------------------
  -- atualização
  ------------------------------------------------------------
  UPDATE pessoa
     SET apelido      = TRIM(p_apelido),
         nome         = TRIM(p_nome),
         funcao       = TRIM(p_funcao),
         obs          = TRIM(p_obs),
         ddd_telefone = p_ddd_telefone,
         num_telefone = p_num_telefone,
         num_ramal    = p_num_ramal,
         ddd_cel_part = p_ddd_cel_part,
         num_cel_part = p_num_cel_part,
         ddd_celular  = p_ddd_celular,
         num_celular  = p_num_celular,
         email        = TRIM(p_email),
         cep          = cep_pkg.converter(rtrim(p_cep)),
         endereco     = TRIM(p_endereco),
         num_ender    = p_num_ender,
         compl_ender  = TRIM(p_compl_ender),
         bairro       = TRIM(p_bairro),
         cidade       = TRIM(p_cidade),
         uf           = upper(TRIM(p_uf)),
         pais         = v_pais_norm
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
 
  IF SQL%ROWCOUNT = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa não encontrada.';
   RAISE v_exception;
  END IF;
 
  ------------------------------------------------------------
  -- segurança
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para atualizar essa pessoa.';
   RAISE v_exception;
  END IF;
 
  ------------------------------------------------------------
  -- log e evento
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
 
  v_identif_objeto := TRIM(p_nome);
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   NULL,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
 
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- contato_atualizar
 --
 --
 --
 PROCEDURE qualificacao_fornec_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 10/06/2025
  -- DESCRICAO: Atualização da qualificacao do fornecedor na tabela de PESSOA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         25/06/2025  Adicionado novos parametros de entrada e tratamentos dos 
  --                               dados de entrada
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_nivel_qualidade    IN VARCHAR2,
  p_nivel_parceria     IN VARCHAR2,
  p_nivel_relac        IN VARCHAR2,
  p_nivel_custo        IN pessoa.nivel_custo%TYPE,
  p_parcela            IN pessoa.parcela%TYPE,
  p_porte              IN pessoa.porte%TYPE,
  p_aval_ai            IN pessoa.aval_ai%TYPE,
  p_vetor_tipo_produto IN VARCHAR2, --ALCBO_250625
  p_comentario         IN VARCHAR2, --ALCBO_250625
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_flag_qualificado   VARCHAR2(1);
  v_exception          EXCEPTION;
  v_flag_admin         usuario.flag_admin%TYPE;
  v_nivel_qualidade    pessoa.nivel_qualidade%TYPE;
  v_nivel_parceria     pessoa.nivel_parceria%TYPE;
  v_nivel_relac        pessoa.nivel_relac%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_pais_norm          pessoa.pais%TYPE;
  v_vetor_tipo_produto VARCHAR2(1000);
  v_delimitador        CHAR(1);
  v_tipo_produto_id    pessoa_tipo_produto.tipo_produto_id%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --ALCBO_250625
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nivel_custo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nivel de custo é obrigatório.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  IF length(TRIM(p_comentario)) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Comentário não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- tratamento dos dados de entrada
  ------------------------------------------------------------
  v_nivel_qualidade := nvl(numero_converter(p_nivel_qualidade), 0);
  v_nivel_parceria  := nvl(taxa_converter(p_nivel_parceria), 0);
  v_nivel_relac     := nvl(taxa_converter(p_nivel_relac), 0);
  --
  -- Calcula o flag_qualificado (se houver alguma qualificacao então S senão N)
  IF (p_nivel_qualidade > 0 OR p_nivel_parceria > 0 OR p_nivel_relac > 0 OR p_nivel_custo > 0 OR
     p_parcela > 0 OR (p_porte IS NOT NULL AND upper(p_porte) <> 'ND') OR p_aval_ai IS NOT NULL)
  THEN
   v_flag_qualificado := 'S';
  ELSE
   v_flag_qualificado := 'N';
  END IF;
  --ALCBO_250625
  v_vetor_tipo_produto := rtrim(p_vetor_tipo_produto);
  v_delimitador        := '|';
  WHILE nvl(length(rtrim(v_vetor_tipo_produto)), 0) > 0
  LOOP
   v_tipo_produto_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_produto, v_delimitador)), 0);
   --exclui registros do vetor anterior
   DELETE pessoa_tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id
      AND pessoa_id = p_pessoa_id;
   --insere registros do novo vetor
   INSERT INTO pessoa_tipo_produto
    (pessoa_id,
     tipo_produto_id)
   VALUES
    (p_pessoa_id,
     v_tipo_produto_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualização
  ------------------------------------------------------------
  --
  UPDATE pessoa
     SET nivel_qualidade  = v_nivel_qualidade,
         nivel_parceria   = v_nivel_parceria,
         nivel_relac      = v_nivel_relac,
         nivel_custo      = p_nivel_custo,
         parcela          = p_parcela,
         porte            = p_porte,
         aval_ai          = p_aval_ai,
         flag_qualificado = v_flag_qualificado,
         comentario       = TRIM(p_comentario)
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- segurança
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_H', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para atualizar esse Fornecedor.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- log e evento
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_identif_objeto := TRIM(p_pessoa_id); --- verificar qual é o objeto que devo passar 
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   NULL,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- qualificacao_fornec_atualizar
 --
 --
 --
 PROCEDURE homologacao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 17/06/2025
  -- DESCRICAO: Inclusão de Homologação de Fornecedor
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         24/07/2025  Obrigatoriedade de validade só se status_para = Homologado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_condicao_pagto_id IN pessoa_homolog.condicao_pagto_id%TYPE,
  p_status_para       IN pessoa_homolog.status_para%TYPE,
  p_data_validade     IN VARCHAR2,
  p_perc_bv           IN VARCHAR2,
  p_tipo_fatur_bv     IN VARCHAR2,
  p_flag_tem_bv       IN VARCHAR2,
  p_perc_imposto      IN VARCHAR2,
  p_flag_nota_cobert  IN VARCHAR2,
  p_flag_tem_cobert   IN VARCHAR2,
  p_obs_homolog       IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_aval_ai_homolog   IN pessoa_homolog.flag_nota_cobert%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_pessoa_homolog_id OUT pessoa_homolog.pessoa_homolog_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_delimitador       CHAR(1);
  v_data_validade     DATE;
  v_status_de         pessoa_homolog.status_de%TYPE;
  v_tipo_fatur_bv     pessoa_homolog.tipo_fatur_bv%TYPE;
  v_flag_tem_bv       pessoa_homolog.flag_tem_bv%TYPE;
  v_perc_imposto      pessoa_homolog.perc_imposto%TYPE;
  v_flag_nota_cobert  pessoa_homolog.flag_nota_cobert%TYPE;
  v_flag_tem_cobert   pessoa_homolog.flag_tem_cobert%TYPE;
  v_perc_bv           pessoa_homolog.perc_bv%TYPE;
  v_flag_admin        usuario.flag_admin%TYPE;
  v_pessoa_id         pessoa.pessoa_id%TYPE;
  v_pessoa_homolog_id pessoa_homolog.pessoa_homolog_id%TYPE;
  v_vetor_tipo_pessoa VARCHAR2(2000);
  v_tipo_pessoa_id    tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_tipo_pessoa   tipo_pessoa.codigo%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_status_para) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  IF p_status_para = 'HMLG'
  THEN
   --ALCBO_240725
   IF rtrim(p_data_validade) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da validade é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_data_validade) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida(' || p_data_validade || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(p_perc_bv) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(p_flag_tem_bv) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag tem BV inválido.';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(p_flag_nota_cobert) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag Nota de Cobertura inválido.';
    RAISE v_exception;
   END IF;
   --
   IF taxa_validar(p_perc_imposto) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Percentual de imposto inválido (' || p_perc_imposto || ').';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(p_flag_tem_cobert) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag Tem Nota de Cobertura inválido.';
    RAISE v_exception;
   END IF;
  END IF; --ALCBO_240725
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  -- 
  v_flag_nota_cobert := TRIM(p_flag_nota_cobert);
  v_flag_tem_cobert  := TRIM(p_flag_tem_cobert);
  v_flag_tem_bv      := TRIM(p_flag_tem_bv);
  v_tipo_fatur_bv    := TRIM(p_tipo_fatur_bv);
  --
  ------------------------------------------------------------
  -- tratamento dos dados de entrada
  ------------------------------------------------------------
  v_data_validade := data_converter(p_data_validade);
  v_perc_bv       := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto  := nvl(taxa_converter(p_perc_imposto), 0);
  v_pessoa_id     := p_pessoa_id;
  --
  IF v_flag_nota_cobert IS NULL
  THEN
   v_flag_nota_cobert := 'N';
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT seq_pessoa_homolog.nextval
    INTO v_pessoa_homolog_id
    FROM dual;
 
  SELECT status_fornec_homolog
    INTO v_status_de
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  INSERT INTO pessoa_homolog
   (pessoa_homolog_id,
    pessoa_id,
    condicao_pagto_id,
    usuario_id,
    data_hora,
    status_de,
    status_para,
    perc_bv,
    tipo_fatur_bv,
    flag_tem_bv,
    perc_imposto,
    flag_nota_cobert,
    flag_tem_cobert,
    data_validade,
    obs,
    aval_ai,
    flag_atual)
  VALUES
   (v_pessoa_homolog_id,
    v_pessoa_id,
    p_condicao_pagto_id,
    p_usuario_sessao_id,
    SYSDATE,
    v_status_de,
    p_status_para,
    v_perc_bv,
    v_tipo_fatur_bv,
    v_flag_tem_bv,
    v_perc_imposto,
    v_flag_nota_cobert,
    v_flag_tem_cobert,
    v_data_validade,
    p_obs_homolog,
    p_aval_ai_homolog,
    'S');
  --
  ------------------------------------------------------------
  -- Demais atualizacões do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET status_fornec_homolog = p_status_para
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio (a verificacao ficou p/ o final,
  -- pois ela depende dos tipos dessa pessoa que estao gravados no banco)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_H', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_pessoa_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  --
  p_pessoa_homolog_id := v_pessoa_homolog_id;
  p_erro_cod          := '00000';
  p_erro_msg          := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- homologacao_adicionar
 --
 --
 PROCEDURE fornecedor_homolog_expirar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana                 ProcessMind     DATA: 24/06/2025
  -- DESCRICAO: Expiração de fornecedores homologados ativos com data expiração menor que a de  
  --            hoje vai ser chamado via job do oracle todos os dias.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_homolog.pessoa_id%TYPE,
  p_data_validade     VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_delimitador    CHAR(1);
  v_data_validade  DATE;
  v_pessoa_id      pessoa_homolog.pessoa_id%TYPE;
  v_status_de      pessoa_homolog.status_de%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  v_status_ant     pessoa_homolog.status_de%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa_homolog ph
    LEFT JOIN pessoa pe
      ON ph.pessoa_id = pe.pessoa_id
   WHERE pe.flag_ativo = 'S'
     AND empresa_id = p_empresa_id
     AND pe.pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não está ativo ou não existe para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_validade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de validade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_data_validade := data_converter(p_data_validade);
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT status_para
    INTO v_status_ant
    FROM pessoa_homolog
   WHERE pessoa_id = p_pessoa_id
     AND data_hora = (SELECT MAX(data_hora)
                        FROM pessoa_homolog
                       WHERE pessoa_id = p_pessoa_id);
  --                     
  IF v_data_validade < SYSDATE
  THEN
   INSERT INTO pessoa_homolog
    (pessoa_homolog_id,
     pessoa_id,
     condicao_pagto_id,
     usuario_id,
     data_hora,
     status_de,
     status_para,
     perc_bv,
     tipo_fatur_bv,
     flag_tem_bv,
     perc_imposto,
     flag_nota_cobert,
     data_validade,
     obs,
     aval_ai,
     flag_atual,
     flag_tem_cobert)
    SELECT seq_pessoa_homolog.nextval, -- Novo ID
           pessoa_id,
           condicao_pagto_id,
           p_usuario_sessao_id,
           SYSDATE, -- Nova data/hora do insert
           v_status_ant, -- Novo STATUS_DE
           'EXPI', -- Novo STATUS_PARA
           perc_bv,
           NULL,
           flag_tem_bv,
           NULL,
           flag_nota_cobert,
           data_validade,
           NULL,
           NULL,
           NULL,
           flag_tem_cobert
      FROM pessoa_homolog
     WHERE pessoa_id = p_pessoa_id
       AND data_hora = (SELECT MAX(data_hora)
                          FROM pessoa_homolog
                         WHERE pessoa_id = p_pessoa_id);
   --
   UPDATE pessoa
      SET status_fornec_homolog = 'EXPI'
    WHERE pessoa_id = p_pessoa_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_pessoa_id);
  v_compl_histor   := 'Expirado pelo Sistema';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END;
 --
 --
 PROCEDURE pessoa_ativar_inativar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 10/06/2025
  -- DESCRICAO: Atualização da flag_ativo da pessoa (Permite Ativar ou Inativar)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_flag_ativo     pessoa.flag_ativo%TYPE;
  v_exception      EXCEPTION;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_pais_norm      pessoa.pais%TYPE;
 BEGIN
  ------------------------------------------------------------
  -- verificação de segurança
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para atualizar essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  v_flag_ativo := p_flag_ativo;
  ------------------------------------------------------------
  -- atualização
  ------------------------------------------------------------
  --
  UPDATE pessoa
     SET flag_ativo = v_flag_ativo
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- log e evento
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_identif_objeto := TRIM(p_pessoa_id);
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   NULL,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- pessoa_ativar_inativar
 --
 --
 --
 PROCEDURE tipo_pessoa_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael                 ProcessMind     DATA: 20/06/2025
  -- DESCRICAO: Atualização do TIPO DE PESSOA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_vetor_tipo_pessoa IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_delimitador       CHAR(1);
  v_vetor_tipo_pessoa VARCHAR2(2000);
  v_tipo_pessoa_id    tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa       tipo_pessoa.codigo%TYPE;
  v_cod_tipo_pessoa   tipo_pessoa.codigo%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_qt_org_pub        INTEGER;
  v_qt_estrang        INTEGER;
  v_qt_cliente        INTEGER;
  v_qt_fornec         INTEGER;
  v_qt_interno        INTEGER;
  v_flag_admin        usuario.flag_admin%TYPE;
  v_xml_antes         CLOB;
  v_xml_atual         CLOB;
  v_parametros        VARCHAR2(500);
  --
 BEGIN
  v_qt := 0;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
 
  --
  --RP_170625
  SELECT nvl(MAX(CASE
                  WHEN tpe.codigo = 'FORNECEDOR' THEN
                   'FORNECEDOR'
                 END),
             'NA')
    INTO v_tipo_pessoa
    FROM tipific_pessoa tp
   INNER JOIN tipo_pessoa tpe
      ON tpe.tipo_pessoa_id = tp.tipo_pessoa_id
   WHERE tp.pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  -- (PESOA_A - privilegio virtual - nao existe na tabela privilegio)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_A', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  /*SELECT flag_fornec_interno,
         nome
    INTO v_flag_fornec_interno,
         v_nome_anterior
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se a pessoa é contato de alguma empresa (pessoa filho).
  SELECT MAX(pessoa_pai_id)
    INTO v_pessoa_pai_id
    FROM relacao
   WHERE pessoa_filho_id = p_pessoa_id;*/
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
 
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
 
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
 
  ------------------------------------------------------------
  -- tratamento do vetor de tipos de pessoa
  ------------------------------------------------------------
  v_delimitador       := '|';
  v_vetor_tipo_pessoa := p_vetor_tipo_pessoa;
  v_qt_org_pub        := 0;
  v_qt_estrang        := 0;
  v_qt_cliente        := 0;
  v_qt_fornec         := 0;
  v_qt_interno        := 0;
  --
  DELETE FROM tipific_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa, v_delimitador));
   --
   SELECT codigo
     INTO v_cod_tipo_pessoa
     FROM tipo_pessoa
    WHERE tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_cod_tipo_pessoa = 'CLIENTE'
   THEN
    v_qt_cliente := v_qt_cliente + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'FORNECEDOR'
   THEN
    v_qt_fornec := v_qt_fornec + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa IN ('ORG_PUB_MUN', 'ORG_PUB_EST', 'ORG_PUB_FED')
   THEN
    v_qt_org_pub := v_qt_org_pub + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'ESTRANGEIRO'
   THEN
    v_qt_estrang := v_qt_estrang + 1;
   END IF;
   --
   IF v_cod_tipo_pessoa = 'INTERNO'
   THEN
    v_qt_interno := v_qt_interno + 1;
   END IF;
   --
   --
   INSERT INTO tipific_pessoa
    (pessoa_id,
     tipo_pessoa_id)
   VALUES
    (p_pessoa_id,
     v_tipo_pessoa_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
 
  /*IF p_flag_pessoa_jur = 'N' AND v_qt_org_pub > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pessoa física não pode ser associada ao tipo "orgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada a mais de um tipo de orgão público.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_org_pub > 0 AND v_qt_estrang > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Uma pessoa não pode ser associada ao tipo "orgão público" ' ||
                 'e "estrangeiro" ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_fornec = 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos devem ser associados ao tipo de pessoa "fornecedor".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_cliente > 0
  THEN
   IF v_obriga_setor_cli = 'S' AND nvl(v_pessoa_pai_id, 0) = 0 AND nvl(p_setor_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para pessoa do tipo "cliente", o preenchimento do setor é obrigatório.';
    RAISE v_exception;
   END IF;
  --
   IF p_flag_fornec_interno = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "cliente".';
    RAISE v_exception;
   END IF;
  --
  --
  IF v_qt_org_pub > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "órgão público".';
   RAISE v_exception;
  END IF;
  --
  IF v_qt_estrang > 0 AND p_flag_fornec_interno = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fornecedores internos não podem ser associados ao tipo de pessoa "estrangeiro".';
   RAISE v_exception;
  END IF; */
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_pessoa_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- tipo_pessoa_atualizar

 --
 --
 --
 --
 PROCEDURE perfil_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/10/2011
  -- DESCRICAO: Atualização de alguns dados (perfil) da PESSOA, feitos pelo proprio usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/02/2019  Saiu parametro website e entrou num_ramal.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_pessoa_id           IN pessoa.pessoa_id%TYPE,
  p_data_nasc           IN VARCHAR2,
  p_ddd_celular         IN pessoa.ddd_celular%TYPE,
  p_num_celular         IN pessoa.num_celular%TYPE,
  p_num_ramal           IN pessoa.num_ramal%TYPE,
  p_flag_notifica_email IN usuario.flag_notifica_email%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_usuario_id     pessoa.usuario_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         usuario_id
    INTO v_nome,
         v_usuario_id
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_usuario_id <> p_usuario_sessao_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF data_nasc_validar(p_data_nasc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de nascimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notifica_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag notifica email inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET num_ramal   = p_num_ramal,
         ddd_celular = p_ddd_celular,
         num_celular = p_num_celular
   WHERE pessoa_id = p_pessoa_id;
  --
  UPDATE usuario
     SET flag_notifica_email = p_flag_notifica_email
   WHERE usuario_id = v_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Alterado pelo próprio usuário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- perfil_atualizar
 --
 --
 PROCEDURE coordenadas_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 10/02/2005
  -- DESCRICAO: Atualização das coordenadas de uma pessoa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_longitude IN VARCHAR2,
  p_latitude  IN VARCHAR2,
  p_erro_cod  OUT VARCHAR2,
  p_erro_msg  OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_longitude NUMBER;
  v_latitude  NUMBER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF coord_validar(p_longitude) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Longitude inválida.';
   RAISE v_exception;
  END IF;
  --
  IF coord_validar(p_latitude) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Latitude inválida.';
   RAISE v_exception;
  END IF;
  --
  v_longitude := coord_converter(p_longitude);
  v_latitude  := coord_converter(p_latitude);
  --
  IF v_longitude > 999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Longitude inválida.';
   RAISE v_exception;
  END IF;
  --
  IF v_latitude > 999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Latitude inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET longitude = v_longitude,
         latitude  = v_latitude
   WHERE pessoa_id = p_pessoa_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- coordenadas_atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 13/10/2004
  -- DESCRICAO: Exclusão de PESSOA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/11/2006  Alteracao de alocacao de supervisor (foi retirado da
  --                               tabela job_pdv e passou para a tabela alocacao).
  -- Silvia            27/03/2008  Consistencia de relacionamento c/ NF (emp_receita_id)
  -- Silvia            04/07/2008  Consistencia de posts.
  -- Silvia            02/10/2008  Consistencia de apontam_hora.
  -- Silvia            15/10/2008  Consistencia de notifica_pessoa.
  -- Silvia            29/03/2010  Consistencia de job_usuario.
  -- Silvia            04/08/2011  Exclusao automatica de natureza_oper_fatur.
  -- Silvia            22/09/2014  Consistencias relacionadas a contrato.
  -- Silvia            07/07/2015  Exclusao automatica de aval_fornec.
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            04/03/2016  Consistencia de faixa_aprov.
  -- Silvia            11/05/2016  Consistencia de campanha.
  -- Silvia            21/07/2016  Consistencia de regra de co-enderecamento.
  -- Silvia            08/09/2016  Exclusao automatica de pessoa_nitem_pdr.
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            11/03/2019  Consistencias de oportunidade.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  -- Silvia            28/01/2021  Exclusao automatica de pessoa_servico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_nome           pessoa.nome%TYPE;
  v_apelido        pessoa.apelido%TYPE;
  v_usuario_id     usuario.usuario_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_lbl_prodclis   VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt           := 0;
  v_lbl_job      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs     := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_prodclis := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         apelido,
         usuario_id
    INTO v_nome,
         v_apelido,
         v_usuario_id
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario/pessoa que esta' sendo excluido e' o administrador
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario u
   WHERE u.usuario_id = v_usuario_id
     AND u.flag_admin_sistema = 'S';
  --
  IF v_qt = 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O administrador não pode ser excluído.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_pai_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contatos associados a essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM historico
   WHERE usuario_id = v_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem registros de histórico associados a essa pessoa/usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data
   WHERE usuario_id = v_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de horas registrados para essa pessoa/usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE usuario_id = v_usuario_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' endereçados a essa pessoa/usuário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE contato_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a essa pessoa (como contato).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE contato_fatur_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs ||
                 ' associados a essa pessoa (como contato de faturamento).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs ||
                 ' associados a essa pessoa (como empresa a faturar por).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE emp_resp_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs ||
                 ' associados a essa pessoa (como empresa responsável).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE contato_fatur_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a essa pessoa (como contato de faturamento).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a essa pessoa (como empresa a faturar por).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE emp_fatur_pdr_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa está definida como empresa de faturamento padrão.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE emp_resp_pdr_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa está definida como empresa responsável padrão.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_pessoa
   WHERE pessoa_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos associados a essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE emp_emissora_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a essa pessoa (como empresa emissora).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a essa pessoa (como empresa a faturar por).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE emp_receita_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a essa pessoa (como empresa da receita).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM lancamento
   WHERE pessoa_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem lançamentos associados a essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE fornecedor_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem itens de Estimativas de Custos associados a essa pessoa (fornecedor).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_decup
   WHERE fornecedor_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem itens de Estimativas de Custos (decupação) associados a essa pessoa (fornecedor).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE fornecedor_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a essa pessoa (fornecedor).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE contato_fornec_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a essa pessoa (contato de fornecedor).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a essa pessoa (cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a essa pessoa (empresa de faturamento).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a essa pessoa (empresa de faturamento).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a essa pessoa (cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE contato_cli_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a essa pessoa (contato do cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE pessoa_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_prodclis || ' associados a essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de hora associados a essa pessoa (cliente).';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contratante_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a essa pessoa (contratante).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contato_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a essa pessoa (como contato).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE contato_fatur_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a essa pessoa (como contato de faturamento).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE emp_faturar_por_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a essa pessoa (como empresa a faturar por).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE emp_resp_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a essa pessoa (como empresa responsável).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_ao
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faixas de aprovação de carta acordo associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_os
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faixas de aprovação de Workflow associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM campanha
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Campanhas associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de co-endereçamento associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE cliente_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a essa pessoa (como cliente).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE contato_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a essa pessoa (como contato).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE cliente_conflito_id = p_pessoa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a essa pessoa (como cliente em conflito).';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('PESSOA_EXCLUIR',
                           p_empresa_id,
                           p_pessoa_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM relacao
   WHERE pessoa_filho_id = p_pessoa_id;
  DELETE FROM tipific_pessoa
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM unidade_negocio_cli
   WHERE cliente_id = p_pessoa_id;
  --
  DELETE FROM fi_tipo_imposto_pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM empr_fatur_sist_ext
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM pessoa_sist_ext
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM natureza_oper_fatur
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM sa_emp_resp
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM notifica_desliga
   WHERE cliente_id = p_pessoa_id;
  --
  DELETE FROM hist_ender
   WHERE tipo_objeto = 'CLI'
     AND objeto_id = p_pessoa_id;
  --
  DELETE FROM aval_fornec
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM pessoa_nitem_pdr
   WHERE pessoa_id = p_pessoa_id;
  DELETE FROM pessoa_servico
   WHERE pessoa_id = p_pessoa_id;
  --ALCBO_020725
  DELETE FROM pessoa_homolog
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  DELETE FROM usuario_papel
   WHERE usuario_id = v_usuario_id;
  DELETE FROM usuario_pref
   WHERE usuario_id = v_usuario_id;
  DELETE FROM ts_equipe
   WHERE usuario_id = v_usuario_id;
  DELETE FROM notifica_usuario
   WHERE usuario_id = v_usuario_id;
  DELETE FROM notifica_desliga
   WHERE usuario_id = v_usuario_id;
  DELETE FROM tipo_job_usuario
   WHERE usuario_id = v_usuario_id;
  DELETE FROM usuario_empresa
   WHERE usuario_id = v_usuario_id;
  DELETE FROM pesquisa
   WHERE usuario_id = v_usuario_id;
  DELETE FROM hist_senha
   WHERE usuario_id = v_usuario_id;
  DELETE FROM dia_alocacao
   WHERE usuario_id = v_usuario_id;
  DELETE FROM usuario
   WHERE usuario_id = v_usuario_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- excluir
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Adicionar arquivo na pessoa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/12/2009  Novo tipo de arquivo.
  -- Silvia            27/10/2011  Novos thumbnails para fotos de usuario.
  -- Silvia            26/06/2012  Se o usuario da sessao estiver alterando seu proprio
  --                               arquivo, nao testa o privilegio.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_pessoa_id            IN arquivo_pessoa.pessoa_id%TYPE,
  p_arquivo_id           IN arquivo.arquivo_id%TYPE,
  p_volume_id            IN arquivo.volume_id%TYPE,
  p_descricao            IN arquivo.descricao%TYPE,
  p_nome_original        IN arquivo.nome_original%TYPE,
  p_nome_fisico          IN arquivo.nome_fisico%TYPE,
  p_mime_type            IN arquivo.mime_type%TYPE,
  p_tamanho              IN arquivo.tamanho%TYPE,
  p_thumb1_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb1_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb1_nome_original IN arquivo.nome_original%TYPE,
  p_thumb1_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb1_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb1_tamanho       IN arquivo.tamanho%TYPE,
  p_thumb2_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb2_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb2_nome_original IN arquivo.nome_original%TYPE,
  p_thumb2_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb2_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb2_tamanho       IN arquivo.tamanho%TYPE,
  p_thumb3_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb3_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb3_nome_original IN arquivo.nome_original%TYPE,
  p_thumb3_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb3_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb3_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_pessoa      IN arquivo_pessoa.tipo_arq_pessoa%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nome            pessoa.nome%TYPE;
  v_apelido         pessoa.apelido%TYPE;
  v_usuario_id      pessoa.usuario_id%TYPE;
  v_tipo_thumb      arquivo_pessoa.tipo_thumb%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_tam_max_arq     tipo_arquivo.tam_max_arq%TYPE;
  v_qtd_max_arq     tipo_arquivo.qtd_max_arq%TYPE;
  v_extensoes       tipo_arquivo.extensoes%TYPE;
  v_extensao        VARCHAR2(200);
  v_qtd_arq         NUMBER(10);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         apelido,
         usuario_id
    INTO v_nome,
         v_apelido,
         v_usuario_id
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_arq_pessoa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_arq_pessoa', p_tipo_arq_pessoa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do tipo de arquivo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_pessoa IN ('FOTO_PRI', 'FOTO_SEC', 'FOTO_USU')
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_pessoa
    WHERE pessoa_id = p_pessoa_id
      AND tipo_arq_pessoa = p_tipo_arq_pessoa;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa pessoa já possui um arquivo/foto desse tipo.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_tipo_arq_pessoa IN ('FOTO_PRI', 'FOTO_SEC')
  THEN
   IF nvl(p_thumb1_arquivo_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O thumbnail não foi enviado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_tipo_arq_pessoa = 'FOTO_USU'
  THEN
   IF nvl(p_thumb1_arquivo_id, 0) = 0 OR nvl(p_thumb2_arquivo_id, 0) = 0 OR
      nvl(p_thumb3_arquivo_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Um ou mais thumbnails não foram enviados.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'PESSOA';
  --
  IF v_tipo_arquivo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de arquivo não encontrado (PESSOA).';
   RAISE v_exception;
  END IF;
  --
  SELECT tam_max_arq,
         qtd_max_arq,
         extensoes
    INTO v_tam_max_arq,
         v_qtd_max_arq,
         v_extensoes
    FROM tipo_arquivo
   WHERE tipo_arquivo_id = v_tipo_arquivo_id;
  --
  SELECT COUNT(*)
    INTO v_qtd_arq
    FROM arquivo_pessoa
   WHERE pessoa_id = p_pessoa_id
     AND tipo_arq_pessoa = p_tipo_arq_pessoa
     AND flag_thumb = 'N';
  --
  IF v_tam_max_arq IS NOT NULL AND p_tamanho > v_tam_max_arq
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do arquivo não pode ser maior que ' || to_char(v_tam_max_arq) ||
                 ' bytes.';
   RAISE v_exception;
  END IF;
  --
  IF v_extensoes IS NOT NULL
  THEN
   v_extensao := substr(p_nome_fisico, instr(p_nome_fisico, '.') + 1);
   --
   IF instr(upper(',' || v_extensoes || ','), upper(',' || v_extensao || ',')) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa extensão do arquivo (' || upper(v_extensao) ||
                  ') não é uma das extensões válidas (' || upper(v_extensoes) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_qtd_max_arq IS NOT NULL AND v_qtd_arq + 1 > v_qtd_max_arq
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A quantidade de arquivos anexados não pode ser maior que ' ||
                 to_char(v_qtd_max_arq) || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_pessoa_id,
                        v_tipo_arquivo_id,
                        p_nome_original,
                        p_nome_fisico,
                        p_descricao,
                        p_mime_type,
                        p_tamanho,
                        NULL,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE arquivo_pessoa
     SET tipo_arq_pessoa = TRIM(p_tipo_arq_pessoa),
         flag_thumb      = 'N'
   WHERE arquivo_id = p_arquivo_id;
  --
  -- verifica se veio o primeiro thumbnail
  IF nvl(p_thumb1_arquivo_id, 0) > 0
  THEN
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_thumb1_arquivo_id,
                         p_thumb1_volume_id,
                         p_pessoa_id,
                         v_tipo_arquivo_id,
                         p_thumb1_nome_original,
                         p_thumb1_nome_fisico,
                         p_descricao,
                         p_thumb1_mime_type,
                         p_thumb1_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_tipo_thumb := NULL;
   IF p_tipo_arq_pessoa = 'FOTO_USU'
   THEN
    -- o primeiro thumbnail corresponde ao arquivo de tamanho PP
    v_tipo_thumb := 'PP';
   END IF;
   --
   UPDATE arquivo_pessoa
      SET tipo_arq_pessoa = TRIM(p_tipo_arq_pessoa),
          flag_thumb      = 'S',
          chave_thumb     = p_arquivo_id,
          tipo_thumb      = v_tipo_thumb
    WHERE arquivo_id = p_thumb1_arquivo_id;
   --
   UPDATE arquivo_pessoa
      SET chave_thumb = p_arquivo_id
    WHERE arquivo_id = p_arquivo_id;
  END IF;
  --
  --
  -- verifica se veio o segundo thumbnail
  IF nvl(p_thumb2_arquivo_id, 0) > 0
  THEN
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_thumb2_arquivo_id,
                         p_thumb2_volume_id,
                         p_pessoa_id,
                         v_tipo_arquivo_id,
                         p_thumb2_nome_original,
                         p_thumb2_nome_fisico,
                         p_descricao,
                         p_thumb2_mime_type,
                         p_thumb2_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_tipo_thumb := NULL;
   IF p_tipo_arq_pessoa = 'FOTO_USU'
   THEN
    -- o segundo thumbnail corresponde ao arquivo de tamanho P
    v_tipo_thumb := 'P';
   END IF;
   --
   UPDATE arquivo_pessoa
      SET tipo_arq_pessoa = TRIM(p_tipo_arq_pessoa),
          flag_thumb      = 'S',
          chave_thumb     = p_arquivo_id,
          tipo_thumb      = v_tipo_thumb
    WHERE arquivo_id = p_thumb2_arquivo_id;
  END IF;
  --
  --
  -- verifica se veio o terceiro thumbnail
  IF nvl(p_thumb3_arquivo_id, 0) > 0
  THEN
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_thumb3_arquivo_id,
                         p_thumb3_volume_id,
                         p_pessoa_id,
                         v_tipo_arquivo_id,
                         p_thumb3_nome_original,
                         p_thumb3_nome_fisico,
                         p_descricao,
                         p_thumb3_mime_type,
                         p_thumb3_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_tipo_thumb := NULL;
   IF p_tipo_arq_pessoa = 'FOTO_USU'
   THEN
    -- o segundo thumbnail corresponde ao arquivo de tamanho P
    v_tipo_thumb := 'M';
   END IF;
   --
   UPDATE arquivo_pessoa
      SET tipo_arq_pessoa = TRIM(p_tipo_arq_pessoa),
          flag_thumb      = 'S',
          chave_thumb     = p_arquivo_id,
          tipo_thumb      = v_tipo_thumb
    WHERE arquivo_id = p_thumb3_arquivo_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Anexação de arquivo na pessoa (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- arquivo_adicionar
 --
 --
 PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Excluir arquivo da pessoa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/12/2009  Novo tipo de arquivo.
  -- Silvia            27/10/2011  Novos thumbnails para fotos de usuario.
  -- Silvia            26/06/2012  Se o usuario da sessao estiver alterando seu proprio
  --                               arquivo, nao testa o privilegio.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nome            pessoa.nome%TYPE;
  v_apelido         pessoa.apelido%TYPE;
  v_pessoa_id       pessoa.pessoa_id%TYPE;
  v_usuario_id      pessoa.usuario_id%TYPE;
  v_nome_original   arquivo.nome_original%TYPE;
  v_tipo_arq_pessoa arquivo_pessoa.tipo_arq_pessoa%TYPE;
  v_chave_thumb     arquivo_pessoa.chave_thumb%TYPE;
  v_arquivo_id_aux  arquivo.arquivo_id%TYPE;
  --
  CURSOR c_arq IS
   SELECT arquivo_id
     FROM arquivo_pessoa
    WHERE pessoa_id = v_pessoa_id
      AND tipo_arq_pessoa = v_tipo_arq_pessoa
      AND chave_thumb = v_chave_thumb
      AND arquivo_id <> p_arquivo_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa         pe,
         arquivo_pessoa ap
   WHERE ap.arquivo_id = p_arquivo_id
     AND ap.pessoa_id = pe.pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.nome,
         pe.apelido,
         pe.pessoa_id,
         ar.nome_original,
         ap.tipo_arq_pessoa,
         ap.chave_thumb,
         pe.usuario_id
    INTO v_nome,
         v_apelido,
         v_pessoa_id,
         v_nome_original,
         v_tipo_arq_pessoa,
         v_chave_thumb,
         v_usuario_id
    FROM pessoa         pe,
         arquivo_pessoa ap,
         arquivo        ar
   WHERE ap.arquivo_id = p_arquivo_id
     AND ap.pessoa_id = pe.pessoa_id
     AND ap.arquivo_id = ar.arquivo_id;
  --
  IF v_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', v_pessoa_id, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_chave_thumb IS NOT NULL
  THEN
   -- exclui demais arquivos thumb vinculados ao arquivo que foi excluido
   FOR r_arq IN c_arq
   LOOP
    arquivo_pkg.excluir(p_usuario_sessao_id, r_arq.arquivo_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Exclusão de arquivo da pessoa (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- arquivo_excluir
 --
 --
 PROCEDURE associar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 14/10/2004
  -- DESCRICAO: Associa uma determinada pessoa pai a uma determinada pessoa filho.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/04/2013  O teste de privilegio passou para o final, apos a
  --                               associacao do contato, e passou a ser feita pelo filho.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_pessoa_filho_id   IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_pai_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa pai não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_filho_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa filho não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_pai_id = p_pessoa_pai_id
     AND pessoa_filho_id = p_pessoa_filho_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa associação de pessoas já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO relacao
   (pessoa_pai_id,
    pessoa_filho_id)
  VALUES
   (p_pessoa_pai_id,
    p_pessoa_filho_id);
  --
  ------------------------------------------------------------
  -- verificacao de privilegio via filho
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  -- (PESOA_A - privilegio virtual - nao existe na tabela privilegio)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_A',
                                p_pessoa_filho_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- associar
 --
 --
 PROCEDURE desassociar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 14/10/2004
  -- DESCRICAO: Retira a associacao de uma determinada pessoa pai com uma determinada
  --   pessoa filho.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_pai_id     IN pessoa.pessoa_id%TYPE,
  p_pessoa_filho_id   IN pessoa.pessoa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_C',
                                p_pessoa_pai_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM relacao
   WHERE pessoa_pai_id = p_pessoa_pai_id
     AND pessoa_filho_id = p_pessoa_filho_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa associação de pessoas não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM relacao
   WHERE pessoa_pai_id = p_pessoa_pai_id
     AND pessoa_filho_id = p_pessoa_filho_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- desassociar
 --
 --
 PROCEDURE impostos_nfe_configurar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 04/07/2007
  -- DESCRICAO: Configuracao de impostos do fornecedor (nota fiscal de entrada)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_pessoa_id             IN pessoa.pessoa_id%TYPE,
  p_valor_faixa_retencao  IN VARCHAR2,
  p_vetor_tipo_imposto_id IN VARCHAR2,
  p_vetor_aliquota        IN VARCHAR2,
  p_vetor_pessoa_iss_id   IN VARCHAR2,
  p_vetor_aliquota_iss    IN VARCHAR2,
  p_vetor_flag_reter_iss  IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                        INTEGER;
  v_exception                 EXCEPTION;
  v_identif_objeto            historico.identif_objeto%TYPE;
  v_compl_histor              historico.complemento%TYPE;
  v_historico_id              historico.historico_id%TYPE;
  v_vetor_tipo_imposto_id     VARCHAR2(4000);
  v_vetor_aliquota            VARCHAR2(4000);
  v_vetor_pessoa_iss_id       VARCHAR2(4000);
  v_vetor_aliquota_iss        VARCHAR2(4000);
  v_vetor_flag_reter_iss      VARCHAR2(4000);
  v_perc_imposto_char         VARCHAR2(20);
  v_nome_pessoa               pessoa.nome%TYPE;
  v_valor_faixa_retencao      pessoa.valor_faixa_retencao%TYPE;
  v_delimitador               CHAR(1);
  v_flag_reter                fi_tipo_imposto_pessoa.flag_reter%TYPE;
  v_fi_tipo_imposto_id        fi_tipo_imposto_pessoa.fi_tipo_imposto_id%TYPE;
  v_fi_tipo_imposto_pessoa_id fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE;
  v_perc_imposto              fi_tipo_imposto_pessoa.perc_imposto%TYPE;
  v_cod_imposto               fi_tipo_imposto.cod_imposto%TYPE;
  v_xml_antes                 CLOB;
  v_xml_atual                 CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_nome_pessoa
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF moeda_validar(p_valor_faixa_retencao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da base de cumulatividade inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_faixa_retencao := moeda_converter(p_valor_faixa_retencao);
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - impostos NAO ISS
  ------------------------------------------------------------
  v_vetor_tipo_imposto_id := p_vetor_tipo_imposto_id;
  v_vetor_aliquota        := p_vetor_aliquota;
  --
  v_delimitador := '|';
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_imposto_id)), 0) > 0
  LOOP
   v_fi_tipo_imposto_id := to_number(prox_valor_retornar(v_vetor_tipo_imposto_id, v_delimitador));
   v_perc_imposto_char  := prox_valor_retornar(v_vetor_aliquota, v_delimitador);
   --
   SELECT MAX(cod_imposto)
     INTO v_cod_imposto
     FROM fi_tipo_imposto
    WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id;
   --
   IF v_cod_imposto IS NULL OR v_cod_imposto = 'ISS'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de imposto inválido.';
    RAISE v_exception;
   END IF;
   --
   IF taxa_validar(v_perc_imposto_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Percentual de alíquota inválido (' || v_perc_imposto_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_perc_imposto := taxa_converter(v_perc_imposto_char);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_tipo_imposto_pessoa
    WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id
      AND pessoa_id = p_pessoa_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO fi_tipo_imposto_pessoa
     (fi_tipo_imposto_pessoa_id,
      fi_tipo_imposto_id,
      pessoa_id,
      perc_imposto,
      flag_reter,
      nome_servico)
    VALUES
     (seq_fi_tipo_imposto_pessoa.nextval,
      v_fi_tipo_imposto_id,
      p_pessoa_id,
      v_perc_imposto,
      'S',
      NULL);
   ELSE
    UPDATE fi_tipo_imposto_pessoa
       SET perc_imposto = v_perc_imposto
     WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id
       AND pessoa_id = p_pessoa_id;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - impostos ISS
  ------------------------------------------------------------
  v_vetor_pessoa_iss_id  := p_vetor_pessoa_iss_id;
  v_vetor_aliquota_iss   := p_vetor_aliquota_iss;
  v_vetor_flag_reter_iss := p_vetor_flag_reter_iss;
  --
  v_delimitador := '|';
  --
  WHILE nvl(length(rtrim(v_vetor_pessoa_iss_id)), 0) > 0
  LOOP
   v_fi_tipo_imposto_pessoa_id := to_number(prox_valor_retornar(v_vetor_pessoa_iss_id,
                                                                v_delimitador));
   v_perc_imposto_char         := prox_valor_retornar(v_vetor_aliquota_iss, v_delimitador);
   v_flag_reter                := prox_valor_retornar(v_vetor_flag_reter_iss, v_delimitador);
   --
   SELECT MAX(tpo.cod_imposto)
     INTO v_cod_imposto
     FROM fi_tipo_imposto_pessoa tip,
          fi_tipo_imposto        tpo
    WHERE tip.fi_tipo_imposto_pessoa_id = v_fi_tipo_imposto_pessoa_id
      AND tip.fi_tipo_imposto_id = tpo.fi_tipo_imposto_id;
   --
   IF v_cod_imposto IS NULL OR v_cod_imposto <> 'ISS'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de imposto inválido.';
    RAISE v_exception;
   END IF;
   --
   IF taxa_validar(v_perc_imposto_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Percentual de alíquota inválido (' || v_perc_imposto_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_perc_imposto := taxa_converter(v_perc_imposto_char);
   --
   IF flag_validar(v_flag_reter) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag reter inválido (' || v_flag_reter || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_imposto IS NULL
   THEN
    DELETE FROM fi_tipo_imposto_pessoa
     WHERE fi_tipo_imposto_pessoa_id = v_fi_tipo_imposto_pessoa_id;
   ELSE
    UPDATE fi_tipo_imposto_pessoa
       SET perc_imposto = v_perc_imposto,
           flag_reter   = v_flag_reter
     WHERE fi_tipo_imposto_pessoa_id = v_fi_tipo_imposto_pessoa_id;
   END IF;
  END LOOP;
  --
  UPDATE pessoa
     SET valor_faixa_retencao = v_valor_faixa_retencao
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_pessoa;
  v_compl_histor   := 'Alteração da configuração de Impostos';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END impostos_nfe_configurar;
 --
 --
 PROCEDURE iss_nfe_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 04/07/2007
  -- DESCRICAO: Configuracao de impostos do fornecedor (nota fiscal de entrada): inclusao
  --  de novo servico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_nome_servico      IN fi_tipo_imposto_pessoa.nome_servico%TYPE,
  p_perc_imposto      IN VARCHAR2,
  p_flag_reter        IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_nome_pessoa        pessoa.nome%TYPE;
  v_fi_tipo_imposto_id fi_tipo_imposto_pessoa.fi_tipo_imposto_id%TYPE;
  v_perc_imposto       fi_tipo_imposto_pessoa.perc_imposto%TYPE;
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_nome_pessoa
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_nome_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_perc_imposto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do percentual do imposto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto inválido.';
   RAISE v_exception;
  END IF;
  --
  v_perc_imposto := taxa_converter(p_perc_imposto);
  --
  IF flag_validar(p_flag_reter) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag reter inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(fi_tipo_imposto_id)
    INTO v_fi_tipo_imposto_id
    FROM fi_tipo_imposto
   WHERE cod_imposto = 'ISS';
  --
  IF v_fi_tipo_imposto_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Imposto ISS não encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_tipo_imposto_pessoa
   WHERE pessoa_id = p_pessoa_id
     AND fi_tipo_imposto_id = v_fi_tipo_imposto_id
     AND upper(nome_servico) = upper(TRIM(p_nome_servico));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de produto já existe para essa pessoa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO fi_tipo_imposto_pessoa
   (fi_tipo_imposto_pessoa_id,
    pessoa_id,
    fi_tipo_imposto_id,
    perc_imposto,
    flag_reter,
    nome_servico)
  VALUES
   (seq_fi_tipo_imposto_pessoa.nextval,
    p_pessoa_id,
    v_fi_tipo_imposto_id,
    v_perc_imposto,
    p_flag_reter,
    TRIM(p_nome_servico));
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_pessoa;
  v_compl_histor   := 'Inclusão de ISS';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END iss_nfe_adicionar;
 --
 --
 PROCEDURE servico_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 28/01/2021
  -- DESCRICAO: inclusao/Atualizacao de servico na empresa responsavel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_servico.pessoa_id%TYPE,
  p_servico_id        IN pessoa_servico.servico_id%TYPE,
  p_cod_ext_servico   IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_cod_ext_servico)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do produto não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa_servico
   WHERE pessoa_id = p_pessoa_id
     AND servico_id = p_servico_id;
  --
  IF v_qt = 0
  THEN
   INSERT INTO pessoa_servico
    (pessoa_id,
     servico_id,
     cod_ext_servico,
     flag_ativo)
   VALUES
    (p_pessoa_id,
     p_servico_id,
     TRIM(p_cod_ext_servico),
     p_flag_ativo);
  ELSE
   UPDATE pessoa_servico
      SET cod_ext_servico = TRIM(p_cod_ext_servico),
          flag_ativo      = p_flag_ativo
    WHERE pessoa_id = p_pessoa_id
      AND servico_id = p_servico_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Alteração de produto';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END servico_atualizar;
 --
 --
 PROCEDURE servico_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 28/01/2021
  -- DESCRICAO: Exclusao de servico da empresa responsavel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa_servico.pessoa_id%TYPE,
  p_servico_id        IN pessoa_servico.servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa_servico
   WHERE pessoa_id = p_pessoa_id
     AND servico_id = p_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de pessoa x produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM pessoa_servico
   WHERE pessoa_id = p_pessoa_id
     AND servico_id = p_servico_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Alteração de produto';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END servico_excluir;
 --
 PROCEDURE pessoa_link_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 25/06/2025
  -- DESCRICAO: Adiciona um link na qualificação de pessoa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_pessoa_id         IN pessoa_link.pessoa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN pessoa_link.tipo_link%TYPE,
  p_pessoa_link_id    OUT pessoa_link.pessoa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_pessoa_link_id pessoa_link.pessoa_link_id%TYPE;
  v_desc_tipo_link VARCHAR2(100);
  --
 BEGIN
  v_qt             := 0;
  p_pessoa_link_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_url) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do hiperlink é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_url) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O hiperlink não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_link) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de hiperlink é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_tipo_link := util_pkg.desc_retornar('tipo_arq_pessoa', p_tipo_link);
  --
  IF v_desc_tipo_link IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de hiperlink inválido (' || p_tipo_link || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_pessoa_link.nextval
    INTO v_pessoa_link_id
    FROM dual;
  --
  INSERT INTO pessoa_link
   (pessoa_link_id,
    pessoa_id,
    usuario_id,
    data_entrada,
    url,
    descricao,
    tipo_link)
  VALUES
   (v_pessoa_link_id,
    p_pessoa_id,
    p_usuario_sessao_id,
    SYSDATE,
    TRIM(p_url),
    TRIM(p_descricao),
    TRIM(p_tipo_link));
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_pessoa_id;
  v_compl_histor   := 'Inclusão de hiperlink de ' || v_desc_tipo_link || ' (' || p_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_pessoa_link_id := v_pessoa_link_id;
  p_erro_cod       := '00000';
  p_erro_msg       := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END pessoa_link_adicionar;
 --
 PROCEDURE pessoa_link_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 25/06/2025
  -- DESCRICAO: Exclui um link da pesso na qualificação
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_link_id    IN pessoa_link.pessoa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_pessoa_id      pessoa.pessoa_id%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_url            pessoa_link.url%TYPE;
  v_tipo_link      pessoa_link.tipo_link%TYPE;
  v_desc_tipo_link VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(pe.pessoa_id)
    INTO v_pessoa_id
    FROM pessoa      pe,
         pessoa_link ol
   WHERE ol.pessoa_link_id = p_pessoa_link_id
     AND ol.pessoa_id = pe.pessoa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_pessoa_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse hiperlink não existe ou não está associado a essa Pessoa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM pessoa_link
   WHERE pessoa_link_id = p_pessoa_link_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_pessoa_id;
  v_compl_histor   := 'Exclusão de hiperlink de ' || v_desc_tipo_link || ' (' || v_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END pessoa_link_excluir;
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/01/2017
  -- DESCRICAO: Subrotina que gera o xml da PESSOA para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/09/2022  Novos atributos flag_cli_aprov_os e flag_cli_aval_os
  ------------------------------------------------------------------------------------------
 (
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_xml       OUT CLOB,
  p_erro_cod  OUT VARCHAR2,
  p_erro_msg  OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_na IS
   SELECT na.codigo,
          na.nome,
          numero_mostrar(pn.valor_padrao, 6, 'N') valor_padrao,
          na.mod_calculo,
          na.ordem
     FROM pessoa_nitem_pdr pn,
          natureza_item    na
    WHERE na.natureza_item_id = pn.natureza_item_id
      AND pn.pessoa_id = p_pessoa_id
    ORDER BY na.ordem;
  --
  CURSOR c_tp IS
   SELECT ti.nome AS tipo_pessoa
     FROM tipific_pessoa tp,
          tipo_pessoa    ti
    WHERE tp.pessoa_id = p_pessoa_id
      AND tp.tipo_pessoa_id = ti.tipo_pessoa_id
    ORDER BY ti.nome;
  --
  CURSOR c_ps IS
   SELECT ti.nome           AS tipo_pessoa,
          se.nome           AS sistema_externo,
          ps.cod_ext_pessoa
     FROM pessoa_sist_ext ps,
          tipo_pessoa     ti,
          sistema_externo se
    WHERE ps.pessoa_id = p_pessoa_id
      AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
      AND ps.sistema_externo_id = se.sistema_externo_id
    ORDER BY se.nome,
             ti.nome;
  --
  CURSOR c_ip IS
   SELECT ti.cod_imposto,
          taxa_mostrar(tp.perc_imposto) AS perc_imposto
     FROM fi_tipo_imposto        ti,
          fi_tipo_imposto_pessoa tp
    WHERE tp.pessoa_id = p_pessoa_id
      AND tp.fi_tipo_imposto_id = ti.fi_tipo_imposto_id
      AND ti.flag_incide_ent = 'S'
    ORDER BY ti.ordem,
             ti.fi_tipo_imposto_id;
  --
  CURSOR c_re IS
   SELECT pe.apelido
     FROM relacao re,
          pessoa  pe
    WHERE re.pessoa_filho_id = p_pessoa_id
      AND re.pessoa_pai_id = pe.pessoa_id
    ORDER BY pe.apelido;
  --
  CURSOR c_nf IS
   SELECT natureza_oper_fatur_id,
          codigo,
          descricao,
          flag_padrao,
          flag_servico,
          flag_bv,
          ordem
     FROM natureza_oper_fatur
    WHERE pessoa_id = p_pessoa_id
    ORDER BY ordem,
             descricao;
  --
  CURSOR c_pc IS
   SELECT nome,
          cod_ext_produto,
          flag_ativo
     FROM produto_cliente
    WHERE pessoa_id = p_pessoa_id
    ORDER BY nome;
  --
  CURSOR c_se IS
   SELECT se.nome,
          ps.cod_ext_servico,
          ps.flag_ativo
     FROM pessoa_servico ps,
          servico        se
    WHERE ps.pessoa_id = p_pessoa_id
      AND ps.servico_id = se.servico_id
    ORDER BY se.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("pessoa_id", pe.pessoa_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("apelido", pe.apelido),
                   xmlelement("nome", pe.nome),
                   xmlelement("usuario", us.login),
                   xmlelement("notifica_email", us.flag_notifica_email),
                   xmlelement("funcao", pe.funcao),
                   xmlelement("ativo", pe.flag_ativo),
                   xmlelement("publ_priv", pe.tipo_publ_priv),
                   xmlelement("empr_resp_job", pe.flag_emp_resp),
                   xmlelement("empr_fatur", pe.flag_emp_fatur),
                   xmlelement("empr_incentivo", pe.flag_emp_incentivo),
                   xmlelement("empr_scp", pe.flag_emp_scp),
                   -- documentacao
                   xmlelement("pessoa_juridica", pe.flag_pessoa_jur),
                   xmlelement("simples", pe.flag_simples),
                   xmlelement("cpom", pe.flag_cpom),
                   xmlelement("cnpj", pe.cnpj),
                   xmlelement("inscr_estadual", pe.inscr_estadual),
                   xmlelement("inscr_municipal", pe.inscr_municipal),
                   xmlelement("inscr_inss", pe.inscr_inss),
                   xmlelement("cpf", pe.cpf),
                   xmlelement("rg", pe.rg),
                   xmlelement("rg_org_exp", pe.rg_org_exp),
                   xmlelement("rg_uf", pe.rg_uf),
                   -- endereco/contato
                   xmlelement("endereco", pe.endereco),
                   xmlelement("num_ender", pe.num_ender),
                   xmlelement("complemento", pe.compl_ender),
                   xmlelement("zona", pe.zona),
                   xmlelement("bairro", pe.bairro),
                   xmlelement("cep", pe.cep),
                   xmlelement("cidade", pe.cidade),
                   xmlelement("estado", pe.uf),
                   xmlelement("pais", pe.pais),
                   xmlelement("telefone", TRIM(pe.ddd_telefone || ' ' || pe.num_telefone)),
                   xmlelement("ramal", pe.num_ramal),
                   xmlelement("celular", TRIM(pe.ddd_celular || ' ' || pe.num_celular)),
                   xmlelement("website", pe.website),
                   xmlelement("email", pe.email),
                   -- banco
                   xmlelement("banco", ba.nome),
                   xmlelement("num_agencia", pe.num_agencia),
                   xmlelement("num_conta", pe.num_conta),
                   xmlelement("tipo_conta", pe.tipo_conta),
                   xmlelement("titular", pe.nome_titular),
                   xmlelement("cnpj_cpf_titular", pe.cnpj_cpf_titular),
                   -- cliente
                   xmlelement("num_dias_fatur", to_char(pe.num_dias_fatur)),
                   xmlelement("tipo_num_dias_fatur", pe.tipo_num_dias_fatur),
                   xmlelement("item_a_pago_cliente", pe.flag_pago_cliente),
                   xmlelement("prefixo_job", pe.cod_job),
                   xmlelement("num_primeiro_job", to_char(pe.num_primeiro_job)),
                   xmlelement("data_entrada_agencia", data_hora_mostrar(pe.data_entrada_agencia)),
                   xmlelement("empr_resp_job_pdr", pr.apelido),
                   xmlelement("empr_fatur_pdr", pf.apelido),
                   xmlelement("setor", st.nome),
                   -- fornecedor
                   xmlelement("fornec_interno", pe.flag_fornec_interno),
                   -- cadastro
                   xmlelement("cadastro_verificado", pe.flag_cad_verif),
                   xmlelement("info_fiscal_verificado", pe.flag_fis_verif),
                   -- configuracao operacional
                   xmlelement("habilita_aprov_os", pe.flag_cli_aprov_os),
                   xmlelement("habilita_aval_os", pe.flag_cli_aval_os))
    INTO v_xml
    FROM pessoa   pe,
         usuario  us,
         fi_banco ba,
         pessoa   pr,
         pessoa   pf,
         setor    st
   WHERE pe.pessoa_id = p_pessoa_id
     AND pe.usuario_id = us.usuario_id(+)
     AND pe.fi_banco_id = ba.fi_banco_id(+)
     AND pe.emp_resp_pdr_id = pr.pessoa_id(+)
     AND pe.emp_fatur_pdr_id = pf.pessoa_id(+)
     AND pe.setor_id = st.setor_id(+);
  --
  ------------------------------------------------------------
  -- monta TIPO PESSOA
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_tp IN c_tp
  LOOP
   SELECT xmlconcat(xmlelement("tipo", r_tp.tipo_pessoa))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("tipos_pessoa", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta CONTATO DE
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_re IN c_re
  LOOP
   SELECT xmlconcat(xmlelement("nome", r_re.apelido))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("contato_de", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta PRODUTO_CLIENTE
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pc IN c_pc
  LOOP
   SELECT xmlagg(xmlelement("produto_cliente",
                            xmlelement("nome", r_pc.nome),
                            xmlelement("cod_ext_produto", r_pc.cod_ext_produto),
                            xmlelement("ativo", r_pc.flag_ativo)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("produtos_cliente", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta INFORMACOES FINANCEIRAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_na IN c_na
  LOOP
   SELECT xmlagg(xmlelement("info_finan",
                            xmlelement("codigo", r_na.codigo),
                            xmlelement("nome", r_na.nome),
                            xmlelement("tipo", r_na.mod_calculo),
                            xmlelement("valor_padrao", r_na.valor_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("info_financeiras", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta IMPOSTOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ip IN c_ip
  LOOP
   SELECT xmlagg(xmlelement("imposto",
                            xmlelement("cod_imposto", r_ip.cod_imposto),
                            xmlelement("perc_imposto", r_ip.perc_imposto)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("impostos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta CODIGOS EXTERNOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ps IN c_ps
  LOOP
   SELECT xmlagg(xmlelement("cod_ext_pessoa",
                            xmlelement("sistema_externo", r_ps.sistema_externo),
                            xmlelement("tipo_pessoa", r_ps.tipo_pessoa),
                            xmlelement("codigo_externo", r_ps.cod_ext_pessoa)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("codigos_externos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta NATUREZAS P/ FATURAMENTO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_nf IN c_nf
  LOOP
   SELECT xmlagg(xmlelement("natureza_oper_fatur",
                            xmlelement("natureza_oper_fatur_id", r_nf.natureza_oper_fatur_id),
                            xmlelement("codigo", r_nf.codigo),
                            xmlelement("descricao", r_nf.descricao),
                            xmlelement("padrao", r_nf.flag_padrao),
                            xmlelement("servico", r_nf.flag_servico),
                            xmlelement("bv", r_nf.flag_bv),
                            xmlelement("ordem", to_char(r_nf.ordem))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("naturezas_oper_fatur", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta SERVICOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_se IN c_se
  LOOP
   SELECT xmlagg(xmlelement("servico",
                            xmlelement("nome", r_se.nome),
                            xmlelement("cod_ext_servico", r_se.cod_ext_servico),
                            xmlelement("ativo", r_se.flag_ativo)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("servicos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "pessoa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("pessoa", v_xml))
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- acrescenta o tipo de documento e converte para CLOB
  ------------------------------------------------------------
  SELECT v_xml_doc || v_xml.getclobval()
    INTO p_xml
    FROM dual;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END xml_gerar;
 --
 --
 FUNCTION perc_imposto_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 04/07/2007
  -- DESCRICAO: retorna o percentual (aliquota) configurado para um determinado tipo de
  --   imposto e uma determinada pessoa. Essa funcao nao é valida para ISS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id          IN pessoa.pessoa_id%TYPE,
  p_fi_tipo_imposto_id IN fi_tipo_imposto.fi_tipo_imposto_id%TYPE
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT MAX(perc_imposto)
    INTO v_retorno
    FROM fi_tipo_imposto_pessoa tip,
         fi_tipo_imposto        tpo
   WHERE tip.pessoa_id = p_pessoa_id
     AND tip.fi_tipo_imposto_id = p_fi_tipo_imposto_id
     AND tip.fi_tipo_imposto_id = tpo.fi_tipo_imposto_id
     AND tpo.cod_imposto <> 'ISS';
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END perc_imposto_retornar;
 --
 --
 FUNCTION pai_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/02/2005
  -- DESCRICAO: retorna quem e' o pai de determinada pessoa. Quando o tipo de retorno for:
  --     ID - retorna pessoa_id
  --     AP - retorna o apelido
  --     NO - retorna o nome
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id    IN pessoa.pessoa_id%TYPE,
  p_tipo_retorno IN VARCHAR2
 ) RETURN VARCHAR2 AS
  v_retorno       VARCHAR2(100);
  v_qt            INTEGER;
  v_pessoa_pai_id pessoa.pessoa_id%TYPE;
  v_apelido       pessoa.apelido%TYPE;
  v_nome          pessoa.nome%TYPE;
  v_exception     EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_tipo_retorno NOT IN ('ID', 'AP', 'NO')
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT MIN(r.pessoa_pai_id)
    INTO v_pessoa_pai_id
    FROM relacao r
   WHERE r.pessoa_filho_id = p_pessoa_id;
  --
  IF v_pessoa_pai_id IS NOT NULL
  THEN
   SELECT p.apelido,
          p.nome
     INTO v_apelido,
          v_nome
     FROM pessoa p
    WHERE p.pessoa_id = v_pessoa_pai_id;
  END IF;
  --
  IF p_tipo_retorno = 'ID'
  THEN
   v_retorno := v_pessoa_pai_id;
  ELSIF p_tipo_retorno = 'AP'
  THEN
   v_retorno := v_apelido;
  ELSIF p_tipo_retorno = 'NO'
  THEN
   v_retorno := v_nome;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END pai_retornar;
 --
 --
 FUNCTION tipo_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/04/2005
  -- DESCRICAO: verifica se a pessoa e' de determiando tipo. Retorna 1 caso seja e
  --   0 caso não.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id   IN pessoa.pessoa_id%TYPE,
  p_tipo_pessoa IN VARCHAR2
 ) RETURN INTEGER AS
  v_retorno   INTEGER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipific_pessoa tp,
         tipo_pessoa    ti
   WHERE tp.pessoa_id = p_pessoa_id
     AND tp.tipo_pessoa_id = ti.tipo_pessoa_id
     AND ti.codigo = p_tipo_pessoa;
  --
  IF v_qt > 0
  THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END tipo_verificar;
 --
 --
 FUNCTION dados_integr_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/04/2005
  -- DESCRICAO: verifica se a pessoa esta com os dados completos para a integracao com o
  --   sistema financeiro. Retorna 1 caso esteja e 0 caso não.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id IN pessoa.pessoa_id%TYPE
 ) RETURN INTEGER AS
  v_retorno             INTEGER;
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_endereco            pessoa.endereco%TYPE;
  v_cep                 pessoa.cep%TYPE;
  v_cidade              pessoa.cidade%TYPE;
  v_uf                  pessoa.uf%TYPE;
  v_bairro              pessoa.bairro%TYPE;
  v_cpf                 pessoa.cpf%TYPE;
  v_cnpj                pessoa.cnpj%TYPE;
  v_pes_estrang         INTEGER;
  v_pes_fornec          INTEGER;
  v_pes_cliente         INTEGER;
  v_pessoa_pai_id       pessoa.pessoa_id%TYPE;
  v_flag_fornec_interno pessoa.flag_fornec_interno%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT endereco,
         cep,
         cidade,
         uf,
         bairro,
         cpf,
         cnpj,
         pessoa_pkg.tipo_verificar(p_pessoa_id, 'CLIENTE'),
         pessoa_pkg.tipo_verificar(p_pessoa_id, 'FORNECEDOR'),
         pessoa_pkg.tipo_verificar(p_pessoa_id, 'ESTRANGEIRO'),
         flag_fornec_interno
    INTO v_endereco,
         v_cep,
         v_cidade,
         v_uf,
         v_bairro,
         v_cpf,
         v_cnpj,
         v_pes_cliente,
         v_pes_fornec,
         v_pes_estrang,
         v_flag_fornec_interno
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  SELECT MAX(pessoa_pai_id)
    INTO v_pessoa_pai_id
    FROM relacao
   WHERE pessoa_filho_id = p_pessoa_id;
  --
  IF TRIM(v_endereco) IS NOT NULL AND TRIM(v_cep) IS NOT NULL AND TRIM(v_cidade) IS NOT NULL AND
     TRIM(v_uf) IS NOT NULL AND TRIM(v_bairro) IS NOT NULL AND (v_pes_fornec + v_pes_cliente) > 0 AND
     nvl(v_pessoa_pai_id, 0) = 0 AND
     (v_cpf IS NOT NULL OR v_cnpj IS NOT NULL OR v_pes_estrang > 0 OR v_flag_fornec_interno = 'S')
  THEN
   --
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END dados_integr_verificar;
 --
 --
 FUNCTION saldo_do_dia_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 01/04/2008
  -- DESCRICAO: Retorna o valor do saldo do dia da conta da pessoa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id IN pessoa.pessoa_id%TYPE,
  p_data      IN DATE
 )
 --
  RETURN NUMBER AS
  v_ret       NUMBER;
  v_data      DATE;
  v_exception EXCEPTION;
  --
 BEGIN
  v_ret := 0;
  --
  IF p_data IS NULL
  THEN
   v_data := trunc(SYSDATE);
  ELSE
   v_data := trunc(p_data);
  END IF;
  --
  SELECT nvl(SUM(decode(la.tipo_mov, 'E', la.valor_lancam, 'S', -la.valor_lancam)), 0)
    INTO v_ret
    FROM lancamento la
   WHERE la.pessoa_id = p_pessoa_id
     AND la.data_lancam < v_data + 1;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_exception THEN
   v_ret := 999999999;
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 999999999;
   RETURN v_ret;
 END saldo_do_dia_retornar;
 --
 --
 FUNCTION cnpj_raiz_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/09/2011
  -- DESCRICAO: retorna a raiz do CNPJ de uma determinada pessoa, desde que nao se trate
  --   de SCP (sociedade por conta de participacao). Funcao usada no calculo de impostos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro empresa_id
  ------------------------------------------------------------------------------------------
  p_pessoa_id  IN pessoa.pessoa_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno      VARCHAR2(100);
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_flag_emp_scp pessoa.flag_emp_scp%TYPE;
  v_cod_pais     pais.codigo%TYPE;
  --
 BEGIN
  --
  SELECT MAX(pa.codigo)
    INTO v_cod_pais
    FROM empresa em,
         pais    pa
   WHERE em.empresa_id = p_empresa_id
     AND em.pais_id = pa.pais_id;
  --
  SELECT cnpj_pkg.converter(cnpj, p_empresa_id),
         flag_emp_scp
    INTO v_retorno,
         v_flag_emp_scp
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_cod_pais = 'BRA' AND v_flag_emp_scp = 'N'
  THEN
   v_retorno := substr(v_retorno, 1, 8);
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END cnpj_raiz_retornar;
 --
 --
 FUNCTION cod_sist_ext_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/09/2011
  -- DESCRICAO: retorna o código da pessoa no sistema externo. Se o cod_sist_ext nao for
  --   informado, utiliza o sistema externo ativo do tipo FIN (Financeiro).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id       IN pessoa.pessoa_id%TYPE,
  p_cod_tipo_pessoa IN tipo_pessoa.codigo%TYPE,
  p_cod_sist_ext    IN sistema_externo.codigo%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno tipo_pessoa.codigo%TYPE;
  v_qt      INTEGER;
  --
 BEGIN
  --
  IF TRIM(p_cod_sist_ext) IS NULL
  THEN
   SELECT MAX(ps.cod_ext_pessoa)
     INTO v_retorno
     FROM pessoa_sist_ext ps,
          tipo_pessoa     ti,
          sistema_externo si
    WHERE ps.pessoa_id = p_pessoa_id
      AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
      AND ti.codigo = p_cod_tipo_pessoa
      AND ps.sistema_externo_id = si.sistema_externo_id
      AND si.flag_ativo = 'S'
      AND si.tipo_sistema = 'FIN';
  ELSE
   SELECT MAX(ps.cod_ext_pessoa)
     INTO v_retorno
     FROM pessoa_sist_ext ps,
          tipo_pessoa     ti,
          sistema_externo se
    WHERE ps.pessoa_id = p_pessoa_id
      AND ps.tipo_pessoa_id = ti.tipo_pessoa_id
      AND ti.codigo = p_cod_tipo_pessoa
      AND ps.sistema_externo_id = se.sistema_externo_id
      AND se.codigo = p_cod_sist_ext;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END cod_sist_ext_retornar;
 --
 --
 FUNCTION nivel_excelencia_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 06/07/2015
  -- DESCRICAO: Retorna o nivel de excelencia do fornecedor calculado com base nas
  --   avaliacoes dos usuarios.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id IN pessoa.pessoa_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_ret       NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_ret := 0;
  --
  SELECT round(nvl(AVG(nota), 0), 1)
    INTO v_ret
    FROM aval_fornec
   WHERE pessoa_id = p_pessoa_id
     AND tipo_aval = 'EXC';
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_exception THEN
   v_ret := 999;
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 999;
   RETURN v_ret;
 END nivel_excelencia_retornar;
 --
 --
 FUNCTION nivel_parceria_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 06/07/2015
  -- DESCRICAO: Retorna o nivel de pareria do fornecedor calculado com base nas
  --   avaliacoes dos usuarios.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_pessoa_id IN pessoa.pessoa_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_ret       NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_ret := 0;
  --
  SELECT round(nvl(AVG(nota), 0), 1)
    INTO v_ret
    FROM aval_fornec
   WHERE pessoa_id = p_pessoa_id
     AND tipo_aval = 'PAR';
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_exception THEN
   v_ret := 999;
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 999;
   RETURN v_ret;
 END nivel_parceria_retornar;
 --
 --
 FUNCTION unid_negocio_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia       ProcessMind     DATA: 09/07/2020
  -- DESCRICAO: Retorna a unidade de negocio do cliente. Se o job_id/usuaro_id forem
  --   passados, a preferencia eh pela unidade de negocio que bata com um deles.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/07/2020  Novo parametro job_id
  ------------------------------------------------------------------------------------------
  p_cliente_id IN pessoa.pessoa_id%TYPE,
  p_job_id     IN job.job_id%TYPE,
  p_usuario_id IN usuario.usuario_id%TYPE
 )
 --
  RETURN NUMBER AS
  v_unidade_negocio_id unidade_negocio.unidade_negocio_id%TYPE;
  v_exception          EXCEPTION;
  --
 BEGIN
  v_unidade_negocio_id := NULL;
  --
  IF nvl(p_job_id, 0) > 0
  THEN
   SELECT MAX(uc.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_cli uc,
          job                 jo
    WHERE jo.job_id = p_job_id
      AND jo.unidade_negocio_id = uc.unidade_negocio_id
      AND uc.cliente_id = p_cliente_id;
  END IF;
  --
  IF v_unidade_negocio_id IS NULL AND nvl(p_usuario_id, 0) > 0
  THEN
   SELECT MAX(uc.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_usu us,
          unidade_negocio_cli uc
    WHERE us.usuario_id = p_usuario_id
      AND us.unidade_negocio_id = uc.unidade_negocio_id
      AND uc.cliente_id = p_cliente_id;
  END IF;
  --
  IF v_unidade_negocio_id IS NULL
  THEN
   SELECT MAX(uc.unidade_negocio_id)
     INTO v_unidade_negocio_id
     FROM unidade_negocio_cli uc
    WHERE uc.cliente_id = p_cliente_id;
  END IF;
  --
  RETURN v_unidade_negocio_id;
 EXCEPTION
  WHEN v_exception THEN
   v_unidade_negocio_id := NULL;
   RETURN v_unidade_negocio_id;
  WHEN OTHERS THEN
   v_unidade_negocio_id := NULL;
   RETURN v_unidade_negocio_id;
 END unid_negocio_retornar;
 --
 --
 FUNCTION chave_pix_validar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza       ProcessMind     DATA: 25/10/2024
  -- DESCRICAO: Valida se uma chave PIX é válida.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
  p_chave_pix IN VARCHAR2
 ) RETURN INTEGER AS
  v_retorno INTEGER := 0;
 BEGIN
  -- Verifica se a chave PIX atende ao formato esperado
  IF regexp_like(p_chave_pix, '^\d{11}$') OR
     regexp_like(p_chave_pix, '^\d{3}\.\d{3}\.\d{3}-\d{2}$')
  THEN
   -- CPF (com ou sem máscara)
   v_retorno := 1;
  ELSIF regexp_like(p_chave_pix, '^\d{14}$') OR
        regexp_like(p_chave_pix, '^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$')
  THEN
   -- CNPJ (com ou sem máscara)
   v_retorno := 1;
  ELSIF regexp_like(p_chave_pix, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
  THEN
   -- E-mail
   v_retorno := 1;
  ELSIF regexp_like(p_chave_pix, '^\d{10,11}$') OR
        regexp_like(p_chave_pix, '^\(\d{2}\) \d{4,5}-\d{4}$')
  THEN
   -- Telefone (com ou sem máscara)
   v_retorno := 1;
  ELSIF regexp_like(p_chave_pix, '^[A-Fa-f0-9]{32}$') OR
        regexp_like(p_chave_pix,
                    '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$')
  THEN
   -- Chave aleatória no formato UUID
   v_retorno := 1;
  END IF;
 
  RETURN v_retorno;
 
 EXCEPTION
  WHEN OTHERS THEN
   RETURN 0; -- Retorna 0 em caso de erro
 END chave_pix_validar;
 --
 --
 PROCEDURE cadastro_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: José Mario                 ProcessMind     DATA: 09/06/2022
  -- DESCRICAO: Atualização das colunas usu_cad_verif_id, flag_cad_verif, coment_cad_verif,
  --            data_cad_verif para verificação de cadastro.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- José Mario        28/10/2022  Inclusão da atualização na tabela CONTRATO_ELAB
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_cad_verif    IN pessoa.flag_cad_verif%TYPE,
  p_coment_cad_verifi IN pessoa.coment_cad_verif%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_data_exec      DATE;
  v_status         contrato_elab.status%TYPE;
  --
 BEGIN
  v_qt        := 0;
  v_data_exec := SYSDATE;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_VER_CAD_A', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF flag_validar(p_flag_cad_verif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de cadastro verificado inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_cad_verif = 'S'
  THEN
   v_status := 'PRON';
  ELSE
   v_status := 'PRON';
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE pessoa p
     SET p.usu_cad_verif_id = p_usuario_sessao_id,
         p.flag_cad_verif   = p_flag_cad_verif,
         p.coment_cad_verif = p_coment_cad_verifi,
         p.data_cad_verif   = v_data_exec
   WHERE pessoa_id = p_pessoa_id;
  --
  UPDATE contrato_elab ce
     SET status        = v_status,
         data_execucao = v_data_exec,
         usuario_id    = p_usuario_sessao_id
   WHERE cod_contrato_elab = 'CLIE'
     AND EXISTS (SELECT 1
            FROM contrato ct
           WHERE ct.contratante_id = p_pessoa_id
             AND ct.contrato_id = ce.contrato_id);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Verificação de informações cadastrais';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END cadastro_atualizar;
 --
 --
 PROCEDURE info_fiscal_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: José Mario                 ProcessMind     DATA: 09/06/2022
  -- DESCRICAO: Atualização das colunas usu_fis_verif_id, flag_fis_verif, coment_fis_verif,
  --            data_fis_verif para verificação das informações fiscais do cadastro de pessoa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- José Mario        28/10/2022  Inclusão da atualização na tabela CONTRATO_ELAB
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_fis_verif    IN pessoa.flag_fis_verif%TYPE,
  p_status_fis_verif  IN pessoa.status_fis_verif%TYPE,
  p_coment_fis_verif  IN pessoa.coment_fis_verif%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_nome                   pessoa.nome%TYPE;
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  v_data_exec              DATE;
  v_status_fis_verif       pessoa.status_fis_verif%TYPE;
  v_status_fis_verif_atual pessoa.status_fis_verif%TYPE;
  v_status_ctr_elab        contrato_elab.status%TYPE;
  --
 BEGIN
  v_qt        := 0;
  v_data_exec := SYSDATE;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         status_fis_verif
    INTO v_nome,
         v_status_fis_verif_atual
    FROM pessoa p
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_VER_FISCAL_A',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF flag_validar(p_flag_fis_verif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de verificação fiscal inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_fis_verif = 'S'
  THEN
   IF rtrim(p_status_fis_verif) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do status OK/NÃO OK é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF util_pkg.desc_retornar('status_fis_verif', p_status_fis_verif) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código do status inválido (' || p_status_fis_verif || ').';
    RAISE v_exception;
   END IF;
   --
   v_status_fis_verif := p_status_fis_verif;
   v_status_ctr_elab  := 'PRON';
  ELSE
   v_status_fis_verif := v_status_fis_verif_atual;
   v_status_ctr_elab  := 'PEND';
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE pessoa
     SET usu_fis_verif_id = p_usuario_sessao_id,
         flag_fis_verif   = p_flag_fis_verif,
         coment_fis_verif = p_coment_fis_verif,
         data_fis_verif   = v_data_exec,
         status_fis_verif = v_status_fis_verif
   WHERE pessoa_id = p_pessoa_id;
  --
  UPDATE contrato_elab ce
     SET status        = v_status_ctr_elab,
         data_execucao = v_data_exec,
         usuario_id    = p_usuario_sessao_id
   WHERE cod_contrato_elab = 'FISC'
     AND EXISTS (SELECT 1
            FROM contrato ct
           WHERE ct.contratante_id = p_pessoa_id
             AND ct.contrato_id = ce.contrato_id);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(p_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Verificação de informações fiscais cadastrais';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END info_fiscal_atualizar;
 --
 --
 PROCEDURE config_oper_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 06/09/2022
  -- DESCRICAO: atualiza flags que habilitam ou nao o uso da interface de cliente
  --   para aprovacoes/avaliacoes de OS (configuracoes operacionais)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_flag_cli_aprov_os IN VARCHAR2,
  p_flag_cli_aval_os  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa p
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF flag_validar(p_flag_cli_aprov_os) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_cli_aval_os) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar avaliação inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET flag_cli_aprov_os = p_flag_cli_aprov_os,
         flag_cli_aval_os  = p_flag_cli_aval_os
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Configuraçao operacional: habilitar aprovação (' || p_flag_cli_aprov_os ||
                      '); habilitar avaliação (' || p_flag_cli_aval_os || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END config_oper_atualizar;
 --
 --
 PROCEDURE email_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 06/09/2022
  -- DESCRICAO: atualiza email da pessoa ou contato
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_pessoa_id         IN pessoa.pessoa_id%TYPE,
  p_email             IN pessoa.email%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_pessoa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa pessoa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM pessoa p
   WHERE pessoa_id = p_pessoa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PESSOA_C', p_pessoa_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_email) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Email é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_email) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE pessoa
     SET email = TRIM(p_email)
   WHERE pessoa_id = p_pessoa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Alteração do email: ' || TRIM(p_email);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_pessoa_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END email_atualizar;
 --
--
END; -- PESSOA_PKG

/
