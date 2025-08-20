--------------------------------------------------------
--  DDL for Package Body JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "JOB_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Inclusão de JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2007  Numero do job aberto p/ inclusao (jobs antigos).
  --                               Tratamento de flag_pago_cliente
  -- Silvia            26/09/2007  Privilegio p/ criar jobs antigos. Nao se usa mais
  --                               sequence p/ gerar o numero do job.
  -- Silvia            15/12/2008  Novo atributo em job_usuario_papel (flag_comissionado).
  -- Silvia            03/06/2009  Novo parametro flag_bloq_negoc.
  -- Silvia            08/06/2009  Pega percentuais de encargos do cliente (se houver).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            28/10/2011  Implementacao do auto-enderecamento.
  -- Silvia            09/02/2012  Caminho para arquivos externos.
  -- Silvia            11/01/2013  Novo mecanismo de numeracao do job.
  -- Silvia            12/06/2013  Novo parametro emp_resp_id.
  -- Silvia            21/02/2014  Tratamento para geracao de numero duplicado de job.
  -- Silvia            11/09/2014  Novo parametro contrato_id.
  -- Silvia            03/12/2014  Grava data de entrada na agencia no cliente.
  -- Silvia            12/01/2016  Criacao autom. cronograma.
  -- Silvia            03/03/2016  Complexidade do job.
  -- Silvia            23/03/2016  Tratamento do status auxiliar/estendido.
  -- Silvia            11/05/2016  Novo parametro campanha_id.
  -- Silvia            31/05/2016  Enderecamento de responsavel interno.
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            04/09/2018  Novo atributo flag_obriga_desc_horas.
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev e 
  --                                      receita_prevista
  -- Silvia            21/01/2019  Eliminacao do privilegio JOB_IA (jobs antigos); novo
  --                               parametro cod_ext_job
  -- Silvia            13/04/2020  Registro do evento de tipo financeiro
  -- Joel Dias         29/11/2023  Inclusão do parâmetro p_flag_commit
  -- Ana Luiza         04/06/2024  Inclusao de parametros adicionais job automatico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_cliente_id         IN job.cliente_id%TYPE,
  p_emp_resp_id        IN job.emp_resp_id%TYPE,
  p_tipo_job_id        IN job.tipo_job_id%TYPE,
  p_tipo_financeiro_id IN job.tipo_financeiro_id%TYPE,
  p_contrato_id        IN job.contrato_id%TYPE,
  p_campanha_id        IN job.campanha_id%TYPE,
  p_numero_job         IN VARCHAR2,
  p_cod_ext_job        IN VARCHAR2,
  p_nome               IN job.nome%TYPE,
  p_descricao          IN LONG,
  p_complex_job        IN VARCHAR2,
  p_flag_commit        IN VARCHAR2,
  p_produto_cliente_id IN VARCHAR2,
  p_data_prev_ini      IN VARCHAR2,
  p_data_prev_fim      IN VARCHAR2,
  p_job_id             OUT job.job_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_priv_todos             INTEGER;
  v_exception              EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_tipo_num_job           job.tipo_num_job%TYPE;
  v_flag_pago_cliente      job.flag_pago_cliente%TYPE;
  v_perc_bv                job.perc_bv%TYPE;
  v_flag_bv_fornec         job.flag_bv_fornec%TYPE;
  v_caminho_arq_externo    job.caminho_arq_externo%TYPE;
  v_status_aux_job_id      job.status_aux_job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_emp_faturar_por_id     job.emp_faturar_por_id%TYPE;
  v_mod_crono_id           mod_crono.mod_crono_id%TYPE;
  v_flag_cria_crono_auto   tipo_job.flag_cria_crono_auto%TYPE;
  v_flag_tem_camp          tipo_job.flag_tem_camp%TYPE;
  v_flag_camp_obr          tipo_job.flag_camp_obr%TYPE;
  v_flag_ender_todos       tipo_job.flag_ender_todos%TYPE;
  v_flag_usa_budget        tipo_financeiro.flag_usa_budget%TYPE;
  v_flag_usa_receita_prev  tipo_financeiro.flag_usa_receita_prev%TYPE;
  v_flag_obriga_contrato   tipo_financeiro.flag_obriga_contrato%TYPE;
  v_cod_tipo_finan         tipo_financeiro.codigo%TYPE;
  v_nome_tipo_finan        tipo_financeiro.nome%TYPE;
  v_estrat_job             tipo_job.estrat_job%TYPE;
  v_cronograma_id          cronograma.cronograma_id%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_justif_histor          historico.justificativa%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_data_atual             DATE;
  v_lbl_job                VARCHAR2(100);
  v_lbl_jobs               VARCHAR2(100);
  v_flag_tipo_finan        VARCHAR2(10);
  v_flag_usar_camp         VARCHAR2(10);
  v_flag_obriga_desc_horas VARCHAR2(10);
  v_caminho_externo        VARCHAR2(200);
  v_xml_atual              CLOB;
  --
  -- seleciona valor padrao das naturezas definido para o contrato,
  -- ou para o cliente ou pega o valor padrao do sistema.
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          nvl(nvl(cn.valor_padrao, pn.valor_padrao), na.valor_padrao) valor_padrao
     FROM contrato_nitem_pdr cn,
          pessoa_nitem_pdr   pn,
          natureza_item      na
    WHERE na.empresa_id = p_empresa_id
      AND na.codigo <> 'CUSTO'
      AND na.flag_ativo = 'S'
      AND na.natureza_item_id = cn.natureza_item_id(+)
      AND cn.contrato_id(+) = nvl(p_contrato_id, 0)
      AND na.natureza_item_id = pn.natureza_item_id(+)
      AND pn.pessoa_id(+) = p_cliente_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt                     := 0;
  p_job_id                 := 0;
  v_priv_todos             := 0;
  v_data_atual             := SYSDATE;
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_flag_tipo_finan        := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  v_caminho_externo        := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'CAMINHO_ARQUIVOS_EXTERNOS');
  v_flag_usar_camp         := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_CAMPANHA');
  v_flag_obriga_desc_horas := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_OBRIGA_DESC_APONTAM_HS');
  --
  -- status em que o job eh criado
  v_status_job := 'PREP';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de ' || v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio p/ criar qualquer job
  IF p_flag_commit = 'S'
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_I', NULL, p_tipo_job_id, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT MAX(status_aux_job_id)
    INTO v_status_aux_job_id
    FROM status_aux_job
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = v_status_job
     AND flag_padrao = 'S';
  --
  IF v_status_aux_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão para o status ' || v_status_job || ' não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_numero_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_numero_job := TRIM(upper(p_numero_job));
  --
  IF length(TRIM(p_cod_ext_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job ||
                 ' no outro sistema não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_ext_job) IN ('-', '.', ':', '?', '/', '\', '|', '*', ',', '0')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do ' || v_lbl_job || ' no outro sistema inválido (esse campo é opcional).';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe. ' || p_cliente_id || '|' || p_empresa_id;
   RAISE v_exception;
  END IF;
  --
  SELECT emp_fatur_pdr_id
    INTO v_emp_faturar_por_id
    FROM pessoa
   WHERE pessoa_id = p_cliente_id;
  --
  IF nvl(p_emp_resp_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa responsável não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da complexidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || p_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_cria_crono_auto,
         flag_tem_camp,
         flag_camp_obr,
         estrat_job,
         flag_ender_todos
    INTO v_flag_cria_crono_auto,
         v_flag_tem_camp,
         v_flag_camp_obr,
         v_estrat_job,
         v_flag_ender_todos
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  SELECT MAX(mod_crono_id)
    INTO v_mod_crono_id
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND flag_padrao = 'S';
  --
  IF v_flag_usar_camp = 'S' AND v_flag_tem_camp = 'S' AND v_flag_camp_obr = 'S'
  THEN
   IF nvl(p_campanha_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da campanha é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_campanha_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM campanha
    WHERE campanha_id = p_campanha_id
      AND cliente_id = p_cliente_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa campanha não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_tipo_finan = 'S'
  THEN
   IF nvl(p_tipo_financeiro_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo financeiro é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_flag_usa_budget       := 'S';
  v_flag_usa_receita_prev := 'S';
  v_flag_obriga_contrato  := 'N';
  --
  IF nvl(p_tipo_financeiro_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo financeiro não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_usa_receita_prev,
          flag_usa_budget,
          flag_obriga_contrato,
          codigo,
          nome
     INTO v_flag_usa_receita_prev,
          v_flag_usa_budget,
          v_flag_obriga_contrato,
          v_cod_tipo_finan,
          v_nome_tipo_finan
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  END IF;
  --
  IF v_flag_obriga_contrato = 'S' AND nvl(p_contrato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato
    WHERE contrato_id = p_contrato_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa(' || p_contrato_id || ')';
    RAISE v_exception;
   END IF;
   --
   -- pega dados do contrato
   SELECT flag_pago_cliente,
          perc_bv,
          flag_bv_fornec
     INTO v_flag_pago_cliente,
          v_perc_bv,
          v_flag_bv_fornec
     FROM contrato
    WHERE contrato_id = p_contrato_id;
  ELSE
   -- contrato nao definido. Pega dados do cliente
   SELECT flag_pago_cliente
     INTO v_flag_pago_cliente
     FROM pessoa
    WHERE pessoa_id = p_cliente_id;
   --
   v_perc_bv        := NULL;
   v_flag_bv_fornec := 'S';
  END IF;
  --
  IF length(p_descricao) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_numero_job IS NULL
  THEN
   job_pkg.prox_numero_retornar(p_usuario_sessao_id,
                                p_empresa_id,
                                p_cliente_id,
                                p_tipo_financeiro_id,
                                v_numero_job,
                                v_tipo_num_job,
                                p_erro_cod,
                                p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- foi informado um numero de job antigo (p_numero_job)
   v_tipo_num_job := 'NUM_ANTIGO';
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE numero = v_numero_job
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job ||
                 '). Tente novamente.';
   RAISE v_exception;
  END IF;
  --                  
  SELECT seq_job.nextval
    INTO v_job_id
    FROM dual;
  --
  v_caminho_arq_externo := v_caminho_externo || '\' || to_char(v_data_atual, 'YYYY') || '\' ||
                           to_char(v_numero_job);
  --
  INSERT INTO job
   (job_id,
    empresa_id,
    cliente_id,
    emp_resp_id,
    usuario_solic_id,
    numero,
    tipo_num_job,
    tipo_job_id,
    tipo_financeiro_id,
    contrato_id,
    campanha_id,
    nome,
    descricao,
    data_entrada,
    status,
    data_status,
    perc_bv,
    flag_bv_fornec,
    flag_pago_cliente,
    status_checkin,
    data_status_checkin,
    status_fatur,
    data_status_fatur,
    flag_bloq_negoc,
    caminho_arq_externo,
    tipo_data_prev,
    complex_job,
    estrat_job,
    status_aux_job_id,
    emp_faturar_por_id,
    flag_obriga_desc_horas,
    flag_usa_budget,
    flag_usa_receita_prev,
    flag_obriga_contrato,
    budget,
    receita_prevista,
    cod_ext_job,
    produto_cliente_id,
    data_prev_ini,
    data_prev_fim)
  VALUES
   (v_job_id,
    p_empresa_id,
    p_cliente_id,
    p_emp_resp_id,
    p_usuario_sessao_id,
    v_numero_job,
    v_tipo_num_job,
    p_tipo_job_id,
    zvl(p_tipo_financeiro_id, NULL),
    zvl(p_contrato_id, NULL),
    zvl(p_campanha_id, NULL),
    TRIM(p_nome),
    TRIM(p_descricao),
    v_data_atual,
    v_status_job,
    v_data_atual,
    v_perc_bv,
    v_flag_bv_fornec,
    v_flag_pago_cliente,
    'A',
    v_data_atual,
    'A',
    v_data_atual,
    'N',
    v_caminho_arq_externo,
    'EST',
    p_complex_job,
    v_estrat_job,
    v_status_aux_job_id,
    v_emp_faturar_por_id,
    v_flag_obriga_desc_horas,
    v_flag_usa_budget,
    v_flag_usa_receita_prev,
    v_flag_obriga_contrato,
    NULL,
    decode(v_flag_usa_receita_prev, 'S', 0, 'N', NULL),
    TRIM(p_cod_ext_job),
    p_produto_cliente_id,
    p_data_prev_ini,
    p_data_prev_fim);
  --
  UPDATE pessoa
     SET data_entrada_agencia = v_data_atual
   WHERE pessoa_id = p_cliente_id
     AND data_entrada_agencia IS NULL;
  --
  ------------------------------------------------------------
  -- instancia os valores padrao das naturezas dos itens
  ------------------------------------------------------------
  FOR r_na IN c_na
  LOOP
   INSERT INTO job_nitem_pdr
    (job_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_job_id,
     r_na.natureza_item_id,
     nvl(r_na.valor_padrao, 0));
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento do job
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'INCLUIR',
                   v_identif_objeto,
                   v_job_id,
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
  -- geracao de evento do tipo financeiro
  ------------------------------------------------------------
  IF nvl(p_tipo_financeiro_id, 0) > 0
  THEN
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := 'Tipo Financeiro: ' || v_nome_tipo_finan;
   v_justif_histor  := v_cod_tipo_finan;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'DEFINIR_TFIN',
                    v_identif_objeto,
                    v_job_id,
                    v_compl_histor,
                    v_justif_histor,
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
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  job_pkg.enderecar_automatico(p_usuario_sessao_id, p_empresa_id, v_job_id, p_erro_cod, p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento de todos os usuarios (se for o caso)
  ------------------------------------------------------------
  IF v_flag_ender_todos = 'S'
  THEN
   job_pkg.enderecar_todos_usuarios(p_usuario_sessao_id,
                                    p_empresa_id,
                                    v_job_id,
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
  -- cronograma automatico
  ------------------------------------------------------------
  IF v_flag_cria_crono_auto = 'S' AND nvl(v_mod_crono_id, 0) > 0
  THEN
   cronograma_pkg.adicionar_com_modelo(p_usuario_sessao_id,
                                       p_empresa_id,
                                       'N',
                                       v_job_id,
                                       v_mod_crono_id,
                                       NULL,
                                       v_cronograma_id,
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
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_ADICIONAR', p_empresa_id, v_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_job_id   := v_job_id;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE consistir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/01/2013
  -- DESCRICAO: Consistencia de dados do JOB (usado pelo wizard)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/09/2014  Novo parametro contrato_id.
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            03/03/2016  Complexidade do job.
  -- Silvia            05/04/2016  Consistencia de periodo.
  -- Silvia            11/05/2016  Novo parametro campanha_id.
  -- Silvia            07/02/2017  Novo parametro mod_crono_id, data_crono_base
  -- Silvia            12/06/2018  Novo parametro flag_concorrencia
  -- Silvia            13/09/2018  Novo parametro flag_obriga_desc_horas
  -- Silvia            04/10/2018  Novo parammetro receita_prevista
  -- Silvia            21/01/2019  Alteração na ordem das consistencias; novos parametros 
  --                               numero_job, cod_ext_job.
  -- Silvia            03/01/2020  Novos campos de contexto do cronograma
  -- Silvia            04/06/2020  Alteração na ordem das consistencias
  -- Silvia            14/08/2020  Novo parammetro data_golive
  -- Silvia            12/01/2021  Novo parametro servico
  -- Silvia            11/08/2021  Novo parametro unidade_negocio
  -- Silvia            31/08/2022  Consistencia de periodo job x contrato
  -- Ana Luiza         01/04/2025  Adicionado novo parametro de tipo chamada para controlar 
  --                               transacoes de chamada via jobone_self
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_numero_job               IN VARCHAR2,
  p_cod_ext_job              IN VARCHAR2,
  p_nome                     IN job.nome%TYPE,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_flag_obriga_desc_horas   IN VARCHAR2,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_mod_crono_id             IN mod_crono.mod_crono_id%TYPE,
  p_data_crono_base          IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_flag_concorrencia        IN VARCHAR2,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_tipo_chamada             IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_numero_job              job.numero%TYPE;
  v_tipo_num_job            job.tipo_num_job%TYPE;
  v_budget                  job.budget%TYPE;
  v_receita_prevista        job.receita_prevista%TYPE;
  v_data_prev_ini           job.data_prev_ini%TYPE;
  v_data_prev_fim           job.data_prev_fim%TYPE;
  v_mod_crono_id            mod_crono.mod_crono_id%TYPE;
  v_flag_tem_camp           tipo_job.flag_tem_camp%TYPE;
  v_flag_camp_obr           tipo_job.flag_camp_obr%TYPE;
  v_flag_usa_budget         tipo_financeiro.flag_usa_budget%TYPE;
  v_flag_usa_receita_prev   tipo_financeiro.flag_usa_receita_prev%TYPE;
  v_flag_obriga_contrato    tipo_financeiro.flag_obriga_contrato%TYPE;
  v_flag_periodo_job        tipo_job.flag_usa_per_job%TYPE;
  v_flag_obriga_data_cli    tipo_job.flag_obriga_data_cli%TYPE;
  v_flag_obr_data_golive    tipo_job.flag_obr_data_golive%TYPE;
  v_flag_usa_crono_cria_job tipo_job.flag_usa_crono_cria_job%TYPE;
  v_flag_obr_crono_cria_job tipo_job.flag_obr_crono_cria_job%TYPE;
  v_lbl_job                 VARCHAR2(100);
  v_lbl_un                  VARCHAR2(100);
  v_un_obr                  VARCHAR2(100);
  v_lbl_prodcli             VARCHAR2(100);
  v_flag_tipo_finan         VARCHAR2(10);
  v_flag_budget_obrig       VARCHAR2(10);
  v_flag_usar_camp          VARCHAR2(10);
  v_flag_receita_obrig      VARCHAR2(10);
  v_flag_usar_servico       VARCHAR2(10);
  v_restringe_periodo       VARCHAR2(10);
  v_data_ini_ctr            contrato.data_inicio%TYPE;
  v_data_fim_ctr            contrato.data_termino%TYPE;
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_job            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_lbl_un             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  v_flag_tipo_finan    := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  v_flag_budget_obrig  := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BUDGET_OBRIGATORIO');
  v_flag_usar_camp     := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_CAMPANHA');
  v_flag_receita_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_RECEITA_OBRIGATORIO');
  v_flag_usar_servico  := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_JOB');
  v_un_obr             := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_UNID_NEG_OBRIGATORIO');
  v_restringe_periodo  := empresa_pkg.parametro_retornar(p_empresa_id, 'RESTRINGIR_PERIODO_JOB_CTR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  v_flag_usa_budget       := 'S';
  v_flag_usa_receita_prev := 'S';
  v_flag_obriga_contrato  := 'N';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_contato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contato não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_un_obr = 'S' AND nvl(p_unidade_negocio_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento de ' || v_lbl_un || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_lbl_prodcli || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM produto_cliente
   WHERE produto_cliente_id = p_produto_cliente_id
     AND pessoa_id = p_cliente_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tipo_finan = 'S'
  THEN
   IF nvl(p_tipo_financeiro_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo financeiro é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tipo_financeiro_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo financeiro não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_usa_receita_prev,
          flag_usa_budget,
          flag_obriga_contrato
     INTO v_flag_usa_receita_prev,
          v_flag_usa_budget,
          v_flag_obriga_contrato
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  END IF;
  --
  IF v_flag_obriga_contrato = 'S' AND nvl(p_contrato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato
    WHERE contrato_id = p_contrato_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT data_inicio,
          data_termino
     INTO v_data_ini_ctr,
          v_data_fim_ctr
     FROM contrato
    WHERE contrato_id = p_contrato_id;
  END IF;
  --
  IF nvl(p_tipo_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de ' || v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usar_servico = 'S' AND nvl(p_servico_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_servico_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM servico
    WHERE servico_id = p_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT flag_tem_camp,
         flag_camp_obr,
         flag_usa_per_job,
         flag_obriga_data_cli,
         flag_obr_data_golive,
         flag_usa_crono_cria_job,
         flag_obr_crono_cria_job
    INTO v_flag_tem_camp,
         v_flag_camp_obr,
         v_flag_periodo_job,
         v_flag_obriga_data_cli,
         v_flag_obr_data_golive,
         v_flag_usa_crono_cria_job,
         v_flag_obr_crono_cria_job
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  SELECT MAX(mod_crono_id)
    INTO v_mod_crono_id
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND flag_padrao = 'S';
  --
  -- verifica se o usuario tem privilegio p/ criar job
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_I', NULL, p_tipo_job_id, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usar_camp = 'S' AND v_flag_tem_camp = 'S' AND v_flag_camp_obr = 'S'
  THEN
   IF nvl(p_campanha_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da campanha é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_campanha_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM campanha
    WHERE campanha_id = p_campanha_id
      AND cliente_id = p_cliente_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa campanha não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_resp_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa responsável não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da complexidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || p_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_numero_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job ||
                 ' no outro sistema não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_ext_job) IN ('-', '.', ':', '?', '/', '\', '|', '*', ',', '0')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do ' || v_lbl_job || ' no outro sistema inválido (esse campo é opcional).';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_periodo_job = 'S'
  THEN
   IF TRIM(p_data_prev_ini) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data de início é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_data_prev_fim) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da data de término é obrigatório.';
    RAISE v_exception;
   END IF;
  ELSE
   IF v_mod_crono_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não é possível criar o ' || v_lbl_job || ' sem a definição do Período do ' ||
                  v_lbl_job || ' ou um Modelo de Cronograma definido para esse Tipo de ' ||
                  v_lbl_job || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF data_validar(p_data_prev_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_prev_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prev_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_prev_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prev_ini := data_converter(p_data_prev_ini);
  v_data_prev_fim := data_converter(p_data_prev_fim);
  --
  IF v_data_prev_ini > v_data_prev_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início não pode ser maior que a data de término.';
   RAISE v_exception;
  END IF;
  --
  IF v_restringe_periodo = 'S' AND v_data_prev_ini IS NOT NULL AND v_data_prev_fim IS NOT NULL AND
     v_data_ini_ctr IS NOT NULL AND v_data_fim_ctr IS NOT NULL AND
     (v_data_prev_ini NOT BETWEEN v_data_ini_ctr AND v_data_fim_ctr OR
     v_data_prev_fim NOT BETWEEN v_data_ini_ctr AND v_data_fim_ctr)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O período de duração do ' || v_lbl_job || ' deve estar contido ' ||
                 'no período de vigência do Contrato indicado.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_data_job', p_tipo_data_prev) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de data inválido (' || p_tipo_data_prev || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_obriga_data_cli = 'S' AND TRIM(p_data_pri_aprov) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data da apresentação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_pri_aprov) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da apresentação inválida (' || p_data_pri_aprov || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_obr_data_golive = 'S' AND TRIM(p_data_golive) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de Go Live é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_golive) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de Go Live inválida (' || p_data_golive || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_desc_horas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga descrição de horas inválido (' || p_flag_obriga_desc_horas || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_obr_crono_cria_job = 'S' AND nvl(p_mod_crono_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do modelo de Cronograma é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_mod_crono_id, 0) > 0 AND TRIM(p_data_crono_base) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data do Cronograma é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_crono_base) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do Cronograma inválida (' || p_data_crono_base || ')';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_budget_nd) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag budget não definido inválido (' || p_flag_budget_nd || ').';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_budget) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --
  v_budget := moeda_converter(p_budget);
  --
  IF v_budget < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usa_budget = 'S' AND nvl(v_budget, 0) = 0 AND
     (v_flag_budget_obrig = 'S' AND p_flag_budget_nd <> 'S')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do budget é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_receita_prevista) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Receita prevista inválida.';
   RAISE v_exception;
  END IF;
  --
  v_receita_prevista := moeda_converter(p_receita_prevista);
  --
  IF v_receita_prevista < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Receita prevista inválida.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usa_receita_prev = 'S' AND nvl(v_receita_prevista, 0) = 0 AND
     v_flag_receita_obrig = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da receita prevista é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_concorrencia) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da concorrência é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_concorrencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag concorrência inválido (' || p_flag_concorrencia || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_restringe_alt_crono) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag restringe alteração de cronograma inválido (' || p_flag_restringe_alt_crono || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome_contexto) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O contexto não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nome_contexto) IS NOT NULL AND p_flag_restringe_alt_crono = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quando o contexto é especificado, as atividades não podem ser alteradas no cronograma.';
   RAISE v_exception;
  END IF;
  --
  -- simula a geracao do numero do job para verificar erros de configuracao
  job_pkg.prox_numero_retornar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_cliente_id,
                               p_tipo_financeiro_id,
                               v_numero_job,
                               v_tipo_num_job,
                               p_erro_cod,
                               p_erro_msg);
  --
  -- desfaz eventuais alteracoes da subrotina prox_numero_retornar
  --ALCBO_010425 - Adicionado condicao para nao afetar transicoes na chamado do jobone_self
  IF p_tipo_chamada = 'WEB'
  THEN
   ROLLBACK;
  END IF;
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
   ROLLBACK;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END consistir;
 --
 --
 PROCEDURE adicionar_wizard
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/01/2013
  -- DESCRICAO: Inclusão de JOB via wizard.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/06/2013  Novo parametro emp_resp_id.
  -- Silvia            24/02/2014  Novo parametro vetor_area_id.
  -- Silvia            11/09/2014  Novo parametro contrato_id.
  -- Silvia            03/12/2014  Grava data de entrada na agencia no cliente.
  -- Silvia            03/06/2015  Metadados de briefing
  -- Silvia            04/01/2016  Alteracoes em briefing (status)
  -- Silvia            12/01/2016  Criacao autom. cronograma.
  -- Silvia            03/03/2016  Complexidade do job.
  -- Silvia            09/03/2016  Enderecamento do usuario do contato
  -- Silvia            23/03/2016  Tratamento do status auxiliar/estendido.
  -- Silvia            11/05/2016  Novo parametro campanha_id.
  -- Silvia            31/05/2016  Enderecamento do responsavel interno pelo privilegio.
  -- Silvia            31/05/2016  Enderecamento de responsavel interno.
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            14/10/2016  Novos vetores para matriz classificacao (dicionario)
  -- Silvia            07/02/2017  Novos parametros data_crono_base, mod_crono_id
  -- Silvia            23/03/2017  Grava data limite p/ distribuicao de job novo.
  -- Silvia            10/05/2017  Grava data limite p/ aprovacao de briefing.
  -- Silvia            16/08/2017  Validacao de metadado.
  -- Silvia            12/06/2018  Novo parametro flag_concorrencia.
  -- Silvia            04/09/2018  Novo parametro flag_obriga_desc_horas.
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev e 
  --                                      receita_prevista
  -- Silvia            16/01/2019  Novo paramento numero_job (nro antigo do job)
  -- Silvia            21/01/2019  Novo parametro cod_ext_job
  -- Silvia            06/09/2019  Novo parametro unidade_negocio
  -- Silvia            03/01/2020  Novos campos de contexto do cronograma
  -- Silvia            13/04/2020  Registro do evento de tipo financeiro
  -- Silvia            14/08/2020  Novo parametro data_golive
  -- Silvia            12/01/2021  Novo parametro servico
  -- Silvia            29/03/2021  Chamada de subrotina para enderecar todos usuarios
  -- Silvia            30/06/2021  Mudanca na definicao de data_apont_fim
  -- Ana Luiza         27/02/2025  Adicao de novo parametro p_flag_commit para controlar chamada       
  --                               dentro do pacote JOBONE_SELF
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_numero_job               IN VARCHAR2,
  p_cod_ext_job              IN VARCHAR2,
  p_nome                     IN job.nome%TYPE,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_flag_obriga_desc_horas   IN VARCHAR2,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_mod_crono_id             IN mod_crono.mod_crono_id%TYPE,
  p_data_crono_base          IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_flag_concorrencia        IN VARCHAR2,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_requisicao_cliente       IN briefing.requisicao_cliente%TYPE,
  p_vetor_area_id            IN VARCHAR2,
  p_vetor_atributo_id        IN VARCHAR2,
  p_vetor_atributo_valor     IN CLOB,
  p_vetor_dicion_emp_id      IN VARCHAR2,
  p_vetor_dicion_emp_val_id  IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_flag_commit              IN VARCHAR2,
  p_tipo_chamada             IN VARCHAR2,
  p_job_id                   OUT job.job_id%TYPE,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_exception               EXCEPTION;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_justif_histor           historico.justificativa%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_job_id                  job.job_id%TYPE;
  v_numero_job              job.numero%TYPE;
  v_tipo_num_job            job.tipo_num_job%TYPE;
  v_budget                  job.budget%TYPE;
  v_receita_prevista        job.receita_prevista%TYPE;
  v_data_dist_limite        job.data_dist_limite%TYPE;
  v_flag_budget_nd          job.flag_budget_nd%TYPE;
  v_data_prev_ini           job.data_prev_ini%TYPE;
  v_data_prev_fim           job.data_prev_fim%TYPE;
  v_data_apont_ini          job.data_apont_ini%TYPE;
  v_data_apont_fim          job.data_apont_fim%TYPE;
  v_data_pri_aprov          job.data_pri_aprov%TYPE;
  v_data_golive             job.data_golive%TYPE;
  v_flag_pago_cliente       job.flag_pago_cliente%TYPE;
  v_perc_bv                 job.perc_bv%TYPE;
  v_flag_bv_fornec          job.flag_bv_fornec%TYPE;
  v_caminho_arq_externo     job.caminho_arq_externo%TYPE;
  v_status_aux_job_id       job.status_aux_job_id%TYPE;
  v_status_job              job.status%TYPE;
  v_emp_faturar_por_id      job.emp_faturar_por_id%TYPE;
  v_briefing_id             briefing.briefing_id%TYPE;
  v_data_aprov_limite       briefing.data_aprov_limite%TYPE;
  v_mod_crono_id            mod_crono.mod_crono_id%TYPE;
  v_data_crono_base         DATE;
  v_flag_apr_brief_auto     tipo_job.flag_apr_brief_auto%TYPE;
  v_flag_cria_crono_auto    tipo_job.flag_cria_crono_auto%TYPE;
  v_flag_usa_crono_cria_job tipo_job.flag_usa_crono_cria_job%TYPE;
  v_flag_obr_crono_cria_job tipo_job.flag_obr_crono_cria_job%TYPE;
  v_estrat_job              tipo_job.estrat_job%TYPE;
  v_flag_ender_todos        tipo_job.flag_ender_todos%TYPE;
  v_flag_usa_budget         tipo_financeiro.flag_usa_budget%TYPE;
  v_flag_usa_receita_prev   tipo_financeiro.flag_usa_receita_prev%TYPE;
  v_flag_obriga_contrato    tipo_financeiro.flag_obriga_contrato%TYPE;
  v_cod_tipo_finan          tipo_financeiro.codigo%TYPE;
  v_nome_tipo_finan         tipo_financeiro.nome%TYPE;
  v_cronograma_id           cronograma.cronograma_id%TYPE;
  v_item_crono_id           item_crono.item_crono_id%TYPE;
  v_delimitador             CHAR(1);
  v_vetor_area_id           VARCHAR2(1000);
  v_area_id                 area.area_id%TYPE;
  v_data_atual              DATE;
  v_lbl_job                 VARCHAR2(100);
  v_lbl_jobs                VARCHAR2(100);
  v_lbl_brief               VARCHAR2(100);
  v_vetor_atributo_id       LONG;
  v_vetor_atributo_valor    LONG;
  v_metadado_id             metadado.metadado_id%TYPE;
  v_nome_atributo           metadado.nome%TYPE;
  v_tamanho                 metadado.tamanho%TYPE;
  v_flag_obrigatorio        metadado.flag_obrigatorio%TYPE;
  v_tipo_dado               tipo_dado.codigo%TYPE;
  v_valor_atributo          LONG;
  v_valor_atributo_sai      LONG;
  v_usuario_contato_id      usuario.usuario_id%TYPE;
  v_vetor_dicion_emp_id     LONG;
  v_vetor_dicion_emp_val_id LONG;
  v_dicion_emp_id           dicion_emp.dicion_emp_id%TYPE;
  v_dicion_desc             dicion_emp.descricao%TYPE;
  v_dicion_emp_val_id       dicion_emp_val.dicion_emp_val_id%TYPE;
  v_nome_contato            pessoa.apelido%TYPE;
  v_xml_atual               CLOB;
  v_contexto_crono_id       contexto_crono.contexto_crono_id%TYPE;
  v_num_dias_apont          NUMBER(5);
  --
  -- seleciona valor padrao das naturezas definido para o contrato,
  -- ou para o cliente ou pega o valor padrao do sistema.
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          nvl(nvl(cn.valor_padrao, pn.valor_padrao), na.valor_padrao) valor_padrao
     FROM contrato_nitem_pdr cn,
          pessoa_nitem_pdr   pn,
          natureza_item      na
    WHERE na.empresa_id = p_empresa_id
      AND na.codigo <> 'CUSTO'
      AND na.flag_ativo = 'S'
      AND na.natureza_item_id = cn.natureza_item_id(+)
      AND cn.contrato_id(+) = nvl(p_contrato_id, 0)
      AND na.natureza_item_id = pn.natureza_item_id(+)
      AND pn.pessoa_id(+) = p_cliente_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt             := 0;
  p_job_id         := 0;
  v_data_atual     := SYSDATE;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_brief      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_SINGULAR');
  v_num_dias_apont := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                   'NUM_DIAS_DATA_FIM_APONT')),
                          0);
  --
  --ALCBO_270225
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  -- status em que o job eh criado
  v_status_job := 'ANDA';
  --
  SELECT MAX(status_aux_job_id)
    INTO v_status_aux_job_id
    FROM status_aux_job
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = v_status_job
     AND flag_padrao = 'S';
  --
  IF v_status_aux_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão para o status ' || v_status_job || ' não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  job_pkg.consistir(p_usuario_sessao_id,
                    p_empresa_id,
                    p_numero_job,
                    p_cod_ext_job,
                    p_nome,
                    p_cliente_id,
                    p_emp_resp_id,
                    p_contato_id,
                    p_unidade_negocio_id,
                    p_produto_cliente_id,
                    p_tipo_job_id,
                    p_servico_id,
                    p_tipo_financeiro_id,
                    p_contrato_id,
                    p_campanha_id,
                    p_data_prev_ini,
                    p_data_prev_fim,
                    p_tipo_data_prev,
                    p_flag_obriga_desc_horas,
                    p_data_pri_aprov,
                    p_data_golive,
                    p_mod_crono_id,
                    p_data_crono_base,
                    p_budget,
                    p_flag_budget_nd,
                    p_receita_prevista,
                    p_flag_concorrencia,
                    p_descricao,
                    p_complex_job,
                    p_nome_contexto,
                    p_flag_restringe_alt_crono,
                    p_tipo_chamada,
                    p_erro_cod,
                    p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_requisicao_cliente IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_lbl_brief || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_vetor_atributo_valor) > 32767
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A quantidade de caracteres dos metadados ultrapassou o limite de 32767.';
   RAISE v_exception;
  END IF;
  --
  SELECT emp_fatur_pdr_id
    INTO v_emp_faturar_por_id
    FROM pessoa
   WHERE pessoa_id = p_cliente_id;
  --
  SELECT flag_cria_crono_auto,
         flag_usa_crono_cria_job,
         flag_obr_crono_cria_job,
         estrat_job,
         flag_ender_todos
    INTO v_flag_cria_crono_auto,
         v_flag_usa_crono_cria_job,
         v_flag_obr_crono_cria_job,
         v_estrat_job,
         v_flag_ender_todos
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  v_flag_usa_budget       := 'S';
  v_flag_usa_receita_prev := 'S';
  v_flag_obriga_contrato  := 'N';
  --
  IF nvl(p_tipo_financeiro_id, 0) > 0
  THEN
   SELECT flag_usa_receita_prev,
          flag_usa_budget,
          flag_obriga_contrato,
          codigo,
          nome
     INTO v_flag_usa_receita_prev,
          v_flag_usa_budget,
          v_flag_obriga_contrato,
          v_cod_tipo_finan,
          v_nome_tipo_finan
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id;
  END IF;
  --
  IF nvl(p_mod_crono_id, 0) > 0
  THEN
   -- modelo informado pelo usuario
   v_mod_crono_id := p_mod_crono_id;
  ELSE
   IF v_flag_cria_crono_auto = 'S' AND v_flag_usa_crono_cria_job = 'N'
   THEN
    -- usa o modelo padrao para esse tipo de job (usuario nao escolhe 
    -- o modelo pela interface)
    SELECT MAX(mod_crono_id)
      INTO v_mod_crono_id
      FROM tipo_job_mod_crono
     WHERE tipo_job_id = p_tipo_job_id
       AND flag_padrao = 'S';
   END IF;
  END IF;
  --
  v_data_prev_ini    := data_converter(p_data_prev_ini);
  v_data_prev_fim    := data_converter(p_data_prev_fim);
  v_data_pri_aprov   := data_converter(p_data_pri_aprov);
  v_data_golive      := data_converter(p_data_golive);
  v_data_crono_base  := data_converter(p_data_crono_base);
  v_budget           := moeda_converter(p_budget);
  v_receita_prevista := moeda_converter(p_receita_prevista);
  --
  v_data_apont_ini := v_data_prev_ini;
  v_data_apont_fim := v_data_prev_fim;
  --
  IF v_num_dias_apont > 0
  THEN
   v_data_apont_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                          v_data_prev_fim,
                                                          v_num_dias_apont,
                                                          'S');
  END IF;
  --
  IF nvl(v_budget, 0) > 0
  THEN
   -- forca budget como Definido
   v_flag_budget_nd := 'N';
  ELSE
   v_flag_budget_nd := p_flag_budget_nd;
  END IF;
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   -- pega dados do contrato
   SELECT flag_pago_cliente,
          perc_bv,
          flag_bv_fornec
     INTO v_flag_pago_cliente,
          v_perc_bv,
          v_flag_bv_fornec
     FROM contrato
    WHERE contrato_id = p_contrato_id;
  ELSE
   -- contrato nao definido. Pega dados do cliente
   SELECT flag_pago_cliente
     INTO v_flag_pago_cliente
     FROM pessoa
    WHERE pessoa_id = p_cliente_id;
   --
   v_perc_bv        := NULL;
   v_flag_bv_fornec := 'S';
  END IF;
  --
  IF length(TRIM(p_numero_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_numero_job := TRIM(upper(p_numero_job));
  --
  IF v_numero_job IS NULL
  THEN
   job_pkg.prox_numero_retornar(p_usuario_sessao_id,
                                p_empresa_id,
                                p_cliente_id,
                                p_tipo_financeiro_id,
                                v_numero_job,
                                v_tipo_num_job,
                                p_erro_cod,
                                p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- foi informado um numero de job antigo (p_numero_job)
   v_tipo_num_job := 'NUM_ANTIGO';
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE numero = v_numero_job
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job || ').';
   RAISE v_exception;
  END IF;
  --
  v_caminho_arq_externo := empresa_pkg.parametro_retornar(p_empresa_id, 'CAMINHO_ARQUIVOS_EXTERNOS') || '\' ||
                           to_char(v_data_atual, 'YYYY') || '\' || to_char(v_numero_job);
  --                     
  SELECT seq_job.nextval
    INTO v_job_id
    FROM dual;
  --
  INSERT INTO job
   (job_id,
    empresa_id,
    cliente_id,
    unidade_negocio_id,
    emp_resp_id,
    usuario_solic_id,
    contato_id,
    produto_cliente_id,
    numero,
    tipo_num_job,
    tipo_job_id,
    servico_id,
    tipo_financeiro_id,
    contrato_id,
    campanha_id,
    nome,
    descricao,
    data_entrada,
    status,
    data_status,
    data_prev_ini,
    data_prev_fim,
    tipo_data_prev,
    data_pri_aprov,
    data_golive,
    budget,
    flag_budget_nd,
    perc_bv,
    flag_bv_fornec,
    flag_pago_cliente,
    status_checkin,
    data_status_checkin,
    status_fatur,
    data_status_fatur,
    flag_bloq_negoc,
    caminho_arq_externo,
    data_apont_ini,
    data_apont_fim,
    complex_job,
    estrat_job,
    status_aux_job_id,
    emp_faturar_por_id,
    flag_concorrencia,
    flag_obriga_desc_horas,
    flag_usa_budget,
    flag_usa_receita_prev,
    flag_obriga_contrato,
    receita_prevista,
    cod_ext_job,
    flag_restringe_alt_crono)
  VALUES
   (v_job_id,
    p_empresa_id,
    p_cliente_id,
    zvl(p_unidade_negocio_id, NULL),
    p_emp_resp_id,
    p_usuario_sessao_id,
    p_contato_id,
    p_produto_cliente_id,
    v_numero_job,
    v_tipo_num_job,
    p_tipo_job_id,
    zvl(p_servico_id, NULL),
    zvl(p_tipo_financeiro_id, NULL),
    zvl(p_contrato_id, NULL),
    zvl(p_campanha_id, NULL),
    TRIM(p_nome),
    TRIM(p_descricao),
    v_data_atual,
    v_status_job,
    v_data_atual,
    v_data_prev_ini,
    v_data_prev_fim,
    p_tipo_data_prev,
    v_data_pri_aprov,
    v_data_golive,
    v_budget,
    v_flag_budget_nd,
    v_perc_bv,
    v_flag_bv_fornec,
    v_flag_pago_cliente,
    'A',
    v_data_atual,
    'A',
    v_data_atual,
    'N',
    v_caminho_arq_externo,
    v_data_apont_ini,
    v_data_apont_fim,
    p_complex_job,
    v_estrat_job,
    v_status_aux_job_id,
    v_emp_faturar_por_id,
    p_flag_concorrencia,
    p_flag_obriga_desc_horas,
    v_flag_usa_budget,
    v_flag_usa_receita_prev,
    v_flag_obriga_contrato,
    v_receita_prevista,
    TRIM(p_cod_ext_job),
    p_flag_restringe_alt_crono);
  --
  ------------------------------------------------------------
  -- instancia os valores padrao das naturezas dos itens
  ------------------------------------------------------------
  FOR r_na IN c_na
  LOOP
   INSERT INTO job_nitem_pdr
    (job_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_job_id,
     r_na.natureza_item_id,
     nvl(r_na.valor_padrao, 0));
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento do job
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'INCLUIR',
                   v_identif_objeto,
                   v_job_id,
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
  -- geracao de evento do tipo financeiro
  ------------------------------------------------------------
  IF nvl(p_tipo_financeiro_id, 0) > 0
  THEN
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := 'Tipo Financeiro: ' || v_nome_tipo_finan;
   v_justif_histor  := v_cod_tipo_finan;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'DEFINIR_TFIN',
                    v_identif_objeto,
                    v_job_id,
                    v_compl_histor,
                    v_justif_histor,
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
  END IF;
  --
  ------------------------------------------------------------
  -- demais atualizacoes
  ------------------------------------------------------------
  UPDATE pessoa
     SET data_entrada_agencia = v_data_atual
   WHERE pessoa_id = p_cliente_id
     AND data_entrada_agencia IS NULL;
  --
  SELECT flag_apr_brief_auto
    INTO v_flag_apr_brief_auto
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  SELECT seq_briefing.nextval
    INTO v_briefing_id
    FROM dual;
  --
  INSERT INTO briefing
   (briefing_id,
    job_id,
    usuario_id,
    numero,
    data_requisicao,
    requisicao_cliente,
    status,
    data_status)
  VALUES
   (v_briefing_id,
    v_job_id,
    p_usuario_sessao_id,
    1,
    trunc(SYSDATE),
    p_requisicao_cliente,
    decode(v_flag_apr_brief_auto, 'S', 'APROV', 'EMAPRO'),
    SYSDATE);
  --
  IF v_flag_apr_brief_auto = 'N'
  THEN
   -- briefing foi criado no status em aprovação (EMAPRO)
   v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                              p_empresa_id,
                                                              SYSDATE,
                                                              'NUM_HORAS_APROV_BRIEF',
                                                              0);
   UPDATE briefing
      SET data_aprov_limite = v_data_aprov_limite,
          flag_com_aprov    = 'S'
    WHERE briefing_id = v_briefing_id;
  END IF;
  --
  -- grava historico do novo briefing
  INSERT INTO brief_hist
   (brief_hist_id,
    briefing_id,
    usuario_id,
    data,
    motivo)
  VALUES
   (seq_brief_hist.nextval,
    v_briefing_id,
    p_usuario_sessao_id,
    SYSDATE,
    'Versão inicial');
  --
  IF TRIM(p_nome_contexto) IS NOT NULL
  THEN
   SELECT MAX(contexto_crono_id)
     INTO v_contexto_crono_id
     FROM contexto_crono
    WHERE upper(nome) = TRIM(upper(p_nome_contexto))
      AND empresa_id = p_empresa_id;
   --
   IF v_contexto_crono_id IS NULL
   THEN
    SELECT seq_contexto_crono.nextval
      INTO v_contexto_crono_id
      FROM dual;
    --
    INSERT INTO contexto_crono
     (contexto_crono_id,
      empresa_id,
      nome)
    VALUES
     (v_contexto_crono_id,
      p_empresa_id,
      TRIM(p_nome_contexto));
   END IF;
   --
   UPDATE job
      SET contexto_crono_id = v_contexto_crono_id
    WHERE job_id = v_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de areas
  ------------------------------------------------------------
  v_delimitador   := '|';
  v_vetor_area_id := p_vetor_area_id;
  --
  WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0
  LOOP
   v_area_id := to_number(prox_valor_retornar(v_vetor_area_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = v_area_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa área não existe ou não pertence a essa empresa (' || to_char(v_area_id) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO brief_area
    (briefing_id,
     area_id)
   VALUES
    (v_briefing_id,
     v_area_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de metadados
  ------------------------------------------------------------
  v_delimitador          := '|';
  v_vetor_atributo_id    := p_vetor_atributo_id;
  v_vetor_atributo_valor := p_vetor_atributo_valor;
  --
  WHILE nvl(length(rtrim(v_vetor_atributo_id)), 0) > 0
  LOOP
   v_metadado_id    := to_number(prox_valor_retornar(v_vetor_atributo_id, v_delimitador));
   v_valor_atributo := prox_valor_retornar(v_vetor_atributo_valor, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE metadado_id = v_metadado_id
      AND grupo = 'BRIEFING';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado inválido (' || to_char(v_metadado_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT ab.nome,
          ab.tamanho,
          ab.flag_obrigatorio,
          td.codigo
     INTO v_nome_atributo,
          v_tamanho,
          v_flag_obrigatorio,
          v_tipo_dado
     FROM metadado  ab,
          tipo_dado td
    WHERE ab.metadado_id = v_metadado_id
      AND ab.tipo_dado_id = td.tipo_dado_id;
   --
   tipo_dado_pkg.validar(p_usuario_sessao_id,
                         p_empresa_id,
                         v_tipo_dado,
                         v_flag_obrigatorio,
                         'N',
                         v_tamanho,
                         v_valor_atributo,
                         v_valor_atributo_sai,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    p_erro_msg := v_nome_atributo || ': ' || p_erro_msg;
    RAISE v_exception;
   END IF;
   --
   INSERT INTO brief_atributo_valor
    (briefing_id,
     metadado_id,
     valor_atributo)
   VALUES
    (v_briefing_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores da matriz de classif (dicionario)
  ------------------------------------------------------------
  v_delimitador             := '|';
  v_vetor_dicion_emp_id     := p_vetor_dicion_emp_id;
  v_vetor_dicion_emp_val_id := p_vetor_dicion_emp_val_id;
  --
  WHILE nvl(length(rtrim(v_vetor_dicion_emp_id)), 0) > 0
  LOOP
   v_dicion_emp_id     := to_number(prox_valor_retornar(v_vetor_dicion_emp_id, v_delimitador));
   v_dicion_emp_val_id := nvl(to_number(prox_valor_retornar(v_vetor_dicion_emp_val_id,
                                                            v_delimitador)),
                              0);
   --
   SELECT MAX(descricao)
     INTO v_dicion_desc
     FROM dicion_emp
    WHERE dicion_emp_id = v_dicion_emp_id;
   --
   IF v_dicion_desc IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Atributo do dicionário inválido (' || to_char(v_dicion_emp_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_dicion_emp_val_id = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento de ' || v_dicion_desc || ' é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM dicion_emp_val
    WHERE dicion_emp_val_id = v_dicion_emp_val_id
      AND dicion_emp_id = v_dicion_emp_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Valor de atributo não encontrado (' || to_char(v_dicion_emp_val_id) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO brief_dicion_valor
    (briefing_id,
     dicion_emp_val_id)
   VALUES
    (v_briefing_id,
     v_dicion_emp_val_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  job_pkg.enderecar_automatico(p_usuario_sessao_id, p_empresa_id, v_job_id, p_erro_cod, p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario do contato, com co-enderecamento
  ------------------------------------------------------------
  IF nvl(p_contato_id, 0) > 0
  THEN
   SELECT usuario_id,
          apelido
     INTO v_usuario_contato_id,
          v_nome_contato
     FROM pessoa
    WHERE pessoa_id = p_contato_id;
   --
   IF v_usuario_contato_id IS NOT NULL
   THEN
    -- com co-ender, sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'S',
                              'N',
                              p_empresa_id,
                              v_job_id,
                              v_usuario_contato_id,
                              v_nome_contato || ' indicado como Contato do Cliente',
                              'Criação do ' || v_lbl_job,
                              p_erro_cod,
                              p_erro_msg);
    -- 
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento de todos os usuarios (se for o caso)
  ------------------------------------------------------------
  IF v_flag_ender_todos = 'S'
  THEN
   job_pkg.enderecar_todos_usuarios(p_usuario_sessao_id,
                                    p_empresa_id,
                                    v_job_id,
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
  -- calculo da data limite p/ distribuicao
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE job_id = v_job_id
     AND flag_responsavel = 'S';
  --
  IF v_qt = 0
  THEN
   v_data_dist_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_DIST_JOB',
                                                             0);
   UPDATE job
      SET data_dist_limite = v_data_dist_limite
    WHERE job_id = v_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- cronograma automatico
  ------------------------------------------------------------
  IF nvl(v_mod_crono_id, 0) > 0
  THEN
   cronograma_pkg.adicionar_com_modelo(p_usuario_sessao_id,
                                       p_empresa_id,
                                       'N',
                                       v_job_id,
                                       v_mod_crono_id,
                                       data_mostrar(v_data_crono_base),
                                       v_cronograma_id,
                                       p_erro_cod,
                                       p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_cronograma_id, 0) > 0
   THEN
    -- verifica se precisa instanciar a atividade de briefing
    cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_cronograma_id,
                                         'BRIEFING',
                                         'IME',
                                         v_item_crono_id,
                                         p_erro_cod,
                                         p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- vincula a atividade de briefing ao novo briefing criado
    UPDATE item_crono
       SET objeto_id = v_briefing_id
     WHERE item_crono_id = v_item_crono_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_ADICIONAR', p_empresa_id, v_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  -- registra evento de job em andamento
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'APROVAR',
                   v_identif_objeto,
                   v_job_id,
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
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_job_id   := v_job_id;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar_wizard;
 --
 --
 PROCEDURE adicionar_do_cliente
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 02/01/2017
  -- DESCRICAO: Inclusão de JOB pela inteface de cliente.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2018  Novo atributo flag_obriga_desc_horas.
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev e 
  --                                      receita_prevista
  -- Silvia            13/04/2020  Registro do evento de tipo financeiro
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN job.empresa_id%TYPE,
  p_cliente_id           IN job.cliente_id%TYPE,
  p_nome                 IN job.nome%TYPE,
  p_produto_cliente_id   IN job.produto_cliente_id%TYPE,
  p_nome_produto_cliente IN VARCHAR2,
  p_descricao_cliente    IN CLOB,
  p_contrato_id          IN job.contrato_id%TYPE,
  p_budget               IN VARCHAR2,
  p_flag_budget_nd       IN VARCHAR2,
  p_job_id               OUT job.job_id%TYPE,
  p_briefing_id          OUT briefing.briefing_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_priv_todos             INTEGER;
  v_exception              EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_tipo_job_id            job.tipo_job_id%TYPE;
  v_tipo_financeiro_id     job.tipo_financeiro_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_tipo_num_job           job.tipo_num_job%TYPE;
  v_flag_pago_cliente      job.flag_pago_cliente%TYPE;
  v_budget                 job.budget%TYPE;
  v_flag_budget_nd         job.flag_budget_nd%TYPE;
  v_perc_bv                job.perc_bv%TYPE;
  v_flag_bv_fornec         job.flag_bv_fornec%TYPE;
  v_caminho_arq_externo    job.caminho_arq_externo%TYPE;
  v_status_aux_job_id      job.status_aux_job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_complex_job            job.complex_job%TYPE;
  v_emp_faturar_por_id     job.emp_faturar_por_id%TYPE;
  v_emp_resp_id            job.emp_resp_id%TYPE;
  v_produto_cliente_id     job.produto_cliente_id%TYPE;
  v_data_pri_aprov         job.data_pri_aprov%TYPE;
  v_contato_id             job.contato_id%TYPE;
  v_briefing_id            briefing.briefing_id%TYPE;
  v_mod_crono_id           mod_crono.mod_crono_id%TYPE;
  v_flag_cria_crono_auto   tipo_job.flag_cria_crono_auto%TYPE;
  v_estrat_job             tipo_job.estrat_job%TYPE;
  v_flag_usa_budget        tipo_financeiro.flag_usa_budget%TYPE;
  v_flag_usa_receita_prev  tipo_financeiro.flag_usa_receita_prev%TYPE;
  v_flag_obriga_contrato   tipo_financeiro.flag_obriga_contrato%TYPE;
  v_cod_tipo_finan         tipo_financeiro.codigo%TYPE;
  v_nome_tipo_finan        tipo_financeiro.nome%TYPE;
  v_cronograma_id          cronograma.cronograma_id%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_justif_histor          historico.justificativa%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_data_atual             DATE;
  v_lbl_job                VARCHAR2(100);
  v_lbl_jobs               VARCHAR2(100);
  v_lbl_prodcli            VARCHAR2(100);
  v_flag_tipo_finan        VARCHAR2(10);
  v_flag_budget_obrig      VARCHAR2(10);
  v_flag_obriga_desc_horas VARCHAR2(10);
  v_caminho_externo        VARCHAR2(200);
  v_xml_atual              CLOB;
  --
  -- seleciona valor padrao das naturezas definido para o contrato,
  -- ou para o cliente ou pega o valor padrao do sistema.
  CURSOR c_na IS
   SELECT na.natureza_item_id,
          na.codigo,
          nvl(nvl(cn.valor_padrao, pn.valor_padrao), na.valor_padrao) valor_padrao
     FROM contrato_nitem_pdr cn,
          pessoa_nitem_pdr   pn,
          natureza_item      na
    WHERE na.empresa_id = p_empresa_id
      AND na.codigo <> 'CUSTO'
      AND na.flag_ativo = 'S'
      AND na.natureza_item_id = cn.natureza_item_id(+)
      AND cn.contrato_id(+) = nvl(p_contrato_id, 0)
      AND na.natureza_item_id = pn.natureza_item_id(+)
      AND pn.pessoa_id(+) = p_cliente_id
    ORDER BY na.ordem;
  --
 BEGIN
  v_qt          := 0;
  p_job_id      := 0;
  p_briefing_id := 0;
  v_priv_todos  := 0;
  v_data_atual  := SYSDATE;
  v_complex_job := 'M';
  --
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs               := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_prodcli            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_tipo_finan        := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  v_caminho_externo        := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'CAMINHO_ARQUIVOS_EXTERNOS');
  v_flag_budget_obrig      := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_BUDGET_OBRIGATORIO');
  v_flag_obriga_desc_horas := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_OBRIGA_DESC_APONTAM_HS');
  --
  -- status em que o job eh criado
  v_status_job := 'PREP';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação da empresa é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_job_id)
    INTO v_tipo_job_id
    FROM tipo_job
   WHERE empresa_id = p_empresa_id
     AND flag_padrao = 'S';
  --
  IF v_tipo_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de ' || v_lbl_job || ' padrão não encontrado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio p/ criar qualquer job
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_I', NULL, v_tipo_job_id, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(status_aux_job_id)
    INTO v_status_aux_job_id
    FROM status_aux_job
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = v_status_job
     AND flag_padrao = 'S';
  --
  IF v_status_aux_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão para o status ' || v_status_job || ' não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(pessoa_id)
    INTO v_contato_id
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_contato_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na recuperação da pessoa (contato).';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome_produto_cliente) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ' || v_lbl_prodcli || ' não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) = 0 AND TRIM(p_nome_produto_cliente) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_lbl_prodcli || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0 AND TRIM(p_nome_produto_cliente) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quando um ' || v_lbl_prodcli || ' existente é selecionado, o campo ' ||
                 'para se criar um novo ' || v_lbl_prodcli || ' não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE produto_cliente_id = p_produto_cliente_id
      AND pessoa_id = p_cliente_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
   --
   v_produto_cliente_id := p_produto_cliente_id;
  ELSE
   -- cria o novo produto
   produto_cliente_pkg.adicionar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 'N',
                                 p_cliente_id,
                                 p_nome_produto_cliente,
                                 v_produto_cliente_id,
                                 p_erro_cod,
                                 p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT emp_fatur_pdr_id,
         emp_resp_pdr_id
    INTO v_emp_faturar_por_id,
         v_emp_resp_id
    FROM pessoa
   WHERE pessoa_id = p_cliente_id;
  --
  IF util_pkg.desc_retornar('complex_job', v_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || v_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_cria_crono_auto,
         estrat_job
    INTO v_flag_cria_crono_auto,
         v_estrat_job
    FROM tipo_job
   WHERE tipo_job_id = v_tipo_job_id;
  --
  SELECT MAX(mod_crono_id)
    INTO v_mod_crono_id
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = v_tipo_job_id
     AND flag_padrao = 'S';
  --
  v_flag_usa_budget       := 'S';
  v_flag_usa_receita_prev := 'S';
  v_flag_obriga_contrato  := 'N';
  --
  IF v_flag_tipo_finan = 'S'
  THEN
   SELECT MAX(tipo_financeiro_id)
     INTO v_tipo_financeiro_id
     FROM tipo_financeiro
    WHERE empresa_id = p_empresa_id
      AND flag_padrao = 'S';
   --
   IF v_tipo_financeiro_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo financeiro padrão não encontrado para essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT flag_usa_receita_prev,
          flag_usa_budget,
          flag_obriga_contrato,
          codigo,
          nome
     INTO v_flag_usa_receita_prev,
          v_flag_usa_budget,
          v_flag_obriga_contrato,
          v_cod_tipo_finan,
          v_nome_tipo_finan
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = v_tipo_financeiro_id;
  END IF;
  --
  IF v_flag_obriga_contrato = 'S' AND nvl(p_contrato_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do contrato é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato
    WHERE contrato_id = p_contrato_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   -- pega dados do contrato
   SELECT flag_pago_cliente,
          perc_bv,
          flag_bv_fornec
     INTO v_flag_pago_cliente,
          v_perc_bv,
          v_flag_bv_fornec
     FROM contrato
    WHERE contrato_id = p_contrato_id;
  ELSE
   -- contrato nao definido. Pega dados do cliente
   SELECT flag_pago_cliente
     INTO v_flag_pago_cliente
     FROM pessoa
    WHERE pessoa_id = p_cliente_id;
   --
   v_perc_bv        := NULL;
   v_flag_bv_fornec := 'S';
  END IF;
  --
  IF p_descricao_cliente IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_budget_nd) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag budget não definido inválido (' || p_flag_budget_nd || ').';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_budget) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --
  v_budget := moeda_converter(p_budget);
  --
  IF v_budget < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_budget, 0) > 0
  THEN
   -- forca budget como Definido
   v_flag_budget_nd := 'N';
  ELSE
   v_flag_budget_nd := p_flag_budget_nd;
  END IF;
  --
  v_data_pri_aprov := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                         trunc(SYSDATE),
                                                         5,
                                                         'S');
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  job_pkg.prox_numero_retornar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_cliente_id,
                               v_tipo_financeiro_id,
                               v_numero_job,
                               v_tipo_num_job,
                               p_erro_cod,
                               p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE numero = v_numero_job
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job ||
                 '). Tente novamente.';
   RAISE v_exception;
  END IF;
  --                     
  SELECT seq_job.nextval
    INTO v_job_id
    FROM dual;
  --
  v_caminho_arq_externo := v_caminho_externo || '\' || to_char(v_data_atual, 'YYYY') || '\' ||
                           to_char(v_numero_job);
  --
  INSERT INTO job
   (job_id,
    empresa_id,
    cliente_id,
    contato_id,
    produto_cliente_id,
    emp_resp_id,
    usuario_solic_id,
    numero,
    tipo_num_job,
    tipo_job_id,
    tipo_financeiro_id,
    nome,
    descricao_cliente,
    data_pri_aprov,
    budget,
    flag_budget_nd,
    data_entrada,
    status,
    data_status,
    perc_bv,
    flag_bv_fornec,
    flag_pago_cliente,
    status_checkin,
    data_status_checkin,
    status_fatur,
    data_status_fatur,
    flag_bloq_negoc,
    caminho_arq_externo,
    tipo_data_prev,
    complex_job,
    estrat_job,
    status_aux_job_id,
    emp_faturar_por_id,
    contrato_id,
    flag_obriga_desc_horas,
    flag_usa_budget,
    flag_usa_receita_prev,
    flag_obriga_contrato,
    receita_prevista)
  VALUES
   (v_job_id,
    p_empresa_id,
    p_cliente_id,
    v_contato_id,
    v_produto_cliente_id,
    v_emp_resp_id,
    p_usuario_sessao_id,
    v_numero_job,
    v_tipo_num_job,
    v_tipo_job_id,
    zvl(v_tipo_financeiro_id, NULL),
    TRIM(p_nome),
    p_descricao_cliente,
    v_data_pri_aprov,
    v_budget,
    v_flag_budget_nd,
    v_data_atual,
    v_status_job,
    v_data_atual,
    v_perc_bv,
    v_flag_bv_fornec,
    v_flag_pago_cliente,
    'A',
    v_data_atual,
    'A',
    v_data_atual,
    'N',
    v_caminho_arq_externo,
    'EST',
    v_complex_job,
    v_estrat_job,
    v_status_aux_job_id,
    v_emp_faturar_por_id,
    zvl(p_contrato_id, NULL),
    v_flag_obriga_desc_horas,
    v_flag_usa_budget,
    v_flag_usa_receita_prev,
    v_flag_obriga_contrato,
    decode(v_flag_usa_receita_prev, 'S', 0, 'N', NULL));
  --
  UPDATE pessoa
     SET data_entrada_agencia = v_data_atual
   WHERE pessoa_id = p_cliente_id
     AND data_entrada_agencia IS NULL;
  --
  ------------------------------------------------------------
  -- instancia os valores padrao das naturezas dos itens
  ------------------------------------------------------------
  FOR r_na IN c_na
  LOOP
   INSERT INTO job_nitem_pdr
    (job_id,
     natureza_item_id,
     valor_padrao)
   VALUES
    (v_job_id,
     r_na.natureza_item_id,
     nvl(r_na.valor_padrao, 0));
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento do job
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Interface do Cliente';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'INCLUIR',
                   v_identif_objeto,
                   v_job_id,
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
  -- geracao de evento do tipo financeiro
  ------------------------------------------------------------
  IF nvl(v_tipo_financeiro_id, 0) > 0
  THEN
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := 'Tipo Financeiro: ' || v_nome_tipo_finan;
   v_justif_histor  := v_cod_tipo_finan;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'DEFINIR_TFIN',
                    v_identif_objeto,
                    v_job_id,
                    v_compl_histor,
                    v_justif_histor,
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
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento automatico
  ------------------------------------------------------------
  job_pkg.enderecar_automatico(p_usuario_sessao_id, p_empresa_id, v_job_id, p_erro_cod, p_erro_msg);
  -- 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- cronograma automatico
  ------------------------------------------------------------
  IF v_flag_cria_crono_auto = 'S' AND nvl(v_mod_crono_id, 0) > 0
  THEN
   cronograma_pkg.adicionar_com_modelo(p_usuario_sessao_id,
                                       p_empresa_id,
                                       'N',
                                       v_job_id,
                                       v_mod_crono_id,
                                       NULL,
                                       v_cronograma_id,
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
  -- cria o primeiro briefing
  ------------------------------------------------------------
  briefing_pkg.adicionar(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         v_job_id,
                         NULL,
                         v_briefing_id,
                         p_erro_cod,
                         p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_ADICIONAR', p_empresa_id, v_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_job_id      := v_job_id;
  p_briefing_id := v_briefing_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de ' || v_lbl_job || ' já existe (' || v_numero_job ||
                 '). Tente novamente.';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar_do_cliente;
 --
 --
 PROCEDURE atualizar_principal
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Atualização de JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/10/2007  Novos parametros para concorrencia e agencia.
  -- Silvia            24/04/2008  Preenchimento obrigatorio do produto.
  -- Silvia            16/01/2009  Consistencias adicionais em alteracao de status do job.
  -- Silvia            03/06/2009  Novo parametro flag_bloq_negoc.
  -- Silvia            15/07/2009  Retirada de consistencia de valores validos de encargos.
  -- Silvia            02/02/2010  Consistencia p/ alteracao de job do tipo 360.
  -- Silvia            23/03/2010  Ajuste em consistencia de percentual de honor do job para
  --                               usuarios sem privilegio de alteracao.
  -- Silvia            25/11/2010  Permitir conclusao de jobs sem estimativas aprovadas.
  --                               Novo parametro data_evento.
  -- Silvia            30/03/2011  Nao permitir conclusao de jobs sem estimativas aprovadas.
  -- Silvia            20/07/2011  Troca da data_evento por data_prev_ini e data_prev_fim.
  -- Silvia            10/05/2012  Nao permitir conclusao de jobs com estimativas em prep.
  -- Silvia            05/07/2012  Novo parametro p/ testar obrigatoriedade de briefing.
  -- Silvia            28/09/2012  Geracao de tarefa ao colocar job em andamento.
  -- Silvia            14/01/2013  Novos atributos de data.
  -- Silvia            12/06/2013  Novo parametro emp_resp_id.
  -- Silvia            04/06/2014  Perc BV passou a ter 5 decimais.
  -- Silvia            11/09/2014  Novo parametro contrato_id.
  -- Silvia            22/09/2014  Parametro agencia_id virou parceiro_id (pessoa).
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            03/03/2016  Complexidade do job.
  -- Silvia            09/03/2016  Enderecamento do usuario do contato
  -- Silvia            25/04/2016  Novo atributo em tipo de job (flag_alt_tipo_est) para 
  --                               substituir o 360.
  -- Silvia            11/05/2016  Novo parametro campanha_id.
  -- Silvia            13/09/2016  Naturezas de item configuraveis.
  -- Silvia            11/06/2018  Consistencia de alteracao do tipo financeiro.
  -- Silvia            24/07/2018  Deixa alterar o tipo financeiro, renumerando o job.
  -- Silvia            13/09/2018  Desmembramento da proc e troca de nome (antiga atualizar)
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev e 
  --                                      receita_prevista
  -- Silvia            21/01/2019  novo parametro cod_ext_job.
  -- Silvia            06/09/2019  Novo parametro unidade_negocio
  -- Silvia            15/10/2019  Retirada de parceiro de negocios.
  -- Silvia            03/01/2020  Novos campos de contexto do cronograma
  -- Silvia            13/04/2020  Registro do evento de tipo financeiro
  -- Silvia            14/08/2020  Novo parametro data_golive
  -- Silvia            12/01/2021  Novo parametro servico
  -- Silvia            31/08/2022  Consistencia de periodo job x contrato
  -- Ana Luiza         07/02/2025  Tratamento para pegar dependencias de job so se tiver 
  --                               parametro USAR_TIPO_FINANCEIRO = S
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id        IN NUMBER,
  p_empresa_id               IN job.empresa_id%TYPE,
  p_job_id                   IN job.job_id%TYPE,
  p_emp_resp_id              IN job.emp_resp_id%TYPE,
  p_tipo_job_id              IN job.tipo_job_id%TYPE,
  p_servico_id               IN job.servico_id%TYPE,
  p_tipo_financeiro_id       IN job.tipo_financeiro_id%TYPE,
  p_contrato_id              IN job.contrato_id%TYPE,
  p_campanha_id              IN job.campanha_id%TYPE,
  p_nome                     IN job.nome%TYPE,
  p_cod_ext_job              IN VARCHAR2,
  p_cliente_id               IN job.cliente_id%TYPE,
  p_contato_id               IN job.contato_id%TYPE,
  p_unidade_negocio_id       IN job.unidade_negocio_id%TYPE,
  p_produto_cliente_id       IN job.produto_cliente_id%TYPE,
  p_descricao                IN LONG,
  p_complex_job              IN VARCHAR2,
  p_budget                   IN VARCHAR2,
  p_flag_budget_nd           IN VARCHAR2,
  p_receita_prevista         IN VARCHAR2,
  p_data_prev_ini            IN VARCHAR2,
  p_data_prev_fim            IN VARCHAR2,
  p_tipo_data_prev           IN job.tipo_data_prev%TYPE,
  p_data_pri_aprov           IN VARCHAR2,
  p_data_golive              IN VARCHAR2,
  p_flag_alt_data_estim      IN VARCHAR2,
  p_nome_contexto            IN VARCHAR2,
  p_flag_restringe_alt_crono IN VARCHAR2,
  p_erro_cod                 OUT VARCHAR2,
  p_erro_msg                 OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_numero_job             job.numero%TYPE;
  v_cliente_old_id         job.cliente_id%TYPE;
  v_tipo_job_old_id        job.tipo_job_id%TYPE;
  v_flag_alt_tipo_est_old  tipo_job.flag_alt_tipo_est%TYPE;
  v_flag_alt_tipo_est_new  tipo_job.flag_alt_tipo_est%TYPE;
  v_flag_tem_camp          tipo_job.flag_tem_camp%TYPE;
  v_flag_camp_obr          tipo_job.flag_camp_obr%TYPE;
  v_flag_obriga_data_cli   tipo_job.flag_obriga_data_cli%TYPE;
  v_flag_obr_data_golive   tipo_job.flag_obr_data_golive%TYPE;
  v_tipo_job_min_id        job.tipo_job_id%TYPE;
  v_tipo_job_max_id        job.tipo_job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_flag_budget_nd         job.flag_budget_nd%TYPE;
  v_budget                 job.budget%TYPE;
  v_receita_prevista       job.receita_prevista%TYPE;
  v_data_prev_ini          job.data_prev_ini%TYPE;
  v_data_prev_fim          job.data_prev_fim%TYPE;
  v_data_pri_aprov         job.data_pri_aprov%TYPE;
  v_data_golive            job.data_golive%TYPE;
  v_status_checkin         job.status_checkin%TYPE;
  v_status_fatur           job.status_fatur%TYPE;
  v_emp_resp_old_id        job.emp_resp_id%TYPE;
  v_cod_ext_job            job.cod_ext_job%TYPE;
  v_data_prev_ini_old      job.data_prev_ini%TYPE;
  v_data_prev_fim_old      job.data_prev_fim%TYPE;
  v_tipo_num_job           job.tipo_num_job%TYPE;
  v_tipo_financeiro_old_id job.tipo_financeiro_id%TYPE;
  v_flag_usa_budget        job.flag_usa_budget%TYPE;
  v_flag_usa_receita_prev  job.flag_usa_receita_prev%TYPE;
  v_flag_obriga_contrato   job.flag_obriga_contrato%TYPE;
  v_cod_job                tipo_financeiro.cod_job%TYPE;
  v_cod_job_old            tipo_financeiro.cod_job%TYPE;
  v_cod_tipo_finan         tipo_financeiro.codigo%TYPE;
  v_nome_tipo_finan        tipo_financeiro.nome%TYPE;
  v_nome_tipo_finan_old    tipo_financeiro.nome%TYPE;
  v_exception              EXCEPTION;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_justif_histor          historico.justificativa%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_item_liberado          INTEGER;
  v_descricao              tarefa.descricao%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_lbl_jobs               VARCHAR2(100);
  v_lbl_briefs             VARCHAR2(100);
  v_lbl_prodcli            VARCHAR2(100);
  v_lbl_un                 VARCHAR2(100);
  v_un_obr                 VARCHAR2(100);
  v_flag_tipo_finan        VARCHAR2(10);
  v_flag_usar_camp         VARCHAR2(10);
  v_flag_briefing          VARCHAR2(10);
  v_flag_financeiro        VARCHAR2(10);
  v_flag_budget_obrig      VARCHAR2(10);
  v_flag_atu_apontam       VARCHAR2(5);
  v_flag_usar_servico      VARCHAR2(10);
  v_usuario_contato_id     usuario.usuario_id%TYPE;
  v_nome_contato           pessoa.apelido%TYPE;
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  v_flag_receita_obrig     VARCHAR2(10);
  v_contexto_crono_id      contexto_crono.contexto_crono_id%TYPE;
  v_restringe_periodo      VARCHAR2(10);
  v_data_ini_ctr           contrato.data_inicio%TYPE;
  v_data_fim_ctr           contrato.data_termino%TYPE;
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_job            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs           := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_un             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  v_lbl_prodcli        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_tipo_finan    := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_TIPO_FINANCEIRO');
  v_flag_financeiro    := empresa_pkg.parametro_retornar(p_empresa_id, 'FINANCE');
  v_flag_briefing      := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BRIEFING_OBRIGATORIO');
  v_flag_budget_obrig  := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BUDGET_OBRIGATORIO');
  v_flag_usar_camp     := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_CAMPANHA');
  v_lbl_briefs         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_PLURAL');
  v_flag_receita_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_RECEITA_OBRIGATORIO');
  v_flag_usar_servico  := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_SERVICO_JOB');
  v_un_obr             := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_UNID_NEG_OBRIGATORIO');
  v_restringe_periodo  := empresa_pkg.parametro_retornar(p_empresa_id, 'RESTRINGIR_PERIODO_JOB_CTR');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.cliente_id,
         jo.emp_resp_id,
         jo.status,
         jo.status_checkin,
         jo.status_fatur,
         jo.tipo_job_id,
         tj.flag_alt_tipo_est,
         jo.cod_ext_job,
         jo.data_prev_ini,
         jo.data_prev_fim,
         jo.tipo_financeiro_id,
         jo.tipo_num_job,
         jo.flag_usa_budget,
         jo.flag_usa_receita_prev,
         jo.flag_obriga_contrato
    INTO v_numero_job,
         v_cliente_old_id,
         v_emp_resp_old_id,
         v_status_job,
         v_status_checkin,
         v_status_fatur,
         v_tipo_job_old_id,
         v_flag_alt_tipo_est_old,
         v_cod_ext_job,
         v_data_prev_ini_old,
         v_data_prev_fim_old,
         v_tipo_financeiro_old_id,
         v_tipo_num_job,
         v_flag_usa_budget,
         v_flag_usa_receita_prev,
         v_flag_obriga_contrato
    FROM job      jo,
         tipo_job tj
   WHERE jo.job_id = p_job_id
     AND jo.tipo_job_id = tj.tipo_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se algum item ja foi liberado para faturamento
  SELECT COUNT(*)
    INTO v_item_liberado
    FROM item
   WHERE job_id = p_job_id
     AND status_fatur <> 'NLIB'
     AND rownum = 1;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_nome) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_cod_ext_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job ||
                 ' no outro sistema não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_ext_job) IN ('-', '.', ':', '?', '/', '\', '|', '*', ',', '0')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número do ' || v_lbl_job || ' no outro sistema inválido (esse campo é opcional).';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_emp_resp_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa responsável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE pessoa_id = p_emp_resp_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa empresa responsável não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_emp_resp_old_id <> p_emp_resp_id
  THEN
   IF v_cod_ext_job IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A empresa responsável não pode ser alterada pois o ' || v_lbl_job ||
                  ' já foi integrado.';
    RAISE v_exception;
   END IF;
   --
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_RESP_A', p_job_id, NULL, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para alterar a empresa responsável pelo ' || v_lbl_job || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_tipo_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de ' || v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_usar_servico = 'S' AND nvl(p_servico_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do produto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_servico_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM servico
    WHERE servico_id = p_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF TRIM(p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da complexidade é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade inválida (' || p_complex_job || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_alt_tipo_est,
         flag_tem_camp,
         flag_camp_obr,
         flag_obriga_data_cli,
         flag_obr_data_golive
    INTO v_flag_alt_tipo_est_new,
         v_flag_tem_camp,
         v_flag_camp_obr,
         v_flag_obriga_data_cli,
         v_flag_obr_data_golive
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  -- verifica se mudou o flag_alt_tipo_est do tipo de job (antigo teste 360)
  IF v_flag_alt_tipo_est_old = 'S' AND v_flag_alt_tipo_est_new = 'N'
  THEN
   --
   SELECT MIN(tipo_job_id),
          MAX(tipo_job_id)
     INTO v_tipo_job_min_id,
          v_tipo_job_max_id
     FROM orcamento
    WHERE job_id = p_job_id;
   --
   IF v_tipo_job_min_id IS NOT NULL
   THEN
    IF v_tipo_job_min_id <> p_tipo_job_id OR v_tipo_job_max_id <> p_tipo_job_id
    THEN
     --
     p_erro_cod := '90000';
     p_erro_msg := 'O ' || v_lbl_job || ' só pode deixar de ser desse tipo se todas as ' ||
                   'Estimativas de Custos forem alteradas para o novo tipo do ' || v_lbl_job || '.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF v_flag_usar_camp = 'S' AND v_flag_tem_camp = 'S' AND v_flag_camp_obr = 'S'
  THEN
   IF nvl(p_campanha_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da campanha é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_campanha_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM campanha
    WHERE campanha_id = p_campanha_id
      AND cliente_id = p_cliente_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa campanha não existe ou não pertence a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_tipo_finan = 'S'
  THEN
   IF nvl(p_tipo_financeiro_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do tipo financeiro é obrigatório.';
    RAISE v_exception;
   END IF;
  ELSE
   --ALCBO_070225
   -- v_flag_tipo_finan = 'N'
   IF nvl(p_tipo_financeiro_id, 0) > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_financeiro
     WHERE tipo_financeiro_id = p_tipo_financeiro_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse tipo financeiro não existe.';
     RAISE v_exception;
    END IF;
    --
    SELECT flag_usa_receita_prev,
           flag_usa_budget,
           flag_obriga_contrato,
           codigo,
           nome
      INTO v_flag_usa_receita_prev,
           v_flag_usa_budget,
           v_flag_obriga_contrato,
           v_cod_tipo_finan,
           v_nome_tipo_finan
      FROM tipo_financeiro
     WHERE tipo_financeiro_id = p_tipo_financeiro_id;
    --
    -- verifica se a mudanca do tipo financeiro afeta a numeracao do job
    -- (apenas no caso de jobs criados com numeracao com tipo financeiro)
    IF p_tipo_financeiro_id <> v_tipo_financeiro_old_id AND v_tipo_num_job = 'SEQ_COM_TFI'
    THEN
     --
     SELECT TRIM(cod_job)
       INTO v_cod_job
       FROM tipo_financeiro
      WHERE tipo_financeiro_id = p_tipo_financeiro_id;
     --
     IF v_cod_job IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O novo tipo financeiro não tem código definido para ' ||
                    'ser usado na numeração do ' || v_lbl_job || '.';
      RAISE v_exception;
     END IF;
     --
     SELECT MAX(TRIM(cod_job))
       INTO v_cod_job_old
       FROM tipo_financeiro
      WHERE tipo_financeiro_id = v_tipo_financeiro_old_id;
     --
     -- verifica se o novo tipo financeiro tem o mesmo prefixo
     IF v_cod_job <> v_cod_job_old
     THEN
      -- atualiza o numero do job
      v_numero_job := v_cod_job || substr(v_numero_job, length(v_cod_job_old) + 1);
     END IF;
    END IF;
   END IF;
   --
   IF nvl(v_tipo_financeiro_old_id, 0) > 0
   THEN
    SELECT nome
      INTO v_nome_tipo_finan_old
      FROM tipo_financeiro
     WHERE tipo_financeiro_id = v_tipo_financeiro_old_id;
   END IF;
   --
   IF v_flag_obriga_contrato = 'S' AND nvl(p_contrato_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do contrato é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF; --v_flag_tipo_finan = 'N'; --ALCBO_070225
  --
  IF nvl(p_contrato_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM contrato
    WHERE contrato_id = p_contrato_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT data_inicio,
          data_termino
     INTO v_data_ini_ctr,
          v_data_fim_ctr
     FROM contrato
    WHERE contrato_id = p_contrato_id;
  END IF;
  --
  IF nvl(p_cliente_id, 0) = 0
  THEN
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  IF p_cliente_id <> v_cliente_old_id AND v_item_liberado > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O cliente não pode ser alterado pois existem itens ' ||
                 'que já foram liberados para faturamento.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_contato_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao r
    WHERE r.pessoa_pai_id = p_cliente_id
      AND r.pessoa_filho_id = p_contato_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato não está associado a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_un_obr = 'S' AND nvl(p_unidade_negocio_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento de ' || v_lbl_un || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job = 'ANDA'
  THEN
   IF nvl(p_produto_cliente_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do ' || v_lbl_prodcli || ' é obrigatório para ' || v_lbl_jobs ||
                  ' "em andamento".';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_produto_cliente_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM produto_cliente
    WHERE produto_cliente_id = p_produto_cliente_id
      AND pessoa_id = p_cliente_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não está associado a esse cliente.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_financeiro = 'S' AND (v_status_checkin = 'F' OR v_status_fatur = 'F')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := v_lbl_job || ' com check-in ou faturamento fechado não pode ser alterado.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 1000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_alt_data_estim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag alterar datas das estimativas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_prev_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_prev_ini || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prev_ini := data_converter(p_data_prev_ini);
  --
  IF data_validar(p_data_prev_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_prev_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_prev_fim := data_converter(p_data_prev_fim);
  --
  IF util_pkg.desc_retornar('tipo_data_job', p_tipo_data_prev) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de data inválido (' || p_tipo_data_prev || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_obriga_data_cli = 'S' AND TRIM(p_data_pri_aprov) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data da apresentação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_pri_aprov) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data da apresentação inválida (' || p_data_pri_aprov || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_pri_aprov := data_converter(p_data_pri_aprov);
  --
  IF v_flag_obr_data_golive = 'S' AND TRIM(p_data_golive) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de Go Live é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_golive) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de Go Live inválida (' || p_data_golive || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_golive := data_converter(p_data_golive);
  --
  IF flag_validar(p_flag_budget_nd) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag budget não definido inválido.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_budget) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --
  v_budget := moeda_converter(p_budget);
  --
  IF v_budget < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Budget inválido.';
   RAISE v_exception;
  END IF;
  --ALCBO_070225 -> Add AND v_flag_tipo_finan = 'S'
  IF v_flag_usa_budget = 'S' AND v_flag_tipo_finan = 'S' AND nvl(v_budget, 0) = 0 AND
     (v_flag_budget_obrig = 'S' OR p_flag_budget_nd <> 'S')
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM briefing
    WHERE job_id = p_job_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O budget deve ser informado pois já existem ' || v_lbl_briefs || ' para esse ' ||
                  v_lbl_job || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(v_budget, 0) > 0
  THEN
   -- forca budget como Definido
   v_flag_budget_nd := 'N';
  ELSE
   v_flag_budget_nd := p_flag_budget_nd;
  END IF;
  --
  IF moeda_validar(p_receita_prevista) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Receita prevista inválida.';
   RAISE v_exception;
  END IF;
  --
  v_receita_prevista := moeda_converter(p_receita_prevista);
  --
  IF v_receita_prevista < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Receita prevista inválida.';
   RAISE v_exception;
  END IF;
  --ALCBO_070225 -> Add AND v_flag_tipo_finan = 'S'
  IF v_flag_usa_receita_prev = 'S' AND v_flag_tipo_finan = 'S' AND nvl(v_receita_prevista, 0) = 0 AND
     v_flag_receita_obrig = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da receita prevista é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_prev_ini > v_data_prev_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início não pode ser maior que a data de término.';
   RAISE v_exception;
  END IF;
  --
  IF v_restringe_periodo = 'S' AND v_data_prev_ini IS NOT NULL AND v_data_prev_fim IS NOT NULL AND
     v_data_ini_ctr IS NOT NULL AND v_data_fim_ctr IS NOT NULL AND
     (v_data_prev_ini NOT BETWEEN v_data_ini_ctr AND v_data_fim_ctr OR
     v_data_prev_fim NOT BETWEEN v_data_ini_ctr AND v_data_fim_ctr)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O período de duração do ' || v_lbl_job || ' deve estar contido ' ||
                 'no período de vigência do Contrato indicado.';
   RAISE v_exception;
  END IF;
  --
  v_flag_atu_apontam := 'N';
  IF v_data_prev_ini IS NOT NULL AND v_data_prev_fim IS NOT NULL
  THEN
   IF v_data_prev_ini <> v_data_prev_ini_old OR v_data_prev_ini_old IS NULL OR
      v_data_prev_fim <> v_data_prev_fim_old OR v_data_prev_fim_old IS NULL
   THEN
    -- mudou o periodo do job. atualiza tb o periodo do apontamento.
    v_flag_atu_apontam := 'S';
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_restringe_alt_crono) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag restringe alteração de cronograma inválido (' || p_flag_restringe_alt_crono || ').';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome_contexto) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O contexto não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nome_contexto) IS NOT NULL AND p_flag_restringe_alt_crono = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quando o contexto é especificado, as atividades não podem ser alteradas no cronograma.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_contexto_crono_id := NULL;
  --
  IF TRIM(p_nome_contexto) IS NOT NULL
  THEN
   SELECT MAX(contexto_crono_id)
     INTO v_contexto_crono_id
     FROM contexto_crono
    WHERE upper(nome) = TRIM(upper(p_nome_contexto))
      AND empresa_id = p_empresa_id;
   --
   IF v_contexto_crono_id IS NULL
   THEN
    SELECT seq_contexto_crono.nextval
      INTO v_contexto_crono_id
      FROM dual;
    --
    INSERT INTO contexto_crono
     (contexto_crono_id,
      empresa_id,
      nome)
    VALUES
     (v_contexto_crono_id,
      p_empresa_id,
      TRIM(p_nome_contexto));
   END IF;
  END IF;
  --
  UPDATE job
     SET tipo_job_id              = p_tipo_job_id,
         servico_id               = zvl(p_servico_id, NULL),
         tipo_financeiro_id       = zvl(p_tipo_financeiro_id, NULL),
         contrato_id              = zvl(p_contrato_id, NULL),
         campanha_id              = zvl(p_campanha_id, NULL),
         nome                     = TRIM(p_nome),
         numero                   = v_numero_job,
         emp_resp_id              = p_emp_resp_id,
         cliente_id               = p_cliente_id,
         contato_id               = zvl(p_contato_id, NULL),
         descricao                = TRIM(p_descricao),
         budget                   = v_budget,
         receita_prevista         = v_receita_prevista,
         flag_budget_nd           = v_flag_budget_nd,
         data_prev_ini            = v_data_prev_ini,
         data_prev_fim            = v_data_prev_fim,
         tipo_data_prev           = TRIM(p_tipo_data_prev),
         data_pri_aprov           = v_data_pri_aprov,
         data_golive              = v_data_golive,
         produto_cliente_id       = zvl(p_produto_cliente_id, NULL),
         complex_job              = p_complex_job,
         cod_ext_job              = p_cod_ext_job,
         unidade_negocio_id       = zvl(p_unidade_negocio_id, NULL),
         flag_usa_budget          = v_flag_usa_budget,
         flag_usa_receita_prev    = v_flag_usa_receita_prev,
         flag_obriga_contrato     = v_flag_obriga_contrato,
         contexto_crono_id        = v_contexto_crono_id,
         flag_restringe_alt_crono = p_flag_restringe_alt_crono
   WHERE job_id = p_job_id;
  --
  -- limpa eventuais contextos nao mais utilizados
  DELETE FROM contexto_crono cc
   WHERE empresa_id = p_empresa_id
     AND NOT EXISTS (SELECT 1
            FROM job jo
           WHERE jo.contexto_crono_id = cc.contexto_crono_id);
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  IF p_tipo_job_id <> v_tipo_job_old_id AND v_flag_alt_tipo_est_new = 'N'
  THEN
   -- mudou o tipo de job e nao se trata de 360. Sincroniza os tipos de job das
   -- estimativas.
   UPDATE orcamento
      SET tipo_job_id = p_tipo_job_id
    WHERE job_id = p_job_id;
  END IF;
  --
  IF p_flag_alt_data_estim = 'S' AND v_data_prev_ini IS NOT NULL AND v_data_prev_fim IS NOT NULL
  THEN
   --
   -- atualiza as datas de todas as estimativas do job
   UPDATE orcamento
      SET data_prev_ini = v_data_prev_ini,
          data_prev_fim = v_data_prev_fim
    WHERE job_id = p_job_id;
  END IF;
  --
  IF v_flag_atu_apontam = 'S'
  THEN
   UPDATE job
      SET data_apont_ini = v_data_prev_ini,
          data_apont_fim = v_data_prev_fim
    WHERE job_id = p_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- enderecamento do usuario do contato, com co-enderecamento
  ------------------------------------------------------------
  IF nvl(p_contato_id, 0) > 0
  THEN
   SELECT usuario_id,
          apelido
     INTO v_usuario_contato_id,
          v_nome_contato
     FROM pessoa
    WHERE pessoa_id = p_contato_id;
   --
   IF v_usuario_contato_id IS NOT NULL
   THEN
    -- com co-ender, sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'S',
                              'N',
                              p_empresa_id,
                              p_job_id,
                              v_usuario_contato_id,
                              v_nome_contato || ' indicado como Contato do Cliente',
                              'Alteração de ' || v_lbl_job,
                              p_erro_cod,
                              p_erro_msg);
    -- 
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_ATUALIZAR', p_empresa_id, p_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento do job
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
  -- geracao de evento do tipo financeiro
  ------------------------------------------------------------
  IF nvl(p_tipo_financeiro_id, 0) > 0 AND
     nvl(p_tipo_financeiro_id, 0) <> nvl(v_tipo_financeiro_old_id, 0)
  THEN
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := 'Tipo Financeiro: ' || v_nome_tipo_finan_old || ' - ' || v_nome_tipo_finan;
   v_justif_histor  := v_cod_tipo_finan;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'ALTERAR_TFIN',
                    v_identif_objeto,
                    p_job_id,
                    v_compl_histor,
                    v_justif_histor,
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
 END atualizar_principal;
 --
 --
 PROCEDURE atualizar_concorrencia
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/09/2018
  -- DESCRICAO: Atualização de dados de concorrencia do JOB (desmembrado da antiga 
  --    procedure ATUALIZAR)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_flag_concorrencia IN job.flag_concorrencia%TYPE,
  p_contra_quem       IN job.contra_quem%TYPE,
  p_flag_conc_perdida IN job.flag_conc_perdida%TYPE,
  p_perdida_para      IN job.perdida_para%TYPE,
  p_motivo_cancel     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status
    INTO v_numero_job,
         v_status_job
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_concorrencia) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag concorrência inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_conc_perdida) IS NOT NULL AND TRIM(p_flag_conc_perdida) NOT IN ('S', 'N')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag concorrência perdida inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_concorrencia = 'N' AND
     (TRIM(p_contra_quem) IS NOT NULL OR p_flag_conc_perdida IN ('S', 'N') OR
     TRIM(p_perdida_para) IS NOT NULL)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Como o ' || v_lbl_job || ' não está marcado como "concorrência", os campos ' ||
                 'que indicam contra quem / concorrência perdida / perdida para quem, ' ||
                 'não devem ser preenchidos.';
   RAISE v_exception;
  END IF;
  --
  IF (p_flag_conc_perdida = 'S' OR v_status_job = 'CANC') AND TRIM(p_motivo_cancel) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo da perda da concorrência ' || 'ou do cancelamento do ' ||
                 v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_motivo_cancel) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo da concorrência perdida ' || 'não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET flag_concorrencia = p_flag_concorrencia,
         contra_quem       = TRIM(p_contra_quem),
         flag_conc_perdida = TRIM(p_flag_conc_perdida),
         perdida_para      = TRIM(p_perdida_para),
         motivo_cancel     = TRIM(p_motivo_cancel)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Alteração de concorrência';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END atualizar_concorrencia;
 --
 --
 PROCEDURE atualizar_financeiro
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/09/2018
  -- DESCRICAO: Atualização de informacoes financeiras do JOB (desmembrado da antiga 
  --    procedure ATUALIZAR)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN job.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_contato_fatur_id       IN job.contato_fatur_id%TYPE,
  p_vetor_natureza_item_id IN VARCHAR2,
  p_vetor_valor_padrao     IN VARCHAR2,
  p_flag_pago_cliente      IN job.flag_pago_cliente%TYPE,
  p_flag_bloq_negoc        IN job.flag_bloq_negoc%TYPE,
  p_flag_bv_fornec         IN job.flag_bv_fornec%TYPE,
  p_perc_bv                IN VARCHAR2,
  p_emp_faturar_por_id     IN job.emp_faturar_por_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_numero_job             job.numero%TYPE;
  v_cliente_id             job.cliente_id%TYPE;
  v_perc_bv                job.perc_bv%TYPE;
  v_status_job             job.status%TYPE;
  v_status_checkin         job.status_checkin%TYPE;
  v_status_fatur           job.status_fatur%TYPE;
  v_exception              EXCEPTION;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_altera_perc            INTEGER;
  v_lbl_job                VARCHAR2(100);
  v_flag_financeiro        VARCHAR2(10);
  v_delimitador            CHAR(1);
  v_vetor_natureza_item_id VARCHAR2(1000);
  v_vetor_valor_padrao     VARCHAR2(1000);
  v_natureza_item_id       job_nitem_pdr.natureza_item_id%TYPE;
  v_valor_padrao           job_nitem_pdr.valor_padrao%TYPE;
  v_valor_padrao_char      VARCHAR2(50);
  v_nome_natureza          natureza_item.nome%TYPE;
  v_mod_calculo            natureza_item.mod_calculo%TYPE;
  v_desc_calculo           VARCHAR2(100);
  v_xml_antes              CLOB;
  v_xml_atual              CLOB;
  --
 BEGIN
  v_qt              := 0;
  v_lbl_job         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'FINANCE');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.cliente_id,
         jo.status,
         jo.status_checkin,
         jo.status_fatur
    INTO v_numero_job,
         v_cliente_id,
         v_status_job,
         v_status_checkin,
         v_status_fatur
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio de alterar percentuais do job
  SELECT usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_PERC_C', p_job_id, NULL, p_empresa_id)
    INTO v_altera_perc
    FROM dual;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_contato_fatur_id, 0) > 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM relacao r
    WHERE r.pessoa_pai_id = v_cliente_id
      AND r.pessoa_filho_id = p_contato_fatur_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse contato de faturamento não está associado ao cliente do ' || v_lbl_job || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_financeiro = 'S' AND (v_status_checkin = 'F' OR v_status_fatur = 'F')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := v_lbl_job || ' com check-in ou faturamento fechado não pode ser alterado.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_perc_bv) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Percentual de BV inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bv_fornec) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag BV de fornecedor inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_bloq_negoc) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag bloqueio de negociação inválido.';
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
  v_perc_bv := numero_converter(p_perc_bv);
  --
  IF p_flag_bv_fornec = 'S' AND nvl(v_perc_bv, 0) <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ao se utilizar o BV padrão de cada fornecedor, ' ||
                 'o percentual de BV não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_bv_fornec = 'N' AND v_perc_bv IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O BV a ser utilizado no ' || v_lbl_job || ' deve ser definido';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET contato_fatur_id   = zvl(p_contato_fatur_id, NULL),
         perc_bv            = v_perc_bv,
         flag_bloq_negoc    = p_flag_bloq_negoc,
         flag_bv_fornec     = p_flag_bv_fornec,
         emp_faturar_por_id = zvl(p_emp_faturar_por_id, NULL),
         flag_pago_cliente  = p_flag_pago_cliente
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de naturezas do item
  ------------------------------------------------------------
  IF v_altera_perc = 1
  THEN
   -- apenas usuario com priv de alterar percentuais
   DELETE FROM job_nitem_pdr
    WHERE job_id = p_job_id;
   --
   v_delimitador            := '|';
   v_vetor_natureza_item_id := rtrim(p_vetor_natureza_item_id);
   v_vetor_valor_padrao     := rtrim(p_vetor_valor_padrao);
   --
   WHILE nvl(length(rtrim(v_vetor_natureza_item_id)), 0) > 0
   LOOP
    v_natureza_item_id  := nvl(to_number(prox_valor_retornar(v_vetor_natureza_item_id,
                                                             v_delimitador)),
                               0);
    v_valor_padrao_char := prox_valor_retornar(v_vetor_valor_padrao, v_delimitador);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM natureza_item
     WHERE natureza_item_id = v_natureza_item_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa (' ||
                   to_char(v_natureza_item_id) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT nome,
           util_pkg.desc_retornar('mod_calculo', mod_calculo),
           mod_calculo
      INTO v_nome_natureza,
           v_desc_calculo,
           v_mod_calculo
      FROM natureza_item
     WHERE natureza_item_id = v_natureza_item_id;
    --
    IF v_mod_calculo = 'NA'
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa natureza de item não se aplica para cálculos (' || v_nome_natureza || ').';
     RAISE v_exception;
    END IF;
    --
    IF numero_validar(v_valor_padrao_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := v_desc_calculo || ' para ' || v_nome_natureza || ' inválido (' ||
                   v_valor_padrao_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_valor_padrao := numero_converter(v_valor_padrao_char);
    --
    IF v_valor_padrao IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do ' || v_desc_calculo || ' para ' || v_nome_natureza ||
                   ' é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO job_nitem_pdr
     (job_id,
      natureza_item_id,
      valor_padrao)
    VALUES
     (p_job_id,
      v_natureza_item_id,
      nvl(v_valor_padrao, 0));
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_ATUALIZAR', p_empresa_id, p_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Alteração de informações financeiras';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END atualizar_financeiro;
 --
 --
 PROCEDURE atualizar_comissionados
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Alteracao em lista de indicacao de comissionamento de um determinado job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/09/2018  Troca de nome da proc (antiga comissionados_atualizar)
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_vetor_usuarios     IN VARCHAR2,
  p_vetor_comissionado IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_cliente_id         job.cliente_id%TYPE;
  v_status_job         job.status%TYPE;
  v_vetor_usuarios     VARCHAR2(2000);
  v_vetor_comissionado VARCHAR2(2000);
  v_delimitador        CHAR(1);
  v_usuario_id         usuario.usuario_id%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_flag_comissionado  VARCHAR2(10);
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(cliente_id),
         MAX(status)
    INTO v_numero_job,
         v_cliente_id,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'ENDER_COMISSAO_C',
                                p_job_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  v_delimitador        := ',';
  v_vetor_usuarios     := rtrim(p_vetor_usuarios);
  v_vetor_comissionado := rtrim(p_vetor_comissionado);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id        := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   v_flag_comissionado := nvl(prox_valor_retornar(v_vetor_comissionado, v_delimitador), 'N');
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_comissionado NOT IN ('S', 'N')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag comissionado inválido (' || v_flag_comissionado || ').';
    RAISE v_exception;
   END IF;
   --
   UPDATE job_usuario
      SET flag_comissionado = v_flag_comissionado
    WHERE job_id = p_job_id
      AND usuario_id = v_usuario_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Alteração de indicação de comissionamento';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END atualizar_comissionados;
 --
 --
 PROCEDURE atualizar_responsavel
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/05/2016
  -- DESCRICAO: define o responsavel interno pelo job (apenas 1). Quando 
  --  usuario_id = 0, desmarca todos os responsaveis internos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/03/2017  Uso de subrotina enderecar_usuario com co-ender
  -- Silvia            22/11/2017  Altera solicitante das OS.
  -- Silvia            13/09/2018  Troca de nome da proc (antiga responsavel_atualizar)
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_numero_job          job.numero%TYPE;
  v_data_dist_limite    job.data_dist_limite%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_justif_histor       historico.justificativa%TYPE;
  v_apelido             pessoa.apelido%TYPE;
  v_qt_resp_atu         NUMBER(5);
  v_altera_sol_os       VARCHAR2(10);
  v_numero_os_char      VARCHAR2(50);
  v_usuario_resp_ant_id usuario.usuario_id%TYPE;
  --
  CURSOR c_os IS
   SELECT os.ordem_servico_id
     FROM ordem_servico os
    WHERE os.job_id = p_job_id
      AND os.status NOT IN ('CANC', 'CONC', 'DESC')
      AND NOT EXISTS (SELECT 1
             FROM os_usuario ou
            WHERE ou.ordem_servico_id = os.ordem_servico_id
              AND ou.usuario_id = p_usuario_id
              AND ou.tipo_ender = 'SOL');
  --
 BEGIN
  v_qt            := 0;
  v_altera_sol_os := empresa_pkg.parametro_retornar(p_empresa_id, 'ALTERAR_SOL_OS_RESP_INT');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero)
    INTO v_numero_job
    FROM job jo
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica o responsavel antes da alteracao
  SELECT MAX(usuario_id)
    INTO v_usuario_resp_ant_id
    FROM job_usuario
   WHERE job_id = p_job_id
     AND flag_responsavel = 'S';
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_usuario
     SET flag_responsavel = 'N'
   WHERE job_id = p_job_id;
  --
  IF nvl(p_usuario_id, 0) > 0
  THEN
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'JOB_RESP_INT_V', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário ' || v_apelido || ' não tem privilégio para ser responsável.';
    RAISE v_exception;
   END IF;
   --
   -- a subrotina marca esse usuario como responsavel, COM co-ender, sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'S',
                             'N',
                             p_empresa_id,
                             p_job_id,
                             p_usuario_id,
                             v_apelido || ' definido como responsável',
                             'Definição de responsável',
                             p_erro_cod,
                             p_erro_msg);
   -- 
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF v_altera_sol_os = 'S'
   THEN
    -- altera solicitantes das OS em andamento
    FOR r_os IN c_os
    LOOP
     v_numero_os_char := ordem_servico_pkg.numero_formatar(r_os.ordem_servico_id);
     --
     INSERT INTO os_usuario
      (ordem_servico_id,
       usuario_id,
       status,
       data_status,
       tipo_ender,
       horas_planej,
       sequencia)
     VALUES
      (r_os.ordem_servico_id,
       p_usuario_id,
       NULL,
       NULL,
       'SOL',
       NULL,
       1);
     --
     historico_pkg.hist_ender_registrar(p_usuario_id,
                                        'OS',
                                        r_os.ordem_servico_id,
                                        'SOL',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     IF nvl(v_usuario_resp_ant_id, 0) <> p_usuario_id
     THEN
      -- desendereca o solicitante anterior
      DELETE FROM os_usuario
       WHERE ordem_servico_id = r_os.ordem_servico_id
         AND tipo_ender = 'SOL'
         AND usuario_id = v_usuario_resp_ant_id;
     END IF;
     --
     -- geracao de evento
     v_identif_objeto := v_numero_os_char;
     v_compl_histor   := 'Endereçamento automático de solicitante (' || v_apelido || ')';
     --
     evento_pkg.gerar(p_usuario_sessao_id,
                      p_empresa_id,
                      'ORDEM_SERVICO',
                      'ALTERAR',
                      v_identif_objeto,
                      r_os.ordem_servico_id,
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
    END LOOP;
   END IF;
  END IF; -- fim do IF NVL(p_usuario_id,0) > 0
  --
  ------------------------------------------------------------
  -- calculo da data limite p/ distribuicao
  ------------------------------------------------------------
  -- verifica a qtd de responsaveis depois da alteracao
  SELECT COUNT(*)
    INTO v_qt_resp_atu
    FROM job_usuario
   WHERE job_id = p_job_id
     AND flag_responsavel = 'S';
  --
  IF v_qt_resp_atu = 0 AND v_usuario_resp_ant_id IS NOT NULL
  THEN
   v_data_dist_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_DIST_JOB',
                                                             0);
   UPDATE job
      SET data_dist_limite = v_data_dist_limite
    WHERE job_id = p_job_id;
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
 END atualizar_responsavel;
 --
 --
 PROCEDURE atualizar_periodo_apont
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/06/2013
  -- DESCRICAO: Atualização do periodo de apontamento de horas do JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2018  Novo parametro 
  -- Silvia            13/09/2018  Troca de nome da proc (antiga periodo_apont_atualizar)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN job.empresa_id%TYPE,
  p_job_id                 IN job.job_id%TYPE,
  p_data_apont_ini         IN VARCHAR2,
  p_data_apont_fim         IN VARCHAR2,
  p_flag_obriga_desc_horas IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_data_apont_ini job.data_apont_ini%TYPE;
  v_data_apont_fim job.data_apont_fim%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_PER_HOR_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data_apont_ini) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_apont_fim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de término é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apont_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_apont_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_apont_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_apont_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_apont_ini := data_converter(p_data_apont_ini);
  v_data_apont_fim := data_converter(p_data_apont_fim);
  --
  IF v_data_apont_ini > v_data_apont_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início não pode ser maior que a data de término.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_desc_horas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga descrição inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET data_apont_ini         = v_data_apont_ini,
         data_apont_fim         = v_data_apont_fim,
         flag_obriga_desc_horas = TRIM(p_flag_obriga_desc_horas)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Alteração do período de apontamento de horas';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END atualizar_periodo_apont;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2015
  -- DESCRICAO: Adicionar arquivo no JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_volume_id         IN arquivo.volume_id%TYPE,
  p_job_id            IN arquivo_job.job_id%TYPE,
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
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
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
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
   WHERE empresa_id = p_empresa_id
     AND codigo = 'JOB';
  -- 
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_job_id,
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
  v_identif_objeto := to_char(v_numero_job);
  --                  
  v_compl_histor := 'Anexação de arquivo no Job (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2015
  -- DESCRICAO: Excluir arquivo do JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_nome_original  arquivo.nome_original%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job         jo,
         arquivo_job ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.job_id = jo.job_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT aj.job_id,
         ar.nome_original
    INTO v_job_id,
         v_nome_original
    FROM arquivo_job aj,
         arquivo     ar
   WHERE aj.arquivo_id = p_arquivo_id
     AND aj.arquivo_id = ar.arquivo_id;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = v_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', v_job_id, NULL, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
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
  v_identif_objeto := to_char(v_numero_job);
  --
  v_compl_histor := 'Exclusão de arquivo do Job (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 PROCEDURE receita_contrato_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/09/2018
  -- DESCRICAO: Inclusao de receita de contrato ao JOB (alocacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_contrato_id       IN contrato.contrato_id%TYPE,
  p_valor_alocado     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_numero_contrato    contrato.numero%TYPE;
  v_status_contrato    contrato.status%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_job_receita_ctr_id job_receita_ctr.job_receita_ctr_id%TYPE;
  v_valor_alocado      job_receita_ctr.valor_alocado%TYPE;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_contrato,
         v_status_contrato
    FROM contrato
   WHERE contrato_id = p_contrato_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_contrato IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse contrato não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_RECEITA_CTR_C',
                                p_job_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF moeda_validar(p_valor_alocado) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da nova receita inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_alocado := nvl(moeda_converter(p_valor_alocado), 0);
  --
  IF v_valor_alocado <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor da nova receita inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_valor_alocado > contrato_pkg.valor_retornar(p_contrato_id, 'AALOCAR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O valor da nova receita não pode ser maior do que o valor ' ||
                 'disponível (a alocar) do contrato.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT MAX(job_receita_ctr_id)
    INTO v_job_receita_ctr_id
    FROM job_receita_ctr
   WHERE job_id = p_job_id
     AND contrato_id = p_contrato_id;
  --
  IF v_job_receita_ctr_id IS NULL
  THEN
   SELECT seq_job_receita_ctr.nextval
     INTO v_job_receita_ctr_id
     FROM dual;
   --
   INSERT INTO job_receita_ctr
    (job_receita_ctr_id,
     job_id,
     contrato_id,
     valor_alocado)
   VALUES
    (v_job_receita_ctr_id,
     p_job_id,
     p_contrato_id,
     v_valor_alocado);
  ELSE
   UPDATE job_receita_ctr
      SET valor_alocado = valor_alocado + v_valor_alocado
    WHERE job_receita_ctr_id = v_job_receita_ctr_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Inclusão de receita de contrato (Contrato: ' || to_char(v_numero_contrato) ||
                      ' - Valor: ' || moeda_mostrar(v_valor_alocado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END receita_contrato_adicionar;
 --
 --
 PROCEDURE receita_contrato_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/09/2018
  -- DESCRICAO: Exclusao de receita de contrato do JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_receita_ctr_id IN job_receita_ctr.job_receita_ctr_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_job_id          job.job_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_numero_contrato contrato.numero%TYPE;
  v_status_contrato contrato.status%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_valor_alocado   job_receita_ctr.valor_alocado%TYPE;
  v_lbl_job         VARCHAR2(100);
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
    FROM job_receita_ctr
   WHERE job_receita_ctr_id = p_job_receita_ctr_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa receita não existe.';
   RAISE v_exception;
  END IF;
  SELECT jo.numero,
         jo.status,
         jo.job_id,
         ct.numero,
         ct.status,
         jr.valor_alocado
    INTO v_numero_job,
         v_status_job,
         v_job_id,
         v_numero_contrato,
         v_status_contrato,
         v_valor_alocado
    FROM job             jo,
         contrato        ct,
         job_receita_ctr jr
   WHERE jr.job_receita_ctr_id = p_job_receita_ctr_id
     AND jr.job_id = jo.job_id
     AND jr.contrato_id = ct.contrato_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_RECEITA_CTR_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_contrato NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do contrato não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM job_receita_ctr
   WHERE job_receita_ctr_id = p_job_receita_ctr_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Exclusão de receita de contrato (Contrato: ' || to_char(v_numero_contrato) ||
                      ' - Valor: ' || moeda_mostrar(v_valor_alocado, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END receita_contrato_excluir;
 --
 --
 PROCEDURE valor_ajuste_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2008
  -- DESCRICAO: Inclusao de valor de ajuste do JOB (outras receitas/despesas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_data              IN VARCHAR2,
  p_descricao         IN ajuste_job.descricao%TYPE,
  p_valor_ajuste      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_valor_ajuste_final job.valor_ajuste_final%TYPE;
  v_ajuste_job_id      ajuste_job.ajuste_job_id%TYPE;
  v_valor_ajuste       ajuste_job.valor%TYPE;
  v_data               ajuste_job.data%TYPE;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(status)
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  IF TRIM(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_valor_ajuste) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Valor do ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  v_valor_ajuste := nvl(moeda_converter(p_valor_ajuste), 0);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_ajuste_job.nextval
    INTO v_ajuste_job_id
    FROM dual;
  --
  INSERT INTO ajuste_job
   (ajuste_job_id,
    job_id,
    usuario_id,
    data,
    descricao,
    valor)
  VALUES
   (v_ajuste_job_id,
    p_job_id,
    p_usuario_sessao_id,
    v_data,
    TRIM(p_descricao),
    v_valor_ajuste);
  --
  SELECT nvl(SUM(valor), 0)
    INTO v_valor_ajuste_final
    FROM ajuste_job
   WHERE job_id = p_job_id;
  --
  UPDATE job
     SET valor_ajuste_final = v_valor_ajuste_final
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Inclusão de valor de ajuste (' || TRIM(p_descricao) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_ajuste, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- valor_ajuste_adicionar
 --
 --
 PROCEDURE valor_ajuste_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2008
  -- DESCRICAO: Exclusao de valor de ajuste do JOB (outras receitas/despesas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_ajuste_job_id     IN ajuste_job.ajuste_job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_job_id             job.job_id%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_valor_ajuste_final job.valor_ajuste_final%TYPE;
  v_descricao          ajuste_job.descricao%TYPE;
  v_valor_ajuste       ajuste_job.valor%TYPE;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(aj.job_id)
    INTO v_job_id
    FROM ajuste_job aj,
         job        jo
   WHERE aj.ajuste_job_id = p_ajuste_job_id
     AND aj.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ajuste não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = v_job_id;
  --
  SELECT descricao,
         valor
    INTO v_descricao,
         v_valor_ajuste
    FROM ajuste_job
   WHERE ajuste_job_id = p_ajuste_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', v_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  DELETE FROM ajuste_job
   WHERE ajuste_job_id = p_ajuste_job_id;
  --
  SELECT nvl(SUM(valor), 0)
    INTO v_valor_ajuste_final
    FROM ajuste_job
   WHERE job_id = v_job_id;
  --
  UPDATE job
     SET valor_ajuste_final = v_valor_ajuste_final
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Exclusão de valor de ajuste (' || TRIM(v_descricao) || ' - Valor: ' ||
                      moeda_mostrar(v_valor_ajuste, 'S');
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END; -- valor_ajuste_excluir
 --
 --
 PROCEDURE checkin_fechar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/06/2008
  -- DESCRICAO: Fechamento do checkin do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/04/2009  Permitir fechamento de jobs cancelados.
  -- Silvia            26/01/2016  Tratamento de cronograma.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_status_checkin_job job.status_checkin%TYPE;
  v_status_checkin     VARCHAR2(10);
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_cronograma_id      item_crono.cronograma_id%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_checkin
    INTO v_numero_job,
         v_status_job,
         v_status_checkin_job
    FROM job
   WHERE job_id = p_job_id;
  --
  -- privilegio do grupo JOBEND
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ORCAMENTO_CF', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ' || v_lbl_job ||
                 ' deve estar concluído ou cancelado para que o check-in possa ser fechado.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_checkin_job = 'F'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O check-in desse ' || v_lbl_job || ' já se encontra fechado.';
   RAISE v_exception;
  END IF;
  --
  v_status_checkin := job_pkg.status_checkin_retornar(p_job_id);
  --
  IF v_status_checkin <> 'F'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem pendências de check-in nas Estimativas de Custos desse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_checkin      = 'F',
         data_status_checkin = trunc(SYSDATE)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
  --
  IF nvl(v_cronograma_id, 0) = 0
  THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            p_job_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- cria a atividade de fechamento de check-in
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'CHECKIN_CONC',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Fechamento do check-in';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- checkin_fechar
 --
 --
 PROCEDURE faturamento_fechar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/06/2008
  -- DESCRICAO: Fechamento do faturamento do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/04/2009  Permitir fechamento de jobs cancelados.
  -- Silvia            26/01/2016  Tratamento de cronograma.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_status_fatur_job job.status_fatur%TYPE;
  v_status_fatur     VARCHAR2(10);
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_cronograma_id    item_crono.cronograma_id%TYPE;
  v_item_crono_id    item_crono.item_crono_id%TYPE;
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_fatur
    INTO v_numero_job,
         v_status_job,
         v_status_fatur_job
    FROM job
   WHERE job_id = p_job_id;
  --
  -- privilegio do grupo JOBEND
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ORCAMENTO_FF', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O ' || v_lbl_job ||
                 ' deve estar concluído ou cancelado para que o faturamento possa ser fechado.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_fatur_job = 'F'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O faturamento desse ' || v_lbl_job || ' já se encontra fechado.';
   RAISE v_exception;
  END IF;
  --
  v_status_fatur := job_pkg.status_fatur_retornar(p_job_id);
  --
  IF v_status_fatur <> 'F'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem pendências de faturamento nas Estimativas de Custos desse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_fatur      = 'F',
         data_status_fatur = trunc(SYSDATE)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
  --
  IF nvl(v_cronograma_id, 0) = 0
  THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            p_job_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- cria a atividade de fechamento de faturamento
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'FATUR_CONC',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Fechamento do faturamento';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- faturamento_fechar
 --
 --
 PROCEDURE caminho_arq_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 09/02/2012
  -- DESCRICAO: Alteracao do caminho dos arquivos externos de um determinado job. 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN job.empresa_id%TYPE,
  p_job_id              IN job.job_id%TYPE,
  p_caminho_arq_externo IN job.caminho_arq_externo%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_caminho_arq_externo job.caminho_arq_externo%TYPE;
  v_desc_status         VARCHAR(100);
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_tam                 INTEGER;
  v_lbl_job             VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_ARQ_EXT_A', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_caminho_arq_externo := empresa_pkg.parametro_retornar(p_empresa_id, 'CAMINHO_ARQUIVOS_EXTERNOS');
  v_tam                 := length(v_caminho_arq_externo);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_status_job NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o caminho informado pertence a raiz do caminho configurado 
  -- no parametro.
  IF upper(v_caminho_arq_externo) <> substr(upper(TRIM(p_caminho_arq_externo)), 1, v_tam)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O caminho informado deve fazer parte do repositório ' || 'de arquivos grandes (' ||
                 v_caminho_arq_externo || ').';
   RAISE v_exception;
  END IF;
  --
  --------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET caminho_arq_externo = TRIM(p_caminho_arq_externo)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Mudança de caminho de arquivos externos (' || TRIM(p_caminho_arq_externo) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- caminho_arq_alterar
 --
 --
 PROCEDURE status_alterar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                ProcessMind     DATA: 15/10/2004
  -- DESCRICAO: Alteracao do status de um determinado job. 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/09/2011  Antes permitia apenas colocar o job em andamento. Alterado
  --                               para permitir demais mudancas exceto reabertura, pois isso
  --                               eh feito pela procedure reabir.
  -- Silvia            05/07/2012  Novo parametro p/ testar obrigatoriedade de briefing.
  -- Silvia            28/09/2012  Geracao de tarefa ao colocar job em andamento.
  -- Silvia            17/03/2014  Integracao no cancelamento.
  -- Silvia            23/01/2015  Deixa reabrir job com financeiro fechado, testando priv.
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            26/01/2016  Tratamento de cronograma.
  -- Silvia            22/03/2016  Novos parametros para tratar status auxiliar.
  -- Silvia            28/10/2016  Novo parametro motivo do cancelamento/evento
  -- Silvia            10/11/2016  Nao deixa concluir job com matriz incompleta.
  -- Silvia            23/03/2017  Grava data limite p/ distribuicao de job novo.
  -- Silvia            25/07/2017  Integracao Comunicacao Visual
  -- Silvia            22/11/2017  Tratamento de Briefing, Estimativa Horas e Cronograma
  --                               no caso de conclusao ou cancelamento do job.
  -- Silvia            06/04/2018  Novo parametro flag_commit.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_status            IN job.status%TYPE,
  p_status_aux_job_id IN status_aux_job.status_aux_job_id%TYPE,
  p_motivo            IN VARCHAR2,
  p_complemento       IN VARCHAR2,
  p_flag_commit       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_briefing_id           briefing.briefing_id%TYPE;
  v_numero_job            job.numero%TYPE;
  v_status_job_old        job.status%TYPE;
  v_desc_status_old       VARCHAR(100);
  v_data_dist_limite      job.data_dist_limite%TYPE;
  v_produto_cliente_id    job.produto_cliente_id%TYPE;
  v_motivo_cancel         job.motivo_cancel%TYPE;
  v_status_checkin        job.status_checkin%TYPE;
  v_status_fatur          job.status_fatur%TYPE;
  v_data_apont_fim        job.data_apont_fim%TYPE;
  v_data_prev_fim         job.data_prev_fim%TYPE;
  v_flag_usa_matriz_tjob  tipo_job.flag_usa_matriz%TYPE;
  v_flag_usa_matriz_emp   VARCHAR2(10);
  v_desc_status           VARCHAR(100);
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_lbl_job               VARCHAR2(100);
  v_lbl_jobs              VARCHAR2(100);
  v_lbl_briefs            VARCHAR2(100);
  v_lbl_prodcli           VARCHAR2(100);
  v_flag_briefing         VARCHAR2(10);
  v_flag_financeiro       VARCHAR2(10);
  v_flag_status_aux       VARCHAR2(10);
  v_flag_canc_auto        VARCHAR2(10);
  v_flag_impede_conc      VARCHAR2(10);
  v_cod_acao              tipo_acao.codigo%TYPE;
  v_cronograma_id         item_crono.cronograma_id%TYPE;
  v_item_crono_id         item_crono.item_crono_id%TYPE;
  v_status_aux_job_id     status_aux_job.status_aux_job_id%TYPE;
  v_status_aux_job_id_old status_aux_job.status_aux_job_id%TYPE;
  v_nome_status_aux       status_aux_job.nome%TYPE;
  v_flag_tem_motivo       evento.flag_tem_motivo%TYPE;
  --
 BEGIN
  v_qt                  := 0;
  v_lbl_job             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_prodcli         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_financeiro     := empresa_pkg.parametro_retornar(p_empresa_id, 'FINANCE');
  v_flag_briefing       := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_BRIEFING_OBRIGATORIO');
  v_flag_status_aux     := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_STATUS_AUX_JOB');
  v_flag_canc_auto      := empresa_pkg.parametro_retornar(p_empresa_id, 'CANCELAR_OSDOCTAR_JOBCANC');
  v_flag_impede_conc    := empresa_pkg.parametro_retornar(p_empresa_id, 'IMPEDIR_JOBCONC_OSDOCTAR');
  v_flag_usa_matriz_emp := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_MATRIZ');
  v_lbl_briefs          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_PLURAL');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
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
  SELECT jo.numero,
         jo.status,
         util_pkg.desc_retornar('status_job', jo.status),
         jo.produto_cliente_id,
         jo.motivo_cancel,
         jo.status_checkin,
         jo.status_fatur,
         jo.data_apont_fim,
         jo.data_prev_fim,
         jo.status_aux_job_id,
         tj.flag_usa_matriz
    INTO v_numero_job,
         v_status_job_old,
         v_desc_status_old,
         v_produto_cliente_id,
         v_motivo_cancel,
         v_status_checkin,
         v_status_fatur,
         v_data_apont_fim,
         v_data_prev_fim,
         v_status_aux_job_id_old,
         v_flag_usa_matriz_tjob
    FROM job      jo,
         tipo_job tj
   WHERE jo.job_id = p_job_id
     AND jo.empresa_id = p_empresa_id
     AND jo.tipo_job_id = tj.tipo_job_id;
  --
  IF p_status = 'ANDA' AND v_status_job_old = 'PREP'
  THEN
   v_cod_acao := 'APROVAR';
  ELSIF p_status = 'ANDA' AND v_status_job_old IN ('CONC', 'CANC')
  THEN
   v_cod_acao := 'REABRIR';
  ELSIF p_status = 'PREP' AND v_status_job_old = 'ANDA'
  THEN
   v_cod_acao := 'REPROVAR';
  ELSIF p_status = 'CONC'
  THEN
   v_cod_acao := 'CONCLUIR';
  ELSIF p_status = 'CANC'
  THEN
   v_cod_acao := 'CANCELAR';
  ELSE
   -- transicao nao prevista.
   -- registra como alteracao para nao dar erro.
   v_cod_acao := 'ALTERAR';
  END IF;
  --
  SELECT nvl(MAX(ev.flag_tem_motivo), 'N')
    INTO v_flag_tem_motivo
    FROM evento      ev,
         tipo_objeto tb,
         tipo_acao   ta
   WHERE ev.tipo_objeto_id = tb.tipo_objeto_id
     AND tb.codigo = 'JOB'
     AND ev.tipo_acao_id = ta.tipo_acao_id
     AND ta.codigo = v_cod_acao;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_status) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(descricao)
    INTO v_desc_status
    FROM dicionario
   WHERE tipo = 'status_job'
     AND codigo = p_status;
  --
  IF v_desc_status IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do status inválido (' || p_status || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S'
  THEN
   IF p_status = 'CONC'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_CONC', p_job_id, NULL, p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSIF p_status = 'CANC'
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_CANC', p_job_id, NULL, p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSIF p_status = 'ANDA' AND v_status_job_old IN ('CONC', 'CANC') AND
         (v_status_checkin = 'F' OR v_status_fatur = 'F')
   THEN
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_REAB', NULL, NULL, p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   ELSE
    IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_A', p_job_id, NULL, p_empresa_id) <> 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF; -- fim do IF p_flag_commit = 'S'
  --
  IF nvl(p_status_aux_job_id, 0) > 0
  THEN
   -- usa o que a interface passou, mesmo q o parametro esteja desligado
   v_status_aux_job_id := p_status_aux_job_id;
  END IF;
  --
  IF v_flag_status_aux = 'N'
  THEN
   -- sem status auxiliar
   IF v_status_job_old = p_status
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' já se encontra nesse status.';
    RAISE v_exception;
   END IF;
   --
   IF v_status_aux_job_id IS NULL
   THEN
    -- descobre o status auxiliar padrao para essa transicao.
    SELECT MAX(status_aux_job_id),
           MAX(nome)
      INTO v_status_aux_job_id,
           v_nome_status_aux
      FROM status_aux_job
     WHERE empresa_id = p_empresa_id
       AND cod_status_pai = p_status
       AND flag_padrao = 'S';
    --
    IF v_status_aux_job_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Status estendido padrão não encontrado para essa transição.';
     RAISE v_exception;
    END IF;
   END IF;
  ELSE
   -- com status auxiliar
   IF v_status_aux_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do novo status é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   -- verifica se eh compativel
   SELECT MAX(nome)
     INTO v_nome_status_aux
     FROM status_aux_job
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = p_status
      AND flag_ativo = 'S'
      AND status_aux_job_id = v_status_aux_job_id;
   --
   IF v_nome_status_aux IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Status estendido inválido para essa transição.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_aux_job_id = v_status_aux_job_id_old
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' já se encontra nesse status.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_status_aux = 'N' AND v_flag_tem_motivo = 'S'
  THEN
   IF TRIM(p_motivo) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do motivo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF length(TRIM(p_motivo)) > 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_complemento) > 800
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 800 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF p_status = 'PREP'
  THEN
   -- o job está voltando p/ em preparacao. Verifica se tem estimativa aprovada.
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O ' || v_lbl_job ||
                  ' não pode voltar p/ "Em Preparação" pois já existem Estimativas de Custos aprovadas.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job_old = 'PREP' AND p_status = 'ANDA'
  THEN
   IF nvl(v_produto_cliente_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do ' || v_lbl_prodcli || ' é obrigatório para ' || v_lbl_jobs ||
                  ' "em andamento".';
    RAISE v_exception;
   END IF;
   --
   IF v_flag_briefing = 'S'
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM briefing
     WHERE job_id = p_job_id
       AND status = 'APROV';
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O ' || v_lbl_job || ' não pode ser colocado "em andamento" pois não existem ' ||
                   v_lbl_briefs || ' aprovados.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF p_status = 'CONC'
  THEN
   IF v_status_job_old = 'CANC'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_lbl_job || ' "Cancelado" não pode ser concluído.';
    RAISE v_exception;
   END IF;
   --
   IF v_status_job_old = 'PREP'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_lbl_job || ' "Em Preparação" não pode ser concluído.';
    RAISE v_exception;
   END IF;
   --
   /* inibido em 06/04/2018 para deixar concluir
   IF v_flag_financeiro = 'S' THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM orcamento
       WHERE job_id = p_job_id
         AND status IN ('PREP','EMAPRO');
      --
      IF v_qt > 0 THEN
         p_erro_cod := '90000';
         p_erro_msg := 'O ' || v_lbl_job || ' não pode ser concluído pois existem ' || 
                       'estimativas em preparação ou em aprovação.';
         RAISE v_exception;
      END IF;
   END IF;
   */
   --
   IF v_flag_usa_matriz_tjob = 'S' AND v_flag_usa_matriz_emp = 'S'
   THEN
    SELECT MAX(briefing_id)
      INTO v_briefing_id
      FROM briefing
     WHERE job_id = p_job_id;
    --
    IF v_briefing_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ' || v_lbl_job || ' não possui ' || v_lbl_briefs || '.';
     RAISE v_exception;
    END IF;
    --
    briefing_pkg.dicion_verificar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_briefing_id,
                                  p_erro_cod,
                                  p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF p_status IN ('CONC', 'CANC')
  THEN
   -- muda a data limite de apontamento 
   v_data_apont_fim := trunc(SYSDATE);
  END IF;
  --
  IF p_status = 'ANDA' AND v_status_job_old IN ('CONC', 'CANC')
  THEN
   -- restaura a data limite de apontamento 
   v_data_apont_fim := v_data_prev_fim;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  IF p_status = 'CONC'
  THEN
   v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
   --
   IF nvl(v_cronograma_id, 0) = 0
   THEN
    -- cria o primeiro cronograma com as atividades obrigatorias
    cronograma_pkg.adicionar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             p_job_id,
                             v_cronograma_id,
                             p_erro_cod,
                             p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- cria a atividade de conclusao do job
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'JOB_CONC',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status            = p_status,
         data_status       = trunc(SYSDATE),
         data_apont_fim    = v_data_apont_fim,
         status_aux_job_id = v_status_aux_job_id
   WHERE job_id = p_job_id;
  --
  IF p_status = 'CONC'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM orcamento
    WHERE job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    -- conclusao de job sem estimativa.
    -- fecha tb check-in e faturamento.
    UPDATE job
       SET status_checkin      = 'F',
           data_status_checkin = trunc(SYSDATE),
           status_fatur        = 'F',
           data_status_fatur   = trunc(SYSDATE)
     WHERE job_id = p_job_id;
   END IF;
  END IF;
  --
  IF p_status = 'ANDA' AND v_status_job_old IN ('CONC', 'CANC')
  THEN
   UPDATE job
      SET status_checkin      = 'A',
          data_status_checkin = trunc(SYSDATE),
          status_fatur        = 'A',
          data_status_fatur   = trunc(SYSDATE)
    WHERE job_id = p_job_id;
  END IF;
  --
  IF p_status = 'CANC'
  THEN
   UPDATE job
      SET motivo_cancel = TRIM(p_motivo)
    WHERE job_id = p_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- calculo da data limite p/ distribuicao
  ------------------------------------------------------------
  IF p_status = 'ANDA' AND v_status_job_old = 'PREP'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE job_id = p_job_id
      AND flag_responsavel = 'S';
   --
   IF v_qt = 0
   THEN
    v_data_dist_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                              p_empresa_id,
                                                              SYSDATE,
                                                              'NUM_HORAS_DIST_JOB',
                                                              0);
    UPDATE job
       SET data_dist_limite = v_data_dist_limite
     WHERE job_id = p_job_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- cancelamento automatico de OS, Documento e Tarefa
  ------------------------------------------------------------
  IF p_status = 'CANC' AND v_flag_canc_auto = 'S'
  THEN
   ordem_servico_pkg.concluir_cancelar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       p_job_id,
                                       0,
                                       p_erro_cod,
                                       p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE documento
      SET status = 'NOK'
    WHERE job_id = p_job_id
      AND status = 'PEND';
   --
   UPDATE tarefa
      SET status      = 'CANC',
          data_status = SYSDATE
    WHERE job_id = p_job_id
      AND status IN ('EMEX', 'RECU');
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de Briefing, Estimativa de Horas e Cronograma
  ------------------------------------------------------------
  IF p_status IN ('CONC', 'CANC')
  THEN
   UPDATE briefing
      SET status      = 'PREP',
          data_status = SYSDATE
    WHERE job_id = p_job_id
      AND status IN ('REPROV', 'EMAPRO');
   --
   UPDATE job
      SET status_horas      = 'PREP',
          data_status_horas = SYSDATE
    WHERE job_id = p_job_id
      AND status_horas IN ('REPROV', 'EMAPRO');
   --
   UPDATE cronograma
      SET status      = 'PREP',
          data_status = SYSDATE
    WHERE job_id = p_job_id
      AND status IN ('REPROV', 'EMAPRO');
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF p_status = 'CANC'
  THEN
   it_controle_pkg.integrar('JOB_CANCELAR', p_empresa_id, p_job_id, NULL, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job_old = 'CANC'
  THEN
   it_controle_pkg.integrar('JOB_DESCANCELAR',
                            p_empresa_id,
                            p_job_id,
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
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF p_status = 'CONC'
  THEN
   it_controle_pkg.integrar('JOB_MCV_NOTIFICAR',
                            p_empresa_id,
                            p_job_id,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Status: ' || v_desc_status;
  --
  IF v_flag_status_aux = 'S'
  THEN
   v_compl_histor := v_compl_histor || ' - ' || v_nome_status_aux;
  END IF;
  --
  IF TRIM(p_complemento) IS NOT NULL
  THEN
   v_compl_histor := substr(v_compl_histor || ' (' || p_complemento || ')', 1, 1000);
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   v_cod_acao,
                   v_identif_objeto,
                   p_job_id,
                   v_compl_histor,
                   TRIM(p_motivo),
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
 END; -- status_alterar
 --
 --
 PROCEDURE status_tratar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/06/2008
  -- DESCRICAO: subrotina que trata/altera o status do check-in e do faturamento, no caso
  --   de jobs concluidos e fechados que tenham sofrido alguma alteracao em carta acordo,
  --   nota fiscal, sobra, abatimento, etc.    NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_tipo_status       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_status_checkin job.status_checkin%TYPE;
  v_status_fatur   job.status_fatur%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
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
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_status NOT IN ('CHE', 'FAT', 'ALL')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de status do ' || v_lbl_job || ' inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_checkin,
         status_fatur
    INTO v_numero_job,
         v_status_job,
         v_status_checkin,
         v_status_fatur
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_tipo_status IN ('CHE', 'ALL')
  THEN
   IF v_status_job = 'CONC' AND v_status_checkin = 'F'
   THEN
    UPDATE job
       SET status_checkin      = 'A',
           data_status_checkin = trunc(SYSDATE)
     WHERE job_id = p_job_id;
   END IF;
  END IF;
  --
  IF p_tipo_status IN ('FAT', 'ALL')
  THEN
   IF v_status_job = 'CONC' AND v_status_fatur = 'F'
   THEN
    UPDATE job
       SET status_fatur      = 'A',
           data_status_fatur = trunc(SYSDATE)
     WHERE job_id = p_job_id;
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
 END; -- status_tratar
 --
 --
 PROCEDURE reabrir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/06/2008
  -- DESCRICAO: reabertura de JOB concluído ou cancelado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/02/2014  Nao testa mais privilegios financeiros.
  -- Silvia            17/03/2014  Integracao no descancelamento.
  -- Silvia            23/03/2016  Tratamento do status auxiliar/estendido.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_status_new        job.status%TYPE;
  v_status_checkin    job.status_checkin%TYPE;
  v_status_fatur      job.status_fatur%TYPE;
  v_data_prev_fim     job.data_prev_fim%TYPE;
  v_status_aux_job_id job.status_aux_job_id%TYPE;
  v_exception         EXCEPTION;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_lbl_job           VARCHAR2(100);
  v_desc_status       VARCHAR2(100);
  v_desc_status_old   VARCHAR2(100);
  v_flag_financeiro   VARCHAR2(10);
  v_flag_status_aux   VARCHAR2(10);
  v_nome_status_aux   status_aux_job.nome%TYPE;
  --
 BEGIN
  v_qt              := 0;
  v_lbl_job         := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'FINANCE');
  v_flag_status_aux := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_STATUS_AUX_JOB');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_checkin,
         status_fatur,
         data_prev_fim
    INTO v_numero_job,
         v_status_job,
         v_status_checkin,
         v_status_fatur,
         v_data_prev_fim
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_status_job NOT IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não se encontra concluído ou cancelado.';
   RAISE v_exception;
  END IF;
  --
  v_status_new := 'ANDA';
  --
  v_desc_status_old := util_pkg.desc_retornar('status_job', v_status_job);
  v_desc_status     := util_pkg.desc_retornar('status_job', v_status_new);
  --
  -- verifica se o usuario tem privilegio para reabrir
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_REAB', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- status auxiliar/estendido
  ------------------------------------------------------------
  SELECT MAX(status_aux_job_id),
         MAX(nome)
    INTO v_status_aux_job_id,
         v_nome_status_aux
    FROM status_aux_job
   WHERE empresa_id = p_empresa_id
     AND cod_status_pai = v_status_new
     AND flag_padrao = 'S';
  --
  IF v_status_aux_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Status estendido padrão para o status ' || v_status_new || ' não foi encontrado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status              = v_status_new,
         data_status         = trunc(SYSDATE),
         status_checkin      = 'A',
         data_status_checkin = trunc(SYSDATE),
         status_fatur        = 'A',
         data_status_fatur   = trunc(SYSDATE),
         data_apont_fim      = v_data_prev_fim,
         status_aux_job_id   = v_status_aux_job_id
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF v_status_job = 'CANC'
  THEN
   it_controle_pkg.integrar('JOB_DESCANCELAR',
                            p_empresa_id,
                            p_job_id,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Status: ' || v_desc_status;
  --
  IF v_flag_status_aux = 'S'
  THEN
   v_compl_histor := v_compl_histor || ' - ' || v_nome_status_aux;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'REABRIR',
                   v_identif_objeto,
                   p_job_id,
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
 END reabrir;
 --
 --
 PROCEDURE concluir_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 19/04/2022
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a concluir 
  --     automaticamente jobs, caso o parametro esteja ligado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  IS
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_erro_cod          VARCHAR2(20);
  v_erro_msg          VARCHAR2(200);
  v_num_dias_conc_job NUMBER(10);
  v_empresa_id        empresa.empresa_id%TYPE;
  v_job_id            job.job_id%TYPE;
  v_status_new        job.status%TYPE;
  v_status_aux_job_id job.status_aux_job_id%TYPE;
  v_usuario_admin_id  usuario.usuario_id%TYPE;
  v_motivo            VARCHAR2(100);
  v_flag_impede_conc  VARCHAR2(100);
  v_processa          NUMBER(5);
  --
  CURSOR c_em IS
   SELECT empresa_id
     FROM empresa
    WHERE flag_ativo = 'S'
    ORDER BY empresa_id;
  --
  -- jobs a concluir 
  -- (por enquanto apenas em Andamento; se pegar tbm PREP,
  -- eles serao cancelados)
  CURSOR c_jo IS
   SELECT job_id,
          status
     FROM job
    WHERE empresa_id = v_empresa_id
      AND status = 'ANDA'
      AND trunc(data_prev_fim) + v_num_dias_conc_job < trunc(SYSDATE)
    ORDER BY job_id;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF v_usuario_admin_id IS NULL
  THEN
   v_erro_cod := '90000';
   v_erro_msg := 'Usuário administrador não encontrado.';
   RAISE v_exception;
  END IF;
  --
  v_motivo := '- concluído automaticamente devido ao prazo';
  --
  FOR r_em IN c_em
  LOOP
   v_empresa_id        := r_em.empresa_id;
   v_num_dias_conc_job := nvl(empresa_pkg.parametro_retornar(v_empresa_id, 'NUM_DIAS_CONC_JOB'), 0);
   v_flag_impede_conc  := empresa_pkg.parametro_retornar(v_empresa_id, 'IMPEDIR_JOBCONC_OSDOCTAR');
   --
   IF v_num_dias_conc_job > 0
   THEN
    FOR r_jo IN c_jo
    LOOP
     v_job_id := r_jo.job_id;
     --
     -- conclui jobs em andamento e cancela
     -- jobs em preparacao
     IF r_jo.status = 'ANDA'
     THEN
      v_status_new := 'CONC';
     ELSE
      v_status_new := 'CANC';
     END IF;
     --
     -- descobre o status auxiliar padrao para essa transicao.
     SELECT nvl(MAX(status_aux_job_id), 0)
       INTO v_status_aux_job_id
       FROM status_aux_job
      WHERE empresa_id = v_empresa_id
        AND cod_status_pai = v_status_new
        AND flag_padrao = 'S';
     --
     -- verificacao de outro parametro que pode impedir
     -- a conclusao do job.
     v_processa := 1;
     IF v_flag_impede_conc = 'S'
     THEN
      SELECT COUNT(*)
        INTO v_qt
        FROM tarefa
       WHERE job_id = v_job_id
         AND status NOT IN ('CONC', 'CANC', 'TEMP', 'EXEC');
      --
      IF v_qt > 0
      THEN
       -- job tem tarefa em andamento.
       -- pula o processamento
       v_processa := 0;
      END IF;
      --
      SELECT COUNT(*)
        INTO v_qt
        FROM ordem_servico
       WHERE job_id = v_job_id
         AND status NOT IN ('CONC', 'CANC', 'DESC');
      --
      IF v_qt > 0
      THEN
       -- job tem OS em andamento.
       -- pula o processamento
       v_processa := 0;
      END IF;
      --
      SELECT COUNT(*)
        INTO v_qt
        FROM documento
       WHERE job_id = v_job_id
         AND status NOT IN ('OK');
      --
      IF v_qt > 0
      THEN
       -- job tem documento em andamento.
       -- pula o processamento
       v_processa := 0;
      END IF;
     END IF;
     --
     IF v_processa = 1
     THEN
      job_pkg.status_alterar(v_usuario_admin_id,
                             v_empresa_id,
                             v_job_id,
                             v_status_new,
                             v_status_aux_job_id,
                             v_motivo,
                             NULL,
                             'N',
                             v_erro_cod,
                             v_erro_msg);
     END IF;
     --
     COMMIT;
    END LOOP;
   END IF;
  END LOOP;
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'job_pkg.concluir_automatico',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   ROLLBACK;
   v_erro_cod := SQLCODE;
   v_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'job_pkg.concluir_automatico',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END concluir_automatico;
 --
 --
 PROCEDURE concluir_em_massa
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/04/2018
  -- DESCRICAO: Conclusao/cancelamento em massa de JOBs em andamento ou em preparacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/10/2020  Troca da data_entrada pela data_prev_fim
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_data_de           IN VARCHAR2,
  p_data_ate          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_data_de           DATE;
  v_data_ate          DATE;
  v_status_aux_job_id job.status_aux_job_id%TYPE;
  v_motivo            historico.justificativa%TYPE;
  v_complemento       historico.complemento%TYPE;
  v_exception         EXCEPTION;
  --
  CURSOR c_jo IS
   SELECT job_id,
          decode(status, 'ANDA', 'CONC', 'PREP', 'CANC') AS status_para
     FROM job
    WHERE status IN ('ANDA', 'PREP')
      AND trunc(data_prev_fim) BETWEEN v_data_de AND v_data_ate
      AND empresa_id = p_empresa_id
    ORDER BY job_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CONC_MASSA_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_data_de) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_ate) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_de) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_de || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ate) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ate || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_de  := data_converter(p_data_de);
  v_data_ate := data_converter(p_data_ate);
  --
  IF v_data_de > v_data_ate
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data inicial não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_jo IN c_jo
  LOOP
   -- descobre o status auxiliar padrao para essa transicao.
   SELECT MAX(status_aux_job_id)
     INTO v_status_aux_job_id
     FROM status_aux_job
    WHERE empresa_id = p_empresa_id
      AND cod_status_pai = r_jo.status_para
      AND flag_padrao = 'S';
   --
   IF v_status_aux_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Status estendido padrão não encontrado para essa transição (' ||
                  r_jo.status_para || ').';
    RAISE v_exception;
   END IF;
   --
   IF r_jo.status_para = 'CANC'
   THEN
    v_motivo      := 'Conclusão/cancelamento em massa';
    v_complemento := 'Conclusão/cancelamento em massa';
   ELSE
    v_complemento := 'Conclusão/cancelamento em massa';
    v_motivo      := NULL;
   END IF;
   --
   job_pkg.status_alterar(p_usuario_sessao_id,
                          p_empresa_id,
                          r_jo.job_id,
                          r_jo.status_para,
                          v_status_aux_job_id,
                          v_motivo,
                          v_complemento,
                          'N',
                          p_erro_cod,
                          p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
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
 END concluir_em_massa;
 --
 --
 PROCEDURE desenderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/01/2017
  -- DESCRICAO: subrotina que desendereca um determinado usuario do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_numero_job     job.numero%TYPE;
  --
 BEGIN
  v_qt := 0;
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
  IF flag_validar(p_flag_pula_notif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pula notif inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe (' || to_char(p_job_id) || ').';
   RAISE v_exception;
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
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE job_id = p_job_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt > 0
  THEN
   DELETE FROM job_usuario
    WHERE job_id = p_job_id
      AND usuario_id = p_usuario_id;
   --                       
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := TRIM(p_complemento);
   v_justif_histor  := TRIM(p_justificativa);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'DESENDERECAR',
                    v_identif_objeto,
                    p_job_id,
                    v_compl_histor,
                    v_justif_histor,
                    p_flag_pula_notif,
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
   INSERT INTO notifica_usu_avulso
    (historico_id,
     usuario_id,
     papel_id,
     tipo_notifica)
   VALUES
    (v_historico_id,
     p_usuario_id,
     NULL,
     'PADRAO');
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
 END desenderecar_usuario;
 --
 --
 PROCEDURE resp_int_tratar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 04/08/2017
  -- DESCRICAO: subrotina que verifica se o usuario pode ser responsavel 
  --   interno e, caso o job nao tenha nenhum, marca como responsavel. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_job_id     IN job.job_id%TYPE,
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_empresa_id job.empresa_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao 
  ------------------------------------------------------------
  -- verifica se o job ja tem responsavel interno
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE job_id = p_job_id
     AND flag_responsavel = 'S';
  --
  IF v_qt = 0
  THEN
   -- job sem responsavel interno.
   -- verifica se esse usuario tem privilegio de responsavel interno
   SELECT empresa_id
     INTO v_empresa_id
     FROM job
    WHERE job_id = p_job_id;
   --
   IF usuario_pkg.priv_verificar(p_usuario_id, 'JOB_RESP_INT_V', NULL, NULL, v_empresa_id) = 1
   THEN
    UPDATE job_usuario
       SET flag_responsavel = 'S'
     WHERE job_id = p_job_id
       AND usuario_id = p_usuario_id;
   END IF;
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
 END resp_int_tratar;
 --
 --
 PROCEDURE enderecar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/07/2012
  -- DESCRICAO: subrotina que endereca um determinado usuario ao job, caso ele ainda nao 
  --   esteja enderecado. 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/01/2013  Novos parametros flag_commit e papel_id.
  -- Silvia            17/04/2014  Qdo o papel_id nao eh informado, pega papel enderecavel
  --                               (antes pegava qualquer um).
  -- Silvia            03/06/2015  Novo flag para fazer tb o co-enderecamento ou nao
  -- Silvia            04/09/2015  Geracao de evento desligada.
  -- Silvia            31/05/2016  Tratamento de responsavel interno.
  -- Silvia            11/10/2016  Preferencia pelo papel definido na regra do job.
  -- Silvia            16/01/2017  Geracao de evento ligada.
  --                               Novos parametros para receber complemento e justificativa.
  -- Silvia            27/11/2017  Flag ativo na regra.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_flag_commit       IN VARCHAR2,
  p_flag_coender      IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_justif_histor      historico.justificativa%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_cliente_id         job.cliente_id%TYPE;
  v_tipo_job_id        job.tipo_job_id%TYPE;
  v_numero_job         job.numero%TYPE;
  v_produto_cliente_id job.produto_cliente_id%TYPE;
  --
 BEGIN
  v_qt := 0;
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
  IF flag_validar(p_flag_coender) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag coender inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pula_notif) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pula notif inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe (' || to_char(p_job_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT cliente_id,
         tipo_job_id,
         produto_cliente_id,
         numero
    INTO v_cliente_id,
         v_tipo_job_id,
         v_produto_cliente_id,
         v_numero_job
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se o usuario ja esta enderecado no job
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario
   WHERE job_id = p_job_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0
  THEN
   -- usuario ainda nao esta enderecado nesse job.
   INSERT INTO job_usuario
    (job_id,
     usuario_id)
   VALUES
    (p_job_id,
     p_usuario_id);
   --
   historico_pkg.hist_ender_registrar(p_usuario_id, 'JOB', p_job_id, NULL, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- verifica se esse usuario pode ser resp interno e marca
   resp_int_tratar(p_job_id, p_usuario_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- geracao de evento 
   v_identif_objeto := to_char(v_numero_job);
   v_compl_histor   := TRIM(p_complemento);
   v_justif_histor  := TRIM(p_justificativa);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'JOB',
                    'ENDERECAR',
                    v_identif_objeto,
                    p_job_id,
                    v_compl_histor,
                    v_justif_histor,
                    p_flag_pula_notif,
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
   INSERT INTO notifica_usu_avulso
    (historico_id,
     usuario_id,
     papel_id,
     tipo_notifica)
   VALUES
    (v_historico_id,
     p_usuario_id,
     NULL,
     'PADRAO');
   --
   -- trata coenderecamento desse usuario
   IF p_flag_coender = 'S'
   THEN
    job_pkg.enderecar_solidario(p_usuario_sessao_id,
                                p_empresa_id,
                                p_job_id,
                                p_usuario_id,
                                p_erro_cod,
                                p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  ELSE
   -- o enderecamento ja existe.
   -- verifica se esse usuario pode ser resp interno e marca
   resp_int_tratar(p_job_id, p_usuario_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF; -- fim do IF v_qt = 0
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
 END enderecar_usuario;
 --
 --
 PROCEDURE enderecar_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/01/2013
  -- DESCRICAO: subrotina p/ Enderecamento automatico do JOB.
  --            NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/06/2015  Co-enderecamento
  -- Silvia            04/09/2015  Geracao de evento desligada.
  -- Silvia            16/01/2017  Geracao de evento ligada.
  -- Silvia            23/05/2017  Ajuste no enderecamento do usuario criador
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_tipo_job_id    tipo_job.tipo_job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_cliente_id     job.cliente_id%TYPE;
  v_tipo_job       tipo_job.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_lbl_un         VARCHAR2(100);
  v_achou_resp_int NUMBER(5);
  --
  CURSOR c_usu IS
  -- usuario com papel de criador do job com priv de resp interno
   SELECT 1 AS ordem,
          up.usuario_id,
          pa.papel_id,
          pa.nome AS nome_papel,
          pe.apelido AS nome_usuario,
          'CRIADOR' AS tipo_ender,
          'S' AS flag_responsavel
     FROM usuario_papel   up,
          papel           pa,
          pessoa          pe,
          papel_priv      pp1,
          privilegio      pr1,
          papel_priv      pp2,
          privilegio      pr2,
          papel_priv_tjob tj
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
         --AND pa.flag_ender = 'S'
      AND up.usuario_id = pe.usuario_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp1.papel_id
      AND pp1.privilegio_id = pr1.privilegio_id
      AND pr1.codigo = 'JOB_RESP_INT_V'
      AND up.papel_id = pp2.papel_id
      AND pp2.privilegio_id = pr2.privilegio_id
      AND pr2.codigo = 'JOB_I'
      AND pp2.papel_id = tj.papel_id
      AND pr2.privilegio_id = tj.privilegio_id
      AND tj.tipo_job_id = v_tipo_job_id
      AND rownum = 1
   UNION
   -- usuario com papel de criador do job SEM priv de resp interno (caso o select anterior
   -- nao tenha retornado registro).
   SELECT 2 AS ordem,
          up.usuario_id,
          pa.papel_id,
          pa.nome AS nome_papel,
          pe.apelido AS nome_usuario,
          'CRIADOR' AS tipo_ender,
          'N' AS flag_responsavel
     FROM usuario_papel   up,
          papel           pa,
          pessoa          pe,
          papel_priv      pp2,
          privilegio      pr2,
          papel_priv_tjob tj
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
         --AND pa.flag_ender = 'S'
      AND up.usuario_id = pe.usuario_id
      AND pa.empresa_id = p_empresa_id
      AND up.papel_id = pp2.papel_id
      AND pp2.privilegio_id = pr2.privilegio_id
      AND pr2.codigo = 'JOB_I'
      AND pp2.papel_id = tj.papel_id
      AND pr2.privilegio_id = tj.privilegio_id
      AND tj.tipo_job_id = v_tipo_job_id
      AND NOT EXISTS (SELECT 1
             FROM papel_priv pp1,
                  privilegio pr1
            WHERE up.papel_id = pp1.papel_id
              AND pp1.privilegio_id = pr1.privilegio_id
              AND pr1.codigo = 'JOB_RESP_INT_V')
      AND rownum = 1
   UNION
   -- usuarios com papeis autoenderecaveis
   SELECT 3 AS ordem,
          up.usuario_id,
          pa.papel_id,
          pa.nome AS nome_papel,
          pe.apelido AS nome_usuario,
          'PAPEL_AUTO' AS tipo_ender,
          'N' AS flag_responsavel
     FROM papel         pa,
          usuario_papel up,
          usuario       us,
          pessoa        pe
    WHERE pa.flag_auto_ender = 'S'
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = up.papel_id
      AND up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
   UNION
   -- usuarios enderecados por tipo de job
   SELECT 4 AS ordem,
          tj.usuario_id,
          0 AS papel_id,
          '' AS nome_papel,
          pe.apelido AS nome_usuario,
          'TIPO_JOB' AS tipo_ender,
          'N' AS flag_responsavel
     FROM tipo_job_usuario tj,
          usuario          us,
          pessoa           pe
    WHERE tj.tipo_job_id = v_tipo_job_id
      AND tj.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
   UNION
   -- usuarios da unidade de negocios do job
   SELECT 5 AS ordem,
          nu.usuario_id,
          0 AS papel_id,
          '' AS nome_papel,
          pe.apelido AS nome_usuario,
          'UNID_NEG' AS tipo_ender,
          'N' AS flag_responsavel
     FROM unidade_negocio_cli nc,
          unidade_negocio_usu nu,
          usuario             us,
          pessoa              pe
    WHERE nc.cliente_id = v_cliente_id
      AND nc.unidade_negocio_id = nu.unidade_negocio_id
      AND nu.usuario_id = us.usuario_id
      AND nu.flag_enderecar = 'S'
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
    ORDER BY 1;
  --
  CURSOR c_end IS
   SELECT usuario_id
     FROM job_usuario
    WHERE job_id = p_job_id;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_un  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_UNIDNEG_SINGULAR');
  --
  SELECT jo.tipo_job_id,
         jo.numero,
         tj.nome,
         jo.cliente_id
    INTO v_tipo_job_id,
         v_numero_job,
         v_tipo_job,
         v_cliente_id
    FROM job      jo,
         tipo_job tj
   WHERE jo.job_id = p_job_id
     AND jo.tipo_job_id = tj.tipo_job_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_achou_resp_int := 0;
  --
  -- endereca automaticamente usuarios ativos c/ papel auto-enderecavel
  -- mais os que foram definidos na configuracao de tipo de job 
  -- mais o criador do job
  FOR r_usu IN c_usu
  LOOP
   IF r_usu.ordem = 1
   THEN
    v_achou_resp_int := 1;
   END IF;
   --
   IF r_usu.ordem = 2 AND v_achou_resp_int = 1
   THEN
    -- pula o segundo select do UNION caso o primeiro tenha sido 
    -- encontrado, evitando enderecar o criador duas vezes.
    NULL;
   ELSE
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE job_id = p_job_id
       AND usuario_id = r_usu.usuario_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO job_usuario
      (job_id,
       usuario_id)
     VALUES
      (p_job_id,
       r_usu.usuario_id);
     --
     historico_pkg.hist_ender_registrar(r_usu.usuario_id,
                                        'JOB',
                                        p_job_id,
                                        NULL,
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     -- verifica se esse usuario/papel pode ser resp interno e marca
     resp_int_tratar(p_job_id, r_usu.usuario_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     -- geracao de evento (sem pular notif)
     v_identif_objeto := to_char(v_numero_job);
     v_compl_histor   := NULL;
     --
     IF r_usu.tipo_ender = 'CRIADOR'
     THEN
      v_compl_histor := r_usu.nome_usuario || '/' || r_usu.nome_papel || ' criou o ' || v_lbl_job;
     ELSIF r_usu.tipo_ender = 'TIPO_JOB'
     THEN
      v_compl_histor := r_usu.nome_usuario || ' endereçado automaticamente em função do Tipo de ' ||
                        v_lbl_job || ' ' || v_tipo_job;
     ELSIF r_usu.tipo_ender = 'PAPEL_AUTO'
     THEN
      v_compl_histor := r_usu.nome_usuario || '/' || r_usu.nome_papel ||
                        ' endereçado automaticamente em função do Papel';
     ELSIF r_usu.tipo_ender = 'UNID_NEG'
     THEN
      v_compl_histor := r_usu.nome_usuario || '/' || r_usu.nome_papel ||
                        ' endereçado automaticamente em função da ' || v_lbl_un;
     END IF;
     --
     v_justif_histor := 'Criação de ' || v_lbl_job;
     --
     evento_pkg.gerar(p_usuario_sessao_id,
                      p_empresa_id,
                      'JOB',
                      'ENDERECAR',
                      v_identif_objeto,
                      p_job_id,
                      v_compl_histor,
                      v_justif_histor,
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
     INSERT INTO notifica_usu_avulso
      (historico_id,
       usuario_id,
       papel_id,
       tipo_notifica)
     VALUES
      (v_historico_id,
       r_usu.usuario_id,
       r_usu.papel_id,
       'PADRAO');
    END IF;
   END IF; -- fim do IF r_usu.ordem = 2 AND v_achou_resp_int = 1
  END LOOP;
  --
  -- co-enderecamento
  FOR r_end IN c_end
  LOOP
   job_pkg.enderecar_solidario(p_usuario_sessao_id,
                               p_empresa_id,
                               p_job_id,
                               r_end.usuario_id,
                               p_erro_cod,
                               p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END enderecar_automatico;
 --
 --
 PROCEDURE enderecar_manual
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Enderecamento de usuarios do JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/12/2008  Novo atributo em job_usuario_papel (flag_comissionado).
  -- Silvia            27/10/2011  Novo parametro area_id (serve para alterar apenas os 
  --                               enderecamentos de uma determinada area).
  -- Silvia            06/05/2015  Teste de privilegio por area (priv_verificar)
  -- Silvia            03/06/2015  Co-enderecamento
  -- Silvia            16/01/2017  Geracao de evento padronizada com sub-rotinas.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_cliente_id     job.cliente_id%TYPE;
  v_status_job     job.status%TYPE;
  v_vetor_usuarios VARCHAR2(500);
  v_delimitador    CHAR(1);
  v_usuario_id     usuario.usuario_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_justif_histor  historico.justificativa%TYPE;
  v_apelido        pessoa.apelido%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
  CURSOR c_us IS
   SELECT usuario_id
     FROM job_usuario ju
    WHERE ju.job_id = p_job_id
      AND controle = 'DEL';
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(numero),
         MAX(cliente_id),
         MAX(status)
    INTO v_numero_job,
         v_cliente_id,
         v_status_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_numero_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ENDER_C', p_job_id, p_area_id, p_empresa_id) <> 1
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
  IF nvl(p_area_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A área não foi informada.';
   RAISE v_exception;
  END IF;
  --
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM area
     WHERE area_id = p_area_id
       AND empresa_id = p_empresa_id;
  --
    IF v_qt = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Essa área não existe ou não pertence a essa empresa.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  -- marca os enderecamentos atuais como candidatos a serem deletados 
  -- (apenas da area).
  UPDATE job_usuario ju
     SET controle = 'DEL'
   WHERE ju.job_id = p_job_id
     AND EXISTS (SELECT 1
            FROM usuario us
           WHERE us.area_id = p_area_id
             AND us.usuario_id = ju.usuario_id);
  --
  v_delimitador    := ',';
  v_vetor_usuarios := rtrim(p_vetor_usuarios);
  --
  -- loop por usuario no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id
      AND area_id = p_area_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) ||
                  ' ou não pertence a essa área (area_id = ' || to_char(p_area_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE job_id = p_job_id
      AND usuario_id = v_usuario_id;
   --
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    -- a subrotina marca esse usuario como responsavel, com co-ender, sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'S',
                              'N',
                              p_empresa_id,
                              p_job_id,
                              v_usuario_id,
                              v_apelido || ' endereçado manualmente',
                              'Endereçamento Manual',
                              p_erro_cod,
                              p_erro_msg);
    -- 
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- usuario JA enderecado 
    -- desmarca o controle de delecao
    UPDATE job_usuario
       SET controle = NULL
     WHERE job_id = p_job_id
       AND usuario_id = v_usuario_id;
   END IF;
  END LOOP;
  --
  --
  -- desendereca usuarios que nao vieram no vetor
  FOR r_us IN c_us
  LOOP
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = r_us.usuario_id;
   --
   -- desendereca o usuario, sem pula notif
   job_pkg.desenderecar_usuario(p_usuario_sessao_id,
                                'N',
                                'N',
                                p_empresa_id,
                                p_job_id,
                                r_us.usuario_id,
                                v_apelido || ' desendereçado manualmente',
                                'Desendereçamento Manual',
                                p_erro_cod,
                                p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
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
 END enderecar_manual;
 --
 --
 PROCEDURE enderecar_solidario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 01/06/2015
  -- DESCRICAO: subrotina que endereca solidarios de um determinado usuario ao job, caso eles 
  --   ainda nao estejam enderecados (co-enderecamento). NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/09/2015  Geracao de evento desligada.
  -- Silvia            21/07/2016  Novas possibilidades de regras (cliente, produto_cliente,
  --                               tipo_job).
  -- Silvia            16/01/2017  Geracao de evento ligada 
  -- Silvia            27/11/2017  Flag ativo na regra.
  -- Silvia            13/09/2019  Mudancas em co-enderecamento
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  -- Silvia            27/07/2023  Ajuste em complemento do historico
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_cliente_id         job.cliente_id%TYPE;
  v_produto_cliente_id job.produto_cliente_id%TYPE;
  v_tipo_job_id        job.tipo_job_id%TYPE;
  v_empresa_id         job.empresa_id%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_justif_evento      historico.justificativa%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_nome_usuario       pessoa.apelido%TYPE;
  --
  -- cursor de usuarios a serem coenderecados
  CURSOR c_co IS
   SELECT 1                   AS ordem,
          uc.usuario_id       AS usuario_co_id,
          pc.apelido          AS nome_usuario_co,
          rc.regra_coender_id
     FROM usuario_ender   ue,
          usuario_coender uc,
          regra_coender   rc,
          pessoa          pc,
          usuario         us
    WHERE ue.usuario_id = p_usuario_id
      AND ue.regra_coender_id = rc.regra_coender_id
      AND rc.flag_ativo = 'S'
      AND rc.empresa_id = v_empresa_id
      AND ue.regra_coender_id = uc.regra_coender_id
      AND uc.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND uc.usuario_id = pc.usuario_id
      AND (rc.cliente_id IS NULL OR rc.cliente_id = v_cliente_id)
      AND (rc.produto_cliente_id IS NULL OR rc.produto_cliente_id = v_produto_cliente_id)
      AND (rc.tipo_job_id IS NULL OR rc.tipo_job_id = v_tipo_job_id)
      AND (rc.grupo_id IS NULL OR EXISTS
           (SELECT 1
              FROM grupo_pessoa gp
             WHERE gp.grupo_id = rc.grupo_id
               AND gp.pessoa_id = v_cliente_id))
   UNION
   SELECT 2                   AS ordem,
          uc.usuario_id       AS usuario_co_id,
          pc.apelido          AS nome_usuario_co,
          rc.regra_coender_id
     FROM usuario_coender uc,
          regra_coender   rc,
          pessoa          pc,
          usuario         us
    WHERE uc.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND uc.usuario_id = pc.usuario_id
      AND uc.regra_coender_id = rc.regra_coender_id
      AND rc.flag_ativo = 'S'
      AND rc.empresa_id = v_empresa_id
      AND (rc.cliente_id IS NULL OR rc.cliente_id = v_cliente_id)
      AND (rc.produto_cliente_id IS NULL OR rc.produto_cliente_id = v_produto_cliente_id)
      AND (rc.tipo_job_id IS NULL OR rc.tipo_job_id = v_tipo_job_id)
      AND (rc.grupo_id IS NULL OR EXISTS
           (SELECT 1
              FROM grupo_pessoa gp
             WHERE gp.grupo_id = rc.grupo_id
               AND gp.pessoa_id = v_cliente_id))
      AND NOT EXISTS (SELECT 1
             FROM usuario_ender ue
            WHERE ue.regra_coender_id = rc.regra_coender_id)
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt           := 0;
  v_historico_id := NULL;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT numero,
         cliente_id,
         produto_cliente_id,
         tipo_job_id,
         empresa_id
    INTO v_numero_job,
         v_cliente_id,
         v_produto_cliente_id,
         v_tipo_job_id,
         v_empresa_id
    FROM job
   WHERE job_id = p_job_id;
  --
  SELECT MAX(apelido)
    INTO v_nome_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_co IN c_co
  LOOP
   -- verifica se o usuario ja esta enderecado 
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE job_id = p_job_id
      AND usuario_id = r_co.usuario_co_id;
   --
   IF v_qt = 0
   THEN
    -- usuario ainda nao esta enderecado nesse job.
    INSERT INTO job_usuario
     (job_id,
      usuario_id)
    VALUES
     (p_job_id,
      r_co.usuario_co_id);
    --
    historico_pkg.hist_ender_registrar(r_co.usuario_co_id,
                                       'JOB',
                                       p_job_id,
                                       NULL,
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- verifica se esse usuario pode ser resp interno e marca
    resp_int_tratar(p_job_id, r_co.usuario_co_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- geracao de evento (sem pular notif)
    v_identif_objeto := to_char(v_numero_job);
    IF r_co.ordem = 1
    THEN
     v_compl_histor := r_co.nome_usuario_co || ' co-endereçado com ' || v_nome_usuario ||
                       ' via Regra: ' || to_char(r_co.regra_coender_id);
    ELSIF r_co.ordem = 2
    THEN
     v_compl_histor := r_co.nome_usuario_co || ' co-endereçado via Regra: ' ||
                       to_char(r_co.regra_coender_id);
    END IF;
    v_justif_evento := 'Co-endereçamento';
    --
    evento_pkg.gerar(p_usuario_sessao_id,
                     p_empresa_id,
                     'JOB',
                     'ENDERECAR',
                     v_identif_objeto,
                     p_job_id,
                     v_compl_histor,
                     v_justif_evento,
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
    INSERT INTO notifica_usu_avulso
     (historico_id,
      usuario_id,
      papel_id,
      tipo_notifica)
    VALUES
     (v_historico_id,
      r_co.usuario_co_id,
      NULL,
      'PADRAO');
   END IF;
   --
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END enderecar_solidario;
 --
 --
 PROCEDURE enderecar_todos_usuarios
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/03/2021
  -- DESCRICAO: subrotina p/ enderecamento de todos os usuarios num determinado job
  --     NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  -- todos os usuarios ativos com papel enderecavel na empresa
  CURSOR c_us IS
   SELECT us.usuario_id
     FROM usuario us
    WHERE us.flag_ativo = 'S'
      AND EXISTS (SELECT 1
             FROM usuario_papel up,
                  papel         pa
            WHERE pa.empresa_id = p_empresa_id
              AND pa.flag_ender = 'S'
              AND pa.papel_id = up.papel_id
              AND up.usuario_id = us.usuario_id)
    ORDER BY 1;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_job_id, 0) > 0
  THEN
   -- veio o job. Endereca em todos os usuarios nesse job.
   FOR r_us IN c_us
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM job_usuario
     WHERE job_id = p_job_id
       AND usuario_id = r_us.usuario_id;
    --
    IF v_qt = 0
    THEN
     INSERT INTO job_usuario
      (job_id,
       usuario_id)
     VALUES
      (p_job_id,
       r_us.usuario_id);
     --
     historico_pkg.hist_ender_registrar(r_us.usuario_id,
                                        'JOB',
                                        p_job_id,
                                        NULL,
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     -- verifica se esse usuario/papel pode ser resp interno e marca
     resp_int_tratar(p_job_id, r_us.usuario_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
  END IF; -- fim do IF NVL(p_job_id,0)
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
 END enderecar_todos_usuarios;
 --
 --
 PROCEDURE task_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/08/2006
  -- DESCRICAO: Gera tasks de notificacao de enderecamento relacionadas a um job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_prioridade        IN task.prioridade%TYPE,
  p_vetor_papel_id    IN LONG,
  p_obs               IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_papel_id       papel.papel_id%TYPE;
  v_delimitador    CHAR(1);
  v_vetor_papel_id LONG;
  v_task_id        task.task_id%TYPE;
  v_tipo_objeto_id task.tipo_objeto_id%TYPE;
  v_usuario        pessoa.apelido%TYPE;
  v_desc_curta     task.desc_curta%TYPE;
  v_desc_detalhada task.desc_detalhada%TYPE;
  v_tipo_task      task.tipo_task%TYPE;
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status
    INTO v_numero_job,
         v_status_job
    FROM job j
   WHERE j.job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'ENDER_C', p_job_id, NULL, p_empresa_id) <> 1
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
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(p_obs) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto das observações não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_vetor_papel_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário indicar pelo menos um papel como responsável pela task.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_tipo_task      := 'JOB_ENDER_MSG';
  v_desc_curta     := 'Tomar conhecimento do Endereçamento do ' || v_lbl_job;
  v_desc_detalhada := rtrim(v_usuario || ' solicitou que os participantes tomem ' ||
                            'conhecimento do Endereçamento do ' || v_lbl_job || '. ' || p_obs);
  --
  v_delimitador    := ',';
  v_vetor_papel_id := p_vetor_papel_id;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_id)), 0) > 0
  LOOP
   v_papel_id := to_number(prox_valor_retornar(v_vetor_papel_id, v_delimitador));
   --
   task_pkg.adicionar(p_usuario_sessao_id,
                      p_empresa_id,
                      'N', -- flag_commit
                      p_job_id,
                      0, -- milestone_id
                      v_papel_id,
                      v_desc_curta,
                      v_desc_detalhada,
                      p_prioridade,
                      v_tipo_task,
                      v_task_id, -- output
                      p_erro_cod,
                      p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_job;
  v_compl_histor   := 'Geração de tasks de ' || v_lbl_job || ' (notificação de endereçamento)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- task_gerar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/11/2004
  -- DESCRICAO: Exclusão de JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/08/2006  Consistencia de job_peca
  -- Silvia            10/12/2008  Exclusao automatica de ajuste_job.
  -- Silvia            12/05/2009  Exclusao automatica de tarefa.
  -- Silvia            02/04/2013  Deixa excluir jobs em andamento.
  -- Silvia            03/05/2013  Exclusao automatica de hist_ender.
  -- Silvia            08/09/2016  Exclusao automatica de job_nitem_pdr.
  -- Silvia            06/02/2017  Permite excluir job com cronograma em preparacao.
  -- Silvia            09/10/2018  Remocao do modulo de casting.
  -- Silvia            03/10/2019  Eliminacao de job_usuario_papel
  -- Silvia            15/12/2020  Nao deixa excluir job com tarefa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_crono   cronograma.status%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
  v_lbl_briefs     VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt         := 0;
  v_lbl_job    := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs   := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_lbl_briefs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_BRIEFING_PLURAL');
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_E', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite a exclusão.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM briefing  br,
         os_evento oe
   WHERE br.job_id = p_job_id
     AND br.briefing_id = oe.briefing_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem eventos de Workflow associados a ' || v_lbl_briefs || ' desse ' ||
                 v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM documento
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem documentos associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_peca
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem peças associadas a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_job
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem milestones associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM nota_fiscal
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem notas fiscais associadas a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faturamento
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faturamentos associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Workflows associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_tipo_produto
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem tipos de produto associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*),
         MAX(status)
    INTO v_qt,
         v_status_crono
    FROM cronograma
   WHERE job_id = p_job_id;
  --
  IF v_qt > 2 OR v_status_crono <> 'PREP'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem cronogramas associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM adiant_desp
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem adiantamentos para despesas associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_job
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos associados a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_estim
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem estimativas de Workflow associadas a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE job_id = p_job_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Tasks associadas a esse ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_EXCLUIR', p_empresa_id, p_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
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
  DELETE FROM hist_ender
   WHERE tipo_objeto = 'JOB'
     AND objeto_id = p_job_id;
  DELETE FROM job_nitem_pdr
   WHERE job_id = p_job_id;
  DELETE FROM job_horas
   WHERE job_id = p_job_id;
  DELETE FROM job_usuario
   WHERE job_id = p_job_id;
  DELETE FROM ajuste_job
   WHERE job_id = p_job_id;
  DELETE FROM brief_area ba
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = ba.briefing_id);
  DELETE FROM brief_hist bh
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bh.briefing_id);
  DELETE FROM brief_atributo_valor ba
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = ba.briefing_id);
  DELETE FROM brief_dicion_valor ba
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = ba.briefing_id);
  DELETE FROM briefing
   WHERE job_id = p_job_id;
  DELETE FROM notifica_desliga
   WHERE job_id = p_job_id;
  --
  UPDATE item_crono ic
     SET item_crono_pai_id = NULL
   WHERE EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id);
  --
  DELETE FROM item_crono_pre ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono_dest ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono_dia ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id);
  --
  DELETE FROM cronograma
   WHERE job_id = p_job_id;
  --
  DELETE FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_job_id,
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
 PROCEDURE apagar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 24/11/2004
  -- DESCRICAO: apaga completamente um determinado JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/08/2006  Exclusao de job_peca
  -- Silvia            13/04/2007  Exclusao de orcamento
  -- Silvia            02/04/2008  Exclusao de sobra/abatimento
  -- Silvia            10/12/2008  Exclusao de ajuste/job
  -- Silvia            12/05/2009  Exclusao de tarefa.
  -- Silvia            04/01/2010  Exclusao de milestone_usuario.
  -- Silvia            12/03/2010  Ajuste na exclusao de OS.
  -- Silvia            03/05/2013  Exclusao de hist_ender.
  -- Silvia            18/03/2015  Exclusao de os_refacao.
  -- Silvia            14/05/2015  Exclusao de metadados de briefing
  -- Silvia            22/12/2015  Exclusao de estimativa de OS
  -- Silvia            08/09/2016  Exclusao de job_nitem_pdr e orcam_nitem_pdr.
  -- Silvia            18/10/2016  Exclusao de orcam_usuario.
  -- Silvia            25/07/2018  Exclusao de os_link.
  -- Silvia            03/10/2019  Eliminacao de job_usuario_papel
  -- Silvia            17/06/2020  Exclusao de arquivo de orcamento (estimativa)
  -- Silvia            24/07/2020  Recalculo da alocacao dos usuarios envolvidos
  -- Silvia            28/07/2020  Exclusao de tarefa_link, tarefa_tipo_produto
  -- Silvia            18/08/2020  Exclusao de os_usuario_data, tarefa_usuario_data
  -- Silvia            12/03/2021  Exclusao de parcela_nf
  -- Silvia            01/06/2022  Exclusao de orcam_aprov
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt              INTEGER;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_xml_atual       CLOB;
  v_usu_admin_id    usuario.usuario_id%TYPE;
  --
  CURSOR c_arq_doc IS
   SELECT ad.arquivo_id
     FROM arquivo_documento ad,
          documento         dc
    WHERE dc.job_id = p_job_id
      AND dc.documento_id = ad.documento_id;
  --
  CURSOR c_arq_tas IS
   SELECT aq.arquivo_id
     FROM arquivo_task aq,
          task         ta,
          milestone    mi
    WHERE mi.job_id = p_job_id
      AND mi.milestone_id = ta.milestone_id
      AND ta.task_id = aq.task_id;
  --
  CURSOR c_arq_tar IS
   SELECT ar.arquivo_id
     FROM tarefa         ta,
          arquivo_tarefa ar
    WHERE ta.job_id = p_job_id
      AND ta.tarefa_id = ar.tarefa_id;
  --
  CURSOR c_arq_os IS
   SELECT ao.arquivo_id
     FROM ordem_servico os,
          arquivo_os    ao
    WHERE os.job_id = p_job_id
      AND os.ordem_servico_id = ao.ordem_servico_id;
  --
  CURSOR c_arq_ca IS
   SELECT DISTINCT ac.arquivo_id
     FROM arquivo_carta ac,
          item_carta    ic,
          item          it
    WHERE it.job_id = p_job_id
      AND it.item_id = ic.item_id
      AND ic.carta_acordo_id = ac.carta_acordo_id;
  --
  CURSOR c_arq_nf IS
   SELECT DISTINCT an.arquivo_id
     FROM arquivo_nf an,
          item_nota  io,
          item       it
    WHERE it.job_id = p_job_id
      AND it.item_id = io.item_id
      AND io.nota_fiscal_id = an.nota_fiscal_id;
  --
  CURSOR c_arq_jo IS
   SELECT arquivo_id
     FROM arquivo_job
    WHERE job_id = p_job_id;
  --
  CURSOR c_arq_orcam IS
   SELECT arquivo_id
     FROM arquivo_orcamento ao,
          orcamento         oc
    WHERE oc.job_id = p_job_id
      AND oc.orcamento_id = ao.orcamento_id;
  --
  CURSOR c_item IS
   SELECT item_id
     FROM item
    WHERE job_id = p_job_id;
  --
  -- seleciona executores do item do cronograma
  CURSOR c_iu IS
   SELECT DISTINCT iu.usuario_id
     FROM item_crono_usu iu,
          item_crono     ic,
          cronograma     cr
    WHERE cr.job_id = p_job_id
      AND cr.cronograma_id = ic.cronograma_id
      AND ic.item_crono_id = iu.item_crono_id;
  --     
  -- seleciona executores da tarefa
  CURSOR c_ut IS
   SELECT tu.tarefa_id,
          tu.usuario_para_id,
          ta.data_inicio,
          ta.data_termino
     FROM tarefa_usuario tu,
          tarefa         ta
    WHERE ta.job_id = p_job_id
      AND ta.tarefa_id = tu.tarefa_id;
  --     
  -- seleciona executores da OS
  CURSOR c_uo IS
   SELECT ou.ordem_servico_id,
          ou.usuario_id,
          os.data_inicio,
          os.data_termino
     FROM os_usuario    ou,
          ordem_servico os
    WHERE os.job_id = p_job_id
      AND os.ordem_servico_id = ou.ordem_servico_id
      AND ou.tipo_ender = 'EXE';
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
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(usuario_id)
    INTO v_usu_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  SELECT numero,
         status
    INTO v_numero_job,
         v_status_job
    FROM job
   WHERE job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'JOB_X', p_job_id, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o job tem NF multijob
  SELECT COUNT(*)
    INTO v_qt
    FROM item_nota io1,
         item      it1
   WHERE it1.job_id = p_job_id
     AND it1.item_id = io1.item_id
     AND EXISTS (SELECT 1
            FROM item_nota io2,
                 item      it2
           WHERE io2.nota_fiscal_id = io1.nota_fiscal_id
             AND io2.item_id = it2.item_id
             AND it2.job_id <> it1.job_id);
  -- 
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job ||
                 ' não pode ser apagado pois existem notas fiscais multijob.';
   RAISE v_exception;
  END IF;
  --                   
  -- verifica se o job tem carta acordo multijob
  SELECT COUNT(*)
    INTO v_qt
    FROM item_carta ic1,
         item       it1
   WHERE it1.job_id = p_job_id
     AND it1.item_id = ic1.item_id
     AND EXISTS (SELECT 1
            FROM item_carta ic2,
                 item       it2
           WHERE ic2.carta_acordo_id = ic1.carta_acordo_id
             AND ic2.item_id = it2.item_id
             AND it2.job_id <> it1.job_id);
  -- 
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job ||
                 ' não pode ser apagado pois existem cartas acordo multijob.';
   RAISE v_exception;
  END IF;
  --
  SELECT MIN(ic.data_planej_ini),
         MAX(ic.data_planej_fim)
    INTO v_data_planej_ini,
         v_data_planej_fim
    FROM item_crono ic,
         cronograma cr
   WHERE cr.job_id = p_job_id
     AND cr.cronograma_id = ic.cronograma_id;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('JOB_EXCLUIR', p_empresa_id, p_job_id, NULL, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- exclusoes de arquivos
  ------------------------------------------------------------
  FOR r_arq_doc IN c_arq_doc
  LOOP
   DELETE FROM arquivo_documento
    WHERE arquivo_id = r_arq_doc.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_doc.arquivo_id;
  END LOOP;
  --
  FOR r_arq_tas IN c_arq_tas
  LOOP
   DELETE FROM arquivo_task
    WHERE arquivo_id = r_arq_tas.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tas.arquivo_id;
  END LOOP;
  --
  FOR r_arq_tar IN c_arq_tar
  LOOP
   DELETE FROM arquivo_tarefa
    WHERE arquivo_id = r_arq_tar.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_tar.arquivo_id;
  END LOOP;
  --
  FOR r_arq_os IN c_arq_os
  LOOP
   DELETE FROM arquivo_os
    WHERE arquivo_id = r_arq_os.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_os.arquivo_id;
  END LOOP;
  --
  FOR r_arq_ca IN c_arq_ca
  LOOP
   DELETE FROM arquivo_carta
    WHERE arquivo_id = r_arq_ca.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_ca.arquivo_id;
  END LOOP;
  --
  FOR r_arq_nf IN c_arq_nf
  LOOP
   DELETE FROM arquivo_nf
    WHERE arquivo_id = r_arq_nf.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_nf.arquivo_id;
  END LOOP;
  --
  FOR r_arq_jo IN c_arq_jo
  LOOP
   DELETE FROM arquivo_job
    WHERE arquivo_id = r_arq_jo.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_jo.arquivo_id;
  END LOOP;
  --
  FOR r_arq_orcam IN c_arq_orcam
  LOOP
   DELETE FROM arquivo_orcamento
    WHERE arquivo_id = r_arq_orcam.arquivo_id;
   --
   DELETE FROM arquivo
    WHERE arquivo_id = r_arq_orcam.arquivo_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- exclusoes dos usuarios executores de tarefa
  ------------------------------------------------------------
  DELETE FROM tarefa_usuario_data tu
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tu.tarefa_id);
  --
  FOR r_ut IN c_ut
  LOOP
   DELETE FROM tarefa_usuario
    WHERE tarefa_id = r_ut.tarefa_id
      AND usuario_para_id = r_ut.usuario_para_id;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(v_usu_admin_id,
                                         p_empresa_id,
                                         r_ut.usuario_para_id,
                                         r_ut.data_inicio,
                                         r_ut.data_termino,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- exclusoes dos usuarios executores de OS
  ------------------------------------------------------------
  DELETE FROM os_usuario_data ou
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ou.ordem_servico_id);
  --
  FOR r_uo IN c_uo
  LOOP
   DELETE FROM os_usuario
    WHERE ordem_servico_id = r_uo.ordem_servico_id
      AND usuario_id = r_uo.usuario_id
      AND tipo_ender = 'EXE';
   --
   cronograma_pkg.alocacao_usu_processar(v_usu_admin_id,
                                         p_empresa_id,
                                         r_uo.usuario_id,
                                         r_uo.data_inicio,
                                         r_uo.data_termino,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM os_usuario ou
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ou.ordem_servico_id);
  --
  ------------------------------------------------------------
  -- demais exclusoes
  ------------------------------------------------------------
  DELETE FROM task_hist_ciencia tc
   WHERE EXISTS (SELECT 1
            FROM task_hist th,
                 task      ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = th.task_id
             AND th.task_hist_id = tc.task_hist_id);
  --
  DELETE FROM task_hist th
   WHERE EXISTS (SELECT 1
            FROM task ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = th.task_id);
  --
  DELETE FROM task_coment tc
   WHERE EXISTS (SELECT 1
            FROM task ta
           WHERE ta.job_id = p_job_id
             AND ta.task_id = tc.task_id);
  --
  DELETE FROM task
   WHERE job_id = p_job_id;
  --
  DELETE FROM tipific_milestone tm
   WHERE EXISTS (SELECT 1
            FROM milestone mi
           WHERE mi.job_id = p_job_id
             AND mi.milestone_id = tm.milestone_id);
  --
  DELETE FROM milestone_usuario mu
   WHERE EXISTS (SELECT 1
            FROM milestone mi
           WHERE mi.job_id = p_job_id
             AND mi.milestone_id = mu.milestone_id);
  --
  UPDATE ordem_servico
     SET milestone_id         = NULL,
         ordem_servico_ori_id = NULL
   WHERE job_id = p_job_id;
  --
  UPDATE tarefa
     SET ordem_servico_id = NULL
   WHERE job_id = p_job_id;
  --
  DELETE FROM milestone
   WHERE job_id = p_job_id;
  --
  DELETE FROM documento
   WHERE job_id = p_job_id;
  DELETE FROM job_usuario
   WHERE job_id = p_job_id;
  DELETE FROM job_peca
   WHERE job_id = p_job_id;
  DELETE FROM apontam_hora
   WHERE job_id = p_job_id;
  DELETE FROM apontam_job
   WHERE job_id = p_job_id;
  --
  FOR r_item IN c_item
  LOOP
   -- guarda o job_id (caso NULL) para poder deletar a carta acordo
   UPDATE carta_acordo ca
      SET job_id = p_job_id
    WHERE job_id IS NULL
      AND EXISTS (SELECT 1
             FROM item_carta ic
            WHERE ic.item_id = r_item.item_id
              AND ic.carta_acordo_id = ca.carta_acordo_id);
   --
   -- guarda o job_id (caso NULL) para poder deletar a nota fiscal
   UPDATE nota_fiscal nf
      SET job_id = p_job_id
    WHERE job_id IS NULL
      AND EXISTS (SELECT 1
             FROM item_nota io
            WHERE io.item_id = r_item.item_id
              AND io.nota_fiscal_id = nf.nota_fiscal_id);
   --
   DELETE FROM parcela
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_hist
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_decup
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_nota
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_fatur
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_carta
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_sobra
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_abat
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item_adiant
    WHERE item_id = r_item.item_id;
   --
   DELETE FROM item
    WHERE item_id = r_item.item_id;
  END LOOP;
  --
  UPDATE ordem_servico
     SET os_evento_id = NULL
   WHERE job_id = p_job_id;
  --
  DELETE FROM os_evento oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_refacao oe
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oe.ordem_servico_id);
  --
  DELETE FROM os_atributo_valor oa
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oa.ordem_servico_id);
  --
  DELETE FROM os_tp_atributo_valor oa
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oa.ordem_servico_id);
  --
  DELETE FROM os_horas oh
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oh.ordem_servico_id);
  --
  DELETE FROM os_tipo_produto_ref ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM os_tipo_produto ot
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ot.ordem_servico_id);
  --
  DELETE FROM parcela_carta pc
   WHERE EXISTS (SELECT 1
            FROM carta_acordo ca
           WHERE ca.job_id = p_job_id
             AND ca.carta_acordo_id = pc.carta_acordo_id);
  --
  DELETE FROM email_carta ec
   WHERE EXISTS (SELECT 1
            FROM carta_acordo ca
           WHERE ca.job_id = p_job_id
             AND ca.carta_acordo_id = ec.carta_acordo_id);
  --
  DELETE FROM carta_fluxo_aprov cf
   WHERE EXISTS (SELECT 1
            FROM carta_acordo ca
           WHERE ca.job_id = p_job_id
             AND ca.carta_acordo_id = cf.carta_acordo_id);
  --
  DELETE FROM imposto_nota ip
   WHERE EXISTS (SELECT 1
            FROM nota_fiscal nf
           WHERE nf.job_id = p_job_id
             AND nf.nota_fiscal_id = ip.nota_fiscal_id);
  --
  DELETE FROM duplicata dp
   WHERE EXISTS (SELECT 1
            FROM nota_fiscal nf
           WHERE nf.job_id = p_job_id
             AND nf.nota_fiscal_id = dp.nota_fiscal_id);
  --
  DELETE FROM parcela_nf pa
   WHERE EXISTS (SELECT 1
            FROM nota_fiscal nf
           WHERE nf.job_id = p_job_id
             AND nf.nota_fiscal_id = pa.nota_fiscal_id);
  --
  DELETE FROM faturamento fa
   WHERE job_id = p_job_id
     AND EXISTS (SELECT 1
            FROM nota_fiscal nf
           WHERE nf.job_id = p_job_id
             AND nf.nota_fiscal_id = fa.nota_fiscal_sai_id);
  --
  DELETE FROM hist_ender hi
   WHERE hi.tipo_objeto = 'OS'
     AND EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = hi.objeto_id);
  --
  DELETE FROM hist_ender hi
   WHERE hi.tipo_objeto = 'TAR'
     AND EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = hi.objeto_id);
  --
  DELETE FROM tarefa_link tl
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tl.tarefa_id);
  --
  DELETE FROM tarefa_evento te
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = te.tarefa_id);
  --                 
  DELETE FROM tarefa_tp_atrib_valor tv
   WHERE EXISTS (SELECT 1
            FROM tarefa_tipo_produto tt,
                 tarefa              ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tt.tarefa_id
             AND tt.tarefa_tipo_produto_id = tv.tarefa_tipo_produto_id);
  --
  DELETE FROM tarefa_tipo_produto tt
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tt.tarefa_id);
  --
  DELETE FROM tarefa_afazer tf
   WHERE EXISTS (SELECT 1
            FROM tarefa ta
           WHERE ta.job_id = p_job_id
             AND ta.tarefa_id = tf.tarefa_id);
  --
  DELETE FROM brief_area ba
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = ba.briefing_id);
  -- 
  DELETE FROM brief_hist bh
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bh.briefing_id);
  --
  DELETE FROM brief_atributo_valor bv
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bv.briefing_id);
  --
  DELETE FROM brief_dicion_valor bv
   WHERE EXISTS (SELECT 1
            FROM briefing br
           WHERE br.job_id = p_job_id
             AND br.briefing_id = bv.briefing_id);
  --
  DELETE FROM devol_realiz dr
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = dr.adiant_desp_id);
  --
  DELETE FROM desp_realiz dr
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = dr.adiant_desp_id);
  --
  DELETE FROM adiant_realiz ar
   WHERE EXISTS (SELECT 1
            FROM adiant_desp ad
           WHERE ad.job_id = p_job_id
             AND ad.adiant_desp_id = ar.adiant_desp_id);
  --                 
  DELETE FROM os_fluxo_aprov fa
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = fa.ordem_servico_id);
  --                 
  DELETE FROM os_usuario_refacao ou
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ou.ordem_servico_id);
  --                 
  DELETE FROM os_link ol
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = ol.ordem_servico_id);
  --
  DELETE FROM os_afazer oa
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = oa.ordem_servico_id);
  --                 
  DELETE FROM os_negociacao og
   WHERE EXISTS (SELECT 1
            FROM ordem_servico os
           WHERE os.job_id = p_job_id
             AND os.ordem_servico_id = og.ordem_servico_id);
  --                  
  DELETE FROM orcam_nitem_pdr oi
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = oi.orcamento_id);
  --                  
  DELETE FROM orcam_usuario ou
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = ou.orcamento_id);
  --                  
  DELETE FROM orcam_fluxo_aprov oa
   WHERE EXISTS (SELECT 1
            FROM orcamento oc
           WHERE oc.job_id = p_job_id
             AND oc.orcamento_id = oa.orcamento_id);
  --
  UPDATE ordem_servico
     SET os_estim_id = NULL
   WHERE job_id = p_job_id;
  --
  DELETE FROM briefing
   WHERE job_id = p_job_id;
  DELETE FROM abatimento
   WHERE job_id = p_job_id;
  DELETE FROM sobra
   WHERE job_id = p_job_id;
  DELETE FROM carta_acordo
   WHERE job_id = p_job_id;
  DELETE FROM os_estim
   WHERE job_id = p_job_id;
  DELETE FROM ordem_servico
   WHERE job_id = p_job_id;
  DELETE FROM orcamento
   WHERE job_id = p_job_id;
  DELETE FROM nota_fiscal
   WHERE job_id = p_job_id;
  DELETE FROM faturamento
   WHERE job_id = p_job_id;
  DELETE FROM ajuste_job
   WHERE job_id = p_job_id;
  DELETE FROM tarefa
   WHERE job_id = p_job_id;
  DELETE FROM job_tipo_produto
   WHERE job_id = p_job_id;
  DELETE FROM job_horas
   WHERE job_id = p_job_id;
  DELETE FROM hist_ender
   WHERE tipo_objeto = 'JOB'
     AND objeto_id = p_job_id;
  DELETE FROM notifica_desliga
   WHERE job_id = p_job_id;
  DELETE FROM adiant_desp
   WHERE job_id = p_job_id;
  DELETE FROM job_nitem_pdr
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- recalculo das horas alocadas nos itens do cronograma
  ------------------------------------------------------------
  UPDATE item_crono_usu ip
     SET horas_diarias = 0,
         horas_totais  = 0
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --               
  FOR r_iu IN c_iu
  LOOP
   cronograma_pkg.alocacao_usu_processar(v_usu_admin_id,
                                         p_empresa_id,
                                         r_iu.usuario_id,
                                         v_data_planej_ini,
                                         v_data_planej_fim,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- exclusao dos cronogramas
  ------------------------------------------------------------
  UPDATE item_crono ic
     SET item_crono_pai_id = NULL
   WHERE EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id);
  --
  DELETE FROM item_crono_pre ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono_dest ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono_dia ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono_usu ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic,
                 cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
  --
  DELETE FROM item_crono ic
   WHERE EXISTS (SELECT 1
            FROM cronograma cr
           WHERE cr.job_id = p_job_id
             AND cr.cronograma_id = ic.cronograma_id);
  --
  DELETE FROM cronograma
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- exclusao do job
  ------------------------------------------------------------
  DELETE FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'APAGAR',
                   v_identif_objeto,
                   p_job_id,
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
 END apagar;
 --
 --
 PROCEDURE visualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/06/2008
  -- DESCRICAO: registra o evento de visualizacao do JOB.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero
    INTO v_numero_job
    FROM job
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB',
                   'VISUALIZAR',
                   v_identif_objeto,
                   p_job_id,
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
 END; -- visualizar
 --
 --
 PROCEDURE lido_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/12/2013
  -- DESCRICAO: marca o job como lido pelo usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_numero_job job.numero%TYPE;
  v_exception  EXCEPTION;
  v_lbl_job    VARCHAR2(100);
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_usuario
     SET flag_lido = 'S'
   WHERE job_id = p_job_id
     AND usuario_id = p_usuario_sessao_id;
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
 END lido_marcar;
 --
 --
 PROCEDURE nao_lido_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/12/2013
  -- DESCRICAO: marca o job como nao lido para os usuarios enderecados, dependendo do tipo.
  --   Se o usuario_sessao_id for passado, e pq a chamada eh via interface (marca apenas esse 
  --   usuario e faz commit).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_tipo              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_numero_job job.numero%TYPE;
  v_exception  EXCEPTION;
  v_lbl_job    VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo) IS NULL OR p_tipo NOT IN ('ENDER_TODOS', 'ENDER_BRIEF_C')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de ' || v_lbl_job || ' não lido inválido (' || p_tipo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) > 0
  THEN
   -- marca apenas o usuario informado
   UPDATE job_usuario
      SET flag_lido = 'N'
    WHERE job_id = p_job_id
      AND usuario_id = p_usuario_sessao_id;
  ELSIF p_tipo = 'ENDER_TODOS'
  THEN
   -- marca todos os usuarios enderecados no job
   UPDATE job_usuario
      SET flag_lido = 'N'
    WHERE job_id = p_job_id;
  ELSIF p_tipo = 'ENDER_BRIEF_C'
  THEN
   -- marca todos os usuarios enderecados que podem alterar briefing
   UPDATE job_usuario
      SET flag_lido = 'N'
    WHERE job_id = p_job_id
      AND usuario_pkg.priv_verificar(usuario_id, 'BRIEF_C', p_job_id, NULL, p_empresa_id) = 1;
  END IF;
  --
  IF nvl(p_usuario_sessao_id, 0) > 0
  THEN
   -- chamada via interface
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
 END nao_lido_marcar;
 --
 --
 PROCEDURE prox_numero_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/01/2013
  -- DESCRICAO: subrotina que retorna o proximo numero de job a ser usado na criacao 
  --   de job de um determinado cliente ou tipo financeiro. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/06/2018  Nova sequencia com tipo financeiro.
  -- Silvia            23/07/2018  Novo parametro de output tipo_num_job
  -- Ana Luiza         27/12/2023  Adicionado berificacao de limitacao caractere
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_cliente_id         IN job.cliente_id%TYPE,
  p_tipo_financeiro_id IN job.tipo_financeiro_id%TYPE,
  p_numero_job         OUT job.numero%TYPE,
  p_tipo_num_job       OUT job.tipo_num_job%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_padrao_numeracao_job VARCHAR2(40);
  v_numero_job           NUMBER(20);
  v_cod_job              pessoa.cod_job%TYPE;
  v_num_primeiro_job     pessoa.num_primeiro_job%TYPE;
  v_lbl_job              VARCHAR2(100);
  v_lbl_jobs             VARCHAR2(100);
  v_tam_cod_job          NUMBER(5);
  v_parametro_id         parametro.parametro_id%TYPE;
  v_tipo_num_job         job.tipo_num_job%TYPE;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  SELECT MAX(pa.parametro_id)
    INTO v_parametro_id
    FROM parametro         pa,
         empresa_parametro ep
   WHERE pa.nome = 'NUMERO_SEQUENCIAL_JOB'
     AND pa.parametro_id = ep.parametro_id
     AND ep.empresa_id = p_empresa_id;
  --
  IF v_parametro_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Parâmetro NUMERO_SEQUENCIAL_JOB não definido para essa empresa.';
   RAISE v_exception;
  END IF;
  --ALCBO_271223
  IF length(TRIM(p_numero_job)) > 20
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || CASE
                  WHEN v_lbl_job IS NOT NULL THEN
                   v_lbl_job
                  WHEN v_lbl_jobs IS NOT NULL THEN
                   v_lbl_jobs
                  ELSE
                   'job'
                 END || ' não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- consistencias
  ------------------------------------------------------------
  --
  v_padrao_numeracao_job := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_JOB');
  --
  IF v_padrao_numeracao_job NOT IN
     ('SEQUENCIAL_GERAL', 'SEQUENCIAL_POR_CLIENTE', 'SEQUENCIAL_COM_TIPO_FINANCEIRO') OR
     TRIM(v_padrao_numeracao_job) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Padrão de numeração de ' || v_lbl_job || ' inválido ou não definido (' ||
                 v_padrao_numeracao_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_padrao_numeracao_job = 'SEQUENCIAL_COM_TIPO_FINANCEIRO' AND nvl(p_tipo_financeiro_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo financeiro do ' || v_lbl_job ||
                 ' não foi definido, impedindo o uso do padrão de numeração (' ||
                 v_padrao_numeracao_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_padrao_numeracao_job = 'SEQUENCIAL_GERAL'
  THEN
   v_tipo_num_job := 'SEQ_GERAL';
  ELSIF v_padrao_numeracao_job = 'SEQUENCIAL_POR_CLIENTE'
  THEN
   v_tipo_num_job := 'SEQ_POR_CLI';
  ELSIF v_padrao_numeracao_job = 'SEQUENCIAL_COM_TIPO_FINANCEIRO'
  THEN
   v_tipo_num_job := 'SEQ_COM_TFI';
  END IF;
  --
  ------------------------------------------------------------
  -- SEQUENCIAL_GERAL
  ------------------------------------------------------------
  IF v_padrao_numeracao_job = 'SEQUENCIAL_GERAL'
  THEN
   SELECT nvl(to_number(ep.valor), 0) + 1
     INTO v_numero_job
     FROM empresa_parametro ep
    WHERE ep.empresa_id = p_empresa_id
      AND ep.parametro_id = v_parametro_id
      FOR UPDATE;
   /*   
   -- numero do job composto por 4 digitos (mascara 0000) ou mais
   SELECT NVL(MAX(TO_NUMBER(numero)),0) + 1
     INTO v_numero_job
     FROM job
    WHERE empresa_id = p_empresa_id
      AND inteiro_validar(numero) = 1;*/
   --
   IF length(v_numero_job) <= 4
   THEN
    p_numero_job := TRIM(to_char(v_numero_job, '0000'));
   ELSE
    p_numero_job := TRIM(to_char(v_numero_job));
   END IF;
   --
   UPDATE empresa_parametro
      SET valor = to_char(v_numero_job)
    WHERE empresa_id = p_empresa_id
      AND parametro_id = v_parametro_id;
  END IF;
  --
  ------------------------------------------------------------
  -- SEQUENCIAL_POR_CLIENTE
  ------------------------------------------------------------
  IF v_padrao_numeracao_job = 'SEQUENCIAL_POR_CLIENTE'
  THEN
   -- numero do job composto por letras com o codigo definido no cliente +
   -- 4 digitos (mascara 0000)
   SELECT TRIM(upper(cod_job)),
          nvl(num_primeiro_job, 1)
     INTO v_cod_job,
          v_num_primeiro_job
     FROM pessoa
    WHERE pessoa_id = p_cliente_id;
   --
   IF TRIM(v_cod_job) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse cliente não tem um código padrão definido para a criação de ' || v_lbl_jobs || '.';
    RAISE v_exception;
   END IF;
   --
   v_tam_cod_job := length(v_cod_job);
   --
   SELECT nvl(MAX(to_number(substr(numero, v_tam_cod_job + 1))), 0) + 1
     INTO v_numero_job
     FROM job
    WHERE empresa_id = p_empresa_id
      AND substr(numero, 1, v_tam_cod_job) = v_cod_job
      AND inteiro_validar(substr(numero, v_tam_cod_job + 1)) = 1
      AND tipo_num_job = 'SEQ_POR_CLI';
   --
   IF v_numero_job > v_num_primeiro_job
   THEN
    IF length(v_numero_job) <= 4
    THEN
     p_numero_job := v_cod_job || TRIM(to_char(v_numero_job, '0000'));
    ELSE
     p_numero_job := v_cod_job || TRIM(to_char(v_numero_job));
    END IF;
   ELSE
    IF length(v_num_primeiro_job) <= 4
    THEN
     p_numero_job := v_cod_job || TRIM(to_char(v_num_primeiro_job, '0000'));
    ELSE
     p_numero_job := v_cod_job || TRIM(to_char(v_num_primeiro_job));
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- SEQUENCIAL_COM_TIPO_FINANCEIRO
  ------------------------------------------------------------
  IF v_padrao_numeracao_job = 'SEQUENCIAL_COM_TIPO_FINANCEIRO'
  THEN
   -- numero do job composto por letras com o codigo definido no tipo financeiro +
   -- 4 digitos (mascara 0000)
   SELECT MAX(TRIM(upper(cod_job)))
     INTO v_cod_job
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = p_tipo_financeiro_id;
   --
   IF TRIM(v_cod_job) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tipo financeiro escolhido não tem um código padrão ' ||
                  'definido para compor a numeração do ' || v_lbl_job || '.';
    RAISE v_exception;
   END IF;
   --
   -- numero do job composto por 4 digitos (mascara 0000) ou mais
   SELECT nvl(to_number(ep.valor), 0) + 1
     INTO v_numero_job
     FROM empresa_parametro ep
    WHERE ep.empresa_id = p_empresa_id
      AND ep.parametro_id = v_parametro_id
      FOR UPDATE;
   --
   IF length(v_numero_job) <= 4
   THEN
    p_numero_job := v_cod_job || TRIM(to_char(v_numero_job, '0000'));
   ELSE
    p_numero_job := v_cod_job || TRIM(to_char(v_numero_job));
   END IF;
   --
   UPDATE empresa_parametro
      SET valor = to_char(v_numero_job)
    WHERE empresa_id = p_empresa_id
      AND parametro_id = v_parametro_id;
  END IF;
  --
  p_tipo_num_job := v_tipo_num_job;
  p_erro_cod     := '00000';
  p_erro_msg     := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_numero_job   := NULL;
   p_tipo_num_job := NULL;
   ROLLBACK;
  WHEN OTHERS THEN
   p_numero_job   := NULL;
   p_tipo_num_job := NULL;
   p_erro_cod     := SQLCODE;
   p_erro_msg     := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                            1,
                            200);
   ROLLBACK;
 END prox_numero_retornar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/01/2017
  -- DESCRICAO: Subrotina que gera o xml do job para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/01/2018  Grava area da estimativa de horas.
  -- Silvia            12/01/2021  Grava servico
  ------------------------------------------------------------------------------------------
 (
  p_job_id   IN job.job_id%TYPE,
  p_xml      OUT CLOB,
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_na IS
   SELECT na.codigo,
          na.nome,
          numero_mostrar(jn.valor_padrao, 6, 'N') valor_padrao,
          na.mod_calculo,
          na.ordem
     FROM job_nitem_pdr jn,
          natureza_item na
    WHERE na.natureza_item_id = jn.natureza_item_id
      AND jn.job_id = p_job_id
    ORDER BY na.ordem;
  --
  CURSOR c_ho IS
   SELECT ar.nome         AS area,
          ca.nome         AS cargo,
          jh.nivel,
          pu.apelido      AS usuario,
          jh.horas_planej
     FROM job_horas jh,
          cargo     ca,
          pessoa    pu,
          area      ar
    WHERE jh.job_id = p_job_id
      AND jh.cargo_id = ca.cargo_id(+)
      AND jh.usuario_id = pu.usuario_id(+)
      AND jh.area_id = ar.area_id(+)
    ORDER BY 1,
             2,
             3,
             4;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("job_id", jo.job_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("tipo_num_job", jo.tipo_num_job),
                   xmlelement("empresa_resp", pr.apelido),
                   xmlelement("solicitante", ps.apelido),
                   xmlelement("data_entrada", data_mostrar(jo.data_entrada)),
                   xmlelement("cliente", cl.apelido),
                   xmlelement("contato_cliente", co.apelido),
                   xmlelement("unidade_negocio", un.nome),
                   xmlelement("produto_cliente", pc.nome),
                   xmlelement("tipo_job", tj.nome),
                   xmlelement("servico", se.nome),
                   xmlelement("tipo_financeiro", tf.nome),
                   xmlelement("campanha", ca.nome),
                   xmlelement("estrategia", jo.estrat_job),
                   xmlelement("contrato", ct.numero),
                   xmlelement("data_apres_cliente", data_mostrar(jo.data_pri_aprov)),
                   xmlelement("data_golive", data_mostrar(jo.data_golive)),
                   xmlelement("data_prev_ini", data_mostrar(jo.data_prev_ini)),
                   xmlelement("data_prev_fim", data_mostrar(jo.data_prev_fim)),
                   xmlelement("tipo_data_prev", jo.tipo_data_prev),
                   xmlelement("data_apont_ini", data_mostrar(jo.data_apont_ini)),
                   xmlelement("data_apont_fim", data_mostrar(jo.data_apont_fim)),
                   xmlelement("complex_job", jo.complex_job),
                   xmlelement("budget", numero_mostrar(jo.budget, 2, 'S')),
                   xmlelement("receita_prevista", numero_mostrar(jo.receita_prevista, 2, 'S')),
                   xmlelement("empresa_fatur", pf.apelido),
                   xmlelement("pago_cliente", jo.flag_pago_cliente),
                   xmlelement("tem_bloqeio_negoc", jo.flag_bloq_negoc),
                   xmlelement("usa_bv_fornec", jo.flag_bv_fornec),
                   xmlelement("perc_bv", numero_mostrar(jo.perc_bv, 5, 'N')),
                   xmlelement("status_job", jo.status),
                   xmlelement("status_job_aux", st.nome),
                   xmlelement("data_status", data_mostrar(jo.data_status)),
                   xmlelement("status_checkin", jo.status_checkin),
                   xmlelement("status_fatur", jo.status_fatur),
                   xmlelement("cod_ext_job", jo.cod_ext_job),
                   xmlelement("usa_budget", jo.flag_usa_budget),
                   xmlelement("usa_receita_prevista", jo.flag_usa_receita_prev),
                   xmlelement("obriga_contrato", jo.flag_obriga_contrato))
    INTO v_xml
    FROM job             jo,
         pessoa          cl,
         pessoa          co,
         pessoa          ps,
         pessoa          pf,
         pessoa          pr,
         tipo_job        tj,
         tipo_financeiro tf,
         produto_cliente pc,
         status_aux_job  st,
         campanha        ca,
         contrato        ct,
         unidade_negocio un,
         servico         se
   WHERE jo.job_id = p_job_id
     AND jo.cliente_id = cl.pessoa_id
     AND jo.contato_id = co.pessoa_id(+)
     AND jo.tipo_job_id = tj.tipo_job_id
     AND jo.produto_cliente_id = pc.produto_cliente_id(+)
     AND jo.usuario_solic_id = ps.usuario_id(+)
     AND jo.emp_faturar_por_id = pf.pessoa_id(+)
     AND jo.emp_resp_id = pr.pessoa_id
     AND jo.tipo_financeiro_id = tf.tipo_financeiro_id(+)
     AND jo.status_aux_job_id = st.status_aux_job_id(+)
     AND jo.campanha_id = ca.campanha_id(+)
     AND jo.contrato_id = ct.contrato_id(+)
     AND jo.unidade_negocio_id = un.unidade_negocio_id(+)
     AND jo.servico_id = se.servico_id(+);
  --
  ------------------------------------------------------------
  -- monta INFORMACOES FINANCEIRAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_na IN c_na
  LOOP
   SELECT xmlagg(xmlelement("info_finan",
                            xmlelement("codigo", r_na.codigo),
                            xmlelement("nome", r_na.nome),
                            xmlelement("tipo", r_na.mod_calculo),
                            xmlelement("valor_padrao", r_na.valor_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("info_financeiras", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta ESTIMATIVA_HORAS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  SELECT xmlconcat(xmlelement("tem_aprov_estim", jo.flag_com_aprov_horas),
                   xmlelement("data_aprov_limite", data_mostrar(jo.data_aprov_horas_limite)),
                   xmlelement("responsavel", pa.apelido),
                   xmlelement("status", jo.status_horas),
                   xmlelement("data_status", data_hora_mostrar(jo.data_status_horas)),
                   xmlelement("usuario_status", ps.apelido),
                   xmlelement("motivo_status", jo.motivo_status_horas),
                   xmlelement("complemento_status", jo.compl_status_horas))
    INTO v_xml_aux1
    FROM job    jo,
         pessoa pa,
         pessoa ps
   WHERE jo.job_id = p_job_id
     AND jo.usu_autor_horas_id = pa.usuario_id(+)
     AND jo.usu_status_horas_id = ps.usuario_id(+);
  FOR r_ho IN c_ho
  LOOP
   SELECT xmlagg(xmlelement("estimativa",
                            xmlelement("area", r_ho.area),
                            xmlelement("cargo", r_ho.cargo),
                            xmlelement("nivel", r_ho.nivel),
                            xmlelement("usuario", r_ho.usuario),
                            xmlelement("horas", to_char(r_ho.horas_planej))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("estimativa_horas", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "job"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("job", v_xml))
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
 FUNCTION usuarios_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 01/12/2004
  -- DESCRICAO: retorna os apelidos dos usuarios ativos e enderecados ao job, que possuem
  --  determinado papel (o retorno e' feito em forma de vetor, separado por virgulas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id   IN job.job_id%TYPE,
  p_papel_id IN papel.papel_id%TYPE
 ) RETURN VARCHAR2 AS
  v_usuarios VARCHAR2(1000);
  v_qt       INTEGER;
  --
  CURSOR c_usuario IS
   SELECT pe.apelido
     FROM usuario     us,
          pessoa      pe,
          job_usuario ju
    WHERE ju.job_id = p_job_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
      AND EXISTS (SELECT 1
             FROM usuario_papel up
            WHERE up.usuario_id = ju.usuario_id
              AND up.papel_id = p_papel_id)
    ORDER BY upper(pe.apelido);
  --
  r_usuario c_usuario%ROWTYPE;
  --
 BEGIN
  v_usuarios := NULL;
  --
  FOR r_usuario IN c_usuario
  LOOP
   v_usuarios := v_usuarios || ', ' || r_usuario.apelido;
  END LOOP;
  --
  -- retira a primeira virgula
  v_usuarios := substr(v_usuarios, 3);
  --
  RETURN v_usuarios;
 EXCEPTION
  WHEN OTHERS THEN
   v_usuarios := 'ERRO';
   RETURN v_usuarios;
 END usuarios_retornar;
 --
 --
 FUNCTION menor_data_aprov_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/02/2007
  -- DESCRICAO: retorna a menor data de aprovacao dos itens aprovados de um determinado job,
  --  de acordo com o tipo de item especificado. O tipo pode ser:
  --  NPAR - itens nao parcelados,
  --  NLIB - itens nao liberados p/ fatur,
  --  LESP - itens em liberacao especial
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id    IN job.job_id%TYPE,
  p_tipo_item IN VARCHAR2
 ) RETURN DATE AS
  v_qt      INTEGER;
  v_retorno DATE;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_tipo_item = 'NPAR'
  THEN
   -- itens com parcelamento pendente
   SELECT MIN(data)
     INTO v_retorno
     FROM item      it,
          item_hist hi,
          orcamento oc
    WHERE it.job_id = p_job_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND it.flag_parcelado = 'N'
      AND it.item_id = hi.item_id
      AND hi.codigo = 'APROVACAO';
  END IF;
  --
  IF p_tipo_item = 'NLIB'
  THEN
   -- itens com liberacao fatur pendente
   SELECT MIN(data)
     INTO v_retorno
     FROM item      it,
          item_hist hi,
          orcamento oc
    WHERE it.job_id = p_job_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND it.flag_parcelado = 'S'
      AND it.status_fatur = 'NLIB'
      AND it.item_id = hi.item_id
      AND hi.codigo = 'APROVACAO';
  END IF;
  --
  IF p_tipo_item = 'LESP'
  THEN
   -- itens com liberacao especial pendente
   SELECT MIN(data)
     INTO v_retorno
     FROM item      it,
          item_hist hi,
          orcamento oc
    WHERE it.job_id = p_job_id
      AND it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND it.flag_parcelado = 'S'
      AND it.status_fatur = 'LESP'
      AND it.item_id = hi.item_id
      AND hi.codigo = 'APROVACAO';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END menor_data_aprov_retornar;
 --
 --
 FUNCTION nome_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/05/2008
  -- DESCRICAO: retorna o nome de um determinado job, concatenado com o nome do produto,
  --   quando existir.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt           INTEGER;
  v_nome         VARCHAR2(200);
  v_nome_produto produto_cliente.nome%TYPE;
  --
 BEGIN
  v_nome := NULL;
  --
  SELECT jo.nome,
         pc.nome
    INTO v_nome,
         v_nome_produto
    FROM job             jo,
         produto_cliente pc
   WHERE jo.job_id = p_job_id
     AND jo.produto_cliente_id = pc.produto_cliente_id(+);
  --
  IF v_nome_produto IS NOT NULL
  THEN
   -- so concatena o produto se ele nao aparecer no comeco do nome do job.
   IF TRIM(upper(v_nome)) NOT LIKE TRIM(upper(v_nome_produto)) || '%'
   THEN
    v_nome := TRIM(v_nome_produto) || ' - ' || TRIM(v_nome);
   END IF;
  END IF;
  --
  RETURN v_nome;
 EXCEPTION
  WHEN OTHERS THEN
   v_nome := 'ERRO';
   RETURN v_nome;
 END nome_retornar;
 --
 --
 FUNCTION valor_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor total previsto de um determinado job (orcamentos nao
  --   arquivados), de acordo com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/07/2008  Novas naturezas/tipos de calculo.
  -- Silvia            21/11/2008  Novo parametro para permitir somar apenas valores
  --                               de acordo com o status do orcamento.
  -- Silvia            28/11/2008  Nova natureza CUSTO_SALDO.
  -- Silvia            08/01/2018  Novas naturezas HONOR_OUT e ENCARGO_OUT.
  ------------------------------------------------------------------------------------------
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_natureza_item NOT IN ('CUSTO',
                             'CPMF',
                             'HONOR',
                             'ENCARGO',
                             'ENCARGO_HONOR',
                             'TOTAL_GERAL',
                             'TOTAL_FORNEC',
                             'PAGO_CLI',
                             'CUSTO_SALDO',
                             'HONOR_OUT',
                             'ENCARGO_OUT') OR TRIM(p_natureza_item) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_retornar;
 --
 --
 FUNCTION valor_custo_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/01/2018
  -- DESCRICAO: retorna o valor total do custo previsto de um determinado job (orcamentos nao
  --   arquivados), de acordo com o tipode item especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  p_job_id       IN job.job_id%TYPE,
  p_tipo_item    IN VARCHAR2,
  p_status_orcam IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_item IS NULL
  THEN
   IF p_status_orcam = 'APROV'
   THEN
    -- soma apenas valores de orcamentos aprovados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           orcamento oc
     WHERE it.job_id = p_job_id
       AND it.natureza_item = 'CUSTO'
       AND oc.status = 'APROV'
       AND it.orcamento_id = oc.orcamento_id;
   ELSIF p_status_orcam = 'TUDO'
   THEN
    -- soma valores de orcamentos em preparacao, prontos e aprovados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           orcamento oc
     WHERE it.job_id = p_job_id
       AND it.natureza_item = 'CUSTO'
       AND oc.status <> 'ARQUI'
       AND it.orcamento_id = oc.orcamento_id;
   END IF;
  END IF;
  --
  IF p_tipo_item IS NOT NULL
  THEN
   IF p_status_orcam = 'APROV'
   THEN
    -- soma apenas valores de orcamentos aprovados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           orcamento oc
     WHERE it.job_id = p_job_id
       AND it.tipo_item = p_tipo_item
       AND it.natureza_item = 'CUSTO'
       AND oc.status = 'APROV'
       AND it.orcamento_id = oc.orcamento_id;
   ELSIF p_status_orcam = 'TUDO'
   THEN
    -- soma valores de orcamentos em preparacao, prontos e aprovados
    SELECT nvl(SUM(it.valor_aprovado), 0)
      INTO v_retorno
      FROM item      it,
           orcamento oc
     WHERE it.job_id = p_job_id
       AND it.tipo_item = p_tipo_item
       AND it.natureza_item = 'CUSTO'
       AND oc.status <> 'ARQUI'
       AND it.orcamento_id = oc.orcamento_id;
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_custo_retornar;
 --
 --
 FUNCTION valor_realizado_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor realizado de um determinado job, de acordo
  --   com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/07/2008  Novas naturezas/tipos de calculo.
  -- Silvia            21/11/2008  Novo parametro para permitir somar apenas valores
  --                               de acordo com o status do orcamento.
  ------------------------------------------------------------------------------------------
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  --
  IF p_natureza_item NOT IN ('HONOR', 'TOTAL_GERAL', 'SALDO', 'BV_FAT', 'BV_ABA', 'PAGO_CLI') OR
     TRIM(p_natureza_item) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_realizado_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_realizado_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_realizado_retornar;
 --
 --
 FUNCTION valor_abat_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor de abatimentos de um determinado job, de acordo
  --   com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/11/2008  Novo parametro para permitir somar apenas valores
  --                               de acordo com o status do orcamento.
  -- Silvia            25/02/2010  Acrescentada a natureza CUSTO.
  ------------------------------------------------------------------------------------------
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_natureza_item NOT IN ('TOTAL_GERAL', 'CUSTO') OR TRIM(p_natureza_item) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_abat_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_abat_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_abat_retornar;
 --
 --
 FUNCTION valor_cred_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor de credito de um determinado job, de acordo
  --   com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/07/2008  Novas naturezas/tipos de calculo.
  -- Silvia            21/11/2008  Novo parametro para permitir somar apenas valores
  --                               de acordo com o status do orcamento.
  ------------------------------------------------------------------------------------------
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_natureza_item NOT IN ('TOTAL_GERAL') OR TRIM(p_natureza_item) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_cred_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_cred_retornar(orcamento_id, p_natureza_item, NULL)), 0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_cred_retornar;
 --
 --
 FUNCTION valor_outras_receitas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/04/2007
  -- DESCRICAO: retorna o valor de outras receitas de um determinado job,
  --   de acordo com os tipos de itens especificados nos parametros de entrada.
  --   ATENCAO: retorna apenas receitas pagas direto pela fonte (encargos e honorarios
  --   nao entram pois nao podem ser pagos diretamente).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/11/2008  Novo parametro para permitir somar apenas valores
  --                               de acordo com o status do orcamento.
  ------------------------------------------------------------------------------------------
  p_job_id        IN job.job_id%TYPE,
  p_natureza_item IN VARCHAR2,
  p_status_orcam  IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_natureza_item NOT IN ('TOTAL_GERAL') OR TRIM(p_natureza_item) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_outras_receitas_retornar(orcamento_id, p_natureza_item, NULL)),
              0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status = 'APROV';
   --
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT nvl(SUM(orcamento_pkg.valor_outras_receitas_retornar(orcamento_id, p_natureza_item, NULL)),
              0)
     INTO v_retorno
     FROM orcamento
    WHERE job_id = p_job_id
      AND status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_outras_receitas_retornar;
 --
 --
 FUNCTION valor_economia_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/03/2012
  -- DESCRICAO: retorna o valor da economia de um determinado job, de acordo
  --   com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  p_job_id       IN job.job_id%TYPE,
  p_tipo_item    IN VARCHAR2,
  p_status_orcam IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF TRIM(p_tipo_item) IS NOT NULL AND p_tipo_item NOT IN ('A', 'B', 'C')
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_status_orcam = 'APROV'
  THEN
   -- soma apenas valores de orcamentos aprovados
   SELECT SUM(orcamento_pkg.valor_realizado_retornar(o.orcamento_id, 'CUSTO', p_tipo_item) -
              orcamento_pkg.valor_geral_pend_retornar(o.orcamento_id, p_tipo_item) +
              orcamento_pkg.valor_retornar(o.orcamento_id, 'PAGO_CLI', p_tipo_item) +
              orcamento_pkg.valor_outras_receitas_retornar(o.orcamento_id, 'CUSTO', p_tipo_item) -
              orcamento_pkg.valor_retornar(o.orcamento_id, 'COM_NF', p_tipo_item))
     INTO v_retorno
     FROM orcamento o
    WHERE o.job_id = p_job_id
      AND o.status = 'APROV';
  ELSIF p_status_orcam = 'TUDO'
  THEN
   -- soma valores de orcamentos em preparacao, prontos e aprovados
   SELECT SUM(orcamento_pkg.valor_realizado_retornar(o.orcamento_id, 'CUSTO', p_tipo_item) -
              orcamento_pkg.valor_geral_pend_retornar(o.orcamento_id, p_tipo_item) +
              orcamento_pkg.valor_retornar(o.orcamento_id, 'PAGO_CLI', p_tipo_item) +
              orcamento_pkg.valor_outras_receitas_retornar(o.orcamento_id, 'CUSTO', p_tipo_item) -
              orcamento_pkg.valor_retornar(o.orcamento_id, 'COM_NF', p_tipo_item))
     INTO v_retorno
     FROM orcamento o
    WHERE o.job_id = p_job_id
      AND o.status <> 'ARQUI';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_economia_retornar;
 --
 --
 FUNCTION valor_custo_horas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 21/03/2012
  -- DESCRICAO: retorna o valor do custo das horas apontadas num determinado job, de acordo
  --   com o tipo especificado no parametro de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE,
  p_tipo   IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := 0;
  --
  IF TRIM(p_tipo) IS NULL OR p_tipo NOT IN ('REAL', 'AJUSTADO')
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo = 'REAL'
  THEN
   SELECT nvl(SUM(nvl(util_pkg.num_decode(ad.custo_hora, 'C06C35872C9B409A8AB38C7A7E360F3C'), 0) *
                  ah.horas),
              0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad
    WHERE ah.job_id = p_job_id
      AND ah.apontam_data_id = ad.apontam_data_id;
  ELSIF p_tipo = 'AJUSTADO'
  THEN
   SELECT nvl(SUM(nvl(util_pkg.num_decode(ad.custo_hora, 'C06C35872C9B409A8AB38C7A7E360F3C'), 0) *
                  ah.horas_ajustadas),
              0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad
    WHERE ah.job_id = p_job_id
      AND ah.apontam_data_id = ad.apontam_data_id;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 9999999;
   RETURN v_retorno;
 END valor_custo_horas_retornar;
 --
 --
 FUNCTION status_checkin_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/05/2008
  -- DESCRICAO: retorna o status "virtual" do checkin de um determinado job, com
  --   base nas estimativas. Usado para testar se um check-in pode ser realmente
  --   fechado. Retorno:
  --   A - aberto; F - fechado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno    VARCHAR2(10);
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_valor_pend NUMBER;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT nvl(SUM(orcamento_pkg.valor_geral_pend_retornar(orcamento_id, 'T')), 0)
    INTO v_valor_pend
    FROM orcamento
   WHERE job_id = p_job_id
     AND status <> 'ARQUI';
  --
  IF v_valor_pend > 0
  THEN
   v_retorno := 'A';
  ELSE
   v_retorno := 'F';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END status_checkin_retornar;
 --
 --
 FUNCTION status_fatur_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/05/2008
  -- DESCRICAO: retorna o status "virtual" do faturamento de um determinado job, com
  --   base nas estimativas. Usado para testar se um faturamento pode ser realmente
  --   fechado. Retorno:
  --   A - aberto; F - fechado
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno    VARCHAR2(10);
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_valor_pend NUMBER;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT nvl(SUM(faturamento_pkg.valor_orcam_retornar(orcamento_id, 'AFATURAR')), 0)
    INTO v_valor_pend
    FROM orcamento
   WHERE job_id = p_job_id
     AND status <> 'ARQUI';
  --
  IF v_valor_pend > 0
  THEN
   v_retorno := 'A';
  ELSE
   v_retorno := 'F';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END status_fatur_retornar;
 --
 --
 FUNCTION data_fech_fatur_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/05/2008
  -- DESCRICAO: retorna a data de fechamento do faturamento de um determinado job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN DATE AS
  v_retorno   DATE;
  v_data_aux  DATE;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF job_pkg.status_fatur_retornar(p_job_id) = 'F'
  THEN
   SELECT MAX(fa.data_ordem)
     INTO v_retorno
     FROM faturamento fa
    WHERE fa.job_id = p_job_id;
   --
   SELECT MAX(ab.data_entrada)
     INTO v_data_aux
     FROM abatimento ab
    WHERE ab.job_id = p_job_id;
   --
   IF v_retorno IS NULL OR v_data_aux > v_retorno
   THEN
    v_retorno := v_data_aux;
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_fech_fatur_retornar;
 --
 --
 FUNCTION horas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 17/01/2013
  -- DESCRICAO: retorna as horas gastas ou planejadas para um determinado job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/05/2020  Retirada do papel_id de job_horas
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE,
  p_nivel  IN usuario_cargo.nivel%TYPE,
  p_tipo   IN VARCHAR2
 ) RETURN NUMBER AS
  v_retorno   NUMBER;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_tipo NOT IN ('PLANEJ', 'GASTA') OR TRIM(p_tipo) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_nivel) IS NOT NULL AND util_pkg.desc_retornar('nivel_usuario', p_nivel) IS NULL
  THEN
   RAISE v_exception;
  END IF;
  --
  -------------------------------------------
  -- retorna horas planejadas para o job
  -------------------------------------------
  IF p_tipo = 'PLANEJ'
  THEN
   IF TRIM(p_nivel) IS NOT NULL
   THEN
    SELECT nvl(SUM(horas_planej), 0)
      INTO v_retorno
      FROM job_horas
     WHERE job_id = p_job_id
       AND nivel = p_nivel;
   ELSE
    SELECT nvl(SUM(horas_planej), 0)
      INTO v_retorno
      FROM job_horas
     WHERE job_id = p_job_id;
   END IF;
  END IF;
  --
  -------------------------------------------
  -- retorna horas gastas no job
  -------------------------------------------
  IF p_tipo = 'GASTA'
  THEN
   IF TRIM(p_nivel) IS NOT NULL
   THEN
    SELECT nvl(SUM(ah.horas), 0)
      INTO v_retorno
      FROM apontam_hora ah,
           apontam_data ad
     WHERE ah.job_id = p_job_id
       AND ah.apontam_data_id = ad.apontam_data_id
       AND ad.nivel = p_nivel;
   ELSE
    SELECT nvl(SUM(horas), 0)
      INTO v_retorno
      FROM apontam_hora
     WHERE job_id = p_job_id;
   END IF;
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END horas_retornar;
 --
 --
 FUNCTION usuario_solic_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/05/2008
  -- DESCRICAO: retorna o ID do usuario que criou/solicitou o job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN NUMBER AS
  v_qt         INTEGER;
  v_nome       VARCHAR2(200);
  v_usuario_id usuario.usuario_id%TYPE;
  --
 BEGIN
  v_usuario_id := NULL;
  --
  SELECT MAX(usuario_solic_id)
    INTO v_usuario_id
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_usuario_id IS NULL
  THEN
   SELECT MAX(hi.usuario_id)
     INTO v_usuario_id
     FROM historico   hi,
          evento      ev,
          tipo_objeto ob,
          tipo_acao   ac
    WHERE ob.codigo = 'JOB'
      AND ac.codigo = 'INCLUIR'
      AND ev.tipo_objeto_id = ob.tipo_objeto_id
      AND ev.tipo_acao_id = ac.tipo_acao_id
      AND ev.evento_id = hi.evento_id
      AND hi.objeto_id = p_job_id;
  END IF;
  --
  RETURN v_usuario_id;
 EXCEPTION
  WHEN OTHERS THEN
   v_usuario_id := NULL;
   RETURN v_usuario_id;
 END usuario_solic_retornar;
 --
 --
 FUNCTION sla_data_inicio_job_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Tiago Lima            ProcessMind                       DATA: 09/08/2017
  -- DESCRICAO: Retorna a data de inicio do job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN DATE IS
  --
  v_data_inicio_job os_evento.data_evento%TYPE;
 BEGIN
  --
  --Captura a menor data inicio planejado do job
  SELECT MIN(ic.data_planej_ini)
    INTO v_data_inicio_job
    FROM item_crono ic
   INNER JOIN cronograma cr
      ON ic.cronograma_id = cr.cronograma_id
   WHERE cr.job_id = p_job_id;
  --
  IF v_data_inicio_job IS NULL
  THEN
   SELECT MIN(oe.data_evento)
     INTO v_data_inicio_job
     FROM os_evento oe
    INNER JOIN ordem_servico o
       ON oe.ordem_servico_id = o.ordem_servico_id
    WHERE oe.flag_estim = 'N'
      AND oe.status_de = 'PREP'
      AND oe.status_para IN ('DIST', 'ACEI')
      AND o.job_id = p_job_id;
   --
   IF v_data_inicio_job IS NULL
   THEN
    SELECT data_entrada
      INTO v_data_inicio_job
      FROM job j
     WHERE j.job_id = p_job_id;
   END IF;
  END IF;
  --
  RETURN v_data_inicio_job;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data_inicio_job;
 END sla_data_inicio_job_retornar;
 --
 --
 FUNCTION sla_data_inicio_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna a data de inicio da SLA do Job para a Porto Seguro com base na 
  --            (1)data da última aprovação de estimativa de OS do Job, quando nula a 
  --            (2)data de início da primeira atividade do cronograma do Job, quando nula a 
  --            (3)data do primeiro envio de OS para a Área Executora, quando nula a
  --            (4)data de abertura do Job, quando nula
  --            (5)retorna null se o Job não existir
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN DATE IS
  --
  v_sla_data_inicio DATE;
 BEGIN
  --
  --(5)retorna null se o Job não existir
  --
  v_sla_data_inicio := NULL;
  --
  --(1)data da última aprovação de estimativa de OS do Job
  --
  IF v_sla_data_inicio IS NULL
  THEN
   SELECT MAX(oe.data_evento)
     INTO v_sla_data_inicio
     FROM os_evento oe
    INNER JOIN ordem_servico os
       ON oe.ordem_servico_id = os.ordem_servico_id
    WHERE oe.flag_estim = 'S'
      AND oe.status_de IN ('EMAP', 'EXEC')
      AND oe.status_para IN ('CONC', 'PREP')
      AND oe.cod_acao = 'APROVAR_EST'
      AND os.status <> 'CANC'
      AND os.job_id = p_job_id;
  END IF;
  --
  --(2)data de início da primeira atividade do Cronograma do Job
  --
  IF v_sla_data_inicio IS NULL
  THEN
   SELECT MIN(ic.data_planej_ini)
     INTO v_sla_data_inicio
     FROM item_crono ic
    INNER JOIN cronograma cr
       ON ic.cronograma_id = cr.cronograma_id
    WHERE cr.status <> 'ARQUI'
      AND cr.job_id = p_job_id;
  END IF;
  --
  --(3)data do primeiro envio de OS para a Área Executora
  --
  IF v_sla_data_inicio IS NULL
  THEN
   SELECT MIN(oe.data_evento)
     INTO v_sla_data_inicio
     FROM os_evento oe
    INNER JOIN ordem_servico o
       ON oe.ordem_servico_id = o.ordem_servico_id
    WHERE oe.flag_estim = 'N'
      AND oe.status_de = 'PREP'
      AND oe.status_para IN ('DIST', 'ACEI')
      AND o.status <> 'CANC'
      AND o.job_id = p_job_id;
  END IF;
  --
  --(4)data de abertura do Job
  --
  IF v_sla_data_inicio IS NULL
  THEN
   SELECT data_entrada
     INTO v_sla_data_inicio
     FROM job j
    WHERE j.job_id = p_job_id;
  END IF;
  --
  RETURN v_sla_data_inicio;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_sla_data_inicio;
 END sla_data_inicio_retornar;
 --
 --
 FUNCTION sla_data_inicio_ori_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna a origem da data de inicio da SLA do Job para a Porto Seguro
  --            que pode ser:
  --            (1)data da última aprovação de estimativa de OS do Job 
  --            (2)data de início da primeira atividade do Cronograma do Job 
  --            (3)data do primeiro envio de OS para a Área Executora
  --            (4)data de abertura do Job
  --            (5)o Job não existe
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN VARCHAR2 IS
  --
  v_sla_data_inicio_ori VARCHAR2(100);
  v_qt                  INT;
  v_data                DATE;
  --
 BEGIN
  --
  v_sla_data_inicio_ori := NULL;
  --
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job j
   WHERE j.job_id = p_job_id;
  --
  IF v_qt = 0
  THEN
   v_sla_data_inicio_ori := 'O Job não existe';
  END IF;
  --
  --(1)data da última aprovação de estimativa de OS do Job
  --
  IF v_sla_data_inicio_ori IS NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM os_evento oe
    INNER JOIN ordem_servico os
       ON oe.ordem_servico_id = os.ordem_servico_id
    WHERE oe.flag_estim = 'S'
      AND oe.status_de IN ('EMAP', 'EXEC')
      AND oe.status_para IN ('CONC', 'PREP')
      AND oe.cod_acao = 'APROVAR_EST'
      AND os.status <> 'CANC'
      AND os.job_id = p_job_id;
   --
   IF v_qt > 0
   THEN
    v_sla_data_inicio_ori := 'Data da Aprovação da Estimativa';
   END IF;
  END IF;
  --
  --(2)data de início da primeira atividade do Cronograma do Job
  --
  IF v_sla_data_inicio_ori IS NULL
  THEN
   SELECT MIN(ic.data_planej_ini)
     INTO v_data
     FROM item_crono ic
    INNER JOIN cronograma cr
       ON ic.cronograma_id = cr.cronograma_id
    WHERE cr.status <> 'ARQUI'
      AND cr.job_id = p_job_id;
   --
   IF v_data IS NOT NULL
   THEN
    v_sla_data_inicio_ori := 'Data de início do Cronograma do Job';
   END IF;
  END IF;
  --
  --(3)data do primeiro envio de OS para a Área Executora
  --
  IF v_sla_data_inicio_ori IS NULL
  THEN
   SELECT MIN(oe.data_evento)
     INTO v_data
     FROM os_evento oe
    INNER JOIN ordem_servico o
       ON oe.ordem_servico_id = o.ordem_servico_id
    WHERE oe.flag_estim = 'N'
      AND oe.status_de = 'PREP'
      AND oe.status_para IN ('DIST', 'ACEI')
      AND o.status <> 'CANC'
      AND o.job_id = p_job_id;
   --
   IF v_data IS NOT NULL
   THEN
    v_sla_data_inicio_ori := 'Data do envio da primeira OS';
   END IF;
  END IF;
  --
  --(4)data de abertura do Job
  --
  IF v_sla_data_inicio_ori IS NULL
  THEN
   v_sla_data_inicio_ori := 'Data de abertura do Job';
  END IF;
  --
  RETURN v_sla_data_inicio_ori;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_sla_data_inicio_ori;
 END sla_data_inicio_ori_retornar;
 --
 --
 FUNCTION sla_data_limite_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna a data limite do SLA da Porto Seguro para Término da Execução da 
  --            última iteração de Execução de OS no Job que pode ser:
  --            (1)Maior data limite de atividade de conclusão do Cronograma do Job
  --            (2)Maior data limite de qualquer atividade do  do Job
  --            (3)Data de Previsão de Fim do Job
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN DATE IS
  --
  v_data_limite DATE;
  --
 BEGIN
  --
  v_data_limite := NULL;
  --
  --(1)Maior data limite de atividade de conclusão do Cronograma do Job
  --
  SELECT MAX(ic.data_planej_fim)
    INTO v_data_limite
    FROM item_crono ic
   INNER JOIN cronograma cr
      ON ic.cronograma_id = cr.cronograma_id
   WHERE cr.job_id = p_job_id
     AND cr.status <> 'ARQUI'
     AND ic.cod_objeto = 'JOB_CONC';
  --
  --(2)Maior data limite de qualquer atividade do Cronograma do Job
  --
  IF v_data_limite IS NULL
  THEN
   SELECT MAX(ic.data_planej_fim)
     INTO v_data_limite
     FROM item_crono ic
    INNER JOIN cronograma cr
       ON ic.cronograma_id = cr.cronograma_id
    WHERE cr.job_id = p_job_id
      AND cr.status <> 'ARQUI';
  END IF;
  --
  --(3)Data de Previsão de Fim do Job
  --
  IF v_data_limite IS NULL
  THEN
   SELECT MAX(jo.data_prev_fim)
     INTO v_data_limite
     FROM job jo
    WHERE jo.job_id = p_job_id;
  END IF;
  --
  RETURN v_data_limite;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data_limite;
 END sla_data_limite_retornar;
 --
 --
 FUNCTION sla_data_limite_ori_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna a origem da data limite do SLA da Porto Seguro para Término da 
  --            Execução da última iteração de Execução de OS no Job que pode ser:
  --            (1)Maior data limite de atividade de conclusão do Cronograma do Job
  --            (2)Maior data limite de qualquer atividade do Cronograma do Job
  --            (3)Data de Previsão de Fim do Job
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/12/2017  Ajuste nos testes (ic.data_planej_fim IS NOT NULL)
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN VARCHAR2 IS
  --
  v_data_limite_ori VARCHAR2(100);
  v_qt              INT;
  --
 BEGIN
  --
  v_data_limite_ori := NULL;
  --
  v_qt := 0;
  --
  --(1)Maior data limite de atividade de conclusão do Cronograma do Job
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono ic
   INNER JOIN cronograma cr
      ON ic.cronograma_id = cr.cronograma_id
   WHERE cr.job_id = p_job_id
     AND cr.status <> 'ARQUI'
     AND ic.cod_objeto = 'JOB_CONC'
     AND ic.data_planej_fim IS NOT NULL;
  --
  IF v_qt > 0
  THEN
   v_data_limite_ori := 'data prevista para Conclusão do Job';
  END IF;
  --
  --(2)Maior data limite de qualquer atividade do Cronograma do Job
  --
  IF v_data_limite_ori IS NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono ic
    INNER JOIN cronograma cr
       ON ic.cronograma_id = cr.cronograma_id
    WHERE cr.job_id = p_job_id
      AND cr.status <> 'ARQUI'
      AND ic.data_planej_fim IS NOT NULL;
   --
   IF v_qt > 0
   THEN
    v_data_limite_ori := 'data prevista para conclusão da última Atividade do Job';
   END IF;
  END IF;
  --
  --(3)Data final do Período do Job
  --
  IF v_data_limite_ori IS NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job jo
    WHERE jo.job_id = p_job_id
      AND data_prev_fim IS NOT NULL;
   --
   IF v_qt > 0
   THEN
    v_data_limite_ori := 'Data final do Período do Job';
   END IF;
  END IF;
  --
  IF v_data_limite_ori IS NULL
  THEN
   v_data_limite_ori := 'Não se aplica';
  END IF;
  --
  RETURN v_data_limite_ori;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_data_limite_ori;
 END sla_data_limite_ori_retornar;
 --
 --
 FUNCTION sla_data_termino_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna a data de término ou data do cumprimento da SLA da Porto Seguro
  --            podendo conter as seguintes datas:
  --            (1)data do primeiro envio da OS para aprovacao na iteração de Execução
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/11/2017  Retirada de restricao do nro da refacao.
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN DATE IS
  --
  sla_data_termino os_evento.data_evento%TYPE;
  --
 BEGIN
  --
  sla_data_termino := NULL;
  --
  --(1)data do primeiro envio da OS para aprovacao na iteração de Execução
  --
  SELECT MIN(oe.data_evento)
    INTO sla_data_termino
    FROM os_evento oe
   INNER JOIN ordem_servico os
      ON oe.ordem_servico_id = os.ordem_servico_id
   WHERE oe.flag_estim = 'N'
     AND status_de IN ('EXEC', 'PREP')
     AND oe.status_para IN ('EMAP')
     AND os.status <> 'CANC'
     AND os.job_id = p_job_id;
  --
  RETURN sla_data_termino;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN sla_data_termino;
 END sla_data_termino_retornar;
 --
 --
 FUNCTION sla_job_no_prazo_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias            ProcessMind                       DATA: 17/08/2017
  -- DESCRICAO: Retorna se o job está ou não no prazo de acordo com as regras de SLA 
  --            da Porto Segugo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         24/11/2017  incluisão da verificação da aprovação da 
  --                               estimativa da OS 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN VARCHAR2 IS
  --
  v_job_no_prazo        VARCHAR2(100);
  v_data_termino        DATE;
  v_data_limite         DATE;
  v_job_status          job.status%TYPE;
  v_estimativa_aprovada NUMBER(20);
  --
 BEGIN
  --
  v_data_termino := sla_data_termino_retornar(p_job_id);
  --
  v_data_limite := sla_data_limite_retornar(p_job_id);
  --
  v_job_no_prazo := NULL;
  --
  SELECT COUNT(*)
    INTO v_estimativa_aprovada
    FROM os_evento oe
   INNER JOIN ordem_servico os
      ON oe.ordem_servico_id = os.ordem_servico_id
   WHERE oe.flag_estim = 'S'
     AND oe.status_de IN ('EMAP', 'EXEC')
     AND oe.status_para IN ('CONC', 'PREP')
     AND oe.cod_acao = 'APROVAR_EST'
     AND os.status <> 'CANC'
     AND os.job_id = p_job_id;
  --
  SELECT status
    INTO v_job_status
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_data_limite IS NOT NULL AND v_job_status <> 'CANC'
  THEN
   --
   --Para Jobs que possuem limite mas que ainda estão em andamento
   --assumir o dia de hoje para comparar com a data limite
   IF v_estimativa_aprovada > 0
   THEN
    --  
    IF v_data_termino IS NULL
    THEN
     IF v_job_status = 'CONC'
     THEN
      --para jobs concluídos e que não possuem OS concluídas, assumir "no prazo"
      v_job_no_prazo := 'SIM';
     ELSE
      --para jobs em andamento e que não possuem OS concluídas, pegar
      --a data de hoje como referência para comparar com a data término
      v_data_termino := trunc(SYSDATE);
     END IF;
    END IF;
    --
    IF v_job_no_prazo IS NULL
    THEN
     IF trunc(v_data_termino) > trunc(v_data_limite)
     THEN
      --
      v_job_no_prazo := 'NÃO';
      -- 
     ELSE
      --
      v_job_no_prazo := 'SIM';
      --
     END IF;
    END IF;
   ELSE
    --se a data limite não é nula e o Job não foi cancelado
    --mas a estimativa de OS não foi Aprovada
    v_job_no_prazo := 'Estimativa de Workflow não Aprovada';
   END IF;
   --
  ELSE
   --se a data limite é nula, não há como avaliar SLA ou
   --se o Job foi Cancelado, a verificação do prazo não se aplica
   v_job_no_prazo := 'Não se Aplica';
  END IF;
  --
  RETURN v_job_no_prazo;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_job_no_prazo;
 END sla_job_no_prazo_retornar;
 --
 --
 FUNCTION sla_num_dias_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dis            ProcessMind                       DATA: 18/08/2017
  -- DESCRICAO: Retorna o número de dias de prazo para execução das OS do Job de 
  --            acordo com a SLA POrto Seguro
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (p_job_id IN job.job_id%TYPE) RETURN INT IS
  -- 
  v_num_dias    INT;
  v_usuario_id  usuario.usuario_id%TYPE;
  v_data_inicio DATE;
  v_data_limite DATE;
  --
 BEGIN
  --
  v_num_dias := 0;
  --
  v_data_inicio := sla_data_inicio_retornar(p_job_id);
  --
  v_data_limite := sla_data_limite_retornar(p_job_id);
  --
  SELECT MIN(usuario_id)
    INTO v_usuario_id
    FROM job_usuario
   WHERE flag_responsavel = 'S'
     AND job_id = p_job_id;
  --
  IF v_usuario_id IS NULL
  THEN
   SELECT MIN(usuario_id)
     INTO v_usuario_id
     FROM job_usuario
    WHERE job_id = p_job_id;
  END IF;
  --
  IF v_data_inicio IS NOT NULL AND v_data_limite IS NOT NULL
  THEN
   v_num_dias := feriado_pkg.qtd_dias_uteis_retornar(v_usuario_id, v_data_inicio, v_data_limite) + 1;
  END IF;
  --
  IF v_num_dias > 99999
  THEN
   v_num_dias := 99999;
  END IF;
  --
  RETURN v_num_dias;
  --
 EXCEPTION
  WHEN OTHERS THEN
   RETURN v_num_dias;
 END sla_num_dias_retornar;
 --
--
END; -- JOB_PKG

/
