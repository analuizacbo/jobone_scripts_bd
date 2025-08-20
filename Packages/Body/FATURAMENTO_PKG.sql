--------------------------------------------------------
--  DDL for Package Body FATURAMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "FATURAMENTO_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: Comanda o faturamento dos itens/cartas acordo passados nos vetores.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            05/08/2008  Ajustes em consistencias de receita e patrocinio.
  -- Silvia            02/09/2009  Nao deixa faturar pela 100% Incentivo
  -- Silvia            04/08/2011  Novo parametro cod_natureza_oper.
  -- Silvia            26/04/2013  Desconto de abatimento no calculo do valor_liberado.
  -- Silvia            30/03/2015  Novos parametros municipio_servico, uf_servico.
  -- Silvia            11/06/2015  Novo parametro produto_cliente_id
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            11/04/2019  Novo atributo ordem_compra
  -- Silvia            26/02/2021  Novo parametro para usar ou nao data vencim
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_job_id                IN faturamento.job_id%TYPE,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_carta_acordo_id IN VARCHAR2,
  p_vetor_nota_fiscal_id  IN VARCHAR2,
  p_vetor_valor_fatura    IN VARCHAR2,
  p_emp_faturar_por_id    IN faturamento.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper     IN faturamento.cod_natureza_oper%TYPE,
  p_ordem_compra          IN faturamento.ordem_compra%TYPE,
  p_cliente_id            IN faturamento.cliente_id%TYPE,
  p_contato_cli_id        IN faturamento.contato_cli_id%TYPE,
  p_produto_cliente_id    IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim           IN VARCHAR2,
  p_num_parcela           IN VARCHAR2,
  p_descricao             IN VARCHAR2,
  p_obs                   IN VARCHAR2,
  p_flag_patrocinio       IN VARCHAR2,
  p_flag_outras_receitas  IN VARCHAR2,
  p_tipo_receita          IN VARCHAR2,
  p_municipio_servico     IN nota_fiscal.municipio_servico%TYPE,
  p_uf_servico            IN nota_fiscal.uf_servico%TYPE,
  p_faturamento_id        OUT faturamento.faturamento_id%TYPE,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_numero_job            job.numero%TYPE;
  v_faturamento_id        faturamento.faturamento_id%TYPE;
  v_data_vencim           faturamento.data_vencim%TYPE;
  v_flag_bv               faturamento.flag_bv%TYPE;
  v_valor_total           NUMBER;
  v_delimitador           CHAR(1);
  v_vetor_item_id         VARCHAR2(4000);
  v_vetor_carta_acordo_id VARCHAR2(4000);
  v_vetor_nota_fiscal_id  VARCHAR2(4000);
  v_vetor_valor_fatura    VARCHAR2(4000);
  v_valor_fatura_char     VARCHAR2(20);
  v_valor_fatura          item_fatur.valor_fatura%TYPE;
  v_valor_a_faturar       item_fatur.valor_fatura%TYPE;
  v_item_id               item_fatur.item_id%TYPE;
  v_carta_acordo_id       item_fatur.carta_acordo_id%TYPE;
  v_nota_fiscal_id        nota_fiscal.nota_fiscal_id%TYPE;
  v_resp_pgto_receita     nota_fiscal.resp_pgto_receita%TYPE;
  v_emp_receita_id        nota_fiscal.emp_receita_id%TYPE;
  v_num_doc_nf            nota_fiscal.num_doc%TYPE;
  v_flag_item_patrocinado nota_fiscal.flag_item_patrocinado%TYPE;
  v_nf_cliente_id         nota_fiscal.cliente_id%TYPE;
  v_emp_receita_nome      pessoa.nome%TYPE;
  v_nf_cliente_nome       pessoa.nome%TYPE;
  v_flag_emp_incentivo    pessoa.flag_emp_incentivo%TYPE;
  v_valor_liberado        NUMBER;
  v_tipo_item             item.tipo_item%TYPE;
  v_nome_item             VARCHAR2(100);
  v_job_id                job.job_id%TYPE;
  v_tem_item_comum        INTEGER;
  v_tem_item_patroc       INTEGER;
  v_tem_item_receita      INTEGER;
  v_lbl_job               VARCHAR2(100);
  v_lbl_prodcli           VARCHAR2(100);
  v_xml_atual             CLOB;
  v_num_parcela           NUMBER(10);
  v_flag_usar_data        VARCHAR2(10);
  --
 BEGIN
  v_qt                   := 0;
  p_faturamento_id       := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_usar_data       := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_DATA_VENCIM_FATUR');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FATURAMENTO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_cliente_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_cliente_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE produto_cliente_id = p_produto_cliente_id
      AND pessoa_id = p_cliente_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_data_vencim) IS NULL AND v_flag_usar_data = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_vencim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_parcela) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da parcela inválido (' || p_num_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_parcela := to_number(p_num_parcela);
  --
  IF v_num_parcela < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da parcela inválido (' || p_num_parcela || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa a faturar é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id
     AND flag_emp_fatur = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_natureza_oper) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da natureza de operação para faturamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE pessoa_id = p_emp_faturar_por_id
     AND codigo = p_cod_natureza_oper;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Natureza de operação para faturamento inválida (' || p_cod_natureza_oper || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_ordem_compra)) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número da Ordem de Compra não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_bv
    INTO v_flag_bv
    FROM natureza_oper_fatur
   WHERE pessoa_id = p_emp_faturar_por_id
     AND codigo = p_cod_natureza_oper;
  --
  SELECT flag_emp_incentivo
    INTO v_flag_emp_incentivo
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id;
  --
  IF v_flag_emp_incentivo = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A empresa 100% Incentivo não pode ser usada para faturamento.';
   RAISE v_exception;
  END IF;
  --
  v_data_vencim := data_converter(p_data_vencim);
  --
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_patrocinio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag patrocínio inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_outras_receitas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag outras receitas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL THEN
   -- o tipo de receita foi especificado
   IF util_pkg.desc_retornar('tipo_receita', p_tipo_receita) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de receita inválida (' || p_tipo_receita || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_outras_receitas = 'N' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Um tipo de receita foi especificado mas a opção de ' ||
                  'Outras Receitas não está marcada.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_patrocinio = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível selecionar patrocínio e outras receitas ' || 'ao mesmo tempo.';
    RAISE v_exception;
   END IF;
  ELSE
   -- o tipo de receita nao foi especificado
   IF p_flag_outras_receitas = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A opção de Outras Receitas está marcada mas nenhum ' ||
                  'tipo de receita foi especificado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF (TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NULL) OR
     (TRIM(p_uf_servico) IS NULL AND TRIM(p_municipio_servico) IS NOT NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O local da prestação de serviço está incompleto.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_uf_servico) IS NOT NULL AND TRIM(p_municipio_servico) IS NOT NULL THEN
   IF cep_pkg.municipio_validar(p_uf_servico, p_municipio_servico) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Município do local da prestação de serviço inválido (' || p_uf_servico || '/' ||
                  p_municipio_servico || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT numero
    INTO v_numero_job
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_faturamento.nextval
    INTO v_faturamento_id
    FROM dual;
  --
  INSERT INTO faturamento
   (faturamento_id,
    job_id,
    emp_faturar_por_id,
    cliente_id,
    contato_cli_id,
    produto_cliente_id,
    usuario_fatur_id,
    data_vencim,
    data_ordem,
    descricao,
    obs,
    cod_natureza_oper,
    flag_patrocinio,
    tipo_receita,
    flag_bv,
    municipio_servico,
    uf_servico,
    ordem_compra,
    num_parcela)
  VALUES
   (v_faturamento_id,
    p_job_id,
    p_emp_faturar_por_id,
    p_cliente_id,
    zvl(p_contato_cli_id, NULL),
    zvl(p_produto_cliente_id, NULL),
    p_usuario_sessao_id,
    v_data_vencim,
    trunc(SYSDATE),
    TRIM(p_descricao),
    TRIM(p_obs),
    TRIM(p_cod_natureza_oper),
    p_flag_patrocinio,
    TRIM(p_tipo_receita),
    v_flag_bv,
    TRIM(p_municipio_servico),
    TRIM(p_uf_servico),
    TRIM(p_ordem_compra),
    v_num_parcela);
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_tem_item_comum   := 0;
  v_tem_item_patroc  := 0;
  v_tem_item_receita := 0;
  --
  v_valor_total           := 0;
  v_delimitador           := '|';
  v_vetor_item_id         := p_vetor_item_id;
  v_vetor_carta_acordo_id := p_vetor_carta_acordo_id;
  v_vetor_nota_fiscal_id  := p_vetor_nota_fiscal_id;
  v_vetor_valor_fatura    := p_vetor_valor_fatura;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id           := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_carta_acordo_id   := nvl(to_number(prox_valor_retornar(v_vetor_carta_acordo_id, v_delimitador)),
                              0);
   v_nota_fiscal_id    := nvl(to_number(prox_valor_retornar(v_vetor_nota_fiscal_id, v_delimitador)),
                              0);
   v_valor_fatura_char := prox_valor_retornar(v_vetor_valor_fatura, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item
    WHERE item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT it.tipo_item,
          item_pkg.num_item_retornar(it.item_id, 'N'),
          oc.job_id
     INTO v_tipo_item,
          v_nome_item,
          v_job_id
     FROM item      it,
          orcamento oc
    WHERE it.item_id = v_item_id
      AND it.orcamento_id = oc.orcamento_id;
   --
   IF v_job_id <> p_job_id THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não pertence a esse ' || v_lbl_job || ' (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_carta_acordo_id > 0 THEN
    SELECT nvl(MAX(job_id), 0)
      INTO v_job_id
      FROM carta_acordo
     WHERE carta_acordo_id = v_carta_acordo_id;
    --
    IF v_job_id <> p_job_id THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa carta acordo não pertence a esse ' || v_lbl_job || ' (' ||
                   to_char(v_carta_acordo_id) || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_valor_fatura_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor a faturar inválido (' || v_valor_fatura_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_fatura := nvl(moeda_converter(v_valor_fatura_char), 0);
   --
   IF v_valor_fatura < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor a faturar inválido (' || v_valor_fatura_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_a_faturar := faturamento_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'AFATURAR');
   --
   IF v_valor_fatura > v_valor_a_faturar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor que está sendo faturado (' || moeda_mostrar(v_valor_fatura, 'S') ||
                  ') não pode exceder o restante a faturar (' ||
                  moeda_mostrar(v_valor_a_faturar, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------
   -- tratamento p/ itens acompanhados de NF
   ------------------------------------------
   IF v_nota_fiscal_id > 0 AND v_valor_fatura > 0 THEN
    v_valor_liberado := item_pkg.valor_na_nf_retornar(v_item_id,
                                                      v_carta_acordo_id,
                                                      v_nota_fiscal_id);
    /*
    v_valor_liberado := item_pkg.valor_na_nf_retornar(v_item_id, v_carta_acordo_id, v_nota_fiscal_id) - 
                        item_pkg.valor_retornar(v_item_id, v_carta_acordo_id, 'ABAT');*/
    --
    IF v_tipo_item = 'A' AND v_valor_fatura <> v_valor_liberado THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor que está sendo faturado (' || moeda_mostrar(v_valor_fatura, 'S') ||
                   ') deve corresponder ao valor cheio do item na nota fiscal (' ||
                   moeda_mostrar(v_valor_liberado, 'S') || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_tipo_item <> 'A' AND v_valor_fatura < v_valor_liberado THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O valor que está sendo faturado (' || moeda_mostrar(v_valor_fatura, 'S') ||
                   ') deve ser maior ou igual ao valor cheio do item na nota fiscal (' ||
                   moeda_mostrar(v_valor_liberado, 'S') || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT nf.resp_pgto_receita,
           nf.emp_receita_id,
           pr.apelido,
           nf.num_doc,
           nf.flag_item_patrocinado,
           nf.cliente_id,
           pp.apelido
      INTO v_resp_pgto_receita,
           v_emp_receita_id,
           v_emp_receita_nome,
           v_num_doc_nf,
           v_flag_item_patrocinado,
           v_nf_cliente_id,
           v_nf_cliente_nome
      FROM nota_fiscal nf,
           pessoa      pr,
           pessoa      pp
     WHERE nf.nota_fiscal_id = v_nota_fiscal_id
       AND nf.emp_receita_id = pr.pessoa_id(+)
       AND nf.cliente_id = pp.pessoa_id(+);
    --
    IF v_resp_pgto_receita = 'AGE' AND nvl(v_emp_receita_id, 0) <> p_cliente_id THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Como o item ' || v_nome_item || ' está associado a uma nota fiscal paga ' ||
                   'com receita gerada pela empresa ' || v_emp_receita_nome ||
                   ', o faturamento deve ser gerado contra essa empresa (' ||
                   moeda_mostrar(v_valor_fatura, 'S') || ' NF: ' || v_num_doc_nf || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_resp_pgto_receita = 'FON' THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Como o item ' || v_nome_item || ' está associado a uma nota fiscal paga ' ||
                   'com receita gerada diretamente pela empresa ' || v_emp_receita_nome ||
                   ', não se deve gerar faturamento contra essa empresa (' ||
                   moeda_mostrar(v_valor_fatura, 'S') || ' NF: ' || v_num_doc_nf || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_flag_item_patrocinado = 'S' AND nvl(v_nf_cliente_id, 0) <> p_cliente_id THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Como o item ' || v_nome_item || ' está associado a uma nota fiscal ' ||
                   'patrocinada pela empresa ' || v_nf_cliente_nome ||
                   ', o faturamento deve ser gerado contra essa empresa (' ||
                   moeda_mostrar(v_valor_fatura, 'S') || ' NF: ' || v_num_doc_nf || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_resp_pgto_receita IS NOT NULL THEN
     v_tem_item_receita := 1;
    ELSIF v_flag_item_patrocinado = 'S' THEN
     v_tem_item_patroc := 1;
    ELSE
     v_tem_item_comum := 1;
    END IF;
   END IF;
   --
   ------------------------------------------
   -- tratamento p/ itens sem NF
   ------------------------------------------
   IF v_nota_fiscal_id = 0 AND v_valor_fatura > 0 THEN
    v_tem_item_comum := 1;
   END IF;
   --
   ------------------------------------------
   -- inclusao do detalhe do faturamento
   ------------------------------------------
   IF v_valor_fatura > 0 THEN
    INSERT INTO item_fatur
     (item_fatur_id,
      item_id,
      faturamento_id,
      carta_acordo_id,
      nota_fiscal_id,
      valor_fatura)
    VALUES
     (seq_item_fatur.nextval,
      v_item_id,
      v_faturamento_id,
      zvl(v_carta_acordo_id, NULL),
      zvl(v_nota_fiscal_id, NULL),
      v_valor_fatura);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   v_valor_total := v_valor_total + v_valor_fatura;
  END LOOP;
  --
  IF v_valor_total = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor a faturar foi informado.';
   RAISE v_exception;
  END IF;
  --
  /*
  IF v_tem_item_receita + v_tem_item_patroc + v_tem_item_comum > 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não é possível agrupar num mesmo faturamento itens pagos ' ||
                   'com receita e/ou itens patrocinados com demais itens.';
     RAISE v_exception;
  END IF;
  */
  --
  IF v_tem_item_receita = 1 AND p_flag_patrocinio = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Honorários e encargos foram marcados como patrocinados, mas ' ||
                 'existem notas fiscais indicando receita.';
   RAISE v_exception;
  END IF;
  --
  IF v_tem_item_patroc = 1 AND p_flag_outras_receitas = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Honorários e encargos foram marcados como outras receitas, mas ' ||
                 'existem notas fiscais indicando patrocínio.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('FATURAMENTO_ADICIONAR',
                           p_empresa_id,
                           v_faturamento_id,
                           'JOB',
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
  faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_faturamento_id,
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
  p_faturamento_id := v_faturamento_id;
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
 END comandar;
 --
 --
 PROCEDURE bv_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: subrotina que comanda o faturamento de BV+TIP associados a uma determinada
  --   nota fiscal de entrada. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            18/01/2011  Novo atributo tipo_fatur_bv na NF.
  -- Silvia            04/08/2011  cod_natureza_oper passou a ser tabelado.
  -- Silvia            17/12/2012  geracao do evento de inclusao.
  -- Silvia            16/08/2013  antiga bv_comandar. Passou a ter um flag p/ comandar.
  -- Silvia            23/03/2018  Ajustes p/ aceitar job_id NULL na NF.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_nota_fiscal_id    IN nota_fiscal.nota_fiscal_id%TYPE,
  p_flag_comandar     IN VARCHAR2,
  p_faturamento_id    OUT faturamento.faturamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_job_id             job.job_id%TYPE;
  v_numero_job         job.numero%TYPE;
  v_cliente_id         pessoa.pessoa_id%TYPE;
  v_cli_apelido        pessoa.apelido%TYPE;
  v_cliente_ok         INTEGER;
  v_emp_faturar_por_id faturamento.emp_faturar_por_id%TYPE;
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  v_data_vencim        faturamento.data_vencim%TYPE;
  v_descricao          faturamento.descricao%TYPE;
  v_cod_natureza_oper  faturamento.cod_natureza_oper%TYPE;
  v_desc_natureza_oper natureza_oper_fatur.descricao%TYPE;
  v_valor_bv           NUMBER;
  v_valor_tip          NUMBER;
  v_valor_total        NUMBER;
  v_tipo_fatur_bv      item.tipo_fatur_bv%TYPE;
  v_num_dias_bv        INTEGER;
  v_flag_for_como_cli  VARCHAR(10);
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  --
  CURSOR c_itn IS
   SELECT item_id,
          carta_acordo_id,
          valor_bv,
          valor_tip
     FROM item_nota
    WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
 BEGIN
  v_qt             := 0;
  p_faturamento_id := 0;
  v_faturamento_id := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não exists (' || to_char(p_nota_fiscal_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(it.job_id)
    INTO v_job_id
    FROM item_nota io,
         item      it
   WHERE io.nota_fiscal_id = p_nota_fiscal_id
     AND io.item_id = it.item_id;
  --
  SELECT nf.emp_emissora_id,
         nf.desc_servico,
         nf.tipo_fatur_bv,
         nf.emp_faturar_por_id
    INTO v_cliente_id,
         v_descricao,
         v_tipo_fatur_bv,
         v_emp_faturar_por_id
    FROM nota_fiscal nf
   WHERE nf.nota_fiscal_id = p_nota_fiscal_id;
  --
  SELECT MAX(numero)
    INTO v_numero_job
    FROM job
   WHERE job_id = v_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa nota fiscal não pertence a essa empresa (' || to_char(p_empresa_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(codigo),
         MAX(descricao)
    INTO v_cod_natureza_oper,
         v_desc_natureza_oper
    FROM natureza_oper_fatur
   WHERE pessoa_id = v_emp_faturar_por_id
     AND flag_bv = 'S';
  --
  IF v_cod_natureza_oper IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe natureza de operação cadastrada para o faturamento de BV.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_comandar) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag comandar inválido.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se tem BV/TIP nos itens da nota
  SELECT nvl(SUM(valor_bv), 0),
         nvl(SUM(valor_tip), 0)
    INTO v_valor_bv,
         v_valor_tip
    FROM item_nota
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  v_valor_total := v_valor_bv + v_valor_tip;
  --
  v_num_dias_bv := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_BV')), 0);
  --
  SELECT nvl(MAX(data_vencim), trunc(SYSDATE))
    INTO v_data_vencim
    FROM duplicata
   WHERE nota_fiscal_id = p_nota_fiscal_id;
  --
  v_data_vencim := v_data_vencim + v_num_dias_bv;
  --
  -- verifica se a empresa emissora da NF (fornecedor) tb esta definido como
  -- cliente p/ poder faturar o BV.
  SELECT apelido,
         pessoa_pkg.tipo_verificar(pessoa_id, 'CLIENTE')
    INTO v_cli_apelido,
         v_cliente_ok
    FROM pessoa
   WHERE pessoa_id = v_cliente_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_valor_total > 0 AND v_tipo_fatur_bv = 'FAT' THEN
   IF v_emp_faturar_por_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não foi possível faturar o BV pois a empresa de faturamento não foi definida.';
    RAISE v_exception;
   END IF;
   --
   v_flag_for_como_cli := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_FOR_COMO_CLI_FATBV');
   --
   IF v_flag_for_como_cli = 'S' AND v_cliente_ok = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O fornecedor ' || v_cli_apelido || ' deve estar marcado também como Cliente ' ||
                  ' para que o BV/TIP possa ser faturado.';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_faturamento.nextval
     INTO v_faturamento_id
     FROM dual;
   --
   INSERT INTO faturamento
    (faturamento_id,
     job_id,
     emp_faturar_por_id,
     cliente_id,
     contato_cli_id,
     usuario_fatur_id,
     data_vencim,
     data_ordem,
     descricao,
     obs,
     cod_natureza_oper,
     flag_bv)
   VALUES
    (v_faturamento_id,
     v_job_id,
     v_emp_faturar_por_id,
     v_cliente_id,
     NULL,
     p_usuario_sessao_id,
     v_data_vencim,
     trunc(SYSDATE),
     nvl(TRIM(v_descricao), v_desc_natureza_oper),
     NULL,
     v_cod_natureza_oper,
     'S');
   --
   FOR r_itn IN c_itn
   LOOP
    v_valor_total := r_itn.valor_bv + r_itn.valor_tip;
    --
    IF v_valor_total > 0 THEN
     INSERT INTO item_fatur
      (item_fatur_id,
       item_id,
       faturamento_id,
       carta_acordo_id,
       nota_fiscal_id,
       valor_fatura)
     VALUES
      (seq_item_fatur.nextval,
       r_itn.item_id,
       v_faturamento_id,
       r_itn.carta_acordo_id,
       p_nota_fiscal_id,
       v_valor_total);
    END IF;
   END LOOP;
   --
   IF p_flag_comandar = 'S' THEN
    ------------------------------------------------------------
    -- integracao com sistemas externos
    ------------------------------------------------------------
    it_controle_pkg.integrar('FATURAMENTO_ADICIONAR',
                             p_empresa_id,
                             v_faturamento_id,
                             'JOB',
                             p_erro_cod,
                             p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   --
   SELECT nvl(SUM(valor_fatura), 0)
     INTO v_valor_total
     FROM item_fatur
    WHERE faturamento_id = v_faturamento_id;
   --
   ------------------------------------------------------------
   -- gera xml do log 
   ------------------------------------------------------------
   faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                       moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                       data_mostrar(v_data_vencim);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'FATURAMENTO',
                    'INCLUIR',
                    v_identif_objeto,
                    v_faturamento_id,
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
  END IF;
  --
  p_faturamento_id := v_faturamento_id;
  p_erro_cod       := '00000';
  p_erro_msg       := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END bv_gerar;
 --
 --
 PROCEDURE bv_comandar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: Atualização de FATURAMENTO de BV e registro de faturamento comandado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2015  Novo parametro opcional produto_cliente_id (do fornecedor)
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            26/02/2021  Novo parametro para usar ou nao data vencim
  -- Ana Luiza         08/11/2024  Novo tratamento para bvs cancelados
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_emp_faturar_por_id IN faturamento.emp_faturar_por_id%TYPE,
  p_cod_natureza_oper  IN faturamento.cod_natureza_oper%TYPE,
  p_produto_cliente_id IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim        IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_job_id         job.job_id%TYPE;
  v_data_vencim    faturamento.data_vencim%TYPE;
  v_cod_ext_fatur  faturamento.cod_ext_fatur%TYPE;
  v_cliente_id     faturamento.cliente_id%TYPE;
  v_valor_total    NUMBER;
  v_lbl_job        VARCHAR2(100);
  v_lbl_prodcli    VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_flag_usar_data VARCHAR2(10);
  --
  v_flag_cancelado     faturamento.flag_cancelado%TYPE;
  v_faturamento_id_new faturamento.faturamento_id%TYPE;
  v_faturamento_id     faturamento.faturamento_id%TYPE;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_usar_data       := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_DATA_VENCIM_FATUR');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         fa.cliente_id
    INTO v_job_id,
         v_numero_job,
         v_cliente_id
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FATURAMENTO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_produto_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE produto_cliente_id = p_produto_cliente_id
      AND pessoa_id = v_cliente_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_data_vencim) IS NULL AND v_flag_usar_data = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_vencim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa a faturar é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_natureza_oper) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da natureza da operação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id
     AND flag_emp_fatur = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE pessoa_id = p_emp_faturar_por_id
     AND codigo = TRIM(p_cod_natureza_oper)
     AND flag_bv = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Natureza da operação inválida (' || p_cod_natureza_oper || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_vencim := data_converter(p_data_vencim);
  --
  SELECT SUM(valor_fatura)
    INTO v_valor_total
    FROM item_fatur
   WHERE faturamento_id = p_faturamento_id;
  --ALCBO_081124
  SELECT flag_cancelado
    INTO v_flag_cancelado
    FROM faturamento
   WHERE faturamento_id = p_faturamento_id;
  --
  IF v_flag_cancelado = 'S' THEN
   -- Gera o novo ID para faturamento
   SELECT seq_faturamento.nextval
     INTO v_faturamento_id_new
     FROM dual;
  
   -- Define o ID de faturamento a ser usado no restante do fluxo
   v_faturamento_id := v_faturamento_id_new;
   -- Criar uma cópia do faturamento com o novo ID
   INSERT INTO faturamento
    (faturamento_id,
     job_id,
     emp_faturar_por_id,
     cliente_id,
     contato_cli_id,
     produto_cliente_id,
     nota_fiscal_sai_id,
     usuario_fatur_id,
     data_ordem,
     data_vencim,
     descricao,
     obs,
     cod_natureza_oper,
     cod_ext_fatur,
     flag_patrocinio,
     tipo_receita,
     flag_bv,
     uf_servico,
     municipio_servico,
     ordem_compra,
     num_parcela,
     flag_cancelado)
    SELECT v_faturamento_id_new, -- Usa o novo ID gerado
           job_id,
           emp_faturar_por_id,
           cliente_id,
           contato_cli_id,
           produto_cliente_id,
           nota_fiscal_sai_id,
           usuario_fatur_id,
           data_ordem,
           data_vencim,
           descricao,
           obs,
           cod_natureza_oper,
           cod_ext_fatur,
           flag_patrocinio,
           tipo_receita,
           flag_bv,
           uf_servico,
           municipio_servico,
           ordem_compra,
           num_parcela,
           'N' -- Define o novo registro como não cancelado
      FROM faturamento
     WHERE faturamento_id = p_faturamento_id;
   -- Criar cópias dos registros na tabela item_fatur com o novo ID de faturamento
   FOR r_item IN (SELECT *
                    FROM item_fatur
                   WHERE faturamento_id = p_faturamento_id)
   LOOP
    INSERT INTO item_fatur
     (item_fatur_id,
      faturamento_id,
      item_id,
      carta_acordo_id,
      nota_fiscal_id,
      valor_fatura)
    VALUES
     (seq_item_fatur.nextval, -- Novo ID para item_fatur
      v_faturamento_id_new, -- Referência ao novo faturamento
      r_item.item_id,
      r_item.carta_acordo_id,
      r_item.nota_fiscal_id,
      r_item.valor_fatura);
   END LOOP;
   -- Remove os registros antigos
   DELETE FROM item_fatur
    WHERE faturamento_id = p_faturamento_id;
   DELETE FROM faturamento
    WHERE faturamento_id = p_faturamento_id;
  ELSE
   v_faturamento_id := p_faturamento_id;
   --ALCBO_081124F
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faturamento
     SET emp_faturar_por_id = p_emp_faturar_por_id,
         data_vencim        = v_data_vencim,
         cod_natureza_oper  = TRIM(p_cod_natureza_oper),
         produto_cliente_id = zvl(p_produto_cliente_id, NULL),
         usuario_fatur_id   = p_usuario_sessao_id
   WHERE faturamento_id = v_faturamento_id;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('FATURAMENTO_ADICIONAR',
                           p_empresa_id,
                           v_faturamento_id,
                           'JOB',
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT TRIM(cod_ext_fatur)
    INTO v_cod_ext_fatur
    FROM faturamento
   WHERE faturamento_id = v_faturamento_id;
  --
  IF v_cod_ext_fatur IS NULL THEN
   -- nao existe integracao com sistema externo. Marca como comandado. 
   UPDATE faturamento
      SET cod_ext_fatur = 'J' || to_char(v_faturamento_id)
    WHERE faturamento_id = v_faturamento_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_faturamento_id,
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
 END bv_comandar;
 --
 --
 PROCEDURE bv_cancelar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza          ProcessMind     DATA: 15/10/2024
  -- DESCRICAO: Cancela BV de faturamento, limpa cod_ext_fatur e faturamento volta a ficar
  -- como nao comandado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_exception EXCEPTION;
 BEGIN
  UPDATE faturamento
     SET cod_ext_fatur  = NULL,
         flag_cancelado = 'S'
   WHERE faturamento_id = p_faturamento_id;
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
 END bv_cancelar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: Atualização de FATURAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/06/2015  Novo parametro produto_cliente_id
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_faturamento_id     IN faturamento.faturamento_id%TYPE,
  p_emp_faturar_por_id IN faturamento.emp_faturar_por_id%TYPE,
  p_cliente_id         IN faturamento.cliente_id%TYPE,
  p_contato_cli_id     IN faturamento.contato_cli_id%TYPE,
  p_produto_cliente_id IN faturamento.produto_cliente_id%TYPE,
  p_data_vencim        IN VARCHAR2,
  p_descricao          IN faturamento.descricao%TYPE,
  p_obs                IN faturamento.obs%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_job_id         job.job_id%TYPE;
  v_data_vencim    faturamento.data_vencim%TYPE;
  v_valor_total    NUMBER;
  v_lbl_job        VARCHAR2(100);
  v_lbl_prodcli    VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt                   := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_lbl_agencia_singular := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_AGENCIA_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero
    INTO v_job_id,
         v_numero_job
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FATURAMENTO_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_cliente_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do cliente é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_cliente_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE produto_cliente_id = p_produto_cliente_id
      AND pessoa_id = p_cliente_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_data_vencim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de vencimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_vencim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de vencimento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_faturar_por_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa a faturar é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_faturar_por_id
     AND empresa_id = p_empresa_id
     AND flag_emp_fatur = 'S';
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa de faturamento não existe ou não pertence ao grupo da ' ||
                 v_lbl_agencia_singular || ' (' || to_char(p_emp_faturar_por_id) || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_vencim := data_converter(p_data_vencim);
  --
  IF TRIM(p_descricao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da descrição não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT SUM(valor_fatura)
    INTO v_valor_total
    FROM item_fatur
   WHERE faturamento_id = p_faturamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(p_faturamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faturamento
     SET emp_faturar_por_id = p_emp_faturar_por_id,
         cliente_id         = p_cliente_id,
         contato_cli_id     = zvl(p_contato_cli_id, NULL),
         produto_cliente_id = zvl(p_produto_cliente_id, NULL),
         data_vencim        = v_data_vencim,
         descricao          = TRIM(p_descricao),
         obs                = TRIM(p_obs)
   WHERE faturamento_id = p_faturamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(p_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_faturamento_id,
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
 PROCEDURE receita_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 21/10/2008
  -- DESCRICAO: Alteracao de receita / patrocinio de Faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_faturamento_id       IN VARCHAR2,
  p_flag_patrocinio      IN VARCHAR2,
  p_flag_outras_receitas IN VARCHAR2,
  p_tipo_receita         IN VARCHAR2,
  p_justificativa        IN VARCHAR2,
  p_historico_id         OUT historico.historico_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_job_id            job.job_id%TYPE;
  v_faturamento_id    faturamento.faturamento_id%TYPE;
  v_data_vencim       faturamento.data_vencim%TYPE;
  v_cod_natureza_oper faturamento.cod_natureza_oper%TYPE;
  v_flag_bv           faturamento.flag_bv%TYPE;
  v_valor_total       NUMBER;
  v_lbl_job           VARCHAR2(100);
  v_xml_antes         CLOB;
  v_xml_atual         CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF inteiro_validar(p_faturamento_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da ordem de faturamento inválido.';
   RAISE v_exception;
  END IF;
  --
  v_faturamento_id := nvl(to_number(p_faturamento_id), 0);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = v_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         fa.data_vencim,
         fa.cod_natureza_oper,
         fa.flag_bv
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_data_vencim,
         v_cod_natureza_oper,
         v_flag_bv
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = v_faturamento_id
     AND fa.job_id = jo.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OPER_ESP_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT SUM(valor_fatura)
    INTO v_valor_total
    FROM item_fatur
   WHERE faturamento_id = v_faturamento_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_flag_bv = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Indicação de receita ou patrocínio não pode ser feita para ' ||
                 'ordem de faturamento de BV.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_patrocinio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag patrocínio inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_outras_receitas) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag outras receitas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_receita) IS NOT NULL THEN
   -- o tipo de receita foi especificado
   IF util_pkg.desc_retornar('tipo_receita', p_tipo_receita) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de receita inválida (' || p_tipo_receita || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_outras_receitas = 'N' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Um tipo de receita foi especificado mas a opção de ' ||
                  'Outras Receitas não está marcada.';
    RAISE v_exception;
   END IF;
   --
   IF p_flag_patrocinio = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível selecionar patrocínio e outras receitas ' || 'ao mesmo tempo.';
    RAISE v_exception;
   END IF;
  ELSE
   -- o tipo de receita nao foi especificado
   IF p_flag_outras_receitas = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A opção de Outras Receitas está marcada mas nenhum ' ||
                  'tipo de receita foi especificado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --
  IF p_flag_patrocinio = 'S' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_fatur  it,
          nota_fiscal nf
    WHERE it.faturamento_id = v_faturamento_id
      AND it.nota_fiscal_id = nf.nota_fiscal_id
      AND rtrim(nf.tipo_receita) IS NOT NULL;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Faturamento foi marcado como patrocinado, mas ' ||
                  'existem notas fiscais indicando receita.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_flag_outras_receitas = 'S' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_fatur  it,
          nota_fiscal nf
    WHERE it.faturamento_id = v_faturamento_id
      AND it.nota_fiscal_id = nf.nota_fiscal_id
      AND rtrim(nf.tipo_receita) IS NOT NULL;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Faturamento foi marcado como outras receitas, mas ' ||
                  'existem notas fiscais indicando patrocínio.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE faturamento
     SET flag_patrocinio = p_flag_patrocinio,
         tipo_receita    = TRIM(p_tipo_receita)
   WHERE faturamento_id = v_faturamento_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  faturamento_pkg.xml_gerar(v_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                      data_mostrar(v_data_vencim);
  v_compl_histor   := 'Alteração de receita / patrocínio';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'FATURAMENTO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_faturamento_id,
                   v_compl_histor,
                   p_justificativa,
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
 END; -- receita_atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 07/05/2007
  -- DESCRICAO: Exclusão de FATURAMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            19/01/2011  Nao reabre check-in ou faturamento nem recalcula saldos
  --                               de itens qdo se tratar de faturamento de BV.
  -- Ana Luiza         17/10/2024  Volta bv para nao comandado, para nao precisar refazer o checkin
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_faturamento_id    IN faturamento.faturamento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_numero_job         job.numero%TYPE;
  v_job_id             job.job_id%TYPE;
  v_data_vencim        faturamento.data_vencim%TYPE;
  v_valor_total        NUMBER;
  v_nota_fiscal_sai_id faturamento.nota_fiscal_sai_id%TYPE;
  v_cod_natureza_oper  faturamento.cod_natureza_oper%TYPE;
  v_flag_bv            faturamento.flag_bv%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  --
  CURSOR c_it IS
   SELECT item_fatur_id,
          item_id
     FROM item_fatur
    WHERE faturamento_id = p_faturamento_id;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse faturamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         fa.data_vencim,
         fa.nota_fiscal_sai_id,
         fa.cod_natureza_oper,
         fa.flag_bv
    INTO v_job_id,
         v_numero_job,
         v_data_vencim,
         v_nota_fiscal_sai_id,
         v_cod_natureza_oper,
         v_flag_bv
    FROM faturamento fa,
         job         jo
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.job_id = jo.job_id;
  --
  IF p_flag_commit = 'S' THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'FATURAMENTO_C', NULL, NULL, p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_nota_fiscal_sai_id IS NOT NULL THEN
   IF v_cod_natureza_oper = 'BV' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O faturamento de BV já tem nota fiscal de saída emitida.';
    RAISE v_exception;
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'Esse faturamento já tem nota fiscal de saída emitida.';
    RAISE v_exception;
   END IF;
  END IF;
  --ALCBO_171024
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_oper_fatur
   WHERE codigo = v_cod_natureza_oper
     AND flag_bv = 'S';
  IF v_cod_natureza_oper = 'BV' OR v_qt > 0 THEN
   faturamento_pkg.bv_cancelar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_faturamento_id,
                               'S',
                               p_erro_cod,
                               p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  ELSE
   --
   SELECT SUM(valor_fatura)
     INTO v_valor_total
     FROM item_fatur
    WHERE faturamento_id = p_faturamento_id;
   --
   ------------------------------------------------------------
   -- gera xml do log 
   ------------------------------------------------------------
   faturamento_pkg.xml_gerar(p_faturamento_id, v_xml_atual, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   ------------------------------------------------------------
   -- integracao com sistemas externos
   ------------------------------------------------------------
   it_controle_pkg.integrar('FATURAMENTO_EXCLUIR',
                            p_empresa_id,
                            p_faturamento_id,
                            'JOB',
                            p_erro_cod,
                            p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   ------------------------------------------------------------
   -- atualizacao do banco
   ------------------------------------------------------------
   FOR r_it IN c_it
   LOOP
    DELETE FROM item_fatur
     WHERE item_fatur_id = r_it.item_fatur_id;
    --
    IF v_flag_bv = 'N' THEN
     item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
   --
   DELETE FROM faturamento
    WHERE faturamento_id = p_faturamento_id;
   --
   IF v_flag_bv = 'N' THEN
    job_pkg.status_tratar(p_usuario_sessao_id,
                          p_empresa_id,
                          v_job_id,
                          'ALL',
                          p_erro_cod,
                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- geracao de evento
   ------------------------------------------------------------
   v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Valor: ' ||
                       moeda_mostrar(v_valor_total, 'S') || ' - Data Vencim: ' ||
                       data_mostrar(v_data_vencim);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'FATURAMENTO',
                    'EXCLUIR',
                    v_identif_objeto,
                    p_faturamento_id,
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
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   IF p_flag_commit = 'S' THEN
    ROLLBACK;
   END IF;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   IF p_flag_commit = 'S' THEN
    ROLLBACK;
   END IF;
 END excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 08/02/2017
  -- DESCRICAO: Subrotina que gera o xml do faturamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_faturamento_id IN faturamento.faturamento_id%TYPE,
  p_xml            OUT CLOB,
  p_erro_cod       OUT VARCHAR2,
  p_erro_msg       OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_xml          xmltype;
  v_xml_aux1     xmltype;
  v_xml_aux99    xmltype;
  v_xml_doc      VARCHAR2(100);
  v_valor_fatura NUMBER;
  --
  CURSOR c_it IS
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || '/' || it.tipo_item ||
          to_char(it.num_seq) AS num_item,
          numero_mostrar(ia.valor_fatura, 2, 'N') valor_item,
          CASE
           WHEN ia.carta_acordo_id IS NULL THEN
            NULL
           ELSE
            carta_acordo_pkg.numero_completo_formatar(ia.carta_acordo_id, 'N')
          END AS num_carta_acordo,
          ia.nota_fiscal_id
     FROM item_fatur ia,
          item       it
    WHERE ia.faturamento_id = p_faturamento_id
      AND ia.item_id = it.item_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT nvl(SUM(valor_fatura), 0)
    INTO v_valor_fatura
    FROM item_fatur
   WHERE faturamento_id = p_faturamento_id;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("faturamento_id", fa.faturamento_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("job", jo.numero),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("contato_cliente", co.apelido),
                   xmlelement("produto_cliente", pc.nome),
                   xmlelement("data_entrada", data_mostrar(fa.data_ordem)),
                   xmlelement("data_vencimento", data_mostrar(fa.data_vencim)),
                   xmlelement("num_parcela", to_char(fa.num_parcela)),
                   xmlelement("empresa_fatur", ef.apelido),
                   xmlelement("natureza_oper", fa.cod_natureza_oper || '-' || na.descricao),
                   xmlelement("valor_fatura", numero_mostrar(v_valor_fatura, 2, 'S')),
                   xmlelement("bv", fa.flag_bv),
                   xmlelement("patrocinio", fa.flag_patrocinio),
                   xmlelement("tipo_receita",
                              util_pkg.desc_retornar('tipo_receita', fa.tipo_receita)),
                   xmlelement("municipio_servico", fa.municipio_servico),
                   xmlelement("uf_servico", fa.uf_servico),
                   xmlelement("cod_ext_fatur", fa.cod_ext_fatur),
                   xmlelement("ordem_compra", fa.ordem_compra))
    INTO v_xml
    FROM faturamento         fa,
         pessoa              cl,
         pessoa              ef,
         job                 jo,
         produto_cliente     pc,
         pessoa              co,
         natureza_oper_fatur na
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.cliente_id = cl.pessoa_id
     AND fa.emp_faturar_por_id = ef.pessoa_id
     AND fa.job_id = jo.job_id
     AND fa.produto_cliente_id = pc.produto_cliente_id(+)
     AND fa.contato_cli_id = co.pessoa_id(+)
     AND fa.emp_faturar_por_id = na.pessoa_id(+)
     AND fa.cod_natureza_oper = na.codigo(+);
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
                            xmlelement("carta_acordo", r_it.num_carta_acordo),
                            xmlelement("nota_fiscal_id", r_it.nota_fiscal_id)))
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
  -- junta tudo debaixo de "faturamento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("faturamento", v_xml))
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
 FUNCTION valor_fatura_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor total de uma determinada ordem de faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_faturamento_id IN faturamento.faturamento_id%TYPE
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  SELECT nvl(SUM(valor_fatura), 0)
    INTO v_retorno
    FROM item_fatur
   WHERE faturamento_id = p_faturamento_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_fatura_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor de um determinado item ou carta acordo, de acordo com o tipo
  --  especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/04/2008  Tratamento de abatimentos.
  -- Silvia            23/05/2008  Ajuste nos valores liberados de Honor/Encargos de A.
  -- Silvia            05/08/2008  Ajuste em receita pago pela fonte.
  -- Silvia            09/09/2008  Ajuste em check-in de incentivo.
  -- Silvia            08/10/2008  Alteracao em calculo de valor liberado de A.
  -- Silvia            13/11/2009  Implementacao de receita de contrato.
  -- Silvia            22/06/2016  Tratamento p/ orcamento do tipo despesa.
  -- Silvia            10/11/2022  Nova modalidade de calculo (DIV) de natureza do item
  -- Ana Luiza         08/05/2024  Adiccao de condicoes para encargo
  ------------------------------------------------------------------------------------------
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                       INTEGER;
  v_retorno                  NUMBER;
  v_exception                EXCEPTION;
  v_saida                    EXCEPTION;
  v_empresa_id               natureza_item.empresa_id%TYPE;
  v_mod_calculo              natureza_item.mod_calculo%TYPE;
  v_valor_padrao             natureza_item.valor_padrao%TYPE;
  v_mod_calculo_honor        natureza_item.mod_calculo%TYPE;
  v_valor_padrao_honor       natureza_item.valor_padrao%TYPE;
  v_flag_vinc_ck_a           natureza_item.flag_vinc_ck_a%TYPE;
  v_valor_aprovado           item.valor_aprovado%TYPE;
  v_valor_faturado           item.valor_aprovado%TYPE;
  v_valor_com_nf             item.valor_aprovado%TYPE;
  v_tipo_item                item.tipo_item%TYPE;
  v_natureza_item            item.natureza_item%TYPE;
  v_flag_pago_cliente        item.flag_pago_cliente%TYPE;
  v_orcamento_id             orcamento.orcamento_id%TYPE;
  v_flag_despesa             orcamento.flag_despesa%TYPE;
  v_precisao                 NUMBER;
  v_valor_abatimentos        NUMBER;
  v_valor_afaturar           NUMBER;
  v_valor_rec_pago_fonte     NUMBER;
  v_valor_rec_contrato       NUMBER;
  v_valor_incentivo          NUMBER;
  v_valor_receitas_sem_fatur NUMBER;
  v_valor_aprov_orcam_a      NUMBER;
  v_valor_lib_parcial_a      NUMBER;
  v_permitir_fatur_a_sem_ca  VARCHAR2(1);
  --
 BEGIN
  v_retorno  := 0;
  v_precisao := 0.05;
  --
  v_valor_faturado           := 0;
  v_valor_aprovado           := 0;
  v_valor_abatimentos        := 0;
  v_valor_com_nf             := 0;
  v_valor_receitas_sem_fatur := 0;
  v_valor_rec_pago_fonte     := 0;
  v_valor_incentivo          := 0;
  v_valor_rec_contrato       := 0;
  v_valor_aprov_orcam_a      := 0;
  v_valor_lib_parcial_a      := 0;
  --
  ------------------------------------------------------------
  -- preparacao dos calculos
  ------------------------------------------------------------
  IF p_tipo_valor NOT IN
     ('FATURADO', 'AFATURAR', 'LIBERADO', 'ABATIDO', 'AFATURAR_SEM_CA', 'RECEITA_SEM_FATUR') OR
     TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_item,
         natureza_item,
         orcamento_id,
         flag_pago_cliente,
         valor_aprovado
    INTO v_tipo_item,
         v_natureza_item,
         v_orcamento_id,
         v_flag_pago_cliente,
         v_valor_aprovado
    FROM item
   WHERE item_id = p_item_id;
  --
  SELECT oc.flag_despesa,
         jo.empresa_id
    INTO v_flag_despesa,
         v_empresa_id
    FROM orcamento oc,
         job       jo
   WHERE oc.orcamento_id = v_orcamento_id
     AND oc.job_id = jo.job_id;
  --
  v_permitir_fatur_a_sem_ca := empresa_pkg.parametro_retornar(v_empresa_id,
                                                              'PERMITIR_FATUR_A_SEM_CA');
  --
  ------------------------------------------------------------
  -- calcula valor ABATIDO
  ------------------------------------------------------------
  IF p_tipo_valor = 'ABATIDO' THEN
   IF nvl(p_carta_acordo_id, 0) = 0 THEN
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_valor_abatimentos
      FROM item_abat ia
     WHERE ia.item_id = p_item_id;
   ELSE
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_valor_abatimentos
      FROM item_abat  ia,
           abatimento ab
     WHERE ab.carta_acordo_id = p_carta_acordo_id
       AND ab.abatimento_id = ia.abatimento_id
       AND ia.item_id = p_item_id;
   END IF;
   --
   v_retorno := v_valor_abatimentos;
  END IF; -- fim do ABATIDO
  --
  ------------------------------------------------------------
  -- calcula valor RECEITA_SEM_FATUR
  ------------------------------------------------------------
  IF p_tipo_valor = 'RECEITA_SEM_FATUR' THEN
   IF nvl(p_carta_acordo_id, 0) = 0 THEN
    -- soma receita paga diretamente pela fonte
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_rec_pago_fonte
      FROM item_nota   it,
           nota_fiscal nf
     WHERE it.item_id = p_item_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita IS NOT NULL
       AND nf.resp_pgto_receita = 'FON';
    --
    -- soma receita de contrato
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_rec_contrato
      FROM item_nota   it,
           nota_fiscal nf
     WHERE it.item_id = p_item_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita = 'CONTRATO'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
    --
    -- soma receita de incentivo (desde que nao seja
    -- paga direto pela fonte).
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_incentivo
      FROM item_nota   it,
           nota_fiscal nf,
           pessoa      pe
     WHERE it.item_id = p_item_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.emp_faturar_por_id = pe.pessoa_id
       AND pe.flag_emp_incentivo = 'S'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
   ELSE
    -- soma receita paga diretamente pela fonte
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_rec_pago_fonte
      FROM item_nota   it,
           nota_fiscal nf
     WHERE it.item_id = p_item_id
       AND it.carta_acordo_id = p_carta_acordo_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita IS NOT NULL
       AND nf.resp_pgto_receita = 'FON';
    --
    -- soma receita de contrato
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_rec_contrato
      FROM item_nota   it,
           nota_fiscal nf
     WHERE it.item_id = p_item_id
       AND it.carta_acordo_id = p_carta_acordo_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.tipo_receita = 'CONTRATO'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
    --
    -- soma receita de incentivo (desde que nao seja
    -- paga direto pela fonte).
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_valor_incentivo
      FROM item_nota   it,
           nota_fiscal nf,
           pessoa      pe
     WHERE it.item_id = p_item_id
       AND it.carta_acordo_id = p_carta_acordo_id
       AND it.nota_fiscal_id = nf.nota_fiscal_id
       AND nf.emp_faturar_por_id = pe.pessoa_id
       AND pe.flag_emp_incentivo = 'S'
       AND nvl(nf.resp_pgto_receita, 'XXX') <> 'FON';
   END IF;
   --
   v_retorno := v_valor_rec_pago_fonte + v_valor_rec_contrato + v_valor_incentivo;
  END IF; -- fim do RECEITA_SEM_FATUR
  --
  ------------------------------------------------------------
  -- calcula valor FATURADO
  ------------------------------------------------------------
  IF p_tipo_valor = 'FATURADO' THEN
   IF v_flag_pago_cliente = 'S' OR v_flag_despesa = 'S' THEN
    v_retorno := 0;
   ELSE
    IF nvl(p_carta_acordo_id, 0) = 0 THEN
     SELECT nvl(SUM(it.valor_fatura), 0)
       INTO v_valor_faturado
       FROM item_fatur  it,
            faturamento fa
      WHERE it.item_id = p_item_id
        AND it.faturamento_id = fa.faturamento_id
        AND fa.flag_bv = 'N';
    ELSE
     SELECT nvl(SUM(it.valor_fatura), 0)
       INTO v_valor_faturado
       FROM item_fatur  it,
            faturamento fa
      WHERE it.carta_acordo_id = p_carta_acordo_id
        AND it.item_id = p_item_id
        AND it.faturamento_id = fa.faturamento_id
        AND fa.flag_bv = 'N';
    END IF;
    --
    v_retorno := v_valor_faturado;
   END IF;
  END IF; -- fim do FATURADO
  --
  ------------------------------------------------------------
  -- calcula valor AFATURAR
  ------------------------------------------------------------
  IF p_tipo_valor = 'AFATURAR' THEN
   IF v_flag_pago_cliente = 'S' OR v_flag_despesa = 'S' THEN
    v_retorno := 0;
   ELSE
    IF nvl(p_carta_acordo_id, 0) <> 0 THEN
     SELECT nvl(SUM(valor_aprovado), 0)
       INTO v_valor_aprovado
       FROM item_carta
      WHERE carta_acordo_id = p_carta_acordo_id
        AND item_id = p_item_id;
    END IF;
    --
    v_valor_faturado           := valor_retornar(p_item_id, p_carta_acordo_id, 'FATURADO');
    v_valor_abatimentos        := valor_retornar(p_item_id, p_carta_acordo_id, 'ABATIDO');
    v_valor_receitas_sem_fatur := valor_retornar(p_item_id, p_carta_acordo_id, 'RECEITA_SEM_FATUR');
    --
    v_retorno := v_valor_aprovado - v_valor_faturado - v_valor_receitas_sem_fatur -
                 v_valor_abatimentos;
   END IF;
   --
   IF abs(v_retorno) < v_precisao AND v_natureza_item <> 'CUSTO' THEN
    -- despreza a diferenca (arredondamentos)
    v_retorno := 0;
   END IF;
  END IF; -- fim do AFATURAR
  --
  ------------------------------------------------------------
  -- calcula valor AFATURAR_SEM_CA
  ------------------------------------------------------------
  IF p_tipo_valor = 'AFATURAR_SEM_CA' THEN
   -- caso especifico para linha de itens de A sem carta acordo
   IF v_flag_pago_cliente = 'S' OR v_flag_despesa = 'S' THEN
    v_retorno := 0;
   ELSE
    v_valor_aprovado := item_pkg.valor_retornar(p_item_id, 0, 'SEM_CA');
    --
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_valor_abatimentos
      FROM item_abat  ia,
           abatimento ab
     WHERE ia.item_id = p_item_id
       AND ab.abatimento_id = ia.abatimento_id
       AND ab.carta_acordo_id IS NULL;
    --
    v_retorno := v_valor_aprovado - v_valor_abatimentos;
   END IF;
   --
   IF abs(v_retorno) < v_precisao AND v_natureza_item <> 'CUSTO' THEN
    -- despreza a diferenca (arredondamento)
    v_retorno := 0;
   END IF;
  END IF; -- fom do AFATURAR_SEM_CA
  --
  ------------------------------------------------------------
  -- calcula valor LIBERADO
  ------------------------------------------------------------
  IF p_tipo_valor = 'LIBERADO' THEN
   -- para itens de B e C (qualquer natureza) 
   -- o valor liberado é o mesmo que o valor a faturar
   IF v_tipo_item IN ('B', 'C') OR (v_tipo_item = 'A' AND v_permitir_fatur_a_sem_ca = 'S') THEN
    v_retorno := valor_retornar(p_item_id, p_carta_acordo_id, 'AFATURAR');
    RAISE v_saida;
   END IF;
   --
   -- para itens de A (CUSTO), o valor liberado geralmente corresponde aos 
   -- valores de notas fiscais recebidas que ainda nao foram faturadas.
   IF v_tipo_item = 'A' AND v_natureza_item = 'CUSTO' AND v_permitir_fatur_a_sem_ca = 'N' THEN
    IF v_flag_pago_cliente = 'S' OR v_flag_despesa = 'S' THEN
     -- pago pelo cliente ou orcamento de despesa (nada a faturar)
     v_retorno := 0;
     RAISE v_saida;
    END IF;
    --
    SELECT MAX(flag_vinc_ck_a)
      INTO v_flag_vinc_ck_a
      FROM natureza_item
     WHERE codigo = v_natureza_item
       AND empresa_id = v_empresa_id;
    --
    IF v_flag_vinc_ck_a = 'N' THEN
     -- natureza de item sem vinculo com check-in de A.
     -- o valor liberado é o mesmo que o valor a faturar
     v_retorno := valor_retornar(p_item_id, p_carta_acordo_id, 'AFATURAR');
     RAISE v_saida;
    END IF;
    --
    IF nvl(p_carta_acordo_id, 0) = 0 THEN
     SELECT nvl(SUM(valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota
      WHERE item_id = p_item_id;
    ELSE
     SELECT nvl(SUM(valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota
      WHERE carta_acordo_id = p_carta_acordo_id
        AND item_id = p_item_id;
    END IF;
    --
    v_valor_faturado           := valor_retornar(p_item_id, p_carta_acordo_id, 'FATURADO');
    v_valor_receitas_sem_fatur := valor_retornar(p_item_id, p_carta_acordo_id, 'RECEITA_SEM_FATUR');
    --
    v_retorno := v_valor_com_nf - v_valor_receitas_sem_fatur - v_valor_faturado;
   END IF; -- fim do IF v_tipo_item = 'A' AND v_natureza_item = 'CUSTO'
   --
   -- para itens de A (NAO CUSTO), o valor liberado geralmente corresponde ao valor
   -- proporcional as notas fiscais recebidas + abatimentos menos o que foi faturado.
   IF v_tipo_item = 'A' AND v_natureza_item <> 'CUSTO' THEN
    -- Precisa ver configuracoes da natureza.
    SELECT MAX(nvl(oc.valor_padrao, 0)),
           MAX(na.mod_calculo),
           MAX(na.flag_vinc_ck_a)
      INTO v_valor_padrao,
           v_mod_calculo,
           v_flag_vinc_ck_a
      FROM natureza_item   na,
           orcam_nitem_pdr oc
     WHERE oc.orcamento_id = v_orcamento_id
       AND oc.natureza_item_id = na.natureza_item_id
       AND na.codigo = v_natureza_item
       AND na.empresa_id = v_empresa_id;
    --
    IF v_flag_vinc_ck_a = 'N' THEN
     -- natureza de item sem vinculo com check-in de A.
     -- o valor liberado é o mesmo que o valor a faturar
     v_retorno := valor_retornar(p_item_id, p_carta_acordo_id, 'AFATURAR');
     RAISE v_saida;
    END IF;
    --
    SELECT nvl(SUM(ia.valor_abat_item), 0)
      INTO v_valor_abatimentos
      FROM item_abat  ia,
           abatimento ab,
           item       it
     WHERE it.orcamento_id = v_orcamento_id
       AND it.tipo_item = 'A'
       AND it.natureza_item = 'CUSTO'
       AND ia.item_id = it.item_id
       AND ab.abatimento_id = ia.abatimento_id;
    --
    IF v_natureza_item = 'CPMF' THEN
     SELECT nvl(SUM(it.valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota   it,
            item        ie,
            nota_fiscal nf
      WHERE ie.orcamento_id = v_orcamento_id
        AND ie.tipo_item = v_tipo_item
        AND ie.flag_pago_cliente = 'N'
        AND ie.flag_com_encargo = 'S'
        AND ie.item_id = it.item_id
        AND it.nota_fiscal_id = nf.nota_fiscal_id;
    ELSIF v_natureza_item = 'HONOR' THEN
     SELECT nvl(SUM(it.valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota   it,
            item        ie,
            nota_fiscal nf
      WHERE ie.orcamento_id = v_orcamento_id
        AND ie.tipo_item = v_tipo_item
        AND ie.flag_com_honor = 'S'
        AND ie.item_id = it.item_id
        AND it.nota_fiscal_id = nf.nota_fiscal_id;
    ELSIF v_natureza_item = 'ENCARGO_HONOR' THEN
     SELECT nvl(SUM(it.valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota   it,
            item        ie,
            nota_fiscal nf
      WHERE ie.orcamento_id = v_orcamento_id
        AND ie.tipo_item = v_tipo_item
        AND ie.flag_com_honor = 'S'
        AND ie.flag_com_encargo_honor = 'S'
        AND ie.item_id = it.item_id
        AND it.nota_fiscal_id = nf.nota_fiscal_id;
     --ALCBO_080524    
    ELSIF v_natureza_item = 'ENCARGO' THEN
     SELECT nvl(SUM(it.valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota   it,
            item        ie,
            nota_fiscal nf
      WHERE ie.orcamento_id = v_orcamento_id
        AND ie.tipo_item = v_tipo_item
        AND ie.flag_com_encargo = 'S'
        AND ie.item_id = it.item_id
        AND it.nota_fiscal_id = nf.nota_fiscal_id;
     --
     -- precisa tb do percentual do honorario
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
    ELSE
     -- naturezas customizaveis (o calculo eh proporcional)
     SELECT nvl(SUM(it.valor_aprovado), 0)
       INTO v_valor_com_nf
       FROM item_nota   it,
            item        ie,
            nota_fiscal nf
      WHERE ie.orcamento_id = v_orcamento_id
        AND ie.tipo_item = v_tipo_item
        AND ie.item_id = it.item_id
        AND it.nota_fiscal_id = nf.nota_fiscal_id;
     --
     SELECT nvl(SUM(valor_aprovado), 0)
       INTO v_valor_aprov_orcam_a
       FROM item
      WHERE orcamento_id = v_orcamento_id
        AND tipo_item = v_tipo_item
        AND natureza_item = 'CUSTO';
    END IF;
    --
    v_valor_faturado := valor_retornar(p_item_id, p_carta_acordo_id, 'FATURADO');
    -- junta eventuais abatimentos
    v_valor_com_nf := v_valor_com_nf + v_valor_abatimentos;
    --
    IF v_natureza_item = 'ENCARGO_HONOR' THEN
     -- precisa primeiro aplicar os honorarios
     IF v_mod_calculo_honor = 'PERC' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf * v_valor_padrao_honor / 100, 2);
     ELSIF v_mod_calculo_honor = 'IND' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf * v_valor_padrao_honor, 2);
     ELSIF v_mod_calculo_honor = 'DIV' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf / (1 - v_valor_padrao_honor / 100), 2) -
                               v_valor_com_nf;
     END IF;
     --
     v_valor_com_nf := v_valor_lib_parcial_a;
    END IF;
    --
    IF v_natureza_item IN ('CPMF', 'HONOR', 'ENCARGO_HONOR') THEN
     IF v_mod_calculo = 'PERC' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf * v_valor_padrao / 100, 2);
     ELSIF v_mod_calculo = 'IND' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf * v_valor_padrao, 2);
     ELSIF v_mod_calculo_honor = 'DIV' THEN
      v_valor_lib_parcial_a := round(v_valor_com_nf / (1 - v_valor_padrao / 100), 2) -
                               v_valor_com_nf;
     END IF;
     --
     v_retorno := v_valor_lib_parcial_a - v_valor_faturado;
    ELSE
     IF v_valor_aprovado > 0 THEN
      v_retorno := round(v_valor_aprovado * v_valor_com_nf / v_valor_aprov_orcam_a, 2) -
                   v_valor_faturado;
     ELSE
      v_retorno := 0;
     END IF;
    END IF;
   END IF; -- fim do IF v_tipo_item = 'A' AND v_natureza_item <> 'CUSTO'
   --  
   -- consistencias finais do valor liberado
   IF v_retorno < 0 THEN
    -- despreza valores negativos (houve faturamento sem check-in de nota fiscal)
    v_retorno := 0;
   END IF;
   --
   v_valor_abatimentos := valor_retornar(p_item_id, p_carta_acordo_id, 'ABATIDO');
   IF v_valor_aprovado = v_valor_faturado + v_valor_abatimentos THEN
    -- ja foi tudo faturado (nada a liberar).
    -- despreza os calculos pois pode ter havido erro de arredondamento
    v_retorno := 0;
   END IF;
   --
   -- o valor liberado nao pode ser maior que o valor a faturar
   v_valor_afaturar := valor_retornar(p_item_id, p_carta_acordo_id, 'AFATURAR');
   IF v_retorno > v_valor_afaturar THEN
    v_retorno := v_valor_afaturar;
   END IF;
   --
   IF abs(v_retorno) < v_precisao AND v_natureza_item <> 'CUSTO' THEN
    -- despreza a diferenca (arredondamento de encargos e honor)
    v_retorno := 0;
   END IF;
  END IF; -- fim do LIBERADO
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION valor_na_nf_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor de um determinado item/carta acordo/nota_fiscal de entrada,
  --  de acordo com o tipo especificado no parametro de entrada. Essa funcao vale apenas
  --  para itens do tipo A.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/08/2008  Tratamento de receita paga pela fonte.
  -- Silvia            13/11/2009  Implementacao de receita de contrato.
  ------------------------------------------------------------------------------------------
  p_item_id         IN item.item_id%TYPE,
  p_carta_acordo_id IN carta_acordo.carta_acordo_id%TYPE,
  p_nota_fiscal_id  IN nota_fiscal.nota_fiscal_id%TYPE,
  p_tipo_valor      IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt                INTEGER;
  v_retorno           NUMBER;
  v_exception         EXCEPTION;
  v_valor_faturado    item.valor_aprovado%TYPE;
  v_valor_nf          item.valor_aprovado%TYPE;
  v_flag_nf_com_fatur CHAR(1);
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN ('FATURADO', 'AFATURAR') OR TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  v_flag_nf_com_fatur := nota_fiscal_pkg.flag_com_fatur_retornar(p_nota_fiscal_id);
  --
  IF nvl(p_carta_acordo_id, 0) = 0 THEN
   --
   SELECT nvl(SUM(it.valor_fatura), 0)
     INTO v_valor_faturado
     FROM item_fatur  it,
          faturamento fa
    WHERE it.item_id = p_item_id
      AND it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'N';
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_nf
     FROM item_nota
    WHERE item_id = p_item_id
      AND nota_fiscal_id = p_nota_fiscal_id;
  ELSE
   SELECT nvl(SUM(it.valor_fatura), 0)
     INTO v_valor_faturado
     FROM item_fatur  it,
          faturamento fa
    WHERE it.carta_acordo_id = p_carta_acordo_id
      AND it.item_id = p_item_id
      AND it.nota_fiscal_id = p_nota_fiscal_id
      AND it.faturamento_id = fa.faturamento_id
      AND fa.flag_bv = 'N';
   --
   SELECT nvl(SUM(valor_aprovado), 0)
     INTO v_valor_nf
     FROM item_nota
    WHERE carta_acordo_id = p_carta_acordo_id
      AND item_id = p_item_id
      AND nota_fiscal_id = p_nota_fiscal_id;
  END IF;
  --
  IF p_tipo_valor = 'FATURADO' THEN
   v_retorno := v_valor_faturado;
   --
  ELSIF p_tipo_valor = 'AFATURAR' THEN
   IF v_flag_nf_com_fatur = 'N' THEN
    v_retorno := 0;
   ELSE
    v_retorno := v_valor_nf - v_valor_faturado;
   END IF;
   --
   IF v_retorno < 0 THEN
    -- despreza valores negativos (houve faturamento sem
    -- check-in de nota fiscal)
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
 END valor_na_nf_retornar;
 --
 --
 FUNCTION valor_orcam_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna o valor de um determinado orcamento, de acordo com o tipo
  --  especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/04/2008  Tratamento de abatimento.
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE,
  p_tipo_valor   IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt        INTEGER;
  v_retorno   NUMBER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_valor NOT IN ('FATURADO', 'AFATURAR', 'LIBERADO', 'ABATIDO') OR
     TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_valor = 'FATURADO' THEN
   SELECT nvl(SUM(valor_faturado), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND flag_sem_valor = 'N';
  ELSIF p_tipo_valor = 'AFATURAR' THEN
   SELECT nvl(SUM(valor_afaturar), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND flag_sem_valor = 'N';
  ELSIF p_tipo_valor = 'LIBERADO' THEN
   SELECT nvl(SUM(valor_liberado), 0)
     INTO v_retorno
     FROM item
    WHERE orcamento_id = p_orcamento_id
      AND flag_sem_valor = 'N';
  ELSE
   SELECT nvl(SUM(ia.valor_abat_item), 0)
     INTO v_retorno
     FROM item_abat ia,
          item      it
    WHERE it.orcamento_id = p_orcamento_id
      AND it.flag_sem_valor = 'N'
      AND it.item_id = ia.item_id;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_orcam_retornar;
 --
 --
 FUNCTION data_fechamento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a data de fechamento do faturamento de um determinado orcamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/04/2008  Tratamento de abatimento.
  ------------------------------------------------------------------------------------------
  p_orcamento_id IN orcamento.orcamento_id%TYPE
 ) RETURN DATE AS
  v_qt        INTEGER;
  v_retorno   DATE;
  v_data_aux  DATE;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF faturamento_pkg.valor_orcam_retornar(p_orcamento_id, 'AFATURAR') = 0 THEN
   SELECT MAX(fa.data_ordem)
     INTO v_retorno
     FROM item        it,
          item_fatur  ff,
          faturamento fa
    WHERE it.orcamento_id = p_orcamento_id
      AND it.item_id = ff.item_id
      AND ff.faturamento_id = fa.faturamento_id;
   --
   SELECT MAX(ab.data_entrada)
     INTO v_data_aux
     FROM item       it,
          item_abat  ia,
          abatimento ab
    WHERE it.orcamento_id = p_orcamento_id
      AND it.item_id = ia.item_id
      AND ia.abatimento_id = ab.abatimento_id;
   --
   IF v_retorno IS NULL OR v_data_aux > v_retorno THEN
    v_retorno := v_data_aux;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_fechamento_retornar;
 --
 --
 FUNCTION itens_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/12/2007
  -- DESCRICAO: retorna os codigos dos itens associados a um determinado faturamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_faturamento_id IN faturamento.faturamento_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt                INTEGER;
  v_retorno           VARCHAR2(4000);
  v_exception         EXCEPTION;
  v_item              VARCHAR2(100);
  v_num_orcamento_ant VARCHAR2(10);
  v_prefixo           VARCHAR2(10);
  v_fim               INTEGER;
  --
  CURSOR c_fat IS
   SELECT DISTINCT it.item_id,
                   it.tipo_item,
                   it.num_seq,
                   decode(it.natureza_item,
                          'ENCARGO',
                          'ENCARGO-CUSTO',
                          'ENCARGO_HONOR',
                          'ENCARGO-HONOR',
                          'HONOR',
                          'HONORARIO',
                          it.natureza_item) natureza_item,
                   orcamento_pkg.numero_formatar2(oc.orcamento_id) AS num_orcamento
     FROM item_fatur fa,
          item       it,
          orcamento  oc
    WHERE fa.faturamento_id = p_faturamento_id
      AND fa.item_id = it.item_id
      AND it.orcamento_id = oc.orcamento_id
    ORDER BY num_orcamento,
             it.tipo_item,
             nvl(it.num_seq, 99999),
             natureza_item;
  --
 BEGIN
  v_retorno           := NULL;
  v_num_orcamento_ant := NULL;
  v_prefixo           := NULL;
  v_fim               := 0;
  --
  FOR r_fat IN c_fat
  LOOP
   --
   IF nvl(v_num_orcamento_ant, 'XXXXX') <> r_fat.num_orcamento THEN
    -- quebrou a estimativa. Imprime o prefixo.
    v_prefixo           := '; ' || r_fat.num_orcamento || ':';
    v_num_orcamento_ant := r_fat.num_orcamento;
   ELSE
    v_prefixo := ',';
   END IF;
   --
   IF r_fat.natureza_item = 'CUSTO' THEN
    v_item := r_fat.tipo_item || to_char(r_fat.num_seq);
   ELSE
    v_item := r_fat.natureza_item || '-' || r_fat.tipo_item;
   END IF;
   --
   IF nvl(length(v_retorno), 0) <= 800 THEN
    v_retorno := TRIM(v_retorno || v_prefixo || ' ' || v_item);
   ELSIF v_fim = 0 THEN
    v_fim     := 1;
    v_retorno := TRIM(v_retorno || ' ...');
   END IF;
  END LOOP;
  --
  -- retira a primeira virgula
  v_retorno := substr(v_retorno, 3);
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END itens_retornar;
 --
 --
 FUNCTION nf_fornec_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/09/2013
  -- DESCRICAO: retorna o id da nota fiscal de fornecedor associado a um faturamento de BV.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_faturamento_id IN faturamento.faturamento_id%TYPE
 ) RETURN INTEGER AS
  v_qt        INTEGER;
  v_retorno   INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MIN(nota_fiscal_id)
    INTO v_retorno
    FROM item_fatur  it,
         faturamento fa
   WHERE fa.faturamento_id = p_faturamento_id
     AND fa.faturamento_id = it.faturamento_id
     AND fa.flag_bv = 'S';
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END nf_fornec_id_retornar;
 --
--
END; -- FATURAMENTO_PKG

/
