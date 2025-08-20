--------------------------------------------------------
--  DDL for Package Body SOBRA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SOBRA_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/03/2008
  -- DESCRICAO: Inclusão de SOBRA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  -- Silvia            05/08/2008  Consistencia de abatimento automatico.
  -- Silvia            29/10/2020  Novo flag para indicar sobra criada dentro da carta acordo
  -- Joel Dias         22/09/2023  Inclusão do parâmetro de entrada p_flag_commit
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN sobra.job_id%TYPE,
  p_carta_acordo_id   IN sobra.carta_acordo_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_valor_sobra IN VARCHAR2,
  p_tipo_sobra        IN sobra.tipo_sobra%TYPE,
  p_tipo_extra        IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_sobra_id          OUT sobra.sobra_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_num_job           job.numero%TYPE;
  v_nome_job          job.nome%TYPE;
  v_cliente_id        job.cliente_id%TYPE;
  v_num_carta         carta_acordo.num_carta_acordo%TYPE;
  v_sobra_id          sobra.sobra_id%TYPE;
  v_valor_sobra_tot   sobra.valor_sobra%TYPE;
  v_valor_cred_tot    sobra.valor_cred_cliente%TYPE;
  v_flag_dentro_ca    sobra.flag_dentro_ca%TYPE;
  v_item_sobra_id     item_sobra.item_sobra_id%TYPE;
  v_valor_sobra_item  item_sobra.valor_sobra_item%TYPE;
  v_valor_cred_item   item_sobra.valor_cred_item%TYPE;
  v_item_id           item_sobra.item_id%TYPE;
  v_flag_abate_fatur  item_sobra.flag_abate_fatur%TYPE;
  v_orcamento_id      item.orcamento_id%TYPE;
  v_tipo_item         item.tipo_item%TYPE;
  v_flag_pago_cliente item.flag_pago_cliente%TYPE;
  v_delimitador       CHAR(1);
  v_vetor_item_id     VARCHAR2(2000);
  v_vetor_valor_sobra VARCHAR2(2000);
  v_valor_sobra_char  VARCHAR2(20);
  v_nome_item         VARCHAR2(100);
  v_lancamento_id     lancamento.lancamento_id%TYPE;
  v_operador          lancamento.operador%TYPE;
  v_descricao         lancamento.descricao%TYPE;
  v_valor_pend        NUMBER;
  v_tipo_sobra_desc   VARCHAR2(100);
  v_abatimento_id     abatimento.abatimento_id%TYPE;
  v_lbl_job           VARCHAR2(100);
  v_xml_atual         CLOB;
  v_permitir_sobra_a  VARCHAR2(1);
  --
 BEGIN
  v_qt       := 0;
  p_sobra_id := 0;
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  v_valor_sobra_tot := 0;
  v_valor_cred_tot  := 0;
  v_flag_dentro_ca  := 'N';
  --
  v_permitir_sobra_a := empresa_pkg.parametro_retornar(p_empresa_id, 'PERMITIR_SOBRA_A');
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
  SELECT numero,
         cliente_id,
         nome
    INTO v_num_job,
         v_cliente_id,
         v_nome_job
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_carta_acordo_id, 0) > 0 THEN
   v_flag_dentro_ca := 'S';
   --
   -- sobra de carta acordo
   SELECT COUNT(*)
     INTO v_qt
     FROM carta_acordo
    WHERE carta_acordo_id = p_carta_acordo_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa carta acordo não existe.';
    RAISE v_exception;
   END IF;
   --
   SELECT num_carta_acordo
     INTO v_num_carta
     FROM carta_acordo
    WHERE carta_acordo_id = p_carta_acordo_id;
  END IF;
  --
  IF TRIM(p_vetor_item_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum item foi passado no vetor.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_valor_sobra) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor de sobra foi especificado.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_sobra) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de sobra é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_tipo_sobra_desc := util_pkg.desc_retornar('tipo_sobra', p_tipo_sobra);
  --
  IF v_tipo_sobra_desc IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de sobra inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_sobra = 'SNP' AND rtrim(p_tipo_extra) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo extra é obrigatório para serviço não prestado.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_extra NOT IN ('CRED', 'ABAT') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo extra inválido (' || p_tipo_extra || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_sobra = 'SNP' AND p_tipo_extra = 'ABAT' THEN
   v_flag_abate_fatur := 'S';
  ELSE
   v_flag_abate_fatur := 'N';
  END IF;
  --
  IF rtrim(p_justificativa) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da justificativa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_justificativa) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da justificativa não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_sobra.nextval
    INTO v_sobra_id
    FROM dual;
  --
  INSERT INTO sobra
   (sobra_id,
    job_id,
    carta_acordo_id,
    usuario_resp_id,
    data_entrada,
    tipo_sobra,
    justificativa,
    valor_sobra,
    valor_cred_cliente,
    flag_dentro_ca)
  VALUES
   (v_sobra_id,
    p_job_id,
    zvl(p_carta_acordo_id, NULL),
    p_usuario_sessao_id,
    SYSDATE,
    p_tipo_sobra,
    TRIM(p_justificativa),
    0,
    0,
    v_flag_dentro_ca);
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  v_vetor_item_id     := p_vetor_item_id;
  v_vetor_valor_sobra := p_vetor_valor_sobra;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id          := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_sobra_char := prox_valor_retornar(v_vetor_valor_sobra, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT item_pkg.num_item_retornar(it.item_id, 'N'),
          tipo_item,
          flag_pago_cliente,
          orcamento_id
     INTO v_nome_item,
          v_tipo_item,
          v_flag_pago_cliente,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'SOBRA_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 AND p_flag_commit = 'S' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF p_tipo_extra = 'CRED' AND p_flag_commit = 'S' THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                  'SOBRA_CCA',
                                  v_orcamento_id,
                                  NULL,
                                  p_empresa_id) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para indicar um crédito para o cliente.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_tipo_item = 'A' AND p_tipo_sobra = 'SOB' AND v_permitir_sobra_a = 'N' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Itens de A não podem ter sobra, aceitando apenas serviços não prestados.';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_pago_cliente = 'S' THEN
    -- deixa entrar servico nao prestado sem abatimento automatico
    v_flag_abate_fatur := 'N';
   ELSE
    IF v_tipo_item = 'A' AND p_tipo_extra <> 'ABAT' THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Serviços não prestados em A devem ser abatidos do faturamento.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF moeda_validar(v_valor_sobra_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (Item: ' || v_nome_item || ' Valor: ' || v_valor_sobra_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_sobra_item := nvl(moeda_converter(v_valor_sobra_char), 0);
   v_valor_sobra_tot  := v_valor_sobra_tot + v_valor_sobra_item;
   --
   IF v_valor_sobra_item < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (Item: ' || v_nome_item || ' Valor: ' || v_valor_sobra_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_carta_acordo_id, 0) > 0 THEN
    v_valor_pend := item_pkg.valor_retornar(v_item_id, p_carta_acordo_id, 'SEM_NF');
   ELSE
    v_valor_pend := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   END IF;
   --
   IF v_valor_sobra_item > v_valor_pend THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não tem saldo suficiente para essa sobra (Item: ' || v_nome_item ||
                  ' - Saldo: ' || moeda_mostrar(v_valor_pend, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_tipo_extra = 'CRED' AND v_valor_sobra_item > 0 THEN
    v_valor_cred_item := v_valor_sobra_item;
    v_valor_cred_tot  := v_valor_cred_tot + v_valor_cred_item;
   ELSE
    v_valor_cred_item := 0;
   END IF;
   --
   IF v_valor_sobra_item > 0 THEN
    SELECT seq_item_sobra.nextval
      INTO v_item_sobra_id
      FROM dual;
    --
    INSERT INTO item_sobra
     (item_sobra_id,
      item_id,
      sobra_id,
      valor_sobra_item,
      valor_cred_item,
      flag_abate_fatur)
    VALUES
     (v_item_sobra_id,
      v_item_id,
      v_sobra_id,
      v_valor_sobra_item,
      v_valor_cred_item,
      v_flag_abate_fatur);
    --
    IF v_flag_abate_fatur = 'N' THEN
     -- verifica se existe abatimento de mesmo valor registrado para esse item
     -- e sem vinculo com sobras
     -- (abatimento com apenas 1 item, em que o valor total bate com o valor
     -- abatido no item).
     SELECT MAX(ab.abatimento_id)
       INTO v_abatimento_id
       FROM abatimento ab,
            item_abat  ia
      WHERE ia.item_id = v_item_id
        AND ia.valor_abat_item = v_valor_sobra_item
        AND ab.valor_abat = ia.valor_abat_item
        AND ia.abatimento_id = ab.abatimento_id
        AND nvl(ab.carta_acordo_id, -999) = zvl(p_carta_acordo_id, -999)
        AND ab.sobra_id IS NULL;
     --
     IF v_abatimento_id IS NOT NULL THEN
      -- marca a sobra como vinculada a um abatimento
      UPDATE item_sobra
         SET flag_abate_fatur = 'S'
       WHERE item_sobra_id = v_item_sobra_id;
      --
      UPDATE sobra
         SET tipo_sobra = 'SNP'
       WHERE sobra_id = v_sobra_id;
      --
      UPDATE abatimento
         SET sobra_id = v_sobra_id
       WHERE abatimento_id = v_abatimento_id;
     END IF;
    END IF;
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  IF v_valor_sobra_tot = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum valor de sobra foi informado';
   RAISE v_exception;
  END IF;
  --
  UPDATE sobra
     SET valor_sobra        = v_valor_sobra_tot,
         valor_cred_cliente = v_valor_cred_tot
   WHERE sobra_id = v_sobra_id;
  --
  ------------------------------------------------------------
  -- credito para o cliente
  ------------------------------------------------------------
  IF v_valor_cred_tot > 0 THEN
   SELECT apelido
     INTO v_operador
     FROM pessoa
    WHERE usuario_id = p_usuario_sessao_id;
   --
   v_descricao := v_tipo_sobra_desc || ', ' || v_lbl_job || ' ' || to_char(v_num_job) || ' - ' ||
                  v_nome_job || ', ';
   --
   IF nvl(p_carta_acordo_id, 0) > 0 THEN
    v_descricao := v_descricao || 'Carta Acordo ' || TRIM(to_char(v_num_carta, '0000'));
   ELSE
    v_descricao := v_descricao || 'Item ' || v_nome_item;
   END IF;
   --
   SELECT seq_lancamento.nextval
     INTO v_lancamento_id
     FROM dual;
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
    (v_lancamento_id,
     v_cliente_id,
     SYSDATE,
     v_descricao,
     v_valor_cred_tot,
     'E',
     v_operador,
     p_justificativa);
  END IF;
  --
  ------------------------------------------------------------
  -- abatimento automatico
  ------------------------------------------------------------
  IF v_flag_abate_fatur = 'S' THEN
   -- gera abatimento automatico para os itens dessa sobra
   abatimento_pkg.auto_abater(p_usuario_sessao_id,
                              p_empresa_id,
                              v_sobra_id,
                              v_abatimento_id,
                              p_erro_cod,
                              p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sobra_pkg.xml_gerar(v_sobra_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(p_carta_acordo_id, 0) > 0 THEN
   v_identif_objeto := 'Carta Acordo: ' || to_char(v_num_job) || '/' || to_char(v_num_carta) ||
                       ' Valor: ' || moeda_mostrar(v_valor_sobra_tot, 'S');
  ELSE
   v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item || ' Valor: ' ||
                       moeda_mostrar(v_valor_sobra_tot, 'S');
  END IF;
  --
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SOBRA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_sobra_id,
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
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_sobra_id := v_sobra_id;
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
 END; -- adicionar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/03/2008
  -- DESCRICAO: Exclusão de SOBRA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_sobra_id          IN sobra.sobra_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_num_job            job.numero%TYPE;
  v_nome_job           job.nome%TYPE;
  v_job_id             job.job_id%TYPE;
  v_cliente_id         job.cliente_id%TYPE;
  v_carta_acordo_id    carta_acordo.carta_acordo_id%TYPE;
  v_num_carta          carta_acordo.num_carta_acordo%TYPE;
  v_valor_sobra        sobra.valor_sobra%TYPE;
  v_valor_cred_cliente sobra.valor_cred_cliente%TYPE;
  v_nome_item          VARCHAR2(100);
  v_operador           lancamento.operador%TYPE;
  v_descricao          lancamento.descricao%TYPE;
  v_abatimento_id      abatimento.abatimento_id%TYPE;
  v_flag_debito_cli    abatimento.flag_debito_cli%TYPE;
  v_valor_abat         abatimento.valor_abat%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  --
  CURSOR c_it IS
   SELECT io.item_sobra_id,
          io.item_id,
          it.orcamento_id
     FROM item_sobra io,
          item       it
    WHERE io.sobra_id = p_sobra_id
      AND io.item_id = it.item_id;
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
    FROM sobra so,
         job   jo
   WHERE so.sobra_id = p_sobra_id
     AND so.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa sobra não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT so.carta_acordo_id,
         so.valor_sobra,
         so.valor_cred_cliente,
         jo.numero,
         jo.cliente_id,
         jo.nome,
         jo.job_id
    INTO v_carta_acordo_id,
         v_valor_sobra,
         v_valor_cred_cliente,
         v_num_job,
         v_cliente_id,
         v_nome_job,
         v_job_id
    FROM sobra so,
         job   jo
   WHERE so.sobra_id = p_sobra_id
     AND so.job_id = jo.job_id;
  --
  IF v_carta_acordo_id IS NULL THEN
   SELECT MAX(item_pkg.num_item_retornar(it.item_id, 'N'))
     INTO v_nome_item
     FROM item_sobra so,
          item       it
    WHERE so.sobra_id = p_sobra_id
      AND so.item_id = it.item_id;
  ELSE
   SELECT num_carta_acordo
     INTO v_num_carta
     FROM carta_acordo
    WHERE carta_acordo_id = v_carta_acordo_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  sobra_pkg.xml_gerar(p_sobra_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (abatimento vinculado)
  ------------------------------------------------------------
  SELECT MAX(abatimento_id)
    INTO v_abatimento_id
    FROM abatimento
   WHERE sobra_id = p_sobra_id;
  --
  IF v_abatimento_id IS NOT NULL THEN
   SELECT flag_debito_cli,
          valor_abat
     INTO v_flag_debito_cli,
          v_valor_abat
     FROM abatimento
    WHERE abatimento_id = v_abatimento_id;
   --
   -- exclui abatimento vinculado a essa sobra
   DELETE FROM item_abat
    WHERE abatimento_id = v_abatimento_id;
   --
   DELETE FROM abatimento
    WHERE abatimento_id = v_abatimento_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (excusao da sobra)
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'SOBRA_E',
                                 r_it.orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM item_sobra
    WHERE item_sobra_id = r_it.item_sobra_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM sobra
   WHERE sobra_id = p_sobra_id;
  --
  ------------------------------------------------------------
  -- estorno do credito para o cliente
  ------------------------------------------------------------
  IF v_valor_cred_cliente > 0 THEN
   SELECT apelido
     INTO v_operador
     FROM pessoa
    WHERE usuario_id = p_usuario_sessao_id;
   --
   v_descricao := v_lbl_job || ' ' || to_char(v_num_job) || ' - ' || v_nome_job || ', ';
   --
   IF nvl(v_carta_acordo_id, 0) > 0 THEN
    v_descricao := v_descricao || 'Carta Acordo ' || TRIM(to_char(v_num_carta, '0000'));
   ELSE
    v_descricao := v_descricao || 'Item ' || v_nome_item;
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
     v_cliente_id,
     SYSDATE,
     v_descricao,
     v_valor_cred_cliente,
     'S',
     v_operador,
     'Estorno (resultante de exclusão de sobra)');
  END IF;
  --
  ------------------------------------------------------------
  -- estorno do debito do cliente
  ------------------------------------------------------------
  IF v_flag_debito_cli = 'S' THEN
   SELECT apelido
     INTO v_operador
     FROM pessoa
    WHERE usuario_id = p_usuario_sessao_id;
   --
   v_descricao := v_lbl_job || ' ' || to_char(v_num_job) || ' - ' || v_nome_job || ', ';
   --
   IF nvl(v_carta_acordo_id, 0) > 0 THEN
    v_descricao := v_descricao || 'Carta Acordo ' || TRIM(to_char(v_num_carta, '0000'));
   ELSE
    v_descricao := v_descricao || 'Item ' || v_nome_item;
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
     v_cliente_id,
     SYSDATE,
     v_descricao,
     v_valor_abat,
     'E',
     v_operador,
     'Estorno (resultante de exclusão de abatimento)');
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
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
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(v_carta_acordo_id, 0) > 0 THEN
   v_identif_objeto := 'Carta Acordo: ' || to_char(v_num_job) || '/' || to_char(v_num_carta) ||
                       ' Valor: ' || moeda_mostrar(v_valor_sobra, 'S');
  ELSE
   v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item || ' Valor: ' ||
                       moeda_mostrar(v_valor_sobra, 'S');
  END IF;
  --
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'SOBRA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_sobra_id,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 21/02/2017
  -- DESCRICAO: Subrotina que gera o xml de sobra para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_sobra_id IN sobra.sobra_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_xml              xmltype;
  v_xml_aux1         xmltype;
  v_xml_aux99        xmltype;
  v_xml_doc          VARCHAR2(100);
  v_xml_atual        CLOB;
  v_carta_acordo_id  carta_acordo.carta_acordo_id%TYPE;
  v_num_carta_acordo VARCHAR2(100);
  --
  CURSOR c_it IS
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || '/' || it.tipo_item ||
          to_char(it.num_seq) AS num_item,
          tp.nome AS tipo_produto,
          numero_mostrar(ia.valor_sobra_item, 2, 'N') valor_sobra_item,
          numero_mostrar(ia.valor_cred_item, 2, 'N') valor_cred_item,
          ia.flag_abate_fatur
     FROM item_sobra   ia,
          item         it,
          tipo_produto tp
    WHERE ia.sobra_id = p_sobra_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  SELECT carta_acordo_id
    INTO v_carta_acordo_id
    FROM sobra
   WHERE sobra_id = p_sobra_id;
  --
  IF v_carta_acordo_id IS NOT NULL THEN
   v_num_carta_acordo := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
  END IF;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("sobra_id", sb.sobra_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("responsavel", pe.apelido),
                   xmlelement("data_entrada", data_mostrar(sb.data_entrada)),
                   xmlelement("tipo_sobra", util_pkg.desc_retornar('tipo_sobra', sb.tipo_sobra)),
                   xmlelement("valor_sobra", numero_mostrar(sb.valor_sobra, 2, 'N')),
                   xmlelement("valor_credito_cliente",
                              numero_mostrar(sb.valor_cred_cliente, 2, 'N')),
                   xmlelement("carta_acordo", v_num_carta_acordo))
    INTO v_xml
    FROM sobra  sb,
         job    jo,
         pessoa pe
   WHERE sb.sobra_id = p_sobra_id
     AND sb.job_id = jo.job_id
     AND sb.usuario_resp_id = pe.usuario_id(+);
  --
  ------------------------------------------------------------
  -- monta ITENS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_it IN c_it
  LOOP
   SELECT xmlagg(xmlelement("item",
                            xmlelement("num_item", r_it.num_item),
                            xmlelement("tipo_produto", r_it.tipo_produto),
                            xmlelement("valor_sobra", r_it.valor_sobra_item),
                            xmlelement("valor_credito", r_it.valor_cred_item),
                            xmlelement("abate_faturamento", r_it.flag_abate_fatur)))
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
  -- junta tudo debaixo de "abatimento"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("abatimento", v_xml))
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
 FUNCTION item_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 01/04/2008
  -- DESCRICAO: retorna o item_id de uma determinada sobra, caso se trate de sobra de item.
  --   Se a sobra for de carta acordo, retorna NULL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_sobra_id IN sobra.sobra_id%TYPE
 ) RETURN NUMBER AS
  v_qt              INTEGER;
  v_retorno         INTEGER;
  v_carta_acordo_id sobra.carta_acordo_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT carta_acordo_id
    INTO v_carta_acordo_id
    FROM sobra
   WHERE sobra_id = p_sobra_id;
  --
  IF v_carta_acordo_id IS NULL THEN
   SELECT MAX(item_id)
     INTO v_retorno
     FROM item_sobra
    WHERE sobra_id = p_sobra_id;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END item_id_retornar;
 --
--
END; -- SOBRA_PKG



/
