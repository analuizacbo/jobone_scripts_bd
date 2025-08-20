--------------------------------------------------------
--  DDL for Package Body FI_BANCO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FI_BANCO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 05/09/2022
  -- DESCRICAO: Inclusão de FI_BANCO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_codigo            IN fi_banco.codigo%TYPE,
  p_nome              IN fi_banco.nome%TYPE,
  p_fi_banco_id       OUT fi_banco.fi_banco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_fi_banco_id    fi_banco.fi_banco_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt          := 0;
  p_fi_banco_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FI_BANCO_C', NULL, NULL, p_empresa_id) = 0 THEN
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
   p_erro_msg := 'O preenchimento do número obrigatório.';
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
    FROM fi_banco
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
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
  SELECT seq_fi_banco.nextval
    INTO v_fi_banco_id
    FROM dual;
  --
  INSERT INTO fi_banco
   (fi_banco_id,
    empresa_id,
    codigo,
    nome,
    flag_ativo)
  VALUES
   (v_fi_banco_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    'S');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  fi_banco_pkg.xml_gerar(v_fi_banco_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'FI_BANCO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_fi_banco_id,
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
  p_fi_banco_id := v_fi_banco_id;
  p_erro_cod    := '00000';
  p_erro_msg    := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 05/09/2022
  -- DESCRICAO: Atualização de FI_BANCO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_fi_banco_id       IN fi_banco.fi_banco_id%TYPE,
  p_codigo            IN fi_banco.codigo%TYPE,
  p_nome              IN fi_banco.nome%TYPE,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FI_BANCO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
   WHERE fi_banco_id = p_fi_banco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse banco não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id
     AND fi_banco_id <> p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND fi_banco_id <> p_fi_banco_id;
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
  fi_banco_pkg.xml_gerar(p_fi_banco_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE fi_banco
     SET codigo     = TRIM(upper(p_codigo)),
         nome       = TRIM(p_nome),
         flag_ativo = TRIM(p_flag_ativo)
   WHERE fi_banco_id = p_fi_banco_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  fi_banco_pkg.xml_gerar(p_fi_banco_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'FI_BANCO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_fi_banco_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 05/09/2022
  -- DESCRICAO: Exclusão de FI_BANCO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_fi_banco_id       IN fi_banco.fi_banco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         fi_banco.codigo%TYPE;
  v_nome           fi_banco.nome%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FI_BANCO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM fi_banco
   WHERE fi_banco_id = p_fi_banco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse banco não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM fi_banco
   WHERE fi_banco_id = p_fi_banco_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE fi_banco_id = p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem pessoas associadas a esse banco.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE fi_banco_fornec_id = p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a esse banco.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE fi_banco_cobrador_id = p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a esse banco.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE fi_banco_fornec_id = p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a esse banco.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_realiz
   WHERE fi_banco_id = p_fi_banco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos realizados associados a esse banco.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  fi_banco_pkg.xml_gerar(p_fi_banco_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM fi_banco
   WHERE fi_banco_id = p_fi_banco_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FI_BANCO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_fi_banco_id,
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
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/09/2022
  -- DESCRICAO: Subrotina que gera o xml do banco para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_fi_banco_id IN fi_banco.fi_banco_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
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
  SELECT xmlconcat(xmlelement("fi_banco_id", ti.fi_banco_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("ativo", ti.flag_ativo))
    INTO v_xml
    FROM fi_banco ti
   WHERE ti.fi_banco_id = p_fi_banco_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_documento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("fi_banco", v_xml))
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
END; -- FI_BANCO_PKG



/
