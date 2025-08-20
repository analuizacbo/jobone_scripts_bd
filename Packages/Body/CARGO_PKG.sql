--------------------------------------------------------
--  DDL for Package Body CARGO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CARGO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 22/09/2016
  -- DESCRICAO: Inclusão de CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  --------------------------------------------------------
  -- Silvia            11/05/2017  Inclusao de area no cargo
  -- Silvia            03/06/2019  Inclusao de ordem no cargo
  -- Silvia            21/01/2021  Inclusao de qtd_vagas_aprov
  -- Silvia            24/06/2022  Inclusao de flag_aloc_usu_ctr
  -- Ana Luiza         31/05/2023  Inclusao subrotina tab_preco_vincular
  --                               e alteração parametros
  -----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_area_id              IN cargo.area_id%TYPE,
  p_nome                 IN cargo.nome%TYPE,
  p_ordem                IN VARCHAR2,
  p_qtd_vagas_aprov      IN VARCHAR2,
  p_flag_aloc_usu_ctr    IN VARCHAR2,
  p_vetor_preco_id       IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_cargo_id             OUT cargo.cargo_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cargo_id        cargo.cargo_id%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_ordem           cargo.ordem%TYPE;
  v_qtd_vagas_aprov cargo.qtd_vagas_aprov%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt       := 0;
  p_cargo_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CARGO_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM area
   WHERE area_id = p_area_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa área não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := to_number(p_ordem);
  --
  IF flag_validar(p_flag_aloc_usu_ctr) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com alocação de usuário no contrato inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_vagas_aprov) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_qtd_vagas_aprov := to_number(p_qtd_vagas_aprov);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE empresa_id = p_empresa_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de cargo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_cargo.nextval
    INTO v_cargo_id
    FROM dual;
  --
  INSERT INTO cargo
   (cargo_id,
    empresa_id,
    nome,
    flag_aloc_usu_ctr,
    flag_ativo,
    area_id,
    ordem,
    qtd_vagas_aprov)
  VALUES
   (v_cargo_id,
    p_empresa_id,
    TRIM(p_nome),
    p_flag_aloc_usu_ctr,
    'S',
    p_area_id,
    v_ordem,
    v_qtd_vagas_aprov);
  --
  -----------------------------------------------------------------------------------
  -- Adicao subrotina sem commit, vincula tabela de preço à salario_cargo
  -----------------------------------------------------------------------------------
  --ALCBO_310523
  preco_pkg.salario_cargo_vincular(p_usuario_sessao_id,
                                   p_empresa_id,
                                   v_cargo_id,
                                   p_vetor_preco_id,
                                   p_vetor_nivel,
                                   p_vetor_faixa_salarial,
                                   p_vetor_beneficio,
                                   p_vetor_encargo,
                                   p_vetor_dissidio,
                                   p_vetor_overhead,
                                   p_vetor_custo_hora,
                                   p_vetor_custo_mensal,
                                   p_vetor_venda_mensal,
                                   p_vetor_margem_hora,
                                   p_erro_cod,
                                   p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cargo_pkg.xml_gerar(v_cargo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
                   'CARGO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_cargo_id := v_cargo_id;
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
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 22/09/2016
  -- DESCRICAO: Atualização de CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/05/2017  Inclusao de area no cargo
  -- Silvia            03/06/2019  Inclusao de ordem no cargo
  -- Silvia            21/01/2021  Inclusao de qtd_vagas_aprov
  -- Silvia            24/06/2022  Inclusao de flag_aloc_usu_ctr
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_area_id           IN cargo.area_id%TYPE,
  p_nome              IN cargo.nome%TYPE,
  p_ordem             IN VARCHAR2,
  p_qtd_vagas_aprov   IN VARCHAR2,
  p_flag_aloc_usu_ctr IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_ordem           cargo.ordem%TYPE;
  v_qtd_vagas_aprov cargo.qtd_vagas_aprov%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CARGO_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM area
   WHERE area_id = p_area_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa área não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := to_number(p_ordem);
  --
  IF flag_validar(p_flag_aloc_usu_ctr) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com alocação de usuário no contrato inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_qtd_vagas_aprov) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_qtd_vagas_aprov := to_number(p_qtd_vagas_aprov);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE empresa_id = p_empresa_id
     AND cargo_id <> p_cargo_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de cargo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cargo_pkg.xml_gerar(p_cargo_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE cargo
     SET nome              = TRIM(p_nome),
         flag_ativo        = p_flag_ativo,
         flag_aloc_usu_ctr = p_flag_aloc_usu_ctr,
         area_id           = p_area_id,
         ordem             = v_ordem,
         qtd_vagas_aprov   = v_qtd_vagas_aprov
   WHERE cargo_id = p_cargo_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cargo_pkg.xml_gerar(p_cargo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
                   'CARGO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 22/09/2016
  -- DESCRICAO: Exclusão de CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           cargo.nome%TYPE;
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
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CARGO_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_cargo
   WHERE cargo_id = p_cargo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem usuários associados a esse cargo.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM contrato_horas
   WHERE cargo_id = p_cargo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem estimativas de horas em contratos associadas a esse cargo.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_horas
   WHERE cargo_id = p_cargo_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem estimativas de horas em ' || v_lbl_jobs || ' associadas a esse cargo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cargo_pkg.xml_gerar(p_cargo_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM salario_cargo
   WHERE cargo_id = p_cargo_id;
 
  DELETE FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARGO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
 PROCEDURE salario_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 22/09/2016
  -- DESCRICAO: Inclusão de SALARIO do CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         24/05/2023  Adicao de novas colunas.
  -- Ana Luiza         30/11/2023  Remoção obrigatoriedade valor de venda de acordo com --
  --                               parametro
  -- Ana Luiza         12/12/2023  Adicao horas estagiario
  -- Ana Luiza         28/08/2024  Ajuste calculo, evitar 99999
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_data_ini             IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_vetor_margem_mensal  IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_salario_cargo_id salario_cargo.salario_cargo_id%TYPE;
  v_nivel            salario_cargo.nivel%TYPE;
  --v_data_ini           salario_cargo.data_ini%TYPE;
  --v_data_ini_ant       salario_cargo.data_ini%TYPE;
  v_custo_mensal       salario_cargo.custo_mensal%TYPE;
  v_custo_hora         salario_cargo.custo_hora%TYPE;
  v_venda_mensal       salario_cargo.venda_mensal%TYPE;
  v_venda_hora         salario_cargo.venda_hora%TYPE;
  v_custo_mensal_en    salario_cargo.custo_mensal%TYPE;
  v_custo_hora_en      salario_cargo.custo_hora%TYPE;
  v_venda_mensal_en    salario_cargo.venda_mensal%TYPE;
  v_venda_hora_en      salario_cargo.venda_hora%TYPE;
  v_nome_cargo         cargo.nome%TYPE;
  v_qt_horas           NUMBER;
  v_delimitador        CHAR(1);
  v_vetor_nivel        VARCHAR2(1000);
  v_vetor_custo_mensal VARCHAR2(1000);
  v_vetor_venda_mensal VARCHAR2(1000);
  v_venda_mensal_char  VARCHAR2(20);
  v_custo_mensal_char  VARCHAR2(20);
  --ALCBO_240523
  v_faixa_salarial salario_cargo.faixa_salarial%TYPE;
  v_beneficio      salario_cargo.beneficio%TYPE;
  v_encargo        salario_cargo.encargo%TYPE;
  v_dissidio       salario_cargo.dissidio%TYPE;
  v_overhead       salario_cargo.overhead%TYPE;
  v_margem_hora    salario_cargo.margem_hora%TYPE;
  v_margem_mensal  salario_cargo.margem_mensal%TYPE;
  --
  v_faixa_salarial_en salario_cargo.faixa_salarial%TYPE;
  v_beneficio_en      salario_cargo.beneficio%TYPE;
  v_encargo_en        salario_cargo.encargo%TYPE;
  v_dissidio_en       salario_cargo.dissidio%TYPE;
  v_overhead_en       salario_cargo.overhead%TYPE;
  v_margem_hora_en    salario_cargo.margem_hora%TYPE;
  v_margem_mensal_en  salario_cargo.margem_mensal%TYPE;
  --
  v_vetor_faixa_salarial VARCHAR2(1000);
  v_vetor_beneficio      VARCHAR2(1000);
  v_vetor_encargo        VARCHAR2(1000);
  v_vetor_dissidio       VARCHAR2(1000);
  v_vetor_overhead       VARCHAR2(1000);
  v_vetor_margem_hora    VARCHAR2(1000);
  v_vetor_margem_mensal  VARCHAR2(1000);
  --
  v_faixa_salarial_char VARCHAR2(20);
  v_beneficio_char      VARCHAR2(20);
  v_encargo_char        VARCHAR2(20);
  v_dissidio_char       VARCHAR2(20);
  v_overhead_char       VARCHAR2(20);
  v_margem_hora_char    VARCHAR2(20);
  v_margem_mensal_char  VARCHAR2(20);
  --
  v_parametro           CHAR(1);
  v_qt_horas_estagiario NUMBER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARGO_CUSTO_PRECO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  /*
  IF v_qt = 0
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
  RAISE v_exception;
  END IF;
  */
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
  IF rtrim(p_data_ini) IS NULL
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'O preenchimento da data é obrigatório.';
  RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_ini) = 0
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Data inválida(' || p_data_ini || ').';
  RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || p_data_ini);
  --
  SELECT MAX(data_ini)
  INTO   v_data_ini_ant
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id;
  --
  IF v_data_ini <= v_data_ini_ant
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'A data não pode ser anterior ou igual a datas já cadastradas.';
  RAISE v_exception;
  END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador        := '|';
  v_vetor_nivel        := rtrim(p_vetor_nivel);
  v_vetor_custo_mensal := rtrim(p_vetor_custo_mensal);
  v_vetor_venda_mensal := rtrim(p_vetor_venda_mensal);
  --ALCBO_240523
  v_vetor_faixa_salarial := rtrim(p_vetor_faixa_salarial);
  v_vetor_beneficio      := rtrim(p_vetor_beneficio);
  v_vetor_encargo        := rtrim(p_vetor_encargo);
  v_vetor_dissidio       := rtrim(p_vetor_dissidio);
  v_vetor_overhead       := rtrim(p_vetor_overhead);
  v_vetor_margem_hora    := rtrim(p_vetor_margem_hora);
  v_vetor_margem_mensal  := rtrim(p_vetor_margem_mensal);
  --
  WHILE nvl(length(rtrim(v_vetor_nivel)), 0) > 0
  LOOP
   --
   v_nivel             := prox_valor_retornar(v_vetor_nivel, v_delimitador);
   v_custo_mensal_char := prox_valor_retornar(v_vetor_custo_mensal, v_delimitador);
   v_venda_mensal_char := prox_valor_retornar(v_vetor_venda_mensal, v_delimitador);
   --ALCBO_240523
   v_faixa_salarial_char := prox_valor_retornar(v_vetor_faixa_salarial, v_delimitador);
   v_beneficio_char      := prox_valor_retornar(v_vetor_beneficio, v_delimitador);
   v_encargo_char        := prox_valor_retornar(v_vetor_encargo, v_delimitador);
   v_dissidio_char       := prox_valor_retornar(v_vetor_dissidio, v_delimitador);
   v_overhead_char       := prox_valor_retornar(v_vetor_overhead, v_delimitador);
   v_margem_hora_char    := prox_valor_retornar(v_vetor_margem_hora, v_delimitador);
   v_margem_mensal_char  := prox_valor_retornar(v_vetor_margem_mensal, v_delimitador);
   --ALCBO_240523F
   IF util_pkg.desc_retornar('nivel_usuario', v_nivel) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível inválido (' || v_nivel || ').';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(v_custo_mensal_char) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_custo_mensal_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo inválido (' || v_custo_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --
   --ALCBO_301123
   v_parametro := empresa_pkg.parametro_retornar(p_empresa_id, 'COMP_CUSTO_PRECO_CARGO');
   --
   IF v_parametro = 'S'
   THEN
    IF rtrim(v_venda_mensal_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do valor de venda é obrigatório.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_venda_mensal_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de venda inválido (' || v_venda_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_240523
   IF moeda_validar(v_faixa_salarial_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de benefício inválido (' || v_faixa_salarial_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_beneficio_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de benefício inválido (' || v_beneficio_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_dissidio_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de dissídio inválido (' || v_dissidio_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_overhead_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de overhead inválido (' || v_overhead_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_margem_hora_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de margem hora inválido (' || v_margem_hora_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_margem_mensal_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de margem mensal inválido (' || v_margem_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_240523F
   --
   v_custo_mensal := nvl(moeda_converter(v_custo_mensal_char), 0);
   v_venda_mensal := nvl(moeda_converter(v_venda_mensal_char), 0);
   --ALCBO_280824 --REMOVIDO DAQUI
   --ALCBO_121223
   v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id, 'QT_HORAS_MENSAIS'));
   IF v_nivel = 'E'
   THEN
    --ALCBO_121223
    v_qt_horas_estagiario := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                             'QT_HORAS_MENSAIS_ESTAG'));
    v_qt_horas            := v_qt_horas_estagiario;
   END IF;
   --ALCBO_280824 --MOVIDO AQUI
   v_custo_hora := round(v_custo_mensal / v_qt_horas, 2);
   v_venda_hora := round(v_venda_mensal / v_qt_horas, 2);
   --
   --ALCBO_240523
   v_faixa_salarial := nvl(moeda_converter(v_faixa_salarial_char), 0);
   v_beneficio      := nvl(moeda_converter(v_beneficio_char), 0);
   v_encargo        := nvl(moeda_converter(v_encargo_char), 0);
   v_dissidio       := nvl(moeda_converter(v_dissidio_char), 0);
   v_overhead       := nvl(moeda_converter(v_overhead_char), 0);
   v_margem_hora    := nvl(moeda_converter(v_margem_hora_char), 0);
   v_margem_mensal  := nvl(moeda_converter(v_margem_mensal_char), 0);
   --ALCBO_240523F
   -- encripta para salvar
   v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
   --
   IF v_custo_mensal_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
   --
   IF v_venda_mensal_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
   --
   IF v_custo_hora_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
   --
   IF v_venda_hora_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --ALCBO_240523
   v_faixa_salarial_en := util_pkg.num_encode(v_faixa_salarial);
   --
   IF v_faixa_salarial_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_faixa_salarial, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_beneficio_en := util_pkg.num_encode(v_beneficio);
   --
   IF v_beneficio_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_beneficio, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_encargo_en := util_pkg.num_encode(v_encargo);
   --
   IF v_encargo_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_encargo, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_dissidio_en := util_pkg.num_encode(v_dissidio);
   --
   IF v_dissidio_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_dissidio, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_overhead_en := util_pkg.num_encode(v_overhead);
   --
   IF v_overhead_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_overhead, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_margem_hora_en := util_pkg.num_encode(v_margem_hora);
   --
   IF v_margem_hora_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_margem_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_margem_mensal_en := util_pkg.num_encode(v_margem_mensal);
   --
   IF v_margem_mensal_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_margem_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_240523F
   SELECT seq_salario_cargo.nextval
     INTO v_salario_cargo_id
     FROM dual;
   --
   INSERT INTO salario_cargo
    (salario_cargo_id,
     cargo_id,
     nivel,
     custo_mensal,
     custo_hora,
     venda_mensal,
     venda_hora,
     faixa_salarial,
     beneficio,
     encargo,
     dissidio,
     overhead,
     margem_hora,
     margem_mensal)
   VALUES
    (v_salario_cargo_id,
     p_cargo_id,
     v_nivel,
     v_custo_mensal_en,
     v_custo_hora_en,
     v_venda_mensal_en,
     v_venda_hora_en,
     v_faixa_salarial_en,
     v_beneficio_en,
     v_encargo_en,
     v_dissidio_en,
     v_overhead_en,
     v_margem_hora_en,
     v_margem_mensal_en);
  
  END LOOP;
  --
  /*
  -- atualiza data_fim de eventual registro anterior em aberto
  UPDATE salario_cargo
  SET    data_fim = v_data_ini - 1
  WHERE  cargo_id = p_cargo_id
  AND    data_fim IS NULL
  AND    data_ini < v_data_ini;
  */
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_cargo;
  /*v_compl_histor   := 'Salário incluído: ' ||
  mes_ano_mostrar(v_data_ini);*/
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARGO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
 END salario_adicionar;
 --
 --
 PROCEDURE salario_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 23/09/2016
  -- DESCRICAO: Atualização de SALARIO do CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         30/11/2023  Remoção obrigatoriedade valor de venda de acordo com
  --                               parametro
  -- Ana Luiza         12/12/2023  Adicao horas estagiario
  -----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_cargo_id           IN cargo.cargo_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_vetor_nivel        IN VARCHAR2,
  p_vetor_custo_mensal IN VARCHAR2,
  p_vetor_venda_mensal IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  /*
  v_data_ini           salario_cargo.data_ini%TYPE;
  v_data_ini_atu       salario_cargo.data_ini%TYPE;
  v_data_ini_ant       salario_cargo.data_ini%TYPE;
  */
  v_nivel              salario_cargo.nivel%TYPE;
  v_custo_mensal       salario_cargo.custo_mensal%TYPE;
  v_custo_hora         salario_cargo.custo_hora%TYPE;
  v_venda_mensal       salario_cargo.venda_mensal%TYPE;
  v_venda_hora         salario_cargo.venda_hora%TYPE;
  v_custo_mensal_en    salario_cargo.custo_mensal%TYPE;
  v_custo_hora_en      salario_cargo.custo_hora%TYPE;
  v_venda_mensal_en    salario_cargo.venda_mensal%TYPE;
  v_venda_hora_en      salario_cargo.venda_hora%TYPE;
  v_nome_cargo         cargo.nome%TYPE;
  v_qt_horas           NUMBER;
  v_delimitador        CHAR(1);
  v_vetor_nivel        VARCHAR2(1000);
  v_vetor_custo_mensal VARCHAR2(1000);
  v_vetor_venda_mensal VARCHAR2(1000);
  v_venda_mensal_char  VARCHAR2(20);
  v_custo_mensal_char  VARCHAR2(20);
  --
  v_parametro           CHAR(1);
  v_qt_horas_estagiario NUMBER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARGO_CUSTO_PRECO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  /*
  IF v_qt = 0
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
  RAISE v_exception;
  END IF;
  */
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
  IF rtrim(p_data_ini) IS NULL
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'O preenchimento da data é obrigatório.';
  RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_ini) = 0
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Data inválida(' || p_data_ini || ').';
  RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || p_data_ini);
  --
  SELECT MAX(data_ini)
  INTO   v_data_ini_atu
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id
  AND    data_fim IS NULL;
  --
  IF v_data_ini_atu IS NULL
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Salário não encontrado.';
  RAISE v_exception;
  END IF;
  --
  SELECT MAX(data_ini)
  INTO   v_data_ini_ant
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id
  AND    data_ini < v_data_ini_atu;
  --
  IF v_data_ini <= v_data_ini_ant
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'A data não pode ser anterior ou igual a datas já cadastradas.';
  RAISE v_exception;
  END IF;*/
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador        := '|';
  v_vetor_nivel        := rtrim(p_vetor_nivel);
  v_vetor_custo_mensal := rtrim(p_vetor_custo_mensal);
  v_vetor_venda_mensal := rtrim(p_vetor_venda_mensal);
  --
  WHILE nvl(length(rtrim(v_vetor_nivel)), 0) > 0
  LOOP
   --
   v_nivel             := prox_valor_retornar(v_vetor_nivel, v_delimitador);
   v_custo_mensal_char := prox_valor_retornar(v_vetor_custo_mensal, v_delimitador);
   v_venda_mensal_char := prox_valor_retornar(v_vetor_venda_mensal, v_delimitador);
   --
   IF util_pkg.desc_retornar('nivel_usuario', v_nivel) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível inválido (' || v_nivel || ').';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(v_custo_mensal_char) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_custo_mensal_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo inválido (' || v_custo_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_301123
   v_parametro := empresa_pkg.parametro_retornar(p_empresa_id, 'COMP_CUSTO_PRECO_CARGO');
   --
   IF v_parametro = 'S'
   THEN
    IF rtrim(v_venda_mensal_char) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do valor de venda é obrigatório.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_venda_mensal_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de venda inválido (' || v_venda_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_mensal := nvl(moeda_converter(v_custo_mensal_char), 0);
   v_venda_mensal := nvl(moeda_converter(v_venda_mensal_char), 0);
   --
   --ALCBO_121223
   v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id, 'QT_HORAS_MENSAIS'));
   IF v_nivel = 'E'
   THEN
    --ALCBO_121223
    v_qt_horas_estagiario := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                             'QT_HORAS_MENSAIS_ESTAG'));
    v_qt_horas            := v_qt_horas_estagiario;
   END IF;
   --
   v_custo_hora := round(v_custo_mensal / v_qt_horas, 2);
   v_venda_hora := round(v_venda_mensal / v_qt_horas, 2);
   --
   -- encripta para salvar
   v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
   --
   IF v_custo_mensal_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
   --
   IF v_venda_mensal_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
   --
   IF v_custo_hora_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
   --
   IF v_venda_hora_en = -99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE salario_cargo
      SET --data_ini     = v_data_ini,
          --data_fim     = NULL,
           custo_mensal = v_custo_mensal_en,
          custo_hora   = v_custo_hora_en,
          venda_mensal = v_venda_mensal_en,
          venda_hora   = v_venda_hora_en
    WHERE cargo_id = p_cargo_id
         --AND    data_ini = v_data_ini_atu
         --AND    data_fim IS NULL
      AND nivel = v_nivel;
   --
  /*
                                                                                             IF v_data_ini_ant IS NOT NULL
                                                                                             THEN
                                                                                               -- ajusta data_fim do periodo anterior
                                                                                               UPDATE salario_cargo
                                                                                               SET    data_fim = v_data_ini - 1
                                                                                               WHERE  cargo_id = p_cargo_id
                                                                                               AND    data_ini = v_data_ini_ant
                                                                                               AND    nivel = v_nivel;
                                                                                             END IF;
                                                                                             */
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome_cargo;
  /*v_compl_histor   := 'Salário alterado: ' ||
  mes_ano_mostrar(v_data_ini);*/
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARGO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_erro_cod <> '00000'
  THEN
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
 END salario_atualizar;
 --
 --
 PROCEDURE salario_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                    ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: Exclusão de SALARIO do CARGO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome_cargo     cargo.nome%TYPE;
  /*
  v_data_ini     salario_cargo.data_ini%TYPE;
  v_data_ini_atu salario_cargo.data_ini%TYPE;
  v_data_ini_ant salario_cargo.data_ini%TYPE;
  */
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARGO_CUSTO_PRECO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  /*
  IF rtrim(p_data_ini) IS NULL
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'O preenchimento da data é obrigatório.';
  RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_ini) = 0
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Data inválida(' || p_data_ini || ').';
  RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || p_data_ini);
  --
  SELECT MAX(data_ini)
  INTO   v_data_ini_atu
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id
  AND    data_fim IS NULL;
  --
  IF v_data_ini_atu IS NULL
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Salário não encontrado.';
  RAISE v_exception;
  END IF;
  --
  IF v_data_ini_atu <> v_data_ini
  THEN
  p_erro_cod := '90000';
  p_erro_msg := 'Apenas o salário mais recente pode ser alterado.';
  RAISE v_exception;
  END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM salario_cargo
   WHERE cargo_id = p_cargo_id;
  --AND    data_ini = v_data_ini
  --AND    data_fim IS NULL;
  --
  -- procura pelo salario anterior do cargo
  /*
  SELECT MAX(data_ini)
  INTO   v_data_ini_ant
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id;
  --
  IF v_data_ini_ant IS NOT NULL
  THEN
  -- reabre o salario (torna vigente)
  UPDATE salario_cargo
  SET    data_fim = NULL
  WHERE  cargo_id = p_cargo_id
  AND    data_ini = v_data_ini_ant;
  END IF;
  */
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  /*
  v_identif_objeto := v_nome_cargo;
  v_compl_histor   := 'Salário excluído: ' ||
                  mes_ano_mostrar(v_data_ini);
                  */
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CARGO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cargo_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   NULL,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
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
 END salario_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/04/2017
  -- DESCRICAO: Subrotina que gera o xml do cargo para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/05/2017  Inclusao de area no cargo
  ------------------------------------------------------------------------------------------
 (
  p_cargo_id IN cargo.cargo_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  v_xml_cargo     xmltype;
  v_xml_tab_preco xmltype;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("cargo_id", ca.cargo_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", ca.nome),
                   xmlelement("area", ar.nome),
                   xmlelement("ordem", ca.ordem),
                   xmlelement("qtd_vagas_aprov", ca.qtd_vagas_aprov),
                   xmlelement("aloca_usuario_contrato", ca.flag_aloc_usu_ctr),
                   xmlelement("ativo", ca.flag_ativo))
    INTO v_xml_cargo
    FROM cargo ca
   INNER JOIN area ar
      ON ca.area_id = ar.area_id
   WHERE ca.cargo_id = p_cargo_id;
  --------------------------------------------------------------
  --Composicao rate_card
  --------------------------------------------------------------
  SELECT xmlagg(xmlelement("rate_card",
                           xmlelement("usu_ult_alt", sub.apelido),
                           xmlelement("data_ult_alt", data_hora_mostrar(sub.data_ult_alt)),
                           xmlelement("nome", sub.nome)))
    INTO v_xml_tab_preco
    FROM (SELECT DISTINCT ca.cargo_id,
                          pr.nome,
                          pe.apelido,
                          pr.data_ult_alt
            FROM cargo ca
           INNER JOIN area ar
              ON ca.area_id = ar.area_id
            LEFT JOIN salario_cargo sc
              ON ca.cargo_id = sc.cargo_id
            LEFT JOIN tab_preco pr
              ON sc.preco_id = pr.preco_id
            LEFT JOIN pessoa pe
              ON pr.usu_alt_id = pe.usuario_id
           WHERE ca.cargo_id = p_cargo_id) sub;
  ------------------------------------------------------------
  -- junta tudo debaixo de "cargo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("cargo", v_xml_cargo, v_xml_tab_preco))
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
 FUNCTION salario_id_atu_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 23/09/2016
  -- DESCRICAO: retorna o ID do salario atual do cargo/nivel, baseado na data do sistema.
  --  Se nao encontrar salario definido, retorna NULL. Em caso de erro, retorna zero.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         29/08/2024  Alterado para trazer salario de acordo com
  --                               rate card padrao (tab_preco)
  ------------------------------------------------------------------------------------------
  p_cargo_id IN cargo.cargo_id%TYPE,
  p_nivel    IN salario_cargo.nivel%TYPE
 ) RETURN INTEGER AS
 
  v_qt               INTEGER;
  v_salario_cargo_id salario_cargo.salario_cargo_id%TYPE;
  --v_data_ini         salario_cargo.data_ini%TYPE;
  --ALCBO_290824
  v_tab_preco_padrao tab_preco.preco_id%TYPE;
  v_empresa_id       empresa.empresa_id%TYPE;
  --
 BEGIN
  v_salario_cargo_id := NULL;
  --
  /*
  SELECT MAX(data_ini)
  INTO   v_data_ini
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id
  AND    data_ini <= trunc(SYSDATE)
  AND    nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');
  --
  IF v_data_ini IS NOT NULL THEN
  SELECT salario_cargo_id
  INTO   v_salario_cargo_id
  FROM   salario_cargo
  WHERE  cargo_id = p_cargo_id
  AND    data_ini = v_data_ini
  AND    nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');
  END IF;
  */
  --ALCBO_290824
  --Seleciona empresa do cargo
  SELECT empresa_id
    INTO v_empresa_id
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  SELECT preco_id
    INTO v_tab_preco_padrao
    FROM tab_preco
   WHERE flag_padrao_atual = 'S'
     AND empresa_id = v_empresa_id;
  --
  SELECT salario_cargo_id
    INTO v_salario_cargo_id
    FROM salario_cargo
   WHERE cargo_id = p_cargo_id
     AND preco_id = v_tab_preco_padrao
     AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');
  --
  RETURN v_salario_cargo_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_salario_cargo_id := 0;
   RETURN v_salario_cargo_id;
 END salario_id_atu_retornar;
 --
 --
 FUNCTION do_usuario_retornar
 (
  ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/08/2017
  -- DESCRICAO: retorna o ID do cargo do usuario na data especificada e na empresa padrao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         13/12/2024  Adicionado parametro de empresa_id para também 
  --                               ser utilizada em empresa não padrao
  -- Ana Luiza         16/05/2025  Modificação para retornar empresa_id mesmo que não padrão
  ----------------------------------------------------------------------------------------
  p_usuario_id IN NUMBER,
  p_data       IN DATE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN INTEGER AS
  v_qt       INTEGER;
  v_cargo_id cargo.cargo_id%TYPE;
  --
 BEGIN
  v_cargo_id := NULL;
  --
  IF p_empresa_id IS NULL
  THEN
   --ALCBO_131224
   SELECT MAX(uc.cargo_id)
     INTO v_cargo_id
     FROM usuario_cargo   uc,
          cargo           ca,
          usuario_empresa ue
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND uc.usuario_id = ue.usuario_id
      AND ue.flag_padrao = 'S'
      AND ue.empresa_id = ca.empresa_id
      AND trunc(p_data) BETWEEN uc.data_ini AND nvl(uc.data_fim, data_converter('31/12/5000'));
  ELSE
   --ALCBO_160525
   SELECT MAX(uc.cargo_id)
     INTO v_cargo_id
     FROM usuario_cargo   uc,
          cargo           ca,
          usuario_empresa ue
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND uc.usuario_id = ue.usuario_id
      AND ue.empresa_id = ca.empresa_id
         --AND trunc(p_data) BETWEEN uc.data_ini 
         --AND nvl(uc.data_fim, data_converter('31/12/5000'))
      AND ue.empresa_id = p_empresa_id;
   /*
   --ALCBO_131224
   SELECT MAX(uc.cargo_id)
     INTO v_cargo_id
     FROM usuario_cargo   uc,
          cargo           ca,
          usuario_empresa ue
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND uc.usuario_id = ue.usuario_id
      AND ue.empresa_id = ca.empresa_id
      AND trunc(p_data) BETWEEN uc.data_ini AND nvl(uc.data_fim, data_converter('31/12/5000'))
      AND ue.empresa_id = p_empresa_id;
      */
  END IF;
  --
  RETURN v_cargo_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_cargo_id := 0;
   RETURN v_cargo_id;
 END do_usuario_retornar;
 --
 --
 FUNCTION nivel_usuario_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/08/2017
  -- DESCRICAO: retorna o nivel do cargo do usuario na data especificada e na empresa padrao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         13/12/2024  Adicionado parametro de empresa_id para também 
  --                               ser utilizada em empresa não padrao
  ------------------------------------------------------------------------------------------
  p_usuario_id IN NUMBER,
  p_data       IN DATE,
  p_empresa_id IN empresa.empresa_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt    INTEGER;
  v_nivel usuario_cargo.nivel%TYPE;
  --
 BEGIN
  v_nivel := NULL;
  --ALCBO_131224
  IF p_empresa_id IS NULL
  THEN
   SELECT MAX(uc.nivel)
     INTO v_nivel
     FROM usuario_cargo   uc,
          cargo           ca,
          usuario_empresa ue
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND uc.usuario_id = ue.usuario_id
      AND ue.flag_padrao = 'S'
      AND ue.empresa_id = ca.empresa_id
      AND trunc(p_data) BETWEEN uc.data_ini AND nvl(uc.data_fim, data_converter('31/12/5000'));
  ELSE
   --ALCBO_131224
   SELECT MAX(uc.nivel)
     INTO v_nivel
     FROM usuario_cargo   uc,
          cargo           ca,
          usuario_empresa ue
    WHERE uc.usuario_id = p_usuario_id
      AND uc.cargo_id = ca.cargo_id
      AND uc.usuario_id = ue.usuario_id
      AND ue.empresa_id = ca.empresa_id
      AND trunc(p_data) BETWEEN uc.data_ini AND nvl(uc.data_fim, data_converter('31/12/5000'))
      AND ue.empresa_id = p_empresa_id;
  END IF;
  --
  RETURN v_nivel;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_nivel := 'X';
   RETURN v_nivel;
 END nivel_usuario_retornar;
 --
END; -- CARGO_PKG

/
