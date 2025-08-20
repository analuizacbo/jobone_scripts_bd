--------------------------------------------------------
--  DDL for Package Body CENARIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CENARIO_PKG" IS
 --
 --
 PROCEDURE consistir_cenario
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/03/2019
  -- DESCRICAO: Consistencia de valores da OPORTUNIDADE.
  --   TIPO_CHAMADA: BD - usado como subrotina pelo banco
  --                 WEB - usado pelo wizard (pre-consistencia)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Silvia            29/05/2020  Novos parametros de cenario
  -- Silvia            13/04/2022  Novos parametros de responsavel
  -- Silvia            12/07/2022  Consistencia de responsavel obrigatorio
  -- Silvia            28/07/2022  Na chamada WEB, verifica cenario obrigatorio
  -- Ana Luiza         20/07/2023  Remoção da cenario/servico empresa, pois recebera valor
  --                               ja precificado da tab_preco
  -- Ana Luiza         17/08/2023  Adicao de consistencias para novas colunas da tab
  --                               cenario
  -- Ana Luiza         18/12/2023  Remocao de obrigatoriedade e validacao cond_pag e
  --                               num_parcelas a pedido do pessoal de web
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_tipo_chamada      IN VARCHAR2,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_nome_cenario      IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_saida               EXCEPTION;
  v_valor_cotacao       cenario.valor_cotacao%TYPE;
  v_data_cotacao        cenario.data_cotacao%TYPE;
  v_num_parcelas        cenario.num_parcelas%TYPE;
  v_prazo_pagamento     cenario.prazo_pagamento%TYPE;
  v_valor_oportun       oportunidade.valor_oportun%TYPE;
  v_valor_oportun_aux   oportunidade.valor_oportun%TYPE;
  v_flag_obriga_cenario status_aux_oport.flag_obriga_cenario%TYPE;
  --ALCBO_270723
  v_preco_id       tab_preco.preco_id%TYPE;
  v_cond_pagamento cenario.cond_pagamento%TYPE;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_chamada) IS NULL OR p_tipo_chamada NOT IN ('BD', 'WEB')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de chamada inválida (' || p_tipo_chamada || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(flag_obriga_cenario)
    INTO v_flag_obriga_cenario
    FROM status_aux_oport
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = 'ANDA'
     AND flag_padrao = 'S';
  --
  IF p_tipo_chamada = 'WEB' AND v_flag_obriga_cenario = 'N' AND TRIM(p_nome_cenario) IS NULL
  THEN
   -- chamada via Wizard. Qdo o cenario nao eh obrigatorio e o nome
   -- do cenario nao eh informado, sai sem consistir.
   RAISE v_saida;
  END IF;
  --
  IF TRIM(p_nome_cenario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Nome do Cenário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome_cenario)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Nome do Cenário não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido (' || p_flag_padrao || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_moeda) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da Moeda é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('moeda', p_moeda) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Moeda inválida (' || p_moeda || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_valor_cotacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da cotação da moeda inválido (' || p_valor_cotacao || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_cotacao := nvl(numero_converter(p_valor_cotacao), 0);
  --
  IF data_validar(p_data_cotacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da cotação inválido (' || p_data_cotacao || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_cotacao := data_converter(p_data_cotacao);
  --
  IF p_moeda = 'REAL' AND (v_data_cotacao IS NOT NULL OR v_valor_cotacao > 0)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para essa moeda, a cotação não deve ser informada.';
   RAISE v_exception;
  END IF;
  --
  IF p_moeda <> 'REAL' AND (v_data_cotacao IS NULL OR v_valor_cotacao = 0)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para essa moeda, a cotação deve ser informada.';
   RAISE v_exception;
  END IF;
  --ALCBO_170823
  IF nvl(p_preco_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Rate Card é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(preco_id)
    INTO v_preco_id
    FROM tab_preco
   WHERE preco_id = p_preco_id
     AND empresa_id = p_empresa_id;
  --
  IF v_preco_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Rate Card não existe ou não pertence à empresa.';
   RAISE v_exception;
  END IF;
  --
  --
  /*
  --ALCBO_181223
  IF inteiro_validar(p_num_parcelas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de Parcelas inválido (' || p_num_parcelas || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_parcelas := nvl(to_number(p_num_parcelas), 0);
  --
  IF v_num_parcelas <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de Parcelas inválido (' || p_num_parcelas || ').';
   RAISE v_exception;
  END IF;
  v_num_parcelas := nvl(to_number(p_num_parcelas), 0);
  --
  IF TRIM(p_cond_pagamento) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Condição de Pagamento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cond_pagamento) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Condição de Pagamento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_cond_pagamento) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Condição de Pagamento inválido (' || p_cond_pagamento || ').';
   RAISE v_exception;
  END IF;
  --
  v_cond_pagamento := nvl(to_number(p_cond_pagamento), 0);
  --
  IF v_cond_pagamento < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Condição de Pagamento inválido (' || v_cond_pagamento || ').';
   RAISE v_exception;
  END IF;
  */
  v_num_parcelas   := nvl(to_number(p_num_parcelas), 0);
  v_cond_pagamento := nvl(to_number(p_cond_pagamento), 0);
  --
  IF TRIM(p_prazo_pagamento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo de Pagamento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_prazo_pagamento) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo de Pagamento inválido (' || p_prazo_pagamento || ').';
   RAISE v_exception;
  END IF;
  --
  v_prazo_pagamento := nvl(to_number(p_prazo_pagamento), 0);
  --
  IF v_prazo_pagamento < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo de Pagamento inválido (' || v_prazo_pagamento || ').';
   RAISE v_exception;
  END IF;
  --ALCBO_250823
  IF TRIM(p_coment_parcelas) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Comentário de Condição de Pagamento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_coment_parcelas)) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Os Comentários da condição de pagamento não podem ' ||
                 'ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_comissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag Comissão inválida (' || p_flag_comissao || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_oportun <> v_valor_oportun_aux
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Total de produtos deve bater com o Budget Total.';
   RAISE v_exception;
  END IF;
  --ALCBO_250823F
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   ROLLBACK;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
 END consistir_cenario;
 --
 --
 PROCEDURE cenario_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/07/2019
  -- DESCRICAO: Inclusao de CENARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Silvia            20/05/2020  Novos parametros de moeda
  -- Silvia            13/04/2022  Novos parametros para responsavel
  -- Silvia            01/08/2022  Enderecamento automatico de responsavel
  -- Ana Luiza         20/07/2023  Remoção da cenario/servico empresa, pois recebera valor
  --                               ja precificado da tab_preco
  -- Ana Luiza         31/07/2023  Adicao novos atributos da tab cenario
  -- Ana Luiza         16/08/2023  Adição de variavel que grava parametro de empresa
  -- Ana Luiza         03/04/2024  Adicao do parametro overhead
  -- Ana Luiza         28/06/2024  Criado condicao para ter pelo menos um cenario padrao
  -- Ana Luiza         18/12/2024  Follow-up automatico(novo registro na tab interacao)
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_nome              IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_briefing          IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_cenario_id        OUT cenario.cenario_id%TYPE,
  p_etapa             OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_numero_oport   oportunidade.numero%TYPE;
  v_status_oport   oportunidade.status%TYPE;
  v_valor_oportun  oportunidade.valor_oportun%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_cenario_id     cenario.cenario_id%TYPE;
  v_num_cenario    cenario.num_cenario%TYPE;
  --
  v_data_prazo cenario.data_prazo%TYPE;
  --ALCBO_160823
  v_perc_imposto_precif       cenario.perc_imposto_precif%TYPE;
  v_perc_imposto_precif_honor cenario.perc_imposto_precif%TYPE;
  v_num_dias_elab_precif      VARCHAR2(100);
  --
  v_num_parcelas    cenario.num_parcelas%TYPE;
  v_valor_cotacao   cenario.valor_cotacao%TYPE;
  v_data_cotacao    cenario.data_cotacao%TYPE;
  v_prazo_pagamento cenario.prazo_pagamento%TYPE;
  v_cond_pagamento  cenario.cond_pagamento%TYPE;
  --ALCBO_030424
  v_perc_overhead       NUMBER;
  v_interacao_id        interacao.interacao_id%TYPE;
  v_avancar_etapa_oport VARCHAR2(100);
 BEGIN
  v_qt                  := 0;
  p_cenario_id          := 0;
  v_avancar_etapa_oport := empresa_pkg.parametro_retornar(p_empresa_id, 'AVANCAR_ETAPA_OPORT');
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                p_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = p_oportunidade_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  --cenario_pkg.xml_gerar(v_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  oportunidade_pkg.xml_gerar(p_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --ALCBO_200723
  cenario_pkg.consistir_cenario(p_usuario_sessao_id,
                                p_empresa_id,
                                p_preco_id,
                                'BD',
                                0,
                                p_nome,
                                p_num_parcelas,
                                p_coment_parcelas,
                                'S',
                                p_moeda,
                                p_valor_cotacao,
                                p_data_cotacao,
                                p_flag_comissao,
                                p_prazo_pagamento,
                                p_cond_pagamento,
                                p_erro_cod,
                                p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_num_parcelas    := numero_converter(p_num_parcelas);
  v_valor_cotacao   := numero_converter(p_valor_cotacao);
  v_data_cotacao    := data_converter(p_data_cotacao);
  v_prazo_pagamento := numero_converter(p_prazo_pagamento);
  --ACBO_180723
  v_num_dias_elab_precif := empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_ELAB_PRECIF');
  v_data_prazo           := feriado_pkg.prox_dia_util_retornar(1,
                                                               SYSDATE,
                                                               v_num_dias_elab_precif,
                                                               'S');
  v_cond_pagamento       := numero_converter(p_cond_pagamento);
  --ALCBO_030424
  v_perc_overhead := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                     'PERC_OH_CUSTO_CARGO'));
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S'
  THEN
   -- desmarca cenarios anteriores
   UPDATE cenario
      SET flag_padrao = 'N'
    WHERE oportunidade_id = p_oportunidade_id;
  
  END IF;
  --
  SELECT seq_cenario.nextval
    INTO v_cenario_id
    FROM dual;
  --
  SELECT nvl(MAX(num_cenario), 0) + 1
    INTO v_num_cenario
    FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  --
  v_perc_imposto_precif       := empresa_pkg.parametro_retornar(p_empresa_id, 'PERC_IMPOSTO_PRECIF');
  v_perc_imposto_precif_honor := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                'PERC_IMPOSTO_PRECIF_HONOR');
  --
  INSERT INTO cenario
   (cenario_id,
    oportunidade_id,
    num_cenario,
    nome,
    data_entrada,
    num_parcelas,
    prazo_pagamento,
    coment_parcelas,
    flag_padrao,
    flag_comissao_venda,
    moeda,
    valor_cotacao,
    data_cotacao,
    preco_id,
    briefing,
    data_prazo,
    status,
    valor,
    status_margem,
    perc_imposto_precif,
    perc_imposto_honor,
    cond_pagamento,
    status_aprov_rc,
    perc_overhead)
  VALUES
   (v_cenario_id,
    p_oportunidade_id,
    v_num_cenario,
    TRIM(p_nome),
    SYSDATE,
    v_num_parcelas,
    v_prazo_pagamento,
    TRIM(p_coment_parcelas),
    p_flag_padrao,
    p_flag_comissao,
    p_moeda,
    v_valor_cotacao,
    v_data_cotacao,
    p_preco_id,
    p_briefing,
    v_data_prazo,
    'PREP',
    0,
    'PEND',
    v_perc_imposto_precif,
    v_perc_imposto_precif_honor,
    v_cond_pagamento,
    'NA',
    v_perc_overhead);
  --
  --ALCBO_280624
  IF p_flag_padrao = 'N'
  THEN
   SELECT COUNT(flag_padrao)
     INTO v_qt
     FROM cenario
    WHERE oportunidade_id = p_oportunidade_id
      AND flag_padrao = 'S';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário tem pelo menos um Cenário Padrão.';
    RAISE v_exception;
    --
    UPDATE cenario
       SET flag_padrao = 'S'
     WHERE cenario_id = p_cenario_id;
   
   END IF;
  
  END IF;
  --
  IF p_flag_padrao = 'S'
  THEN
   UPDATE oportunidade
      SET valor_oportun = v_valor_oportun
    WHERE oportunidade_id = p_oportunidade_id;
  END IF;
  --
  --instancia modalidades de contratação para indicação em ITENS relacionados ao cenario_servico
  INSERT INTO cenario_mod_contr
   (cenario_mod_contr_id,
    cenario_id,
    ordem,
    codigo,
    descricao,
    flag_margem,
    flag_honor,
    flag_encargo,
    flag_imposto,
    tipo_item_codigo,
    flag_impo_so_honor,
    tipo_impo_honor)
   SELECT seq_cenario_mod_contr.nextval,
          v_cenario_id,
          ordem,
          codigo,
          descricao,
          flag_margem,
          flag_honor,
          flag_encargo,
          flag_imposto,
          tipo_item_codigo,
          flag_impo_so_honor,
          tipo_impo_honor
     FROM modal_contratacao
    WHERE empresa_id = p_empresa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(v_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport) || '/' || to_char(v_num_cenario);
  v_compl_histor   := 'Inclusão de Cenário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cenario_id,
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
  --ALCBO_181224
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  IF v_qt = 1 AND v_avancar_etapa_oport NOT IN ('NENHUMA')
  THEN
   --
   cenario_pkg.interacao_adicionar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   p_oportunidade_id,
                                   'N',
                                   v_interacao_id,
                                   p_erro_cod,
                                   p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  IF v_interacao_id IS NOT NULL
  THEN
   p_etapa := v_avancar_etapa_oport;
  END IF;
  p_cenario_id := v_cenario_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de Cenário já existe (' || to_char(v_num_cenario) ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END cenario_adicionar;
 --
 --
 PROCEDURE cenario_atualizar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/03/2019
  -- DESCRICAO: Atualização de dados do CENARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Silvia            20/05/2020  Novos parametros de moeda
  -- Silvia            13/04/2022  Novos parametros para responsavel
  -- Silvia            01/08/2022  Enderecamento automatico de responsavel
  -- Ana Luiza         20/07/2023  Remoção da cenario/servico empresa, pois recebera valor
  --                               ja precificado da tab_preco
  -- Ana Luiza         31/07/2023  Adicao novos atributos da tab cenario
  -- Ana Luiza         11/06/2023  Alterado condicao para testar prazo_pagamento
  -- Ana Luiza         28/06/2024  Criado condicao para ter pelo menos um cenario padrao
  -- Ana Luiza         03/09/2024  Correcao taxa financ
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_nome              IN VARCHAR2,
  p_num_parcelas      IN VARCHAR2,
  p_coment_parcelas   IN VARCHAR2,
  p_flag_padrao       IN VARCHAR2,
  p_moeda             IN VARCHAR2,
  p_valor_cotacao     IN VARCHAR2,
  p_data_cotacao      IN VARCHAR2,
  p_flag_comissao     IN VARCHAR2,
  p_prazo_pagamento   IN VARCHAR2,
  p_cond_pagamento    IN VARCHAR2,
  p_briefing          IN CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_valor_oportun   oportunidade.valor_oportun%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_num_cenario     cenario.num_cenario%TYPE;
  --
  v_num_parcelas        cenario.num_parcelas%TYPE;
  v_num_parcelas_old    cenario.num_parcelas%TYPE;
  v_valor_cotacao       cenario.valor_cotacao%TYPE;
  v_data_cotacao        cenario.data_cotacao%TYPE;
  v_prazo_pagamento     cenario.prazo_pagamento%TYPE;
  v_prazo_pagamento_old cenario.prazo_pagamento%TYPE;
  v_cond_pagamento      cenario.cond_pagamento%TYPE;
  v_cond_pagamento_old  cenario.cond_pagamento%TYPE;
  v_flag_comissao_old   cenario.flag_comissao_venda%TYPE;
  v_taxa                cenario_servico.taxa%TYPE;
  v_flag_padrao_old     cenario.flag_padrao%TYPE;
  --
  /*
  CURSOR c_taxa_financ IS
   SELECT dias_a_partir,
          percentual
     FROM taxa_financ
    ORDER BY dias_a_partir;
  */
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(oportunidade_id),
         MAX(num_cenario)
    INTO v_oportunidade_id,
         v_num_cenario
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_oportunidade_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = v_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --ACLBO_270723
  consistir_cenario(p_usuario_sessao_id,
                    p_empresa_id,
                    p_preco_id,
                    'BD',
                    0,
                    p_nome,
                    p_num_parcelas,
                    p_coment_parcelas,
                    'S',
                    p_moeda,
                    p_valor_cotacao,
                    p_data_cotacao,
                    p_flag_comissao,
                    p_prazo_pagamento,
                    p_cond_pagamento,
                    p_erro_cod,
                    p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_num_parcelas    := numero_converter(p_num_parcelas);
  v_valor_cotacao   := numero_converter(p_valor_cotacao);
  v_data_cotacao    := data_converter(p_data_cotacao);
  v_prazo_pagamento := numero_converter(p_prazo_pagamento);
  v_cond_pagamento  := numero_converter(p_cond_pagamento);
  --
  SELECT cond_pagamento,
         prazo_pagamento,
         num_parcelas,
         flag_comissao_venda,
         flag_padrao
    INTO v_cond_pagamento_old,
         v_prazo_pagamento_old,
         v_num_parcelas_old,
         v_flag_comissao_old,
         v_flag_padrao_old
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S'
  THEN
   -- desmarca cenarios anteriores
   UPDATE cenario
      SET flag_padrao = 'N'
    WHERE oportunidade_id = v_oportunidade_id;
  
   UPDATE cenario
      SET flag_padrao = 'S'
    WHERE cenario_id = p_cenario_id;
  
   SELECT nvl(SUM(preco_final), 0)
     INTO v_valor_oportun
     FROM cenario_servico
    WHERE cenario_id = p_cenario_id;
  
   UPDATE oportunidade
      SET valor_oportun = v_valor_oportun
    WHERE oportunidade_id = v_oportunidade_id;
  
  END IF;
  --
  UPDATE cenario
     SET nome                = TRIM(p_nome),
         flag_padrao         = p_flag_padrao,
         num_parcelas        = v_num_parcelas,
         coment_parcelas     = TRIM(p_coment_parcelas),
         moeda               = p_moeda,
         valor_cotacao       = v_valor_cotacao,
         data_cotacao        = v_data_cotacao,
         flag_comissao_venda = p_flag_comissao,
         prazo_pagamento     = v_prazo_pagamento,
         briefing            = p_briefing,
         cond_pagamento      = v_cond_pagamento
   WHERE cenario_id = p_cenario_id;
  --ALCBO_280624
  IF p_flag_padrao = 'N'
  THEN
   SELECT COUNT(flag_padrao)
     INTO v_qt
     FROM cenario
    WHERE oportunidade_id = v_oportunidade_id
      AND flag_padrao = 'S';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário tem pelo menos um Cenário Padrão.';
    RAISE v_exception;
    --
    UPDATE cenario
       SET flag_padrao = 'S'
     WHERE cenario_id = p_cenario_id;
   
   END IF;
  
  END IF;
  --ALBO_110923
  /*
    IF (v_cond_pagamento <> v_cond_pagamento_old) THEN
      FOR r_taxa_financ IN c_taxa_financ LOOP
        IF v_cond_pagamento >= r_taxa_financ.dias_a_partir THEN
          v_taxa := r_taxa_financ.percentual;
        END IF;
      END LOOP;
  */
  --
  IF (v_prazo_pagamento <> v_prazo_pagamento_old)
  THEN
   /*
   FOR r_taxa_financ IN c_taxa_financ
   LOOP
    IF v_prazo_pagamento >= r_taxa_financ.dias_a_partir THEN
     v_taxa := r_taxa_financ.percentual;
    END IF;
   END LOOP;
   */
   --ALCBO_030924
   SELECT coalesce(MAX(round(percentual, 1)), 0)
     INTO v_taxa
     FROM taxa_financ
    WHERE dias_a_partir <= v_prazo_pagamento;
   --
   UPDATE cenario_servico
      SET taxa = v_taxa
    WHERE cenario_id = p_cenario_id;
  
  END IF;
 
  IF (v_cond_pagamento <> v_cond_pagamento_old) OR (v_prazo_pagamento <> v_prazo_pagamento_old) OR
     (v_num_parcelas <> v_num_parcelas_old) OR (p_flag_comissao <> v_flag_comissao_old) OR
     (p_flag_padrao <> v_flag_padrao_old)
  THEN
   cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_cenario_id,
                                  p_erro_cod,
                                  p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  --v_identif_objeto := TO_CHAR(v_numero_oport) || '/' || to_char(v_num_cenario);
  v_identif_objeto := to_char(v_num_cenario);
  v_compl_histor   := 'Alteração de Cenário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cenario_id,
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
 END cenario_atualizar;
 --
 --
 PROCEDURE cenario_duplicar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 01/08/2023
  -- DESCRICAO: Duplica um cenario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         12/09/2023  Adicao duplicidade de horas e itens e ajuste duplicar
  -- Ana Luiza         13/09/2023  Duplicacao de cenario_servico e tabelas filhas
  -- Ana Luiza         03/04/2024  Adicao do parametro overhead
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_preco_id          IN tab_preco.preco_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_nome                cenario.nome%TYPE;
  v_num_parcelas        cenario.num_parcelas%TYPE;
  v_coment_parcelas     cenario.coment_parcelas%TYPE;
  v_flag_padrao         cenario.flag_padrao%TYPE;
  v_moeda               cenario.moeda%TYPE;
  v_valor_cotacao       cenario.valor_cotacao%TYPE;
  v_data_cotacao        cenario.data_cotacao%TYPE;
  v_briefing            cenario.briefing%TYPE;
  v_flag_comissao_venda cenario.flag_comissao_venda%TYPE;
  v_data_prazo          cenario.data_prazo%TYPE;
  v_valor               cenario.valor%TYPE;
  v_status_margem       cenario.status_margem%TYPE;
  v_prazo_pagamento     cenario.prazo_pagamento%TYPE;
  --
  v_num_cenario cenario.num_cenario%TYPE;
  --
  v_perc_imposto_precif cenario.perc_imposto_precif%TYPE;
  v_data_prazo_aprov    cenario.data_prazo_aprov%TYPE;
  v_cond_pagamento      cenario.cond_pagamento%TYPE;
  v_cenario_novo_id     cenario.cenario_id%TYPE;
  --ALCBO_030424
  v_perc_honor cenario.perc_overhead%TYPE;
 BEGIN
  v_qt := 0;
  ----------------------------------------------------------------------------------------
  --Verificacao de seguranca
  ----------------------------------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CENA_C',
                                p_oportunidade_id,
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
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Oportunidade não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cenario_id)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(preco_id)
    INTO v_qt
    FROM cenario
   WHERE preco_id = p_preco_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Rate Card não existe.';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT nome,
         num_parcelas,
         coment_parcelas,
         flag_padrao,
         moeda,
         valor_cotacao,
         data_cotacao,
         briefing,
         flag_comissao_venda,
         data_prazo,
         valor,
         status_margem,
         prazo_pagamento,
         perc_imposto_precif,
         data_prazo_aprov,
         cond_pagamento,
         perc_overhead
    INTO v_nome,
         v_num_parcelas,
         v_coment_parcelas,
         v_flag_padrao,
         v_moeda,
         v_valor_cotacao,
         v_data_cotacao,
         v_briefing,
         v_flag_comissao_venda,
         v_data_prazo,
         v_valor,
         v_status_margem,
         v_prazo_pagamento,
         v_perc_imposto_precif,
         v_data_prazo_aprov,
         v_cond_pagamento,
         v_perc_honor
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  SELECT nvl(MAX(num_cenario), 0) + 1
    INTO v_num_cenario
    FROM cenario
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_flag_padrao = 'S'
  THEN
   FOR aux IN (SELECT cenario_id
                 FROM cenario
                WHERE flag_padrao = 'S'
                  AND oportunidade_id = p_oportunidade_id)
   LOOP
    UPDATE cenario
       SET flag_padrao = 'N'
     WHERE cenario_id = aux.cenario_id;
   
   END LOOP;
   --
  END IF;
  --
  v_cenario_novo_id := seq_cenario.nextval;
  --
  INSERT INTO cenario
   (cenario_id,
    oportunidade_id,
    num_cenario,
    nome,
    data_entrada,
    num_parcelas,
    coment_parcelas,
    flag_padrao,
    moeda,
    valor_cotacao,
    data_cotacao,
    briefing,
    flag_comissao_venda,
    data_prazo,
    status,
    valor,
    status_margem,
    prazo_pagamento,
    perc_imposto_precif,
    data_prazo_aprov,
    preco_id,
    status_aprov_rc,
    cond_pagamento,
    perc_overhead)
  VALUES
   (v_cenario_novo_id,
    p_oportunidade_id,
    v_num_cenario,
    v_nome,
    SYSDATE,
    v_num_parcelas,
    v_coment_parcelas,
    v_flag_padrao,
    v_moeda,
    v_valor_cotacao,
    v_data_cotacao,
    v_briefing,
    v_flag_comissao_venda,
    v_data_prazo,
    'PREP',
    v_valor,
    v_status_margem,
    v_prazo_pagamento,
    v_perc_imposto_precif,
    v_data_prazo_aprov,
    p_preco_id,
    'NA',
    v_cond_pagamento,
    v_perc_honor);
  --
  --
  SELECT MAX(cenario_servico_id)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt IS NOT NULL
  THEN
   FOR r_cs IN (SELECT cenario_servico_id
                  FROM cenario_servico
                 WHERE cenario_id = p_cenario_id)
   LOOP
    cenario_pkg.cenario_servico_duplicar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_cenario_novo_id,
                                         r_cs.cenario_servico_id,
                                         'N',
                                         p_erro_cod,
                                         p_erro_msg);
   
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP; --FIM CENARIO_SERVICO
  END IF;
  --
  ------------------------------------------------------------
  -- recalcula cenario
  ------------------------------------------------------------
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  --instancia modalidades de contratação para indicação em ITENS relacionados ao cenario_servico
  INSERT INTO cenario_mod_contr
   (cenario_mod_contr_id,
    cenario_id,
    ordem,
    codigo,
    descricao,
    flag_margem,
    flag_honor,
    flag_encargo,
    flag_imposto,
    tipo_item_codigo)
   SELECT seq_cenario_mod_contr.nextval,
          v_cenario_novo_id,
          ordem,
          codigo,
          descricao,
          flag_margem,
          flag_honor,
          flag_encargo,
          flag_imposto,
          tipo_item_codigo
     FROM modal_contratacao
    WHERE empresa_id = p_empresa_id;
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
 END;
 --
 --
 PROCEDURE cenario_padrao_marcar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Marca CENARIO como padrao
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_xml_atual       CLOB;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_num_cenario     cenario.num_cenario%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(oportunidade_id),
         MAX(num_cenario)
    INTO v_oportunidade_id,
         v_num_cenario
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_oportunidade_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status
    INTO v_numero_oport,
         v_status_oport
    FROM oportunidade op
   WHERE op.oportunidade_id = v_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualização do banco
  ------------------------------------------------------------
  -- desmarca cenarios anteriores
  UPDATE cenario
     SET flag_padrao = 'N'
   WHERE oportunidade_id = v_oportunidade_id;
  --
  UPDATE cenario
     SET flag_padrao = 'S'
   WHERE cenario_id = p_cenario_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- recalcula cenario
  ------------------------------------------------------------
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport || '/' || to_char(v_num_cenario);
  v_compl_histor   := 'Alteração de Cenário Padrão';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
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
 END cenario_padrao_marcar;
 --
 --
 PROCEDURE cenario_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2019
  -- DESCRICAO: Exclusao de CENARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_numero_oport         oportunidade.numero%TYPE;
  v_status_oport         oportunidade.status%TYPE;
  v_cenario_escolhido_id oportunidade.cenario_escolhido_id%TYPE;
  v_valor_oportun        oportunidade.valor_oportun%TYPE;
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
  v_oportunidade_id      oportunidade.oportunidade_id%TYPE;
  v_num_cenario          cenario.num_cenario%TYPE;
  v_flag_padrao          cenario.flag_padrao%TYPE;
  v_num_max_cenario      cenario.num_cenario%TYPE;
  v_cenario_pdr_id       cenario.cenario_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe. ';
   RAISE v_exception;
  END IF;
  --
  SELECT oportunidade_id,
         num_cenario,
         flag_padrao
    INTO v_oportunidade_id,
         v_num_cenario,
         v_flag_padrao
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.numero,
         op.status,
         op.cenario_escolhido_id
    INTO v_numero_oport,
         v_status_oport,
         v_cenario_escolhido_id
    FROM oportunidade op
   WHERE op.oportunidade_id = v_oportunidade_id;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_cenario_id = v_cenario_escolhido_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário está marcado como o Cenário escolhido da Oportuniade.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos associados a esse Cenário.';
   RAISE v_exception;
  END IF;
  --
  v_cenario_pdr_id := NULL;
  --
  IF v_flag_padrao = 'S'
  THEN
   -- o cenario padrao esta sendo excluiodo.
   -- procura o maior cenario restante para ser o padrao.
   SELECT MAX(num_cenario)
     INTO v_num_max_cenario
     FROM cenario
    WHERE oportunidade_id = v_oportunidade_id
      AND cenario_id <> p_cenario_id;
   --
   IF v_num_max_cenario IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existe outro Cenário que possa ser o cenário padrão.';
    RAISE v_exception;
   END IF;
   --
   SELECT cenario_id
     INTO v_cenario_pdr_id
     FROM cenario
    WHERE oportunidade_id = v_oportunidade_id
      AND num_cenario = v_num_max_cenario;
   --
   SELECT nvl(SUM(preco_final), 0)
     INTO v_valor_oportun
     FROM cenario_servico
    WHERE cenario_id = v_cenario_pdr_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM cenario_servico
   WHERE cenario_id = p_cenario_id;
 
  DELETE FROM cenario_empresa
   WHERE cenario_id = p_cenario_id;
 
  DELETE FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_cenario_pdr_id IS NOT NULL
  THEN
   UPDATE cenario
      SET flag_padrao = 'S'
    WHERE cenario_id = v_cenario_pdr_id;
   --
   UPDATE oportunidade
      SET valor_oportun = v_valor_oportun
    WHERE oportunidade_id = v_oportunidade_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --oportunidade_pkg.xml_gerar(v_oportunidade_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_oport || '/' || to_char(v_num_cenario);
  v_compl_histor   := 'Exclusão de Cenário';
  --ALCBO_190923
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'EXCLUIR',
                   v_identif_objeto,
                   v_oportunidade_id,
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
 END cenario_excluir;
 --
 --
 PROCEDURE cenario_recalcular
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                   ProcessMind     DATA: 28/08/2023
  -- DESCRICAO: Recálculo de margem e verificação de cenário dentro da margem
  -- altera cenario.status_margem para um dos valores possíveis
  -- MARGEM_ABAIXO_META
  -- MARGEM_ABAIXO_MIN
  -- MARGEM_OK
  -- PEND
  -- (select * from dicionario where tipo = 'status_margem_cen';)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------    
  -- Ana Luiza         30/08/2023  Parametro de saída para retornar o status_margem
  -- Ana Luiza         06/09/2023  Adicionado multiplicacao para transformar em percentual
  -- Ana Luiza         29/04/2024  Alteracao calculo percentual margem
  -- Ana Luiza         20/05/2024  Ajuste status margem
  -- Joel Dias         23/07/2025  Ajuste nos cálculos do imposto e de margem             
  ---------------- ------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                           INTEGER;
  v_exception                    EXCEPTION;
  v_horas_custo_total            cenario_servico.horas_custo_total%TYPE;
  v_horas_margem_perc            cenario_servico.horas_margem_perc%TYPE;
  v_horas_preco_marg_imp         cenario_servico.horas_preco_marg_imp%TYPE;
  v_horas_preco_desc             cenario_servico.horas_preco_desc%TYPE;
  v_item_custo_total             cenario_servico.item_custo_total%TYPE;
  v_item_margem_perc             cenario_servico.item_margem_perc%TYPE;
  v_item_preco_marg_imp          cenario_servico.item_preco_marg_imp%TYPE;
  v_item_preco_desc              cenario_servico.item_preco_desc%TYPE;
  v_comissao                     cenario_servico.comissao%TYPE;
  v_preco_final                  cenario_servico.preco_final%TYPE;
  v_status_margem                cenario_servico.status_margem%TYPE;
  v_cenario_flag_tem_comissao    cenario.flag_comissao_venda%TYPE;
  v_servico_flag_tem_comissao    servico.flag_tem_comissao%TYPE;
  v_qt_parc_contr_fee_proj       NUMBER(3);
  v_fee_proj                     VARCHAR(10);
  v_cond_pagamento               cenario.cond_pagamento%TYPE;
  v_valor_comissao               comissao.valor_comissao%TYPE;
  v_perc_comissao                comissao.perc_comissao%TYPE;
  v_oport_comis_val_perc         VARCHAR(10);
  v_valor_oportun                oportunidade.valor_oportun%TYPE;
  v_flag_cenario_padrao          cenario.flag_padrao%TYPE;
  v_oportunidade_id              oportunidade.oportunidade_id%TYPE;
  v_perc_imposto_precif          cenario.perc_imposto_precif%TYPE;
  v_horas_imposto                cenario_servico.horas_imposto%TYPE;
  v_horas_receita_liquida        cenario_servico.horas_receita_liquida%TYPE;
  v_horas_valor_margem_final     cenario_servico.horas_valor_margem_final%TYPE;
  v_horas_margem_final           cenario_servico.horas_margem_final%TYPE;
  v_item_imposto                 cenario_servico.item_imposto%TYPE;
  v_item_receita_liquida         cenario_servico.item_receita_liquida%TYPE;
  v_item_valor_margem_final      cenario_servico.item_valor_margem_final%TYPE;
  v_item_margem_final            cenario_servico.item_margem_final%TYPE;
  v_item_custo_imposto_total     cenario_servico.item_imposto%TYPE; --JD_230725
  v_item_honorario_imposto_total cenario_servico.item_imposto%TYPE; --JD_230725
  --
  CURSOR c_cenario_servico IS
   SELECT cenario_servico_id,
          servico_id,
          margem_oper_min,
          margem_oper_meta
     FROM cenario_servico
    WHERE cenario_id = p_cenario_id;
  --
  CURSOR c_comissao IS
   SELECT valor_a_partir,
          valor_comissao,
          perc_comissao,
          tipo_fee_projeto
     FROM comissao
    ORDER BY valor_a_partir;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --verificar se o cenário tem comissão SIM
  --recuperar condição de pagamento, percentual de imposto
  --verificar se o cenário é padrão para atualizar o valor da Oportunidade
  SELECT flag_comissao_venda,
         cond_pagamento,
         flag_padrao,
         perc_imposto_precif
    INTO v_cenario_flag_tem_comissao,
         v_cond_pagamento,
         v_flag_cenario_padrao,
         v_perc_imposto_precif
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --processar e atualizar servico a servico do cenário
  FOR r_cenario_servico IN c_cenario_servico
  LOOP
   v_status_margem := 'PEND';
   --CARGOS ou EQUIPE
   SELECT COUNT(*),
          nvl(SUM(h.custo_total), 0),
          nvl(SUM(h.preco_venda), 0),
          nvl(SUM(h.preco_final), 0)
     INTO v_qt,
          v_horas_custo_total,
          v_horas_preco_marg_imp,
          v_horas_preco_desc
     FROM cenario_servico_horas h
    INNER JOIN cenario_servico s
       ON s.cenario_servico_id = h.cenario_servico_id
    WHERE s.cenario_servico_id = r_cenario_servico.cenario_servico_id;
   IF v_qt > 0
   THEN
    v_horas_imposto            := round(v_horas_preco_desc * v_perc_imposto_precif / 100, 2);
    v_horas_receita_liquida    := v_horas_preco_desc - v_horas_imposto;
    v_horas_valor_margem_final := v_horas_receita_liquida - v_horas_custo_total;
    IF v_horas_receita_liquida <> 0
    THEN
     v_horas_margem_final := round(v_horas_valor_margem_final / v_horas_receita_liquida * 100, 2);
    ELSE
     v_horas_margem_final := 0;
    END IF;
    IF v_horas_preco_marg_imp <> 0 AND v_horas_receita_liquida <> 0
    THEN
     v_horas_margem_perc := round(v_horas_valor_margem_final / v_horas_receita_liquida * 100, 2);
    ELSE
     IF v_horas_custo_total <> 0
     THEN
      v_horas_margem_perc := -100;
     ELSE
      v_horas_margem_perc := 0;
     END IF;
    END IF;
   ELSE
    v_horas_custo_total        := 0;
    v_horas_margem_perc        := 0;
    v_horas_preco_marg_imp     := 0;
    v_horas_preco_desc         := 0;
    v_horas_imposto            := 0;
    v_horas_receita_liquida    := 0;
    v_horas_valor_margem_final := 0;
    v_horas_margem_final       := 0;
   END IF;
   --ITENS
   SELECT COUNT(*) AS contagem,
          nvl(SUM(i.custo_total), 0),
          nvl(SUM(i.preco_venda), 0),
          nvl(SUM(i.preco_final), 0)
     INTO v_qt,
          v_item_custo_total,
          v_item_preco_marg_imp,
          v_item_preco_desc
     FROM cenario_servico_item i
    INNER JOIN cenario_servico c
       ON c.cenario_servico_id = i.cenario_servico_id
    WHERE i.cenario_servico_id = r_cenario_servico.cenario_servico_id;
   --JD_230725
   SELECT nvl(SUM(i.custo_total), 0)
     INTO v_item_custo_imposto_total
     FROM cenario_servico_item i
    INNER JOIN cenario_servico c
       ON c.cenario_servico_id = i.cenario_servico_id
    INNER JOIN cenario_mod_contr m
       ON m.cenario_id = c.cenario_id
      AND i.mod_contr = m.codigo
    WHERE i.cenario_servico_id = r_cenario_servico.cenario_servico_id
      AND m.flag_imposto = 'S';
   --JD_230725     
   SELECT nvl(SUM(i.honorarios), 0)
     INTO v_item_honorario_imposto_total
     FROM cenario_servico_item i
    INNER JOIN cenario_servico c
       ON c.cenario_servico_id = i.cenario_servico_id
    INNER JOIN cenario_mod_contr m
       ON m.cenario_id = c.cenario_id
      AND i.mod_contr = m.codigo
    WHERE i.cenario_servico_id = r_cenario_servico.cenario_servico_id
      AND m.tipo_impo_honor IN ('HONOR', 'NORMAL');
   --
   IF v_qt > 0
   THEN
    IF v_item_preco_marg_imp <> 0
    THEN
     v_item_margem_perc := 100 * (1 - (v_item_custo_total / v_item_preco_marg_imp));
    ELSE
     v_item_margem_perc := 0;
    END IF;
    --JD_230725(item_imposto antes modificação) 
    --v_item_imposto            := round(v_item_preco_desc * v_perc_imposto_precif / 100, 2);
    --
    --JD_230725
    v_item_imposto            := round(((v_item_custo_imposto_total /
                                       (1 - (v_perc_imposto_precif / 100))) -
                                       v_item_custo_imposto_total) +
                                       ((v_item_honorario_imposto_total /
                                       (1 - (v_perc_imposto_precif / 100))) -
                                       v_item_honorario_imposto_total),
                                       2);
    v_item_receita_liquida    := v_item_preco_desc - v_item_imposto - v_item_custo_total;
    v_item_valor_margem_final := v_item_receita_liquida;
    IF v_item_receita_liquida <> 0
    THEN
     v_item_margem_final := round(v_item_valor_margem_final / v_item_custo_total * 100, 2);
    ELSE
     v_item_margem_final := 0;
    END IF;
   ELSE
    v_item_custo_total        := 0;
    v_item_margem_perc        := 0;
    v_item_preco_marg_imp     := 0;
    v_item_preco_desc         := 0;
    v_item_imposto            := 0;
    v_item_receita_liquida    := 0;
    v_item_valor_margem_final := 0;
    v_item_margem_final       := 0;
   END IF;
   --DEMAIS INFORMAÇÕES DO CENARIO_SERVICO
   --verificar se no cadastro do serviço a comissão está como SIM
   SELECT flag_tem_comissao
     INTO v_servico_flag_tem_comissao
     FROM servico
    WHERE servico_id = r_cenario_servico.servico_id;
   --tratar comissão
   IF v_cenario_flag_tem_comissao = 'S' AND v_servico_flag_tem_comissao = 'S' AND
      (v_horas_preco_desc + v_item_preco_desc) > 0
   THEN
    v_qt_parc_contr_fee_proj := to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'OPORT_QT_PARC_CONTR_FEE_PROJ'));
    v_oport_comis_val_perc   := empresa_pkg.parametro_retornar(p_empresa_id, 'OPORT_COMIS_VAL_PERC');
    --até uma certa quantidade de parcelas definida no parâmetro OPORT_QT_PARC_CONTR_FEE_PROJ
    --o futuro contrato será considerado de projeto, além dessa quantidade,
    --será FEE; isto influencia na comissão que será aplicada, na tabela
    --COMISSAO uma coluna define se é para FEE ou PROJETO
    IF v_cond_pagamento >= v_qt_parc_contr_fee_proj
    THEN
     v_fee_proj := 'FEE';
    ELSE
     v_fee_proj := 'PROJETO';
    END IF;
    --buscar na tabela comussão o percentual e o valor da comissão
    FOR r_comissao IN c_comissao
    LOOP
     IF (v_horas_preco_desc + v_item_preco_desc) > r_comissao.valor_a_partir AND
        r_comissao.tipo_fee_projeto = v_fee_proj
     THEN
      v_valor_comissao := r_comissao.valor_comissao;
      v_perc_comissao  := r_comissao.perc_comissao;
     END IF;
    END LOOP;
    --de acordo com o parâmetro de empresa OPORT_COMIS_VAL_PERC
    --usar o percentual ou o valor da comissao
    IF v_oport_comis_val_perc = 'VALOR'
    THEN
     v_comissao := v_valor_comissao;
     SELECT MAX(valor_comissao)
       INTO v_comissao
       FROM comissao
      WHERE (v_horas_preco_desc + v_item_preco_desc) >= valor_a_partir;
    ELSE
     v_comissao := round((v_horas_preco_desc + v_item_preco_desc) * v_perc_comissao, 2);
    END IF;
   ELSE
    --se no cenário ou no serviço está definido que não há comissão
    v_comissao := 0;
   END IF;
   v_preco_final := v_horas_preco_desc + v_item_preco_desc + v_comissao;
   --define o status da margem do cenario_servico de acordo
   --com margem meta e margem mínima definidas no serviço
   /*ALCBO_200524
   Alterado de v_horas_preco_desc -> v_horas_preco_marg_imp(preco_venda)
   Alterado de v_item_preco_desc -> v_item_preco_marg_imp(prevo_venda_item)
   */
   IF v_horas_preco_marg_imp = 0 AND v_item_preco_marg_imp = 0
   THEN
    v_status_margem := 'PEND';
   ELSIF v_horas_preco_desc = 0 AND v_item_preco_desc > 0
   THEN
    v_status_margem := 'MARGEM_OK';
   ELSIF v_horas_margem_perc > r_cenario_servico.margem_oper_meta
   THEN
    v_status_margem := 'MARGEM_ACIMA';
   ELSIF v_horas_margem_perc = r_cenario_servico.margem_oper_meta
   THEN
    v_status_margem := 'MARGEM_OK';
   ELSIF v_horas_margem_perc > r_cenario_servico.margem_oper_min
   THEN
    v_status_margem := 'MARGEM_ABAIXO_META';
   ELSE
    v_status_margem := 'MARGEM_ABAIXO_MIN';
   END IF;
   --
   --ATUALIZA CENARIO_SERVICO
   UPDATE cenario_servico
      SET horas_custo_total        = v_horas_custo_total,
          horas_margem_perc        = v_horas_margem_perc,
          horas_preco_marg_imp     = v_horas_preco_marg_imp,
          horas_preco_desc         = v_horas_preco_desc,
          item_custo_total         = v_item_custo_total,
          item_margem_perc         = v_item_margem_perc,
          item_preco_marg_imp      = v_item_preco_marg_imp,
          item_preco_desc          = v_item_preco_desc,
          comissao                 = v_comissao,
          preco_final              = v_preco_final,
          status_margem            = v_status_margem,
          horas_imposto            = v_horas_imposto,
          horas_receita_liquida    = v_horas_receita_liquida,
          horas_valor_margem_final = v_horas_valor_margem_final,
          horas_margem_final       = v_horas_margem_final,
          item_imposto             = v_item_imposto,
          item_receita_liquida     = v_item_receita_liquida,
          item_valor_margem_final  = v_item_valor_margem_final,
          item_margem_final        = v_item_margem_final
    WHERE cenario_servico_id = r_cenario_servico.cenario_servico_id;
  END LOOP; --
  --calcular e atualizar o status da margem no cenario
  --se houver ao menos um cenario_servico PEND, então o status do cenario
  --será PEND; se houver ao menos um MARGEM_ABAIXO_MIN, então o cenario
  --será MARGEM_ABAIXO_MIN e assim por diante
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id;
  IF v_qt = 0
  THEN
   v_status_margem := 'PEND';
  ELSE
   SELECT COUNT(*)
     INTO v_qt
     FROM cenario_servico
    WHERE cenario_id = p_cenario_id
      AND status_margem = 'PEND';
   IF v_qt > 0
   THEN
    v_status_margem := 'PEND';
   ELSE
    SELECT COUNT(*)
      INTO v_qt
      FROM cenario_servico
     WHERE cenario_id = p_cenario_id
       AND status_margem = 'MARGEM_ABAIXO_MIN';
    IF v_qt > 0
    THEN
     v_status_margem := 'MARGEM_ABAIXO_MIN';
    ELSE
     SELECT COUNT(*)
       INTO v_qt
       FROM cenario_servico
      WHERE cenario_id = p_cenario_id
        AND status_margem = 'MARGEM_ABAIXO_META';
     IF v_qt > 0
     THEN
      v_status_margem := 'MARGEM_ABAIXO_META';
     ELSE
      SELECT COUNT(*)
        INTO v_qt
        FROM cenario_servico
       WHERE cenario_id = p_cenario_id
         AND status_margem = 'MARGEM_ACIMA';
      IF v_qt > 0
      THEN
       v_status_margem := 'MARGEM_ACIMA';
      ELSE
       v_status_margem := 'MARGEM_OK';
      END IF;
     END IF;
    END IF;
   END IF; --PEND
  END IF; --v_qt = 0
  --atualiza status da margem do cenário
  UPDATE cenario
     SET status_margem = v_status_margem
   WHERE cenario_id = p_cenario_id;
  --atualizar o valor da oportunidade na tabela oportunidade
  --se o cenario que está sendo recalculado for o padrão
  IF v_flag_cenario_padrao = 'S'
  THEN
   SELECT nvl(SUM(v_preco_final), 0)
     INTO v_valor_oportun
     FROM cenario_servico
    WHERE cenario_id = p_cenario_id;
   SELECT oportunidade_id
     INTO v_oportunidade_id
     FROM cenario
    WHERE cenario_id = p_cenario_id;
   UPDATE oportunidade
      SET valor_oportun = v_valor_oportun
    WHERE oportunidade_id = v_oportunidade_id;
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
 END cenario_recalcular;
 --
 --
 PROCEDURE cenario_servico_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/07/2019
  -- DESCRICAO: Inclusao de CENARIO_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         11/06/2023  Alterado condicao para testar prazo_pagamento
  -- Ana Luiza         07/04/2024  Prefixado taxa com base na taxa financ
  -- Ana Luiza         23/04/2024  Ajuste descricao
  -- Ana Luiza         03/09/2024  Correcao taxa financ
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_id         IN cenario.cenario_id%TYPE,
  p_servico_id         IN servico.servico_id%TYPE,
  p_descricao          IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_escopo             IN VARCHAR2,
  p_mes_ano_inicio     IN VARCHAR2,
  p_cenario_servico_id OUT cenario_servico.cenario_servico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
  v_duracao            cenario_servico.duracao_meses%TYPE;
  v_descricao          cenario_servico.descricao%TYPE;
  v_mes_ano_inicio     cenario_servico.mes_ano_inicio%TYPE;
  v_servico_nome       servico.nome%TYPE;
  --v_cond_pagamento                 cenario.cond_pagamento%TYPE;
  v_prazo_pagamento  cenario.prazo_pagamento%TYPE;
  v_taxa             cenario_servico.taxa%TYPE;
  v_margem_oper_meta servico.margem_oper_meta%TYPE;
  v_margem_oper_min  servico.margem_oper_min%TYPE;
  --ALCBO_060923
  v_valor_padrao pessoa_nitem_pdr.valor_padrao%TYPE;
  v_honorario    cenario_servico.honorario%TYPE;
  --
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_origem_honor    cenario_servico.origem_honor%TYPE;
  --
  /*
  CURSOR c_taxa_financ IS
   SELECT dias_a_partir,
          percentual
     FROM taxa_financ
    ORDER BY dias_a_partir;
  */
 BEGIN
  v_qt := 0;
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CENA_C',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM servico
   WHERE servico_id = p_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id
     AND servico_id = p_servico_id
     AND TRIM(descricao) = TRIM(p_descricao);
  --
  IF v_qt <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto já existe para este cenário.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_duracao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo duração é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_duracao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo duração é inválido (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  v_duracao := nvl(to_number(p_duracao), 0);
  --
  IF v_duracao <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo duração é inválido (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mes_ano_inicio) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo mês ano início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_mes_ano_inicio) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mês ano início inválido (' || p_mes_ano_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_escopo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo escopo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_mes_ano_inicio := data_converter('01/' || p_mes_ano_inicio);
  --
  SELECT COUNT(TRIM(descricao))
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id
     AND servico_id = p_servico_id
     AND descricao = TRIM(p_descricao); --ALCBO_230424
  --
  IF v_qt <> 0
  THEN
   SELECT descricao
     INTO v_descricao
     FROM cenario_servico
    WHERE cenario_id = p_cenario_id
      AND servico_id = p_servico_id
      AND descricao = TRIM(p_descricao); --ALCBO_230424
   --
   IF upper(TRIM(v_descricao)) = upper(TRIM(p_descricao))
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe uma descricao de produto para este cenário';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT margem_oper_meta,
         margem_oper_min
    INTO v_margem_oper_meta,
         v_margem_oper_min
    FROM servico
   WHERE servico_id = p_servico_id;
  /*
    SELECT cond_pagamento
      INTO v_cond_pagamento
      FROM cenario
     WHERE cenario_id = p_cenario_id;
    FOR r_taxa_financ IN c_taxa_financ LOOP
      IF v_cond_pagamento >= r_taxa_financ.dias_a_partir THEN
        v_taxa := r_taxa_financ.percentual;
      END IF;
    END LOOP;
  --
  SELECT prazo_pagamento
    INTO v_prazo_pagamento
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --ALCBO_070424 -- valores baseados na taxa financ
  IF v_prazo_pagamento <= 30 THEN
   v_taxa := 5;
  ELSIF v_prazo_pagamento <= 45 THEN
   v_taxa := 7.5;
  ELSIF v_prazo_pagamento <= 60 THEN
   v_taxa := 7.45;
  ELSIF v_prazo_pagamento <= 90 THEN
   v_taxa := 15;
  ELSE
   v_taxa := 0;
  END IF;
  */
  --ALCBO_030924
  -- Obtém o prazo de pagamento baseado no cenario_id fornecido
  SELECT prazo_pagamento
    INTO v_prazo_pagamento
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  -- Obtem a taxa percentual correspondente ao prazo de pagamento
  SELECT coalesce(MAX(round(percentual, 1)), 0)
    INTO v_taxa
    FROM taxa_financ
   WHERE dias_a_partir <= v_prazo_pagamento;
  --
  --ALCBO_060923
  SELECT nvl(MAX(pni.valor_padrao), 0)
    INTO v_valor_padrao
    FROM pessoa_nitem_pdr pni
   INNER JOIN natureza_item ni
      ON pni.natureza_item_id = ni.natureza_item_id
   WHERE pessoa_id IN
         (SELECT cliente_id
            FROM oportunidade
           WHERE oportunidade_id IN (SELECT oportunidade_id
                                       FROM cenario
                                      WHERE cenario_id = p_cenario_id))
     AND ni.codigo = 'HONOR'
     AND ni.empresa_id = p_empresa_id;
  --ALCBO_070424
  IF v_valor_padrao = 0
  THEN
   v_honorario    := empresa_pkg.parametro_retornar(p_empresa_id, 'PERC_HONOR_PRECIF_ITEM');
   v_origem_honor := 'EMPRESA';
  ELSE
   v_honorario    := v_valor_padrao;
   v_origem_honor := 'CLIENTE';
  END IF;
  --
  /*IF 1 = 1 THEN
  
  p_erro_cod := '90000';
    p_erro_msg := v_cenario_servico_id ||'|'||  p_cenario_iD||'|'|| p_servico_id
    ||'|'|| 0 ||'|'|| p_descricao;
    RAISE v_exception;
  
  END IF;
  */
  SELECT seq_cenario_servico.nextval
    INTO v_cenario_servico_id
    FROM dual;
  --
  INSERT INTO cenario_servico
   (cenario_servico_id,
    cenario_id,
    servico_id,
    valor_servico,
    descricao,
    duracao_meses,
    escopo,
    status,
    desc_acres,
    honorario,
    taxa,
    mes_ano_inicio,
    margem_oper_meta,
    margem_oper_min,
    horas_custo_total,
    horas_margem_perc,
    horas_preco_marg_imp,
    horas_preco_desc,
    item_custo_total,
    item_margem_perc,
    item_preco_marg_imp,
    item_preco_desc,
    comissao,
    preco_final,
    status_margem,
    horas_imposto,
    horas_receita_liquida,
    horas_valor_margem_final,
    horas_margem_final,
    item_imposto,
    item_receita_liquida,
    item_valor_margem_final,
    item_margem_final,
    origem_honor)
  VALUES
   (v_cenario_servico_id,
    p_cenario_id,
    p_servico_id,
    0,
    TRIM(p_descricao),
    v_duracao,
    TRIM(p_escopo),
    'PEND',
    0,
    v_honorario,
    v_taxa,
    v_mes_ano_inicio,
    v_margem_oper_meta,
    v_margem_oper_min,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    'PEND',
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    v_origem_honor);
  --
  SELECT nome
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = p_servico_id;
 
  cenario_pkg.cenario_status_alterar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     'N',
                                     p_cenario_id,
                                     'ALTERAR',
                                     '',
                                     'O Produto ' || v_servico_nome || ' foi incluído.',
                                     p_erro_cod,
                                     p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- recalcula cenario
  ------------------------------------------------------------
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cenario_id,
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
  cenario_pkg.xml_gerar(p_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_cenario_servico_id) || '/' || to_char(p_cenario_id);
  v_compl_histor   := 'Inclusão do Produto ' || v_servico_nome || ' no Cenário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'INCLUIR_PROD_CEN',
                   v_identif_objeto,
                   p_cenario_id,
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
  p_cenario_servico_id := v_cenario_servico_id;
  p_erro_cod           := '00000';
  p_erro_msg           := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END cenario_servico_adicionar;
 --
 --
 PROCEDURE cenario_servico_atualizar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/07/2019
  -- DESCRICAO: Atualizacao de CENARIO_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         17/04/2024  Adicionado chamada de recalculo cenario_servico_horas
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_descricao          IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_escopo             IN VARCHAR2,
  p_mes_ano_inicio     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_duracao        cenario_servico.duracao_meses%TYPE;
  v_mes_ano_inicio cenario_servico.mes_ano_inicio%TYPE;
  --
  v_servico_nome servico.nome%TYPE;
  --
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_cenario_id     cenario.cenario_id%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  --ALCBO_170424
  v_desconto    cenario_servico.desc_acres%TYPE;
  v_duracao_old cenario_servico.duracao_meses%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id IN (SELECT cenario_id
                          FROM cenario_servico
                         WHERE cenario_servico_id = p_cenario_servico_id);
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CENA_C',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT nome,
         cenario_id
    INTO v_servico_nome,
         v_cenario_id
    FROM servico se
   INNER JOIN cenario_servico cs
      ON cs.servico_id = se.servico_id
   WHERE cenario_servico_id = p_cenario_servico_id;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(v_cenario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse serviço é inválido para este cenário.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_duracao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo duração é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_duracao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo duração é inválido (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  v_duracao := nvl(to_number(p_duracao), 0);
  --
  IF v_duracao <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo duração é inválido (' || p_duracao || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mes_ano_inicio) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo mês ano início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar('01' || p_mes_ano_inicio) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mês ano início inválido (' || p_mes_ano_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_escopo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'o campo escopo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_mes_ano_inicio := data_converter('01/' || p_mes_ano_inicio);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  --
  --ALCBO_170424
  SELECT duracao_meses
    INTO v_duracao_old
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --ALCBO_170424
  IF v_duracao_old <> v_duracao
  THEN
   --
   SELECT desc_acres
     INTO v_desconto
     FROM cenario_servico
    WHERE cenario_servico_id = p_cenario_servico_id;
   --Caso altere faz recalculo de todos os cenario_horas_servico
   cenario_pkg.cenario_servico_horas_recalcular(p_usuario_sessao_id,
                                                p_empresa_id,
                                                p_cenario_servico_id,
                                                v_desconto,
                                                v_duracao,
                                                p_erro_cod,
                                                p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_230424
  SELECT COUNT(TRIM(descricao))
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa descrição já existe para esse Produto.';
   RAISE v_exception;
  END IF;
  --
  UPDATE cenario_servico
     SET descricao      = TRIM(p_descricao),
         duracao_meses  = v_duracao,
         escopo         = TRIM(p_escopo),
         mes_ano_inicio = v_mes_ano_inicio
   WHERE cenario_servico_id = p_cenario_servico_id;
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(v_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(p_cenario_servico_id) || '/' || to_char(v_cenario_id);
  v_compl_histor   := 'Alteração do Produto ' || v_servico_nome || ' no Cenário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'ALTERAR_PROD_CEN',
                   v_identif_objeto,
                   v_cenario_id,
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
 END cenario_servico_atualizar;
 --
 --
 PROCEDURE cenario_servico_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/07/2019
  -- DESCRICAO: Excluir de CENARIO_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_cenario_id   cenario.cenario_id%TYPE;
  v_servico_id   servico.servico_id%TYPE;
  v_servico_nome servico.nome%TYPE;
  --
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id IN (SELECT cenario_id
                          FROM cenario_servico
                         WHERE cenario_servico_id = p_cenario_servico_id);
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CENA_C',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(servico_id),
         MAX(cenario_id)
    INTO v_servico_id,
         v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
 
  SELECT MAX(nome)
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  IF v_servico_nome IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nome do Serviço não encontrado';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(v_cenario_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(cenario_servico_id)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
 
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Registro não encontrado';
   RAISE v_exception;
  END IF;
  --
  DELETE FROM cenario_servico_usu
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  DELETE FROM cenario_servico_horas
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  DELETE FROM cenario_servico_item
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  DELETE FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  cenario_status_alterar(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         v_cenario_id,
                         'ALTERAR',
                         '',
                         'O Produto ' || v_servico_nome || ' foi excluído.',
                         p_erro_cod,
                         p_erro_msg);
  --
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  /*
  ATECAO => LEMBRAR DE RECALCULAR TODAS AS MARGENS APOS A ADICAO
  DE UM NOVO PROD STATUS DO CENARIO_ID PAI PARA ELAB
  */
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  cenario_pkg.xml_gerar(v_cenario_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_cenario_servico_id || '/' || v_cenario_id;
  v_compl_histor   := 'Exclusão de Produto ' || v_servico_nome || ' no Cenário';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CENARIO',
                   'EXCLUIR_PROD_CEN',
                   v_identif_objeto,
                   v_cenario_id,
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
 END cenario_servico_excluir;
 --
 --
 PROCEDURE cenario_servico_duplicar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 13/09/2023
  -- DESCRICAO: Duplica um cenario_servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         27/05/2024  Adicao de verificacao da descricao
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_id         IN cenario.cenario_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_cenario_id               cenario_servico.cenario_id%TYPE;
  v_servico_id               cenario_servico.servico_id%TYPE;
  v_valor_servico            cenario_servico.valor_servico%TYPE;
  v_unid_negocio_resp_id     cenario_servico.unid_negocio_resp_id%TYPE;
  v_usuario_resp_id          cenario_servico.usuario_resp_id%TYPE;
  v_descricao                cenario_servico.descricao%TYPE;
  v_duracao_meses            cenario_servico.duracao_meses%TYPE;
  v_escopo                   cenario_servico.escopo%TYPE;
  v_desc_acres               cenario_servico.desc_acres%TYPE;
  v_honorario                cenario_servico.honorario%TYPE;
  v_taxa                     cenario_servico.taxa%TYPE;
  v_margem_oper_min          cenario_servico.margem_oper_min%TYPE;
  v_margem_oper_meta         cenario_servico.margem_oper_meta%TYPE;
  v_origem_honor             cenario_servico.origem_honor%TYPE;
  v_mes_ano_inicio           cenario_servico.mes_ano_inicio%TYPE;
  v_horas_custo_total        cenario_servico.horas_custo_total%TYPE;
  v_horas_margem_perc        cenario_servico.horas_margem_perc%TYPE;
  v_horas_preco_marg_imp     cenario_servico.horas_preco_marg_imp%TYPE;
  v_horas_preco_desc         cenario_servico.horas_preco_desc%TYPE;
  v_item_custo_total         cenario_servico.item_custo_total%TYPE;
  v_item_margem_perc         cenario_servico.item_margem_perc%TYPE;
  v_item_preco_marg_imp      cenario_servico.item_preco_marg_imp%TYPE;
  v_item_preco_desc          cenario_servico.item_preco_desc%TYPE;
  v_comissao                 cenario_servico.comissao%TYPE;
  v_preco_final              cenario_servico.preco_final%TYPE;
  v_horas_imposto            cenario_servico.horas_imposto%TYPE;
  v_horas_receita_liquida    cenario_servico.horas_receita_liquida%TYPE;
  v_horas_valor_margem_final cenario_servico.horas_valor_margem_final%TYPE;
  v_horas_margem_final       cenario_servico.horas_margem_final%TYPE;
  v_item_imposto             cenario_servico.item_imposto%TYPE;
  v_item_receita_liquida     cenario_servico.item_receita_liquida%TYPE;
  v_item_valor_margem_final  cenario_servico.item_valor_margem_final%TYPE;
  v_item_margem_final        cenario_servico.item_margem_final%TYPE;
  v_cenario_servico_id_novo  cenario_servico.cenario_servico_id%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  ----------------------------------------------------------------------------------------
  --Verificacao de seguranca
  ----------------------------------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_CENA_C',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cenario_servico_id)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Cenário Serviço informado não existe';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT servico_id,
         valor_servico,
         unid_negocio_resp_id,
         usuario_resp_id,
         descricao,
         duracao_meses,
         escopo,
         desc_acres,
         honorario,
         taxa,
         margem_oper_min,
         margem_oper_meta,
         origem_honor,
         mes_ano_inicio,
         horas_custo_total,
         horas_margem_perc,
         horas_preco_marg_imp,
         horas_preco_desc,
         item_custo_total,
         item_margem_perc,
         item_preco_marg_imp,
         item_preco_desc,
         comissao,
         preco_final,
         horas_imposto,
         horas_receita_liquida,
         horas_valor_margem_final,
         horas_margem_final,
         item_imposto,
         item_receita_liquida,
         item_valor_margem_final,
         item_margem_final
    INTO v_servico_id,
         v_valor_servico,
         v_unid_negocio_resp_id,
         v_usuario_resp_id,
         v_descricao,
         v_duracao_meses,
         v_escopo,
         v_desc_acres,
         v_honorario,
         v_taxa,
         v_margem_oper_min,
         v_margem_oper_meta,
         v_origem_honor,
         v_mes_ano_inicio,
         v_horas_custo_total,
         v_horas_margem_perc,
         v_horas_preco_marg_imp,
         v_horas_preco_desc,
         v_item_custo_total,
         v_item_margem_perc,
         v_item_preco_marg_imp,
         v_item_preco_desc,
         v_comissao,
         v_preco_final,
         v_horas_imposto,
         v_horas_receita_liquida,
         v_horas_valor_margem_final,
         v_horas_margem_final,
         v_item_imposto,
         v_item_receita_liquida,
         v_item_valor_margem_final,
         v_item_margem_final
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id
     AND servico_id = v_servico_id
     AND descricao = TRIM(v_descricao); --ALCBO_270524
  --ALCBO_270524 ANTES v_qt > 1 | DEPOIS v_qt > 1
  IF v_qt > 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto já existe neste Cenário.';
   RAISE v_exception;
  END IF;
  --
  v_cenario_servico_id_novo := seq_cenario_servico.nextval;
  --
  INSERT INTO cenario_servico
   (cenario_servico_id,
    cenario_id,
    servico_id,
    valor_servico,
    unid_negocio_resp_id,
    usuario_resp_id,
    descricao,
    duracao_meses,
    escopo,
    status,
    desc_acres,
    honorario,
    taxa,
    margem_oper_min,
    margem_oper_meta,
    origem_honor,
    mes_ano_inicio,
    horas_custo_total,
    horas_margem_perc,
    horas_preco_marg_imp,
    horas_preco_desc,
    item_custo_total,
    item_margem_perc,
    item_preco_marg_imp,
    item_preco_desc,
    comissao,
    preco_final,
    status_margem,
    horas_imposto,
    horas_receita_liquida,
    horas_valor_margem_final,
    horas_margem_final,
    item_imposto,
    item_receita_liquida,
    item_valor_margem_final,
    item_margem_final)
  VALUES
   (v_cenario_servico_id_novo,
    p_cenario_id,
    v_servico_id,
    v_valor_servico,
    v_unid_negocio_resp_id,
    v_usuario_resp_id,
    v_descricao,
    v_duracao_meses,
    v_escopo,
    'PEND',
    v_desc_acres,
    v_honorario,
    v_taxa,
    v_margem_oper_min,
    v_margem_oper_meta,
    v_origem_honor,
    v_mes_ano_inicio,
    v_horas_custo_total,
    v_horas_margem_perc,
    v_horas_preco_marg_imp,
    v_horas_preco_desc,
    v_item_custo_total,
    v_item_margem_perc,
    v_item_preco_marg_imp,
    v_item_preco_desc,
    v_comissao,
    v_preco_final,
    'PEND',
    v_horas_imposto,
    v_horas_receita_liquida,
    v_horas_valor_margem_final,
    v_horas_margem_final,
    v_item_imposto,
    v_item_receita_liquida,
    v_item_valor_margem_final,
    v_item_margem_final);
  --
  --
  SELECT MAX(cenario_servico_horas_id)
    INTO v_qt
    FROM cenario_servico_horas
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt IS NOT NULL
  THEN
   FOR r_csh IN (SELECT cenario_servico_horas_id
                   FROM cenario_servico_horas
                  WHERE cenario_servico_id = p_cenario_servico_id)
   LOOP
    cenario_pkg.cenario_servico_horas_duplicar(p_usuario_sessao_id,
                                               p_empresa_id,
                                               r_csh.cenario_servico_horas_id,
                                               v_cenario_servico_id_novo,
                                               'N',
                                               p_erro_cod,
                                               p_erro_msg);
   
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP; --FIM CENARIO_SERVICO_HORA
  END IF;
  --
  SELECT MAX(cenario_servico_item_id)
    INTO v_qt
    FROM cenario_servico_item
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt IS NOT NULL
  THEN
   FOR r_csi IN (SELECT cenario_servico_item_id
                   FROM cenario_servico_item
                  WHERE cenario_servico_id = p_cenario_servico_id)
   LOOP
    cenario_pkg.cenario_servico_item_duplicar(p_usuario_sessao_id,
                                              p_empresa_id,
                                              r_csi.cenario_servico_item_id,
                                              v_cenario_servico_id_novo,
                                              'N',
                                              p_erro_cod,
                                              p_erro_msg);
   
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP; --FIM CENARIO_SERVICO_ITEM
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
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
 --
 PROCEDURE cenario_servico_horas_recalcular
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 18/08/2023
  -- DESCRICAO: Recalculo desconto/acréscimo horas cargo
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         12/04/2024  Alteracao tipo campo, para aceitar mais decimais
  -- Ana Luiza         17/04/2024  Adicionado calculo do custo
  -- Rafael            23/05/2025  Tratamento para que a variavel V_preco_venda não seja null
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_desconto           IN VARCHAR2,
  p_duracao            IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_cenario_id cenario.cenario_id%TYPE;
  --
  v_desconto cenario_servico.desc_acres%TYPE; --ALCBO_120424
  --ALCBO_030424
  v_perc_overhead cenario.perc_overhead%TYPE;
  v_overhead      cenario_servico_horas.overhead%TYPE;
  v_custo         cenario_servico_horas.custo%TYPE;
  v_custo_total   cenario_servico_horas.custo_total%TYPE;
  --
  v_perc_imposto_precif cenario.perc_imposto_precif%TYPE;
  v_margem_oper_meta    cenario_servico.margem_oper_meta%TYPE;
  v_preco_venda         cenario_servico_horas.preco_venda%TYPE;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORT_PRECIF_CARGO_ALTERAR',
                                p_cenario_servico_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- validação entrada
  ------------------------------------------------------------
  IF numero_validar(p_desconto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo desconto é inválido (' || p_desconto || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualização
  ------------------------------------------------------------
  v_desconto := numero_converter(nvl(p_desconto, 0));
  --
  SELECT cenario_id,
         margem_oper_meta
    INTO v_cenario_id,
         v_margem_oper_meta
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  SELECT perc_overhead,
         perc_imposto_precif
    INTO v_perc_overhead,
         v_perc_imposto_precif
    FROM cenario
   WHERE cenario_id = v_cenario_id;
  --
  UPDATE cenario_servico
     SET desc_acres = v_desconto
   WHERE cenario_servico_id = p_cenario_servico_id;
  --trabalhando com porcentagem
  --v_desconto            := (v_desconto / 100);
  --v_margem_oper_meta    := (v_margem_oper_meta / 100);
  --v_perc_imposto_precif := (v_perc_imposto_precif / 100);
  --ALCBO_030424
  FOR aux IN (SELECT cenario_servico_horas_id,
                     hora_mes, --ALCBO_170424
                     custo_hora --ALCBO_170424
                FROM cenario_servico_horas
               WHERE cenario_servico_id = p_cenario_servico_id)
  LOOP
   v_custo := aux.hora_mes * p_duracao * aux.custo_hora; --ALCBO_170424
   IF v_perc_overhead = 0
   THEN
    v_overhead    := 0;
    v_custo_total := v_custo;
   ELSE
    v_overhead    := v_custo * round((v_perc_overhead / 100), 2);
    v_custo_total := v_custo + v_overhead;
   END IF;
   --
   IF v_margem_oper_meta = 100
   THEN
    v_preco_venda := 0;
   ELSE
    v_preco_venda := round(v_custo_total / (1 - (v_margem_oper_meta / 100)) /
                           (1 - (v_perc_imposto_precif / 100)),
                           2);
   END IF;
   --
   IF v_preco_venda IS NULL
   THEN
    v_preco_venda := 0;
   END IF;
   --
   --RP_230525 Tratamento para que a variavel V_preco_venda não seja null
   IF v_preco_venda IS NULL
   THEN
    v_preco_venda := 0;
   END IF;
   --
   --ALCBO_030424
   UPDATE cenario_servico_horas
      SET preco_final =
          (v_preco_venda * (1 + (v_desconto / 100))),
          overhead     = v_overhead,
          custo_total  = v_custo_total,
          custo        = v_custo,
          horas_totais = aux.hora_mes * p_duracao,
          preco_venda  = v_preco_venda
    WHERE cenario_servico_id = p_cenario_servico_id
      AND cenario_servico_horas_id = aux.cenario_servico_horas_id;
  
  END LOOP;
  --
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
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
 END cenario_servico_horas_recalcular;
 --
 --
 PROCEDURE cenario_servico_horas_adicionar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Adicionar cenario_servico_horas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         06/11/2023  Ajustado variavel horas_mes
  -- Ana Luiza         04/12/2023  Ajuste comentário erro
  -- Ana Luiaz         03/04/2024  Adicao colunas custo e overhead
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_area_id            IN area.area_id%TYPE,
  p_cargo_id           IN cargo.cargo_id%TYPE,
  p_nivel              IN VARCHAR2,
  p_nome_alternativo   IN VARCHAR2,
  p_hora_mes           IN VARCHAR2,
  p_horas_totais       IN VARCHAR2,
  p_custo_hora         IN VARCHAR2,
  p_custo_total        IN VARCHAR2,
  p_preco_venda        IN VARCHAR2,
  p_preco_final        IN VARCHAR2,
  p_custo              IN VARCHAR2,
  p_overhead           IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_horas_totais    cenario_servico_horas.horas_totais%TYPE;
  v_custo_hora      cenario_servico_horas.custo_hora%TYPE;
  v_custo_total     cenario_servico_horas.custo_total%TYPE;
  v_preco_venda     cenario_servico_horas.preco_venda%TYPE;
  v_preco_final     cenario_servico_horas.preco_final%TYPE;
  v_cargo_nome      cargo.nome%TYPE;
  v_servico_id      servico.servico_id%TYPE;
  v_servico_nome    servico.nome%TYPE;
  v_cenario_id      cenario.cenario_id%TYPE;
  --ALCBO_061123
  v_hora_mes cenario_servico_horas.hora_mes%TYPE;
  --ALCBO_030424
  v_custo    cenario_servico_horas.custo%TYPE;
  v_overhead cenario_servico_horas.overhead%TYPE;
 BEGIN
  /*
  IF 1 = 1 THEN
   p_erro_cod := '90000';
   p_erro_msg :='p_hora_mes: '||
   p_hora_mes ||' p_horas_totais: '||
   p_horas_totais ||' p_custo_hora: '||
   p_custo_hora|| ' p_custo_total: '||
   p_custo_total || ' p_preco_venda: '||
   p_preco_venda|| ' p_preco_final:' ||
   p_preco_final;
   RAISE v_exception;
  END IF;
  */
  v_qt := 0;
  --
  SELECT MAX(oportunidade_id)
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id IN (SELECT cenario_id
                          FROM cenario_servico
                         WHERE cenario_servico_id = p_cenario_servico_id);
  --
  IF v_oportunidade_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe horas vinculadas à esta oportunidade.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORT_PRECIF_CARGO_ALTERAR',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --ALCBO_041223
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Area/Cargo/Nível é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cargo_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Cargo é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nivel) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Nivel é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_mes) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Horas mês é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_horas_totais) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas Totais é inválido ' || p_horas_totais || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_hora) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo Hora é inválido ' || p_custo_hora || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_venda) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço Venda é inválido ' || p_preco_venda || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_final) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço Final é inválido ' || p_preco_final || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_horas
   WHERE nivel = TRIM(p_nivel)
     AND cenario_servico_id = p_cenario_servico_id
     AND cargo_id = p_cargo_id;
  --
  IF v_qt <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cargo já foi inserido para este nível';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------------
  --Funcao de calculo será adicionada aqui e fará calculo de valores
  ------------------------------------------------------------------
  v_horas_totais := nvl(numero_converter(p_horas_totais), 0);
  v_custo_hora   := nvl(numero_converter(p_custo_hora), 0);
  v_custo_total  := nvl(numero_converter(p_custo_total), 0);
  v_preco_venda  := nvl(numero_converter(p_preco_venda), 0);
  v_preco_final  := nvl(numero_converter(p_preco_final), 0);
  v_hora_mes     := nvl(numero_converter(p_hora_mes), 0); --ALCBO_061123
  --ALCBO_030424
  v_custo    := nvl(numero_converter(p_custo), 0);
  v_overhead := nvl(numero_converter(p_overhead), 0);
  ---------------------------------------------------------------
  --Gravacao banco de dados
  ---------------------------------------------------------------
  INSERT INTO cenario_servico_horas
   (cenario_servico_horas_id,
    cenario_servico_id,
    area_id,
    cargo_id,
    nivel,
    nome_alternativo,
    hora_mes,
    horas_totais,
    custo_hora,
    custo_total,
    preco_venda,
    preco_final,
    custo,
    overhead)
  VALUES
   (seq_cenario_servico_horas.nextval,
    p_cenario_servico_id,
    p_area_id,
    p_cargo_id,
    p_nivel,
    TRIM(p_nome_alternativo),
    v_hora_mes,
    v_horas_totais,
    v_custo_hora,
    v_custo_total,
    v_preco_venda,
    v_preco_final,
    v_custo,
    v_overhead);
  --
  SELECT nome
    INTO v_cargo_nome
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  SELECT servico_id,
         cenario_id
    INTO v_servico_id,
         v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  SELECT nome
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = v_servico_id;
 
  cenario_servico_status_alterar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 p_cenario_servico_id,
                                 'REFAZER',
                                 NULL,
                                 'Inclusão de Cargo ' || v_cargo_nome || ' no Produto ' ||
                                 v_servico_nome,
                                 p_erro_cod,
                                 p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
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
   --
 END cenario_servico_horas_adicionar;
 --
 --
 PROCEDURE cenario_servico_horas_atualizar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Alterar cenario_servico_horas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         06/11/2023  Ajustado variavel horas_mes
  -- Ana Luiza         04/12/2023  Ajuste comentário erro
  -- Ana Luiaz         03/04/2024  Adicao colunas custo e overhead
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_area_id                  IN area.area_id%TYPE,
  p_cargo_id                 IN cargo.cargo_id%TYPE,
  p_nivel                    IN VARCHAR2,
  p_nome_alternativo         IN VARCHAR2,
  p_hora_mes                 IN VARCHAR2,
  p_horas_totais             IN VARCHAR2,
  p_custo_hora               IN VARCHAR2,
  p_custo_total              IN VARCHAR2,
  p_preco_venda              IN VARCHAR2,
  p_preco_final              IN VARCHAR2,
  p_custo                    IN VARCHAR2,
  p_overhead                 IN VARCHAR2, --ALCBO_030424
  p_erro_cod                 OUT VARCHAR2, --ALCBO_030424
  p_erro_msg                 OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  --
  v_horas_totais       cenario_servico_horas.horas_totais%TYPE;
  v_custo_hora         cenario_servico_horas.custo_hora%TYPE;
  v_custo_total        cenario_servico_horas.custo_total%TYPE;
  v_preco_venda        cenario_servico_horas.preco_venda%TYPE;
  v_preco_final        cenario_servico_horas.preco_final%TYPE;
  v_cargo_nome         cargo.nome%TYPE;
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
  v_servico_id         servico.servico_id%TYPE;
  v_servico_nome       servico.nome%TYPE;
  v_cenario_id         cenario.cenario_id%TYPE;
  --ALCBO_061123
  v_hora_mes cenario_servico_horas.hora_mes%TYPE;
  --ALCBO_030424
  v_custo    cenario_servico_horas.custo%TYPE;
  v_overhead cenario_servico_horas.overhead%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(oportunidade_id)
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id IN
         (SELECT cenario_id
            FROM cenario_servico
           WHERE cenario_servico_id IN
                 (SELECT cenario_servico_id
                    FROM cenario_servico_horas
                   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id));
  --
  IF v_oportunidade_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe horas vinculadas à esta oportunidade.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORT_PRECIF_CARGO_ALTERAR',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --ALCBO_041223
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Area/Cargo/Nível é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cargo_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Cargo é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nivel) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Nivel é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_mes) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Horas mês é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_horas_totais) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas Totais é inválido ' || p_horas_totais || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_hora) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo Hora é inválido ' || p_custo_hora || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_venda) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço Venda é inválido ' || p_preco_venda || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_final) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço Final é inválido ' || p_preco_final || '.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------------
  --Funcao de calculo será adicionada aqui e fará calculo de valores
  ------------------------------------------------------------------
  v_horas_totais := nvl(numero_converter(p_horas_totais), 0);
  v_custo_hora   := nvl(numero_converter(p_custo_hora), 0);
  v_custo_total  := nvl(numero_converter(p_custo_total), 0);
  v_preco_venda  := nvl(numero_converter(p_preco_venda), 0);
  v_preco_final  := nvl(numero_converter(p_preco_final), 0);
  v_hora_mes     := nvl(numero_converter(p_hora_mes), 0); --ALCBO_06112
  --ALCBO_030424
  v_custo    := nvl(numero_converter(p_custo), 0);
  v_overhead := nvl(numero_converter(p_overhead), 0);
  ------------------------------------------------------------------
  --Atualizacao base de dados
  ------------------------------------------------------------------
  --
  UPDATE cenario_servico_horas
     SET area_id          = p_area_id,
         cargo_id         = p_cargo_id,
         nivel            = p_nivel,
         nome_alternativo = TRIM(p_nome_alternativo),
         hora_mes         = v_hora_mes,
         horas_totais     = v_horas_totais,
         custo_hora       = v_custo_hora,
         custo_total      = v_custo_total,
         preco_venda      = v_preco_venda,
         preco_final      = v_preco_final,
         custo            = v_custo,
         overhead         = v_overhead
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  SELECT nome
    INTO v_cargo_nome
    FROM cargo
   WHERE cargo_id = p_cargo_id;
  --
  SELECT cenario_servico_id
    INTO v_cenario_servico_id
    FROM cenario_servico_horas
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  SELECT servico_id,
         cenario_id
    INTO v_servico_id,
         v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = v_cenario_servico_id;
  --
  SELECT nome
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  cenario_servico_status_alterar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 v_cenario_servico_id,
                                 'REFAZER',
                                 NULL,
                                 'Alteração de Cargo ' || v_cargo_nome || ' no Produto ' ||
                                 v_servico_nome,
                                 p_erro_cod,
                                 p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  cenario_recalcular(p_usuario_sessao_id, p_empresa_id, v_cenario_id, p_erro_cod, p_erro_msg);
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
   --
 END cenario_servico_horas_atualizar;
 --
 --
 PROCEDURE cenario_servico_horas_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Excluir cenario_servico_horas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_cenario_id         cenario.cenario_id%TYPE;
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(oportunidade_id)
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id IN
         (SELECT cenario_id
            FROM cenario_servico
           WHERE cenario_servico_id IN
                 (SELECT cenario_servico_id
                    FROM cenario_servico_horas
                   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id));
  --
  IF v_oportunidade_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe horas vinculadas à esta oportunidade.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORT_PRECIF_CARGO_ALTERAR',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(cenario_servico_horas_id)
    INTO v_qt
    FROM cenario_servico_horas
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe horas vinculados à este produto no cenário';
   RAISE v_exception;
  END IF;
  --
  SELECT cenario_servico_id
    INTO v_cenario_servico_id
    FROM cenario_servico_horas
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  DELETE FROM cenario_servico_horas
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  SELECT cenario_id
    INTO v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = v_cenario_servico_id;
  --
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
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
   --
 END cenario_servico_horas_excluir;
 --
 --
 PROCEDURE cenario_servico_horas_duplicar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 13/09/2023
  -- DESCRICAO: Duplica um cenario_servico_horas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         03/04/2024  Adicionado novas colunas overhead e custo
  --------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_horas_id IN cenario_servico_horas.cenario_servico_horas_id%TYPE,
  p_cenario_servico_id       IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit              IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_area_id          cenario_servico_horas.area_id%TYPE;
  v_cargo_id         cenario_servico_horas.cargo_id%TYPE;
  v_custo_hora       cenario_servico_horas.custo_hora%TYPE;
  v_custo_total      cenario_servico_horas.custo_total%TYPE;
  v_horas_totais     cenario_servico_horas.horas_totais%TYPE;
  v_hora_mes         cenario_servico_horas.hora_mes%TYPE;
  v_nivel            cenario_servico_horas.nivel%TYPE;
  v_nome_alternativo cenario_servico_horas.nome_alternativo%TYPE;
  v_preco_final      cenario_servico_horas.preco_final%TYPE;
  v_preco_venda      cenario_servico_horas.preco_venda%TYPE;
  --
  v_custo    cenario_servico_horas.custo%TYPE;
  v_overhead cenario_servico_horas.overhead%TYPE;
 BEGIN
  v_qt := 0;
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT area_id,
         cargo_id,
         custo_hora,
         custo_total,
         horas_totais,
         hora_mes,
         nivel,
         nome_alternativo,
         preco_final,
         preco_venda,
         custo,
         overhead
    INTO v_area_id,
         v_cargo_id,
         v_custo_hora,
         v_custo_total,
         v_horas_totais,
         v_hora_mes,
         v_nivel,
         v_nome_alternativo,
         v_preco_final,
         v_preco_venda,
         v_custo,
         v_overhead
    FROM cenario_servico_horas
   WHERE cenario_servico_horas_id = p_cenario_servico_horas_id;
  --
  --
  INSERT INTO cenario_servico_horas
   (cenario_servico_horas_id,
    cenario_servico_id,
    area_id,
    cargo_id,
    nivel,
    nome_alternativo,
    hora_mes,
    horas_totais,
    custo_hora,
    custo_total,
    preco_venda,
    preco_final)
  VALUES
   (seq_cenario_servico_horas.nextval,
    p_cenario_servico_id,
    v_area_id,
    v_cargo_id,
    v_nivel,
    v_nome_alternativo,
    v_hora_mes,
    v_horas_totais,
    v_custo_hora,
    v_custo_total,
    v_preco_venda,
    v_preco_final);
  --
  --
  IF p_flag_commit = 'S'
  THEN
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
 --
 PROCEDURE cenario_servico_item_adicionar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Incluir cenario_servico_item
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_tipo_produto_id    IN tipo_produto.tipo_produto_id%TYPE,
  p_fornecedor_id      IN pessoa.pessoa_id%TYPE,
  p_complemento        IN VARCHAR2,
  p_custo_unitario     IN VARCHAR2,
  p_quantidade         IN VARCHAR2,
  p_frequencia         IN VARCHAR2,
  p_unidade            IN VARCHAR2,
  p_custo_total        IN VARCHAR2,
  p_honorarios         IN VARCHAR2,
  p_taxas              IN VARCHAR2,
  p_preco_venda        IN VARCHAR2,
  p_preco_final        IN VARCHAR2,
  p_mod_contr          IN VARCHAR2,
  p_honorario_perc     IN VARCHAR2,
  p_taxa_perc          IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_custo_unitario    cenario_servico_item.custo_unitario%TYPE;
  v_quantidade        cenario_servico_item.quantidade%TYPE;
  v_frequencia        cenario_servico_item.frequencia%TYPE;
  v_custo_total       cenario_servico_item.custo_total%TYPE;
  v_honorarios        cenario_servico_item.honorarios%TYPE;
  v_taxas             cenario_servico_item.taxas%TYPE;
  v_preco_venda       cenario_servico_item.preco_venda%TYPE;
  v_preco_final       cenario_servico_item.preco_final%TYPE;
  v_tipo_produto_nome tipo_produto.nome%TYPE;
  v_servico_id        servico.servico_id%TYPE;
  v_servico_nome      servico.nome%TYPE;
  v_cenario_id        cenario.cenario_id%TYPE;
  v_honorario_perc    cenario_servico_item.honorario%TYPE;
  v_taxa_perc         cenario_servico_item.taxa%TYPE;
  --
 BEGIN
  /*
  IF 1 = 1 THEN
   p_erro_cod := '90000';
   p_erro_msg :='p_custo_total: '||
   p_custo_total ||' p_honorarios: '||
   p_honorarios ||' p_taxas: '||
   p_taxas|| ' p_preco_venda: '||
   p_preco_venda || ' p_preco_venda: '||
   p_preco_venda|| ' p_preco_final:' ||
   p_preco_final;
   RAISE v_exception;
  END IF;
  */
  v_qt := 0;
  --
  /*
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id
                               ,'OPORT_PRECIF_CARGO_ALTERAR'
                               ,v_oportunidade_id
                               ,NULL
                               ,p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
  END IF;
  */
  -----------------------------------------------------------------------
  --Teste obrigatoriedade
  -----------------------------------------------------------------------
  IF nvl(p_tipo_produto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Tipo de Entregável é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complemento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Complemento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_custo_unitario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo Unitário é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_quantidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Quantidade é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_frequencia) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Frequência é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_unidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Unidade é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mod_contr) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A modalidade de contração é obrigatória';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------------------
  --Verificacao parametros de entrada
  ------------------------------------------------------------------------
  IF numero_validar(p_custo_unitario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo Unitário é inválido ' || p_custo_unitario || '.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Quantidade é inválido ' || p_quantidade || '.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_frequencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Frequência é inválido ' || p_frequencia || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_total) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo total é inválido ' || p_custo_total || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_honorarios) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Honorários é inválido ' || p_honorarios || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_taxas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Taxas é inválido ' || p_taxas || '.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_honorario_perc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de Honorários é inválido ' || p_honorarios || '.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_taxa_perc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de Taxas é inválido ' || p_taxas || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_venda) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Preço Venda é inválido ' || p_preco_venda || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_final) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Preço Final é inválido ' || p_preco_final || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_item
   WHERE complemento = TRIM(p_complemento)
     AND cenario_servico_id = p_cenario_servico_id
     AND tipo_produto_id = p_tipo_produto_id;
  --
  IF v_qt <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item já foi inserido com o mesmo complemento';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_tipo_produto_nome
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  SELECT servico_id,
         cenario_id
    INTO v_servico_id,
         v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  SELECT nome
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = v_servico_id;
  --
  --
  v_custo_unitario := nvl(numero_converter(p_custo_unitario), 0);
  v_quantidade     := nvl(numero_converter(p_quantidade), 0);
  v_frequencia     := nvl(numero_converter(p_frequencia), 0);
  v_custo_total    := nvl(numero_converter(p_custo_total), 0);
  v_honorarios     := nvl(numero_converter(p_honorarios), 0);
  v_taxas          := nvl(numero_converter(p_taxas), 0);
  v_preco_venda    := nvl(numero_converter(p_preco_venda), 0);
  v_preco_final    := nvl(numero_converter(p_preco_final), 0);
  v_honorario_perc := nvl(taxa_converter(p_honorario_perc), 0);
  v_taxa_perc      := nvl(taxa_converter(p_taxa_perc), 0);
  -------------------------------------------------------------------------
  --Gravacao dos dados
  ---------------------------------------------------------------------------
  INSERT INTO cenario_servico_item
   (cenario_servico_item_id,
    cenario_servico_id,
    tipo_produto_id,
    complemento,
    fornecedor_id,
    custo_unitario,
    quantidade,
    frequencia,
    unidade_freq,
    custo_total,
    honorarios,
    taxas,
    honorario,
    taxa,
    preco_venda,
    preco_final,
    mod_contr)
  VALUES
   (seq_cenario_servico_item.nextval,
    p_cenario_servico_id,
    p_tipo_produto_id,
    TRIM(p_complemento),
    p_fornecedor_id,
    v_custo_unitario,
    v_quantidade,
    v_frequencia,
    TRIM(p_unidade),
    v_custo_total,
    v_honorarios,
    v_taxas,
    v_honorario_perc,
    v_taxa_perc,
    v_preco_venda,
    v_preco_final,
    TRIM(p_mod_contr));
  --
  cenario_servico_status_alterar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 p_cenario_servico_id,
                                 'REFAZER',
                                 NULL,
                                 'Inclusão de Item ' || v_tipo_produto_nome || ' ' || p_complemento ||
                                 ' no Produto ' || v_servico_nome,
                                 p_erro_cod,
                                 p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
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
   --
 END cenario_servico_item_adicionar;
 --
 --
 PROCEDURE cenario_servico_item_atualizar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Alterar cenario_servico_item
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         01/10/2024  Tratamento para so alterar se chaves diferentes
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_tipo_produto_id         IN tipo_produto.tipo_produto_id%TYPE,
  p_fornecedor_id           IN pessoa.pessoa_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_custo_unitario          IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_frequencia              IN VARCHAR2,
  p_unidade                 IN VARCHAR2,
  p_custo_total             IN VARCHAR2,
  p_honorarios              IN VARCHAR2,
  p_taxas                   IN VARCHAR2,
  p_preco_venda             IN VARCHAR2,
  p_preco_final             IN VARCHAR2,
  p_mod_contr               IN VARCHAR2,
  p_honorario_perc          IN VARCHAR2,
  p_taxa_perc               IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_custo_unitario     cenario_servico_item.custo_unitario%TYPE;
  v_quantidade         cenario_servico_item.quantidade%TYPE;
  v_frequencia         cenario_servico_item.frequencia%TYPE;
  v_custo_total        cenario_servico_item.custo_total%TYPE;
  v_honorarios         cenario_servico_item.honorarios%TYPE;
  v_taxas              cenario_servico_item.taxas%TYPE;
  v_preco_venda        cenario_servico_item.preco_venda%TYPE;
  v_preco_final        cenario_servico_item.preco_final%TYPE;
  v_tipo_produto_nome  tipo_produto.nome%TYPE;
  v_servico_id         servico.servico_id%TYPE;
  v_servico_nome       servico.nome%TYPE;
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
  v_cenario_id         cenario.cenario_id%TYPE;
  v_honorario_perc     cenario_servico_item.honorario%TYPE;
  v_taxa_perc          cenario_servico_item.taxa%TYPE;
  --
  v_tipo_produto_id cenario_servico_item.tipo_produto_id%TYPE;
  v_complemento     cenario_servico_item.complemento%TYPE;
 BEGIN
  v_qt := 0;
  --
  /*
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id
                               ,'OPORT_PRECIF_CARGO_ALTERAR'
                               ,v_oportunidade_id
                               ,NULL
                               ,p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
  END IF;
  */
  -----------------------------------------------------------------------
  --Teste obrigatoriedade
  -----------------------------------------------------------------------
  IF nvl(p_tipo_produto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Tipo de Entregável é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complemento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Complemento é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_custo_unitario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo Unitário é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_quantidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Quantidade é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_frequencia) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Frequência é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_unidade) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Unidade é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mod_contr) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A modalidade de contração é obrigatória';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------------------
  --Verificacao parametros de entrada
  ------------------------------------------------------------------------
  IF numero_validar(p_custo_unitario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo Unitário é inválido ' || p_custo_unitario || '.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Quantidade é inválido ' || p_quantidade || '.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_frequencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Frequência é inválido ' || p_frequencia || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_total) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Custo total é inválido ' || p_custo_total || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_honorarios) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Honorários é inválido ' || p_honorarios || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_taxas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Taxas é inválido ' || p_taxas || '.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_honorario_perc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de Honorários é inválido ' || p_honorarios || '.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_taxa_perc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O percentual de Taxas é inválido ' || p_taxas || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_venda) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Preço Venda é inválido ' || p_preco_venda || '.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_preco_final) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Preço Final é inválido ' || p_preco_final || '.';
   RAISE v_exception;
  END IF;
  --
  --
  v_custo_unitario := nvl(numero_converter(p_custo_unitario), 0);
  v_quantidade     := nvl(numero_converter(p_quantidade), 0);
  v_frequencia     := nvl(numero_converter(p_frequencia), 0);
  v_custo_total    := nvl(numero_converter(p_custo_total), 0);
  v_honorarios     := nvl(numero_converter(p_honorarios), 0);
  v_taxas          := nvl(numero_converter(p_taxas), 0);
  v_preco_venda    := nvl(numero_converter(p_preco_venda), 0);
  v_preco_final    := nvl(numero_converter(p_preco_final), 0);
  v_honorario_perc := nvl(taxa_converter(p_honorario_perc), 0);
  v_taxa_perc      := nvl(taxa_converter(p_taxa_perc), 0);
  -------------------------------------------------------------------------
  --Gravacao dos dados
  -------------------------------------------------------------------------
  --ALCBO_011024
  -- Obter os valores atuais da linha
  SELECT tipo_produto_id,
         complemento
    INTO v_tipo_produto_id,
         v_complemento
    FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  -- Verificar se as chaves únicas mudaram
  IF (v_tipo_produto_id != p_tipo_produto_id OR v_complemento != TRIM(p_complemento))
  THEN
   -- Se as chaves mudaram, atualiza todos os campos
   UPDATE cenario_servico_item
      SET tipo_produto_id = p_tipo_produto_id,
          fornecedor_id   = p_fornecedor_id,
          complemento     = TRIM(p_complemento),
          custo_unitario  = v_custo_unitario,
          quantidade      = v_quantidade,
          frequencia      = v_frequencia,
          unidade_freq    = TRIM(p_unidade),
          custo_total     = v_custo_total,
          honorarios      = v_honorarios,
          taxas           = v_taxas,
          honorario       = v_honorario_perc,
          taxa            = v_taxa_perc,
          preco_venda     = v_preco_venda,
          preco_final     = v_preco_final,
          mod_contr       = TRIM(p_mod_contr)
    WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  
  ELSE
   -- Se as chaves não mudaram, atualiza todos os campos, exceto as chaves
   UPDATE cenario_servico_item
      SET fornecedor_id  = p_fornecedor_id,
          custo_unitario = v_custo_unitario,
          quantidade     = v_quantidade,
          frequencia     = v_frequencia,
          unidade_freq   = TRIM(p_unidade),
          custo_total    = v_custo_total,
          honorarios     = v_honorarios,
          taxas          = v_taxas,
          honorario      = v_honorario_perc,
          taxa           = v_taxa_perc,
          preco_venda    = v_preco_venda,
          preco_final    = v_preco_final,
          mod_contr      = TRIM(p_mod_contr)
    WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  
  END IF;
  --
  SELECT nome
    INTO v_tipo_produto_nome
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  SELECT cenario_servico_id
    INTO v_cenario_servico_id
    FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  --
  SELECT servico_id,
         cenario_id
    INTO v_servico_id,
         v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = v_cenario_servico_id;
  --
  SELECT nome
    INTO v_servico_nome
    FROM servico
   WHERE servico_id = v_servico_id;
 
  cenario_servico_status_alterar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 v_cenario_servico_id,
                                 'REFAZER',
                                 NULL,
                                 'Alteração de Item ' || v_tipo_produto_nome || ' ' ||
                                 p_complemento || ' no Produto ' || v_servico_nome,
                                 p_erro_cod,
                                 p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
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
   --
 END cenario_servico_item_atualizar;
 --
 --
 PROCEDURE cenario_servico_item_excluir
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2023
  -- DESCRICAO: Excluir cenario_servico_item
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_cenario_id         cenario.cenario_id%TYPE;
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
 BEGIN
  v_qt := 0;
  SELECT MAX(cenario_servico_item_id)
    INTO v_qt
    FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  --
  IF v_qt IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Item não existe dentro desse cenário.';
   RAISE v_exception;
  END IF;
  --
  SELECT cenario_servico_id
    INTO v_cenario_servico_id
    FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  --
  DELETE FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  --
  SELECT cenario_id
    INTO v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = v_cenario_servico_id;
  --
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
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
 END cenario_servico_item_excluir;
 --
 --
 PROCEDURE cenario_servico_item_recalcular
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 22/08/2023
  -- DESCRICAO: Recalculo honorários itens
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_honorario          IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_honorario           cenario_servico.honorario%TYPE;
  v_taxa                cenario_servico.taxa%TYPE;
  v_margem_oper_meta    cenario_servico.margem_oper_meta%TYPE;
  v_cenario_id          cenario.cenario_id%TYPE;
  v_flag_margem         cenario_mod_contr.flag_margem%TYPE;
  v_flag_honor          cenario_mod_contr.flag_honor%TYPE;
  v_flag_encargo        cenario_mod_contr.flag_encargo%TYPE;
  v_flag_imposto        cenario_mod_contr.flag_imposto%TYPE;
  v_perc_imposto_precif cenario.perc_imposto_precif%TYPE;
  --
  v_custo_total cenario_servico_item.custo_total%TYPE;
  v_custo_hono  cenario_servico_item.honorarios%TYPE;
  v_custo_taxa  cenario_servico_item.taxas%TYPE;
  v_preco_venda cenario_servico_item.preco_venda%TYPE;
  --
  CURSOR c_item IS
   SELECT cenario_servico_item_id,
          mod_contr
     FROM cenario_servico_item
    WHERE cenario_servico_id = p_cenario_servico_id;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORT_PRECIF_ITENS_ALTERAR',
                                p_cenario_servico_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- validação entrada
  ------------------------------------------------------------
  IF numero_validar(p_honorario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo honorário é inválido (' || p_honorario || ').';
   RAISE v_exception;
  END IF;
  --
  v_honorario := numero_converter(nvl(p_honorario, 0));
  --
  SELECT cenario_id
    INTO v_cenario_id
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  UPDATE cenario_servico
     SET honorario    = v_honorario,
         origem_honor = 'USUÁRIO'
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  FOR r_item IN c_item
  LOOP
   --
   SELECT flag_margem,
          flag_honor,
          flag_encargo,
          flag_imposto
     INTO v_flag_margem,
          v_flag_honor,
          v_flag_encargo,
          v_flag_imposto
     FROM cenario_mod_contr
    WHERE cenario_id = v_cenario_id
      AND codigo = r_item.mod_contr;
   --
   --
   SELECT nvl(perc_imposto_precif, 0)
     INTO v_perc_imposto_precif
     FROM cenario
    WHERE cenario_id = v_cenario_id;
   --
   --
   SELECT nvl(honorario, 0),
          nvl(taxa, 0),
          nvl(margem_oper_meta, 0)
     INTO v_honorario,
          v_taxa,
          v_margem_oper_meta
     FROM cenario_servico
    WHERE cenario_servico_id = p_cenario_servico_id;
   --
   --trabalhando com porcentagem
   v_honorario           := (v_honorario / 100);
   v_taxa                := (v_taxa / 100);
   v_perc_imposto_precif := (v_perc_imposto_precif / 100);
   v_margem_oper_meta    := (v_margem_oper_meta / 100);
   --
   IF v_flag_margem = 'N'
   THEN
    v_margem_oper_meta := 0;
   END IF;
   --
   IF v_flag_honor = 'N'
   THEN
    v_honorario := 0;
   END IF;
   --
   IF v_flag_encargo = 'N'
   THEN
    v_taxa := 0;
   END IF;
   --
   IF v_flag_imposto = 'N'
   THEN
    v_perc_imposto_precif := 0;
   END IF;
   --
   SELECT nvl(custo_total, 0)
     INTO v_custo_total
     FROM cenario_servico_item
    WHERE cenario_servico_item_id = r_item.cenario_servico_item_id;
   --
   v_custo_hono  := v_custo_total * v_honorario;
   v_custo_taxa  := v_custo_total * v_taxa;
   v_preco_venda := round((v_custo_total + v_custo_hono + v_custo_taxa) / (1 - v_margem_oper_meta),
                          2);
   --
   UPDATE cenario_servico_item
      SET honorarios  = v_custo_hono,
          preco_venda = v_preco_venda,
          preco_final = round(v_preco_venda / (1 - v_perc_imposto_precif), 2)
    WHERE cenario_servico_item_id = r_item.cenario_servico_item_id;
  
  END LOOP;
 
  cenario_pkg.cenario_recalcular(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cenario_id,
                                 p_erro_cod,
                                 p_erro_msg);
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
 END cenario_servico_item_recalcular;
 --
 --
 PROCEDURE cenario_servico_usu_adicionar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2019
  -- DESCRICAO: Incluir cenario_servico_usu
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
 BEGIN
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto não existe dentro desse cenário.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_usu
   WHERE usuario_id = p_usuario_id
     AND cenario_servico_id = p_cenario_servico_id;
  --
  IF v_qt = 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário já foi adicionado para este Produto';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Por favor informe o Usuário';
   RAISE v_exception;
  END IF;
  --
  INSERT INTO cenario_servico_usu
   (cenario_servico_usu_id,
    cenario_servico_id,
    usuario_id)
  VALUES
   (seq_cenario_servico_usu.nextval,
    p_cenario_servico_id,
    p_usuario_id);
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
 END cenario_servico_usu_adicionar;
 --
 --
 PROCEDURE cenario_servico_usu_excluir
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 31/08/2019
  -- DESCRICAO: Excluir cenario_servico_usu
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ---------------- -----------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN oportunidade.empresa_id%TYPE,
  p_servico_usu_id    IN cenario_servico_usu.cenario_servico_usu_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
 BEGIN
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico_usu
   WHERE cenario_servico_usu_id = p_servico_usu_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Registro não existe.';
   RAISE v_exception;
  END IF;
  --
  DELETE cenario_servico_usu
   WHERE cenario_servico_usu_id = p_servico_usu_id;
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
 END cenario_servico_usu_excluir;
 --
 --
 PROCEDURE arquivo_cenario_adicionar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 15/07/2019
  -- DESCRICAO: Adicionar arquivo no CENARIO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_cenario_id        IN arquivo_cenario.cenario_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_palavras_chave    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_num_cenario     cenario.num_cenario%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT op.oportunidade_id,
         op.numero,
         op.status,
         ce.num_cenario
    INTO v_oportunidade_id,
         v_numero_oport,
         v_status_oport,
         v_num_cenario
    FROM oportunidade op,
         cenario      ce
   WHERE ce.cenario_id = p_cenario_id
     AND ce.oportunidade_id = op.oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_original) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome_fisico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome jurídico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'CENARIO';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_cenario_id,
                        v_tipo_arquivo_id,
                        p_nome_original,
                        p_nome_fisico,
                        p_descricao,
                        p_mime_type,
                        p_tamanho,
                        p_palavras_chave,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport) || '/' || to_char(v_num_cenario);
  v_compl_histor   := 'Anexação de arquivo no Cenário (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
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
 END arquivo_cenario_adicionar;
 --
 --
 PROCEDURE arquivo_cenario_excluir
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 15/07/2019
  -- DESCRICAO: Excluir arquivo do CENARIO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         14/11/2023  Arquivo de aceite proposta incluso
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_numero_oport    oportunidade.numero%TYPE;
  v_status_oport    oportunidade.status%TYPE;
  v_nome_original   arquivo.nome_original%TYPE;
  v_cenario_id      cenario.cenario_id%TYPE;
  v_num_cenario     cenario.num_cenario%TYPE;
  v_arquivo_prop_id oportunidade.arquivo_prop_id%TYPE;
  v_arquivo_prec_id oportunidade.arquivo_prec_id%TYPE;
  --ALCBO_141123
  v_arquivo_acei_id oportunidade.arquivo_acei_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario         ce,
         arquivo_cenario ac
   WHERE ac.arquivo_id = p_arquivo_id
     AND ac.cenario_id = ce.cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ac.cenario_id,
         ar.nome_original
    INTO v_cenario_id,
         v_nome_original
    FROM arquivo_cenario ac,
         arquivo         ar
   WHERE ac.arquivo_id = p_arquivo_id
     AND ac.arquivo_id = ar.arquivo_id;
  --ALCBO_141123
  SELECT op.oportunidade_id,
         op.numero,
         op.status,
         ce.num_cenario,
         op.arquivo_prop_id,
         op.arquivo_prec_id,
         op.arquivo_acei_id
    INTO v_oportunidade_id,
         v_numero_oport,
         v_status_oport,
         v_num_cenario,
         v_arquivo_prop_id,
         v_arquivo_prec_id,
         v_arquivo_acei_id
    FROM oportunidade op,
         cenario      ce
   WHERE ce.cenario_id = v_cenario_id
     AND ce.oportunidade_id = op.oportunidade_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OPORTUN_A',
                                v_oportunidade_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_oport <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Oportunidade não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF p_arquivo_id = v_arquivo_prop_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não pode ser excluído pois está sendo ' ||
                 'referenciado como arquivo de Proposta.';
   RAISE v_exception;
  END IF;
  --
  IF p_arquivo_id = v_arquivo_prec_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não pode ser excluído pois está sendo ' ||
                 'referenciado como arquivo de Precificação.';
   RAISE v_exception;
  END IF;
  --
  IF p_arquivo_id = v_arquivo_acei_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não pode ser excluído pois está sendo ' ||
                 'referenciado como arquivo de Precificação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_oport) || '/' || to_char(v_num_cenario);
  v_compl_histor   := 'Exclusão de arquivo do Cenário (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'OPORTUNIDADE',
                   'ALTERAR',
                   v_identif_objeto,
                   v_oportunidade_id,
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
 END arquivo_cenario_excluir;
 --
 --
 PROCEDURE xml_gerar
 ----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza              ProcessMind     DATA: 19/09/2019
  -- DESCRICAO: Subrotina que gera o xml da CENARIO para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         03/04/2024  Adicionado novas colunas, custo e overhead
  ----------------------------------------------------------------------------------------
 (
  p_cenario_id IN cenario.cenario_id%TYPE,
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
  v_cenario_servico_id cenario_servico.cenario_servico_id%TYPE;
  --
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("cenario_id", ce.cenario_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("num_cenario", ce.num_cenario),
                   xmlelement("data_entrada", data_mostrar(ce.data_entrada)),
                   xmlelement("num_parcelas", ce.num_parcelas),
                   xmlelement("padrao", ce.flag_padrao),
                   xmlelement("moeda", ce.moeda),
                   xmlelement("valor_cotacao", ce.valor_cotacao),
                   xmlelement("data_cotacao", ce.data_cotacao),
                   xmlelement("tab_preco", tp.nome),
                   xmlelement("briefing", ce.briefing),
                   xmlelement("tem_comissao_venda", ce.flag_comissao_venda),
                   xmlelement("status", ce.status),
                   xmlelement("valor", ce.valor),
                   xmlelement("status_margem", ce.status_margem),
                   xmlelement("aprovador_preco", pe.nome),
                   xmlelement("data_aprovador", data_mostrar(ce.data_aprov_rc)),
                   xmlelement("status_aprovador", ce.status_aprov_rc),
                   xmlelement("prazo_aprovador", ce.data_prazo_aprov_rc),
                   xmlelement("prazo_pagamento", ce.prazo_pagamento),
                   xmlelement("percent_imposto", ce.perc_imposto_precif),
                   xmlelement("data_prazo", ce.data_prazo_aprov),
                   xmlelement("cond_pagamento", ce.cond_pagamento))
    INTO v_xml
    FROM cenario ce
    LEFT JOIN tab_preco tp
      ON ce.preco_id = tp.preco_id
    LEFT JOIN usuario usu
      ON ce.aprov_rc_usuario_id = usu.usuario_id
    LEFT JOIN pessoa pe
      ON usu.usuario_id = pe.usuario_id
   WHERE cenario_id = p_cenario_id;
  --
  ------------------------------------------------------------
  -- monta cenario_servico
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt <> 0
  THEN
   FOR r_cs IN (SELECT cs.cenario_servico_id,
                       cs.servico_id,
                       cs.valor_servico,
                       cs.unid_negocio_resp_id,
                       cs.usuario_resp_id,
                       cs.descricao,
                       cs.duracao_meses,
                       cs.escopo,
                       cs.status,
                       cs.desc_acres,
                       cs.honorario,
                       cs.taxa,
                       cs.margem_oper_min,
                       cs.margem_oper_meta,
                       cs.origem_honor,
                       cs.data_prazo,
                       cs.mes_ano_inicio,
                       cs.horas_custo_total,
                       cs.horas_margem_perc,
                       cs.horas_preco_marg_imp,
                       cs.horas_preco_desc,
                       cs.item_custo_total,
                       cs.item_margem_perc,
                       cs.item_preco_marg_imp,
                       cs.item_preco_desc,
                       cs.comissao,
                       cs.preco_final,
                       cs.status_margem,
                       cs.motivo_recusa,
                       cs.complemento_recusa,
                       cs.horas_imposto,
                       cs.horas_receita_liquida,
                       cs.horas_valor_margem_final,
                       cs.horas_margem_final,
                       cs.item_imposto,
                       cs.item_receita_liquida,
                       cs.item_valor_margem_final,
                       cs.item_margem_final,
                       cs.usu_recusa,
                       cs.data_recusa
                  FROM cenario_servico cs
                 WHERE cs.cenario_id = p_cenario_id)
   LOOP
    SELECT xmlagg(xmlelement("cenario_servico",
                             xmlelement("cenario_servico_id", r_cs.cenario_servico_id),
                             xmlelement("servico_id", r_cs.servico_id),
                             xmlelement("valor_servico", r_cs.valor_servico),
                             xmlelement("unid_negocio_resp_id", r_cs.unid_negocio_resp_id),
                             xmlelement("usuario_resp_id", r_cs.usuario_resp_id),
                             xmlelement("descricao", r_cs.descricao),
                             xmlelement("duracao_meses", r_cs.duracao_meses),
                             xmlelement("escopo", r_cs.escopo),
                             xmlelement("status", r_cs.status),
                             xmlelement("desc_acres", r_cs.desc_acres),
                             xmlelement("honorario", r_cs.honorario),
                             xmlelement("taxa", r_cs.taxa),
                             xmlelement("margem_oper_min", r_cs.margem_oper_min),
                             xmlelement("margem_oper_meta", r_cs.margem_oper_meta),
                             xmlelement("origem_honor", r_cs.origem_honor),
                             xmlelement("data_prazo", r_cs.data_prazo),
                             xmlelement("mes_ano_inicio", r_cs.mes_ano_inicio),
                             xmlelement("horas_custo_total", r_cs.horas_custo_total),
                             xmlelement("horas_margem_perc", r_cs.horas_margem_perc),
                             xmlelement("horas_preco_marg_imp", r_cs.horas_preco_marg_imp),
                             xmlelement("horas_preco_desc", r_cs.horas_preco_desc),
                             xmlelement("item_custo_total", r_cs.item_custo_total),
                             xmlelement("item_margem_perc", r_cs.item_margem_perc),
                             xmlelement("item_preco_marg_imp", r_cs.item_preco_marg_imp),
                             xmlelement("item_preco_desc", r_cs.item_preco_desc),
                             xmlelement("comissao", r_cs.comissao),
                             xmlelement("preco_final", r_cs.preco_final),
                             xmlelement("status_margem", r_cs.status_margem),
                             xmlelement("motivo_recusa", r_cs.motivo_recusa),
                             xmlelement("complemento_recusa", r_cs.complemento_recusa),
                             xmlelement("horas_imposto", r_cs.horas_imposto),
                             xmlelement("horas_receita_liquida", r_cs.horas_receita_liquida),
                             xmlelement("horas_valor_margem_final", r_cs.horas_valor_margem_final),
                             xmlelement("horas_margem_final", r_cs.horas_margem_final),
                             xmlelement("item_imposto", r_cs.item_imposto),
                             xmlelement("item_receita_liquida", r_cs.item_receita_liquida),
                             xmlelement("item_valor_margem_final", r_cs.item_valor_margem_final),
                             xmlelement("item_margem_final", r_cs.item_margem_final),
                             xmlelement("usu_recusa", r_cs.usu_recusa),
                             xmlelement("data_recusa", r_cs.data_recusa)))
      INTO v_xml_aux99
      FROM dual;
    --
    SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
      INTO v_xml_aux1
      FROM dual;
    --
    SELECT xmlagg(xmlelement("cenario_servicos", v_xml_aux1))
      INTO v_xml_aux1
      FROM dual;
    --
    SELECT xmlconcat(v_xml, v_xml_aux1)
      INTO v_xml
      FROM dual;
    ------------------------------------------------------------
    -- monta HORAS
    ------------------------------------------------------------
    v_xml_aux1 := NULL;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM cenario_servico_horas
     WHERE cenario_servico_id = r_cs.cenario_servico_id;
    --
    IF v_qt <> 0
    THEN
     FOR r_ch IN (SELECT ch.cenario_servico_horas_id,
                         ch.cenario_servico_id,
                         ch.area_id,
                         ch.cargo_id,
                         ch.nivel,
                         ch.nome_alternativo,
                         ch.hora_mes,
                         ch.horas_totais,
                         ch.custo_hora,
                         ch.custo_total,
                         ch.preco_venda,
                         ch.preco_final,
                         ch.custo, --ALCBO_030424
                         ch.overhead --ALCBO_030424
                    FROM cenario_servico_horas ch
                   WHERE cenario_servico_id = r_cs.cenario_servico_id)
     LOOP
      SELECT xmlagg(xmlelement("cenario_servico_horas",
                               xmlelement("cenario_servico_horas_id", r_ch.cenario_servico_horas_id),
                               xmlelement("cenario_servico_id", r_ch.cenario_servico_id),
                               xmlelement("area_id", r_ch.area_id),
                               xmlelement("cargo_id", r_ch.cargo_id),
                               xmlelement("nivel", r_ch.nivel),
                               xmlelement("nome_alternativo", r_ch.nome_alternativo),
                               xmlelement("hora_mes", r_ch.hora_mes),
                               xmlelement("horas_totais", r_ch.horas_totais),
                               xmlelement("custo", r_ch.custo), --ALCBO_030424
                               xmlelement("custo_hora", r_ch.custo_hora),
                               xmlelement("custo_total", r_ch.custo_total),
                               xmlelement("preco_venda", r_ch.preco_venda),
                               xmlelement("preco_final", r_ch.preco_final),
                               xmlelement("overhead", r_ch.overhead))) --ALCBO_030424
        INTO v_xml_aux99
        FROM dual;
      --
      SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
        INTO v_xml_aux1
        FROM dual;
     
     END LOOP;
     --
     SELECT xmlagg(xmlelement("horas", v_xml_aux1))
       INTO v_xml_aux1
       FROM dual;
     --
     SELECT xmlconcat(v_xml, v_xml_aux1)
       INTO v_xml
       FROM dual;
    
    END IF;
    --
    ------------------------------------------------------------
    -- monta ITENS
    ------------------------------------------------------------
    v_xml_aux1 := NULL;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM cenario_servico_item
     WHERE cenario_servico_id = r_cs.cenario_servico_id;
    --
    IF v_qt <> 0
    THEN
     --
     FOR r_ci IN (SELECT ci.cenario_servico_item_id,
                         ci.cenario_servico_id,
                         ci.tipo_produto_id,
                         ci.fornecedor_id,
                         ci.complemento,
                         ci.custo_unitario,
                         ci.quantidade,
                         ci.unidade_freq,
                         ci.frequencia,
                         ci.custo_total,
                         ci.honorarios,
                         ci.taxas,
                         ci.preco_venda,
                         ci.preco_final,
                         ci.mod_contr
                    FROM cenario_servico_item ci
                   WHERE cenario_servico_id = r_cs.cenario_servico_id)
     LOOP
      SELECT xmlagg(xmlelement("cenario_servico_item",
                               xmlelement("cenario_servico_item_id", r_ci.cenario_servico_item_id),
                               xmlelement("cenario_servico_id", r_ci.cenario_servico_id),
                               xmlelement("tipo_produto_id", r_ci.tipo_produto_id),
                               xmlelement("fornecedor_id", r_ci.fornecedor_id),
                               xmlelement("complemento", r_ci.complemento),
                               xmlelement("custo_unitario", r_ci.custo_unitario),
                               xmlelement("quantidade", r_ci.quantidade),
                               xmlelement("unidade_freq", r_ci.unidade_freq),
                               xmlelement("frequencia", r_ci.frequencia),
                               xmlelement("custo_total", r_ci.custo_total),
                               xmlelement("honorarios", r_ci.honorarios),
                               xmlelement("taxas", r_ci.taxas),
                               xmlelement("preco_venda", r_ci.preco_venda),
                               xmlelement("preco_final", r_ci.preco_final),
                               xmlelement("mod_contr", r_ci.mod_contr)))
        INTO v_xml_aux99
        FROM dual;
      --
      SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
        INTO v_xml_aux1
        FROM dual;
     
     END LOOP;
     --
     SELECT xmlagg(xmlelement("itens", v_xml_aux1))
       INTO v_xml_aux1
       FROM dual;
     --
     SELECT xmlconcat(v_xml, v_xml_aux1)
       INTO v_xml
       FROM dual;
     --
    END IF;
   
   END LOOP;
   ------------------------------------------------------------
   -- junta tudo debaixo de "cenario"
   ------------------------------------------------------------
   SELECT xmlagg(xmlelement("cenario", v_xml))
     INTO v_xml
     FROM dual;
   --
   ------------------------------------------------------------
   -- acrescenta o tipo de documento e converte para CLOB
   ------------------------------------------------------------
   SELECT v_xml_doc || v_xml.getclobval()
     INTO p_xml
     FROM dual;
  
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
  
 END xml_gerar;
 --
 --
 FUNCTION cenario_valor_retornar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 04/09/2019
  -- DESCRICAO: retorna o valor total de um cenario
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  ----------------------------------------------------------------------------------------
 (p_cenario_id IN cenario.cenario_id%TYPE) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(SUM(valor_budget), 0)
    INTO v_retorno
    FROM cenario_empresa
   WHERE cenario_id = p_cenario_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END cenario_valor_retornar;
 --
 --
 PROCEDURE cenario_status_alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                ProcessMind     DATA: 21/08/2023
  -- DESCRICAO: Alteracao do status de cenário
  --            de uma Oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         30/08/2023  Adicionado verificação de status da margem
  -- Ana Luiza         12/09/2023  Adicao de colunas de historico na tab cenario
  -- Ana Luiza         30/11/2023  Adicao de verificacao baseado no status_margem
  -- Ana Luiza         11/04/2024  Remocao checagem privilegio
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_oportunidade_status oportunidade.status%TYPE;
  v_status_old          cenario.status%TYPE;
  v_status_new          cenario.status%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_num_cenario         cenario.num_cenario%TYPE;
  v_desc_status_old     dicionario.descricao%TYPE;
  v_desc_status_new     dicionario.descricao%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_xml_atual           CLOB;
  --
  v_status_margem cenario.status_margem%TYPE;
  v_motivo        cenario.motivo%TYPE;
  v_complemento   cenario.complemento%TYPE;
  --
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT o.status,
         o.numero,
         o.empresa_id
    INTO v_oportunidade_status,
         v_oportunidade_numero,
         v_empresa_id
    FROM oportunidade o
   INNER JOIN cenario c
      ON c.oportunidade_id = o.oportunidade_id
   WHERE cenario_id = p_cenario_id;
  --
  IF v_oportunidade_status <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Oportunidade precisa estar Em Andamento para alterar o status do preço do Produto.';
   RAISE v_exception;
  END IF;
  --
  SELECT num_cenario,
         status,
         status_margem,
         oportunidade_id
    INTO v_num_cenario,
         v_status_old,
         v_status_margem,
         v_oportunidade_id
    FROM cenario c
   WHERE cenario_id = p_cenario_id;
  --
  --ALCBO_110424
  /*
  IF p_flag_commit = 'S' THEN
   IF p_cod_acao IN ('APROVAR', 'REPROVAR') THEN
    --ALCBO_110424
    IF v_status_margem = 'MARGEM_ABAIXO_MIN' THEN
     IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                   'OPORT_PRECIF_APROV_MIN',
                                   v_oportunidade_id,
                                   NULL,
                                   p_empresa_id) <> 1 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Você não tem privilégio para realizar essa operação 1.';
      RAISE v_exception;
     END IF;
    END IF;
  
    IF v_status_margem = 'MARGEM_ABAIXO_META' THEN
     IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                   'OPORT_PRECIF_APROV_META',
                                   v_oportunidade_id,
                                   NULL,
                                   p_empresa_id) <> 1 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Você não tem privilégio para realizar essa operação 2.';
      RAISE v_exception;
     END IF;
    END IF;
   END IF;
   IF p_cod_acao = 'DEVOLVER_APROV' THEN
    -- soh testa privilegio qdo a chamada for via interface.
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'OPORTUN_CENA_C',
                                  v_oportunidade_id,
                                  NULL,
                                  p_empresa_id) <> 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação 3.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  */
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
  IF RTRIM(p_cod_acao) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da ação é obrigatório.';
     RAISE v_exception;
  END IF;
  */
  IF p_cod_acao NOT IN
     ('ALTERAR', 'APRESENTAR', 'APROVAR', 'DEVOLVER_APROV', 'ENVIAR_APROV', 'REPROVAR', 'TERMINAR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'REPROVAR' AND TRIM(p_motivo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Motivo é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'REPROVAR' AND TRIM(p_complemento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Complemento é obrigatório';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_status_old = 'PREP' AND p_cod_acao = 'TERMINAR'
  THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'TERMINAR'
  THEN
   v_status_new := 'APROV_INTERNA';
  ELSIF v_status_old = 'PRONTO' AND p_cod_acao = 'ENVIAR_APROV'
  THEN
   v_status_new := 'EM_APROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'DEVOLVER_APROV'
  THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'APROVAR'
  THEN
   v_status_new := 'APROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'REPROVAR'
  THEN
   v_status_new := 'REPROV_INTERNA';
  ELSIF v_status_old = 'EM_APROV_INTERNA' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'APROV_INTERNA' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'REPROV_INTERNA' AND p_cod_acao = 'DEVOLVER_APROV'
  THEN
   v_status_new := 'EM_APROV_INTERNA';
  ELSIF v_status_old = 'REPROV_INTERNA' AND p_cod_acao = 'TERMINAR'
  THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'APROV_INTERNA' AND p_cod_acao = 'APRESENTAR'
  THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'APROVAR'
  THEN
   v_status_new := 'APROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'APRESENTAR'
  THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'APRES_CLIENTE' AND p_cod_acao = 'REPROVAR'
  THEN
   v_status_new := 'REPROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'REPROVAR'
  THEN
   v_status_new := 'REPROV_CLIENTE';
  ELSIF v_status_old = 'APROV_CLIENTE' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'APROVAR'
  THEN
   v_status_new := 'APROV_CLIENTE';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'APRESENTAR'
  THEN
   v_status_new := 'APRES_CLIENTE';
  ELSIF v_status_old = 'REPROV_CLIENTE' AND p_cod_acao = 'TERMINAR'
  THEN
   v_status_new := 'PRONTO';
  ELSIF v_status_old = 'PREP' AND p_cod_acao = 'ALTERAR'
  THEN
   v_status_new := 'PREP';
  ELSE
   IF p_flag_commit = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Transição de status inválida.';
    RAISE v_exception;
   END IF;
  END IF;
 
  IF v_status_new <> v_status_old
  THEN
   IF v_status_new = 'PRONTO' AND
      (v_status_margem = 'MARGEM_OK' OR v_status_margem = 'MARGEM_ACIMA')
   THEN
    v_status_new := 'APROV_INTERNA';
   END IF;
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   SELECT descricao
     INTO v_desc_status_old
     FROM dicionario
    WHERE codigo = v_status_old
      AND tipo = 'status_cenario';
  
   SELECT descricao
     INTO v_desc_status_new
     FROM dicionario
    WHERE codigo = v_status_new
      AND tipo = 'status_cenario';
  
   v_identif_objeto := to_char(v_oportunidade_numero);
   v_compl_histor   := 'Status do Cenário alterado de ' || v_desc_status_old || ' para ' ||
                       v_desc_status_new || ' do Cenário #' || v_num_cenario;
  
   IF TRIM(p_complemento) IS NOT NULL
   THEN
    v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
   END IF;
  
   evento_pkg.gerar(p_usuario_sessao_id,
                    v_empresa_id,
                    'CENARIO',
                    'ALTERAR_STATUS_CEN',
                    v_identif_objeto,
                    p_cenario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --ALCBO_120923
   IF TRIM(p_motivo) IS NULL AND TRIM(p_complemento) IS NULL
   THEN
    v_motivo      := NULL;
    v_complemento := NULL;
   ELSE
    v_motivo      := TRIM(p_motivo);
    v_complemento := TRIM(p_complemento);
   END IF;
   --
   UPDATE cenario
      SET status      = v_status_new,
          usu_alt_id  = p_usuario_sessao_id,
          data_alt    = SYSDATE,
          motivo      = v_motivo,
          complemento = v_complemento
    WHERE cenario_id = p_cenario_id;
   --
   IF p_flag_commit = 'S'
   THEN
    COMMIT;
   END IF;
  END IF;
 
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END cenario_status_alterar;
 --
 --
 PROCEDURE cenario_servico_status_alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                ProcessMind     DATA: 17/08/2023
  -- DESCRICAO: Alteracao do status de precificação de um serviço dentro de um cenário
  --            de uma Oportunidade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         04/09/2023  Gravar usuario e data de recusa
  -- Ana Luiza         05/09/2023  Adicionado variavel complemento para
  --                               evitar erro na chamada do cenario_status_alterar
  -- Ana Luiza         11/04/2025  Dar mensagem caso não possua itens e horas no cenario
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_flag_commit        IN VARCHAR2,
  p_cenario_servico_id IN cenario_servico.cenario_servico_id%TYPE,
  p_cod_acao           IN tipo_acao.codigo%TYPE,
  p_motivo             IN VARCHAR2,
  p_complemento        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_oportunidade_status oportunidade.status%TYPE;
  v_cenario_id          cenario.cenario_id%TYPE;
  v_status_old          cenario_servico.status%TYPE;
  v_status_new          cenario_servico.status%TYPE;
  v_oportunidade_numero oportunidade.numero%TYPE;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_num_cenario         cenario.num_cenario%TYPE;
  v_servico_desc        VARCHAR(203);
  v_desc_status_old     dicionario.descricao%TYPE;
  v_desc_status_new     dicionario.descricao%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_cod_acao            tipo_acao.codigo%TYPE;
  v_xml_atual           CLOB;
  --ALCBO_050923
  v_complemento     VARCHAR2(500);
  v_oportunidade_id oportunidade.oportunidade_id%TYPE;
  v_qt_itens        INTEGER;
  v_qt_horas        INTEGER;
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
 
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario_servico
   WHERE cenario_servico_id = p_cenario_servico_id;
 
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Produto dentro do Cenário não existe.';
   RAISE v_exception;
  END IF;
 
  SELECT o.status,
         o.numero,
         o.empresa_id
    INTO v_oportunidade_status,
         v_oportunidade_numero,
         v_empresa_id
    FROM oportunidade o
   INNER JOIN cenario c
      ON c.oportunidade_id = o.oportunidade_id
   INNER JOIN cenario_servico s
      ON s.cenario_id = c.cenario_id
   WHERE cenario_servico_id = p_cenario_servico_id;
 
  IF v_oportunidade_status <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Oportunidade precisa estar Em Andamento para alterar o status do preço do Produto.';
   RAISE v_exception;
  END IF;
 
  SELECT c.cenario_id,
         num_cenario,
         oportunidade_id
    INTO v_cenario_id,
         v_num_cenario,
         v_oportunidade_id
    FROM cenario c
   INNER JOIN cenario_servico s
      ON s.cenario_id = c.cenario_id
   WHERE cenario_servico_id = p_cenario_servico_id;
 
  IF p_flag_commit = 'S'
  THEN
   -- soh testa privilegio qdo a chamada for via interface.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORTUN_CENA_C',
                                 v_oportunidade_id,
                                 NULL,
                                 p_empresa_id) <> 1 AND
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORT_PRECIF_CARGO_ALTERAR',
                                 p_cenario_servico_id,
                                 NULL,
                                 p_empresa_id) <> 1 AND
      usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORT_PRECIF_ITENS_ALTERAR',
                                 p_cenario_servico_id,
                                 NULL,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_cod_acao NOT IN ('TERMINAR', 'REFAZER', 'RECUSAR_PROD_CEN')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'RECUSAR_PROD_CEN' AND TRIM(p_motivo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Motivo é obrigatório';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'RECUSAR_PROD_CEN' AND TRIM(p_complemento) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O campo Complemento é obrigatório';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT c.status,
         g.nome || ' - ' || s.nome
    INTO v_status_old,
         v_servico_desc
    FROM cenario_servico c
   INNER JOIN servico s
      ON s.servico_id = c.servico_id
    LEFT JOIN grupo_servico g
      ON g.grupo_servico_id = s.grupo_servico_id
   WHERE c.cenario_servico_id = p_cenario_servico_id;
  --
  IF v_status_old = 'PEND' AND p_cod_acao = 'TERMINAR'
  THEN
   v_status_new := 'PRON';
   v_cod_acao   := 'ALTERAR_STATUS_PROD_CEN';
  ELSIF v_status_old = 'PRON' AND p_cod_acao = 'REFAZER'
  THEN
   v_status_new := 'PEND';
   v_cod_acao   := 'ALTERAR_STATUS_PROD_CEN';
  ELSIF v_status_old = 'PEND' AND p_cod_acao = 'RECUSAR_PROD_CEN'
  THEN
   v_status_new := 'RECU';
   v_cod_acao   := 'RECUSAR_PROD_CEN';
  ELSIF v_status_old = 'RECU' AND p_cod_acao = 'REFAZER'
  THEN
   v_status_new := 'PEND';
   v_cod_acao   := 'ALTERAR_STATUS_PROD_CEN';
  ELSIF v_status_old = 'PEND' AND p_cod_acao = 'REFAZER'
  THEN
   v_status_new := 'PEND';
   v_cod_acao   := 'ALTERAR_STATUS_PROD_CEN';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Transição de status inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_040923
  IF v_status_new <> v_status_old
  THEN
   UPDATE cenario_servico
      SET status             = v_status_new,
          motivo_recusa      = p_motivo,
          complemento_recusa = p_complemento,
          usu_recusa         = p_usuario_sessao_id,
          data_recusa        = SYSDATE
    WHERE cenario_servico_id = p_cenario_servico_id;
   --alterar status do cenario quando a precificação é alterada
   IF p_cod_acao = 'REFAZER'
   THEN
    --ALCBO_050923
    v_complemento := 'O Preço do Produto' || v_servico_desc || ' foi alterado.';
    cenario_status_alterar(p_usuario_sessao_id,
                           p_empresa_id,
                           'N',
                           v_cenario_id,
                           'ALTERAR',
                           '',
                           v_complemento,
                           p_erro_cod,
                           p_erro_msg);
   
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --alterar status do cenario quando todas as precificações estiverem prontas
   IF p_cod_acao = 'TERMINAR'
   THEN
    --
    --ALCBO_110425   
    SELECT COUNT(*)
      INTO v_qt_itens
      FROM cenario_servico_horas
     WHERE cenario_servico_id = p_cenario_servico_id;
    --
    SELECT COUNT(*)
      INTO v_qt_horas
      FROM cenario_servico_item
     WHERE cenario_servico_id = p_cenario_servico_id;
    --
    IF v_qt_itens = 0 AND v_qt_horas = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não é possível terminar, este serviço não possui precificação de Equipe ou Itens';
     RAISE v_exception;
    END IF;
    --ALCBO_110425F 
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM cenario_servico
     WHERE status <> 'PRON'
       AND cenario_id = v_cenario_id;
    --   
    IF v_qt = 0
    THEN
     cenario_status_alterar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_cenario_id,
                            'TERMINAR',
                            '',
                            'Os preços de todos os Produtos estão
                                Prontos.',
                            p_erro_cod,
                            p_erro_msg);
    
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   
   END IF;
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   SELECT descricao
     INTO v_desc_status_old
     FROM dicionario
    WHERE codigo = v_status_old
      AND tipo = 'status_cenario_servico';
  
   SELECT descricao
     INTO v_desc_status_new
     FROM dicionario
    WHERE codigo = v_status_new
      AND tipo = 'status_cenario_servico';
  
   v_identif_objeto := to_char(v_oportunidade_numero);
   v_compl_histor   := 'Status de Preço de Produto ' || v_servico_desc || ' alterado de ' ||
                       v_desc_status_old || ' para ' || v_desc_status_new || ' do Cenário #' ||
                       v_num_cenario;
  
   IF TRIM(p_complemento) IS NOT NULL
   THEN
    v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
   END IF;
  
   evento_pkg.gerar(p_usuario_sessao_id,
                    v_empresa_id,
                    'CENARIO',
                    v_cod_acao,
                    v_identif_objeto,
                    v_cenario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   IF p_flag_commit = 'S'
   THEN
    COMMIT;
   END IF;
  END IF;
 
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END cenario_servico_status_alterar;
 --
 --
 PROCEDURE cenario_servico_item_duplicar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 13/09/2023
  -- DESCRICAO: Duplica um cenario_servico_item
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN oportunidade.empresa_id%TYPE,
  p_cenario_servico_item_id IN cenario_servico_item.cenario_servico_item_id%TYPE,
  p_cenario_servico_id      IN cenario_servico.cenario_servico_id%TYPE,
  p_flag_commit             IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  v_cenario_servico_id      cenario_servico_item.cenario_servico_id%TYPE;
  v_cenario_servico_item_id cenario_servico_item.cenario_servico_item_id%TYPE;
  v_complemento             cenario_servico_item.complemento%TYPE;
  v_custo_total             cenario_servico_item.custo_total%TYPE;
  v_custo_unitario          cenario_servico_item.custo_unitario%TYPE;
  v_fornecedor_id           cenario_servico_item.fornecedor_id%TYPE;
  v_frequencia              cenario_servico_item.frequencia%TYPE;
  v_honorarios              cenario_servico_item.honorarios%TYPE;
  v_mod_contr               cenario_servico_item.mod_contr%TYPE;
  v_preco_final             cenario_servico_item.preco_final%TYPE;
  v_preco_venda             cenario_servico_item.preco_venda%TYPE;
  v_quantidade              cenario_servico_item.quantidade%TYPE;
  v_taxas                   cenario_servico_item.taxas%TYPE;
  v_tipo_produto_id         cenario_servico_item.tipo_produto_id%TYPE;
  v_unidade_freq            cenario_servico_item.unidade_freq%TYPE;
 BEGIN
  v_qt := 0;
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT complemento,
         custo_total,
         custo_unitario,
         fornecedor_id,
         frequencia,
         honorarios,
         mod_contr,
         preco_final,
         preco_venda,
         quantidade,
         taxas,
         tipo_produto_id,
         unidade_freq
    INTO v_complemento,
         v_custo_total,
         v_custo_unitario,
         v_fornecedor_id,
         v_frequencia,
         v_honorarios,
         v_mod_contr,
         v_preco_final,
         v_preco_venda,
         v_quantidade,
         v_taxas,
         v_tipo_produto_id,
         v_unidade_freq
    FROM cenario_servico_item
   WHERE cenario_servico_item_id = p_cenario_servico_item_id;
  --
  --
  INSERT INTO cenario_servico_item
   (cenario_servico_item_id,
    cenario_servico_id,
    tipo_produto_id,
    fornecedor_id,
    complemento,
    custo_unitario,
    quantidade,
    unidade_freq,
    frequencia,
    custo_total,
    honorarios,
    taxas,
    preco_venda,
    preco_final,
    mod_contr)
  VALUES
   (seq_cenario_servico_item.nextval,
    p_cenario_servico_id,
    v_tipo_produto_id,
    v_fornecedor_id,
    v_complemento,
    v_custo_unitario,
    v_quantidade,
    v_unidade_freq,
    v_frequencia,
    v_custo_total,
    v_honorarios,
    v_taxas,
    v_preco_venda,
    v_preco_final,
    v_mod_contr);
  --
  --
  IF p_flag_commit = 'S'
  THEN
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
 --
 PROCEDURE cenario_aprov_rc_alterar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                ProcessMind     DATA: 28/08/2023
  -- DESCRICAO: Alterar status e outros elementos da aprovação do uso de rate card
  --            expirado num Cenário de Oportunidade
  --            NA - não houve solicitação de aprovação
  --            EMAP - solicitação de aprovação pendente
  --            REPR - reprovado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Ana Luiza         07/12/2023  Adicionado condicoes para teste de privilegio
  ----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cenario_id        IN cenario.cenario_id%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                        INTEGER;
  v_exception                 EXCEPTION;
  v_oportunidade_status       oportunidade.status%TYPE;
  v_status_old                cenario.status_aprov_rc%TYPE;
  v_status_new                cenario.status_aprov_rc%TYPE;
  v_oportunidade_numero       oportunidade.numero%TYPE;
  v_empresa_id                empresa.empresa_id%TYPE;
  v_num_cenario               cenario.num_cenario%TYPE;
  v_desc_status_old           dicionario.descricao%TYPE;
  v_desc_status_new           dicionario.descricao%TYPE;
  v_identif_objeto            historico.identif_objeto%TYPE;
  v_compl_histor              historico.complemento%TYPE;
  v_historico_id              historico.historico_id%TYPE;
  v_xml_atual                 CLOB;
  v_num_dias_rc_val_estendida INTEGER;
  v_num_dias_aprov_rc         INTEGER;
  v_oportunidade_id           oportunidade.oportunidade_id%TYPE;
 BEGIN
  v_qt := 0;
  --
  SELECT oportunidade_id
    INTO v_oportunidade_id
    FROM cenario
   WHERE cenario_id = p_cenario_id;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_cod_acao NOT IN ('SOLIC_APROV', 'APROVAR', 'NAO_APROVAR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --ALCBO_071223
  IF p_cod_acao IN ('NAO_APROVAR', 'APROVAR')
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORT_APROV_RC_INV',
                                 v_oportunidade_id,
                                 NULL,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_071223
  IF p_cod_acao IN ('SOLIC_APROV')
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OPORTUN_CENA_C',
                                 v_oportunidade_id,
                                 NULL,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cenario
   WHERE cenario_id = p_cenario_id;
 
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Cenário não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT o.status,
         o.numero,
         o.empresa_id
    INTO v_oportunidade_status,
         v_oportunidade_numero,
         v_empresa_id
    FROM oportunidade o
   INNER JOIN cenario c
      ON c.oportunidade_id = o.oportunidade_id
   WHERE cenario_id = p_cenario_id;
  --
  IF v_oportunidade_status <> 'ANDA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A Oportunidade precisa estar Em Andamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT num_cenario,
         status_aprov_rc
    INTO v_num_cenario,
         v_status_old
    FROM cenario c
   WHERE cenario_id = p_cenario_id;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  /*
  IF 1 = 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := v_status_old || '|' || p_cod_acao;
     RAISE v_exception;
  END IF;
  */
  IF v_status_old = 'NA' AND p_cod_acao = 'SOLIC_APROV'
  THEN
   v_status_new := 'EMAP';
  ELSIF v_status_old = 'NAAP' AND p_cod_acao = 'SOLIC_APROV'
  THEN
   v_status_new := 'EMAP';
  ELSIF v_status_old = 'EMAP' AND p_cod_acao = 'APROVAR'
  THEN
   v_status_new := 'NA';
  ELSIF v_status_old = 'EMAP' AND p_cod_acao = 'NAO_APROVAR'
  THEN
   v_status_new := 'NAAP';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Transição de status inválida 3.';
   RAISE v_exception;
  END IF;
 
  IF v_status_new <> v_status_old
  THEN
   IF (v_status_new = 'NA' AND p_cod_acao = 'APROVAR') OR
      (v_status_new = 'NAAP' AND p_cod_acao = 'NAO_APROVAR')
   THEN
    UPDATE cenario
       SET status_aprov_rc     = v_status_new,
           usuario_aprov_rc_id = p_usuario_sessao_id,
           data_aprov_rc       = SYSDATE
     WHERE cenario_id = p_cenario_id;
   
   ELSE
    UPDATE cenario
       SET status_aprov_rc = v_status_new
     WHERE cenario_id = p_cenario_id;
   
   END IF;
  
   IF (v_status_new = 'NA' AND p_cod_acao = 'APROVAR')
   THEN
    v_num_dias_rc_val_estendida := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                  'NUM_DIAS_RC_VAL_ESTENDIDA');
    UPDATE cenario
       SET data_aprov_rc = feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                              SYSDATE,
                                                              v_num_dias_rc_val_estendida,
                                                              'S')
     WHERE cenario_id = p_cenario_id;
   
   END IF;
  
   IF (v_status_new = 'EMAP' AND p_cod_acao = 'SOLIC_APROV')
   THEN
    v_num_dias_aprov_rc := empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_APROV_RC');
    UPDATE cenario
       SET data_prazo_aprov_rc = feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                                    SYSDATE,
                                                                    v_num_dias_aprov_rc,
                                                                    'S')
     WHERE cenario_id = p_cenario_id;
   
   END IF;
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   SELECT descricao
     INTO v_desc_status_old
     FROM dicionario
    WHERE codigo = v_status_old
      AND tipo = 'status_aprov_rc';
  
   SELECT descricao
     INTO v_desc_status_new
     FROM dicionario
    WHERE codigo = v_status_new
      AND tipo = 'status_aprov_rc';
  
   v_identif_objeto := to_char(v_oportunidade_numero);
   v_compl_histor   := 'Status de aprovação de uso de Rate Card alterado de ' || v_desc_status_old ||
                       ' para ' || v_desc_status_new || ' do Cenário #' || v_num_cenario;
  
   IF TRIM(p_complemento) IS NOT NULL
   THEN
    v_compl_histor := v_compl_histor || ' ' || TRIM(p_complemento);
   END IF;
  
   evento_pkg.gerar(p_usuario_sessao_id,
                    v_empresa_id,
                    'CENARIO',
                    'ALTERAR',
                    v_identif_objeto,
                    p_cenario_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    v_xml_atual,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   COMMIT;
  END IF;
 
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END cenario_aprov_rc_alterar;
 --
 PROCEDURE interacao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza               ProcessMind     DATA: 18/12/2024
  -- DESCRICAO: Adiciona interacao (Follow-up) automatico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  --------------------------------------------------------
  -----------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_interacao_id      OUT interacao.interacao_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_interacao_id        interacao.interacao_id%TYPE;
  v_avancar_etapa_oport VARCHAR2(100);
  v_status_atual        VARCHAR2(100);
  v_data_interacao1     DATE;
  v_meio_contato        VARCHAR2(100);
  v_descricao           VARCHAR2(200);
  v_status_aux_oport_id oportunidade.status_aux_oport_id%TYPE;
  v_int2_descricao      interacao.desc_prox_int%TYPE;
  v_data_interacao2     interacao.data_prox_int%TYPE;
  v_int2_usuario_id     interacao.usuario_prox_int_id%TYPE;
  v_data_prov_fech      interacao.data_prov_fech%TYPE;
  v_perc_prob_fech      interacao.perc_prob_fech%TYPE;
  v_int1_usuario_id     interacao.usuario_resp_id%TYPE;
  --
 BEGIN
  v_qt                  := 0;
  v_avancar_etapa_oport := empresa_pkg.parametro_retornar(p_empresa_id, 'AVANCAR_ETAPA_OPORT');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_oportunidade_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da oportunidade_id é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa oportunidade não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  SELECT nome
    INTO v_status_atual
    FROM status_aux_oport
   WHERE status_aux_oport_id IN (SELECT (status_aux_oport_id)
                                   FROM oportunidade
                                  WHERE oportunidade_id = p_oportunidade_id);
  --
  IF v_status_atual IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Status da Oportunidade não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM interacao
   WHERE oportunidade_id = p_oportunidade_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Follow-up anterior não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  --ALCBO_161224 - Criacao Follow-up automatico
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_status_atual <> v_avancar_etapa_oport
  THEN
   IF v_avancar_etapa_oport NOT IN ('NENHUMA')
   THEN
    --
    SELECT usuario_resp_id,
           perc_prob_fech,
           data_prov_fech,
           usuario_prox_int_id,
           data_prox_int
      INTO v_int1_usuario_id,
           v_perc_prob_fech,
           v_data_prov_fech,
           v_int2_usuario_id,
           v_data_interacao2
      FROM interacao
     WHERE oportunidade_id = p_oportunidade_id;
    --
    SELECT codigo
      INTO v_meio_contato
      FROM dicionario
     WHERE codigo = 'IND'
       AND tipo = 'oportunidade_meio_contato';
    --
    SELECT status_aux_oport_id
      INTO v_status_aux_oport_id
      FROM status_aux_oport
     WHERE nome = v_avancar_etapa_oport
       AND empresa_id = p_empresa_id;
    --
    v_data_interacao1 := SYSDATE;
    v_descricao       := 'O primeiro Cenário da Oportunidade foi criado. A Oportunidade avançou automaticamente para a Etapa ' ||
                         v_avancar_etapa_oport || '.';
    --
    SELECT seq_interacao.nextval
      INTO v_interacao_id
      FROM dual;
    --
    INSERT INTO interacao
     (interacao_id,
      oportunidade_id,
      usuario_resp_id,
      data_entrada,
      data_interacao,
      descricao,
      meio_contato,
      perc_prob_fech,
      data_prov_fech,
      usuario_prox_int_id,
      data_prox_int,
      desc_prox_int,
      status_aux_oport_id)
    VALUES
     (v_interacao_id,
      p_oportunidade_id,
      v_int1_usuario_id,
      SYSDATE,
      SYSDATE,
      TRIM(v_descricao),
      v_meio_contato,
      v_perc_prob_fech,
      v_data_prov_fech,
      v_int2_usuario_id,
      v_data_interacao2,
      TRIM(v_int2_descricao),
      v_status_aux_oport_id); --novo status de acordo com parametro
   END IF; --so cria follow-up se status op eh diferente do parametro
  END IF; --ALCBO_161224_FIM
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_interacao_id := v_interacao_id;
  p_erro_cod     := '00000';
  p_erro_msg     := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END interacao_adicionar;
 --
END; -- CENARIO_PKG

/
