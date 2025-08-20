--------------------------------------------------------
--  DDL for Package Body NOTA_FISCAL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NOTA_FISCAL_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE sub_checkin_consistir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 21/09/2012
  -- DESCRICAO: subrotina que consiste dados basicos do checkin.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/10/2017  Liberado: empresa emissora igual a empresa de faturamento.
  -- Joel Dias         22/09/2023  Inclusão do vetor de sobra
  -- Ana Luiza         12/11/2024  Inclusao validacao fornecedor ativo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_valor_credito_usado    IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_cliente_job_id         job.cliente_id%TYPE;
  v_nota_fiscal_id         nota_fiscal.nota_fiscal_id%TYPE;
  v_valor_bruto            nota_fiscal.valor_bruto%TYPE;
  v_data_entrada           nota_fiscal.data_entrada%TYPE;
  v_data_emissao           nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim        nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id             nota_fiscal.cliente_id%TYPE;
  v_resp_pgto_receita      nota_fiscal.resp_pgto_receita%TYPE;
  v_valor_credito_usado    nota_fiscal.valor_credito_usado%TYPE;
  v_tipo_doc               tipo_doc_nf.codigo%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_item_id          VARCHAR2(8000);
  v_vetor_carta_acordo_id  VARCHAR2(8000);
  v_vetor_valor_aprovado   VARCHAR2(8000);
  v_vetor_valor_fornecedor VARCHAR2(8000);
  v_vetor_valor_bv         VARCHAR2(8000);
  v_vetor_valor_tip        VARCHAR2(4000);
  v_vetor_valor_sobra      VARCHAR2(4000);
  v_vetor_tipo_produto_id  VARCHAR2(8000);
  v_vetor_quantidade       VARCHAR2(8000);
  v_vetor_frequencia       VARCHAR2(8000);
  v_vetor_custo_unitario   VARCHAR2(8000);
  v_vetor_complemento      LONG;
  v_item_id                item.item_id%TYPE;
  v_nome_item              VARCHAR2(100);
  v_carta_acordo_id        carta_acordo.carta_acordo_id%TYPE;
  v_status_ca              carta_acordo.status%TYPE;
  v_num_ca                 VARCHAR2(50);
  v_tipo_produto_id        tipo_produto.tipo_produto_id%TYPE;
  v_tipo_item              VARCHAR2(10);
  v_tipo_item_ant          VARCHAR2(10);
  v_orcamento_id           item.orcamento_id%TYPE;
  v_tipo_fatur_bv          item.tipo_fatur_bv%TYPE;
  v_tipo_fatur_bv_ant      item.tipo_fatur_bv%TYPE;
  v_flag_pago_cliente      item.flag_pago_cliente%TYPE;
  v_flag_pago_cliente_ant  item.flag_pago_cliente%TYPE;
  v_flag_emp_fatur         pessoa.flag_emp_fatur%TYPE;
  v_flag_incentivo_rec     pessoa.flag_emp_incentivo%TYPE;
  v_flag_incentivo_fat     pessoa.flag_emp_incentivo%TYPE;
  v_flag_incentivo         pessoa.flag_emp_incentivo%TYPE;
  v_quantidade             item_nota.quantidade%TYPE;
  v_frequencia             item_nota.frequencia%TYPE;
  v_custo_unitario         item_nota.custo_unitario%TYPE;
  v_tipo_checkin           VARCHAR2(5);
  v_tipo_checkin_ant       VARCHAR2(5);
  --
  v_valor_aprovado_char   VARCHAR2(50);
  v_valor_bv_char         VARCHAR2(50);
  v_valor_tip_char        VARCHAR2(50);
  v_valor_sobra_char      VARCHAR2(50);
  v_quantidade_char       VARCHAR2(50);
  v_frequencia_char       VARCHAR2(50);
  v_custo_unitario_char   VARCHAR2(50);
  v_complemento           VARCHAR2(2000);
  v_valor_aprovado        item_nota.valor_aprovado%TYPE;
  v_valor_aprovado_aux    item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_char VARCHAR2(20);
  v_valor_fornecedor      item_nota.valor_fornecedor%TYPE;
  v_valor_bv              item_nota.valor_bv%TYPE;
  v_valor_tip             item_nota.valor_tip%TYPE;
  v_valor_sobra           sobra.valor_sobra%TYPE;
  v_lbl_job               VARCHAR2(100);
  v_local_parcelam        VARCHAR2(40);
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_local_parcelam       := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_job_id IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job jo
    WHERE jo.job_id = p_job_id
      AND jo.empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT jo.cliente_id
     INTO v_cliente_job_id
     FROM job jo
    WHERE jo.job_id = p_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos itens passados nos vetores
  ------------------------------------------------------------
  v_tipo_item_ant         := NULL;
  v_tipo_fatur_bv_ant     := NULL;
  v_flag_pago_cliente_ant := NULL;
  v_tipo_checkin_ant      := NULL;
  --
  v_delimitador            := '|';
  v_vetor_item_id          := p_vetor_item_id;
  v_vetor_carta_acordo_id  := p_vetor_carta_acordo_id;
  v_vetor_tipo_produto_id  := p_vetor_tipo_produto_id;
  v_vetor_quantidade       := p_vetor_quantidade;
  v_vetor_frequencia       := p_vetor_frequencia;
  v_vetor_custo_unitario   := p_vetor_custo_unitario;
  v_vetor_complemento      := p_vetor_complemento;
  v_vetor_valor_aprovado   := p_vetor_valor_aprovado;
  v_vetor_valor_fornecedor := p_vetor_valor_fornecedor;
  v_vetor_valor_bv         := p_vetor_valor_bv;
  v_vetor_valor_tip        := p_vetor_valor_tip;
  IF p_vetor_valor_sobra IS NOT NULL
  THEN
   v_vetor_valor_sobra := p_vetor_valor_sobra;
  END IF;
  --
  IF rtrim(v_vetor_item_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum item foi selecionado.';
   RAISE v_exception;
  END IF;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0 OR
        nvl(length(rtrim(v_vetor_carta_acordo_id)), 0) > 0
  LOOP
   --
   v_item_id               := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_carta_acordo_id       := nvl(to_number(prox_valor_retornar(v_vetor_carta_acordo_id,
                                                                v_delimitador)),
                                  0);
   v_tipo_produto_id       := nvl(to_number(prox_valor_retornar(v_vetor_tipo_produto_id,
                                                                v_delimitador)),
                                  0);
   v_quantidade_char       := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char       := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char   := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento           := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_valor_aprovado_char   := prox_valor_retornar(v_vetor_valor_aprovado, v_delimitador);
   v_valor_fornecedor_char := prox_valor_retornar(v_vetor_valor_fornecedor, v_delimitador);
   v_valor_bv_char         := prox_valor_retornar(v_vetor_valor_bv, v_delimitador);
   v_valor_tip_char        := prox_valor_retornar(v_vetor_valor_tip, v_delimitador);
   IF p_vetor_valor_sobra IS NOT NULL
   THEN
    v_valor_sobra_char := prox_valor_retornar(v_vetor_valor_sobra, v_delimitador);
   END IF;
   --
   IF v_item_id = 0 AND v_carta_acordo_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Os vetores de itens/cartas acordo selecionados contêm ambos os ' ||
                  'identificadores zerados ou nulos.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item no vetor não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_carta_acordo_id > 0
   THEN
    v_tipo_checkin := 'CA';
   ELSE
    v_tipo_checkin := 'IT';
   END IF;
   --
   IF v_tipo_checkin_ant IS NULL
   THEN
    v_tipo_checkin_ant := v_tipo_checkin;
   ELSE
    IF v_tipo_checkin_ant <> v_tipo_checkin
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não é possível misturar itens com carta acordo e itens sem carta ' ||
                   'acordo no check-in.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   SELECT decode(tipo_item, 'A', 'A', 'B', 'BC', 'C', 'BC'),
          tipo_fatur_bv,
          flag_pago_cliente,
          item_pkg.num_item_retornar(item_id, 'N'),
          orcamento_id
     INTO v_tipo_item,
          v_tipo_fatur_bv,
          v_flag_pago_cliente,
          v_nome_item,
          v_orcamento_id
     FROM item
    WHERE item_id = v_item_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'NOTA_FISCAL_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_pago_cliente_ant IS NULL
   THEN
    v_flag_pago_cliente_ant := v_flag_pago_cliente;
   ELSE
    IF v_flag_pago_cliente_ant <> v_flag_pago_cliente
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens que são pagos diretamente pelo cliente não podem ser ' ||
                   'agrupados na mesma nota fiscal com itens que não são pagos diretamente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_tipo_item_ant IS NULL
   THEN
    v_tipo_item_ant := v_tipo_item;
   ELSE
    IF v_tipo_item_ant <> v_tipo_item
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Itens de A não podem ser agrupados com itens de B e C ' ||
                   'na mesma nota fiscal.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_carta_acordo_id > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_carta
     WHERE carta_acordo_id = v_carta_acordo_id
       AND item_id = v_item_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A carta acordo passada no vetor não existe ou não pertence ao item.';
     RAISE v_exception;
    END IF;
    --
    SELECT tipo_fatur_bv,
           carta_acordo_pkg.numero_completo_formatar(carta_acordo_id, 'N'),
           status
      INTO v_tipo_fatur_bv,
           v_num_ca,
           v_status_ca
      FROM carta_acordo
     WHERE carta_acordo_id = v_carta_acordo_id;
    --
    IF v_status_ca <> 'EMITIDA'
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A carta acordo ' || v_num_ca || ' ainda não foi emitida.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- verifica a quebra de tipo de faturamento de BV/TIP apenas p/ itens
   -- com valor de BV/TIP definido (maior que zero).
   IF v_tipo_fatur_bv <> 'NA'
   THEN
    IF v_tipo_fatur_bv_ant IS NULL
    THEN
     v_tipo_fatur_bv_ant := v_tipo_fatur_bv;
    ELSE
     IF v_tipo_fatur_bv_ant <> v_tipo_fatur_bv
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Itens/Cartas Acordo com tipos de faturamento de BV diferentes, ' ||
                    'não podem ser agrupados na mesma nota fiscal.';
      RAISE v_exception;
     END IF;
    END IF;
   END IF;
   --
   IF moeda_validar(v_valor_aprovado_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor aprovado inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_fornecedor_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_bv_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de BV inválido (' || v_nome_item || ': ' || v_valor_bv_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_tip_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de TIP inválido (' || v_nome_item || ': ' || v_valor_tip_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_custo_unitario_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_quantidade_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_frequencia_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento do item não pode ter mais que 500 caracteres (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   -- verifica valores do check-in
   v_valor_aprovado   := nvl(moeda_converter(v_valor_aprovado_char), 0);
   v_valor_fornecedor := nvl(moeda_converter(v_valor_fornecedor_char), 0);
   v_valor_bv         := nvl(moeda_converter(v_valor_bv_char), 0);
   v_valor_tip        := nvl(moeda_converter(v_valor_tip_char), 0);
   IF p_vetor_valor_sobra IS NOT NULL
   THEN
    v_valor_sobra := nvl(moeda_converter(v_valor_sobra_char), 0);
   END IF;
   v_custo_unitario := nvl(numero_converter(v_custo_unitario_char), 0);
   v_quantidade     := nvl(numero_converter(v_quantidade_char), 0);
   v_frequencia     := nvl(numero_converter(v_frequencia_char), 0);
   --
   IF v_valor_aprovado < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor aprovado inválido (' || v_nome_item || ': ' || v_valor_aprovado_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor do fornecedor inválido (' || v_nome_item || ': ' ||
                  v_valor_fornecedor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_custo_unitario < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Preço unitário inválido (' || v_nome_item || ': ' || v_custo_unitario_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_quantidade < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Quantidade inválida (' || v_nome_item || ': ' || v_quantidade_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_frequencia < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência inválida (' || v_nome_item || ': ' || v_frequencia_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_bv < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de BV inválido (' || v_nome_item || ': ' || v_valor_bv_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_tip < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de TIP inválido (' || v_nome_item || ': ' || v_valor_tip_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_vetor_valor_sobra IS NOT NULL AND v_valor_sobra < 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de Sobra inválido (' || v_nome_item || ': ' || v_valor_sobra_char || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_121124
   IF v_carta_acordo_id = 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM pessoa
     WHERE pessoa_id = p_emp_emissora_id
       AND empresa_id = p_empresa_id
       AND flag_ativo = 'N';
    --
    IF v_qt <> 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não é possível realizar o check-in pois o cadastro do fornecedor está inativo e não foi emitida uma Carta Acordo no(s) item(ns) selecionados';
     RAISE v_exception;
    END IF;
   END IF;
   --
  /*
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               IF v_custo_unitario <> 0 OR v_quantidade <> 0 OR v_frequencia <> 0 THEN
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- o valor aprovado nao foi informado diretamente.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- verifica se o valor bate.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  v_valor_aprovado_aux := ROUND(v_custo_unitario*v_quantidade*v_frequencia,2);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  --
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  IF v_valor_aprovado <> v_valor_aprovado_aux THEN
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     p_erro_cod := '90000';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     p_erro_msg := 'Valor aprovado não bate com o valor calculado (' || v_nome_item || ': ' || 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    moeda_mostrar(v_valor_aprovado,'S') ||  ' e ' ||
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    moeda_mostrar(v_valor_aprovado_aux,'S') || ').';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     RAISE v_exception;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  END IF;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               END IF;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               */
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencia do credito usado
  ------------------------------------------------------------
  IF moeda_validar(p_valor_credito_usado) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito do fornecedor inválido (' || p_valor_credito_usado || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_credito_usado := nvl(moeda_converter(p_valor_credito_usado), 0);
  --
  IF v_valor_credito_usado < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do crédito do fornecedor inválido (' || p_valor_credito_usado || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros do documento
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor (empresa emissora) não existe (' || to_char(p_emp_emissora_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_tipo_doc NOT IN ('NCL', 'NBI', 'NFO') AND TRIM(p_num_doc) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número da nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_doc IN ('NCL', 'NBI', 'NFO') AND TRIM(p_num_doc) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de documento, o número não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_serie) > 2
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de série não pode ter mais que 2 caracteres .';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_emissao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de emissão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_emissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_entrada) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de entrada é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_entrada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada inválida.';
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam = 'CARTA_ACORDO'
  THEN
   IF rtrim(p_data_pri_vencim) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data do primeiro vencimento é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(p_data_pri_vencim) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data do primeiro vencimento inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_valor_bruto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor bruto da nota fiscal é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_bruto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_servico) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do serviço não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_valor_bruto     := nvl(moeda_converter(p_valor_bruto), 0);
  v_data_entrada    := data_converter(p_data_entrada);
  v_data_emissao    := data_converter(p_data_emissao);
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  --
  IF v_data_emissao > trunc(SYSDATE)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de emissão não pode ser uma data futura.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_entrada > trunc(SYSDATE)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de entrada não pode ser uma data futura.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_entrada < v_data_emissao
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de entrada deve ser maior que a data de emissão.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_pri_vencim < v_data_emissao
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data do primeiro vencimento deve ser maior que a data de emissão.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_bruto <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa de faturamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  /*
    IF p_emp_emissora_id = p_emp_faturar_por_id THEN
       p_erro_cod := '90000';
       p_erro_msg := 'A empresa emissora da nota fiscal não pode ser igual a empresa de faturamento.';
       RAISE v_exception;
    END IF;
  */
  --
  SELECT flag_emp_incentivo
    INTO v_flag_incentivo_fat
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  ------------------------------------------------------------
  -- consistencia das informacoes de repasse / receita
  ------------------------------------------------------------
  IF flag_validar(p_flag_repasse) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag repasse inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_patrocinio) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag patrocínio inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_repasse = 'S' AND TRIM(p_tipo_receita) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens de repasse não podem ser pagos com receita.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_patrocinio = 'S' AND TRIM(p_tipo_receita) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens patrocinados não podem ser pagos com receita.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pago_cliente = 'S' AND TRIM(p_tipo_receita) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens pagos pelo cliente não podem ser pagos com receita.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_pago_cliente = 'S' AND p_flag_patrocinio = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens pagos pelo cliente não podem ser patrocinados.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_item = 'A'
  THEN
   -- consistencias p/ itens de A
   IF nvl(p_emp_receita_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens de A, o preenchimento do responsável pelo ' ||
                  'repasse, patrocínio ou receita é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_repasse = 'N' AND p_flag_patrocinio = 'N' AND TRIM(p_tipo_receita) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens de A, a indicação de repasse, patrocínio ou ' ||
                  'receita é obrigatória.';
    RAISE v_exception;
   END IF;
  ELSE
   -- consistencias p/ itens de B e C
   IF p_flag_repasse = 'S' OR p_flag_patrocinio = 'S' OR TRIM(p_tipo_receita) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens de B e C, as informações de repasse, patrocínio ou ' ||
                  'receita não devem ser preenchidas.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_receita_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa responsável pelo repasse/receita não existe.';
    RAISE v_exception;
   END IF;
   --
   v_cliente_id := p_emp_receita_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL
  THEN
   -- o tipo de receita foi informado
   IF util_pkg.desc_retornar('tipo_receita', p_tipo_receita) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de receita inválida (' || p_tipo_receita || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_emp_receita_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa responsável pela receita deve ser especificada.';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_emp_incentivo
     INTO v_flag_incentivo_rec
     FROM pessoa
    WHERE pessoa_id = p_emp_receita_id;
   --
   IF util_pkg.desc_retornar('resp_pgto_receita', p_resp_pgto_receita) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Responsável pelo pgto da receita (fonte, ' || v_lbl_agencia_singular ||
                  ') inválido ' || 'ou não especificado.';
    RAISE v_exception;
   END IF;
   --
   IF p_tipo_receita = 'CONTRATO' AND p_resp_pgto_receita = 'FON'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Receitas de contratos devem ser pagas pela ' || v_lbl_agencia_singular || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- verifica se o cliente é uma empresa do grupo
  IF nvl(v_cliente_id, 0) = 0
  THEN
   v_flag_emp_fatur := 'S';
   v_flag_incentivo := 'N';
  ELSE
   SELECT flag_emp_fatur,
          flag_emp_incentivo
     INTO v_flag_emp_fatur,
          v_flag_incentivo
     FROM pessoa
    WHERE pessoa_id = v_cliente_id;
  END IF;
  --
  IF v_tipo_item = 'A'
  THEN
   -- consistencias p/ itens de A
   IF v_flag_emp_fatur = 'S' AND v_cliente_id <> v_cliente_job_id AND v_flag_incentivo = 'N'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens de A, o cliente/responsável não pode ser ' || 'uma empresa do grupo.';
    RAISE v_exception;
   END IF;
  ELSE
   -- consistencias p/ itens de B e C
   IF p_flag_patrocinio = 'N'
   THEN
    IF nvl(v_cliente_id, 0) <> 0 AND v_cliente_id <> p_emp_faturar_por_id
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para itens de B e C o cliente não deve ser preenchido ou deve ser ' ||
                   'a própria empresa de faturamento.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF p_flag_patrocinio = 'S' AND v_cliente_id = v_cliente_job_id
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para itens patrocinados, a empresa responsável não pode ser ' ||
                 'a mesma empresa cliente do ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos demais parametros
  ------------------------------------------------------------
  IF TRIM(p_uf_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do local do serviço é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_municipio_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do município do serviço é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NOT NULL
  THEN
   IF cep_pkg.municipio_validar(p_uf_servico, p_municipio_servico) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do local da prestação de serviço inválido (' || p_uf_servico || '/' ||
                  p_municipio_servico || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- se a empresa da receita for a 100% Incentivo, a empresa de
  -- faturamento tb deve ser.
  IF v_flag_incentivo_rec = 'S' AND v_flag_incentivo_fat <> 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quando a empresa da receita for a Incentivo, a empresa de ' ||
                 'faturamento "Faturar por" também deve ser.';
   RAISE v_exception;
  END IF;
  --
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
 END sub_checkin_consistir;
 --
 --
 PROCEDURE sub_itens_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 21/09/2012
  -- DESCRICAO: subrotina que adiciona itens na NOTA FISCAL.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  -- Silvia            13/06/2019  Ao final, limpa eventuais registros sem valores
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  -- Joel Dias         25/09/2023  Inclusão de sobras indicadas no check-in
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id         IN nota_fiscal.nota_fiscal_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_valor_bruto            nota_fiscal.valor_bruto%TYPE;
  v_tipo_receita           nota_fiscal.tipo_receita%TYPE;
  v_job_id                 nota_fiscal.job_id%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_item_id          VARCHAR2(8000);
  v_vetor_carta_acordo_id  VARCHAR2(8000);
  v_vetor_valor_aprovado   VARCHAR2(8000);
  v_vetor_valor_fornecedor VARCHAR2(8000);
  v_vetor_valor_bv         VARCHAR2(8000);
  v_vetor_valor_tip        VARCHAR2(8000);
  v_vetor_valor_sobra      VARCHAR2(8000);
  v_vetor_tipo_produto_id  VARCHAR2(8000);
  v_vetor_quantidade       VARCHAR2(8000);
  v_vetor_frequencia       VARCHAR2(8000);
  v_vetor_custo_unitario   VARCHAR2(8000);
  v_vetor_complemento      LONG;
  v_item_id                item.item_id%TYPE;
  v_tipo_item              item.tipo_item%TYPE;
  v_nome_item              VARCHAR2(100);
  v_carta_acordo_id        carta_acordo.carta_acordo_id%TYPE;
  v_perc_bv                carta_acordo.perc_bv%TYPE;
  v_perc_imposto           carta_acordo.perc_imposto%TYPE;
  v_tipo_produto_id        tipo_produto.tipo_produto_id%TYPE;
  v_sobra_id               sobra.sobra_id%TYPE;
  --
  v_valor_aprovado_char   VARCHAR2(50);
  v_valor_bv_char         VARCHAR2(50);
  v_valor_tip_char        VARCHAR2(50);
  v_valor_sobra_char      VARCHAR2(50);
  v_quantidade_char       VARCHAR2(50);
  v_frequencia_char       VARCHAR2(50);
  v_custo_unitario_char   VARCHAR2(50);
  v_complemento           VARCHAR2(2000);
  v_valor_aprovado        item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_char VARCHAR2(20);
  v_valor_fornecedor      item_nota.valor_fornecedor%TYPE;
  v_valor_bv              item_nota.valor_bv%TYPE;
  v_valor_tip             item_nota.valor_tip%TYPE;
  v_valor_sobra           sobra.valor_sobra%TYPE;
  v_quantidade            item_nota.quantidade%TYPE;
  v_frequencia            item_nota.frequencia%TYPE;
  v_custo_unitario        item_nota.custo_unitario%TYPE;
  v_item_nota_id          item_nota.item_nota_id%TYPE;
  v_num_ca                VARCHAR2(50);
  --
  v_valor_aprovado_it   item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_it item_nota.valor_fornecedor%TYPE;
  v_valor_bv_it         item_nota.valor_aprovado%TYPE;
  v_valor_tip_it        item_nota.valor_tip%TYPE;
  v_valor_sobra_it      sobra.valor_sobra%TYPE;
  v_valor_saldo_it      NUMBER;
  v_valor_liberado_b    NUMBER;
  --
  v_valor_aprovado_it_nf   item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_it_nf item_nota.valor_fornecedor%TYPE;
  v_valor_bv_it_nf         item_nota.valor_bv%TYPE;
  v_valor_tip_it_nf        item_nota.valor_tip%TYPE;
  v_valor_tip_sobra_nf     sobra.valor_sobra%TYPE;
  --
  v_valor_aprovado_ca   item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_ca item_nota.valor_fornecedor%TYPE;
  v_valor_bv_ca         item_nota.valor_aprovado%TYPE;
  v_valor_tip_ca        item_nota.valor_aprovado%TYPE;
  v_valor_sobra_ca      sobra.valor_sobra%TYPE;
  v_valor_saldo_ca      NUMBER;
  --
  v_valor_aprovado_ca_nf   item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor_ca_nf item_nota.valor_fornecedor%TYPE;
  v_valor_bv_ca_nf         item_nota.valor_bv%TYPE;
  v_valor_tip_ca_nf        item_nota.valor_tip%TYPE;
  v_valor_sobra_ca_nf      sobra.valor_sobra%TYPE;
  --
  v_orcamento_id         orcamento.orcamento_id%TYPE;
  v_orcamento_id_ant     orcamento.orcamento_id%TYPE;
  v_valor_pend           NUMBER;
  v_flag_calcular_bv_tip CHAR(1);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT valor_bruto,
         tipo_receita
    INTO v_valor_bruto,
         v_tipo_receita
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  --
  v_delimitador           := '|';
  v_flag_calcular_bv_tip  := 'N';
  v_vetor_item_id         := p_vetor_item_id;
  v_vetor_carta_acordo_id := p_vetor_carta_acordo_id;
  v_vetor_tipo_produto_id := p_vetor_tipo_produto_id;
  v_vetor_quantidade      := p_vetor_quantidade;
  v_vetor_frequencia      := p_vetor_frequencia;
  v_vetor_custo_unitario  := p_vetor_custo_unitario;
  v_vetor_complemento     := p_vetor_complemento;
  v_vetor_valor_aprovado  := p_vetor_valor_aprovado;
  --
  IF p_vetor_valor_fornecedor = 'CALCULAR' OR p_vetor_valor_bv = 'CALCULAR' OR
     p_vetor_valor_tip = 'CALCULAR'
  THEN
   --
   v_flag_calcular_bv_tip := 'S';
  END IF;
  --
  v_vetor_valor_fornecedor := p_vetor_valor_fornecedor;
  v_vetor_valor_bv         := p_vetor_valor_bv;
  v_vetor_valor_tip        := p_vetor_valor_tip;
  v_vetor_valor_sobra      := p_vetor_valor_sobra;
  --
  v_orcamento_id_ant := 0;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0 OR
        nvl(length(rtrim(v_vetor_carta_acordo_id)), 0) > 0
  LOOP
   --
   v_item_id             := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_carta_acordo_id     := nvl(to_number(prox_valor_retornar(v_vetor_carta_acordo_id,
                                                              v_delimitador)),
                                0);
   v_tipo_produto_id     := nvl(to_number(prox_valor_retornar(v_vetor_tipo_produto_id,
                                                              v_delimitador)),
                                0);
   v_quantidade_char     := prox_valor_retornar(v_vetor_quantidade, v_delimitador);
   v_frequencia_char     := prox_valor_retornar(v_vetor_frequencia, v_delimitador);
   v_custo_unitario_char := prox_valor_retornar(v_vetor_custo_unitario, v_delimitador);
   v_complemento         := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_valor_aprovado_char := prox_valor_retornar(v_vetor_valor_aprovado, v_delimitador);
   v_valor_sobra_char    := prox_valor_retornar(v_vetor_valor_sobra, v_delimitador);
   --
   IF v_flag_calcular_bv_tip = 'S' AND v_carta_acordo_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível calcular BV/TIP sem carta acordo (Item: ' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_calcular_bv_tip = 'N'
   THEN
    v_valor_fornecedor_char := prox_valor_retornar(v_vetor_valor_fornecedor, v_delimitador);
    v_valor_bv_char         := prox_valor_retornar(v_vetor_valor_bv, v_delimitador);
    v_valor_tip_char        := prox_valor_retornar(v_vetor_valor_tip, v_delimitador);
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_carta_acordo_id > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_carta
     WHERE item_id = v_item_id
       AND carta_acordo_id = v_carta_acordo_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse item não está associado a essa carta acordo (Item: ' || to_char(v_item_id) ||
                   ' Carta Acordo: ' || to_char(v_carta_acordo_id) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT nvl(perc_bv, 0),
           nvl(perc_imposto, 0),
           nvl(valor_aprovado, 0),
           nvl(valor_fornecedor, 0)
      INTO v_perc_bv,
           v_perc_imposto,
           v_valor_aprovado_ca,
           v_valor_fornecedor_ca
      FROM carta_acordo
     WHERE carta_acordo_id = v_carta_acordo_id;
   END IF;
   --
   SELECT item_pkg.num_item_retornar(item_id, 'N'),
          orcamento_id,
          job_id,
          tipo_item
     INTO v_nome_item,
          v_orcamento_id,
          v_job_id,
          v_tipo_item
     FROM item
    WHERE item_id = v_item_id;
   --
   -- verifica valores do check-in
   v_valor_aprovado := nvl(moeda_converter(v_valor_aprovado_char), 0);
   --
   IF v_flag_calcular_bv_tip = 'N'
   THEN
    -- usa os valores informados pelo usuario
    v_valor_fornecedor := nvl(moeda_converter(v_valor_fornecedor_char), 0);
    v_valor_bv         := nvl(moeda_converter(v_valor_bv_char), 0);
    v_valor_tip        := nvl(moeda_converter(v_valor_tip_char), 0);
   ELSE
    -- calcula os valores proporcionalmente
    v_valor_fornecedor := round(v_valor_aprovado * v_valor_fornecedor_ca / v_valor_aprovado_ca, 2);
    v_valor_bv         := round(v_valor_fornecedor * v_perc_bv / 100, 2);
    v_valor_tip        := round((v_valor_aprovado - v_valor_fornecedor) *
                                (1 - v_perc_imposto / 100),
                                2);
   END IF;
   --
   v_valor_sobra    := nvl(moeda_converter(v_valor_sobra_char), 0);
   v_custo_unitario := numero_converter(v_custo_unitario_char);
   v_quantidade     := numero_converter(v_quantidade_char);
   v_frequencia     := numero_converter(v_frequencia_char);
   --
   -- recupera valores definidos para o item
   v_valor_aprovado_it   := item_pkg.valor_retornar(v_item_id, 0, 'APROVADO');
   v_valor_fornecedor_it := item_pkg.valor_retornar(v_item_id, 0, 'FORNECEDOR');
   v_valor_bv_it         := item_pkg.valor_retornar(v_item_id, 0, 'BV');
   v_valor_tip_it        := item_pkg.valor_retornar(v_item_id, 0, 'TIP');
   v_valor_sobra_it      := item_pkg.valor_retornar(v_item_id, 0, 'SOBRA');
   --
   -- recupera valores ja lancados para o item (com NF)
   SELECT nvl(SUM(valor_aprovado), 0),
          nvl(SUM(valor_fornecedor), 0),
          nvl(SUM(valor_bv), 0),
          nvl(SUM(valor_tip), 0)
     INTO v_valor_aprovado_it_nf,
          v_valor_fornecedor_it_nf,
          v_valor_bv_it_nf,
          v_valor_tip_it_nf
     FROM item_nota
    WHERE item_id = v_item_id;
   --
   IF v_tipo_item = 'B'
   THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    -- 
    IF v_valor_aprovado > v_valor_liberado_b
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor aprovado da nova entrada não pode ser maior que ' ||
                   'o valor já liberado via faturamento (Item: ' || v_nome_item ||
                   '; Valor informado: ' || moeda_mostrar(v_valor_aprovado, 'S') ||
                   '; Valor liberado restante: ' || moeda_mostrar(v_valor_liberado_b, 'S') || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- verifica se vai estourar o saldo do item
   v_valor_saldo_it := v_valor_aprovado_it - v_valor_aprovado_it_nf;
   --
   IF v_valor_aprovado > v_valor_saldo_it
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor aprovado da nova entrada não pode ser maior que ' ||
                  'o saldo restante (Item: ' || v_nome_item || '; Valor informado: ' ||
                  moeda_mostrar(v_valor_aprovado, 'S') || '; Saldo restante: ' ||
                  moeda_mostrar(v_valor_saldo_it, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor > v_valor_aprovado
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor do fornecedor não pode ser maior que ' || 'o valor aprovado (Item:  ' ||
                  v_nome_item || '; Valor fornecedor: ' || moeda_mostrar(v_valor_fornecedor, 'S') ||
                  '; Valor aprovado: ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_tipo_receita) IS NOT NULL
   THEN
    v_valor_pend := faturamento_pkg.valor_retornar(v_item_id, 0, 'AFATURAR');
    --
    IF v_valor_aprovado > v_valor_pend
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse item não tem saldo a faturar suficiente (Item: ' || v_nome_item ||
                   '; Saldo: ' || moeda_mostrar(v_valor_pend, 'S') || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_carta_acordo_id > 0
   THEN
    v_num_ca := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
    --
    -- recupera valores definidos para o item x carta acordo
    v_valor_aprovado_ca    := item_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'APROVADO');
    v_valor_sobra_ca       := item_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'SOBRA');
    v_valor_aprovado_ca_nf := item_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'COM_NF');
    --
    -- verifica se vai estourar o saldo do item x carta acordo
    v_valor_saldo_ca := v_valor_aprovado_ca - v_valor_aprovado_ca_nf;
    --
    IF v_valor_aprovado > v_valor_saldo_ca
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor aprovado da nova entrada não pode ser maior que ' ||
                   'o saldo restante (Carta Acordo: ' || v_num_ca || '; Item: ' || v_nome_item ||
                   '; Valor informado: ' || moeda_mostrar(v_valor_aprovado, 'S') ||
                   '; Saldo restante: ' || moeda_mostrar(v_valor_saldo_ca, 'S') || ').';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(v_tipo_receita) IS NOT NULL
    THEN
     v_valor_pend := faturamento_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'AFATURAR');
     --
     IF v_valor_aprovado > v_valor_pend
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse item não tem saldo a faturar suficiente (Carta Acordo: ' || v_num_ca ||
                    '; Item: ' || v_nome_item || '; Saldo: ' || moeda_mostrar(v_valor_pend, 'S') || ').';
      RAISE v_exception;
     END IF;
    END IF;
    --
    -- recupera valores definidos para a carta acordo
    v_valor_aprovado_ca   := carta_acordo_pkg.valor_retornar(v_carta_acordo_id, 'APROVADO');
    v_valor_fornecedor_ca := carta_acordo_pkg.valor_retornar(v_carta_acordo_id, 'FORNECEDOR');
    v_valor_bv_ca         := carta_acordo_pkg.valor_retornar(v_carta_acordo_id, 'BV');
    v_valor_tip_ca        := carta_acordo_pkg.valor_retornar(v_carta_acordo_id, 'TIP');
    v_valor_sobra_ca      := carta_acordo_pkg.valor_retornar(v_carta_acordo_id, 'SOBRA');
    --
    -- recupera os valores ja lancados para a carta acordo (com NF)
    SELECT nvl(SUM(valor_aprovado), 0),
           nvl(SUM(valor_fornecedor), 0),
           nvl(SUM(valor_bv), 0),
           nvl(SUM(valor_tip), 0)
      INTO v_valor_aprovado_ca_nf,
           v_valor_fornecedor_ca_nf,
           v_valor_bv_ca_nf,
           v_valor_tip_ca_nf
      FROM item_nota
     WHERE carta_acordo_id = v_carta_acordo_id;
    --
    -- verifica se vai estourar o saldo da carta acordo
    v_valor_saldo_ca := v_valor_aprovado_ca - v_valor_aprovado_ca_nf;
    --
    IF v_valor_aprovado > v_valor_saldo_ca
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor aprovado da nova entrada não pode ser maior que ' ||
                   'o saldo restante (Carta Acordo: ' || v_num_ca || '; Item: ' || v_nome_item ||
                   '; Valor informado: ' || moeda_mostrar(v_valor_aprovado, 'S') ||
                   '; Saldo restante: ' || moeda_mostrar(v_valor_saldo_ca, 'S') || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_valor_fornecedor > v_valor_aprovado
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor do fornecedor não pode ser maior que ' ||
                   'o valor aprovado (Carta Acordo: ' || v_num_ca || '; Item ' || v_nome_item ||
                   '; Valor fornecedor: ' || moeda_mostrar(v_valor_fornecedor, 'S') ||
                   '; Valor aprovado: ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
     RAISE v_exception;
    END IF;
    --
    -- verifica se vai estourar o saldo do fornecedor
    IF v_valor_fornecedor > v_valor_fornecedor_ca - v_valor_fornecedor_ca_nf
    THEN
     IF v_flag_calcular_bv_tip = 'N'
     THEN
      IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                    'NOTA_FISCAL_AVF',
                                    v_orcamento_id,
                                    NULL,
                                    p_empresa_id) = 0
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para indicar um valor de fornecedor que resulte ' ||
                     'num total de fornecedor superior ao definido (Carta Acordo: ' || v_num_ca ||
                     '; Valor informado: ' || moeda_mostrar(v_valor_fornecedor, 'S') ||
                     '; Saldo restante: ' ||
                     moeda_mostrar(v_valor_fornecedor_ca - v_valor_fornecedor_ca_nf, 'S') || ').';
       RAISE v_exception;
      END IF;
     ELSE
      -- recalcula o custo do fornecedor com o saldo
      v_valor_fornecedor := v_valor_fornecedor_ca - v_valor_fornecedor_ca_nf;
     END IF;
    END IF;
    --
    -- verifica se esgotou o valor aprovado
    IF v_valor_aprovado = v_valor_saldo_ca
    THEN
     IF abs(v_valor_bv_ca - v_valor_bv_ca_nf - v_valor_bv) > 0.05
     THEN
      IF v_flag_calcular_bv_tip = 'N'
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Quando o check-in do valor total é completado, ' ||
                     'o BV também deve ser finalizado (Carta Acordo: ' || v_num_ca ||
                     '; BV informado: ' || moeda_mostrar(v_valor_bv, 'S') || '; BV restante: ' ||
                     moeda_mostrar(v_valor_bv_ca - v_valor_bv_ca_nf, 'S') || ').';
       RAISE v_exception;
      ELSE
       -- recalcula o BV com o saldo
       v_valor_bv := v_valor_bv_ca - v_valor_bv_ca_nf;
      END IF;
     END IF;
     --
     IF abs(v_valor_tip_ca - v_valor_tip_ca_nf - v_valor_tip) > 0.05
     THEN
      IF v_flag_calcular_bv_tip = 'N'
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Quando o check-in do valor total é completado, ' ||
                     'o TIP também deve ser finalizado (Carta Acordo: ' || v_num_ca ||
                     '; TIP informado: ' || moeda_mostrar(v_valor_tip, 'S') || '; TIP restante: ' ||
                     moeda_mostrar(v_valor_tip_ca - v_valor_tip_ca_nf, 'S') || ').';
       RAISE v_exception;
      ELSE
       -- recalcula o tip com o saldo
       v_valor_tip := v_valor_tip_ca - v_valor_tip_ca_nf;
      END IF;
     END IF;
    END IF;
   ELSE
    -- consistencias finais p/ check-in de item solto (sem carta acordo)
    IF v_valor_fornecedor > v_valor_fornecedor_it - v_valor_fornecedor_it_nf
    THEN
     IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                   'NOTA_FISCAL_AVF',
                                   v_orcamento_id,
                                   NULL,
                                   p_empresa_id) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Você não tem privilégio para indicar um valor de fornecedor que resulte ' ||
                    'num total de fornecedor superior ao definido (Item: ' || v_nome_item ||
                    '; Valor informado: ' || moeda_mostrar(v_valor_fornecedor, 'S') ||
                    '; Saldo restante: ' ||
                    moeda_mostrar(v_valor_fornecedor_it - v_valor_fornecedor_it_nf, 'S') || ').';
      RAISE v_exception;
     END IF;
    END IF;
   END IF;
   --
   SELECT MAX(item_nota_id)
     INTO v_item_nota_id
     FROM item_nota
    WHERE item_id = v_item_id
      AND nota_fiscal_id = p_nota_fiscal_id
      AND nvl(carta_acordo_id, -99) = zvl(v_carta_acordo_id, -99)
      AND nvl(tipo_produto_id, -99) = zvl(v_tipo_produto_id, -99)
      AND nvl(TRIM(complemento), 'ZZZZZ') = nvl(TRIM(v_complemento), 'ZZZZZ')
      AND nvl(zvl(custo_unitario, NULL), -99) = nvl(zvl(v_custo_unitario, NULL), -99);
   --
   IF v_item_nota_id IS NULL
   THEN
    INSERT INTO item_nota
     (item_nota_id,
      item_id,
      nota_fiscal_id,
      carta_acordo_id,
      valor_aprovado,
      valor_fornecedor,
      valor_bv,
      valor_tip,
      tipo_produto_id,
      quantidade,
      frequencia,
      custo_unitario,
      complemento)
    VALUES
     (seq_item_nota.nextval,
      v_item_id,
      p_nota_fiscal_id,
      zvl(v_carta_acordo_id, NULL),
      v_valor_aprovado,
      v_valor_fornecedor,
      v_valor_bv,
      v_valor_tip,
      zvl(v_tipo_produto_id, NULL),
      v_quantidade,
      v_frequencia,
      v_custo_unitario,
      v_complemento);
   ELSE
    UPDATE item_nota
       SET valor_aprovado   = valor_aprovado + v_valor_aprovado,
           valor_fornecedor = valor_fornecedor + v_valor_fornecedor,
           valor_bv         = valor_bv + v_valor_bv,
           valor_tip        = valor_tip + v_valor_tip
     WHERE item_nota_id = v_item_nota_id;
   END IF;
   --
   -- inclusão de sobras
   IF v_valor_sobra > 0
   THEN
    sobra_pkg.adicionar(p_usuario_sessao_id --p_usuario_sessao_id
                       ,
                        p_empresa_id --p_empresa_id
                       ,
                        v_job_id --p_job_id
                       ,
                        NULL --p_carta_acordo_id
                       ,
                        v_item_id --p_vetor_item_id
                       ,
                        v_valor_sobra_char,
                        'SOB' --p_tipo_sobra (Sobra)
                       ,
                        NULL --p_tipo_extra
                       ,
                        'Sobra indicada durante o check-in com o documento: ' || '<nota_fiscal_id>' ||
                        p_nota_fiscal_id || '</nota_fiscal_id>' --p_justificativa
                       ,
                        'N' --p_flag_commit
                       ,
                        v_sobra_id --p_sobra_id
                       ,
                        p_erro_cod,
                        p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- recalcula os saldos oo item
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF v_orcamento_id <> v_orcamento_id_ant
   THEN
    -- quebra de estimativa. Recalcula os saldos dos acessorios
    -- (honorarios, encargos, etc) da estimativa.
    orcamento_pkg.saldos_acessorios_recalcular(p_usuario_sessao_id,
                                               v_orcamento_id,
                                               p_erro_cod,
                                               p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   v_orcamento_id_ant := v_orcamento_id;
  END LOOP;
  --
  -- limpa eventuais registros sem valores
  DELETE FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id
     AND valor_aprovado = 0
     AND valor_fornecedor = 0
     AND valor_bv = 0
     AND valor_tip = 0
     AND nvl(quantidade, 0) * nvl(frequencia, 0) * nvl(custo_unitario, 0) = 0;
  --
  IF v_orcamento_id_ant > 0
  THEN
   -- Recalcula os saldos dos acessorios da ultima estimativa
   orcamento_pkg.saldos_acessorios_recalcular(p_usuario_sessao_id,
                                              v_orcamento_id_ant,
                                              p_erro_cod,
                                              p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
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
 END sub_itens_adicionar;
 --
 --
 PROCEDURE sub_impostos_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 21/09/2012
  -- DESCRICAO: subrotina que faz o calculo inicial de impostos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/03/2015  limite retencao de INSS apenas para PF
  -- Silvia            05/08/2016  Parametro que habilita ou nao calculo do imposto.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_valor_mao_obra    IN VARCHAR2,
  p_valor_base_iss    IN VARCHAR2,
  p_valor_base_ir     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_emp_emissora_id       nota_fiscal.emp_emissora_id%TYPE;
  v_data_emissao          nota_fiscal.data_emissao%TYPE;
  v_resp_pgto_receita     nota_fiscal.resp_pgto_receita%TYPE;
  v_valor_mao_obra        nota_fiscal.valor_mao_obra%TYPE;
  v_valor_base_iss        nota_fiscal.valor_mao_obra%TYPE;
  v_valor_base_ir         nota_fiscal.valor_mao_obra%TYPE;
  v_valor_bruto           nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum      nota_fiscal.valor_bruto%TYPE;
  v_flag_pessoa_jur       pessoa.flag_pessoa_jur%TYPE;
  v_flag_fornec_interno   pessoa.flag_fornec_interno%TYPE;
  v_valor_faixa_retencao  pessoa.valor_faixa_retencao%TYPE;
  v_flag_ret_imposto      tipo_doc_nf.flag_ret_imposto%TYPE;
  v_num_seq               imposto_nota.num_seq%TYPE;
  v_valor_tributado       imposto_nota.valor_tributado%TYPE;
  v_valor_base_calc       imposto_nota.valor_base_calc%TYPE;
  v_perc_imposto_sugerido imposto_nota.perc_imposto_sugerido%TYPE;
  v_perc_imposto_nota     imposto_nota.perc_imposto_nota%TYPE;
  v_valor_deducao         imposto_nota.valor_deducao%TYPE;
  v_valor_imposto_base    imposto_nota.valor_imposto_base%TYPE;
  v_valor_imposto_acum    imposto_nota.valor_imposto_acum%TYPE;
  v_valor_imposto_liq     imposto_nota.valor_imposto%TYPE;
  v_cod_retencao          imposto_nota.cod_retencao%TYPE;
  v_flag_reter            imposto_nota.flag_reter%TYPE;
  v_municipio_servico     orcamento.municipio_servico%TYPE;
  v_uf_servico            orcamento.uf_servico%TYPE;
  v_qt_org_publ           INTEGER;
  v_calcula_imposto       VARCHAR2(10);
  --
  CURSOR c_tipo_imp IS
   SELECT fi_tipo_imposto_id,
          cod_imposto,
          perc_padrao,
          perc_altern1,
          valor_faixa_retencao,
          valor_minimo,
          valor_maximo,
          cod_retencao_padrao,
          cod_retencao_altern1
     FROM fi_tipo_imposto
    WHERE flag_incide_ent = 'S'
    ORDER BY ordem;
  --
 BEGIN
  v_qt              := 0;
  v_calcula_imposto := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_CALCULO_IMPOSTO');
  --
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
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT td.flag_ret_imposto,
         nf.valor_bruto,
         nf.data_emissao,
         pe.flag_fornec_interno,
         pe.flag_pessoa_jur,
         nf.resp_pgto_receita,
         nf.valor_faixa_retencao,
         nf.emp_emissora_id,
         nf.municipio_servico,
         nf.uf_servico
    INTO v_flag_ret_imposto,
         v_valor_bruto,
         v_data_emissao,
         v_flag_fornec_interno,
         v_flag_pessoa_jur,
         v_resp_pgto_receita,
         v_valor_faixa_retencao,
         v_emp_emissora_id,
         v_municipio_servico,
         v_uf_servico
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  SELECT COUNT(*)
    INTO v_qt_org_publ
    FROM tipific_pessoa tp,
         tipo_pessoa    ti
   WHERE tp.pessoa_id = v_emp_emissora_id
     AND tp.tipo_pessoa_id = ti.tipo_pessoa_id
     AND ti.codigo LIKE 'ORG_PUB%';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF moeda_validar(p_valor_mao_obra) = 0 OR TRIM(p_valor_mao_obra) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_base_iss) = 0 OR TRIM(p_valor_base_iss) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do ISS inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_base_ir) = 0 OR TRIM(p_valor_base_ir) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do IR inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_mao_obra := nvl(moeda_converter(p_valor_mao_obra), 0);
  v_valor_base_iss := nvl(moeda_converter(p_valor_base_iss), 0);
  v_valor_base_ir  := nvl(moeda_converter(p_valor_base_ir), 0);
  --
  IF v_valor_mao_obra < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_iss < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do ISS inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_ir < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do IR inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_iss > 0 AND (TRIM(v_municipio_servico) IS NULL OR TRIM(v_uf_servico) IS NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para check-in com ISS, a UF e o município da prestação de ' ||
                 'serviço devem ser informados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- calculo dos impostos da nota
  ------------------------------------------------------------
  DELETE FROM imposto_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_flag_ret_imposto = 'S' AND v_calcula_imposto = 'S' AND nvl(v_flag_fornec_interno, 'N') = 'N' AND
     v_qt_org_publ = 0 AND nvl(v_resp_pgto_receita, 'XXX') <> 'FON'
  THEN
   -- documento do tipo que tem imposto;
   -- calculo do imposto habilitado;
   -- os itens nao sao do tipo fornecedor interno, nem orgao publico;
   -- nao se trata de receita paga pela fonte.
   -- Precisa criar e calcular os impostos.
   v_num_seq := 0;
   --
   v_valor_bruto_acum := imposto_pkg.valor_bruto_acum_retornar(p_nota_fiscal_id);
   --
   FOR r_tipo_imp IN c_tipo_imp
   LOOP
    --
    v_flag_reter            := 'S';
    v_valor_tributado       := v_valor_bruto;
    v_valor_deducao         := 0;
    v_valor_imposto_acum    := 0;
    v_perc_imposto_sugerido := NULL;
    v_cod_retencao          := NULL;
    --
    -----------------------------------
    -- tratamento de INSS
    -----------------------------------
    IF r_tipo_imp.cod_imposto = 'INSS'
    THEN
     v_valor_tributado := v_valor_mao_obra;
     v_valor_base_calc := v_valor_mao_obra;
     --
     -- verifica se o fornecedor tem aliquota definida
     SELECT MAX(perc_imposto)
       INTO v_perc_imposto_sugerido
       FROM fi_tipo_imposto_pessoa
      WHERE pessoa_id = v_emp_emissora_id
        AND fi_tipo_imposto_id = r_tipo_imp.fi_tipo_imposto_id;
     --
     IF v_flag_pessoa_jur = 'S'
     THEN
      -- pessoa juridica
      IF v_perc_imposto_sugerido IS NULL
      THEN
       -- fornecedor sem aliquota definida.
       -- pega o default para esse tipo de imposto
       v_perc_imposto_sugerido := nvl(r_tipo_imp.perc_padrao, 0);
      END IF;
      --
      v_cod_retencao := r_tipo_imp.cod_retencao_padrao;
     ELSIF v_flag_pessoa_jur = 'N'
     THEN
      -- pessoa fisica
      IF v_perc_imposto_sugerido IS NULL
      THEN
       -- fornecedor sem aliquota definida.
       -- pega o default para esse tipo de imposto
       v_perc_imposto_sugerido := nvl(r_tipo_imp.perc_altern1, 0);
      END IF;
      --
      v_cod_retencao := r_tipo_imp.cod_retencao_altern1;
     END IF;
     --
     v_perc_imposto_nota  := v_perc_imposto_sugerido;
     v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2);
     --
     IF v_valor_imposto_base < r_tipo_imp.valor_minimo
     THEN
      v_valor_imposto_liq := 0;
     ELSE
      v_valor_imposto_liq := v_valor_imposto_base;
     END IF;
     --
     IF v_flag_pessoa_jur = 'N' AND v_valor_imposto_base > r_tipo_imp.valor_maximo
     THEN
      -- limite apenas para pessoa fisica
      v_valor_imposto_liq := r_tipo_imp.valor_maximo;
     ELSE
      v_valor_imposto_liq := v_valor_imposto_base;
     END IF;
    END IF; -- fim do INSS
    --
    -----------------------------------
    -- tratamento de ISS
    -----------------------------------
    IF r_tipo_imp.cod_imposto = 'ISS'
    THEN
     -- verifica se o fornecedor tem aliquota definida
     SELECT MAX(perc_imposto)
       INTO v_perc_imposto_sugerido
       FROM fi_tipo_imposto_pessoa
      WHERE pessoa_id = v_emp_emissora_id
        AND fi_tipo_imposto_id = r_tipo_imp.fi_tipo_imposto_id;
     --
     IF v_perc_imposto_sugerido IS NULL
     THEN
      IF v_municipio_servico IS NOT NULL AND v_uf_servico IS NOT NULL
      THEN
       SELECT MAX(perc_iss)
         INTO v_perc_imposto_sugerido
         FROM cep_cidade ci,
              cep_uf     uf
        WHERE uf.uf_sigla = v_uf_servico
          AND uf.uf_id = ci.uf_id
          AND acento_retirar(ci.cidade_descricao) = acento_retirar(v_municipio_servico);
      END IF;
     END IF;
     --
     IF v_perc_imposto_sugerido IS NULL
     THEN
      -- nenhum percentual definido.
      -- pega o default para esse tipo de imposto
      v_perc_imposto_sugerido := nvl(r_tipo_imp.perc_padrao, 0);
     END IF;
     --
     v_valor_tributado    := v_valor_base_iss;
     v_valor_base_calc    := v_valor_base_iss;
     v_cod_retencao       := r_tipo_imp.cod_retencao_padrao;
     v_perc_imposto_nota  := v_perc_imposto_sugerido;
     v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2);
     v_valor_imposto_liq  := v_valor_imposto_base;
    END IF; -- fim do ISS
    --
    -----------------------------------
    -- tratamento de IRRF
    -----------------------------------
    IF r_tipo_imp.cod_imposto = 'IRRF'
    THEN
     v_valor_tributado := v_valor_base_ir;
     v_valor_base_calc := v_valor_base_ir;
     --
     -- verifica se o fornecedor tem aliquota definida (só juridica)
     IF v_flag_pessoa_jur = 'S'
     THEN
      SELECT MAX(perc_imposto)
        INTO v_perc_imposto_sugerido
        FROM fi_tipo_imposto_pessoa
       WHERE pessoa_id = v_emp_emissora_id
         AND fi_tipo_imposto_id = r_tipo_imp.fi_tipo_imposto_id;
     END IF;
     --
     IF v_perc_imposto_sugerido IS NULL
     THEN
      -- fornecedor sem aliquota definida.
      -- pega o default para esse tipo de imposto
      IF v_flag_pessoa_jur = 'S'
      THEN
       -- pessoa juridica
       v_perc_imposto_sugerido := nvl(r_tipo_imp.perc_padrao, 0);
       v_cod_retencao          := r_tipo_imp.cod_retencao_padrao;
      ELSE
       -- pessoa fisica
       v_cod_retencao := r_tipo_imp.cod_retencao_altern1;
       --
       IF r_tipo_imp.perc_altern1 IS NOT NULL
       THEN
        v_perc_imposto_sugerido := r_tipo_imp.perc_altern1;
       ELSE
        SELECT MAX(perc_imposto),
               MAX(valor_deducao)
          INTO v_perc_imposto_sugerido,
               v_valor_deducao
          FROM fi_tipo_imposto_faixa
         WHERE fi_tipo_imposto_id = r_tipo_imp.fi_tipo_imposto_id
           AND v_data_emissao BETWEEN data_vigencia_ini AND data_vigencia_fim
           AND v_valor_base_calc BETWEEN valor_base_ini AND valor_base_fim;
        --
        IF v_perc_imposto_sugerido IS NULL
        THEN
         p_erro_cod := '90000';
         p_erro_msg := 'A tabela progressiva para retenção de imposto de ' ||
                       'renda de pessoa física não está configurada.';
         RAISE v_exception;
        END IF;
       END IF;
      END IF;
     ELSE
      IF v_flag_pessoa_jur = 'S'
      THEN
       v_cod_retencao := r_tipo_imp.cod_retencao_padrao;
      ELSE
       v_cod_retencao := r_tipo_imp.cod_retencao_altern1;
      END IF;
     END IF;
     --
     v_perc_imposto_nota  := v_perc_imposto_sugerido;
     v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2) -
                             v_valor_deducao;
     --
     IF v_valor_imposto_base < r_tipo_imp.valor_minimo
     THEN
      v_valor_imposto_liq := 0;
     ELSE
      v_valor_imposto_liq := v_valor_imposto_base;
     END IF;
    END IF; -- fim do IRRF
    --
    -----------------------------------
    -- tratamento de PIS, COFINS, CSLL
    -----------------------------------
    IF r_tipo_imp.cod_imposto IN ('RET-PIS', 'RET-COFINS', 'RET-CSLL')
    THEN
     -- verifica se o fornecedor tem aliquota definida
     SELECT MAX(perc_imposto)
       INTO v_perc_imposto_sugerido
       FROM fi_tipo_imposto_pessoa
      WHERE pessoa_id = v_emp_emissora_id
        AND fi_tipo_imposto_id = r_tipo_imp.fi_tipo_imposto_id;
     --
     v_cod_retencao := r_tipo_imp.cod_retencao_padrao;
     --
     IF v_perc_imposto_sugerido IS NULL
     THEN
      -- fornecedor sem aliquota definida.
      -- pega o default para esse tipo de imposto
      v_perc_imposto_sugerido := nvl(r_tipo_imp.perc_padrao, 0);
     END IF;
     --
     -- verifica se o fornecedor tem faixa de retencao definida
     IF v_valor_faixa_retencao IS NULL
     THEN
      -- nao tem. Pega o default.
      v_valor_faixa_retencao := nvl(r_tipo_imp.valor_faixa_retencao, 0);
     END IF;
     --
     v_valor_imposto_acum := imposto_pkg.imposto_retido_retornar(r_tipo_imp.fi_tipo_imposto_id,
                                                                 p_nota_fiscal_id);
     --
     v_perc_imposto_nota  := v_perc_imposto_sugerido;
     v_valor_base_calc    := v_valor_tributado + v_valor_bruto_acum;
     v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2) -
                             v_valor_deducao;
     --
     IF v_valor_base_calc > v_valor_faixa_retencao
     THEN
      v_valor_imposto_liq := v_valor_imposto_base - v_valor_imposto_acum;
     ELSE
      v_valor_imposto_liq := 0;
     END IF;
    END IF; -- fim do PIS,COFINS, CSLL
    --
    -----------------------------------
    -- insere o registro do imposto
    -----------------------------------
    IF r_tipo_imp.cod_imposto IN ('INSS', 'ISS', 'IRRF', 'RET-PIS', 'RET-COFINS', 'RET-CSLL')
    THEN
     v_num_seq := v_num_seq + 1;
     --
     IF v_valor_imposto_liq < 0
     THEN
      v_valor_imposto_liq := 0;
     END IF;
     --
     IF v_valor_imposto_liq = 0
     THEN
      v_flag_reter := 'N';
     END IF;
     --
     INSERT INTO imposto_nota
      (imposto_nota_id,
       nota_fiscal_id,
       fi_tipo_imposto_id,
       num_seq,
       valor_tributado,
       valor_base_calc,
       perc_imposto_sugerido,
       perc_imposto_nota,
       valor_deducao,
       valor_imposto_acum,
       valor_imposto_base,
       valor_imposto,
       cod_retencao,
       flag_reter)
     VALUES
      (seq_imposto_nota.nextval,
       p_nota_fiscal_id,
       r_tipo_imp.fi_tipo_imposto_id,
       v_num_seq,
       v_valor_tributado,
       v_valor_base_calc,
       v_perc_imposto_sugerido,
       v_perc_imposto_nota,
       v_valor_deducao,
       v_valor_imposto_acum,
       v_valor_imposto_base,
       v_valor_imposto_liq,
       v_cod_retencao,
       v_flag_reter);
    END IF;
   END LOOP;
   --
   UPDATE nota_fiscal
      SET valor_faixa_retencao = nvl(v_valor_faixa_retencao, 0),
          valor_mao_obra       = v_valor_mao_obra
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  ELSE
   ------------------------------------------------------------
   -- criacao dos impostos no caso de isentos
   ------------------------------------------------------------
   -- os itens sao do tipo fornecedor interno ou orgao publico, ou
   -- se trata de nota de debito, ou receita paga pela fonte.
   -- Cria os impostos zerados.
   v_num_seq := 0;
   --
   FOR r_tipo_imp IN c_tipo_imp
   LOOP
    IF r_tipo_imp.cod_imposto IN ('INSS', 'ISS', 'IRRF', 'RET-PIS', 'RET-COFINS', 'RET-CSLL')
    THEN
     v_num_seq := v_num_seq + 1;
     --
     INSERT INTO imposto_nota
      (imposto_nota_id,
       nota_fiscal_id,
       fi_tipo_imposto_id,
       num_seq,
       valor_tributado,
       valor_base_calc,
       perc_imposto_sugerido,
       perc_imposto_nota,
       valor_deducao,
       valor_imposto_acum,
       valor_imposto_base,
       valor_imposto,
       cod_retencao,
       flag_reter)
     VALUES
      (seq_imposto_nota.nextval,
       p_nota_fiscal_id,
       r_tipo_imp.fi_tipo_imposto_id,
       v_num_seq,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       NULL,
       'N');
    END IF;
   END LOOP;
   --
   UPDATE nota_fiscal
      SET valor_faixa_retencao = 0
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  --
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
 END sub_impostos_calcular;
 --
 --
 PROCEDURE sub_impostos_completar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/04/2007
  -- DESCRICAO: subrotina de atualização de impostos e valores de duplicatas de NOTA_FISCAL 
  --    de entrada. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/01/2016  Ajuste em calculo de INSS pessoa juridica.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id            IN nota_fiscal.nota_fiscal_id%TYPE,
  p_valor_mao_obra            IN VARCHAR2,
  p_valor_base_iss            IN VARCHAR2,
  p_valor_base_ir             IN VARCHAR2,
  p_fi_banco_cobrador_id      IN nota_fiscal.fi_banco_cobrador_id%TYPE,
  p_vetor_data_vencim         IN VARCHAR2,
  p_vetor_valor_duplicata     IN VARCHAR2,
  p_vetor_fi_tipo_imposto     IN VARCHAR2,
  p_vetor_perc_imposto        IN VARCHAR2,
  p_fi_tipo_imposto_pessoa_id IN fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE,
  p_flag_reter_iss            IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_motivo_alt_aliquota       IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_job_id                job.job_id%TYPE;
  v_emp_emissora_id       nota_fiscal.emp_emissora_id%TYPE;
  v_data_emissao          nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim       nota_fiscal.data_pri_vencim%TYPE;
  v_valor_bruto           nota_fiscal.valor_bruto%TYPE;
  v_num_doc               nota_fiscal.num_doc%TYPE;
  v_tipo_doc              tipo_doc_nf.codigo%TYPE;
  v_serie                 nota_fiscal.serie%TYPE;
  v_motivo_alt_aliquota   nota_fiscal.motivo_alt_aliquota%TYPE;
  v_valor_mao_obra        nota_fiscal.valor_mao_obra%TYPE;
  v_valor_base_iss        nota_fiscal.valor_mao_obra%TYPE;
  v_valor_base_ir         nota_fiscal.valor_mao_obra%TYPE;
  v_municipio_servico     nota_fiscal.municipio_servico%TYPE;
  v_uf_servico            nota_fiscal.uf_servico%TYPE;
  v_emp_apelido           pessoa.apelido%TYPE;
  v_emp_cnpj              pessoa.cnpj%TYPE;
  v_flag_pessoa_jur       pessoa.flag_pessoa_jur%TYPE;
  v_delimitador           CHAR(1);
  v_vetor_valor_duplicata VARCHAR2(4000);
  v_vetor_data_vencim     VARCHAR2(4000);
  v_vetor_fi_tipo_imposto VARCHAR2(4000);
  v_vetor_perc_imposto    VARCHAR2(4000);
  v_valor_duplicata_char  VARCHAR2(20);
  v_data_vencim_char      VARCHAR2(20);
  v_perc_imposto_char     VARCHAR2(20);
  v_data_vencim           duplicata.data_vencim%TYPE;
  v_data_vencim_ant       duplicata.data_vencim%TYPE;
  v_valor_duplicata       duplicata.valor_duplicata%TYPE;
  v_valor_parcela_ult     duplicata.valor_duplicata%TYPE;
  v_valor_parcela_ant     duplicata.valor_duplicata%TYPE;
  v_valor_parcela_aju     duplicata.valor_duplicata%TYPE;
  v_duplicata_id          duplicata.duplicata_id%TYPE;
  v_num_parcela           duplicata.num_parcela%TYPE;
  v_valor_dupli_tot       NUMBER;
  v_valor_imposto_tot     NUMBER;
  v_fi_tipo_imposto_id    imposto_nota.fi_tipo_imposto_id%TYPE;
  v_perc_imposto_nota     imposto_nota.perc_imposto_nota%TYPE;
  v_perc_imposto_sugerido imposto_nota.perc_imposto_sugerido%TYPE;
  v_valor_base_calc       imposto_nota.valor_base_calc%TYPE;
  v_valor_imposto_base    imposto_nota.valor_imposto_base%TYPE;
  v_valor_imposto_liq     imposto_nota.valor_imposto%TYPE;
  v_valor_deducao         imposto_nota.valor_deducao%TYPE;
  v_valor_imposto_acum    imposto_nota.valor_imposto_acum%TYPE;
  v_flag_reter            imposto_nota.flag_reter%TYPE;
  v_cod_retencao          imposto_nota.cod_retencao%TYPE;
  v_cod_imposto           fi_tipo_imposto.cod_imposto%TYPE;
  v_cod_retencao_padrao   fi_tipo_imposto.cod_retencao_padrao%TYPE;
  v_cod_retencao_altern1  fi_tipo_imposto.cod_retencao_altern1%TYPE;
  v_valor_minimo          fi_tipo_imposto.valor_minimo%TYPE;
  v_valor_maximo          fi_tipo_imposto.valor_maximo%TYPE;
  v_nome_servico          fi_tipo_imposto_pessoa.nome_servico%TYPE;
  v_valor_faixa_retencao  pessoa.valor_faixa_retencao%TYPE;
  v_flag_mudou            CHAR(1);
  v_qt_agrupado           INTEGER;
  v_usa_duplicata         VARCHAR2(10);
  --
 BEGIN
  v_qt            := 0;
  v_usa_duplicata := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_DUPLICATAS_CHECKIN');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.emp_emissora_id,
         nf.data_emissao,
         nf.data_pri_vencim,
         nf.job_id,
         nf.num_doc,
         nf.serie,
         nf.valor_bruto,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         pe.flag_pessoa_jur,
         nf.valor_faixa_retencao,
         td.codigo,
         nf.municipio_servico,
         nf.uf_servico
    INTO v_emp_emissora_id,
         v_data_emissao,
         v_data_pri_vencim,
         v_job_id,
         v_num_doc,
         v_serie,
         v_valor_bruto,
         v_emp_apelido,
         v_emp_cnpj,
         v_flag_pessoa_jur,
         v_valor_faixa_retencao,
         v_tipo_doc,
         v_municipio_servico,
         v_uf_servico
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_reter_iss) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag reter inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_mao_obra) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_base_iss) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do ISS inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_base_ir) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do IR inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_mao_obra := nvl(moeda_converter(p_valor_mao_obra), 0);
  v_valor_base_iss := nvl(moeda_converter(p_valor_base_iss), 0);
  v_valor_base_ir  := nvl(moeda_converter(p_valor_base_ir), 0);
  --
  IF v_valor_mao_obra < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_iss < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do ISS inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_ir < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor para base de cálculo do IR inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_base_iss > 0 AND (TRIM(v_municipio_servico) IS NULL OR TRIM(v_uf_servico) IS NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para check-in com ISS, a UF e o município da prestação de ' ||
                 'serviço devem ser informados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores das duplicatas
  ------------------------------------------------------------
  IF v_usa_duplicata = 'S'
  THEN
   v_delimitador     := '|';
   v_num_parcela     := 0;
   v_valor_dupli_tot := 0;
   v_data_vencim_ant := data_converter('01/01/1970');
   --
   DELETE FROM duplicata
    WHERE nota_fiscal_id = p_nota_fiscal_id;
   --
   v_vetor_valor_duplicata := p_vetor_valor_duplicata;
   v_vetor_data_vencim     := p_vetor_data_vencim;
   --
   WHILE nvl(length(rtrim(v_vetor_valor_duplicata)), 0) > 0
   LOOP
    v_valor_duplicata_char := prox_valor_retornar(v_vetor_valor_duplicata, v_delimitador);
    v_data_vencim_char     := prox_valor_retornar(v_vetor_data_vencim, v_delimitador);
    --
    IF data_validar(v_data_vencim_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da duplicata inválida (' || v_data_vencim_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_duplicata_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da duplicata inválido (' || v_valor_duplicata_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_valor_duplicata := nvl(moeda_converter(v_valor_duplicata_char), 0);
    v_data_vencim     := data_converter(v_data_vencim_char);
    --
    IF v_data_vencim IS NOT NULL AND v_valor_duplicata <= 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor inválido para a duplicata com data de ' || data_mostrar(v_data_vencim) || '( ' ||
                   v_valor_duplicata_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_data_vencim IS NULL AND v_valor_duplicata <> 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data inválida para a duplicata com valor de ' ||
                   moeda_mostrar(v_valor_duplicata, 'S') || '.';
     RAISE v_exception;
    END IF;
    --
    IF v_data_vencim IS NOT NULL
    THEN
     IF v_data_vencim <= v_data_vencim_ant
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'As datas de vencimento das duplicatas ' || 'devem estar em ordem crescente.';
      RAISE v_exception;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_dupli_tot := v_valor_dupli_tot + v_valor_duplicata;
     v_data_vencim_ant := v_data_vencim;
     --
     IF v_num_parcela = 1 AND v_data_vencim <> v_data_pri_vencim
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data de vencimento da primeira duplicata não pode ser alterada (' ||
                    data_mostrar(v_data_pri_vencim) || ').';
      RAISE v_exception;
     END IF;
    END IF;
    --
    IF v_valor_duplicata > 0 AND v_data_vencim IS NOT NULL
    THEN
     SELECT seq_duplicata.nextval
       INTO v_duplicata_id
       FROM dual;
     --
     INSERT INTO duplicata
      (duplicata_id,
       nota_fiscal_id,
       num_parcela,
       num_tot_parcelas,
       num_duplicata,
       valor_duplicata,
       data_vencim)
     VALUES
      (v_duplicata_id,
       p_nota_fiscal_id,
       v_num_parcela,
       0,
       to_char(v_num_parcela),
       v_valor_duplicata,
       v_data_vencim);
    END IF;
   END LOOP;
   --
   -- acerta o total de parcelas
   UPDATE duplicata
      SET num_tot_parcelas = v_num_parcela
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de impostos
  ------------------------------------------------------------
  IF TRIM(p_valor_mao_obra) IS NOT NULL
  THEN
   -- a inteface pode ter alterado o valor base
   UPDATE imposto_nota ip
      SET valor_tributado = v_valor_mao_obra,
          valor_base_calc = v_valor_mao_obra
    WHERE ip.nota_fiscal_id = p_nota_fiscal_id
      AND fi_tipo_imposto_id = (SELECT fi_tipo_imposto_id
                                  FROM fi_tipo_imposto
                                 WHERE cod_imposto = 'INSS');
  END IF;
  --
  IF TRIM(p_valor_base_iss) IS NOT NULL
  THEN
   -- a inteface pode ter alterado o valor base
   UPDATE imposto_nota ip
      SET valor_tributado = v_valor_base_iss,
          valor_base_calc = v_valor_base_iss
    WHERE ip.nota_fiscal_id = p_nota_fiscal_id
      AND fi_tipo_imposto_id = (SELECT fi_tipo_imposto_id
                                  FROM fi_tipo_imposto
                                 WHERE cod_imposto = 'ISS');
  END IF;
  --
  IF TRIM(p_valor_base_ir) IS NOT NULL
  THEN
   -- a inteface pode ter alterado o valor base
   UPDATE imposto_nota ip
      SET valor_tributado = v_valor_base_ir,
          valor_base_calc = v_valor_base_ir
    WHERE ip.nota_fiscal_id = p_nota_fiscal_id
      AND fi_tipo_imposto_id = (SELECT fi_tipo_imposto_id
                                  FROM fi_tipo_imposto
                                 WHERE cod_imposto = 'IRRF');
  END IF;
  -- 
  v_flag_mudou        := 'N';
  v_qt_agrupado       := 0;
  v_valor_imposto_tot := 0;
  v_delimitador       := '|';
  --
  v_vetor_fi_tipo_imposto := p_vetor_fi_tipo_imposto;
  v_vetor_perc_imposto    := p_vetor_perc_imposto;
  --
  WHILE nvl(length(rtrim(v_vetor_fi_tipo_imposto)), 0) > 0
  LOOP
   v_fi_tipo_imposto_id := to_number(prox_valor_retornar(v_vetor_fi_tipo_imposto, v_delimitador));
   v_perc_imposto_char  := prox_valor_retornar(v_vetor_perc_imposto, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_tipo_imposto
    WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Erro na seleção do imposto.';
    RAISE v_exception;
   END IF;
   --
   SELECT cod_imposto,
          valor_minimo,
          valor_maximo,
          cod_retencao_padrao,
          cod_retencao_altern1
     INTO v_cod_imposto,
          v_valor_minimo,
          v_valor_maximo,
          v_cod_retencao_padrao,
          v_cod_retencao_altern1
     FROM fi_tipo_imposto
    WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id;
   --
   IF taxa_validar(v_perc_imposto_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Percentual de imposto inválido (' || v_perc_imposto_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_perc_imposto_nota := nvl(taxa_converter(v_perc_imposto_char), 0);
   --
   SELECT valor_base_calc,
          perc_imposto_sugerido,
          valor_deducao,
          valor_imposto_acum
     INTO v_valor_base_calc,
          v_perc_imposto_sugerido,
          v_valor_deducao,
          v_valor_imposto_acum
     FROM imposto_nota
    WHERE nota_fiscal_id = p_nota_fiscal_id
      AND fi_tipo_imposto_id = v_fi_tipo_imposto_id;
   --
   IF v_perc_imposto_sugerido <> v_perc_imposto_nota
   THEN
    v_flag_mudou := 'S';
   END IF;
   --
   v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2) -
                           v_valor_deducao;
   v_cod_retencao       := v_cod_retencao_padrao;
   v_flag_reter         := 'S';
   --
   IF v_cod_imposto = 'ISS'
   THEN
    IF p_flag_reter_iss = 'S'
    THEN
     v_valor_imposto_liq := v_valor_imposto_base;
    ELSE
     v_valor_imposto_liq := 0;
    END IF;
    --
    IF v_tipo_doc = 'REC'
    THEN
     v_cod_retencao := v_cod_retencao_altern1;
    END IF;
    --
   ELSIF v_cod_imposto = 'IRRF'
   THEN
    IF v_flag_pessoa_jur = 'N' AND v_perc_imposto_nota > 0
    THEN
     -- pessoa fisica. Pode ter mudado a faixa. 
     SELECT MAX(perc_imposto),
            MAX(valor_deducao)
       INTO v_perc_imposto_sugerido,
            v_valor_deducao
       FROM fi_tipo_imposto_faixa
      WHERE fi_tipo_imposto_id = v_fi_tipo_imposto_id
        AND v_data_emissao BETWEEN data_vigencia_ini AND data_vigencia_fim
        AND v_valor_base_calc BETWEEN valor_base_ini AND valor_base_fim;
     --
     IF v_perc_imposto_sugerido IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A tabela progressiva para retenção de imposto de ' ||
                    'renda de pessoa física não está configurada.';
      RAISE v_exception;
     END IF;
     --
     v_perc_imposto_nota  := v_perc_imposto_sugerido;
     v_valor_imposto_base := round(v_valor_base_calc * v_perc_imposto_nota / 100, 2) -
                             v_valor_deducao;
    END IF;
    --
    IF v_valor_imposto_base < v_valor_minimo
    THEN
     v_valor_imposto_liq := 0;
    ELSE
     v_valor_imposto_liq := v_valor_imposto_base;
    END IF;
    --
    IF v_flag_pessoa_jur = 'N'
    THEN
     v_cod_retencao := v_cod_retencao_altern1;
    END IF;
    --
   ELSIF v_cod_imposto IN ('RET-PIS', 'RET-COFINS', 'RET-CSLL')
   THEN
    IF v_valor_base_calc > v_valor_faixa_retencao
    THEN
     v_valor_imposto_liq := v_valor_imposto_base - v_valor_imposto_acum;
     --
     IF v_valor_imposto_liq < 0
     THEN
      -- despreza o calculo do imposto acumulado (mudaram os percentuais no mes
      -- ou tipo de documento nota de debito).
      v_valor_imposto_liq := 0;
     END IF;
    ELSE
     v_valor_imposto_liq := 0;
    END IF;
    --
    IF v_valor_imposto_liq > 0
    THEN
     v_qt_agrupado := v_qt_agrupado + 1;
    END IF;
   ELSIF v_cod_imposto = 'INSS'
   THEN
    IF v_valor_imposto_base < v_valor_minimo
    THEN
     v_valor_imposto_liq := 0;
    ELSE
     v_valor_imposto_liq := v_valor_imposto_base;
    END IF;
    --
    IF v_flag_pessoa_jur = 'N' AND v_valor_imposto_base > v_valor_maximo
    THEN
     -- limite para pessoa fisica
     v_valor_imposto_liq := v_valor_maximo;
    ELSE
     v_valor_imposto_liq := v_valor_imposto_base;
    END IF;
    --
    IF v_flag_pessoa_jur = 'N'
    THEN
     v_cod_retencao := v_cod_retencao_altern1;
    END IF;
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de imposto não previsto (' || v_cod_imposto || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_imposto_liq = 0
   THEN
    v_flag_reter   := 'N';
    v_cod_retencao := NULL;
   END IF;
   --
   --
   UPDATE imposto_nota
      SET perc_imposto_nota  = v_perc_imposto_nota,
          valor_imposto_base = v_valor_imposto_base,
          valor_imposto      = v_valor_imposto_liq,
          flag_reter         = v_flag_reter,
          cod_retencao       = v_cod_retencao
    WHERE nota_fiscal_id = p_nota_fiscal_id
      AND fi_tipo_imposto_id = v_fi_tipo_imposto_id;
   --
   v_valor_imposto_tot := v_valor_imposto_tot + v_valor_imposto_liq;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamentos finais
  ------------------------------------------------------------
  IF v_valor_dupli_tot + v_valor_imposto_tot <> v_valor_bruto
  THEN
   -- tenta ajustar o valor da última parcela da duplicata.
   -- recupera o valor da ultima parcela.
   SELECT nvl(MAX(valor_duplicata), 0)
     INTO v_valor_parcela_ult
     FROM duplicata
    WHERE duplicata_id = v_duplicata_id;
   --
   -- recupera a somatoria das parcelas anteriores à ultima
   SELECT nvl(SUM(valor_duplicata), 0)
     INTO v_valor_parcela_ant
     FROM duplicata
    WHERE duplicata_id <> v_duplicata_id
      AND nota_fiscal_id = p_nota_fiscal_id;
   --
   -- calcula a parcela ajustada
   v_valor_parcela_aju := v_valor_bruto - v_valor_imposto_tot - v_valor_parcela_ant;
   --
   IF abs(v_valor_parcela_aju - v_valor_parcela_ult) > 0.05
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Somatória das duplicatas e impostos não bate ' ||
                  'com o valor bruto da nota fiscal (Duplicatas: ' ||
                  moeda_mostrar(v_valor_dupli_tot, 'S') || ' - Impostos: ' ||
                  moeda_mostrar(v_valor_imposto_tot, 'S') || ' - Valor NF: ' ||
                  moeda_mostrar(v_valor_bruto, 'S') || ').';
    RAISE v_exception;
   ELSE
    UPDATE duplicata
       SET valor_duplicata = v_valor_parcela_aju
     WHERE duplicata_id = v_duplicata_id;
   END IF;
  END IF;
  --
  IF nvl(p_fi_tipo_imposto_pessoa_id, 0) > 0
  THEN
   SELECT nome_servico
     INTO v_nome_servico
     FROM fi_tipo_imposto_pessoa
    WHERE fi_tipo_imposto_pessoa_id = p_fi_tipo_imposto_pessoa_id;
  END IF;
  --
  IF v_flag_mudou = 'S' AND TRIM(p_motivo_alt_aliquota) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário justificar em caso de mudança de alíquota.';
   RAISE v_exception;
  END IF;
  --
  IF v_nome_servico IS NOT NULL
  THEN
   v_motivo_alt_aliquota := TRIM(TRIM(p_motivo_alt_aliquota) || ' (serviço selecionado: ' ||
                                 v_nome_servico || ')');
  ELSE
   v_motivo_alt_aliquota := TRIM(p_motivo_alt_aliquota);
  END IF;
  --
  IF length(v_motivo_alt_aliquota) > 250
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A justificativa da mudança da alíquota não pode ter mais que 250 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se precisa atualizar o codigo de retencao no caso da existencia
  -- de PIS/COFINS/CSLL ao mesmo tempo.
  IF v_qt_agrupado = 3
  THEN
   SELECT nvl(MIN(cod_retencao_altern1), 'XXX'),
          nvl(MAX(cod_retencao_altern1), 'XXX')
     INTO v_cod_retencao_altern1,
          v_cod_retencao
     FROM fi_tipo_imposto
    WHERE cod_imposto IN ('RET-PIS', 'RET-COFINS', 'RET-CSLL');
   --
   IF v_cod_retencao_altern1 <> v_cod_retencao OR v_cod_retencao_altern1 = 'XXX'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O código de retenção agrupado para PIS/COFINS/CSLL ' ||
                  'não é o mesmo ou não foi definido.';
    RAISE v_exception;
   END IF;
   --
   UPDATE imposto_nota no
      SET cod_retencao = v_cod_retencao
    WHERE nota_fiscal_id = p_nota_fiscal_id
      AND EXISTS (SELECT 1
             FROM fi_tipo_imposto ti
            WHERE no.fi_tipo_imposto_id = ti.fi_tipo_imposto_id
              AND ti.cod_imposto IN ('RET-PIS', 'RET-COFINS', 'RET-CSLL'));
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET fi_banco_cobrador_id = zvl(p_fi_banco_cobrador_id, NULL),
         motivo_alt_aliquota  = v_motivo_alt_aliquota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
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
 END sub_impostos_completar;
 --
 --
 PROCEDURE sub_pagto_comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 21/09/2012
  -- DESCRICAO: subrotina que comanda o pagamento da nota fiscai de entrada (fornecedor).
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/07/2020  NF pagas pelo cliente vao para a camada de integracao.
  -- Silvia            17/01/2023  Antecipacao de algumas consistencias em caso de 
  --                               da NF envolver faturamento de BV.
  -- Ana Luiza         17/06/2025  Tratamento para apagar nota_fiscal em caso de erro na
  --                               integracao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_fornecedor_id       pessoa.pessoa_id%TYPE;
  v_emp_apelido         pessoa.apelido%TYPE;
  v_emp_cnpj            pessoa.cnpj%TYPE;
  v_flag_fornec_interno pessoa.flag_fornec_interno%TYPE;
  v_tipo_doc            tipo_doc_nf.codigo%TYPE;
  v_num_doc             nota_fiscal.num_doc%TYPE;
  v_serie               nota_fiscal.serie%TYPE;
  v_valor_bruto         nota_fiscal.valor_bruto%TYPE;
  v_resp_pgto_receita   nota_fiscal.resp_pgto_receita%TYPE;
  v_faturamento_id      faturamento.faturamento_id%TYPE;
  v_operador            lancamento.operador%TYPE;
  v_descricao           lancamento.descricao%TYPE;
  v_valor_bv            NUMBER;
  v_valor_tip           NUMBER;
  v_valor_bv_tip        NUMBER;
  v_tipo_fatur_bv       VARCHAR2(10);
  v_flag_pago_cliente   item.flag_pago_cliente%TYPE;
  v_flag_enviou_nf      CHAR(1);
  v_erro_cod            VARCHAR2(100);
  v_erro_msg            VARCHAR2(4000);
  v_bv_fatur_autom      VARCHAR2(10);
  v_carta_acordo_id     carta_acordo.carta_acordo_id%TYPE;
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  v_flag_for_como_cli   VARCHAR(10);
  v_cadastro_ok         INTEGER;
  v_erro_origem         VARCHAR2(2000);
  --
 BEGIN
  v_qt                   := 0;
  v_bv_fatur_autom       := empresa_pkg.parametro_retornar(p_empresa_id, 'BV_FATUR_AUTOM');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.num_doc,
         td.codigo,
         nf.serie,
         nf.valor_bruto,
         pe.pessoa_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         pe.flag_fornec_interno,
         nf.tipo_fatur_bv,
         nf.flag_pago_cliente,
         nf.resp_pgto_receita
    INTO v_num_doc,
         v_tipo_doc,
         v_serie,
         v_valor_bruto,
         v_fornecedor_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_flag_fornec_interno,
         v_tipo_fatur_bv,
         v_flag_pago_cliente,
         v_resp_pgto_receita
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  SELECT nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0),
         MIN(carta_acordo_id)
    INTO v_valor_bv,
         v_valor_tip,
         v_carta_acordo_id
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  v_valor_bv_tip := v_valor_bv + v_valor_tip;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- antecipacao de algumas consistencias de faturamento de BV 
  -- (que estao codificadas em faturamento_pkg.bv_gerar)
  -- para evitar mandar a NF e depois ter que exluir. 
  ------------------------------------------------------------
  IF v_tipo_fatur_bv = 'FAT' AND v_valor_bv_tip > 0
  THEN
   -- NF tem BV a faturar
   v_flag_for_como_cli := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_FOR_COMO_CLI_FATBV');
   --
   IF v_flag_for_como_cli = 'S'
   THEN
    SELECT pessoa_pkg.tipo_verificar(pessoa_id, 'CLIENTE')
      INTO v_cadastro_ok
      FROM pessoa
     WHERE pessoa_id = v_fornecedor_id;
    --
    IF v_cadastro_ok = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O fornecedor ' || v_emp_apelido || ' deve estar marcado também como Cliente' ||
                   ' para que o BV/TIP possa ser faturado.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistema externo
  ------------------------------------------------------------
  v_flag_enviou_nf := 'N';
  --
  -- IF v_flag_pago_cliente = 'N' AND
  IF nvl(v_resp_pgto_receita, 'XXX') <> 'FON' AND v_flag_fornec_interno = 'N' AND
     v_tipo_doc NOT IN ('NCL', 'NBI', 'NFO')
  THEN
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('NOTA_FISCAL_ENT_ADICIONAR',
                            p_empresa_id,
                            p_nota_fiscal_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    --ALCBO_170625  
    -- Concatena explicação amigável ao erro
    p_erro_msg    := 'Houve um problema ao enviar a nota fiscal para o sistema financeiro. Por favor, tente novamente em alguns instantes. | ' ||
                     p_erro_msg;
    v_erro_origem := p_erro_msg;
    -- Tenta excluir a nota no sistema externo
    it_controle_pkg.integrar('NOTA_FISCAL_ENT_EXCLUIR',
                             p_empresa_id,
                             p_nota_fiscal_id,
                             NULL,
                             p_erro_cod,
                             p_erro_msg);
    -- Se a exclusão também falhar, a p_erro_msg será sobrescrita.
    IF p_erro_cod <> '00000'
    THEN
     p_erro_msg := p_erro_msg ||
                   ' | Houve um problema ao tentar excluir a nota fiscal no sistema externo.';
     -- Lança exceção com mensagem final acumulada
     --ALCBO_170625
     RAISE v_exception;
    END IF;
    p_erro_cod := '90000';
    p_erro_msg := v_erro_origem;
    RAISE v_exception;
   ELSE
    v_flag_enviou_nf := 'S';
   END IF;
   --
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  IF v_tipo_fatur_bv = 'FAT'
  THEN
   -- gera e eventualmente comanda o faturamento de BV/TIP associado a nota fiscal
   faturamento_pkg.bv_gerar(p_usuario_sessao_id,
                            p_empresa_id,
                            p_nota_fiscal_id,
                            v_bv_fatur_autom,
                            v_faturamento_id,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    -- erro na integracao do BV. Guarda o erro retornado.
    v_erro_cod := p_erro_cod;
    v_erro_msg := p_erro_msg;
    --
    IF v_flag_enviou_nf = 'S'
    THEN
     -- precisa desfazer o envio da NF
     -- integracao com sistemas externos
     it_controle_pkg.integrar('NOTA_FISCAL_ENT_EXCLUIR',
                              p_empresa_id,
                              p_nota_fiscal_id,
                              NULL,
                              p_erro_cod,
                              p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      -- tambem deu erro na exclusao da NF. Volta as duas mensagens de erro.
      p_erro_msg := v_erro_msg || ' *** ' || p_erro_msg;
     ELSE
      -- restaura a mensagem de erro do BV.
      p_erro_cod := v_erro_cod;
      p_erro_msg := v_erro_msg;
     END IF;
    END IF;
    --
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_tipo_fatur_bv IN ('CRE', 'PER') AND v_valor_bv_tip > 0
  THEN
   -- a agencia fica com credito junto ao fornecedor (movimento de entrada).
   v_descricao := 'Crédito de BV/TIP para a ' || v_lbl_agencia_singular || ': ' ||
                  TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
   --
   IF v_carta_acordo_id IS NOT NULL
   THEN
    v_descricao := v_descricao || ' - ' ||
                   carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'S');
   END IF;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     v_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_bv_tip,
     'E',
     v_operador,
     NULL);
  END IF;
  --
  UPDATE nota_fiscal
     SET status         = 'FATUR_LIB',
         data_lib_fatur = trunc(SYSDATE)
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' ||
                      TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'PAGAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 END sub_pagto_comandar;
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 20/09/2012
  -- DESCRICAO: Check-in de NOTA_FISCAL (informacoes operacionais). 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/02/2014  Pega modo de pagto da carta acordo
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  -- Silvia            06/07/2015  Novos parametros nivel_excelencia/nivel_paceria
  -- Silvia            16/12/2016  Teste de obrigatoriedade de anexar documento.
  -- Silvia            12/03/2021  Novos parametros de condicao_pagto_id e parcelas
  -- Joel Dias         28/09/2023  Inclusão de Sobra
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_cliente_job_id        job.cliente_id%TYPE;
  v_nota_fiscal_id        nota_fiscal.nota_fiscal_id%TYPE;
  v_num_doc               nota_fiscal.num_doc%TYPE;
  v_valor_bruto           nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum      nota_fiscal.valor_bruto%TYPE;
  v_data_entrada          nota_fiscal.data_entrada%TYPE;
  v_data_emissao          nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim       nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id            nota_fiscal.cliente_id%TYPE;
  v_resp_pgto_receita     nota_fiscal.resp_pgto_receita%TYPE;
  v_modo_pagto            nota_fiscal.modo_pagto%TYPE;
  v_tipo_doc              tipo_doc_nf.codigo%TYPE;
  v_emp_apelido           pessoa.apelido%TYPE;
  v_emp_cnpj              pessoa.cnpj%TYPE;
  v_valor_faixa_retencao  pessoa.valor_faixa_retencao%TYPE;
  v_flag_incentivo_fat    pessoa.flag_emp_incentivo%TYPE;
  v_tipo_arquivo_id       tipo_arquivo.tipo_arquivo_id%TYPE;
  v_carta_acordo_id       carta_acordo.carta_acordo_id%TYPE;
  v_delimitador           CHAR(1);
  v_vetor_parc_datas      LONG;
  v_vetor_parc_valores    LONG;
  v_vetor_parc_num_dias   LONG;
  v_data_parcela_char     VARCHAR2(20);
  v_valor_parcela_char    VARCHAR2(20);
  v_num_dias_char         VARCHAR2(20);
  v_valor_aprovado_char   VARCHAR2(20);
  v_valor_fornecedor_char VARCHAR2(20);
  v_data_parcela          parcela_nf.data_parcela%TYPE;
  v_valor_parcela         parcela_nf.valor_parcela%TYPE;
  v_num_dias              parcela_nf.num_dias%TYPE;
  v_num_dias_ant          parcela_nf.num_dias%TYPE;
  v_parcela_nf_id         parcela_nf.parcela_nf_id%TYPE;
  v_num_parcela           parcela_nf.num_parcela%TYPE;
  v_data_parcela_ant      parcela_nf.data_parcela%TYPE;
  v_valor_acumulado       NUMBER;
  v_tipo_data             VARCHAR2(10);
  v_tipo_data_ant         VARCHAR2(10);
  v_checkin_pagto_autom   VARCHAR2(10);
  v_checkin_financeiro    VARCHAR2(10);
  v_checkin_com_docum     VARCHAR2(10);
  v_lbl_job               VARCHAR2(100);
  v_xml_atual             CLOB;
  v_local_parcelam        VARCHAR2(40);
  v_sobra_id              sobra.sobra_id%TYPE;
  --
 BEGIN
  v_qt             := 0;
  p_nota_fiscal_id := 0;
  v_num_doc        := TRIM(p_num_doc);
  --
  v_lbl_job             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_checkin_pagto_autom := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_PAGTO_AUTOM');
  v_checkin_financeiro  := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_FINANCEIRO');
  v_checkin_com_docum   := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_CHECKIN_COM_DOCUM');
  v_local_parcelam      := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job jo
   WHERE jo.job_id = p_job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.cliente_id
    INTO v_cliente_job_id
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada (testa tb privilegio)
  ------------------------------------------------------------
  sub_checkin_consistir(p_usuario_sessao_id,
                        p_empresa_id,
                        p_job_id,
                        p_vetor_item_id,
                        p_vetor_carta_acordo_id,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_vetor_valor_aprovado,
                        p_vetor_valor_fornecedor,
                        p_vetor_valor_bv,
                        p_vetor_valor_tip,
                        p_vetor_valor_sobra,
                        NULL,
                        p_emp_emissora_id,
                        p_tipo_doc_nf_id,
                        p_num_doc,
                        p_serie,
                        p_data_entrada,
                        p_data_emissao,
                        p_data_pri_vencim,
                        p_valor_bruto,
                        p_emp_receita_id,
                        p_flag_repasse,
                        p_flag_patrocinio,
                        p_tipo_receita,
                        p_resp_pgto_receita,
                        p_desc_servico,
                        p_municipio_servico,
                        p_uf_servico,
                        p_emp_faturar_por_id,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam = 'CHECKIN'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_condicao_pagto_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM condicao_pagto
    WHERE condicao_pagto_id = p_condicao_pagto_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição de pagamento não existe ou não pertence a essa empresa (' ||
                  to_char(p_condicao_pagto_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf),
         valor_faixa_retencao
    INTO v_emp_apelido,
         v_emp_cnpj,
         v_valor_faixa_retencao
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_num_doc IS NULL
  THEN
   -- documento virtual (negociacao), sem numero proprio
   SELECT 'NE' || TRIM(to_char(seq_num_doc.nextval, '00000000'))
     INTO v_num_doc
     FROM dual;
  END IF;
  --
  v_valor_bruto     := nvl(moeda_converter(p_valor_bruto), 0);
  v_data_entrada    := data_converter(p_data_entrada);
  v_data_emissao    := data_converter(p_data_emissao);
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  --
  SELECT flag_emp_incentivo
    INTO v_flag_incentivo_fat
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   v_cliente_id := p_emp_receita_id;
  END IF;
  -- 
  /* a pedido da Ana Maria 20/05/2016, o cliente da NF voltou a ser a Incentivo
  IF v_flag_incentivo_fat = 'S' THEN
     -- empresa de faturamento eh a Incentivo. Mantem o 
     -- cliente do job como cliente da nota
     v_cliente_id := v_cliente_job_id;
  END IF;*/
  --
  IF nvl(v_cliente_id, 0) = 0
  THEN
   v_cliente_id := p_emp_faturar_por_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NULL
  THEN
   v_resp_pgto_receita := NULL;
  ELSE
   v_resp_pgto_receita := p_resp_pgto_receita;
  END IF;
  --
  IF TRIM(p_nivel_excelencia) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_excelencia', p_nivel_excelencia) IS NULL OR
      inteiro_validar(p_nivel_excelencia) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de excelência inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_nivel_parceria) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_parceria', p_nivel_parceria) IS NULL OR
      inteiro_validar(p_nivel_parceria) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de parceria inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(nota_fiscal_id)
    INTO v_nota_fiscal_id
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_nota_fiscal_id IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_nota_fiscal.nextval
    INTO v_nota_fiscal_id
    FROM dual;
  --
  INSERT INTO nota_fiscal
   (nota_fiscal_id,
    job_id,
    cliente_id,
    emp_emissora_id,
    tipo_ent_sai,
    tipo_doc_nf_id,
    num_doc,
    serie,
    data_entrada,
    data_emissao,
    data_pri_vencim,
    valor_bruto,
    valor_mao_obra,
    desc_servico,
    municipio_servico,
    uf_servico,
    status,
    emp_faturar_por_id,
    flag_item_patrocinado,
    tipo_receita,
    emp_receita_id,
    resp_pgto_receita,
    valor_faixa_retencao,
    modo_pagto,
    condicao_pagto_id)
  VALUES
   (v_nota_fiscal_id,
    p_job_id,
    v_cliente_id,
    p_emp_emissora_id,
    'E',
    p_tipo_doc_nf_id,
    TRIM(v_num_doc),
    TRIM(p_serie),
    v_data_entrada,
    v_data_emissao,
    v_data_pri_vencim,
    v_valor_bruto,
    0,
    TRIM(p_desc_servico),
    TRIM(p_municipio_servico),
    TRIM(p_uf_servico),
    'CHECKIN_PEND',
    p_emp_faturar_por_id,
    p_flag_patrocinio,
    TRIM(p_tipo_receita),
    zvl(p_emp_receita_id, NULL),
    v_resp_pgto_receita,
    v_valor_faixa_retencao,
    'OU',
    zvl(p_condicao_pagto_id, NULL));
  --ALCBO_310725
  nota_fiscal_pkg.nf_saldo_atualizar(v_nota_fiscal_id,
                                     v_valor_bruto,
                                     v_valor_bruto,
                                     'N',
                                     p_erro_cod,
                                     p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- trata parcelamento
  ------------------------------------------------------------
  IF v_local_parcelam = 'CHECKIN'
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_nf.nextval
       INTO v_parcela_nf_id
       FROM dual;
     --
     INSERT INTO parcela_nf
      (parcela_nf_id,
       nota_fiscal_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_nf_id,
       v_nota_fiscal_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    END IF;
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_bruto
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total da nota fiscal (' ||
                  moeda_mostrar(v_valor_bruto, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_nf
      SET num_tot_parcelas = v_num_parcela
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- associacao dos itens a nota fiscal
  ------------------------------------------------------------
  sub_itens_adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      v_nota_fiscal_id,
                      p_vetor_item_id,
                      p_vetor_carta_acordo_id,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      p_vetor_valor_aprovado,
                      p_vetor_valor_fornecedor,
                      p_vetor_valor_bv,
                      p_vetor_valor_tip,
                      p_vetor_valor_sobra,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais na NF para campos desnormalizados
  ------------------------------------------------------------
  SELECT MAX(ca.carta_acordo_id)
    INTO v_carta_acordo_id
    FROM item_nota    io,
         carta_acordo ca
   WHERE io.nota_fiscal_id = v_nota_fiscal_id
     AND io.carta_acordo_id = ca.carta_acordo_id
     AND ca.modo_pagto IS NOT NULL;
  --
  IF v_carta_acordo_id IS NOT NULL
  THEN
   SELECT modo_pagto
     INTO v_modo_pagto
     FROM carta_acordo
    WHERE carta_acordo_id = v_carta_acordo_id;
   --
   UPDATE nota_fiscal
      SET modo_pagto = v_modo_pagto
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  UPDATE nota_fiscal
     SET tipo_fatur_bv     = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id),
         flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_bruto_acum
    FROM item_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  IF v_valor_bruto_acum <> v_valor_bruto
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor acumulado dos itens dessa nota (1) (' ||
                 moeda_mostrar(v_valor_bruto_acum, 'S') ||
                 ') não corresponde ao valor bruto da nota fiscal (' ||
                 moeda_mostrar(v_valor_bruto, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do arquivo
  ------------------------------------------------------------
  /*
  IF v_checkin_com_docum = 'S' AND NVL(p_arquivo_id,0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'É necessário anexar ao menos um Documento no Check-in.';
     RAISE v_exception;
  END IF;*/
  --
  IF nvl(p_arquivo_id, 0) > 0
  THEN
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
    p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(tipo_arquivo_id)
     INTO v_tipo_arquivo_id
     FROM tipo_arquivo
    WHERE empresa_id = p_empresa_id
      AND codigo = 'NOTA_FISCAL';
   --
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_arquivo_id,
                         p_volume_id,
                         v_nota_fiscal_id,
                         v_tipo_arquivo_id,
                         p_nome_original,
                         p_nome_fisico,
                         NULL,
                         p_mime_type,
                         p_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula impostos, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_financeiro = 'S'
  THEN
   sub_impostos_calcular(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         v_nota_fiscal_id,
                         '0', -- mao de obra
                         moeda_mostrar(v_valor_bruto, 'N'), -- base ISS
                         moeda_mostrar(v_valor_bruto, 'N'), -- base IR
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- nao precisa deixar a NF com pendencia financeira
   UPDATE nota_fiscal
      SET status = 'CHECKIN_OK'
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- grava avaliacoes, se for o caso.
  ------------------------------------------------------------
  IF nvl(to_number(p_nivel_excelencia), 0) > 0
  THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'EXC',
     SYSDATE,
     to_number(p_nivel_excelencia));
  END IF;
  --
  IF nvl(to_number(p_nivel_parceria), 0) > 0
  THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'PAR',
     SYSDATE,
     to_number(p_nivel_parceria));
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_emp_receita_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- integracao com sistemas externos
  it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                           p_empresa_id,
                           p_emp_emissora_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_pagto_autom = 'S' AND v_checkin_financeiro = 'N'
  THEN
   -- a subrotina muda o status da NF para FATUR_LIB
   nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      v_nota_fiscal_id,
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  p_nota_fiscal_id := v_nota_fiscal_id;
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
 PROCEDURE multijob_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 20/09/2012
  -- DESCRICAO: Check-in de NOTA_FISCAL multijob (informacoes operacionais). 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  -- Silvia            06/07/2015  Novos parametros nivel_excelencia/nivel_paceria
  -- Silvia            16/12/2016  Teste de obrigatoriedade de anexar documento.
  -- Silvia            12/03/2021  Novos parametros de condicao_pagto_id e parcelas
  -- Joel Dias         27/09/2023  Inclusão de Sobra
  -- Ana Luiza         23/09/2024  Adicao de parametro aquivo externo recebido do ADNNET
  -- Ana Luiza         01/10/2024  Gravacao de arquivo ext no ADNNET
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_valor_credito_usado    IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_arquivo_id_ext         IN VARCHAR2,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_nota_fiscal_id        nota_fiscal.nota_fiscal_id%TYPE;
  v_num_doc               nota_fiscal.num_doc%TYPE;
  v_valor_bruto           nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum      nota_fiscal.valor_bruto%TYPE;
  v_data_entrada          nota_fiscal.data_entrada%TYPE;
  v_data_emissao          nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim       nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id            nota_fiscal.cliente_id%TYPE;
  v_resp_pgto_receita     nota_fiscal.resp_pgto_receita%TYPE;
  v_valor_credito_usado   nota_fiscal.valor_credito_usado%TYPE;
  v_tipo_doc              tipo_doc_nf.codigo%TYPE;
  v_emp_apelido           pessoa.apelido%TYPE;
  v_emp_cnpj              pessoa.cnpj%TYPE;
  v_valor_faixa_retencao  pessoa.valor_faixa_retencao%TYPE;
  v_flag_incentivo_fat    pessoa.flag_emp_incentivo%TYPE;
  v_tipo_arquivo_id       tipo_arquivo.tipo_arquivo_id%TYPE;
  v_checkin_pagto_autom   VARCHAR2(10);
  v_checkin_financeiro    VARCHAR2(10);
  v_checkin_com_docum     VARCHAR2(10);
  v_lbl_job               VARCHAR2(100);
  v_xml_atual             CLOB;
  v_delimitador           CHAR(1);
  v_vetor_parc_datas      LONG;
  v_vetor_parc_valores    LONG;
  v_vetor_parc_num_dias   LONG;
  v_data_parcela_char     VARCHAR2(20);
  v_valor_parcela_char    VARCHAR2(20);
  v_num_dias_char         VARCHAR2(20);
  v_valor_aprovado_char   VARCHAR2(20);
  v_valor_fornecedor_char VARCHAR2(20);
  v_local_parcelam        VARCHAR2(40);
  v_data_parcela          parcela_nf.data_parcela%TYPE;
  v_valor_parcela         parcela_nf.valor_parcela%TYPE;
  v_num_dias              parcela_nf.num_dias%TYPE;
  v_num_dias_ant          parcela_nf.num_dias%TYPE;
  v_parcela_nf_id         parcela_nf.parcela_nf_id%TYPE;
  v_num_parcela           parcela_nf.num_parcela%TYPE;
  v_data_parcela_ant      parcela_nf.data_parcela%TYPE;
  v_valor_acumulado       NUMBER;
  v_tipo_data             VARCHAR2(10);
  v_tipo_data_ant         VARCHAR2(10);
  --
 BEGIN
  v_qt             := 0;
  p_nota_fiscal_id := 0;
  v_num_doc        := TRIM(p_num_doc);
  /*
  p_erro_cod := '90000';
  p_erro_msg := 'Aprovado:' || p_vetor_valor_aprovado || '   ' ||
                'Fornecedor:' || p_vetor_valor_fornecedor || '   ' ||
                'BV:' || p_vetor_valor_bv || '   ' ||
                'TIP:' || p_vetor_valor_tip || '   ' ||
                'Sobra:' || p_vetor_valor_sobra;
  RAISE v_exception;
  */
  --
  v_lbl_job             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_checkin_pagto_autom := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_PAGTO_AUTOM');
  v_checkin_financeiro  := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_FINANCEIRO');
  v_checkin_com_docum   := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_CHECKIN_COM_DOCUM');
  v_local_parcelam      := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada (testa tb privilegio)
  ------------------------------------------------------------
  sub_checkin_consistir(p_usuario_sessao_id,
                        p_empresa_id,
                        NULL,
                        p_vetor_item_id,
                        p_vetor_carta_acordo_id,
                        p_vetor_tipo_produto_id,
                        p_vetor_quantidade,
                        p_vetor_frequencia,
                        p_vetor_custo_unitario,
                        p_vetor_complemento,
                        p_vetor_valor_aprovado,
                        p_vetor_valor_fornecedor,
                        p_vetor_valor_bv,
                        p_vetor_valor_tip,
                        p_vetor_valor_sobra,
                        p_valor_credito_usado,
                        p_emp_emissora_id,
                        p_tipo_doc_nf_id,
                        p_num_doc,
                        p_serie,
                        p_data_entrada,
                        p_data_emissao,
                        p_data_pri_vencim,
                        p_valor_bruto,
                        p_emp_receita_id,
                        p_flag_repasse,
                        p_flag_patrocinio,
                        p_tipo_receita,
                        p_resp_pgto_receita,
                        p_desc_servico,
                        p_municipio_servico,
                        p_uf_servico,
                        p_emp_faturar_por_id,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam = 'CHECKIN'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_condicao_pagto_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM condicao_pagto
    WHERE condicao_pagto_id = p_condicao_pagto_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição de pagamento não existe ou não pertence a essa empresa (' ||
                  to_char(p_condicao_pagto_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf),
         valor_faixa_retencao
    INTO v_emp_apelido,
         v_emp_cnpj,
         v_valor_faixa_retencao
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_num_doc IS NULL
  THEN
   -- documento virtual (negociacao), sem numero proprio
   SELECT 'NE' || TRIM(to_char(seq_num_doc.nextval, '00000000'))
     INTO v_num_doc
     FROM dual;
  END IF;
  --
  v_valor_bruto         := nvl(moeda_converter(p_valor_bruto), 0);
  v_valor_credito_usado := nvl(moeda_converter(p_valor_credito_usado), 0);
  v_data_entrada        := data_converter(p_data_entrada);
  v_data_emissao        := data_converter(p_data_emissao);
  v_data_pri_vencim     := data_converter(p_data_pri_vencim);
  --
  SELECT flag_emp_incentivo
    INTO v_flag_incentivo_fat
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   v_cliente_id := p_emp_receita_id;
  END IF;
  --
  IF nvl(v_cliente_id, 0) = 0
  THEN
   v_cliente_id := p_emp_faturar_por_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NULL
  THEN
   v_resp_pgto_receita := NULL;
  ELSE
   v_resp_pgto_receita := p_resp_pgto_receita;
  END IF;
  --
  IF TRIM(p_nivel_excelencia) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_excelencia', p_nivel_excelencia) IS NULL OR
      inteiro_validar(p_nivel_excelencia) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de excelência inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_nivel_parceria) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_parceria', p_nivel_parceria) IS NULL OR
      inteiro_validar(p_nivel_parceria) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de parceria inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(nota_fiscal_id)
    INTO v_nota_fiscal_id
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_nota_fiscal_id IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT seq_nota_fiscal.nextval
    INTO v_nota_fiscal_id
    FROM dual;
  --ALCBO_011024
  INSERT INTO nota_fiscal
   (nota_fiscal_id,
    job_id,
    cliente_id,
    emp_emissora_id,
    tipo_ent_sai,
    tipo_doc_nf_id,
    num_doc,
    serie,
    data_entrada,
    data_emissao,
    data_pri_vencim,
    valor_bruto,
    valor_mao_obra,
    desc_servico,
    municipio_servico,
    uf_servico,
    status,
    emp_faturar_por_id,
    flag_item_patrocinado,
    tipo_receita,
    emp_receita_id,
    resp_pgto_receita,
    valor_faixa_retencao,
    valor_credito_usado,
    condicao_pagto_id,
    cod_arquivo_ext)
  VALUES
   (v_nota_fiscal_id,
    NULL,
    v_cliente_id,
    p_emp_emissora_id,
    'E',
    p_tipo_doc_nf_id,
    TRIM(v_num_doc),
    TRIM(p_serie),
    v_data_entrada,
    v_data_emissao,
    v_data_pri_vencim,
    v_valor_bruto,
    0,
    TRIM(p_desc_servico),
    TRIM(p_municipio_servico),
    TRIM(p_uf_servico),
    'CHECKIN_PEND',
    p_emp_faturar_por_id,
    p_flag_patrocinio,
    TRIM(p_tipo_receita),
    zvl(p_emp_receita_id, NULL),
    v_resp_pgto_receita,
    v_valor_faixa_retencao,
    v_valor_credito_usado,
    zvl(p_condicao_pagto_id, NULL),
    TRIM(p_arquivo_id_ext));
  --
  ------------------------------------------------------------
  -- trata parcelamento
  ------------------------------------------------------------
  IF v_local_parcelam = 'CHECKIN'
  THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0
    THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0
     THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL
     THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA'
     THEN
      IF v_data_parcela <= v_data_parcela_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA'
     THEN
      IF v_num_dias <= v_num_dias_ant
      THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_nf.nextval
       INTO v_parcela_nf_id
       FROM dual;
     --
     INSERT INTO parcela_nf
      (parcela_nf_id,
       nota_fiscal_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_nf_id,
       v_nota_fiscal_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    END IF;
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_bruto
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total da nota fiscal (' ||
                  moeda_mostrar(v_valor_bruto, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_nf
      SET num_tot_parcelas = v_num_parcela
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- associacao dos itens a nota fiscal
  ------------------------------------------------------------
  sub_itens_adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      v_nota_fiscal_id,
                      p_vetor_item_id,
                      p_vetor_carta_acordo_id,
                      p_vetor_tipo_produto_id,
                      p_vetor_quantidade,
                      p_vetor_frequencia,
                      p_vetor_custo_unitario,
                      p_vetor_complemento,
                      p_vetor_valor_aprovado,
                      p_vetor_valor_fornecedor,
                      p_vetor_valor_bv,
                      p_vetor_valor_tip,
                      p_vetor_valor_sobra,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais na NF para campos desnormalizados
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET tipo_fatur_bv     = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id),
         flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_bruto_acum
    FROM item_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  IF v_valor_bruto_acum <> v_valor_bruto + v_valor_credito_usado
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor acumulado dos itens dessa nota  (aqui) (' ||
                 moeda_mostrar(v_valor_bruto_acum, 'S') ||
                 ') não corresponde ao valor bruto da nota fiscal mais os créditos usados (' ||
                 moeda_mostrar(v_valor_bruto + v_valor_credito_usado, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do arquivo
  ------------------------------------------------------------
  /*
  IF v_checkin_com_docum = 'S' AND NVL(p_arquivo_id,0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'É necessário anexar ao menos um Documento no Check-in.';
     RAISE v_exception;
  END IF;*/
  --
  IF nvl(p_arquivo_id, 0) > 0
  THEN
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
    p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(tipo_arquivo_id)
     INTO v_tipo_arquivo_id
     FROM tipo_arquivo
    WHERE empresa_id = p_empresa_id
      AND codigo = 'NOTA_FISCAL';
   --
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_arquivo_id,
                         p_volume_id,
                         v_nota_fiscal_id,
                         v_tipo_arquivo_id,
                         p_nome_original,
                         p_nome_fisico,
                         NULL,
                         p_mime_type,
                         p_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula impostos, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_financeiro = 'S'
  THEN
   sub_impostos_calcular(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         v_nota_fiscal_id,
                         '0', -- mao de obra
                         moeda_mostrar(v_valor_bruto, 'N'), -- base ISS
                         moeda_mostrar(v_valor_bruto, 'N'), -- base IR
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- nao precisa deixar a NF com pendencia financeira
   UPDATE nota_fiscal
      SET status = 'CHECKIN_OK'
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- grava avaliacoes, se for o caso.
  ------------------------------------------------------------
  IF nvl(to_number(p_nivel_excelencia), 0) > 0
  THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'EXC',
     SYSDATE,
     to_number(p_nivel_excelencia));
  END IF;
  --
  IF nvl(to_number(p_nivel_parceria), 0) > 0
  THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'PAR',
     SYSDATE,
     to_number(p_nivel_parceria));
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_emp_receita_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- integracao com sistemas externos
  it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                           p_empresa_id,
                           p_emp_emissora_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_pagto_autom = 'S' AND v_checkin_financeiro = 'N'
  THEN
   -- a subrotina muda o status da NF para FATUR_LIB
   nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      v_nota_fiscal_id,
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  COMMIT;
  p_nota_fiscal_id := v_nota_fiscal_id;
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
 END multijob_adicionar;
 --
 --
 PROCEDURE auto_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 04/02/2014
  -- DESCRICAO: subrotina de Check-in automatico de NOTA_FISCAL para cartas acordo com 
  --   credito usado ou do tipo permuta. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/06/2014  Tratamento para tipo permuta.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id    OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_nota_fiscal_id      nota_fiscal.nota_fiscal_id%TYPE;
  v_num_doc             nota_fiscal.num_doc%TYPE;
  v_valor_bruto         nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum    nota_fiscal.valor_bruto%TYPE;
  v_data_entrada        nota_fiscal.data_entrada%TYPE;
  v_data_emissao        nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim     nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id          nota_fiscal.cliente_id%TYPE;
  v_emp_emissora_id     nota_fiscal.emp_emissora_id%TYPE;
  v_tipo_doc            tipo_doc_nf.codigo%TYPE;
  v_tipo_doc_nf_id      tipo_doc_nf.tipo_doc_nf_id%TYPE;
  v_emp_apelido         pessoa.apelido%TYPE;
  v_emp_cnpj            pessoa.cnpj%TYPE;
  v_valor_aprovado_ca   carta_acordo.valor_aprovado%TYPE;
  v_valor_fornecedor_ca carta_acordo.valor_fornecedor%TYPE;
  v_valor_credito_usado carta_acordo.valor_credito_usado%TYPE;
  v_emp_faturar_por_id  carta_acordo.emp_faturar_por_id%TYPE;
  v_job_id              carta_acordo.job_id%TYPE;
  v_perc_bv             carta_acordo.perc_bv%TYPE;
  v_perc_imposto        carta_acordo.perc_imposto%TYPE;
  v_tipo_fatur_bv       carta_acordo.tipo_fatur_bv%TYPE;
  v_valor_aprovado      item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor    item_nota.valor_fornecedor%TYPE;
  v_valor_bv            item_nota.valor_bv%TYPE;
  v_valor_tip           item_nota.valor_tip%TYPE;
  v_valor_saldo         item_nota.valor_aprovado%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_xml_atual           CLOB;
  --
  CURSOR c_it IS
   SELECT ic.item_carta_id,
          ic.item_id,
          it.job_id,
          it.orcamento_id,
          nvl(ic.valor_aprovado, 0) valor_aprovado,
          nvl(ic.valor_fornecedor, 0) valor_fornecedor,
          ic.quantidade,
          ic.frequencia,
          ic.custo_unitario,
          ic.complemento,
          ic.tipo_produto_id
     FROM item_carta ic,
          item       it
    WHERE ic.carta_acordo_id = p_carta_acordo_id
      AND ic.item_id = it.item_id;
  --
 BEGIN
  v_qt             := 0;
  p_nota_fiscal_id := 0;
  --
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_acordo
   WHERE carta_acordo_id = p_carta_acordo_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa carta acordo não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT ca.fornecedor_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         nvl(ca.valor_aprovado, 0),
         nvl(ca.valor_fornecedor, 0),
         nvl(ca.valor_credito_usado, 0),
         nvl(ca.perc_bv, 0),
         nvl(ca.perc_imposto, 0),
         ca.emp_faturar_por_id,
         ca.job_id,
         ca.cliente_id,
         ca.tipo_fatur_bv
    INTO v_emp_emissora_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_valor_aprovado_ca,
         v_valor_fornecedor_ca,
         v_valor_credito_usado,
         v_perc_bv,
         v_perc_imposto,
         v_emp_faturar_por_id,
         v_job_id,
         v_cliente_id,
         v_tipo_fatur_bv
    FROM pessoa       pe,
         carta_acordo ca
   WHERE ca.carta_acordo_id = p_carta_acordo_id
     AND ca.fornecedor_id = pe.pessoa_id;
  --
  v_tipo_doc := 'NFO';
  --
  SELECT MAX(tipo_doc_nf_id)
    INTO v_tipo_doc_nf_id
    FROM tipo_doc_nf
   WHERE codigo = v_tipo_doc;
  --
  IF v_tipo_doc_nf_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de documento não existe (' || v_tipo_doc || ').';
   RAISE v_exception;
  END IF;
  --
  -- documento virtual (negociacao), sem numero proprio
  SELECT 'NE' || TRIM(to_char(seq_num_doc.nextval, '00000000'))
    INTO v_num_doc
    FROM dual;
  --
  IF v_tipo_fatur_bv = 'PER'
  THEN
   v_valor_bruto := v_valor_aprovado_ca;
  ELSE
   v_valor_bruto := v_valor_credito_usado;
  END IF;
  --
  v_data_entrada    := trunc(SYSDATE);
  v_data_emissao    := trunc(SYSDATE);
  v_data_pri_vencim := trunc(SYSDATE);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(nota_fiscal_id)
    INTO v_nota_fiscal_id
    FROM nota_fiscal
   WHERE emp_emissora_id = v_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = v_tipo_doc_nf_id;
  --
  IF v_nota_fiscal_id IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_nota_fiscal.nextval
    INTO v_nota_fiscal_id
    FROM dual;
  --
  INSERT INTO nota_fiscal
   (nota_fiscal_id,
    job_id,
    cliente_id,
    emp_emissora_id,
    tipo_ent_sai,
    tipo_doc_nf_id,
    num_doc,
    serie,
    data_entrada,
    data_emissao,
    data_pri_vencim,
    valor_bruto,
    valor_mao_obra,
    desc_servico,
    municipio_servico,
    uf_servico,
    status,
    emp_faturar_por_id,
    flag_item_patrocinado,
    modo_pagto)
  VALUES
   (v_nota_fiscal_id,
    v_job_id,
    v_cliente_id,
    v_emp_emissora_id,
    'E',
    v_tipo_doc_nf_id,
    TRIM(v_num_doc),
    NULL,
    v_data_entrada,
    v_data_emissao,
    v_data_pri_vencim,
    v_valor_bruto,
    0,
    'Check-in automático para baixa de crédito',
    NULL,
    NULL,
    'CHECKIN_OK',
    v_emp_faturar_por_id,
    'N',
    'OU');
  --
  ------------------------------------------------------------
  -- associacao dos itens a nota fiscal
  ------------------------------------------------------------
  v_valor_saldo := v_valor_bruto;
  --
  FOR r_it IN c_it
  LOOP
   IF v_valor_saldo >= r_it.valor_aprovado
   THEN
    v_valor_aprovado := r_it.valor_aprovado;
   ELSE
    v_valor_aprovado := v_valor_saldo;
   END IF;
   --
   v_valor_saldo := v_valor_saldo - v_valor_aprovado;
   --
   v_valor_fornecedor := round(v_valor_aprovado * v_valor_fornecedor_ca / v_valor_aprovado_ca, 2);
   v_valor_bv         := round(v_valor_fornecedor * v_perc_bv / 100, 2);
   v_valor_tip        := round((v_valor_aprovado - v_valor_fornecedor) * (1 - v_perc_imposto / 100),
                               2);
   --
   IF v_valor_aprovado > 0
   THEN
    INSERT INTO item_nota
     (item_nota_id,
      item_id,
      nota_fiscal_id,
      carta_acordo_id,
      valor_aprovado,
      valor_fornecedor,
      valor_bv,
      valor_tip,
      tipo_produto_id,
      quantidade,
      frequencia,
      custo_unitario,
      complemento)
    VALUES
     (seq_item_nota.nextval,
      r_it.item_id,
      v_nota_fiscal_id,
      p_carta_acordo_id,
      v_valor_aprovado,
      v_valor_fornecedor,
      v_valor_bv,
      v_valor_tip,
      r_it.tipo_produto_id,
      r_it.quantidade,
      r_it.frequencia,
      r_it.custo_unitario,
      r_it.complemento);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- Recalcula os saldos dos acessorios da estimativa
    orcamento_pkg.saldos_acessorios_recalcular(p_usuario_sessao_id,
                                               r_it.orcamento_id,
                                               p_erro_cod,
                                               p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais na NF para campos desnormalizados
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET tipo_fatur_bv     = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id),
         flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_bruto_acum
    FROM item_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  IF v_valor_bruto_acum <> v_valor_bruto
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor acumulado dos itens dessa nota (3) (' ||
                 moeda_mostrar(v_valor_bruto_acum, 'S') ||
                 ') não corresponde ao valor bruto da nota fiscal (' ||
                 moeda_mostrar(v_valor_bruto, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento
  ------------------------------------------------------------
  -- a subrotina muda o status da NF para FATUR_LIB
  nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     v_nota_fiscal_id,
                                     p_erro_cod,
                                     p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  p_nota_fiscal_id := v_nota_fiscal_id;
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
 END auto_adicionar;
 --
 --
 PROCEDURE completar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/04/2007
  -- DESCRICAO: Atualização de informacoes financeiras da nota fiscal de entrada (impostos, 
  --   valores de duplicatas, etc). A NF passa do status CHECKIN_PEND para CHECKIN_OK.
  --   Se o parametro pagamento automatico estiver ligado, passa do status CHECKIN_OK para 
  --   FATUR_LIB.
  --   
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/03/2021  Novos parametros produto_fiscal_id e produto
  -- Ana Luiza         01/02/2024  Tratamento dicionario para codigo do ADNNET
  -- Ana Luiza         13/01/2025  Adicionado novas modalidades de pagamento Inhaus
  -- Ana Luiza         12/02/2025  Testa tipo_pag_pessoa se parametro = S Inhaus
  -- Ana Luiza         28/02/2025  Alteracao na modalidade de pagamento para guardar apenas 
  --                               código
  -- Ana Luiza         17/06/2025  Volta Obrigar chave de acesso para Integracao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id            IN nota_fiscal.nota_fiscal_id%TYPE,
  p_valor_mao_obra            IN VARCHAR2,
  p_valor_base_iss            IN VARCHAR2,
  p_valor_base_ir             IN VARCHAR2,
  p_desc_servico              IN VARCHAR2,
  p_produto_fiscal_id         IN nota_fiscal.produto_fiscal_id%TYPE,
  p_produto                   IN nota_fiscal.produto%TYPE,
  p_tipo_pag_pessoa           IN nota_fiscal.tipo_pag_pessoa%TYPE,
  p_cod_verificacao           IN nota_fiscal.cod_verificacao%TYPE,
  p_chave_acesso              IN nota_fiscal.chave_acesso%TYPE,
  p_modo_pagto                IN nota_fiscal.modo_pagto%TYPE,
  p_num_doc_pagto             IN nota_fiscal.num_doc_pagto%TYPE,
  p_emp_fi_banco_id           IN pessoa.fi_banco_id%TYPE,
  p_emp_num_agencia           IN pessoa.num_agencia%TYPE,
  p_emp_num_conta             IN pessoa.num_conta%TYPE,
  p_emp_tipo_conta            IN pessoa.tipo_conta%TYPE,
  p_emp_flag_atualizar        IN VARCHAR2,
  p_fi_banco_cobrador_id      IN nota_fiscal.fi_banco_cobrador_id%TYPE,
  p_vetor_data_vencim         IN VARCHAR2,
  p_vetor_valor_duplicata     IN VARCHAR2,
  p_vetor_fi_tipo_imposto     IN VARCHAR2,
  p_vetor_perc_imposto        IN VARCHAR2,
  p_fi_tipo_imposto_pessoa_id IN fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE,
  p_flag_reter_iss            IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_motivo_alt_aliquota       IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_job_id               job.job_id%TYPE;
  v_emp_emissora_id      nota_fiscal.emp_emissora_id%TYPE;
  v_valor_bruto          nota_fiscal.valor_bruto%TYPE;
  v_num_doc              nota_fiscal.num_doc%TYPE;
  v_tipo_doc             tipo_doc_nf.codigo%TYPE;
  v_flag_cod_verific     tipo_doc_nf.flag_cod_verific%TYPE;
  v_flag_chave_acesso    tipo_doc_nf.flag_chave_acesso%TYPE;
  v_serie                nota_fiscal.serie%TYPE;
  v_status_nf            nota_fiscal.status%TYPE;
  v_valor_mao_obra       nota_fiscal.valor_mao_obra%TYPE;
  v_emp_apelido          pessoa.apelido%TYPE;
  v_emp_cnpj             pessoa.cnpj%TYPE;
  v_checkin_pagto_autom  VARCHAR2(10);
  v_usa_prod_fiscal      VARCHAR2(10);
  v_usa_produto          VARCHAR2(10);
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
  v_cod_ext_item_checkin parametro.valor%TYPE;
  v_cod_sist_ext         sistema_externo.codigo%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  v_checkin_pagto_autom  := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_PAGTO_AUTOM');
  v_usa_prod_fiscal      := empresa_pkg.parametro_retornar(p_empresa_id,
                                                           'HABILITA_PROD_FISCAL_CHECKIN');
  v_usa_produto          := empresa_pkg.parametro_retornar(p_empresa_id, 'HABILITA_PRODUTO_CHECKIN');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --ALCBO_120225
  v_cod_ext_item_checkin := empresa_pkg.parametro_retornar(p_empresa_id, 'COD_EXT_ITEM_CHECKIN');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.emp_emissora_id,
         nf.job_id,
         nf.num_doc,
         nf.serie,
         nf.valor_bruto,
         nf.status,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         td.codigo,
         td.flag_cod_verific,
         td.flag_chave_acesso
    INTO v_emp_emissora_id,
         v_job_id,
         v_num_doc,
         v_serie,
         v_valor_bruto,
         v_status_nf,
         v_emp_apelido,
         v_emp_cnpj,
         v_tipo_doc,
         v_flag_cod_verific,
         v_flag_chave_acesso
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'NOTA_FISCAL_FIN', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_nf <> 'CHECKIN_PEND'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite a alteração.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos dados de entrada
  ------------------------------------------------------------
  IF TRIM(p_valor_mao_obra) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor de mão-de-obra é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_base_iss) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor base ISS é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_base_ir) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor base IR é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_desc_servico) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do serviço não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_usa_prod_fiscal = 'S' AND nvl(p_produto_fiscal_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Produto Fiscal é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_fiscal_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_fiscal
    WHERE produto_fiscal_id = p_produto_fiscal_id
      AND empresa_id = p_empresa_id;
   -- 
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Produto Fiscal não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_usa_produto = 'S' AND TRIM(p_produto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_120225
  IF v_cod_ext_item_checkin = 'N'
  THEN
   IF TRIM(p_tipo_pag_pessoa) IS NOT NULL
   THEN
    IF util_pkg.desc_retornar('tipo_pag_pessoa', p_tipo_pag_pessoa) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Conta específica inválida.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_tipo_doc = 'PP' AND TRIM(p_tipo_pag_pessoa) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de nota fiscal, o preenchimento da conta específica ' ||
                  'é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_cod_verific = 'S' AND TRIM(p_cod_verificacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de documento, o código de verificação deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_cod_verific = 'N' AND TRIM(p_cod_verificacao) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de documento, o código de verificação não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --ALCBO_170625
  IF v_flag_chave_acesso = 'S' AND TRIM(p_chave_acesso) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de documento, a chave de acesso deve ser preenchida.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_chave_acesso = 'N' AND TRIM(p_chave_acesso) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de documento, a chave de acesso não deve ser preenchida.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_chave_acesso) IS NOT NULL AND
     nota_fiscal_pkg.chave_acesso_verificar(p_chave_acesso) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Chave de acesso inválida.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do modo de pagamento é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('modo_pgto', p_modo_pagto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Modo de pagamento inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_emp_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   IF (TRIM(p_emp_num_agencia) IS NULL OR TRIM(p_emp_num_conta) IS NULL)
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Dados bancários incompletos - ' || v_lbl_agencia_singular || '/conta.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_emp_fi_banco_id, 0) = 0 AND
     (TRIM(p_emp_num_agencia) IS NOT NULL OR TRIM(p_emp_num_conta) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Dados bancários incompletos - nro do banco.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_emp_tipo_conta) IS NOT NULL AND p_emp_tipo_conta NOT IN ('C', 'P')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_emp_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_emp_flag_atualizar) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualizar dados bancários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_reter_iss) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag reter inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fi_banco_cobrador_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_cobrador_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco cobrador não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de impostos e duplicatas
  ------------------------------------------------------------
  sub_impostos_completar(p_usuario_sessao_id,
                         p_empresa_id,
                         p_nota_fiscal_id,
                         p_valor_mao_obra,
                         p_valor_base_iss,
                         p_valor_base_ir,
                         p_fi_banco_cobrador_id,
                         p_vetor_data_vencim,
                         p_vetor_valor_duplicata,
                         p_vetor_fi_tipo_imposto,
                         p_vetor_perc_imposto,
                         p_fi_tipo_imposto_pessoa_id,
                         p_flag_reter_iss,
                         p_motivo_alt_aliquota,
                         p_erro_cod,
                         p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_valor_mao_obra := nvl(moeda_converter(p_valor_mao_obra), 0);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- fi_banco_cobrador_id e motivo_alt_aliquota ja foram atualizados
  -- via subrotina sub_impostos_completar.
  UPDATE nota_fiscal
     SET valor_mao_obra  = v_valor_mao_obra,
         desc_servico    = TRIM(p_desc_servico),
         tipo_pag_pessoa = TRIM(p_tipo_pag_pessoa),
         cod_verificacao = TRIM(upper(p_cod_verificacao)),
         chave_acesso    = TRIM(p_chave_acesso),
         --ALCBO_010224 --280225
         modo_pagto         = p_modo_pagto,
         num_doc_pagto      = TRIM(p_num_doc_pagto),
         fi_banco_fornec_id = zvl(p_emp_fi_banco_id, NULL),
         num_agencia        = TRIM(p_emp_num_agencia),
         num_conta          = TRIM(p_emp_num_conta),
         tipo_conta         = TRIM(p_emp_tipo_conta),
         status             = 'CHECKIN_OK',
         produto_fiscal_id  = zvl(p_produto_fiscal_id, NULL),
         produto            = TRIM(p_produto)
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- atualizacao de dados bancarios da empresa emissora
  ------------------------------------------------------------
  IF p_emp_flag_atualizar = 'S' AND nvl(p_emp_fi_banco_id, 0) > 0
  THEN
   pessoa_pkg.xml_gerar(v_emp_emissora_id, v_xml_antes, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- atualiza os dados bancarios na tabela de pessoa
   UPDATE pessoa
      SET fi_banco_id = p_emp_fi_banco_id,
          num_agencia = p_emp_num_agencia,
          num_conta   = p_emp_num_conta,
          tipo_conta  = rtrim(p_emp_tipo_conta)
    WHERE pessoa_id = v_emp_emissora_id;
   --
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            v_emp_emissora_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- gera log da atualizacao da pessoa
   pessoa_pkg.xml_gerar(v_emp_emissora_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_identif_objeto := v_emp_apelido;
   v_compl_histor   := 'Alteração de informações bancárias - check-in da NF ' || TRIM(v_num_doc);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'PESSOA',
                    'ALTERAR',
                    v_identif_objeto,
                    v_emp_emissora_id,
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
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' ||
                      TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S') || ' - completar';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_pagto_autom = 'S'
  THEN
   nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_nota_fiscal_id,
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
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
 END completar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/04/2007
  -- DESCRICAO: Atualização de NOTA_FISCAL de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id         IN nota_fiscal.nota_fiscal_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_cliente_job_id      job.cliente_id%TYPE;
  v_valor_bruto         nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum    nota_fiscal.valor_bruto%TYPE;
  v_valor_mao_obra      nota_fiscal.valor_mao_obra%TYPE;
  v_data_entrada        nota_fiscal.data_entrada%TYPE;
  v_data_emissao        nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim     nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id          nota_fiscal.cliente_id%TYPE;
  v_status_nf           nota_fiscal.status%TYPE;
  v_num_doc             nota_fiscal.num_doc%TYPE;
  v_resp_pgto_receita   nota_fiscal.resp_pgto_receita%TYPE;
  v_tipo_doc            tipo_doc_nf.codigo%TYPE;
  v_emp_apelido         pessoa.apelido%TYPE;
  v_emp_cnpj            pessoa.cnpj%TYPE;
  v_flag_incentivo_fat  pessoa.flag_emp_incentivo%TYPE;
  v_checkin_pagto_autom VARCHAR2(10);
  v_checkin_financeiro  VARCHAR2(10);
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_num_doc := TRIM(p_num_doc);
  --
  v_checkin_pagto_autom := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_PAGTO_AUTOM');
  v_checkin_financeiro  := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_FINANCEIRO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.job_id,
         jo.cliente_id,
         nf.status,
         nf.valor_mao_obra
    INTO v_job_id,
         v_cliente_job_id,
         v_status_nf,
         v_valor_mao_obra
    FROM nota_fiscal nf,
         job         jo
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.job_id = jo.job_id(+);
  --
  IF v_status_nf NOT IN ('CHECKIN_PEND', 'CHECKIN_OK')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite a alteração.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada (testa tb privilegio)
  ------------------------------------------------------------
  sub_checkin_consistir(p_usuario_sessao_id,
                        p_empresa_id,
                        v_job_id,
                        p_vetor_item_id,
                        p_vetor_carta_acordo_id,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_vetor_valor_aprovado,
                        p_vetor_valor_fornecedor,
                        p_vetor_valor_bv,
                        p_vetor_valor_tip,
                        NULL,
                        NULL,
                        p_emp_emissora_id,
                        p_tipo_doc_nf_id,
                        p_num_doc,
                        p_serie,
                        p_data_entrada,
                        p_data_emissao,
                        p_data_pri_vencim,
                        p_valor_bruto,
                        p_emp_receita_id,
                        p_flag_repasse,
                        p_flag_patrocinio,
                        p_tipo_receita,
                        p_resp_pgto_receita,
                        p_desc_servico,
                        p_municipio_servico,
                        p_uf_servico,
                        p_emp_faturar_por_id,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf)
    INTO v_emp_apelido,
         v_emp_cnpj
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_num_doc IS NULL
  THEN
   -- documento virtual (negociacao), sem numero proprio
   SELECT 'NE' || TRIM(to_char(seq_num_doc.nextval, '00000000'))
     INTO v_num_doc
     FROM dual;
  END IF;
  --
  v_valor_bruto     := nvl(moeda_converter(p_valor_bruto), 0);
  v_data_entrada    := data_converter(p_data_entrada);
  v_data_emissao    := data_converter(p_data_emissao);
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  --
  SELECT flag_emp_incentivo
    INTO v_flag_incentivo_fat
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   v_cliente_id := p_emp_receita_id;
  END IF;
  --  
  /* a pedido da Ana Maria 20/05/2016, o cliente da NF voltou a ser a Incentivo
  IF v_flag_incentivo_fat = 'S' THEN
     -- empresa de faturamento eh a Incentivo. Mantem o 
     -- cliente do job como cliente da nota
     v_cliente_id := v_cliente_job_id;
  END IF;*/
  --
  IF nvl(v_cliente_id, 0) = 0
  THEN
   v_cliente_id := p_emp_faturar_por_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NULL
  THEN
   v_resp_pgto_receita := NULL;
  ELSE
   v_resp_pgto_receita := p_resp_pgto_receita;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE nota_fiscal_id <> p_nota_fiscal_id
     AND emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE nota_fiscal
     SET cliente_id            = v_cliente_id,
         emp_emissora_id       = p_emp_emissora_id,
         tipo_doc_nf_id        = p_tipo_doc_nf_id,
         num_doc               = TRIM(v_num_doc),
         serie                 = TRIM(p_serie),
         data_entrada          = v_data_entrada,
         data_emissao          = v_data_emissao,
         data_pri_vencim       = v_data_pri_vencim,
         valor_bruto           = v_valor_bruto,
         municipio_servico     = TRIM(p_municipio_servico),
         uf_servico            = TRIM(p_uf_servico),
         emp_faturar_por_id    = p_emp_faturar_por_id,
         flag_item_patrocinado = p_flag_patrocinio,
         tipo_receita          = TRIM(p_tipo_receita),
         emp_receita_id        = zvl(p_emp_receita_id, NULL),
         resp_pgto_receita     = v_resp_pgto_receita
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- associacao dos itens a nota fiscal
  ------------------------------------------------------------
  DELETE FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  sub_itens_adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      p_nota_fiscal_id,
                      p_vetor_item_id,
                      p_vetor_carta_acordo_id,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      p_vetor_valor_aprovado,
                      p_vetor_valor_fornecedor,
                      p_vetor_valor_bv,
                      p_vetor_valor_tip,
                      NULL,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais na NF para campos desnormalizados
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET tipo_fatur_bv     = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id),
         flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_bruto_acum
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_valor_bruto_acum <> v_valor_bruto
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor acumulado dos itens dessa nota (4) (' ||
                 moeda_mostrar(v_valor_bruto_acum, 'S') ||
                 ') não corresponde ao valor bruto da nota fiscal (' ||
                 moeda_mostrar(v_valor_bruto, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula impostos, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_financeiro = 'S'
  THEN
   sub_impostos_calcular(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         p_nota_fiscal_id,
                         moeda_mostrar(v_valor_mao_obra, 'N'),
                         moeda_mostrar(v_valor_bruto, 'N'), -- base ISS
                         moeda_mostrar(v_valor_bruto, 'N'), -- base IR
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- nao precisa deixar a NF com pendencia financeira
   UPDATE nota_fiscal
      SET status = 'CHECKIN_OK'
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_emp_receita_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- integracao com sistemas externos
  it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                           p_empresa_id,
                           p_emp_emissora_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento, se for o caso.
  ------------------------------------------------------------
  SELECT nf.status
    INTO v_status_nf
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_checkin_pagto_autom = 'S' AND v_status_nf = 'CHECKIN_OK'
  THEN
   -- 
   nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_nota_fiscal_id,
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
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
 PROCEDURE atualizar_nfe
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/06/2017
  -- DESCRICAO: Atualização de NOTA_FISCAL de entrada ja comandada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id     IN nota_fiscal.nota_fiscal_id%TYPE,
  p_emp_emissora_id    IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id     IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc            IN VARCHAR2,
  p_serie              IN nota_fiscal.serie%TYPE,
  p_tipo_pag_pessoa    IN nota_fiscal.tipo_pag_pessoa%TYPE,
  p_valor_mao_obra     IN VARCHAR2,
  p_data_entrada       IN VARCHAR2,
  p_data_emissao       IN VARCHAR2,
  p_data_pri_vencim    IN VARCHAR2,
  p_cliente_id         IN nota_fiscal.cliente_id%TYPE,
  p_emp_faturar_por_id IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_municipio_servico  IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico         IN nota_fiscal.uf_servico%TYPE,
  p_desc_servico       IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_valor_mao_obra  nota_fiscal.valor_mao_obra%TYPE;
  v_data_entrada    nota_fiscal.data_entrada%TYPE;
  v_data_emissao    nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim nota_fiscal.data_pri_vencim%TYPE;
  v_status_nf       nota_fiscal.status%TYPE;
  v_num_doc         nota_fiscal.num_doc%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_num_doc := TRIM(p_num_doc);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NOTA_FISCAL_A',
                                NULL,
                                p_nota_fiscal_id,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.job_id,
         nf.status,
         nf.valor_bruto
    INTO v_job_id,
         v_status_nf,
         v_valor_bruto
    FROM nota_fiscal nf,
         job         jo
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.job_id = jo.job_id(+);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor (empresa emissora) não existe (' || to_char(p_emp_emissora_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF length(p_serie) > 2
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de série não pode ter mais que 2 caracteres .';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_pag_pessoa) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('tipo_pag_pessoa', p_tipo_pag_pessoa) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Conta específica inválida.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_tipo_doc = 'PP' AND TRIM(p_tipo_pag_pessoa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de nota fiscal, o preenchimento da conta específica ' ||
                 'é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_mao_obra) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão de obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_emissao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de emissão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_emissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_entrada) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de entrada é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_entrada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_pri_vencim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data do primeiro vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_pri_vencim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do primeiro vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Faturado Contra é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_cliente_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente (faturado contra) não existe (' || to_char(p_cliente_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Faturar Por é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do local do serviço é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do local do serviço é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_municipio_servico) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do município do serviço é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NOT NULL
  THEN
   IF cep_pkg.municipio_validar(p_uf_servico, p_municipio_servico) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do local da prestação de serviço inválido (' || p_uf_servico || '/' ||
                  p_municipio_servico || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_desc_servico) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição do serviço não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf)
    INTO v_emp_apelido,
         v_emp_cnpj
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  v_data_entrada    := data_converter(p_data_entrada);
  v_data_emissao    := data_converter(p_data_emissao);
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  v_valor_mao_obra  := nvl(moeda_converter(p_valor_mao_obra), 0);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE nota_fiscal_id <> p_nota_fiscal_id
     AND emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE nota_fiscal
     SET emp_emissora_id    = p_emp_emissora_id,
         tipo_doc_nf_id     = p_tipo_doc_nf_id,
         num_doc            = TRIM(v_num_doc),
         serie              = TRIM(p_serie),
         tipo_pag_pessoa    = TRIM(p_tipo_pag_pessoa),
         valor_mao_obra     = v_valor_mao_obra,
         data_entrada       = v_data_entrada,
         data_emissao       = v_data_emissao,
         data_pri_vencim    = v_data_pri_vencim,
         municipio_servico  = TRIM(p_municipio_servico),
         uf_servico         = TRIM(p_uf_servico),
         desc_servico       = TRIM(p_desc_servico),
         cliente_id         = p_cliente_id,
         emp_faturar_por_id = p_emp_faturar_por_id
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 END atualizar_nfe;
 --
 --
 PROCEDURE nf_saida_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/06/2017
  -- DESCRICAO: Atualização de NOTA_FISCAL de saida ja comandada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN VARCHAR2,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_valor_mao_obra    IN VARCHAR2,
  p_data_emissao      IN VARCHAR2,
  p_data_pri_vencim   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_valor_mao_obra  nota_fiscal.valor_mao_obra%TYPE;
  v_data_emissao    nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim nota_fiscal.data_pri_vencim%TYPE;
  v_status_nf       nota_fiscal.status%TYPE;
  v_num_doc         nota_fiscal.num_doc%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_num_doc := TRIM(p_num_doc);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'NOTA_FISCAL_SAI_I', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.job_id,
         nf.status,
         nf.valor_bruto
    INTO v_job_id,
         v_status_nf,
         v_valor_bruto
    FROM nota_fiscal nf,
         job         jo
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.job_id = jo.job_id(+);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa emissora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa emissora) não existe (' || to_char(p_emp_emissora_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id
     AND flag_nf_saida = 'S';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF length(p_num_doc) > 10
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de série da nota fiscal não pode ter mais que 10 caracteres .';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_mao_obra) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão de obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_emissao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de emissão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_emissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_pri_vencim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data do primeiro vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_pri_vencim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do primeiro vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf)
    INTO v_emp_apelido,
         v_emp_cnpj
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  v_data_emissao    := data_converter(p_data_emissao);
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  v_valor_mao_obra  := nvl(moeda_converter(p_valor_mao_obra), 0);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE nota_fiscal_id <> p_nota_fiscal_id
     AND emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE nota_fiscal
     SET emp_emissora_id = p_emp_emissora_id,
         tipo_doc_nf_id  = p_tipo_doc_nf_id,
         num_doc         = TRIM(v_num_doc),
         serie           = TRIM(p_serie),
         valor_mao_obra  = v_valor_mao_obra,
         data_emissao    = v_data_emissao,
         data_pri_vencim = v_data_pri_vencim
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || ' - NF Saída: ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 END nf_saida_atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 30/04/2007
  -- DESCRICAO: Exclusão de NOTA_FISCAL de entrada (fornecedor).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            07/07/2008  Nao exclui do sistema externo qdo o fornecedor é INTERNO.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            18/01/2011  Novo atributo flag_pago_cliente na NF.
  -- Silvia            06/04/2011  Adaptacao para uso de integracao via webservice.
  -- Silvia            24/09/2012  Consistencia de arquivos e teste de novo privilegio.
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  -- Silvia            26/04/2016  Tratamento de multiplos arquivos.
  -- Silvia            12/03/2021  Exclusao de parcela_nf
  -- Ana Luiza         05/11/2024  Exclusao de faturamento que ainda nao esta no adn
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_job_id            job.job_id%TYPE;
  v_fornecedor_id     pessoa.pessoa_id%TYPE;
  v_emp_apelido       pessoa.apelido%TYPE;
  v_emp_cnpj          pessoa.cnpj%TYPE;
  v_num_doc           nota_fiscal.num_doc%TYPE;
  v_tipo_doc          tipo_doc_nf.codigo%TYPE;
  v_serie             nota_fiscal.serie%TYPE;
  v_valor_bruto       nota_fiscal.valor_bruto%TYPE;
  v_status_nf         nota_fiscal.status%TYPE;
  v_resp_pgto_receita nota_fiscal.resp_pgto_receita%TYPE;
  v_cod_ext_nf        nota_fiscal.cod_ext_nf%TYPE;
  v_faturamento_id    faturamento.faturamento_id%TYPE;
  v_cod_ext_fatur     faturamento.cod_ext_fatur%TYPE;
  v_operador          lancamento.operador%TYPE;
  v_descricao         lancamento.descricao%TYPE;
  v_tipo_fatur_bv     VARCHAR2(10);
  v_valor_bv          NUMBER;
  v_valor_tip         NUMBER;
  v_valor_bv_tip      NUMBER;
  v_carta_acordo_id   carta_acordo.carta_acordo_id%TYPE;
  v_xml_atual         CLOB;
  --
  CURSOR c_it IS
   SELECT item_nota_id,
          item_id
     FROM item_nota
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  CURSOR c_ar IS
   SELECT arquivo_id
     FROM arquivo_nf
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.num_doc,
         td.codigo,
         nf.serie,
         nf.valor_bruto,
         nf.status,
         pe.pessoa_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         nf.job_id,
         nf.resp_pgto_receita,
         TRIM(nf.cod_ext_nf),
         nf.tipo_fatur_bv
    INTO v_num_doc,
         v_tipo_doc,
         v_serie,
         v_valor_bruto,
         v_status_nf,
         v_fornecedor_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_job_id,
         v_resp_pgto_receita,
         v_cod_ext_nf,
         v_tipo_fatur_bv
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  -- verifica se o usuario tem privilegio de excluir NF 
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NOTA_FISCAL_E',
                                NULL,
                                p_nota_fiscal_id,
                                p_empresa_id) = 0
  THEN
   -- verifica se o usuario tem privilegio apenas operacional 
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'NOTA_FISCAL_C',
                                 NULL,
                                 p_nota_fiscal_id,
                                 p_empresa_id) = 0 OR
      v_status_nf NOT IN ('CHECKIN_PEND', 'CHECKIN_OK')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0),
         MIN(carta_acordo_id)
    INTO v_valor_bv,
         v_valor_tip,
         v_carta_acordo_id
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  v_valor_bv_tip := v_valor_bv + v_valor_tip;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_status_nf NOT IN ('CHECKIN_PEND', 'CHECKIN_OK', 'FATUR_LIB')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite a exclusão.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur  it,
         faturamento fa
   WHERE it.nota_fiscal_id = p_nota_fiscal_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'N';
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal de entrada já está associada a uma ordem de faturamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE nota_fiscal_sai_id = p_nota_fiscal_id;
  --
  IF v_qt > 0
  THEN
   -- exclusao desse tipo eh via proc nf_saida_excluir
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal de saída já está associada a uma ordem de faturamento.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se a nota fiscal tem BV associado
  SELECT MAX(fa.faturamento_id),
         MAX(fa.cod_ext_fatur)
    INTO v_faturamento_id,
         v_cod_ext_fatur
    FROM item_fatur  it,
         faturamento fa
   WHERE it.nota_fiscal_id = p_nota_fiscal_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'S';
  --
  IF v_cod_ext_fatur IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota tem BV já comandado para o sistema financeiro. ' ||
                 'Exclua primeiro essa ordem de faturamento (' || to_char(v_faturamento_id) ||
                 ') via JobOne.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de BV e integracao com sistema externo
  ------------------------------------------------------------
  IF v_faturamento_id IS NOT NULL
  THEN
   -- exclui a ordem de faturamento do BV
   faturamento_pkg.excluir(p_usuario_sessao_id,
                           p_empresa_id,
                           'N',
                           v_faturamento_id,
                           p_erro_cod,
                           p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_cod_ext_nf IS NOT NULL
  THEN
   -- integracao com sistemas externos
   it_controle_pkg.integrar('NOTA_FISCAL_ENT_EXCLUIR',
                            p_empresa_id,
                            p_nota_fiscal_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   DELETE FROM item_nota
    WHERE item_nota_id = r_it.item_nota_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  FOR r_ar IN c_ar
  LOOP
   arquivo_pkg.excluir(p_usuario_sessao_id, r_ar.arquivo_id, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  IF v_status_nf = 'FATUR_LIB' AND v_tipo_fatur_bv IN ('CRE', 'PER') AND v_valor_bv_tip > 0
  THEN
   -- estorno do credito da agencia junto ao fornecedor (movimento de saida).
   v_descricao := 'Estorno do crédito de BV/TIP para a ' || v_lbl_agencia_singular || ': ' ||
                  TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
   --
   IF v_carta_acordo_id IS NOT NULL
   THEN
    v_descricao := v_descricao || ' - ' ||
                   carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'S');
   END IF;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     v_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_bv_tip,
     'S',
     v_operador,
     NULL);
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM parcela_nf
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  DELETE FROM duplicata
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  DELETE FROM imposto_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --ALCBO_051124
  DELETE FROM item_fatur
   WHERE nota_fiscal_id = p_nota_fiscal_id
     AND faturamento_id IN (SELECT faturamento_id
                              FROM faturamento
                             WHERE cod_ext_fatur IS NULL
                               AND flag_bv = 'S');
  --
  DELETE FROM faturamento
   WHERE faturamento_id IN (SELECT faturamento_id
                              FROM item_fatur
                             WHERE nota_fiscal_id = p_nota_fiscal_id)
     AND cod_ext_fatur IS NULL
     AND flag_bv = 'S';
  --
  DELETE FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_job_id IS NOT NULL
  THEN
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' ||
                      TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 PROCEDURE apagar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Exclui uma NF de entrada (fornecedor) mesmo já estando integrada com o
  --  financeiro.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/04/2016  Tratamento de multiplos arquivos.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nota_fiscal_id  nota_fiscal.nota_fiscal_id%TYPE;
  v_nota_fiscal_aux nota_fiscal.nota_fiscal_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_status_nf       nota_fiscal.status%TYPE;
  v_num_doc         nota_fiscal.num_doc%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_serie           nota_fiscal.serie%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_job_id          job.job_id%TYPE;
  v_fornecedor_id   pessoa.pessoa_id%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_faturamento_id  faturamento.faturamento_id%TYPE;
  v_tipo_fatur_bv   VARCHAR2(10);
  v_operador        lancamento.operador%TYPE;
  v_descricao       lancamento.descricao%TYPE;
  v_valor_bv        NUMBER;
  v_valor_tip       NUMBER;
  v_valor_bv_tip    NUMBER;
  v_carta_acordo_id carta_acordo.carta_acordo_id%TYPE;
  v_xml_atual       CLOB;
  --
  CURSOR c_it IS
   SELECT item_nota_id,
          item_id
     FROM item_nota
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  CURSOR c_ar IS
   SELECT arquivo_id
     FROM arquivo_nf
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de nota fiscal/documento deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo)
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_tipo_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nota_fiscal_id),
         MIN(nota_fiscal_id)
    INTO v_nota_fiscal_id,
         v_nota_fiscal_aux
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND num_doc = p_num_doc
     AND nvl(serie, 'ZZZ') = nvl(TRIM(p_serie), 'ZZZ');
  --
  IF v_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal/documento não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_nota_fiscal_id <> v_nota_fiscal_aux
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Há mais de uma nota fiscal com esse número/tipo/série para esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         nf.valor_bruto,
         pe.pessoa_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         nf.num_doc,
         nf.serie,
         nf.tipo_fatur_bv,
         nf.status
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_valor_bruto,
         v_fornecedor_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_num_doc,
         v_serie,
         v_tipo_fatur_bv,
         v_status_nf
    FROM job         jo,
         nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = v_nota_fiscal_id
     AND nf.job_id = jo.job_id(+)
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur  it,
         faturamento fa
   WHERE it.nota_fiscal_id = v_nota_fiscal_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'N';
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já está associada a uma ordem de faturamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0),
         MIN(carta_acordo_id)
    INTO v_valor_bv,
         v_valor_tip,
         v_carta_acordo_id
    FROM item_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  v_valor_bv_tip := v_valor_bv + v_valor_tip;
  --
  SELECT apelido
    INTO v_operador
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se a nota fiscal tem BV associado
  SELECT MAX(fa.faturamento_id)
    INTO v_faturamento_id
    FROM item_fatur  it,
         faturamento fa
   WHERE it.nota_fiscal_id = v_nota_fiscal_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'S';
  --
  IF v_faturamento_id IS NOT NULL
  THEN
   -- exclui a ordem de faturamento do BV
   faturamento_pkg.excluir(p_usuario_sessao_id,
                           p_empresa_id,
                           'N',
                           v_faturamento_id,
                           p_erro_cod,
                           p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  FOR r_it IN c_it
  LOOP
   DELETE FROM item_nota
    WHERE item_nota_id = r_it.item_nota_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF: ' || p_num_doc || ' ' || p_serie;
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'APAGAR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
                   v_compl_histor,
                   p_justificativa,
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
  ------------------------------------------------------------
  -- exclusao final
  ------------------------------------------------------------
  FOR r_ar IN c_ar
  LOOP
   arquivo_pkg.excluir(p_usuario_sessao_id, r_ar.arquivo_id, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  IF v_status_nf = 'FATUR_LIB' AND v_tipo_fatur_bv IN ('CRE', 'PER') AND v_valor_bv_tip > 0
  THEN
   -- estorno do credito da agencia junto ao fornecedor (movimento de saida).
   v_descricao := 'Estorno do crédito de BV/TIP para a ' || v_lbl_agencia_singular || ': ' ||
                  TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
   --
   IF v_carta_acordo_id IS NOT NULL
   THEN
    v_descricao := v_descricao || ' - ' ||
                   carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'S');
   END IF;
   --
   INSERT INTO lancamento
    (lancamento_id,
     pessoa_id,
     data_lancam,
     descricao,
     valor_lancam,
     tipo_mov,
     operador,
     justificativa)
   VALUES
    (seq_lancamento.nextval,
     v_fornecedor_id,
     SYSDATE,
     v_descricao,
     v_valor_bv_tip,
     'S',
     v_operador,
     NULL);
  END IF;
  --
  DELETE FROM duplicata
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  DELETE FROM imposto_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  DELETE FROM nota_fiscal
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  IF v_job_id IS NOT NULL
  THEN
   job_pkg.status_tratar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_job_id,
                         'ALL',
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  p_historico_id := v_historico_id;
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
 END apagar;
 --
 --
 PROCEDURE fornecedor_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 19/09/2012
  -- DESCRICAO: Criação de fornecedor via tela de check-in.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/12/2016  Novos parametros flag_simples e flag_cpom
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_emp2_apelido          IN pessoa.apelido%TYPE,
  p_emp2_nome             IN pessoa.nome%TYPE,
  p_emp2_flag_simples     IN VARCHAR2,
  p_emp2_flag_cpom        IN VARCHAR2,
  p_emp2_cnpj             IN pessoa.cnpj%TYPE,
  p_emp2_inscr_estadual   IN pessoa.inscr_estadual%TYPE,
  p_emp2_inscr_municipal  IN pessoa.inscr_municipal%TYPE,
  p_emp2_inscr_inss       IN pessoa.inscr_inss%TYPE,
  p_emp2_endereco         IN pessoa.endereco%TYPE,
  p_emp2_num_ender        IN pessoa.num_ender%TYPE,
  p_emp2_compl_ender      IN pessoa.compl_ender%TYPE,
  p_emp2_bairro           IN pessoa.bairro%TYPE,
  p_emp2_cep              IN pessoa.cep%TYPE,
  p_emp2_cidade           IN pessoa.cidade%TYPE,
  p_emp2_uf               IN pessoa.uf%TYPE,
  p_emp2_obs              IN pessoa.obs%TYPE,
  p_emp2_fi_banco_id      IN pessoa.fi_banco_id%TYPE,
  p_emp2_num_agencia      IN pessoa.num_agencia%TYPE,
  p_emp2_num_conta        IN pessoa.num_conta%TYPE,
  p_emp2_tipo_conta       IN pessoa.tipo_conta%TYPE,
  p_emp2_nome_titular     IN pessoa.nome_titular%TYPE,
  p_emp2_cnpj_cpf_titular IN pessoa.cnpj_cpf_titular%TYPE,
  p_emp2_perc_bv          IN VARCHAR2,
  p_emp2_tipo_fatur_bv    IN VARCHAR2,
  p_emp2_perc_imposto     IN VARCHAR2,
  p_fornecedor_id         OUT pessoa.pessoa_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  --
 BEGIN
  --
  pessoa_pkg.basico_adicionar(p_usuario_sessao_id,
                              p_empresa_id,
                              'S',
                              p_emp2_apelido,
                              p_emp2_nome,
                              p_emp2_flag_simples,
                              p_emp2_flag_cpom,
                              p_emp2_cnpj,
                              p_emp2_inscr_estadual,
                              p_emp2_inscr_municipal,
                              p_emp2_inscr_inss,
                              p_emp2_endereco,
                              p_emp2_num_ender,
                              p_emp2_compl_ender,
                              p_emp2_bairro,
                              p_emp2_cep,
                              p_emp2_cidade,
                              p_emp2_uf,
                              p_emp2_obs,
                              p_emp2_fi_banco_id,
                              p_emp2_num_agencia,
                              p_emp2_num_conta,
                              p_emp2_tipo_conta,
                              p_emp2_nome_titular,
                              p_emp2_cnpj_cpf_titular,
                              --p_emp2_perc_bv,
                              p_emp2_tipo_fatur_bv,
                              --p_emp2_perc_imposto,
                              p_fornecedor_id,
                              p_erro_cod,
                              p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio (a verificacao ficou p/ o final,
  -- pois ela depende dos tipos dessa pessoa que estao gravados no banco)
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PESSOA_C',
                                p_fornecedor_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
 END fornecedor_adicionar;
 --
 --
 PROCEDURE receita_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Alteracao de receita / patrocinio de NF.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/01/2009  Recalculo dos valores de saldos dos itens associados a
  --                               nota fiscal que está sendo alterada.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_emp_patrocinio_id IN nota_fiscal.cliente_id%TYPE,
  p_tipo_receita      IN nota_fiscal.tipo_receita%TYPE,
  p_emp_receita_id    IN nota_fiscal.emp_receita_id%TYPE,
  p_resp_pgto_receita IN nota_fiscal.resp_pgto_receita%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nota_fiscal_id  nota_fiscal.nota_fiscal_id%TYPE;
  v_nota_fiscal_aux nota_fiscal.nota_fiscal_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_job_id          job.job_id%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
  CURSOR c_it IS
   SELECT item_nota_id,
          item_id
     FROM item_nota
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de nota fiscal/documento deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo)
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_tipo_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nf.nota_fiscal_id),
         MIN(nf.nota_fiscal_id)
    INTO v_nota_fiscal_id,
         v_nota_fiscal_aux
    FROM nota_fiscal nf
   WHERE nf.emp_emissora_id = p_emp_emissora_id
     AND nf.tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nf.num_doc = TRIM(p_num_doc)
     AND nvl(nf.serie, 'ZZZ') = nvl(p_serie, 'ZZZ');
  --
  IF v_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal/documento não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_nota_fiscal_id <> v_nota_fiscal_aux
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Há mais de uma nota fiscal com esse número/tipo/série para esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         nf.valor_bruto,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf)
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_valor_bruto,
         v_emp_apelido,
         v_emp_cnpj
    FROM job         jo,
         nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = v_nota_fiscal_id
     AND nf.job_id = jo.job_id(+)
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_tipo_receita) IS NOT NULL AND nvl(p_emp_patrocinio_id, 0) <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Patrocínio e receita não podem ser indicados ao mesmo tempo.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NULL AND nvl(p_emp_patrocinio_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Algum tipo de receita ou patrocínio deve ser indicado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL
  THEN
   -- o tipo de receita foi informado
   IF util_pkg.desc_retornar('tipo_receita', p_tipo_receita) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de receita inválida (' || p_tipo_receita || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_emp_receita_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa fonte da receita deve ser especificada.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_receita_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa fonte da receita não existe.';
    RAISE v_exception;
   END IF;
   --
   IF util_pkg.desc_retornar('resp_pgto_receita', p_resp_pgto_receita) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Responsável pelo pgto da receita (fonte, ' || v_lbl_agencia_singular ||
                  ') inválido ' || 'ou não especificado.';
    RAISE v_exception;
   END IF;
  ELSE
   -- o tipo de receita nao foi informado
   IF nvl(p_emp_receita_id, 0) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa fonte da receita só deve ser preenchida quando ' ||
                  'o tipo de receita for especificado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_emp_patrocinio_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_emp_patrocinio_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa do patrocínio não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_emp_patrocinio_id, 0) <> 0
  THEN
   UPDATE nota_fiscal
      SET cliente_id            = p_emp_patrocinio_id,
          flag_item_patrocinado = 'S',
          emp_receita_id        = NULL,
          tipo_receita          = NULL,
          resp_pgto_receita     = NULL
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL
  THEN
   UPDATE nota_fiscal
      SET emp_receita_id        = p_emp_receita_id,
          tipo_receita          = p_tipo_receita,
          resp_pgto_receita     = p_resp_pgto_receita,
          flag_item_patrocinado = 'N'
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  FOR r_it IN c_it
  LOOP
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF: ' || TRIM(p_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR_ESP1',
                   v_identif_objeto,
                   v_nota_fiscal_id,
                   v_compl_histor,
                   p_justificativa,
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
  p_historico_id := v_historico_id;
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
 END receita_atualizar;
 --
 --
 PROCEDURE numero_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Alteracao do numero de NF.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_num_doc_novo      IN nota_fiscal.num_doc%TYPE,
  p_serie_novo        IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nota_fiscal_id  nota_fiscal.nota_fiscal_id%TYPE;
  v_nota_fiscal_aux nota_fiscal.nota_fiscal_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_emp_emissora_id nota_fiscal.emp_emissora_id%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_job_id          job.job_id%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de nota fiscal/documento deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo)
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_tipo_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nota_fiscal_id),
         MIN(nota_fiscal_id)
    INTO v_nota_fiscal_id,
         v_nota_fiscal_aux
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND num_doc = p_num_doc
     AND nvl(serie, 'ZZZ') = nvl(TRIM(p_serie), 'ZZZ');
  --
  IF v_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal/documento não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_nota_fiscal_id <> v_nota_fiscal_aux
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Há mais de uma nota fiscal com esse número/tipo/série para esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         nf.valor_bruto,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         nf.emp_emissora_id
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_valor_bruto,
         v_emp_apelido,
         v_emp_cnpj,
         v_emp_emissora_id
    FROM job         jo,
         nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = v_nota_fiscal_id
     AND nf.job_id = jo.job_id(+)
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_num_doc_novo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O novo número do documento deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE nota_fiscal_id <> v_nota_fiscal_id
     AND emp_emissora_id = v_emp_emissora_id
     AND num_doc = TRIM(p_num_doc_novo)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'ZZZ') = nvl(TRIM(p_serie_novo), 'ZZZ');
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse novo número de nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET num_doc = TRIM(p_num_doc_novo),
         serie   = TRIM(p_serie_novo)
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF: ' || TRIM(p_num_doc_novo) || ' ' ||
                      TRIM(p_serie_novo);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S') || ' - Nº antigo: ' || p_num_doc || ' ' ||
                    p_serie;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR_ESP2',
                   v_identif_objeto,
                   v_nota_fiscal_id,
                   v_compl_histor,
                   p_justificativa,
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
  p_historico_id := v_historico_id;
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
 END numero_atualizar;
 --
 --
 PROCEDURE pagto_comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: Comanda o pagamento da nota fiscai de entrada (fornecedor).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/07/2008  Nao envia p/ sistema externo qdo o fornecedor é INTERNO.
  -- Silvia            18/01/2011  Novos atributos tipo_fatur_bv e flag_pago_cliente na NF.
  -- Silvia            06/04/2011  Adaptacao para uso de integracao via webservice.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN NUMBER,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id            IN nota_fiscal.nota_fiscal_id%TYPE,
  p_fi_banco_cobrador_id      IN nota_fiscal.fi_banco_cobrador_id%TYPE,
  p_vetor_data_vencim         IN VARCHAR2,
  p_vetor_valor_duplicata     IN VARCHAR2,
  p_vetor_fi_tipo_imposto     IN VARCHAR2,
  p_vetor_perc_imposto        IN VARCHAR2,
  p_fi_tipo_imposto_pessoa_id IN fi_tipo_imposto_pessoa.fi_tipo_imposto_pessoa_id%TYPE,
  p_flag_reter_iss            IN fi_tipo_imposto_pessoa.flag_reter%TYPE,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_job_id              job.job_id%TYPE;
  v_status_nf           nota_fiscal.status%TYPE;
  v_motivo_alt_aliquota nota_fiscal.motivo_alt_aliquota%TYPE;
  v_checkin_financeiro  VARCHAR2(10);
  --
 BEGIN
  v_qt := 0;
  --
  v_checkin_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_FINANCEIRO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.job_id,
         nf.status,
         nf.motivo_alt_aliquota
    INTO v_job_id,
         v_status_nf,
         v_motivo_alt_aliquota
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'NOTA_FISCAL_PAG', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_nf <> 'CHECKIN_OK'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fi_banco_cobrador_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_cobrador_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco cobrador não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_checkin_financeiro = 'S'
  THEN
   sub_impostos_completar(p_usuario_sessao_id,
                          p_empresa_id,
                          p_nota_fiscal_id,
                          NULL,
                          NULL,
                          NULL,
                          p_fi_banco_cobrador_id,
                          p_vetor_data_vencim,
                          p_vetor_valor_duplicata,
                          p_vetor_fi_tipo_imposto,
                          p_vetor_perc_imposto,
                          p_fi_tipo_imposto_pessoa_id,
                          p_flag_reter_iss,
                          v_motivo_alt_aliquota,
                          p_erro_cod,
                          p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     p_nota_fiscal_id,
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
 END pagto_comandar;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 24/09/2012
  -- DESCRICAO: Adicionar arquivo na nota fiscal.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/04/2015  Verificacao de privilegio com enderecamento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_nota_fiscal_id    IN arquivo_nf.nota_fiscal_id%TYPE,
  p_descricao         IN arquivo.descricao%TYPE,
  p_nome_original     IN arquivo.nome_original%TYPE,
  p_nome_fisico       IN arquivo.nome_fisico%TYPE,
  p_mime_type         IN arquivo.mime_type%TYPE,
  p_tamanho           IN arquivo.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_empresa_id      empresa.empresa_id%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_num_doc         nota_fiscal.num_doc%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_serie           nota_fiscal.serie%TYPE;
  v_status_nf       nota_fiscal.status%TYPE;
  v_job_id          nota_fiscal.job_id%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.num_doc,
         td.codigo,
         nf.serie,
         nf.status,
         nf.job_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         pe.empresa_id
    INTO v_num_doc,
         v_tipo_doc,
         v_serie,
         v_status_nf,
         v_job_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_empresa_id
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NOTA_FISCAL_C',
                                NULL,
                                p_nota_fiscal_id,
                                v_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_nf NOT IN ('CHECKIN_PEND', 'CHECKIN_OK')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite a alteração.';
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
   p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = v_empresa_id
     AND codigo = 'NOTA_FISCAL';
  -- 
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_nota_fiscal_id,
                        v_tipo_arquivo_id,
                        p_nome_original,
                        p_nome_fisico,
                        p_descricao,
                        p_mime_type,
                        p_tamanho,
                        NULL,
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
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' ||
                      TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
  --                  
  v_compl_histor := 'Anexação de arquivo na Nota Fiscal (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 END arquivo_adicionar;
 --
 --
 PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 24/09/2012
  -- DESCRICAO: Excluir arquivo da Nota Fiscal
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/12/2016  Teste de obrigatoriedade de anexar documento.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_nota_fiscal_id    nota_fiscal.nota_fiscal_id%TYPE;
  v_job_id            nota_fiscal.job_id%TYPE;
  v_nome_original     arquivo.nome_original%TYPE;
  v_empresa_id        empresa.empresa_id%TYPE;
  v_emp_apelido       pessoa.apelido%TYPE;
  v_emp_cnpj          pessoa.cnpj%TYPE;
  v_num_doc           nota_fiscal.num_doc%TYPE;
  v_tipo_doc          tipo_doc_nf.codigo%TYPE;
  v_serie             nota_fiscal.serie%TYPE;
  v_status_nf         nota_fiscal.status%TYPE;
  v_checkin_com_docum VARCHAR2(10);
  --
 BEGIN
  v_qt                := 0;
  v_checkin_com_docum := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_CHECKIN_COM_DOCUM');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         arquivo_nf  ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.nota_fiscal_id = nf.nota_fiscal_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.nota_fiscal_id,
         ar.nome_original
    INTO v_nota_fiscal_id,
         v_nome_original
    FROM arquivo_nf nf,
         arquivo    ar
   WHERE nf.arquivo_id = p_arquivo_id
     AND nf.arquivo_id = ar.arquivo_id;
  --
  --
  SELECT nf.num_doc,
         td.codigo,
         nf.serie,
         nf.status,
         nf.job_id,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf),
         pe.empresa_id
    INTO v_num_doc,
         v_tipo_doc,
         v_serie,
         v_status_nf,
         v_job_id,
         v_emp_apelido,
         v_emp_cnpj,
         v_empresa_id
    FROM nota_fiscal nf,
         pessoa      pe,
         tipo_doc_nf td
   WHERE nf.nota_fiscal_id = v_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = td.tipo_doc_nf_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'NOTA_FISCAL_C',
                                NULL,
                                v_nota_fiscal_id,
                                v_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_nf NOT IN ('CHECKIN_PEND', 'CHECKIN_OK')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da nota fiscal não permite a alteração.';
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
  IF v_checkin_com_docum = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_nf
    WHERE nota_fiscal_id = v_nota_fiscal_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário anexar ao menos um Documento no Check-in.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' ||
                      TRIM(v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' || TRIM(v_serie));
  --
  v_compl_histor := 'Exclusão de arquivo da Nota Fiscal (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
 END arquivo_excluir;
 --
 --
 PROCEDURE bv_comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 18/01/2011
  -- DESCRICAO: Comanda o faturamento de BV uma determinada nota fiscal, cujo faturamento
  --   tenha sido excluido após o check-in (Operacao Especial).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc           IN nota_fiscal.num_doc%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_justificativa     IN VARCHAR2,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_nota_fiscal_id  nota_fiscal.nota_fiscal_id%TYPE;
  v_nota_fiscal_aux nota_fiscal.nota_fiscal_id%TYPE;
  v_valor_bruto     nota_fiscal.valor_bruto%TYPE;
  v_tipo_doc        tipo_doc_nf.codigo%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_job_id          job.job_id%TYPE;
  v_emp_apelido     pessoa.apelido%TYPE;
  v_emp_cnpj        pessoa.cnpj%TYPE;
  v_faturamento_id  faturamento.faturamento_id%TYPE;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O fornecedor deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse fornecedor não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de nota fiscal/documento deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo)
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_tipo_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nota_fiscal_id),
         MIN(nota_fiscal_id)
    INTO v_nota_fiscal_id,
         v_nota_fiscal_aux
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND num_doc = p_num_doc
     AND nvl(serie, 'ZZZ') = nvl(TRIM(p_serie), 'ZZZ');
  --
  IF v_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal/documento não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_nota_fiscal_id <> v_nota_fiscal_aux
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Há mais de uma nota fiscal com esse número/tipo/série para esse fornecedor.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         nf.valor_bruto,
         pe.apelido,
         nvl(pe.cnpj, pe.cpf)
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_valor_bruto,
         v_emp_apelido,
         v_emp_cnpj
    FROM job         jo,
         nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = v_nota_fiscal_id
     AND nf.job_id = jo.job_id(+)
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur  it,
         faturamento fa
   WHERE it.nota_fiscal_id = v_nota_fiscal_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'S';
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já está associada a uma ordem de faturamento de BV.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  faturamento_pkg.bv_gerar(p_usuario_sessao_id,
                           p_empresa_id,
                           v_nota_fiscal_id,
                           'N',
                           v_faturamento_id,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF: ' || p_num_doc || ' ' || p_serie;
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'ALTERAR_ESP3',
                   v_identif_objeto,
                   v_nota_fiscal_id,
                   v_compl_histor,
                   p_justificativa,
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
  p_historico_id := v_historico_id;
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
 END bv_comandar;
 --
 --
 --
 PROCEDURE nf_pagto_adicionar_manual
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 29/07/2025
  -- DESCRICAO: Adiciona registro na tab NOTA_FISCAL_PAGTO via baixa manual
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id       IN VARCHAR2,
  p_data_baixa           IN VARCHAR2,
  p_tipo_baixa           IN VARCHAR2,
  p_acao                 IN VARCHAR2,
  p_valor                IN VARCHAR2,
  p_valor_multa          IN VARCHAR2,
  p_valor_juros          IN VARCHAR2,
  p_nota_fiscal_pagto_id OUT nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_nota_fiscal_pagto_id nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE;
  v_data_baixa           nota_fiscal_pagto.data_baixa%TYPE;
  v_saldo_bruto          nota_fiscal_pagto.saldo_bruto%TYPE;
  v_saldo_liquido        nota_fiscal_pagto.saldo_liquido%TYPE;
  v_valor_desconto       nota_fiscal_pagto.valor_desconto%TYPE;
  v_valor_juros          nota_fiscal_pagto.valor_juros%TYPE;
  v_valor_liquido        nota_fiscal_pagto.valor_liquido%TYPE;
  v_valor_multa          nota_fiscal_pagto.valor_multa%TYPE;
  v_sequencia            nota_fiscal_pagto.sequencia%TYPE;
  v_nota_fiscal_id       nota_fiscal_pagto.nota_fiscal_id%TYPE;
  v_data_lancamento      nota_fiscal_pagto.data_lancamento%TYPE;
  v_valor                nota_fiscal_pagto.valor_desconto%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- Validação: Ação
  IF TRIM(p_acao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A ação é obrigatória.';
   RAISE v_exception;
  END IF;
  -- Validação: Data de baixa
  IF p_data_baixa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de baixa é obrigatória.';
   RAISE v_exception;
  END IF;
  -- Validação: Nota fiscal ID
  IF p_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ID da nota fiscal é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Tipo de baixa
  IF p_tipo_baixa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de baixa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_baixa_nf_pagto', p_tipo_baixa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de baixa inválida (' || p_tipo_baixa || ').';
   RAISE v_exception;
  END IF;
  -- Validação: Valor
  IF p_tipo_baixa IN ('D', 'B', 'X') AND p_valor IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_baixa = 'M' AND (p_valor_juros IS NULL AND p_valor_multa IS NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de juros ou multa são obrigatórios.';
   RAISE v_exception;
  END IF;
  /*IF p_valor_juros IS NULL 
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de juros é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Valor de multa
  IF p_valor_multa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de multa é obrigatório.';
   RAISE v_exception;
  END IF;*/
  --
  --
  -- Conversão de data
  v_data_baixa := data_hora_converter(p_data_baixa);
  --ALCBO_160725
  v_data_lancamento := SYSDATE;
  -- Conversão de valores monetários
  v_valor_juros := nvl(moeda_converter(p_valor_juros), 0);
  v_valor_multa := nvl(moeda_converter(p_valor_multa), 0);
  v_valor       := numero_converter(p_valor);
  --
  v_nota_fiscal_id := numero_converter(p_nota_fiscal_id);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT nota_fiscal_pagto_seq.nextval
    INTO v_nota_fiscal_pagto_id
    FROM dual;
  --  
  SELECT nvl(MAX(sequencia), 0) + 1
    INTO v_sequencia
    FROM nota_fiscal_pagto
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  ------------------------------------------------------------
  -- Verificação de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal_pagto
   WHERE nota_fiscal_id = v_nota_fiscal_id
     AND sequencia = v_sequencia
     AND nota_fiscal_pagto_id <> v_nota_fiscal_pagto_id;
  --
  IF v_qt <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe um registro com a mesma sequência (' || v_sequencia ||
                 ') para a nota fiscal ' || v_nota_fiscal_id || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT nf.saldo_liquido,
         nf.saldo_bruto
    INTO v_saldo_liquido,
         v_saldo_bruto
    FROM nota_fiscal nf
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  -- INCLUSÃO + BAIXA / BAIXA CANCELAMENTO
  IF p_acao = 'I' AND p_tipo_baixa IN ('B', 'X')
  THEN
   v_valor_liquido := v_valor;
   --
   v_saldo_liquido := v_saldo_liquido - v_valor_liquido;
   v_saldo_bruto   := v_saldo_bruto - v_valor_liquido;
  END IF;
  -- EXCLUSÃO + BAIXA / BAIXA CANCELAMENTO
  IF p_acao = 'E' AND p_tipo_baixa IN ('B', 'X')
  THEN
   v_valor_liquido := v_valor;
   --
   -- valor_liquido continua positivo, apenas retorna para o saldo
   v_saldo_liquido := v_saldo_liquido + v_valor_liquido;
   v_saldo_bruto   := v_saldo_bruto + v_valor_liquido;
  END IF;
  -- INCLUSÃO + MULTA / JUROS
  IF p_acao = 'I' AND p_tipo_baixa = 'M'
  THEN
   v_valor_multa := v_valor_multa;
   v_valor_juros := v_valor_juros;
  
   v_saldo_liquido := v_saldo_liquido + v_valor_multa + v_valor_juros;
   v_saldo_bruto   := v_saldo_bruto + v_valor_multa + v_valor_juros;
  END IF;
  -- EXCLUSÃO + MULTA / JUROS
  IF p_acao = 'E' AND p_tipo_baixa = 'M'
  THEN
   -- valores negativados para refletir estorno no extrato
   v_valor_multa := -abs(v_valor_multa);
   v_valor_juros := -abs(v_valor_juros);
  
   v_saldo_liquido := v_saldo_liquido + v_valor_multa + v_valor_juros;
   v_saldo_bruto   := v_saldo_bruto + v_valor_multa + v_valor_juros;
  END IF;
  -- INCLUSÃO + DESCONTO
  IF p_acao = 'I' AND p_tipo_baixa = 'D'
  THEN
   v_valor_desconto := v_valor;
  
   v_saldo_liquido := v_saldo_liquido - v_valor_desconto;
   v_saldo_bruto   := v_saldo_bruto - v_valor_desconto;
  END IF;
  -- EXCLUSÃO + DESCONTO
  IF p_acao = 'E' AND p_tipo_baixa = 'D'
  THEN
   -- valor negativado no extrato, pois está estornando
   v_valor_desconto := -abs(v_valor);
  
   v_saldo_liquido := v_saldo_liquido + v_valor_desconto;
   v_saldo_bruto   := v_saldo_bruto + v_valor_desconto;
  END IF;
  --
  INSERT INTO nota_fiscal_pagto
   (nota_fiscal_pagto_id,
    nota_fiscal_id,
    acao,
    data_baixa,
    sequencia,
    saldo_bruto,
    saldo_liquido,
    tipo_baixa,
    valor_desconto,
    valor_juros,
    valor_liquido,
    valor_multa,
    usuario_id,
    data_lancamento)
  VALUES
   (v_nota_fiscal_pagto_id,
    v_nota_fiscal_id,
    TRIM(p_acao),
    v_data_baixa,
    v_sequencia,
    nvl(v_saldo_bruto, 0),
    nvl(v_saldo_liquido, 0),
    TRIM(p_tipo_baixa),
    nvl(v_valor_desconto, 0),
    nvl(v_valor_juros, 0),
    nvl(v_valor_liquido, 0),
    nvl(v_valor_multa, 0),
    p_usuario_sessao_id,
    v_data_lancamento);
  --
  --ALCBO_270625
  nota_fiscal_pkg.nf_saldo_atualizar(v_nota_fiscal_id,
                                     v_saldo_liquido,
                                     v_saldo_bruto,
                                     'N',
                                     p_erro_cod,
                                     p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_nota_fiscal_pagto_id := v_nota_fiscal_pagto_id;
  p_erro_cod             := '00000';
  p_erro_msg             := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END nf_pagto_adicionar_manual;
 --
 PROCEDURE nf_saida_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 08/04/2010
  -- DESCRICAO: Inclusao de NOTA_FISCAL de saida associada a um faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/09/2018  Adaptacao p/ relacionamento c/ faturamento de contrato
  --                               (novo parametro p_tipo_fatur).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_fatur        IN VARCHAR2,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_emp_emissora_id   IN nota_fiscal.emp_emissora_id%TYPE,
  p_num_doc           IN VARCHAR2,
  p_tipo_doc_nf_id    IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_serie             IN nota_fiscal.serie%TYPE,
  p_data_emissao      IN VARCHAR2,
  p_data_pri_vencim   IN VARCHAR2,
  p_valor_bruto       IN VARCHAR2,
  p_valor_mao_obra    IN VARCHAR2,
  p_nota_fiscal_id    OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_job_id             job.job_id%TYPE;
  v_nota_fiscal_id     nota_fiscal.nota_fiscal_id%TYPE;
  v_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_valor_bruto        nota_fiscal.valor_bruto%TYPE;
  v_valor_mao_obra     nota_fiscal.valor_mao_obra%TYPE;
  v_data_pri_vencim    nota_fiscal.data_pri_vencim%TYPE;
  v_data_emissao       nota_fiscal.data_emissao%TYPE;
  v_desc_servico       nota_fiscal.desc_servico%TYPE;
  v_tipo_doc           tipo_doc_nf.codigo%TYPE;
  v_emp_apelido        pessoa.apelido%TYPE;
  v_emp_cnpj           pessoa.cnpj%TYPE;
  v_valor_fatura       NUMBER;
  v_nota_fiscal_sai_id faturamento.nota_fiscal_sai_id%TYPE;
  v_xml_atual          CLOB;
  --
 BEGIN
  v_qt             := 0;
  p_nota_fiscal_id := 0;
  v_job_id         := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_fatur) IS NULL OR p_tipo_fatur NOT IN ('JOB', 'CONTRATO')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento inválido (' || p_tipo_fatur || ').';
   RAISE v_exception;
  END IF;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'NOTA_FISCAL_SAI_I', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_fatur = 'JOB'
  THEN
   -- consistencias para faturamento de JOB
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento fa,
          job         jo
    WHERE fa.faturamento_id = p_faturamento_id
      AND fa.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT cliente_id,
          job_id,
          substr(descricao, 1, 2000),
          nota_fiscal_sai_id
     INTO v_cliente_id,
          v_job_id,
          v_desc_servico,
          v_nota_fiscal_sai_id
     FROM faturamento
    WHERE faturamento_id = p_faturamento_id;
   --
   IF v_nota_fiscal_sai_id IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento já está associada a uma nota fiscal de saída.';
    RAISE v_exception;
   END IF;
   --
   v_valor_fatura := faturamento_pkg.valor_fatura_retornar(p_faturamento_id);
  ELSE
   -- consistencias para faturamento de CONTRATO
   SELECT COUNT(*)
     INTO v_qt
     FROM faturamento_ctr fa,
          contrato        ct
    WHERE fa.faturamento_ctr_id = p_faturamento_id
      AND fa.contrato_id = ct.contrato_id
      AND ct.empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento de contrato não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT cliente_id,
          substr(descricao, 1, 2000),
          nota_fiscal_sai_id
     INTO v_cliente_id,
          v_desc_servico,
          v_nota_fiscal_sai_id
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = p_faturamento_id;
   --
   IF v_nota_fiscal_sai_id IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem de faturamento já está associada a uma nota fiscal de saída.';
    RAISE v_exception;
   END IF;
   --
   v_valor_fatura := faturamento_ctr_pkg.valor_fatura_retornar(p_faturamento_id);
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_doc_nf_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo)
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id
     AND flag_nf_saida = 'S';
  --
  IF v_tipo_doc IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_num_doc) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número da nota fiscal/documento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_num_doc) > 10
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de série da nota fiscal não pode ter mais que 10 caracteres .';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_valor_bruto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor bruto da nota fiscal é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_bruto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_mao_obra) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor de mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_bruto    := nvl(moeda_converter(p_valor_bruto), 0);
  v_valor_mao_obra := nvl(moeda_converter(p_valor_mao_obra), 0);
  --
  IF v_valor_bruto <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_bruto <> v_valor_fatura
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor bruto da nota fiscal não pode ser diferente do ' || 'valor da fatura (' ||
                 moeda_mostrar(v_valor_fatura, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_mao_obra < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da mão-de-obra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_mao_obra > v_valor_bruto
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da mão-de-obra não pode ser maior que o valor bruto da nota fiscal.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_emissora_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa emissora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa emissora não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(cnpj, cpf),
         apelido
    INTO v_emp_cnpj,
         v_emp_apelido
    FROM pessoa
   WHERE pessoa_id = p_emp_emissora_id;
  --
  IF rtrim(p_data_emissao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de emissão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_emissao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de emissão inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_emissao := data_converter(p_data_emissao);
  --
  IF v_data_emissao > trunc(SYSDATE)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de emissão não pode ser uma data futura.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_pri_vencim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data do primeiro vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_pri_vencim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do primeiro vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_pri_vencim := data_converter(p_data_pri_vencim);
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(p_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_nota_fiscal.nextval
    INTO v_nota_fiscal_id
    FROM dual;
  --
  INSERT INTO nota_fiscal
   (nota_fiscal_id,
    emp_emissora_id,
    cliente_id,
    job_id,
    tipo_ent_sai,
    tipo_doc_nf_id,
    num_doc,
    serie,
    data_pri_vencim,
    data_emissao,
    valor_bruto,
    valor_mao_obra,
    desc_servico,
    status)
  VALUES
   (v_nota_fiscal_id,
    p_emp_emissora_id,
    v_cliente_id,
    v_job_id,
    'S',
    p_tipo_doc_nf_id,
    TRIM(p_num_doc),
    TRIM(p_serie),
    v_data_pri_vencim,
    v_data_emissao,
    v_valor_bruto,
    v_valor_mao_obra,
    v_desc_servico,
    'CONC');
  --
  IF p_tipo_fatur = 'JOB'
  THEN
   UPDATE faturamento
      SET nota_fiscal_sai_id = v_nota_fiscal_id
    WHERE faturamento_id = p_faturamento_id;
  ELSE
   UPDATE faturamento_ctr
      SET nota_fiscal_sai_id = v_nota_fiscal_id
    WHERE faturamento_ctr_id = p_faturamento_id;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistema externo
  ------------------------------------------------------------
  it_controle_pkg.integrar('NOTA_FISCAL_SAI_ADICIONAR',
                           p_empresa_id,
                           v_nota_fiscal_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF Saída: ' || TRIM(p_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
  p_nota_fiscal_id := v_nota_fiscal_id;
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
 END nf_saida_adicionar;
 --
 --
 PROCEDURE nf_saida_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 08/04/2010
  -- DESCRICAO: Exclusao de NOTA_FISCAL de saida associada a um faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/09/2018  Limpa eventual relacionamento com faturamento de contrato.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_valor_bruto    nota_fiscal.valor_bruto%TYPE;
  v_num_doc        nota_fiscal.num_doc%TYPE;
  v_serie          nota_fiscal.serie%TYPE;
  v_emp_apelido    pessoa.apelido%TYPE;
  v_emp_cnpj       pessoa.cnpj%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'NOTA_FISCAL_SAI_E', NULL, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.tipo_ent_sai = 'S'
     AND nf.emp_emissora_id = pe.pessoa_id
     AND pe.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal de saída não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(pe.cnpj, pe.cpf),
         pe.apelido,
         nf.valor_bruto,
         nf.num_doc,
         nf.serie
    INTO v_emp_cnpj,
         v_emp_apelido,
         v_valor_bruto,
         v_num_doc,
         v_serie
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(p_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistema externo
  ------------------------------------------------------------
  it_controle_pkg.integrar('NOTA_FISCAL_SAI_EXCLUIR',
                           p_empresa_id,
                           p_nota_fiscal_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faturamento
     SET nota_fiscal_sai_id = NULL
   WHERE nota_fiscal_sai_id = p_nota_fiscal_id;
  --
  UPDATE faturamento_ctr
     SET nota_fiscal_sai_id = NULL
   WHERE nota_fiscal_sai_id = p_nota_fiscal_id;
  --
  DELETE FROM duplicata
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  DELETE FROM imposto_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  DELETE FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - NF Saída: ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(v_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_nota_fiscal_id,
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
 END nf_saida_excluir;
 --
 PROCEDURE dados_checkin_verificar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza          ProcessMind     DATA: 20/09/2024
  -- DESCRICAO: Verificacao de arquivo de entrada de checkin. 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_item_id          IN VARCHAR2,
  p_vetor_carta_acordo_id  IN VARCHAR2,
  p_vetor_tipo_produto_id  IN VARCHAR2,
  p_vetor_quantidade       IN VARCHAR2,
  p_vetor_frequencia       IN VARCHAR2,
  p_vetor_custo_unitario   IN VARCHAR2,
  p_vetor_complemento      IN VARCHAR2,
  p_vetor_valor_aprovado   IN VARCHAR2,
  p_vetor_valor_fornecedor IN VARCHAR2,
  p_vetor_valor_bv         IN VARCHAR2,
  p_vetor_valor_tip        IN VARCHAR2,
  p_vetor_valor_sobra      IN VARCHAR2,
  p_valor_credito_usado    IN VARCHAR2,
  p_emp_emissora_id        IN nota_fiscal.emp_emissora_id%TYPE,
  p_tipo_doc_nf_id         IN nota_fiscal.tipo_doc_nf_id%TYPE,
  p_num_doc                IN VARCHAR2,
  p_serie                  IN nota_fiscal.serie%TYPE,
  p_data_entrada           IN VARCHAR2,
  p_data_emissao           IN VARCHAR2,
  p_data_pri_vencim        IN VARCHAR2,
  p_valor_bruto            IN VARCHAR2,
  p_condicao_pagto_id      IN nota_fiscal.condicao_pagto_id%TYPE,
  p_vetor_parc_datas       IN VARCHAR2,
  p_vetor_parc_num_dias    IN VARCHAR2,
  p_tipo_num_dias          IN parcela_nf.tipo_num_dias%TYPE,
  p_vetor_parc_valores     IN VARCHAR2,
  p_nivel_excelencia       IN VARCHAR2,
  p_nivel_parceria         IN VARCHAR2,
  p_emp_receita_id         IN nota_fiscal.emp_receita_id%TYPE,
  p_flag_repasse           IN VARCHAR2,
  p_flag_patrocinio        IN nota_fiscal.flag_item_patrocinado%TYPE,
  p_tipo_receita           IN nota_fiscal.tipo_receita%TYPE,
  p_resp_pgto_receita      IN nota_fiscal.resp_pgto_receita%TYPE,
  p_desc_servico           IN VARCHAR2,
  p_municipio_servico      IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico             IN nota_fiscal.uf_servico%TYPE,
  p_emp_faturar_por_id     IN nota_fiscal.emp_faturar_por_id%TYPE,
  p_arquivo_id             IN arquivo.arquivo_id%TYPE,
  p_volume_id              IN arquivo.volume_id%TYPE,
  p_nome_original          IN arquivo.nome_original%TYPE,
  p_nome_fisico            IN arquivo.nome_fisico%TYPE,
  p_mime_type              IN arquivo.mime_type%TYPE,
  p_tamanho                IN arquivo.tamanho%TYPE,
  p_nota_fiscal_id         OUT nota_fiscal.nota_fiscal_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_nota_fiscal_id        nota_fiscal.nota_fiscal_id%TYPE;
  v_num_doc               nota_fiscal.num_doc%TYPE;
  v_valor_bruto           nota_fiscal.valor_bruto%TYPE;
  v_valor_bruto_acum      nota_fiscal.valor_bruto%TYPE;
  v_data_entrada          nota_fiscal.data_entrada%TYPE;
  v_data_emissao          nota_fiscal.data_emissao%TYPE;
  v_data_pri_vencim       nota_fiscal.data_pri_vencim%TYPE;
  v_cliente_id            nota_fiscal.cliente_id%TYPE;
  v_resp_pgto_receita     nota_fiscal.resp_pgto_receita%TYPE;
  v_valor_credito_usado   nota_fiscal.valor_credito_usado%TYPE;
  v_tipo_doc              tipo_doc_nf.codigo%TYPE;
  v_emp_apelido           pessoa.apelido%TYPE;
  v_emp_cnpj              pessoa.cnpj%TYPE;
  v_valor_faixa_retencao  pessoa.valor_faixa_retencao%TYPE;
  v_flag_incentivo_fat    pessoa.flag_emp_incentivo%TYPE;
  v_tipo_arquivo_id       tipo_arquivo.tipo_arquivo_id%TYPE;
  v_checkin_pagto_autom   VARCHAR2(10);
  v_checkin_financeiro    VARCHAR2(10);
  v_checkin_com_docum     VARCHAR2(10);
  v_lbl_job               VARCHAR2(100);
  v_xml_atual             CLOB;
  v_delimitador           CHAR(1);
  v_vetor_parc_datas      LONG;
  v_vetor_parc_valores    LONG;
  v_vetor_parc_num_dias   LONG;
  v_data_parcela_char     VARCHAR2(20);
  v_valor_parcela_char    VARCHAR2(20);
  v_num_dias_char         VARCHAR2(20);
  v_valor_aprovado_char   VARCHAR2(20);
  v_valor_fornecedor_char VARCHAR2(20);
  v_local_parcelam        VARCHAR2(40);
  v_data_parcela          parcela_nf.data_parcela%TYPE;
  v_valor_parcela         parcela_nf.valor_parcela%TYPE;
  v_num_dias              parcela_nf.num_dias%TYPE;
  v_num_dias_ant          parcela_nf.num_dias%TYPE;
  v_parcela_nf_id         parcela_nf.parcela_nf_id%TYPE;
  v_num_parcela           parcela_nf.num_parcela%TYPE;
  v_data_parcela_ant      parcela_nf.data_parcela%TYPE;
  v_valor_acumulado       NUMBER;
  v_tipo_data             VARCHAR2(10);
  v_tipo_data_ant         VARCHAR2(10);
  --
 BEGIN
  v_qt             := 0;
  p_nota_fiscal_id := 0;
  v_num_doc        := TRIM(p_num_doc);
  --
  v_lbl_job             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_checkin_pagto_autom := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_PAGTO_AUTOM');
  v_checkin_financeiro  := empresa_pkg.parametro_retornar(p_empresa_id, 'CHECKIN_FINANCEIRO');
  v_checkin_com_docum   := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_CHECKIN_COM_DOCUM');
  v_local_parcelam      := empresa_pkg.parametro_retornar(p_empresa_id, 'LOCAL_PARCELAM_FORNEC');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada (testa tb privilegio)
  ------------------------------------------------------------
  sub_checkin_consistir(p_usuario_sessao_id,
                        p_empresa_id,
                        NULL,
                        p_vetor_item_id,
                        p_vetor_carta_acordo_id,
                        p_vetor_tipo_produto_id,
                        p_vetor_quantidade,
                        p_vetor_frequencia,
                        p_vetor_custo_unitario,
                        p_vetor_complemento,
                        p_vetor_valor_aprovado,
                        p_vetor_valor_fornecedor,
                        p_vetor_valor_bv,
                        p_vetor_valor_tip,
                        p_vetor_valor_sobra,
                        p_valor_credito_usado,
                        p_emp_emissora_id,
                        p_tipo_doc_nf_id,
                        p_num_doc,
                        p_serie,
                        p_data_entrada,
                        p_data_emissao,
                        p_data_pri_vencim,
                        p_valor_bruto,
                        p_emp_receita_id,
                        p_flag_repasse,
                        p_flag_patrocinio,
                        p_tipo_receita,
                        p_resp_pgto_receita,
                        p_desc_servico,
                        p_municipio_servico,
                        p_uf_servico,
                        p_emp_faturar_por_id,
                        p_erro_cod,
                        p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF v_local_parcelam = 'CHECKIN'
  THEN
   IF nvl(p_condicao_pagto_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A indicação da condição de pagamento é obrigatória.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_condicao_pagto_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM condicao_pagto
    WHERE condicao_pagto_id = p_condicao_pagto_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição de pagamento não existe ou não pertence a essa empresa (' ||
                  to_char(p_condicao_pagto_id) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT apelido,
         nvl(cnpj, cpf),
         valor_faixa_retencao
    INTO v_emp_apelido,
         v_emp_cnpj,
         v_valor_faixa_retencao
    FROM pessoa pe
   WHERE pessoa_id = p_emp_emissora_id;
  --
  SELECT codigo
    INTO v_tipo_doc
    FROM tipo_doc_nf
   WHERE tipo_doc_nf_id = p_tipo_doc_nf_id;
  --
  IF v_num_doc IS NULL
  THEN
   -- documento virtual (negociacao), sem numero proprio
   SELECT 'NE' || TRIM(to_char(seq_num_doc.nextval, '00000000'))
     INTO v_num_doc
     FROM dual;
  END IF;
  --
  v_valor_bruto         := nvl(moeda_converter(p_valor_bruto), 0);
  v_valor_credito_usado := nvl(moeda_converter(p_valor_credito_usado), 0);
  v_data_entrada        := data_converter(p_data_entrada);
  v_data_emissao        := data_converter(p_data_emissao);
  v_data_pri_vencim     := data_converter(p_data_pri_vencim);
  --
  SELECT flag_emp_incentivo
    INTO v_flag_incentivo_fat
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  IF nvl(p_emp_receita_id, 0) > 0
  THEN
   v_cliente_id := p_emp_receita_id;
  END IF;
  --
  IF nvl(v_cliente_id, 0) = 0
  THEN
   v_cliente_id := p_emp_faturar_por_id;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NULL
  THEN
   v_resp_pgto_receita := NULL;
  ELSE
   v_resp_pgto_receita := p_resp_pgto_receita;
  END IF;
  --
  IF TRIM(p_nivel_excelencia) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_excelencia', p_nivel_excelencia) IS NULL OR
      inteiro_validar(p_nivel_excelencia) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de excelência inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_nivel_parceria) IS NOT NULL
  THEN
   IF util_pkg.desc_retornar('nivel_parceria', p_nivel_parceria) IS NULL OR
      inteiro_validar(p_nivel_parceria) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Nível de parceria inválido.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  /*------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(nota_fiscal_id)
    INTO v_nota_fiscal_id
    FROM nota_fiscal
   WHERE emp_emissora_id = p_emp_emissora_id
     AND num_doc = TRIM(v_num_doc)
     AND tipo_doc_nf_id = p_tipo_doc_nf_id
     AND nvl(serie, 'XXX') = nvl(TRIM(p_serie), 'XXX');
  --
  IF v_nota_fiscal_id IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal já existe.';
   RAISE v_exception;
  END IF;
  --
  --
  SELECT seq_nota_fiscal.nextval
    INTO v_nota_fiscal_id
    FROM dual;
  --
  INSERT INTO nota_fiscal
   (nota_fiscal_id,
    job_id,
    cliente_id,
    emp_emissora_id,
    tipo_ent_sai,
    tipo_doc_nf_id,
    num_doc,
    serie,
    data_entrada,
    data_emissao,
    data_pri_vencim,
    valor_bruto,
    valor_mao_obra,
    desc_servico,
    municipio_servico,
    uf_servico,
    status,
    emp_faturar_por_id,
    flag_item_patrocinado,
    tipo_receita,
    emp_receita_id,
    resp_pgto_receita,
    valor_faixa_retencao,
    valor_credito_usado,
    condicao_pagto_id)
  VALUES
   (v_nota_fiscal_id,
    NULL,
    v_cliente_id,
    p_emp_emissora_id,
    'E',
    p_tipo_doc_nf_id,
    TRIM(v_num_doc),
    TRIM(p_serie),
    v_data_entrada,
    v_data_emissao,
    v_data_pri_vencim,
    v_valor_bruto,
    0,
    TRIM(p_desc_servico),
    TRIM(p_municipio_servico),
    TRIM(p_uf_servico),
    'CHECKIN_PEND',
    p_emp_faturar_por_id,
    p_flag_patrocinio,
    TRIM(p_tipo_receita),
    zvl(p_emp_receita_id, NULL),
    v_resp_pgto_receita,
    v_valor_faixa_retencao,
    v_valor_credito_usado,
    zvl(p_condicao_pagto_id, NULL));
  --
  ------------------------------------------------------------
  -- trata parcelamento
  ------------------------------------------------------------
  IF v_local_parcelam = 'CHECKIN' THEN
   v_delimitador := '|';
   --
   v_num_parcela      := 0;
   v_valor_acumulado  := 0;
   v_data_parcela_ant := data_converter('01/01/1970');
   v_tipo_data_ant    := NULL;
   v_num_dias_ant     := 0;
   --
   v_vetor_parc_datas    := p_vetor_parc_datas;
   v_vetor_parc_num_dias := p_vetor_parc_num_dias;
   v_vetor_parc_valores  := p_vetor_parc_valores;
   --
   WHILE nvl(length(rtrim(v_vetor_parc_datas)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_num_dias)), 0) > 0 OR
         nvl(length(rtrim(v_vetor_parc_valores)), 0) > 0
   LOOP
    --
    v_data_parcela_char  := prox_valor_retornar(v_vetor_parc_datas, v_delimitador);
    v_num_dias_char      := prox_valor_retornar(v_vetor_parc_num_dias, v_delimitador);
    v_valor_parcela_char := prox_valor_retornar(v_vetor_parc_valores, v_delimitador);
    --
    IF data_validar(v_data_parcela_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data da parcela inválida (' || v_data_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(v_num_dias_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de dias da parcela inválido (' || v_num_dias_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF moeda_validar(v_valor_parcela_char) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Valor da parcela inválido (' || v_valor_parcela_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_parcela  := data_converter(v_data_parcela_char);
    v_num_dias      := nvl(to_number(v_num_dias_char), 0);
    v_valor_parcela := nvl(moeda_converter(v_valor_parcela_char), 0);
    --
    IF v_data_parcela IS NULL AND v_num_dias = 0 AND v_valor_parcela = 0 THEN
     -- despreza a parcela
     NULL;
    ELSE
     IF v_valor_parcela <= 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Valor da parcela inválido (' || moeda_mostrar(v_valor_parcela, 'S') || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias < 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Número de dias da parcela inválido (' || to_char(v_num_dias) || ').';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_num_dias = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Alguma informação de data deve ser fornecida para ' || 'a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL AND v_num_dias > 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A data da parcela e o número de dias não devem ser informados ' ||
                    'ao mesmo tempo para a parcela de valor ' ||
                    moeda_mostrar(v_valor_parcela, 'S') || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_num_dias > 0 THEN
      v_tipo_data := 'DIA';
     ELSE
      v_tipo_data := 'DATA';
     END IF;
     --
     IF v_tipo_data_ant IS NOT NULL THEN
      -- verifica se mudou o tipo de data
      IF v_tipo_data <> v_tipo_data_ant THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Todas as datas do parcelamento devem ser do mesmo tipo.';
       RAISE v_exception;
      END IF;
     ELSE
      -- primeira vez no loop
      v_tipo_data_ant := v_tipo_data;
     END IF;
     --
     IF v_tipo_data = 'DATA' THEN
      IF v_data_parcela <= v_data_parcela_ant THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     IF v_tipo_data = 'DIA' THEN
      IF v_num_dias <= v_num_dias_ant THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Os dias das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_dias_ant := v_num_dias;
     END IF;
     --
     v_num_parcela     := v_num_parcela + 1;
     v_valor_acumulado := v_valor_acumulado + v_valor_parcela;
     --
     SELECT seq_parcela_nf.nextval
       INTO v_parcela_nf_id
       FROM dual;
     --
     INSERT INTO parcela_nf
      (parcela_nf_id,
       nota_fiscal_id,
       num_parcela,
       num_tot_parcelas,
       data_parcela,
       num_dias,
       tipo_num_dias,
       valor_parcela)
     VALUES
      (v_parcela_nf_id,
       v_nota_fiscal_id,
       v_num_parcela,
       0,
       v_data_parcela,
       v_num_dias,
       p_tipo_num_dias,
       v_valor_parcela);
    END IF;
   END LOOP;
   --
   IF v_valor_acumulado <> v_valor_bruto THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A soma dos valores das parcelas (' || moeda_mostrar(v_valor_acumulado, 'S') ||
                  ') deve ser igual ao valor total da nota fiscal (' ||
                  moeda_mostrar(v_valor_bruto, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela_nf
      SET num_tot_parcelas = v_num_parcela
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- associacao dos itens a nota fiscal
  ------------------------------------------------------------
  sub_itens_adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      v_nota_fiscal_id,
                      p_vetor_item_id,
                      p_vetor_carta_acordo_id,
                      p_vetor_tipo_produto_id,
                      p_vetor_quantidade,
                      p_vetor_frequencia,
                      p_vetor_custo_unitario,
                      p_vetor_complemento,
                      p_vetor_valor_aprovado,
                      p_vetor_valor_fornecedor,
                      p_vetor_valor_bv,
                      p_vetor_valor_tip,
                      p_vetor_valor_sobra,
                      p_erro_cod,
                      p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais na NF para campos desnormalizados
  ------------------------------------------------------------
  UPDATE nota_fiscal
     SET tipo_fatur_bv     = nota_fiscal_pkg.tipo_fatur_bv_retornar(nota_fiscal_id),
         flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0)
    INTO v_valor_bruto_acum
    FROM item_nota
   WHERE nota_fiscal_id = v_nota_fiscal_id;
  --
  IF v_valor_bruto_acum <> v_valor_bruto + v_valor_credito_usado THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor acumulado dos itens dessa nota  (aqui) (' ||
                 moeda_mostrar(v_valor_bruto_acum, 'S') ||
                 ') não corresponde ao valor bruto da nota fiscal mais os créditos usados (' ||
                 moeda_mostrar(v_valor_bruto + v_valor_credito_usado, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do arquivo
  ------------------------------------------------------------
  \*
  IF v_checkin_com_docum = 'S' AND NVL(p_arquivo_id,0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'É necessário anexar ao menos um Documento no Check-in.';
     RAISE v_exception;
  END IF;*\
  --
  IF nvl(p_arquivo_id, 0) > 0 THEN
   IF rtrim(p_nome_original) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do nome do arquivo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_nome_fisico) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do nome físico do arquivo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(tipo_arquivo_id)
     INTO v_tipo_arquivo_id
     FROM tipo_arquivo
    WHERE empresa_id = p_empresa_id
      AND codigo = 'NOTA_FISCAL';
   --
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_arquivo_id,
                         p_volume_id,
                         v_nota_fiscal_id,
                         v_tipo_arquivo_id,
                         p_nome_original,
                         p_nome_fisico,
                         NULL,
                         p_mime_type,
                         p_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- calcula impostos, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_financeiro = 'S' THEN
   sub_impostos_calcular(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         v_nota_fiscal_id,
                         '0', -- mao de obra
                         moeda_mostrar(v_valor_bruto, 'N'), -- base ISS
                         moeda_mostrar(v_valor_bruto, 'N'), -- base IR
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- nao precisa deixar a NF com pendencia financeira
   UPDATE nota_fiscal
      SET status = 'CHECKIN_OK'
    WHERE nota_fiscal_id = v_nota_fiscal_id;
  END IF;
  --
  ------------------------------------------------------------
  -- grava avaliacoes, se for o caso.
  ------------------------------------------------------------
  IF nvl(to_number(p_nivel_excelencia), 0) > 0 THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'EXC',
     SYSDATE,
     to_number(p_nivel_excelencia));
  END IF;
  --
  IF nvl(to_number(p_nivel_parceria), 0) > 0 THEN
   INSERT INTO aval_fornec
    (aval_fornec_id,
     pessoa_id,
     usuario_aval_id,
     tipo_aval,
     data_entrada,
     nota)
   VALUES
    (seq_aval_fornec.nextval,
     p_emp_emissora_id,
     p_usuario_sessao_id,
     'PAR',
     SYSDATE,
     to_number(p_nivel_parceria));
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF nvl(p_emp_receita_id, 0) > 0 THEN
   -- integracao com sistemas externos
   it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                            p_empresa_id,
                            p_emp_receita_id,
                            NULL,
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- integracao com sistemas externos
  it_controle_pkg.integrar('PESSOA_ATUALIZAR',
                           p_empresa_id,
                           p_emp_emissora_id,
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  nota_fiscal_pkg.xml_gerar(v_nota_fiscal_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := 'CNPJ/CPF: ' || v_emp_cnpj || ' - ' || v_tipo_doc || ': ' || TRIM(v_num_doc) || ' ' ||
                      TRIM(p_serie);
  --
  v_compl_histor := 'Empresa: ' || v_emp_apelido || ' - Valor NF: ' ||
                    moeda_mostrar(v_valor_bruto, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NOTA_FISCAL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_nota_fiscal_id,
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
  ------------------------------------------------------------
  -- comanda o pagamento, se for o caso.
  ------------------------------------------------------------
  IF v_checkin_pagto_autom = 'S' AND v_checkin_financeiro = 'N' THEN
   -- a subrotina muda o status da NF para FATUR_LIB
   nota_fiscal_pkg.sub_pagto_comandar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      v_nota_fiscal_id,
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;*/
  --
  --COMMIT;
  p_nota_fiscal_id := v_nota_fiscal_id;
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
 END dados_checkin_verificar;
 --
 PROCEDURE nf_pagto_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza             ProcessMind     DATA: 13/06/2025
  -- DESCRICAO: Adiciona registro na tab NOTA_FISCAL_PAGTO após alguma alteração na nota_fiscal
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         27/06/2025  Adiocionado chamada de nf_saldo_atualizar
  -- Ana Luiza         30/06/2025  Adicionado tratamento para não repetir sequencia para mesmo nf
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_acao                 IN VARCHAR2,
  p_data_baixa           IN VARCHAR2,
  p_sequencia            IN VARCHAR2,
  p_nota_fiscal_id       IN VARCHAR2,
  p_saldo_bruto          IN VARCHAR2,
  p_saldo_liquido        IN VARCHAR2,
  p_tipo_baixa           IN VARCHAR2,
  p_valor_desconto       IN VARCHAR2,
  p_valor_juros          IN VARCHAR2,
  p_valor_liquido        IN VARCHAR2,
  p_valor_multa          IN VARCHAR2,
  p_data_lancamento      IN VARCHAR2,
  p_nota_fiscal_pagto_id OUT nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_nota_fiscal_pagto_id nota_fiscal_pagto.nota_fiscal_pagto_id%TYPE;
  v_data_baixa           nota_fiscal_pagto.data_baixa%TYPE;
  v_saldo_bruto          nota_fiscal_pagto.saldo_bruto%TYPE;
  v_saldo_liquido        nota_fiscal_pagto.saldo_liquido%TYPE;
  v_valor_desconto       nota_fiscal_pagto.valor_desconto%TYPE;
  v_valor_juros          nota_fiscal_pagto.valor_juros%TYPE;
  v_valor_liquido        nota_fiscal_pagto.valor_liquido%TYPE;
  v_valor_multa          nota_fiscal_pagto.valor_multa%TYPE;
  v_sequencia            nota_fiscal_pagto.sequencia%TYPE;
  v_nota_fiscal_id       nota_fiscal_pagto.nota_fiscal_id%TYPE;
  v_data_lancamento      nota_fiscal_pagto.data_lancamento%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- Validação: Ação
  IF TRIM(p_acao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A ação é obrigatória.';
   RAISE v_exception;
  END IF;
  -- Validação: Data de baixa
  IF p_data_baixa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de baixa é obrigatória.';
   RAISE v_exception;
  END IF;
  -- Validação: ID do movimento
  IF p_sequencia IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ID do movimento é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Nota fiscal ID
  IF p_nota_fiscal_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ID da nota fiscal é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Saldo bruto
  IF p_saldo_bruto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O saldo bruto é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Saldo líquido
  IF p_saldo_liquido IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O saldo líquido é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Tipo de baixa
  IF p_tipo_baixa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de baixa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_baixa', p_tipo_baixa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de baixa inválida (' || p_tipo_baixa || ').';
   RAISE v_exception;
  END IF;
  -- Validação: Valor de desconto
  IF p_valor_desconto IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de desconto é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Valor de juros
  IF p_valor_juros IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de juros é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Valor líquido
  IF p_valor_liquido IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor líquido é obrigatório.';
   RAISE v_exception;
  END IF;
  -- Validação: Valor de multa
  IF p_valor_multa IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor de multa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  --
  -- Conversão de data
  v_data_baixa := data_converter(p_data_baixa);
  --ALCBO_160725
  v_data_lancamento := data_converter(p_data_lancamento);
  -- Conversão de valores monetários
  v_saldo_bruto    := nvl(moeda_converter(p_saldo_bruto), 0);
  v_saldo_liquido  := nvl(moeda_converter(p_saldo_liquido), 0);
  v_valor_desconto := nvl(moeda_converter(p_valor_desconto), 0);
  v_valor_juros    := nvl(moeda_converter(p_valor_juros), 0);
  v_valor_liquido  := nvl(moeda_converter(p_valor_liquido), 0);
  v_valor_multa    := nvl(moeda_converter(p_valor_multa), 0);
  --
  v_sequencia      := numero_converter(p_sequencia);
  v_nota_fiscal_id := numero_converter(p_nota_fiscal_id);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT nota_fiscal_pagto_seq.nextval
    INTO v_nota_fiscal_pagto_id
    FROM dual;
  ------------------------------------------------------------
  -- Verificação de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal_pagto
   WHERE nota_fiscal_id = v_nota_fiscal_id
     AND sequencia = v_sequencia
     AND nota_fiscal_pagto_id <> v_nota_fiscal_pagto_id;
  --
  IF v_qt <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe um registro com a mesma sequência (' || v_sequencia ||
                 ') para a nota fiscal ' || v_nota_fiscal_id || '.';
   RAISE v_exception;
  END IF;
  --
  --
  INSERT INTO nota_fiscal_pagto
   (nota_fiscal_pagto_id,
    nota_fiscal_id,
    acao,
    data_baixa,
    sequencia,
    saldo_bruto,
    saldo_liquido,
    tipo_baixa,
    valor_desconto,
    valor_juros,
    valor_liquido,
    valor_multa,
    usuario_id,
    data_lancamento)
  VALUES
   (v_nota_fiscal_pagto_id,
    v_nota_fiscal_id,
    TRIM(p_acao),
    v_data_baixa,
    v_sequencia,
    v_saldo_bruto,
    v_saldo_liquido,
    TRIM(p_tipo_baixa),
    v_valor_desconto,
    v_valor_juros,
    v_valor_liquido,
    v_valor_multa,
    p_usuario_sessao_id,
    v_data_lancamento);
  --
  --ALCBO_270625
  nota_fiscal_pkg.nf_saldo_atualizar(v_nota_fiscal_id,
                                     v_saldo_liquido,
                                     v_saldo_bruto,
                                     'N',
                                     p_erro_cod,
                                     p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_nota_fiscal_pagto_id := v_nota_fiscal_pagto_id;
  p_erro_cod             := '00000';
  p_erro_msg             := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END nf_pagto_adicionar;
 --
 --
 PROCEDURE nf_saldo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza            ProcessMind     DATA: 13/06/2025
  -- DESCRICAO: Atualização apenas do saldo liquido e bruto da nota fiscal após consulta no 
  --            ADNNET.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         27/06/2025  Adicionado flag_commit
  ------------------------------------------------------------------------------------------
 (
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
  p_saldo_liquido  IN VARCHAR2,
  p_saldo_bruto    IN VARCHAR2,
  p_flag_commit    IN VARCHAR2,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_valor_saldo_liquido nota_fiscal.saldo_liquido%TYPE;
  v_valor_saldo_bruto   nota_fiscal.saldo_bruto%TYPE;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não existe (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_saldo_liquido := nvl(moeda_converter(p_saldo_liquido), 0);
  v_valor_saldo_bruto   := nvl(moeda_converter(p_saldo_bruto), 0);
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE nota_fiscal
     SET saldo_liquido = v_valor_saldo_liquido,
         saldo_bruto   = v_valor_saldo_bruto
   WHERE nota_fiscal_id = p_nota_fiscal_id;
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
 END nf_saldo_atualizar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 07/02/2017
  -- DESCRICAO: Subrotina que gera o xml da nota fiscal para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
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
  CURSOR c_ip IS
   SELECT ti.cod_imposto,
          ip.cod_retencao,
          numero_mostrar(ip.perc_imposto_nota, 2, 'N') perc_imposto,
          numero_mostrar(ip.valor_imposto, 2, 'N') valor_imposto
     FROM imposto_nota    ip,
          fi_tipo_imposto ti
    WHERE ip.nota_fiscal_id = p_nota_fiscal_id
      AND ip.fi_tipo_imposto_id = ti.fi_tipo_imposto_id
    ORDER BY ip.num_seq;
  --
  CURSOR c_dp IS
   SELECT num_parcela,
          num_duplicata,
          data_mostrar(data_vencim) data_vencim,
          numero_mostrar(valor_duplicata, 2, 'N') valor_duplicata
     FROM duplicata
    WHERE nota_fiscal_id = p_nota_fiscal_id
    ORDER BY num_parcela;
  --
  CURSOR c_it IS
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || '/' || it.tipo_item ||
          to_char(it.num_seq) AS num_item,
          numero_mostrar(io.valor_aprovado, 2, 'N') valor_item,
          numero_mostrar(io.valor_bv, 2, 'N') valor_bv,
          numero_mostrar(io.valor_tip, 2, 'N') valor_tip,
          carta_acordo_pkg.numero_completo_formatar(io.carta_acordo_id, 'N') num_carta_acordo
     FROM item_nota io,
          item      it
    WHERE io.nota_fiscal_id = p_nota_fiscal_id
      AND io.item_id = it.item_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("nota_fiscal_id", nf.nota_fiscal_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("tipo", decode(nf.tipo_ent_sai, 'E', 'Entrada', 'Saída')),
                   xmlelement("status", nf.status),
                   xmlelement("empresa_emissora", pe.apelido),
                   xmlelement("cnpj_cpf_emissor", nvl(pe.cnpj, pe.cpf)),
                   xmlelement("tipo_docum", ti.codigo || '-' || ti.nome),
                   xmlelement("num_docum", nf.num_doc),
                   xmlelement("serie_docum", nf.serie),
                   xmlelement("data_entrada", data_mostrar(nf.data_entrada)),
                   xmlelement("data_emissao", data_mostrar(nf.data_emissao)),
                   xmlelement("data_primeiro_vencim", data_mostrar(nf.data_pri_vencim)),
                   xmlelement("valor_bruto", numero_mostrar(nf.valor_bruto, 2, 'N')),
                   xmlelement("valor_mao_obra", numero_mostrar(nf.valor_mao_obra, 2, 'N')),
                   xmlelement("valor_credito_usado", numero_mostrar(nf.valor_credito_usado, 2, 'N')),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("empresa_fatur", pf.apelido),
                   xmlelement("municipio_servico", nf.municipio_servico),
                   xmlelement("uf_servico", nf.uf_servico),
                   xmlelement("modo_pagto", util_pkg.desc_retornar('modo_pgto', nf.modo_pagto)),
                   xmlelement("num_doc_pagto", nf.num_doc_pagto),
                   xmlelement("cod_verificacao", nf.cod_verificacao),
                   xmlelement("chave_acesso", nf.chave_acesso),
                   xmlelement("cod_ext_nf", nf.cod_ext_nf),
                   xmlelement("empresa_receita", pr.apelido),
                   xmlelement("tipo_receita",
                              util_pkg.desc_retornar('tipo_receita', nf.tipo_receita)),
                   xmlelement("resp_pagto_receita",
                              util_pkg.desc_retornar('resp_pgto_receita', nf.resp_pgto_receita)),
                   xmlelement("patrocinio", nf.flag_item_patrocinado),
                   xmlelement("pago_cliente", nf.flag_pago_cliente),
                   xmlelement("tipo_fatur_bv", nf.tipo_fatur_bv),
                   xmlelement("conta_especifica", nf.tipo_pag_pessoa),
                   xmlelement("banco_cobrador", ba.nome))
    INTO v_xml
    FROM nota_fiscal nf,
         pessoa      cl,
         pessoa      pe,
         pessoa      pf,
         tipo_doc_nf ti,
         pessoa      pr,
         fi_banco    ba
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_emissora_id = pe.pessoa_id
     AND nf.tipo_doc_nf_id = ti.tipo_doc_nf_id
     AND nf.cliente_id = cl.pessoa_id(+)
     AND nf.emp_faturar_por_id = pf.pessoa_id(+)
     AND nf.emp_receita_id = pr.pessoa_id(+)
     AND nf.fi_banco_cobrador_id = ba.fi_banco_id(+);
  --
  ------------------------------------------------------------
  -- monta DUPLICATAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_dp IN c_dp
  LOOP
   SELECT xmlagg(xmlelement("duplicata",
                            xmlelement("num_duplicata", r_dp.num_duplicata),
                            xmlelement("data_vencim", r_dp.data_vencim),
                            xmlelement("valor_duplicata", r_dp.valor_duplicata)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("duplicatas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta IMPOSTOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ip IN c_ip
  LOOP
   SELECT xmlagg(xmlelement("imposto",
                            xmlelement("cod_imposto", r_ip.cod_imposto),
                            xmlelement("cod_retencao", r_ip.cod_retencao),
                            xmlelement("perc_imposto", r_ip.perc_imposto),
                            xmlelement("valor_imposto", r_ip.valor_imposto)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("impostos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta ITENS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_it IN c_it
  LOOP
   SELECT xmlagg(xmlelement("item",
                            xmlelement("num_item", r_it.num_item),
                            xmlelement("valor_item", r_it.valor_item),
                            xmlelement("valor_bv", r_it.valor_bv),
                            xmlelement("valor_tip", r_it.valor_tip),
                            xmlelement("carta_acordo", r_it.num_carta_acordo)))
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
  ------------------------------------------------------------
  -- junta tudo debaixo de "nota_fiscal"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("nota_fiscal", v_xml))
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
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor de uma determinada nota fiscal, de acordo com o tipo
  --  especificado no parametro de entrada.
  --  Os tipos: 'APROVADO','FORNECEDOR','BV','IMPOSTO','TIP','BV_TOT' só fazem sentido para
  --  notas fiscais de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE,
  p_tipo_valor     IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt               INTEGER;
  v_retorno          NUMBER;
  v_exception        EXCEPTION;
  v_valor_aprovado   item_nota.valor_aprovado%TYPE;
  v_valor_fornecedor item_nota.valor_fornecedor%TYPE;
  v_valor_bv         item_nota.valor_bv%TYPE;
  v_valor_tip        item_nota.valor_tip%TYPE;
  v_valor_impostos   NUMBER;
  v_valor_bruto      nota_fiscal.valor_bruto%TYPE;
  v_valor_liquido    nota_fiscal.valor_bruto%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN
     ('APROVADO', 'FORNECEDOR', 'BV', 'IMPOSTO', 'TIP', 'BV_TOT', 'BRUTO', 'IMPOSTOS', 'LIQUIDO') OR
     TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  --
  SELECT nvl(valor_bruto, 0)
    INTO v_valor_bruto
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_aprovado), 0),
         nvl(SUM(valor_fornecedor), 0),
         nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0)
    INTO v_valor_aprovado,
         v_valor_fornecedor,
         v_valor_bv,
         v_valor_tip
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  SELECT nvl(SUM(valor_imposto), 0)
    INTO v_valor_impostos
    FROM imposto_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id
     AND flag_reter = 'S';
  --
  IF p_tipo_valor = 'APROVADO'
  THEN
   -- valor da nota de entrada com check-in ja realizado
   -- (pode nao ser igual ao valor bruto no caso de checkin parcial)
   v_retorno := v_valor_aprovado;
  ELSIF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornecedor;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := v_valor_bv;
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := v_valor_tip;
  ELSIF p_tipo_valor = 'BV_TOT'
  THEN
   v_retorno := v_valor_bv + v_valor_tip;
  ELSIF p_tipo_valor = 'IMPOSTO'
  THEN
   -- imposto do fornecedor (usado apenas no calculo do tip)
   v_retorno := v_valor_aprovado - v_valor_fornecedor - v_valor_tip;
  ELSIF p_tipo_valor = 'BRUTO'
  THEN
   v_retorno := v_valor_bruto;
  ELSIF p_tipo_valor = 'IMPOSTOS'
  THEN
   -- impostos retidos da nota
   v_retorno := v_valor_impostos;
  ELSIF p_tipo_valor = 'LIQUIDO'
  THEN
   v_retorno := v_valor_bruto - v_valor_impostos;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION valor_checkin_pend_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor pendente de checkin de uma determinada nota fiscal.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN NUMBER AS
  v_retorno       NUMBER;
  v_valor_checkin NUMBER;
  v_valor_nf      NUMBER;
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(valor_bruto, 0)
    INTO v_valor_nf
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  SELECT nvl(SUM(io.valor_aprovado), 0)
    INTO v_valor_checkin
    FROM item_nota   io,
         nota_fiscal no
   WHERE no.nota_fiscal_id = p_nota_fiscal_id
     AND no.nota_fiscal_id = io.nota_fiscal_id;
  --
  v_retorno := v_valor_nf - v_valor_checkin;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_checkin_pend_retornar;
 --
 --
 FUNCTION data_pri_vencim_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a data do primeiro vencimento da nota fiscal/duplicata.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN DATE AS
  v_qt        INTEGER;
  v_retorno   DATE;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MIN(data_vencim)
    INTO v_retorno
    FROM duplicata
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_pri_vencim_retornar;
 --
 --
 FUNCTION flag_pago_cliente_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/09/2007
  -- DESCRICAO: retorna o flag que indica pagamento direto pelo cliente correspondente a
  --  uma determinada nota fiscal de entrada, com base no que foi definido nos itens.
  --  Caso existam flags distintos (o que nao deveria ocorrer), retorna 'N'.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno VARCHAR2(20);
  --
 BEGIN
  --
  SELECT nvl(to_char(MIN(ie.flag_pago_cliente)), 'N')
    INTO v_retorno
    FROM item_nota it,
         item      ie
   WHERE it.nota_fiscal_id = p_nota_fiscal_id
     AND it.item_id = ie.item_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END flag_pago_cliente_retornar;
 --
 --
 FUNCTION flag_com_fatur_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 16/11/2009
  -- DESCRICAO: retorna flag que indica se a NF gerou faturamento (certos tipos de receita
  --  ou itens pagos diretos pelo cliente nao geram faturamento).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2011  Novo atributo flag_pago_cliente na NF.
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt                INTEGER;
  v_retorno           VARCHAR2(20);
  v_flag_pago_cliente CHAR(1);
  v_saida             EXCEPTION;
  --
 BEGIN
  v_retorno := 'S';
  --
  -- verifica se a nota é de itens pagos diretamente pelo cliente
  SELECT flag_pago_cliente
    INTO v_flag_pago_cliente
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_flag_pago_cliente = 'S'
  THEN
   v_retorno := 'N';
   RAISE v_saida;
  END IF;
  --
  -- verifica se a nota é do tipo com receita paga diretamente pela fonte
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.tipo_receita IS NOT NULL
     AND nf.resp_pgto_receita = 'FON';
  --
  IF v_qt > 0
  THEN
   v_retorno := 'N';
   RAISE v_saida;
  END IF;
  --
  -- verifica se a nota é do tipo com receita de contrato
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.tipo_receita = 'CONTRATO'
     AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
  --
  IF v_qt > 0
  THEN
   v_retorno := 'N';
   RAISE v_saida;
  END IF;
  --
  -- verifica se a nota é faturada pela 100% Incentivo
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf,
         pessoa      pe
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id
     AND nf.emp_faturar_por_id = pe.pessoa_id
     AND pe.flag_emp_incentivo = 'S'
     AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
  --
  IF v_qt > 0
  THEN
   v_retorno := 'N';
   RAISE v_saida;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END flag_com_fatur_retornar;
 --
 --
 FUNCTION tipo_item_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2007
  -- DESCRICAO: retorna a modalidade de contratação associado a uma determinada nota fiscal (A, B, C ou
  --   BC).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno VARCHAR2(20);
  --
  CURSOR c_it IS
   SELECT it.tipo_item
     FROM item_nota no,
          item      it
    WHERE no.nota_fiscal_id = p_nota_fiscal_id
      AND no.item_id = it.item_id
    ORDER BY it.tipo_item;
  --
 BEGIN
  v_retorno := NULL;
  --
  FOR r_it IN c_it
  LOOP
   IF v_retorno IS NULL
   THEN
    v_retorno := r_it.tipo_item;
   ELSE
    IF instr(v_retorno, r_it.tipo_item, 1) = 0
    THEN
     v_retorno := v_retorno || r_it.tipo_item;
    END IF;
   END IF;
  END LOOP;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END tipo_item_retornar;
 --
 --
 FUNCTION tipo_fatur_bv_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: retorna o tipo de faturamento do BV (FAT ou ABA) correspondente a uma
  --  determinada nota fiscal de entrada, com base no que foi definido nos itens/cartas.
  --  Caso o NF nao tenha itens com BV definido, retorna NA.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta acordo multi-item.
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno VARCHAR2(20);
  --
 BEGIN
  -- verifica se a NF é do tipo associada a carta acordo
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id
     AND carta_acordo_id IS NOT NULL;
  --
  IF v_qt = 0
  THEN
   SELECT nvl(MAX(it.tipo_fatur_bv), 'NA')
     INTO v_retorno
     FROM item_nota io,
          item      it
    WHERE io.nota_fiscal_id = p_nota_fiscal_id
      AND io.item_id = it.item_id
      AND it.tipo_fatur_bv <> 'NA';
  ELSE
   SELECT nvl(MAX(ca.tipo_fatur_bv), 'NA')
     INTO v_retorno
     FROM item_nota    io,
          carta_acordo ca
    WHERE io.nota_fiscal_id = p_nota_fiscal_id
      AND io.carta_acordo_id = ca.carta_acordo_id
      AND ca.tipo_fatur_bv <> 'NA';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END tipo_fatur_bv_retornar;
 --
 --
 FUNCTION data_fatur_bv_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a data de faturamento do BV/TIP associado a uma determinada NF.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2011  Novo atributo tipo_fatur_bv na NF.
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN DATE AS
  v_qt              INTEGER;
  v_retorno         DATE;
  v_exception       EXCEPTION;
  v_tipo_fatur_bv   VARCHAR2(10);
  v_data_pri_vencim nota_fiscal.data_pri_vencim%TYPE;
  v_faturamento_id  faturamento.faturamento_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT nf.tipo_fatur_bv,
         nf.data_pri_vencim
    INTO v_tipo_fatur_bv,
         v_data_pri_vencim
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_tipo_fatur_bv IN ('ABA', 'CRE', 'PER')
  THEN
   v_retorno := v_data_pri_vencim;
   --
  ELSIF v_tipo_fatur_bv = 'FAT'
  THEN
   -- verifica se existe faturamento de BV associado a essa nota
   SELECT MAX(fa.faturamento_id)
     INTO v_faturamento_id
     FROM faturamento fa,
          item_fatur  it
    WHERE it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S';
   --
   IF v_faturamento_id IS NOT NULL
   THEN
    SELECT nvl(nf.data_pri_vencim, fa.data_vencim)
      INTO v_data_pri_vencim
      FROM faturamento fa,
           nota_fiscal nf
     WHERE fa.faturamento_id = v_faturamento_id
       AND fa.nota_fiscal_sai_id = nf.nota_fiscal_id(+);
    --
    v_retorno := v_data_pri_vencim;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_fatur_bv_retornar;
 --
 --
 FUNCTION bv_faturado_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: verifica se o BV/TIP associado a uma determinada NF ja foi faturado ou nao.
  --   Retorna 1 caso sim e 0 caso nao. BV a abater é sempre considerado faturado. BV a
  --   faturar é considerado faturado quando houver NF de saida já associada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2011  Novo atributo tipo_fatur_bv na NF.
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN INTEGER AS
  v_qt                 INTEGER;
  v_retorno            INTEGER;
  v_tipo_fatur_bv      VARCHAR2(10);
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_nota_fiscal_sai_id faturamento.nota_fiscal_sai_id%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT tipo_fatur_bv
    INTO v_tipo_fatur_bv
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_tipo_fatur_bv IN ('ABA', 'CRE', 'PER')
  THEN
   v_retorno := 1;
   --
  ELSIF v_tipo_fatur_bv = 'FAT'
  THEN
   -- verifica se existe faturamento de BV associado a essa nota
   SELECT MAX(fa.faturamento_id)
     INTO v_faturamento_id
     FROM faturamento fa,
          item_fatur  it
    WHERE it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S';
   --
   IF v_faturamento_id IS NOT NULL
   THEN
    SELECT nota_fiscal_sai_id
      INTO v_nota_fiscal_sai_id
      FROM faturamento fa
     WHERE faturamento_id = v_faturamento_id;
    --
    IF v_nota_fiscal_sai_id IS NOT NULL
    THEN
     v_retorno := 1;
    END IF;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END bv_faturado_verificar;
 --
 --
 FUNCTION bv_comandado_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/01/2011
  -- DESCRICAO: verifica se o BV/TIP associado a uma determinada NF foi comandado (tem ordem
  --   de faturamento gerada). Isso eh feito automaticamente no check-in, mas pode ocorrer
  --   da ordem de faturamento ter sido excluida.
  --   Retorna 1 caso sim e 0 caso nao. BV a abater é sempre considerado como comandado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN INTEGER AS
  v_qt             INTEGER;
  v_retorno        INTEGER;
  v_tipo_fatur_bv  VARCHAR2(10);
  v_faturamento_id faturamento.faturamento_id%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT tipo_fatur_bv
    INTO v_tipo_fatur_bv
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_tipo_fatur_bv IN ('ABA', 'CRE', 'PER')
  THEN
   v_retorno := 1;
   --
  ELSIF v_tipo_fatur_bv = 'FAT'
  THEN
   -- verifica se existe faturamento de BV associado a essa nota
   SELECT MAX(fa.faturamento_id)
     INTO v_faturamento_id
     FROM faturamento fa,
          item_fatur  it
    WHERE it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S';
   --
   IF v_faturamento_id IS NOT NULL
   THEN
    v_retorno := 1;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END bv_comandado_verificar;
 --
 --
 FUNCTION bv_nf_saida_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/01/2010
  -- DESCRICAO: retorna o ID da nota fiscal de saida associada ao BV/TIP de uma
  --  determinada NF de fornecedor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/01/2011  Novo atributo tipo_fatur_bv na NF.
  ------------------------------------------------------------------------------------------
  p_nota_fiscal_id IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN NUMBER AS
  v_qt                 INTEGER;
  v_retorno            NUMBER;
  v_tipo_fatur_bv      VARCHAR2(10);
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_nota_fiscal_sai_id faturamento.nota_fiscal_sai_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT tipo_fatur_bv
    INTO v_tipo_fatur_bv
    FROM nota_fiscal
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_tipo_fatur_bv = 'FAT'
  THEN
   -- verifica se existe faturamento de BV associado a essa nota
   SELECT MAX(fa.faturamento_id)
     INTO v_faturamento_id
     FROM faturamento fa,
          item_fatur  it
    WHERE it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S';
   --
   IF v_faturamento_id IS NOT NULL
   THEN
    SELECT nota_fiscal_sai_id
      INTO v_nota_fiscal_sai_id
      FROM faturamento fa
     WHERE faturamento_id = v_faturamento_id;
    --
    IF v_nota_fiscal_sai_id IS NOT NULL
    THEN
     v_retorno := v_nota_fiscal_sai_id;
    END IF;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END bv_nf_saida_retornar;
 --
 --
 FUNCTION chave_acesso_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 28/06/2012
  -- DESCRICAO: verifica se a chave de acesso eh valida. Retorna 1 se valida, 0 se invalida.
  --    numeros validos:
  --    24110509540525000194550010000007091242050760
  --    24110509540525000194550010000007071681710981
  --    29061233009911011920550100000084661242094583
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  p_chave_acesso IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                INTEGER;
  v_retorno           NUMBER;
  v_exception         EXCEPTION;
  v_chave_acesso_alfa VARCHAR2(100);
  v_chave_acesso_num  NUMBER;
  v_digito            INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF length(TRIM(p_chave_acesso)) <> 44
  THEN
   RAISE v_exception;
  END IF;
  --
  v_chave_acesso_alfa := TRIM(p_chave_acesso);
  --
  -- tenta converter p/ numerico (apenas para consistir)
  v_chave_acesso_num := to_number(v_chave_acesso_alfa);
  --
  v_digito := to_number(substr(v_chave_acesso_alfa, 44, 1));
  --
  IF v_digito = dig_mod11_retornar(substr(v_chave_acesso_alfa, 1, 43))
  THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_exception THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   RETURN v_retorno;
 END chave_acesso_verificar;
 --
--
END; -- NOTA_FISCAL_PKG

/
