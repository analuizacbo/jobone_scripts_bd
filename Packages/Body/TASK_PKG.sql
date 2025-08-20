--------------------------------------------------------
--  DDL for Package Body TASK_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TASK_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 15/02/2007
  -- DESCRICAO: Inclusão de TASK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Eduardo Delgado   21/02/2007  Inclusão do histórico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN task.job_id%TYPE,
  p_milestone_id      IN task.milestone_id%TYPE,
  p_papel_resp_id     IN task.papel_resp_id%TYPE,
  p_desc_curta        IN task.desc_curta%TYPE,
  p_desc_detalhada    IN LONG,
  p_prioridade        IN task.prioridade%TYPE,
  p_tipo_task         IN task.tipo_task%TYPE,
  p_task_id           OUT task.task_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_task_id        task.task_id%TYPE;
  v_data_task      task.data_task%TYPE;
  v_job_id         job.job_id%TYPE;
  v_desc_milestone milestone.descricao%TYPE;
  v_data_milestone milestone.data_milestone%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  p_task_id := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_job_id, 0) > 0 AND nvl(p_milestone_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ' || v_lbl_job ||
                 ' e o Milestone não devem ser fornecidos ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_job_id, 0) = 0 AND nvl(p_milestone_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ' || v_lbl_job || ' ou o Milestone devem ser fornecidos.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_milestone_id, 0) > 0 THEN
   -- a task pertence ao milestone
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
          descricao,
          data_milestone
     INTO v_job_id,
          v_desc_milestone,
          v_data_milestone
     FROM milestone
    WHERE milestone_id = p_milestone_id;
  ELSE
   -- a task pertence ao job
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
   v_data_task := trunc(SYSDATE) + 1;
   v_job_id    := p_job_id;
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   -- usuarios enderecados no job podem criar tasks
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_V', v_job_id, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
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
  IF rtrim(p_desc_curta) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição curta é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_detalhada) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição detalhada não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_prioridade) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da prioridade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_prioridade NOT IN ('A', 'M', 'B') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da prioridade inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_task.nextval
    INTO v_task_id
    FROM dual;
  --
  INSERT INTO task
   (task_id,
    empresa_id,
    milestone_id,
    papel_resp_id,
    usuario_autor_id,
    job_id,
    data_task,
    desc_curta,
    desc_detalhada,
    prioridade,
    flag_fechado,
    compl_fecham,
    tipo_task)
  VALUES
   (v_task_id,
    p_empresa_id,
    zvl(p_milestone_id, NULL),
    p_papel_resp_id,
    p_usuario_sessao_id,
    v_job_id,
    v_data_task,
    p_desc_curta,
    p_desc_detalhada,
    p_prioridade,
    'N',
    NULL,
    p_tipo_task);
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           v_task_id,
                           'CRIACAO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(p_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Inclusão de task (' || p_desc_curta || ')';
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
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  --
  p_task_id  := v_task_id;
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 15/02/2007
  -- DESCRICAO: Atualização de TASK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_id           IN task.task_id%TYPE,
  p_papel_resp_id     IN task.papel_resp_id%TYPE,
  p_desc_curta        IN task.desc_curta%TYPE,
  p_desc_detalhada    IN LONG,
  p_prioridade        IN task.prioridade%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_milestone_id     milestone.milestone_id%TYPE;
  v_desc_milestone   milestone.descricao%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_usuario_autor_id task.usuario_autor_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mi.job_id,
         mi.descricao,
         mi.data_milestone,
         mi.milestone_id,
         ta.usuario_autor_id
    INTO v_job_id,
         v_desc_milestone,
         v_data_milestone,
         v_milestone_id,
         v_usuario_autor_id
    FROM milestone mi,
         task      ta
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  -- apenas o autor da task pode atualizar
  IF p_usuario_sessao_id <> v_usuario_autor_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
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
  IF rtrim(p_desc_curta) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição curta é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_detalhada) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição detalhada não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_prioridade) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da prioridade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_prioridade NOT IN ('A', 'M', 'B') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da prioridade inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE task
     SET papel_resp_id  = p_papel_resp_id,
         desc_curta     = p_desc_curta,
         desc_detalhada = p_desc_detalhada,
         prioridade     = p_prioridade
   WHERE task_id = p_task_id;
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_task_id,
                           'ALTERACAO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Alteração de task (' || p_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 15/02/2007
  -- DESCRICAO: Exclusão de TASK
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_id           IN task.task_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_milestone_id     milestone.milestone_id%TYPE;
  v_desc_milestone   milestone.descricao%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_usuario_autor_id task.usuario_autor_id%TYPE;
  v_desc_curta       task.desc_curta%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mi.job_id,
         mi.descricao,
         mi.data_milestone,
         mi.milestone_id,
         ta.usuario_autor_id,
         ta.desc_curta
    INTO v_job_id,
         v_desc_milestone,
         v_data_milestone,
         v_milestone_id,
         v_usuario_autor_id,
         v_desc_curta
    FROM milestone mi,
         task      ta
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  -- apenas o autor da task pode atualizar
  IF p_usuario_sessao_id <> v_usuario_autor_id THEN
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
    FROM task_coment
   WHERE task_id = p_task_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task tem comentários associados.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_task
   WHERE task_id = p_task_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task tem arquivos associados.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task_hist
   WHERE task_id = p_task_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task tem históricos associados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM task
   WHERE task_id = p_task_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Exclusão de task (' || v_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado            ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Adicionar arquivo na task
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_task_id           IN arquivo_task.task_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_usuario_autor_id task.usuario_autor_id%TYPE;
  v_papel_resp_id    task.papel_resp_id%TYPE;
  v_milestone_id     task.milestone_id%TYPE;
  v_desc_curta       task.desc_curta%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_desc_milestone   milestone.descricao%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_tipo_arquivo_id  tipo_arquivo.tipo_arquivo_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ta.usuario_autor_id,
         ta.papel_resp_id,
         ta.milestone_id,
         ta.desc_curta,
         mi.job_id,
         mi.descricao,
         mi.data_milestone
    INTO v_usuario_autor_id,
         v_papel_resp_id,
         v_milestone_id,
         v_desc_curta,
         v_job_id,
         v_desc_milestone,
         v_data_milestone
    FROM task      ta,
         milestone mi
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel
   WHERE papel_id = v_papel_resp_id
     AND usuario_id = p_usuario_sessao_id;
  --
  -- apenas o autor ou o usuario endereçado da task pode incluir arquivo
  IF p_usuario_sessao_id <> v_usuario_autor_id AND v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'TASK';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_task_id,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_task_id,
                           'ANEXACAO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Anexação de arquivo na task (' || v_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
 END; -- arquivo_adicionar
 --
 --
 PROCEDURE comentario_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado            ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Inclusão de comentário da task
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_task_id           IN task_coment.task_id%TYPE,
  p_comentario        IN LONG,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_task_coment_id task_coment.task_coment_id%TYPE;
  v_milestone_id   task.milestone_id%TYPE;
  v_desc_curta     task.desc_curta%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_desc_milestone milestone.descricao%TYPE;
  v_data_milestone milestone.data_milestone%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mi.job_id,
         mi.descricao,
         mi.data_milestone,
         mi.milestone_id,
         ta.desc_curta
    INTO v_job_id,
         v_desc_milestone,
         v_data_milestone,
         v_milestone_id,
         v_desc_curta
    FROM milestone mi,
         task      ta
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_comentario) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do comentário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_comentario) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do comentário não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_task_coment.nextval
    INTO v_task_coment_id
    FROM dual;
  --
  INSERT INTO task_coment
   (task_coment_id,
    task_id,
    usuario_id,
    data,
    comentario)
  VALUES
   (v_task_coment_id,
    p_task_id,
    p_usuario_sessao_id,
    SYSDATE,
    rtrim(p_comentario));
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_task_id,
                           'COMENTARIO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Inclusão de comentario na task (' || v_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
  END IF;
  --
  IF p_flag_commit = 'S' THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END; -- comentario_adicionar
 --
 --
 PROCEDURE fechar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado            ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Fechamento da task. Caso o parametro p_comentario esteja preenchido,
  --   inclui tambem um comentario referente a essa task (usado no caso de documento).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/04/2007  Alteracao na checagem do privilegio.
  -- Silvia            28/08/2017  Consolidacao autom. na ultima acao. Geracao de evento.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_task_id           IN task.task_id%TYPE,
  p_compl_fecham      IN task.compl_fecham%TYPE,
  p_comentario        IN LONG,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_usuario_autor_id task.usuario_autor_id%TYPE;
  v_papel_resp_id    task.papel_resp_id%TYPE;
  v_milestone_id     task.milestone_id%TYPE;
  v_desc_curta       task.desc_curta%TYPE;
  v_flag_fechado     task.flag_fechado%TYPE;
  v_tipo_task        task.tipo_task%TYPE;
  v_objeto_id        task.objeto_id%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_desc_milestone   milestone.descricao%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  v_cod_objeto       tipo_objeto.codigo%TYPE;
  v_nome_docum       documento.nome%TYPE;
  v_tipo_fluxo       documento.tipo_fluxo%TYPE;
  v_nome_tipo_doc    tipo_documento.nome%TYPE;
  v_gera_evento_doc  NUMBER(5);
  v_texto_fluxo      VARCHAR2(50);
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_compl_fecham) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complemento do fechamento não informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_compl_fecham NOT IN ('OK', 'NOK', 'INV', 'DUP', 'SIS') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complemento do fechamento inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT mi.job_id,
         mi.descricao,
         mi.data_milestone,
         mi.milestone_id,
         ta.usuario_autor_id,
         ta.papel_resp_id,
         ta.desc_curta,
         ta.flag_fechado,
         tb.codigo,
         ta.tipo_task,
         ta.objeto_id
    INTO v_job_id,
         v_desc_milestone,
         v_data_milestone,
         v_milestone_id,
         v_usuario_autor_id,
         v_papel_resp_id,
         v_desc_curta,
         v_flag_fechado,
         v_cod_objeto,
         v_tipo_task,
         v_objeto_id
    FROM milestone   mi,
         task        ta,
         tipo_objeto tb
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+)
     AND ta.tipo_objeto_id = tb.tipo_objeto_id;
  --
  IF nvl(v_job_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario   ju,
          usuario_papel up
    WHERE up.papel_id = v_papel_resp_id
      AND up.usuario_id = p_usuario_sessao_id
      AND up.usuario_id = ju.usuario_id
      AND ju.job_id = v_job_id;
  ELSE
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel
    WHERE papel_id = v_papel_resp_id
      AND usuario_id = p_usuario_sessao_id;
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   -- apenas o autor ou o usuario endereçado da task pode atualizar
   IF p_usuario_sessao_id <> v_usuario_autor_id AND v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_comentario) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do comentário não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_fechado = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task já se encontra fechada.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE task
     SET flag_fechado = 'S',
         compl_fecham = p_compl_fecham
   WHERE task_id = p_task_id;
  --
  IF TRIM(p_comentario) IS NOT NULL THEN
   task_pkg.comentario_adicionar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 p_task_id,
                                 p_comentario,
                                 p_erro_cod,
                                 p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_task_id,
                           'FECHAMENTO',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- para documento, verifica se precisa consolidar (exceto
  -- qdo o fechamento for disparado pelo sistema)
  ------------------------------------------------------------
  IF v_cod_objeto = 'DOCUMENTO' AND v_tipo_task = 'DOC_ANALISE_MSG' AND
     p_compl_fecham <> 'SIS' THEN
   v_gera_evento_doc := 1;
   --
   SELECT MAX(dc.nome),
          MAX(td.nome),
          MAX(dc.tipo_fluxo)
     INTO v_nome_docum,
          v_nome_tipo_doc,
          v_tipo_fluxo
     FROM documento      dc,
          tipo_documento td
    WHERE dc.documento_id = v_objeto_id
      AND dc.tipo_documento_id = td.tipo_documento_id;
   --
   IF v_tipo_fluxo = 'AP' THEN
    v_texto_fluxo := 'Aprovação';
   ELSIF v_tipo_fluxo = 'CO' THEN
    v_texto_fluxo := 'Comentário';
   ELSIF v_tipo_fluxo = 'CI' THEN
    v_texto_fluxo := 'Ciência';
   END IF;
   --
   -- verifica se tem task aberta para esse documento.
   SELECT COUNT(*)
     INTO v_qt
     FROM task
    WHERE objeto_id = v_objeto_id
      AND tipo_task = v_tipo_task
      AND flag_fechado = 'N';
   --
   IF v_qt = 0 THEN
    -- nao tem task aberta. Verifca se entre as fechadas tem alguma reprovada.
    SELECT COUNT(*)
      INTO v_qt
      FROM task
     WHERE objeto_id = v_objeto_id
       AND tipo_task = v_tipo_task
       AND flag_fechado = 'S'
       AND compl_fecham = 'NOK';
    --
    IF v_qt = 0 THEN
     -- nao existe reprovacao. Pode consolidar.
     UPDATE documento
        SET status = 'OK'
      WHERE documento_id = v_objeto_id;
     --
     -- gera xml do log
     documento_pkg.xml_gerar(v_objeto_id, v_xml_atual, p_erro_cod, p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     -- geracao de evento de aprovacao final
     v_identif_objeto := to_char(v_objeto_id);
     v_compl_histor   := v_nome_tipo_doc || ' - ' || v_nome_docum || ' (Último(a) ' ||
                         v_texto_fluxo || ')';
     --
     evento_pkg.gerar(p_usuario_sessao_id,
                      p_empresa_id,
                      'DOCUMENTO',
                      'APROVAR',
                      v_identif_objeto,
                      v_objeto_id,
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
     -- teve consolidacao de documento. Nao precisa gerar evento de
     -- aprov/reprov individual.
     v_gera_evento_doc := 0;
    END IF;
   END IF;
   --
   IF v_gera_evento_doc = 1 THEN
    -- geracao de evento de aprovacao individual
    v_identif_objeto := to_char(v_objeto_id);
    v_compl_histor   := v_nome_tipo_doc || ' - ' || v_nome_docum || ' (' || v_texto_fluxo || ')';
    --
    evento_pkg.gerar(p_usuario_sessao_id,
                     p_empresa_id,
                     'DOCUMENTO',
                     'NOTIFICAR',
                     v_identif_objeto,
                     v_objeto_id,
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
   END IF;
  END IF; -- fim do IF v_cod_objeto = 'DOCUMENTO'
  --
  ------------------------------------------------------------
  -- geracao de evento de MILESTONE
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Fechamento de task (' || v_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
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
  -- DESENVOLVEDOR: Eduardo Delgado            ProcessMind     DATA: 22/02/2007
  -- DESCRICAO: Reabertura da task
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_id           IN task.task_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_usuario_autor_id task.usuario_autor_id%TYPE;
  v_papel_resp_id    task.papel_resp_id%TYPE;
  v_milestone_id     task.milestone_id%TYPE;
  v_desc_curta       task.desc_curta%TYPE;
  v_compl_fecham     task.compl_fecham%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_desc_milestone   milestone.descricao%TYPE;
  v_data_milestone   milestone.data_milestone%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT mi.job_id,
         mi.descricao,
         mi.data_milestone,
         mi.milestone_id,
         ta.usuario_autor_id,
         ta.papel_resp_id,
         ta.desc_curta,
         ta.compl_fecham
    INTO v_job_id,
         v_desc_milestone,
         v_data_milestone,
         v_milestone_id,
         v_usuario_autor_id,
         v_papel_resp_id,
         v_desc_curta,
         v_compl_fecham
    FROM milestone mi,
         task      ta
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel
   WHERE papel_id = v_papel_resp_id
     AND usuario_id = p_usuario_sessao_id;
  --
  -- apenas o autor ou o usuario endereçado da task pode atualizar
  IF p_usuario_sessao_id <> v_usuario_autor_id AND v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_compl_fecham = 'SIS' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não pode ser reaberta foi foi fechada via sistema.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE task
     SET flag_fechado = 'N'
   WHERE task_id = p_task_id;
  --
  -- gera historico
  task_pkg.historico_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           p_task_id,
                           'REABERTURA',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_milestone_id, 0) > 0 THEN
   v_identif_objeto := data_mostrar(v_data_milestone) || ' - ' || v_desc_milestone;
   v_compl_histor   := 'Reabertura de task (' || v_desc_curta || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'MILESTONE',
                    'ALTERAR',
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
 PROCEDURE historico_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Eduardo Delgado         ProcessMind     DATA: 21/02/2007
  -- DESCRICAO: subrotina que registra o historico da task. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/03/2010  Troca do texto de task para pedido.
  -- Silvia            31/08/2015  Volta o texto de pedido para tarefa.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_id           IN item.item_id%TYPE,
  p_codigo            IN item_hist.codigo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_descricao    item_hist.descricao%TYPE;
  v_compl_fecham task.compl_fecham%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT rtrim(compl_fecham)
    INTO v_compl_fecham
    FROM task
   WHERE task_id = p_task_id
     AND empresa_id = p_empresa_id;
  --
  IF p_codigo = 'CRIACAO' THEN
   v_descricao := 'Criou tarefa';
  ELSIF p_codigo = 'ALTERACAO' THEN
   v_descricao := 'Alterou tarefa';
  ELSIF p_codigo = 'ANEXACAO' THEN
   v_descricao := 'Anexou arquivo na tarefa';
  ELSIF p_codigo = 'COMENTARIO' THEN
   v_descricao := 'Incluiu comentário na tarefa';
  ELSIF p_codigo = 'FECHAMENTO' AND v_compl_fecham = 'OK' THEN
   v_descricao := 'Fechou tarefa (feita/aprovada)';
  ELSIF p_codigo = 'FECHAMENTO' AND v_compl_fecham = 'NOK' THEN
   v_descricao := 'Fechou tarefa (não feita/reprovada)';
  ELSIF p_codigo = 'FECHAMENTO' AND v_compl_fecham = 'INV' THEN
   v_descricao := 'Fechou tarefa (inválida)';
  ELSIF p_codigo = 'FECHAMENTO' AND v_compl_fecham = 'DUP' THEN
   v_descricao := 'Fechou tarefa (duplicada)';
  ELSIF p_codigo = 'FECHAMENTO' AND v_compl_fecham = 'SIS' THEN
   v_descricao := 'Fechou tarefa (via sistema)';
  ELSIF p_codigo = 'REABERTURA' THEN
   v_descricao := 'Reabriu tarefa';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do histórico da task inválido (' || p_codigo || '-' || v_compl_fecham || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO task_hist
   (task_hist_id,
    task_id,
    usuario_id,
    data,
    codigo,
    descricao)
  VALUES
   (seq_task_hist.nextval,
    p_task_id,
    p_usuario_sessao_id,
    SYSDATE,
    p_codigo,
    v_descricao);
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
 END historico_gerar;
 --
 --
 PROCEDURE ciente_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/02/2007
  -- DESCRICAO: marca que determinado registro de historico de task foi acessado/lido pelo
  --    usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_task_hist_id      IN task_hist.task_hist_id%TYPE,
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
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM task_hist_ciencia
   WHERE task_hist_id = p_task_hist_id
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   INSERT INTO task_hist_ciencia
    (task_hist_id,
     usuario_id,
     data)
   VALUES
    (p_task_hist_id,
     p_usuario_sessao_id,
     SYSDATE);
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
 END ciente_marcar;
 --
 --
 FUNCTION ciente_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/03/2007
  -- DESCRICAO: verifica se um determinado registro de historico da task foi lido/acessado
  --   por um determinado usuario. Retorna 0 - caso nao ou 1 - caso sim.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_task_hist_id      IN task_hist.task_hist_id%TYPE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task_hist_ciencia
   WHERE task_hist_id = p_task_hist_id
     AND usuario_id = p_usuario_sessao_id;
  --
  IF v_qt > 0 THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END ciente_verificar;
 --
 --
 FUNCTION data_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a data referente a um determinado evento da task (criacao,
  --   fechamento, comentario etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_task_id IN task_hist.task_id%TYPE,
  p_codigo  IN task_hist.codigo%TYPE
 ) RETURN DATE AS
  v_qt      INTEGER;
  v_retorno DATE;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_codigo = 'FECHAMENTO' THEN
   SELECT MAX(th.data)
     INTO v_retorno
     FROM task_hist th,
          task      ta
    WHERE th.task_id = p_task_id
      AND th.codigo = p_codigo
      AND th.task_id = ta.task_id
      AND ta.flag_fechado = 'S';
  ELSIF p_codigo = 'REBERTURA' THEN
   SELECT MAX(th.data)
     INTO v_retorno
     FROM task_hist th,
          task      ta
    WHERE th.task_id = p_task_id
      AND th.codigo = p_codigo
      AND th.task_id = ta.task_id
      AND ta.flag_fechado = 'N';
  ELSE
   SELECT MAX(data)
     INTO v_retorno
     FROM task_hist
    WHERE task_id = p_task_id
      AND codigo = p_codigo;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_evento_retornar;
 --
 --
 FUNCTION usuario_id_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o usuario_id responsavel pela execucao de um determinado evento
  --   da task (criacao, fechamento, comentario etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_task_id IN task_hist.task_id%TYPE,
  p_codigo  IN task_hist.codigo%TYPE
 ) RETURN NUMBER AS
  v_qt      INTEGER;
  v_retorno NUMBER;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_codigo = 'FECHAMENTO' THEN
   SELECT MAX(th.usuario_id)
     INTO v_retorno
     FROM task_hist th,
          task      ta
    WHERE th.task_id = p_task_id
      AND th.codigo = p_codigo
      AND th.task_id = ta.task_id
      AND ta.flag_fechado = 'S';
  ELSIF p_codigo = 'REBERTURA' THEN
   SELECT MAX(th.usuario_id)
     INTO v_retorno
     FROM task_hist th,
          task      ta
    WHERE th.task_id = p_task_id
      AND th.codigo = p_codigo
      AND th.task_id = ta.task_id
      AND ta.flag_fechado = 'N';
  ELSE
   SELECT MAX(usuario_id)
     INTO v_retorno
     FROM task_hist
    WHERE task_id = p_task_id
      AND codigo = p_codigo;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END usuario_id_evento_retornar;
 --
 --
 FUNCTION situacao_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/02/2007
  -- DESCRICAO: retorna o codigo da situacao de uma determinada task.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_task_id IN task_hist.task_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno      VARCHAR2(10);
  v_data         milestone.data_milestone%TYPE;
  v_flag_fechado task.flag_fechado%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT nvl(ta.data_task, mi.data_milestone),
         ta.flag_fechado
    INTO v_data,
         v_flag_fechado
    FROM task      ta,
         milestone mi
   WHERE ta.task_id = p_task_id
     AND ta.milestone_id = mi.milestone_id(+);
  --
  IF v_flag_fechado = 'S' THEN
   v_retorno := 'FECH';
  ELSE
   IF trunc(SYSDATE) > trunc(v_data) THEN
    v_retorno := 'ATRA';
   ELSIF trunc(SYSDATE) < trunc(v_data) THEN
    v_retorno := 'FUTU';
   ELSE
    v_retorno := 'ANDA';
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_retorno;
 END situacao_retornar;
 --
 --
 FUNCTION ult_comentario_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/02/2007
  -- DESCRICAO: retorna o comentario mais recente de uma determinada task (funcao usada
  --  em documentos).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_task_id IN task_hist.task_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno        task_coment.comentario%TYPE;
  v_task_coment_id task_coment.task_coment_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(task_coment_id)
    INTO v_task_coment_id
    FROM task_coment
   WHERE task_id = p_task_id;
  --
  IF v_task_coment_id IS NOT NULL THEN
   SELECT comentario
     INTO v_retorno
     FROM task_coment
    WHERE task_coment_id = v_task_coment_id;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_retorno;
 END ult_comentario_retornar;
 --
--
END; -- TASK_PKG



/
