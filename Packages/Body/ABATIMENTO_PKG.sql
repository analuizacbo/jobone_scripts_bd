--------------------------------------------------------
--  DDL for Package Body ABATIMENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ABATIMENTO_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 02/04/2008
  -- DESCRICAO: Inclusão de ABATIMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/06/2008  Abatimento p/ itens de A (com carta acordo).
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_carta_acordo_id   IN abatimento.carta_acordo_id%TYPE,
  p_item_id           IN item.item_id%TYPE,
  p_valor_abat        IN VARCHAR2,
  p_flag_debito_cli   IN abatimento.flag_debito_cli%TYPE,
  p_justificativa     IN VARCHAR2,
  p_abatimento_id     OUT abatimento.abatimento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_job        job.numero%TYPE;
  v_nome_job       job.nome%TYPE;
  v_job_id         job.job_id%TYPE;
  v_cliente_id     job.cliente_id%TYPE;
  v_abatimento_id  abatimento.abatimento_id%TYPE;
  v_valor_abat     abatimento.valor_abat%TYPE;
  v_nome_item      VARCHAR2(100);
  v_operador       lancamento.operador%TYPE;
  v_descricao      lancamento.descricao%TYPE;
  v_num_carta      carta_acordo.num_carta_acordo%TYPE;
  v_item_sobra_id  item_sobra.item_sobra_id%TYPE;
  v_valor_sobra    sobra.valor_sobra%TYPE;
  v_sobra_id       sobra.sobra_id%TYPE;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_valor_pend     NUMBER;
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt            := 0;
  p_abatimento_id := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.cliente_id,
         jo.nome,
         jo.job_id,
         item_pkg.num_item_retornar(it.item_id, 'N'),
         it.orcamento_id
    INTO v_num_job,
         v_cliente_id,
         v_nome_job,
         v_job_id,
         v_nome_item,
         v_orcamento_id
    FROM item it,
         job  jo
   WHERE it.item_id = p_item_id
     AND it.job_id = jo.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ABATIMENTO_C',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_carta_acordo_id, 0) > 0 THEN
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
  IF TRIM(p_valor_abat) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor a abater é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_abat) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor a abater inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_abat := nvl(moeda_converter(p_valor_abat), 0);
  --
  IF v_valor_abat <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor a abater inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_debito_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag debitar do cliente inválido.';
   RAISE v_exception;
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
  v_valor_pend := faturamento_pkg.valor_retornar(p_item_id,
                                                 nvl(p_carta_acordo_id, 0),
                                                 'AFATURAR');
  --
  IF v_valor_abat > v_valor_pend THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não tem saldo suficiente para esse abatimento (Item: ' ||
                 v_nome_item || ', Saldo: ' || moeda_mostrar(v_valor_pend, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_abatimento.nextval
    INTO v_abatimento_id
    FROM dual;
  --
  INSERT INTO abatimento
   (abatimento_id,
    job_id,
    carta_acordo_id,
    usuario_resp_id,
    data_entrada,
    flag_debito_cli,
    justificativa,
    valor_abat)
  VALUES
   (v_abatimento_id,
    v_job_id,
    zvl(p_carta_acordo_id, NULL),
    p_usuario_sessao_id,
    SYSDATE,
    p_flag_debito_cli,
    TRIM(p_justificativa),
    v_valor_abat);
  --
  INSERT INTO item_abat
   (item_abat_id,
    item_id,
    abatimento_id,
    valor_abat_item)
  VALUES
   (seq_item_abat.nextval,
    p_item_id,
    v_abatimento_id,
    v_valor_abat);
  --
  -- verifica se existe sobra de mesmo valor registrada para esse item
  -- sem abatimento automatico.
  SELECT MAX(io.item_sobra_id)
    INTO v_item_sobra_id
    FROM sobra      so,
         item_sobra io
   WHERE io.item_id = p_item_id
     AND io.valor_sobra_item = v_valor_abat
     AND io.flag_abate_fatur = 'N'
     AND io.sobra_id = so.sobra_id
     AND nvl(so.carta_acordo_id, -999) = zvl(p_carta_acordo_id, -999);
  --
  IF v_item_sobra_id IS NOT NULL THEN
   -- possivel vinculo com sobra ou servico nao prestado
   SELECT so.valor_sobra,
          so.sobra_id
     INTO v_valor_sobra,
          v_sobra_id
     FROM item_sobra it,
          sobra      so
    WHERE it.item_sobra_id = v_item_sobra_id
      AND it.sobra_id = so.sobra_id;
   --
   IF v_valor_sobra = v_valor_abat THEN
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
  item_pkg.valores_recalcular(p_usuario_sessao_id, p_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- debito para o cliente
  ------------------------------------------------------------
  IF p_flag_debito_cli = 'S' THEN
   SELECT apelido
     INTO v_operador
     FROM pessoa
    WHERE usuario_id = p_usuario_sessao_id;
   --
   v_descricao := 'Abatimento, ' || v_lbl_job || ' ' || to_char(v_num_job) || ' - ' ||
                  v_nome_job || ', Item ' || v_nome_item;
   --
   IF nvl(p_carta_acordo_id, 0) > 0 THEN
    v_descricao := v_descricao || ', Carta Acordo ' || TRIM(to_char(v_num_carta, '0000'));
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
     'S',
     v_operador,
     p_justificativa);
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  abatimento_pkg.xml_gerar(v_abatimento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF nvl(p_carta_acordo_id, 0) > 0 THEN
   v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item ||
                       ' Carta Acordo: ' || to_char(v_num_job) || '/' || to_char(v_num_carta) ||
                       ' Valor: ' || moeda_mostrar(v_valor_abat, 'S');
  ELSE
   v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item || ' Valor: ' ||
                       moeda_mostrar(v_valor_abat, 'S');
  END IF;
  --
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ABATIMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_abatimento_id,
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
  --
  p_abatimento_id := v_abatimento_id;
  p_erro_cod      := '00000';
  p_erro_msg      := 'Operação realizada com sucesso.';
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
 END adicionar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 02/04/2008
  -- DESCRICAO: Exclusão de ABATIMENTO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/06/2008  Tratamento de status do job.
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_abatimento_id     IN abatimento.abatimento_id%TYPE,
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
  v_valor_abat         abatimento.valor_abat%TYPE;
  v_flag_debito_cli    abatimento.flag_debito_cli%TYPE;
  v_nome_item          VARCHAR2(100);
  v_carta_acordo_id    carta_acordo.carta_acordo_id%TYPE;
  v_num_carta          carta_acordo.num_carta_acordo%TYPE;
  v_operador           lancamento.operador%TYPE;
  v_descricao          lancamento.descricao%TYPE;
  v_item_id            item.item_id%TYPE;
  v_item_sobra_id      item_sobra.item_sobra_id%TYPE;
  v_sobra_id           sobra.sobra_id%TYPE;
  v_valor_cred_cliente sobra.valor_cred_cliente%TYPE;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_atual          CLOB;
  --
  CURSOR c_it IS
   SELECT ia.item_abat_id,
          ia.item_id,
          ia.valor_abat_item,
          ab.carta_acordo_id
     FROM item_abat  ia,
          abatimento ab
    WHERE ia.abatimento_id = p_abatimento_id
      AND ia.abatimento_id = ab.abatimento_id;
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
    FROM abatimento ab,
         job        jo
   WHERE ab.abatimento_id = p_abatimento_id
     AND ab.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse abatimento não existe.';
   RAISE v_exception;
  END IF;
  SELECT ab.valor_abat,
         ab.flag_debito_cli,
         ab.carta_acordo_id,
         ab.sobra_id,
         jo.numero,
         jo.cliente_id,
         jo.nome,
         jo.job_id
    INTO v_valor_abat,
         v_flag_debito_cli,
         v_carta_acordo_id,
         v_sobra_id,
         v_num_job,
         v_cliente_id,
         v_nome_job,
         v_job_id
    FROM abatimento ab,
         job        jo
   WHERE ab.abatimento_id = p_abatimento_id
     AND ab.job_id = jo.job_id;
  --
  SELECT MAX(orcamento_id)
    INTO v_orcamento_id
    FROM item      it,
         item_abat ia
   WHERE ia.abatimento_id = p_abatimento_id
     AND ia.item_id = it.item_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ABATIMENTO_C',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_carta_acordo_id IS NULL THEN
   SELECT MAX(item_id)
     INTO v_item_id
     FROM item_abat
    WHERE abatimento_id = p_abatimento_id;
   --
   v_nome_item := item_pkg.num_item_retornar(v_item_id, 'N');
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
  abatimento_pkg.xml_gerar(p_abatimento_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (sobra vinculada)
  ------------------------------------------------------------
  IF v_sobra_id > 0 THEN
   SELECT valor_cred_cliente
     INTO v_valor_cred_cliente
     FROM sobra
    WHERE sobra_id = v_sobra_id;
   --
   UPDATE abatimento
      SET sobra_id = NULL
    WHERE abatimento_id = p_abatimento_id;
   --
   -- exclui a sobra vincula a esse abatimento
   DELETE FROM item_sobra
    WHERE sobra_id = v_sobra_id;
   DELETE FROM sobra
    WHERE sobra_id = v_sobra_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (exclusao do abatimento)
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   DELETE FROM item_abat
    WHERE item_abat_id = r_it.item_abat_id;
   --
   -- verifica se existe sobra de mesmo valor registrada para esse item
   -- com abatimento automatico.
   SELECT MAX(io.item_sobra_id)
     INTO v_item_sobra_id
     FROM sobra      so,
          item_sobra io
    WHERE io.item_id = r_it.item_id
      AND (io.valor_cred_item = r_it.valor_abat_item OR
          io.valor_sobra_item = r_it.valor_abat_item)
      AND io.flag_abate_fatur = 'S'
      AND io.sobra_id = so.sobra_id
      AND nvl(so.carta_acordo_id, -999) = nvl(r_it.carta_acordo_id, -999);
   --
   IF v_item_sobra_id IS NOT NULL THEN
    -- marca a sobra como NAO vinculada ao abatimento
    UPDATE item_sobra
       SET flag_abate_fatur = 'N'
     WHERE item_sobra_id = v_item_sobra_id;
   END IF;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM abatimento
   WHERE abatimento_id = p_abatimento_id;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
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
  -- estorno do debito para o cliente
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
  v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item || ' Valor: ' ||
                      moeda_mostrar(v_valor_abat, 'S');
  --
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ABATIMENTO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_abatimento_id,
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
 PROCEDURE auto_abater
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 27/03/2008
  -- DESCRICAO: Gera abatimento automatico relativo a uma determinada sobra.    
  --   NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2008  Calculos adicionais dos itens (valores de saldos,etc).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_sobra_id          IN sobra.sobra_id%TYPE,
  p_abatimento_id     OUT abatimento.abatimento_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_num_job         job.numero%TYPE;
  v_nome_job        job.nome%TYPE;
  v_job_id          job.job_id%TYPE;
  v_cliente_id      job.cliente_id%TYPE;
  v_carta_acordo_id carta_acordo.carta_acordo_id%TYPE;
  v_num_carta       carta_acordo.num_carta_acordo%TYPE;
  v_nome_item       VARCHAR2(100);
  v_operador        lancamento.operador%TYPE;
  v_descricao       lancamento.descricao%TYPE;
  v_abatimento_id   abatimento.abatimento_id%TYPE;
  v_valor_abat      abatimento.valor_abat%TYPE;
  v_orcamento_id    orcamento.orcamento_id%TYPE;
  v_valor_pend      NUMBER;
  v_lbl_job         VARCHAR2(100);
  v_xml_atual       CLOB;
  --
  CURSOR c_it IS
   SELECT item_id,
          valor_sobra_item,
          item_pkg.num_item_retornar(item_id, 'N') AS nome_item
     FROM item_sobra
    WHERE sobra_id = p_sobra_id
      AND flag_abate_fatur = 'S';
  --
 BEGIN
  v_qt         := 0;
  v_valor_abat := 0;
  v_lbl_job    := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
         jo.numero,
         jo.cliente_id,
         jo.nome,
         jo.job_id
    INTO v_carta_acordo_id,
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
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_abatimento.nextval
    INTO v_abatimento_id
    FROM dual;
  --
  INSERT INTO abatimento
   (abatimento_id,
    job_id,
    carta_acordo_id,
    usuario_resp_id,
    sobra_id,
    data_entrada,
    flag_debito_cli,
    justificativa,
    valor_abat)
  VALUES
   (v_abatimento_id,
    v_job_id,
    v_carta_acordo_id,
    p_usuario_sessao_id,
    p_sobra_id,
    SYSDATE,
    'N',
    'Abatimento automático',
    0);
  --
  FOR r_it IN c_it
  LOOP
   v_valor_pend := faturamento_pkg.valor_retornar(r_it.item_id, 0, 'AFATURAR');
   --
   IF r_it.valor_sobra_item > v_valor_pend THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não tem saldo suficiente para esse abatimento (Item: ' ||
                  r_it.nome_item || ', Saldo: ' || moeda_mostrar(v_valor_pend, 'S') ||
                  ', Abatimento: ' || moeda_mostrar(r_it.valor_sobra_item, 'S') || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO item_abat
    (item_abat_id,
     item_id,
     abatimento_id,
     valor_abat_item)
   VALUES
    (seq_item_abat.nextval,
     r_it.item_id,
     v_abatimento_id,
     r_it.valor_sobra_item);
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   v_valor_abat := v_valor_abat + r_it.valor_sobra_item;
  END LOOP;
  --
  UPDATE abatimento
     SET valor_abat = v_valor_abat
   WHERE abatimento_id = v_abatimento_id;
  --
  SELECT MAX(orcamento_id)
    INTO v_orcamento_id
    FROM item      it,
         item_abat ia
   WHERE ia.abatimento_id = v_abatimento_id
     AND ia.item_id = it.item_id;
  --
  orcamento_pkg.totais_recalcular(p_usuario_sessao_id, v_orcamento_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  abatimento_pkg.xml_gerar(v_abatimento_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
                       ' Valor: ' || moeda_mostrar(v_valor_abat, 'S');
  ELSE
   v_identif_objeto := 'Item: ' || to_char(v_num_job) || '/' || v_nome_item || ' Valor: ' ||
                       moeda_mostrar(v_valor_abat, 'S');
  END IF;
  --
  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ABATIMENTO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_abatimento_id,
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
  p_abatimento_id := v_abatimento_id;
  p_erro_cod      := '00000';
  p_erro_msg      := 'Operação realizada com sucesso.';
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
 END auto_abater;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 20/02/2017
  -- DESCRICAO: Subrotina que gera o xml de abatimento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_abatimento_id IN abatimento.abatimento_id%TYPE,
  p_xml           OUT CLOB,
  p_erro_cod      OUT VARCHAR2,
  p_erro_msg      OUT VARCHAR2
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
          numero_mostrar(ia.valor_abat_item, 2, 'N') valor_abat_item
     FROM item_abat    ia,
          item         it,
          tipo_produto tp
    WHERE ia.abatimento_id = p_abatimento_id
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
    FROM abatimento
   WHERE abatimento_id = p_abatimento_id;
  --
  IF v_carta_acordo_id IS NOT NULL THEN
   v_num_carta_acordo := carta_acordo_pkg.numero_completo_formatar(v_carta_acordo_id, 'N');
  END IF;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("abatimento_id", ab.abatimento_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("responsavel", pe.apelido),
                   xmlelement("data_entrada", data_mostrar(ab.data_entrada)),
                   xmlelement("valor_abatimento", numero_mostrar(ab.valor_abat, 2, 'N')),
                   xmlelement("debito_cliente", ab.flag_debito_cli),
                   xmlelement("carta_acordo", v_num_carta_acordo),
                   xmlelement("sobra_id", to_char(ab.sobra_id)))
    INTO v_xml
    FROM abatimento ab,
         job        jo,
         pessoa     pe
   WHERE ab.abatimento_id = p_abatimento_id
     AND ab.job_id = jo.job_id
     AND ab.usuario_resp_id = pe.usuario_id(+);
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
                            xmlelement("valor_abatido", r_it.valor_abat_item)))
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
  -- DESCRICAO: retorna o item_id de um determinado abatimento, caso se trate de abatimento
  --   de item. Se o abatimento for de carta acordo, retorna NULL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_abatimento_id IN abatimento.abatimento_id%TYPE
 ) RETURN NUMBER AS
  v_qt              INTEGER;
  v_retorno         INTEGER;
  v_carta_acordo_id abatimento.carta_acordo_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT carta_acordo_id
    INTO v_carta_acordo_id
    FROM abatimento
   WHERE abatimento_id = p_abatimento_id;
  --
  IF v_carta_acordo_id IS NULL THEN
   SELECT MAX(item_id)
     INTO v_retorno
     FROM item_abat
    WHERE abatimento_id = p_abatimento_id;
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
END;

/
