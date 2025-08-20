--------------------------------------------------------
--  DDL for Package Body MILESTONE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "MILESTONE_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado        ProcessMind     DATA: 16/02/2007
  -- DESCRICAO: Inclusão de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/01/2010  Novo parametro (vetor de usuarios).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_papel_resp_id           IN milestone.papel_resp_id%TYPE,
  p_job_id                  IN milestone.job_id%TYPE,
  p_vetor_tipo_milestone_id IN LONG,
  p_data_milestone          IN VARCHAR2,
  p_hora_ini                IN milestone.hora_ini%TYPE,
  p_hora_fim                IN milestone.hora_fim%TYPE,
  p_descricao               IN milestone.descricao%TYPE,
  p_vetor_usuario_id        IN VARCHAR2,
  p_milestone_id            OUT milestone.milestone_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_milestone_id            milestone.milestone_id%TYPE;
  v_data_milestone          milestone.data_milestone%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_tipo_milestone_id LONG;
  v_tipo_milestone_id       tipo_milestone.tipo_milestone_id%TYPE;
  v_vetor_usuario_id        LONG;
  v_usuario_id              milestone_usuario.usuario_id%TYPE;
  v_lbl_job                 VARCHAR2(100);
  --
 BEGIN
  v_qt           := 0;
  p_milestone_id := 0;
  v_lbl_job      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE job_id = p_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
    RAISE v_exception;
   END IF;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 p_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_milestone) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_milestone) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora inicial inválida.';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora final inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_papel_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel responsável não existe.';
   RAISE v_exception;
  END IF;
  --
  v_data_milestone := data_converter(p_data_milestone);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_milestone.nextval
    INTO v_milestone_id
    FROM dual;
  --
  INSERT INTO milestone
   (milestone_id,
    empresa_id,
    papel_resp_id,
    usuario_autor_id,
    job_id,
    data_milestone,
    hora_ini,
    hora_fim,
    descricao,
    data_criacao,
    flag_fechado)
  VALUES
   (v_milestone_id,
    p_empresa_id,
    p_papel_resp_id,
    p_usuario_sessao_id,
    zvl(p_job_id, NULL),
    v_data_milestone,
    p_hora_ini,
    p_hora_fim,
    p_descricao,
    SYSDATE,
    'N');
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo_milestone
  ------------------------------------------------------------
  v_vetor_tipo_milestone_id := p_vetor_tipo_milestone_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_milestone_id)), 0) > 0
  LOOP
   v_tipo_milestone_id := to_number(prox_valor_retornar(v_vetor_tipo_milestone_id,
                                                        v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_milestone
    WHERE tipo_milestone_id = v_tipo_milestone_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Milestone inválido.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO tipific_milestone
    (milestone_id,
     tipo_milestone_id)
   VALUES
    (v_milestone_id,
     v_tipo_milestone_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de usuario
  ------------------------------------------------------------
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   IF nvl(v_usuario_id, 0) > 0 THEN
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario
     WHERE usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário inválido.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM milestone_usuario
     WHERE usuario_id = v_usuario_id
       AND milestone_id = v_milestone_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO milestone_usuario
      (milestone_id,
       usuario_id)
     VALUES
      (v_milestone_id,
       v_usuario_id);
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || p_descricao;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'INCLUIR',
                   v_identif_objeto,
                   v_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_milestone_id := v_milestone_id;
  p_erro_cod     := '00000';
  p_erro_msg     := 'Operação realizada com sucesso.';
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado        ProcessMind     DATA: 16/02/2007
  -- DESCRICAO: Atualização de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/01/2010  Novo parametro (vetor de usuarios).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_milestone_id            IN milestone.milestone_id%TYPE,
  p_papel_resp_id           IN milestone.papel_resp_id%TYPE,
  p_vetor_tipo_milestone_id IN LONG,
  p_data_milestone          IN VARCHAR2,
  p_hora_ini                IN milestone.hora_ini%TYPE,
  p_hora_fim                IN milestone.hora_fim%TYPE,
  p_descricao               IN milestone.descricao%TYPE,
  p_vetor_usuario_id        IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_delimitador             CHAR(1);
  v_vetor_tipo_milestone_id LONG;
  v_tipo_milestone_id       tipo_milestone.tipo_milestone_id%TYPE;
  v_data_milestone          milestone.data_milestone%TYPE;
  v_job_id                  milestone.job_id%TYPE;
  v_vetor_usuario_id        LONG;
  v_usuario_id              milestone_usuario.usuario_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE milestone_id = p_milestone_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id
    INTO v_job_id
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_milestone) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_milestone) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora inicial inválida.';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora final inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_papel_resp_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel responsável não existe.';
   RAISE v_exception;
  END IF;
  --
  v_data_milestone := data_converter(p_data_milestone);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE milestone
     SET papel_resp_id  = p_papel_resp_id,
         data_milestone = v_data_milestone,
         hora_ini       = p_hora_ini,
         hora_fim       = p_hora_fim,
         descricao      = p_descricao
   WHERE milestone_id = p_milestone_id;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo_milestone
  ------------------------------------------------------------
  v_vetor_tipo_milestone_id := p_vetor_tipo_milestone_id;
  --
  DELETE FROM tipific_milestone
   WHERE milestone_id = p_milestone_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_milestone_id)), 0) > 0
  LOOP
   v_tipo_milestone_id := to_number(prox_valor_retornar(v_vetor_tipo_milestone_id,
                                                        v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_milestone
    WHERE tipo_milestone_id = v_tipo_milestone_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Milestone inválido.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO tipific_milestone
    (milestone_id,
     tipo_milestone_id)
   VALUES
    (p_milestone_id,
     v_tipo_milestone_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de usuario
  ------------------------------------------------------------
  v_vetor_usuario_id := p_vetor_usuario_id;
  --
  DELETE FROM milestone_usuario
   WHERE milestone_id = p_milestone_id;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --
   IF nvl(v_usuario_id, 0) > 0 THEN
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario
     WHERE usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário inválido.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM milestone_usuario
     WHERE usuario_id = v_usuario_id
       AND milestone_id = p_milestone_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO milestone_usuario
      (milestone_id,
       usuario_id)
     VALUES
      (p_milestone_id,
       v_usuario_id);
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || p_descricao;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
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
 END; -- atualizar
 --
 --
 PROCEDURE atualizar_data
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado        ProcessMind     DATA: 16/02/2007
  -- DESCRICAO: Atualização de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_milestone_id      IN milestone.milestone_id%TYPE,
  p_data_milestone    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_delimitador             CHAR(1);
  v_vetor_tipo_milestone_id LONG;
  v_tipo_milestone_id       tipo_milestone.tipo_milestone_id%TYPE;
  v_data_milestone          milestone.data_milestone%TYPE;
  v_job_id                  milestone.job_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE milestone_id = p_milestone_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id
    INTO v_job_id
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_milestone) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_milestone) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_milestone := data_converter(p_data_milestone);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE milestone
     SET data_milestone = v_data_milestone
   WHERE milestone_id = p_milestone_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
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
 END; -- atualizar_data
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado        ProcessMind     DATA: 16/02/2007
  -- DESCRICAO: Exclusão de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/01/2010  Exclusao de usuarios associados ao milestone.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_milestone_id      IN milestone.milestone_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_job_id           milestone.job_id%TYPE;
  v_usuario_autor_id milestone.usuario_autor_id%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_descricao        milestone.descricao%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE milestone_id = p_milestone_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id,
         usuario_autor_id,
         data_milestone,
         descricao
    INTO v_job_id,
         v_usuario_autor_id,
         v_data_milestone,
         v_descricao
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE milestone_id = p_milestone_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone está sendo referenciado por tasks.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE milestone_id = p_milestone_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone está sendo referenciado por Workflows.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipific_milestone
   WHERE milestone_id = p_milestone_id;
  --
  DELETE FROM milestone_usuario
   WHERE milestone_id = p_milestone_id;
  --
  DELETE FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_descricao;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
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
 END; -- excluir
 --
 --
 PROCEDURE fechar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 27/02/2007
  -- DESCRICAO: Fechamento de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_milestone_id      IN milestone.milestone_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_job_id           milestone.job_id%TYPE;
  v_usuario_autor_id milestone.usuario_autor_id%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_descricao        milestone.descricao%TYPE;
  v_flag_fechado     milestone.flag_fechado%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE milestone_id = p_milestone_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id,
         usuario_autor_id,
         data_milestone,
         descricao,
         flag_fechado
    INTO v_job_id,
         v_usuario_autor_id,
         v_data_milestone,
         v_descricao,
         v_flag_fechado
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_flag_fechado = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone já se encontra fechado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE milestone
     SET flag_fechado = 'S'
   WHERE milestone_id = p_milestone_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_descricao;
  v_compl_histor   := 'Fechamento de Milestone';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
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
 END; -- fechar
 --
 --
 PROCEDURE reabrir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 27/02/2007
  -- DESCRICAO: Reabertura de MILESTONE
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_milestone_id      IN milestone.milestone_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_job_id           milestone.job_id%TYPE;
  v_usuario_autor_id milestone.usuario_autor_id%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_descricao        milestone.descricao%TYPE;
  v_flag_fechado     milestone.flag_fechado%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE milestone_id = p_milestone_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id,
         usuario_autor_id,
         data_milestone,
         descricao,
         flag_fechado
    INTO v_job_id,
         v_usuario_autor_id,
         v_data_milestone,
         v_descricao,
         v_flag_fechado
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_MILESTONE_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'MILESTONE_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_flag_fechado = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse milestone já se encontra aberto.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE milestone
     SET flag_fechado = 'N'
   WHERE milestone_id = p_milestone_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_descricao;
  v_compl_histor   := 'Reabertura de Milestone';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'MILESTONE',
                   'ALTERAR',
                   v_identif_objeto,
                   p_milestone_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
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
 END; -- reabrir
 --
 --
 FUNCTION atrasado_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/02/2007
  -- DESCRICAO: verifica se um determinado milestone está atrasado ou nao. Retorna 1 caso
  --  esteja atrasado e 0 caso nao esteja.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_milestone_id IN milestone.milestone_id%TYPE
 ) RETURN INTEGER AS
  v_retorno        INTEGER;
  v_data_milestone milestone.data_milestone%TYPE;
  v_flag_fechado   milestone.flag_fechado%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT data_milestone,
         flag_fechado
    INTO v_data_milestone,
         v_flag_fechado
    FROM milestone
   WHERE milestone_id = p_milestone_id;
  --
  IF v_flag_fechado = 'N' AND trunc(SYSDATE) - trunc(v_data_milestone) > 0 THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_retorno;
 END atrasado_verificar;
 --
 --
 FUNCTION data_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/03/2012
  -- DESCRICAO: retorna a data do proximo milestone (ou do anterior dependendo do sentido)
  --  de um determinado usuario a partir de uma determinada data de referencia, exceto quando
  --  existir um dia util que se aproxime mais dessa data de referencia. O usuario pode ser
  --  tanto autor como participante do milestone.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id IN milestone.empresa_id%TYPE,
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_data_refer IN DATE,
  p_sentido    IN VARCHAR2
 ) RETURN DATE AS
  v_data_evento     DATE;
  v_exception       EXCEPTION;
  v_dia_util        DATE;
  v_data_milestone1 DATE;
  v_data_milestone2 DATE;
  --
 BEGIN
  v_data_evento := NULL;
  --
  IF p_data_refer IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_sentido) IS NULL OR p_sentido NOT IN ('ANT', 'PROX') THEN
   RAISE v_exception;
  END IF;
  --
  IF p_sentido = 'ANT' THEN
   v_dia_util := feriado_pkg.prox_dia_util_retornar(p_usuario_id, p_data_refer, -1, 'N');
   --
   SELECT MAX(data_milestone)
     INTO v_data_milestone1
     FROM milestone
    WHERE empresa_id = p_empresa_id
      AND usuario_autor_id = p_usuario_id
      AND data_milestone < p_data_refer;
   --
   SELECT MAX(mi.data_milestone)
     INTO v_data_milestone2
     FROM milestone         mi,
          milestone_usuario mu
    WHERE mi.empresa_id = p_empresa_id
      AND data_milestone < p_data_refer
      AND mi.milestone_id = mu.milestone_id
      AND mu.usuario_id = p_usuario_id;
   --
   v_data_evento := v_dia_util;
   --
   IF v_data_milestone1 > v_data_evento THEN
    v_data_evento := v_data_milestone1;
   END IF;
   --
   IF v_data_milestone2 > v_data_evento THEN
    v_data_evento := v_data_milestone2;
   END IF;
  END IF;
  --
  IF p_sentido = 'PROX' THEN
   v_dia_util := feriado_pkg.prox_dia_util_retornar(p_usuario_id, p_data_refer, 1, 'N');
   --
   SELECT MIN(data_milestone)
     INTO v_data_milestone1
     FROM milestone
    WHERE empresa_id = p_empresa_id
      AND usuario_autor_id = p_usuario_id
      AND data_milestone > p_data_refer;
   --
   SELECT MIN(mi.data_milestone)
     INTO v_data_milestone2
     FROM milestone         mi,
          milestone_usuario mu
    WHERE mi.empresa_id = p_empresa_id
      AND data_milestone > p_data_refer
      AND mi.milestone_id = mu.milestone_id
      AND mu.usuario_id = p_usuario_id;
   --
   v_data_evento := v_dia_util;
   --
   IF v_data_milestone1 < v_data_evento THEN
    v_data_evento := v_data_milestone1;
   END IF;
   --
   IF v_data_milestone2 < v_data_evento THEN
    v_data_evento := v_data_milestone2;
   END IF;
  END IF;
  --
  RETURN v_data_evento;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data_evento;
 END data_evento_retornar;
 --
--
END; -- MILESTONE_PKG



/
