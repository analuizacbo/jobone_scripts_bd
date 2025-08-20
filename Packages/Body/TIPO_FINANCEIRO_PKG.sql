--------------------------------------------------------
--  DDL for Package Body TIPO_FINANCEIRO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_FINANCEIRO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 19/06/2013
  -- DESCRICAO: Inclusão de TIPO_FINANCEIRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/03/2015  Novo atributo flag_ativo.
  -- Silvia            22/06/2016  Novo atributo flag_despesa.
  -- Silvia            29/06/2017  Novo atributo flag_consid_hr_os_ctr.
  -- Silvia            07/06/2018  Novo atributo cod_job.
  -- Silvia            06/12/2018  Consistencia do codigo do job.
  -- Silvia            14/10/2019  flag_usa_budget,flag_usa_receita_prev,flag_obriga_contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_codigo                IN tipo_financeiro.codigo%TYPE,
  p_nome                  IN tipo_financeiro.nome%TYPE,
  p_flag_despesa          IN VARCHAR2,
  p_flag_consid_hr_os_ctr IN VARCHAR2,
  p_flag_padrao           IN VARCHAR2,
  p_tipo_custo            IN VARCHAR2,
  p_cod_job               IN VARCHAR2,
  p_flag_usa_budget       IN VARCHAR2,
  p_flag_usa_receita_prev IN VARCHAR2,
  p_flag_obriga_contrato  IN VARCHAR2,
  p_tipo_financeiro_id    OUT tipo_financeiro.tipo_financeiro_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_tipo_financeiro_id tipo_financeiro.tipo_financeiro_id%TYPE;
  v_xml_atual          CLOB;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt                 := 0;
  p_tipo_financeiro_id := 0;
  v_lbl_job            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_FINANCEIRO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código obrigatório.';
   RAISE v_exception;
  END IF;
  --
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
    FROM tipo_financeiro
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe (' || p_codigo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_despesa) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag despesa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_consid_hr_os_ctr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag considera horas apontadas nos Workflows em contratos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_budget) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita uso do budget inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_receita_prev) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita uso da receita prevista inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_contrato) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga contrato inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_tipo_custo)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de custo não pode ter mais que 10 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_job)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_job) IS NOT NULL THEN
   IF instr(TRIM(p_cod_job), ' ') > 0 OR instr(TRIM(p_cod_job), '%') > 0 OR
      lower(TRIM(p_cod_job)) <> acento_retirar(TRIM(p_cod_job)) THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter caracteres em branco, ' ||
                  'com acentuação ou % (' || upper(p_cod_job) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_financeiro.nextval
    INTO v_tipo_financeiro_id
    FROM dual;
  --
  INSERT INTO tipo_financeiro
   (tipo_financeiro_id,
    empresa_id,
    codigo,
    nome,
    flag_despesa,
    flag_consid_hr_os_ctr,
    flag_padrao,
    tipo_custo,
    cod_job,
    flag_ativo,
    flag_usa_budget,
    flag_usa_receita_prev,
    flag_obriga_contrato)
  VALUES
   (v_tipo_financeiro_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    p_flag_despesa,
    p_flag_consid_hr_os_ctr,
    p_flag_padrao,
    TRIM(p_tipo_custo),
    TRIM(p_cod_job),
    'S',
    p_flag_usa_budget,
    p_flag_usa_receita_prev,
    p_flag_obriga_contrato);
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo pode ser padrao.
   UPDATE tipo_financeiro
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_financeiro_id <> v_tipo_financeiro_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(v_tipo_financeiro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo));
  v_compl_histor   := TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_FINANCEIRO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_financeiro_id,
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
  p_tipo_financeiro_id := v_tipo_financeiro_id;
  p_erro_cod           := '00000';
  p_erro_msg           := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 19/06/2013
  -- DESCRICAO: Atualização de TIPO_FINANCEIRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/03/2015  Novo atributo flag_ativo.
  -- Silvia            22/06/2016  Novo atributo flag_despesa.
  -- Silvia            29/06/2017  Novo atributo flag_consid_hr_os_ctr.
  -- Silvia            07/06/2018  Novo atributo cod_job.
  -- Silvia            23/07/2018  Teste de alteracao de codigo do job.
  -- Silvia            06/12/2018  Consistencia do codigo do job.
  -- Silvia            14/10/2019  flag_usa_budget,flag_usa_receita_prev,flag_obriga_contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_tipo_financeiro_id    IN tipo_financeiro.tipo_financeiro_id%TYPE,
  p_codigo                IN tipo_financeiro.codigo%TYPE,
  p_nome                  IN tipo_financeiro.nome%TYPE,
  p_flag_despesa          IN VARCHAR2,
  p_flag_consid_hr_os_ctr IN VARCHAR2,
  p_flag_padrao           IN VARCHAR2,
  p_tipo_custo            IN VARCHAR2,
  p_cod_job               IN VARCHAR2,
  p_flag_usa_budget       IN VARCHAR2,
  p_flag_usa_receita_prev IN VARCHAR2,
  p_flag_obriga_contrato  IN VARCHAR2,
  p_flag_ativo            IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_cod_job_ant          tipo_financeiro.cod_job%TYPE;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
  v_lbl_job              VARCHAR2(100);
  v_lbl_jobs             VARCHAR2(100);
  v_padrao_numeracao_job VARCHAR2(40);
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_padrao_numeracao_job := empresa_pkg.parametro_retornar(p_empresa_id,
                                                           'PADRAO_NUMERACAO_JOB');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_FINANCEIRO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo financeiro não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT TRIM(cod_job)
    INTO v_cod_job_ant
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_despesa) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag despesa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_consid_hr_os_ctr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag considera horas apontadas nos Workflows em contratos inválido.';
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
  IF flag_validar(p_flag_usa_budget) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita uso do budget inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_receita_prev) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita uso da receita prevista inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_contrato) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga contrato inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_tipo_custo)) > 10 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de custo não pode ter mais que 10 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_job)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_job) IS NOT NULL THEN
   IF instr(TRIM(p_cod_job), ' ') > 0 OR instr(TRIM(p_cod_job), '%') > 0 OR
      lower(TRIM(p_cod_job)) <> acento_retirar(TRIM(p_cod_job)) THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ter caracteres em branco, ' ||
                  'com acentuação ou % (' || upper(p_cod_job) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id
     AND tipo_financeiro_id <> p_tipo_financeiro_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe (' || p_codigo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_financeiro_id <> p_tipo_financeiro_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_cod_job_ant, 'ZZXXWW') <> nvl(TRIM(p_cod_job), 'ZZXXWW') THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job
    WHERE tipo_financeiro_id = p_tipo_financeiro_id
      AND tipo_num_job = 'SEQ_COM_TFI'
      AND rownum = 1;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código do ' || v_lbl_job || ' não pode ser alterado pois já ' ||
                  'existem ' || v_lbl_jobs || ' associados a esse tipo financeiro.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(p_tipo_financeiro_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_financeiro
     SET codigo                = TRIM(upper(p_codigo)),
         nome                  = TRIM(p_nome),
         flag_despesa          = p_flag_despesa,
         flag_consid_hr_os_ctr = p_flag_consid_hr_os_ctr,
         flag_padrao           = p_flag_padrao,
         tipo_custo            = TRIM(p_tipo_custo),
         cod_job               = TRIM(p_cod_job),
         flag_ativo            = p_flag_ativo,
         flag_usa_budget       = p_flag_usa_budget,
         flag_usa_receita_prev = p_flag_usa_receita_prev,
         flag_obriga_contrato  = p_flag_obriga_contrato
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo pode ser padrao.
   UPDATE tipo_financeiro
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_financeiro_id <> p_tipo_financeiro_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(p_tipo_financeiro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo));
  v_compl_histor   := TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_FINANCEIRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_financeiro_id,
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
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 19/06/2013
  -- DESCRICAO: Exclusão de TIPO_FINANCEIRO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/06/2016  Consistencia de papel_priv_tfin
  -- Silvia            22/06/2016  Consistencia de orcamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_financeiro.codigo%TYPE;
  v_nome           tipo_financeiro.nome%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_FINANCEIRO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo financeiro não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse tipo financeiro.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Workflows associados a esse tipo financeiro.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv_tfin
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem papéis configurados com privilégios para esse tipo financeiro.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a esse tipo financeiro.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(p_tipo_financeiro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_FINANCEIRO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_financeiro_id,
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
 END; -- excluir
 --
 --
 PROCEDURE papel_priv_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/06/2016
  -- DESCRICAO: Alteracao de privilegios para criar job desse tipo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN tipo_financeiro.empresa_id%TYPE,
  p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
  p_vetor_papeis       IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_vetor_papeis   VARCHAR2(1000);
  v_delimitador    CHAR(1);
  v_papel_id       papel.papel_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_financeiro.codigo%TYPE;
  v_nome           tipo_financeiro.nome%TYPE;
  v_privilegio_id  privilegio.privilegio_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_FINANCEIRO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo financeiro não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_financeiro
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'JOB_TIPO_FIN_C';
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(p_tipo_financeiro_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_priv_tfin
   WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  --
  DELETE FROM papel_priv pp
   WHERE privilegio_id = v_privilegio_id
     AND NOT EXISTS (SELECT 1
            FROM papel_priv_tfin pt
           WHERE pp.papel_id = pt.papel_id
             AND pp.privilegio_id = pt.privilegio_id);
  --
  v_delimitador  := '|';
  v_vetor_papeis := rtrim(p_vetor_papeis);
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_papeis)), 0) > 0
  LOOP
   v_papel_id := nvl(to_number(prox_valor_retornar(v_vetor_papeis, v_delimitador)), 0);
   --
   IF v_papel_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse papel não existe (papel_id = ' || to_char(v_papel_id) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_priv
     WHERE papel_id = v_papel_id
       AND privilegio_id = v_privilegio_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO papel_priv
      (papel_id,
       privilegio_id,
       abrangencia)
     VALUES
      (v_papel_id,
       v_privilegio_id,
       'P');
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_priv_tfin
     WHERE tipo_financeiro_id = p_tipo_financeiro_id
       AND papel_id = v_papel_id
       AND privilegio_id = v_privilegio_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO papel_priv_tfin
      (papel_id,
       privilegio_id,
       tipo_financeiro_id)
     VALUES
      (v_papel_id,
       v_privilegio_id,
       p_tipo_financeiro_id);
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_financeiro_pkg.xml_gerar(p_tipo_financeiro_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_FINANCEIRO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_financeiro_id,
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
 END papel_priv_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 23/01/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo financeiro para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_financeiro_id IN tipo_financeiro.tipo_financeiro_id%TYPE,
  p_xml                OUT CLOB,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_pa IS
   SELECT pa.nome AS papel
     FROM papel_priv_tfin pp,
          papel           pa
    WHERE pp.tipo_financeiro_id = p_tipo_financeiro_id
      AND pp.papel_id = pa.papel_id;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tipo_financeiro_id", ti.tipo_financeiro_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("usa_budget", ti.flag_usa_budget),
                   xmlelement("usa_receita_prevista", ti.flag_usa_receita_prev),
                   xmlelement("obriga_contrato", ti.flag_obriga_contrato),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("padrao", ti.flag_padrao),
                   xmlelement("despesa", ti.flag_despesa),
                   xmlelement("tipo_custo", ti.tipo_custo),
                   xmlelement("cod_job", ti.cod_job))
    INTO v_xml
    FROM tipo_financeiro ti
   WHERE ti.tipo_financeiro_id = p_tipo_financeiro_id;
  --
  FOR r_pa IN c_pa
  LOOP
   SELECT xmlconcat(xmlelement("papel", r_pa.papel))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("papeis_habilitados", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_financeiro"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_financeiro", v_xml, v_xml_aux1))
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
END; -- TIPO_FINANCEIRO_PKG



/
