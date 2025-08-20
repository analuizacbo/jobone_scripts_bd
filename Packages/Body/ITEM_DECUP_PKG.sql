--------------------------------------------------------
--  DDL for Package Body ITEM_DECUP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ITEM_DECUP_PKG" IS
 --
 --
 PROCEDURE renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 21/02/2006
  -- DESCRICAO: subrotina que renumera registros de decupacao de um determinado item.
  --     Nao faz o commit.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_item_id  IN item.item_id%TYPE,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_ordem     item_decup.ordem_decup%TYPE;
  --
  CURSOR c_reg IS
   SELECT item_decup_id
     FROM item_decup
    WHERE item_id = p_item_id
    ORDER BY ordem_decup;
  --
 BEGIN
  v_ordem := 0;
  --
  FOR r_reg IN c_reg
  LOOP
   -- renumera de 10 em 10
   v_ordem := v_ordem + 10;
   --
   UPDATE item_decup
      SET ordem_decup = v_ordem
    WHERE item_decup_id = r_reg.item_decup_id;
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
 END; -- renumerar
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Inclusão de ITEM_DECUP (detalhamento/decupacao do item)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/07/2012  Aumento do campo descricao.
  -- Silvia            10/04/2017  Novos campos (fornecedor_id, custo)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_id           IN item_decup.item_id%TYPE,
  p_fornecedor_id     IN item_decup.fornecedor_id%TYPE,
  p_custo_fornec      IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_item_decup_id     OUT item_decup.item_decup_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_item_decup_id      item_decup.item_decup_id%TYPE;
  v_job_id             item.job_id%TYPE;
  v_complemento        item.complemento%TYPE;
  v_custo_fornec_item  item.valor_fornecedor%TYPE;
  v_custo_fornec_decup item.valor_fornecedor%TYPE;
  v_nome_produto       tipo_produto.nome%TYPE;
  v_num_orcamento      orcamento.num_orcamento%TYPE;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_custo_fornec       item_decup.custo_fornec%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt            := 0;
  p_item_decup_id := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         it.complemento,
         nvl(it.valor_fornecedor, 0)
    INTO v_nome_produto,
         v_complemento,
         v_custo_fornec_item
    FROM tipo_produto tp,
         item         it
   WHERE it.item_id = p_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_fornecedor_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_fornecedor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF moeda_validar(p_custo_fornec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo do fornecedor inválido (' || p_custo_fornec || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo_fornec := nvl(moeda_converter(p_custo_fornec), 0);
  --
  IF v_custo_fornec < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL AND nvl(p_fornecedor_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das observações ou do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As observações não podem ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_item_decup.nextval
    INTO v_item_decup_id
    FROM dual;
  --
  INSERT INTO item_decup
   (item_decup_id,
    item_id,
    descricao,
    fornecedor_id,
    custo_fornec,
    ordem_decup)
  VALUES
   (v_item_decup_id,
    p_item_id,
    TRIM(p_descricao),
    zvl(p_fornecedor_id, NULL),
    v_custo_fornec,
    90000);
  --
  renumerar(p_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(SUM(custo_fornec), 0)
    INTO v_custo_fornec_decup
    FROM item_decup
   WHERE item_id = p_item_id;
  --
  IF v_custo_fornec_decup > v_custo_fornec_item THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A soma dos custos das decupações (' ||
                 moeda_mostrar(v_custo_fornec_decup, 'S') ||
                 ') não pode ultrapassar o custo total definido no item (' ||
                 moeda_mostrar(v_custo_fornec_item, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                      to_char(v_num_orcamento);
  v_compl_histor   := 'Inclusão de decupação de item (' ||
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
  p_item_decup_id := v_item_decup_id;
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
 END; -- adicionar
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 13/07/2012
  -- DESCRICAO: Atualização de ITEM_DECUP (detalhamento/decupacao do item)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/04/2017  Novos campos (fornecedor_id, custo)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_decup_id     IN item_decup.item_decup_id%TYPE,
  p_fornecedor_id     IN item_decup.fornecedor_id%TYPE,
  p_custo_fornec      IN VARCHAR2,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_item_id            item.item_id%TYPE;
  v_complemento        item.complemento%TYPE;
  v_custo_fornec_item  item.valor_fornecedor%TYPE;
  v_custo_fornec_decup item.valor_fornecedor%TYPE;
  v_nome_produto       tipo_produto.nome%TYPE;
  v_num_orcamento      orcamento.num_orcamento%TYPE;
  v_orcamento_id       orcamento.orcamento_id%TYPE;
  v_custo_fornec       item_decup.custo_fornec%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_job_id             job.job_id%TYPE;
  v_lbl_job            VARCHAR2(100);
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
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa decupação de item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.orcamento_id,
         i.item_id,
         nvl(i.valor_fornecedor, 0)
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id,
         v_item_id,
         v_custo_fornec_item
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         it.complemento
    INTO v_nome_produto,
         v_complemento
    FROM tipo_produto tp,
         item         it
   WHERE it.item_id = v_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_fornecedor_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM pessoa
    WHERE pessoa_id = p_fornecedor_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse fornecedor não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF moeda_validar(p_custo_fornec) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo do fornecedor inválido (' || p_custo_fornec || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo_fornec := nvl(moeda_converter(p_custo_fornec), 0);
  --
  IF v_custo_fornec < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O custo do fornecedor não pode ser negativo.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL AND nvl(p_fornecedor_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das observações ou do fornecedor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As observações não podem ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item_decup
     SET descricao     = TRIM(p_descricao),
         fornecedor_id = zvl(p_fornecedor_id, NULL),
         custo_fornec  = v_custo_fornec
   WHERE item_decup_id = p_item_decup_id;
  --
  SELECT nvl(SUM(custo_fornec), 0)
    INTO v_custo_fornec_decup
    FROM item_decup
   WHERE item_id = v_item_id;
  --
  IF v_custo_fornec_decup > v_custo_fornec_item THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A soma dos custos das decupações (' ||
                 moeda_mostrar(v_custo_fornec_decup, 'S') ||
                 ') não pode ultrapassar o custo total definido no item (' ||
                 moeda_mostrar(v_custo_fornec_item, 'S') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                      to_char(v_num_orcamento);
  v_compl_histor   := 'Alteração de decupação de item (' ||
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
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Exclusão de ITEM_DECUP (detalhamento/decupacao do item)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_decup_id     IN item_decup.item_decup_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_item_id        item.item_id%TYPE;
  v_complemento    item.complemento%TYPE;
  v_nome_produto   tipo_produto.nome%TYPE;
  v_num_orcamento  orcamento.num_orcamento%TYPE;
  v_orcamento_id   orcamento.orcamento_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_lbl_job        VARCHAR2(100);
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
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa decupação de item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.job_id,
         o.num_orcamento,
         o.orcamento_id,
         i.item_id
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_num_orcamento,
         v_orcamento_id,
         v_item_id
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         it.complemento
    INTO v_nome_produto,
         v_complemento
    FROM tipo_produto tp,
         item         it
   WHERE it.item_id = v_item_id
     AND it.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM item_decup
   WHERE item_decup_id = p_item_decup_id;
  --
  renumerar(v_item_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_lbl_job || ': ' || to_char(v_numero_job) || ' - Orçamento: ' ||
                      to_char(v_num_orcamento);
  v_compl_histor   := 'Exclusão de decupação de item (' ||
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
 END; -- excluir
 --
 --
 PROCEDURE mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia         ProcessMind     DATA: 14/12/2006
  -- DESCRICAO: Movimentacao de ITEM_DECUP (detalhamento/decupacao do item), de acordo com
  --   a direcao informada (S - sobe, D - desce).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_decup_id     IN item_decup.item_decup_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_ordem_ori    NUMBER(5);
  v_ordem        NUMBER(5);
  v_ordem_aux    NUMBER(5);
  v_status_job   job.status%TYPE;
  v_job_id       job.job_id%TYPE;
  v_item_id      item.item_id%TYPE;
  v_orcamento_id orcamento.orcamento_id%TYPE;
  v_exception    EXCEPTION;
  v_lbl_job      VARCHAR2(100);
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
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa decupação de item não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.status,
         j.job_id,
         i.item_id,
         i.orcamento_id
    INTO v_status_job,
         v_job_id,
         v_item_id,
         v_orcamento_id
    FROM job        j,
         orcamento  o,
         item       i,
         item_decup d
   WHERE d.item_decup_id = p_item_decup_id
     AND d.item_id = i.item_id
     AND i.orcamento_id = o.orcamento_id
     AND o.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ORCAMENTO_A',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_direcao IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da direção é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('S', 'D') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção inválida.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(ordem_decup, 90000)
    INTO v_ordem_ori
    FROM item_decup
   WHERE item_decup_id = p_item_decup_id;
  --
  IF p_direcao = 'D' THEN
   -- desce uma posicao.
   -- procura o proximo registro.
   SELECT nvl(MIN(ordem_decup), 0)
     INTO v_ordem_aux
     FROM item_decup
    WHERE item_id = v_item_id
      AND ordem_decup > v_ordem_ori;
   --
   v_ordem := v_ordem_aux + 5;
   --
  ELSIF p_direcao = 'S' THEN
   -- sobe uma posicao.
   -- procura o registro anterior.
   SELECT nvl(MAX(ordem_decup), 0)
     INTO v_ordem_aux
     FROM item_decup
    WHERE item_id = v_item_id
      AND ordem_decup < v_ordem_ori;
   --
   IF v_ordem_aux = 0 THEN
    v_ordem := 90000;
   ELSE
    v_ordem := v_ordem_aux - 5;
   END IF;
  END IF;
  --
  UPDATE item_decup
     SET ordem_decup = v_ordem
   WHERE item_decup_id = p_item_decup_id;
  --
  renumerar(v_item_id, p_erro_cod, p_erro_msg);
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
 END; -- mover
--
--
END; -- ITEM_DECUP_PKG



/
