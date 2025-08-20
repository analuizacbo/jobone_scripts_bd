--------------------------------------------------------
--  DDL for Package Body PARCELA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PARCELA_PKG" IS
 --
 --
 PROCEDURE arredondar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/12/2006
  -- DESCRICAO: subrotina que ajusta o valor da ultima parcela de um
  --   determinado item, de modo a evitar diferencas nos totais. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_valor_cli       NUMBER;
  v_valor_for       NUMBER;
  v_valor_definido  NUMBER;
  v_valor_parcelado NUMBER;
  v_valor_ajustado  NUMBER;
  v_exception       EXCEPTION;
  --
  CURSOR c_parcela IS
   SELECT parcela_id,
          valor_parcela,
          tipo_parcela
     FROM parcela
    WHERE item_id = p_item_id
      AND num_parcela = num_tot_parcelas;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE item_id = p_item_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(valor_aprovado, 0),
         nvl(valor_aprovado, 0)
    INTO v_valor_cli,
         v_valor_for
    FROM item
   WHERE item_id = p_item_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_parcela IN c_parcela
  LOOP
   IF r_parcela.tipo_parcela = 'CLI' THEN
    v_valor_definido := v_valor_cli;
   ELSIF r_parcela.tipo_parcela = 'FOR' THEN
    v_valor_definido := v_valor_for;
   END IF;
   --
   -- seleciona o valor total parcelado para o respectivo tipo de parcela
   SELECT nvl(SUM(valor_parcela), 0)
     INTO v_valor_parcelado
     FROM parcela
    WHERE item_id = p_item_id
      AND tipo_parcela = r_parcela.tipo_parcela;
   --
   -- verifica se precisa ajustar o valor
   IF v_valor_definido <> v_valor_parcelado THEN
    v_valor_ajustado := v_valor_definido - (v_valor_parcelado - r_parcela.valor_parcela);
    --
    IF v_valor_ajustado <= 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro no arredondamento das parcelas (valor negativo).';
     RAISE v_exception;
    END IF;
    --
    UPDATE parcela
       SET valor_parcela = v_valor_ajustado
     WHERE parcela_id = r_parcela.parcela_id;
   END IF;
  END LOOP;
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
 END arredondar;
 --
 --
 PROCEDURE parcelado_marcar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 01/02/2007
  -- DESCRICAO: subrotina que marca um determinado item como parcelado. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item
   WHERE item_id = p_item_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- marca o item como parcelado e gera historico do item
  UPDATE item
     SET flag_parcelado = 'S'
   WHERE item_id = p_item_id;
  --
  item_pkg.historico_gerar(p_usuario_sessao_id,
                           p_item_id,
                           'PARCEL',
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END parcelado_marcar;
 --
 --
 PROCEDURE simular
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/12/2006
  -- DESCRICAO: rotina que simula as datas de vencimento de um lote de itens, conforme a
  --  condicao de pagamento escolhida.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_condicao_pagto_id IN condicao_pagto.condicao_pagto_id%TYPE,
  p_vetor_num_parcela OUT VARCHAR2,
  p_vetor_data        OUT VARCHAR2,
  p_vetor_dia_semana  OUT VARCHAR2,
  p_vetor_perc        OUT VARCHAR2,
  p_vetor_valor       OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                     INTEGER;
  v_delimitador            CHAR(1);
  v_vetor_num_parcela      LONG;
  v_vetor_data             LONG;
  v_vetor_dia_semana       LONG;
  v_vetor_perc             LONG;
  v_vetor_valor            LONG;
  v_data_base              DATE;
  v_data_parcela           DATE;
  v_data_parcela_pri       DATE;
  v_num_dias_fatur_interno INTEGER;
  v_status_job             job.status%TYPE;
  v_tipo_num_dias_fatur    pessoa.tipo_num_dias_fatur%TYPE;
  v_num_dias_fatur_cli     pessoa.num_dias_fatur%TYPE;
  v_nome_item              VARCHAR2(1000);
  v_num_parcela            condicao_pagto_det.num_parcela%TYPE;
  v_valor_perc             condicao_pagto_det.valor_perc%TYPE;
  v_num_dias               condicao_pagto_det.num_dias%TYPE;
  v_dia_semana             VARCHAR2(10);
  v_valor                  NUMBER;
  v_vetor_item_id          LONG;
  v_item_id                item.item_id%TYPE;
  v_valor_aprovado         item.valor_aprovado%TYPE;
  v_valor_total            item.valor_aprovado%TYPE;
  v_exception              EXCEPTION;
  v_lbl_job                VARCHAR2(100);
  --
  CURSOR c_cond IS
   SELECT num_parcela,
          valor_perc,
          num_dias
     FROM condicao_pagto_det
    WHERE condicao_pagto_id = p_condicao_pagto_id
    ORDER BY num_parcela;
  --
 BEGIN
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
  SELECT jo.status,
         nvl(pc.num_dias_fatur, 0),
         nvl(pc.tipo_num_dias_fatur, 'C')
    INTO v_status_job,
         v_num_dias_fatur_cli,
         v_tipo_num_dias_fatur
    FROM job    jo,
         pessoa pc
   WHERE jo.job_id = p_job_id
     AND jo.cliente_id = pc.pessoa_id;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_condicao_pagto_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A condição de pagamento deve ser especificada.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM condicao_pagto
   WHERE condicao_pagto_id = p_condicao_pagto_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa condição de pagamento não existe.';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur_interno := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_DIAS_FATUR_INTERNO')),
                                  0);
  --
  IF v_num_dias_fatur_cli = 0 THEN
   v_num_dias_fatur_cli := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                        'NUM_DIAS_FATUR_CLI')),
                               0);
  END IF;
  --
  ------------------------------------------------------------
  -- somatoria dos valores dos itens
  ------------------------------------------------------------
  v_vetor_item_id := p_vetor_item_id;
  --
  v_delimitador := '|';
  v_valor_total := 0;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   --
   -- seleciona dados do item
   SELECT rtrim(tp.nome || ' ' || i.complemento),
          nvl(i.valor_aprovado, 0)
     INTO v_nome_item,
          v_valor_aprovado
     FROM item         i,
          tipo_produto tp
    WHERE i.item_id = v_item_id
      AND i.tipo_produto_id = tp.tipo_produto_id;
   --
   v_valor_total := v_valor_total + v_valor_aprovado;
  END LOOP; -- fim do loop por item
  --
  ------------------------------------------------------------
  -- simulacao do parcelamento
  ------------------------------------------------------------
  v_data_base := trunc(SYSDATE);
  --
  FOR r_cond IN c_cond
  LOOP
   v_num_parcela := r_cond.num_parcela;
   v_valor_perc  := r_cond.valor_perc;
   v_num_dias    := r_cond.num_dias;
   --
   IF v_valor_perc <> 0 THEN
    IF v_num_parcela = 1 THEN
     -- a data primeira parcela é a maior data dos dois calculos
     -- a seguir:
     v_data_parcela := v_data_base + v_num_dias_fatur_interno;
     --
     IF v_tipo_num_dias_fatur = 'C' THEN
      -- dias corridos
      v_data_parcela := v_data_parcela + v_num_dias_fatur_cli;
     ELSE
      -- dias uteis
      v_data_parcela := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_parcela,
                                                           v_num_dias_fatur_cli,
                                                           'N');
     END IF;
     --
     IF v_data_base + v_num_dias > v_data_parcela THEN
      v_data_parcela := v_data_base + v_num_dias;
     END IF;
     --
     v_data_parcela_pri := v_data_parcela;
    ELSE
     -- as demais parcelas seguem os dias da condicao de pagto
     -- selecionada.
     v_data_parcela := v_data_parcela_pri + v_num_dias;
    END IF;
    --
    -- aplica a regra da condicao de pagamento
    v_data_parcela := condicao_pagto_pkg.data_retornar(p_usuario_sessao_id,
                                                       p_condicao_pagto_id,
                                                       v_data_parcela);
    --
    IF v_data_parcela IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na aplicação da condição de pagamento.';
     RAISE v_exception;
    END IF;
    --
    v_valor      := round(v_valor_total * v_valor_perc / 100, 2);
    v_dia_semana := dia_semana_mostrar(v_data_parcela);
    --
    v_vetor_num_parcela := v_vetor_num_parcela || '|' || to_char(v_num_parcela);
    v_vetor_data        := v_vetor_data || '|' || data_mostrar(v_data_parcela);
    v_vetor_dia_semana  := v_vetor_dia_semana || '|' || v_dia_semana;
    v_vetor_perc        := v_vetor_perc || '|' || numero_mostrar(v_valor_perc, 4, 'N');
    v_vetor_valor       := v_vetor_valor || '|' || moeda_mostrar(v_valor, 'S');
   END IF;
   --
  END LOOP;
  --
  -- retira o primeiro pipe
  IF substr(v_vetor_num_parcela, 1, 1) = '|' THEN
   v_vetor_num_parcela := substr(v_vetor_num_parcela, 2);
   v_vetor_data        := substr(v_vetor_data, 2);
   v_vetor_dia_semana  := substr(v_vetor_dia_semana, 2);
   v_vetor_perc        := substr(v_vetor_perc, 2);
   v_vetor_valor       := substr(v_vetor_valor, 2);
  END IF;
  --
  p_vetor_num_parcela := v_vetor_num_parcela;
  p_vetor_data        := v_vetor_data;
  p_vetor_dia_semana  := v_vetor_dia_semana;
  p_vetor_perc        := v_vetor_perc;
  p_vetor_valor       := v_vetor_valor;
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
 END simular;
 --
 --
 PROCEDURE simulacao_gravar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/12/2006
  -- DESCRICAO: gera o parcelamento para os itens selecionados, de acordo com as datas e
  --  percentuais passados nos vetores.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_datas       IN VARCHAR2,
  p_vetor_perc        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_status_job             job.status%TYPE;
  v_numero_job             job.numero%TYPE;
  v_num_orcamento          orcamento.num_orcamento%TYPE;
  v_orcamento_id           orcamento.orcamento_id%TYPE;
  v_num_parcela            parcela.num_parcela%TYPE;
  v_valor_parcela          parcela.valor_parcela%TYPE;
  v_parcela_id             parcela.parcela_id%TYPE;
  v_num_dias_fatur_interno INTEGER;
  v_num_dias_fatur_cli     INTEGER;
  v_num_dias_fornec        INTEGER;
  v_num_dias_bv            INTEGER;
  v_vetor_item_id          LONG;
  v_item_id                item.item_id%TYPE;
  v_valor_aprovado         item.valor_aprovado%TYPE;
  v_valor_fornecedor       item.valor_fornecedor%TYPE;
  v_tipo_item              item.tipo_item%TYPE;
  v_flag_sem_valor         item.flag_sem_valor%TYPE;
  v_nome_item              VARCHAR2(1000);
  v_delimitador            CHAR(1);
  v_vetor_datas            LONG;
  v_vetor_perc             LONG;
  v_data_parcela           DATE;
  v_data_parcela_ant       DATE;
  v_data_notif_fatur       DATE;
  v_perc                   NUMBER;
  v_perc_acumulado         NUMBER;
  v_data_parcela_char      VARCHAR2(20);
  v_perc_char              VARCHAR2(20);
  v_precisao_arredon       NUMBER;
  v_exception              EXCEPTION;
  v_lbl_job                VARCHAR2(100);
  --
 BEGIN
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur_interno := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_DIAS_FATUR_INTERNO')),
                                  0);
  --
  v_num_dias_fatur_cli := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_FATUR_CLI')),
                              0);
  --
  v_num_dias_fornec := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                    'NUM_DIAS_FORNEC')),
                           0);
  --
  v_num_dias_bv := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_BV')),
                       0);
  --
  v_precisao_arredon := 0.04;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_item_id := p_vetor_item_id;
  v_delimitador   := '|';
  --
  --------------------------
  -- loop por item no vetor
  --------------------------
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   --
   -- seleciona dados do item
   SELECT rtrim(tp.nome || ' ' || i.complemento),
          nvl(i.valor_aprovado, 0),
          nvl(i.valor_fornecedor, 0),
          i.orcamento_id,
          i.tipo_item,
          i.flag_sem_valor
     INTO v_nome_item,
          v_valor_aprovado,
          v_valor_fornecedor,
          v_orcamento_id,
          v_tipo_item,
          v_flag_sem_valor
     FROM item         i,
          tipo_produto tp
    WHERE i.item_id = v_item_id
      AND i.tipo_produto_id = tp.tipo_produto_id;
   --
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'PARCELA_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   -- verifica se o item pode ser parcelado
   SELECT COUNT(*)
     INTO v_qt
     FROM parcela
    WHERE item_id = v_item_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item já foi parcelado (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   v_num_parcela      := 0;
   v_perc_acumulado   := 0;
   v_vetor_datas      := p_vetor_datas;
   v_vetor_perc       := p_vetor_perc;
   v_data_parcela_ant := data_converter('01/01/1970');
   --
   -- verifica se o item tem valor a ser parcelado
   IF v_flag_sem_valor = 'N' THEN
    --------------------------
    -- loop por data no vetor
    --------------------------
    WHILE nvl(length(rtrim(v_vetor_datas)), 0) > 0
    LOOP
     v_data_parcela_char := prox_valor_retornar(v_vetor_datas, v_delimitador);
     v_perc_char         := prox_valor_retornar(v_vetor_perc, v_delimitador);
     --
     IF data_validar(v_data_parcela_char) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Data inválida (' || v_data_parcela_char || ').';
      RAISE v_exception;
     END IF;
     --
     IF numero_validar(v_perc_char) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Percentual inválido (' || v_perc_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_data_parcela := data_converter(v_data_parcela_char);
     v_perc         := nvl(numero_converter(v_perc_char), 0);
     --
     IF v_data_parcela IS NOT NULL AND v_perc = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Percentual inválido para a parcela com data de ' ||
                    data_mostrar(v_data_parcela) || '.';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NULL AND v_perc > 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Data inválida para a parcela com percentual de ' ||
                    numero_mostrar(v_perc, 4, 'N') || ' %.';
      RAISE v_exception;
     END IF;
     --
     IF v_data_parcela IS NOT NULL THEN
      IF v_data_parcela <= v_data_parcela_ant THEN
       p_erro_cod := '90000';
       p_erro_msg := 'As datas de vencimento das parcelas devem estar em ordem crescente.';
       RAISE v_exception;
      END IF;
      --
      v_num_parcela      := v_num_parcela + 1;
      v_perc_acumulado   := v_perc_acumulado + v_perc;
      v_data_parcela_ant := v_data_parcela;
     END IF;
     --
     -------------------------------------------------
     -- cria a parcela do cliente
     -------------------------------------------------
     v_valor_parcela    := round(v_valor_aprovado * v_perc / 100, 2);
     v_data_notif_fatur := v_data_parcela - nvl(v_num_dias_fatur_cli, 0) -
                           nvl(v_num_dias_fatur_interno, 0);
     --
     IF v_valor_parcela > 0 AND v_data_parcela IS NOT NULL THEN
      SELECT seq_parcela.nextval
        INTO v_parcela_id
        FROM dual;
      --
      INSERT INTO parcela
       (parcela_id,
        item_id,
        num_parcela,
        num_tot_parcelas,
        valor_parcela,
        data_notif_fatur,
        data_parcela,
        tipo_parcela)
      VALUES
       (v_parcela_id,
        v_item_id,
        v_num_parcela,
        0,
        v_valor_parcela,
        v_data_notif_fatur,
        v_data_parcela,
        'CLI');
     END IF;
     --
     -------------------------------------------------
     -- cria a parcela do fornecedor
     -------------------------------------------------
     --v_valor_parcela := ROUND(v_valor_fornecedor * v_perc / 100,2);
     v_valor_parcela    := round(v_valor_aprovado * v_perc / 100, 2);
     v_data_parcela     := v_data_parcela + nvl(v_num_dias_fornec, 0);
     v_data_notif_fatur := v_data_parcela - nvl(v_num_dias_fatur_cli, 0) -
                           nvl(v_num_dias_fatur_interno, 0);
     --
     IF v_valor_parcela > 0 AND v_data_parcela IS NOT NULL THEN
      SELECT seq_parcela.nextval
        INTO v_parcela_id
        FROM dual;
      --
      INSERT INTO parcela
       (parcela_id,
        item_id,
        num_parcela,
        num_tot_parcelas,
        valor_parcela,
        data_notif_fatur,
        data_parcela,
        tipo_parcela)
      VALUES
       (v_parcela_id,
        v_item_id,
        v_num_parcela,
        0,
        v_valor_parcela,
        v_data_notif_fatur,
        v_data_parcela,
        'FOR');
     END IF;
     --
    END LOOP; -- fim do loop por data
    --
    IF abs(v_perc_acumulado - 100.00) > v_precisao_arredon THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A soma dos percentuais deve corresponder a 100 %.';
     RAISE v_exception;
    END IF;
    --
    -- acerta o total de parcelas
    UPDATE parcela
       SET num_tot_parcelas = v_num_parcela
     WHERE item_id = v_item_id;
    --
    -------------------------------------------------
    -- atualizacoes finais
    -------------------------------------------------
    -- arredondamento do valor total da ultima parcela
    parcela_pkg.arredondar(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    -- marca o item como parcelado e gera historico do item
    parcela_pkg.parcelado_marcar(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
   END IF; -- fim do IF v_flag_sem_valor = 'N'
  --
  END LOOP; -- fim do loop por item
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF v_orcamento_id IS NOT NULL THEN
   SELECT num_orcamento
     INTO v_num_orcamento
     FROM orcamento
    WHERE orcamento_id = v_orcamento_id;
   --
   v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                       to_char(v_num_orcamento);
   v_compl_histor   := 'Parcelamento de itens';
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
                    NULL,
                    v_historico_id,
                    p_erro_cod,
                    p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
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
   ROLLBACK;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END simulacao_gravar;
 --
 --
 PROCEDURE atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2006
  -- DESCRICAO: atualizacao manual do parcelamento de um determinado item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_vetor_cli_valor   IN VARCHAR2,
  p_vetor_cli_data    IN VARCHAR2,
  p_vetor_for_valor   IN VARCHAR2,
  p_vetor_for_data    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_numero_job             job.numero%TYPE;
  v_num_orcamento          orcamento.num_orcamento%TYPE;
  v_orcamento_id           orcamento.orcamento_id%TYPE;
  v_num_parcela            parcela.num_parcela%TYPE;
  v_valor_parcela          parcela.valor_parcela%TYPE;
  v_parcela_id             parcela.parcela_id%TYPE;
  v_num_dias_fatur_cli     INTEGER;
  v_num_dias_fatur_interno INTEGER;
  v_num_dias_fornec        INTEGER;
  v_num_dias_bv            INTEGER;
  v_valor_aprovado         item.valor_aprovado%TYPE;
  v_valor_fornecedor       item.valor_fornecedor%TYPE;
  v_tipo_item              item.tipo_item%TYPE;
  v_flag_sem_valor         item.flag_sem_valor%TYPE;
  v_nome_item              VARCHAR2(1000);
  v_delimitador            CHAR(1);
  v_vetor_valor            LONG;
  v_vetor_data             LONG;
  v_valor_char             VARCHAR2(20);
  v_data_char              VARCHAR2(20);
  v_data_parcela           DATE;
  v_data_parcela_ant       DATE;
  v_data_notif_fatur       DATE;
  v_perc                   NUMBER;
  v_valor_acumulado        NUMBER;
  v_precisao_arredon       NUMBER;
  v_exception              EXCEPTION;
  v_lbl_job                VARCHAR2(100);
  --
 BEGIN
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
  IF v_qt = 0 THEN
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
         rtrim(t.nome || ' ' || i.complemento),
         nvl(i.valor_aprovado, 0),
         nvl(i.valor_fornecedor, 0),
         i.tipo_item,
         i.flag_sem_valor
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id,
         v_nome_item,
         v_valor_aprovado,
         v_valor_fornecedor,
         v_tipo_item,
         v_flag_sem_valor
    FROM job          j,
         orcamento    o,
         item         i,
         tipo_produto t
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND i.tipo_produto_id = t.tipo_produto_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PARCELA_C',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_sem_valor = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não pode ser parcelado pois está marcado como "sem valor".';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_fatur_interno := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_DIAS_FATUR_INTERNO')),
                                  0);
  --
  v_num_dias_fatur_cli := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_DIAS_FATUR_CLI')),
                              0);
  --
  v_num_dias_fornec := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                    'NUM_DIAS_FORNEC')),
                           0);
  --
  v_num_dias_bv := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_BV')),
                       0);
  --
  v_precisao_arredon := 0.04;
  --
  DELETE FROM parcela
   WHERE item_id = p_item_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores do cliente
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_num_parcela      := 0;
  v_valor_acumulado  := 0;
  v_data_parcela_ant := data_converter('01/01/1970');
  --
  v_vetor_valor := p_vetor_cli_valor;
  v_vetor_data  := p_vetor_cli_data;
  --
  WHILE nvl(length(rtrim(v_vetor_valor)), 0) > 0
  LOOP
   v_valor_char := prox_valor_retornar(v_vetor_valor, v_delimitador);
   v_data_char  := prox_valor_retornar(v_vetor_data, v_delimitador);
   --
   IF moeda_validar(v_valor_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido para a parcela do cliente (' || v_valor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida para a parcela do cliente (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_parcela := nvl(moeda_converter(v_valor_char), 0);
   v_data_parcela  := data_converter(v_data_char);
   --
   IF v_data_parcela IS NOT NULL AND v_valor_parcela <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido para a parcela do cliente com data de ' ||
                  data_mostrar(v_data_parcela) || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_data_parcela IS NULL AND v_valor_parcela <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida para a parcela do cliente com valor de ' ||
                  moeda_mostrar(v_valor_parcela, 'S') || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_data_parcela IS NOT NULL THEN
    IF v_data_parcela <= v_data_parcela_ant THEN
     p_erro_cod := '90000';
     p_erro_msg := 'As datas de vencimento das parcelas do cliente ' ||
                   'devem estar em ordem crescente.';
     RAISE v_exception;
    END IF;
    --
    v_num_parcela      := v_num_parcela + 1;
    v_valor_acumulado  := v_valor_acumulado + v_valor_parcela;
    v_data_parcela_ant := v_data_parcela;
   END IF;
   --
   -------------------------------------------------
   -- cria a parcela do cliente
   -------------------------------------------------
   v_data_notif_fatur := v_data_parcela - nvl(v_num_dias_fatur_cli, 0) -
                         nvl(v_num_dias_fatur_interno, 0);
   --
   IF v_valor_parcela > 0 AND v_data_parcela IS NOT NULL THEN
    SELECT seq_parcela.nextval
      INTO v_parcela_id
      FROM dual;
    --
    INSERT INTO parcela
     (parcela_id,
      item_id,
      num_parcela,
      num_tot_parcelas,
      valor_parcela,
      data_notif_fatur,
      data_parcela,
      tipo_parcela)
    VALUES
     (v_parcela_id,
      p_item_id,
      v_num_parcela,
      0,
      v_valor_parcela,
      v_data_notif_fatur,
      v_data_parcela,
      'CLI');
   END IF;
  END LOOP; -- fim do loop do cliente
  --
  IF v_valor_aprovado > 0 THEN
   IF abs(v_valor_acumulado - v_valor_aprovado) > v_precisao_arredon THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Somatória das parcelas do cliente não bate ' ||
                  'com o valor a ser parcelado.';
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela
      SET num_tot_parcelas = v_num_parcela
    WHERE item_id = p_item_id
      AND tipo_parcela = 'CLI';
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores do fornecedor
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_num_parcela      := 0;
  v_valor_acumulado  := 0;
  v_data_parcela_ant := data_converter('01/01/1970');
  --
  v_vetor_valor := p_vetor_for_valor;
  v_vetor_data  := p_vetor_for_data;
  --
  WHILE nvl(length(rtrim(v_vetor_valor)), 0) > 0
  LOOP
   v_valor_char := prox_valor_retornar(v_vetor_valor, v_delimitador);
   v_data_char  := prox_valor_retornar(v_vetor_data, v_delimitador);
   --
   IF moeda_validar(v_valor_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido para a parcela do fornecedor (' || v_valor_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida para a parcela do fornecedor (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_parcela := nvl(moeda_converter(v_valor_char), 0);
   v_data_parcela  := data_converter(v_data_char);
   --
   IF v_data_parcela IS NOT NULL AND v_valor_parcela <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido para a parcela do fornecedor com data de ' ||
                  data_mostrar(v_data_parcela) || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_data_parcela IS NULL AND v_valor_parcela <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida para a parcela do fornecedor com valor de ' ||
                  moeda_mostrar(v_valor_parcela, 'S') || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_data_parcela IS NOT NULL THEN
    IF v_data_parcela <= v_data_parcela_ant THEN
     p_erro_cod := '90000';
     p_erro_msg := 'As datas de vencimento das parcelas do fornecedor ' ||
                   'devem estar em ordem crescente.';
     RAISE v_exception;
    END IF;
    --
    v_num_parcela      := v_num_parcela + 1;
    v_valor_acumulado  := v_valor_acumulado + v_valor_parcela;
    v_data_parcela_ant := v_data_parcela;
   END IF;
   --
   -------------------------------------------------
   -- cria a parcela do fornecedor
   -------------------------------------------------
   v_data_notif_fatur := v_data_parcela - nvl(v_num_dias_fatur_cli, 0) -
                         nvl(v_num_dias_fatur_interno, 0);
   --
   IF v_valor_parcela > 0 AND v_data_parcela IS NOT NULL THEN
    SELECT seq_parcela.nextval
      INTO v_parcela_id
      FROM dual;
    --
    INSERT INTO parcela
     (parcela_id,
      item_id,
      num_parcela,
      num_tot_parcelas,
      valor_parcela,
      data_notif_fatur,
      data_parcela,
      tipo_parcela)
    VALUES
     (v_parcela_id,
      p_item_id,
      v_num_parcela,
      0,
      v_valor_parcela,
      v_data_notif_fatur,
      v_data_parcela,
      'FOR');
   END IF;
  END LOOP; -- fim do loop do fornecedor
  --
  IF v_valor_aprovado > 0 THEN
   IF abs(v_valor_acumulado - v_valor_aprovado) > v_precisao_arredon THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Somatória das parcelas do fornecedor não bate ' ||
                  'com o valor a ser parcelado.';
    RAISE v_exception;
   END IF;
   --
   -- acerta o total de parcelas
   UPDATE parcela
      SET num_tot_parcelas = v_num_parcela
    WHERE item_id = p_item_id
      AND tipo_parcela = 'FOR';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  parcela_pkg.arredondar(p_usuario_sessao_id, p_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  -- marca o item como parcelado e gera historico do item
  parcela_pkg.parcelado_marcar(p_usuario_sessao_id, p_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                      to_char(v_num_orcamento);
  v_compl_histor   := 'Parcelamento de item (' || v_nome_item || ')';
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
   ROLLBACK;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
 END atualizar;
 --
 --
 PROCEDURE desparcelar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2006
  -- DESCRICAO: desfaz o parcelamento de um determinado item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_flag_parcelado item.flag_parcelado%TYPE;
  v_complemento    item.complemento%TYPE;
  v_flag_sem_valor item.flag_sem_valor%TYPE;
  v_nome_produto   tipo_produto.nome%TYPE;
  v_exception      EXCEPTION;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
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
  IF v_qt = 0 THEN
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
         i.flag_parcelado,
         i.complemento,
         t.nome,
         i.flag_sem_valor
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id,
         v_flag_parcelado,
         v_complemento,
         v_nome_produto,
         v_flag_sem_valor
    FROM job          j,
         orcamento    o,
         item         i,
         tipo_produto t
   WHERE i.item_id = p_item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND i.tipo_produto_id = t.tipo_produto_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'PARCELA_C',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job <> 'ANDA' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_parcelado = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não se encontra parcelado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_sem_valor = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não pode ser desparcelado pois está marcado como "sem valor".';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM parcela
   WHERE item_id = p_item_id;
  --
  UPDATE item
     SET flag_parcelado = 'N',
         status_fatur   = 'NLIB'
   WHERE item_id = p_item_id;
  --
  item_pkg.historico_gerar(p_usuario_sessao_id,
                           p_item_id,
                           'DESPARCEL',
                           NULL,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                      to_char(v_num_orcamento);
  v_compl_histor   := 'Desparcelamento de item (' ||
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END desparcelar;
 --
--
END; -- PARCELA_PKG



/
