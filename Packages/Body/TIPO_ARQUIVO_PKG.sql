--------------------------------------------------------
--  DDL for Package Body TIPO_ARQUIVO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_ARQUIVO_PKG" IS
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 08/07/2013
  -- DESCRICAO: Atualização de TIPO_ARQUIVO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_arquivo_id   IN tipo_arquivo.tipo_arquivo_id%TYPE,
  p_nome              IN tipo_arquivo.nome%TYPE,
  p_tam_max_arq       IN VARCHAR2,
  p_qtd_max_arq       IN VARCHAR2,
  p_extensoes         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_arquivo.codigo%TYPE;
  v_tam_max_arq    tipo_arquivo.tam_max_arq%TYPE;
  v_qtd_max_arq    tipo_arquivo.qtd_max_arq%TYPE;
  v_extensoes      tipo_arquivo.extensoes%TYPE;
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
                                'TIPO_ARQUIVO_C',
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
    FROM tipo_arquivo
   WHERE tipo_arquivo_id = p_tipo_arquivo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo
    INTO v_codigo
    FROM tipo_arquivo
   WHERE tipo_arquivo_id = p_tipo_arquivo_id;
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_arquivo
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_arquivo_id <> p_tipo_arquivo_id;
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
  tipo_arquivo_pkg.xml_gerar(p_tipo_arquivo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_arquivo
     SET nome        = TRIM(p_nome),
         tam_max_arq = v_tam_max_arq,
         qtd_max_arq = v_qtd_max_arq,
         extensoes   = v_extensoes
   WHERE tipo_arquivo_id = p_tipo_arquivo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_arquivo_pkg.xml_gerar(p_tipo_arquivo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_ARQUIVO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_arquivo_id,
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
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/02/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de arquivo para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_arquivo_id IN tipo_arquivo.tipo_arquivo_id%TYPE,
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
  SELECT xmlconcat(xmlelement("tipo_arquivo_id", ti.tipo_arquivo_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ti.codigo),
                   xmlelement("nome", ti.nome),
                   xmlelement("tam_max_arq", to_char(ti.tam_max_arq)),
                   xmlelement("qtd_max_arq", to_char(ti.qtd_max_arq)),
                   xmlelement("extensoes", to_char(ti.extensoes)))
    INTO v_xml
    FROM tipo_arquivo ti
   WHERE ti.tipo_arquivo_id = p_tipo_arquivo_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_arquivo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_arquivo", v_xml))
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
END; -- TIPO_ARQUIVO_PKG



/
