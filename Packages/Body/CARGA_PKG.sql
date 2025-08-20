--------------------------------------------------------
--  DDL for Package Body CARGA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CARGA_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE pessoa_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel            ProcessMind     DATA: 18/07/2007
  -- DESCRICAO: p_vetor_job_pdv: vetor de numeros de jobs para associação de PDVs
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/05/2010  Implementacao de multiagencia (empresa_id).
  -- Silvia            11/07/2011  Uso de webservice p/ integracao (sistema_externo_id)
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            05/12/2016  Novo campo produto_cliente.
  -- Silvia            23/09/2019  Retirada do grupo_id da pessoa.
  ------------------------------------------------------------------------------------------
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_vetor_job_pdv           IN VARCHAR2,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  --
  v_qt                       INTEGER;
  v_ok                       INTEGER;
  v_exception                EXCEPTION;
  v_usuario_administrador_id usuario.usuario_id%TYPE;
  v_tipo_pessoa_cli_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_for_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_est_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_opm_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_ope_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_opf_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa_int_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_pessoa_id                pessoa.pessoa_id%TYPE;
  v_cnpj_cpf_titular         pessoa.cnpj_cpf_titular%TYPE;
  v_num_dias_fatur           pessoa.num_dias_fatur%TYPE;
  v_tipo_num_dias_fatur      pessoa.tipo_num_dias_fatur%TYPE;
  v_flag_pessoa_jur          pessoa.flag_pessoa_jur%TYPE;
  v_pais                     pessoa.pais%TYPE;
  v_flag_sem_docum           pessoa.flag_sem_docum%TYPE;
  v_flag_ativo               pessoa.flag_ativo%TYPE;
  v_grupo_id                 grupo.grupo_id%TYPE;
  v_banco_id                 fi_banco.fi_banco_id%TYPE;
  v_motivo                   pessoa_transferencia.motivo%TYPE;
  v_delimitador              CHAR(1);
  v_vetor_job_pdv            VARCHAR2(500);
  v_job_id                   job.job_id%TYPE;
  v_job_numero               job.numero%TYPE;
  v_num_ender                VARCHAR2(100);
  v_cnpj                     VARCHAR2(100);
  v_cpf                      VARCHAR2(100);
  v_contato_cnpj_cpf         VARCHAR2(100);
  v_cep                      VARCHAR2(100);
  v_sistema_externo1_id      sistema_externo.sistema_externo_id%TYPE;
  v_sistema_externo2_id      sistema_externo.sistema_externo_id%TYPE;
  v_sistema_externo3_id      sistema_externo.sistema_externo_id%TYPE;
  v_pessoa_pai_id            relacao.pessoa_pai_id%TYPE;
  v_produto_cliente          VARCHAR2(500);
  v_vetor_produto_cliente    LONG;
  --
  CURSOR c_pessoa IS
   SELECT TRIM(p.cod_ext_pessoa1) AS cod_ext_pessoa1,
          TRIM(p.cod_ext_pessoa2) AS cod_ext_pessoa2,
          TRIM(p.cod_ext_pessoa3) AS cod_ext_pessoa3,
          TRIM(p.pessoa_id_update) AS pessoa_id_update,
          TRIM(p.grupo_nome) AS grupo_nome,
          TRIM(p.praca_nome) AS praca_nome,
          TRIM(upper(p.praca_uf)) AS praca_uf,
          TRIM(p.apelido) AS apelido,
          TRIM(p.nome) AS nome,
          TRIM(upper(p.flag_cliente)) AS flag_cliente,
          TRIM(p.perc_honor) AS perc_honor,
          TRIM(p.perc_encargo) AS perc_encargo,
          TRIM(p.perc_encargo_honor) AS perc_encargo_honor,
          TRIM(p.num_dias_fatur) AS num_dias_fatur,
          TRIM(upper(p.tipo_num_dias_fatur)) AS tipo_num_dias_fatur,
          TRIM(upper(p.flag_fornecedor)) AS flag_fornecedor,
          TRIM(p.perc_bv) AS perc_bv,
          TRIM(p.perc_imposto) AS perc_imposto,
          TRIM(p.desc_servicos) AS desc_servicos,
          TRIM(upper(p.flag_pessoa_jur)) AS flag_pessoa_jur,
          TRIM(p.cnpj) AS cnpj,
          TRIM(p.inscr_estadual) AS inscr_estadual,
          TRIM(p.inscr_municipal) AS inscr_municipal,
          TRIM(p.inscr_inss) AS inscr_inss,
          TRIM(p.cpf) AS cpf,
          TRIM(p.rg) AS rg,
          TRIM(p.rg_org_exp) AS rg_org_exp,
          TRIM(upper(p.rg_uf)) AS rg_uf,
          TRIM(p.rg_data_exp) AS rg_data_exp,
          TRIM(upper(p.flag_sem_docum)) AS flag_sem_docum,
          TRIM(upper(p.sexo)) AS sexo,
          TRIM(p.data_nasc) AS data_nasc,
          TRIM(upper(p.estado_civil)) AS estado_civil,
          TRIM(p.funcao) AS funcao,
          TRIM(p.contato_cnpj_cpf) AS contato_cnpj_cpf,
          TRIM(p.endereco) AS endereco,
          TRIM(p.num_ender) AS num_ender,
          TRIM(p.compl_ender) AS compl_ender,
          TRIM(p.zona) AS zona,
          TRIM(p.bairro) AS bairro,
          TRIM(p.cep) AS cep,
          TRIM(p.cidade) AS cidade,
          TRIM(upper(p.uf)) AS uf,
          TRIM(p.pais) AS pais,
          TRIM(p.ddd_telefone) AS ddd_telefone,
          TRIM(p.num_telefone) AS num_telefone,
          TRIM(p.ddd_fax) AS ddd_fax,
          TRIM(p.num_fax) AS num_fax,
          TRIM(p.ddd_celular) AS ddd_celular,
          TRIM(p.num_celular) AS num_celular,
          TRIM(p.website) AS website,
          TRIM(p.email) AS email,
          TRIM(p.nome_banco) AS nome_banco,
          TRIM(p.num_banco) AS num_banco,
          TRIM(p.num_agencia) AS num_agencia,
          TRIM(p.num_conta) AS num_conta,
          TRIM(p.nome_titular) AS nome_titular,
          TRIM(p.cnpjcpf_titular) AS cnpjcpf_titular,
          TRIM(upper(p.tipo_conta)) AS tipo_conta,
          TRIM(p.obs) AS obs,
          TRIM(p.tipo_pdv_valor_nome) AS tipo_pdv_valor_nome,
          TRIM(p.status) AS status,
          TRIM(p.produto_cliente) AS produto_cliente,
          TRIM(upper(p.flag_fornec_homolog)) AS flag_fornec_homolog,
          ROWID
     FROM pessoa_transferencia p
    WHERE (status IS NULL OR status = 'ERRO')
      AND empresa_id = p_empresa_id
    ORDER BY nvl(TRIM(p.contato_cnpj_cpf), '999999999999999999'),
             ROWID;
  --
 BEGIN
  ------------------------------------------------------------
  -- inicialização de variáveis
  ------------------------------------------------------------
  v_qt                   := 0;
  v_delimitador          := ',';
  v_flag_ativo           := 'S';
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  IF flag_validar(p_flag_excluir_carregados) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag excluir carregados inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_administrador_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_administrador_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Impossível realizar a carga sem um usuário administrador definido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_cli_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  IF v_tipo_pessoa_cli_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa CLIENTE.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_for_id
    FROM tipo_pessoa
   WHERE codigo = 'FORNECEDOR';
  --
  IF v_tipo_pessoa_for_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa FORNECEDOR.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_est_id
    FROM tipo_pessoa
   WHERE codigo = 'ESTRANGEIRO';
  --
  IF v_tipo_pessoa_est_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa ESTRANGEIRO.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_opm_id
    FROM tipo_pessoa
   WHERE codigo = 'ORG_PUB_MUN';
  --
  IF v_tipo_pessoa_opm_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa ORG_PUB_MUN.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_ope_id
    FROM tipo_pessoa
   WHERE codigo = 'ORG_PUB_EST';
  --
  IF v_tipo_pessoa_ope_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa ORG_PUB_EST.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_opf_id
    FROM tipo_pessoa
   WHERE codigo = 'ORG_PUB_FED';
  --
  IF v_tipo_pessoa_opf_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa ORG_PUB_FED.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_int_id
    FROM tipo_pessoa
   WHERE codigo = 'INTERNO';
  --
  IF v_tipo_pessoa_opf_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa INTERNO.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa não foi informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa informada não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- LOOP por pessoa a ser carregada
  ------------------------------------------------------------
  FOR r_pessoa IN c_pessoa
  LOOP
   v_ok                  := 0;
   v_motivo              := '';
   v_pessoa_id           := 0;
   v_cnpj                := NULL;
   v_cpf                 := NULL;
   v_grupo_id            := NULL;
   v_banco_id            := NULL;
   v_cnpj_cpf_titular    := NULL;
   v_num_dias_fatur      := NULL;
   v_tipo_num_dias_fatur := 'C';
   v_sistema_externo1_id := NULL;
   v_sistema_externo2_id := NULL;
   v_sistema_externo3_id := NULL;
   v_contato_cnpj_cpf    := NULL;
   v_pessoa_pai_id       := NULL;
   -- retira o ponto de milhar do numero e do cep
   v_num_ender := REPLACE(r_pessoa.num_ender, '.', '');
   v_cep       := REPLACE(r_pessoa.cep, '.', '');
   --
   IF length(r_pessoa.cod_ext_pessoa1) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O código externo 1 da pessoa excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.cod_ext_pessoa2) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O código externo 2 da pessoa excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.cod_ext_pessoa3) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O código externo 3 da pessoa excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.grupo_nome) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome do grupo excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.praca_nome) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome da praça excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.praca_uf) > 2
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A UF da praça excedeu o tamanho de 2 posições. ';
   END IF;
  
   IF length(r_pessoa.apelido) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O apelido excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.nome) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.flag_pessoa_jur) > 1
   THEN
    v_ok     := 9;
    v_motivo := v_motivo ||
                'A indicação de pessoa física/jurídica excedeu o tamanho de 1 posição. ';
   END IF;
  
   IF length(r_pessoa.cnpj) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O CNPJ excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.inscr_estadual) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A inscrição estadual excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.inscr_municipal) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A inscrição municipal excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.inscr_inss) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A inscrição no INSS excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.cpf) > 14
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O CPF excedeu o tamanho de 14 posições. ';
   END IF;
  
   IF length(r_pessoa.rg) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O RG excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.rg_org_exp) > 6
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O órgão expedidor do RG excedeu o tamanho de 6 posições. ';
   END IF;
  
   IF length(r_pessoa.rg_uf) > 2
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O estado de expedição do RG excedeu o tamanho de 2 posições. ';
   END IF;
  
   IF length(r_pessoa.flag_sem_docum) > 1
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A indicação de sem documento excedeu o tamanho de 1 posições. ';
   END IF;
  
   IF length(r_pessoa.sexo) > 1
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O sexo excedeu o tamanho de 1 posição. ';
   END IF;
  
   IF length(r_pessoa.data_nasc) > 10
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A data de nascimento excedeu o tamanho de 10 posições. ';
   END IF;
  
   IF length(r_pessoa.rg_data_exp) > 10
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A data de expedição do RG excedeu o tamanho de 10 posições. ';
   END IF;
  
   IF length(r_pessoa.estado_civil) > 2
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O estado civil excedeu o tamanho de 2 posições. ';
   END IF;
  
   IF length(r_pessoa.funcao) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A função excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(r_pessoa.endereco) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O endereço excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(v_num_ender) > 6
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número do endereço excedeu o tamanho de 6 posições. ';
   END IF;
  
   IF length(r_pessoa.compl_ender) > 30
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O complemento do endereço excedeu o tamanho de 30 posições. ';
   END IF;
  
   IF length(r_pessoa.zona) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A zona excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(r_pessoa.bairro) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O bairro excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(v_cep) > 9
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O CEP excedeu o tamanho de 9 posições. ';
   END IF;
  
   IF length(r_pessoa.cidade) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A cidade excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(r_pessoa.uf) > 2
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A UF excedeu o tamanho de 2 posições. ';
   END IF;
  
   IF length(r_pessoa.pais) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O país excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.ddd_telefone) > 3
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O ddd do telefone excedeu o tamanho de 3 posições. ';
   END IF;
  
   IF length(r_pessoa.num_telefone) > 80
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número do telefone excedeu o tamanho de 80 posições. ';
   END IF;
  
   IF length(r_pessoa.ddd_fax) > 3
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O ddd do fax excedeu o tamanho de 3 posições. ';
   END IF;
  
   IF length(r_pessoa.num_fax) > 80
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número do fax excedeu o tamanho de 80 posições. ';
   END IF;
  
   IF length(r_pessoa.ddd_celular) > 3
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O ddd do celular excedeu o tamanho de 3 posições. ';
   END IF;
  
   IF length(r_pessoa.num_celular) > 80
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número do celular excedeu o tamanho de 80 posições. ';
   END IF;
  
   IF length(r_pessoa.website) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O website excedeu o tamanho de 100 posições. ';
   END IF;
  
   IF length(r_pessoa.email) > 50
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O E-mail excedeu o tamanho de 50 posições. ';
   END IF;
  
   IF length(r_pessoa.nome_banco) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome do banco excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(r_pessoa.num_banco) > 10
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número do banco excedeu o tamanho de 10 posições. ';
   END IF;
  
   IF length(r_pessoa.num_agencia) > 10
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número da ' || v_lbl_agencia_singular ||
                ' excedeu o tamanho de 10 posições. ';
   END IF;
  
   IF length(r_pessoa.num_conta) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O número da conta excedeu o tamanho de 20 posições. ';
   END IF;
  
   IF length(r_pessoa.nome_titular) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome do titular excedeu o tamanho de 60 posições. ';
   END IF;
  
   IF length(r_pessoa.tipo_conta) > 1
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O tipo da conta do banco excedeu o tamanho de 1 posições. ';
   END IF;
  
   IF length(r_pessoa.obs) > 500
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A observação excedeu o tamanho de 500 posições. ';
   END IF;
  
   IF length(r_pessoa.desc_servicos) > 4000
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A descrição dos serviços excedeu o tamanho de 4000 posições. ';
   END IF;
  
   IF length(r_pessoa.tipo_pdv_valor_nome) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O tipo de PDV excedeu o tamanho de 60 posições. ';
   END IF;
   --
   --
   IF r_pessoa.cod_ext_pessoa1 IS NOT NULL
   THEN
    SELECT MAX(sistema_externo_id)
      INTO v_sistema_externo1_id
      FROM sistema_externo
     WHERE flag_ativo = 'S'
       AND tipo_sistema = 'FIN';
    --
    IF nvl(v_sistema_externo1_id, 0) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Sistema externo Financeiro não encontrado. ';
    END IF;
   
   END IF;
   --
   IF r_pessoa.cod_ext_pessoa2 IS NOT NULL
   THEN
    SELECT MAX(sistema_externo_id)
      INTO v_sistema_externo2_id
      FROM sistema_externo
     WHERE flag_ativo = 'S'
       AND tipo_sistema = 'RH';
    --
    IF nvl(v_sistema_externo2_id, 0) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Sistema externo RH não encontrado. ';
    END IF;
   
   END IF;
   --
   IF r_pessoa.cod_ext_pessoa3 IS NOT NULL
   THEN
    SELECT MAX(sistema_externo_id)
      INTO v_sistema_externo3_id
      FROM sistema_externo
     WHERE flag_ativo = 'S'
       AND tipo_sistema = 'CRM';
    --
    IF nvl(v_sistema_externo3_id, 0) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Sistema externo CRM não encontrado. ';
    END IF;
   
   END IF;
   --
   v_pessoa_id := 0;
   --
   IF inteiro_validar(r_pessoa.pessoa_id_update) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Campo pessoa_id_update não inteiro. ';
   ELSE
    v_pessoa_id := nvl(to_number(r_pessoa.pessoa_id_update), 0);
   END IF;
   --
   IF TRIM(r_pessoa.apelido) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O apelido está nulo. ';
   END IF;
   --
   IF TRIM(r_pessoa.nome) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome está nulo. ';
   END IF;
   --
   IF data_validar(r_pessoa.data_nasc) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A data de nascimento inválida. ';
   END IF;
   --
   IF data_validar(r_pessoa.rg_data_exp) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A data de expedição do RG inválida. ';
   END IF;
   --
   IF TRIM(r_pessoa.rg_uf) IS NOT NULL
   THEN
    IF util_pkg.desc_retornar('estado', TRIM(r_pessoa.rg_uf)) IS NULL
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Sigla do estado do RG inválida. ';
    END IF;
   END IF;
   --
   IF TRIM(r_pessoa.num_banco) IS NOT NULL
   THEN
    SELECT MAX(fi_banco_id)
      INTO v_banco_id
      FROM fi_banco
     WHERE acento_retirar(r_pessoa.num_banco) = acento_retirar(codigo)
       AND empresa_id = p_empresa_id;
   
    IF v_banco_id IS NULL
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'O número do banco não foi encontrado na tabela de bancos. ';
    END IF;
   
   END IF;
   --
   /*
   IF v_num_ender IS NOT NULL AND INTEIRO_VALIDAR(v_num_ender) = 0 THEN
     v_ok := 9;
     v_motivo := v_motivo || 'Número do endereço inválido. ';
   END IF; */
   --
   v_pais := r_pessoa.pais;
   --
   IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL')
   THEN
    v_pais := 'BRASIL';
   END IF;
   --
   IF v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')
   THEN
    -- so consiste uf p/ o Brasil
    IF TRIM(r_pessoa.uf) IS NOT NULL
    THEN
     IF util_pkg.desc_retornar('estado', TRIM(r_pessoa.uf)) IS NULL
     THEN
      v_ok     := 9;
      v_motivo := v_motivo || 'Sigla do estado inválida. ';
     END IF;
    END IF;
    -- so consiste o municipio p/ o Brasil
    IF r_pessoa.cidade IS NOT NULL
    THEN
     IF cep_pkg.municipio_validar(r_pessoa.uf, r_pessoa.cidade) = 0
     THEN
      v_ok     := 9;
      v_motivo := v_motivo || 'A cidade/UF informados não constam na tabela de municípios. ';
     END IF;
    
    END IF;
   
   END IF;
   --
   IF TRIM(r_pessoa.cep) IS NOT NULL AND
      (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR'))
   THEN
    IF cep_pkg.validar(v_cep) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'CEP inválido. ';
    END IF;
   END IF;
   --
   IF TRIM(r_pessoa.sexo) IS NOT NULL AND r_pessoa.sexo NOT IN ('F', 'M')
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Sexo inválido. ';
   END IF;
   --
   IF TRIM(r_pessoa.estado_civil) IS NOT NULL
   THEN
    IF util_pkg.desc_retornar('estado_civil', r_pessoa.estado_civil) IS NULL
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Estado civil inválido. ';
    END IF;
   END IF;
   --
   IF email_validar(r_pessoa.email) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Email inválido. ';
   END IF;
   --
   IF flag_validar(r_pessoa.flag_cliente) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Flag cliente inválido. ';
   END IF;
   --
   IF flag_validar(r_pessoa.flag_fornecedor) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Flag fornecedor inválido. ';
   END IF;
   --
   IF flag_validar(r_pessoa.flag_fornec_homolog) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Flag fornecedor homologado inválido. ';
   END IF;
   --
   IF cnpj_pkg.validar(r_pessoa.cnpj, p_empresa_id) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'CNPJ inválido. ';
   ELSE
    -- retira formatacao
    v_cnpj := cnpj_pkg.converter(r_pessoa.cnpj, p_empresa_id);
    --
    IF v_cnpj IN ('00000000000000',
                  '11111111111111',
                  '22222222222222',
                  '33333333333333',
                  '44444444444444',
                  '55555555555555',
                  '66666666666666',
                  '77777777777777',
                  '88888888888888',
                  '99999999999999')
    THEN
     v_cnpj := NULL;
    END IF;
    --
    IF v_cnpj IS NOT NULL
    THEN
     IF v_pessoa_id > 0
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa
       WHERE cnpj = v_cnpj
         AND empresa_id = p_empresa_id
         AND pessoa_id <> v_pessoa_id;
      --
      IF v_qt > 0
      THEN
       v_ok     := 9;
       v_motivo := v_motivo || 'CNPJ já cadastrado para outra pessoa. ';
      END IF;
     
     ELSE
      -- verifica se a pessoa ja esta cadastrada
      SELECT nvl(MAX(pessoa_id), 0)
        INTO v_pessoa_id
        FROM pessoa
       WHERE cnpj = v_cnpj
         AND empresa_id = p_empresa_id;
     
     END IF;
    END IF;
   
   END IF;
   --
   IF cpf_pkg.validar(r_pessoa.cpf, p_empresa_id) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'CPF inválido. ';
   ELSE
    -- retira formatacao
    v_cpf := cpf_pkg.converter(r_pessoa.cpf, p_empresa_id);
    --
    IF v_cpf IN ('00000000000',
                 '11111111111',
                 '22222222222',
                 '33333333333',
                 '44444444444',
                 '55555555555',
                 '66666666666',
                 '77777777777',
                 '88888888888',
                 '99999999999')
    THEN
     v_cpf := NULL;
    END IF;
    --
    IF v_cpf IS NOT NULL
    THEN
     IF v_pessoa_id > 0
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa
       WHERE cpf = v_cpf
         AND empresa_id = p_empresa_id
         AND pessoa_id <> v_pessoa_id;
      --
      IF v_qt > 0
      THEN
       v_ok     := 9;
       v_motivo := v_motivo || 'CPF já cadastrado para outra pessoa. ';
      END IF;
     
     ELSE
      -- verifica se a pessoa ja esta cadastrada
      SELECT nvl(MAX(pessoa_id), 0)
        INTO v_pessoa_id
        FROM pessoa
       WHERE cpf = v_cpf
         AND empresa_id = p_empresa_id;
     
     END IF;
    END IF;
   
   END IF;
   --
   --  tratamento do "contato de"
   IF r_pessoa.contato_cnpj_cpf IS NOT NULL
   THEN
    IF cnpj_pkg.validar(r_pessoa.contato_cnpj_cpf, p_empresa_id) = 0 AND
       cpf_pkg.validar(r_pessoa.contato_cnpj_cpf, p_empresa_id) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'CNPJ/CPF do "contato de" inválido. ';
    ELSE
     IF cnpj_pkg.validar(r_pessoa.contato_cnpj_cpf, p_empresa_id) = 1
     THEN
      v_contato_cnpj_cpf := cnpj_pkg.converter(r_pessoa.contato_cnpj_cpf, p_empresa_id);
      --
      SELECT MAX(pessoa_id)
        INTO v_pessoa_pai_id
        FROM pessoa
       WHERE cnpj = v_contato_cnpj_cpf
         AND empresa_id = p_empresa_id;
      --
      IF v_pessoa_pai_id IS NULL
      THEN
       v_ok     := 9;
       v_motivo := v_motivo || 'CNPJ do "contato de" não encontrado. ';
      END IF;
     
     END IF;
     --
     IF cpf_pkg.validar(r_pessoa.contato_cnpj_cpf, p_empresa_id) = 1
     THEN
      v_contato_cnpj_cpf := cpf_pkg.converter(r_pessoa.contato_cnpj_cpf, p_empresa_id);
      --
      SELECT MAX(pessoa_id)
        INTO v_pessoa_pai_id
        FROM pessoa
       WHERE cpf = v_contato_cnpj_cpf
         AND empresa_id = p_empresa_id;
      --
      IF v_pessoa_pai_id IS NULL
      THEN
       v_ok     := 9;
       v_motivo := v_motivo || 'CPF do "contato de" não encontrado. ';
      END IF;
     
     END IF;
    
    END IF;
   END IF;
   --
   --
   IF r_pessoa.cnpjcpf_titular IS NOT NULL
   THEN
    IF cnpj_pkg.validar(r_pessoa.cnpjcpf_titular, p_empresa_id) = 1
    THEN
     v_cnpj_cpf_titular := cnpj_pkg.converter(r_pessoa.cnpjcpf_titular, p_empresa_id);
    ELSE
     IF cpf_pkg.validar(r_pessoa.cnpjcpf_titular, p_empresa_id) = 1
     THEN
      v_cnpj_cpf_titular := cpf_pkg.converter(r_pessoa.cnpjcpf_titular, p_empresa_id);
     ELSE
      v_ok     := 9;
      v_motivo := v_motivo || 'CNPJ/CPF do titular da conta inválido. ';
     END IF;
    END IF;
   END IF;
   --
   --
   IF taxa_validar(r_pessoa.perc_honor) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Percentual de honorários inválido. ';
   END IF;
   --
   IF taxa_validar(r_pessoa.perc_encargo) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Percentual de encargo sobre custos inválido. ';
   END IF;
   --
   IF taxa_validar(r_pessoa.perc_encargo_honor) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Percentual de encargo sobre honorários inválido. ';
   END IF;
   --
   IF r_pessoa.num_dias_fatur IS NOT NULL
   THEN
    IF inteiro_validar(r_pessoa.num_dias_fatur) = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Número de dias para faturamento inválido. ';
    ELSE
     v_num_dias_fatur := to_number(r_pessoa.num_dias_fatur);
    END IF;
   END IF;
   --
   IF taxa_validar(r_pessoa.perc_imposto) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Percentual de impostos do fornecedor inválido. ';
   END IF;
   --
   IF numero_validar(r_pessoa.perc_bv) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Percentual de BV inválido. ';
   END IF;
   --
   IF r_pessoa.tipo_num_dias_fatur IS NOT NULL
   THEN
    IF r_pessoa.tipo_num_dias_fatur IN ('C', 'U')
    THEN
     v_tipo_num_dias_fatur := r_pessoa.tipo_num_dias_fatur;
    ELSE
     v_ok     := 9;
     v_motivo := v_motivo || 'Tipo de número de dias para faturamento inválido. ';
    END IF;
   END IF;
   --
   IF r_pessoa.flag_pessoa_jur IS NOT NULL
   THEN
    IF r_pessoa.flag_pessoa_jur NOT IN ('J', 'F', 'E', 'T', 'M', 'S', 'P', 'U', 'I')
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Tipo pessoa física/jurídica/etc inválido. ';
    END IF;
   END IF;
   --
   IF r_pessoa.flag_pessoa_jur IN ('E', 'T') AND
      (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR'))
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Foi indicada pessoa no estrangeiro com endereço no Brasil. ';
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento para pessoa VALIDA
   ------------------------------------------------------------
   IF v_ok = 0
   THEN
    --
    IF r_pessoa.grupo_nome IS NOT NULL
    THEN
     SELECT MAX(grupo_id)
       INTO v_grupo_id
       FROM grupo
      WHERE acento_retirar(r_pessoa.grupo_nome) = acento_retirar(nome)
        AND empresa_id = p_empresa_id;
    
    END IF;
    --
    v_flag_pessoa_jur := 'S';
    --
    IF r_pessoa.flag_pessoa_jur IS NOT NULL
    THEN
     IF r_pessoa.flag_pessoa_jur IN ('F', 'T', 'U')
     THEN
      -- pessoa fisica, pessoa fisica no estrangeiro, funcionario
      v_flag_pessoa_jur := 'N';
     END IF;
    END IF;
    --
    IF r_pessoa.cpf IS NOT NULL OR r_pessoa.cnpj IS NOT NULL
    THEN
     v_flag_sem_docum := 'N';
    ELSE
     v_flag_sem_docum := 'S';
    END IF;
    --
    IF v_pessoa_id > 0
    THEN
     UPDATE pessoa
        SET apelido             = r_pessoa.apelido,
            nome                = r_pessoa.nome,
            cpf                 = v_cpf,
            cnpj                = v_cnpj,
            flag_pessoa_jur     = v_flag_pessoa_jur,
            inscr_estadual      = r_pessoa.inscr_estadual,
            inscr_municipal     = r_pessoa.inscr_municipal,
            inscr_inss          = r_pessoa.inscr_inss,
            endereco            = r_pessoa.endereco,
            num_ender           = v_num_ender,
            compl_ender         = r_pessoa.compl_ender,
            zona                = r_pessoa.zona,
            bairro              = r_pessoa.bairro,
            cidade              = r_pessoa.cidade,
            uf                  = r_pessoa.uf,
            pais                = v_pais,
            cep                 = cep_pkg.converter(v_cep),
            ddd_telefone        = r_pessoa.ddd_telefone,
            num_telefone        = r_pessoa.num_telefone,
            ddd_celular         = r_pessoa.ddd_celular,
            num_celular         = r_pessoa.num_celular,
            website             = r_pessoa.website,
            email               = r_pessoa.email,
            fi_banco_id         = v_banco_id,
            num_agencia         = r_pessoa.num_agencia,
            num_conta           = r_pessoa.num_conta,
            tipo_conta          = r_pessoa.tipo_conta,
            nome_titular        = r_pessoa.nome_titular,
            cnpj_cpf_titular    = v_cnpj_cpf_titular,
            num_dias_fatur      = v_num_dias_fatur,
            tipo_num_dias_fatur = v_tipo_num_dias_fatur,
            desc_servicos       = r_pessoa.desc_servicos,
            rg                  = r_pessoa.rg,
            rg_org_exp          = r_pessoa.rg_org_exp,
            rg_uf               = r_pessoa.rg_uf,
            rg_data_exp         = data_converter(r_pessoa.rg_data_exp),
            flag_sem_docum      = v_flag_sem_docum,
            funcao              = r_pessoa.funcao,
            flag_ativo          = v_flag_ativo,
            obs                 = r_pessoa.obs
      WHERE pessoa_id = v_pessoa_id;
     --
    ELSIF nvl(v_pessoa_id, 0) = 0
    THEN
     SELECT seq_pessoa.nextval
       INTO v_pessoa_id
       FROM dual;
     --
     INSERT INTO pessoa
      (pessoa_id,
       empresa_id,
       usuario_id,
       apelido,
       nome,
       num_dias_fatur,
       tipo_num_dias_fatur,
       desc_servicos,
       flag_pessoa_jur,
       cnpj,
       inscr_estadual,
       inscr_municipal,
       inscr_inss,
       cpf,
       rg,
       rg_org_exp,
       rg_uf,
       rg_data_exp,
       flag_sem_docum,
       funcao,
       endereco,
       num_ender,
       compl_ender,
       zona,
       bairro,
       cep,
       cidade,
       uf,
       pais,
       ddd_telefone,
       num_telefone,
       ddd_celular,
       num_celular,
       website,
       email,
       fi_banco_id,
       num_agencia,
       num_conta,
       nome_titular,
       cnpj_cpf_titular,
       tipo_conta,
       obs,
       flag_ativo)
     VALUES
      (v_pessoa_id,
       p_empresa_id,
       NULL,
       r_pessoa.apelido,
       r_pessoa.nome,
       v_num_dias_fatur,
       v_tipo_num_dias_fatur,
       r_pessoa.desc_servicos,
       v_flag_pessoa_jur,
       v_cnpj,
       r_pessoa.inscr_estadual,
       r_pessoa.inscr_municipal,
       r_pessoa.inscr_inss,
       v_cpf,
       r_pessoa.rg,
       r_pessoa.rg_org_exp,
       r_pessoa.rg_uf,
       data_converter(r_pessoa.rg_data_exp),
       v_flag_sem_docum,
       r_pessoa.funcao,
       r_pessoa.endereco,
       v_num_ender,
       r_pessoa.compl_ender,
       r_pessoa.zona,
       r_pessoa.bairro,
       cep_pkg.converter(v_cep),
       r_pessoa.cidade,
       r_pessoa.uf,
       v_pais,
       r_pessoa.ddd_telefone,
       r_pessoa.num_telefone,
       r_pessoa.ddd_celular,
       r_pessoa.num_celular,
       r_pessoa.website,
       r_pessoa.email,
       v_banco_id,
       r_pessoa.num_agencia,
       r_pessoa.num_conta,
       r_pessoa.nome_titular,
       v_cnpj_cpf_titular,
       r_pessoa.tipo_conta,
       r_pessoa.obs,
       v_flag_ativo);
    
    END IF;
    --
    IF v_grupo_id IS NULL AND r_pessoa.grupo_nome IS NOT NULL
    THEN
     SELECT seq_grupo.nextval
       INTO v_grupo_id
       FROM dual;
     --
     INSERT INTO grupo
      (grupo_id,
       empresa_id,
       nome)
     VALUES
      (v_grupo_id,
       p_empresa_id,
       r_pessoa.grupo_nome);
    
    END IF;
    --
    IF v_grupo_id IS NOT NULL
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM grupo_pessoa
      WHERE grupo_id = v_grupo_id
        AND pessoa_id = v_pessoa_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO grupo_pessoa
       (grupo_id,
        pessoa_id)
      VALUES
       (v_grupo_id,
        v_pessoa_id);
     
     END IF;
    
    END IF;
    --
    IF nvl(v_pessoa_pai_id, 0) > 0
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM relacao
      WHERE pessoa_pai_id = v_pessoa_pai_id
        AND pessoa_filho_id = v_pessoa_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO relacao
       (pessoa_pai_id,
        pessoa_filho_id)
      VALUES
       (v_pessoa_pai_id,
        v_pessoa_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_cliente = 'S'
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_cli_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_fornecedor = 'S'
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_for_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_for_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_pessoa_jur IN ('U')
    THEN
     -- funcionario
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_int_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_int_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_pessoa_jur IN ('E', 'T')
    THEN
     -- pessoa no estrangeiro
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_est_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_est_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_pessoa_jur = 'M'
    THEN
     -- orgao publico municipal
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_opm_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_opm_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_pessoa_jur = 'S'
    THEN
     -- orgao publico estadual
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_ope_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_ope_id);
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_pessoa_jur = 'P'
    THEN
     -- orgao publico federal
     SELECT COUNT(*)
       INTO v_qt
       FROM tipific_pessoa
      WHERE pessoa_id = v_pessoa_id
        AND tipo_pessoa_id = v_tipo_pessoa_opf_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO tipific_pessoa
       (pessoa_id,
        tipo_pessoa_id)
      VALUES
       (v_pessoa_id,
        v_tipo_pessoa_opf_id);
     
     END IF;
    
    END IF;
    --
    --
    IF nvl(v_sistema_externo1_id, 0) > 0
    THEN
     IF r_pessoa.flag_cliente = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo1_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo1_id,
         v_pessoa_id,
         v_tipo_pessoa_cli_id,
         r_pessoa.cod_ext_pessoa1);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa1
        WHERE sistema_externo_id = v_sistema_externo1_id
          AND tipo_pessoa_id = v_tipo_pessoa_cli_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
     --
     IF r_pessoa.flag_fornecedor = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo1_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_for_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo1_id,
         v_pessoa_id,
         v_tipo_pessoa_for_id,
         r_pessoa.cod_ext_pessoa1);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa1
        WHERE sistema_externo_id = v_sistema_externo1_id
          AND tipo_pessoa_id = v_tipo_pessoa_for_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
    
    END IF;
    --
    --
    IF nvl(v_sistema_externo2_id, 0) > 0
    THEN
     IF r_pessoa.flag_cliente = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo2_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo2_id,
         v_pessoa_id,
         v_tipo_pessoa_cli_id,
         r_pessoa.cod_ext_pessoa2);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa2
        WHERE sistema_externo_id = v_sistema_externo2_id
          AND tipo_pessoa_id = v_tipo_pessoa_cli_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
     --
     IF r_pessoa.flag_fornecedor = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo2_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_for_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo2_id,
         v_pessoa_id,
         v_tipo_pessoa_for_id,
         r_pessoa.cod_ext_pessoa2);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa2
        WHERE sistema_externo_id = v_sistema_externo2_id
          AND tipo_pessoa_id = v_tipo_pessoa_for_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
    
    END IF;
    --
    --
    IF nvl(v_sistema_externo3_id, 0) > 0
    THEN
     IF r_pessoa.flag_cliente = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo3_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_cli_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo3_id,
         v_pessoa_id,
         v_tipo_pessoa_cli_id,
         r_pessoa.cod_ext_pessoa3);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa3
        WHERE sistema_externo_id = v_sistema_externo3_id
          AND tipo_pessoa_id = v_tipo_pessoa_cli_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
     --
     IF r_pessoa.flag_fornecedor = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM pessoa_sist_ext
       WHERE sistema_externo_id = v_sistema_externo3_id
         AND pessoa_id = v_pessoa_id
         AND tipo_pessoa_id = v_tipo_pessoa_for_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO pessoa_sist_ext
        (sistema_externo_id,
         pessoa_id,
         tipo_pessoa_id,
         cod_ext_pessoa)
       VALUES
        (v_sistema_externo3_id,
         v_pessoa_id,
         v_tipo_pessoa_for_id,
         r_pessoa.cod_ext_pessoa3);
      
      ELSE
       UPDATE pessoa_sist_ext
          SET cod_ext_pessoa = r_pessoa.cod_ext_pessoa3
        WHERE sistema_externo_id = v_sistema_externo3_id
          AND tipo_pessoa_id = v_tipo_pessoa_for_id
          AND pessoa_id = v_pessoa_id;
      
      END IF;
     
     END IF;
    
    END IF;
    --
    IF r_pessoa.flag_cliente = 'S' AND r_pessoa.produto_cliente IS NOT NULL
    THEN
     v_vetor_produto_cliente := r_pessoa.produto_cliente;
     v_delimitador           := ';';
     --
     WHILE nvl(length(rtrim(v_vetor_produto_cliente)), 0) > 0
     LOOP
      v_produto_cliente := TRIM(prox_valor_retornar(v_vetor_produto_cliente, v_delimitador));
      --
      SELECT COUNT(*)
        INTO v_qt
        FROM produto_cliente
       WHERE pessoa_id = v_pessoa_id
         AND TRIM(upper(nome)) = TRIM(upper(substr(v_produto_cliente, 1, 100)));
      --
      IF v_qt = 0
      THEN
       INSERT INTO produto_cliente
        (produto_cliente_id,
         pessoa_id,
         nome,
         flag_ativo)
       VALUES
        (seq_produto_cliente.nextval,
         v_pessoa_id,
         TRIM(substr(v_produto_cliente, 1, 100)),
         'S');
      
      END IF;
     
     END LOOP;
    
    END IF;
    --
    -- carregou com sucesso
    IF p_flag_excluir_carregados = 'S'
    THEN
     DELETE FROM pessoa_transferencia
      WHERE ROWID = r_pessoa.rowid;
    
    ELSE
     UPDATE pessoa_transferencia
        SET status      = 'OK',
            data_status = SYSDATE,
            motivo      = NULL
      WHERE ROWID = r_pessoa.rowid;
    
    END IF;
    --
   ELSE
    -- se v_ok <> 0, pessoa inválida
    ------------------------------------------------------------
    -- copiar pessoa inválida para a tabela de erro de transf.
    ------------------------------------------------------------
    -- deu erro
    UPDATE pessoa_transferencia
       SET motivo      = v_motivo,
           status      = 'ERRO',
           data_status = SYSDATE
     WHERE ROWID = r_pessoa.rowid;
    --
   END IF;
   --
  END LOOP;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END pessoa_carregar;
 --
 --
 PROCEDURE usuario_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/07/2016
  -- DESCRICAO: carrega usuarios
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  --
  v_qt                INTEGER;
  v_ok                INTEGER;
  v_exception         EXCEPTION;
  v_usuario_admin_id  usuario.usuario_id%TYPE;
  v_tipo_pessoa_id    tipo_pessoa.tipo_pessoa_id%TYPE;
  v_pessoa_id         pessoa.pessoa_id%TYPE;
  v_pessoa_alt_id     pessoa.pessoa_id%TYPE;
  v_flag_pessoa_jur   pessoa.flag_pessoa_jur%TYPE;
  v_flag_sem_docum    pessoa.flag_sem_docum%TYPE;
  v_flag_ativo        pessoa.flag_ativo%TYPE;
  v_motivo            VARCHAR2(10000);
  v_usuario_transf_id usuario_transf.usuario_transf_id%TYPE;
  v_cpf               VARCHAR2(100);
  v_papel_id          papel.papel_id%TYPE;
  v_usuario_id        usuario.usuario_id%TYPE;
  v_usuario_alt_id    usuario.usuario_id%TYPE;
  v_senha_encriptada  usuario.senha%TYPE;
  v_tab_feriado_id    usuario.tab_feriado_id%TYPE;
  --
  CURSOR c_us IS
   SELECT usuario_transf_id,
          TRIM(apelido) AS apelido,
          TRIM(nome) AS nome,
          TRIM(cpf) AS cpf,
          TRIM(email) AS email,
          TRIM(papel) AS papel,
          TRIM(login) AS login,
          TRIM(senha) AS senha,
          TRIM(carga_status) AS carga_status,
          ROWID
     FROM usuario_transf
    WHERE carga_status IS NULL
       OR carga_status = 'ERRO'
    ORDER BY upper(nome),
             ROWID;
  --
 BEGIN
  ------------------------------------------------------------
  -- inicialização de variáveis
  ------------------------------------------------------------
  v_flag_ativo      := 'S';
  v_flag_sem_docum  := 'S';
  v_flag_pessoa_jur := 'N';
  --
  SELECT nvl(MAX(usuario_transf_id), 0)
    INTO v_usuario_transf_id
    FROM usuario_transf;
  --
  FOR r_us IN c_us
  LOOP
   IF r_us.usuario_transf_id IS NULL
   THEN
    v_usuario_transf_id := v_usuario_transf_id + 1;
    UPDATE usuario_transf
       SET usuario_transf_id = v_usuario_transf_id
     WHERE ROWID = r_us.rowid;
   
   END IF;
  END LOOP;
 
  COMMIT;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa não foi informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa informada não existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_excluir_carregados) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag excluir carregados inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_admin_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_id
    FROM tipo_pessoa
   WHERE codigo = 'INTERNO';
  --
  IF v_tipo_pessoa_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrado o tipo de pessoa INTERNO.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tab_feriado_id)
    INTO v_tab_feriado_id
    FROM tab_feriado
   WHERE empresa_id = p_empresa_id
     AND flag_padrao = 'S';
  --
  IF v_tab_feriado_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não foi encontrada a tabela de feriados padrão.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- LOOP por usuario a ser carregado
  ------------------------------------------------------------
  FOR r_us IN c_us
  LOOP
   v_ok             := 0;
   v_motivo         := NULL;
   v_pessoa_id      := 0;
   v_cpf            := NULL;
   v_pessoa_alt_id  := NULL;
   v_usuario_alt_id := NULL;
   --
   IF TRIM(r_us.apelido) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O apelido está nulo. ';
   END IF;
   --
   IF length(r_us.apelido) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O apelido excedeu o tamanho de 100 posições. ';
   END IF;
   --
   IF TRIM(r_us.nome) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome está nulo. ';
   END IF;
   --
   IF length(r_us.nome) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome excedeu o tamanho de 100 posições. ';
   END IF;
   --
   IF length(r_us.email) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O E-mail excedeu o tamanho de 100 posições. ';
   END IF;
   --
   IF email_validar(r_us.email) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Email inválido. ';
   END IF;
   --
   IF length(r_us.cpf) > 14
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O CPF excedeu o tamanho de 14 posições. ';
   END IF;
   --
   IF cpf_pkg.validar(r_us.cpf, p_empresa_id) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'CPF inválido. ';
   ELSE
    -- retira formatacao
    v_cpf := cpf_pkg.converter(r_us.cpf, p_empresa_id);
    --
    IF v_cpf IN ('00000000000',
                 '11111111111',
                 '22222222222',
                 '33333333333',
                 '44444444444',
                 '55555555555',
                 '66666666666',
                 '77777777777',
                 '88888888888',
                 '99999999999')
    THEN
     v_cpf := NULL;
    END IF;
    --
    IF v_cpf IS NOT NULL
    THEN
     v_flag_sem_docum := 'N';
     --
     -- tenta achar a pessoa pelo CPF
     SELECT MAX(pessoa_id)
       INTO v_pessoa_alt_id
       FROM pessoa
      WHERE cpf = v_cpf
        AND empresa_id = p_empresa_id;
    
    END IF;
   
   END IF;
   --
   IF v_pessoa_alt_id IS NULL
   THEN
    -- tenta achar a pessoa pelo email (desde que seja usuario)
    SELECT MAX(pessoa_id)
      INTO v_pessoa_alt_id
      FROM pessoa
     WHERE lower(email) = lower(r_us.email)
       AND empresa_id = p_empresa_id
       AND usuario_id IS NOT NULL;
   
   END IF;
   --
   IF v_pessoa_alt_id IS NULL
   THEN
    -- tenta achar a pessoa pelo email (mesmo que nao seja usuario)
    SELECT MAX(pessoa_id)
      INTO v_pessoa_alt_id
      FROM pessoa
     WHERE lower(email) = lower(r_us.email)
       AND empresa_id = p_empresa_id;
   
   END IF;
   --
   IF TRIM(r_us.login) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O login está nulo. ';
   END IF;
   --
   IF length(r_us.login) > 50
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O login excedeu o tamanho de 50 posições. ';
   END IF;
   --
   -- tenta achar o usuario pelo login
   SELECT MAX(usuario_id)
     INTO v_usuario_alt_id
     FROM usuario
    WHERE rtrim(upper(login)) = rtrim(upper(r_us.login));
   --
   IF v_usuario_alt_id IS NOT NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O login ' || r_us.login || ' já existe. ';
   END IF;
   --
   IF TRIM(r_us.senha) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A senha está nula. ';
   END IF;
   --
   IF length(r_us.senha) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A senha excedeu o tamanho de 20 caracterres. ';
   END IF;
   --
   IF length(r_us.senha) < 4
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A senha deve ter no mínimo 4 caracteres. ';
   END IF;
   --
   v_senha_encriptada := util_pkg.texto_encriptar(r_us.senha, NULL);
   IF v_senha_encriptada IS NULL OR length(v_senha_encriptada) > 20
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Senha com tamanho inválido ou com erro na encriptação. ';
   END IF;
   --
   IF length(r_us.papel) > 100
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O papel excedeu o tamanho de 100 posições. ';
   END IF;
   --
   IF r_us.papel IS NOT NULL
   THEN
    SELECT MAX(papel_id)
      INTO v_papel_id
      FROM papel
     WHERE empresa_id = p_empresa_id
       AND upper(nome) = upper(r_us.papel);
    --
    IF v_papel_id IS NULL
    THEN
     SELECT MAX(papel_id)
       INTO v_papel_id
       FROM papel
      WHERE empresa_id = p_empresa_id
        AND acento_retirar(nome) = acento_retirar(r_us.papel);
    
    END IF;
    --
    IF v_papel_id IS NULL
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'O papel ' || r_us.papel || ' não exixte. ';
    END IF;
   
   END IF;
   --
   IF v_pessoa_alt_id IS NOT NULL
   THEN
    -- verifica a pessoa encontrada ja tem usuario
    SELECT MAX(usuario_id)
      INTO v_usuario_id
      FROM pessoa
     WHERE pessoa_id = v_pessoa_alt_id;
    --
    IF v_usuario_id IS NOT NULL AND v_usuario_alt_id IS NOT NULL AND
       v_usuario_id <> v_usuario_alt_id
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Pessoa já associada a outro usuário. ';
    END IF;
   
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento para pessoa VALIDA
   ------------------------------------------------------------
   IF v_ok = 0
   THEN
    -------------------------------------
    -- cria ou atualiza a pessoa
    -------------------------------------
    IF v_pessoa_alt_id IS NOT NULL
    THEN
     -- atualiza alguns dados da pessoa
     v_pessoa_id := v_pessoa_alt_id;
     --
     UPDATE pessoa
        SET nome    = r_us.nome,
            apelido = r_us.apelido
      WHERE pessoa_id = v_pessoa_id;
     --
     IF v_cpf IS NOT NULL
     THEN
      UPDATE pessoa
         SET cpf = v_cpf
       WHERE pessoa_id = v_pessoa_id;
     
     END IF;
     --
     IF r_us.email IS NOT NULL
     THEN
      UPDATE pessoa
         SET email = r_us.email
       WHERE pessoa_id = v_pessoa_id;
     
     END IF;
    
    ELSE
     -- cria a pessoa
     SELECT seq_pessoa.nextval
       INTO v_pessoa_id
       FROM dual;
     --
     -- cria o registro da pessoa
     INSERT INTO pessoa
      (pessoa_id,
       empresa_id,
       usuario_id,
       apelido,
       nome,
       flag_pessoa_jur,
       cpf,
       flag_sem_docum,
       email,
       flag_ativo)
     VALUES
      (v_pessoa_id,
       p_empresa_id,
       NULL,
       r_us.apelido,
       r_us.nome,
       v_flag_pessoa_jur,
       v_cpf,
       v_flag_sem_docum,
       r_us.email,
       v_flag_ativo);
    
    END IF;
    --
    -------------------------------------
    -- trata a tipificacao da pessoa
    -------------------------------------
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa_id);
    
    END IF;
    --
    -------------------------------------
    -- cria ou atualiza o usuario
    -------------------------------------
    IF v_usuario_alt_id IS NOT NULL
    THEN
     -- atualiza alguns dados do usuario
     v_usuario_id := v_usuario_alt_id;
     --
     UPDATE usuario
        SET login              = TRIM(r_us.login),
            senha              = v_senha_encriptada,
            flag_ativo         = 'S',
            qtd_login_invalido = 0,
            flag_bloqueado     = 'N',
            flag_email_bloq    = 'N'
      WHERE usuario_id = v_usuario_id;
    
    ELSE
     -- cria o usuario
     SELECT seq_usuario.nextval
       INTO v_usuario_id
       FROM dual;
     --
     INSERT INTO usuario
      (usuario_id,
       login,
       senha,
       qtd_login_invalido,
       flag_bloqueado,
       flag_email_bloq,
       flag_admin,
       flag_ativo,
       flag_sem_bloq_apont,
       flag_sem_bloq_aprov,
       flag_sem_aprov_horas,
       flag_permite_home,
       data_apontam_ini,
       data_apontam_fim,
       tab_feriado_id,
       flag_notifica_email,
       categoria,
       tipo_relacao)
     VALUES
      (v_usuario_id,
       TRIM(r_us.login),
       v_senha_encriptada,
       0,
       'N',
       'N',
       'N',
       'S',
       'S',
       'S',
       'S',
       'S',
       NULL,
       NULL,
       v_tab_feriado_id,
       'S',
       'COMUM',
       'CPGAGE');
     --
     INSERT INTO usuario_empresa
      (usuario_id,
       empresa_id,
       flag_padrao)
     VALUES
      (v_usuario_id,
       p_empresa_id,
       'S');
    
    END IF;
    --
    UPDATE pessoa
       SET usuario_id = v_usuario_id
     WHERE pessoa_id = v_pessoa_id;
    --
    -------------------------------------
    -- trata o papel
    -------------------------------------
    IF nvl(v_papel_id, 0) > 0
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM usuario_papel
      WHERE usuario_id = v_usuario_id
        AND papel_id = v_papel_id;
     --
     IF v_qt = 0
     THEN
      INSERT INTO usuario_papel
       (usuario_id,
        papel_id)
      VALUES
       (v_usuario_id,
        v_papel_id);
     
     END IF;
    
    END IF;
    --
    -------------------------------------
    -- trata o registro da carga
    -------------------------------------
    IF p_flag_excluir_carregados = 'S'
    THEN
     DELETE FROM usuario_transf
      WHERE ROWID = r_us.rowid;
    
    ELSE
     UPDATE usuario_transf
        SET carga_status = 'OK',
            carga_data   = SYSDATE,
            carga_motivo = NULL
      WHERE ROWID = r_us.rowid;
    
    END IF;
    --
   ELSE
    -- se v_ok <> 0, pessoa inválida
    -------------------------------------
    -- grava o erro
    -------------------------------------
    UPDATE usuario_transf
       SET carga_motivo = substr(v_motivo, 1, 2000),
           carga_status = 'ERRO',
           carga_data   = SYSDATE
     WHERE ROWID = r_us.rowid;
   
   END IF; -- fim do IF v_ok = 0
  END LOOP;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END usuario_carregar;
 --
 --
 PROCEDURE tipo_produto_carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 20/07/2016
  -- DESCRICAO: carrega tipo de produto
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         19/05/2023  Remoção das colunas custo interno min, med e max.
  -- Ana Luiza         25/11/2024  Adicao de categoria_id
  ------------------------------------------------------------------------------------------
 (
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_flag_excluir_carregados IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  --
  v_qt                     INTEGER;
  v_ok                     INTEGER;
  v_exception              EXCEPTION;
  v_usuario_admin_id       usuario.usuario_id%TYPE;
  v_tipo_produto_id        tipo_produto.tipo_produto_id%TYPE;
  v_tipo_produto_alt_id    tipo_produto.tipo_produto_id%TYPE;
  v_flag_ativo             tipo_produto.flag_ativo%TYPE;
  v_flag_sistema           tipo_produto.flag_sistema%TYPE;
  v_tempo_exec_info        tipo_produto.tempo_exec_info%TYPE;
  v_classe_produto_id      categoria.classe_produto_id%TYPE;
  v_categoria_id           tipo_produto.categoria_id%TYPE;
  v_motivo                 VARCHAR2(10000);
  v_tipo_produto_transf_id tipo_produto_transf.tipo_produto_transf_id%TYPE;
  v_vetor_tipo_os          VARCHAR2(500);
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_cod_tipo_os            tipo_os.codigo%TYPE;
  v_variacoes              VARCHAR2(4000);
  v_nome_var               VARCHAR2(100);
  v_nome_aux               VARCHAR2(100);
  v_delimitador            CHAR(1);
  --
  CURSOR c_tp IS
   SELECT tipo_produto_transf_id,
          TRIM(nome) AS nome,
          TRIM(variacoes) AS variacoes,
          TRIM(categoria_id) AS categoria_id,
          TRIM(cod_classe) AS cod_classe,
          TRIM(sub_classe) AS sub_classe,
          TRIM(codigos_tipo_os) AS codigos_tipo_os,
          TRIM(custo_interno_min) AS custo_interno_min,
          TRIM(custo_interno_med) AS custo_interno_med,
          TRIM(custo_interno_max) AS custo_interno_max,
          TRIM(cod_ext_produto) AS cod_ext_produto,
          TRIM(tempo_exec_info) AS tempo_exec_info,
          TRIM(carga_status) AS carga_status,
          ROWID
     FROM tipo_produto_transf
    WHERE carga_status IS NULL
       OR carga_status = 'ERRO'
    ORDER BY upper(nome),
             ROWID;
  --
 BEGIN
  ------------------------------------------------------------
  -- inicialização de variáveis
  ------------------------------------------------------------
  v_flag_ativo := 'S';
  --
  SELECT nvl(MAX(tipo_produto_transf_id), 0)
    INTO v_tipo_produto_transf_id
    FROM tipo_produto_transf;
  --
  FOR r_tp IN c_tp
  LOOP
   IF r_tp.tipo_produto_transf_id IS NULL
   THEN
    v_tipo_produto_transf_id := v_tipo_produto_transf_id + 1;
    UPDATE tipo_produto_transf
       SET tipo_produto_transf_id = v_tipo_produto_transf_id
     WHERE ROWID = r_tp.rowid;
   
   END IF;
  END LOOP;
 
  COMMIT;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa não foi informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM empresa
   WHERE empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa informada não existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_excluir_carregados) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag excluir carregados inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_admin_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- LOOP por produto a ser carregado
  ------------------------------------------------------------
  FOR r_tp IN c_tp
  LOOP
   v_ok                  := 0;
   v_motivo              := NULL;
   v_tipo_produto_id     := NULL;
   v_tipo_produto_alt_id := NULL;
   v_classe_produto_id   := NULL;
   --
   --v_categoria           := 'ND';
   --
   IF TRIM(r_tp.nome) IS NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome está nulo. ';
   END IF;
   --
   IF length(r_tp.nome) > 60
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome excedeu o tamanho de 60 posições. ';
   END IF;
   --
   IF instr(r_tp.nome, '|') > 0 OR instr(r_tp.nome, ';') > 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'O nome não pode conter pipe ou ponto-e-vírgula. ';
   END IF;
   --
   -- verifica se ja existe produto com esse nome (para alteracao)
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_alt_id
     FROM tipo_produto
    WHERE TRIM(acento_retirar(nome)) = TRIM(acento_retirar(r_tp.nome))
      AND empresa_id = p_empresa_id;
   --
   IF v_tipo_produto_alt_id IS NOT NULL
   THEN
    SELECT flag_sistema
      INTO v_flag_sistema
      FROM tipo_produto
     WHERE tipo_produto_id = v_tipo_produto_alt_id;
    --
    IF v_flag_sistema = 'S'
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Esse nome de produto é reservado para produtos do sistema. ';
    END IF;
   
   END IF;
   --
   IF length(r_tp.variacoes) > 500
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'As variações do nome são limitadas em 500 caracteres. ';
   END IF;
   --
   IF instr(r_tp.variacoes, '|') > 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'As variações do nome não podem conter pipe. ';
   END IF;
   --
   IF moeda_validar(r_tp.custo_interno_min) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Valor do custo interno mínimo inválido. ';
   END IF;
   --
   IF moeda_validar(r_tp.custo_interno_max) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Valor do custo interno máximo inválido. ';
   END IF;
   --
   IF moeda_validar(r_tp.custo_interno_med) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Valor do custo interno médio inválido. ';
   END IF;
   --
   IF numero_validar(r_tp.tempo_exec_info) = 0
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Tempo médio de execução inválido. ';
   END IF;
   --
   v_tempo_exec_info := round(numero_converter(r_tp.tempo_exec_info), 2);
   --
   /*IF length(r_tp.categoria) > 20 THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'o código da categoria do produto excedeu o tamanho de 20 posições. ';
   END IF;
   --
   IF r_tp.categoria IS NOT NULL THEN
    IF util_pkg.desc_retornar('categoria_tipo_prod', r_tp.categoria) IS NULL THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Categoria do produto inválida. ';
    END IF;
   --
   IF r_tp.categoria_id IS NOT NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Categoria do produto inválida. ';
   END IF;*/
   v_categoria_id := r_tp.categoria_id;
   --
   IF r_tp.cod_classe IS NULL AND r_tp.sub_classe IS NOT NULL
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'Código da classe do produto não foi informado. ';
   END IF;
   --
   IF length(r_tp.sub_classe) > 50
   THEN
    v_ok     := 9;
    v_motivo := v_motivo || 'A sub classe do produto excedeu o tamanho de 50 posições. ';
   END IF;
   --
   IF r_tp.cod_classe IS NOT NULL
   THEN
    SELECT MAX(classe_produto_id)
      INTO v_classe_produto_id
      FROM classe_produto
     WHERE empresa_id = p_empresa_id
       AND cod_classe = r_tp.cod_classe
       AND acento_retirar(nvl(sub_classe, 'ZZZ999ZZZ')) =
           acento_retirar(nvl(r_tp.sub_classe, 'ZZZ999ZZZ'));
    --
    IF v_classe_produto_id IS NULL
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Classe do produto não encontrada. ';
    END IF;
   
   END IF;
   --
   -- tratamento do vetor de tipo de OS
   v_vetor_tipo_os := TRIM(r_tp.codigos_tipo_os);
   v_delimitador   := ';';
   --
   WHILE nvl(length(rtrim(v_vetor_tipo_os)), 0) > 0
   LOOP
    v_cod_tipo_os := TRIM(prox_valor_retornar(v_vetor_tipo_os, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_os
     WHERE codigo = v_cod_tipo_os
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'Esse tipo de Workflow não existe (' || v_cod_tipo_os || '). ';
    END IF;
   
   END LOOP;
   --
   -- tratamento das variacoes
   v_variacoes   := TRIM(r_tp.variacoes);
   v_delimitador := ';';
   --
   WHILE nvl(length(rtrim(v_variacoes)), 0) > 0
   LOOP
    v_nome_var := TRIM(prox_valor_retornar(v_variacoes, v_delimitador));
    v_nome_var := acento_retirar(TRIM(v_nome_var));
    --
    IF length(v_nome_var) > 60
    THEN
     v_ok     := 9;
     v_motivo := v_motivo || 'O tamanho de uma única variação não pode exceder ' ||
                 '60 caracteres (' || v_nome_var || '). ';
    END IF;
    --
    IF v_nome_var IS NOT NULL
    THEN
     SELECT MAX(nome)
       INTO v_nome_aux
       FROM tipo_produto
      WHERE acento_retirar(nome) = v_nome_var
        AND empresa_id = p_empresa_id;
     --
     IF v_nome_aux IS NOT NULL
     THEN
      v_ok     := 9;
      v_motivo := v_motivo || 'Essa variação (' || v_nome_var ||
                  ') já está definida como um tipo de entregável. ';
     END IF;
     --
     SELECT MAX(tp.nome)
       INTO v_nome_aux
       FROM tipo_produto_var tv,
            tipo_produto     tp
      WHERE tp.tipo_produto_id = tv.tipo_produto_id
        AND acento_retirar(tv.nome) = v_nome_var
        AND tp.empresa_id = p_empresa_id
        AND tp.tipo_produto_id <> nvl(v_tipo_produto_alt_id, 0);
     --
     IF v_nome_aux IS NOT NULL
     THEN
      v_ok     := 9;
      v_motivo := v_motivo || 'Essa variação (' || upper(v_nome_var) ||
                  ') já está associada outro tipo de entregável (' || v_nome_aux || '). ';
     
     END IF;
    
    END IF;
   
   END LOOP;
   --
   ------------------------------------------------------------
   -- tratamento para produto VALIDO
   ------------------------------------------------------------
   IF v_ok = 0
   THEN
    -------------------------------------
    -- cria ou atualiza o produto
    -------------------------------------
    IF v_tipo_produto_alt_id IS NOT NULL
    THEN
     -- atualiza dados do produto
     v_tipo_produto_id := v_tipo_produto_alt_id;
     --ALCBO_190523
     UPDATE tipo_produto
        SET nome            = r_tp.nome,
            cod_ext_produto = r_tp.cod_ext_produto,
            --classe_produto_id = v_classe_produto_id,
            categoria_id    = v_categoria_id,
            variacoes       = r_tp.variacoes,
            tempo_exec_info = v_tempo_exec_info
      WHERE tipo_produto_id = v_tipo_produto_id;
     --
    ELSE
     -- cria o produto
     SELECT seq_tipo_produto.nextval
       INTO v_tipo_produto_id
       FROM dual;
     --ALCBO_190523
     INSERT INTO tipo_produto
      (tipo_produto_id,
       empresa_id,
       nome,
       codigo,
       cod_ext_produto,
       --classe_produto_id,
       categoria_id,
       variacoes,
       tempo_exec_info,
       flag_sistema,
       flag_ativo,
       unidade_freq)
     VALUES
      (v_tipo_produto_id,
       p_empresa_id,
       r_tp.nome,
       NULL,
       r_tp.cod_ext_produto,
       --v_classe_produto_id,
       v_categoria_id,
       r_tp.variacoes,
       v_tempo_exec_info,
       'N',
       v_flag_ativo,
       'UN');
    
    END IF;
    --
    -------------------------------------
    -- trata vetor de tipo de OS
    -------------------------------------
    v_vetor_tipo_os := TRIM(r_tp.codigos_tipo_os);
    v_delimitador   := ';';
    --
    WHILE nvl(length(rtrim(v_vetor_tipo_os)), 0) > 0
    LOOP
     v_cod_tipo_os := TRIM(prox_valor_retornar(v_vetor_tipo_os, v_delimitador));
     --
     SELECT MAX(tipo_os_id)
       INTO v_tipo_os_id
       FROM tipo_os
      WHERE codigo = v_cod_tipo_os
        AND empresa_id = p_empresa_id;
     --
     IF v_tipo_os_id IS NOT NULL
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM tipo_prod_tipo_os
       WHERE tipo_produto_id = v_tipo_produto_id
         AND tipo_os_id = v_tipo_os_id;
      --
      IF v_qt = 0
      THEN
       INSERT INTO tipo_prod_tipo_os
        (tipo_produto_id,
         tipo_os_id)
       VALUES
        (v_tipo_produto_id,
         v_tipo_os_id);
      
      END IF;
     
     END IF;
    
    END LOOP;
    --
    -------------------------------------
    -- trata vetor de variacoes
    -------------------------------------
    v_variacoes   := TRIM(r_tp.variacoes);
    v_delimitador := ';';
    --
    WHILE nvl(length(rtrim(v_variacoes)), 0) > 0
    LOOP
     v_nome_var := TRIM(prox_valor_retornar(v_variacoes, v_delimitador));
     v_nome_var := acento_retirar(TRIM(v_nome_var));
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM tipo_produto_var
      WHERE tipo_produto_id = v_tipo_produto_id
        AND acento_retirar(nome) = v_nome_var;
     --
     IF v_qt = 0 AND TRIM(v_nome_var) IS NOT NULL
     THEN
      INSERT INTO tipo_produto_var
       (tipo_produto_id,
        nome)
      VALUES
       (v_tipo_produto_id,
        v_nome_var);
     
     END IF;
    
    END LOOP;
    --
    -------------------------------------
    -- trata o registro da carga
    -------------------------------------
    IF p_flag_excluir_carregados = 'S'
    THEN
     DELETE FROM tipo_produto_transf
      WHERE ROWID = r_tp.rowid;
    
    ELSE
     UPDATE tipo_produto_transf
        SET carga_status = 'OK',
            carga_data   = SYSDATE,
            carga_motivo = NULL
      WHERE ROWID = r_tp.rowid;
    
    END IF;
    --
   ELSE
    -- se v_ok <> 0, pessoa inválida
    -------------------------------------
    -- grava o erro
    -------------------------------------
    UPDATE tipo_produto_transf
       SET carga_motivo = substr(v_motivo, 1, 2000),
           carga_status = 'ERRO',
           carga_data   = SYSDATE
     WHERE ROWID = r_tp.rowid;
   
   END IF; -- fim do IF v_ok = 0
  END LOOP;
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END tipo_produto_carregar;
 --
--
END; -- CARGA_pkg

/
