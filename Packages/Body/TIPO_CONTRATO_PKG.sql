--------------------------------------------------------
--  DDL for Package Body TIPO_CONTRATO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_CONTRATO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/08/2014
  -- DESCRICAO: Inclusão de TIPO_CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- José Mario        13/02/2022  Inclusão das flags FLAG_VERIFI_PRECIF, FLAG_VERIFI_HORAS,
  --                                                  FLAG_ELAB_CONTRATO E FLAG_ALOC_USUARIO
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_codigo             IN tipo_contrato.codigo%TYPE,
  p_cod_ext_tipo       IN tipo_contrato.cod_ext_tipo%TYPE,
  p_nome               IN tipo_contrato.nome%TYPE,
  p_flag_padrao        IN VARCHAR2,
  p_flag_tem_horas     IN VARCHAR2,
  p_flag_tem_fee       IN VARCHAR2,
  p_tipo_contratante   IN tipo_contrato.tipo_contratante%TYPE,
  p_flag_verifi_precif IN tipo_contrato.flag_verifi_precif%TYPE,
  p_flag_verifi_horas  IN tipo_contrato.flag_verifi_horas%TYPE,
  p_flag_elab_contrato IN tipo_contrato.flag_elab_contrato%TYPE,
  p_flag_aloc_usuario  IN tipo_contrato.flag_aloc_usuario%TYPE,
  p_tipo_contrato_id   OUT tipo_contrato.tipo_contrato_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_tipo_contrato_id tipo_contrato.tipo_contrato_id%TYPE;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt               := 0;
  p_tipo_contrato_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_CONTRATO_C',
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
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_horas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_fee) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem fee inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_contratante) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de contratante obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_contratante) NOT IN ('CLI', 'FOR', 'CLIFOR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de contratante inválido (' || p_tipo_contratante || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
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
    FROM tipo_contrato
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
  SELECT seq_tipo_contrato.nextval
    INTO v_tipo_contrato_id
    FROM dual;
  --
  INSERT INTO tipo_contrato
   (tipo_contrato_id,
    empresa_id,
    codigo,
    cod_ext_tipo,
    nome,
    flag_ativo,
    flag_padrao,
    flag_tem_horas,
    flag_tem_fee,
    tipo_contratante,
    flag_verifi_precif,
    flag_verifi_horas,
    flag_elab_contrato,
    flag_aloc_usuario)
  VALUES
   (v_tipo_contrato_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_cod_ext_tipo),
    TRIM(p_nome),
    'S',
    TRIM(p_flag_padrao),
    TRIM(p_flag_tem_horas),
    TRIM(p_flag_tem_fee),
    TRIM(p_tipo_contratante),
    TRIM(p_flag_verifi_precif),
    TRIM(p_flag_verifi_horas),
    TRIM(p_flag_elab_contrato),
    TRIM(p_flag_aloc_usuario));
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo pode ser padrao.
   UPDATE tipo_contrato
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_contrato_id <> v_tipo_contrato_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_contrato_pkg.xml_gerar(v_tipo_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_CONTRATO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_contrato_id,
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
  p_tipo_contrato_id := v_tipo_contrato_id;
  p_erro_cod         := '00000';
  p_erro_msg         := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/08/2014
  -- DESCRICAO: Atualização de TIPO_CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- José Mario        13/02/2022  Inclusão das flags FLAG_VERIFI_PRECIF, FLAG_VERIFI_HORAS,
  --                                                  FLAG_ELAB_CONTRATO E FLAG_ALOC_USUARIO
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_tipo_contrato_id   IN tipo_contrato.tipo_contrato_id%TYPE,
  p_codigo             IN tipo_contrato.codigo%TYPE,
  p_cod_ext_tipo       IN tipo_contrato.cod_ext_tipo%TYPE,
  p_nome               IN tipo_contrato.nome%TYPE,
  p_flag_ativo         IN VARCHAR2,
  p_flag_padrao        IN VARCHAR2,
  p_flag_tem_horas     IN VARCHAR2,
  p_flag_tem_fee       IN VARCHAR2,
  p_tipo_contratante   IN tipo_contrato.tipo_contratante%TYPE,
  p_flag_verifi_precif IN tipo_contrato.flag_verifi_precif%TYPE,
  p_flag_verifi_horas  IN tipo_contrato.flag_verifi_horas%TYPE,
  p_flag_elab_contrato IN tipo_contrato.flag_elab_contrato%TYPE,
  p_flag_aloc_usuario  IN tipo_contrato.flag_aloc_usuario%TYPE,
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
                                'TIPO_CONTRATO_C',
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
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de contrato não existe.';
   RAISE v_exception;
  END IF;
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
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_horas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_fee) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem fee inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_contratante) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de contratante obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_contratante) NOT IN ('CLI', 'FOR', 'CLIFOR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de contratante inválido (' || p_tipo_contratante || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id
     AND tipo_contrato_id <> p_tipo_contrato_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_contrato
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_contrato_id <> p_tipo_contrato_id;
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
  tipo_contrato_pkg.xml_gerar(p_tipo_contrato_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_contrato
     SET codigo             = TRIM(upper(p_codigo)),
         nome               = TRIM(p_nome),
         cod_ext_tipo       = TRIM(p_cod_ext_tipo),
         flag_ativo         = TRIM(p_flag_ativo),
         flag_padrao        = TRIM(p_flag_padrao),
         flag_tem_horas     = TRIM(p_flag_tem_horas),
         flag_tem_fee       = TRIM(p_flag_tem_fee),
         tipo_contratante   = TRIM(p_tipo_contratante),
         flag_verifi_precif = TRIM(p_flag_verifi_precif),
         flag_verifi_horas  = TRIM(p_flag_verifi_horas),
         flag_elab_contrato = TRIM(p_flag_elab_contrato),
         flag_aloc_usuario  = TRIM(p_flag_aloc_usuario)
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo pode ser padrao.
   UPDATE tipo_contrato
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_contrato_id <> p_tipo_contrato_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_contrato_pkg.xml_gerar(p_tipo_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_CONTRATO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_contrato_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/08/2014
  -- DESCRICAO: Exclusão de TIPO_CONTRATO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_contrato_id  IN tipo_contrato.tipo_contrato_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_contrato.codigo%TYPE;
  v_nome           tipo_contrato.nome%TYPE;
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
                                'TIPO_CONTRATO_C',
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
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de contrato não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem contratos associados a esse tipo de contrato.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem oportunidades associadas a esse tipo de contrato.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_contrato_pkg.xml_gerar(p_tipo_contrato_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_contrato
   WHERE tipo_contrato_id = p_tipo_contrato_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_CONTRATO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_contrato_id,
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
  -- DESCRICAO: Subrotina que gera o xml do tipo de contrato para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_contrato_id IN tipo_contrato.tipo_contrato_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
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
  SELECT xmlconcat(xmlelement("tipo_contrato_id", ti.tipo_contrato_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("padrao", ti.flag_padrao),
                   xmlelement("tem_horas", ti.flag_tem_horas),
                   xmlelement("tem_fee", ti.flag_tem_fee),
                   xmlelement("tipo_contratante",
                              decode(ti.tipo_contratante,
                                     'CLI',
                                     'Cliente',
                                     'FOR',
                                     'Fornecedor',
                                     'Ambos')),
                   xmlelement("cod_ext_tipo", ti.cod_ext_tipo),
                   xmlelement("verif_precif", ti.flag_verifi_precif),
                   xmlelement("verifi_horas", ti.flag_verifi_horas),
                   xmlelement("elab_contrato", ti.flag_elab_contrato),
                   xmlelement("aloc_usuario", ti.flag_aloc_usuario))
    INTO v_xml
    FROM tipo_contrato ti
   WHERE ti.tipo_contrato_id = p_tipo_contrato_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_documento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_contrato", v_xml))
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
END; -- TIPO_CONTRATO_PKG



/
