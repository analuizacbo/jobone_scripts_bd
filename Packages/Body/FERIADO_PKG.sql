--------------------------------------------------------
--  DDL for Package Body FERIADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FERIADO_PKG" IS
 --
 --
 PROCEDURE tab_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/05/2014
  -- DESCRICAO: Inclusão de TABELA de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/08/2015  Novo parametro flag_padrao.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_nome                IN tab_feriado.nome%TYPE,
  p_flag_padrao         IN VARCHAR2,
  p_tab_feriado_base_id IN tab_feriado.tab_feriado_id%TYPE,
  p_data_base           IN VARCHAR2,
  p_tab_feriado_id      OUT tab_feriado.tab_feriado_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_tab_feriado_id tab_feriado.tab_feriado_id%TYPE;
  v_data_base      DATE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
  CURSOR c_fe IS
   SELECT data,
          nome,
          tipo
     FROM feriado
    WHERE tab_feriado_id = p_tab_feriado_base_id
      AND data >= nvl(v_data_base, data_converter('01/01/1900'))
    ORDER BY data;
  --
 BEGIN
  v_qt             := 0;
  p_tab_feriado_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tab_feriado_base_id, 0) = 0 AND TRIM(p_data_base) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A tabela de feriados a ser usada como modelo não foi especificada.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_base) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_base || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_base := data_converter(p_data_base);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de tabela de feriado já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tab_feriado.nextval
    INTO v_tab_feriado_id
    FROM dual;
  --
  INSERT INTO tab_feriado
   (tab_feriado_id,
    empresa_id,
    nome,
    flag_padrao)
  VALUES
   (v_tab_feriado_id,
    p_empresa_id,
    TRIM(p_nome),
    p_flag_padrao);
  --
  IF nvl(p_tab_feriado_base_id, 0) > 0 THEN
   FOR r_fe IN c_fe
   LOOP
    INSERT INTO feriado
     (feriado_id,
      tab_feriado_id,
      data,
      nome,
      tipo)
    VALUES
     (seq_feriado.nextval,
      v_tab_feriado_id,
      r_fe.data,
      r_fe.nome,
      r_fe.tipo);
   END LOOP;
  END IF;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas uma tabela da empresa pode ser padrao.
   UPDATE tab_feriado
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tab_feriado_id <> v_tab_feriado_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(v_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
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
                   'TAB_FERIADO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tab_feriado_id,
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
  p_tab_feriado_id := v_tab_feriado_id;
  p_erro_cod       := '00000';
  p_erro_msg       := 'Operação realizada com sucesso.';
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
 END tab_adicionar;
 --
 --
 PROCEDURE tab_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/05/2014
  -- DESCRICAO: Alteracao da TABELA de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/08/2015  Novo parametro flag_padrao.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
  p_nome              IN tab_feriado.nome%TYPE,
  p_flag_padrao       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE empresa_id = p_empresa_id
     AND tab_feriado_id = p_tab_feriado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa tabela de feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
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
    FROM tab_feriado
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tab_feriado_id <> p_tab_feriado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de tabela de feriado já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tab_feriado
     SET nome        = TRIM(p_nome),
         flag_padrao = p_flag_padrao
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas uma tabela da empresa pode ser padrao.
   UPDATE tab_feriado
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tab_feriado_id <> p_tab_feriado_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
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
                   'TAB_FERIADO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tab_feriado_id,
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
 END tab_atualizar;
 --
 --
 PROCEDURE tab_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/05/2014
  -- DESCRICAO: Exclusao da TABELA de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_nome_tab       tab_feriado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa tabela de feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tab
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa tabela de feriado está sendo referenciada por algum usuário.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  DELETE FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_tab;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_FERIADO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tab_feriado_id,
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
 END tab_excluir;
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 05/04/2004
  -- DESCRICAO: Inclusão de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Nova tabela agrupadora de feriados.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Ana Luiza         02/12/2024  Recalculando alocacao em feriados
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tab_feriado_id    IN feriado.tab_feriado_id%TYPE,
  p_data              IN VARCHAR2,
  p_nome              IN feriado.nome%TYPE,
  p_tipo              IN feriado.tipo%TYPE,
  p_feriado_id        OUT feriado.feriado_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_feriado_id     feriado.feriado_id%TYPE;
  v_data           feriado.data%TYPE;
  v_nome_tab       tab_feriado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt         := 0;
  p_feriado_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa tabela de feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tab
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo NOT IN ('F', 'M', 'I') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de feriado inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM feriado
   WHERE data = v_data
     AND tab_feriado_id = p_tab_feriado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe feriado cadastrado para essa data.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_feriado.nextval
    INTO v_feriado_id
    FROM dual;
  --
  INSERT INTO feriado
   (feriado_id,
    tab_feriado_id,
    data,
    nome,
    tipo)
  VALUES
   (v_feriado_id,
    p_tab_feriado_id,
    v_data,
    p_nome,
    p_tipo);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  FOR r_usu IN (SELECT DISTINCT (usuario_id)
                  FROM dia_alocacao
                 WHERE usuario_id IN (SELECT usuario_id
                                        FROM pessoa
                                       WHERE empresa_id = p_empresa_id))
  LOOP
   --ALCBO_021224
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_usu.usuario_id,
                                         v_data,
                                         v_data,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_tab;
  v_compl_histor   := 'Nova data: ' || data_mostrar(v_data);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_FERIADO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tab_feriado_id,
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
  p_feriado_id := v_feriado_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 05/04/2004
  -- DESCRICAO: Atualização de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Nova tabela agrupadora de feriados.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Ana Luiza         02/12/2024  Recalculando alocacao em feriados
  -- Ana Luiza         05/12/2024  Trata alocacao do feriado alterado anteriormente
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_feriado_id        IN feriado.feriado_id%TYPE,
  p_data              IN VARCHAR2,
  p_nome              IN feriado.nome%TYPE,
  p_tipo              IN feriado.tipo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_tab_feriado_id tab_feriado.tab_feriado_id%TYPE;
  v_data           feriado.data%TYPE;
  v_nome_tab       tab_feriado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_data_old       DATE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(fe.tab_feriado_id)
    INTO v_tab_feriado_id
    FROM feriado     fe,
         tab_feriado tf
   WHERE fe.feriado_id = p_feriado_id
     AND fe.tab_feriado_id = tf.tab_feriado_id
     AND tf.empresa_id = p_empresa_id;
  --
  IF v_tab_feriado_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tab
    FROM tab_feriado
   WHERE tab_feriado_id = v_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo NOT IN ('F', 'M', 'I') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de feriado inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM feriado
   WHERE feriado_id <> p_feriado_id
     AND data = v_data
     AND tab_feriado_id = v_tab_feriado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe feriado cadastrado para essa data.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(v_tab_feriado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT data
    INTO v_data_old
    FROM feriado
   WHERE feriado_id = p_feriado_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE feriado
     SET data = v_data,
         nome = p_nome,
         tipo = p_tipo
   WHERE feriado_id = p_feriado_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(v_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF v_data <> v_data_old THEN
   --Ajusta hora do dia informado anteriormente como feriado
   --ALCBO_051224
   FOR r_usu IN (SELECT DISTINCT (usuario_id)
                   FROM dia_alocacao
                  WHERE usuario_id IN (SELECT usuario_id
                                         FROM pessoa
                                        WHERE empresa_id = p_empresa_id))
   LOOP
    --ALCBO_021224
    -- recalcula alocacao
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_usu.usuario_id,
                                          v_data_old,
                                          v_data_old,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --ALCBO_021224
  --Ajusta hora do novo dia informado como feriado
  FOR r_usu IN (SELECT DISTINCT (usuario_id)
                  FROM dia_alocacao
                 WHERE usuario_id IN (SELECT usuario_id
                                        FROM pessoa
                                       WHERE empresa_id = p_empresa_id))
  LOOP
   --ALCBO_021224
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_usu.usuario_id,
                                         v_data,
                                         v_data,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_tab;
  v_compl_histor   := 'Data alterada: ' || data_mostrar(v_data);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_FERIADO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tab_feriado_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar;
 --
 --
 PROCEDURE replicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 05/04/2004
  -- DESCRICAO: Replica os feriados fixos de um determinado ano para um ano destino.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Nova tabela agrupadora de feriados.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tab_feriado_id    IN tab_feriado.tab_feriado_id%TYPE,
  p_ano_origem        IN VARCHAR2,
  p_ano_destino       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_ano_origem     INTEGER;
  v_ano_destino    INTEGER;
  v_data_nova      feriado.data%TYPE;
  v_exception      EXCEPTION;
  v_nome_tab       tab_feriado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
  CURSOR c_fer IS
   SELECT data,
          nome
     FROM feriado
    WHERE to_number(to_char(data, 'YYYY')) = v_ano_origem
      AND tipo = 'F'
      AND tab_feriado_id = p_tab_feriado_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_feriado
   WHERE empresa_id = p_empresa_id
     AND tab_feriado_id = p_tab_feriado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa tabela de feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tab
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_ano_origem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano origem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano_origem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano origem inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_ano_destino) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ano destino é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ano_destino) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano destino inválido.';
   RAISE v_exception;
  END IF;
  --
  v_ano_origem  := to_number(p_ano_origem);
  v_ano_destino := to_number(p_ano_destino);
  --
  IF v_ano_origem < 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano origem inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_ano_destino < 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ano destino inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_fer IN c_fer
  LOOP
   v_data_nova := data_converter(to_char(r_fer.data, 'dd/mm') || '/' || v_ano_destino);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM feriado
    WHERE data = v_data_nova
      AND tab_feriado_id = p_tab_feriado_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO feriado
     (feriado_id,
      tab_feriado_id,
      data,
      nome,
      tipo)
    VALUES
     (seq_feriado.nextval,
      p_tab_feriado_id,
      v_data_nova,
      r_fer.nome,
      'F');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(p_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_tab;
  v_compl_histor   := 'Replicação de ' || p_ano_origem || ' para ' || p_ano_destino;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_FERIADO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tab_feriado_id,
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
 END replicar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 05/04/2004
  -- DESCRICAO: Exclusão de FERIADO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Nova tabela agrupadora de feriados.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Ana Luiza         02/12/2024  Recalculando alocacao em feriados
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_feriado_id        IN feriado.feriado_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_tab_feriado_id tab_feriado.tab_feriado_id%TYPE;
  v_data           feriado.data%TYPE;
  v_nome_tab       tab_feriado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FERIADO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(fe.tab_feriado_id)
    INTO v_tab_feriado_id
    FROM feriado     fe,
         tab_feriado tf
   WHERE fe.feriado_id = p_feriado_id
     AND fe.tab_feriado_id = tf.tab_feriado_id
     AND tf.empresa_id = p_empresa_id;
  --
  IF v_tab_feriado_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse feriado não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tab
    FROM tab_feriado
   WHERE tab_feriado_id = v_tab_feriado_id;
  --
  SELECT data
    INTO v_data
    FROM feriado
   WHERE feriado_id = p_feriado_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(v_tab_feriado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM feriado
   WHERE feriado_id = p_feriado_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  feriado_pkg.xml_gerar(v_tab_feriado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  FOR r_usu IN (SELECT DISTINCT (usuario_id)
                  FROM dia_alocacao
                 WHERE usuario_id IN (SELECT usuario_id
                                        FROM pessoa
                                       WHERE empresa_id = p_empresa_id))
  LOOP
   --ALCBO_021224
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_usu.usuario_id,
                                         v_data,
                                         v_data,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_tab;
  v_compl_histor   := 'Data excluída: ' || data_mostrar(v_data);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_FERIADO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tab_feriado_id,
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
 END excluir;
 --
 --
 FUNCTION prox_dia_util_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/04/2004
  -- DESCRICAO: retorna o n-esimo dia util (p_dias_uteis) a partir de uma determinada data.
  --  O parametro p_feriado_interno serve para indicar se os feriados internos devem ser
  --  considerados como feriados normais ou nao ('S' ou 'N').
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Troca do parametro empresa_id por usuario_id (usado para
  --                                 pegar a tabela de feriado associada a ele.
  ------------------------------------------------------------------------------------------
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_data            IN DATE,
  p_dias_uteis      IN INTEGER,
  p_feriado_interno IN VARCHAR2
 ) RETURN DATE AS
  v_qt         INTEGER;
  v_ind        INTEGER;
  v_achou      INTEGER;
  v_data       DATE;
  v_dia_semana CHAR(1);
  v_data_base  DATE;
  v_dias_uteis INTEGER;
  --
 BEGIN
  --
  v_data_base  := trunc(p_data);
  v_dias_uteis := nvl(p_dias_uteis, 0);
  --
  IF v_dias_uteis = 0 THEN
   v_dias_uteis := 1;
   v_data       := v_data_base - 1;
  ELSE
   v_data := v_data_base;
  END IF;
  --
  v_ind := 1;
  --
  IF v_data IS NOT NULL THEN
   WHILE v_ind <= abs(v_dias_uteis)
   LOOP
    v_achou := 0;
    WHILE v_achou = 0
    LOOP
     IF v_dias_uteis >= 0 THEN
      v_data := v_data + 1;
     ELSE
      v_data := v_data - 1;
     END IF;
     --
     v_dia_semana := to_char(v_data, 'D');
     --
     IF v_dia_semana NOT IN ('7', '1') THEN
      -- nao é sabado nem domingo. Verifica se é feriado.
      IF p_feriado_interno = 'N' THEN
       -- feriados internos nao sao considerados
       SELECT COUNT(*)
         INTO v_qt
         FROM feriado fe,
              usuario us
        WHERE us.usuario_id = p_usuario_id
          AND us.tab_feriado_id = fe.tab_feriado_id
          AND trunc(fe.data) = v_data
          AND fe.tipo <> 'I';
      ELSE
       SELECT COUNT(*)
         INTO v_qt
         FROM feriado fe,
              usuario us
        WHERE us.usuario_id = p_usuario_id
          AND us.tab_feriado_id = fe.tab_feriado_id
          AND trunc(fe.data) = v_data;
      END IF;
      --
      IF v_qt = 0 THEN
       -- a data é um dia util
       v_achou := 1;
      END IF;
     END IF;
    END LOOP;
    --
    v_ind := v_ind + 1;
   END LOOP;
  END IF;
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_data := NULL;
   RETURN v_data;
 END prox_dia_util_retornar;
 --
 --
 FUNCTION dia_util_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/04/2004
  -- DESCRICAO: verifica se determinado dia é um dia útil. Retorna 0 caso não seja e 1
  --  caso seja. O parametro p_feriado_interno serve para indicar se os feriados internos
  --  devem ser considerados ou nao ('S' ou 'N').
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/05/2014  Troca do parametro empresa_id por usuario_id (usado para
  --                                 pegar a tabela de feriado associada a ele.
  ------------------------------------------------------------------------------------------
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_data            IN DATE,
  p_feriado_interno IN VARCHAR2
 ) RETURN INTEGER AS
  v_qt         INTEGER;
  v_retorno    INTEGER;
  v_data       DATE;
  v_dia_semana CHAR(1);
  --
 BEGIN
  --
  v_data    := trunc(p_data);
  v_retorno := 0;
  --
  IF v_data IS NOT NULL THEN
   --
   v_dia_semana := to_char(v_data, 'D');
   --
   IF v_dia_semana NOT IN ('7', '1') THEN
    -- nao é sabado nem domingo. Verifica se é feriado.
    IF p_feriado_interno = 'N' THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM feriado fe,
            usuario us
      WHERE us.usuario_id = p_usuario_id
        AND us.tab_feriado_id = fe.tab_feriado_id
        AND trunc(fe.data) = v_data
        AND fe.tipo <> 'I';
    ELSE
     SELECT COUNT(*)
       INTO v_qt
       FROM feriado fe,
            usuario us
      WHERE us.usuario_id = p_usuario_id
        AND us.tab_feriado_id = fe.tab_feriado_id
        AND trunc(fe.data) = v_data;
    END IF;
    --
    IF v_qt = 0 THEN
     -- a data é um dia util
     v_retorno := 1;
    END IF;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END dia_util_verificar;
 --
 --
 FUNCTION qtd_dias_uteis_retornar
 (
  ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 24/06/2010
  -- DESCRICAO: retorna a qtd de dias uteis entre duas datas.
  --  (Nao considera feriados internos).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Silvia            23/05/2014  Troca do parametro empresa_id por usuario_id (usado
  --                               para pegar a tabela de feriado associada a ele.
  ----------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_data_ini   IN DATE,
  p_data_fim   IN DATE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  v_data    DATE;
  --
 BEGIN
  --
  v_data    := trunc(p_data_ini);
  v_retorno := 0;
  --
  WHILE v_data <= trunc(p_data_fim)
  LOOP
   IF dia_util_verificar(p_usuario_id, v_data, 'N') = 1 THEN
    v_retorno := v_retorno + 1;
   END IF;
   --
   v_data := v_data + 1;
  END LOOP;
  --
  IF v_retorno > 0 THEN
   v_retorno := v_retorno - 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END qtd_dias_uteis_retornar;
 --
 --
 FUNCTION prazo_em_horas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias     ProcessMind     DATA: 21/01/2016
  -- DESCRICAO: retorna o prazo em data/hora calculado a partir de uma data/hora fornecida
  --            e de acordo com o parâmetro da empresa que define qual é o tipo de prazo
  --            que está sendo calculado
  --
  -- Parâmetros utilizados:
  -- AG_HORA_INI_EXP - Hora início do expediente da agência (HH:MI).
  -- AG_HORA_FIM_EXP - Hora fim do expediente da agência (HH:MI).
  --
  -- Parâmetro de entrada p_param_num_horas:
  -- NUM_HORAS_APROV_CRONO - Número de horas úteis limite para aprovação de Cronograma.
  -- NUM_HORAS_APROV_BRIEF - Número de horas úteis limite para aprovação de Briefing.
  -- NUM_HORAS_APROV_JOBHORAS - Número de horas úteis limite para aprovação de
  --                            Estimativa de Horas.
  -- NUM_HORAS_APROV_ORCAM - Número de horas úteis limite para aprovação de
  --                         Estimativa de Custos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         12/04/2018  Inclusão do parâmetro de entrada p_num_horas, alteração
  --                               das variáveis v_param_prazo_horas, v_num_horas_prazo,
  --                               v_num_horas_prazo_restantes de integer para number
  ------------------------------------------------------------------------------------------
  p_usuario_id      IN usuario.usuario_id%TYPE,
  p_empresa_id      IN empresa.empresa_id%TYPE,
  p_data            IN DATE,
  p_param_num_horas IN VARCHAR2,
  p_num_horas       NUMBER
 ) RETURN DATE AS
  v_qt                        INTEGER;
  v_data                      DATE;
  v_horas                     NUMBER;
  v_hora_dia_inicial          DATE;
  v_param_prazo_horas         VARCHAR2(20);
  v_prazo_horas               NUMBER;
  v_ag_hora_ini_exp           DATE;
  v_ag_hora_fim_exp           DATE;
  v_ag_hora_ini_int_prog      DATE;
  v_ag_hora_fim_int_prog      DATE;
  v_num_horas_prazo           NUMBER;
  v_num_horas_prazo_restantes NUMBER;
  v_num_horas_exp             NUMBER;
  v_num_horas_int_prog        NUMBER;
  v_num_dias_uteis            INT;
  v_cont                      NUMBER;
  v_qt_achou                  INT;
  v_qt_ausencia               INT;
  v_num_horas_cabe_no_dia     NUMBER;
  v_data_aux                  DATE;
  --
 BEGIN
  --
  v_data  := trunc(p_data);
  v_horas := p_data - trunc(p_data);
  --
  IF nvl(p_num_horas, 0) = 0 THEN
   v_num_horas_prazo := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                 p_param_num_horas));
  ELSE
   v_num_horas_prazo := p_num_horas;
  END IF;
  --definir o número de horas totais em 1 dia de expediente (incluindo intervalo programado)
  v_ag_hora_ini_exp := to_date(empresa_pkg.parametro_retornar(p_empresa_id, 'AG_HORA_INI_EXP'),
                               'HH24:MI');
  v_ag_hora_fim_exp := to_date(empresa_pkg.parametro_retornar(p_empresa_id, 'AG_HORA_FIM_EXP'),
                               'HH24:MI');
  v_num_horas_exp   := v_ag_hora_fim_exp - v_ag_hora_ini_exp;
  --definir o número de horas do intervalo programado
  v_ag_hora_ini_int_prog := to_date(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'AG_HORA_INI_INT_PROG'),
                                    'HH24:MI');
  v_ag_hora_fim_int_prog := to_date(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'AG_HORA_FIM_INT_PROG'),
                                    'HH24:MI');
  v_num_horas_int_prog   := v_ag_hora_fim_int_prog - v_ag_hora_ini_int_prog;
  --
  --definir o número de dias úteis no tempo informado
  v_num_dias_uteis            := trunc(v_num_horas_prazo /
                                       ((v_num_horas_exp - v_num_horas_int_prog) * 24));
  v_num_horas_prazo_restantes := (v_num_horas_prazo -
                                 (v_num_dias_uteis * (v_num_horas_exp - v_num_horas_int_prog) * 24));
  --
  IF v_num_dias_uteis > 0 THEN
   v_qt_achou := 0;
   WHILE v_qt_achou < v_num_dias_uteis
   LOOP
    v_qt_ausencia := 0;
    --
    IF p_param_num_horas = 'TLINE' THEN
     --verifica programacao de ausencia na data
     SELECT COUNT(*)
       INTO v_qt_ausencia
       FROM apontam_progr
      WHERE usuario_id = p_usuario_id
        AND trunc(v_data) >= trunc(data_ini)
        AND trunc(v_data) <= trunc(data_fim);
    END IF;
    --
    IF v_qt_ausencia = 0 AND feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 1 THEN
     -- nao tem programacao de ausencia e eh dia util
     v_qt_achou := v_qt_achou + 1;
    END IF;
    --
    IF v_qt_achou <= v_num_dias_uteis THEN
     v_data := v_data + 1;
    END IF;
   END LOOP;
   --
   IF feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 0 THEN
    v_data := feriado_pkg.prox_dia_util_retornar(p_usuario_id, v_data, 1, 'S');
   END IF;
  END IF;
  --
  v_data := v_data + v_horas;
  --
  IF v_num_horas_prazo_restantes > 0 THEN
   v_cont := 0.5;
   WHILE v_cont <= v_num_horas_prazo_restantes
   LOOP
    v_data        := v_data + 0.5 / 24;
    v_qt_ausencia := 0;
    --
    IF p_param_num_horas = 'TLINE' THEN
     --verifica programacao de ausencia na data
     SELECT COUNT(*)
       INTO v_qt_ausencia
       FROM apontam_progr
      WHERE usuario_id = p_usuario_id
        AND trunc(v_data) >= trunc(data_ini)
        AND trunc(v_data) <= trunc(data_fim);
    END IF;
    --
    -- isola a hora para poder comparar
    v_data_aux := to_date(to_char(v_data, 'HH24:MI'), 'HH24:MI');
    --
    IF v_qt_ausencia = 0 AND feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 1 AND
       (v_data_aux >= v_ag_hora_ini_exp AND v_data_aux < v_ag_hora_ini_int_prog OR
       v_data_aux >= v_ag_hora_fim_int_prog AND v_data_aux < v_ag_hora_fim_exp) THEN
     -- nao tem programacao de ausencia e eh dia util e eh horario valido
     v_cont := v_cont + 0.5;
    END IF;
   END LOOP;
  END IF;
  --
  RETURN v_data;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_data := NULL;
   RETURN v_data;
 END prazo_em_horas_retornar;
 --
 --
 FUNCTION dif_horas_uteis_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias     ProcessMind     DATA: 19/04/2018
  -- DESCRICAO: retorna o número de horas uteis entre duas datas fornecidas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/06/2020  Novo parametro para considerar ou nao programacao de
  --                               apontamentos                              --
  ------------------------------------------------------------------------------------------
  p_usuario_id           IN usuario.usuario_id%TYPE,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_data_inicio          IN DATE,
  p_data_fim             IN DATE,
  p_flag_considera_progr IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                   INTEGER;
  v_data_inicio          DATE;
  v_data_fim             DATE;
  v_horas_inicio         DATE;
  v_horas_fim            DATE;
  v_ag_hora_ini_exp      DATE;
  v_ag_hora_fim_exp      DATE;
  v_ag_hora_ini_int_prog DATE;
  v_ag_hora_fim_int_prog DATE;
  v_num_horas            NUMBER;
  v_num_horas_exp        NUMBER;
  v_num_horas_int_prog   NUMBER;
  --
 BEGIN
  --
  v_data_inicio  := trunc(p_data_inicio);
  v_horas_inicio := to_date(to_char(p_data_inicio, 'HH24:MI'), 'HH24:MI');
  v_data_fim     := trunc(p_data_fim);
  v_horas_fim    := to_date(to_char(p_data_fim, 'HH24:MI'), 'HH24:MI');
  --
  v_ag_hora_ini_exp := to_date(empresa_pkg.parametro_retornar(p_empresa_id, 'AG_HORA_INI_EXP'),
                               'HH24:MI');
  v_ag_hora_fim_exp := to_date(empresa_pkg.parametro_retornar(p_empresa_id, 'AG_HORA_FIM_EXP'),
                               'HH24:MI');
  v_num_horas_exp   := (v_ag_hora_fim_exp - v_ag_hora_ini_exp) * 24;
  --
  --definir o número de horas do intervalo programado
  v_ag_hora_ini_int_prog := to_date(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'AG_HORA_INI_INT_PROG'),
                                    'HH24:MI');
  v_ag_hora_fim_int_prog := to_date(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'AG_HORA_FIM_INT_PROG'),
                                    'HH24:MI');
  v_num_horas_int_prog   := (v_ag_hora_fim_int_prog - v_ag_hora_ini_int_prog) * 24;
  --
  v_num_horas := (feriado_pkg.qtd_dias_uteis_retornar(p_usuario_id, v_data_inicio, v_data_fim) - 1) *
                 (v_num_horas_exp - v_num_horas_int_prog);
  --
  v_qt := 0;
  --
  IF p_flag_considera_progr = 'S' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_progr
    WHERE usuario_id = p_usuario_id
      AND trunc(v_data_inicio) >= trunc(data_ini)
      AND trunc(v_data_fim) <= trunc(data_fim);
  END IF;
  --
  v_num_horas := v_num_horas - (v_qt * v_num_horas_exp);
  --
  v_num_horas := v_num_horas + ((v_ag_hora_fim_exp - v_horas_inicio) * 24);
  --
  IF p_data_inicio <= to_date(to_char(v_data_inicio, 'dd/mm/yyyy') || ' ' ||
                              to_char(v_ag_hora_ini_int_prog, 'HH24:MI'),
                              'dd/mm/yyyy HH24:MI') THEN
   v_num_horas := v_num_horas - v_num_horas_int_prog;
  END IF;
  --
  v_num_horas := v_num_horas + ((v_horas_fim - v_ag_hora_ini_exp) * 24);
  --
  IF p_data_fim >= to_date(to_char(v_data_fim, 'dd/mm/yyyy') || ' ' ||
                           to_char(v_ag_hora_fim_int_prog, 'HH24:MI'),
                           'dd/mm/yyyy HH24:MI') THEN
   v_num_horas := v_num_horas - v_num_horas_int_prog;
  END IF;
  --
  RETURN v_num_horas;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_num_horas := NULL;
   RETURN v_num_horas;
 END dif_horas_uteis_retornar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/09/2017
  -- DESCRICAO: Subrotina que gera o xml de TAB_FERIADO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tab_feriado_id IN tab_feriado.tab_feriado_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_fe IS
   SELECT feriado_id,
          data_mostrar(data) data_char,
          nome,
          decode(tipo, 'F', 'Fixo', 'M', 'Móvel', 'I', 'Interno') tipo
     FROM feriado
    WHERE tab_feriado_id = p_tab_feriado_id
    ORDER BY data;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tab_feriado_id", tab_feriado_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", nome),
                   xmlelement("padrao", flag_padrao))
    INTO v_xml
    FROM tab_feriado
   WHERE tab_feriado_id = p_tab_feriado_id;
  --
  ------------------------------------------------------------
  -- monta FERIADOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_fe IN c_fe
  LOOP
   SELECT xmlagg(xmlelement("feriado",
                            xmlelement("data", r_fe.data_char),
                            xmlelement("nome", r_fe.nome),
                            xmlelement("tipo", r_fe.tipo)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("feriados", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tab_feriado"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tab_feriado", v_xml))
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
END; -- FERIADO_PKG



/
