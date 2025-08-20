--------------------------------------------------------
--  DDL for Package Body TIPO_APONTAM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_APONTAM_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 25/04/2013
  -- DESCRICAO: Inclusão de TIPO_APONTAM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/05/2020  Novo parametro flag_ausencia_full
  -- Silvia            28/12 2020  Novos parametros grupo e flag_billable
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_codigo             IN tipo_apontam.codigo%TYPE,
  p_nome               IN tipo_apontam.nome%TYPE,
  p_grupo              IN tipo_apontam.grupo%TYPE,
  p_flag_billable      IN VARCHAR2,
  p_flag_sistema       IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_flag_ausencia      IN VARCHAR2,
  p_flag_ausencia_full IN VARCHAR2,
  p_flag_formulario    IN VARCHAR2,
  p_tipo_apontam_id    OUT tipo_apontam.tipo_apontam_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_tipo_apontam_id tipo_apontam.tipo_apontam_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt              := 0;
  p_tipo_apontam_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_APONTAM_C',
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
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_billable) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag billable inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sistema) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sistema inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ausencia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ausência inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ausencia_full) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ausência full inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_ausencia_full = 'S' AND p_flag_ausencia = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indisponibilidade do usuário o dia inteiro só pode ' ||
                 'ser indicada no caso de ausência.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_formulario) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag formulário inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_apontam
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_apontam
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_apontam.nextval
    INTO v_tipo_apontam_id
    FROM dual;
  --
  INSERT INTO tipo_apontam
   (tipo_apontam_id,
    empresa_id,
    codigo,
    nome,
    grupo,
    flag_billable,
    flag_sistema,
    flag_ativo,
    flag_ausencia,
    flag_ausencia_full,
    flag_formulario)
  VALUES
   (v_tipo_apontam_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    TRIM(p_grupo),
    p_flag_billable,
    p_flag_sistema,
    p_flag_ativo,
    p_flag_ausencia,
    p_flag_ausencia_full,
    p_flag_formulario);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_apontam_pkg.xml_gerar(v_tipo_apontam_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_APONTAM',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_apontam_id,
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
  p_tipo_apontam_id := v_tipo_apontam_id;
  p_erro_cod        := '00000';
  p_erro_msg        := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 25/04/2013
  -- DESCRICAO: Atualização de TIPO_APONTAM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/05/2020  Novo parametro flag_ausencia_full
  -- Silvia            28/12 2020  Novos parametros grupo e flag_billable
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
  p_codigo             IN tipo_apontam.codigo%TYPE,
  p_nome               IN tipo_apontam.nome%TYPE,
  p_grupo              IN tipo_apontam.grupo%TYPE,
  p_flag_billable      IN VARCHAR2,
  p_flag_sistema       IN VARCHAR2,
  p_flag_ativo         IN VARCHAR2,
  p_flag_ausencia      IN VARCHAR2,
  p_flag_ausencia_full IN VARCHAR2,
  p_flag_formulario    IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_APONTAM_C',
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
    FROM tipo_apontam
   WHERE tipo_apontam_id = p_tipo_apontam_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de apontamento não existe.';
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
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_billable) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag billable inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sistema) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sistema inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ausencia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ausência inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ausencia_full) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ausência full inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_ausencia_full = 'S' AND p_flag_ausencia = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indisponibilidade do usuário o dia inteiro só pode ' ||
                 'ser indicada no caso de ausência.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_formulario) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag formulário inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_apontam
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id
     AND tipo_apontam_id <> p_tipo_apontam_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_apontam
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_apontam_id <> p_tipo_apontam_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_apontam_pkg.xml_gerar(p_tipo_apontam_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_apontam
     SET codigo             = TRIM(upper(p_codigo)),
         nome               = TRIM(p_nome),
         grupo              = TRIM(p_grupo),
         flag_billable      = p_flag_billable,
         flag_sistema       = p_flag_sistema,
         flag_ativo         = p_flag_ativo,
         flag_ausencia      = p_flag_ausencia,
         flag_ausencia_full = p_flag_ausencia_full,
         flag_formulario    = p_flag_formulario
   WHERE tipo_apontam_id = p_tipo_apontam_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_apontam_pkg.xml_gerar(p_tipo_apontam_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_APONTAM',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_apontam_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 25/04/2013
  -- DESCRICAO: Exclusão de TIPO_APONTAM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_apontam_id   IN tipo_apontam.tipo_apontam_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_apontam.codigo%TYPE;
  v_nome           tipo_apontam.nome%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_APONTAM_C',
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
    FROM tipo_apontam
   WHERE tipo_apontam_id = p_tipo_apontam_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de apontamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_apontam
   WHERE tipo_apontam_id = p_tipo_apontam_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE tipo_apontam_id = p_tipo_apontam_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos de horas associados a esse tipo.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE tipo_apontam_id = p_tipo_apontam_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem programações de apontamentos associados a esse tipo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_apontam_pkg.xml_gerar(p_tipo_apontam_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_apontam
   WHERE tipo_apontam_id = p_tipo_apontam_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_APONTAM',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_apontam_id,
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
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/02/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de apontamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_apontam_id IN tipo_apontam.tipo_apontam_id%TYPE,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
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
  SELECT xmlconcat(xmlelement("tipo_apontam_id", ti.tipo_apontam_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("grupo", ti.grupo),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("billable", ti.flag_billable),
                   xmlelement("do_sistema", ti.flag_sistema),
                   xmlelement("indica_ausencia", ti.flag_ausencia),
                   xmlelement("ausencia_dia_todo", ti.flag_ausencia_full),
                   xmlelement("mostra_no_apontam", ti.flag_formulario))
    INTO v_xml
    FROM tipo_apontam ti
   WHERE ti.tipo_apontam_id = p_tipo_apontam_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_documento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_apontam", v_xml))
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
END; -- TIPO_APONTAM_PKG



/
