--------------------------------------------------------
--  DDL for Package Body ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ITEM_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Inclusão de ITEM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/02/2008  Tipo de faturamento do BV (novo valor 'NA')
  -- Silvia            25/07/2008  Chamada da funcao que calcula valores de saldos.
  -- Silvia            12/05/2014  Novo paramento p_flag_com_encargo.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            14/07/2014  Novo parametro perc_imposto (antes vinha do cadastro 
  --                               do fornecedor).
  -- Silvia            14/10/2014  Novo paramento p_flag_com_encargo_honor.
  -- Silvia            22/06/2016  Consistencia de orcamento de despesa
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  -- Ana Luiza         08/11/2024  Comentado item = A, para B ser pago p/cliente
  -- Ana Luiza         02/01/2024  Adicao de novo parametro cod_externo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_orcamento_id           IN item.orcamento_id%TYPE,
  p_tipo_produto_id        IN item.tipo_produto_id%TYPE,
  p_fornecedor_id          IN item.fornecedor_id%TYPE,
  p_grupo                  IN VARCHAR2,
  p_subgrupo               IN VARCHAR2,
  p_complemento            IN item.complemento%TYPE,
  p_tipo_item              IN item.tipo_item%TYPE,
  p_flag_sem_valor         IN item.flag_sem_valor%TYPE,
  p_flag_com_honor         IN item.flag_com_honor%TYPE,
  p_flag_com_encargo       IN item.flag_com_encargo%TYPE,
  p_flag_com_encargo_honor IN item.flag_com_encargo_honor%TYPE,
  p_flag_pago_cliente      IN item.flag_pago_cliente%TYPE,
  p_quantidade             IN VARCHAR2,
  p_frequencia             IN VARCHAR2,
  p_unidade_freq           IN item.unidade_freq%TYPE,
  p_custo_unitario         IN VARCHAR2,
  p_valor_fornecedor       IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_tipo_fatur_bv          IN item.tipo_fatur_bv%TYPE,
  p_obs                    IN VARCHAR2,
  p_cod_ext                IN VARCHAR2,
  p_item_id                OUT item.item_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_item_id           item.item_id%TYPE;
  v_job_id            item.job_id%TYPE;
  v_quantidade        item.quantidade%TYPE;
  v_frequencia        item.frequencia%TYPE;
  v_custo_unitario    item.custo_unitario%TYPE;
  v_valor_aprovado    item.valor_aprovado%TYPE;
  v_valor_fornecedor  item.valor_fornecedor%TYPE;
  v_perc_bv           item.perc_bv%TYPE;
  v_perc_imposto      item.perc_imposto%TYPE;
  v_fornecedor_id     item.fornecedor_id%TYPE;
  v_ordem_grupo       item.ordem_grupo%TYPE;
  v_ordem_subgrupo    item.ordem_subgrupo%TYPE;
  v_ordem_item        item.ordem_item%TYPE;
  v_ordem_grupo_sq    item.ordem_grupo%TYPE;
  v_ordem_subgrupo_sq item.ordem_subgrupo%TYPE;
  v_ordem_item_sq     item.ordem_item%TYPE;
  v_flag_pago_cliente item.flag_pago_cliente%TYPE;
  v_tipo_fatur_bv     item.tipo_fatur_bv%TYPE;
  v_nome_produto      tipo_produto.nome%TYPE;
  v_num_orcamento     orcamento.num_orcamento%TYPE;
  v_flag_despesa      orcamento.flag_despesa%TYPE;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_lbl_job           VARCHAR2(100);
  v_num_item          VARCHAR2(50);
  v_num_orcam         VARCHAR2(50);
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt      := 0;
  p_item_id := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.flag_despesa
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_flag_despesa
    FROM job       j,
         orcamento o
   WHERE o.orcamento_id = p_orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                p_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(p_orcamento_id) > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Estimativa de Custos não pode ser alterada ' ||
                 'pois já foi liberada para faturamento.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   v_fornecedor_id := NULL;
  ELSE
   v_fornecedor_id := p_fornecedor_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = v_fornecedor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse fornecedor não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(nome)
    INTO v_nome_produto
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  IF TRIM(p_subgrupo) IS NOT NULL AND TRIM(p_grupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O subgrupo só pode ser preenchido quando o grupo for especificado.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_grupo)) > 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O grupo não pode ter mais que 60 caracteres (' || p_grupo || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_subgrupo)) > 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O subgrupo não pode ter mais que 60 caracteres (' || p_subgrupo || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo do item é obrigatório (' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do item não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_item', p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Modalidade de Contratação inválida (' || p_tipo_item || ' - ' || v_nome_produto || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_despesa = 'S' AND p_tipo_item = 'A'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Estimativa de Custos de despesas não deve ter itens de A.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_valor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem valor inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_honor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com honorários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_encargo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com encargos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_encargo_honor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com encargos sobre honorários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_com_honor = 'N' AND p_flag_com_encargo_honor = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Combinação inválida de flags honorários/encargos sobre honorários.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pago_cliente) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pago pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_produto_id, -1) = -1
  THEN
   -- foi usado -1 pois existe produto_id = 0 cadastrado (do sistema, ND)
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do entregável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse entregável não existe ou não pertence a essa empresa (' ||
                 to_char(p_tipo_produto_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_sem_valor = 'N'
  THEN
   IF rtrim(p_quantidade) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da quantidade é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_frequencia) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_custo_unitario) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo unitário é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_valor_fornecedor) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo do fornecedor é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_flag_pago_cliente := p_flag_pago_cliente;
  --ALCBO_081124
  /*
  IF v_flag_pago_cliente = 'S' AND p_tipo_item <> 'A' THEN
   -- despreza o flag para itens de B e C
   v_flag_pago_cliente := 'N';
  END IF;
  */
  --
  IF numero_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade inválida (' || p_quantidade || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_frequencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Frequência inválida (' || p_frequencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_unitario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo unitário inválido (' || p_custo_unitario || ').';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_fornecedor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo do fornecedor inválido (' || p_valor_fornecedor || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto do fornecedor inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF length(TRIM(p_obs)) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo do item não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_quantidade       := nvl(numero_converter(p_quantidade), 0);
  v_frequencia       := nvl(numero_converter(p_frequencia), 0);
  v_custo_unitario   := nvl(numero_converter(p_custo_unitario), 0);
  v_valor_aprovado   := round(v_quantidade * v_frequencia * v_custo_unitario, 2);
  v_valor_fornecedor := nvl(moeda_converter(p_valor_fornecedor), 0);
  v_perc_bv          := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto     := nvl(taxa_converter(p_perc_imposto), 0);
  --
  IF v_valor_aprovado < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor aprovado pelo cliente não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor > v_valor_aprovado
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser maior que o valor aprovado ' ||
                 'pelo cliente - ' || TRIM(v_nome_produto || p_complemento) ||
                 ' (custo fornecedor: ' || moeda_mostrar(v_valor_fornecedor, 'S') ||
                 ' ; valor aprovado: ' || moeda_mostrar(v_valor_aprovado, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_sem_valor = 'S'
  THEN
   -- consistencia de itens sem valor
   IF v_custo_unitario <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens sem valor, o custo unitário deve ser igual a zero.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens sem valor, o valor do fornecedor deve ser igual a zero.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para itens sem valor, o percentual de BV deve ser igual a zero.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_tipo_fatur_bv = 'NA' AND
     ((v_valor_aprovado > v_valor_fornecedor) OR (v_perc_bv <> 0 AND v_valor_fornecedor <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv IN ('FAT', 'ABA') AND
     ((v_valor_aprovado = v_valor_fornecedor) AND (v_perc_bv = 0 OR v_valor_fornecedor = 0))
  THEN
   v_tipo_fatur_bv := 'NA';
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento das ordens
  ------------------------------------------------------------
  -- ordens COM quebra por tipo
  item_pkg.ordem_retornar(p_usuario_sessao_id,
                          v_job_id,
                          p_orcamento_id,
                          0,
                          p_tipo_item,
                          p_grupo,
                          p_subgrupo,
                          'S',
                          v_ordem_grupo,
                          v_ordem_subgrupo,
                          v_ordem_item,
                          p_erro_cod,
                          p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- ordens SEM quebra por tipo
  item_pkg.ordem_retornar(p_usuario_sessao_id,
                          v_job_id,
                          p_orcamento_id,
                          0,
                          p_tipo_item,
                          p_grupo,
                          p_subgrupo,
                          'N',
                          v_ordem_grupo_sq,
                          v_ordem_subgrupo_sq,
                          v_ordem_item_sq,
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
  SELECT seq_item.nextval
    INTO v_item_id
    FROM dual;
  --
  INSERT INTO item
   (item_id,
    job_id,
    orcamento_id,
    tipo_produto_id,
    fornecedor_id,
    grupo,
    subgrupo,
    complemento,
    natureza_item,
    tipo_item,
    quantidade,
    frequencia,
    unidade_freq,
    custo_unitario,
    valor_aprovado,
    valor_fornecedor,
    perc_bv,
    tipo_fatur_bv,
    perc_imposto,
    ordem_grupo,
    ordem_subgrupo,
    ordem_item,
    ordem_grupo_sq,
    ordem_subgrupo_sq,
    ordem_item_sq,
    flag_parcelado,
    flag_sem_valor,
    flag_com_honor,
    flag_com_encargo,
    flag_com_encargo_honor,
    flag_pago_cliente,
    status_fatur,
    obs,
    cod_externo)
  VALUES
   (v_item_id,
    v_job_id,
    p_orcamento_id,
    p_tipo_produto_id,
    v_fornecedor_id,
    TRIM(p_grupo),
    TRIM(p_subgrupo),
    TRIM(p_complemento),
    'CUSTO',
    p_tipo_item,
    v_quantidade,
    v_frequencia,
    p_unidade_freq,
    v_custo_unitario,
    v_valor_aprovado,
    v_valor_fornecedor,
    v_perc_bv,
    v_tipo_fatur_bv,
    v_perc_imposto,
    v_ordem_grupo,
    v_ordem_subgrupo,
    v_ordem_item,
    v_ordem_grupo_sq,
    v_ordem_subgrupo_sq,
    v_ordem_item_sq,
    'N',
    p_flag_sem_valor,
    p_flag_com_honor,
    p_flag_com_encargo,
    p_flag_com_encargo_honor,
    v_flag_pago_cliente,
    'NLIB',
    TRIM(p_obs),
    TRIM(p_cod_ext));
  --
  item_pkg.historico_gerar(p_usuario_sessao_id, v_item_id, 'CRIACAO', NULL, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- recalcula o numero sequencial dos itens do orcamento
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, p_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  item_pkg.xml_gerar(v_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_num_item  := item_pkg.num_item_retornar(v_item_id, 'S');
  v_num_orcam := orcamento_pkg.numero_formatar(p_orcamento_id);
  --
  v_identif_objeto := v_num_orcam;
  v_compl_histor   := 'Inclusão de item (' || v_num_item || ' - ' ||
                      rtrim(v_nome_produto || ' ' || p_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_orcamento_id,
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
  p_item_id  := v_item_id;
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Atualização de ITEM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/02/2008  Tipo de faturamento do BV (novo valor 'NA')
  -- Silvia            01/04/2008  Consistencia em alteracao de flag_pago_cliente.
  -- Silvia            25/07/2008  Chamada da funcao que calcula valores de saldos.
  -- Silvia            21/11/2011  Alteraco do historico do item de forma a gravar um
  --                               complemento no caso de alteracoes especiais.
  -- Silvia            12/05/2014  Novo paramento p_flag_com_encargo.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            14/07/2014  Novo parametro perc_imposto (antes vinha do cadastro 
  --                               do fornecedor).
  -- Silvia            14/10/2014  Novo paramento p_flag_com_encargo_honor.
  -- Silvia            22/06/2016  Consistencia de orcamento de despesa
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  -- Joel Dias         24/05/2024  Bloqueios para impedir alteração do item quando
  --                               possuir faturamento, abatimento, nota fiscal de entrada,
  --                               carta acordo ou adiantamento para despesas
  -- Ana Luiza         08/11/2024  Comentado item = A, para B ser pago p/cliente
  -- Ana Luiza         27/05/2025  Tratamento para IMPEDIR_ALTERACAO_ITENS_UTILIZADOS = N
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_item_id                IN item.item_id%TYPE,
  p_tipo_produto_id        IN item.tipo_produto_id%TYPE,
  p_fornecedor_id          IN item.fornecedor_id%TYPE,
  p_grupo                  IN item.grupo%TYPE,
  p_subgrupo               IN item.subgrupo%TYPE,
  p_complemento            IN item.complemento%TYPE,
  p_tipo_item              IN item.tipo_item%TYPE,
  p_flag_sem_valor         IN item.flag_sem_valor%TYPE,
  p_flag_com_honor         IN item.flag_com_honor%TYPE,
  p_flag_com_encargo       IN item.flag_com_encargo%TYPE,
  p_flag_com_encargo_honor IN item.flag_com_encargo_honor%TYPE,
  p_flag_pago_cliente      IN item.flag_pago_cliente%TYPE,
  p_quantidade             IN VARCHAR2,
  p_frequencia             IN VARCHAR2,
  p_unidade_freq           IN item.unidade_freq%TYPE,
  p_custo_unitario         IN VARCHAR2,
  p_valor_fornecedor       IN VARCHAR2,
  p_perc_bv                IN VARCHAR2,
  p_perc_imposto           IN VARCHAR2,
  p_tipo_fatur_bv          IN item.tipo_fatur_bv%TYPE,
  p_obs                    IN VARCHAR2,
  p_cod_ext                IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                             INTEGER;
  v_identif_objeto                 historico.identif_objeto%TYPE;
  v_compl_histor                   historico.complemento%TYPE;
  v_historico_id                   historico.historico_id%TYPE;
  v_exception                      EXCEPTION;
  v_compl_aux                      VARCHAR2(500);
  v_job_id                         item.job_id%TYPE;
  v_quantidade                     item.quantidade%TYPE;
  v_frequencia                     item.frequencia%TYPE;
  v_custo_unitario                 item.custo_unitario%TYPE;
  v_valor_aprovado                 item.valor_aprovado%TYPE;
  v_valor_fornecedor               item.valor_fornecedor%TYPE;
  v_valor_aprovado_old             item.valor_aprovado%TYPE;
  v_valor_fornecedor_old           item.valor_fornecedor%TYPE;
  v_flag_pago_cliente_old          item.flag_pago_cliente%TYPE;
  v_tipo_fatur_bv_old              item.tipo_fatur_bv%TYPE;
  v_tipo_item_old                  item.tipo_item%TYPE;
  v_perc_bv                        item.perc_bv%TYPE;
  v_perc_imposto                   item.perc_imposto%TYPE;
  v_flag_parcelado                 item.flag_parcelado%TYPE;
  v_fornecedor_id                  item.fornecedor_id%TYPE;
  v_ordem_grupo                    item.ordem_grupo%TYPE;
  v_ordem_subgrupo                 item.ordem_subgrupo%TYPE;
  v_ordem_item                     item.ordem_item%TYPE;
  v_grupo                          item.grupo%TYPE;
  v_subgrupo                       item.subgrupo%TYPE;
  v_flag_pago_cliente              item.flag_pago_cliente%TYPE;
  v_tipo_fatur_bv                  item.tipo_fatur_bv%TYPE;
  v_nome_produto                   tipo_produto.nome%TYPE;
  v_num_orcamento                  orcamento.num_orcamento%TYPE;
  v_orcamento_id                   orcamento.orcamento_id%TYPE;
  v_flag_despesa                   orcamento.flag_despesa%TYPE;
  v_numero_job                     job.numero%TYPE;
  v_status_job                     job.status%TYPE;
  v_update_completo                CHAR(1);
  v_lbl_job                        VARCHAR2(100);
  v_num_item                       VARCHAR2(50);
  v_num_orcam                      VARCHAR2(50);
  v_xml_antes                      CLOB;
  v_xml_atual                      CLOB;
  v_impedir_alterar_item_utilizado CHAR(1);
  v_valor_comprometido             item.valor_disponivel%TYPE;
  v_valor_faturado                 item.valor_faturado%TYPE;
  --
 BEGIN
  v_qt              := 0;
  v_update_completo := 'S';
  v_lbl_job         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
 
  v_impedir_alterar_item_utilizado := empresa_pkg.parametro_retornar(p_empresa_id,
                                                                     'IMPEDIR_ALTERACAO_ITENS_UTILIZADOS');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.orcamento_id,
         o.flag_despesa,
         i.flag_parcelado,
         i.ordem_grupo,
         i.ordem_subgrupo,
         i.ordem_item,
         i.grupo,
         i.subgrupo,
         nvl(i.valor_aprovado, 0),
         nvl(i.valor_fornecedor, 0),
         i.flag_pago_cliente,
         i.tipo_fatur_bv,
         i.tipo_item
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id,
         v_flag_despesa,
         v_flag_parcelado,
         v_ordem_grupo,
         v_ordem_subgrupo,
         v_ordem_item,
         v_grupo,
         v_subgrupo,
         v_valor_aprovado_old,
         v_valor_fornecedor_old,
         v_flag_pago_cliente_old,
         v_tipo_fatur_bv_old,
         v_tipo_item_old
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(v_orcamento_id) > 0
  THEN
   -- orcamento ja aprovado. Verifica privilegio especial.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ITEM_APROV_A', NULL, NULL, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para alterar Estimativas de Custos já aprovadas.';
    RAISE v_exception;
   END IF;
   --
   -- com orcamento ja aprovado, o update é parcial.
   v_update_completo := 'N';
  END IF;
  --
  IF nvl(p_fornecedor_id, 0) = 0
  THEN
   v_fornecedor_id := NULL;
  ELSE
   v_fornecedor_id := p_fornecedor_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = v_fornecedor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse fornecedor não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_impedir_alterar_item_utilizado = 'S'
  THEN
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_fatur
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele já foi faturado.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_abat
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele possui abatimentos.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_nota i
    INNER JOIN nota_fiscal n
       ON n.nota_fiscal_id = i.nota_fiscal_id
    WHERE n.tipo_ent_sai = 'E'
      AND i.item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele está associado ao menos a uma nota de entrada.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_carta
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele está associado ao menos a uma Carta Acordo.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_adiant
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele já foi utilizado ao menos em um adiantamento para despesas.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_sobra
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível alterar este item pois ele possui sobras indicadas.';
    RAISE v_exception;
   END IF;
   --
  END IF;
  --
  IF TRIM(p_subgrupo) IS NOT NULL AND TRIM(p_grupo) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O subgrupo só pode ser preenchido quando o grupo for especificado .';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo do item é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_item', p_tipo_item) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Modalidade de Contratação inválida (' || p_tipo_item || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_despesa = 'S' AND p_tipo_item = 'A'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Estimativa de Custos de despesas não deve ter itens de A.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_sem_valor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag sem valor inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_honor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com honorários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_encargo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com encargos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_com_encargo_honor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com encargos sobre honorários inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_com_honor = 'N' AND p_flag_com_encargo_honor = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Combinação inválida de flags honorários/encargos sobre honorários.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pago_cliente) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pago pelo cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_produto_id, -1) = -1
  THEN
   -- foi usado -1 pois existe produto_id = 0 cadastrado (do sistema, ND)
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do entregável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do item não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_sem_valor = 'N'
  THEN
   IF rtrim(p_quantidade) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da quantidade é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_frequencia) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_custo_unitario) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo unitário é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF rtrim(p_valor_fornecedor) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do custo do fornecedor é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_flag_pago_cliente := p_flag_pago_cliente;
  --ALCBO_081124
  /*IF v_flag_pago_cliente = 'S' AND p_tipo_item <> 'A' THEN
   -- despreza o flag para itens de B e C
   v_flag_pago_cliente := 'N';
  END IF;*/
  --
  IF numero_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade inválida (' || p_quantidade || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_frequencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Frequência inválida (' || p_frequencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_custo_unitario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo unitário inválido (' || p_custo_unitario || ').';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_fornecedor) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo do fornecedor inválido (' || p_valor_fornecedor || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido (' || p_perc_bv || ').';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_perc_imposto) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de imposto do fornecedor inválido (' || p_perc_imposto || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_fatur_bv) IS NOT NULL AND
     util_pkg.desc_retornar('tipo_fatur_bv', p_tipo_fatur_bv) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de faturamento do BV inválido (' || p_tipo_fatur_bv || ').';
   RAISE v_exception;
  END IF;
  --
  v_tipo_fatur_bv := nvl(p_tipo_fatur_bv, 'NA');
  --
  IF length(TRIM(p_obs)) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 2000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O código externo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse entregável não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_produto
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  v_quantidade       := nvl(numero_converter(p_quantidade), 0);
  v_frequencia       := nvl(numero_converter(p_frequencia), 0);
  v_custo_unitario   := nvl(numero_converter(p_custo_unitario), 0);
  v_valor_aprovado   := round(v_quantidade * v_frequencia * v_custo_unitario, 2);
  v_valor_fornecedor := nvl(moeda_converter(p_valor_fornecedor), 0);
  v_perc_bv          := nvl(numero_converter(p_perc_bv), 0);
  v_perc_imposto     := nvl(taxa_converter(p_perc_imposto), 0);
  --
  --ALCBO_270525
  IF v_impedir_alterar_item_utilizado = 'N'
  THEN
   v_valor_comprometido := item_pkg.valor_reservado_retornar(p_item_id, 'APROVADO');
   v_valor_faturado     := item_pkg.valor_realizado_retornar(p_item_id, 'FATURADO');
   --
   IF v_valor_aprovado < v_valor_comprometido
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível revisar o valor deste item para um valor menor do que R$ ' ||
                  moeda_mostrar(v_valor_comprometido, 'S') ||
                  ', pois este valor já foi comprometido no Orçamento';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_aprovado < v_valor_faturado
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível revisar o valor deste item para um valor menor do que R$ ' ||
                  moeda_mostrar(v_valor_faturado, 'S') || ' , pois este valor já foi faturado';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_valor_aprovado < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor aprovado pelo cliente não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_fornecedor > v_valor_aprovado
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser maior que o valor aprovado pelo cliente.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_parcelado = 'S'
  THEN
   IF v_valor_aprovado <> v_valor_aprovado_old OR v_valor_fornecedor <> v_valor_fornecedor_old
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Os valores desse item não podem ser alterados pois ele já foi parcelado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_flag_sem_valor = 'S'
  THEN
   -- consistencia de itens sem valor
   IF v_custo_unitario <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para essa modalidade de contratação, o custo unitário deve ser igual a zero.';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_fornecedor <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para essa modalidade de contratação, o valor do fornecedor deve ser igual a zero.';
    RAISE v_exception;
   END IF;
   --
   IF v_perc_bv <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para essa modalidade de contratação, o percentual de BV deve ser igual a zero.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_pago_cliente = 'S' AND v_tipo_fatur_bv = 'ABA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Itens pagos diretamente pelo cliente não podem ter o valor do BV abatido.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV ou TIP definido
  IF v_tipo_fatur_bv = 'NA' AND
     ((v_valor_aprovado > v_valor_fornecedor) OR (v_perc_bv <> 0 AND v_valor_fornecedor <> 0))
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Falta especificar o tipo de faturamento do BV/TIP.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_fatur_bv IN ('FAT', 'ABA') AND
     ((v_valor_aprovado = v_valor_fornecedor) AND (v_perc_bv = 0 OR v_valor_fornecedor = 0))
  THEN
   v_tipo_fatur_bv := 'NA';
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  item_pkg.xml_gerar(p_item_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento das ordens
  ------------------------------------------------------------
  IF nvl(TRIM(p_grupo), 'XXXXX') <> nvl(v_grupo, 'XXXXX') OR
     nvl(TRIM(p_subgrupo), 'XXXXX') <> nvl(v_subgrupo, 'XXXXX') OR p_tipo_item <> v_tipo_item_old
  THEN
   --
   -- ajusta a ordenacao COM quebra por tipo
   item_pkg.ordem_retornar(p_usuario_sessao_id,
                           v_job_id,
                           v_orcamento_id,
                           p_item_id,
                           p_tipo_item,
                           p_grupo,
                           p_subgrupo,
                           'S',
                           v_ordem_grupo,
                           v_ordem_subgrupo,
                           v_ordem_item,
                           p_erro_cod,
                           p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE item
      SET ordem_grupo    = v_ordem_grupo,
          ordem_subgrupo = v_ordem_subgrupo,
          ordem_item     = v_ordem_item
    WHERE item_id = p_item_id;
   --
   -- ajusta a ordenacao SEM quebra por tipo
   item_pkg.ordem_retornar(p_usuario_sessao_id,
                           v_job_id,
                           v_orcamento_id,
                           p_item_id,
                           p_tipo_item,
                           p_grupo,
                           p_subgrupo,
                           'N',
                           v_ordem_grupo,
                           v_ordem_subgrupo,
                           v_ordem_item,
                           p_erro_cod,
                           p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE item
      SET ordem_grupo_sq    = v_ordem_grupo,
          ordem_subgrupo_sq = v_ordem_subgrupo,
          ordem_item_sq     = v_ordem_item
    WHERE item_id = p_item_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_update_completo = 'S'
  THEN
   UPDATE item
      SET tipo_produto_id        = p_tipo_produto_id,
          fornecedor_id          = v_fornecedor_id,
          grupo                  = TRIM(p_grupo),
          subgrupo               = TRIM(p_subgrupo),
          complemento            = TRIM(p_complemento),
          tipo_item              = p_tipo_item,
          flag_sem_valor         = p_flag_sem_valor,
          flag_com_honor         = p_flag_com_honor,
          flag_com_encargo       = p_flag_com_encargo,
          flag_com_encargo_honor = p_flag_com_encargo_honor,
          flag_pago_cliente      = v_flag_pago_cliente,
          quantidade             = v_quantidade,
          frequencia             = v_frequencia,
          unidade_freq           = p_unidade_freq,
          custo_unitario         = v_custo_unitario,
          valor_aprovado         = v_valor_aprovado,
          valor_fornecedor       = v_valor_fornecedor,
          perc_bv                = v_perc_bv,
          tipo_fatur_bv          = v_tipo_fatur_bv,
          perc_imposto           = v_perc_imposto,
          obs                    = TRIM(p_obs),
          cod_externo            = TRIM(p_cod_ext)
    WHERE item_id = p_item_id;
   --
   IF p_tipo_item <> v_tipo_item_old
   THEN
    -- item mudou de tipo (nao pode manter a sequencia)
    UPDATE item
       SET flag_mantem_seq = 'N'
     WHERE item_id = p_item_id;
   END IF;
   --
   -- recalcula o numero sequencial dos itens do orcamento
   orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   UPDATE item
      SET flag_pago_cliente = v_flag_pago_cliente,
          quantidade        = v_quantidade,
          frequencia        = v_frequencia,
          unidade_freq      = p_unidade_freq,
          fornecedor_id     = v_fornecedor_id,
          custo_unitario    = v_custo_unitario,
          valor_aprovado    = v_valor_aprovado,
          valor_fornecedor  = v_valor_fornecedor,
          perc_bv           = v_perc_bv,
          tipo_fatur_bv     = v_tipo_fatur_bv,
          perc_imposto      = v_perc_imposto
    WHERE item_id = p_item_id;
   --
   -- verifica se precisa voltar algum status do job
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
  item_pkg.valores_recalcular(p_usuario_sessao_id, p_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de alteracoes especiais
  ------------------------------------------------------------
  IF v_flag_pago_cliente <> v_flag_pago_cliente_old
  THEN
   -- verifica se o item tem check-in de nota fiscal
   SELECT COUNT(*)
     INTO v_qt
     FROM item_nota
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    v_compl_aux := ' - PAGO CLIENTE ALTERADO DE "' || v_flag_pago_cliente_old || '" PARA "' ||
                   v_flag_pago_cliente || '" COM CHECK-IN JÁ EFETUADO - ' || to_char(p_item_id);
    --
    item_pkg.historico_gerar(p_usuario_sessao_id,
                             p_item_id,
                             'ALTERACAO',
                             v_compl_aux,
                             p_erro_cod,
                             p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE nota_fiscal nf
       SET flag_pago_cliente = nota_fiscal_pkg.flag_pago_cliente_retornar(nota_fiscal_id)
     WHERE EXISTS (SELECT 1
              FROM item_nota io
             WHERE io.item_id = p_item_id
               AND io.nota_fiscal_id = nf.nota_fiscal_id);
   END IF;
  END IF;
  --
  IF v_tipo_item_old <> p_tipo_item
  THEN
   -- verifica se o item tem check-in de nota fiscal
   SELECT COUNT(*)
     INTO v_qt
     FROM item_nota
    WHERE item_id = p_item_id;
   --
   IF v_qt > 0
   THEN
    v_compl_aux := ' - TIPO DO ITEM ALTERADO DE "' || v_tipo_item_old || '" PARA "' || p_tipo_item ||
                   '" COM CHECK-IN JÁ EFETUADO - ' || to_char(p_item_id);
    --
    item_pkg.historico_gerar(p_usuario_sessao_id,
                             p_item_id,
                             'ALTERACAO',
                             v_compl_aux,
                             p_erro_cod,
                             p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  item_pkg.xml_gerar(p_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_num_item  := item_pkg.num_item_retornar(p_item_id, 'S');
  v_num_orcam := orcamento_pkg.numero_formatar(v_orcamento_id);
  --
  v_identif_objeto := v_num_orcam;
  v_compl_histor   := 'Alteração de item (' || v_num_item || ' - ' ||
                      rtrim(v_nome_produto || ' ' || p_complemento) || ')' || v_compl_aux;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_orcamento_id,
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
 END; -- atualizar
 --
 --
 PROCEDURE tipo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 08/08/2008
  -- DESCRICAO: Atualização de entregável / complemento do ITEM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         19/05/2023  Modificação chamada tipo_produto_pkg.adicionar
  --                               removido parametros custo min, med e max.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_complemento       IN item.complemento%TYPE,
  p_tipo_produto_id   IN item.tipo_produto_id%TYPE,
  p_novo_tipo_produto IN tipo_produto.nome%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          item.job_id%TYPE;
  v_nome_produto    tipo_produto.nome%TYPE;
  v_tipo_produto_id tipo_produto.tipo_produto_id%TYPE;
  v_num_orcamento   orcamento.num_orcamento%TYPE;
  v_orcamento_id    orcamento.orcamento_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_num_item        VARCHAR2(50);
  v_num_orcam       VARCHAR2(50);
  v_xml_antes       CLOB;
  v_xml_atual       CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.orcamento_id
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_produto_id, -1) > 0 AND TRIM(p_novo_tipo_produto) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Um novo entregável não deve ser especificado ' ||
                 'em conjunto com um tipo já existente.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_produto_id, -1) = -1 AND TRIM(p_novo_tipo_produto) IS NULL
  THEN
   -- foi usado -1 pois existe produto_id = 0 cadastrado (do sistema, ND)
   p_erro_cod := '90000';
   p_erro_msg := 'A indicação do entregável é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do item não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- cria tipo produto se necessario
  ------------------------------------------------------------
  IF TRIM(p_novo_tipo_produto) IS NOT NULL
  THEN
   --tipo_produto_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 'N', NU1372LL, p_novo_tipo_produto,
   --NULL, NULL, NULL, NULL, NULL, 'S', 'N', 'N', 'N', 'N', v_tipo_produto_id,
   --p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   v_tipo_produto_id := p_tipo_produto_id;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = v_tipo_produto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse entregável não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  item_pkg.xml_gerar(p_item_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome_produto
    FROM tipo_produto
   WHERE tipo_produto_id = v_tipo_produto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item
     SET tipo_produto_id = v_tipo_produto_id,
         complemento     = TRIM(p_complemento)
   WHERE item_id = p_item_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  item_pkg.xml_gerar(p_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_num_item  := item_pkg.num_item_retornar(p_item_id, 'S');
  v_num_orcam := orcamento_pkg.numero_formatar(v_orcamento_id);
  --
  v_identif_objeto := v_num_orcam;
  v_compl_histor   := 'Alteração de item (' || v_num_item || ' - ' ||
                      rtrim(v_nome_produto || ' ' || p_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_orcamento_id,
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
 END; -- tipo_atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Exclusão de ITEM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta acordo multi-item.
  -- Silvia            02/04/2008  Consistencia de sobra/abatimento.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_complemento    item.complemento%TYPE;
  v_nome_produto   tipo_produto.nome%TYPE;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_num_item       VARCHAR2(50);
  v_num_orcam      VARCHAR2(50);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.orcamento_id
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF orcamento_pkg.liberado_fatur_verificar(v_orcamento_id) > 0
  THEN
   -- orcamento ja aprovado. Verifica privilegio especial.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ITEM_APROV_A', NULL, NULL, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para alterar Estimativas de Custos já aprovadas.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur
   WHERE item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele já foi faturado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_abat
   WHERE item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele possui abatimentos.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota i
   INNER JOIN nota_fiscal n
      ON n.nota_fiscal_id = i.nota_fiscal_id
   WHERE n.tipo_ent_sai = 'E'
     AND i.item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele está associado ao menos a uma nota fiscal de entrada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_carta
   WHERE item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele está associado ao menos a uma Carta Acordo.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_adiant
   WHERE item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele já foi utilizado ao menos em um adiantamento para despesas.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_sobra
   WHERE item_id = p_item_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível excluir este item pois ele possui sobras indicadas.';
   RAISE v_exception;
  END IF;
  --
 
  SELECT COUNT(*)
    INTO v_qt
    FROM parcela
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item já foi parcelado.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_decup
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item possui detalhamento/decupação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a esse item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_carta
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cartas acordo associadas a esse item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_fatur
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a esse item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_sobra
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem sobras associadas a esse item.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_abat
   WHERE item_id = p_item_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem abatimentos associados a esse item.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         it.complemento
    INTO v_nome_produto,
         v_complemento
    FROM tipo_produto tp,
         item         it
   WHERE it.item_id = p_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  item_pkg.xml_gerar(p_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_num_item := item_pkg.num_item_retornar(p_item_id, 'S');
  --
  DELETE FROM item_hist
   WHERE item_id = p_item_id;
  --
  DELETE FROM item
   WHERE item_id = p_item_id;
  --
  -- recalcula o numero sequencial dos itens do orcamento
  orcamento_pkg.num_seq_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_num_orcam := orcamento_pkg.numero_formatar(v_orcamento_id);
  --
  v_identif_objeto := v_num_orcam;
  v_compl_histor   := 'Exclusão de item (' || v_num_item || ' - ' ||
                      rtrim(v_nome_produto || ' ' || v_complemento) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORCAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_orcamento_id,
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
 END; -- excluir
 --
 --
 PROCEDURE valores_recalcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 13/12/2006
  -- DESCRICAO: Recalcula valores desnormalizados do item.
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/07/2012  Novos atributos valor_reservado/valor_disponivel.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_natureza_item    item.natureza_item%TYPE;
  v_valor_ckpend     item.valor_ckpend%TYPE;
  v_valor_cksaldo    item.valor_cksaldo%TYPE;
  v_valor_faturado   item.valor_faturado%TYPE;
  v_valor_liberado   item.valor_liberado%TYPE;
  v_valor_afaturar   item.valor_afaturar%TYPE;
  v_valor_disponivel item.valor_disponivel%TYPE;
  v_valor_reservado  item.valor_reservado%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE item_id = p_item_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT natureza_item
    INTO v_natureza_item
    FROM item
   WHERE item_id = p_item_id;
  --
  v_valor_ckpend     := 0;
  v_valor_cksaldo    := 0;
  v_valor_faturado   := 0;
  v_valor_liberado   := 0;
  v_valor_afaturar   := 0;
  v_valor_reservado  := 0;
  v_valor_disponivel := 0;
  --
  IF v_natureza_item = 'CUSTO'
  THEN
   -- para itens de A, ckpend = cksaldo, pois todo o valor aprovado deve
   -- ter nota fiscal. Para itens de B e C, o ckpend eh calculado com base
   -- na existencia de carta acordo.
   v_valor_ckpend  := item_pkg.valor_checkin_pend_retornar(p_item_id);
   v_valor_cksaldo := item_pkg.valor_retornar(p_item_id, 0, 'SEM_NF');
  END IF;
  --
  v_valor_faturado   := faturamento_pkg.valor_retornar(p_item_id, 0, 'FATURADO');
  v_valor_liberado   := faturamento_pkg.valor_retornar(p_item_id, 0, 'LIBERADO');
  v_valor_afaturar   := faturamento_pkg.valor_retornar(p_item_id, 0, 'AFATURAR');
  v_valor_reservado  := valor_reservado_retornar(p_item_id, 'APROVADO');
  v_valor_disponivel := valor_disponivel_retornar(p_item_id, 'APROVADO');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item
     SET valor_ckpend     = v_valor_ckpend,
         valor_cksaldo    = v_valor_cksaldo,
         valor_faturado   = v_valor_faturado,
         valor_liberado   = v_valor_liberado,
         valor_afaturar   = v_valor_afaturar,
         valor_reservado  = v_valor_reservado,
         valor_disponivel = v_valor_disponivel
   WHERE item_id = p_item_id;
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
 END; -- valores_recalcular
 --
 --
 PROCEDURE ordem_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: subrotina que retorna a nova ordenacao de um determinado item que teve
  --   seus dados alterados (tipo_item, acao, grupo, subgrupo ou aprovado/desaprovado) ou
  --   de um novo item que esta sendo incluido em orcamento de proposta.
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/08/2016  Retirada de acao, alteracoes em ordenacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_job_id            IN item.job_id%TYPE,
  p_orcamento_id      IN item.orcamento_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_tipo_item         IN item.tipo_item%TYPE,
  p_grupo             IN item.grupo%TYPE,
  p_subgrupo          IN item.subgrupo%TYPE,
  p_flag_quebra_tipo  IN VARCHAR2,
  p_ordem_grupo       OUT item.ordem_grupo%TYPE,
  p_ordem_subgrupo    OUT item.ordem_subgrupo%TYPE,
  p_ordem_item        OUT item.ordem_item%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_ordem_grupo    item.ordem_grupo%TYPE;
  v_ordem_subgrupo item.ordem_subgrupo%TYPE;
  v_ordem_item     item.ordem_item%TYPE;
  --
 BEGIN
  v_qt             := 0;
  p_ordem_grupo    := 0;
  p_ordem_subgrupo := 0;
  p_ordem_item     := 0;
  --
  IF p_flag_quebra_tipo = 'S'
  THEN
   ------------------------------------------------------------
   -- tratamento da ordem do grupo COM quebra por tipo
   ------------------------------------------------------------
   v_ordem_grupo := 0;
   --
   IF rtrim(p_grupo) IS NOT NULL
   THEN
    -- o item pertence a um grupo.
    -- verifica se esse grupo ja foi usado no orcamento
    SELECT nvl(MAX(ordem_grupo), 0)
      INTO v_ordem_grupo
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = p_tipo_item
       AND grupo = TRIM(p_grupo);
    --
    IF v_ordem_grupo = 0
    THEN
     -- o grupo nunca foi usado. Procura a maior ordem de grupo
     -- para esse orcamento, e incrementa.
     SELECT zvl(nvl(MAX(ordem_grupo), 0), 50000) + 1
       INTO v_ordem_grupo
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND natureza_item = 'CUSTO'
        AND tipo_item = p_tipo_item;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento da ordem do subgrupo COM quebra por tipo
   ------------------------------------------------------------
   v_ordem_subgrupo := 0;
   --
   IF rtrim(p_subgrupo) IS NOT NULL
   THEN
    -- o item pertence a um subgrupo.
    -- verifica se esse subgrupo ja foi usado no orcamento/grupo
    SELECT nvl(MAX(ordem_subgrupo), 0)
      INTO v_ordem_subgrupo
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = 'CUSTO'
       AND tipo_item = p_tipo_item
       AND ordem_grupo = v_ordem_grupo
       AND subgrupo = TRIM(p_subgrupo);
    --
    IF v_ordem_subgrupo = 0
    THEN
     -- o subgrupo nunca foi usado. Procura a maior ordem de subgrupo
     -- para esse orcamento/grupo, e incrementa.
     SELECT zvl(nvl(MAX(ordem_subgrupo), 0), 50000) + 1
       INTO v_ordem_subgrupo
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND natureza_item = 'CUSTO'
        AND tipo_item = p_tipo_item
        AND ordem_grupo = v_ordem_grupo;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento da ordem do item COM quebra por tipo
   ------------------------------------------------------------
   -- incrementa a ordem do item
   SELECT zvl(nvl(MAX(ordem_item), 0), 50000) + 1
     INTO v_ordem_item
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND natureza_item = 'CUSTO'
      AND tipo_item = p_tipo_item
      AND ordem_grupo = v_ordem_grupo
      AND ordem_subgrupo = v_ordem_subgrupo;
  END IF; -- fim do COM quebra por tipo
  --
  --
  IF p_flag_quebra_tipo = 'N'
  THEN
   ------------------------------------------------------------
   -- tratamento da ordem do grupo SEM quebra por tipo
   ------------------------------------------------------------
   v_ordem_grupo := 0;
   --
   IF rtrim(p_grupo) IS NOT NULL
   THEN
    -- o item pertence a um grupo.
    -- verifica se esse grupo ja foi usado no orcamento
    SELECT nvl(MAX(ordem_grupo_sq), 0)
      INTO v_ordem_grupo
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = 'CUSTO'
       AND grupo = TRIM(p_grupo);
    --
    IF v_ordem_grupo = 0
    THEN
     -- o grupo nunca foi usado. Procura a maior ordem de grupo
     -- para esse orcamento, e incrementa.
     SELECT zvl(nvl(MAX(ordem_grupo_sq), 0), 50000) + 1
       INTO v_ordem_grupo
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND natureza_item = 'CUSTO';
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento da ordem do subgrupo SEM quebra por tipo
   ------------------------------------------------------------
   v_ordem_subgrupo := 0;
   --
   IF rtrim(p_subgrupo) IS NOT NULL
   THEN
    -- o item pertence a um subgrupo.
    -- verifica se esse subgrupo ja foi usado no orcamento/grupo
    SELECT nvl(MAX(ordem_subgrupo_sq), 0)
      INTO v_ordem_subgrupo
      FROM item
     WHERE orcamento_id = p_orcamento_id
       AND natureza_item = 'CUSTO'
       AND ordem_grupo_sq = v_ordem_grupo
       AND subgrupo = TRIM(p_subgrupo);
    --
    IF v_ordem_subgrupo = 0
    THEN
     -- o subgrupo nunca foi usado. Procura a maior ordem de subgrupo
     -- para esse orcamento/grupo, e incrementa.
     SELECT zvl(nvl(MAX(ordem_subgrupo_sq), 0), 50000) + 1
       INTO v_ordem_subgrupo
       FROM item
      WHERE orcamento_id = p_orcamento_id
        AND natureza_item = 'CUSTO'
        AND ordem_grupo_sq = v_ordem_grupo;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- tratamento da ordem do item SEM quebra por tipo
   ------------------------------------------------------------
   -- incrementa a ordem do item
   SELECT zvl(nvl(MAX(ordem_item_sq), 0), 50000) + 1
     INTO v_ordem_item
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND natureza_item = 'CUSTO'
      AND ordem_grupo_sq = v_ordem_grupo
      AND ordem_subgrupo_sq = v_ordem_subgrupo;
  END IF; -- fim do SEM quebra por tipo
  --
  p_ordem_grupo    := v_ordem_grupo;
  p_ordem_subgrupo := v_ordem_subgrupo;
  p_ordem_item     := v_ordem_item;
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
 END; -- ordem_retornar
 --
 PROCEDURE ordem_compra_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                 ProcessMind     DATA: 30/12/2024
  -- DESCRICAO: Adicao de ORDEM DE COMPRA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_ordem_compra      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'INFO_OC_ITEM', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF length(p_ordem_compra) > 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A ordem de compra não pode ter mais que 60 caracteres';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job       j,
         orcamento o,
         item      i
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id
     AND TRIM(upper(i.ordem_compra)) = TRIM(upper(p_ordem_compra));
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ordem de compra já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item
     SET ordem_compra = TRIM(p_ordem_compra)
   WHERE item_id = p_item_id;
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
 END ordem_compra_adicionar;
 --
 PROCEDURE historico_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: subrotina que registra o historico do item. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2015  novo codigo REPROVACAO
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_codigo            IN item_hist.codigo%TYPE,
  p_complemento       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_descricao item_hist.descricao%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_codigo = 'CRIACAO'
  THEN
   v_descricao := 'Criação';
  ELSIF p_codigo = 'APROVACAO'
  THEN
   v_descricao := 'Aprovação da Estimativa de Custos';
  ELSIF p_codigo = 'REPROVACAO'
  THEN
   v_descricao := 'Rerovação da Estimativa de Custos';
  ELSIF p_codigo = 'ALTERACAO'
  THEN
   v_descricao := 'Alteração Especial';
  ELSIF p_codigo = 'REVISAO'
  THEN
   v_descricao := 'Revisão da Estimativa de Custos';
  ELSIF p_codigo = 'PARCEL'
  THEN
   v_descricao := 'Parcelamento';
  ELSIF p_codigo = 'DESPARCEL'
  THEN
   v_descricao := 'Desparcelamento';
  ELSIF p_codigo = 'LIBE_FATUR'
  THEN
   v_descricao := 'Liberação para Faturamento';
  ELSIF p_codigo = 'LESP_FATUR'
  THEN
   v_descricao := 'Liberação Especial';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Código do histórico do item inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do histórico do item não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO item_hist
   (item_hist_id,
    item_id,
    usuario_resp_id,
    data,
    codigo,
    descricao,
    complemento)
  VALUES
   (seq_item_hist.nextval,
    p_item_id,
    p_usuario_sessao_id,
    trunc(SYSDATE),
    p_codigo,
    v_descricao,
    ltrim(rtrim(p_complemento)));
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
 END historico_gerar;
 --
 --
 PROCEDURE cod_externo_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Rafael         ProcessMind     DATA: 11/03/2025
  -- DESCRICAO: procedimento que adiciona ou altera o cod_externo na tabela item
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_cod_externo       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  --
  -- verificando o campo cod_externo se é > que 20 caracteres
  IF length(TRIM(p_cod_externo)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Código Externo do item não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- VALIDAÇÕES
  ------------------------------------------------------------
  --
  ------------------------------------------------------------
  -- ATUALIZAÇÃO DO BANCO
  ------------------------------------------------------------
  --
  -- Faz UPDATE sobrescrevendo o cod_externo old
  UPDATE item
     SET cod_externo = p_cod_externo
   WHERE item_id = p_item_id;
  --
  -- Confirma a transação
  COMMIT;
  --
  -- Retorno de sucesso
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   --
 END cod_externo_alterar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 10/01/2017
  -- DESCRICAO: Subrotina que gera o xml do item para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_item_id  IN item.item_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_doc   VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("item",
                           xmlelement("item_id", it.item_id),
                           xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                           xmlelement("numero_job", jo.numero),
                           xmlelement("status_job", jo.status),
                           xmlelement("numero_estim", oc.num_orcamento),
                           xmlelement("status_estim", oc.status),
                           xmlelement("tipo_item", it.tipo_item),
                           xmlelement("num_seq", it.num_seq),
                           xmlelement("natureza_item", it.natureza_item),
                           xmlelement("nome_tipo_produto", tp.nome),
                           xmlelement("complemento", char_especial_retirar(it.complemento)),
                           xmlelement("quantidade", numero_mostrar(it.quantidade, 2, 'N')),
                           xmlelement("frequencia", numero_mostrar(it.frequencia, 2, 'N')),
                           xmlelement("unidade_freq",
                                      util_pkg.desc_retornar('unidade_freq_item', it.unidade_freq)),
                           xmlelement("custo_unitario", numero_mostrar(it.custo_unitario, 5, 'N')),
                           xmlelement("valor_aprovado", numero_mostrar(it.valor_aprovado, 5, 'N')),
                           xmlelement("valor_fornecedor",
                                      numero_mostrar(it.valor_fornecedor, 5, 'N')),
                           xmlelement("fornecedor", fo.apelido),
                           xmlelement("perc_bv", numero_mostrar(it.perc_bv, 5, 'N')),
                           xmlelement("perc_imposto", numero_mostrar(it.perc_imposto, 2, 'N')),
                           xmlelement("tipo_fatur_bv", it.tipo_fatur_bv),
                           xmlelement("pago_cliente", it.flag_pago_cliente),
                           xmlelement("tem_honor", it.flag_com_honor),
                           xmlelement("tem_encargo", it.flag_com_encargo),
                           xmlelement("tem_encargo_honor", it.flag_com_encargo_honor)))
    INTO v_xml
    FROM item         it,
         job          jo,
         orcamento    oc,
         tipo_produto tp,
         pessoa       fo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id
     AND it.orcamento_id = oc.orcamento_id
     AND it.tipo_produto_id = tp.tipo_produto_id
     AND it.fornecedor_id = fo.pessoa_id(+);
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
 FUNCTION liberacao_especial_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: verifica se um determinado item a ser liberado p/ faturamento necessita
  --    de liberacao especial.  Retorna 1 caso necessite e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  --v_perc_bv_fornec pessoa.perc_bv%TYPE;
  v_perc_bv_item   item.perc_bv%TYPE;
  v_tipo_item      item.tipo_item%TYPE;
  v_flag_sem_valor item.flag_sem_valor%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(it.perc_bv, 0),
         --nvl(pe.perc_bv, 0),
         tipo_item,
         flag_sem_valor
    INTO v_perc_bv_item,
         --v_perc_bv_fornec,
         v_tipo_item,
         v_flag_sem_valor
    FROM item   it,
         pessoa pe
   WHERE it.item_id = p_item_id
     AND it.fornecedor_id = pe.pessoa_id(+);
  --
  /*IF v_flag_sem_valor = 'N' AND v_tipo_item IN ('A', 'B')
  THEN
   IF v_perc_bv_item <> v_perc_bv_fornec
   THEN
    v_retorno := 1;
    RETURN v_retorno;
   END IF;
  END IF;*/
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END liberacao_especial_verificar;
 --
 --
 FUNCTION data_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a data referente a um determinado evento do item (criacao,
  --   aprovacao, parcelamento, liberacao, etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE,
  p_codigo  IN item_hist.codigo%TYPE
 ) RETURN DATE AS
  v_qt      INTEGER;
  v_retorno DATE;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_codigo = 'APROVACAO'
  THEN
   SELECT MAX(data)
     INTO v_retorno
     FROM item_hist hi,
          item      it,
          orcamento oc
    WHERE hi.item_id = p_item_id
      AND hi.codigo = p_codigo
      AND hi.item_id = it.item_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV';
  ELSIF p_codigo = 'PARCEL'
  THEN
   SELECT MAX(data)
     INTO v_retorno
     FROM item_hist hi,
          item      it
    WHERE hi.item_id = p_item_id
      AND hi.codigo = p_codigo
      AND hi.item_id = it.item_id
      AND it.flag_parcelado = 'S';
  ELSIF p_codigo IN ('LIBE_FATUR', 'LESP_FATUR')
  THEN
   SELECT MAX(data)
     INTO v_retorno
     FROM item_hist hi,
          item      it
    WHERE hi.item_id = p_item_id
      AND hi.codigo = p_codigo
      AND hi.item_id = it.item_id
      AND it.status_fatur <> 'NLIB';
  ELSE
   SELECT MAX(data)
     INTO v_retorno
     FROM item_hist
    WHERE item_id = p_item_id
      AND codigo = p_codigo;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_evento_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor planejado de um determinado item ou carta acordo, de acordo
  --  com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2008  Implementacao de carta acordo multi-item.
  -- Silvia            01/04/2008  Tratamento de sobras.
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            15/06/2012  Nova natureza ABAT.
  -- Silvia            28/10/2013  Nova natureza ABAT_COM_DEB
  -- Silvia            21/01/2015  Tratamento de adiantamento.
  -- Silvia            19/06/2017  Nova natureza ADIANT_SOLIC.
  -- Silvia            30/10/2020  Tratamento de flag_dentro_ca (sobra),
  -- Ana Luiza         11/07/2025  Tratamento para quando LIMITAR_ORCAM_FORNEC ligado
  ------------------------------------------------------------------------------------------
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                   INTEGER;
  v_retorno              NUMBER;
  v_exception            EXCEPTION;
  v_valor_aprovado       item.valor_aprovado%TYPE;
  v_valor_fornecedor     item.valor_fornecedor%TYPE;
  v_valor_sobras         NUMBER;
  v_valor_sobras_parcial NUMBER;
  v_perc_bv              item.perc_bv%TYPE;
  v_perc_imposto         item.perc_imposto%TYPE;
  v_valor_com_nf         NUMBER;
  v_valor_aprov_com_ca   NUMBER;
  v_valor_fornec_com_ca  NUMBER;
  v_valor_bv_ca          NUMBER;
  v_valor_tip_ca         NUMBER;
  v_valor_abat           NUMBER;
  v_valor_abat_com_deb   NUMBER;
  v_valor_adiant_efetivo NUMBER;
  v_valor_adiant_solic   NUMBER;
  v_limitar_orcam_fornec CHAR(1);
  v_empresa_id           NUMBER;
  v_valor_disponivel     item.valor_disponivel%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --ALCBO_110725
  SELECT empresa_id
    INTO v_empresa_id
    FROM job
   WHERE job_id IN (SELECT job_id
                      FROM item
                     WHERE item_id = p_item_id);
  --
  v_limitar_orcam_fornec := empresa_pkg.parametro_retornar(v_empresa_id, 'LIMITAR_ORCAM_FORNEC');
  --
  IF p_tipo_valor NOT IN ('APROVADO',
                          'FORNECEDOR',
                          'BV',
                          'IMPOSTO',
                          'TIP',
                          'PERC_BV',
                          'PERC_IMPOSTO',
                          'COM_NF',
                          'SEM_NF',
                          'COM_CA',
                          'SEM_CA',
                          'FOR_COM_CA',
                          'FOR_SEM_CA',
                          'BV_COM_CA',
                          'TIP_COM_CA',
                          'SOBRA',
                          'SOBRA_SEM_CA',
                          'ABAT',
                          'ABAT_COM_DEB',
                          'ADIANT_SOLIC',
                          --ALCBO_110725 (SALDO)Criado para controlar LIMITAR_ORCAM_FORNEC
                          'SALDO') OR TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  v_valor_sobras_parcial := 0;
  v_valor_adiant_efetivo := 0;
  v_valor_adiant_solic   := 0;
  --
  IF nvl(p_carta_acordo_id, 0) = 0
  THEN
   -- recupera as sobras puras do item, sem levar em conta
   -- as sobras dentro da carta acordo.
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras_parcial
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id
         -- AND so.carta_acordo_id IS NULL
      AND so.flag_dentro_ca = 'N';
   --
   -- recupera os adiantamentos efetivos do item
   SELECT nvl(SUM(decode(ad.status, 'ENCE', it.valor_despesa, it.valor_solicitado)), 0)
     INTO v_valor_adiant_efetivo
     FROM item_adiant it,
          adiant_desp ad
    WHERE it.item_id = p_item_id
      AND it.adiant_desp_id = ad.adiant_desp_id;
   --
   -- recupera os adiantamentos solicitados do item
   SELECT nvl(SUM(it.valor_solicitado), 0)
     INTO v_valor_adiant_solic
     FROM item_adiant it
    WHERE it.item_id = p_item_id;
  END IF;
  --
  IF nvl(p_carta_acordo_id, 0) = 0
  THEN
   SELECT nvl(valor_aprovado, 0),
          nvl(valor_fornecedor, 0),
          nvl(perc_bv, 0),
          nvl(perc_imposto, 0)
     INTO v_valor_aprovado,
          v_valor_fornecedor,
          v_perc_bv,
          v_perc_imposto
     FROM item
    WHERE item_id = p_item_id;
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_com_nf
     FROM item_nota
    WHERE item_id = p_item_id;
   --
   SELECT nvl(SUM(ic.valor_aprovado), 0),
          nvl(SUM(ic.valor_fornecedor), 0),
          nvl(SUM(round(nvl(ic.valor_fornecedor, 0) * nvl(ca.perc_bv, 0) / 100, 2)), 0),
          nvl(SUM(round((nvl(ic.valor_aprovado, 0) - nvl(ic.valor_fornecedor, 0)) *
                        (1 - nvl(ca.perc_imposto, 0) / 100),
                        2)),
              0)
     INTO v_valor_aprov_com_ca,
          v_valor_fornec_com_ca,
          v_valor_bv_ca,
          v_valor_tip_ca
     FROM carta_acordo ca,
          item_carta   ic
    WHERE ic.item_id = p_item_id
      AND ic.carta_acordo_id = ca.carta_acordo_id
      AND ca.status = 'EMITIDA';
   --
   -- recupera as sobras totais do item
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra it
    WHERE it.item_id = p_item_id;
   --
   -- recupera os abatimentos totais do item
   SELECT nvl(SUM(it.valor_abat_item), 0)
     INTO v_valor_abat
     FROM item_abat it
    WHERE it.item_id = p_item_id;
   --
   -- recupera os abatimentos do item com debito para o cliente
   SELECT nvl(SUM(it.valor_abat_item), 0)
     INTO v_valor_abat_com_deb
     FROM item_abat  it,
          abatimento ab
    WHERE it.item_id = p_item_id
      AND it.abatimento_id = ab.abatimento_id
      AND ab.flag_debito_cli = 'S';
  ELSE
   SELECT SUM(nvl(ic.valor_aprovado, 0)),
          SUM(nvl(ic.valor_fornecedor, 0)),
          MAX(nvl(ca.perc_bv, 0)),
          MAX(nvl(ca.perc_imposto, 0)),
          SUM(nvl(round(nvl(ic.valor_fornecedor, 0) * nvl(ca.perc_bv, 0) / 100, 2), 0)),
          SUM(nvl(round((nvl(ic.valor_aprovado, 0) - nvl(ic.valor_fornecedor, 0)) *
                        (1 - nvl(ca.perc_imposto, 0) / 100),
                        2),
                  0))
     INTO v_valor_aprovado,
          v_valor_fornecedor,
          v_perc_bv,
          v_perc_imposto,
          v_valor_bv_ca,
          v_valor_tip_ca
     FROM carta_acordo ca,
          item_carta   ic
    WHERE ca.carta_acordo_id = p_carta_acordo_id
      AND ca.carta_acordo_id = ic.carta_acordo_id
      AND ic.item_id = p_item_id;
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_com_nf
     FROM item_nota
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = p_item_id;
   --
   -- recupera as sobras totais do item em relacao a essa carta acordo
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id
      AND so.carta_acordo_id = p_carta_acordo_id
      AND so.flag_dentro_ca = 'S';
   --
   -- recupera os abatimentos totais do item em relacao a essa carta acordo
   SELECT nvl(SUM(it.valor_abat_item), 0)
     INTO v_valor_abat
     FROM item_abat  it,
          abatimento ab
    WHERE it.item_id = p_item_id
      AND it.abatimento_id = ab.abatimento_id
      AND ab.carta_acordo_id = p_carta_acordo_id;
   --
   -- recupera os abatimentos do item em relacao a essa carta acordo com
   -- debito para o cliente
   SELECT nvl(SUM(it.valor_abat_item), 0)
     INTO v_valor_abat_com_deb
     FROM item_abat  it,
          abatimento ab
    WHERE it.item_id = p_item_id
      AND it.abatimento_id = ab.abatimento_id
      AND ab.flag_debito_cli = 'S'
      AND ab.carta_acordo_id = p_carta_acordo_id;
   --
   v_valor_aprov_com_ca  := v_valor_aprovado;
   v_valor_fornec_com_ca := v_valor_fornecedor;
  END IF;
  --
  IF p_tipo_valor = 'APROVADO'
  THEN
   v_retorno := v_valor_aprovado;
  ELSIF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornecedor;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := round(v_valor_fornecedor * v_perc_bv / 100, 2);
  ELSIF p_tipo_valor = 'IMPOSTO'
  THEN
   v_retorno := round((v_valor_aprovado - v_valor_fornecedor) * v_perc_imposto / 100, 2);
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := round((v_valor_aprovado - v_valor_fornecedor) * (1 - v_perc_imposto / 100), 2);
  ELSIF p_tipo_valor = 'PERC_BV'
  THEN
   v_retorno := v_perc_bv;
  ELSIF p_tipo_valor = 'PERC_IMPOSTO'
  THEN
   v_retorno := v_perc_imposto;
  ELSIF p_tipo_valor = 'BV_COM_CA'
  THEN
   v_retorno := v_valor_bv_ca;
  ELSIF p_tipo_valor = 'TIP_COM_CA'
  THEN
   v_retorno := v_valor_tip_ca;
  ELSIF p_tipo_valor = 'COM_NF'
  THEN
   v_retorno := v_valor_com_nf;
  ELSIF p_tipo_valor = 'SEM_NF'
  THEN
   v_retorno := v_valor_aprovado - v_valor_com_nf - v_valor_sobras - v_valor_adiant_efetivo;
  ELSIF p_tipo_valor = 'COM_CA'
  THEN
   v_retorno := v_valor_aprov_com_ca;
  ELSIF p_tipo_valor = 'SEM_CA'
  THEN
   v_retorno := v_valor_aprovado - v_valor_aprov_com_ca - v_valor_sobras_parcial;
  ELSIF p_tipo_valor = 'FOR_COM_CA'
  THEN
   v_retorno := v_valor_fornec_com_ca;
   --ALCBO_110725  
  ELSIF p_tipo_valor = 'SALDO'
  THEN
   IF v_limitar_orcam_fornec = 'S'
   THEN
    v_retorno := v_valor_fornecedor;
   ELSE
    SELECT valor_disponivel
      INTO v_valor_disponivel
      FROM item
     WHERE item_id = p_item_id;
    v_retorno := v_valor_disponivel;
   END IF;
  ELSIF p_tipo_valor = 'FOR_SEM_CA'
  THEN
   v_retorno := v_valor_fornecedor - v_valor_fornec_com_ca - v_valor_sobras_parcial;
   --
   -- o saldo do custo do fornecedor nao pode ser maior que o saldo aprovado
   IF v_retorno > v_valor_aprovado - v_valor_aprov_com_ca - v_valor_sobras_parcial
   THEN
    v_retorno := v_valor_aprovado - v_valor_aprov_com_ca - v_valor_sobras_parcial;
   END IF;
   --
   -- o salso do custo do fornecedor nao pode ser negativo
   IF v_retorno < 0
   THEN
    v_retorno := 0;
   END IF;
  ELSIF p_tipo_valor = 'SOBRA'
  THEN
   v_retorno := v_valor_sobras;
  ELSIF p_tipo_valor = 'SOBRA_SEM_CA'
  THEN
   v_retorno := v_valor_sobras_parcial;
  ELSIF p_tipo_valor = 'ABAT'
  THEN
   v_retorno := v_valor_abat;
  ELSIF p_tipo_valor = 'ABAT_COM_DEB'
  THEN
   v_retorno := v_valor_abat_com_deb;
  ELSIF p_tipo_valor = 'ADIANT_SOLIC'
  THEN
   v_retorno := v_valor_adiant_solic;
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
 FUNCTION valor_natureza_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/08/2023
  -- DESCRICAO: aplica o calculo de uma determinada natureza num item
  --  do tipo CUSTO. Se o item nao for CUSTO, retorna o valor gravado no banco.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id       IN item.item_id%TYPE,
  p_natureza_calc IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno                NUMBER;
  v_qt                     INTEGER;
  v_valor_base             NUMBER;
  v_valor_base_custo       NUMBER;
  v_valor_base_outros      NUMBER;
  v_valor_outros           NUMBER;
  v_valor_calculado        NUMBER;
  v_tipo_item_inc          VARCHAR2(20);
  v_tipo_item              item.tipo_item%TYPE;
  v_orcamento_id           item.orcamento_id%TYPE;
  v_flag_pago_cliente      item.flag_pago_cliente%TYPE;
  v_flag_com_honor         item.flag_com_honor%TYPE;
  v_flag_com_encargo       item.flag_com_encargo%TYPE;
  v_flag_com_encargo_honor item.flag_com_encargo_honor%TYPE;
  v_natureza_item          item.natureza_item%TYPE;
  v_empresa_id             job.empresa_id%TYPE;
  v_natureza_item_id       natureza_item.natureza_item_id%TYPE;
  v_valor_padrao_honor     natureza_item.valor_padrao%TYPE;
  v_mod_calculo_honor      natureza_item.mod_calculo%TYPE;
  v_flag_inc_a             natureza_item.flag_inc_a%TYPE;
  v_flag_inc_b             natureza_item.flag_inc_b%TYPE;
  v_flag_inc_c             natureza_item.flag_inc_c%TYPE;
  v_mod_calculo            natureza_item.mod_calculo%TYPE;
  v_valor_padrao           orcam_nitem_pdr.valor_padrao%TYPE;
  v_tipo_natur             natureza_item.tipo%TYPE;
  v_flag_sistema           natureza_item.flag_sistema%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  --
  -- seleciona a natureza sobre a qual essa incide
  --(natureza anterior)
  CURSOR c_na IS
   SELECT na.codigo,
          na.nome,
          na.tipo,
          na.ordem
     FROM natureza_item_inc ni,
          natureza_item     na
    WHERE ni.natureza_item_id = v_natureza_item_id
      AND ni.natureza_item_inc_id = na.natureza_item_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_valor_calculado := 0;
  --
  -- recupera dados do item a ser calculado
  SELECT it.orcamento_id,
         it.tipo_item,
         jo.empresa_id,
         nvl(it.valor_aprovado, 0),
         it.flag_pago_cliente,
         it.flag_com_honor,
         it.flag_com_encargo,
         it.flag_com_encargo_honor,
         it.natureza_item
    INTO v_orcamento_id,
         v_tipo_item,
         v_empresa_id,
         v_valor_base_custo,
         v_flag_pago_cliente,
         v_flag_com_honor,
         v_flag_com_encargo,
         v_flag_com_encargo_honor,
         v_natureza_item
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id;
  --
  IF p_natureza_calc = 'CUSTO'
  THEN
   -- nao existe calculo do tipo CUSTO.
   -- retorna o valor do item gravado no banco.
   v_valor_calculado := v_valor_base_custo;
   RAISE v_saida;
  END IF;
  --
  IF v_natureza_item <> 'CUSTO'
  THEN
   IF v_natureza_item = p_natureza_calc
   THEN
    -- o item nao eh CUSTO. Retorna o valor ja calculado no banco,
    -- pois o uso dessa funcao so faz sentido para itens de
    -- natureza CUSTO.
    v_valor_calculado := v_valor_base_custo;
    RAISE v_saida;
   ELSE
    -- o item nao eh CUSTO. Combinacao invalida entre o item_id
    -- e a modalidade de calculo. Sai sem calcular.
    v_valor_calculado := 0;
    RAISE v_saida;
   END IF;
  END IF;
  --
  -- recupera dados na natureza a ser calculada
  SELECT MAX(na.natureza_item_id),
         MAX(na.flag_inc_a),
         MAX(na.flag_inc_b),
         MAX(na.flag_inc_c),
         MAX(na.mod_calculo),
         MAX(oc.valor_padrao),
         MAX(na.tipo),
         MAX(na.flag_sistema)
    INTO v_natureza_item_id,
         v_flag_inc_a,
         v_flag_inc_b,
         v_flag_inc_c,
         v_mod_calculo,
         v_valor_padrao,
         v_tipo_natur,
         v_flag_sistema
    FROM natureza_item   na,
         orcam_nitem_pdr oc
   WHERE na.empresa_id = v_empresa_id
     AND na.codigo = p_natureza_calc
     AND na.natureza_item_id = oc.natureza_item_id
     AND oc.orcamento_id = v_orcamento_id;
  --
  IF v_natureza_item_id IS NULL
  THEN
   -- natureza nao instanciada no orcamento.
   -- sai sem calcular.
   v_valor_calculado := 0;
   RAISE v_saida;
  END IF;
  --
  -- inicializa variavel para nao deixar NULL
  v_tipo_item_inc := 'X';
  --
  -- concatena na v_tipo_item_inc todos os tipos de incidencia
  -- configuradas na natureza
  IF v_flag_inc_a = 'S'
  THEN
   v_tipo_item_inc := v_tipo_item_inc || 'A';
  END IF;
  --
  IF v_flag_inc_b = 'S'
  THEN
   v_tipo_item_inc := v_tipo_item_inc || 'B';
  END IF;
  --
  IF v_flag_inc_c = 'S'
  THEN
   v_tipo_item_inc := v_tipo_item_inc || 'C';
  END IF;
  --
  IF instr(v_tipo_item_inc, v_tipo_item) = 0
  THEN
   -- natureza NAO incide sobre essa modalidade de contratação
   v_valor_base_custo := 0;
  END IF;
  --
  IF v_valor_base_custo > 0
  THEN
   IF p_natureza_calc = 'CPMF'
   THEN
    IF v_flag_pago_cliente = 'S' OR v_flag_com_encargo = 'N'
    THEN
     -- nao calcula essa natureza
     v_valor_base_custo := 0;
    END IF;
   ELSIF p_natureza_calc = 'HONOR'
   THEN
    IF v_flag_com_honor = 'N'
    THEN
     -- nao calcula essa natureza
     v_valor_base_custo := 0;
    END IF;
   ELSIF p_natureza_calc = 'ENCARGO'
   THEN
    IF v_flag_pago_cliente = 'S' OR v_flag_com_encargo = 'N'
    THEN
     -- nao calcula essa natureza
     v_valor_base_custo := 0;
    END IF;
   ELSIF p_natureza_calc = 'ENCARGO_HONOR'
   THEN
    -- tratamento especial pois essa natureza nao usa incidencia
    -- sobre honorarios configurada na tela.
    IF v_flag_com_honor = 'N' OR v_flag_com_encargo_honor = 'N'
    THEN
     -- nao calcula essa natureza
     v_valor_base_custo := 0;
    ELSE
     -- recupera indice p/ calculo de honorarios
     SELECT MAX(nvl(oc.valor_padrao, 0)),
            MAX(na.mod_calculo)
       INTO v_valor_padrao_honor,
            v_mod_calculo_honor
       FROM natureza_item   na,
            orcam_nitem_pdr oc
      WHERE oc.orcamento_id = v_orcamento_id
        AND oc.natureza_item_id = na.natureza_item_id
        AND na.codigo = 'HONOR'
        AND na.empresa_id = v_empresa_id;
     --
     -- calcula honorarios do item para depois poder calcular encargos
     IF v_mod_calculo_honor = 'PERC'
     THEN
      -- o valor padrao eh um percentual
      v_valor_base_custo := round(v_valor_base_custo * v_valor_padrao_honor / 100, 2);
     ELSIF v_mod_calculo_honor = 'IND'
     THEN
      -- o valor padrao eh um indice
      v_valor_base_custo := round(v_valor_base_custo * v_valor_padrao_honor, 2);
     ELSIF v_mod_calculo_honor = 'DIV'
     THEN
      -- o valor padrao eh um percentual a ser usado na divisao
      v_valor_base_custo := round(v_valor_base_custo / ((100 - v_valor_padrao_honor) / 100), 2) -
                            v_valor_base_custo;
     END IF;
    END IF;
   ELSE
    -- natureza nao sistemica.
    -- Testa pelo tipo (HONOR ou ENCARGO)
    IF v_tipo_natur = 'HONOR'
    THEN
     IF v_flag_com_honor = 'N'
     THEN
      -- nao calcula essa natureza
      v_valor_base_custo := 0;
     END IF;
    ELSIF v_tipo_natur = 'ENCARGO'
    THEN
     IF v_flag_pago_cliente = 'S' OR v_flag_com_encargo = 'N'
     THEN
      -- nao calcula essa natureza
      v_valor_base_custo := 0;
     END IF;
    END IF;
   END IF;
  END IF; -- fim do IF INSTR(v_tipo_item_inc,v_tipo_item)
  --
  -- recupera valor base de naturezas anteriores
  --
  v_valor_base_outros := 0;
  FOR r_na IN c_na
  LOOP
   IF v_flag_sistema = 'N' AND v_tipo_natur = 'ENCARGO' AND r_na.tipo = 'HONOR' AND
      v_flag_com_encargo_honor = 'N'
   THEN
    -- natureza principal encargo incide sobre outra do tipo
    -- honorario. Nao calcula se o item estiver com encargo_honor
    -- desligado.
    v_valor_outros := 0;
   ELSE
    v_valor_outros := item_pkg.valor_natureza_retornar(p_item_id, r_na.codigo);
   END IF;
   --
   v_valor_base_outros := v_valor_base_outros + v_valor_outros;
  END LOOP;
  --
  -- aplica o percentual ou indice
  --
  v_valor_base := v_valor_base_custo + v_valor_base_outros;
  --
  IF v_mod_calculo = 'PERC'
  THEN
   -- o valor padrao eh um percentual
   v_valor_calculado := round(v_valor_base * v_valor_padrao / 100, 2);
  ELSIF v_mod_calculo = 'IND'
  THEN
   -- o valor padrao eh um indice
   v_valor_calculado := round(v_valor_base * v_valor_padrao, 2);
  ELSIF v_mod_calculo = 'DIV'
  THEN
   -- o valor padrao eh um percentual a ser usado na divisao
   v_valor_calculado := round(v_valor_base / ((100 - v_valor_padrao) / 100), 2) - v_valor_base;
  END IF;
  --
  RETURN v_valor_calculado;
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_valor_calculado;
  WHEN v_exception THEN
   v_valor_calculado := 99999;
   RETURN v_valor_calculado;
  WHEN OTHERS THEN
   v_valor_calculado := 99999;
   RETURN v_valor_calculado;
 END valor_natureza_retornar;
 --
 --
 FUNCTION valor_sobra_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/12/2013
  -- DESCRICAO: retorna o valor da sobra determinado item.
  --  p_tipo_valor: SOB - sobra, SNP - servico nao prestado, TOT - total
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_sobra IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt           INTEGER;
  v_retorno      NUMBER;
  v_exception    EXCEPTION;
  v_valor_sobras NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_sobra NOT IN ('SOB', 'SNP', 'TOT') OR TRIM(p_tipo_sobra) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_sobra = 'TOT'
  THEN
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id;
  ELSE
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id
      AND so.tipo_sobra = p_tipo_sobra;
  END IF;
  --
  v_retorno := v_valor_sobras;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_sobra_retornar;
 --
 --
 FUNCTION valor_planejado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor planejado de um determinado item , de acordo
  --  com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                        INTEGER;
  v_retorno                   NUMBER;
  v_exception                 EXCEPTION;
  v_valor_fornecedor          NUMBER;
  v_valor_bv                  NUMBER;
  v_valor_tip                 NUMBER;
  v_tipo_item                 item.tipo_item%TYPE;
  v_valor_fornecedor_it       item.valor_fornecedor%TYPE;
  v_valor_bv_it               NUMBER;
  v_valor_tip_it              NUMBER;
  v_permitir_checkin_a_sem_ca VARCHAR2(1);
  v_empresa_id                empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT j.empresa_id
    INTO v_empresa_id
    FROM item i
   INNER JOIN orcamento o
      ON o.orcamento_id = i.orcamento_id
   INNER JOIN job j
      ON j.job_id = o.job_id
   WHERE i.item_id = p_item_id;
  --
  v_permitir_checkin_a_sem_ca := empresa_pkg.parametro_retornar(v_empresa_id,
                                                                'PERMITIR_CHECKIN_A_SEM_CA');
  --
  IF p_tipo_valor NOT IN ('FORNECEDOR', 'BV', 'TIP', 'RENTAB') OR TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_item,
         nvl(valor_fornecedor, 0),
         item_pkg.valor_retornar(item_id, 0, 'BV'),
         item_pkg.valor_retornar(item_id, 0, 'TIP')
    INTO v_tipo_item,
         v_valor_fornecedor_it,
         v_valor_bv_it,
         v_valor_tip_it
    FROM item
   WHERE item_id = p_item_id;
  --
  -- para itens de A o planejado é o que foi definido nas cartas acordo
  v_valor_bv         := item_pkg.valor_retornar(p_item_id, 0, 'BV_COM_CA');
  v_valor_tip        := item_pkg.valor_retornar(p_item_id, 0, 'TIP_COM_CA');
  v_valor_fornecedor := item_pkg.valor_retornar(p_item_id, 0, 'FOR_COM_CA');
  --
  -- para os demais itens, vale o que foi definido no item, desde que
  -- maior que os valores das cartas acordo.
  IF v_tipo_item <> 'A' OR (v_tipo_item = 'A' AND v_permitir_checkin_a_sem_ca = 'S')
  THEN
   IF v_valor_fornecedor_it > v_valor_fornecedor
   THEN
    v_valor_fornecedor := v_valor_fornecedor_it;
   END IF;
   --
   IF v_valor_bv_it > v_valor_bv
   THEN
    v_valor_bv := v_valor_bv_it;
   END IF;
   --
   IF v_valor_tip_it > v_valor_tip
   THEN
    v_valor_tip := v_valor_tip_it;
   END IF;
  END IF;
  --
  IF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornecedor;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := v_valor_bv;
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := v_valor_tip;
  ELSIF p_tipo_valor = 'RENTAB'
  THEN
   v_retorno := v_valor_bv + v_valor_tip;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_planejado_retornar;
 --
 --
 FUNCTION valor_utilizado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/07/2012
  -- DESCRICAO: retorna o valor utilizado de um determinado item , de acordo
  --  com o tipo especificado no parametro de entrada. Usado na interface de rentabilidade.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2013  Novos tipos para retornar valores com nota fiscal de
  --                               saida (BV_NFS e TIP_NFS).
  -- Silvia            01/11/2013  Novos tipos para retornar valores com nota fiscal de
  --                               entrada (BV_NFE e TIP_NFE).
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt               INTEGER;
  v_retorno          NUMBER;
  v_exception        EXCEPTION;
  v_valor_ckpend     item.valor_ckpend%TYPE;
  v_valor_bv_com_ca  NUMBER;
  v_valor_tip_com_ca NUMBER;
  v_valor_bv_com_nf  NUMBER;
  v_valor_tip_com_nf NUMBER;
  --
 BEGIN
  v_retorno          := 0;
  v_valor_bv_com_ca  := 0;
  v_valor_tip_com_ca := 0;
  v_valor_bv_com_nf  := 0;
  v_valor_tip_com_nf := 0;
  --
  IF p_tipo_valor NOT IN ('BV', 'TIP', 'BV_NFS', 'TIP_NFS', 'BV_NFE', 'TIP_NFE') OR
     TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_valor IN ('BV', 'TIP')
  THEN
   -- retorna BV/TIP previsto na carta acordo ou o que foi efetivamente
   -- entrado no check-in.
   SELECT valor_ckpend
     INTO v_valor_ckpend
     FROM item
    WHERE item_id = p_item_id;
   --
   IF v_valor_ckpend > 0
   THEN
    -- item c/ cartas acordo com check-in incompleto. Vale o que foi definido na
    -- carta acordo.
    SELECT nvl(SUM(item_pkg.valor_retornar(ic.item_id, ic.carta_acordo_id, 'BV')), 0),
           nvl(SUM(item_pkg.valor_retornar(ic.item_id, ic.carta_acordo_id, 'TIP')), 0)
      INTO v_valor_bv_com_ca,
           v_valor_tip_com_ca
      FROM item_carta ic
     WHERE ic.item_id = p_item_id;
   ELSIF v_valor_ckpend = 0
   THEN
    -- item c/ cartas acordo com check-in completo ou item de B/C sem carta acordo.
    -- Vale o que foi reateado nas NFs das cartas acordo.
    SELECT nvl(SUM(valor_bv), 0),
           nvl(SUM(valor_tip), 0)
      INTO v_valor_bv_com_ca,
           v_valor_tip_com_ca
      FROM item_nota
     WHERE item_id = p_item_id
       AND carta_acordo_id IS NOT NULL;
   END IF;
   --
   -- pega valores de notas fiscais soltas (sem carta acordo).
   SELECT nvl(SUM(valor_bv), 0),
          nvl(SUM(valor_tip), 0)
     INTO v_valor_bv_com_nf,
          v_valor_tip_com_nf
     FROM item_nota
    WHERE item_id = p_item_id
      AND carta_acordo_id IS NULL;
   --
   IF p_tipo_valor = 'BV'
   THEN
    v_retorno := v_valor_bv_com_ca + v_valor_bv_com_nf;
   ELSIF p_tipo_valor = 'TIP'
   THEN
    v_retorno := v_valor_tip_com_ca + v_valor_tip_com_nf;
   END IF;
  END IF; -- fim do IF p_tipo_valor IN ('BV','TIP')
  --
  IF p_tipo_valor IN ('BV_NFE', 'TIP_NFE')
  THEN
   -- retorna apenas os valores que tem nota fiscal de entrada
   SELECT nvl(SUM(valor_bv), 0),
          nvl(SUM(valor_tip), 0)
     INTO v_valor_bv_com_nf,
          v_valor_tip_com_nf
     FROM item_nota
    WHERE item_id = p_item_id;
   --
   IF p_tipo_valor = 'BV_NFE'
   THEN
    v_retorno := v_valor_bv_com_nf;
   ELSIF p_tipo_valor = 'TIP_NFE'
   THEN
    v_retorno := v_valor_tip_com_nf;
   END IF;
  END IF;
  --
  IF p_tipo_valor IN ('BV_NFS', 'TIP_NFS')
  THEN
   -- retorna apenas os valores que tem nota fiscal de saida
   SELECT nvl(SUM(io.valor_bv), 0),
          nvl(SUM(io.valor_tip), 0)
     INTO v_valor_bv_com_nf,
          v_valor_tip_com_nf
     FROM item_nota   io,
          item_fatur  ia,
          faturamento fa
    WHERE io.item_id = p_item_id
      AND io.item_id = ia.item_id
      AND io.nota_fiscal_id = ia.nota_fiscal_id
      AND ia.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'S'
      AND fa.nota_fiscal_sai_id IS NOT NULL;
   --
   IF p_tipo_valor = 'BV_NFS'
   THEN
    v_retorno := v_valor_bv_com_nf;
   ELSIF p_tipo_valor = 'TIP_NFS'
   THEN
    v_retorno := v_valor_tip_com_nf;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_utilizado_retornar;
 --
 --
 FUNCTION valor_reservado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor já comprometido de um determinado item, seja via carta
  --    acordo, nota fiscal solta ou sobra.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/04/2008  Tratamento de sobras.
  -- Silvia            21/01/2015  Tratamento de adiantamento.
  -- Silvia            30/10/2020  Tratamento de flag_dentro_ca (sobra)
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                   INTEGER;
  v_retorno              NUMBER;
  v_exception            EXCEPTION;
  v_valor_aprov_com_nf   NUMBER;
  v_valor_fornec_com_nf  NUMBER;
  v_valor_bv_com_nf      NUMBER;
  v_valor_tip_com_nf     NUMBER;
  v_valor_aprov_com_ca   NUMBER;
  v_valor_fornec_com_ca  NUMBER;
  v_valor_bv_com_ca      NUMBER;
  v_valor_tip_com_ca     NUMBER;
  v_valor_sobras_parcial NUMBER;
  v_valor_adiant_efetivo NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN ('APROVADO', 'FORNECEDOR', 'BV', 'TIP') OR TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(SUM(valor_aprovado), 0),
         nvl(SUM(valor_fornecedor), 0),
         nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0)
    INTO v_valor_aprov_com_nf,
         v_valor_fornec_com_nf,
         v_valor_bv_com_nf,
         v_valor_tip_com_nf
    FROM item_nota
   WHERE item_id = p_item_id
     AND carta_acordo_id IS NULL;
  --
  SELECT nvl(SUM(ic.valor_aprovado), 0),
         nvl(SUM(ic.valor_fornecedor), 0),
         nvl(SUM(item_pkg.valor_retornar(ic.item_id, ic.carta_acordo_id, 'BV')), 0),
         nvl(SUM(item_pkg.valor_retornar(ic.item_id, ic.carta_acordo_id, 'TIP')), 0)
    INTO v_valor_aprov_com_ca,
         v_valor_fornec_com_ca,
         v_valor_bv_com_ca,
         v_valor_tip_com_ca
    FROM item_carta ic
   WHERE ic.item_id = p_item_id;
  --
  -- pega apenas as sobras puras do item, pois as sobras de carta
  -- acordo já estão embutitas no valor aprovado da carta
  SELECT nvl(SUM(valor_sobra_item), 0)
    INTO v_valor_sobras_parcial
    FROM item_sobra it,
         sobra      so
   WHERE it.item_id = p_item_id
     AND it.sobra_id = so.sobra_id
        --AND so.carta_acordo_id IS NULL
     AND so.flag_dentro_ca = 'N';
  --
  SELECT nvl(SUM(decode(ad.status, 'ENCE', it.valor_despesa, it.valor_solicitado)), 0)
    INTO v_valor_adiant_efetivo
    FROM item_adiant it,
         adiant_desp ad
   WHERE it.item_id = p_item_id
     AND it.adiant_desp_id = ad.adiant_desp_id;
  --
  IF p_tipo_valor = 'APROVADO'
  THEN
   v_retorno := v_valor_aprov_com_nf + v_valor_aprov_com_ca + v_valor_sobras_parcial +
                v_valor_adiant_efetivo;
  ELSIF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornec_com_nf + v_valor_fornec_com_ca + v_valor_sobras_parcial +
                v_valor_adiant_efetivo;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := v_valor_bv_com_nf + v_valor_bv_com_ca;
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := v_valor_tip_com_nf + v_valor_tip_com_ca;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_reservado_retornar;
 --
 --
 FUNCTION valor_liberado_b_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/05/2020
  -- DESCRICAO: retorna o valor de um determinado item de B que está liberado para
  --  emissoa de carta acordo, nota fiscal solta ou adiantamento de despesa (por conta de
  -- vinculo com o faturamento realizado).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         11/12/2023  inclusão do parametro PERMITIR_FATUR_A_SEM_CA
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN NUMBER AS
  v_qt                          INTEGER;
  v_retorno                     NUMBER;
  v_exception                   EXCEPTION;
  v_valor_aprovado              item.valor_aprovado%TYPE;
  v_tipo_item                   item.tipo_item%TYPE;
  v_natureza_item               item.natureza_item%TYPE;
  v_valor_com_nf                NUMBER;
  v_valor_com_ca                NUMBER;
  v_valor_com_adiant            NUMBER;
  v_valor_com_fatur             NUMBER;
  v_flag_obriga_fatur_b         VARCHAR2(10);
  v_flag_permite_fatur_a_sem_ca VARCHAR2(10);
  v_empresa_id                  empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT jo.empresa_id,
         it.valor_aprovado,
         it.tipo_item,
         it.natureza_item
    INTO v_empresa_id,
         v_valor_aprovado,
         v_tipo_item,
         v_natureza_item
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id;
  --
  v_flag_obriga_fatur_b         := empresa_pkg.parametro_retornar(v_empresa_id,
                                                                  'FLAG_OBRIGA_FATUR_B');
  v_flag_permite_fatur_a_sem_ca := empresa_pkg.parametro_retornar(v_empresa_id,
                                                                  'PERMITIR_FATUR_A_SEM_CA');
  --
  IF v_tipo_item <> 'B' OR v_natureza_item <> 'CUSTO'
  THEN
   -- essa fncao nao faz sentido para demais itens
   v_retorno := 0;
  ELSIF v_flag_obriga_fatur_b = 'N' OR v_flag_permite_fatur_a_sem_ca = 'S'
  THEN
   -- as despesas/custos do item de B nao dependem do faturamento.
   -- todo o valor do item eh liberado
   v_retorno := v_valor_aprovado;
  ELSE
   -- o valor liberado depende do valor ja faturado
   SELECT nvl(SUM(it.valor_fatura), 0)
     INTO v_valor_com_fatur
     FROM item_fatur  it,
          faturamento fa
    WHERE it.item_id = p_item_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'N';
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_com_nf
     FROM item_nota
    WHERE item_id = p_item_id
      AND carta_acordo_id IS NULL;
   --
   SELECT nvl(SUM(ic.valor_aprovado), 0)
     INTO v_valor_com_ca
     FROM item_carta ic
    WHERE ic.item_id = p_item_id;
   --
   SELECT nvl(SUM(decode(ad.status, 'ENCE', it.valor_despesa, it.valor_solicitado)), 0)
     INTO v_valor_com_adiant
     FROM item_adiant it,
          adiant_desp ad
    WHERE it.item_id = p_item_id
      AND it.adiant_desp_id = ad.adiant_desp_id;
   --
   v_retorno := v_valor_com_fatur - (v_valor_com_nf + v_valor_com_ca + v_valor_com_adiant);
   --
   IF v_retorno < 0
   THEN
    v_retorno := 0;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_liberado_b_retornar;
 --
 --
 FUNCTION valor_disponivel_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor ainda nao comprometido de um determinado item de natureza
  --  CUSTO (nao faz sentido para as demais naturezas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         11/07/2025  Tratamento para quando LIMITAR_ORCAM_FORNEC ligado
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt               INTEGER;
  v_retorno          NUMBER;
  v_exception        EXCEPTION;
  v_valor_aprovado   NUMBER;
  v_valor_fornecedor NUMBER;
  v_valor_reservado  NUMBER;
  --
  v_empresa_id           NUMBER;
  v_valor_disponivel     item.valor_disponivel%TYPE;
  v_limitar_orcam_fornec CHAR(1);
  --
 BEGIN
  v_retorno := 0;
  --ALCBO_110725
  SELECT empresa_id
    INTO v_empresa_id
    FROM job
   WHERE job_id IN (SELECT job_id
                      FROM item
                     WHERE item_id = p_item_id);
  --
  v_limitar_orcam_fornec := empresa_pkg.parametro_retornar(v_empresa_id, 'LIMITAR_ORCAM_FORNEC');
  --
  IF p_tipo_valor NOT IN ('APROVADO', 'FORNECEDOR') OR TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  v_valor_reservado := item_pkg.valor_reservado_retornar(p_item_id, p_tipo_valor);
  --
  SELECT valor_aprovado,
         valor_fornecedor
    INTO v_valor_aprovado,
         v_valor_fornecedor
    FROM item
   WHERE item_id = p_item_id;
  --
  IF p_tipo_valor = 'APROVADO'
  THEN
   --ALCBO_110725
   IF v_limitar_orcam_fornec = 'S'
   THEN
    v_retorno := v_valor_fornecedor - v_valor_reservado;
   ELSE
    v_retorno := v_valor_aprovado - v_valor_reservado;
   END IF;
  ELSIF p_tipo_valor = 'FORNECEDOR'
  THEN
   v_retorno := v_valor_fornecedor - v_valor_reservado;
   --
   IF v_retorno < 0
   THEN
    -- o valor de fornecedor definido no item nao reflete o que foi
    -- lancado em cartas acordo ou notas fiscais. Assume o saldo
    -- de fornecedor igual ao saldo do valor aprovado.
    v_retorno := v_valor_aprovado - v_valor_reservado;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_disponivel_retornar;
 --
 --
 FUNCTION valor_na_nf_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor de um determinado item ou carta acordo, já lancado numa
  --  determinada nota fiscal.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id  IN nota_fiscal.nota_fiscal_id%TYPE
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF nvl(p_carta_acordo_id, 0) = 0
  THEN
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_retorno
     FROM item_nota
    WHERE item_id = p_item_id
      AND nota_fiscal_id = p_nota_fiscal_id;
  ELSE
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_retorno
     FROM item_nota
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = p_item_id
      AND nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_na_nf_retornar;
 --
 --
 FUNCTION valor_checkin_pend_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2007
  -- DESCRICAO: retorna o valor pendente de check-in de um determinado item.
  --   Para itens de A, a pendencia é calculada considerando o valor total do item, mesmo
  --   nao existindo carta acordo.
  --   Para itens de B/C considera apenas a parte que tem carta acordo sem check-in.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/03/2008  Tratamento das sobras.
  -- Silvia            21/01/2015  Tratamento de adiantamento.
  -- Silvia            30/10/2020  Tratamento de flag_dentro_ca (sobra)
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN NUMBER AS
  v_retorno              NUMBER;
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_valor_aprov          NUMBER;
  v_valor_checado        NUMBER;
  v_valor_sobras         NUMBER;
  v_tipo_item            item.tipo_item%TYPE;
  v_valor_adiant_efetivo NUMBER;
  v_permitir_sobra_a     VARCHAR2(1);
  v_empresa_id           empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno              := 0;
  v_valor_aprov          := 0;
  v_valor_checado        := 0;
  v_valor_sobras         := 0;
  v_valor_adiant_efetivo := 0;
  --
  SELECT j.empresa_id
    INTO v_empresa_id
    FROM item i
   INNER JOIN job j
      ON j.job_id = i.job_id
   WHERE i.item_id = p_item_id;
  --
  v_permitir_sobra_a := empresa_pkg.parametro_retornar(v_empresa_id, 'PERMITIR_SOBRA_A');
  --
  SELECT tipo_item
    INTO v_tipo_item
    FROM item
   WHERE item_id = p_item_id;
  --
  ---------------------------------------------
  -- recuperacao dos valores aprovados e sobras
  ---------------------------------------------
  IF v_tipo_item = 'A' AND v_permitir_sobra_a = 'N'
  THEN
   -- valor a checar de A (desde que o item seja CUSTO, independente da
   -- existencia de carta acordo)
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_aprov
     FROM item
    WHERE item_id = p_item_id
      AND flag_sem_valor = 'N'
      AND natureza_item = 'CUSTO';
   --
   -- valor de sobras de A (independente da existencia de carta acordo)
   SELECT nvl(SUM(valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra
    WHERE item_id = p_item_id;
  ELSE
   -- valor a checar de B ou C (desde que o item seja CUSTO, e que exista
   -- carta acordo)
   SELECT nvl(SUM(ic.valor_aprovado), 0)
     INTO v_valor_aprov
     FROM item       it,
          item_carta ic
    WHERE it.item_id = p_item_id
      AND it.flag_sem_valor = 'N'
      AND it.natureza_item = 'CUSTO'
      AND it.item_id = ic.item_id;
   --
   -- valor de sobras de B/C (desde que dentro da carta acordo)
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id
         --AND so.carta_acordo_id IS NOT NULL
      AND so.flag_dentro_ca = 'S';
   --
   SELECT nvl(SUM(decode(ad.status, 'ENCE', it.valor_despesa, it.valor_solicitado)), 0)
     INTO v_valor_adiant_efetivo
     FROM item_adiant it,
          adiant_desp ad
    WHERE it.item_id = p_item_id
      AND it.adiant_desp_id = ad.adiant_desp_id;
  END IF;
  --
  ------------------------------------------
  -- recuperacao dos valores checados
  -- (apenas notas c/ carta acordo. Notas de
  -- B e C soltas nao sao consideradas).
  ------------------------------------------
  SELECT nvl(SUM(io.valor_aprovado), 0)
    INTO v_valor_checado
    FROM item      it,
         item_nota io
   WHERE it.item_id = p_item_id
     AND it.flag_sem_valor = 'N'
     AND it.item_id = io.item_id
     AND io.carta_acordo_id IS NOT NULL;
  --
  v_retorno := v_valor_aprov - v_valor_checado - v_valor_sobras - v_valor_adiant_efetivo;
  --
  IF v_retorno < 0
  THEN
   -- itens de B,C sem carta acordo (sem valor a checar), com sobras ou com adiant desp.
   v_retorno := 0;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99998;
   RETURN v_retorno;
 END valor_checkin_pend_retornar;
 --
 --
 FUNCTION valor_realizado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor realizado de um determinado item , de acordo
  --  com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id    IN item.item_id%TYPE,
  p_tipo_valor IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                INTEGER;
  v_retorno           NUMBER;
  v_exception         EXCEPTION;
  v_valor_faturado    NUMBER;
  v_valor_pago_fornec NUMBER;
  v_valor_bv          NUMBER;
  v_valor_tip         NUMBER;
  v_flag_pago_cliente item.flag_pago_cliente%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN ('FATURADO', 'PAGO_FORNEC', 'BV', 'TIP', 'RENTAB') OR
     TRIM(p_tipo_valor) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT flag_pago_cliente
    INTO v_flag_pago_cliente
    FROM item
   WHERE item_id = p_item_id;
  --
  SELECT nvl(SUM(it.valor_fatura), 0)
    INTO v_valor_faturado
    FROM item_fatur  it,
         faturamento fa
   WHERE it.item_id = p_item_id
     AND it.faturamento_id = fa.faturamento_id
     AND fa.flag_bv = 'N';
  --
  SELECT nvl(SUM(it.valor_aprovado), 0),
         nvl(SUM(it.valor_bv), 0),
         nvl(SUM(it.valor_tip), 0)
    INTO v_valor_pago_fornec,
         v_valor_bv,
         v_valor_tip
    FROM item_nota   it,
         nota_fiscal nf
   WHERE it.item_id = p_item_id
     AND it.nota_fiscal_id = nf.nota_fiscal_id
     AND nf.tipo_ent_sai = 'E'
     AND nf.status <> 'CHECKIN_PEND';
  --AND nf.status IN ('FATUR_LIB','CONC');
  --
  IF p_tipo_valor = 'FATURADO'
  THEN
   IF v_flag_pago_cliente = 'S'
   THEN
    v_retorno := 0;
   ELSE
    v_retorno := v_valor_faturado;
   END IF;
  ELSIF p_tipo_valor = 'PAGO_FORNEC'
  THEN
   IF v_flag_pago_cliente = 'S'
   THEN
    v_retorno := 0;
   ELSE
    v_retorno := v_valor_pago_fornec;
   END IF;
  ELSIF p_tipo_valor = 'BV'
  THEN
   v_retorno := v_valor_bv;
  ELSIF p_tipo_valor = 'TIP'
  THEN
   v_retorno := v_valor_tip;
  ELSIF p_tipo_valor = 'RENTAB'
  THEN
   IF v_flag_pago_cliente = 'S'
   THEN
    v_retorno := v_valor_bv + v_valor_tip;
   ELSE
    v_retorno := v_valor_faturado - v_valor_pago_fornec + v_valor_bv + v_valor_tip;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_realizado_retornar;
 --
 --
 FUNCTION parcelado_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/01/2008
  -- DESCRICAO: verifica se o item está parcelado. Retorna 1 caso sim e 0 caso nao.
  --   Serve apenas p/ itens de natureza CUSTO (para os demais, retorna sempre 1).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN INTEGER AS
  v_qt              INTEGER;
  v_retorno         INTEGER;
  v_tipo_item       item.tipo_item%TYPE;
  v_natureza_item   item.natureza_item%TYPE;
  v_valor_aprovado  item.valor_aprovado%TYPE;
  v_valor_parcelado item.valor_aprovado%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT tipo_item,
         natureza_item,
         nvl(valor_aprovado, 0)
    INTO v_tipo_item,
         v_natureza_item,
         v_valor_aprovado
    FROM item
   WHERE item_id = p_item_id;
  --
  IF v_natureza_item = 'CUSTO'
  THEN
   SELECT nvl(SUM(valor_parcela), 0)
     INTO v_valor_parcelado
     FROM parcela
    WHERE item_id = p_item_id
      AND tipo_parcela = 'CLI';
   --
   IF v_valor_aprovado = v_valor_parcelado
   THEN
    v_retorno := 1;
   END IF;
  ELSE
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END parcelado_verificar;
 --
 --
 FUNCTION qtd_carta_acordo_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: retorna a qtd de cartas acordo relacionadas a um determinado item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN INTEGER AS
  v_qt      INTEGER;
  v_retorno INTEGER;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT COUNT(DISTINCT carta_acordo_id)
    INTO v_retorno
    FROM item_carta
   WHERE item_id = p_item_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END qtd_carta_acordo_retornar;
 --
 --
 FUNCTION carta_acordo_ok_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: para itens de A (natureza CUSTO), verifica se o item está com as cartas
  --   acordo ja definidas e emitidas. Para B e C verifica apenas a pendencia de emissao,
  --   no caso de haver carta acordo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/04/2008  Tratamento de sobras.
  -- Silvia            05/02/2009  Implementacao de status da CA (p/ aprovacao de orcam).
  -- Silvia            30/10/2020  Tratamento de flag_dentro_ca (sobra)
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN INTEGER AS
  v_qt                        INTEGER;
  v_retorno                   INTEGER;
  v_tipo_item                 item.tipo_item%TYPE;
  v_natureza_item             item.natureza_item%TYPE;
  v_valor_aprovado_it         item.valor_aprovado%TYPE;
  v_valor_aprovado_ca         item.valor_aprovado%TYPE;
  v_valor_sobras_parcial      NUMBER;
  v_permitir_checkin_a_sem_ca VARCHAR2(1);
  v_empresa_id                empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT j.empresa_id
    INTO v_empresa_id
    FROM item i
   INNER JOIN orcamento o
      ON o.orcamento_id = i.orcamento_id
   INNER JOIN job j
      ON j.job_id = o.job_id
   WHERE i.item_id = p_item_id;
  --
  v_permitir_checkin_a_sem_ca := empresa_pkg.parametro_retornar(v_empresa_id,
                                                                'PERMITIR_CHECKIN_A_SEM_CA');
  --
  SELECT tipo_item,
         natureza_item,
         nvl(valor_aprovado, 0)
    INTO v_tipo_item,
         v_natureza_item,
         v_valor_aprovado_it
    FROM item
   WHERE item_id = p_item_id;
  --
  IF v_tipo_item = 'A' AND v_natureza_item = 'CUSTO' AND v_permitir_checkin_a_sem_ca = 'N'
  THEN
   SELECT nvl(SUM(ic.valor_aprovado), 0)
     INTO v_valor_aprovado_ca
     FROM item_carta   ic,
          carta_acordo ca
    WHERE ic.item_id = p_item_id
      AND ic.carta_acordo_id = ca.carta_acordo_id
      AND ca.status = 'EMITIDA';
   --
   -- recupera as sobras puras do item, sem levar em conta
   -- as sobras da carta acordo.
   SELECT nvl(SUM(it.valor_sobra_item), 0)
     INTO v_valor_sobras_parcial
     FROM item_sobra it,
          sobra      so
    WHERE it.item_id = p_item_id
      AND it.sobra_id = so.sobra_id
         -- AND so.carta_acordo_id IS NULL
      AND so.flag_dentro_ca = 'N';
   --
   -- verifica se todas as cartas do item foram emitidas e se a somatoria
   -- dos valores das cartas bate com o valor aprovado do item.
   IF v_valor_aprovado_it = v_valor_aprovado_ca + v_valor_sobras_parcial
   THEN
    v_retorno := 1;
   END IF;
  ELSIF v_natureza_item = 'CUSTO'
  THEN
   -- para B e C, verifica apenas se existem cartas com emissao pendente
   -- para A aceitando checkin em A sem carta acordo, mesmo tratamento
   SELECT COUNT(*)
     INTO v_qt
     FROM item_carta   ic,
          carta_acordo ca
    WHERE ic.item_id = p_item_id
      AND ic.carta_acordo_id = ca.carta_acordo_id
      AND ca.status <> 'EMITIDA';
   --
   IF v_qt = 0
   THEN
    v_retorno := 1;
   END IF;
  ELSE
   --para naturezas não CUSTO
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END carta_acordo_ok_verificar;
 --
 --
 FUNCTION nome_item_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/05/2014
  -- DESCRICAO: retorna o nome completo do item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id IN item.item_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt        INTEGER;
  v_nome_item VARCHAR2(4000);
  --
 BEGIN
  v_nome_item := NULL;
  --
  SELECT TRIM(tp.nome || ' ' || it.complemento)
    INTO v_nome_item
    FROM item         it,
         tipo_produto tp
   WHERE it.item_id = p_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  RETURN v_nome_item;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_nome_item := 'ERRO';
   RETURN v_nome_item;
 END nome_item_retornar;
 --
 --
 FUNCTION num_item_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/02/2007
  -- DESCRICAO: retorna o numero do item concatenado com o numero do orcamento e com o
  --   numero do job (caso o parametro p_flag_com_job seja 'S').
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_id      IN item.item_id%TYPE,
  p_flag_com_job IN VARCHAR2
 ) RETURN VARCHAR2 AS
  v_qt            INTEGER;
  v_nome_item     VARCHAR2(100);
  v_natureza_item VARCHAR2(50);
  v_num_job       job.numero%TYPE;
  --
 BEGIN
  v_nome_item := NULL;
  --
  SELECT orcamento_pkg.numero_formatar2(it.orcamento_id) || '.' || it.tipo_item ||
         to_char(it.num_seq),
         decode(it.natureza_item,
                'ENCARGO',
                'ENCARGO-CUSTO',
                'ENCARGO_HONOR',
                'ENCARGO-HONOR',
                'HONOR',
                'HONORARIO',
                it.natureza_item),
         jo.numero
    INTO v_nome_item,
         v_natureza_item,
         v_num_job
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id;
  --
  IF v_natureza_item <> 'CUSTO'
  THEN
   v_nome_item := v_nome_item || '.' || v_natureza_item;
  END IF;
  --
  IF p_flag_com_job = 'S'
  THEN
   v_nome_item := to_char(v_num_job) || '.' || v_nome_item;
  END IF;
  --
  RETURN v_nome_item;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_nome_item := 'ERRO';
   RETURN v_nome_item;
 END num_item_retornar;
 --
--
END; -- ITEM_PKG

/
