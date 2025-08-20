--------------------------------------------------------
--  DDL for Package Body ADIANT_DESP_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ADIANT_DESP_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 12/01/2015
  -- DESCRICAO: Inclusão de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_motivo_adiant     IN adiant_desp.motivo_adiant%TYPE,
  p_complemento       IN VARCHAR2,
  p_data_limite       IN VARCHAR2,
  p_hora_limite       IN VARCHAR2,
  p_valor_solicitado  IN VARCHAR2,
  p_forma_adiant_pref IN adiant_desp.forma_adiant_pref%TYPE,
  p_solicitante_id    IN adiant_desp.solicitante_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_valor       IN VARCHAR2,
  p_adiant_desp_id    OUT adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_item_id          item.item_id%TYPE;
  v_orcamento_id     item.orcamento_id%TYPE;
  v_tipo_item        VARCHAR2(10);
  v_nome_item        VARCHAR2(200);
  v_adiant_desp_id   adiant_desp.adiant_desp_id%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_data_limite      adiant_desp.data_limite%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_item_id    LONG;
  v_vetor_valor      LONG;
  v_valor_it_char    VARCHAR2(20);
  v_valor_it_solic   item_adiant.valor_solicitado%TYPE;
  v_valor_disponivel NUMBER;
  v_valor_liberado_b NUMBER;
  v_lbl_job          VARCHAR2(100);
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt             := 0;
  p_adiant_desp_id := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
  SELECT jo.numero,
         jo.status
    INTO v_num_job,
         v_status_job
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('motivo_adiant_desp', p_motivo_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Motivo inválido (' || p_motivo_adiant || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_limite) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data limite é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_limite) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data limite inválida (' || p_data_limite || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_limite) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora inválida (' || p_hora_limite || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_limite := data_hora_converter(p_data_limite || ' ' || p_hora_limite);
  --
  IF v_data_limite < SYSDATE THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data limite não pode ser anterior à data atual ' ||
                 data_hora_mostrar(v_data_limite) || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_solicitado) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor solicitado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_solicitado) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor solicitado inválido (' || p_valor_solicitado || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_solicitado := nvl(moeda_converter(p_valor_solicitado), 0);
  --
  IF v_valor_solicitado <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor solicitado inválido (' || p_valor_solicitado || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_forma_adiant_pref) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da forma de recebimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('forma_adiant_desp', p_forma_adiant_pref) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de recebimento inválida (' || p_forma_adiant_pref || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_solicitante_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do solicitante é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_adiant_desp.nextval
    INTO v_adiant_desp_id
    FROM dual;
  --
  SELECT nvl(MAX(num_adiant), 0) + 1
    INTO v_num_adiant
    FROM adiant_desp
   WHERE job_id = p_job_id;
  --
  INSERT INTO adiant_desp
   (adiant_desp_id,
    solicitante_id,
    criador_id,
    job_id,
    num_adiant,
    data_entrada,
    data_limite,
    valor_solicitado,
    motivo_adiant,
    complemento,
    forma_adiant_pref,
    status,
    data_status,
    aprovador_id,
    data_aprov)
  VALUES
   (v_adiant_desp_id,
    p_solicitante_id,
    p_usuario_sessao_id,
    p_job_id,
    v_num_adiant,
    SYSDATE,
    v_data_limite,
    v_valor_solicitado,
    p_motivo_adiant,
    TRIM(p_complemento),
    p_forma_adiant_pref,
    'EMAP',
    SYSDATE,
    NULL,
    NULL);
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  v_delimitador := '|';
  --
  v_vetor_item_id := p_vetor_item_id;
  v_vetor_valor   := p_vetor_valor;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id       := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_it_char := prox_valor_retornar(v_vetor_valor, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item      it,
          orcamento oc
    WHERE it.item_id = v_item_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.job_id = p_job_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe ou não pertence a esse ' || v_lbl_job || ' (' ||
                  to_char(v_item_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          it.tipo_item,
          it.job_id,
          it.orcamento_id
     INTO v_nome_item,
          v_tipo_item,
          v_job_id,
          v_orcamento_id
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ADIDESP_C',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ADIDESP_SAP',
                                 v_orcamento_id,
                                 NULL,
                                 p_empresa_id) = 1 THEN
    -- nao necessita aprovacao
    UPDATE adiant_desp
       SET status       = 'APRO',
           aprovador_id = p_usuario_sessao_id,
           data_aprov   = SYSDATE
     WHERE adiant_desp_id = v_adiant_desp_id;
   
   END IF;
   --
   IF v_tipo_item = 'A' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa Modalidade de Contratação não pode ter adiantamentos (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_job_id <> p_job_id THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não pertence ao mesmo ' || v_lbl_job || ' (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_it_solic := nvl(moeda_converter(v_valor_it_char), 0);
   --
   IF v_valor_it_solic < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item = 'B' THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_it_solic > v_valor_liberado_b THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado no adiantamento (' ||
                   moeda_mostrar(v_valor_it_solic, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_it_solic > v_valor_disponivel THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado no adiantamento (' ||
                  moeda_mostrar(v_valor_it_solic, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_it_solic > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_adiant
     WHERE adiant_desp_id = v_adiant_desp_id
       AND item_id = v_item_id;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O item ' || v_nome_item ||
                   ', não pode ser lançado no adiantamento mais de uma vez.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO item_adiant
     (item_adiant_id,
      adiant_desp_id,
      item_id,
      valor_solicitado)
    VALUES
     (seq_item_adiant.nextval,
      v_adiant_desp_id,
      v_item_id,
      v_valor_it_solic);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
  END LOOP;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, p_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(v_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(v_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'INCLUIR',
                   v_identif_objeto,
                   v_adiant_desp_id,
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
  p_adiant_desp_id := v_adiant_desp_id;
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
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: Atualização de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  -- Silvia            05/05/2020  Consistencia do valor liberado de B
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_motivo_adiant     IN adiant_desp.motivo_adiant%TYPE,
  p_complemento       IN VARCHAR2,
  p_data_limite       IN VARCHAR2,
  p_hora_limite       IN VARCHAR2,
  p_valor_solicitado  IN VARCHAR2,
  p_forma_adiant_pref IN adiant_desp.forma_adiant_pref%TYPE,
  p_solicitante_id    IN adiant_desp.solicitante_id%TYPE,
  p_vetor_item_id     IN VARCHAR2,
  p_vetor_valor       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_item_id          item.item_id%TYPE;
  v_tipo_item        VARCHAR2(10);
  v_nome_item        VARCHAR2(200);
  v_adiant_desp_id   adiant_desp.adiant_desp_id%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_data_limite      adiant_desp.data_limite%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_item_id    LONG;
  v_vetor_valor      LONG;
  v_valor_it_char    VARCHAR2(20);
  v_valor_it_solic   item_adiant.valor_solicitado%TYPE;
  v_valor_disponivel NUMBER;
  v_valor_liberado_b NUMBER;
  v_lbl_job          VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
  CURSOR c_it IS
   SELECT DISTINCT ia.item_id,
                   it.orcamento_id
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = it.item_id;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('EMAP', 'REPR') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('motivo_adiant_desp', p_motivo_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Motivo inválido (' || p_motivo_adiant || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_limite) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data limite é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_limite) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data limite inválida (' || p_data_limite || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_limite) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora inválida (' || p_hora_limite || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_limite := data_hora_converter(p_data_limite || ' ' || p_hora_limite);
  --
  IF TRIM(p_valor_solicitado) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor solicitado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_solicitado) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor solicitado inválido (' || p_valor_solicitado || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_solicitado := nvl(moeda_converter(p_valor_solicitado), 0);
  --
  IF v_valor_solicitado <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor solicitado inválido (' || p_valor_solicitado || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_forma_adiant_pref) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da forma de recebimento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('forma_adiant_desp', p_forma_adiant_pref) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de recebimento inválida (' || p_forma_adiant_pref || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_solicitante_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do solicitante é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET solicitante_id    = p_solicitante_id,
         data_limite       = v_data_limite,
         valor_solicitado  = v_valor_solicitado,
         motivo_adiant     = p_motivo_adiant,
         complemento       = TRIM(p_complemento),
         forma_adiant_pref = p_forma_adiant_pref
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_status_adiant = 'REPR' THEN
   -- volta para em aprovacao
   UPDATE adiant_desp
      SET status      = 'EMAP',
          data_status = SYSDATE
    WHERE adiant_desp_id = p_adiant_desp_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de itens
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ADIDESP_C',
                                 r_it.orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = r_it.item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  v_delimitador := '|';
  --
  v_vetor_item_id := p_vetor_item_id;
  v_vetor_valor   := p_vetor_valor;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id       := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_it_char := prox_valor_retornar(v_vetor_valor, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item      it,
          orcamento oc
    WHERE it.item_id = v_item_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.job_id = v_job_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item não existe ou não pertence a esse ' || v_lbl_job || ' (' ||
                  to_char(v_item_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq),
          it.tipo_item
     INTO v_nome_item,
          v_tipo_item
     FROM item it
    WHERE it.item_id = v_item_id;
   --
   IF v_tipo_item = 'A' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa Modalidade de Contratação não pode ter adiantamentos (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_it_solic := nvl(moeda_converter(v_valor_it_char), 0);
   --
   IF v_valor_it_solic < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_nome_item || ': ' || v_valor_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_tipo_item = 'B' THEN
    v_valor_liberado_b := item_pkg.valor_liberado_b_retornar(v_item_id);
    --
    IF v_valor_it_solic > v_valor_liberado_b THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado no adiantamento (' ||
                   moeda_mostrar(v_valor_it_solic, 'S') ||
                   ') não pode ser maior que o valor restante já liberado via faturamento (' ||
                   moeda_mostrar(v_valor_liberado_b, 'S') || ').';
    
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -- verifica se o item suporta esse lancamento
   v_valor_disponivel := item_pkg.valor_disponivel_retornar(v_item_id, 'APROVADO');
   --
   IF v_valor_it_solic > v_valor_disponivel THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para o item ' || v_nome_item || ', o valor lançado no adiantamento (' ||
                  moeda_mostrar(v_valor_it_solic, 'S') ||
                  ') não pode ser maior que o saldo disponível (' ||
                  moeda_mostrar(v_valor_disponivel, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_valor_it_solic > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_adiant
     WHERE adiant_desp_id = v_adiant_desp_id
       AND item_id = v_item_id;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O item ' || v_nome_item ||
                   ', não pode ser lançado no adiantamento mais de uma vez.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO item_adiant
     (item_adiant_id,
      adiant_desp_id,
      item_id,
      valor_solicitado)
    VALUES
     (seq_item_adiant.nextval,
      p_adiant_desp_id,
      v_item_id,
      v_valor_it_solic);
    --
    item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
  END LOOP;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, v_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: Exclusao de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_num_adiant       VARCHAR2(100);
  v_status_adiant    adiant_desp.status%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_xml_atual        CLOB;
  --
  CURSOR c_it IS
   SELECT DISTINCT ia.item_id,
                   it.orcamento_id
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = it.item_id;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_status_adiant NOT IN ('EMAP', 'REPR', 'APRO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem valores adiantados para essa solicitação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM desp_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem prestações de contas para essa solicitação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM devol_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem devoluções para essa solicitação.';
   RAISE v_exception;
  END IF;
  --
  v_num_adiant := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'ADIDESP_C',
                                 r_it.orcamento_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = r_it.item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, r_it.item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- trata status do job
  job_pkg.status_tratar(p_usuario_sessao_id, p_empresa_id, v_job_id, 'ALL', p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  DELETE FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  COMMIT;
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
 PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: aprovacao de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_orcamento_id     orcamento.orcamento_id%TYPE;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  SELECT MAX(it.orcamento_id)
    INTO v_orcamento_id
    FROM item_adiant ia,
         item        it
   WHERE ia.adiant_desp_id = p_adiant_desp_id
     AND ia.item_id = it.item_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('EMAP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ADIDESP_AP',
                                v_orcamento_id,
                                NULL,
                                p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status       = 'APRO',
         data_status  = SYSDATE,
         aprovador_id = p_usuario_sessao_id,
         data_aprov   = SYSDATE
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'APROVAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END aprovar;
 --
 --
 PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: reprovacao de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_orcamento_id     item.orcamento_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  SELECT MAX(it.orcamento_id)
    INTO v_orcamento_id
    FROM item_adiant ia,
         item        it
   WHERE ia.adiant_desp_id = p_adiant_desp_id
     AND ia.item_id = it.item_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('EMAP', 'APRO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ADIDESP_AP',
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
  IF TRIM(p_motivo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status       = 'REPR',
         data_status  = SYSDATE,
         aprovador_id = NULL,
         data_aprov   = NULL
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'REPROVAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
                   v_compl_histor,
                   TRIM(p_motivo),
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END reprovar;
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: termina ADIANT_DESP para realização de adiantamentos, passando para
  --  prestacao de contas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EX', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'ADIANTADO') = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ainda não existem adiantamentos realizados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status      = 'PCON',
         data_status = SYSDATE
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'TERMINAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END terminar;
 --
 --
 PROCEDURE retomar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: retorna ADIANT_DESP para realização de adiantamentos
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- privilegio do grupo jOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EX', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status      = 'APRO',
         data_status = SYSDATE
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'RETOMAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END retomar;
 --
 --
 PROCEDURE encerrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: encerra prestacao de contas de ADIANT_DESP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EN', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status      = 'ENCE',
         data_status = SYSDATE
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'CONCLUIR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END encerrar;
 --
 --
 PROCEDURE reabrir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2015
  -- DESCRICAO: reabrir ADIANT_DESP para prestacao de contas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_desp_id    IN adiant_desp.adiant_desp_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_lbl_job          VARCHAR2(100);
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.num_adiant,
         ad.status,
         ad.valor_solicitado
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_adiant,
         v_status_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('ENCE') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento para despesas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_PC', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE adiant_desp
     SET status      = 'PCON',
         data_status = SYSDATE
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'REABRIR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END reabrir;
 --
 --
 PROCEDURE realizado_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 12/01/2015
  -- DESCRICAO: Inclusão de valor realizado (adiantado) - ADIANT_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_adiant_desp_id      IN adiant_realiz.adiant_desp_id%TYPE,
  p_forma_adiant        IN adiant_realiz.forma_adiant%TYPE,
  p_valor_realiz        IN VARCHAR2,
  p_fi_banco_id         IN adiant_realiz.fi_banco_id%TYPE,
  p_num_agencia         IN adiant_realiz.num_agencia%TYPE,
  p_num_conta           IN adiant_realiz.num_conta%TYPE,
  p_tipo_conta          IN adiant_realiz.tipo_conta%TYPE,
  p_cnpj_cpf_titular    IN VARCHAR2,
  p_nome_titular        IN VARCHAR2,
  p_flag_atualiza_conta IN VARCHAR2,
  p_adiant_realiz_id    OUT adiant_realiz.adiant_realiz_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_adiant_realiz_id adiant_realiz.adiant_realiz_id%TYPE;
  v_valor_realiz     adiant_realiz.valor_realiz%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_solicitante_id   adiant_desp.solicitante_id%TYPE;
  v_cnpj_cpf_titular adiant_realiz.cnpj_cpf_titular%TYPE;
  v_valor_disponivel NUMBER;
  v_lbl_job          VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt               := 0;
  p_adiant_realiz_id := 0;
  v_lbl_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado,
         ad.solicitante_id
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado,
         v_solicitante_id
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EX', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant <> 'APRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_forma_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da forma de adiantamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('forma_adiant_desp', p_forma_adiant) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Forma de adiantamento inválida (' || p_forma_adiant || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_valor_realiz) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do valor é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_realiz) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor inválido (' || p_valor_realiz || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_realiz := nvl(moeda_converter(p_valor_realiz), 0);
  --
  IF v_valor_realiz <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor inválido (' || p_valor_realiz || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_forma_adiant <> 'DC' AND
     (nvl(p_fi_banco_id, 0) > 0 OR TRIM(p_num_agencia) IS NOT NULL OR TRIM(p_num_conta) IS NOT NULL OR
     TRIM(p_nome_titular) IS NOT NULL OR TRIM(p_cnpj_cpf_titular) IS NOT NULL) THEN
   -- nao eh deposito em conta
   p_erro_cod := '90000';
   p_erro_msg := 'Para essa forma de adiantamento, os dados bancários não devem ser informados.';
   RAISE v_exception;
  END IF;
  --
  IF p_forma_adiant = 'DC' AND (nvl(p_fi_banco_id, 0) = 0 OR TRIM(p_num_agencia) IS NULL OR
     TRIM(p_num_conta) IS NULL OR TRIM(p_tipo_conta) IS NULL) THEN
   -- eh deposito em conta
   p_erro_cod := '90000';
   p_erro_msg := 'Para essa forma de adiantamento, os dados bancários devem ser informados.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_fi_banco_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM fi_banco
    WHERE fi_banco_id = p_fi_banco_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse banco não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF rtrim(p_tipo_conta) IS NOT NULL AND p_tipo_conta NOT IN ('C', 'P') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de conta inválido (' || p_tipo_conta || ').';
   RAISE v_exception;
  END IF;
  --
  v_cnpj_cpf_titular := NULL;
  --
  IF TRIM(p_cnpj_cpf_titular) IS NOT NULL THEN
   IF cnpj_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0 THEN
    IF cpf_pkg.validar(p_cnpj_cpf_titular, p_empresa_id) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'CNPJ/CPF do titular da conta inválido (' || p_cnpj_cpf_titular || ').';
     RAISE v_exception;
    ELSE
     v_cnpj_cpf_titular := cpf_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
    END IF;
   
   ELSE
    v_cnpj_cpf_titular := cnpj_pkg.converter(p_cnpj_cpf_titular, p_empresa_id);
   END IF;
  END IF;
  --
  v_valor_disponivel := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'DISPONIVEL');
  --
  IF v_valor_realiz > v_valor_disponivel THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe saldo suficiente para realizar esse adiantamento.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_atualiza_conta) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag atualiza conta inválido (' || p_flag_atualiza_conta || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_adiant_realiz.nextval
    INTO v_adiant_realiz_id
    FROM dual;
  --
  INSERT INTO adiant_realiz
   (adiant_realiz_id,
    adiant_desp_id,
    usuario_id,
    data_entrada,
    forma_adiant,
    valor_realiz,
    fi_banco_id,
    num_agencia,
    num_conta,
    tipo_conta,
    nome_titular,
    cnpj_cpf_titular)
  VALUES
   (v_adiant_realiz_id,
    p_adiant_desp_id,
    p_usuario_sessao_id,
    SYSDATE,
    p_forma_adiant,
    v_valor_realiz,
    zvl(p_fi_banco_id, NULL),
    TRIM(p_num_agencia),
    TRIM(p_num_conta),
    TRIM(p_tipo_conta),
    TRIM(p_nome_titular),
    v_cnpj_cpf_titular);
  --
  IF p_flag_atualiza_conta = 'S' THEN
   UPDATE pessoa
      SET fi_banco_id      = zvl(p_fi_banco_id, NULL),
          num_agencia      = TRIM(p_num_agencia),
          num_conta        = TRIM(p_num_conta),
          tipo_conta       = TRIM(p_tipo_conta),
          nome_titular     = TRIM(p_nome_titular),
          cnpj_cpf_titular = v_cnpj_cpf_titular
    WHERE usuario_id = v_solicitante_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Valor adiantado: ' || moeda_mostrar(v_valor_realiz, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- recalcula o valor disponivel
  v_valor_disponivel := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'DISPONIVEL');
  --
  IF v_valor_disponivel = 0 THEN
   UPDATE adiant_desp
      SET status = 'PCON'
    WHERE adiant_desp_id = p_adiant_desp_id;
   --
   v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
   v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ADIANT_DESP',
                    'TERMINAR',
                    v_identif_objeto,
                    p_adiant_desp_id,
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
  p_adiant_realiz_id := v_adiant_realiz_id;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END realizado_adicionar;
 --
 --
 PROCEDURE realizado_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 12/01/2015
  -- DESCRICAO: Exclusao de valor realizado (adiantado) - ADIANT_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_adiant_realiz_id  IN adiant_realiz.adiant_realiz_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_valor_realiz     adiant_realiz.valor_realiz%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_adiant_desp_id   adiant_desp.adiant_desp_id%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
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
    FROM adiant_realiz
   WHERE adiant_realiz_id = p_adiant_realiz_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento realizado não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado,
         ar.valor_realiz,
         ad.adiant_desp_id
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado,
         v_valor_realiz,
         v_adiant_desp_id
    FROM adiant_realiz ar,
         adiant_desp   ad,
         job           jo
   WHERE ar.adiant_realiz_id = p_adiant_realiz_id
     AND ar.adiant_desp_id = ad.adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EX', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant <> 'APRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(v_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(v_adiant_desp_id, 'S');
  v_compl_histor   := 'Estorno de valor adiantado: ' || moeda_mostrar(v_valor_realiz, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   v_adiant_desp_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   NULL,
                   v_historico_id,
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
  DELETE FROM adiant_realiz
   WHERE adiant_realiz_id = p_adiant_realiz_id;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END realizado_excluir;
 --
 --
 PROCEDURE despesa_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/01/2015
  -- DESCRICAO: Inclusao de valores de despesa - DESP_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_adiant_desp_id        IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_desp       IN VARCHAR2,
  p_vetor_tipo_produto_id IN VARCHAR2,
  p_vetor_complemento     IN VARCHAR2,
  p_vetor_fornecedor      IN VARCHAR2,
  p_vetor_num_doc         IN VARCHAR2,
  p_vetor_serie           IN VARCHAR2,
  p_vetor_valor_desp      IN VARCHAR2,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_valor_desp_it   IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
 
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_job_id                job.job_id%TYPE;
  v_num_job               job.numero%TYPE;
  v_status_job            job.status%TYPE;
  v_delimitador           CHAR(1);
  v_data_desp_char        VARCHAR2(20);
  v_complemento           VARCHAR2(2000);
  v_fornecedor            VARCHAR2(200);
  v_num_doc               VARCHAR2(200);
  v_serie                 VARCHAR2(200);
  v_valor_desp_char       VARCHAR2(50);
  v_vetor_data_desp       LONG;
  v_vetor_tipo_produto_id LONG;
  v_vetor_complemento     LONG;
  v_vetor_fornecedor      LONG;
  v_vetor_num_doc         LONG;
  v_vetor_serie           LONG;
  v_vetor_valor_desp      LONG;
  v_vetor_item_id         LONG;
  v_vetor_valor_desp_it   LONG;
  v_desp_realiz_id        desp_realiz.desp_realiz_id%TYPE;
  v_tipo_produto_id       desp_realiz.tipo_produto_id%TYPE;
  v_data_desp             desp_realiz.data_desp%TYPE;
  v_valor_desp            desp_realiz.valor_desp%TYPE;
  v_valor_solicitado      adiant_desp.valor_solicitado%TYPE;
  v_num_adiant            adiant_desp.num_adiant%TYPE;
  v_status_adiant         adiant_desp.status%TYPE;
  v_item_id               item_adiant.item_id%TYPE;
  v_valor_solic_it        item_adiant.valor_solicitado%TYPE;
  v_valor_devol_it        item_adiant.valor_devolvido%TYPE;
  v_valor_desp_it         item_adiant.valor_despesa%TYPE;
  v_valor_desp_it_char    VARCHAR2(20);
  v_valor_prestar         NUMBER;
  v_valor_desp_tot        NUMBER;
  v_valor_desp_it_tot     NUMBER;
  v_lbl_job               VARCHAR2(100);
  v_nome_item             VARCHAR2(200);
  v_xml_antes             CLOB;
  v_xml_atual             CLOB;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_PC', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - despesas
  ------------------------------------------------------------
  --
  v_delimitador           := '|';
  v_vetor_data_desp       := p_vetor_data_desp;
  v_vetor_tipo_produto_id := p_vetor_tipo_produto_id;
  v_vetor_complemento     := p_vetor_complemento;
  v_vetor_fornecedor      := p_vetor_fornecedor;
  v_vetor_num_doc         := p_vetor_num_doc;
  v_vetor_serie           := p_vetor_serie;
  v_vetor_valor_desp      := p_vetor_valor_desp;
  --
  WHILE nvl(length(rtrim(v_vetor_data_desp)), 0) > 0
  LOOP
   v_data_desp_char  := prox_valor_retornar(v_vetor_data_desp, v_delimitador);
   v_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_complemento     := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_fornecedor      := prox_valor_retornar(v_vetor_fornecedor, v_delimitador);
   v_num_doc         := prox_valor_retornar(v_vetor_num_doc, v_delimitador);
   v_serie           := prox_valor_retornar(v_vetor_serie, v_delimitador);
   v_valor_desp_char := prox_valor_retornar(v_vetor_valor_desp, v_delimitador);
   --
   IF TRIM(v_data_desp_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_desp_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_desp := data_converter(v_data_desp_char);
   --
   IF nvl(v_tipo_produto_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo de produto é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_fornecedor) > 100 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O fornecedor não pode ter mais que 100 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_num_doc) > 10 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número do documento não pode ter mais que 10 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_serie) > 10 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número de série não pode ter mais que 10 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_valor_desp_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do valor obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_desp_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_desp := nvl(moeda_converter(v_valor_desp_char), 0);
   --
   IF v_valor_desp <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
   --
   IF v_valor_desp > v_valor_prestar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor da despesa não pode ser maior do que o valor de ' ||
                  'contas a prestar (' || moeda_mostrar(v_valor_prestar, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT seq_desp_realiz.nextval
     INTO v_desp_realiz_id
     FROM dual;
   --
   INSERT INTO desp_realiz
    (desp_realiz_id,
     adiant_desp_id,
     usuario_id,
     data_entrada,
     data_desp,
     valor_desp,
     tipo_produto_id,
     complemento,
     fornecedor,
     num_doc,
     serie)
   VALUES
    (v_desp_realiz_id,
     p_adiant_desp_id,
     p_usuario_sessao_id,
     SYSDATE,
     v_data_desp,
     v_valor_desp,
     zvl(v_tipo_produto_id, NULL),
     TRIM(v_complemento),
     TRIM(v_fornecedor),
     TRIM(v_num_doc),
     TRIM(v_serie));
  
  END LOOP;
  --
  SELECT nvl(SUM(valor_desp), 0)
    INTO v_valor_desp_tot
    FROM desp_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - rateio dos itens
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_item_id       := p_vetor_item_id;
  v_vetor_valor_desp_it := p_vetor_valor_desp_it;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id            := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_desp_it_char := prox_valor_retornar(v_vetor_valor_desp_it, v_delimitador);
   --
   IF nvl(v_item_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do item é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item não associado ao adiantamento (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(valor_solicitado, 0),
          nvl(valor_devolvido, 0),
          orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq)
     INTO v_valor_solic_it,
          v_valor_devol_it,
          v_nome_item
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = v_item_id
      AND ia.item_id = it.item_id;
   --
   IF moeda_validar(v_valor_desp_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_desp_it := nvl(moeda_converter(v_valor_desp_it_char), 0);
   --
   IF v_valor_desp_it < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_desp_it + v_valor_devol_it > v_valor_solic_it THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A prestação de contas do item ultrapassa o valor solicitado (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE item_adiant
      SET valor_despesa = valor_despesa + v_valor_desp_it
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  SELECT nvl(SUM(valor_despesa), 0)
    INTO v_valor_desp_it_tot
    FROM item_adiant
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_valor_desp_it_tot <> v_valor_desp_tot THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor das despesas rateadas pelos itens deve ser igual a ' ||
                 moeda_mostrar(v_valor_desp_tot, 'S') || ' .';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Inclusão - Valor despesa: ' || moeda_mostrar(v_valor_desp_tot, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- recalcula o valor a prestar
  v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
  --
  IF v_valor_prestar = 0 AND v_status_adiant = 'PCON' AND
     usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EN', NULL, NULL, p_empresa_id) = 1 THEN
   -- total de contas prestadas e usuario com privilegio de encerrar
   --
   UPDATE adiant_desp
      SET status = 'ENCE'
    WHERE adiant_desp_id = p_adiant_desp_id;
   --
   v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
   v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ADIANT_DESP',
                    'CONCLUIR',
                    v_identif_objeto,
                    p_adiant_desp_id,
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
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END despesa_adicionar;
 --
 --
 PROCEDURE despesa_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/01/2015
  -- DESCRICAO: Informacao/edicao de valores de despesa - DESP_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN NUMBER,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_adiant_desp_id        IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_desp       IN VARCHAR2,
  p_vetor_tipo_produto_id IN VARCHAR2,
  p_vetor_complemento     IN VARCHAR2,
  p_vetor_fornecedor      IN VARCHAR2,
  p_vetor_num_doc         IN VARCHAR2,
  p_vetor_serie           IN VARCHAR2,
  p_vetor_valor_desp      IN VARCHAR2,
  p_vetor_item_id         IN VARCHAR2,
  p_vetor_valor_desp_it   IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
 
  v_qt                    INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_job_id                job.job_id%TYPE;
  v_num_job               job.numero%TYPE;
  v_status_job            job.status%TYPE;
  v_delimitador           CHAR(1);
  v_data_desp_char        VARCHAR2(20);
  v_complemento           VARCHAR2(2000);
  v_fornecedor            VARCHAR2(200);
  v_num_doc               VARCHAR2(200);
  v_serie                 VARCHAR2(200);
  v_valor_desp_char       VARCHAR2(50);
  v_vetor_data_desp       LONG;
  v_vetor_tipo_produto_id LONG;
  v_vetor_complemento     LONG;
  v_vetor_fornecedor      LONG;
  v_vetor_num_doc         LONG;
  v_vetor_serie           LONG;
  v_vetor_valor_desp      LONG;
  v_vetor_item_id         LONG;
  v_vetor_valor_desp_it   LONG;
  v_desp_realiz_id        desp_realiz.desp_realiz_id%TYPE;
  v_tipo_produto_id       desp_realiz.tipo_produto_id%TYPE;
  v_data_desp             desp_realiz.data_desp%TYPE;
  v_valor_desp            desp_realiz.valor_desp%TYPE;
  v_valor_solicitado      adiant_desp.valor_solicitado%TYPE;
  v_num_adiant            adiant_desp.num_adiant%TYPE;
  v_status_adiant         adiant_desp.status%TYPE;
  v_item_id               item_adiant.item_id%TYPE;
  v_valor_solic_it        item_adiant.valor_solicitado%TYPE;
  v_valor_devol_it        item_adiant.valor_devolvido%TYPE;
  v_valor_desp_it         item_adiant.valor_despesa%TYPE;
  v_valor_desp_it_char    VARCHAR2(20);
  v_valor_prestar         NUMBER;
  v_valor_desp_tot        NUMBER;
  v_valor_desp_it_tot     NUMBER;
  v_lbl_job               VARCHAR2(100);
  v_nome_item             VARCHAR2(200);
  v_xml_antes             CLOB;
  v_xml_atual             CLOB;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_PC', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - despesas
  ------------------------------------------------------------
  DELETE FROM desp_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  v_delimitador           := '|';
  v_vetor_data_desp       := p_vetor_data_desp;
  v_vetor_tipo_produto_id := p_vetor_tipo_produto_id;
  v_vetor_complemento     := p_vetor_complemento;
  v_vetor_fornecedor      := p_vetor_fornecedor;
  v_vetor_num_doc         := p_vetor_num_doc;
  v_vetor_serie           := p_vetor_serie;
  v_vetor_valor_desp      := p_vetor_valor_desp;
  --
  WHILE nvl(length(rtrim(v_vetor_data_desp)), 0) > 0
  LOOP
   v_data_desp_char  := prox_valor_retornar(v_vetor_data_desp, v_delimitador);
   v_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_tipo_produto_id, v_delimitador));
   v_complemento     := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_fornecedor      := prox_valor_retornar(v_vetor_fornecedor, v_delimitador);
   v_num_doc         := prox_valor_retornar(v_vetor_num_doc, v_delimitador);
   v_serie           := prox_valor_retornar(v_vetor_serie, v_delimitador);
   v_valor_desp_char := prox_valor_retornar(v_vetor_valor_desp, v_delimitador);
   --
   IF TRIM(v_data_desp_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_desp_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_desp := data_converter(v_data_desp_char);
   --
   IF nvl(v_tipo_produto_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo de produto é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 500 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_fornecedor) > 100 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O fornecedor não pode ter mais que 100 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_num_doc) > 10 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número do documento não pode ter mais que 10 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_serie) > 10 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número de série não pode ter mais que 10 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_valor_desp_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_desp_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_desp := nvl(moeda_converter(v_valor_desp_char), 0);
   --
   IF v_valor_desp <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
   --
   IF v_valor_desp > v_valor_prestar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor da despesa não pode ser maior do que o valor de ' ||
                  'contas a prestar (' || moeda_mostrar(v_valor_prestar, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT seq_desp_realiz.nextval
     INTO v_desp_realiz_id
     FROM dual;
   --
   INSERT INTO desp_realiz
    (desp_realiz_id,
     adiant_desp_id,
     usuario_id,
     data_entrada,
     data_desp,
     valor_desp,
     tipo_produto_id,
     complemento,
     fornecedor,
     num_doc,
     serie)
   VALUES
    (v_desp_realiz_id,
     p_adiant_desp_id,
     p_usuario_sessao_id,
     SYSDATE,
     v_data_desp,
     v_valor_desp,
     zvl(v_tipo_produto_id, NULL),
     TRIM(v_complemento),
     TRIM(v_fornecedor),
     TRIM(v_num_doc),
     TRIM(v_serie));
  
  END LOOP;
  --
  SELECT nvl(SUM(valor_desp), 0)
    INTO v_valor_desp_tot
    FROM desp_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - rateio dos itens
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_item_id       := p_vetor_item_id;
  v_vetor_valor_desp_it := p_vetor_valor_desp_it;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id            := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_desp_it_char := prox_valor_retornar(v_vetor_valor_desp_it, v_delimitador);
   --
   IF nvl(v_item_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do item é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item não associado ao adiantamento (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(valor_solicitado, 0),
          nvl(valor_devolvido, 0),
          orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq)
     INTO v_valor_solic_it,
          v_valor_devol_it,
          v_nome_item
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = v_item_id
      AND ia.item_id = it.item_id;
   --
   IF moeda_validar(v_valor_desp_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_desp_it := nvl(moeda_converter(v_valor_desp_it_char), 0);
   --
   IF v_valor_desp_it < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_desp_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_desp_it + v_valor_devol_it > v_valor_solic_it THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A prestação de contas do item ultrapassa o valor solicitado (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE item_adiant
      SET valor_despesa = v_valor_desp_it
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  SELECT nvl(SUM(valor_despesa), 0)
    INTO v_valor_desp_it_tot
    FROM item_adiant
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_valor_desp_it_tot <> v_valor_desp_tot THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor das despesas rateadas pelos itens deve ser igual a ' ||
                 moeda_mostrar(v_valor_desp_tot, 'S') || ' .';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Alteração - Valor despesa: ' || moeda_mostrar(v_valor_desp_tot, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- recalcula o valor a prestar
  v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
  --
  IF v_valor_prestar = 0 AND v_status_adiant = 'PCON' AND
     usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EN', NULL, NULL, p_empresa_id) = 1 THEN
   -- total de contas prestadas e usuario com privilegio de encerrar
   --
   UPDATE adiant_desp
      SET status = 'ENCE'
    WHERE adiant_desp_id = p_adiant_desp_id;
   --
   v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
   v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ADIANT_DESP',
                    'CONCLUIR',
                    v_identif_objeto,
                    p_adiant_desp_id,
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
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END despesa_atualizar;
 --
 --
 PROCEDURE despesa_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 12/01/2015
  -- DESCRICAO: Exclusao de valor de despesa - DESP_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_desp_realiz_id    IN desp_realiz.desp_realiz_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_valor_desp       desp_realiz.valor_desp%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_adiant_desp_id   adiant_desp.adiant_desp_id%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
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
    FROM desp_realiz
   WHERE desp_realiz_id = p_desp_realiz_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa despesa não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado,
         dr.valor_desp
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado,
         v_valor_desp
    FROM desp_realiz dr,
         adiant_desp ad,
         job         jo
   WHERE dr.desp_realiz_id = p_desp_realiz_id
     AND dr.adiant_desp_id = ad.adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_PC', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(v_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(v_adiant_desp_id, 'S');
  v_compl_histor   := 'Estorno de despesa: ' || moeda_mostrar(v_valor_desp, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   v_adiant_desp_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   NULL,
                   v_historico_id,
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
  DELETE FROM desp_realiz
   WHERE desp_realiz_id = p_desp_realiz_id;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END despesa_excluir;
 --
 --
 PROCEDURE devolucao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/01/2015
  -- DESCRICAO: Inclusao de valores de devolucao - DEVOL_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_adiant_desp_id       IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_devol     IN VARCHAR2,
  p_vetor_forma_devol    IN VARCHAR2,
  p_vetor_complemento    IN VARCHAR2,
  p_vetor_valor_devol    IN VARCHAR2,
  p_vetor_item_id        IN VARCHAR2,
  p_vetor_valor_devol_it IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_job_id               job.job_id%TYPE;
  v_num_job              job.numero%TYPE;
  v_status_job           job.status%TYPE;
  v_delimitador          CHAR(1);
  v_data_devol_char      VARCHAR2(20);
  v_complemento          VARCHAR2(2000);
  v_forma_devol          VARCHAR2(50);
  v_valor_devol_char     VARCHAR2(50);
  v_vetor_data_devol     LONG;
  v_vetor_complemento    LONG;
  v_vetor_forma_devol    LONG;
  v_vetor_valor_devol    LONG;
  v_vetor_item_id        LONG;
  v_vetor_valor_devol_it LONG;
  v_devol_realiz_id      devol_realiz.devol_realiz_id%TYPE;
  v_data_devol           devol_realiz.data_devol%TYPE;
  v_valor_devol          devol_realiz.valor_devol%TYPE;
  v_valor_solicitado     adiant_desp.valor_solicitado%TYPE;
  v_num_adiant           adiant_desp.num_adiant%TYPE;
  v_status_adiant        adiant_desp.status%TYPE;
  v_item_id              item_adiant.item_id%TYPE;
  v_valor_solic_it       item_adiant.valor_solicitado%TYPE;
  v_valor_devol_it       item_adiant.valor_devolvido%TYPE;
  v_valor_desp_it        item_adiant.valor_despesa%TYPE;
  v_valor_devol_it_char  VARCHAR2(20);
  v_valor_prestar        NUMBER;
  v_valor_devol_tot      NUMBER;
  v_valor_devol_it_tot   NUMBER;
  v_lbl_job              VARCHAR2(100);
  v_nome_item            VARCHAR2(200);
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_DV', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - despesas
  ------------------------------------------------------------
  --
  v_delimitador       := '|';
  v_vetor_data_devol  := p_vetor_data_devol;
  v_vetor_forma_devol := p_vetor_forma_devol;
  v_vetor_complemento := p_vetor_complemento;
  v_vetor_valor_devol := p_vetor_valor_devol;
  --
  WHILE nvl(length(rtrim(v_vetor_data_devol)), 0) > 0
  LOOP
   v_data_devol_char  := prox_valor_retornar(v_vetor_data_devol, v_delimitador);
   v_forma_devol      := prox_valor_retornar(v_vetor_forma_devol, v_delimitador);
   v_complemento      := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_valor_devol_char := prox_valor_retornar(v_vetor_valor_devol, v_delimitador);
   --
   IF TRIM(v_data_devol_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_devol_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_devol := data_converter(v_data_devol_char);
   --
   IF TRIM(v_forma_devol) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da forma de devolução é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF util_pkg.desc_retornar('forma_adiant_desp', v_forma_devol) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Forma de devolução inválida (' || v_forma_devol || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 200 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O histórico não pode ter mais que 200 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_valor_devol_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do valor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_devol_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_devol := nvl(moeda_converter(v_valor_devol_char), 0);
   --
   IF v_valor_devol <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
   --
   IF v_valor_devol > v_valor_prestar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor da devolução não pode ser maior do que o valor de ' ||
                  'contas a prestar (' || moeda_mostrar(v_valor_prestar, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT seq_devol_realiz.nextval
     INTO v_devol_realiz_id
     FROM dual;
   --
   INSERT INTO devol_realiz
    (devol_realiz_id,
     adiant_desp_id,
     usuario_id,
     data_entrada,
     data_devol,
     valor_devol,
     forma_devol,
     complemento)
   VALUES
    (v_devol_realiz_id,
     p_adiant_desp_id,
     p_usuario_sessao_id,
     SYSDATE,
     v_data_devol,
     v_valor_devol,
     v_forma_devol,
     TRIM(v_complemento));
  
  END LOOP;
  --
  SELECT nvl(SUM(valor_devol), 0)
    INTO v_valor_devol_tot
    FROM devol_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - rateio dos itens
  ------------------------------------------------------------
  v_delimitador          := '|';
  v_vetor_item_id        := p_vetor_item_id;
  v_vetor_valor_devol_it := p_vetor_valor_devol_it;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id             := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_devol_it_char := prox_valor_retornar(v_vetor_valor_devol_it, v_delimitador);
   --
   IF nvl(v_item_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do item é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item não associado ao adiantamento (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(valor_solicitado, 0),
          nvl(valor_devolvido, 0),
          orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq)
     INTO v_valor_solic_it,
          v_valor_devol_it,
          v_nome_item
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = v_item_id
      AND ia.item_id = it.item_id;
   --
   IF moeda_validar(v_valor_devol_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_devol_it := nvl(moeda_converter(v_valor_devol_it_char), 0);
   --
   IF v_valor_devol_it < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_desp_it + v_valor_devol_it > v_valor_solic_it THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A prestação de contas do item ultrapassa o valor solicitado (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE item_adiant
      SET valor_devolvido = valor_devolvido + v_valor_devol_it
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  SELECT nvl(SUM(valor_devolvido), 0)
    INTO v_valor_devol_it_tot
    FROM item_adiant
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_valor_devol_it_tot <> v_valor_devol_tot THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor das devoluções rateadas pelos itens deve ser igual a ' ||
                 moeda_mostrar(v_valor_devol_tot, 'S') || ' .';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Inclusão - Valor devolvido: ' || moeda_mostrar(v_valor_devol_tot, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- recalcula o valor a prestar
  v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
  --
  IF v_valor_prestar = 0 AND v_status_adiant = 'PCON' AND
     usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EN', NULL, NULL, p_empresa_id) = 1 THEN
   -- total de contas prestadas e usuario com privilegio de encerrar
   --
   UPDATE adiant_desp
      SET status = 'ENCE'
    WHERE adiant_desp_id = p_adiant_desp_id;
   --
   v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
   v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ADIANT_DESP',
                    'CONCLUIR',
                    v_identif_objeto,
                    p_adiant_desp_id,
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
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END devolucao_adicionar;
 --
 --
 PROCEDURE devolucao_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 16/01/2015
  -- DESCRICAO: Atualizacao em lista de valores de devolucao - DEVOL_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_adiant_desp_id       IN adiant_realiz.adiant_desp_id%TYPE,
  p_vetor_data_devol     IN VARCHAR2,
  p_vetor_forma_devol    IN VARCHAR2,
  p_vetor_complemento    IN VARCHAR2,
  p_vetor_valor_devol    IN VARCHAR2,
  p_vetor_item_id        IN VARCHAR2,
  p_vetor_valor_devol_it IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_job_id               job.job_id%TYPE;
  v_num_job              job.numero%TYPE;
  v_status_job           job.status%TYPE;
  v_delimitador          CHAR(1);
  v_data_devol_char      VARCHAR2(20);
  v_complemento          VARCHAR2(2000);
  v_forma_devol          VARCHAR2(50);
  v_valor_devol_char     VARCHAR2(50);
  v_vetor_data_devol     LONG;
  v_vetor_complemento    LONG;
  v_vetor_forma_devol    LONG;
  v_vetor_valor_devol    LONG;
  v_vetor_item_id        LONG;
  v_vetor_valor_devol_it LONG;
  v_devol_realiz_id      devol_realiz.devol_realiz_id%TYPE;
  v_data_devol           devol_realiz.data_devol%TYPE;
  v_valor_devol          devol_realiz.valor_devol%TYPE;
  v_valor_solicitado     adiant_desp.valor_solicitado%TYPE;
  v_num_adiant           adiant_desp.num_adiant%TYPE;
  v_status_adiant        adiant_desp.status%TYPE;
  v_item_id              item_adiant.item_id%TYPE;
  v_valor_solic_it       item_adiant.valor_solicitado%TYPE;
  v_valor_devol_it       item_adiant.valor_devolvido%TYPE;
  v_valor_desp_it        item_adiant.valor_despesa%TYPE;
  v_valor_devol_it_char  VARCHAR2(20);
  v_valor_prestar        NUMBER;
  v_valor_devol_tot      NUMBER;
  v_valor_devol_it_tot   NUMBER;
  v_lbl_job              VARCHAR2(100);
  v_nome_item            VARCHAR2(200);
  v_xml_antes            CLOB;
  v_xml_atual            CLOB;
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
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse adiantamento para despesas não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_DV', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - despesas
  ------------------------------------------------------------
  DELETE FROM devol_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  v_delimitador       := '|';
  v_vetor_data_devol  := p_vetor_data_devol;
  v_vetor_forma_devol := p_vetor_forma_devol;
  v_vetor_complemento := p_vetor_complemento;
  v_vetor_valor_devol := p_vetor_valor_devol;
  --
  WHILE nvl(length(rtrim(v_vetor_data_devol)), 0) > 0
  LOOP
   v_data_devol_char  := prox_valor_retornar(v_vetor_data_devol, v_delimitador);
   v_forma_devol      := prox_valor_retornar(v_vetor_forma_devol, v_delimitador);
   v_complemento      := prox_valor_retornar(v_vetor_complemento, v_delimitador);
   v_valor_devol_char := prox_valor_retornar(v_vetor_valor_devol, v_delimitador);
   --
   IF TRIM(v_data_devol_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF data_validar(v_data_devol_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_devol := data_converter(v_data_devol_char);
   --
   IF TRIM(v_forma_devol) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da forma de devolução é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF util_pkg.desc_retornar('forma_adiant_desp', v_forma_devol) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Forma de devolução inválida (' || v_forma_devol || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_complemento) > 200 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O histórico não pode ter mais que 200 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_valor_devol_char) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do valor é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF moeda_validar(v_valor_devol_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_devol := nvl(moeda_converter(v_valor_devol_char), 0);
   --
   IF v_valor_devol <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
   --
   IF v_valor_devol > v_valor_prestar THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O valor da devolução não pode ser maior do que o valor de ' ||
                  'contas a prestar (' || moeda_mostrar(v_valor_prestar, 'S') || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT seq_devol_realiz.nextval
     INTO v_devol_realiz_id
     FROM dual;
   --
   INSERT INTO devol_realiz
    (devol_realiz_id,
     adiant_desp_id,
     usuario_id,
     data_entrada,
     data_devol,
     valor_devol,
     forma_devol,
     complemento)
   VALUES
    (v_devol_realiz_id,
     p_adiant_desp_id,
     p_usuario_sessao_id,
     SYSDATE,
     v_data_devol,
     v_valor_devol,
     v_forma_devol,
     TRIM(v_complemento));
  
  END LOOP;
  --
  SELECT nvl(SUM(valor_devol), 0)
    INTO v_valor_devol_tot
    FROM devol_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - rateio dos itens
  ------------------------------------------------------------
  v_delimitador          := '|';
  v_vetor_item_id        := p_vetor_item_id;
  v_vetor_valor_devol_it := p_vetor_valor_devol_it;
  --
  WHILE nvl(length(rtrim(v_vetor_item_id)), 0) > 0
  LOOP
   v_item_id             := to_number(prox_valor_retornar(v_vetor_item_id, v_delimitador));
   v_valor_devol_it_char := prox_valor_retornar(v_vetor_valor_devol_it, v_delimitador);
   --
   IF nvl(v_item_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do item é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_adiant
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Item não associado ao adiantamento (' || to_char(v_item_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(valor_solicitado, 0),
          nvl(valor_devolvido, 0),
          orcamento_pkg.numero_formatar(it.orcamento_id) || ' ' || it.tipo_item ||
          to_char(it.num_seq)
     INTO v_valor_solic_it,
          v_valor_devol_it,
          v_nome_item
     FROM item_adiant ia,
          item        it
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = v_item_id
      AND ia.item_id = it.item_id;
   --
   IF moeda_validar(v_valor_devol_it_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_valor_devol_it := nvl(moeda_converter(v_valor_devol_it_char), 0);
   --
   IF v_valor_devol_it < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor inválido (' || v_valor_devol_it_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_valor_desp_it + v_valor_devol_it > v_valor_solic_it THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A prestação de contas do item ultrapassa o valor solicitado (' || v_nome_item || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE item_adiant
      SET valor_devolvido = v_valor_devol_it
    WHERE adiant_desp_id = p_adiant_desp_id
      AND item_id = v_item_id;
   --
   item_pkg.valores_recalcular(p_usuario_sessao_id, v_item_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  SELECT nvl(SUM(valor_devolvido), 0)
    INTO v_valor_devol_it_tot
    FROM item_adiant
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF v_valor_devol_it_tot <> v_valor_devol_tot THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor das devoluções rateadas pelos itens deve ser igual a ' ||
                 moeda_mostrar(v_valor_devol_tot, 'S') || ' .';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(p_adiant_desp_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
  v_compl_histor   := 'Alteração - Valor devolvido: ' || moeda_mostrar(v_valor_devol_tot, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   p_adiant_desp_id,
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
  -- recalcula o valor a prestar
  v_valor_prestar := adiant_desp_pkg.valor_retornar(p_adiant_desp_id, 'CONTA_PRESTAR');
  --
  IF v_valor_prestar = 0 AND v_status_adiant = 'PCON' AND
     usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_EN', NULL, NULL, p_empresa_id) = 1 THEN
   -- total de contas prestadas e usuario com privilegio de encerrar
   --
   UPDATE adiant_desp
      SET status = 'ENCE'
    WHERE adiant_desp_id = p_adiant_desp_id;
   --
   v_identif_objeto := adiant_desp_pkg.numero_formatar(p_adiant_desp_id, 'S');
   v_compl_histor   := 'Valor solicitado: ' || moeda_mostrar(v_valor_solicitado, 'S');
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ADIANT_DESP',
                    'CONCLUIR',
                    v_identif_objeto,
                    p_adiant_desp_id,
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
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END devolucao_atualizar;
 --
 --
 PROCEDURE devolucao_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 12/01/2015
  -- DESCRICAO: Exclusao de valor devolvido - DEVOL_REALIZ
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/08/2017  Guarda XML no historico.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_devol_realiz_id   IN devol_realiz.devol_realiz_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_num_job          job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_valor_devol      devol_realiz.valor_devol%TYPE;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_num_adiant       adiant_desp.num_adiant%TYPE;
  v_adiant_desp_id   adiant_desp.adiant_desp_id%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
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
    FROM devol_realiz
   WHERE devol_realiz_id = p_devol_realiz_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa devolução não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ad.status,
         ad.num_adiant,
         ad.valor_solicitado,
         dr.valor_devol
    INTO v_job_id,
         v_num_job,
         v_status_job,
         v_status_adiant,
         v_num_adiant,
         v_valor_solicitado,
         v_valor_devol
    FROM devol_realiz dr,
         adiant_desp  ad,
         job          jo
   WHERE dr.devol_realiz_id = p_devol_realiz_id
     AND dr.adiant_desp_id = ad.adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  -- privilegio do grupo JOB
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ADIDESP_DV', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_adiant NOT IN ('APRO', 'PCON') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do adiantamento não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  adiant_desp_pkg.xml_gerar(v_adiant_desp_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := adiant_desp_pkg.numero_formatar(v_adiant_desp_id, 'S');
  v_compl_histor   := 'Estorno de valor devolvido: ' || moeda_mostrar(v_valor_devol, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ADIANT_DESP',
                   'ALTERAR',
                   v_identif_objeto,
                   v_adiant_desp_id,
                   v_compl_histor,
                   NULL,
                   'N',
                   v_xml_antes,
                   NULL,
                   v_historico_id,
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
  DELETE FROM devol_realiz
   WHERE devol_realiz_id = p_devol_realiz_id;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END devolucao_excluir;
 --
 --
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/01/2015
  -- DESCRICAO: retorna o numero formatado de um determinado adiantamento de despesa,
  --   com o sem prefixo (nro do job).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
  p_flag_prefixo   IN VARCHAR2
 ) RETURN VARCHAR2 AS
 
  v_retorno    VARCHAR2(100);
  v_qt         INTEGER;
  v_num_job    job.numero%TYPE;
  v_num_adiant adiant_desp.num_adiant%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         ad.num_adiant
    INTO v_num_job,
         v_num_adiant
    FROM adiant_desp ad,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id;
  --
  IF length(v_num_adiant) <= 3 THEN
   v_retorno := TRIM(to_char(v_num_adiant, '000'));
  ELSE
   v_retorno := to_char(v_num_adiant);
  END IF;
  --
  IF p_flag_prefixo = 'S' THEN
   v_retorno := v_num_job || '-' || v_retorno;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_formatar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 16/01/2015
  -- DESCRICAO: retorna o valor de um determinado adiantamento de despesa,
  --   de acordo com o tipo especificado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
  p_tipo_valor     IN VARCHAR2
 ) RETURN NUMBER AS
 
  v_retorno          NUMBER;
  v_qt               INTEGER;
  v_valor_solicitado adiant_desp.valor_solicitado%TYPE;
  v_status_adiant    adiant_desp.status%TYPE;
  v_valor_adiantado  NUMBER;
  v_valor_prestado   NUMBER;
  v_valor_despesa    NUMBER;
  v_valor_devolvido  NUMBER;
  v_exception        EXCEPTION;
  --
 BEGIN
  v_retorno          := 0;
  v_valor_solicitado := 0;
  v_valor_adiantado  := 0;
  v_valor_prestado   := 0;
  v_valor_despesa    := 0;
  v_valor_devolvido  := 0;
  --
  IF p_tipo_valor NOT IN ('SOLICITADO',
                          'ADIANTADO',
                          'DISPONIVEL',
                          'CONTA_PRESTADA',
                          'CONTA_PRESTAR',
                          'DEVOLVIDO',
                          'EFETIVO') OR TRIM(p_tipo_valor) IS NULL THEN
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(valor_solicitado, 0),
         status
    INTO v_valor_solicitado,
         v_status_adiant
    FROM adiant_desp
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  SELECT nvl(SUM(valor_realiz), 0)
    INTO v_valor_adiantado
    FROM adiant_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  SELECT nvl(SUM(valor_desp), 0)
    INTO v_valor_despesa
    FROM desp_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  SELECT nvl(SUM(valor_devol), 0)
    INTO v_valor_devolvido
    FROM devol_realiz
   WHERE adiant_desp_id = p_adiant_desp_id;
  --
  IF p_tipo_valor = 'SOLICITADO' THEN
   v_retorno := v_valor_solicitado;
  ELSIF p_tipo_valor = 'ADIANTADO' THEN
   v_retorno := v_valor_adiantado;
  ELSIF p_tipo_valor = 'DISPONIVEL' THEN
   v_retorno := v_valor_solicitado - v_valor_adiantado;
  ELSIF p_tipo_valor = 'CONTA_PRESTADA' THEN
   v_retorno := v_valor_despesa + v_valor_devolvido;
  ELSIF p_tipo_valor = 'DEVOLVIDO' THEN
   v_retorno := v_valor_devolvido;
  ELSIF p_tipo_valor = 'CONTA_PRESTAR' THEN
   v_retorno := v_valor_adiantado - v_valor_despesa - v_valor_devolvido;
  ELSIF p_tipo_valor = 'EFETIVO' THEN
   IF v_status_adiant IN ('EMAP', 'APRO', 'REPR', 'PCON') THEN
    v_retorno := v_valor_solicitado;
   ELSIF v_status_adiant = 'ENCE' THEN
    v_retorno := v_valor_despesa;
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 21/08/2017
  -- DESCRICAO: Subrotina que gera o xml do adiantamento para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_adiant_desp_id IN adiant_desp.adiant_desp_id%TYPE,
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
  CURSOR c_it IS
   SELECT orcamento_pkg.numero_formatar(it.orcamento_id) || '/' || it.tipo_item ||
          to_char(it.num_seq) AS num_item,
          tp.nome AS tipo_produto,
          numero_mostrar(ia.valor_solicitado, 2, 'N') valor_solicitado,
          numero_mostrar(ia.valor_despesa, 2, 'N') valor_despesa,
          numero_mostrar(ia.valor_devolvido, 2, 'N') valor_devolvido
     FROM item_adiant  ia,
          item         it,
          tipo_produto tp
    WHERE ia.adiant_desp_id = p_adiant_desp_id
      AND ia.item_id = it.item_id
      AND it.tipo_produto_id = tp.tipo_produto_id
    ORDER BY 1;
  --
  CURSOR c_ar IS
   SELECT pe.apelido,
          data_mostrar(ar.data_entrada) AS data_ent,
          numero_mostrar(ar.valor_realiz, 2, 'N') AS valor_adiantado,
          util_pkg.desc_retornar('forma_adiant_desp', ar.forma_adiant) AS forma
     FROM adiant_realiz ar,
          pessoa        pe
    WHERE ar.adiant_desp_id = p_adiant_desp_id
      AND ar.usuario_id = pe.usuario_id
    ORDER BY ar.data_entrada;
  --
  CURSOR c_dr IS
   SELECT pe.apelido,
          data_mostrar(dr.data_entrada) AS data_ent,
          data_mostrar(dr.data_desp) AS data_despesa,
          numero_mostrar(dr.valor_desp, 2, 'N') AS valor_despesa,
          TRIM(tp.nome || ' ' || dr.complemento) AS tipo_produto,
          dr.fornecedor,
          dr.num_doc,
          dr.serie
     FROM desp_realiz  dr,
          pessoa       pe,
          tipo_produto tp
    WHERE dr.adiant_desp_id = p_adiant_desp_id
      AND dr.usuario_id = pe.usuario_id
      AND dr.tipo_produto_id = tp.tipo_produto_id
    ORDER BY dr.data_entrada;
  --
  CURSOR c_dv IS
   SELECT pe.apelido,
          data_mostrar(dv.data_entrada) AS data_ent,
          data_mostrar(dv.data_devol) AS data_devolucao,
          numero_mostrar(dv.valor_devol, 2, 'N') AS valor_devolvido,
          util_pkg.desc_retornar('forma_adiant_desp', dv.forma_devol) AS forma,
          dv.complemento
     FROM devol_realiz dv,
          pessoa       pe
    WHERE dv.adiant_desp_id = p_adiant_desp_id
      AND dv.usuario_id = pe.usuario_id
    ORDER BY dv.data_entrada;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("adiant_desp_id", ad.adiant_desp_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("numero_adiant", ad.num_adiant),
                   xmlelement("criador", cr.apelido),
                   xmlelement("data_entrada", data_hora_mostrar(ad.data_entrada)),
                   xmlelement("solicitante", so.apelido),
                   xmlelement("valor_solicitado", numero_mostrar(ad.valor_solicitado, 2, 'S')),
                   xmlelement("motivo",
                              util_pkg.desc_retornar('motivo_adiant_desp', ad.motivo_adiant)),
                   xmlelement("complemento", ad.complemento),
                   xmlelement("forma_adiant_pref",
                              util_pkg.desc_retornar('forma_adiant_desp', ad.forma_adiant_pref)),
                   xmlelement("data_limite", data_hora_mostrar(ad.data_limite)),
                   xmlelement("aprovador", ap.apelido),
                   xmlelement("data_aprovacao", data_hora_mostrar(ad.data_aprov)),
                   xmlelement("status", ad.status),
                   xmlelement("data_status", data_hora_mostrar(ad.data_status)))
    INTO v_xml
    FROM adiant_desp ad,
         pessoa      so,
         pessoa      cr,
         pessoa      ap,
         job         jo
   WHERE ad.adiant_desp_id = p_adiant_desp_id
     AND ad.job_id = jo.job_id
     AND ad.solicitante_id = so.usuario_id
     AND ad.criador_id = cr.usuario_id
     AND ad.aprovador_id = ap.usuario_id(+);
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
                            xmlelement("valor_solicitado", r_it.valor_solicitado),
                            xmlelement("valor_despesa", r_it.valor_despesa),
                            xmlelement("valor_devolvido", r_it.valor_devolvido)))
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
  -- monta ADIANTAMENTOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ar IN c_ar
  LOOP
   SELECT xmlagg(xmlelement("adiantamento",
                            xmlelement("usuario", r_ar.apelido),
                            xmlelement("data_entrada", r_ar.data_ent),
                            xmlelement("valor_adiantado", r_ar.valor_adiantado),
                            xmlelement("forma", r_ar.forma)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("adiantamentos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta DESPESAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_dr IN c_dr
  LOOP
   SELECT xmlagg(xmlelement("despesa",
                            xmlelement("usuario", r_dr.apelido),
                            xmlelement("data_entrada", r_dr.data_ent),
                            xmlelement("data_despesa", r_dr.data_despesa),
                            xmlelement("valor_despesa", r_dr.valor_despesa),
                            xmlelement("tipo_produto", r_dr.tipo_produto),
                            xmlelement("fornecedor", r_dr.fornecedor),
                            xmlelement("num_doc", r_dr.num_doc),
                            xmlelement("serie", r_dr.serie)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("despesas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta DEVOLUCOES
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_dv IN c_dv
  LOOP
   SELECT xmlagg(xmlelement("devolucao",
                            xmlelement("usuario", r_dv.apelido),
                            xmlelement("data_entrada", r_dv.data_ent),
                            xmlelement("data_devolucao", r_dv.data_devolucao),
                            xmlelement("valor_devolvido", r_dv.valor_devolvido),
                            xmlelement("forma", r_dv.forma),
                            xmlelement("complemento", r_dv.complemento)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  
  END LOOP;
  --
  SELECT xmlagg(xmlelement("devolucoes", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "adiant_despesa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("adiant_despesa", v_xml))
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
END; -- ADIANT_DESP_PKG

/
