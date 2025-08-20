--------------------------------------------------------
--  DDL for Package Body UNIDADE_NEGOCIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "UNIDADE_NEGOCIO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Inclusão de UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/02/2020  Novo parametro cod_ext_unid_neg
  -- Silvia            07/08/2020  Novo parametro flag_qualquer_job
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nome               IN unidade_negocio.nome%TYPE,
  p_cod_ext_unid_neg   IN VARCHAR2,
  p_flag_qualquer_job  IN VARCHAR2,
  p_unidade_negocio_id OUT unidade_negocio.unidade_negocio_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_unidade_negocio_id unidade_negocio.unidade_negocio_id%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_un             VARCHAR2(100);
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt                 := 0;
  p_unidade_negocio_id := 0;
  v_lbl_un             := empresa_pkg.parametro_retornar(p_empresa_id,
                                                         'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
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
  IF length(TRIM(p_cod_ext_unid_neg)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_qualquer_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag qualquer job inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio
   WHERE upper(nome) = upper(p_nome)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_unidade_negocio.nextval
    INTO v_unidade_negocio_id
    FROM dual;
  --
  INSERT INTO unidade_negocio
   (unidade_negocio_id,
    empresa_id,
    nome,
    cod_ext_unid_neg,
    flag_qualquer_job)
  VALUES
   (v_unidade_negocio_id,
    p_empresa_id,
    TRIM(p_nome),
    TRIM(p_cod_ext_unid_neg),
    TRIM(p_flag_qualquer_job));
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(v_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'UNIDADE_NEGOCIO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_unidade_negocio_id,
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
  p_unidade_negocio_id := v_unidade_negocio_id;
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Atualização de UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/02/2020  Novo parametro cod_ext_unid_neg
  -- Silvia            07/08/2020  Novo parametro flag_qualquer_job
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_nome               IN unidade_negocio.nome%TYPE,
  p_cod_ext_unid_neg   IN VARCHAR2,
  p_flag_qualquer_job  IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
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
  IF length(TRIM(p_cod_ext_unid_neg)) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_qualquer_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag qualquer job inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio
   WHERE unidade_negocio_id <> p_unidade_negocio_id
     AND upper(nome) = upper(p_nome)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE unidade_negocio
     SET nome              = ltrim(rtrim(p_nome)),
         cod_ext_unid_neg  = TRIM(p_cod_ext_unid_neg),
         flag_qualquer_job = TRIM(p_flag_qualquer_job)
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Exclusão de UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2022  Consistencias de responsavel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           unidade_negocio.nome%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_un   := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE unid_negocio_resp_id = p_unidade_negocio_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades associadas a ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE unid_negocio_resp_id = p_unidade_negocio_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Cenários/produtos associados a ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oport_servico
   WHERE unid_negocio_resp_id = p_unidade_negocio_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Oportunidades/produtos associados a ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_serv_valor
   WHERE unid_negocio_resp_id = p_unidade_negocio_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Contratos/produtos associados a ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM unidade_negocio_cli
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  DELETE FROM unidade_negocio_usu
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  DELETE FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 PROCEDURE cliente_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Inclusao de cliente na UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_cliente_id         IN unidade_negocio_cli.cliente_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_cli       pessoa.apelido%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_cliente_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_cliente_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido
    INTO v_nome_cli
    FROM pessoa
   WHERE pessoa_id = p_cliente_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_cli
   WHERE cliente_id = p_cliente_id
     AND unidade_negocio_id = p_unidade_negocio_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente já está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO unidade_negocio_cli
   (unidade_negocio_id,
    cliente_id)
  VALUES
   (p_unidade_negocio_id,
    p_cliente_id);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Inclusão de cliente (' || v_nome_cli || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 END cliente_adicionar;
 --
 --
 PROCEDURE cliente_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Exclusao de cliente da UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_cliente_id         IN unidade_negocio_cli.cliente_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_cli       pessoa.apelido%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_cli
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND cliente_id = p_cliente_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  SELECT apelido
    INTO v_nome_cli
    FROM pessoa
   WHERE pessoa_id = p_cliente_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM unidade_negocio_cli
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND cliente_id = p_cliente_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Exclusão de cliente (' || v_nome_cli || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 END cliente_excluir;
 --
 --
 PROCEDURE usuario_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Inclusao de usuario na UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/12/2019  Eliminacao do papel do usuario
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_usu       pessoa.apelido%TYPE;
  v_empresa_pdr_id empresa.empresa_id%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ' || v_lbl_un || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome_usu IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_pdr_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  IF v_empresa_pdr_id <> p_empresa_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_usu
   WHERE usuario_id = p_usuario_id
     AND unidade_negocio_id = p_unidade_negocio_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário já está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO unidade_negocio_usu
   (unidade_negocio_id,
    usuario_id,
    flag_enderecar,
    flag_responsavel)
  VALUES
   (p_unidade_negocio_id,
    p_usuario_id,
    'N',
    'N');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Inclusão de usuário (' || v_nome_usu || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Exclusao de usuario da UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_usu       pessoa.apelido%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_usu
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  SELECT apelido
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM unidade_negocio_usu
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Exclusão de usuário (' || v_nome_usu || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 PROCEDURE usu_ender_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Atualizacao do flag_enderecar do usuario da UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
  p_flag_enderecar     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_usu       pessoa.apelido%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_usu
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  SELECT apelido
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF flag_validar(p_flag_enderecar) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag endereçar inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE unidade_negocio_usu
     SET flag_enderecar = p_flag_enderecar
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Alteração de usuário/endereçar (' || v_nome_usu || ' / "' ||
                      p_flag_enderecar || '")';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 END usu_ender_atualizar;
 --
 --
 PROCEDURE usu_resp_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Atualizacao do flag_responsavel do usuario da UNIDADE_NEGOCIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
  p_usuario_id         IN unidade_negocio_usu.usuario_id%TYPE,
  p_flag_responsavel   IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome_unid      unidade_negocio.nome%TYPE;
  v_nome_usu       pessoa.apelido%TYPE;
  v_lbl_un         VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM unidade_negocio_usu
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não está associado a essa ' || v_lbl_un || '.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_unid
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  SELECT apelido
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF flag_validar(p_flag_responsavel) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag responsável inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_responsavel = 'S' THEN
   -- desmarca todos antes de atualizar
   UPDATE unidade_negocio_usu
      SET flag_responsavel = 'N'
    WHERE unidade_negocio_id = p_unidade_negocio_id;
  END IF;
  --
  UPDATE unidade_negocio_usu
     SET flag_responsavel = p_flag_responsavel
   WHERE unidade_negocio_id = p_unidade_negocio_id
     AND usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  unidade_negocio_pkg.xml_gerar(p_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_unid;
  v_compl_histor   := 'Alteração de usuário/responsável (' || v_nome_usu || ' / "' ||
                      p_flag_responsavel || '")';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'UNIDADE_NEGOCIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_unidade_negocio_id,
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
 END usu_resp_atualizar;
 --
 --
 PROCEDURE usu_rateio_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 03/08/2020
  -- DESCRICAO: Atualizacao do perc de rateio do usuario nas diversas unidades de
  -- negocio em que ele participa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/06/2022  Geracao de historico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN unidade_negocio_usu.usuario_id%TYPE,
  p_vetor_unid_neg_id IN VARCHAR2,
  p_vetor_perc_rateio IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_unidade_negocio_id unidade_negocio.unidade_negocio_id%TYPE;
  v_nome_unid          unidade_negocio.nome%TYPE;
  v_nome_usu           pessoa.apelido%TYPE;
  v_perc_rateio        unidade_negocio_usu.perc_rateio%TYPE;
  v_perc_rateio_char   VARCHAR2(20);
  v_delimitador        CHAR(1);
  v_vetor_unid_neg_id  VARCHAR2(2000);
  v_vetor_perc_rateio  VARCHAR2(2000);
  v_lbl_un             VARCHAR2(100);
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt     := 0;
  v_lbl_un := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'UNIDADE_NEGOCIO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome_usu IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  v_vetor_unid_neg_id := p_vetor_unid_neg_id;
  v_vetor_perc_rateio := p_vetor_perc_rateio;
  --
  WHILE nvl(length(rtrim(v_vetor_unid_neg_id)), 0) > 0
  LOOP
   v_unidade_negocio_id := nvl(to_number(prox_valor_retornar(v_vetor_unid_neg_id,
                                                             v_delimitador)),
                               0);
   v_perc_rateio_char   := TRIM(prox_valor_retornar(v_vetor_perc_rateio, v_delimitador));
   --
   SELECT MAX(nome)
     INTO v_nome_unid
     FROM unidade_negocio
    WHERE unidade_negocio_id = v_unidade_negocio_id
      AND empresa_id = p_empresa_id;
   --
   IF v_nome_unid IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ' || v_lbl_un || ' não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM unidade_negocio_usu
    WHERE unidade_negocio_id = v_unidade_negocio_id
      AND usuario_id = p_usuario_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO unidade_negocio_usu
     (unidade_negocio_id,
      usuario_id,
      flag_enderecar,
      flag_responsavel)
    VALUES
     (v_unidade_negocio_id,
      p_usuario_id,
      'N',
      'N');
   END IF;
   --
   IF v_perc_rateio_char IS NULL THEN
    DELETE FROM unidade_negocio_usu
     WHERE unidade_negocio_id = v_unidade_negocio_id
       AND usuario_id = p_usuario_id;
   ELSE
    IF inteiro_validar(v_perc_rateio_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Percentual de rateio inválido para ' || v_nome_unid || '.';
     RAISE v_exception;
    END IF;
    --
    v_perc_rateio := nvl(to_number(v_perc_rateio_char), 0);
    --
    IF v_perc_rateio <= 0 OR v_perc_rateio > 100 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Percentual de rateio inválido para ' || v_nome_unid || '.';
     RAISE v_exception;
    END IF;
    --
    UPDATE unidade_negocio_usu
       SET perc_rateio = v_perc_rateio
     WHERE unidade_negocio_id = v_unidade_negocio_id
       AND usuario_id = p_usuario_id;
   END IF;
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   unidade_negocio_pkg.xml_gerar(v_unidade_negocio_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := v_nome_unid;
   v_compl_histor   := 'Alteração de rateio do usuário (' || v_nome_usu || ')';
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'UNIDADE_NEGOCIO',
                    'ALTERAR',
                    v_identif_objeto,
                    v_unidade_negocio_id,
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
  END LOOP;
  --
  SELECT SUM(perc_rateio)
    INTO v_perc_rateio
    FROM unidade_negocio_usu
   WHERE usuario_id = p_usuario_id;
  --
  IF v_perc_rateio <> 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A soma dos percentuais de rateio do usuário devem totalizar 100%.';
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
 END usu_rateio_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/11/2018
  -- DESCRICAO: Subrotina que gera o xml da unidade_negocio para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/02/2020  Novo parametro cod_ext_unid_neg
  ------------------------------------------------------------------------------------------
 (
  p_unidade_negocio_id IN unidade_negocio.unidade_negocio_id%TYPE,
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
  CURSOR c_cl IS
   SELECT cl.apelido AS nome
     FROM unidade_negocio_cli un,
          pessoa              cl
    WHERE un.unidade_negocio_id = p_unidade_negocio_id
      AND un.cliente_id = cl.pessoa_id
    ORDER BY cl.apelido;
  --
  CURSOR c_us IS
   SELECT pe.apelido AS nome,
          un.flag_enderecar,
          un.flag_responsavel,
          un.perc_rateio
     FROM unidade_negocio_usu un,
          pessoa              pe
    WHERE un.unidade_negocio_id = p_unidade_negocio_id
      AND un.usuario_id = pe.usuario_id
    ORDER BY pe.apelido;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("unidade_negocio_id", unidade_negocio_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", nome),
                   xmlelement("cod_ext_unid_neg", cod_ext_unid_neg),
                   xmlelement("qualquer_job", flag_qualquer_job))
    INTO v_xml
    FROM unidade_negocio
   WHERE unidade_negocio_id = p_unidade_negocio_id;
  --
  ------------------------------------------------------------
  -- monta CLIENTES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_cl IN c_cl
  LOOP
   SELECT xmlconcat(xmlelement("cliente", r_cl.nome))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("clientes", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta USUARIOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_us IN c_us
  LOOP
   SELECT xmlagg(xmlelement("usuario",
                            xmlelement("nome", r_us.nome),
                            xmlelement("flag_enderecar", r_us.flag_enderecar),
                            xmlelement("flag_responsavel", r_us.flag_responsavel),
                            xmlelement("perc_rateio", to_char(r_us.perc_rateio))))
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
  -- junta tudo debaixo de "unidade_negocio"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("unidade_negocio", v_xml))
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
END; -- UNIDADE_NEGOCIO_PKG



/
