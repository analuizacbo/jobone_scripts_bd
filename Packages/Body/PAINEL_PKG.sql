--------------------------------------------------------
--  DDL for Package Body PAINEL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PAINEL_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Inclusão de PAINEL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_autoria           IN VARCHAR2,
  p_versao            IN VARCHAR2,
  p_data_refer        IN VARCHAR2,
  p_contato           IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_origem            IN VARCHAR2,
  p_abertura          IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_painel_id         OUT painel.painel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_painel_id      painel.painel_id%TYPE;
  v_data_refer     painel.data_refer%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt        := 0;
  p_painel_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_autoria)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A autoria não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_versao)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A versão não pode ter mais que 10 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_refer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de referência inválida (' || p_data_refer || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_refer := data_converter(p_data_refer);
  --
  IF length(TRIM(p_contato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto de contato não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_url) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da URL é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_url)) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da URL não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_origem) IS NULL OR p_origem NOT IN ('JOB', 'EXT') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Origem inválida (' || p_origem || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_abertura) IS NULL OR p_abertura NOT IN ('JOB', 'ABA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Abertura inválida (' || p_abertura || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM painel
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de painel já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   UPDATE painel
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id;
  END IF;
  --
  SELECT seq_painel.nextval
    INTO v_painel_id
    FROM dual;
  --
  INSERT INTO painel
   (painel_id,
    empresa_id,
    nome,
    descricao,
    autoria,
    versao,
    data_refer,
    contato,
    url,
    origem,
    abertura,
    flag_padrao,
    flag_ativo)
  VALUES
   (v_painel_id,
    p_empresa_id,
    TRIM(p_nome),
    TRIM(p_descricao),
    TRIM(p_autoria),
    TRIM(p_versao),
    v_data_refer,
    TRIM(p_contato),
    TRIM(p_url),
    TRIM(p_origem),
    TRIM(p_abertura),
    p_flag_padrao,
    p_flag_ativo);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(v_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_painel_id,
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
  p_painel_id := v_painel_id;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Atualização de PAINEL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Rafael            18/06/2025   adicionado novos parametros (p_dash_numero e p_api_key) release_174
  -- Rafael            07/08/2025   adicionado novo parametro de flag_usuario_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_painel_id         IN painel.painel_id%TYPE,
  p_flag_usuario_id   IN VARCHAR2,
  p_nome              IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_autoria           IN VARCHAR2,
  p_versao            IN VARCHAR2,
  p_data_refer        IN VARCHAR2,
  p_contato           IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_origem            IN VARCHAR2,
  p_dash_numero       IN VARCHAR2,
  p_api_key           IN VARCHAR2,
  p_abertura          IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_data_refer        painel.data_refer%TYPE;
  v_flag_usuario_id   painel.flag_usuario_id%TYPE;
  v_dash_numero       painel.dash_numero%TYPE;
  v_xml_antes         CLOB;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM painel
   WHERE painel_id = p_painel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  --
  IF flag_validar(p_flag_usuario_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Passar ID do usuário logado inválido.';
   RAISE v_exception;
  END IF;
  --
  v_flag_usuario_id := TRIM(p_flag_usuario_id);
  -- 
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_descricao)) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_autoria)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A autoria não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_versao)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A versão não pode ter mais que 10 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_refer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de referência inválida (' || p_data_refer || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_refer := data_converter(p_data_refer);
  --
  IF length(TRIM(p_contato)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto de contato não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  --RP_180625
  IF TRIM(p_url) IS NULL OR TRIM(p_url) = '' THEN
   IF TRIM(p_origem) = 'MET' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da METABASE_SITE_URL é obrigatório.';
    RAISE v_exception;
   ELSE
    p_erro_cod := '90001';
    p_erro_msg := 'O preenchimento da URL é obrigatório';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(TRIM(p_url)) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da URL não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_origem) IS NULL OR p_origem NOT IN ('JOB', 'EXT','MET') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Origem inválida (' || p_origem || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_origem) = 'MET' AND p_dash_numero IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do campo Dashboard é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  --RP_180625
  v_dash_numero := nvl(numero_converter(p_dash_numero), 0);
  --
  IF TRIM(p_origem) = 'MET' AND p_api_key IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da METABASE_SECRET_KEY é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_abertura) IS NULL OR p_abertura NOT IN ('JOB', 'ABA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Abertura inválida (' || p_abertura || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM painel
   WHERE painel_id <> p_painel_id
     AND upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de painel já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   UPDATE painel
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id;
  END IF;
  --
  UPDATE painel
     SET nome        = TRIM(p_nome),
         descricao   = TRIM(p_descricao),
         autoria     = TRIM(p_autoria),
         versao      = TRIM(p_versao),
         data_refer  = v_data_refer,
         contato     = TRIM(p_contato),
         url         = TRIM(p_url),
         origem      = TRIM(p_origem),
         abertura    = TRIM(p_abertura),
         flag_padrao = p_flag_padrao,
         flag_ativo  = p_flag_ativo,
         dash_numero = v_dash_numero, --RP_180625
         api_key     = p_api_key,
         flag_usuario_id  = v_flag_usuario_id 
   WHERE painel_id = p_painel_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_painel_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Exclusão de PAINEL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_painel_id         IN painel.painel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           painel.nome%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome
    FROM painel
   WHERE painel_id = p_painel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_painel
   WHERE painel_id = p_painel_id;
  DELETE FROM painel
   WHERE painel_id = p_painel_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_painel_id,
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
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE papel_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Associacao de Papel ao PAINEL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_painel_id         IN painel.painel_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_flag_padrao       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_painel    painel.nome%TYPE;
  v_nome_papel     papel.nome%TYPE;
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
    FROM painel
   WHERE painel_id = p_painel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_painel
    FROM painel
   WHERE painel_id = p_painel_id;
  --
  SELECT nome
    INTO v_nome_papel
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_painel
   WHERE painel_id = p_painel_id
     AND papel_id = p_papel_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel já está associada a esse painel.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   -- desmarca eventual painel ja marcado como padrao para
   -- esse papel.
   UPDATE papel_painel
      SET flag_padrao = 'N'
    WHERE papel_id = p_papel_id;
  END IF;
  --
  INSERT INTO papel_painel
   (painel_id,
    papel_id,
    flag_padrao)
  VALUES
   (p_painel_id,
    p_papel_id,
    p_flag_padrao);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_painel;
  v_compl_histor   := 'Inclusão de papel: ' || v_nome_papel;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_painel_id,
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
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END papel_adicionar;
 --
 --
 PROCEDURE papel_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Exclusao de Papel do PAINEL
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_painel_id         IN painel.painel_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_painel    painel.nome%TYPE;
  v_nome_papel     papel.nome%TYPE;
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
    FROM painel
   WHERE painel_id = p_painel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_painel
    FROM painel
   WHERE painel_id = p_painel_id;
  --
  SELECT nome
    INTO v_nome_papel
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_painel
   WHERE painel_id = p_painel_id
     AND papel_id = p_papel_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não está associada a esse painel.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_painel
   WHERE painel_id = p_painel_id
     AND papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_painel;
  v_compl_histor   := 'Exclusão de papel: ' || v_nome_papel;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_painel_id,
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
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END papel_excluir;
 --
 --
 PROCEDURE padrao_papel_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 19/08/2021
  -- DESCRICAO: Marca/desmarca o PAINEL como padrao do papel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_painel_id         IN painel.painel_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_flag_padrao       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_painel    painel.nome%TYPE;
  v_nome_papel     papel.nome%TYPE;
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
    FROM painel
   WHERE painel_id = p_painel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAINEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_painel
    FROM painel
   WHERE painel_id = p_painel_id;
  --
  SELECT nome
    INTO v_nome_papel
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_painel
   WHERE painel_id = p_painel_id
     AND papel_id = p_papel_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não está associada a esse painel.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   -- desmarca eventual painel ja marcado como padrao para
   -- esse papel.
   UPDATE papel_painel
      SET flag_padrao = 'N'
    WHERE papel_id = p_papel_id;
  END IF;
  --
  UPDATE papel_painel
     SET flag_padrao = p_flag_padrao
   WHERE painel_id = p_painel_id
     AND papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  painel_pkg.xml_gerar(p_painel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_painel;
  v_compl_histor   := 'Papel: ' || v_nome_papel || ' Painel padrão: ' || p_flag_padrao;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAINEL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_painel_id,
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
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END padrao_papel_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/08/2021
  -- DESCRICAO: Subrotina que gera o xml do painel para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_painel_id IN painel.painel_id%TYPE,
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
  CURSOR c_pa IS
   SELECT pa.nome,
          pp.flag_padrao
     FROM papel_painel pp,
          papel        pa
    WHERE pp.painel_id = p_painel_id
      AND pp.papel_id = pa.papel_id
    ORDER BY pa.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("painel_id", painel_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", nome),
                   xmlelement("autoria", autoria),
                   xmlelement("versao", versao),
                   xmlelement("data_refer", data_mostrar(data_refer)),
                   xmlelement("contato", contato),
                   xmlelement("padrao", flag_padrao),
                   xmlelement("ativo", flag_ativo),
                   xmlelement("origem", origem),
                   xmlelement("abertura", abertura))
    INTO v_xml
    FROM painel
   WHERE painel_id = p_painel_id;
  --
  ------------------------------------------------------------
  -- monta EQUIPE
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlagg(xmlelement("papel",
                            xmlelement("nome", r_pa.nome),
                            xmlelement("padrao", r_pa.flag_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("papeis", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "painel"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("painel", v_xml))
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END xml_gerar;
 --
 --
 PROCEDURE cenario_status_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                ProcessMind     DATA: 21/08/2023
  -- DESCRICAO: Alteracao do status de cenário
  --            de uma Oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- --                --          --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_oportunidade_status oportunidade.status%TYPE;
  v_cenario_id          cenario.cenario_id%TYPE;
  v_status_old          cenario.status%TYPE;
  v_status_new          cenario.status%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_num_cenario         cenario.num_cenario%TYPE;
  v_desc_status_old     dicionario.descricao%TYPE;
  v_desc_status_new     dicionario.descricao%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  SELECT o.status,
         o.numero,
         o.empresa_id
    INTO v_oportunidade_status,
         v_oportunidade_numero,
         v_empresa_id
    FROM oportunidade o
   INNER JOIN cenario c ON c.oportunidade_id = o.oportunidade_id
   WHERE cenario_id = p_cenario_id;
  IF v_oportunidade_status <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Oportunidade precisa estar Em Andamento para alterar o status do preço do Produto.';
   RAISE v_exception;
  END IF;
  SELECT num_cenario,
         status
    INTO v_num_cenario,
         v_status_old
    FROM cenario c
   WHERE cenario_id = p_cenario_id;
  IF p_flag_commit = 'S' THEN
   -- soh testa privilegio qdo a chamada for via interface.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORTUN_CENA_C',
                                 p_cenario_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
  IF RTRIM(p_cod_acao) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da ação é obrigatório.';
     RAISE v_exception;
  END IF;
  */
  IF p_cod_acao NOT IN ('ALTERAR',
                        'APRESENTAR',
                        'APROVAR',
                        'DEVOLVER_APROV',
                        'ENVIAR_APROV',
                        'REPROVAR',
                        'TERMINAR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_status_old = 'PREP' AND p_cod_acao = 'TERMINAR' THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'ALTERAR' THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'TERMINAR' THEN
   v_status_new := 'APROV_INTERNA';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'ENVIAR_APROV' THEN
   v_status_new := 'EM_APROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'DEVOLVER_APROV' THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'APROVAR' THEN
   v_status_new := 'APROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'REPROVAR' THEN
   v_status_new := 'REPROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'ALTERAR' THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'APOROV_INTERNA' AND p_cod_acao = 'ALTERAR' THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'REPROV_INTERNA' AND p_cod_acao = 'DEVOLVER_APROV' THEN
   v_status_new := 'EM_APROV_INTERNA';
  ELSIF v_status_old = 'REPROV_INTERNA' AND p_cod_acao = 'TERMINAR' THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'APROV_INTERNA' AND p_cod_acao = 'APRESENTAR' THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'APROVAR' THEN
   v_status_new := 'APROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'APRESENTAR' THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'ALTERAR' THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'REPROVAR' THEN
   v_status_new := 'REPROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'REPROVAR' THEN
   v_status_new := 'REPROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'ALTERAR' THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'APROVAR' THEN
   v_status_new := 'APROV_CLIENTE';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'APRESENTAR' THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'TERMINAR' THEN
   v_status_new := 'PRONTO';
  ELSE
   IF p_flag_commit = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Transição de status inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  IF v_status_new = 'PRONTO' AND 1 = 1 /*checagem do status_margem do cenário*/
   THEN
   v_status_new := 'APROV_INTERNA';
  END IF;
  UPDATE cenario
     SET status = v_status_new
   WHERE cenario_id = p_cenario_id;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  SELECT descricao
    INTO v_desc_status_old
    FROM dicionario
   WHERE codigo = v_status_old
     AND tipo = 'status_cenario';
  SELECT descricao
    INTO v_desc_status_new
    FROM dicionario
   WHERE codigo = v_status_new
     AND tipo = 'status_cenario';
  v_identif_objeto := to_char(v_oportunidade_numero);
  v_compl_histor   := 'Status de Cenário alterado de ' || v_desc_status_old || ' para ' ||
                      v_desc_status_new || ' do Cenário #' || v_num_cenario;
  IF TRIM(p_complemento) IS NOT NULL THEN
   v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
  END IF;
  -- usa a empresa do contrato pois a proc pode ter sido chamada via reabertura
  -- de oportunidade de outra ampresa.
  /*
  evento_pkg.gerar(p_usuario_sessao_id, v_empresa_id, 'OPORTUNIDADE', p_cod_acao,
                   v_identif_objeto, p_cenario_id, v_compl_histor, NULL,
                   'N', NULL, v_xml_atual,
                   v_historico_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
  END IF;
  */
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END cenario_status_alterar;
 --
 --
 PROCEDURE cenario_servico_status_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                ProcessMind     DATA: 17/08/2023
  -- DESCRICAO: Alteracao do status de precificação de um serviço dentro de um cenário
  --            de uma Oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- --                --          --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_cod_acao           IN tipo_acao.codigo%TYPE,
  p_complemento        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_oportunidade_status oportunidade.status%TYPE;
  v_cenario_id          cenario.cenario_id%TYPE;
  v_status_old          cenario_servico.status%TYPE;
  v_status_new          cenario_servico.status%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_num_cenario         cenario.num_cenario%TYPE;
  v_servico_desc        VARCHAR(203);
  v_desc_status_old     dicionario.descricao%TYPE;
  v_desc_status_new     dicionario.descricao%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto dentro do Cenário não existe.';
   RAISE v_exception;
  END IF;
  SELECT o.status,
         o.numero,
         o.empresa_id
    INTO v_oportunidade_status,
         v_oportunidade_numero,
         v_empresa_id
    FROM oportunidade o
   INNER JOIN cenario c ON c.oportunidade_id = o.oportunidade_id
   INNER JOIN cenario_servico s ON s.cenario_id = c.cenario_id
   WHERE cenario_servico_id = p_cenario_servico_id;
  IF v_oportunidade_status <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Oportunidade precisa estar Em Andamento para alterar o status do preço do Produto.';
   RAISE v_exception;
  END IF;
  SELECT c.cenario_id,
         num_cenario
    INTO v_cenario_id,
         v_num_cenario
    FROM cenario c
   INNER JOIN cenario_servico s ON s.cenario_id = c.cenario_id
   WHERE cenario_servico_id = p_cenario_servico_id;
  IF p_flag_commit = 'S' THEN
   -- soh testa privilegio qdo a chamada for via interface.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORTUN_CENA_C',
                                 p_cenario_servico_id,
                                 NULL,
                                 p_empresa_id) <> 1 AND
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORT_PRECIF_CARGO_ALTERAR',
                                 p_cenario_servico_id,
                                 NULL,
                                 p_empresa_id) <> 1 AND
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORT_PRECIF_ITENS_ALTERAR',
                                 p_cenario_servico_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
  IF RTRIM(p_cod_acao) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da ação é obrigatório.';
     RAISE v_exception;
  END IF;
  */
  IF p_cod_acao NOT IN ('TERMINAR', 'REFAZER', 'RECUSAR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT c.status,
         g.nome || ' - ' || s.nome
    INTO v_status_old,
         v_servico_desc
    FROM cenario_servico c
   INNER JOIN servico s ON s.servico_id = c.servico_id
    LEFT JOIN grupo_servico g ON g.grupo_servico_id = s.grupo_servico_id
   WHERE c.cenario_servico_id = p_cenario_servico_id;
  IF v_status_old = 'PEND' AND p_cod_acao = 'TERMINAR' THEN
   v_status_new := 'PRON';
  ELSIF v_status_old = 'PRON' AND p_cod_acao = 'REFAZER' THEN
   v_status_new := 'PEND';
  ELSIF v_status_old = 'PEND' AND p_cod_acao = 'RECUSAR' THEN
   v_status_new := 'RECU';
  ELSIF v_status_old = 'RECU' AND p_cod_acao = 'REFAZER' THEN
   v_status_new := 'PEND';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Transição de status inválida.';
   RAISE v_exception;
  END IF;
  UPDATE cenario_servico
     SET status = v_status_new
   WHERE cenario_servico_id = p_cenario_servico_id;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  SELECT descricao
    INTO v_desc_status_old
    FROM dicionario
   WHERE codigo = v_status_old
     AND tipo = 'status_cenario_servico';
  SELECT descricao
    INTO v_desc_status_new
    FROM dicionario
   WHERE codigo = v_status_new
     AND tipo = 'status_cenario_servico';
  v_identif_objeto := to_char(v_oportunidade_numero);
  v_compl_histor   := 'Status de Preço de Produto ' || v_servico_desc || ' alterado de ' ||
                      v_desc_status_old || ' para ' || v_desc_status_new || ' do Cenário ' ||
                      v_num_cenario;
  IF TRIM(p_complemento) IS NOT NULL THEN
   v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
  END IF;
  -- usa a empresa do contrato pois a proc pode ter sido chamada via reabertura
  -- de oportunidade de outra ampresa.
  /*
  evento_pkg.gerar(p_usuario_sessao_id, v_empresa_id, 'OPORTUNIDADE', p_cod_acao,
                   v_identif_objeto, p_cenario_servico_id, v_compl_histor, NULL,
                   'N', NULL, v_xml_atual,
                   v_historico_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
  END IF;
  */
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END cenario_servico_status_alterar;
 --
END; -- PAINEL_PKG

/
