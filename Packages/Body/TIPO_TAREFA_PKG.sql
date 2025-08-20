--------------------------------------------------------
--  DDL for Package Body TIPO_TAREFA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_TAREFA_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/07/2021
  -- DESCRICAO: Inclusão de TIPO_TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nome              IN tipo_tarefa.nome%TYPE,
  p_tipo_tarefa_id    OUT tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_tipo_tarefa_id tipo_tarefa.tipo_tarefa_id%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt             := 0;
  p_tipo_tarefa_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_TAREFA_C', NULL, NULL, p_empresa_id) = 0 THEN
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
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE upper(nome) = upper(TRIM(p_nome))
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
  SELECT seq_tipo_tarefa.nextval
    INTO v_tipo_tarefa_id
    FROM dual;
  --
  INSERT INTO tipo_tarefa
   (tipo_tarefa_id,
    empresa_id,
    nome,
    flag_ativo,
    flag_padrao,
    flag_tem_descricao,
    flag_tem_corpo,
    flag_tem_itens,
    flag_obriga_item,
    flag_tem_desc_item,
    flag_tem_meta_item,
    flag_auto_ender,
    flag_pode_ender_exec,
    flag_abre_arq_refer,
    flag_abre_arq_exec,
    flag_abre_afazer,
    flag_abre_repet,
    num_max_itens)
  VALUES
   (v_tipo_tarefa_id,
    p_empresa_id,
    TRIM(p_nome),
    'S',
    'N',
    'N',
    'N',
    'S',
    'S',
    'S',
    'S',
    'N',
    'S',
    'N',
    'S',
    'N',
    'N',
    NULL);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_tarefa_pkg.xml_gerar(v_tipo_tarefa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_TAREFA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_tarefa_id,
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
  p_tipo_tarefa_id := v_tipo_tarefa_id;
  p_erro_cod       := '00000';
  p_erro_msg       := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/07/2021
  -- DESCRICAO: Atualização de TIPO_TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         04/03/2024  Adicionado critica se prazo maior que 09 dias.
  -- Ana Luiza         14/01/2025  Adicao de parametro FLAG_APONT_HORAS_ALOC
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id        IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_nome                  IN tipo_tarefa.nome%TYPE,
  p_flag_ativo            IN VARCHAR2,
  p_flag_tem_descricao    IN VARCHAR2,
  p_flag_tem_corpo        IN VARCHAR2,
  p_flag_tem_itens        IN VARCHAR2,
  p_flag_obriga_item      IN VARCHAR2,
  p_flag_tem_desc_item    IN VARCHAR2,
  p_flag_tem_meta_item    IN VARCHAR2,
  p_flag_auto_ender       IN VARCHAR2,
  p_flag_pode_ender_exec  IN VARCHAR2,
  p_flag_abre_arq_refer   IN VARCHAR2,
  p_flag_abre_arq_exec    IN VARCHAR2,
  p_flag_abre_afazer      IN VARCHAR2,
  p_flag_abre_repet       IN VARCHAR2,
  p_num_max_itens         IN VARCHAR2,
  p_num_max_dias_prazo    IN VARCHAR2,
  p_flag_apont_horas_aloc IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_num_max_itens      tipo_tarefa.num_max_itens%TYPE;
  v_num_max_dias_prazo tipo_tarefa.num_max_dias_prazo%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_delimitador        CHAR(1);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_TAREFA_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Task não existe ou não pertence a essa empresa.';
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
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_descricao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem descrição inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_corpo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem corpo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_itens) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem itens inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga item inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_desc_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem descrição do item inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_meta_item) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag tem metadados no item inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag auto endereçamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_ender_exec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode endereçar executores inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_abre_arq_refer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag abre seção arquivo referência inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_abre_arq_exec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag abre seção arquivo execução inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_abre_afazer) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag abre seção a fazer inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_abre_repet) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag abre seção repetição inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_max_itens) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_max_itens := to_number(p_num_max_itens);
  --
  IF v_num_max_itens <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_max_dias_prazo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número máximo de dias de prazo inválido (' || p_num_max_dias_prazo || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_max_dias_prazo := to_number(p_num_max_dias_prazo);
  --
  IF v_num_max_dias_prazo <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número máximo de dias de prazo inválido (' || p_num_max_dias_prazo || ').';
   RAISE v_exception;
  END IF;
  --ALCBO_040324
  IF v_num_max_dias_prazo > 90 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é permitida a duração maior que 90 dias';
   RAISE v_exception;
  END IF;
  --ALCBO_140125
  IF flag_validar(p_flag_apont_horas_aloc) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag apontar horas alocadas de forma automática inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE upper(nome) = upper(TRIM(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_tarefa_id <> p_tipo_tarefa_id;
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
  tipo_tarefa_pkg.xml_gerar(p_tipo_tarefa_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_tarefa
     SET nome                  = TRIM(p_nome),
         flag_ativo            = p_flag_ativo,
         flag_tem_descricao    = p_flag_tem_descricao,
         flag_tem_corpo        = p_flag_tem_corpo,
         flag_tem_itens        = p_flag_tem_itens,
         flag_obriga_item      = p_flag_obriga_item,
         flag_tem_desc_item    = p_flag_tem_desc_item,
         flag_tem_meta_item    = p_flag_tem_meta_item,
         flag_auto_ender       = p_flag_auto_ender,
         flag_pode_ender_exec  = p_flag_pode_ender_exec,
         flag_abre_arq_refer   = p_flag_abre_arq_refer,
         flag_abre_arq_exec    = p_flag_abre_arq_exec,
         flag_abre_afazer      = p_flag_abre_afazer,
         flag_abre_repet       = p_flag_abre_repet,
         num_max_itens         = v_num_max_itens,
         num_max_dias_prazo    = v_num_max_dias_prazo,
         flag_apont_horas_aloc = p_flag_apont_horas_aloc
   WHERE tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_tarefa_pkg.xml_gerar(p_tipo_tarefa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_tarefa_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/07/2021
  -- DESCRICAO: Exclusão de TIPO_TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         21/01/2025  Adicao de tratamento para tasks vinculadas
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id    IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_nome           tipo_tarefa.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_TAREFA_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM equipe
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem Equipes associadas a esse Tipo de Task.';
   RAISE v_exception;
  END IF;
  --ALCBO_210125
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem Tasks associadas a esse Tipo de Task.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_tarefa_pkg.xml_gerar(p_tipo_tarefa_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_TAREFA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_tarefa_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE padrao_definir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/07/2021
  -- DESCRICAO: Torna TIPO_TAREFA padrao
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_tarefa_id    IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_nome           tipo_tarefa.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_TAREFA_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = p_tipo_tarefa_id
     AND flag_padrao = 'S';
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de task já é padrão.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_tarefa
     SET flag_padrao = 'N'
   WHERE empresa_id = p_empresa_id;
  --
  UPDATE tipo_tarefa
     SET flag_padrao = 'S'
   WHERE tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Definição de tipo padrão';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_tarefa_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END padrao_definir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 27/07/2021
  -- DESCRICAO: Subrotina que gera o xml do tipo de OS para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_tarefa_id IN tipo_tarefa.tipo_tarefa_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
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
  SELECT xmlconcat(xmlelement("tipo_tarefa_id", ti.tipo_tarefa_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", ti.nome),
                   xmlelement("ativo", ti.flag_ativo),
                   xmlelement("padrao", ti.flag_padrao),
                   xmlelement("tem_descricao", ti.flag_tem_descricao),
                   xmlelement("tem_corpo", ti.flag_tem_corpo),
                   xmlelement("tem_itens", ti.flag_tem_itens),
                   xmlelement("obriga_item", ti.flag_obriga_item),
                   xmlelement("tem_desc_item", ti.flag_tem_desc_item),
                   xmlelement("tem_metadado_item", ti.flag_tem_meta_item),
                   xmlelement("auto_ender", ti.flag_auto_ender),
                   xmlelement("pode_ender_exec", ti.flag_pode_ender_exec),
                   xmlelement("abre_arq_refer", ti.flag_abre_arq_refer),
                   xmlelement("abre_arq_exec", ti.flag_abre_arq_exec),
                   xmlelement("abre_afazer", ti.flag_abre_afazer),
                   xmlelement("abre_repet", ti.flag_abre_repet),
                   xmlelement("itens_num_max", ti.num_max_itens),
                   xmlelement("num_max_dias_prazo", ti.num_max_dias_prazo))
    INTO v_xml
    FROM tipo_tarefa ti
   WHERE ti.tipo_tarefa_id = p_tipo_tarefa_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_tarefa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_tarefa", v_xml))
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END xml_gerar;
 --
--
END; -- TIPO_TAREFA_PKG

/
