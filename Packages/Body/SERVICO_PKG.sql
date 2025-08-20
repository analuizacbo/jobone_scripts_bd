--------------------------------------------------------
--  DDL for Package Body SERVICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SERVICO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 26/02/2019
  -- DESCRICAO: Inclusão de SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         10/05/2023  Adicao de margens minima e meta.
  -- Ana Luiza         18/05/2023  Adicao de parametro p_grupo_servico_id.
  -- Ana Luiza         31/08/2023  Adicao flag_tem_comissao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN VARCHAR2,
  p_codigo            IN VARCHAR2,
  p_margem_oper_min   IN VARCHAR2,
  p_margem_oper_meta  IN VARCHAR2,
  p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
  p_flag_tem_comissao IN VARCHAR2,
  p_servico_id        OUT servico.servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_servico_id     servico.servico_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --ALCBO_100523
  v_margem_oper_min  servico.margem_oper_min%TYPE;
  v_margem_oper_meta servico.margem_oper_meta%TYPE;
  --
 BEGIN
  v_qt         := 0;
  p_servico_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_codigo)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  IF numero_validar(p_margem_oper_min) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Margem operacional mínima inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  IF numero_validar(p_margem_oper_meta) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Margem operacional meta inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  v_margem_oper_min  := numero_converter(p_margem_oper_min);
  v_margem_oper_meta := numero_converter(p_margem_oper_meta);
  --ALCBO_240523
  IF TRIM(p_grupo_servico_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE upper(codigo) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de produto já existe.';
   RAISE v_exception;
  END IF;
  --ALCBO_310823
  IF flag_validar(p_flag_tem_comissao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag comissão inválida.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_servico.nextval
    INTO v_servico_id
    FROM dual;
  --ALCBO_180523
  INSERT INTO servico
   (servico_id,
    nome,
    flag_ativo,
    codigo,
    margem_oper_min,
    margem_oper_meta,
    grupo_servico_id,
    flag_tem_comissao)
  VALUES
   (v_servico_id,
    TRIM(p_nome),
    'S',
    TRIM(p_codigo),
    v_margem_oper_min,
    v_margem_oper_meta,
    zvl(p_grupo_servico_id, NULL),
    p_flag_tem_comissao);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  servico_pkg.xml_gerar(v_servico_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'SERVICO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_servico_id,
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
  p_servico_id := v_servico_id;
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 26/02/2019
  -- DESCRICAO: Atualização de SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         10/05/2023  Adicao de margens minima e meta.
  -- Ana Luiza         18/05/2023  Adicao de parametro p_grupo_servico_id.
  -- Ana Luiza         31/08/2023  Adicao flag_tem_comissao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_servico_id        IN servico.servico_id%TYPE,
  p_nome              IN VARCHAR2,
  p_codigo            IN VARCHAR2,
  p_margem_oper_min   IN VARCHAR2,
  p_margem_oper_meta  IN VARCHAR2,
  p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
  p_flag_ativo        IN VARCHAR2,
  p_flag_tem_comissao IN VARCHAR2,
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
  --ALCBO_10023
  v_margem_oper_min  servico.margem_oper_min%TYPE;
  v_margem_oper_meta servico.margem_oper_meta%TYPE;
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE servico_id = p_servico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse servico não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_codigo)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  IF numero_validar(p_margem_oper_min) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Margem operacional mínima inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  IF numero_validar(p_margem_oper_meta) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Margem operacional meta inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_100523
  v_margem_oper_min  := numero_converter(p_margem_oper_min);
  v_margem_oper_meta := numero_converter(p_margem_oper_meta);
  --ALCBO_240523
  IF TRIM(p_grupo_servico_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do grupo é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_310823
  IF flag_validar(p_flag_tem_comissao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag comissão inválida.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE servico_id <> p_servico_id
     AND upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE servico_id <> p_servico_id
     AND upper(codigo) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de produto já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  servico_pkg.xml_gerar(p_servico_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_180523
  UPDATE servico
     SET nome              = TRIM(p_nome),
         flag_ativo        = p_flag_ativo,
         codigo            = TRIM(p_codigo),
         margem_oper_min   = v_margem_oper_min,
         margem_oper_meta  = v_margem_oper_meta,
         grupo_servico_id  = zvl(p_grupo_servico_id, NULL),
         flag_tem_comissao = p_flag_tem_comissao
   WHERE servico_id = p_servico_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  servico_pkg.xml_gerar(p_servico_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_servico_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 26/02/2019
  -- DESCRICAO: Exclusão de SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/01/2021  Consistencia de job/orcamento
  -- Silvia            14/09/2022  Consistencia de horas apontadas
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_servico_id        IN servico.servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           servico.nome%TYPE;
  v_xml_atual      CLOB;
  v_lbl_jobs       VARCHAR2(100);
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome
    FROM servico
   WHERE servico_id = p_servico_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse produto não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
    FROM job
   WHERE servico_id = p_servico_id
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
    FROM orcamento
   WHERE servico_id = p_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a esse produto.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE servico_id = p_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Cenários de Oportunidades associados a esse produto.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa_servico
   WHERE servico_id = p_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Empresas Responsáveis associadas a esse produto.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_oport
   WHERE servico_id = p_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem horas apontadas associadas a esse produto.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  servico_pkg.xml_gerar(p_servico_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM servico
   WHERE servico_id = p_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SERVICO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_servico_id,
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
 PROCEDURE grupo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza     ProcessMind     DATA: 18/05/2023
  -- DESCRICAO: Inclusão de GRUPO SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN VARCHAR2,
  p_grupo_servico_id  OUT grupo_servico.grupo_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_grupo_servico_id grupo_servico.grupo_servico_id%TYPE;
  --
 BEGIN
  v_qt               := 0;
  p_grupo_servico_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM grupo_servico
   WHERE upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_grupo_servico.nextval
    INTO v_grupo_servico_id
    FROM dual;
  --ALCBO_180523
  INSERT INTO grupo_servico
   (grupo_servico_id,
    nome)
  VALUES
   (v_grupo_servico_id,
    TRIM(p_nome));
  --
  p_grupo_servico_id := v_grupo_servico_id;
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
 END grupo_adicionar;
 --
 PROCEDURE grupo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 18/05/2023
  -- DESCRICAO: Atualização de GRUPO_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
  p_nome              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM grupo_servico
   WHERE grupo_servico_id = p_grupo_servico_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM grupo_servico
   WHERE grupo_servico_id <> p_grupo_servico_id
     AND upper(nome) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --ALCBO_180523
  UPDATE grupo_servico
     SET nome = TRIM(p_nome)
   WHERE grupo_servico_id = p_grupo_servico_id;
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
 END grupo_atualizar;
 --
 --
 PROCEDURE grupo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 18/05/2023
  -- DESCRICAO: Exclusão de SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_grupo_servico_id  IN grupo_servico.grupo_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_nome      grupo_servico.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome
    FROM grupo_servico
   WHERE grupo_servico_id = p_grupo_servico_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse grupo não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'SERVICO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE grupo_servico_id = p_grupo_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem produtos associadas a esse grupo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM grupo_servico
   WHERE grupo_servico_id = p_grupo_servico_id;
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
 END grupo_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 26/02/2019
  -- DESCRICAO: Subrotina que gera o xml do servico para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luzia         10/05/2023  Adicao das colunas margem_oper_min e margem_oper_meta
  -- Ana Luiza         18/05/2023  Adicao de parametro nome do grupo.
  ------------------------------------------------------------------------------------------
 (
  p_servico_id IN servico.servico_id%TYPE,
  p_xml        OUT CLOB,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  --ALCBO_180523
  SELECT xmlconcat(xmlelement("servico_id", servico_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", se.nome),
                   xmlelement("codigo", codigo),
                   xmlelement("ativo", flag_ativo),
                   xmlelement("margem_min", numero_mostrar(margem_oper_min, 3, 'N')),
                   xmlelement("margem_meta", numero_mostrar(margem_oper_meta, 3, 'N')),
                   xmlelement("grupo_servico", gs.nome))
    INTO v_xml
    FROM servico se
    LEFT JOIN grupo_servico gs ON se.grupo_servico_id = gs.grupo_servico_id
   WHERE se.servico_id = p_servico_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "servico"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("servico", v_xml))
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
END; -- SERVICO_PKG



/
