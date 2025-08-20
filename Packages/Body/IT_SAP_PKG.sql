--------------------------------------------------------
--  DDL for Package Body IT_SAP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "IT_SAP_PKG" IS
 --
 v_xml_doc        VARCHAR2(100) := '<?xml version="1.0" encoding="UTF-8" ?>';
 v_charset_sisext VARCHAR2(20) := 'UTF8';
 v_charset_jobone VARCHAR2(20) := charset_retornar;
 --
 --
 PROCEDURE log_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML principal enviado ao sistema externo ou o
  --   XML principal recebido pelo sistema externo (transacao autonoma, que faz commit mas
  --   nao interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id      IN NUMBER,
  p_sistema_origem  IN VARCHAR2,
  p_sistema_destino IN VARCHAR2,
  p_cod_objeto      IN VARCHAR2,
  p_cod_acao        IN VARCHAR2,
  p_objeto_id       IN VARCHAR2,
  p_xml_in          IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  IF p_xml_in IS NOT NULL THEN
   INSERT INTO xml_log
    (xml_log_id,
     data,
     texto_xml,
     retorno_xml,
     sistema_origem,
     sistema_destino,
     cod_objeto,
     cod_acao,
     objeto_id)
   VALUES
    (p_xml_log_id,
     SYSDATE,
     p_xml_in,
     'PENDENTE',
     p_sistema_origem,
     p_sistema_destino,
     p_cod_objeto,
     p_cod_acao,
     to_number(p_objeto_id));
  END IF;
  --
  COMMIT;
  --
 END log_gravar;
 --
 --
 PROCEDURE log_concluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Subrotina que grava no log o XML de retorno enviado pelo sistema externo ou
  --   o XML de retorno gerado pelo JobOne (transacao autonoma, que faz commit mas nao
  --   interfere no processamento da transacao original).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_xml_log_id IN NUMBER,
  p_objeto_id  IN VARCHAR2,
  p_xml_out    IN CLOB
 ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  --
 BEGIN
  --
  IF p_xml_out IS NOT NULL THEN
   UPDATE xml_log
      SET retorno_xml = p_xml_out,
          objeto_id   = to_number(p_objeto_id)
    WHERE xml_log_id = p_xml_log_id;
  END IF;
  --
  COMMIT;
  --
 END log_concluir;
 --
 --
 --
 FUNCTION char_esp_retirar
 (
  -----------------------------------------------------------------------
  --   char_especial_retirar
  --
  --   Descricao: retira eventuais caracteres especiais de um dado string
  -----------------------------------------------------------------------
  p_string IN VARCHAR2
 ) RETURN VARCHAR2 IS
  --
  v_string VARCHAR2(32000);
  --
 BEGIN
  v_string := TRIM(p_string);
  --
  v_string := TRIM(REPLACE(v_string, chr(13), ''));
  v_string := TRIM(REPLACE(v_string, chr(10), ' '));
  --
  v_string := TRIM(REPLACE(v_string, '&', ' '));
  v_string := TRIM(REPLACE(v_string, '%', ' '));
  v_string := TRIM(REPLACE(v_string, '@', ' '));
  v_string := TRIM(REPLACE(v_string, '"', ' '));
  v_string := TRIM(REPLACE(v_string, '''', ' '));
  v_string := TRIM(REPLACE(v_string, 'º', ' '));
  v_string := TRIM(REPLACE(v_string, '°', ' '));
  v_string := TRIM(REPLACE(v_string, 'ª', ' '));
  --
  RETURN v_string;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_string := 'ERRO string';
   v_string := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 500);
   RETURN v_string;
 END char_esp_retirar;
 --
 --
 --
 PROCEDURE pessoa_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do SAP referentes a
  --  integração de PESSOA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/10/2018  Verifica se o ponto de integracao esta ligado.
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao       IN VARCHAR2,
  p_tipo_pessoa    IN VARCHAR2,
  p_cod_emp_sap    IN VARCHAR2,
  p_cod_filial_sap IN VARCHAR2,
  p_cod_cli_sap    IN VARCHAR2,
  p_apelido        IN VARCHAR2,
  p_nome           IN VARCHAR2,
  p_cod_projeto    IN VARCHAR2,
  p_tipo_fis_jur   IN VARCHAR2,
  p_cnpj           IN VARCHAR2,
  p_cpf            IN VARCHAR2,
  p_pais           IN VARCHAR2,
  p_uf             IN VARCHAR2,
  p_cidade         IN VARCHAR2,
  p_bairro         IN VARCHAR2,
  p_cep            IN VARCHAR2,
  p_endereco       IN VARCHAR2,
  p_complemento    IN VARCHAR2,
  p_telefone       IN VARCHAR2,
  p_fax            IN VARCHAR2,
  p_email          IN VARCHAR2,
  p_ativo          IN VARCHAR2,
  p_pessoa_id      OUT VARCHAR2,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_pessoa_id          pessoa.pessoa_id%TYPE;
  v_emp_resp_pdr_id    pessoa.emp_resp_pdr_id%TYPE;
  v_operacao           VARCHAR2(10);
  --
 BEGIN
  v_qt        := 0;
  p_erro_msg  := NULL;
  p_pessoa_id := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'SAP_WMCCANN';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (SAP_WMCCANN).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa_sist_ext
   WHERE cod_ext_empresa = p_cod_emp_sap
     AND sistema_externo_id = v_sistema_externo_id;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da empresa não encontrado (' || p_cod_emp_sap || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_filial_sap) IS NOT NULL THEN
   SELECT MAX(pessoa_id)
     INTO v_emp_resp_pdr_id
     FROM empr_resp_sist_ext
    WHERE cod_ext_resp = p_cod_filial_sap
      AND sistema_externo_id = v_sistema_externo_id;
   --
   IF v_emp_resp_pdr_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código da filial não encontrado (' || p_cod_filial_sap || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF p_cod_acao IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  -- verifica se o ponto de integracao esta ligado
  SELECT COUNT(*)
    INTO v_qt
    FROM sist_ext_ponto_int sp,
         ponto_integracao   pi
   WHERE sp.sistema_externo_id = v_sistema_externo_id
     AND sp.empresa_id = v_empresa_id
     AND sp.ponto_integracao_id = pi.ponto_integracao_id
     AND pi.codigo =
         decode(p_cod_acao, 'I', 'PESSOA_ATUALIZAR', 'A', 'PESSOA_ATUALIZAR', 'E', 'PESSOA_EXCLUIR');
  --
  IF v_qt > 0 THEN
   it_sap_pkg.pessoa_atualizar(v_usuario_sessao_id,
                               v_sistema_externo_id,
                               v_empresa_id,
                               v_emp_resp_pdr_id,
                               v_operacao,
                               TRIM(p_tipo_pessoa),
                               TRIM(p_cod_cli_sap),
                               TRIM(p_cod_projeto),
                               TRIM(p_tipo_fis_jur),
                               TRIM(p_apelido),
                               TRIM(p_nome),
                               TRIM(p_cnpj),
                               TRIM(p_cpf),
                               TRIM(p_endereco),
                               NULL,
                               TRIM(p_complemento),
                               TRIM(p_bairro),
                               TRIM(p_cep),
                               TRIM(p_cidade),
                               TRIM(p_uf),
                               TRIM(p_pais),
                               TRIM(p_telefone),
                               TRIM(p_fax),
                               TRIM(p_email),
                               TRIM(p_ativo),
                               v_pessoa_id,
                               p_erro_cod,
                               p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   p_pessoa_id := v_pessoa_id;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: erro na integração de pessoa. ' || p_erro_msg;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na integração de pessoa. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
   ROLLBACK;
 END pessoa_processar;
 --
 --
 PROCEDURE pessoa_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: subrotina que consiste e atualiza PESSOA.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/02/2014  Nao aceita CNPJ+código SAP diferentes do que ja existe.
  --                               Replicacao da atualizacao para outras empresas.
  -- Silvia            24/02/2016  Mudanca na carga da perc padrao BV de 10 p/ 0 (momentum).
  -- Silvia            18/05/2016  Tratamento de orgao publico.
  -- Silvia            22/11/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_emp_resp_pdr_id    IN pessoa.emp_resp_pdr_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_tipo_pessoa        IN VARCHAR2,
  p_cod_ext_pessoa     IN VARCHAR2,
  p_cod_job            IN VARCHAR2,
  p_pessoa_fis_jur     IN VARCHAR2,
  p_apelido            IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_cnpj               IN VARCHAR2,
  p_cpf                IN VARCHAR2,
  p_endereco           IN VARCHAR2,
  p_num_ender          IN VARCHAR2,
  p_compl_ender        IN VARCHAR2,
  p_bairro             IN VARCHAR2,
  p_cep                IN VARCHAR2,
  p_cidade             IN VARCHAR2,
  p_uf                 IN VARCHAR2,
  p_pais               IN VARCHAR2,
  p_telefone           IN VARCHAR2,
  p_fax                IN VARCHAR2,
  p_email              IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_pessoa_id          OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_pessoa_id       pessoa.pessoa_id%TYPE;
  v_fi_banco_id     pessoa.fi_banco_id%TYPE;
  v_flag_pessoa_jur pessoa.flag_pessoa_jur%TYPE;
  v_cnpj            pessoa.cnpj%TYPE;
  v_cpf             pessoa.cpf%TYPE;
  v_pais            pessoa.pais%TYPE;
  --v_perc_bv         pessoa.perc_bv%TYPE;
  --v_perc_imposto    pessoa.perc_imposto%TYPE;
  --v_tipo_fatur_bv   pessoa.tipo_fatur_bv%TYPE;
  v_flag_sem_docum  pessoa.flag_sem_docum%TYPE;
  v_tipo_pessoa_id  tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_pessoa2_id tipo_pessoa.tipo_pessoa_id%TYPE;
  v_cod_ext_pessoa  pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_cod_evento      VARCHAR2(40);
  v_lbl_jobs        VARCHAR2(100);
  v_estrangeiro     CHAR(1);
  v_tipo_pessoa1    tipo_pessoa.codigo%TYPE;
  v_tipo_pessoa2    tipo_pessoa.codigo%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  --v_perc_bv       := NULL;
  --v_perc_imposto  := NULL;
  --v_tipo_fatur_bv := NULL;
  --
  SELECT MAX(es.cod_ext_empresa)
    INTO v_cod_ext_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  v_estrangeiro  := 'N';
  v_tipo_pessoa1 := p_tipo_pessoa;
  v_tipo_pessoa2 := NULL;
  --
  IF p_tipo_pessoa LIKE 'CLI_ORG%' OR p_tipo_pessoa LIKE 'FOR_ORG%' THEN
   -- tratamento especial p/ cliente ou fornecedor orgao publico
   IF p_tipo_pessoa LIKE 'CLI%' THEN
    v_tipo_pessoa1 := 'CLIENTE';
   ELSE
    v_tipo_pessoa1 := 'FORNECEDOR';
   END IF;
   --
   -- guarda a parte que indica o tipo orgao publico
   v_tipo_pessoa2 := substr(p_tipo_pessoa, 5);
  END IF;
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_id
    FROM tipo_pessoa
   WHERE codigo = v_tipo_pessoa1;
  --
  IF v_tipo_pessoa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de pessoa inválido (' || v_tipo_pessoa1 || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_ext_pessoa) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_ext_pessoa) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP não pode ter mais que 20 caracteres (' || p_cod_ext_pessoa || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_pessoa_fis_jur NOT IN ('F', 'J', 'X') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Indicação de pessoa física/jurídica inválida (' || p_pessoa_fis_jur || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_pessoa_fis_jur = 'F' THEN
   -- pessoa fisica
   v_flag_pessoa_jur := 'N';
  ELSE
   -- se vier nulo, J ou X, marca como pessoa juridica
   v_flag_pessoa_jur := 'S';
  END IF;
  --
  IF rtrim(p_apelido) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome fantasia é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_apelido) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O apelido/nome fantasia não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome/razão social não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF cnpj_pkg.validar(p_cnpj, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CNPJ inválido (' || p_cnpj || ').';
   RAISE v_exception;
  ELSE
   v_cnpj := cnpj_pkg.converter(p_cnpj, p_empresa_id);
  END IF;
  --
  IF cpf_pkg.validar(p_cpf, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'CPF inválido (' || p_cpf || ').';
   RAISE v_exception;
  ELSE
   v_cpf := cpf_pkg.converter(p_cpf, p_empresa_id);
  END IF;
  --
  IF v_cnpj = '00000000000000' OR v_cpf = '00000000000' THEN
   -- pessoa no estrangeiro
   v_estrangeiro  := 'S';
   v_tipo_pessoa2 := 'ESTRANGEIRO';
   v_cnpj         := NULL;
   v_cpf          := NULL;
  END IF;
  --
  IF v_tipo_pessoa2 IS NULL AND v_cpf IS NULL AND v_cnpj IS NULL THEN
   -- cliente ou fornecedor puro
   p_erro_cod := '90000';
   p_erro_msg := 'O CPF ou o CNPJ devem ser informados.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pessoa_jur = 'S' AND v_cpf IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O CPF só deve ser fornecido para pessoas físicas (' || p_cpf || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pessoa_jur = 'N' AND v_cnpj IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O CNPJ só deve ser fornecido para pessoas jurídicas (' || p_cnpj || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cnpj IS NULL AND v_cpf IS NULL THEN
   -- pessoa no estrangeito, orgao publico
   v_flag_sem_docum := 'S';
  ELSE
   v_flag_sem_docum := 'N';
  END IF;
  --
  IF length(p_endereco) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O endereço não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_ender) = 0 OR to_number(p_num_ender) > 999999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do endereço inválido (' || p_num_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_compl_ender) > 30 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do endereço não pode ter mais que 30 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_bairro) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O bairro não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_pais) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O país não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_pais := TRIM(p_pais);
  --
  IF upper(v_pais) IN ('BASIL', 'BRASI', 'BRAISL', 'BRAIL', 'BRAZIL', 'BRASIL') THEN
   v_pais := 'Brasil';
  END IF;
  --
  IF v_estrangeiro = 'S' AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Foi indicada pessoa no estrangeiro com endereço no Brasil.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cep) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   IF cep_pkg.validar(p_cep) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'CEP inválido (' || p_cep || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_cidade) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O município não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_uf) IS NOT NULL AND (v_pais IS NULL OR upper(v_pais) IN ('BRASIL', 'BRA', 'BR')) THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM dicionario
    WHERE tipo = 'estado'
      AND codigo = upper(rtrim(p_uf));
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Sigla do estado inválida (' || p_uf || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_telefone) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do telefone não pode ter mais que 80 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_fax) > 80 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do fax não pode ter mais que 80 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_email) > 50 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O email não pode ter mais que 50 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF email_validar(p_email) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Email inválido (' || p_email || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido (' || p_flag_ativo || ').';
   RAISE v_exception;
  END IF;
  --
  -- tenta localizar a pessoa pelo codigo externo
  SELECT MAX(pe.pessoa_id),
         MAX(ps.cod_ext_pessoa)
    INTO v_pessoa_id,
         v_cod_ext_pessoa
    FROM pessoa          pe,
         pessoa_sist_ext ps
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.cod_ext_pessoa = p_cod_ext_pessoa
     AND ps.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_pessoa_id IS NULL THEN
   -- tenta localizar a pessoa pelo CNPJ/CPF
   IF v_cnpj IS NOT NULL THEN
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE cnpj = v_cnpj
       AND empresa_id = p_empresa_id;
   END IF;
   --
   IF v_cpf IS NOT NULL THEN
    SELECT MAX(pessoa_id)
      INTO v_pessoa_id
      FROM pessoa
     WHERE cpf = v_cpf
       AND empresa_id = p_empresa_id;
   END IF;
  END IF;
  --
  IF v_pessoa_id IS NOT NULL THEN
   -- verifica se para esse tipo de pessoa o codigo SAP
   -- ja existe e confere com o enviado.
   SELECT MAX(cod_ext_pessoa)
     INTO v_cod_ext_pessoa
     FROM pessoa_sist_ext
    WHERE pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id
      AND sistema_externo_id = p_sistema_externo_id;
   --
   IF v_cod_ext_pessoa <> p_cod_ext_pessoa THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa pessoa já está integrada através do código (' || v_cod_ext_pessoa || ').';
    RAISE v_exception;
   END IF;
   --
   /*SELECT perc_bv,
          perc_imposto,
          tipo_fatur_bv
     INTO v_perc_bv,
          v_perc_imposto,
          v_tipo_fatur_bv
     FROM pessoa
    WHERE pessoa_id = v_pessoa_id;*/
  END IF;
  --
  -- tratamentos especiais p/ momentum e E/OU
  /*IF v_cod_ext_empresa IN ('BR77', 'BR60') THEN
   -- carrega perc BV com 0%, desde que nao preenchido
   IF v_perc_bv IS NULL THEN
    v_perc_bv := 0;
   END IF;
   --
   -- carrega perc imposto com 0%, desde que nao preenchido
   IF v_perc_imposto IS NULL THEN
    v_perc_imposto := 0;
   END IF;
   --
   -- tipo com FAT, desde que nao preenchido
   IF v_tipo_fatur_bv IS NULL THEN
    v_tipo_fatur_bv := 'FAT';
   END IF;
  END IF;*/
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF p_operacao IN ('INCLUIR', 'ALTERAR') THEN
   IF v_pessoa_id IS NOT NULL THEN
    -- pessoa ja existe no JobOne. Atualiza o registro
    v_cod_evento := 'ALTERAR';
    --
    UPDATE pessoa
       SET apelido         = substr(TRIM(p_apelido), 1, 100),
           nome            = substr(TRIM(p_nome), 1, 100),
           cod_job         = p_cod_job,
           cnpj            = v_cnpj,
           cpf             = v_cpf,
           flag_sem_docum  = v_flag_sem_docum,
           flag_pessoa_jur = v_flag_pessoa_jur,
           endereco        = TRIM(p_endereco),
           num_ender       = p_num_ender,
           compl_ender     = TRIM(p_compl_ender),
           bairro          = TRIM(p_bairro),
           cep             = cep_pkg.converter(TRIM(p_cep)),
           cidade          = TRIM(p_cidade),
           uf              = TRIM(upper(p_uf)),
           pais            = v_pais,
           num_telefone    = p_telefone,
           --num_fax         = p_fax,
           email           = TRIM(p_email),
           flag_ativo      = p_flag_ativo,
           emp_resp_pdr_id = zvl(p_emp_resp_pdr_id, NULL)
           --perc_bv         = v_perc_bv,
           -- perc_imposto    = v_perc_imposto
           --tipo_fatur_bv   = v_tipo_fatur_bv
     WHERE pessoa_id = v_pessoa_id;
    --
    -- faz a mesma atualizacao para pessoas de outras
    -- empresas com o mesmo codigo SAP
    UPDATE pessoa pe
       SET apelido         = substr(TRIM(p_apelido), 1, 100),
           nome            = substr(TRIM(p_nome), 1, 100),
           cod_job         = p_cod_job,
           cnpj            = v_cnpj,
           cpf             = v_cpf,
           flag_sem_docum  = v_flag_sem_docum,
           flag_pessoa_jur = v_flag_pessoa_jur,
           endereco        = TRIM(p_endereco),
           num_ender       = p_num_ender,
           compl_ender     = TRIM(p_compl_ender),
           bairro          = TRIM(p_bairro),
           cep             = cep_pkg.converter(TRIM(p_cep)),
           cidade          = TRIM(p_cidade),
           uf              = TRIM(upper(p_uf)),
           pais            = v_pais,
           num_telefone    = p_telefone,
           --num_fax         = p_fax,
           email           = TRIM(p_email)
     WHERE empresa_id <> p_empresa_id
       AND (cnpj = v_cnpj OR cpf = v_cpf)
       AND EXISTS (SELECT 1
              FROM pessoa_sist_ext ps
             WHERE cod_ext_pessoa = p_cod_ext_pessoa
               AND ps.pessoa_id = pe.pessoa_id);
   ELSE
    -- pessoa nao existe para essa empresa no JobOne. Cria o registro
    v_cod_evento := 'INCLUIR';
    --
    SELECT seq_pessoa.nextval
      INTO v_pessoa_id
      FROM dual;
    --
    INSERT INTO pessoa (
    empresa_id,
    pessoa_id,
    apelido,
    nome,
    cod_job,
    cnpj,
    cpf,
    flag_sem_docum,
    flag_pessoa_jur,
    endereco,
    num_ender,
    compl_ender,
    bairro,
    cep,
    cidade,
    uf,
    pais,
    num_telefone,
    --num_fax,
    email,
    flag_emp_fatur,
    flag_emp_resp,
    flag_ativo,
    flag_pago_cliente,
    emp_resp_pdr_id
    --, perc_bv
    --, perc_imposto
    --, tipo_fatur_bv
  ) VALUES (
    p_empresa_id,
    v_pessoa_id,
    substr(TRIM(p_apelido), 1, 100),
    substr(TRIM(p_nome), 1, 100),
    p_cod_job,
    v_cnpj,
    v_cpf,
    v_flag_sem_docum,
    v_flag_pessoa_jur,
    TRIM(p_endereco),
    p_num_ender,
    TRIM(p_compl_ender),
    TRIM(p_bairro),
    cep_pkg.converter(TRIM(p_cep)),
    p_cidade,
    TRIM(upper(p_uf)),
    p_pais,
    p_telefone,
    --p_fax,
    TRIM(p_email),
    'N',
    'N',
    p_flag_ativo,
    'N',
    zvl(p_emp_resp_pdr_id, NULL)
    --, v_perc_bv
    --, v_perc_imposto
    --, v_tipo_fatur_bv
);
    --
    -- cria os impostos usados por fornecedores
    INSERT INTO fi_tipo_imposto_pessoa
     (fi_tipo_imposto_pessoa_id,
      fi_tipo_imposto_id,
      pessoa_id,
      --perc_imposto,
      flag_reter,
      nome_servico)
     SELECT seq_fi_tipo_imposto_pessoa.nextval,
            fi_tipo_imposto_id,
            v_pessoa_id,
            --v_perc_imposto,
            'N',
            NULL
       FROM fi_tipo_imposto
      WHERE flag_incide_ent = 'S';
   END IF;
   --
   -- processamento final apos inclusao / alteracao
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_qt = 0 THEN
    -- cria a pessoa com o tipo especificado
    INSERT INTO tipific_pessoa
     (pessoa_id,
      tipo_pessoa_id)
    VALUES
     (v_pessoa_id,
      v_tipo_pessoa_id);
   END IF;
   --
   IF v_tipo_pessoa2 IS NOT NULL THEN
    SELECT MAX(tipo_pessoa_id)
      INTO v_tipo_pessoa2_id
      FROM tipo_pessoa
     WHERE codigo = v_tipo_pessoa2;
    --
    IF v_tipo_pessoa2_id IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Tipo de pessoa ' || v_tipo_pessoa2 || ' não encontrado.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipific_pessoa
     WHERE pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa2_id;
    --
    IF v_qt = 0 THEN
     -- cria a pessoa com o tipo 2
     INSERT INTO tipific_pessoa
      (pessoa_id,
       tipo_pessoa_id)
     VALUES
      (v_pessoa_id,
       v_tipo_pessoa2_id);
    END IF;
   END IF;
   --
   --
   --
   DELETE FROM pessoa_sist_ext
    WHERE sistema_externo_id = p_sistema_externo_id
      AND pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   INSERT INTO pessoa_sist_ext
    (sistema_externo_id,
     pessoa_id,
     tipo_pessoa_id,
     cod_ext_pessoa)
   VALUES
    (p_sistema_externo_id,
     v_pessoa_id,
     v_tipo_pessoa_id,
     p_cod_ext_pessoa);
   --
   IF v_tipo_pessoa2_id IS NOT NULL THEN
    DELETE FROM pessoa_sist_ext
     WHERE sistema_externo_id = p_sistema_externo_id
       AND pessoa_id = v_pessoa_id
       AND tipo_pessoa_id = v_tipo_pessoa2_id;
    --
    INSERT INTO pessoa_sist_ext
     (sistema_externo_id,
      pessoa_id,
      tipo_pessoa_id,
      cod_ext_pessoa)
    VALUES
     (p_sistema_externo_id,
      v_pessoa_id,
      v_tipo_pessoa2_id,
      p_cod_ext_pessoa);
   END IF;
  END IF; -- fim do IF p_operacao IN ('INCLUIR','ALTERAR')
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF p_operacao = 'EXCLUIR' THEN
   IF v_pessoa_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Pessoa a ser excluída não encontrada (CNPJ/CPF: ' || nvl(p_cnpj, p_cpf) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE cliente_id = v_pessoa_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse cliente.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE pessoa_id = v_pessoa_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem produtos associados a esse cliente.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_hora
    WHERE cliente_id = v_pessoa_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem apontamentos de horas para esse cliente.';
    RAISE v_exception;
   END IF;
   --
   -- desassocia a pessoa desse tipo
   DELETE FROM pessoa_sist_ext
    WHERE sistema_externo_id = p_sistema_externo_id
      AND pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   DELETE FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipific_pessoa
    WHERE pessoa_id = v_pessoa_id;
   --
   IF v_qt = 0 THEN
    v_cod_evento := 'EXCLUIR';
    -- pessoa nao tem mais nenhum tipo. tenta excluir.
    DELETE FROM pessoa
     WHERE pessoa_id = v_pessoa_id;
   ELSE
    -- como a pessoa ainda esta tipificada, mantem o registro
    v_cod_evento := 'ALTERAR';
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := 'Integração SAP';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   v_cod_evento,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END pessoa_atualizar;
 --
 --
 --
 PROCEDURE produto_cliente_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do SAP referentes a
  --  integração de PRODUTO_CLIENTE.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/10/2018  Verifica se o ponto de integracao esta ligado.
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao           IN VARCHAR2,
  p_cod_emp_sap        IN VARCHAR2,
  p_cod_cli_sap        IN VARCHAR2,
  p_cod_pro_sap        IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_ativo              IN VARCHAR2,
  p_produto_cliente_id OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_produto_cliente_id produto_cliente.produto_cliente_id%TYPE;
  v_operacao           VARCHAR2(10);
  --
 BEGIN
  v_qt                 := 0;
  p_erro_msg           := NULL;
  p_produto_cliente_id := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'SAP_WMCCANN';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (SAP_WMCCANN).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa_sist_ext
   WHERE cod_ext_empresa = p_cod_emp_sap
     AND sistema_externo_id = v_sistema_externo_id;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da empresa não encontrado (' || p_cod_emp_sap || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF p_cod_acao IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  -- verifica se o ponto de integracao esta ligado
  SELECT COUNT(*)
    INTO v_qt
    FROM sist_ext_ponto_int sp,
         ponto_integracao   pi
   WHERE sp.sistema_externo_id = v_sistema_externo_id
     AND sp.empresa_id = v_empresa_id
     AND sp.ponto_integracao_id = pi.ponto_integracao_id
     AND pi.codigo = decode(p_cod_acao,
                            'I',
                            'PRODUTO_CLIENTE_ADICIONAR',
                            'A',
                            'PRODUTO_CLIENTE_ATUALIZAR',
                            'E',
                            'PRODUTO_CLIENTE_EXCLUIR');
  --
  IF v_qt > 0 THEN
   it_sap_pkg.produto_cliente_atualizar(v_usuario_sessao_id,
                                        v_sistema_externo_id,
                                        v_empresa_id,
                                        v_operacao,
                                        TRIM(p_cod_cli_sap),
                                        TRIM(p_cod_pro_sap),
                                        TRIM(p_nome),
                                        TRIM(p_ativo),
                                        v_produto_cliente_id,
                                        p_erro_cod,
                                        p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   p_produto_cliente_id := v_produto_cliente_id;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: erro na integração de produto do cliente. ' || p_erro_msg;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na integração de produto do cliente. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
   ROLLBACK;
 END produto_cliente_processar;
 --
 --
 PROCEDURE produto_cliente_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/05/2013
  -- DESCRICAO: subrotina que consiste e atualiza PRODUTO_CLIENTE.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/11/2017  Grava XML no historico.
  -- Silvia            22/04/2019  Atualiza produto ja existente no JobOne.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_cod_ext_cliente    IN VARCHAR2,
  p_cod_ext_produto    IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_produto_cliente_id OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_produto_cliente_id  produto_cliente.produto_cliente_id%TYPE;
  v_pessoa_id           pessoa.pessoa_id%TYPE;
  v_cliente             pessoa.nome%TYPE;
  v_tipo_pessoa_id      tipo_pessoa.tipo_pessoa_id%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_cod_evento          VARCHAR2(40);
  v_lbl_jobs            VARCHAR2(100);
  v_xml_atual           CLOB;
  v_cod_ext_produto_aux VARCHAR2(100);
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT MAX(tipo_pessoa_id)
    INTO v_tipo_pessoa_id
    FROM tipo_pessoa
   WHERE codigo = 'CLIENTE';
  --
  IF v_tipo_pessoa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de pessoa Cliente não encontrado.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_ext_produto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_ext_produto) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP do produto não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do produto não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido (' || p_flag_ativo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.pessoa_id)
    INTO v_pessoa_id
    FROM pessoa_sist_ext ps,
         pessoa          pe
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.tipo_pessoa_id = v_tipo_pessoa_id
     AND ps.cod_ext_pessoa = p_cod_ext_cliente
     AND ps.pessoa_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_pessoa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código SAP do cliente não encontrado (' || p_cod_ext_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_cliente
    FROM pessoa
   WHERE pessoa_id = v_pessoa_id;
  --
  -- tenta localizar o produto pelo codigo externo
  SELECT MAX(produto_cliente_id)
    INTO v_produto_cliente_id
    FROM produto_cliente
   WHERE pessoa_id = v_pessoa_id
     AND cod_ext_produto = p_cod_ext_produto;
  --
  IF v_produto_cliente_id IS NULL THEN
   -- tenta localizar pelo nome
   SELECT MAX(produto_cliente_id)
     INTO v_produto_cliente_id
     FROM produto_cliente
    WHERE pessoa_id = v_pessoa_id
      AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome));
   --
   IF v_produto_cliente_id IS NOT NULL THEN
    -- verifica se o produto ja tem codigo SAP
    SELECT TRIM(cod_ext_produto)
      INTO v_cod_ext_produto_aux
      FROM produto_cliente
     WHERE produto_cliente_id = v_produto_cliente_id;
    --
    IF v_cod_ext_produto_aux IS NOT NULL AND v_cod_ext_produto_aux <> p_cod_ext_produto THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Produto recebido com código ' || p_cod_ext_produto ||
                   ' já se encontra cadastrado com outro código (' || v_cod_ext_produto_aux || ').';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF p_operacao IN ('INCLUIR', 'ALTERAR') THEN
   IF v_produto_cliente_id IS NOT NULL THEN
    -- produto ja existe no JobOne. Atualiza o registro
    v_cod_evento := 'ALTERAR';
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_cliente
     WHERE pessoa_id = v_pessoa_id
       AND produto_cliente_id <> v_produto_cliente_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome));
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse nome de produto já existe para esse cliente (' || p_nome || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE produto_cliente
       SET nome            = TRIM(p_nome),
           flag_ativo      = p_flag_ativo,
           cod_ext_produto = p_cod_ext_produto
     WHERE produto_cliente_id = v_produto_cliente_id;
   ELSE
    -- produto nao existe no JobOne. Cria o registro
    v_cod_evento := 'INCLUIR';
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM produto_cliente
     WHERE pessoa_id = v_pessoa_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(p_nome));
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse nome de produto já existe para esse cliente (' || p_nome || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT seq_produto_cliente.nextval
      INTO v_produto_cliente_id
      FROM dual;
    --
    INSERT INTO produto_cliente
     (produto_cliente_id,
      pessoa_id,
      nome,
      cod_ext_produto,
      flag_ativo)
    VALUES
     (v_produto_cliente_id,
      v_pessoa_id,
      TRIM(p_nome),
      p_cod_ext_produto,
      p_flag_ativo);
   END IF;
  END IF; -- fim do IF p_operacao IN ('INCLUIR','ALTERAR')
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  pessoa_pkg.xml_gerar(v_pessoa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF p_operacao = 'EXCLUIR' THEN
   v_cod_evento := 'EXCLUIR';
   --
   IF v_produto_cliente_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Produto do cliente a ser excluído não encontrado (' || p_cod_ext_produto ||
                  ' - ' || p_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE produto_cliente_id = v_produto_cliente_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse produto.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_hora
    WHERE produto_cliente_id = v_produto_cliente_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem apontamentos de horas associados a esse produto.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento
    WHERE produto_cliente_id = v_produto_cliente_id
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem faturamentos associados a esse produto.';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM produto_cliente
    WHERE produto_cliente_id = v_produto_cliente_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_cliente;
  v_compl_histor   := 'Integração SAP - produto cliente: ' || p_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PESSOA',
                   v_cod_evento,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  p_produto_cliente_id := v_produto_cliente_id;
  p_erro_cod           := '00000';
  p_erro_msg           := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END produto_cliente_atualizar;
 --
 --
 --
 PROCEDURE tipo_produto_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 22/10/2014
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do SAP referentes a
  --  integração de TIPO_PRODUTO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/10/2018  Verifica se o ponto de integracao esta ligado.
  ------------------------------------------------------------------------------------------
 (
  p_cod_acao         IN VARCHAR2,
  p_cod_emp_sap      IN VARCHAR2,
  p_cod_material_sap IN VARCHAR2,
  p_nome             IN VARCHAR2,
  p_categoria        IN VARCHAR2,
  p_ativo            IN VARCHAR2,
  p_tipo_produto_id  OUT NUMBER,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_tipo_produto_id    tipo_produto.tipo_produto_id%TYPE;
  v_operacao           VARCHAR2(10);
  --
 BEGIN
  v_qt              := 0;
  p_erro_msg        := NULL;
  p_tipo_produto_id := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'SAP_WMCCANN';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (SAP_WMCCANN).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa_sist_ext
   WHERE cod_ext_empresa = p_cod_emp_sap
     AND sistema_externo_id = v_sistema_externo_id;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da empresa não encontrado (' || p_cod_emp_sap || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF p_cod_acao IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'I' THEN
   v_operacao := 'INCLUIR';
  ELSIF p_cod_acao = 'A' THEN
   v_operacao := 'ALTERAR';
  ELSIF p_cod_acao = 'E' THEN
   v_operacao := 'EXCLUIR';
  END IF;
  --
  -- verifica se o ponto de integracao esta ligado
  SELECT COUNT(*)
    INTO v_qt
    FROM sist_ext_ponto_int sp,
         ponto_integracao   pi
   WHERE sp.sistema_externo_id = v_sistema_externo_id
     AND sp.empresa_id = v_empresa_id
     AND sp.ponto_integracao_id = pi.ponto_integracao_id
     AND pi.codigo = decode(p_cod_acao,
                            'I',
                            'TIPO_PRODUTO_ADICIONAR',
                            'A',
                            'TIPO_PRODUTO_ATUALIZAR',
                            'E',
                            'TIPO_PRODUTO_EXCLUIR');
  --
  IF v_qt > 0 THEN
   it_sap_pkg.tipo_produto_atualizar(v_usuario_sessao_id,
                                     v_sistema_externo_id,
                                     v_empresa_id,
                                     v_operacao,
                                     TRIM(p_cod_material_sap),
                                     TRIM(p_nome),
                                     TRIM(p_categoria),
                                     TRIM(p_ativo),
                                     v_tipo_produto_id,
                                     p_erro_cod,
                                     p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   p_tipo_produto_id := v_tipo_produto_id;
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: erro na integração de tipo de produto. ' || p_erro_msg;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na integração de tipo de produto. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
   ROLLBACK;
 END tipo_produto_processar;
 --
 --
 PROCEDURE tipo_produto_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 22/10/2014
  -- DESCRICAO: subrotina que consiste e atualiza TIPO_PRODUTO.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/02/2015  Aceita virgula no nome (pipe e ponto-e-virgula nao).
  -- Silvia            22/11/2017  Grava XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_operacao           IN VARCHAR2,
  p_cod_ext_produto    IN VARCHAR2,
  p_nome               IN VARCHAR2,
  p_categoria          IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_tipo_produto_id    OUT NUMBER,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_tipo_produto_id     tipo_produto.tipo_produto_id%TYPE;
  v_categoria_id        tipo_produto.categoria_id%TYPE;
  v_flag_sistema        tipo_produto.flag_sistema%TYPE;
  v_nome                tipo_produto.nome%TYPE;
  v_cod_ext_produto_aux VARCHAR2(100);
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_cod_evento          VARCHAR2(40);
  v_lbl_jobs            VARCHAR2(100);
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF rtrim(p_cod_ext_produto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP do tipo de produto é obrigatório (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_cod_ext_produto) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código SAP do tipo de produto não pode ter mais que 20 caracteres (' ||
                 p_cod_ext_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do tipo de produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do tipo de produto não pode ter mais que 60 caracteres (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  v_nome := TRIM(p_nome);
  --
  -- O nome do tipo de produto não pode conter pipe ou ponto-e-vírgula.
  -- faz a substituicao
  v_nome := REPLACE(v_nome, '|', '-');
  v_nome := REPLACE(v_nome, ';', ',');
  --
  /* IF p_categoria IS NULL THEN
   v_categoria := 'ND';
  ELSE
   v_categoria := p_categoria;
  END IF;*/
  --
  IF util_pkg.desc_retornar('categoria_tipo_prod', v_categoria_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Categoria do produto inválida (' || v_categoria_id || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido (' || p_flag_ativo || ').';
   RAISE v_exception;
  END IF;
  --
  -- tenta localizar o produto pelo codigo externo
  SELECT MAX(tipo_produto_id)
    INTO v_tipo_produto_id
    FROM tipo_produto
   WHERE empresa_id = p_empresa_id
     AND cod_ext_produto = p_cod_ext_produto;
  --
  IF v_tipo_produto_id IS NULL THEN
   -- tenta localizar pelo nome
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_id
     FROM tipo_produto
    WHERE empresa_id = p_empresa_id
      AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome));
   --
   IF v_tipo_produto_id IS NOT NULL THEN
    -- verifica se o produto ja tem codigo SAP
    SELECT TRIM(cod_ext_produto)
      INTO v_cod_ext_produto_aux
      FROM tipo_produto
     WHERE tipo_produto_id = v_tipo_produto_id;
    --
    IF v_cod_ext_produto_aux IS NOT NULL AND v_cod_ext_produto_aux <> p_cod_ext_produto THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Produto recebido com código ' || p_cod_ext_produto ||
                   ' já se encontra cadastrado com outro código (' || v_cod_ext_produto_aux || ').';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - nao eh exclusao
  ------------------------------------------------------------
  IF p_operacao IN ('INCLUIR', 'ALTERAR') THEN
   IF v_tipo_produto_id IS NOT NULL THEN
    -- produto ja existe no JobOne. Atualiza o registro
    v_cod_evento := 'ALTERAR';
    --
    SELECT flag_sistema
      INTO v_flag_sistema
      FROM tipo_produto
     WHERE tipo_produto_id = v_tipo_produto_id;
    --
    IF v_flag_sistema = 'S' THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser alterado (' || v_nome || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_produto
     WHERE empresa_id = p_empresa_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome))
       AND tipo_produto_id <> v_tipo_produto_id;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe outro tipo de produto com o mesmo nome (' || v_nome || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE tipo_produto
       SET nome            = TRIM(v_nome),
           cod_ext_produto = p_cod_ext_produto,
           categoria_id    = v_categoria_id,
           flag_ativo      = p_flag_ativo
     WHERE tipo_produto_id = v_tipo_produto_id;
   ELSE
    -- produto nao existe no JobOne. Cria o registro
    v_cod_evento := 'INCLUIR';
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_produto
     WHERE empresa_id = p_empresa_id
       AND TRIM(acento_retirar(nome)) = TRIM(acento_retirar(v_nome));
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe outro tipo de produto com o mesmo nome (' || v_nome || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT seq_tipo_produto.nextval
      INTO v_tipo_produto_id
      FROM dual;
    --
    INSERT INTO tipo_produto
     (empresa_id,
      tipo_produto_id,
      nome,
      cod_ext_produto,
      flag_ativo,
      flag_sistema,
      categoria_id)
    VALUES
     (p_empresa_id,
      v_tipo_produto_id,
      TRIM(v_nome),
      p_cod_ext_produto,
      p_flag_ativo,
      'N',
      v_categoria_id);
   END IF;
  END IF; -- fim do IF p_operacao IN ('INCLUIR','ALTERAR')
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_produto_pkg.xml_gerar(v_tipo_produto_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - exclusao
  ------------------------------------------------------------
  IF p_operacao = 'EXCLUIR' THEN
   v_cod_evento := 'EXCLUIR';
   --
   IF v_tipo_produto_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável a ser excluído não encontrado (' || p_cod_ext_produto || ' - ' ||
                  v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de produto está sendo referenciado por algum item (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de produto está sendo referenciado por Workflow ou Task (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_sistema
     INTO v_flag_sistema
     FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   IF v_flag_sistema = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável pertencente ao sistema não pode ser excluído (' || v_nome || ').';
    RAISE v_exception;
   END IF;
   --
   --
   DELETE FROM metadado
    WHERE objeto_id = v_tipo_produto_id
      AND tipo_objeto = 'TIPO_PRODUTO'
      AND empresa_id = p_empresa_id;
   --
   DELETE FROM tipo_prod_tipo_os
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   DELETE FROM tipo_produto_var
    WHERE tipo_produto_id = v_tipo_produto_id;
   --
   DELETE FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Integração SAP';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_PRODUTO',
                   v_cod_evento,
                   v_identif_objeto,
                   v_tipo_produto_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  p_tipo_produto_id := v_tipo_produto_id;
  p_erro_cod        := '00000';
  p_erro_msg        := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END tipo_produto_atualizar;
 --
 --
 --
 PROCEDURE ordem_servico_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/04/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/02/2014  O solicitante_id passou para a tabela os_usuario
  -- Silvia            13/10/2020  Mudanca no prefixo do job
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_xml_conteudo    xmltype;
  v_xml_out         CLOB;
  v_xml_in          CLOB;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_cod_ext_resp    empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_nome_empresa    empresa.nome%TYPE;
  v_nome_cliente    pessoa.nome%TYPE;
  v_nome_emp_resp   pessoa.nome%TYPE;
  v_contato         pessoa.nome%TYPE;
  v_cliente_id      pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa  pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id          job.job_id%TYPE;
  v_emp_resp_id     job.emp_resp_id%TYPE;
  v_num_job         job.numero%TYPE;
  v_nome_job        job.nome%TYPE;
  v_data_prev_ini   job.data_prev_ini%TYPE;
  v_data_prev_fim   job.data_prev_fim%TYPE;
  v_nome_produto    produto_cliente.nome%TYPE;
  v_cod_ext_produto produto_cliente.cod_ext_produto%TYPE;
  v_num_os          VARCHAR2(50);
  v_nome_os         ordem_servico.descricao%TYPE;
  v_data_entrada    ordem_servico.data_entrada%TYPE;
  v_data_solicitada ordem_servico.data_solicitada%TYPE;
  v_data_interna    ordem_servico.data_interna%TYPE;
  v_cod_hash        ordem_servico.cod_hash%TYPE;
  v_cod_tipo_os     tipo_os.codigo%TYPE;
  v_cod_ext_tipo_os tipo_os.cod_ext_tipo_os%TYPE;
  v_tipo_custo      tipo_financeiro.tipo_custo%TYPE;
  v_cod_tipo_finan  tipo_financeiro.codigo%TYPE;
  v_responsavel     usuario.login%TYPE;
  v_data_ini        DATE;
  v_data_fim        DATE;
  v_data_conc       DATE;
  v_prefixo         VARCHAR2(10);
  v_data_ini_char   VARCHAR2(40);
  v_data_fim_char   VARCHAR2(40);
  v_data_conc_char  VARCHAR2(40);
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  SELECT cl.pessoa_id,
         cl.nome,
         jo.job_id,
         jo.numero,
         jo.nome,
         jo.data_prev_ini,
         jo.data_prev_fim,
         pc.nome,
         pc.cod_ext_produto,
         ordem_servico_pkg.numero_formatar(os.ordem_servico_id),
         os.descricao,
         os.data_entrada,
         os.data_solicitada,
         os.data_interna,
         os.cod_hash,
         ordem_servico_pkg.data_retornar(os.ordem_servico_id, 'CONC'),
         ti.codigo,
         ti.cod_ext_tipo_os,
         tf.tipo_custo,
         jo.emp_resp_id,
         re.nome,
         co.nome
    INTO v_cliente_id,
         v_nome_cliente,
         v_job_id,
         v_num_job,
         v_nome_job,
         v_data_prev_ini,
         v_data_prev_fim,
         v_nome_produto,
         v_cod_ext_produto,
         v_num_os,
         v_nome_os,
         v_data_entrada,
         v_data_solicitada,
         v_data_interna,
         v_cod_hash,
         v_data_conc,
         v_cod_tipo_os,
         v_cod_ext_tipo_os,
         v_tipo_custo,
         v_emp_resp_id,
         v_nome_emp_resp,
         v_contato
    FROM ordem_servico   os,
         pessoa          cl,
         pessoa          co,
         job             jo,
         produto_cliente pc,
         tipo_os         ti,
         tipo_financeiro tf,
         pessoa          re
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.cliente_id = cl.pessoa_id
     AND jo.emp_resp_id = re.pessoa_id
     AND os.tipo_os_id = ti.tipo_os_id
     AND jo.produto_cliente_id = pc.produto_cliente_id(+)
     AND os.tipo_financeiro_id = tf.tipo_financeiro_id(+)
     AND jo.contato_id = co.pessoa_id(+);
  --
  -- recupera um dos solicitantes
  SELECT MAX(us.login)
    INTO v_responsavel
    FROM os_usuario os,
         usuario    us
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_ender = 'SOL'
     AND os.usuario_id = us.usuario_id;
  --
  -- recupera o tipo financeiro do job
  SELECT MAX(tf.codigo)
    INTO v_cod_tipo_finan
    FROM job             jo,
         tipo_financeiro tf
   WHERE jo.job_id = v_job_id
     AND jo.tipo_financeiro_id = tf.tipo_financeiro_id(+);
  --
  IF v_cod_tipo_finan = 'TSH' THEN
   -- pula o processamento. Esse tipo de job nao eh integrado
   RAISE v_saida;
  END IF;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_resp IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa responsável não definido (' || v_nome_emp_resp || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente ainda não está integrado (' || v_nome_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_produto IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto de cliente ainda não está integrado (' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_tipo_os IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo não especificado para esse tipo de Entrega (' || v_nome_os || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := v_data_entrada;
  --
  IF v_data_interna IS NOT NULL THEN
   v_data_fim := v_data_interna;
  ELSE
   v_data_fim := v_data_solicitada;
  END IF;
  --
  IF v_data_ini IS NOT NULL THEN
   v_data_ini_char := to_char(v_data_ini, 'yyyy-mm-dd') || 'T' || to_char(v_data_ini, 'hh24:mi:ss');
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada da Entrega não definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_fim IS NOT NULL THEN
   v_data_fim_char := to_char(v_data_fim, 'yyyy-mm-dd') || 'T' || to_char(v_data_fim, 'hh24:mi:ss');
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo final da Entrega não definido.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_conc IS NOT NULL THEN
   v_data_conc_char := to_char(v_data_conc, 'yyyy-mm-dd') || 'T' ||
                       to_char(v_data_conc, 'hh24:mi:ss');
  END IF;
  --
  IF v_cod_ext_empresa = 'BR60' THEN
   -- para E/OU, usa como prefixo o codigo da empresa resp pelo job
   v_prefixo := v_cod_ext_resp || '.';
  ELSE
   v_prefixo := v_cod_ext_empresa || '.';
  END IF;
  --
  v_num_os  := REPLACE(v_prefixo || v_num_os, '-', '');
  v_num_job := v_prefixo || v_num_job;
  --
  /*
    v_nome_os := CONVERT(v_nome_os,v_charset_sisext,v_charset_jobone);
    v_responsavel := CONVERT(v_responsavel,v_charset_sisext,v_charset_jobone);
  */
  --
  v_nome_os := upper(acento_retirar(v_nome_os));
  v_contato := upper(acento_retirar(v_contato));
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("ord:mt_req_ordeninterna",
                           --XMLElement("IM_MYOFFICE_JOB",
                           xmlelement("CompayCode", v_cod_ext_resp),
                           xmlelement("JobName", v_num_os),
                           xmlelement("JobDescription", v_nome_os),
                           xmlelement("ClientCode", v_cod_ext_pessoa),
                           xmlelement("ProductCode", v_cod_ext_produto),
                           xmlelement("ParentJob", v_num_job),
                           xmlelement("EstimatedStartDate", NULL),
                           xmlelement("EstimatedEndDate", NULL),
                           --XMLElement("EstimatedStartDate", v_data_ini_char),
                           --XMLElement("EstimatedEndDate", v_data_fim_char),
                           xmlelement("AccountExecutiveName", v_responsavel),
                           xmlelement("ProductionSpecification", v_cod_hash),
                           xmlelement("ClosingDate", v_data_conc_char),
                           xmlelement("JobType", v_cod_tipo_os),
                           xmlelement("CostType", v_tipo_custo),
                           xmlelement("ClientContactRequester", v_contato),
                           xmlelement("JobDivision", v_cod_ext_tipo_os)))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- NAO acrescenta o tipo de documento, apenas converte
  SELECT v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  sap_executar(p_sistema_externo_id,
               p_empresa_id,
               'ORDEM_SERVICO',
               p_cod_acao,
               p_ordem_servico_id,
               v_xml_in,
               v_xml_out,
               p_erro_cod,
               p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE ordem_servico
     SET cod_ext_os = v_num_os
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END ordem_servico_integrar;
 --
 --
 PROCEDURE job_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/04/2013
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/11/2016  Envio do contato do cliente
  -- Silvia            13/10/2020  Mudanca no prefixo do job
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_xml_conteudo    xmltype;
  v_xml_out         CLOB;
  v_xml_in          CLOB;
  v_cod_ext_empresa empresa_sist_ext.cod_ext_empresa%TYPE;
  v_cod_ext_resp    empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_nome_empresa    empresa.nome%TYPE;
  v_nome_cliente    pessoa.nome%TYPE;
  v_nome_emp_resp   pessoa.nome%TYPE;
  v_contato         pessoa.nome%TYPE;
  v_cliente_id      pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa  pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id          job.job_id%TYPE;
  v_num_job         job.numero%TYPE;
  v_nome_job        job.nome%TYPE;
  v_status_job      job.status%TYPE;
  v_data_status     job.data_status%TYPE;
  v_data_prev_ini   job.data_prev_ini%TYPE;
  v_data_prev_fim   job.data_prev_fim%TYPE;
  v_cod_ext_job     job.cod_ext_job%TYPE;
  v_emp_resp_id     job.emp_resp_id%TYPE;
  v_nome_produto    produto_cliente.nome%TYPE;
  v_cod_ext_produto produto_cliente.cod_ext_produto%TYPE;
  v_tipo_custo      tipo_financeiro.tipo_custo%TYPE;
  v_cod_tipo_finan  tipo_financeiro.codigo%TYPE;
  v_usuario_id      usuario.usuario_id%TYPE;
  v_responsavel     usuario.login%TYPE;
  v_data_conc       DATE;
  v_prefixo         VARCHAR2(10);
  v_data_ini_char   VARCHAR2(40);
  v_data_fim_char   VARCHAR2(40);
  v_data_conc_char  VARCHAR2(40);
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  SELECT cl.pessoa_id,
         cl.nome,
         jo.job_id,
         jo.numero,
         jo.nome,
         jo.data_prev_ini,
         jo.data_prev_fim,
         jo.status,
         jo.data_status,
         jo.cod_ext_job,
         jo.emp_resp_id,
         pc.nome,
         pc.cod_ext_produto,
         tf.tipo_custo,
         tf.codigo,
         re.nome,
         co.nome
    INTO v_cliente_id,
         v_nome_cliente,
         v_job_id,
         v_num_job,
         v_nome_job,
         v_data_prev_ini,
         v_data_prev_fim,
         v_status_job,
         v_data_status,
         v_cod_ext_job,
         v_emp_resp_id,
         v_nome_produto,
         v_cod_ext_produto,
         v_tipo_custo,
         v_cod_tipo_finan,
         v_nome_emp_resp,
         v_contato
    FROM job             jo,
         pessoa          cl,
         pessoa          co,
         produto_cliente pc,
         tipo_financeiro tf,
         pessoa          re
   WHERE jo.job_id = p_job_id
     AND jo.cliente_id = cl.pessoa_id
     AND jo.emp_resp_id = re.pessoa_id
     AND jo.produto_cliente_id = pc.produto_cliente_id(+)
     AND jo.tipo_financeiro_id = tf.tipo_financeiro_id(+)
     AND jo.contato_id = co.pessoa_id(+);
  --
  IF v_cod_tipo_finan = 'TSH' THEN
   -- pula o processamento. Esse tipo de job nao eh integrado
   RAISE v_saida;
  END IF;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_resp IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa responsável não definido (' || v_nome_emp_resp || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente ainda não está integrado (' || v_nome_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_produto IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto de cliente ainda não está integrado (' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  v_usuario_id := job_pkg.usuario_solic_retornar(p_job_id);
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT login
     INTO v_responsavel
     FROM usuario
    WHERE usuario_id = v_usuario_id;
  END IF;
  --
  IF v_status_job = 'CONC' THEN
   v_data_conc := v_data_status;
  END IF;
  --
  IF v_data_prev_ini IS NOT NULL THEN
   v_data_ini_char := to_char(v_data_prev_ini, 'yyyy-mm-dd') || 'T' ||
                      to_char(v_data_prev_ini, 'hh24:mi:ss');
  END IF;
  --
  IF v_data_prev_fim IS NOT NULL THEN
   v_data_fim_char := to_char(v_data_prev_fim, 'yyyy-mm-dd') || 'T' ||
                      to_char(v_data_prev_fim, 'hh24:mi:ss');
  END IF;
  --
  IF v_data_conc IS NOT NULL THEN
   v_data_conc_char := to_char(v_data_conc, 'yyyy-mm-dd') || 'T' ||
                       to_char(v_data_conc, 'hh24:mi:ss');
  END IF;
  --
  IF v_cod_ext_empresa = 'BR60' THEN
   -- para E/OU, usa como prefixo o codigo da empresa resp pelo job
   v_prefixo := v_cod_ext_resp || '.';
  ELSE
   v_prefixo := v_cod_ext_empresa || '.';
  END IF;
  --
  v_num_job := v_prefixo || v_num_job;
  --
  IF v_cod_ext_empresa IN ('BR77', 'BR60') THEN
   -- p/ momentum, retira o string inicial pois a ordem interna no SAP tem
   -- limitacao de tamanho
   v_num_job := substr(v_num_job, 3);
  END IF;
  --
  /*
    v_nome_job := CONVERT(v_nome_job,v_charset_sisext,v_charset_jobone);
    v_responsavel := CONVERT(v_responsavel,v_charset_sisext,v_charset_jobone);
  */
  --
  v_nome_job := upper(acento_retirar(v_nome_job));
  v_contato  := upper(acento_retirar(v_contato));
  --
  ------------------------------------------------------------
  -- monta a secao "conteudo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("ord:mt_req_ordeninterna",
                           --XMLElement("IM_MYOFFICE_JOB",
                           xmlelement("CompayCode", v_cod_ext_resp),
                           xmlelement("JobName", v_num_job),
                           xmlelement("JobDescription", v_nome_job),
                           xmlelement("ClientCode", v_cod_ext_pessoa),
                           xmlelement("ProductCode", v_cod_ext_produto),
                           xmlelement("ParentJob", v_num_job),
                           xmlelement("EstimatedStartDate", NULL),
                           xmlelement("EstimatedEndDate", NULL),
                           --XMLElement("EstimatedStartDate", v_data_ini_char),
                           --XMLElement("EstimatedEndDate", v_data_fim_char),
                           xmlelement("AccountExecutiveName", v_responsavel),
                           xmlelement("ProductionSpecification", NULL),
                           xmlelement("ClosingDate", v_data_conc_char),
                           xmlelement("JobType", NULL),
                           xmlelement("CostType", v_tipo_custo),
                           xmlelement("ClientContactRequester", v_contato),
                           xmlelement("JobDivision", NULL)))
    INTO v_xml_conteudo
    FROM dual;
  --
  -- NAO acrescenta o tipo de documento, apenas converte
  SELECT v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  sap_executar(p_sistema_externo_id,
               p_empresa_id,
               'JOB',
               p_cod_acao,
               p_job_id,
               v_xml_in,
               v_xml_out,
               p_erro_cod,
               p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE job
     SET cod_ext_job = v_num_job
   WHERE job_id = p_job_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END job_integrar;
 --
 --
 --
 PROCEDURE carta_acordo_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 04/12/2014
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de carta acordo(PO).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/03/2018  Recupera job_id do item ao inves da carta.
  -- Silvia            03/10/2019  Inclusao de ExternalAP
  -- Silvia            24/10/2019  Alteracao em AprovalId e ExternalAP p/ BR60
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_carta_acordo_id    IN carta_acordo.carta_acordo_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_xml_conteudo           xmltype;
  v_xml_conteudo_itens     xmltype;
  v_xml_conteudo_itens_aux xmltype;
  v_xml_conteudo_coment    xmltype;
  v_xml_conteudo_errors    xmltype;
  v_xml_out                CLOB;
  v_xml_in                 CLOB;
  v_usuario_emis_id        usuario.usuario_id%TYPE;
  v_cod_ext_usuario        usuario.cod_ext_usuario%TYPE;
  v_login                  usuario.login%TYPE;
  v_cod_ext_empresa        empresa_sist_ext.cod_ext_empresa%TYPE;
  v_cod_ext_emp_resp       empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_cod_ext_emp_fatur      empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_nome_empresa           empresa.nome%TYPE;
  v_nome_fornecedor        pessoa.nome%TYPE;
  v_nome_emp_resp          pessoa.nome%TYPE;
  v_nome_emp_fatur         pessoa.nome%TYPE;
  v_fornecedor_id          pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa         pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_emp_resp_id            job.emp_resp_id%TYPE;
  v_num_job                job.numero%TYPE;
  v_nome_job               job.nome%TYPE;
  v_cod_ext_job            job.cod_ext_job%TYPE;
  v_nome_produto           produto_cliente.nome%TYPE;
  v_cod_ext_produto        produto_cliente.cod_ext_produto%TYPE;
  v_descricao              carta_acordo.desc_item%TYPE;
  v_cod_ext_carta          carta_acordo.cod_ext_carta%TYPE;
  v_emp_faturar_por_id     carta_acordo.emp_faturar_por_id%TYPE;
  v_prefixo                VARCHAR2(10);
  v_num_ap                 VARCHAR2(50);
  v_orcamento_id           orcamento.orcamento_id%TYPE;
  --
  CURSOR c_itn IS
   SELECT it.item_id,
          nvl(SUM(ic.valor_aprovado), 0) AS valor_aprovado,
          tp.cod_ext_produto,
          TRIM(tp.nome || ' ' || it.complemento) AS nome_item,
          tp.nome AS nome_produto
     FROM item_carta   ic,
          item         it,
          tipo_produto tp
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id
      AND nvl(ic.tipo_produto_id, it.tipo_produto_id) = tp.tipo_produto_id
    GROUP BY it.item_id,
             tp.cod_ext_produto,
             tp.nome,
             it.complemento
    ORDER BY it.item_id;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'A', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(it.job_id),
         MAX(it.orcamento_id)
    INTO v_job_id,
         v_orcamento_id
    FROM item       it,
         item_carta ic
   WHERE ic.carta_acordo_id = p_carta_acordo_id
     AND ic.item_id = it.item_id;
  --
  SELECT fo.pessoa_id,
         fo.nome,
         jo.job_id,
         jo.numero,
         jo.nome,
         pc.nome,
         pc.cod_ext_produto,
         jo.emp_resp_id,
         re.nome,
         jo.cod_ext_job,
         ca.desc_item,
         ca.cod_ext_carta,
         ca.emp_faturar_por_id,
         pf.nome
    INTO v_fornecedor_id,
         v_nome_fornecedor,
         v_job_id,
         v_num_job,
         v_nome_job,
         v_nome_produto,
         v_cod_ext_produto,
         v_emp_resp_id,
         v_nome_emp_resp,
         v_cod_ext_job,
         v_descricao,
         v_cod_ext_carta,
         v_emp_faturar_por_id,
         v_nome_emp_fatur
    FROM carta_acordo    ca,
         pessoa          fo,
         job             jo,
         produto_cliente pc,
         pessoa          re,
         pessoa          pf
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND jo.job_id = v_job_id
     AND ca.fornecedor_id = fo.pessoa_id
     AND jo.emp_resp_id = re.pessoa_id
     AND ca.emp_faturar_por_id = pf.pessoa_id
     AND jo.produto_cliente_id = pc.produto_cliente_id(+);
  --
  /* comentado em 03/08/2018 a pedido do Rodrigo Pelvini
    IF pessoa_pkg.tipo_verificar(v_fornecedor_id,'ESTRANGEIRO') = 1 THEN
       -- fornecedor no estrangeiro, pula a integracao
       RAISE v_saida;
    END IF;
  */
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_ext_emp_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  IF v_cod_ext_emp_resp IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa responsável não definido (' || v_nome_emp_resp || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_emp_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_faturar_por_id;
  --
  IF v_cod_ext_emp_fatur IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa de faturamento não definido (' || v_nome_emp_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_fornecedor_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'FORNECEDOR';
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor ainda não está integrado (' || v_nome_fornecedor || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_produto IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto de cliente ainda não está integrado (' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(hi.usuario_id)
    INTO v_usuario_emis_id
    FROM historico   hi,
         evento      ev,
         tipo_objeto tb,
         tipo_acao   ta
   WHERE hi.objeto_id = p_carta_acordo_id
     AND hi.evento_id = ev.evento_id
     AND ev.tipo_objeto_id = tb.tipo_objeto_id
     AND ev.tipo_acao_id = ta.tipo_acao_id
     AND tb.codigo = 'CARTA_ACORDO'
     AND ta.codigo = 'EMITIR';
  --
  IF v_usuario_emis_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário emissor da carta acordo não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT us.cod_ext_usuario,
         us.login
    INTO v_cod_ext_usuario,
         v_login
    FROM usuario us
   WHERE us.usuario_id = v_usuario_emis_id;
  --
  IF v_cod_ext_usuario IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo do usuário não definido (' || v_login || ').';
   RAISE v_exception;
  END IF;
  --
  v_descricao := char_esp_retirar(v_descricao);
  v_descricao := upper(acento_retirar(v_descricao));
  --
  ------------------------------------------------------------
  -- monta a secao "header"
  ------------------------------------------------------------
  IF v_cod_ext_empresa = 'BR60' THEN
   v_num_ap := orcamento_pkg.numero_formatar(v_orcamento_id);
   --
   SELECT xmlagg(xmlelement("Header",
                            xmlelement("CompanyId", v_cod_ext_emp_fatur),
                            xmlelement("ProviderId", v_cod_ext_pessoa),
                            xmlelement("CurrencyId", 'BRL'),
                            xmlelement("TaxRate", '1.0'),
                            xmlelement("IsTaxRateFix", 'X'),
                            xmlelement("ApprovalId", v_num_ap),
                            xmlelement("CustomerProductId", v_cod_ext_produto),
                            xmlelement("InternalOrderId", v_cod_ext_job),
                            xmlelement("RequesterName", v_cod_ext_usuario),
                            xmlelement("ExternalPurcOrderId", to_char(p_carta_acordo_id)),
                            xmlelement("ExternalAP", v_num_job)))
     INTO v_xml_conteudo
     FROM dual;
  ELSE
   v_prefixo := v_cod_ext_empresa || '.';
   v_num_job := v_prefixo || v_num_job;
   --
   v_num_ap := orcamento_pkg.numero_formatar(v_orcamento_id);
   --
   SELECT xmlagg(xmlelement("Header",
                            xmlelement("CompanyId", v_cod_ext_emp_fatur),
                            xmlelement("ProviderId", v_cod_ext_pessoa),
                            xmlelement("CurrencyId", 'BRL'),
                            xmlelement("TaxRate", '1.0'),
                            xmlelement("IsTaxRateFix", 'X'),
                            xmlelement("ApprovalId", v_num_job),
                            xmlelement("CustomerProductId", v_cod_ext_produto),
                            xmlelement("InternalOrderId", v_cod_ext_job),
                            xmlelement("RequesterName", v_cod_ext_usuario),
                            xmlelement("ExternalPurcOrderId", to_char(p_carta_acordo_id)),
                            xmlelement("ExternalAP", v_num_ap)))
     INTO v_xml_conteudo
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "details"
  ------------------------------------------------------------
  FOR r_itn IN c_itn
  LOOP
   IF TRIM(r_itn.cod_ext_produto) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável/Material não se encontra integrado ao SAP (' ||
                  r_itn.nome_produto || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT xmlagg(xmlelement("Itens",
                            xmlelement("MaterialId", r_itn.cod_ext_produto),
                            xmlelement("QuantityValue", '1'),
                            xmlelement("BranchId", v_cod_ext_emp_fatur),
                            xmlelement("GrossValue",
                                       REPLACE(moeda_mostrar(r_itn.valor_aprovado, 'N'), ',', '.'))))
     INTO v_xml_conteudo_itens_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_conteudo_itens, v_xml_conteudo_itens_aux)
     INTO v_xml_conteudo_itens
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("Details", v_xml_conteudo_itens))
    INTO v_xml_conteudo_itens
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "comments"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("Comments", xmlelement("Text", v_descricao)))
    INTO v_xml_conteudo_coment
    FROM dual;
  --
  SELECT xmlagg(xmlelement("Comments", v_xml_conteudo_coment))
    INTO v_xml_conteudo_coment
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "errors"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("error",
                           xmlelement("Type", ''),
                           xmlelement("Id", ''),
                           xmlelement("Number", ''),
                           xmlelement("Message", ''),
                           xmlelement("Log_No", ''),
                           xmlelement("Log_Msg_No", ''),
                           xmlelement("Message_V1", ''),
                           xmlelement("Message_V2", ''),
                           xmlelement("Message_V3", ''),
                           xmlelement("Message_V4", ''),
                           xmlelement("Parameter", ''),
                           xmlelement("Row", ''),
                           xmlelement("Field", ''),
                           xmlelement("System", '')))
    INTO v_xml_conteudo_errors
    FROM dual;
  --
  SELECT xmlagg(xmlelement("SapErrors", v_xml_conteudo_errors))
    INTO v_xml_conteudo_errors
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo
  ------------------------------------------------------------
  SELECT xmlconcat(v_xml_conteudo,
                   v_xml_conteudo_itens,
                   v_xml_conteudo_coment,
                   v_xml_conteudo_errors)
    INTO v_xml_conteudo
    FROM dual;
  --
  IF p_cod_acao = 'I' THEN
   SELECT xmlagg(xmlelement("pur:mt_req_PurchaseOrder_Jobone",
                            --XMLElement("myof:mstPurchaseOrder_Request",
                            v_xml_conteudo))
     INTO v_xml_conteudo
     FROM dual;
  ELSIF p_cod_acao = 'E' THEN
   --
   SELECT xmlconcat(xmlelement("NumeroPedidoSAP", v_cod_ext_carta), v_xml_conteudo)
     INTO v_xml_conteudo
     FROM dual;
   --
   SELECT xmlagg(xmlelement("pur:mt_req_Cancel_PO_Jobone",
                            --XMLElement("myof:mstPurchaseOrderCancel_Request",
                            v_xml_conteudo))
     INTO v_xml_conteudo
     FROM dual;
  END IF;
  --
  -- NAO acrescenta o tipo de documento, apenas converte
  SELECT v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  sap_executar(p_sistema_externo_id,
               p_empresa_id,
               'CARTA_ACORDO',
               p_cod_acao,
               p_carta_acordo_id,
               v_xml_in,
               v_xml_out,
               p_erro_cod,
               p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   v_cod_ext_carta := NULL;
   --
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out, '/Envelope/Body/mt_resp_PurchaseOrder_Jobone/NumeroPedidoSAP'))
     INTO v_cod_ext_carta
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_carta) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código SAP da carta acordo. ' || v_xml_out;
    RAISE v_exception;
   END IF;
   --
   UPDATE carta_acordo
      SET cod_ext_carta = TRIM(v_cod_ext_carta)
    WHERE carta_acordo_id = p_carta_acordo_id;
  END IF;
  --
  /*
    IF p_cod_acao <> 'E' THEN
       -- marca a carta acordo como integrada, aguardando o retorno
       -- do codigo do pedido no SAP
       UPDATE carta_acordo
          SET cod_ext_carta = 'PEND'
        WHERE carta_acordo_id = p_carta_acordo_id;
    END IF;
  */
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END carta_acordo_integrar;
 --
 --
 PROCEDURE carta_acordo_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 17/12/2014
  -- DESCRICAO: Procedure que trata o recebimento de informacoes do SAP referentes a
  --  integração de carta_acordo (recebe o número do pedido no SAP).
  --       **** OBSOLETA ****
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_cod_emp_sap     IN VARCHAR2,
  p_carta_acordo_id IN VARCHAR2,
  p_cod_ext_carta   IN VARCHAR2,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_sistema_externo_id sistema_externo.sistema_externo_id%TYPE;
  v_usuario_sessao_id  usuario.usuario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_empresa_aux_id     empresa.empresa_id%TYPE;
  v_carta_acordo_id    carta_acordo.carta_acordo_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE codigo = 'SAP_WMCCANN';
  --
  IF v_sistema_externo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Sistema externo não encontrado (SAP_WMCCANN).';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_sessao_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_sessao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(empresa_id)
    INTO v_empresa_id
    FROM empresa_sist_ext
   WHERE cod_ext_empresa = p_cod_emp_sap
     AND sistema_externo_id = v_sistema_externo_id;
  --
  IF v_empresa_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da empresa não encontrado (' || p_cod_emp_sap || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencias e atualizacao do banco
  ------------------------------------------------------------
  IF inteiro_validar(p_carta_acordo_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Identificador da carta acordo inválido (' || p_carta_acordo_id || ').';
   RAISE v_exception;
  END IF;
  --
  v_carta_acordo_id := nvl(to_number(p_carta_acordo_id), 0);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Carta acordo não encontrada (' || p_carta_acordo_id || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT fo.empresa_id
    INTO v_empresa_aux_id
    FROM carta_acordo ca,
         pessoa       fo
   WHERE ca.carta_acordo_id = v_carta_acordo_id
     AND ca.fornecedor_id = fo.pessoa_id;
  --
  IF v_empresa_id <> v_empresa_aux_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse pedido/carta acordo não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_ext_carta) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do pedido no SAP não foi informado.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_carta)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do pedido no SAP não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  UPDATE carta_acordo
     SET cod_ext_carta = p_cod_ext_carta
   WHERE carta_acordo_id = v_carta_acordo_id;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'JobOne: erro na integração de carta acordo. ' || p_erro_msg;
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'JobOne: erro na integração de carta acordo. ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
   ROLLBACK;
 END carta_acordo_processar;
 --
 --
 --
 PROCEDURE faturamento_integrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/02/2015
  -- DESCRICAO: Subrotina que gera o xml de envio e executa a integracao de faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/02/2018  Novas naturezas ZVPI-TER e ZVAE-TER
  -- Silvia            25/05/2018  Novas naturezas p/ E/OU
  -- Silvia            11/04/2019  Ajuste no tamanho do comentario enviado.
  --                               Envio da ordem_compra.
  -- Silvia            28/05/2019  Ajustes para faturamento de contrato.
  -- Silvia            24/10/2019  Alteracao em AP e NumeroOrcamento p/ BR60
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_cod_acao           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_saida               EXCEPTION;
  v_xml_conteudo        xmltype;
  v_xml_conteudo_itens  xmltype;
  v_xml_comentario      xmltype;
  v_xml_comentario_aux  xmltype;
  v_xml_conteudo_errors xmltype;
  v_xml_out             CLOB;
  v_xml_in              CLOB;
  v_cod_ext_empresa     empresa_sist_ext.cod_ext_empresa%TYPE;
  v_cod_ext_emp_fatur   empr_fatur_sist_ext.cod_ext_fatur%TYPE;
  v_nome_empresa        empresa.nome%TYPE;
  v_nome_cliente        pessoa.nome%TYPE;
  v_nome_emp_fatur      pessoa.nome%TYPE;
  v_cliente_id          pessoa.pessoa_id%TYPE;
  v_cod_ext_pessoa      pessoa_sist_ext.cod_ext_pessoa%TYPE;
  v_job_id              job.job_id%TYPE;
  v_num_job             job.numero%TYPE;
  v_nome_job            job.nome%TYPE;
  v_cod_ext_job         job.cod_ext_job%TYPE;
  v_orcamento_id        orcamento.orcamento_id%TYPE;
  v_num_orcamento       VARCHAR2(100);
  v_nome_produto        produto_cliente.nome%TYPE;
  v_cod_ext_produto     produto_cliente.cod_ext_produto%TYPE;
  v_descricao           VARCHAR2(8000);
  v_data_vencim         faturamento.data_vencim%TYPE;
  v_cod_natureza_oper   faturamento.cod_natureza_oper%TYPE;
  v_cod_ext_fatur       faturamento.cod_ext_fatur%TYPE;
  v_emp_faturar_por_id  faturamento.emp_faturar_por_id%TYPE;
  v_ordem_compra        faturamento.ordem_compra%TYPE;
  v_cod_ext_material    tipo_produto.cod_ext_produto%TYPE;
  v_nome_material       tipo_produto.nome%TYPE;
  v_contrato_id         contrato.contrato_id%TYPE;
  v_num_contrato        VARCHAR2(100);
  v_valor_fatura        NUMBER;
  v_valor_fat_custo     NUMBER;
  v_valor_fat_custo_eou NUMBER;
  v_valor_fat_honor     NUMBER;
  v_perc_honor          NUMBER;
  v_valor_comissao      NUMBER;
  v_valor_custo_interno NUMBER;
  v_valor_custo         NUMBER;
  v_prefixo             VARCHAR2(10);
  v_comentario1         VARCHAR2(200);
  v_comentario2         VARCHAR2(200);
  v_comentario3         VARCHAR2(200);
  v_comentario4         VARCHAR2(200);
  v_comentario5         VARCHAR2(200);
  v_comentario6         VARCHAR2(200);
  v_comentario7         VARCHAR2(200);
  v_cod_material        VARCHAR2(30);
  v_cod_setor           VARCHAR2(20);
  v_cod_motivo          VARCHAR2(20);
  v_tipo_fatur          VARCHAR2(20);
  v_num_ap              VARCHAR2(50);
  v_flag_int_com        VARCHAR2(5);
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  IF TRIM(p_cod_acao) IS NULL OR p_cod_acao NOT IN ('I', 'E') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(es.cod_ext_empresa),
         MAX(em.nome)
    INTO v_cod_ext_empresa,
         v_nome_empresa
    FROM empresa          em,
         empresa_sist_ext es
   WHERE es.empresa_id = p_empresa_id
     AND es.sistema_externo_id = p_sistema_externo_id
     AND es.empresa_id = em.empresa_id;
  --
  IF v_cod_ext_empresa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa não definido (' || v_nome_empresa || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur := 'JOB';
  --
  -- verifica se eh faturamento de job
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE faturamento_id = p_faturamento_id;
  --
  IF v_qt = 0 THEN
   -- verifia se eh faturamento de contrato
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = p_faturamento_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Faturamento a ser integrado não encontrado (' || to_char(p_faturamento_id) || ').';
    RAISE v_exception;
   END IF;
   --
   v_tipo_fatur := 'CONTRATO';
  END IF;
  --
  IF v_tipo_fatur = 'JOB' THEN
   -- tratamento para faturamento de JOB
   SELECT cl.pessoa_id,
          cl.nome,
          jo.job_id,
          jo.numero,
          jo.nome,
          pc.nome,
          pc.cod_ext_produto,
          jo.cod_ext_job,
          fa.descricao,
          fa.data_vencim,
          fa.cod_natureza_oper,
          fa.emp_faturar_por_id,
          pf.nome,
          fa.ordem_compra
     INTO v_cliente_id,
          v_nome_cliente,
          v_job_id,
          v_num_job,
          v_nome_job,
          v_nome_produto,
          v_cod_ext_produto,
          v_cod_ext_job,
          v_descricao,
          v_data_vencim,
          v_cod_natureza_oper,
          v_emp_faturar_por_id,
          v_nome_emp_fatur,
          v_ordem_compra
     FROM faturamento     fa,
          pessoa          cl,
          job             jo,
          produto_cliente pc,
          pessoa          pf
    WHERE fa.faturamento_id = p_faturamento_id
      AND fa.job_id = jo.job_id
      AND fa.cliente_id = cl.pessoa_id
      AND fa.emp_faturar_por_id = pf.pessoa_id
      AND nvl(fa.produto_cliente_id, jo.produto_cliente_id) = pc.produto_cliente_id;
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM item_fatur
    WHERE faturamento_id = p_faturamento_id;
   --
   -- o custo engloba os encargos (so ficam de fora os honorarios)
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fat_custo
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.natureza_item <> 'HONOR';
   --
   -- para a E/OU, o custo nao engloba os encargos (custo puro)
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fat_custo_eou
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.natureza_item = 'CUSTO';
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fat_honor
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.natureza_item = 'HONOR';
   --
   SELECT MIN(it.orcamento_id),
          MIN(tp.cod_ext_produto)
     INTO v_orcamento_id,
          v_cod_ext_material
     FROM item_fatur   ia,
          item         it,
          tipo_produto tp
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id;
   --
   v_num_orcamento := orcamento_pkg.numero_formatar(v_orcamento_id);
  ELSE
   -- tratamento para faturamento de CONTRATO
   SELECT cl.pessoa_id,
          cl.nome,
          ct.contrato_id,
          contrato_pkg.numero_formatar(ct.contrato_id),
          fa.descricao,
          fa.data_vencim,
          fa.cod_natureza_oper,
          fa.emp_faturar_por_id,
          pf.nome,
          fa.ordem_compra
     INTO v_cliente_id,
          v_nome_cliente,
          v_contrato_id,
          v_num_contrato,
          v_descricao,
          v_data_vencim,
          v_cod_natureza_oper,
          v_emp_faturar_por_id,
          v_nome_emp_fatur,
          v_ordem_compra
     FROM faturamento_ctr fa,
          pessoa          cl,
          pessoa          pf,
          contrato        ct
    WHERE fa.faturamento_ctr_id = p_faturamento_id
      AND fa.contrato_id = ct.contrato_id
      AND fa.cliente_id = cl.pessoa_id
      AND fa.emp_faturar_por_id = pf.pessoa_id;
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_fatura
     FROM parcela_fatur_ctr
    WHERE faturamento_ctr_id = p_faturamento_id;
   --
   v_valor_fat_custo := v_valor_fatura;
   v_nome_produto    := 'INSTITUCIONAL';
   v_nome_material   := 'FEE';
   --
   SELECT MAX(cod_ext_produto)
     INTO v_cod_ext_produto
     FROM produto_cliente
    WHERE pessoa_id = v_cliente_id
      AND upper(nome) = v_nome_produto;
   --
   SELECT MAX(tp.cod_ext_produto)
     INTO v_cod_ext_material
     FROM tipo_produto tp
    WHERE empresa_id = p_empresa_id
      AND upper(nome) = v_nome_material;
  END IF;
  --
  SELECT MAX(cod_ext_fatur)
    INTO v_cod_ext_emp_fatur
    FROM empr_fatur_sist_ext
   WHERE sistema_externo_id = p_sistema_externo_id
     AND pessoa_id = v_emp_faturar_por_id;
  --
  IF v_cod_ext_emp_fatur IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código externo da empresa de faturamento não definido (' || v_nome_emp_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(ps.cod_ext_pessoa)
    INTO v_cod_ext_pessoa
    FROM pessoa_sist_ext ps,
         tipo_pessoa     tp
   WHERE ps.sistema_externo_id = p_sistema_externo_id
     AND ps.pessoa_id = v_cliente_id
     AND ps.tipo_pessoa_id = tp.tipo_pessoa_id
     AND tp.codigo = 'CLIENTE';
  --
  IF v_cod_ext_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente ainda não está integrado (' || v_nome_cliente || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_produto IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto do cliente ainda não está integrado (' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  -- consistencia p/ a E/OU
  IF v_cod_natureza_oper LIKE 'ZVPD%' AND v_tipo_fatur = 'JOB' THEN
   -- verifica se o faturamento tem natureza de CUSTO
   SELECT COUNT(*)
     INTO v_qt
     FROM item_fatur    ia,
          item          it,
          tipo_produto  tp,
          natureza_item ni
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id
         --AND tp.cod_ext_produto IS NOT NULL
      AND it.natureza_item = ni.codigo
      AND ni.empresa_id = tp.empresa_id
      AND ni.tipo = 'CUSTO';
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nenhum item de CUSTO foi encontrado nesse faturamento ' ||
                  '(não existe material para enviar ao SAP).';
    RAISE v_exception;
   END IF;
   --
   -- procura produto envolvido no faturamento sem codigo externo
   SELECT MAX(tp.nome)
     INTO v_nome_material
     FROM item_fatur    ia,
          item          it,
          tipo_produto  tp,
          natureza_item ni
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id
      AND tp.cod_ext_produto IS NULL
      AND it.natureza_item = ni.codigo
      AND ni.empresa_id = tp.empresa_id
      AND ni.tipo = 'CUSTO';
   --
   IF v_nome_material IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tipo de produto (material) não está integrado ao SAP (' || v_nome_material || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(tp.nome)
     INTO v_nome_material
     FROM item_fatur   ia,
          item         it,
          tipo_produto tp
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id
      AND tp.cod_ext_produto <> v_cod_ext_material;
   --
   IF v_nome_material IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse faturamento está agrupando tipos de produto com códigos SAP distintos.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --
  IF v_cod_ext_material IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de produto (material) não está integrado ao SAP (' || v_nome_material || ').';
   RAISE v_exception;
  END IF;
  --
  v_descricao := char_esp_retirar(v_descricao);
  v_descricao := upper(acento_retirar(v_descricao));
  --
  v_valor_comissao      := 0;
  v_valor_custo_interno := 0;
  v_valor_custo         := 0;
  v_perc_honor          := 0;
  --
  IF v_cod_natureza_oper IN ('ZVFE', 'BV', 'ZVSP', 'ZVPD-FEE') THEN
   -- FEE, BV
   v_valor_comissao := v_valor_fatura;
  ELSIF v_cod_natureza_oper IN ('ZVMI') THEN
   -- repasse
   v_valor_custo    := v_valor_fat_custo;
   v_valor_comissao := v_valor_fat_honor;
   --
   IF v_valor_custo > 0 THEN
    v_perc_honor := round(v_valor_comissao / v_valor_custo * 100, 4);
   END IF;
   --
   /* calculo de percentual que faz o total bater nos dois sistemas
   IF v_valor_custo > 0 THEN
      v_perc_honor := ROUND(v_valor_comissao/v_valor_custo*100,2);
      --
      -- recalcula o valor da comissao depois do arredondamento do perc
      v_valor_custo := ROUND(v_valor_fatura * 100 / (100 + v_perc_honor),2);
      v_valor_comissao := v_valor_fatura - v_valor_comissao;
   END IF;
   */
  ELSIF v_cod_natureza_oper IN ('ZVPD-ORC') THEN
   -- repasse (calculo diferenciado para a E/OU)
   v_valor_custo    := v_valor_fat_custo_eou;
   v_valor_comissao := v_valor_fatura - v_valor_fat_custo_eou;
   --
   IF v_valor_custo > 0 THEN
    v_perc_honor := round(v_valor_comissao / v_valor_custo * 100, 4);
   END IF;
   --
   /* calculo de percentual que faz o total bater nos dois sistemas
   IF v_valor_custo > 0 THEN
      v_perc_honor := ROUND(v_valor_comissao/v_valor_custo*100,2);
      --
      -- recalcula o valor da comissao depois do arredondamento do perc
      v_valor_custo := ROUND(v_valor_fatura * 100 / (100 + v_perc_honor),2);
      v_valor_comissao := v_valor_fatura - v_valor_custo;
   END IF;
   */
  ELSIF v_cod_natureza_oper IN ('ZVPI-TER', 'ZVAE-TER', 'ZVPD-TER') THEN
   -- custo terceiros
   v_valor_custo := v_valor_fat_custo;
  ELSE
   -- demais vao como interno
   v_valor_custo_interno := v_valor_fatura;
  END IF;
  --
  v_flag_int_com := 'N';
  --
  -- codigos ZVPI,ZVFE,ZVAE,ZVAE-IMP,ZVSP,ZVMI,ZVPI-TER,ZVAE-TER
  -- usados pela Momentum
  IF v_cod_natureza_oper = 'ZVPI' THEN
   v_cod_material := 'MO-FT0001';
   v_cod_setor    := 'PE';
   v_cod_motivo   := 'P77';
  ELSIF v_cod_natureza_oper = 'ZVFE' THEN
   v_cod_material := 'MO-FT0002';
   v_cod_setor    := 'PE';
   v_cod_motivo   := 'P05';
  ELSIF v_cod_natureza_oper = 'ZVAE' THEN
   v_cod_material := 'MO-FT0004';
   v_cod_setor    := 'AE';
   v_cod_motivo   := 'P78';
  ELSIF v_cod_natureza_oper = 'ZVAE-IMP' THEN
   v_cod_natureza_oper := 'ZVAE';
   v_cod_material      := 'MO-FT9999';
   v_cod_setor         := 'AE';
   v_cod_motivo        := 'P78';
  ELSIF v_cod_natureza_oper IN ('BV', 'ZVSP') THEN
   v_cod_material      := 'MO-FT0003';
   v_cod_setor         := 'PE';
   v_cod_motivo        := 'G01';
   v_cod_natureza_oper := 'ZVSP';
  ELSIF v_cod_natureza_oper = 'ZVMI' THEN
   -- alterado em 10/05/2018
   -- v_cod_material := 'MO-FT0001';
   v_cod_material := 'MO-FT0007';
   v_cod_setor    := 'PE';
   v_cod_motivo   := 'P80';
  ELSIF v_cod_natureza_oper = 'ZVPI-TER' THEN
   v_cod_material      := 'MO-FT0007';
   v_cod_setor         := 'PE';
   v_cod_motivo        := 'P07';
   v_cod_natureza_oper := 'ZVPI';
  ELSIF v_cod_natureza_oper = 'ZVAE-TER' THEN
   v_cod_material      := 'MO-FT0008';
   v_cod_setor         := 'AE';
   v_cod_motivo        := 'P07';
   v_cod_natureza_oper := 'ZVAE';
   --
   -- codigos ZVPD-ORC,ZVPD-FEE,ZVPD-ART,ZVPD-TER
   -- usados pela E/ou
  ELSIF v_cod_natureza_oper = 'ZVPD-ORC' THEN
   v_cod_material      := v_cod_ext_material;
   v_cod_setor         := 'MA';
   v_cod_motivo        := 'P03';
   v_cod_natureza_oper := 'ZVPD';
  ELSIF v_cod_natureza_oper = 'ZVPD-FEE' THEN
   v_cod_material      := v_cod_ext_material;
   v_cod_setor         := 'MA';
   v_cod_motivo        := 'P05';
   v_cod_natureza_oper := 'ZVPD';
   v_flag_int_com      := 'S';
  ELSIF v_cod_natureza_oper = 'ZVPD-ART' THEN
   v_cod_material      := v_cod_ext_material;
   v_cod_setor         := 'MA';
   v_cod_motivo        := 'P06';
   v_cod_natureza_oper := 'ZVPD';
   v_flag_int_com      := 'S';
  ELSIF v_cod_natureza_oper = 'ZVPD-TER' THEN
   v_cod_material      := v_cod_ext_material;
   v_cod_setor         := 'MA';
   v_cod_motivo        := 'P07';
   v_cod_natureza_oper := 'ZVPD';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Natureza de faturamento não prevista na integração com o SAP (' ||
                 v_cod_natureza_oper || ').';
   RAISE v_exception;
  END IF;
  --
  /*
    v_comentario1 := SUBSTR(v_descricao,1,100);
    v_comentario2 := SUBSTR(v_descricao,101,100);
    v_comentario3 := SUBSTR(v_descricao,201,100);
    v_comentario4 := SUBSTR(v_descricao,301,100);
    v_comentario5 := SUBSTR(v_descricao,401,100);
    v_comentario6 := SUBSTR(v_descricao,501,100);
    v_comentario7 := SUBSTR(v_descricao,601,100);
  */
  --
  -- apenas 6 linhas com 60 caracteres cada
  v_comentario1 := substr(v_descricao, 1, 60);
  v_comentario2 := substr(v_descricao, 61, 60);
  v_comentario3 := substr(v_descricao, 121, 60);
  v_comentario4 := substr(v_descricao, 181, 60);
  v_comentario5 := substr(v_descricao, 241, 60);
  v_comentario6 := substr(v_descricao, 301, 60);
  --
  ------------------------------------------------------------
  -- monta a secao "header"
  ------------------------------------------------------------
  --
  IF v_tipo_fatur = 'JOB' THEN
   --v_prefixo := v_cod_ext_empresa || '.';
   --v_num_job := v_prefixo || v_num_job;
   --
   v_num_ap := v_num_orcamento;
  ELSE
   v_num_ap := v_num_contrato;
  END IF;
  --
  IF v_num_ap IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do Orcamento ou Ordem de Venda nulo.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_ext_empresa = 'BR60' AND v_tipo_fatur = 'JOB' THEN
   IF v_flag_int_com = 'S' THEN
    -- interno ou comissao. Fica do jeito antigo
    v_num_ap := to_char(p_faturamento_id);
   END IF;
   --
   SELECT xmlagg(xmlelement("Header",
                            xmlelement("OrganizacaoVendas", v_cod_ext_emp_fatur),
                            xmlelement("TipoDocumentoVendas", v_cod_natureza_oper),
                            xmlelement("SetorAtividade", v_cod_setor),
                            xmlelement("Cliente", v_cod_ext_pessoa),
                            xmlelement("Produto", v_cod_ext_produto),
                            xmlelement("MotivoOrdem", v_cod_motivo),
                            xmlelement("MesAnoReferencia", to_char(SYSDATE, 'YYYYMMDD')),
                            xmlelement("Vencimento", to_char(v_data_vencim, 'YYYYMMDD')),
                            xmlelement("AP", v_num_job),
                            xmlelement("NumeroOrdemVenda", v_num_ap)))
     INTO v_xml_conteudo
     FROM dual;
  ELSE
   SELECT xmlagg(xmlelement("Header",
                            xmlelement("OrganizacaoVendas", v_cod_ext_emp_fatur),
                            xmlelement("TipoDocumentoVendas", v_cod_natureza_oper),
                            xmlelement("SetorAtividade", v_cod_setor),
                            xmlelement("Cliente", v_cod_ext_pessoa),
                            xmlelement("Produto", v_cod_ext_produto),
                            xmlelement("MotivoOrdem", v_cod_motivo),
                            xmlelement("MesAnoReferencia", to_char(SYSDATE, 'YYYYMMDD')),
                            xmlelement("Vencimento", to_char(v_data_vencim, 'YYYYMMDD')),
                            xmlelement("AP", v_num_ap),
                            xmlelement("NumeroOrdemVenda", to_char(p_faturamento_id))))
     INTO v_xml_conteudo
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- monta a secao "details"
  ------------------------------------------------------------
  IF v_ordem_compra IS NULL THEN
   v_ordem_compra := v_cod_ext_job;
  END IF;
  --
  SELECT xmlagg(xmlelement("Item",
                           xmlelement("CodigoMaterial", v_cod_material),
                           xmlelement("Quantidade", '1'),
                           xmlelement("ValorCusto",
                                      REPLACE(moeda_mostrar(v_valor_custo, 'N'), ',', '.')),
                           xmlelement("ValorComissao",
                                      REPLACE(moeda_mostrar(v_valor_comissao, 'N'), ',', '.')),
                           xmlelement("PercentualComissao",
                                      REPLACE(numero_mostrar(v_perc_honor, 4, 'N'), ',', '.')),
                           xmlelement("ValorCustoInterno",
                                      REPLACE(moeda_mostrar(v_valor_custo_interno, 'N'), ',', '.')),
                           xmlelement("OrdemInterna", v_ordem_compra)))
    INTO v_xml_conteudo_itens
    FROM dual;
  --
  SELECT xmlagg(xmlelement("Details", v_xml_conteudo_itens))
    INTO v_xml_conteudo_itens
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "comments"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario1)))
    INTO v_xml_comentario
    FROM dual;
  --
  IF v_comentario2 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario2)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  IF v_comentario3 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario3)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  IF v_comentario4 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario4)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  IF v_comentario5 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario5)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  IF v_comentario6 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario6)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  IF v_comentario7 IS NOT NULL THEN
   SELECT xmlagg(xmlelement("comentarios", xmlelement("comentario", v_comentario7)))
     INTO v_xml_comentario_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_comentario, v_xml_comentario_aux)
     INTO v_xml_comentario
     FROM dual;
  END IF;
  --
  SELECT xmlagg(xmlelement("Comments", v_xml_comentario))
    INTO v_xml_comentario
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta a secao "errors"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("error",
                           xmlelement("Type", ''),
                           xmlelement("Id", ''),
                           xmlelement("Number", ''),
                           xmlelement("Message", ''),
                           xmlelement("Log_No", ''),
                           xmlelement("Log_Msg_No", ''),
                           xmlelement("Message_V1", ''),
                           xmlelement("Message_V2", ''),
                           xmlelement("Message_V3", ''),
                           xmlelement("Message_V4", ''),
                           xmlelement("Parameter", ''),
                           xmlelement("Row", ''),
                           xmlelement("Field", ''),
                           xmlelement("System", '')))
    INTO v_xml_conteudo_errors
    FROM dual;
  --
  SELECT xmlagg(xmlelement("SapErrors", v_xml_conteudo_errors))
    INTO v_xml_conteudo_errors
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo
  ------------------------------------------------------------
  SELECT xmlconcat(v_xml_conteudo, v_xml_conteudo_itens, v_xml_comentario, v_xml_conteudo_errors)
    INTO v_xml_conteudo
    FROM dual;
  --
  IF p_cod_acao = 'I' THEN
   SELECT xmlagg(xmlelement("mt_req_SalesOrder_Jobone",
                            --XMLElement("myof:mst_SalesOrder_Request",
                            v_xml_conteudo))
     INTO v_xml_conteudo
     FROM dual;
  ELSIF p_cod_acao = 'E' THEN
   SELECT xmlagg(xmlelement("myof:mt_req_ovcancel_Jobone",
                            --XMLElement("myof:mst_ovcancel_request",
                            v_xml_conteudo))
     INTO v_xml_conteudo
     FROM dual;
  END IF;
  --
  -- NAO acrescenta o tipo de documento, apenas converte
  SELECT v_xml_conteudo.getclobval()
    INTO v_xml_in
    FROM dual;
  --
  ------------------------------------------------------------
  -- chama a procedure de integracao
  ------------------------------------------------------------
  sap_executar(p_sistema_externo_id,
               p_empresa_id,
               'FATURAMENTO',
               p_cod_acao,
               p_faturamento_id,
               v_xml_in,
               v_xml_out,
               p_erro_cod,
               p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao <> 'E' THEN
   v_cod_ext_fatur := NULL;
   --
   -- recupera o codigo externo
   SELECT MAX(extractvalue(xml_out,
                           '/Envelope/Body/mt_resp_SalesOrder_Jobone/SalesOrderDocuments/doc_number'))
     INTO v_cod_ext_fatur
     FROM (SELECT xmltype(v_xml_out) AS xml_out
             FROM dual);
   --
   IF TRIM(v_cod_ext_fatur) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na recuperação do código SAP do faturamento. ' || v_xml_out;
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_fatur = 'JOB' THEN
    UPDATE faturamento
       SET cod_ext_fatur = TRIM(v_cod_ext_fatur)
     WHERE faturamento_id = p_faturamento_id;
   ELSE
    UPDATE faturamento_ctr
       SET cod_ext_fatur = TRIM(v_cod_ext_fatur)
     WHERE faturamento_ctr_id = p_faturamento_id;
   END IF;
  END IF;
  --
  /*
    IF p_cod_acao <> 'E' THEN
       -- marca o faturamento como integrado, aguardando o retorno
       -- do codigo do pedido no SAP
       UPDATE faturamento
          SET cod_ext_fatur = TO_CHAR(p_faturamento_id)
        WHERE faturamento_id = p_faturamento_id;
    END IF;
  */
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END faturamento_integrar;
 --
 --
 --
 PROCEDURE sap_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/05/2013
  -- DESCRICAO: Subrotina que executa a chamada de webservices no sistema SAP.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2017  Novo parametro objeto_id
  ------------------------------------------------------------------------------------------
 (
  p_sistema_externo_id IN sistema_externo.sistema_externo_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cod_objeto         IN VARCHAR2,
  p_cod_acao           IN VARCHAR2,
  p_objeto_id          IN VARCHAR2,
  p_xml_in             IN CLOB,
  p_xml_out            OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_xml_log_id xml_log.xml_log_id%TYPE;
  v_status_ret VARCHAR2(20);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  p_erro_msg := NULL;
  p_xml_out  := NULL;
  --
  IF TRIM(p_cod_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do objeto não foi fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF dbms_lob.getlength(p_xml_in) >= 104000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do XML gerado está com mais de 104000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_xml_log.nextval
    INTO v_xml_log_id
    FROM dual;
  --
  log_gravar(v_xml_log_id, 'JOBONE', 'SAP', p_cod_objeto, p_cod_acao, p_objeto_id, p_xml_in);
  --
  IF p_cod_objeto = 'JOB' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'job_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   --p_xml_out := 'OK';
  ELSIF p_cod_objeto = 'ORDEM_SERVICO' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'ordem_servico_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   --p_xml_out := 'OK';
  ELSIF p_cod_objeto = 'CARTA_ACORDO' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'carta_acordo_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   -- p_xml_out := 'OK';
  ELSIF p_cod_objeto = 'FATURAMENTO' THEN
   webservice_pkg.chamar(p_sistema_externo_id,
                         p_empresa_id,
                         'faturamento_integrar',
                         p_cod_acao,
                         v_xml_log_id,
                         p_xml_out,
                         p_erro_msg);
   --
   -- simula o retorno do webservice
   -- p_xml_out := 'OK';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_erro_msg) IS NOT NULL THEN
   p_erro_cod := '90000';
   RAISE v_exception;
  END IF;
  --
  log_concluir(v_xml_log_id, p_objeto_id, p_xml_out);
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_msg := 'SAP: ' || p_erro_msg;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'SAP - outros: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 2000);
 END sap_executar;
 --
--
END; -- IT_SAP_PKG

/
