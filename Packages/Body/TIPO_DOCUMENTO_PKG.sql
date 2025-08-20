--------------------------------------------------------
--  DDL for Package Body TIPO_DOCUMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_DOCUMENTO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2013
  -- DESCRICAO: Inclusão de TIPO_DOCUMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/08/2014  Novos atributos para interface de cliente.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_codigo            IN tipo_documento.codigo%TYPE,
  p_nome              IN tipo_documento.nome%TYPE,
  p_ordem_cli         IN VARCHAR2,
  p_flag_visivel_cli  IN VARCHAR2,
  p_tam_max_arq       IN VARCHAR2,
  p_qtd_max_arq       IN VARCHAR2,
  p_extensoes         IN VARCHAR2,
  p_flag_tem_aprov    IN VARCHAR2,
  p_flag_tem_comen    IN VARCHAR2,
  p_flag_tem_cienc    IN VARCHAR2,
  p_tipo_documento_id OUT tipo_documento.tipo_documento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_tipo_documento_id tipo_documento.tipo_documento_id%TYPE;
  v_tam_max_arq       tipo_documento.tam_max_arq%TYPE;
  v_qtd_max_arq       tipo_documento.qtd_max_arq%TYPE;
  v_extensoes         tipo_documento.extensoes%TYPE;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt                := 0;
  p_tipo_documento_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_DOCUMENTO_C',
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
  IF inteiro_validar(p_ordem_cli) = 0 OR to_number(p_ordem_cli) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da ordem inválido (' || p_ordem_cli || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_visivel_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag visível pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_tam_max_arq) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq) = 0 OR to_number(p_qtd_max_arq) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  v_tam_max_arq := to_number(p_tam_max_arq);
  v_qtd_max_arq := to_number(p_qtd_max_arq);
  v_extensoes   := TRIM(REPLACE(p_extensoes, ' ', ''));
  --
  IF flag_validar(p_flag_tem_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_comen) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem comentário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_cienc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem ciência inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_documento
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_codigo) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_documento
    WHERE upper(codigo) = TRIM(upper(p_codigo))
      AND empresa_id = p_empresa_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_documento.nextval
    INTO v_tipo_documento_id
    FROM dual;
  --
  INSERT INTO tipo_documento
   (tipo_documento_id,
    empresa_id,
    codigo,
    nome,
    flag_ativo,
    flag_sistema,
    flag_arq_externo,
    flag_tem_aprov,
    flag_tem_comen,
    flag_tem_cienc,
    tam_max_arq,
    qtd_max_arq,
    extensoes,
    ordem_cli,
    flag_visivel_cli)
  VALUES
   (v_tipo_documento_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    'S',
    'N',
    'N',
    p_flag_tem_aprov,
    p_flag_tem_comen,
    p_flag_tem_cienc,
    v_tam_max_arq,
    v_qtd_max_arq,
    v_extensoes,
    to_number(p_ordem_cli),
    p_flag_visivel_cli);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_documento_pkg.xml_gerar(v_tipo_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_DOCUMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_documento_id,
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
  p_tipo_documento_id := v_tipo_documento_id;
  p_erro_cod          := '00000';
  p_erro_msg          := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2013
  -- DESCRICAO: Atualização de TIPO_DOCUMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/08/2014  Novos atributos para interface de cliente.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
  p_codigo            IN tipo_documento.codigo%TYPE,
  p_nome              IN tipo_documento.nome%TYPE,
  p_ordem_cli         IN VARCHAR2,
  p_flag_visivel_cli  IN VARCHAR2,
  p_tam_max_arq       IN VARCHAR2,
  p_qtd_max_arq       IN VARCHAR2,
  p_extensoes         IN VARCHAR2,
  p_flag_tem_aprov    IN VARCHAR2,
  p_flag_tem_comen    IN VARCHAR2,
  p_flag_tem_cienc    IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_tam_max_arq    tipo_documento.tam_max_arq%TYPE;
  v_qtd_max_arq    tipo_documento.qtd_max_arq%TYPE;
  v_extensoes      tipo_documento.extensoes%TYPE;
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
                                'TIPO_DOCUMENTO_C',
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
    FROM tipo_documento
   WHERE tipo_documento_id = p_tipo_documento_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de documento não existe.';
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
  IF inteiro_validar(p_ordem_cli) = 0 OR to_number(p_ordem_cli) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da ordem inválido (' || p_ordem_cli || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_visivel_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag visível pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_tam_max_arq) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho máximo de cada arquivo inválido (' || p_tam_max_arq || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_max_arq) = 0 OR to_number(p_qtd_max_arq) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade máxima de arquivos inválida (' || p_qtd_max_arq || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_extensoes) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O conteúdo do campo extensões não pode ter mais que 100 caractares.';
   RAISE v_exception;
  END IF;
  --
  v_tam_max_arq := to_number(p_tam_max_arq);
  v_qtd_max_arq := to_number(p_qtd_max_arq);
  v_extensoes   := TRIM(REPLACE(p_extensoes, ' ', ''));
  --
  IF flag_validar(p_flag_tem_aprov) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem aprovação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_comen) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem comentário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_cienc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem ciência inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_documento
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_documento_id <> p_tipo_documento_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe (' || p_nome || ') .';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_codigo) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_documento
    WHERE upper(codigo) = TRIM(upper(p_codigo))
      AND empresa_id = p_empresa_id
      AND tipo_documento_id <> p_tipo_documento_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse código já existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_documento_pkg.xml_gerar(p_tipo_documento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_documento
     SET codigo           = TRIM(upper(p_codigo)),
         nome             = TRIM(p_nome),
         flag_ativo       = p_flag_ativo,
         flag_tem_aprov   = p_flag_tem_aprov,
         flag_tem_comen   = p_flag_tem_comen,
         flag_tem_cienc   = p_flag_tem_cienc,
         tam_max_arq      = v_tam_max_arq,
         qtd_max_arq      = v_qtd_max_arq,
         extensoes        = v_extensoes,
         ordem_cli        = to_number(p_ordem_cli),
         flag_visivel_cli = p_flag_visivel_cli
   WHERE tipo_documento_id = p_tipo_documento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_documento_pkg.xml_gerar(p_tipo_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TIPO_DOCUMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_documento_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 02/07/2013
  -- DESCRICAO: Exclusão de TIPO_DOCUMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_documento.codigo%TYPE;
  v_nome           tipo_documento.nome%TYPE;
  v_flag_sistema   tipo_documento.flag_sistema%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'TIPO_DOCUMENTO_C',
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
    FROM tipo_documento
   WHERE tipo_documento_id = p_tipo_documento_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de documento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome,
         flag_sistema
    INTO v_codigo,
         v_nome,
         v_flag_sistema
    FROM tipo_documento
   WHERE tipo_documento_id = p_tipo_documento_id;
  --
  IF v_flag_sistema = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipos de documentos do sistema não podem ser excluídos.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM documento
   WHERE tipo_documento_id = p_tipo_documento_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem documentos associados a esse tipo de documento.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv_tdoc
   WHERE tipo_documento_id = p_tipo_documento_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem papéis configurados com privilégios para esse tipo de documento.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_documento_pkg.xml_gerar(p_tipo_documento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_documento
   WHERE tipo_documento_id = p_tipo_documento_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_DOCUMENTO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_documento_id,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/02/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de documento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_documento_id IN tipo_documento.tipo_documento_id%TYPE,
  p_xml               OUT CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_to IS
   SELECT pr.nome,
          pr.codigo,
          pa.nome AS papel,
          decode(pt.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang_sec
     FROM privilegio      pr,
          papel_priv_tdoc pt,
          papel           pa
    WHERE pt.tipo_documento_id = p_tipo_documento_id
      AND pt.privilegio_id = pr.privilegio_id
      AND pt.papel_id = pa.papel_id
    ORDER BY pr.nome,
             pt.abrangencia,
             pa.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tipo_documento_id", ti.tipo_documento_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("do_sistema", ti.flag_sistema),
                   xmlelement("tem_aprovacao", ti.flag_tem_aprov),
                   xmlelement("tem_comentario", ti.flag_tem_comen),
                   xmlelement("tem_ciencia", ti.flag_tem_cienc),
                   xmlelement("visivel_cliente", ti.flag_visivel_cli),
                   xmlelement("ordenacao_cliente", to_char(ti.ordem_cli)),
                   xmlelement("arquivo_externo", ti.flag_arq_externo),
                   xmlelement("tam_max_arq", to_char(ti.tam_max_arq)),
                   xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq)),
                   xmlelement("extensoes", to_char(ti.extensoes)))
    INTO v_xml
    FROM tipo_documento ti
   WHERE ti.tipo_documento_id = p_tipo_documento_id;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO DOC
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_to IN c_to
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_to.codigo),
                            xmlelement("priv_nome", r_to.nome),
                            xmlelement("papel", r_to.papel),
                            xmlelement("abrang", r_to.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_tipo_documento", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_documento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_documento", v_xml))
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
END; -- TIPO_DOCUMENTO_PKG



/
