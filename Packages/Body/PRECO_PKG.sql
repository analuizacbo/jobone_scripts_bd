--------------------------------------------------------
--  DDL for Package Body PRECO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PRECO_PKG" IS
 --
 PROCEDURE tab_preco_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 29/05/2023
  -- DESCRICAO: Inclusão de tabala de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cliente_id           IN tab_preco.cliente_id%TYPE,
  p_grupo_id             IN tab_preco.grupo_id%TYPE,
  p_nome                 IN tab_preco.nome%TYPE,
  p_tabela_preco_base_id IN tab_preco.tabela_preco_base_id%TYPE,
  p_data_referencia      IN VARCHAR2,
  p_data_validade        IN VARCHAR2,
  p_flag_padrao          IN tab_preco.flag_padrao%TYPE,
  p_perc_acres_cargo     IN VARCHAR2,
  p_perc_acres_tipo_prod IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_preco_id             tab_preco.preco_id%TYPE;
  v_perc_acres_cargo     tab_preco.perc_acres_cargo%TYPE;
  v_perc_acres_tipo_prod tab_preco.perc_acres_tipo_prod%TYPE;
  v_data_ini             tab_preco.data_ini%TYPE;
  v_data_fim             tab_preco.data_fim%TYPE;
  v_usu_cria_id          tab_preco.usu_cria_id%TYPE;
  v_data_criacao         tab_preco.data_criacao%TYPE;
  v_usu_alt_id           tab_preco.usu_alt_id%TYPE;
  v_data_ult_alt         tab_preco.data_ult_alt%TYPE;
  v_data_validade        tab_preco.data_validade%TYPE;
  v_data_referencia      tab_preco.data_referencia%TYPE;
  v_flag_padrao_atual    tab_preco.flag_padrao_atual%TYPE;
  --
  v_padrao_atual_ant tab_preco.preco_id%TYPE;
  v_tab_base_padrao  tab_preco.tabela_preco_base_id%TYPE;
  v_tab_base         tab_preco.tabela_preco_base_id%TYPE;
  v_tab_base_ok      tab_preco.tabela_preco_base_id%TYPE;
  --
  v_salario_cargo_id      salario_cargo.salario_cargo_id%TYPE;
  v_tipo_produto_preco_id tipo_produto_preco.tipo_produto_preco_id%TYPE;
  --
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TAB_PRECO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  IF rtrim(p_data_referencia) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de referência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_referencia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida(' || p_data_referencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_validade) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida(' || p_data_validade || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_acres_cargo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de acréscimo de cargo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_acres_tipo_prod) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de acréscimo de Tipo Entregável inválido.';
   RAISE v_exception;
  END IF;
  --
  v_perc_acres_cargo     := numero_converter(p_perc_acres_cargo);
  v_perc_acres_tipo_prod := numero_converter(p_perc_acres_tipo_prod);
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de tabela já existe.';
   RAISE v_exception;
  END IF;
  --
  --
  IF p_tabela_preco_base_id IS NOT NULL THEN
   --
   SELECT COUNT(*)
     INTO v_tab_base_ok
     FROM tab_preco
    WHERE preco_id = p_tabela_preco_base_id
      AND empresa_id = p_empresa_id;
   --
   IF v_tab_base_ok = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Rate card de base inválido ou não pertence à empresa.';
    RAISE v_exception;
   END IF;
   --
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  v_data_ini        := SYSDATE;
  v_data_referencia := data_converter('01' || p_data_referencia);
  v_data_validade   := data_converter(p_data_validade);
  v_data_fim        := v_data_validade;
  v_usu_cria_id     := p_usuario_sessao_id;
  v_data_criacao    := v_data_ini;
  v_usu_alt_id      := p_usuario_sessao_id;
  v_data_ult_alt    := SYSDATE;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tab_preco.nextval
    INTO v_preco_id
    FROM dual;
  --
  SELECT preco_id
    INTO v_padrao_atual_ant
    FROM tab_preco
   WHERE empresa_id = p_empresa_id
     AND flag_padrao_atual = 'S';
  --
  --
  IF p_flag_padrao <> 'S' THEN
   v_flag_padrao_atual := 'N';
   --
   SELECT COUNT(*)
     INTO v_tab_base_ok
     FROM tab_preco
    WHERE preco_id = p_tabela_preco_base_id
      AND empresa_id = p_empresa_id;
   --
   IF p_tabela_preco_base_id IS NOT NULL THEN
    --
    SELECT preco_id
      INTO v_tab_base
      FROM tab_preco
     WHERE preco_id = p_tabela_preco_base_id
       AND empresa_id = p_empresa_id;
   END IF;
  END IF;
  --
  IF p_flag_padrao = 'S' THEN
   --
   --PRIMEIRA CRIACAO TAB_PRECO
   SELECT COUNT(*)
     INTO v_qt
     FROM tab_preco
    WHERE empresa_id = p_empresa_id
      AND flag_padrao_atual = 'S';
   --
   --verifica se base padrao é valida
   SELECT COUNT(*)
     INTO v_tab_base_padrao
     FROM tab_preco
    WHERE preco_id = p_tabela_preco_base_id
      AND flag_padrao = 'S'
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    v_flag_padrao_atual := 'S';
   ELSE
    IF v_padrao_atual_ant <> 0 THEN
     v_flag_padrao_atual := 'S';
    ELSE
     p_erro_cod := '90000';
     p_erro_msg := 'Rate Card padrão não definido para essa empresa.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tab_preco
     WHERE preco_id = p_tabela_preco_base_id
       AND flag_padrao_atual = 'S'
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Rate Card padrão só pode utilizar o
                        último padrão como base.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  --
  INSERT INTO tab_preco
   (preco_id,
    cliente_id,
    grupo_id,
    empresa_id,
    nome,
    tabela_preco_base_id,
    data_referencia,
    data_ini,
    data_fim,
    data_validade,
    flag_padrao_atual,
    flag_padrao,
    flag_pode_precif,
    flag_pode_ganhar,
    flag_arquivada,
    perc_acres_cargo,
    perc_acres_tipo_prod,
    usu_cria_id,
    data_criacao,
    usu_alt_id,
    data_ult_alt)
  VALUES
   (v_preco_id,
    p_cliente_id,
    p_grupo_id,
    p_empresa_id,
    TRIM(p_nome),
    p_tabela_preco_base_id,
    v_data_referencia,
    v_data_ini,
    v_data_fim,
    v_data_validade,
    v_flag_padrao_atual,
    p_flag_padrao,
    'N',
    'N',
    'N',
    nvl(v_perc_acres_cargo, 0),
    nvl(v_perc_acres_tipo_prod, 0),
    v_usu_cria_id,
    v_data_criacao,
    v_usu_alt_id,
    v_data_ult_alt);
  --
  --
  IF v_tab_base_padrao > 0 THEN
   --insere todos salarios da padrao anterior na tab_padrao nova
   FOR aux1 IN (SELECT DISTINCT (cargo_id)
                  FROM salario_cargo
                 WHERE preco_id = v_padrao_atual_ant)
   LOOP
    salario_cargo_associar(p_usuario_sessao_id,
                           p_empresa_id,
                           v_preco_id,
                           aux1.cargo_id,
                           'N',
                           p_erro_cod,
                           p_erro_msg);
   END LOOP;
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   --insere todos tipo produto da padrao anterior na tab_padrao nova
   FOR aux2 IN (SELECT DISTINCT (tipo_produto_id)
                  FROM tipo_produto_preco
                 WHERE preco_id = v_padrao_atual_ant)
   LOOP
    tipo_produto_preco_associar(p_usuario_sessao_id,
                                p_empresa_id,
                                v_preco_id,
                                aux2.tipo_produto_id,
                                'N',
                                p_erro_cod,
                                p_erro_msg);
   END LOOP;
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_tab_base_ok > 0 THEN
   --
   IF p_tabela_preco_base_id <> 0 THEN
    FOR aux3 IN (SELECT salario_cargo_id,
                        cargo_id,
                        preco_id,
                        nome_alternativo,
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
                        margem_mensal
                   FROM salario_cargo
                  WHERE preco_id = v_tab_base)
    LOOP
     SELECT seq_salario_cargo.nextval
       INTO v_salario_cargo_id
       FROM dual;
     --
     --
     INSERT INTO salario_cargo
      (salario_cargo_id,
       cargo_id,
       preco_id,
       nome_alternativo,
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
       aux3.cargo_id,
       v_preco_id,
       aux3.nome_alternativo,
       aux3.nivel,
       nvl(aux3.custo_mensal, 0),
       nvl(aux3.custo_hora, 0),
       nvl(aux3.venda_mensal, 0),
       nvl(aux3.venda_hora, 0),
       nvl(aux3.faixa_salarial, 0),
       nvl(aux3.beneficio, 0),
       nvl(aux3.encargo, 0),
       nvl(aux3.dissidio, 0),
       nvl(aux3.overhead, 0),
       nvl(aux3.margem_hora, 0),
       nvl(aux3.margem_mensal, 0));
    END LOOP;
    --
    --insere todos tipo produto da padrao anterior na tab_padrao nova
    --
    FOR aux4 IN (SELECT tipo_produto_preco_id,
                        tipo_produto_id,
                        preco_id,
                        preco,
                        custo
                   FROM tipo_produto_preco
                  WHERE preco_id = v_tab_base)
    LOOP
     SELECT seq_tipo_produto_preco.nextval
       INTO v_tipo_produto_preco_id
       FROM dual;
     --
     --
     INSERT INTO tipo_produto_preco
      (tipo_produto_preco_id,
       tipo_produto_id,
       preco_id,
       preco,
       custo)
     VALUES
      (v_tipo_produto_preco_id,
       aux4.tipo_produto_id,
       v_preco_id,
       nvl(aux4.preco, 0),
       nvl(aux4.custo, 0));
    END LOOP;
   END IF;
  END IF;
  --
  --
  IF p_flag_padrao = 'S' THEN
   IF v_padrao_atual_ant <> 0 THEN
    --Altera flag padrao atual
    UPDATE tab_preco
       SET flag_padrao_atual = 'N'
     WHERE preco_id = v_padrao_atual_ant;
    --
    /*
    tab_preco_acao_arquivo(p_usuario_sessao_id,
                           p_empresa_id,
                           v_padrao_atual_ant,
                           'ARQUIVAR',
                           'N',
                           p_erro_cod,
                           p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    */
   END IF;
  END IF;
  preco_pkg.tab_preco_percent_aplicar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      v_preco_id,
                                      p_perc_acres_cargo,
                                      p_perc_acres_tipo_prod,
                                      'N',
                                      p_erro_cod,
                                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  preco_pkg.xml_gerar(v_preco_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TAB_PRECO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_preco_id,
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
 END tab_preco_adicionar;
 --
 PROCEDURE tab_preco_alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 29/05/2023
  -- DESCRICAO: Alteração de tabela de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -----------------  ----------  ---------------------------------------------------------
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cliente_id        IN tab_preco.cliente_id%TYPE,
  p_grupo_id          IN tab_preco.grupo_id%TYPE,
  p_nome              IN tab_preco.nome%TYPE,
  p_data_referencia   IN VARCHAR2,
  p_data_validade     IN VARCHAR2,
  p_flag_pode_precif  IN tab_preco.flag_pode_precif%TYPE,
  p_flag_pode_ganhar  IN tab_preco.flag_pode_ganhar%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_usu_alt_id      tab_preco.usu_alt_id%TYPE;
  v_data_ult_alt    tab_preco.data_ult_alt%TYPE;
  v_data_validade   tab_preco.data_validade%TYPE;
  v_data_referencia tab_preco.data_referencia%TYPE;
  v_nome_ant        tab_preco.nome%TYPE;
  --
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  v_xml_atual CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TAB_PRECO_C', NULL, NULL, p_empresa_id) <> 1 THEN
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
  IF rtrim(p_nome) IS NOT NULL THEN
   SELECT nome
     INTO v_nome_ant
     FROM tab_preco
    WHERE preco_id = p_preco_id;
   --
   IF v_nome_ant <> rtrim(p_nome) THEN
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tab_preco
     WHERE TRIM(upper(rtrim(nome))) = TRIM(upper(rtrim(p_nome)));
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse nome de tabela já existe.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF rtrim(p_data_referencia) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de referência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_data_referencia) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida(' || p_data_referencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_validade) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida(' || p_data_validade || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_precif) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode precificar inválida.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_ganhar) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode ganhar inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  v_data_referencia := data_converter('01' || p_data_referencia);
  v_data_validade   := data_converter(p_data_validade);
  v_usu_alt_id      := p_usuario_sessao_id;
  v_data_ult_alt    := SYSDATE;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE tab_preco
     SET cliente_id       = p_cliente_id,
         grupo_id         = p_grupo_id,
         nome             = TRIM(p_nome),
         data_referencia  = v_data_referencia,
         data_validade    = v_data_validade,
         flag_pode_precif = p_flag_pode_precif,
         flag_pode_ganhar = p_flag_pode_ganhar,
         usu_alt_id       = v_usu_alt_id,
         data_ult_alt     = v_data_ult_alt
   WHERE preco_id = p_preco_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  preco_pkg.xml_gerar(p_preco_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                   'TAB_PRECO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_preco_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   NULL,
                   v_xml_atual,
                   v_historico_id,
                   p_erro_cod,
                   p_erro_msg);
  --
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
 END tab_preco_alterar;
 --
 PROCEDURE tab_preco_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 01/06/2023
  -- DESCRICAO: Exclusão de tabela de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza     23/08/2023      Adicionado validacao para não excluir ratecards em
  --                               precificacao
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  --
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  --
  v_nome tab_preco.nome%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TAB_PRECO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  --**********************ATENCAO*************
  --Fazer verificações ver se existe de vinculo com cargos ou produtos antes de excluir
  --Verifica se a tab de preco esta associada algum salario de cargo
  ----------------------------------------------
  --VALIDACAO DE TABELAS QUE USAM PRECIFICACAO
  ---------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE preco_id = p_preco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card está vinculado a Cenários.';
   RAISE v_exception;
  END IF;
  /*
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_horas
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE preco_id = p_preco_id
                                   AND oportunidade_id IN
                                       (SELECT oportunidade_id
                                          FROM oportunidade
                                         WHERE empresa_id = p_empresa_id)));
  --
  IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Este Rate Card está sendo usado para precificação de Cargo(s) em Cenários';
    RAISE v_exception;
  END IF;
  --
  --Verifica se a tab de preco esta associada algum tipo produto
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_item
   WHERE cenario_servico_id IN
         (SELECT cenario_servico_id
            FROM cenario_servico
           WHERE cenario_id IN (SELECT cenario_id
                                  FROM cenario
                                 WHERE preco_id = p_preco_id
                                   AND oportunidade_id IN
                                       (SELECT oportunidade_id
                                          FROM oportunidade
                                         WHERE empresa_id = p_empresa_id)));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Este Rate Card está sendo usado para precificação de Item(ns) em Cenários';
   RAISE v_exception;
  END IF;*/
  --
  --Verifica se a tab de preco é padrão
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE flag_padrao = 'S'
     AND preco_id = p_preco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tabela já foi utilizada como Default.';
   RAISE v_exception;
  END IF;
  --Verifica se a tab de preco já foi utilizada como base para outra
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE tabela_preco_base_id = p_preco_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tabela já foi utilizada como base para outra tabela.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tabela já foi utilizada como base para outra tabela.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM tab_preco
   WHERE preco_id = p_preco_id;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  preco_pkg.xml_gerar(p_preco_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM salario_cargo
   WHERE preco_id IN (SELECT preco_id
                        FROM tab_preco
                       WHERE preco_id = p_preco_id
                         AND empresa_id = p_empresa_id);
  --
  DELETE FROM tipo_produto_preco
   WHERE preco_id IN (SELECT preco_id
                        FROM tab_preco
                       WHERE preco_id = p_preco_id
                         AND empresa_id = p_empresa_id);
  --
  DELETE FROM tab_preco
   WHERE preco_id = p_preco_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_PRECO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_preco_id,
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
 END; -- excluir
 --
 PROCEDURE tab_preco_acao_arquivo
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 02/06/2023
  -- DESCRICAO: Arquiva e desarquiva tabelas de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_acao              IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_flag_arquivada tab_preco.flag_arquivada%TYPE;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  /*
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARGO_C',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1
  THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
  END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_preco_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preco_id é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_acao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF upper(TRIM(p_acao)) = 'ARQUIVAR' THEN
   v_flag_arquivada := 'S';
  END IF;
  --
  IF upper(TRIM(p_acao)) = 'DESARQUIVAR' THEN
   v_flag_arquivada := 'N';
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  --Verifica se tabela é padrão
  UPDATE tab_preco
     SET flag_arquivada = v_flag_arquivada
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
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
 END;
 --
 PROCEDURE salario_cargo_vincular
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 31/05/2023
  -- DESCRICAO: Vinculo de tabela de preco e salario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- Ana Luiza         01/11/2023  Ajuste do custo hora
  -- Ana Luiza         30/11/2023  Remoção obrigatoriedade valor de venda de acordo com --
  --                               parametro
  -- Ana Luiza         12/12/2023  Adicao horas estagiario
  -- Ana Luiza         25/03/2024  Ajuste para nao dar erro de divisor = 0
  -- Ana Luiza         28/08/2024  Ajuste calculo, evitar 99999
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_vetor_preco_id       IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_salario_cargo_id salario_cargo.salario_cargo_id%TYPE;
  v_nivel            salario_cargo.nivel%TYPE;
  --v_data_ini_ant       salario_cargo.data_ini%TYPE;
  --
  v_faixa_salarial salario_cargo.faixa_salarial%TYPE;
  v_beneficio      salario_cargo.beneficio%TYPE;
  v_encargo        salario_cargo.encargo%TYPE;
  v_dissidio       salario_cargo.dissidio%TYPE;
  v_overhead       salario_cargo.overhead%TYPE;
  v_custo_hora     salario_cargo.custo_hora%TYPE;
  v_custo_mensal   salario_cargo.custo_mensal%TYPE;
  v_venda_hora     salario_cargo.venda_hora%TYPE;
  v_venda_mensal   salario_cargo.venda_mensal%TYPE;
  v_margem_hora    salario_cargo.margem_hora%TYPE;
  v_margem_mensal  salario_cargo.margem_mensal%TYPE;
  --
  v_nome_cargo cargo.nome%TYPE;
  --
  v_faixa_salarial_en salario_cargo.faixa_salarial%TYPE;
  v_beneficio_en      salario_cargo.beneficio%TYPE;
  v_encargo_en        salario_cargo.encargo%TYPE;
  v_dissidio_en       salario_cargo.dissidio%TYPE;
  v_overhead_en       salario_cargo.overhead%TYPE;
  v_custo_hora_en     salario_cargo.custo_hora%TYPE;
  v_custo_mensal_en   salario_cargo.custo_mensal%TYPE;
  v_venda_hora_en     salario_cargo.venda_hora%TYPE;
  v_venda_mensal_en   salario_cargo.venda_mensal%TYPE;
  v_margem_hora_en    salario_cargo.margem_hora%TYPE;
  --
  --
  v_vetor_faixa_salarial VARCHAR2(1000);
  v_vetor_beneficio      VARCHAR2(1000);
  v_vetor_encargo        VARCHAR2(1000);
  v_vetor_dissidio       VARCHAR2(1000);
  v_vetor_overhead       VARCHAR2(1000);
  v_vetor_custo_hora     VARCHAR2(1000);
  v_vetor_custo_mensal   VARCHAR2(1000);
  v_vetor_venda_mensal   VARCHAR2(1000);
  v_vetor_margem_hora    VARCHAR2(1000);
  --
  v_vetor_preco_id VARCHAR2(1000);
  --
  v_qt_horas    NUMBER;
  v_delimitador CHAR(1);
  v_vetor_nivel VARCHAR2(1000);
  --
  v_preco_id_char VARCHAR2(20);
  --
  v_faixa_salarial_char VARCHAR2(20);
  v_beneficio_char      VARCHAR2(20);
  v_encargo_char        VARCHAR2(20);
  v_dissidio_char       VARCHAR2(20);
  v_overhead_char       VARCHAR2(20);
  v_custo_hora_char     VARCHAR2(20);
  v_custo_mensal_char   VARCHAR2(20);
  v_venda_mensal_char   VARCHAR2(20);
  v_margem_hora_char    VARCHAR2(20);
  --
  v_parametro           CHAR(1);
  v_qt_horas_estagiario NUMBER;
 BEGIN
  v_qt := 0;
  --
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  /*
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'CARGO_CUSTO_PRECO_C',
                                NULL,
                                NULL,
                                p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
  END IF;
  */
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Cargo inválido ou não pertence à empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  /*
   IF 1 = 1 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'AQUI ' || p_vetor_custo_mensal;
      RAISE v_exception;
  END IF;
  */
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador          := '|';
  v_vetor_nivel          := rtrim(p_vetor_nivel);
  v_vetor_faixa_salarial := rtrim(p_vetor_faixa_salarial);
  v_vetor_beneficio      := rtrim(p_vetor_beneficio);
  v_vetor_encargo        := rtrim(p_vetor_encargo);
  v_vetor_dissidio       := rtrim(p_vetor_dissidio);
  v_vetor_overhead       := rtrim(p_vetor_overhead);
  v_vetor_custo_hora     := rtrim(p_vetor_custo_hora);
  v_vetor_custo_mensal   := rtrim(p_vetor_custo_mensal);
  v_vetor_venda_mensal   := rtrim(p_vetor_venda_mensal);
  v_vetor_margem_hora    := rtrim(p_vetor_margem_hora);
  v_vetor_preco_id       := rtrim(p_vetor_preco_id);
  --
  --
  WHILE nvl(length(rtrim(v_vetor_preco_id)), 0) > 0
  LOOP
   --
   v_preco_id_char := prox_valor_retornar(v_vetor_preco_id, v_delimitador);
   --
   v_vetor_nivel          := rtrim(p_vetor_nivel);
   v_vetor_faixa_salarial := rtrim(p_vetor_faixa_salarial);
   v_vetor_beneficio      := rtrim(p_vetor_beneficio);
   v_vetor_encargo        := rtrim(p_vetor_encargo);
   v_vetor_dissidio       := rtrim(p_vetor_dissidio);
   v_vetor_overhead       := rtrim(p_vetor_overhead);
   v_vetor_custo_hora     := rtrim(p_vetor_custo_hora);
   v_vetor_custo_mensal   := rtrim(p_vetor_custo_mensal);
   v_vetor_venda_mensal   := rtrim(p_vetor_venda_mensal);
   v_vetor_margem_hora    := rtrim(p_vetor_margem_hora);
   --
   WHILE nvl(length(rtrim(v_vetor_nivel)), 0) > 0
   LOOP
    v_nivel := prox_valor_retornar(v_vetor_nivel, v_delimitador);
    --
    v_faixa_salarial_char := prox_valor_retornar(v_vetor_faixa_salarial, v_delimitador);
    --
    v_beneficio_char := prox_valor_retornar(v_vetor_beneficio, v_delimitador);
    --
    v_encargo_char  := prox_valor_retornar(v_vetor_encargo, v_delimitador);
    v_dissidio_char := prox_valor_retornar(v_vetor_dissidio, v_delimitador);
    --
    v_overhead_char := prox_valor_retornar(v_vetor_overhead, v_delimitador);
    --
    v_custo_hora_char := prox_valor_retornar(v_vetor_custo_hora, v_delimitador);
    --
    v_custo_mensal_char := prox_valor_retornar(v_vetor_custo_mensal, v_delimitador);
    --
    v_venda_mensal_char := prox_valor_retornar(v_vetor_venda_mensal, v_delimitador);
    --
    v_margem_hora_char := prox_valor_retornar(v_vetor_margem_hora, v_delimitador);
    --
    ------------------------------------------------------------
    -- consistencia vetores
    ------------------------------------------------------------
    IF util_pkg.desc_retornar('nivel_usuario', v_nivel) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Nível inválido (' || v_nivel || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF moeda_validar(v_faixa_salarial_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de faixa salarial inválido (' || v_faixa_salarial_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF moeda_validar(v_beneficio_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de benefício inválido (' || v_beneficio_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF moeda_validar(v_encargo_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de encargo inválido (' || v_encargo_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF moeda_validar(v_dissidio_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de dissídio inválido (' || v_dissidio_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF moeda_validar(v_overhead_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de overhead inválido (' || v_overhead_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF rtrim(v_custo_hora_char) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do custo hora é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_custo_hora_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Custo hora inválido (' || v_custo_hora_char || ').';
     RAISE v_exception;
    END IF;
    --
    --
    IF rtrim(v_custo_mensal_char) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do custo mensal é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_custo_mensal_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Custo mensal inválido (' || v_custo_mensal_char || ').';
     RAISE v_exception;
    END IF;
    --ALCBO_301123
    v_parametro := empresa_pkg.parametro_retornar(p_empresa_id, 'COMP_CUSTO_PRECO_CARGO');
    --
    IF v_parametro = 'S' THEN
     IF rtrim(v_venda_mensal_char) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento do valor de venda é obrigatório.';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF moeda_validar(v_venda_mensal_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de venda inválido (' || v_venda_mensal_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_margem_hora_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor de margem hora inválido (' || v_margem_hora_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_preco_id_char IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preço precisa ser vinculado à uma rate card';
     RAISE v_exception;
    END IF;
    --ALCBO_121223
    v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id, 'QT_HORAS_MENSAIS'));
    IF v_nivel = 'E' THEN
     --ALCBO_121223
     v_qt_horas_estagiario := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                              'QT_HORAS_MENSAIS_ESTAG'));
     v_qt_horas            := v_qt_horas_estagiario;
    END IF;
    --ALCBO_270623
    v_faixa_salarial := nvl(numero_converter(v_faixa_salarial_char), 0);
    v_beneficio      := nvl(numero_converter(v_beneficio_char), 0);
    v_encargo        := nvl(numero_converter(v_encargo_char), 0);
    v_dissidio       := nvl(numero_converter(v_dissidio_char), 0);
    v_overhead       := nvl(numero_converter(v_overhead_char), 0);
    v_custo_hora     := nvl(numero_converter(v_custo_hora_char), 0);
    v_custo_mensal   := nvl(numero_converter(v_custo_mensal_char), 0);
    v_venda_mensal   := nvl(numero_converter(v_venda_mensal_char), 0);
    --ALCBO_250324
    IF v_qt_horas = 0 THEN
     v_venda_hora := 0;
     v_custo_hora := 0;
    ELSE
     --ALCBO_280827
     v_venda_hora := (v_venda_mensal / v_qt_horas);
     v_custo_hora := v_custo_mensal / v_qt_horas;
    END IF;
    v_margem_hora   := nvl(numero_converter(v_margem_hora_char), 0);
    v_margem_mensal := nvl(numero_converter(v_venda_mensal - v_custo_mensal), 0);
    --------------------------------------------------------------
    -- encripta para salvar
    --------------------------------------------------------------
    v_faixa_salarial_en := util_pkg.num_encode(v_faixa_salarial);
    --
    IF v_faixa_salarial_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_faixa_salarial, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_beneficio_en := util_pkg.num_encode(v_beneficio);
    --
    IF v_beneficio_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_beneficio, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_encargo_en := util_pkg.num_encode(v_encargo);
    --
    IF v_encargo_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_encargo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_dissidio_en := util_pkg.num_encode(v_dissidio);
    --
    IF v_dissidio_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_dissidio, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_overhead_en := util_pkg.num_encode(v_overhead);
    --
    IF v_overhead_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_overhead, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
    --
    IF v_custo_hora_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
    --
    IF v_custo_mensal_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
    --
    IF v_venda_hora_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
    --
    IF v_venda_mensal_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    v_margem_hora_en := util_pkg.num_encode(v_margem_hora);
    --
    IF v_margem_hora_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_margem_hora, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    /*
    v_margem_mensal_en := util_pkg.num_encode(v_margem_mensal);
    --
    IF v_margem_mensal_en = -99999 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' ||
                    moeda_mostrar(v_margem_mensal, 'N') || ').';
      RAISE v_exception;
    END IF;
    */
    --
    --
    /*
    WHILE nvl(length(rtrim(v_vetor_preco_id)), 0) > 0
     LOOP
      v_preco_id_char               := prox_valor_retornar(v_vetor_preco_id,
                                                           v_delimitador);
      FOR AUX IN (SELECT salario_cargo_id
                  FROM SALARIO_CARGO
                  WHERE cargo_id = p_cargo_id)
      LOOP
         INSERT INTO salario_preco (salario_cargo_id, preco_id)
         VALUES(AUX.salario_cargo_id,v_preco_id_char);
      END LOOP;
    END LOOP;
    */
    --
    SELECT seq_salario_cargo.nextval
      INTO v_salario_cargo_id
      FROM dual;
    --
    --
    INSERT INTO salario_cargo
     (salario_cargo_id,
      cargo_id,
      nivel,
      preco_id,
      faixa_salarial,
      beneficio,
      encargo,
      dissidio,
      overhead,
      custo_hora,
      custo_mensal,
      venda_hora,
      venda_mensal,
      margem_hora,
      margem_mensal)
    VALUES
     (v_salario_cargo_id,
      p_cargo_id,
      v_nivel,
      v_preco_id_char,
      v_faixa_salarial_en,
      v_beneficio_en,
      v_encargo_en,
      v_dissidio_en,
      v_overhead_en,
      v_custo_hora_en,
      v_custo_mensal_en,
      v_venda_hora_en,
      v_venda_mensal_en,
      v_margem_hora_en,
      v_margem_mensal);
    --
   END LOOP; --LOOP NIVEL
  END LOOP; --LOOP TAB_PRECO
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  /*v_identif_objeto := v_nome_cargo;
  v_compl_histor   := 'Salário incluído: ' ||
                      mes_ano_mostrar(v_data_ini);
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
                   p_erro_msg);*/
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END salario_cargo_vincular; --salario_cargo_vincular
 --
 PROCEDURE salario_cargo_associar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 20/06/2023
  -- DESCRICAO: Associa cargo a tabelas de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --Ana Luiza          04/07/2023  Adicionado p_flag_commit
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_nivel            salario_cargo.nivel%TYPE;
  v_custo_hora       salario_cargo.custo_hora%TYPE;
  v_custo_mensal     salario_cargo.custo_mensal%TYPE;
  v_venda_hora       salario_cargo.venda_hora%TYPE;
  v_venda_mensal     salario_cargo.venda_mensal%TYPE;
  v_faixa_salarial   salario_cargo.faixa_salarial%TYPE;
  v_beneficio        salario_cargo.beneficio%TYPE;
  v_encargo          salario_cargo.encargo%TYPE;
  v_dissidio         salario_cargo.dissidio%TYPE;
  v_overhead         salario_cargo.overhead%TYPE;
  v_margem_hora      salario_cargo.margem_hora%TYPE;
  v_margem_mensal    salario_cargo.margem_mensal%TYPE;
  v_salario_cargo_id salario_cargo.salario_cargo_id%TYPE;
  --
  --
 BEGIN
  v_qt := 0;
  --------------------------------------------------------------------------------------
  --Verificações parametros de entrada
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cargo não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  --Busca precos do cargo da tabela padrao
  SELECT COUNT(*)
    INTO v_qt
    FROM salario_cargo
   WHERE preco_id IN (SELECT preco_id
                        FROM tab_preco
                       WHERE flag_padrao_atual = 'S'
                         AND empresa_id = p_empresa_id)
     AND cargo_id = p_cargo_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Este cargo não está vinculado à tabela padrão atual.';
   RAISE v_exception;
  END IF;
  --
  FOR aux IN (SELECT DISTINCT nivel,
                              faixa_salarial,
                              beneficio,
                              encargo,
                              dissidio,
                              overhead,
                              custo_hora,
                              custo_mensal,
                              venda_hora,
                              margem_hora,
                              venda_mensal,
                              margem_mensal
                FROM salario_cargo
               WHERE preco_id IN (SELECT preco_id
                                    FROM tab_preco
                                   WHERE flag_padrao_atual = 'S'
                                     AND empresa_id = p_empresa_id)
                 AND cargo_id = p_cargo_id
               ORDER BY nivel)
  LOOP
   --Consistência valores
   v_nivel          := nvl(aux.nivel, 0);
   v_faixa_salarial := nvl(aux.faixa_salarial, 0);
   v_beneficio      := nvl(aux.beneficio, 0);
   v_encargo        := nvl(aux.encargo, 0);
   v_dissidio       := nvl(aux.dissidio, 0);
   v_overhead       := nvl(aux.overhead, 0);
   v_custo_hora     := nvl(aux.custo_hora, 0);
   v_custo_mensal   := nvl(aux.custo_mensal, 0);
   v_venda_hora     := nvl(aux.venda_hora, 0);
   v_venda_mensal   := nvl(aux.venda_mensal, 0);
   v_margem_hora    := nvl(aux.margem_hora, 0);
   v_margem_mensal  := nvl(aux.margem_mensal, 0);
   --
   --
   SELECT seq_salario_cargo.nextval
     INTO v_salario_cargo_id
     FROM dual;
   --
   INSERT INTO salario_cargo
    (salario_cargo_id,
     cargo_id,
     nivel,
     custo_hora,
     custo_mensal,
     venda_hora,
     venda_mensal,
     faixa_salarial,
     beneficio,
     encargo,
     dissidio,
     overhead,
     margem_hora,
     margem_mensal,
     preco_id)
   VALUES
    (v_salario_cargo_id,
     p_cargo_id,
     v_nivel,
     v_custo_hora,
     v_custo_mensal,
     v_venda_hora,
     v_venda_mensal,
     v_faixa_salarial,
     v_beneficio,
     v_encargo,
     v_dissidio,
     v_overhead,
     v_margem_hora,
     v_margem_mensal,
     p_preco_id);
  END LOOP;
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END salario_cargo_associar;
 --
 --
 PROCEDURE salario_cargo_desassociar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 20/06/2023
  -- DESCRICAO: Associa cargo a tabelas de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_cargo_id          IN cargo.cargo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  --
 BEGIN
  v_qt := 0;
  --------------------------------------------------------------------------------------
  --Verificações parametros de entrada
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cargo não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --------------------------------------------------------------------------------------
  --Valida se pode ser apagado antes
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_horas csh
   INNER JOIN cenario_servico cs
      ON cs.cenario_servico_id = csh.cenario_servico_id
   INNER JOIN cenario ce
      ON ce.cenario_id = cs.cenario_id
   WHERE ce.preco_id = p_preco_id
     AND ce.cenario_id = p_cargo_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cargo está vinculado a Precificação';
   RAISE v_exception;
  END IF;
  --
  DELETE salario_cargo
   WHERE preco_id = p_preco_id
     AND cargo_id = p_cargo_id;
  --
  COMMIT;
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END salario_cargo_desassociar;
 --
 --
 PROCEDURE salario_cargo_alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 21/06/2023
  -- DESCRICAO: alterar composicao de cargo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         01/11/2023  Ajuste do custo hora
  -- Ana Luiza         30/11/2023  Remoção obrigatoriedade valor de venda de acordo com --
  --                               parametro
  -- Ana Luiza         25/03/2024  Ajuste para nao dar erro de divisor = 0
  -- Ana Luiza         28/08/2024  Ajuste calculo, evitar 99999
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_cargo_id             IN cargo.cargo_id%TYPE,
  p_preco_id             IN tab_preco.preco_id%TYPE,
  p_nome_alternativo     IN VARCHAR2,
  p_vetor_nivel          IN VARCHAR2,
  p_vetor_faixa_salarial IN VARCHAR2,
  p_vetor_beneficio      IN VARCHAR2,
  p_vetor_encargo        IN VARCHAR2,
  p_vetor_dissidio       IN VARCHAR2,
  p_vetor_overhead       IN VARCHAR2,
  p_vetor_custo_hora     IN VARCHAR2,
  p_vetor_custo_mensal   IN VARCHAR2,
  p_vetor_venda_mensal   IN VARCHAR2,
  p_vetor_margem_hora    IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  v_exception      EXCEPTION;
  --
  v_nivel          salario_cargo.nivel%TYPE;
  v_faixa_salarial salario_cargo.faixa_salarial%TYPE;
  v_beneficio      salario_cargo.beneficio%TYPE;
  v_encargo        salario_cargo.encargo%TYPE;
  v_dissidio       salario_cargo.dissidio%TYPE;
  v_overhead       salario_cargo.overhead%TYPE;
  v_custo_hora     salario_cargo.custo_hora%TYPE;
  v_custo_mensal   salario_cargo.custo_mensal%TYPE;
  v_venda_hora     salario_cargo.venda_hora%TYPE;
  v_venda_mensal   salario_cargo.venda_mensal%TYPE;
  v_margem_hora    salario_cargo.margem_hora%TYPE;
  v_margem_mensal  salario_cargo.margem_mensal%TYPE;
  --
  v_nome_cargo cargo.nome%TYPE;
  --
  v_faixa_salarial_en salario_cargo.faixa_salarial%TYPE;
  v_beneficio_en      salario_cargo.beneficio%TYPE;
  v_encargo_en        salario_cargo.encargo%TYPE;
  v_dissidio_en       salario_cargo.dissidio%TYPE;
  v_overhead_en       salario_cargo.overhead%TYPE;
  v_custo_hora_en     salario_cargo.custo_hora%TYPE;
  v_custo_mensal_en   salario_cargo.custo_mensal%TYPE;
  v_venda_hora_en     salario_cargo.venda_hora%TYPE;
  v_venda_mensal_en   salario_cargo.venda_mensal%TYPE;
  v_margem_hora_en    salario_cargo.margem_hora%TYPE;
  --
  --
  v_vetor_faixa_salarial VARCHAR2(1000);
  v_vetor_beneficio      VARCHAR2(1000);
  v_vetor_encargo        VARCHAR2(1000);
  v_vetor_dissidio       VARCHAR2(1000);
  v_vetor_overhead       VARCHAR2(1000);
  v_vetor_custo_hora     VARCHAR2(1000);
  v_vetor_custo_mensal   VARCHAR2(1000);
  v_vetor_venda_mensal   VARCHAR2(1000);
  v_vetor_margem_hora    VARCHAR2(1000);
  --
  v_qt_horas    NUMBER;
  v_delimitador CHAR(1);
  v_vetor_nivel VARCHAR2(1000);
  --
  v_faixa_salarial_char VARCHAR2(20);
  v_beneficio_char      VARCHAR2(20);
  v_encargo_char        VARCHAR2(20);
  v_dissidio_char       VARCHAR2(20);
  v_overhead_char       VARCHAR2(20);
  v_custo_hora_char     VARCHAR2(20);
  v_custo_mensal_char   VARCHAR2(20);
  v_venda_mensal_char   VARCHAR2(20);
  v_margem_hora_char    VARCHAR2(20);
  --
  v_salario_cargo_id salario_cargo.salario_cargo_id%TYPE;
  v_parametro        CHAR(1);
  v_nome             tab_preco.nome%TYPE;
  --
  v_faixa_salarial_ant salario_cargo.faixa_salarial%TYPE;
  v_beneficio_ant      salario_cargo.beneficio%TYPE;
  v_encargo_ant        salario_cargo.encargo%TYPE;
  v_dissidio_ant       salario_cargo.dissidio%TYPE;
  v_overhead_ant       salario_cargo.overhead%TYPE;
  v_custo_hora_ant     salario_cargo.custo_hora%TYPE;
  v_custo_mensal_ant   salario_cargo.custo_mensal%TYPE;
  v_venda_hora_ant     salario_cargo.venda_hora%TYPE;
  v_venda_mensal_ant   salario_cargo.venda_mensal%TYPE;
  v_margem_hora_ant    salario_cargo.margem_hora%TYPE;
  v_margem_mensal_ant  salario_cargo.margem_mensal%TYPE;
  --
  g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
  --
  v_qt_horas_estagiario NUMBER;
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_cargo_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cargo_id é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_preco_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preco_id é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  /*
  SELECT COUNT(*)
  INTO v_qt
  FROM tab_preco
  WHERE preco_id = p_preco_id
  AND flag_padrao = 'S';
  --
  IF v_qt <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa rate card não pode ser alterada pois é padrão.';
    RAISE v_exception;
  END IF;
  */
  --
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND flag_arquivada = 'S';
  --
  IF v_qt <> 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa rate card não pode ser alterada pois está arquivada.';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cargo não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_cargo
    FROM cargo
   WHERE cargo_id = p_cargo_id
     AND empresa_id = p_empresa_id;
  --
  /*v_parametro := empresa_pkg.parametro_retornar(p_empresa_id
  ,'COMP_CUSTO_PRECO_CARGO');*/
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador          := '|';
  v_vetor_nivel          := rtrim(p_vetor_nivel);
  v_vetor_faixa_salarial := rtrim(p_vetor_faixa_salarial);
  v_vetor_beneficio      := rtrim(p_vetor_beneficio);
  v_vetor_encargo        := rtrim(p_vetor_encargo);
  v_vetor_dissidio       := rtrim(p_vetor_dissidio);
  v_vetor_overhead       := rtrim(p_vetor_overhead);
  v_vetor_custo_hora     := rtrim(p_vetor_custo_hora);
  v_vetor_custo_mensal   := rtrim(p_vetor_custo_mensal);
  v_vetor_venda_mensal   := rtrim(p_vetor_venda_mensal);
  v_vetor_margem_hora    := rtrim(p_vetor_margem_hora);
  --
  --
  WHILE nvl(length(rtrim(v_vetor_nivel)), 0) > 0
  LOOP
   v_nivel := prox_valor_retornar(v_vetor_nivel, v_delimitador);
   --
   v_faixa_salarial_char := prox_valor_retornar(v_vetor_faixa_salarial, v_delimitador);
   --
   v_beneficio_char := prox_valor_retornar(v_vetor_beneficio, v_delimitador);
   --
   v_encargo_char := prox_valor_retornar(v_vetor_encargo, v_delimitador);
   --
   v_dissidio_char := prox_valor_retornar(v_vetor_dissidio, v_delimitador);
   --
   v_overhead_char := prox_valor_retornar(v_vetor_overhead, v_delimitador);
   --
   v_custo_hora_char := prox_valor_retornar(v_vetor_custo_hora, v_delimitador);
   --
   v_custo_mensal_char := prox_valor_retornar(v_vetor_custo_mensal, v_delimitador);
   --
   v_venda_mensal_char := prox_valor_retornar(v_vetor_venda_mensal, v_delimitador);
   --
   v_margem_hora_char := prox_valor_retornar(v_vetor_margem_hora, v_delimitador);
   --
   ------------------------------------------------------------
   -- consistencia vetores
   ------------------------------------------------------------
   IF util_pkg.desc_retornar('nivel_usuario', v_nivel) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível inválido (' || v_nivel || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF moeda_validar(v_faixa_salarial_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de faixa salarial inválido (' || v_faixa_salarial_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF moeda_validar(v_beneficio_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de benefício inválido (' || v_beneficio_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF moeda_validar(v_encargo_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de encargo inválido (' || v_encargo_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF moeda_validar(v_dissidio_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de dissídio inválido (' || v_dissidio_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF moeda_validar(v_overhead_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de overhead inválido (' || v_overhead_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF rtrim(v_custo_hora_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo hora é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_custo_hora_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo hora inválido (' || v_custo_hora_char || ').';
    RAISE v_exception;
   END IF;
   --
   --
   IF rtrim(v_custo_mensal_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo mensal é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_custo_mensal_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Custo mensal inválido (' || v_custo_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --
   --ALCBO_301123
   v_parametro := empresa_pkg.parametro_retornar(p_empresa_id, 'COMP_CUSTO_PRECO_CARGO');
   --
   IF v_parametro = 'S' THEN
    IF rtrim(v_venda_mensal_char) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do valor de venda é obrigatório.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_venda_mensal_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de venda inválido (' || v_venda_mensal_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_margem_hora_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de margem hora inválido (' || v_margem_hora_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_qt_horas := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id, 'QT_HORAS_MENSAIS'));
   IF v_nivel = 'E' THEN
    --ALCBO_121223
    v_qt_horas_estagiario := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                             'QT_HORAS_MENSAIS_ESTAG'));
    v_qt_horas            := v_qt_horas_estagiario;
   END IF;
   --ALCBO_270623
   v_faixa_salarial := nvl(numero_converter(v_faixa_salarial_char), 0);
   v_beneficio      := nvl(numero_converter(v_beneficio_char), 0);
   v_encargo        := nvl(numero_converter(v_encargo_char), 0);
   v_dissidio       := nvl(numero_converter(v_dissidio_char), 0);
   v_overhead       := nvl(numero_converter(v_overhead_char), 0);
   v_custo_hora     := nvl(numero_converter(v_custo_hora_char), 0);
   v_custo_mensal   := nvl(numero_converter(v_custo_mensal_char), 0);
   v_venda_mensal   := nvl(numero_converter(v_venda_mensal_char), 0);
   --ALCBO_250324
   IF v_qt_horas = 0 THEN
    v_venda_hora := 0;
    v_custo_hora := 0;
   ELSE
    --ALCBO_280827
    v_venda_hora := (v_venda_mensal / v_qt_horas);
    v_custo_hora := v_custo_mensal / v_qt_horas;
   END IF;
   v_margem_hora   := nvl(numero_converter(v_margem_hora_char), 0);
   v_margem_mensal := nvl(numero_converter(v_venda_mensal - v_custo_mensal), 0);
   --------------------------------------------------------------
   -- encripta para salvar
   --------------------------------------------------------------
   v_faixa_salarial_en := util_pkg.num_encode(v_faixa_salarial);
   --
   IF v_faixa_salarial_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_faixa_salarial, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_beneficio_en := util_pkg.num_encode(v_beneficio);
   --
   IF v_beneficio_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_beneficio, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_encargo_en := util_pkg.num_encode(v_encargo);
   --
   IF v_encargo_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_encargo, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_dissidio_en := util_pkg.num_encode(v_dissidio);
   --
   IF v_dissidio_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_dissidio, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_overhead_en := util_pkg.num_encode(v_overhead);
   --
   IF v_overhead_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_overhead, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
   --
   IF v_custo_hora_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
   --
   IF v_custo_mensal_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
   --
   IF v_venda_hora_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
   --
   IF v_venda_mensal_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   v_margem_hora_en := util_pkg.num_encode(v_margem_hora);
   --
   IF v_margem_hora_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_margem_hora, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   --
   /*
   v_margem_mensal_en := util_pkg.num_encode(v_margem_mensal);
   --
   IF v_margem_mensal_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar
                                        (v_margem_mensal, 'N') || ').';
     RAISE v_exception;
   END IF;
   --
   */
   --
   SELECT salario_cargo_id
     INTO v_salario_cargo_id
     FROM salario_cargo
    WHERE cargo_id = p_cargo_id
      AND preco_id = p_preco_id
      AND nivel = v_nivel;
   --
   --
   SELECT util_pkg.num_decode(faixa_salarial, g_key_num),
          util_pkg.num_decode(beneficio, g_key_num),
          util_pkg.num_decode(encargo, g_key_num),
          util_pkg.num_decode(dissidio, g_key_num),
          util_pkg.num_decode(overhead, g_key_num),
          util_pkg.num_decode(custo_hora, g_key_num),
          util_pkg.num_decode(custo_mensal, g_key_num),
          util_pkg.num_decode(venda_hora, g_key_num),
          util_pkg.num_decode(venda_mensal, g_key_num),
          util_pkg.num_decode(margem_hora, g_key_num),
          util_pkg.num_decode(margem_mensal, g_key_num)
     INTO v_faixa_salarial_ant,
          v_beneficio_ant,
          v_encargo_ant,
          v_dissidio_ant,
          v_overhead_ant,
          v_custo_hora_ant,
          v_custo_mensal_ant,
          v_venda_hora_ant,
          v_venda_mensal_ant,
          v_margem_hora_ant,
          v_margem_mensal_ant
     FROM salario_cargo
    WHERE salario_cargo_id = v_salario_cargo_id;
   --
   --
   IF v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
      v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR v_overhead_ant <> v_overhead OR
      v_custo_hora_ant <> v_custo_hora OR v_custo_mensal_ant <> v_custo_mensal OR
      v_venda_hora_ant <> v_venda_hora OR v_venda_mensal_ant <> v_venda_mensal OR
      v_margem_hora_ant <> v_margem_hora OR v_margem_mensal_ant <> v_margem_mensal THEN
    --
    v_compl_histor := 'Antes: ' || CASE
                       WHEN v_faixa_salarial_ant <> v_faixa_salarial THEN
                        'Faixa salarial: ' || moeda_mostrar(v_faixa_salarial_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_beneficio_ant <> v_beneficio THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial THEN
                          ', '
                         ELSE
                          ''
                        END || 'Benefício: ' || moeda_mostrar(v_beneficio_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_encargo_ant <> v_encargo THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio THEN
                          ', '
                         ELSE
                          ''
                        END || 'Encargo: ' || moeda_mostrar(v_encargo_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_dissidio_ant <> v_dissidio THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo THEN
                          ', '
                         ELSE
                          ''
                        END || 'Dissídio: ' || moeda_mostrar(v_dissidio_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_overhead_ant <> v_overhead THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio THEN
                          ', '
                         ELSE
                          ''
                        END || 'Overhead: ' || moeda_mostrar(v_overhead_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_custo_hora_ant <> v_custo_hora THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead THEN
                          ', '
                         ELSE
                          ''
                        END || 'Custo Hora: ' || moeda_mostrar(v_custo_hora_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_custo_mensal_ant <> v_custo_mensal THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora THEN
                          ', '
                         ELSE
                          ''
                        END || 'Custo Mensal: ' || moeda_mostrar(v_custo_mensal_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_venda_hora_ant <> v_venda_hora THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora OR
                              v_custo_mensal_ant <> v_custo_mensal THEN
                          ', '
                         ELSE
                          ''
                        END || 'Venda Hora: ' || moeda_mostrar(v_venda_hora_ant, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_venda_mensal_ant <> v_venda_mensal THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora OR
                              v_custo_mensal_ant <> v_custo_mensal OR v_venda_hora_ant <> v_venda_hora THEN
                          ', '
                         ELSE
                          ''
                        END || 'Venda Mensal: ' || moeda_mostrar(v_venda_mensal_ant, 'N')
                       ELSE
                        ''
                      END || ' || Agora: ' || CASE
                       WHEN v_faixa_salarial_ant <> v_faixa_salarial THEN
                        'Faixa salarial: ' || moeda_mostrar(v_faixa_salarial, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_beneficio_ant <> v_beneficio THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial THEN
                          ', '
                         ELSE
                          ''
                        END || 'Benefício: ' || moeda_mostrar(v_beneficio, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_encargo_ant <> v_encargo THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio THEN
                          ', '
                         ELSE
                          ''
                        END || 'Encargo: ' || moeda_mostrar(v_encargo, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_dissidio_ant <> v_dissidio THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo THEN
                          ', '
                         ELSE
                          ''
                        END || 'Dissídio: ' || moeda_mostrar(v_dissidio, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_overhead_ant <> v_overhead THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio THEN
                          ', '
                         ELSE
                          ''
                        END || 'Overhead: ' || moeda_mostrar(v_overhead, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_custo_hora_ant <> v_custo_hora THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead THEN
                          ', '
                         ELSE
                          ''
                        END || 'Custo Hora: ' || moeda_mostrar(v_custo_hora, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_custo_mensal_ant <> v_custo_mensal THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora THEN
                          ', '
                         ELSE
                          ''
                        END || 'Custo Mensal: ' || moeda_mostrar(v_custo_mensal, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_venda_hora_ant <> v_venda_hora THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora OR
                              v_custo_mensal_ant <> v_custo_mensal THEN
                          ', '
                         ELSE
                          ''
                        END || 'Venda Hora: ' || moeda_mostrar(v_venda_hora, 'N')
                       ELSE
                        ''
                      END || CASE
                       WHEN v_venda_mensal_ant <> v_venda_mensal THEN
                        CASE
                         WHEN v_faixa_salarial_ant <> v_faixa_salarial OR v_beneficio_ant <> v_beneficio OR
                              v_encargo_ant <> v_encargo OR v_dissidio_ant <> v_dissidio OR
                              v_overhead_ant <> v_overhead OR v_custo_hora_ant <> v_custo_hora OR
                              v_custo_mensal_ant <> v_custo_mensal OR v_venda_hora_ant <> v_venda_hora THEN
                          ', '
                         ELSE
                          ''
                        END || 'Venda Mensal: ' || moeda_mostrar(v_venda_mensal, 'N')
                       ELSE
                        ''
                      END;
    --
    v_compl_histor := rtrim(REPLACE(v_compl_histor, ', ||', ' ||'), ', ');
    --
   END IF;
   UPDATE salario_cargo
      SET cargo_id         = p_cargo_id,
          nivel            = v_nivel,
          preco_id         = p_preco_id,
          faixa_salarial   = v_faixa_salarial_en,
          beneficio        = v_beneficio_en,
          encargo          = v_encargo_en,
          dissidio         = v_dissidio_en,
          overhead         = v_overhead_en,
          custo_hora       = v_custo_hora_en,
          custo_mensal     = v_custo_mensal_en,
          venda_hora       = v_venda_hora_en,
          venda_mensal     = v_venda_mensal_en,
          margem_hora      = v_margem_hora,
          margem_mensal    = v_margem_mensal,
          nome_alternativo = TRIM(p_nome_alternativo)
    WHERE cargo_id = p_cargo_id
      AND preco_id = p_preco_id
      AND salario_cargo_id = v_salario_cargo_id;
   --
   --
   ------------------------------------------------------------
   -- gera xml do log
   ------------------------------------------------------------
   preco_pkg.xml_gerar(p_preco_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   SELECT nome
     INTO v_nome
     FROM tab_preco
    WHERE preco_id = p_preco_id;
   v_identif_objeto := TRIM(v_nome);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'TAB_PRECO',
                    'ALTERAR',
                    v_identif_objeto,
                    p_preco_id,
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
  END LOOP; --LOOP NIVEL
  --
  COMMIT;
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END;
 --
 --
 PROCEDURE tab_preco_percent_aplicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza      ProcessMind     DATA: 27/06/2023
  -- DESCRICAO: Percentual tabela de preço
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_preco_id             IN tab_preco.preco_id%TYPE,
  p_perc_acres_cargo     IN VARCHAR2,
  p_perc_acres_tipo_prod IN VARCHAR2,
  p_flag_commit          IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_faixa_salarial salario_cargo.faixa_salarial%TYPE := 0;
  v_beneficio      salario_cargo.beneficio%TYPE := 0;
  v_dissidio       salario_cargo.dissidio%TYPE := 0;
  v_encargo        salario_cargo.encargo%TYPE := 0;
  v_overhead       salario_cargo.overhead%TYPE := 0;
  v_custo_hora     salario_cargo.custo_hora%TYPE := 0;
  v_custo_mensal   salario_cargo.custo_mensal%TYPE := 0;
  v_venda_hora     salario_cargo.venda_hora%TYPE := 0;
  v_venda_mensal   salario_cargo.venda_mensal%TYPE := 0;
  v_margem_hora    salario_cargo.margem_hora %TYPE := 0;
  v_margem_mensal  salario_cargo.margem_mensal%TYPE := 0;
  --
  v_preco tipo_produto_preco.preco%TYPE;
  v_custo tipo_produto_preco.custo%TYPE;
  --
  v_parametro CHAR(1);
  --
  v_enc_par           NUMBER;
  v_oh_par            NUMBER;
  v_mod_par           NUMBER;
  v_horas_mensais_par NUMBER;
  --
  v_encargo_perc  NUMBER;
  v_overhead_perc NUMBER;
  v_mod_perc      NUMBER;
  v_horas_mensais NUMBER;
  --
  v_faixa_salarial_en salario_cargo.faixa_salarial%TYPE;
  v_beneficio_en      salario_cargo.beneficio%TYPE;
  v_dissidio_en       salario_cargo.dissidio%TYPE;
  v_encargo_en        salario_cargo.encargo%TYPE;
  v_overhead_en       salario_cargo.overhead%TYPE;
  v_custo_hora_en     salario_cargo.custo_hora%TYPE;
  v_custo_mensal_en   salario_cargo.custo_mensal%TYPE;
  v_venda_hora_en     salario_cargo.venda_hora%TYPE;
  v_venda_mensal_en   salario_cargo.venda_mensal%TYPE;
  v_margem_hora_en    salario_cargo.margem_hora %TYPE;
  --
  v_preco_en tipo_produto_preco.preco%TYPE;
  v_custo_en tipo_produto_preco.custo%TYPE;
  --
  v_perc_acres_cargo     tab_preco.perc_acres_cargo%TYPE;
  v_perc_acres_tipo_prod tab_preco.perc_acres_tipo_prod%TYPE;
  --
  g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
  --
 BEGIN
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_acres_cargo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual acrescimo cargo inválido (' || p_perc_acres_cargo || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_acres_tipo_prod) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual acrescimo tipo de produto inválido (' || p_perc_acres_tipo_prod || ').';
   RAISE v_exception;
  END IF;
  --
  v_perc_acres_cargo     := numero_converter(p_perc_acres_cargo);
  v_perc_acres_tipo_prod := numero_converter(p_perc_acres_tipo_prod);
  --
  /*
  SELECT COUNT(*)
  INTO v_qt
  FROM salario_cargo
  WHERE preco_id = p_preco_id;
  --
  IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Cargo inválido para Rate Card '||p_preco_id||'.';
    RAISE v_exception;
  END IF;
  */
  --
  IF v_perc_acres_cargo <> 0 THEN
   FOR aux IN (SELECT salario_cargo_id,
                      cargo_id,
                      util_pkg.num_decode(faixa_salarial, g_key_num) AS faixa_salarial,
                      util_pkg.num_decode(beneficio, g_key_num) AS beneficio,
                      util_pkg.num_decode(encargo, g_key_num) AS encargo,
                      util_pkg.num_decode(dissidio, g_key_num) AS dissidio,
                      util_pkg.num_decode(overhead, g_key_num) AS overhead,
                      util_pkg.num_decode(custo_hora, g_key_num) AS custo_hora,
                      util_pkg.num_decode(custo_mensal, g_key_num) AS custo_mensal,
                      util_pkg.num_decode(venda_hora, g_key_num) AS venda_hora,
                      util_pkg.num_decode(venda_mensal, g_key_num) AS venda_mensal,
                      util_pkg.num_decode(margem_hora, g_key_num) AS margem_hora,
                      util_pkg.num_decode(margem_mensal, g_key_num) AS margem_mensal
                 FROM salario_cargo
                WHERE preco_id = p_preco_id)
   LOOP
    IF aux.faixa_salarial <> 0 OR aux.faixa_salarial IS NOT NULL THEN
     v_faixa_salarial := aux.faixa_salarial;
     v_beneficio      := aux.beneficio;
     v_dissidio       := aux.dissidio;
     v_encargo        := aux.encargo;
     v_overhead       := aux.overhead;
     v_custo_hora     := aux.custo_hora;
     v_custo_mensal   := aux.custo_mensal;
     v_venda_hora     := aux.venda_hora;
     v_venda_mensal   := aux.venda_mensal;
     v_margem_hora    := aux.margem_hora;
     v_margem_mensal  := aux.margem_mensal;
     -------------------------------------------------------------------------------------
     --Buscando parametros dinamicos
     -------------------------------------------------------------------------------------
     v_enc_par := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                  'PERC_ENC_CUSTO_CARGO'));
     --
     v_oh_par := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                 'PERC_OH_CUSTO_CARGO'));
     --
     v_mod_par := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                  'PERC_MO_PRECO_CARGO'));
     --
     v_horas_mensais_par := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                            'QT_HORAS_MENSAIS'));
     --------------------------------------------------------------------------------
     --Parametros dinamicos
     --------------------------------------------------------------------------------
     --
     v_encargo_perc  := (v_enc_par / 100);
     v_overhead_perc := (v_oh_par / 100);
     v_mod_perc      := (v_mod_par / 100);
     v_horas_mensais := v_horas_mensais_par;
     --------------------------------------------------------------------------------
     --Parametro empresa
     --------------------------------------------------------------------------------
     v_parametro := empresa_pkg.parametro_retornar(p_empresa_id, 'COMP_CUSTO_PRECO_CARGO');
     --
     IF v_parametro = 'S' THEN
      IF aux.faixa_salarial IS NOT NULL OR aux.faixa_salarial <> 0 THEN
       ----------------------------------------------------------------------------
       --Início calculos acrécimo
       ----------------------------------------------------------------------------
       v_faixa_salarial := v_faixa_salarial + (v_faixa_salarial * (v_perc_acres_cargo / 100));
       --
       v_beneficio := v_beneficio + (v_beneficio * (v_perc_acres_cargo / 100));
       --
       v_dissidio := v_dissidio + (v_dissidio * (v_perc_acres_cargo / 100));
       --
       v_encargo := (v_faixa_salarial + v_beneficio) * (1 + v_encargo_perc);
       --
       v_overhead := (v_encargo + v_dissidio) * v_overhead_perc;
       --
       v_custo_mensal := v_encargo + v_dissidio + v_overhead;
       --
       v_custo_hora := v_custo_mensal / v_horas_mensais;
       --
       v_margem_hora := (v_custo_hora / (1 - v_mod_perc)) - v_custo_hora;
       --
       v_venda_hora := v_custo_hora + v_margem_hora;
       --
       v_venda_mensal := v_custo_hora * v_horas_mensais;
       --
       v_margem_mensal := v_venda_mensal - v_custo_mensal;
       --
       v_faixa_salarial := nvl(v_faixa_salarial, 0);
       v_beneficio      := nvl(v_beneficio, 0);
       v_dissidio       := nvl(v_dissidio, 0);
       v_encargo        := nvl(v_encargo, 0);
       v_overhead       := nvl(v_overhead, 0);
       v_custo_mensal   := nvl(v_custo_mensal, 0);
       v_custo_hora     := nvl(v_custo_hora, 0);
       v_venda_hora     := nvl(v_venda_hora, 0);
       v_venda_mensal   := nvl(v_venda_mensal, 0);
       v_margem_hora    := nvl(v_margem_hora, 0);
       v_margem_mensal  := nvl(v_margem_mensal, 0);
       ----------------------------------------------------------------------------
       --encriptografar valores
       ----------------------------------------------------------------------------
       v_faixa_salarial_en := util_pkg.num_encode(v_faixa_salarial);
       --
       IF v_faixa_salarial_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '1 - Erro na encriptação (' || moeda_mostrar(v_faixa_salarial, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_beneficio_en := util_pkg.num_encode(v_beneficio);
       --
       IF v_beneficio_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '2 - Erro na encriptação (' || moeda_mostrar(v_beneficio, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_encargo_en := util_pkg.num_encode(v_encargo);
       --
       IF v_encargo_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '3 - Erro na encriptação (' || moeda_mostrar(v_encargo, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_dissidio_en := util_pkg.num_encode(v_dissidio);
       --
       IF v_dissidio_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '4 - Erro na encriptação (' || moeda_mostrar(v_dissidio, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_overhead_en := util_pkg.num_encode(v_overhead);
       --
       IF v_overhead_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '5 - Erro na encriptação 5 (' || moeda_mostrar(v_overhead, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_custo_hora_en := util_pkg.num_encode(v_custo_hora);
       --
       IF v_custo_hora_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '6 - Erro na encriptação (' || moeda_mostrar(v_custo_hora, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
       --
       IF v_custo_mensal_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '7 - Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
       --
       IF v_venda_hora_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '8 - Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
       --
       IF v_venda_mensal_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '9 - Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       v_margem_hora_en := util_pkg.num_encode(v_margem_hora);
       --
       IF v_margem_hora_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '10 - Erro na encriptação (' || moeda_mostrar(v_margem_hora, 'N') || ').';
        RAISE v_exception;
       END IF;
       --
       --
       /*
       v_margem_mensal_en := util_pkg.num_encode(v_margem_mensal);
       --
       IF v_margem_mensal_en = -99999 THEN
         p_erro_cod := '90000';
         p_erro_msg := '11 - Erro na encriptação(' || moeda_mostrar
                       (v_margem_mensal, 'N') || ') cargo_id = '|| aux.cargo_id;
         RAISE v_exception;
       END IF;
       --
       */
       --
       UPDATE salario_cargo
          SET faixa_salarial = v_faixa_salarial_en,
              beneficio      = v_beneficio_en,
              dissidio       = v_dissidio_en,
              encargo        = v_encargo_en,
              overhead       = v_overhead_en,
              custo_mensal   = v_custo_mensal_en,
              custo_hora     = v_custo_hora_en,
              venda_hora     = v_venda_hora_en,
              venda_mensal   = v_venda_mensal_en,
              margem_hora    = v_margem_hora_en,
              margem_mensal  = v_margem_mensal
        WHERE salario_cargo_id = aux.salario_cargo_id;
      END IF;
     END IF;
     IF v_parametro = 'N' THEN
      --
      v_custo_mensal := v_custo_mensal + (v_custo_mensal * (v_perc_acres_cargo / 100));
      --
      v_venda_hora := v_venda_hora + (v_venda_hora * (v_perc_acres_cargo / 100));
      --
      v_venda_mensal := v_venda_hora * v_horas_mensais;
      --
      v_margem_mensal := v_venda_mensal - v_custo_mensal;
      --
      v_custo_mensal  := nvl(v_custo_mensal, 0);
      v_venda_hora    := nvl(v_venda_hora, 0);
      v_venda_mensal  := nvl(v_venda_mensal, 0);
      v_margem_mensal := nvl(v_margem_mensal, 0);
      ------------------------------------------------------------------------------
      --encriptografar valores
      ------------------------------------------------------------------------------
      v_custo_mensal_en := util_pkg.num_encode(v_custo_mensal);
      --
      IF v_custo_mensal_en = -99999 THEN
       p_erro_cod := '90000';
       p_erro_msg := '1 - Erro na encriptação (' || moeda_mostrar(v_custo_mensal, 'N') || ').';
       RAISE v_exception;
      END IF;
      --
      --
      v_venda_hora_en := util_pkg.num_encode(v_venda_hora);
      --
      IF v_venda_hora_en = -99999 THEN
       p_erro_cod := '90000';
       p_erro_msg := '2 - Erro na encriptação (' || moeda_mostrar(v_venda_hora, 'N') || ').';
       RAISE v_exception;
      END IF;
      --
      --
      v_venda_mensal_en := util_pkg.num_encode(v_venda_mensal);
      --
      IF v_venda_mensal_en = -99999 THEN
       p_erro_cod := '90000';
       p_erro_msg := '3 - Erro na encriptação (' || moeda_mostrar(v_venda_mensal, 'N') || ').';
       RAISE v_exception;
      END IF;
      --
      --
      /*
      v_margem_mensal_en := util_pkg.num_encode(v_margem_mensal);
      --
      IF v_margem_mensal_en = -99999 THEN
        p_erro_cod := '90000';
        p_erro_msg := '4 - Erro na encriptação (' || moeda_mostrar
                      (v_margem_mensal, 'N') || ').';
        RAISE v_exception;
      END IF;
      */
      --
      UPDATE salario_cargo
         SET custo_mensal  = v_custo_mensal_en,
             venda_hora    = v_venda_hora_en,
             venda_mensal  = v_venda_mensal_en,
             margem_mensal = v_margem_mensal
       WHERE salario_cargo_id = aux.salario_cargo_id;
      --
      --
     END IF;
    END IF; --SE NAO FOREM NULOS
   END LOOP;
  END IF;
  --
  --
  IF v_perc_acres_tipo_prod <> 0 THEN
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_produto_preco
    WHERE preco_id = p_preco_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de Entregável inválido para Rate Card' || p_preco_id || '.';
    RAISE v_exception;
   END IF;
   --
   FOR aux IN (SELECT tipo_produto_preco_id,
                      util_pkg.num_decode(preco, g_key_num) AS preco,
                      util_pkg.num_decode(custo, g_key_num) AS custo
                 FROM tipo_produto_preco
                WHERE preco_id = p_preco_id)
   LOOP
    v_preco := aux.preco;
    v_custo := aux.custo;
    ----------------------------------------------------------------------------------
    --Adicionando percentual
    ----------------------------------------------------------------------------------
    v_preco := v_preco + (v_preco * v_perc_acres_tipo_prod / 100);
    v_custo := v_custo + (v_custo * v_perc_acres_tipo_prod / 100);
    --
    v_preco := nvl(v_preco, 0);
    v_custo := nvl(v_custo, 0);
    ----------------------------------------------------------------------------------
    --encriptografar valores
    ----------------------------------------------------------------------------------
    v_preco_en := util_pkg.num_encode(v_preco);
    --
    IF v_preco_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_preco, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_custo_en := util_pkg.num_encode(v_custo);
    --
    IF v_custo_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    --
    UPDATE tipo_produto_preco
       SET preco = v_preco_en,
           custo = v_custo_en
     WHERE tipo_produto_preco_id = aux.tipo_produto_preco_id;
    --
   --
   END LOOP;
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END;
 --
 --
 PROCEDURE tipo_produto_vincular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza           ProcessMind     DATA: 22/06/2023
  -- DESCRICAO: Vincula tabela de preco com tipo_produto.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_vetor_preco_id    IN VARCHAR2,
  p_custo             IN VARCHAR2,
  p_preco             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_vetor_preco_id VARCHAR2(1000);
  v_custo          VARCHAR2(1000);
  v_preco          VARCHAR2(1000);
  --
  v_delimitador   CHAR(1);
  v_preco_id_char VARCHAR(20);
  --
  v_custo_en              tipo_produto_preco.custo%TYPE;
  v_preco_en              tipo_produto_preco.preco%TYPE;
  v_tipo_produto_preco_id tipo_produto_preco.tipo_produto_preco_id%TYPE;
 BEGIN
  /*
  IF 1 = 1 THEN
     p_erro_cod := '90000';
    p_erro_msg := 'p_usuario_sessao_id ->'|| p_usuario_sessao_id|| 'p_empresa_id ->' ||          p_empresa_id ||'p_tipo_produto_id -> '|| p_tipo_produto_id || 'p_vetor_preco_id -> ' || p_vetor_preco_id || 'p_custo->' || p_custo || 'p_preco->' || p_preco ;
    RAISE v_exception;
  END IF;
  */
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Tipo de Entregável não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  --
  v_delimitador    := '|';
  v_vetor_preco_id := rtrim(p_vetor_preco_id);
  v_custo          := rtrim(p_custo);
  v_preco          := rtrim(p_preco);
  --
  WHILE nvl(length(rtrim(v_vetor_preco_id)), 0) > 0
  LOOP
   v_preco_id_char := prox_valor_retornar(v_vetor_preco_id, v_delimitador);
   --
   IF v_preco_id_char IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preço precisa ser vinculado à uma rate card';
    RAISE v_exception;
   END IF;
   ------------------------------------------------------------
   -- consistencia vetores
   ------------------------------------------------------------
   v_preco_id_char := nvl(v_preco_id_char, 0);
   v_custo         := nvl(numero_converter(v_custo), 0);
   v_preco         := nvl(numero_converter(v_preco), 0);
   --------------------------------------------------------------
   -- encripta para salvar
   --------------------------------------------------------------
   v_custo_en := util_pkg.num_encode(v_custo);
   --
   IF v_custo_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   v_preco_en := util_pkg.num_encode(v_preco);
   --
   IF v_preco_en = -99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_preco, 'N') || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_tipo_produto_preco.nextval
     INTO v_tipo_produto_preco_id
     FROM dual;
   --
   INSERT INTO tipo_produto_preco
    (tipo_produto_preco_id,
     tipo_produto_id,
     preco_id,
     custo,
     preco)
   VALUES
    (v_tipo_produto_preco_id,
     p_tipo_produto_id,
     v_preco_id_char,
     v_custo_en,
     v_preco_en);
   --
  END LOOP;
 END;
 --
 --
 PROCEDURE tipo_produto_preco_associar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 29/06/2023
  -- DESCRICAO: Associa tipo_produto a tabelas de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         04/07/2023  Adicionado p_flag_commit
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_custo tipo_produto_preco.custo%TYPE;
  v_preco tipo_produto_preco.preco%TYPE;
  --
  --
  v_tipo_produto_preco_id tipo_produto_preco.tipo_produto_preco_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --------------------------------------------------------------------------------------
  --Verificações parametros de entrada
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável inválido ou não pertence à empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto_preco
   WHERE preco_id IN (SELECT preco_id
                        FROM tab_preco
                       WHERE flag_padrao_atual = 'S'
                         AND empresa_id = p_empresa_id)
     AND tipo_produto_id = p_tipo_produto_id;
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Este tipo de produto não está vinculado à tabela padrão.';
   RAISE v_exception;
  END IF;
  --Busca precos do cargo da tabela padrao
  FOR aux IN (SELECT custo,
                     preco
                FROM tipo_produto_preco
               WHERE preco_id IN (SELECT preco_id
                                    FROM tab_preco
                                   WHERE flag_padrao_atual = 'S'
                                     AND empresa_id = p_empresa_id)
                 AND tipo_produto_id = p_tipo_produto_id
               ORDER BY tipo_produto_preco_id)
  LOOP
   --Consistência valores
   v_custo := aux.custo;
   v_preco := aux.preco;
   --
   SELECT seq_tipo_produto_preco.nextval
     INTO v_tipo_produto_preco_id
     FROM dual;
   --
   INSERT INTO tipo_produto_preco
    (tipo_produto_preco_id,
     tipo_produto_id,
     preco_id,
     preco,
     custo)
   VALUES
    (v_tipo_produto_preco_id,
     p_tipo_produto_id,
     p_preco_id,
     nvl(v_preco, 0),
     nvl(v_custo, 0));
  END LOOP;
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END tipo_produto_preco_associar;
 --
 --
 PROCEDURE tipo_produto_preco_desassociar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 03/07/2023
  -- DESCRICAO: desassocia produto a tabelas de preco
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  --
 BEGIN
  v_qt := 0;
  --------------------------------------------------------------------------------------
  --Verificações parametros de entrada
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Tipo de Entregável não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  --------------------------------------------------------------------------------------
  --Valida se pode ser apagado antes
  --------------------------------------------------------------------------------------
  DELETE tipo_produto_preco
   WHERE preco_id = p_preco_id
     AND tipo_produto_id = p_tipo_produto_id;
  --
  COMMIT;
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END tipo_produto_preco_desassociar;
 --
 --
 PROCEDURE tipo_produto_preco_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 03/07/2023
  -- DESCRICAO: alterar composicao de tipo_produto
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_produto_id   IN tipo_produto.tipo_produto_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_custo             IN VARCHAR2,
  p_preco             IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_atual      CLOB;
  v_exception      EXCEPTION;
  --
  v_nome_tipo_produto tipo_produto.nome%TYPE;
  --
  v_tipo_produto_preco_id tipo_produto_preco.tipo_produto_preco_id%TYPE;
  --
  v_preco tipo_produto_preco.preco%TYPE;
  v_custo tipo_produto_preco.custo%TYPE;
  --
  v_preco_en tipo_produto_preco.preco%TYPE;
  v_custo_en tipo_produto_preco.custo%TYPE;
  --
  v_custo_ant tipo_produto_preco.custo%TYPE;
  v_preco_ant tipo_produto_preco.preco%TYPE;
  v_nome      tab_preco.nome%TYPE;
  --
  g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 BEGIN
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND flag_arquivada = 'S';
  --
  IF v_qt <> 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa rate card não pode ser alterada pois está arquivada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Tipo de Entregável não existe ou não pertence à essa empresa.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_custo IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do custo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_preco IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_tipo_produto
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  v_custo := nvl(numero_converter(p_custo), 0);
  v_preco := nvl(numero_converter(p_preco), 0);
  --------------------------------------------------------------
  -- encripta para salvar
  --------------------------------------------------------------
  --
  v_custo_en := util_pkg.num_encode(v_custo);
  --
  IF v_custo_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  --
  v_preco_en := util_pkg.num_encode(v_preco);
  --
  IF v_preco_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_preco, 'N') || ').';
   RAISE v_exception;
  END IF;
  --------------------------------------------------------------------------------------
  --Atualizacao do banco
  --------------------------------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto_preco
   WHERE tipo_produto_id = p_tipo_produto_id
     AND preco_id = p_preco_id;
  --
  /*
  IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não encontrado nenhum
                  registro para esse Tipo Entregável -> '||p_tipo_produto_id||
                           ' e tabela ->' || p_preco_id ;
    RAISE v_exception;
  END IF;
  */
  SELECT tipo_produto_preco_id
    INTO v_tipo_produto_preco_id
    FROM tipo_produto_preco
   WHERE tipo_produto_id = p_tipo_produto_id
     AND preco_id = p_preco_id;
  --
  SELECT util_pkg.num_decode(custo, g_key_num),
         util_pkg.num_decode(preco, g_key_num)
    INTO v_custo_ant,
         v_preco_ant
    FROM tipo_produto_preco
   WHERE tipo_produto_preco_id = v_tipo_produto_preco_id;
  --
  SELECT util_pkg.num_decode(custo, g_key_num),
         util_pkg.num_decode(preco, g_key_num)
    INTO v_custo_ant,
         v_preco_ant
    FROM tipo_produto_preco
   WHERE tipo_produto_preco_id = v_tipo_produto_preco_id;
  --
  IF v_custo_ant <> v_custo OR v_preco_ant <> v_preco THEN
   v_compl_histor := 'Antes: ' || CASE
                      WHEN v_custo_ant <> v_custo THEN
                       'Custo: ' || moeda_mostrar(v_custo_ant, 'N') || ', '
                      ELSE
                       ''
                     END || CASE
                      WHEN v_preco_ant <> v_preco THEN
                       'Preço: ' || moeda_mostrar(v_preco_ant, 'N') || ', '
                      ELSE
                       ''
                     END || '|| Agora: ' || CASE
                      WHEN v_custo_ant <> v_custo THEN
                       'Custo: ' || moeda_mostrar(v_custo, 'N') || ', '
                      ELSE
                       ''
                     END || CASE
                      WHEN v_preco_ant <> v_preco THEN
                       'Preço: ' || moeda_mostrar(v_preco, 'N') || ', '
                      ELSE
                       ''
                     END;
   v_compl_histor := rtrim(REPLACE(v_compl_histor, ', ||', ' ||'), ', ');
  END IF;
  --
  UPDATE tipo_produto_preco
     SET custo = nvl(v_custo_en, 0),
         preco = nvl(v_preco_en, 0)
   WHERE tipo_produto_preco_id = v_tipo_produto_preco_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  preco_pkg.xml_gerar(p_preco_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  SELECT nome
    INTO v_nome
    FROM tab_preco
   WHERE preco_id = p_preco_id;
  --
  v_identif_objeto := TRIM(v_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAB_PRECO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_preco_id,
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
   ROLLBACK;
 END;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza           ProcessMind     DATA: 29/05/2023
  -- DESCRICAO: Subrotina que gera o xml do preco para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
 (
  p_preco_id IN tab_preco.preco_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_doc   VARCHAR2(100);
  --
 BEGIN
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("preco_id", pr.preco_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", pr.nome),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("grupo", g.nome),
                   xmlelement("tab_base", pr.tabela_preco_base_id),
                   xmlelement("data_ref", data_mostrar(pr.data_referencia)),
                   xmlelement("data_ini", pr.data_ini),
                   xmlelement("data_fim", pr.data_fim),
                   xmlelement("data_validade", pr.data_validade),
                   xmlelement("pode_precif", pr.flag_pode_precif),
                   xmlelement("pode_ganhar", pr.flag_pode_ganhar),
                   xmlelement("arquivada", pr.flag_arquivada),
                   xmlelement("padrao", pr.flag_padrao),
                   xmlelement("padrao_atual", pr.flag_padrao_atual),
                   xmlelement("perc_acres_cargo", numero_mostrar(pr.perc_acres_cargo, 5, 'N')),
                   xmlelement("perc_acres_tipo_prod",
                              numero_mostrar(pr.perc_acres_tipo_prod, 5, 'N')),
                   xmlelement("usu_cri", pe.apelido),
                   xmlelement("data_criacao", pr.data_criacao),
                   xmlelement("usu_ult_alt", pe.apelido),
                   xmlelement("data_ult_alt", pr.data_ult_alt))
    INTO v_xml
    FROM tab_preco pr
    LEFT JOIN grupo g
      ON pr.grupo_id = g.grupo_id
    LEFT JOIN pessoa cl
      ON pr.cliente_id = cl.pessoa_id
    LEFT JOIN pessoa pe
      ON pr.usu_alt_id = pe.usuario_id
   WHERE pr.preco_id = p_preco_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "cargo"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("preco", v_xml))
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
END;

/
