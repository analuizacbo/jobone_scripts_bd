--------------------------------------------------------
--  DDL for Package Body JOB_PECA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "JOB_PECA_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/08/2006
  -- DESCRICAO: Adiciona uma nova peca ao job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/10/2006  Novo campo: data_solicitacao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job_peca.job_id%TYPE,
  p_tipo_peca_id      IN job_peca.tipo_peca_id%TYPE,
  p_complemento       IN job_peca.complemento%TYPE,
  p_especificacao     IN VARCHAR2,
  p_obs               IN VARCHAR2,
  p_tipo_solicitacao  IN VARCHAR2,
  p_data_prazo        IN VARCHAR2,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_nome_peca         tipo_peca.nome%TYPE;
  v_papel_resp_doc_id papel.papel_id%TYPE;
  v_job_peca_id       job_peca.job_peca_id%TYPE;
  v_doc_refer_id_ult  job_peca.doc_refer_id%TYPE;
  v_complemento       job_peca.complemento%TYPE;
  v_data_prazo        DATE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_tipo_documento_id tipo_documento.tipo_documento_id%TYPE;
  v_documento_id      documento.documento_id%TYPE;
  v_nome_documento    documento.nome%TYPE;
  v_lbl_job           VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_C',
                                p_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_documento_id)
    INTO v_tipo_documento_id
    FROM tipo_documento
   WHERE codigo = 'PECA_ESPEC';
  --
  -- descobre o papel do responsavel pela criacao do documento
  -- (dando preferencia para o papel com priv de responsavel interno).
  SELECT MAX(up.papel_id)
    INTO v_papel_resp_doc_id
    FROM usuario_papel up,
         papel         pa,
         papel_priv    pp,
         privilegio    pr
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND pa.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = 'JOB_RESP_INT_V';
  --
  IF v_papel_resp_doc_id IS NULL THEN
   SELECT MIN(up.papel_id)
     INTO v_papel_resp_doc_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id;
  END IF;
  --
  SELECT nome
    INTO v_nome_peca
    FROM tipo_peca
   WHERE tipo_peca_id = p_tipo_peca_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_peca_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de peça é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_especificacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da especificação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_especificacao) > 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da especificação não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_solicitacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prenchimento do tipo de solicitação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM dicionario
   WHERE tipo = 'tipo_solicitacao'
     AND codigo = p_tipo_solicitacao;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de solicitação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data_prazo  := data_converter(p_data_prazo);
  v_complemento := TRIM(p_complemento);
  --
  v_documento_id     := NULL;
  v_doc_refer_id_ult := ult_doc_retornar(p_job_id, p_tipo_peca_id, v_complemento, 'PECA_ESPEC');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_arquivo_id, 0) > 0 THEN
   -- veio um arquivo de referencia/especificacao de peca
   --
   IF v_doc_refer_id_ult IS NULL THEN
    -- primeiro documento de especificacao da peca (versao 1)
    v_nome_documento := rtrim(v_nome_peca || ' ' || v_complemento);
    --
    documento_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            p_job_id,
                            v_papel_resp_doc_id,
                            v_tipo_documento_id,
                            v_nome_documento,
                            substr(p_especificacao, 1, 200),
                            substr(p_obs, 1, 500),
                            'ND',
                            NULL,
                            NULL,
                            p_arquivo_id,
                            p_volume_id,
                            p_nome_original,
                            p_nome_fisico,
                            p_mime_type,
                            p_tamanho,
                            NULL,
                            0,
                            v_documento_id,
                            p_erro_cod,
                            p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- nova versao de especificacao da peca
    documento_pkg.versao_adicionar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   p_job_id,
                                   v_papel_resp_doc_id,
                                   v_doc_refer_id_ult,
                                   substr(p_obs, 1, 500),
                                   'ND',
                                   NULL,
                                   NULL,
                                   'N',
                                   p_arquivo_id,
                                   p_volume_id,
                                   p_nome_original,
                                   p_nome_fisico,
                                   p_mime_type,
                                   p_tamanho,
                                   NULL,
                                   v_documento_id,
                                   p_erro_cod,
                                   p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE documento
       SET descricao = substr(p_especificacao, 1, 200)
     WHERE documento_id = v_documento_id;
   END IF;
  END IF;
  --
  SELECT seq_job_peca.nextval
    INTO v_job_peca_id
    FROM dual;
  --
  INSERT INTO job_peca
   (job_peca_id,
    job_id,
    tipo_peca_id,
    complemento,
    tipo_solicitacao,
    data_prazo,
    especificacao,
    obs,
    status,
    data_status,
    doc_refer_id,
    data_solicitacao)
  VALUES
   (v_job_peca_id,
    p_job_id,
    p_tipo_peca_id,
    v_complemento,
    p_tipo_solicitacao,
    v_data_prazo,
    TRIM(p_especificacao),
    p_obs,
    'PEND',
    trunc(SYSDATE),
    v_documento_id,
    trunc(SYSDATE));
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Inclusão de peça no ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/08/2006
  -- DESCRICAO: Atualiza determinada peca do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_peca_id       IN job_peca.job_peca_id%TYPE,
  p_tipo_peca_id      IN job_peca.tipo_peca_id%TYPE,
  p_complemento       IN job_peca.complemento%TYPE,
  p_especificacao     IN VARCHAR2,
  p_obs               IN VARCHAR2,
  p_tipo_solicitacao  IN VARCHAR2,
  p_data_prazo        IN VARCHAR2,
  p_ref_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_ref_volume_id     IN arquivo.volume_id%TYPE,
  p_ref_nome_original IN arquivo.nome_original%TYPE,
  p_ref_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_ref_mime_type     IN arquivo.mime_type%TYPE,
  p_ref_tamanho       IN arquivo.tamanho%TYPE,
  p_cri_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_cri_volume_id     IN arquivo.volume_id%TYPE,
  p_cri_nome_original IN arquivo.nome_original%TYPE,
  p_cri_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_cri_mime_type     IN arquivo.mime_type%TYPE,
  p_cri_tamanho       IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_job_id               job.job_id%TYPE;
  v_numero_job           job.numero%TYPE;
  v_status_job           job.status%TYPE;
  v_nome_peca            tipo_peca.nome%TYPE;
  v_data_prazo           DATE;
  v_exception            EXCEPTION;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_tipo_peca_id_old     job_peca.tipo_peca_id%TYPE;
  v_complemento_old      job_peca.complemento%TYPE;
  v_especificacao_old    job_peca.especificacao %TYPE;
  v_obs_old              job_peca.obs%TYPE;
  v_tipo_solicitacao_old job_peca.tipo_solicitacao%TYPE;
  v_data_prazo_old       job_peca.data_prazo%TYPE;
  v_status_peca          job_peca.status%TYPE;
  v_doc_refer_id_old     job_peca.doc_refer_id%TYPE;
  v_doc_criacao_id_old   job_peca.doc_criacao_id%TYPE;
  v_doc_refer_id         job_peca.doc_refer_id%TYPE;
  v_doc_criacao_id       job_peca.doc_criacao_id%TYPE;
  v_doc_refer_id_ult     job_peca.doc_refer_id%TYPE;
  v_doc_criacao_id_ult   job_peca.doc_criacao_id%TYPE;
  v_complemento          job_peca.complemento%TYPE;
  v_papel_resp_doc_id    papel.papel_id%TYPE;
  v_tipo_documento_id    tipo_documento.tipo_documento_id%TYPE;
  v_nome_documento       documento.nome%TYPE;
  v_priv_config_peca     INTEGER;
  v_priv_doc_criacao     INTEGER;
  v_lbl_job              VARCHAR2(100);
  --
 BEGIN
  v_qt               := 0;
  v_priv_config_peca := 0;
  v_priv_doc_criacao := 0;
  v_lbl_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         jp.doc_refer_id,
         jp.doc_criacao_id,
         jp.tipo_peca_id,
         jp.tipo_solicitacao,
         jp.complemento,
         jp.especificacao,
         jp.obs,
         jp.data_prazo,
         jp.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_doc_refer_id_old,
         v_doc_criacao_id_old,
         v_tipo_peca_id_old,
         v_tipo_solicitacao_old,
         v_complemento_old,
         v_especificacao_old,
         v_obs_old,
         v_data_prazo_old,
         v_status_peca
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) = 1 THEN
   v_priv_config_peca := 1;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_DC',
                                v_job_id,
                                NULL,
                                p_empresa_id) = 1 THEN
   v_priv_doc_criacao := 1;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_peca <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da peça não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- descobre o papel do responsavel pela criacao do documento
  -- (dando preferencia para o papel com priv de responsavel interno).
  SELECT MAX(up.papel_id)
    INTO v_papel_resp_doc_id
    FROM usuario_papel up,
         papel         pa,
         papel_priv    pp,
         privilegio    pr
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = p_empresa_id
     AND pa.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = 'JOB_RESP_INT_V';
  --
  IF v_papel_resp_doc_id IS NULL THEN
   SELECT MIN(up.papel_id)
     INTO v_papel_resp_doc_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id;
  END IF;
  --
  SELECT nome
    INTO v_nome_peca
    FROM tipo_peca
   WHERE tipo_peca_id = p_tipo_peca_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_peca_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de peça é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_especificacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da especificação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_especificacao) > 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da especificação não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 2000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_solicitacao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prenchimento do tipo de solicitação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM dicionario
   WHERE tipo = 'tipo_solicitacao'
     AND codigo = p_tipo_solicitacao;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de solicitação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo inválido.';
   RAISE v_exception;
  END IF;
  --
  v_data_prazo  := data_converter(p_data_prazo);
  v_complemento := TRIM(p_complemento);
  --
  IF nvl(v_doc_refer_id_old, 0) > 0 AND nvl(p_ref_arquivo_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe documento de referência para essa solicitação de peça.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_doc_criacao_id_old, 0) > 0 AND nvl(p_cri_arquivo_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe documento de criação para essa solicitação de peça.';
   RAISE v_exception;
  END IF;
  --
  IF v_priv_config_peca = 0 AND
     (nvl(v_tipo_peca_id_old, 0) <> nvl(p_tipo_peca_id, 0) OR
     nvl(v_complemento_old, 'X') <> nvl(v_complemento, 'X') OR
     v_tipo_solicitacao_old <> p_tipo_solicitacao OR
     nvl(v_data_prazo_old, data_converter('1/1/1970')) <>
     nvl(v_data_prazo, data_converter('1/1/1970')) OR v_especificacao_old <> p_especificacao OR
     nvl(v_obs_old, 'X') <> nvl(p_obs, 'X') OR nvl(p_ref_arquivo_id, 0) > 0) THEN
   --
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para alterar dados da solicitação de peças.';
   RAISE v_exception;
  END IF;
  --
  IF v_priv_doc_criacao = 0 AND nvl(p_cri_arquivo_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para incluir documento de criação de peças.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_tipo_peca_id_old, 0) <> nvl(p_tipo_peca_id, 0) OR
     nvl(v_complemento_old, 'X') <> nvl(v_complemento, 'X') THEN
   -- mudou o nome da peca. Verifica se essa peca ja tinha algum documento
   -- associado.
   IF nvl(v_doc_refer_id_old, 0) > 0 OR nvl(v_doc_criacao_id_old, 0) > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tipo de peça/complemento não podem ser alterados, pois ' ||
                  'já existem documentos associados à antiga identificação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_doc_refer_id_ult   := ult_doc_retornar(v_job_id,
                                           p_tipo_peca_id,
                                           v_complemento,
                                           'PECA_ESPEC');
  v_doc_criacao_id_ult := ult_doc_retornar(v_job_id,
                                           p_tipo_peca_id,
                                           v_complemento,
                                           'PECA_CRIACAO');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_peca
     SET tipo_peca_id     = p_tipo_peca_id,
         complemento      = v_complemento,
         tipo_solicitacao = p_tipo_solicitacao,
         data_prazo       = v_data_prazo,
         especificacao    = TRIM(p_especificacao),
         obs              = p_obs
   WHERE job_peca_id = p_job_peca_id;
  --
  -- tratamento do arquivo de referencia
  --
  IF nvl(p_ref_arquivo_id, 0) > 0 THEN
   -- nao existia arquivo de referencia/especificacao e um arquivo foi fornecido.
   --
   IF v_doc_refer_id_ult IS NULL THEN
    -- primeiro documento de especificacao da peca (versao 1)
    v_nome_documento := rtrim(v_nome_peca || ' ' || v_complemento);
    --
    SELECT MAX(tipo_documento_id)
      INTO v_tipo_documento_id
      FROM tipo_documento
     WHERE codigo = 'PECA_ESPEC';
    --
    documento_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_job_id,
                            v_papel_resp_doc_id,
                            v_tipo_documento_id,
                            v_nome_documento,
                            substr(p_especificacao, 1, 200),
                            substr(p_obs, 1, 500),
                            'ND',
                            NULL,
                            NULL,
                            p_ref_arquivo_id,
                            p_ref_volume_id,
                            p_ref_nome_original,
                            p_ref_nome_fisico,
                            p_ref_mime_type,
                            p_ref_tamanho,
                            NULL,
                            0,
                            v_doc_refer_id,
                            p_erro_cod,
                            p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE job_peca
       SET doc_refer_id = v_doc_refer_id
     WHERE job_peca_id = p_job_peca_id;
   ELSE
    -- nova versao de especificacao da peca
    documento_pkg.versao_adicionar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   v_job_id,
                                   v_papel_resp_doc_id,
                                   v_doc_refer_id_ult,
                                   substr(p_obs, 1, 500),
                                   'ND',
                                   NULL,
                                   NULL,
                                   'N',
                                   p_ref_arquivo_id,
                                   p_ref_volume_id,
                                   p_ref_nome_original,
                                   p_ref_nome_fisico,
                                   p_ref_mime_type,
                                   p_ref_tamanho,
                                   NULL,
                                   v_doc_refer_id,
                                   p_erro_cod,
                                   p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE documento
       SET descricao = substr(p_especificacao, 1, 200)
     WHERE documento_id = v_doc_refer_id;
    --
    UPDATE job_peca
       SET doc_refer_id = v_doc_refer_id
     WHERE job_peca_id = p_job_peca_id;
   END IF;
  END IF;
  --
  -- tratamento do arquivo de criacao
  --
  IF nvl(p_cri_arquivo_id, 0) > 0 THEN
   -- -- nao existia arquivo de criacao e um arquivo foi fornecido.
   --
   IF v_doc_criacao_id_ult IS NULL THEN
    -- primeiro documento de criacao da peca (versao 1)
    v_nome_documento := rtrim(v_nome_peca || ' ' || v_complemento);
    --
    SELECT MAX(tipo_documento_id)
      INTO v_tipo_documento_id
      FROM tipo_documento
     WHERE codigo = 'PECA_CRIACAO';
    --
    documento_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_job_id,
                            v_papel_resp_doc_id,
                            v_tipo_documento_id,
                            v_nome_documento,
                            substr(p_especificacao, 1, 200),
                            substr(p_obs, 1, 500),
                            'ND',
                            NULL,
                            NULL,
                            p_cri_arquivo_id,
                            p_cri_volume_id,
                            p_cri_nome_original,
                            p_cri_nome_fisico,
                            p_cri_mime_type,
                            p_cri_tamanho,
                            NULL,
                            0,
                            v_doc_criacao_id,
                            p_erro_cod,
                            p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE job_peca
       SET doc_criacao_id = v_doc_criacao_id
     WHERE job_peca_id = p_job_peca_id;
   ELSE
    -- nova versao de especificacao da peca
    documento_pkg.versao_adicionar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   v_job_id,
                                   v_papel_resp_doc_id,
                                   v_doc_criacao_id_ult,
                                   substr(p_obs, 1, 500),
                                   'ND',
                                   NULL,
                                   NULL,
                                   'N',
                                   p_cri_arquivo_id,
                                   p_cri_volume_id,
                                   p_cri_nome_original,
                                   p_cri_nome_fisico,
                                   p_cri_mime_type,
                                   p_cri_tamanho,
                                   NULL,
                                   v_doc_criacao_id,
                                   p_erro_cod,
                                   p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE documento
       SET descricao = substr(p_especificacao, 1, 200)
     WHERE documento_id = v_doc_criacao_id;
    --
    UPDATE job_peca
       SET doc_criacao_id = v_doc_criacao_id
     WHERE job_peca_id = p_job_peca_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Alteração de peça do ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 PROCEDURE documento_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/09/2006
  -- DESCRICAO: Exclusao de documento associado a job_peca (documento de referencia ou
  --   documento de criacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_peca_id       IN job_peca.job_peca_id%TYPE,
  p_documento_id      IN documento.documento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_job_id            job.job_id%TYPE;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_nome_peca         tipo_peca.nome%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_doc_refer_id      job_peca.doc_refer_id%TYPE;
  v_doc_criacao_id    job_peca.doc_criacao_id%TYPE;
  v_status_peca       job_peca.status%TYPE;
  v_complemento       job_peca.complemento%TYPE;
  v_flag_atual        documento.flag_atual%TYPE;
  v_tipo_documento_id documento.tipo_documento_id%TYPE;
  v_nome_doc          documento.nome%TYPE;
  v_novo_doc_atual_id documento.documento_id%TYPE;
  v_arquivo_id        arquivo.arquivo_id%TYPE;
  v_lbl_job           VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         tp.nome,
         jp.complemento,
         jp.doc_refer_id,
         jp.doc_criacao_id,
         jp.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_nome_peca,
         v_complemento,
         v_doc_refer_id,
         v_doc_criacao_id,
         v_status_peca
    FROM job       jo,
         job_peca  jp,
         tipo_peca tp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jp.tipo_peca_id = tp.tipo_peca_id;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_peca <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da peça não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_documento_id, 0) <> v_doc_refer_id AND nvl(p_documento_id, 0) <> v_doc_criacao_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse documento não existe ou não pertence a essa solicitação de peças.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF p_documento_id = v_doc_refer_id THEN
   -- documentos de referencia podem ser editados por usuarios com privilegio de
   -- configurar pecas.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_PECA_C',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  ELSE
   -- documentos de criacao podem ser editados por usuarios com privilegio de
   -- configurar documentos de criacao.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_PECA_DC',
                                 v_job_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT flag_atual,
         tipo_documento_id,
         nome
    INTO v_flag_atual,
         v_tipo_documento_id,
         v_nome_doc
    FROM documento
   WHERE documento_id = p_documento_id;
  --
  SELECT MAX(arquivo_id)
    INTO v_arquivo_id
    FROM arquivo_documento
   WHERE documento_id = p_documento_id;
  --
  IF v_flag_atual = 'S' THEN
   -- a versao atual vai ser excluida. Procura a versao anterior para
   -- transforma-la em atual.
   SELECT MAX(documento_id)
     INTO v_novo_doc_atual_id
     FROM documento
    WHERE job_id = v_job_id
      AND tipo_documento_id = v_tipo_documento_id
      AND nome = v_nome_doc
      AND flag_atual = 'N';
   --
   IF v_novo_doc_atual_id IS NOT NULL THEN
    UPDATE documento
       SET flag_atual = 'S'
     WHERE documento_id = v_novo_doc_atual_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_documento_id = v_doc_refer_id THEN
   UPDATE job_peca
      SET doc_refer_id = NULL
    WHERE job_peca_id = p_job_peca_id;
  ELSE
   UPDATE job_peca
      SET doc_criacao_id = NULL
    WHERE job_peca_id = p_job_peca_id;
  END IF;
  --
  arquivo_pkg.excluir(p_usuario_sessao_id, v_arquivo_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  DELETE FROM documento
   WHERE documento_id = p_documento_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Exclusão de documento de peça do ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END; -- documento_excluir
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/08/2006
  -- DESCRICAO: Exclusao de determinada peca do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_peca_id       IN job_peca.job_peca_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_nome_peca      tipo_peca.nome%TYPE;
  v_tipo_objeto_id tipo_objeto.tipo_objeto_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_doc_refer_id   job_peca.doc_refer_id%TYPE;
  v_doc_criacao_id job_peca.doc_criacao_id%TYPE;
  v_complemento    job_peca.complemento%TYPE;
  v_status_peca    job_peca.status%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         tp.nome,
         jp.complemento,
         jp.doc_refer_id,
         jp.doc_criacao_id,
         jp.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_nome_peca,
         v_complemento,
         v_doc_refer_id,
         v_doc_criacao_id,
         v_status_peca
    FROM job       jo,
         job_peca  jp,
         tipo_peca tp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jp.tipo_peca_id = tp.tipo_peca_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_peca <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da peça não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_objeto_id)
    INTO v_tipo_objeto_id
    FROM tipo_objeto
   WHERE codigo = 'JOB_PECA';
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF nvl(v_doc_refer_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça possui um documento de referência associado.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_doc_criacao_id, 0) > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça possui um documento de criação associado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM job_peca
   WHERE job_peca_id = p_job_peca_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Exclusão de peça do ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 PROCEDURE cancelar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/08/2006
  -- DESCRICAO: Cancelamento de determinada peca do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_peca_id       IN job_peca.job_peca_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_status_peca    job_peca.status%TYPE;
  v_nome_peca      tipo_peca.nome%TYPE;
  v_complemento    job_peca.complemento%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         tp.nome,
         jp.complemento,
         jp.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_nome_peca,
         v_complemento,
         v_status_peca
    FROM job       jo,
         job_peca  jp,
         tipo_peca tp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jp.tipo_peca_id = tp.tipo_peca_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_peca <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da peça não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_peca
     SET status      = 'CANC',
         data_status = trunc(SYSDATE)
   WHERE job_peca_id = p_job_peca_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Cancelamento de peça do ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END; -- cancelar
 --
 --
 PROCEDURE concluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/09/2006
  -- DESCRICAO: Conclusao de determinada peca do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_peca_id       IN job_peca.job_peca_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_status_peca    job_peca.status%TYPE;
  v_nome_peca      tipo_peca.nome%TYPE;
  v_complemento    job_peca.complemento%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job      jo,
         job_peca jp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa peça não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         tp.nome,
         jp.complemento,
         jp.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_nome_peca,
         v_complemento,
         v_status_peca
    FROM job       jo,
         job_peca  jp,
         tipo_peca tp
   WHERE jp.job_peca_id = p_job_peca_id
     AND jp.job_id = jo.job_id
     AND jp.tipo_peca_id = tp.tipo_peca_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_PECA_CO',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_peca <> 'PEND' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da peça não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_peca
     SET status      = 'CONC',
         data_status = trunc(SYSDATE)
   WHERE job_peca_id = p_job_peca_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Conclusão de peça do ' || v_lbl_job || ' (' ||
                      TRIM(v_nome_peca || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END; -- concluir
 --
 --
 FUNCTION ult_peca_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/10/2006
  -- DESCRICAO: retorna o id da solicitacao de peca mais recente (job_peca_id), referente a
  --  um determinado job e a uma determinada peca.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id       IN job.job_id%TYPE,
  p_tipo_peca_id IN job_peca.tipo_peca_id%TYPE,
  p_complemento  IN job_peca.complemento%TYPE
 ) RETURN INTEGER AS
  v_qt               INTEGER;
  v_job_peca_id      job_peca.job_peca_id%TYPE;
  v_data_solicitacao job_peca.data_solicitacao%TYPE;
  --
 BEGIN
  v_job_peca_id := NULL;
  --
  SELECT MAX(data_solicitacao)
    INTO v_data_solicitacao
    FROM job_peca
   WHERE job_id = p_job_id
     AND tipo_peca_id = p_tipo_peca_id
     AND nvl(complemento, 'X') = nvl(TRIM(p_complemento), 'X');
  --
  SELECT MAX(job_peca_id)
    INTO v_job_peca_id
    FROM job_peca
   WHERE job_id = p_job_id
     AND tipo_peca_id = p_tipo_peca_id
     AND nvl(complemento, 'X') = nvl(TRIM(p_complemento), 'X')
     AND data_solicitacao = v_data_solicitacao;
  --
  RETURN v_job_peca_id;
 EXCEPTION
  WHEN OTHERS THEN
   v_job_peca_id := NULL;
   RETURN v_job_peca_id;
 END ult_peca_retornar;
 --
 --
 FUNCTION ult_doc_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/10/2006
  -- DESCRICAO: retorna o documento_id mais recente de peca, referente a
  --  um determinado job / peca / tipo de documento (especificacao ou criacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id       IN job.job_id%TYPE,
  p_tipo_peca_id IN job_peca.tipo_peca_id%TYPE,
  p_complemento  IN job_peca.complemento%TYPE,
  p_tipo_doc     IN tipo_documento.codigo%TYPE
 ) RETURN INTEGER AS
  v_qt           INTEGER;
  v_documento_id documento.documento_id%TYPE;
  --
 BEGIN
  v_documento_id := NULL;
  --
  IF p_tipo_doc = 'PECA_ESPEC' THEN
   SELECT MAX(jp.doc_refer_id)
     INTO v_documento_id
     FROM job_peca  jp,
          documento dc
    WHERE jp.job_id = p_job_id
      AND jp.tipo_peca_id = p_tipo_peca_id
      AND nvl(jp.complemento, 'X') = nvl(TRIM(p_complemento), 'X')
      AND jp.doc_refer_id = dc.documento_id
      AND dc.flag_atual = 'S';
  END IF;
  --
  IF p_tipo_doc = 'PECA_CRIACAO' THEN
   SELECT MAX(jp.doc_criacao_id)
     INTO v_documento_id
     FROM job_peca  jp,
          documento dc
    WHERE jp.job_id = p_job_id
      AND jp.tipo_peca_id = p_tipo_peca_id
      AND nvl(jp.complemento, 'X') = nvl(TRIM(p_complemento), 'X')
      AND jp.doc_criacao_id = dc.documento_id
      AND dc.flag_atual = 'S';
  END IF;
  --
  RETURN v_documento_id;
 EXCEPTION
  WHEN OTHERS THEN
   v_documento_id := NULL;
   RETURN v_documento_id;
 END ult_doc_retornar;
 --
--
END; -- JOB_PECA_PKG



/
