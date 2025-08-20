--------------------------------------------------------
--  DDL for Package Body EQUIPE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "EQUIPE_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Inclusão de EQUIPE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN equipe.nome%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_equipe_id      equipe.equipe_id%TYPE;
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
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE TRIM(upper(nome)) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de equipe já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_equipe.nextval
    INTO v_equipe_id
    FROM dual;
  --
  INSERT INTO equipe
   (equipe_id,
    empresa_id,
    nome)
  VALUES
   (v_equipe_id,
    p_empresa_id,
    TRIM(p_nome));
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(v_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'EQUIPE',
                   'INCLUIR',
                   v_identif_objeto,
                   v_equipe_id,
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
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Atualização de EQUIPE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_nome              IN equipe.nome%TYPE,
  p_flag_em_dist_os   IN VARCHAR2,
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  IF flag_validar(p_flag_em_dist_os) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag usado em distribuição de Workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE equipe_id <> p_equipe_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de equipe já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE equipe
     SET nome            = TRIM(p_nome),
         flag_em_dist_os = p_flag_em_dist_os
   WHERE equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Exclusão de EQUIPE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         13/03/2024  Adicicao de verificacao de quadro por equipe
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           equipe.nome%TYPE;
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
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --ALCBO_130324
  SELECT COUNT(1)
    INTO v_qt
    FROM quadro_equipe
   WHERE equipe_id = p_equipe_id;
  --
  IF v_qt <> 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Equipe possui Quadros associados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM equipe_usuario
   WHERE equipe_id = p_equipe_id;
  DELETE FROM equipe
   WHERE equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_equipe_id,
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
 PROCEDURE usuario_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Inclusão de usuario na EQUIPE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_nome_equipe    equipe.nome%TYPE;
  v_nome_pessoa    pessoa.nome%TYPE;
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
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_equipe
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome_equipe IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse equipe de cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_pessoa
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe_usuario
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário já está associado a essa equipe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO equipe_usuario
   (equipe_id,
    usuario_id,
    flag_membro,
    flag_responsavel)
  VALUES
   (p_equipe_id,
    p_usuario_id,
    'S',
    'N');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_equipe || ' / ' || v_nome_pessoa;
  v_compl_histor   := 'Inclusão de usuário na equipe';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END usuario_adicionar;
 --
 --
 PROCEDURE usuario_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Exclusão de usuario da EQUIPE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_nome_equipe    equipe.nome%TYPE;
  v_nome_pessoa    pessoa.nome%TYPE;
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
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_equipe
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome_equipe IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_pessoa
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome_pessoa IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe_usuario
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não está associado a essa equipe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM equipe_usuario
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_equipe || ' / ' || v_nome_pessoa;
  v_compl_histor   := 'Exclusão de usuário da equipe';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END usuario_excluir;
 --
 --
 PROCEDURE guide_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 07/08/2020
  -- DESCRICAO: Indicacao de usuario guide
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_flag_guide        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           equipe.nome%TYPE;
  v_usuario        pessoa.apelido%TYPE;
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
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_guide) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag guide inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE equipe_usuario
     SET flag_guide = TRIM(p_flag_guide)
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Indicação de guide: ' || v_usuario || ' - ' || p_flag_guide;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END guide_atualizar;
 --
 --
 PROCEDURE membro_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/12/2019
  -- DESCRICAO: Indicacao de usuario membro
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_flag_membro       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           equipe.nome%TYPE;
  v_usuario        pessoa.apelido%TYPE;
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
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_membro) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag membro inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE equipe_usuario
     SET flag_membro = TRIM(p_flag_membro)
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Indicação de membro: ' || v_usuario || ' - ' || p_flag_membro;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END membro_atualizar;
 --
 --
 PROCEDURE responsavel_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 04/12/2019
  -- DESCRICAO: Indicacao de usuario responsavel
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_flag_responsavel  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           equipe.nome%TYPE;
  v_usuario        pessoa.apelido%TYPE;
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
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_responsavel) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag responsável inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE equipe_usuario
     SET flag_responsavel = TRIM(p_flag_responsavel)
   WHERE equipe_id = p_equipe_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Indicação de responsável: ' || v_usuario || ' - ' || p_flag_responsavel;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END responsavel_atualizar;
 --
 --
 PROCEDURE tipo_tarefa_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 28/07/2021
  -- DESCRICAO: Indicacao de tipo de tarefa usada pela equipe
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_equipe_id         IN equipe.equipe_id%TYPE,
  p_tipo_tarefa_id    IN equipe.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_equipe    equipe.nome%TYPE;
  v_nome_tipo      tipo_tarefa.nome%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_equipe
    FROM equipe
   WHERE equipe_id = p_equipe_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome_equipe IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa equipe não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EQUIPE_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_tarefa_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento dio Tipo de Task é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_tipo
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome_tipo IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE equipe
     SET tipo_tarefa_id = p_tipo_tarefa_id
   WHERE equipe_id = p_equipe_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  equipe_pkg.xml_gerar(p_equipe_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_equipe;
  v_compl_histor   := 'Indicação de tipo de task: ' || v_nome_tipo;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'EQUIPE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_equipe_id,
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
 END tipo_tarefa_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/12/2019
  -- DESCRICAO: Subrotina que gera o xml do equipe para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_equipe_id IN equipe.equipe_id%TYPE,
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
  CURSOR c_cl IS
   SELECT pe.apelido,
          eu.flag_membro,
          eu.flag_responsavel,
          eu.flag_guide
     FROM equipe_usuario eu,
          pessoa         pe
    WHERE eu.equipe_id = p_equipe_id
      AND eu.usuario_id = pe.pessoa_id
    ORDER BY pe.apelido;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("equipe_id", eq.equipe_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", eq.nome),
                   xmlelement("usado_em_dist_workflow", eq.flag_em_dist_os),
                   xmlelement("tipo_task", ti.nome))
    INTO v_xml
    FROM equipe      eq,
         tipo_tarefa ti
   WHERE eq.equipe_id = p_equipe_id
     AND eq.tipo_tarefa_id = ti.tipo_tarefa_id(+);
  --
  ------------------------------------------------------------
  -- monta CLIENTES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_cl IN c_cl
  LOOP
   SELECT xmlconcat(xmlelement("nome", r_cl.apelido),
                    xmlelement("membro", r_cl.flag_membro),
                    xmlelement("responsavel", r_cl.flag_responsavel),
                    xmlelement("responsavel", r_cl.flag_guide))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("usuarios", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "equipe"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("equipe", v_xml))
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
END; -- EQUIPE_PKG



/
