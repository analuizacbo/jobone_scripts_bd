--------------------------------------------------------
--  DDL for Package Body QUADRO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "QUADRO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Inclusão de QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN VARCHAR2,
  p_quadro_id         OUT quadro.quadro_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt        := 0;
  p_quadro_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_quadro.nextval
    INTO v_quadro_id
    FROM dual;
  --
  INSERT INTO quadro
   (quadro_id,
    empresa_id,
    nome)
  VALUES
   (v_quadro_id,
    p_empresa_id,
    TRIM(p_nome));
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'QUADRO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_quadro_id,
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
  p_quadro_id := v_quadro_id;
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Atualização de QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_id         IN quadro.quadro_id%TYPE,
  p_nome              IN VARCHAR2,
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
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro
   WHERE quadro_id = p_quadro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro
   WHERE quadro_id <> p_quadro_id
     AND upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE quadro
     SET nome = TRIM(p_nome)
   WHERE quadro_id = p_quadro_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_quadro_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Exclusão de QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_id         IN quadro.quadro_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           quadro.nome%TYPE;
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
    FROM quadro
   WHERE quadro_id = p_quadro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM quadro_os_config qo
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc
           WHERE qc.quadro_id = p_quadro_id
             AND qc.quadro_coluna_id = qo.quadro_coluna_id);
  DELETE FROM quadro_tarefa_config qt
   WHERE EXISTS (SELECT 1
            FROM quadro_coluna qc
           WHERE qc.quadro_id = p_quadro_id
             AND qc.quadro_coluna_id = qt.quadro_coluna_id);
  DELETE FROM quadro_coluna
   WHERE quadro_id = p_quadro_id;
  DELETE FROM quadro_equipe
   WHERE quadro_id = p_quadro_id;
  DELETE FROM quadro
   WHERE quadro_id = p_quadro_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_quadro_id,
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
 PROCEDURE equipe_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Associacao de Equioe ao QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_id         IN quadro.quadro_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_nome_equipe    equipe.nome%TYPE;
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
    FROM quadro
   WHERE quadro_id = p_quadro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_quadro
    FROM quadro
   WHERE quadro_id = p_quadro_id;
  --
  SELECT nome
    INTO v_nome_equipe
    FROM equipe
   WHERE equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_equipe
   WHERE quadro_id = p_quadro_id
     AND equipe_id = p_equipe_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe já está associada a esse quadro.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO quadro_equipe
   (quadro_id,
    equipe_id)
  VALUES
   (p_quadro_id,
    p_equipe_id);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Inclusão de equipe: ' || v_nome_equipe;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_quadro_id,
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
 END equipe_adicionar;
 --
 --
 PROCEDURE equipe_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Exclusao de Equioe do QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_id         IN quadro.quadro_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_nome_equipe    equipe.nome%TYPE;
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
    FROM quadro
   WHERE quadro_id = p_quadro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_quadro
    FROM quadro
   WHERE quadro_id = p_quadro_id;
  --
  SELECT nome
    INTO v_nome_equipe
    FROM equipe
   WHERE equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_equipe
   WHERE quadro_id = p_quadro_id
     AND equipe_id = p_equipe_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não está associada a esse quadro.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM quadro_equipe
   WHERE quadro_id = p_quadro_id
     AND equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Exclusão de equipe: ' || v_nome_equipe;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_quadro_id,
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
 END equipe_excluir;
 --
 --
 PROCEDURE coluna_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Inclusao de coluna no QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_id         IN quadro.quadro_id%TYPE,
  p_nome              IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_nome_quadro      quadro.nome%TYPE;
  v_ordem            NUMBER(20);
  v_quadro_coluna_id quadro_coluna.quadro_coluna_id%TYPE;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro
   WHERE quadro_id = p_quadro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_quadro
    FROM quadro
   WHERE quadro_id = p_quadro_id;
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
  IF TRIM(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ordem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  --
  IF v_ordem > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_coluna
   WHERE quadro_id = p_quadro_id
     AND upper(nome) = upper(TRIM(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de coluna já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_quadro_coluna.nextval
    INTO v_quadro_coluna_id
    FROM dual;
  --
  INSERT INTO quadro_coluna
   (quadro_coluna_id,
    quadro_id,
    nome,
    ordem)
  VALUES
   (v_quadro_coluna_id,
    p_quadro_id,
    TRIM(p_nome),
    v_ordem);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(p_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Inclusão de coluna: ' || TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_quadro_id,
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
 END coluna_adicionar;
 --
 --
 PROCEDURE coluna_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Alteracao de coluna do QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_coluna.quadro_coluna_id%TYPE,
  p_nome              IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_ordem          NUMBER(20);
  v_quadro_id      quadro_coluna.quadro_id%TYPE;
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
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro/coluna não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT quadro_id
    INTO v_quadro_id
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_quadro
    FROM quadro
   WHERE quadro_id = v_quadro_id;
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
  IF TRIM(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ordem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  --
  IF v_ordem > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_coluna
   WHERE quadro_id = v_quadro_id
     AND upper(nome) = upper(TRIM(p_nome))
     AND quadro_coluna_id <> p_quadro_coluna_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de coluna já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE quadro_coluna
     SET nome  = TRIM(p_nome),
         ordem = v_ordem
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Alteração de coluna: ' || TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END coluna_atualizar;
 --
 --
 PROCEDURE coluna_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Exclusao de coluna do QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_coluna.quadro_coluna_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_quadro_id      quadro_coluna.quadro_id%TYPE;
  v_nome_coluna    quadro_coluna.nome%TYPE;
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
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro/coluna não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT quadro_id,
         nome
    INTO v_quadro_id,
         v_nome_coluna
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_quadro
    FROM quadro
   WHERE quadro_id = v_quadro_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM quadro_tarefa_config
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  DELETE FROM quadro_os_config
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  DELETE FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Exclusão de coluna: ' || TRIM(v_nome_coluna);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END coluna_excluir;
 --
 --
 PROCEDURE config_os_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Inclusao de configuracao de QUADRO de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_os_config.quadro_coluna_id%TYPE,
  p_tipo_os_id        IN quadro_os_config.tipo_os_id%TYPE,
  p_status            IN quadro_os_config.status%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_nome_coluna    quadro_coluna.nome%TYPE;
  v_tipo_os        tipo_os.nome%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_quadro_coluna_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da coluna é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa coluna não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT qd.nome,
         qd.quadro_id,
         qc.nome
    INTO v_nome_quadro,
         v_quadro_id,
         v_nome_coluna
    FROM quadro_coluna qc,
         quadro        qd
   WHERE qc.quadro_coluna_id = p_quadro_coluna_id
     AND qc.quadro_id = qd.quadro_id;
  --
  IF nvl(p_tipo_os_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de workflow é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_tipo_os
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_tipo_os IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('status_os', p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status inválido (' || p_status || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_os_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND tipo_os_id = p_tipo_os_id
     AND status = p_status;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa configuração de workflow já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO quadro_os_config
   (quadro_coluna_id,
    tipo_os_id,
    status)
  VALUES
   (p_quadro_coluna_id,
    p_tipo_os_id,
    p_status);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Inclusão config de OS : ' || TRIM(v_nome_coluna) || '/' || v_tipo_os || '/' ||
                      p_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END config_os_adicionar;
 --
 --
 PROCEDURE config_os_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Exclusao de configuracao de QUADRO de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_os_config.quadro_coluna_id%TYPE,
  p_tipo_os_id        IN quadro_os_config.tipo_os_id%TYPE,
  p_status            IN quadro_os_config.status%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_nome_coluna    quadro_coluna.nome%TYPE;
  v_tipo_os        tipo_os.nome%TYPE;
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
    FROM quadro_os_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND tipo_os_id = p_tipo_os_id
     AND status = p_status;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa configuração de workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT qd.nome,
         qd.quadro_id,
         qc.nome
    INTO v_nome_quadro,
         v_quadro_id,
         v_nome_coluna
    FROM quadro_coluna qc,
         quadro        qd
   WHERE qc.quadro_coluna_id = p_quadro_coluna_id
     AND qc.quadro_id = qd.quadro_id;
  --
  SELECT MAX(nome)
    INTO v_tipo_os
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_tipo_os IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM quadro_os_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND tipo_os_id = p_tipo_os_id
     AND status = p_status;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Exclusão de config de OS : ' || TRIM(v_nome_coluna) || '/' || v_tipo_os || '/' ||
                      p_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END config_os_excluir;
 --
 --
 PROCEDURE config_tarefa_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Inclusao de configuracao de QUADRO de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_tarefa_config.quadro_coluna_id%TYPE,
  p_status            IN quadro_tarefa_config.status%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_nome_coluna    quadro_coluna.nome%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_quadro_coluna_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da coluna é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_coluna
   WHERE quadro_coluna_id = p_quadro_coluna_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa coluna não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT qd.nome,
         qd.quadro_id,
         qc.nome
    INTO v_nome_quadro,
         v_quadro_id,
         v_nome_coluna
    FROM quadro_coluna qc,
         quadro        qd
   WHERE qc.quadro_coluna_id = p_quadro_coluna_id
     AND qc.quadro_id = qd.quadro_id;
  --
  IF TRIM(p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('status_tarefa', p_status) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status inválido (' || p_status || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro_tarefa_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND status = p_status;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa configuração de task já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO quadro_tarefa_config
   (quadro_coluna_id,
    status)
  VALUES
   (p_quadro_coluna_id,
    p_status);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Inclusão config de TASK : ' || TRIM(v_nome_coluna) || '/' || '/' ||
                      p_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END config_tarefa_adicionar;
 --
 --
 PROCEDURE config_tarefa_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Exclusao de configuracao de QUADRO de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_quadro_coluna_id  IN quadro_tarefa_config.quadro_coluna_id%TYPE,
  p_status            IN quadro_tarefa_config.status%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_quadro    quadro.nome%TYPE;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_nome_coluna    quadro_coluna.nome%TYPE;
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
    FROM quadro_tarefa_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND status = p_status;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa configuração de task não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT qd.nome,
         qd.quadro_id,
         qc.nome
    INTO v_nome_quadro,
         v_quadro_id,
         v_nome_coluna
    FROM quadro_coluna qc,
         quadro        qd
   WHERE qc.quadro_coluna_id = p_quadro_coluna_id
     AND qc.quadro_id = qd.quadro_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM quadro_tarefa_config
   WHERE quadro_coluna_id = p_quadro_coluna_id
     AND status = p_status;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_quadro;
  v_compl_histor   := 'Exclusão de config de TASK : ' || TRIM(v_nome_coluna) || '/' ||
                      p_status;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'QUADRO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_quadro_id,
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
 END config_tarefa_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 16/07/2021
  -- DESCRICAO: Subrotina que gera o xml do quadro para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_quadro_id IN quadro.quadro_id%TYPE,
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
  CURSOR c_eq IS
   SELECT eq.nome
     FROM quadro_equipe qe,
          equipe        eq
    WHERE qe.quadro_id = p_quadro_id
      AND qe.equipe_id = eq.equipe_id
    ORDER BY eq.nome;
  --
  CURSOR c_co IS
   SELECT nome,
          ordem
     FROM quadro_coluna
    WHERE quadro_id = p_quadro_id
    ORDER BY nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("quadro_id", quadro_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", nome))
    INTO v_xml
    FROM quadro
   WHERE quadro_id = p_quadro_id;
  --
  ------------------------------------------------------------
  -- monta EQUIPE
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_eq IN c_eq
  LOOP
   SELECT xmlconcat(xmlelement("equipe", r_eq.nome))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("equipes", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta COLUNA
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_co IN c_co
  LOOP
   SELECT xmlagg(xmlelement("coluna",
                            xmlelement("nome", r_co.nome),
                            xmlelement("ordem", r_co.ordem)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("colunas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "quadro"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("quadro", v_xml))
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
PROCEDURE duplicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                 ProcessMind     DATA: 17/06/2024
  -- DESCRICAO: Duplicação de QUADRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xx                99/99/9999  xx
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN VARCHAR2,
  p_quadro_duplicar_id  IN quadro.quadro_id%TYPE,
  p_quadro_id         OUT quadro.quadro_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_quadro_id      quadro.quadro_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt        := 0;
  p_quadro_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'QUADRO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM quadro
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse quadro já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_quadro.nextval
    INTO v_quadro_id
    FROM dual;
  --
  INSERT INTO quadro
   (quadro_id,
    empresa_id,
    nome)
  VALUES
   (v_quadro_id,
    p_empresa_id,
    TRIM(p_nome));
  --
  ------------------------------------------------------------
  -- copia demais configurações para o novo quadro
  ------------------------------------------------------------
  --
  INSERT INTO quadro_coluna
    (quadro_coluna_id, quadro_id, nome, ordem)
  SELECT
    SEQ_quadro_coluna.NEXTVAL, v_quadro_id, nome, ordem
  FROM
    quadro_coluna
  WHERE
    quadro_id = p_quadro_duplicar_id;
  --
  INSERT INTO quadro_equipe
    (quadro_id, equipe_id)
  SELECT
    v_quadro_id, equipe_id
  FROM
    quadro_equipe
  WHERE
    quadro_id = p_quadro_duplicar_id;
  --
  INSERT INTO quadro_os_config (quadro_coluna_id, tipo_os_id, status)
  SELECT nq.quadro_coluna_id, oo.tipo_os_id, oo.status
    FROM quadro_coluna nq
         INNER JOIN quadro_coluna oq ON nq.nome = oq.nome
                    AND nq.ordem = oq.ordem
                    AND nq.quadro_id = v_quadro_id
                    AND oq.quadro_id = p_quadro_duplicar_id
         INNER JOIN quadro_os_config oo ON oo.quadro_coluna_id = oq.quadro_coluna_id;
  --
  INSERT INTO quadro_tarefa_config (quadro_coluna_id, status)
  SELECT nq.quadro_coluna_id, ot.status
    FROM quadro_coluna nq
         INNER JOIN quadro_coluna oq ON nq.nome = oq.nome
                    AND nq.ordem = oq.ordem
                    AND nq.quadro_id = v_quadro_id
                    AND oq.quadro_id = p_quadro_duplicar_id
         INNER JOIN quadro_tarefa_config ot ON ot.quadro_coluna_id = oq.quadro_coluna_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  quadro_pkg.xml_gerar(v_quadro_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'QUADRO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_quadro_id,
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
  p_quadro_id := v_quadro_id;
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
 END duplicar;
 --
--
END; -- QUADRO_PKG



/
