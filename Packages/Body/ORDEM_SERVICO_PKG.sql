--------------------------------------------------------
--  DDL for Package Body ORDEM_SERVICO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ORDEM_SERVICO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/10/2007
  -- DESCRICAO: Inclusão de ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/04/2010  O privilegio da OS passou a usar o enderecamento do JOB.
  -- Silvia            19/06/2012  Novo atributo em OS: tamanho
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS. Numero de OS unico
  --                               por job e nao mais por tipo. Novos vetores p/ associar
  --                               tipo de produto.
  -- Silvia            18/11/2014  Tamanho criado com NULL ao inves de P.
  -- Silvia            18/03/2015  Tabela os_refacao.
  -- Silvia            09/12/2015  Novo parametro flag_com_estim.
  -- Silvia            14/01/2016  Novo parametro item_crono_id (abertura atraves do crono)
  -- Silvia            31/03/2016  Copia nome e data da atividade do cronograma (se existir)
  -- Silvia            09/08/2017  Verifica responsavel interno do job (se necessario)
  -- Silvia            29/03/2018  Atualizacoes automaticas com base no item_crono.
  -- Silvia            29/03/2018  Horas estimadas na execucao (os_usuario).
  -- Silvia            25/09/2019  Troca do nome de OS para Workflow.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  -- Silvia            28/01/2020  Copia da equipe da atividade do cronograma para a OS.
  -- Silvia            12/08/2020  Novos atributos data_inicio e data_termino. Nova tabela
  --                               os_usuario_data.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN ordem_servico.job_id%TYPE,
  p_milestone_id           IN ordem_servico.milestone_id%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_descricao              IN ordem_servico.descricao%TYPE,
  p_data_solicitada        IN VARCHAR2,
  p_hora_solicitada        IN VARCHAR2,
  p_texto_os               IN ordem_servico.texto_os%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_tp_id            IN VARCHAR2,
  p_vetor_tp_compl         IN VARCHAR2,
  p_vetor_tp_desc          IN VARCHAR2,
  p_item_crono_id          IN item_crono.item_crono_id%TYPE,
  p_flag_com_estim         IN VARCHAR2,
  p_ordem_servico_id       OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                       INTEGER;
  v_identif_objeto           historico.identif_objeto%TYPE;
  v_compl_histor             historico.complemento%TYPE;
  v_historico_id             historico.historico_id%TYPE;
  v_exception                EXCEPTION;
  v_ordem_servico_id         ordem_servico.ordem_servico_id%TYPE;
  v_numero_os                ordem_servico.numero%TYPE;
  v_numero_os_aux            ordem_servico.numero%TYPE;
  v_numero_os_char           VARCHAR2(50);
  v_data_solicitada          ordem_servico.data_solicitada%TYPE;
  v_data_interna             ordem_servico.data_interna%TYPE;
  v_data_inicio              ordem_servico.data_inicio%TYPE;
  v_data_termino             ordem_servico.data_termino%TYPE;
  v_descricao                ordem_servico.descricao%TYPE;
  v_tipo_financeiro_id       ordem_servico.tipo_financeiro_id%TYPE;
  v_demanda                  ordem_servico.demanda%TYPE;
  v_data_demanda             ordem_servico.data_demanda%TYPE;
  v_tamanho                  ordem_servico.tamanho%TYPE;
  v_acao_executada           ordem_servico.acao_executada%TYPE;
  v_numero_job               job.numero%TYPE;
  v_status_job               job.status%TYPE;
  v_emp_resp_id              job.emp_resp_id%TYPE;
  v_tipo_os_desc             tipo_os.nome%TYPE;
  v_tipo_os_cod              tipo_os.codigo%TYPE;
  v_flag_tem_itens           tipo_os.flag_tem_itens%TYPE;
  v_flag_tem_corpo           tipo_os.flag_tem_corpo%TYPE;
  v_flag_faixa_aprov         tipo_os.flag_faixa_aprov%TYPE;
  v_flag_tem_estim           tipo_os.flag_tem_estim%TYPE;
  v_flag_estim_custo         tipo_os.flag_estim_custo%TYPE;
  v_flag_estim_prazo         tipo_os.flag_estim_prazo%TYPE;
  v_flag_estim_arq           tipo_os.flag_estim_arq%TYPE;
  v_flag_estim_horas_usu     tipo_os.flag_estim_horas_usu%TYPE;
  v_flag_estim_obs           tipo_os.flag_estim_obs%TYPE;
  v_flag_exec_estim          tipo_os.flag_exec_estim%TYPE;
  v_acoes_executadas         tipo_os.acoes_executadas%TYPE;
  v_delimitador              CHAR(1);
  v_vetor_job_tipo_produto   VARCHAR2(4000);
  v_vetor_tp_id              VARCHAR2(4000);
  v_vetor_tp_compl           VARCHAR2(32000);
  v_vetor_tp_desc            VARCHAR2(32000);
  v_job_tipo_produto_id      job_tipo_produto.job_tipo_produto_id%TYPE;
  v_tipo_produto_id          job_tipo_produto.tipo_produto_id%TYPE;
  v_nome_produto             tipo_produto.nome%TYPE;
  v_tempo_exec_info          tipo_produto.tempo_exec_info%TYPE;
  v_complemento              VARCHAR2(500);
  v_descricao_tp             VARCHAR2(32000);
  v_lbl_job                  VARCHAR2(100);
  v_padrao_numeracao_os      VARCHAR2(50);
  v_cod_emp_resp             empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_cod_empresa              empresa_sist_ext.cod_ext_empresa%TYPE;
  v_sistema_externo_id       sistema_externo.sistema_externo_id%TYPE;
  v_objeto_id                item_crono.objeto_id%TYPE;
  v_cod_objeto               item_crono.cod_objeto%TYPE;
  v_cronograma_id            item_crono.cronograma_id%TYPE;
  v_item_crono_id            item_crono.item_crono_id%TYPE;
  v_nome_ativ                item_crono.nome%TYPE;
  v_data_planej_fim          item_crono.data_planej_fim%TYPE;
  v_data_planej_ini          item_crono.data_planej_ini%TYPE;
  v_demanda_crono            item_crono.demanda%TYPE;
  v_flag_enviar              item_crono.flag_enviar%TYPE;
  v_flag_planejado           item_crono.flag_planejado%TYPE;
  v_papel_id                 papel.papel_id%TYPE;
  v_hora_fim                 VARCHAR2(10);
  v_flag_permite_prazo_neg   VARCHAR2(100);
  v_flag_respint_obrigatorio VARCHAR2(100);
  v_apelido                  pessoa.apelido%TYPE;
  v_data                     DATE;
  --                         
  CURSOR c_it IS
   SELECT tp.job_tipo_produto_id,
          jp.tipo_produto_id
     FROM os_tipo_produto  tp,
          job_tipo_produto jp
    WHERE tp.ordem_servico_id = v_ordem_servico_id
      AND tp.job_tipo_produto_id = jp.job_tipo_produto_id;
  --
  -- seleciona executores da OS
  CURSOR c_us IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
 BEGIN
  p_ordem_servico_id         := 0;
  v_lbl_job                  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_padrao_numeracao_os      := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_OS');
  v_hora_fim                 := empresa_pkg.parametro_retornar(p_empresa_id, 'HORA_PADRAO_NOVA_OS');
  v_flag_permite_prazo_neg   := empresa_pkg.parametro_retornar(p_empresa_id,
                                                               'FLAG_PERMITE_OS_PRAZO_NEGATIVO');
  v_flag_respint_obrigatorio := empresa_pkg.parametro_retornar(p_empresa_id,
                                                               'FLAG_RESPINT_OBRIGATORIO_OS_I');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF v_padrao_numeracao_os NOT IN ('SEQUENCIAL_POR_JOB', 'SEQUENCIAL_POR_TIPO_OS') OR
     TRIM(v_padrao_numeracao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Padrão de numeração de Workflow inválido ou não definido (' ||
                 v_padrao_numeracao_os || ').';
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
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         tipo_financeiro_id,
         emp_resp_id
    INTO v_numero_job,
         v_status_job,
         v_tipo_financeiro_id,
         v_emp_resp_id
    FROM job
   WHERE job_id = p_job_id;
  --
  IF v_status_job IN ('CANC', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_respint_obrigatorio = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_usuario
    WHERE job_id = p_job_id
      AND flag_responsavel = 'S';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário endereçar um Responsável pelo ' || v_lbl_job ||
                  ' antes de criar Workflows.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_flag_planejado := 'N';
  --
  IF nvl(p_item_crono_id, 0) <> 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono ic,
          cronograma cr
    WHERE ic.item_crono_id = p_item_crono_id
      AND ic.cronograma_id = cr.cronograma_id
      AND cr.job_id = p_job_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não existe ou não pertence a esse ' || v_lbl_job || '.';
    RAISE v_exception;
   END IF;
   --
   SELECT objeto_id,
          cod_objeto,
          nome,
          data_planej_fim,
          data_planej_ini,
          demanda,
          flag_enviar,
          flag_planejado
     INTO v_objeto_id,
          v_cod_objeto,
          v_nome_ativ,
          v_data_planej_fim,
          v_data_planej_ini,
          v_demanda_crono,
          v_flag_enviar,
          v_flag_planejado
     FROM item_crono
    WHERE item_crono_id = p_item_crono_id;
   --
   IF v_objeto_id IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de Cronograma já está associado a algum tipo de objeto (' ||
                  v_cod_objeto || ' - ' || to_char(v_objeto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_objeto IS NOT NULL AND v_cod_objeto <> 'ORDEM_SERVICO'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de Cronograma não pode ser usado para Workflows (' || v_cod_objeto || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- recupera dados para gerar numero da OS por tipo, com base em
  -- numeracao ja existente em sistemas legados.
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE tipo_sistema = 'FIN'
     AND flag_ativo = 'S';
  --
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_empresa
    FROM empresa_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND empresa_id = p_empresa_id;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_emp_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_os_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo de Workflow é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         codigo,
         flag_tem_itens,
         flag_tem_corpo,
         flag_faixa_aprov,
         flag_tem_estim,
         flag_estim_custo,
         flag_estim_prazo,
         flag_estim_arq,
         flag_estim_horas_usu,
         flag_estim_obs,
         flag_exec_estim,
         acoes_executadas
    INTO v_tipo_os_desc,
         v_tipo_os_cod,
         v_flag_tem_itens,
         v_flag_tem_corpo,
         v_flag_faixa_aprov,
         v_flag_tem_estim,
         v_flag_estim_custo,
         v_flag_estim_prazo,
         v_flag_estim_arq,
         v_flag_estim_horas_usu,
         v_flag_estim_obs,
         v_flag_exec_estim,
         v_acoes_executadas
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', p_job_id, p_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo solicitado inválida ' || p_data_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo solicitado inválida ' || p_hora_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_solicitada := data_hora_converter(p_data_solicitada || ' ' || p_hora_solicitada);
  --
  IF v_flag_permite_prazo_neg = 'N' AND v_data_solicitada < SYSDATE
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo solicitado não pode ser anterior à data atual ' ||
                 data_hora_mostrar(v_data_solicitada) || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_JOB'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico
    WHERE job_id = p_job_id;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_TIPO_OS'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico os,
          tipo_os       ti
    WHERE os.job_id = p_job_id
      AND os.tipo_os_id = ti.tipo_os_id
      AND ti.codigo = v_tipo_os_cod;
   --
   -- verifica numeracao de sistema legado
   SELECT nvl(MAX(num_ult_os), 0) + 1
     INTO v_numero_os_aux
     FROM numero_os
    WHERE cod_empresa = v_cod_empresa
      AND cod_emp_resp = v_cod_emp_resp
      AND num_job = v_numero_job
      AND cod_tipo_os = v_tipo_os_cod;
   --
   IF v_numero_os_aux > v_numero_os
   THEN
    v_numero_os := v_numero_os_aux;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_com_estim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com estimativa inválido ' || p_flag_com_estim || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_com_estim = 'S'
  THEN
   -- usa as configuracoes definidas para o tipo de OS
   IF v_flag_tem_estim = 'N'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de Workflow não está configurado para ter estimativa.';
    RAISE v_exception;
   END IF;
  ELSE
   -- ignora o que foi definido no tipo de OS
   v_flag_estim_custo     := 'N';
   v_flag_estim_prazo     := 'N';
   v_flag_estim_arq       := 'N';
   v_flag_estim_horas_usu := 'N';
   v_flag_estim_obs       := 'N';
  END IF;
  --
  v_descricao    := TRIM(p_descricao);
  v_demanda      := 'IME';
  v_data_demanda := NULL;
  v_tamanho      := NULL;
  v_data_interna := NULL;
  --
  IF nvl(p_item_crono_id, 0) <> 0 AND v_flag_planejado = 'S'
  THEN
   -- atividade planejada.
   -- pega informacoes da atividade do cronograma
   v_descricao       := substr(v_nome_ativ, 1, 100);
   v_data_solicitada := data_hora_converter(data_mostrar(v_data_planej_fim) || ' ' || v_hora_fim);
   --
   v_demanda := v_demanda_crono;
   IF v_demanda = 'DAT'
   THEN
    v_data_demanda := v_data_planej_ini;
   END IF;
   --
   IF v_flag_enviar = 'S'
   THEN
    v_tamanho := 'P';
   END IF;
   --
   v_data_interna := v_data_solicitada;
   --
   v_data_inicio  := v_data_planej_ini;
   v_data_termino := v_data_solicitada;
  END IF;
  --
  -- verifica se esse tipo de Os tem apenas uma acao executada de
  -- forma a gravar apenas essa acao.
  -- Extrai a primeira acao (se houver)
  v_acao_executada := TRIM(prox_valor_retornar(v_acoes_executadas, ','));
  --
  IF nvl(length(TRIM(v_acoes_executadas)), 0) > 0
  THEN
   -- ainda tem acoes no vetor. Limpa a acao extraida.
   v_acao_executada := NULL;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_ordem_servico.nextval
    INTO v_ordem_servico_id
    FROM dual;
  --
  INSERT INTO ordem_servico
   (ordem_servico_id,
    job_id,
    milestone_id,
    tipo_os_id,
    tipo_financeiro_id,
    numero,
    descricao,
    data_entrada,
    data_solicitada,
    data_interna,
    data_inicio,
    data_termino,
    demanda,
    data_demanda,
    texto_os,
    qtd_refacao,
    status,
    tamanho,
    cod_hash,
    flag_faixa_aprov,
    flag_com_estim,
    flag_estim_custo,
    flag_estim_prazo,
    flag_estim_arq,
    flag_estim_horas_usu,
    flag_estim_obs,
    flag_exec_estim,
    acao_executada)
  VALUES
   (v_ordem_servico_id,
    p_job_id,
    zvl(p_milestone_id, NULL),
    p_tipo_os_id,
    v_tipo_financeiro_id,
    v_numero_os,
    v_descricao,
    SYSDATE,
    v_data_solicitada,
    v_data_interna,
    v_data_inicio,
    v_data_termino,
    v_demanda,
    v_data_demanda,
    p_texto_os,
    0,
    'PREP',
    v_tamanho,
    rawtohex(sys_guid()),
    v_flag_faixa_aprov,
    p_flag_com_estim,
    v_flag_estim_custo,
    v_flag_estim_prazo,
    v_flag_estim_arq,
    v_flag_estim_horas_usu,
    v_flag_estim_obs,
    v_flag_exec_estim,
    v_acao_executada);
  --
  INSERT INTO os_usuario
   (ordem_servico_id,
    usuario_id,
    tipo_ender,
    flag_lido,
    horas_planej,
    sequencia)
  VALUES
   (v_ordem_servico_id,
    p_usuario_sessao_id,
    'SOL',
    'S',
    NULL,
    1);
  --
  INSERT INTO os_evento
   (os_evento_id,
    ordem_servico_id,
    usuario_id,
    data_evento,
    cod_acao,
    comentario,
    num_refacao,
    status_de,
    status_para,
    flag_estim)
  VALUES
   (seq_os_evento.nextval,
    v_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    'CRIAR',
    NULL,
    0,
    NULL,
    'PREP',
    p_flag_com_estim);
  --
  INSERT INTO os_refacao
   (ordem_servico_id,
    num_refacao,
    flag_estim,
    data_solicitada)
  VALUES
   (v_ordem_servico_id,
    0,
    p_flag_com_estim,
    v_data_solicitada);
  --
  -- registra o solicitante no historico de enderecamentos
  historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                     'OS',
                                     v_ordem_servico_id,
                                     'SOL',
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- tenta achar um papel com privilegio para essa acao
  SELECT MAX(up.papel_id)
    INTO v_papel_id
    FROM usuario_papel  up,
         papel_priv_tos pt,
         privilegio     pr
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pt.papel_id
     AND pt.tipo_os_id = p_tipo_os_id
     AND pt.privilegio_id = pr.privilegio_id
     AND pr.codigo = 'OS_C';
  --
  v_numero_os_char := numero_formatar(v_ordem_servico_id);
  --
  -- endereca automaticamente o solicitante ao job com co-ender e sem pula notif
  job_pkg.enderecar_usuario(p_usuario_sessao_id,
                            'N',
                            'S',
                            'N',
                            p_empresa_id,
                            p_job_id,
                            p_usuario_sessao_id,
                            'Criou Workflow ' || v_numero_os_char || ' de ' || v_tipo_os_desc,
                            'Criação de Workflow',
                            p_erro_cod,
                            p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de tipos de produto do job
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse job_tipo_produto não existe (' || to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          tempo_exec_info
     INTO v_nome_produto,
          v_tempo_exec_info
     FROM tipo_produto     tp,
          job_tipo_produto jp
    WHERE jp.job_tipo_produto_id = v_job_tipo_produto_id
      AND jp.tipo_produto_id = tp.tipo_produto_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = v_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_tipo_produto
     (ordem_servico_id,
      job_tipo_produto_id,
      tempo_exec_prev,
      num_refacao,
      data_entrada,
      quantidade)
    VALUES
     (v_ordem_servico_id,
      v_job_tipo_produto_id,
      v_tempo_exec_info,
      0,
      SYSDATE,
      1);
    --
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
    VALUES
     (v_ordem_servico_id,
      v_job_tipo_produto_id,
      0,
      SYSDATE);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de tipos de produto novos
  ------------------------------------------------------------
  v_vetor_tp_id    := p_vetor_tp_id;
  v_vetor_tp_compl := p_vetor_tp_compl;
  v_vetor_tp_desc  := p_vetor_tp_desc;
  --
  WHILE nvl(length(rtrim(v_vetor_tp_id)), 0) > 0
  LOOP
   v_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_tp_id, v_delimitador));
   v_complemento     := prox_valor_retornar(v_vetor_tp_compl, v_delimitador);
   v_descricao_tp    := prox_valor_retornar(v_vetor_tp_desc, v_delimitador);
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
    p_erro_msg := 'Esse tipo de produto não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          tempo_exec_info
     INTO v_nome_produto,
          v_tempo_exec_info
     FROM tipo_produto
    WHERE tipo_produto_id = v_tipo_produto_id
      AND empresa_id = p_empresa_id;
   --
   IF length(TRIM(v_complemento)) > 100
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O complemento do Entregável não pode ter mais que 100 caracteres (' ||
                  v_nome_produto || ').';
    RAISE v_exception;
   END IF;
   --
   /*
   IF LENGTH(TRIM(v_descricao_tp)) > 4000 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'A descrição do Entregável não pode ter mais que 4000 caracteres (' ||
                    v_nome_produto || ').';
      RAISE v_exception;
   END IF;*/
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_id = p_job_id
      AND tipo_produto_id = v_tipo_produto_id
      AND nvl(upper(TRIM(complemento)), 'ZZZZZZ') = nvl(upper(TRIM(v_complemento)), 'ZZZZZZ');
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Entregável já existe (' || TRIM(v_nome_produto || ' ' || v_complemento) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_job_tipo_produto.nextval
     INTO v_job_tipo_produto_id
     FROM dual;
   --
   INSERT INTO job_tipo_produto
    (job_tipo_produto_id,
     job_id,
     tipo_produto_id,
     complemento)
   VALUES
    (v_job_tipo_produto_id,
     p_job_id,
     v_tipo_produto_id,
     TRIM(v_complemento));
   --
   INSERT INTO os_tipo_produto
    (ordem_servico_id,
     job_tipo_produto_id,
     descricao,
     tempo_exec_prev,
     num_refacao,
     data_entrada,
     quantidade)
   VALUES
    (v_ordem_servico_id,
     v_job_tipo_produto_id,
     TRIM(v_descricao_tp),
     v_tempo_exec_info,
     0,
     SYSDATE,
     1);
   --
   INSERT INTO os_tipo_produto_ref
    (ordem_servico_id,
     job_tipo_produto_id,
     num_refacao,
     data_entrada)
   VALUES
    (v_ordem_servico_id,
     v_job_tipo_produto_id,
     0,
     SYSDATE);
  END LOOP;
  --
  ------------------------------------------------------------
  -- criacao de metadados dos itens
  ------------------------------------------------------------
  IF v_flag_tem_itens = 'S'
  THEN
   FOR r_it IN c_it
   LOOP
    -- verifica se o tipo de produto desse item tem metadado
    SELECT COUNT(*)
      INTO v_qt
      FROM metadado
     WHERE tipo_objeto = 'TIPO_PRODUTO'
       AND objeto_id = r_it.tipo_produto_id
       AND flag_ativo = 'S'
       AND grupo = 'ITEM_OS';
    --
    IF v_qt > 0
    THEN
     -- usa preferencialmente o metadado do tipo de produto
     INSERT INTO os_tp_atributo_valor
      (ordem_servico_id,
       job_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT v_ordem_servico_id,
             r_it.job_tipo_produto_id,
             metadado_id,
             NULL
        FROM metadado
       WHERE tipo_objeto = 'TIPO_PRODUTO'
         AND objeto_id = r_it.tipo_produto_id
         AND flag_ativo = 'S'
         AND grupo = 'ITEM_OS';
    ELSE
     -- usa o metadado de item definido para o tipo de OS (se houver)
     INSERT INTO os_tp_atributo_valor
      (ordem_servico_id,
       job_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT v_ordem_servico_id,
             r_it.job_tipo_produto_id,
             metadado_id,
             NULL
        FROM metadado
       WHERE tipo_objeto = 'TIPO_OS'
         AND objeto_id = p_tipo_os_id
         AND flag_ativo = 'S'
         AND grupo = 'ITEM_OS';
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- criacao de metadados do corpo
  ------------------------------------------------------------
  IF v_flag_tem_corpo = 'S'
  THEN
   INSERT INTO os_atributo_valor
    (ordem_servico_id,
     metadado_id,
     valor_atributo)
    SELECT v_ordem_servico_id,
           ab.metadado_id,
           NULL
      FROM metadado ab
     WHERE ab.tipo_objeto = 'TIPO_OS'
       AND ab.objeto_id = p_tipo_os_id
       AND ab.flag_ativo = 'S'
       AND grupo = 'CORPO_OS';
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  IF nvl(p_item_crono_id, 0) <> 0
  THEN
   -- OS criada via cronograma
   UPDATE item_crono
      SET objeto_id  = v_ordem_servico_id,
          cod_objeto = 'ORDEM_SERVICO'
    WHERE item_crono_id = p_item_crono_id;
  ELSE
   -- OS criada por fora do cronograma
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
   -- cria a atividade nao planejada de OS
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'ORDEM_SERVICO',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- vincula a atividade de OS a OS criada
   UPDATE item_crono
      SET objeto_id = v_ordem_servico_id,
          nome      = nvl(v_descricao, 'Workflow ' || numero_formatar(v_ordem_servico_id))
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- copia da equipe do cronograma como executores da OS
  -- em caso de atividade planejada
  ------------------------------------------------------------
  IF nvl(p_item_crono_id, 0) <> 0 AND v_flag_planejado = 'S'
  THEN
   cronograma_pkg.executores_replicar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_item_crono_id,
                                      'PLAY_CRONO',
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
  -- recalcula alocacao
  ------------------------------------------------------------
  SELECT MIN(data),
         MAX(data)
    INTO v_data_inicio,
         v_data_termino
    FROM os_usuario_data
   WHERE ordem_servico_id = v_ordem_servico_id
     AND tipo_ender = 'EXE';
  --
  FOR r_us IN c_us
  LOOP
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_id,
                                         v_data_inicio,
                                         v_data_termino,
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
  -- atualizacoes finais
  ------------------------------------------------------------
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         v_ordem_servico_id,
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
  it_controle_pkg.integrar('ORDEM_SERVICO_ADICIONAR',
                           p_empresa_id,
                           v_ordem_servico_id,
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
  v_identif_objeto := v_numero_os_char;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
  p_ordem_servico_id := v_ordem_servico_id;
  p_erro_cod         := '00000';
  p_erro_msg         := 'Operação realizada com sucesso.';
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
 PROCEDURE adicionar_demais
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/10/2018
  -- DESCRICAO: Inclusão de ORDEM_SERVICO(s) resultante(s) de repeticoes de um
  --   determinado grupo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_job_id                 IN ordem_servico.job_id%TYPE,
  p_repet_grupo            IN item_crono.repet_grupo%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_descricao              IN ordem_servico.descricao%TYPE,
  p_texto_os               IN ordem_servico.texto_os%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_tp_id            IN VARCHAR2,
  p_vetor_tp_compl         IN VARCHAR2,
  p_vetor_tp_desc          IN VARCHAR2,
  p_flag_com_estim         IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  --
  -- seleciona repeticoes do grupo sem OS criada
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          data_mostrar(ic.data_planej_fim) AS data_solicitada,
          hora_mostrar(ic.data_planej_fim) AS hora_solicitada
     FROM item_crono ic,
          cronograma cr
    WHERE ic.cronograma_id = cr.cronograma_id
      AND ic.repet_grupo = p_repet_grupo
      AND ic.cod_objeto = 'ORDEM_SERVICO'
      AND cr.job_id = p_job_id
      AND ic.objeto_id IS NULL
    ORDER BY ic.num_seq;
  --
 BEGIN
  FOR r_ic IN c_ic
  LOOP
   ordem_servico_pkg.adicionar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_job_id,
                               NULL,
                               p_tipo_os_id,
                               p_descricao,
                               r_ic.data_solicitada,
                               r_ic.hora_solicitada,
                               p_texto_os,
                               p_vetor_job_tipo_produto,
                               p_vetor_tp_id,
                               p_vetor_tp_compl,
                               p_vetor_tp_desc,
                               r_ic.item_crono_id,
                               p_flag_com_estim,
                               v_ordem_servico_id,
                               p_erro_cod,
                               p_erro_msg);
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
 END adicionar_demais;
 --
 --
 PROCEDURE basico_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/02/2013
  -- DESCRICAO: Atualização de dados basicoa da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/10/2013  Novo parametro para editar data_entrada.
  -- Silvia            10/03/2014  Novo parametro complex_refacao
  -- Silvia            12/03/2015  Teste de novo flag p/ obrigar o tamanho.
  -- Silvia            26/05/2015  Mudanca de nome de parametro FLAG_VINCULA_EDICAO_DATAS_OS
  --                               para FLAG_PERMITE_QQ_EDICAO_PRAZO_OS
  -- Silvia            08/12/2015  Novo parametro num_estim.
  -- Silvia            06/06/2016  Novo parametro para editar hora da data_entrada
  -- Silvia            06/02/2017  Atualiza atividade em item_crono com a descricao da OS
  --                               (apenas atividades nao planejadas).
  -- Silvia            26/03/2018  Tipo de demanda.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_milestone_id      IN ordem_servico.milestone_id%TYPE,
  p_descricao         IN ordem_servico.descricao%TYPE,
  p_num_estim         IN VARCHAR2,
  p_data_entrada      IN VARCHAR2,
  p_hora_entrada      IN VARCHAR2,
  p_data_solicitada   IN VARCHAR2,
  p_hora_solicitada   IN VARCHAR2,
  p_data_interna      IN VARCHAR2,
  p_hora_interna      IN VARCHAR2,
  p_demanda           IN ordem_servico.demanda%TYPE,
  p_data_demanda      IN VARCHAR2,
  p_tamanho           IN ordem_servico.tamanho%TYPE,
  p_os_evento_id      IN ordem_servico.os_evento_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN CLOB,
  p_complex_refacao   IN os_evento.complex_refacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_data_prev_ini          job.data_prev_ini%TYPE;
  v_numero_os              ordem_servico.numero%TYPE;
  v_data_interna           ordem_servico.data_interna%TYPE;
  v_data_interna_old       ordem_servico.data_interna%TYPE;
  v_data_solicitada        ordem_servico.data_solicitada%TYPE;
  v_data_solicitada_old    ordem_servico.data_solicitada%TYPE;
  v_data_entrada           ordem_servico.data_entrada%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_descricao              ordem_servico.descricao%TYPE;
  v_data_demanda           ordem_servico.data_demanda%TYPE;
  v_flag_obriga_tam        tipo_os.flag_obriga_tam%TYPE;
  v_flag_tem_descricao     tipo_os.flag_tem_descricao%TYPE;
  v_tipo_os                tipo_os.codigo%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc           tipo_os.nome%TYPE;
  v_motivo                 evento_motivo.nome%TYPE;
  v_num_estim              os_estim.num_estim%TYPE;
  v_num_estim_old          os_estim.num_estim%TYPE;
  v_os_estim_id            os_estim.os_estim_id%TYPE;
  v_status_estim           os_estim.status%TYPE;
  v_os_em_estim            CHAR(1);
  v_lbl_job                VARCHAR2(100);
  v_flag_permite_qq_edicao VARCHAR2(100);
  v_flag_permite_prazo_neg VARCHAR2(100);
  --
 BEGIN
  v_qt                     := 0;
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_permite_qq_edicao := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_PERMITE_QQ_EDICAO_PRAZO_OS');
  v_flag_permite_prazo_neg := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_PERMITE_OS_PRAZO_NEGATIVO');
  v_os_em_estim            := 'N';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         jo.data_prev_ini,
         os.numero,
         os.data_solicitada,
         os.data_interna,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         os.status,
         ti.flag_tem_descricao,
         ti.flag_obriga_tam,
         oe.status,
         oe.num_estim
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_data_prev_ini,
         v_numero_os,
         v_data_solicitada_old,
         v_data_interna_old,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_status_os,
         v_flag_tem_descricao,
         v_flag_obriga_tam,
         v_status_estim,
         v_num_estim_old
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_DI', v_job_id, v_tipo_os_id, p_empresa_id) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para configurar ou distribuir Workflows de ' ||
                  v_tipo_os_desc || '.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação (atualização de dados básicos).';
   RAISE v_exception;
  END IF;
  --
  v_num_estim := 0;
  IF TRIM(p_num_estim) IS NOT NULL
  THEN
   IF inteiro_validar(p_num_estim) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número da estimativa inválido (' || p_num_estim || ').';
    RAISE v_exception;
   END IF;
   --
   v_num_estim := to_number(p_num_estim);
  END IF;
  --
  IF v_num_estim_old IS NOT NULL AND v_num_estim_old <> v_num_estim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow já está associado a outra estimativa (' || to_char(v_num_estim_old) || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_num_estim > 0 AND (v_status_estim IS NULL OR v_status_estim = 'ANDA')
  THEN
   -- OS em processo de estimativa
   v_os_em_estim := 'S';
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  v_descricao := TRIM(p_descricao);
  IF v_flag_tem_descricao = 'S' AND v_descricao IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  ELSE
   IF v_flag_tem_descricao = 'S' AND v_descricao IS NOT NULL
   THEN
    v_descricao := v_descricao;
   ELSE
    v_descricao := ordem_servico_pkg.nome_retornar(p_ordem_servico_id);
   END IF;
  END IF;
  --
  IF rtrim(p_data_entrada) IS NULL OR rtrim(p_hora_entrada) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de entrada (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_entrada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de entrada inválida (' || p_data_entrada || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_entrada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora da data de entrada inválida (' || p_hora_entrada || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_solicitada) IS NULL OR rtrim(p_hora_solicitada) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo solicitado (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo solicitado inválida (' || p_data_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo solicitado inválida (' || p_hora_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_entrada    := data_hora_converter(p_data_entrada || ' ' || p_hora_entrada);
  v_data_solicitada := data_hora_converter(p_data_solicitada || ' ' || p_hora_solicitada);
  --
  IF v_flag_permite_qq_edicao = 'N' AND v_data_entrada < v_data_prev_ini
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de entrada não pode ser anterior à data de início do ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_permite_prazo_neg = 'N' AND v_data_solicitada < v_data_entrada
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo solicitado não pode ser anterior à data de entrada.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os <> 'PREP'
  THEN
   -- o prazo interno eh obrigatorio a partir do status Em Preparacao
   -- (Distribuicao em diante)
   IF rtrim(p_data_interna) IS NULL OR rtrim(p_hora_interna) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do prazo interno (data e hora) é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF data_validar(p_data_interna) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo interno inválida (' || p_data_interna || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_interna) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo interno inválida (' || p_hora_interna || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interna := data_hora_converter(p_data_interna || ' ' || p_hora_interna);
  --
  IF v_flag_permite_prazo_neg = 'N' AND v_data_interna < v_data_entrada
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo interno não pode ser anterior à data de entrada.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('demanda', p_demanda) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Demanda inválida (' || p_demanda || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_demanda = 'IME' AND TRIM(p_data_demanda) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para Workflow com início assim que possível, ' ||
                 'a data de início não deve ser preenchida.';
   RAISE v_exception;
  END IF;
  --
  IF p_demanda = 'DAT' AND TRIM(p_data_demanda) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para Workflow com início somente na data, a data de início deve ser preenchida.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_demanda) IS NOT NULL
  THEN
   IF data_validar(p_data_demanda) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data de início inválida (' || p_data_demanda || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_demanda := data_converter(p_data_demanda);
  END IF;
  --
  IF trunc(v_data_demanda) > trunc(v_data_solicitada)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início não pode ser maior que o prazo solicitado.';
   RAISE v_exception;
  END IF;
  --
  IF v_os_em_estim = 'N' AND v_flag_obriga_tam = 'S' AND TRIM(p_tamanho) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tamanho é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tamanho) IS NOT NULL AND p_tamanho NOT IN ('P', 'M', 'G')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho inválido (' || p_tamanho || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_os_evento_id, 0) > 0
  THEN
   IF nvl(p_evento_motivo_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O motivo deve ser especificado.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(nome)
     INTO v_motivo
     FROM evento_motivo
    WHERE evento_motivo_id = p_evento_motivo_id;
   --
   IF length(p_comentario) > 1048576
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O comentário não pode ter mais que 1048576 caracteres.';
    RAISE v_exception;
   END IF;
   --
   IF p_complex_refacao IS NOT NULL AND
      util_pkg.desc_retornar('complex_refacao', p_complex_refacao) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Complexidade da refação inválida (' || p_complex_refacao || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET milestone_id    = zvl(p_milestone_id, NULL),
         data_interna    = v_data_interna,
         data_solicitada = v_data_solicitada,
         data_entrada    = v_data_entrada,
         tamanho         = p_tamanho,
         descricao       = v_descricao,
         demanda         = TRIM(p_demanda),
         data_demanda    = v_data_demanda
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF nvl(p_os_evento_id, 0) > 0
  THEN
   UPDATE os_evento
      SET motivo          = v_motivo,
          comentario      = TRIM(p_comentario),
          complex_refacao = p_complex_refacao
    WHERE os_evento_id = p_os_evento_id;
  END IF;
  --
  IF v_num_estim > 0
  THEN
   -- OS com estimativa. Verifica se ja esta instanciada.
   SELECT MAX(os_estim_id),
          MAX(status)
     INTO v_os_estim_id,
          v_status_estim
     FROM os_estim
    WHERE job_id = v_job_id
      AND num_estim = v_num_estim;
   --
   IF v_os_estim_id IS NULL
   THEN
    SELECT seq_os_estim.nextval
      INTO v_os_estim_id
      FROM dual;
    --
    INSERT INTO os_estim
     (os_estim_id,
      job_id,
      num_estim,
      status,
      data_status)
    VALUES
     (v_os_estim_id,
      v_job_id,
      v_num_estim,
      'ANDA',
      SYSDATE);
   ELSE
    IF v_status_estim = 'CONC' AND nvl(v_num_estim_old, 0) <> v_num_estim
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse Workflow não pode ser associado a uma estimativa já ' ||
                   'concluída (Estim: ' || to_char(v_num_estim) || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_os_em_estim = 'S' AND v_status_os = 'PREP'
    THEN
     -- quando a OS estiver em PREP e na iteracao de Estimativa, nao
     -- permitir a indicacao de um Grupo que possua OS Em Aprov do Cliente
     SELECT COUNT(*)
       INTO v_qt
       FROM ordem_servico
      WHERE os_estim_id = v_os_estim_id
        AND status = 'EMAP';
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse Workflow não pode ser associado a uma estimativa que ' ||
                    'já possui Workflows em aprovação do cliente (Estim: ' || to_char(v_num_estim) || ').';
      RAISE v_exception;
     END IF;
    END IF;
   END IF;
   --
   UPDATE ordem_servico
      SET os_estim_id = v_os_estim_id
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  -- atualiza a atividade com a descricao da OS
  -- (apenas atividades nao planejadas).
  IF TRIM(p_descricao) IS NOT NULL
  THEN
   UPDATE item_crono
      SET nome = TRIM(p_descricao)
    WHERE objeto_id = p_ordem_servico_id
      AND cod_objeto = 'ORDEM_SERVICO'
      AND flag_planejado = 'N';
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORDEM_SERVICO_ATUALIZAR',
                           p_empresa_id,
                           p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Alteração de informações gerais';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  IF v_data_interna <> v_data_interna_old OR
     v_data_interna IS NOT NULL AND v_data_interna_old IS NULL
  THEN
   v_identif_objeto := numero_formatar(p_ordem_servico_id);
   v_compl_histor   := 'Prazo alterado de ' ||
                       nvl(TRIM(data_hora_mostrar(v_data_interna_old)), '-') || ' para ' ||
                       data_hora_mostrar(v_data_interna);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORDEM_SERVICO',
                    'ALTERAR_ESP2',
                    v_identif_objeto,
                    p_ordem_servico_id,
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
 END basico_atualizar;
 --
 --
 PROCEDURE corpo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/02/2013
  -- DESCRICAO: Atualização de dados do corpo da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/08/2017  Alteracao em tipo_dado_pkg.validar.
  -- Silvia            19/06/2019  Troca do delimitador para ^
  -- Silvia            05/03/2020  Deixa atualizar em varios status da OS
  -- Silvia            26/04/2022  Novo parametro para ignorar teste de obrigatoriedade
  --                               nos metadados: flag_ignora_obrig
  -- Ana Luiza         16/12/2024  Adicao de flag_tem_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_financeiro_id      IN ordem_servico.tipo_financeiro_id%TYPE,
  p_servico_id              IN ordem_servico.servico_id%TYPE,
  p_texto_os                IN ordem_servico.texto_os%TYPE,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_job_id                  job.job_id%TYPE;
  v_numero_job              job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_numero_os               ordem_servico.numero%TYPE;
  v_data_interna            ordem_servico.data_interna%TYPE;
  v_status_os               ordem_servico.status%TYPE;
  v_tipo_os                 tipo_os.codigo%TYPE;
  v_tipo_os_id              tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc            tipo_os.nome%TYPE;
  v_flag_tem_corpo          tipo_os.flag_tem_corpo%TYPE;
  v_flag_tem_tipo_finan     tipo_os.flag_tem_tipo_finan%TYPE;
  v_flag_tem_produto        tipo_os.flag_tem_produto%TYPE; --ALCBO_161224
  v_nome_atributo           metadado.nome%TYPE;
  v_tamanho                 metadado.tamanho%TYPE;
  v_flag_obrigatorio        metadado.flag_obrigatorio%TYPE;
  v_tipo_dado               tipo_dado.codigo%TYPE;
  v_lbl_job                 VARCHAR2(100);
  v_vetor_atributo_id       LONG;
  v_vetor_atributo_valor    LONG;
  v_metadado_id             metadado.metadado_id%TYPE;
  v_valor_atributo          LONG;
  v_valor_atributo_sai      LONG;
  v_delimitador             CHAR(1);
  v_vetor_flag_ignora_obrig LONG; --ALCBO_02-03-2023
  v_flag_ignora_obrig       VARCHAR2(10); --ALCBO_02-03-2023
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         os.status,
         ti.flag_tem_corpo,
         ti.flag_tem_tipo_finan,
         ti.flag_tem_produto
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_status_os,
         v_flag_tem_corpo,
         v_flag_tem_tipo_finan,
         v_flag_tem_produto
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para configurar Workflows de ' || v_tipo_os_desc || '.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação (atualização do corpo).';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF v_flag_tem_tipo_finan = 'S' AND nvl(p_tipo_financeiro_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo financeiro é obrigatório.';
   RAISE v_exception;
  END IF;
  --ALCBO_161224
  IF v_flag_tem_produto = 'S' AND nvl(p_servico_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo de Entregável é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_corpo = 'S' AND p_texto_os IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do texto é obrigatório.';
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
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET tipo_financeiro_id = zvl(p_tipo_financeiro_id, NULL),
         texto_os           = p_texto_os,
         servico_id         = zvl(p_servico_id, NULL)
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  DELETE FROM os_atributo_valor
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  v_delimitador             := '^';
  v_vetor_atributo_id       := p_vetor_atributo_id;
  v_vetor_atributo_valor    := p_vetor_atributo_valor;
  v_vetor_flag_ignora_obrig := p_vetor_flag_ignora_obrig; --ALCBO_02-03-2023
  --
  WHILE nvl(length(rtrim(v_vetor_atributo_id)), 0) > 0
  LOOP
   v_metadado_id       := to_number(prox_valor_retornar(v_vetor_atributo_id, v_delimitador));
   v_valor_atributo    := prox_valor_retornar(v_vetor_atributo_valor, v_delimitador);
   v_flag_ignora_obrig := prox_valor_retornar(v_vetor_flag_ignora_obrig, v_delimitador); --ALCBO_02-03-2023
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE metadado_id = v_metadado_id
      AND grupo = 'CORPO_OS';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado do corpo inválido (' || to_char(v_metadado_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(v_flag_ignora_obrig) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag ignora obrigatoriedade inválido (' || v_flag_ignora_obrig || ').';
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
                         v_flag_ignora_obrig,
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
   INSERT INTO os_atributo_valor
    (ordem_servico_id,
     metadado_id,
     valor_atributo)
   VALUES
    (p_ordem_servico_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORDEM_SERVICO_ATUALIZAR',
                           p_empresa_id,
                           p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Alteração do corpo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END corpo_atualizar;
 --
 --
 PROCEDURE copiar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 21/10/2014
  -- DESCRICAO: Cria nova ORDEM_SERVICO a partir de outra
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/08/2015  Novo vetor de arquivo_id
  -- Silvia            19/01/2016  Tratamento de cronograma
  -- Silvia            26/03/2018  Tipo de demanda.
  -- Silvia            29/03/2018  Horas estimadas na execucao (os_usuario).
  -- Silvia            09/10/2020  Se os parametros de vetores tipo_produto e arquivo vierem
  --                               vazio, copia da OS original.
  -- Silvia            03/03/2021  Novo parametro acao_executada; copia de os_link
  -- Silvia            11/05/2021  Copia dos executores com privilegio
  -- Silvia            11/11/2021  Calculo de alocacao dos usuarios executores copiados
  -- Ana Luiza         10/12/2024  Tratamento para copiar entregaveis apenas com parametro ligado
  -- Ana Luiza         20/12/2024  Tratamento num_refacao os_usuario_data
  -- Ana Luiza         06/02/2024  Tratamento em caso de p_vetor_job_tipo_produto nulo e --   
  --                               parametro de restricao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_old_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_os_id             IN tipo_os.tipo_os_id%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_acao_executada         IN VARCHAR2,
  p_ordem_servico_new_id   OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_ordem_servico_id       ordem_servico.ordem_servico_id%TYPE;
  v_num_os_old             VARCHAR2(100);
  v_numero_os              ordem_servico.numero%TYPE;
  v_numero_os_aux          ordem_servico.numero%TYPE;
  v_numero_os_char         VARCHAR2(50);
  v_descricao_os_old       ordem_servico.descricao%TYPE;
  v_texto_os_old           ordem_servico.texto_os%TYPE;
  v_tipo_financeiro_old_id ordem_servico.tipo_financeiro_id%TYPE;
  v_ordem_servico_ori_id   ordem_servico.ordem_servico_ori_id%TYPE;
  v_qtd_refacao            ordem_servico.qtd_refacao%TYPE;
  v_data_inicio            ordem_servico.data_inicio%TYPE;
  v_data_termino           ordem_servico.data_termino%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_emp_resp_id            job.emp_resp_id%TYPE;
  v_tipo_os_desc           tipo_os.nome%TYPE;
  v_tipo_os_cod            tipo_os.codigo%TYPE;
  v_tipo_os_old_id         tipo_os.tipo_os_id%TYPE;
  v_flag_tem_itens         tipo_os.flag_tem_itens%TYPE;
  v_flag_tem_corpo         tipo_os.flag_tem_corpo%TYPE;
  v_flag_faixa_aprov       tipo_os.flag_faixa_aprov%TYPE;
  v_flag_tem_estim         tipo_os.flag_tem_estim%TYPE;
  v_flag_estim_custo       tipo_os.flag_estim_custo%TYPE;
  v_flag_estim_prazo       tipo_os.flag_estim_prazo%TYPE;
  v_flag_estim_arq         tipo_os.flag_estim_arq%TYPE;
  v_flag_estim_horas_usu   tipo_os.flag_estim_horas_usu%TYPE;
  v_flag_estim_obs         tipo_os.flag_estim_obs%TYPE;
  v_flag_exec_estim        tipo_os.flag_exec_estim%TYPE;
  v_comentario             os_evento.comentario%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(4000);
  v_vetor_arquivo_id       VARCHAR2(8000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_nome_produto           tipo_produto.nome%TYPE;
  v_tp_tempo_exec_prev     os_tipo_produto.tempo_exec_prev%TYPE;
  v_tp_fator_tempo_calc    os_tipo_produto.fator_tempo_calc%TYPE;
  v_tp_descricao           os_tipo_produto.descricao%TYPE;
  v_tp_obs                 os_tipo_produto.obs%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_padrao_numeracao_os    VARCHAR2(50);
  v_cod_emp_resp           empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_cod_empresa            empresa_sist_ext.cod_ext_empresa%TYPE;
  v_sistema_externo_id     sistema_externo.sistema_externo_id%TYPE;
  --v_papel_id                       papel.papel_id%TYPE;
  v_arquivo_id         arquivo.arquivo_id%TYPE;
  v_cronograma_id      item_crono.cronograma_id%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
  v_data_atual         DATE;
  v_data_ini           DATE;
  v_data_fim           DATE;
  v_tipoprod_semconfig VARCHAR2(50);
  v_num_refacao        NUMBER; --ALCBO_2012
  v_tipo_produto_id    job_tipo_produto.tipo_produto_id%TYPE;
  --
  CURSOR c_it IS
   SELECT tp.job_tipo_produto_id,
          jp.tipo_produto_id
     FROM os_tipo_produto  tp,
          job_tipo_produto jp
    WHERE tp.ordem_servico_id = v_ordem_servico_id
      AND tp.job_tipo_produto_id = jp.job_tipo_produto_id;
  --
  CURSOR c_ex IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = v_ordem_servico_ori_id
      AND tipo_ender = 'EXE';
  --
 BEGIN
  v_qt                   := 0;
  p_ordem_servico_new_id := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_padrao_numeracao_os  := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_OS');
  v_tipoprod_semconfig   := empresa_pkg.parametro_retornar(p_empresa_id,
                                                           'USAR_TIPOPROD_SEMCONFIG_OS');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF v_padrao_numeracao_os NOT IN ('SEQUENCIAL_POR_JOB', 'SEQUENCIAL_POR_TIPO_OS') OR
     TRIM(v_padrao_numeracao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Padrão de numeração de Workflow inválido ou não definido (' ||
                 v_padrao_numeracao_os || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_old_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         jo.emp_resp_id,
         os.descricao,
         os.texto_os,
         os.tipo_os_id,
         ordem_servico_pkg.numero_formatar(os.ordem_servico_id),
         os.tipo_financeiro_id,
         os.qtd_refacao,
         os.data_inicio,
         os.data_termino,
         os.qtd_refacao --ALCBO_201224
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_emp_resp_id,
         v_descricao_os_old,
         v_texto_os_old,
         v_tipo_os_old_id,
         v_num_os_old,
         v_tipo_financeiro_old_id,
         v_qtd_refacao,
         v_data_inicio,
         v_data_termino,
         v_num_refacao
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_old_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC', 'CONC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- recupera dados para gerar numero da OS por tipo, com base em
  -- numeracao ja existente em sistemas legados.
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE tipo_sistema = 'FIN'
     AND flag_ativo = 'S';
  --
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_empresa
    FROM empresa_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND empresa_id = p_empresa_id;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_emp_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_os_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo da Workflow é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_acao_executada)) > 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A ação executada não pode ter mais que 60 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_acao_executada) IS NOT NULL
  THEN
   -- guarda a OS de origem (mesmo grupo)
   v_ordem_servico_ori_id := p_ordem_servico_old_id;
  END IF;
  --
  SELECT codigo,
         nome,
         flag_tem_itens,
         flag_tem_corpo,
         flag_faixa_aprov,
         flag_tem_estim,
         flag_estim_custo,
         flag_estim_prazo,
         flag_estim_arq,
         flag_estim_horas_usu,
         flag_estim_obs,
         flag_exec_estim
    INTO v_tipo_os_cod,
         v_tipo_os_desc,
         v_flag_tem_itens,
         v_flag_tem_corpo,
         v_flag_faixa_aprov,
         v_flag_tem_estim,
         v_flag_estim_custo,
         v_flag_estim_prazo,
         v_flag_estim_arq,
         v_flag_estim_horas_usu,
         v_flag_estim_obs,
         v_flag_exec_estim
    FROM tipo_os
   WHERE tipo_os_id = p_tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, p_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_JOB'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico
    WHERE job_id = v_job_id;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_TIPO_OS'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico os,
          tipo_os       ti
    WHERE os.job_id = v_job_id
      AND os.tipo_os_id = ti.tipo_os_id
      AND ti.codigo = v_tipo_os_cod;
   --
   -- verifica numeracao de sistema legado
   SELECT nvl(MAX(num_ult_os), 0) + 1
     INTO v_numero_os_aux
     FROM numero_os
    WHERE cod_empresa = v_cod_empresa
      AND cod_emp_resp = v_cod_emp_resp
      AND num_job = v_numero_job
      AND cod_tipo_os = v_tipo_os_cod;
   --
   IF v_numero_os_aux > v_numero_os
   THEN
    v_numero_os := v_numero_os_aux;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT seq_ordem_servico.nextval
    INTO v_ordem_servico_id
    FROM dual;
  --
  INSERT INTO ordem_servico
   (ordem_servico_id,
    ordem_servico_ori_id,
    job_id,
    tipo_os_id,
    tipo_financeiro_id,
    numero,
    descricao,
    data_entrada,
    data_solicitada,
    data_inicio,
    data_termino,
    texto_os,
    qtd_refacao,
    status,
    tamanho,
    cod_hash,
    flag_faixa_aprov,
    flag_com_estim,
    flag_estim_custo,
    flag_estim_prazo,
    flag_estim_arq,
    flag_estim_horas_usu,
    flag_estim_obs,
    flag_exec_estim,
    demanda,
    acao_executada)
  VALUES
   (v_ordem_servico_id,
    v_ordem_servico_ori_id,
    v_job_id,
    p_tipo_os_id,
    v_tipo_financeiro_old_id,
    v_numero_os,
    v_descricao_os_old,
    SYSDATE,
    NULL,
    v_data_inicio,
    v_data_termino,
    v_texto_os_old,
    0,
    'PREP',
    NULL,
    rawtohex(sys_guid()),
    v_flag_faixa_aprov,
    v_flag_tem_estim,
    v_flag_estim_custo,
    v_flag_estim_prazo,
    v_flag_estim_arq,
    v_flag_estim_horas_usu,
    v_flag_estim_obs,
    v_flag_exec_estim,
    'IME',
    TRIM(p_acao_executada));
  --
  INSERT INTO os_usuario
   (ordem_servico_id,
    usuario_id,
    tipo_ender,
    flag_lido,
    horas_planej,
    sequencia)
  VALUES
   (v_ordem_servico_id,
    p_usuario_sessao_id,
    'SOL',
    'S',
    NULL,
    1);
  --
  v_comentario := 'Criado a partir do Workflow: ' || v_num_os_old;
  --
  INSERT INTO os_evento
   (os_evento_id,
    ordem_servico_id,
    usuario_id,
    data_evento,
    cod_acao,
    comentario,
    num_refacao,
    status_de,
    status_para,
    flag_estim)
  VALUES
   (seq_os_evento.nextval,
    v_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    'CRIAR',
    v_comentario,
    0,
    NULL,
    'PREP',
    'N');
  --
  -- registra o solicitante no historico de enderecamentos
  historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                     'OS',
                                     v_ordem_servico_id,
                                     'SOL',
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  /*
    -- tenta achar um papel com privilegio para essa acao
    SELECT MAX(up.papel_id)
      INTO v_papel_id
      FROM usuario_papel up,
           papel_priv_tos pt,
           privilegio pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pt.papel_id
       AND pt.tipo_os_id = p_tipo_os_id
       AND pt.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'OS_C';
  */
  --
  v_numero_os_char := numero_formatar(v_ordem_servico_id);
  --
  -- endereca automaticamente o solicitante ao job com co-ender e sem pula notif
  job_pkg.enderecar_usuario(p_usuario_sessao_id,
                            'N',
                            'S',
                            'N',
                            p_empresa_id,
                            v_job_id,
                            p_usuario_sessao_id,
                            'Criou Workflow ' || v_numero_os_char || ' de ' || v_tipo_os_desc,
                            'Cópia de Workflow',
                            p_erro_cod,
                            p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- copia tipo_produto da OS original se vetor vier vazio
  ------------------------------------------------------------
  IF TRIM(p_vetor_job_tipo_produto) IS NULL
  THEN
   --ALCBO_060225
   -- Caso 1: v_tipoprod_semconfig = 'N' (verifica restrições)
   IF v_tipoprod_semconfig = 'N'
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM os_tipo_produto
     WHERE ordem_servico_id = p_ordem_servico_old_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Workflow anterior não possui registros em os_tipo_produto.';
     RAISE v_exception;
    END IF;
    --
    -- Pega tipo_produto da os anterior e testa com o da nova para ver se tem restricao
    FOR tp_os IN (SELECT tempo_exec_prev,
                         fator_tempo_calc,
                         descricao,
                         obs,
                         quantidade,
                         complemento,
                         tipo_produto_id,
                         jt.job_tipo_produto_id
                    FROM os_tipo_produto ot
                   INNER JOIN job_tipo_produto jt
                      ON ot.job_tipo_produto_id = jt.job_tipo_produto_id
                   WHERE ordem_servico_id = p_ordem_servico_old_id)
    LOOP
     --Insere entregavel se nao achar restricao
     IF util_pkg.entregavel_restrito_validar(p_tipo_os_id, tp_os.tipo_produto_id) = 1
     THEN
      -- Chama a sua nova função para verificar a existência do tipo de produto
      -- entregavel_restrito_validar retorna 1 quando cai aqui porque v_tipoprod_semconfig = 'N'
      INSERT INTO os_tipo_produto
       (ordem_servico_id,
        job_tipo_produto_id,
        tempo_exec_prev,
        fator_tempo_calc,
        descricao,
        obs,
        num_refacao,
        data_entrada,
        quantidade)
      VALUES
       (v_ordem_servico_id,
        tp_os.job_tipo_produto_id,
        tp_os.tempo_exec_prev,
        tp_os.fator_tempo_calc,
        tp_os.descricao,
        tp_os.obs,
        0,
        SYSDATE,
        tp_os.quantidade);
      --
      -- trunca a data por causa do DISTINCT
      v_data_atual := trunc(SYSDATE);
      INSERT INTO os_tipo_produto_ref
       (ordem_servico_id,
        job_tipo_produto_id,
        num_refacao,
        data_entrada)
      VALUES
       (v_ordem_servico_id,
        tp_os.job_tipo_produto_id,
        0,
        v_data_atual);
     END IF;
    END LOOP;
   ELSE
    -- Caso 2: v_tipoprod_semconfig = 'S' (copia sem restrições)
    -- Se não há restrição, simplesmente copia os dados da OS anterior
    INSERT INTO os_tipo_produto
     (ordem_servico_id,
      job_tipo_produto_id,
      tempo_exec_prev,
      fator_tempo_calc,
      descricao,
      obs,
      num_refacao,
      data_entrada,
      quantidade)
     SELECT v_ordem_servico_id,
            job_tipo_produto_id,
            tempo_exec_prev,
            fator_tempo_calc,
            descricao,
            obs,
            0,
            SYSDATE,
            quantidade
       FROM os_tipo_produto
      WHERE ordem_servico_id = p_ordem_servico_old_id;
   
    -- trunca a data por causa do DISTINCT
    v_data_atual := trunc(SYSDATE);
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
     SELECT DISTINCT v_ordem_servico_id,
                     job_tipo_produto_id,
                     0,
                     v_data_atual
       FROM os_tipo_produto
      WHERE ordem_servico_id = p_ordem_servico_old_id;
   END IF;
  END IF; -- verificacao parametro;
  ------------------------------------------------------------
  -- tratamento dos vetores de tipos de produto (caso preenchido)
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse job_tipo_produto não existe (' || to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_old_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse job_tipo_produto não está associado ao Workflow anterior (' ||
                  to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT tempo_exec_prev,
          fator_tempo_calc,
          descricao,
          obs
     INTO v_tp_tempo_exec_prev,
          v_tp_fator_tempo_calc,
          v_tp_descricao,
          v_tp_obs
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_old_id;
   --
   --ALCBO_101224
   SELECT MAX(tipo_produto_id)
     INTO v_tipo_produto_id
     FROM job_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_tipoprod_semconfig = 'N' AND
      util_pkg.entregavel_restrito_validar(p_ordem_servico_old_id, v_tipo_produto_id) = 1
   THEN
    CONTINUE; -- Pula para a próxima iteração do loop quando encontra restricao
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = v_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_tipo_produto
     (ordem_servico_id,
      job_tipo_produto_id,
      tempo_exec_prev,
      fator_tempo_calc,
      descricao,
      obs,
      num_refacao,
      data_entrada,
      quantidade)
    VALUES
     (v_ordem_servico_id,
      v_job_tipo_produto_id,
      v_tp_tempo_exec_prev,
      v_tp_fator_tempo_calc,
      v_tp_descricao,
      v_tp_obs,
      0,
      SYSDATE,
      1);
    --
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
    VALUES
     (v_ordem_servico_id,
      v_job_tipo_produto_id,
      0,
      trunc(SYSDATE));
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- criacao de metadados dos itens
  ------------------------------------------------------------
  IF v_flag_tem_itens = 'S'
  THEN
   FOR r_it IN c_it
   LOOP
    IF p_tipo_os_id = v_tipo_os_old_id
    THEN
     -- nao mudou o tipo de OS. Copia metadados da OS anterior, com valores.
     INSERT INTO os_tp_atributo_valor
      (ordem_servico_id,
       job_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT v_ordem_servico_id,
             job_tipo_produto_id,
             metadado_id,
             valor_atributo
        FROM os_tp_atributo_valor
       WHERE ordem_servico_id = p_ordem_servico_old_id
         AND job_tipo_produto_id = r_it.job_tipo_produto_id;
    
    ELSE
     -- mudou o tipo de OS.
     -- verifica se o tipo de produto desse item tem metadado
     SELECT COUNT(*)
       INTO v_qt
       FROM metadado
      WHERE tipo_objeto = 'TIPO_PRODUTO'
        AND objeto_id = r_it.tipo_produto_id
        AND flag_ativo = 'S'
        AND grupo = 'ITEM_OS';
     --
     IF v_qt > 0
     THEN
      -- usa preferencialmente o metadado do tipo de produto, copiado da OS anterior,
      -- com valores.
      INSERT INTO os_tp_atributo_valor
       (ordem_servico_id,
        job_tipo_produto_id,
        metadado_id,
        valor_atributo)
       SELECT v_ordem_servico_id,
              job_tipo_produto_id,
              metadado_id,
              valor_atributo
         FROM os_tp_atributo_valor
        WHERE ordem_servico_id = p_ordem_servico_old_id
          AND job_tipo_produto_id = r_it.job_tipo_produto_id;
     
     ELSE
      -- usa o metadado de item definido para o tipo de OS (se houver), sem valores
      INSERT INTO os_tp_atributo_valor
       (ordem_servico_id,
        job_tipo_produto_id,
        metadado_id,
        valor_atributo)
       SELECT v_ordem_servico_id,
              r_it.job_tipo_produto_id,
              metadado_id,
              NULL
         FROM metadado
        WHERE tipo_objeto = 'TIPO_OS'
          AND objeto_id = p_tipo_os_id
          AND flag_ativo = 'S'
          AND grupo = 'ITEM_OS';
     
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- criacao de metadados do corpo
  ------------------------------------------------------------
  IF v_flag_tem_corpo = 'S'
  THEN
   IF p_tipo_os_id = v_tipo_os_old_id
   THEN
    -- nao mudou o tipo de OS. Copia metadados da OS anterior,
    -- com valores
    INSERT INTO os_atributo_valor
     (ordem_servico_id,
      metadado_id,
      valor_atributo)
     SELECT v_ordem_servico_id,
            metadado_id,
            valor_atributo
       FROM os_atributo_valor
      WHERE ordem_servico_id = p_ordem_servico_old_id;
   ELSE
    -- mudou o tipo de OS. Cria metadados referentes ao novo
    -- tipo, sem valores
    INSERT INTO os_atributo_valor
     (ordem_servico_id,
      metadado_id,
      valor_atributo)
     SELECT v_ordem_servico_id,
            ab.metadado_id,
            NULL
       FROM metadado ab
      WHERE ab.tipo_objeto = 'TIPO_OS'
        AND ab.objeto_id = p_tipo_os_id
        AND ab.flag_ativo = 'S'
        AND grupo = 'CORPO_OS';
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- copia arquivo da OS original se vetor vier vazio
  ------------------------------------------------------------
  IF TRIM(p_vetor_arquivo_id) IS NULL
  THEN
   INSERT INTO arquivo_os
    (arquivo_id,
     ordem_servico_id,
     tipo_arq_os,
     flag_thumb,
     chave_thumb,
     num_refacao)
    SELECT arquivo_id,
           v_ordem_servico_id,
           'REFER',
           flag_thumb,
           chave_thumb,
           0
      FROM arquivo_os
     WHERE ordem_servico_id = p_ordem_servico_old_id
       AND tipo_arq_os = 'EXEC';
  END IF;
  --
  ------------------------------------------------------------
  -- vetor de arquivos a serem copiados (caso preenchido)
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_arquivo_id := p_vetor_arquivo_id;
  --
  WHILE nvl(length(rtrim(v_vetor_arquivo_id)), 0) > 0
  LOOP
   v_arquivo_id := to_number(prox_valor_retornar(v_vetor_arquivo_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_os
    WHERE arquivo_id = v_arquivo_id
      AND ordem_servico_id = p_ordem_servico_old_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse arquivo não existe ou não pertence a esse Workflow (' ||
                  to_char(v_arquivo_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- copia o arquivo para a nova OS
   INSERT INTO arquivo_os
    (arquivo_id,
     ordem_servico_id,
     tipo_arq_os,
     flag_thumb,
     chave_thumb,
     num_refacao)
    SELECT v_arquivo_id,
           v_ordem_servico_id,
           'REFER',
           flag_thumb,
           chave_thumb,
           0
      FROM arquivo_os
     WHERE ordem_servico_id = p_ordem_servico_old_id
       AND arquivo_id = v_arquivo_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(v_job_id);
  --
  IF nvl(v_cronograma_id, 0) = 0
  THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_job_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- cria a atividade de OS
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'ORDEM_SERVICO',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- vincula a atividade de OS a OS criada
  UPDATE item_crono
     SET objeto_id = v_ordem_servico_id,
         nome      = nvl(v_descricao_os_old, 'Workflow ' || numero_formatar(v_ordem_servico_id))
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- copia links
  ------------------------------------------------------------
  IF TRIM(p_acao_executada) IS NOT NULL
  THEN
   INSERT INTO os_link
    (os_link_id,
     ordem_servico_id,
     usuario_id,
     data_entrada,
     url,
     descricao,
     tipo_link,
     num_refacao)
    SELECT seq_os_link.nextval,
           v_ordem_servico_id,
           p_usuario_sessao_id,
           SYSDATE,
           url,
           descricao,
           'REFER',
           0
      FROM os_link
     WHERE ordem_servico_id = p_ordem_servico_old_id
       AND tipo_link = 'EXEC';
  END IF;
  --
  ------------------------------------------------------------
  -- copia executores com privilegio
  ------------------------------------------------------------
  FOR r_ex IN c_ex
  LOOP
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE usuario_id = r_ex.usuario_id
      AND ordem_servico_id = v_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   IF v_qt = 0 AND
      usuario_pkg.priv_verificar(r_ex.usuario_id, 'OS_EX', v_job_id, p_tipo_os_id, p_empresa_id) = 1
   THEN
    --
    INSERT INTO os_usuario
     (ordem_servico_id,
      usuario_id,
      tipo_ender,
      flag_lido,
      horas_planej,
      sequencia,
      status,
      data_status)
    VALUES
     (v_ordem_servico_id,
      r_ex.usuario_id,
      'EXE',
      'N',
      NULL,
      1,
      'EMEX',
      SYSDATE);
    --
    historico_pkg.hist_ender_registrar(r_ex.usuario_id,
                                       'OS',
                                       v_ordem_servico_id,
                                       'EXE',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    INSERT INTO os_usuario_data
     (ordem_servico_id,
      usuario_id,
      tipo_ender,
      data,
      horas,
      num_refacao)
     SELECT v_ordem_servico_id,
            usuario_id,
            tipo_ender,
            data,
            horas,
            v_num_refacao --ALCBO_201224
       FROM os_usuario_data
      WHERE ordem_servico_id = p_ordem_servico_old_id
        AND usuario_id = r_ex.usuario_id
        AND tipo_ender = 'EXE';
    --
    -- recalcula a alocacao do usuario executor no periodo
    SELECT MIN(data),
           MAX(data)
      INTO v_data_ini,
           v_data_fim
      FROM os_usuario_data
     WHERE ordem_servico_id = p_ordem_servico_old_id
       AND usuario_id = r_ex.usuario_id
       AND tipo_ender = 'EXE';
    --
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_ex.usuario_id,
                                          v_data_ini,
                                          v_data_fim,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         v_ordem_servico_id,
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
  it_controle_pkg.integrar('ORDEM_SERVICO_ADICIONAR',
                           p_empresa_id,
                           v_ordem_servico_id,
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
  v_identif_objeto := v_numero_os_char;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
  p_ordem_servico_new_id := v_ordem_servico_id;
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
 END copiar;
 --
 --
 PROCEDURE data_solic_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/02/2014
  -- DESCRICAO: Atualização de data_solicitada da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/02/2014  Ajuste no prazo interno.
  -- Silvia            26/05/2015  Mudanca de nome de parametro FLAG_VINCULA_EDICAO_DATAS_OS
  --                               para FLAG_PERMITE_QQ_EDICAO_PRAZO_OS
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_solicitada   IN VARCHAR2,
  p_hora_solicitada   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_data_entrada           ordem_servico.data_entrada%TYPE;
  v_data_solicitada        ordem_servico.data_solicitada%TYPE;
  v_data_solicitada_old    ordem_servico.data_solicitada%TYPE;
  v_data_interna           ordem_servico.data_interna%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_flag_permite_qq_edicao VARCHAR2(100);
  v_flag_permite_prazo_neg VARCHAR2(100);
  --
 BEGIN
  v_qt                     := 0;
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_permite_qq_edicao := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_PERMITE_QQ_EDICAO_PRAZO_OS');
  v_flag_permite_prazo_neg := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_PERMITE_OS_PRAZO_NEGATIVO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         os.data_entrada,
         os.data_solicitada,
         os.data_interna
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_data_entrada,
         v_data_solicitada_old,
         v_data_interna
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_solicitada) IS NULL OR rtrim(p_hora_solicitada) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo solicitado (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo solicitado inválida (' || p_data_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_solicitada) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo solicitado inválida (' || p_hora_solicitada || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_solicitada := data_hora_converter(p_data_solicitada || ' ' || p_hora_solicitada);
  --
  IF v_flag_permite_prazo_neg = 'N' AND v_data_solicitada < v_data_entrada
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo solicitado não pode ser anterior à data de entrada.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_solicitada = v_data_solicitada_old
  THEN
   -- a data nao mudou pula o processamento
   RAISE v_saida;
  END IF;
  --
  IF v_flag_permite_qq_edicao = 'N' AND v_data_solicitada < v_data_solicitada_old
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo solicitado não pode ser anterior ao prazo antigo (' ||
                 data_hora_mostrar(v_data_solicitada_old) || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_data_solicitada > v_data_interna
  THEN
   v_data_interna := v_data_solicitada;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET data_solicitada = v_data_solicitada,
         data_interna    = v_data_interna
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- marca executores como nao lido
  UPDATE os_usuario
     SET flag_lido = 'N'
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = 'EXE';
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORDEM_SERVICO_ATUALIZAR',
                           p_empresa_id,
                           p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Prazo alterado de ' || data_hora_mostrar(v_data_solicitada_old) || ' para ' ||
                      data_hora_mostrar(v_data_solicitada);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR_ESP1',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END data_solic_atualizar;
 --
 --
 PROCEDURE data_interna_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 03/04/2018
  -- DESCRICAO: Atualização de data_interna da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/10/2020  Novo parametro para atualizar datas inicio/termino
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_interna      IN VARCHAR2,
  p_hora_interna      IN VARCHAR2,
  p_flag_atu_periodo  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_data_entrada           ordem_servico.data_entrada%TYPE;
  v_data_interna           ordem_servico.data_interna%TYPE;
  v_data_interna_old       ordem_servico.data_interna%TYPE;
  v_data_inicio_old        ordem_servico.data_inicio%TYPE;
  v_data_termino_old       ordem_servico.data_termino%TYPE;
  v_data_inicio_new        ordem_servico.data_inicio%TYPE;
  v_data_termino_new       ordem_servico.data_termino%TYPE;
  v_data_inicio            ordem_servico.data_inicio%TYPE;
  v_data_termino           ordem_servico.data_termino%TYPE;
  v_flag_planejado         item_crono.flag_planejado%TYPE;
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_flag_permite_prazo_neg VARCHAR2(100);
  v_num_dias               NUMBER(10);
  v_data                   DATE;
  --
  -- seleciona datas ascendentes dos executores da OS
  CURSOR c_ua IS
   SELECT ou.usuario_id,
          ou.data
     FROM os_usuario_data ou
    WHERE ou.ordem_servico_id = p_ordem_servico_id
      AND ou.tipo_ender = 'EXE'
    ORDER BY data ASC;
  --
  -- seleciona datas descendentes dos executores da OS
  CURSOR c_ud IS
   SELECT ou.usuario_id,
          ou.data
     FROM os_usuario_data ou
    WHERE ou.ordem_servico_id = p_ordem_servico_id
      AND ou.tipo_ender = 'EXE'
    ORDER BY data DESC;
  --
  -- seleciona usuarios executores
  CURSOR c_oe IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
 BEGIN
  v_qt                     := 0;
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_permite_prazo_neg := empresa_pkg.parametro_retornar(p_empresa_id,
                                                             'FLAG_PERMITE_OS_PRAZO_NEGATIVO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         os.data_entrada,
         os.data_interna,
         os.data_inicio,
         os.data_termino
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_data_entrada,
         v_data_interna_old,
         v_data_inicio_old,
         v_data_termino_old
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'ORDEM_SERVICO'
     AND objeto_id = p_ordem_servico_id;
  --
  IF v_item_crono_id > 0
  THEN
   SELECT flag_planejado
     INTO v_flag_planejado
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_interna) IS NULL OR rtrim(p_hora_interna) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo interno (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os <> 'PREP'
  THEN
   -- o prazo interno eh obrigatorio a partir do status Em Preparacao
   -- (Distribuicao em diante)
   IF rtrim(p_data_interna) IS NULL OR rtrim(p_hora_interna) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do prazo interno (data e hora) é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF data_validar(p_data_interna) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo interno inválida (' || p_data_interna || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_interna) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo interno inválida (' || p_hora_interna || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_interna := data_hora_converter(p_data_interna || ' ' || p_hora_interna);
  --
  IF v_flag_permite_prazo_neg = 'N' AND v_data_interna < v_data_entrada
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O prazo interno não pode ser anterior à data de entrada (' ||
                 data_hora_mostrar(v_data_entrada) || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_atu_periodo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de alteração de período inválido (' || p_flag_atu_periodo || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET data_interna = v_data_interna
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- verifica se precisa atualizar datas de inicio e termino
  IF trunc(v_data_interna) <> trunc(v_data_interna_old) AND p_flag_atu_periodo = 'S'
  THEN
   -- calcula o deslocamento
   IF v_data_interna > v_data_interna_old
   THEN
    --v_num_dias := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,v_data_interna_old,v_data_interna);
    v_num_dias := trunc(v_data_interna) - trunc(v_data_interna_old);
   ELSE
    --v_num_dias := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,v_data_interna,v_data_interna_old);
    --v_num_dias := v_num_dias * -1;
    v_num_dias := (trunc(v_data_interna_old) - trunc(v_data_interna)) * -1;
   END IF;
   --
   -- calcula o novo periodo usando o deslocamento
   --v_data_inicio_new := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,v_data_inicio_old,v_num_dias,'S');
   --v_data_termino_new := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,v_data_termino_old,v_num_dias,'S');
   v_data_inicio_new  := v_data_inicio_old + v_num_dias;
   v_data_termino_new := v_data_termino_old + v_num_dias;
   --
   UPDATE ordem_servico
      SET data_inicio  = v_data_inicio_new,
          data_termino = v_data_termino_new
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   IF v_flag_planejado = 'N' AND nvl(v_item_crono_id, 0) > 0
   THEN
    UPDATE item_crono
       SET data_planej_ini = trunc(v_data_inicio_new),
           data_planej_fim = trunc(v_data_termino_new)
     WHERE item_crono_id = v_item_crono_id;
   END IF;
   --
   IF v_num_dias > 0
   THEN
    -- deslocamento pra frente. Comeca pela maior data
    FOR r_ud IN c_ud
    LOOP
     --v_data := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,r_ud.data,v_num_dias,'S');
     v_data := r_ud.data + v_num_dias;
     --
     UPDATE os_usuario_data
        SET data = v_data
      WHERE ordem_servico_id = p_ordem_servico_id
        AND usuario_id = r_ud.usuario_id
        AND tipo_ender = 'EXE'
        AND data = r_ud.data;
    END LOOP;
   ELSE
    -- deslocamento pra tras. Comeca pela menor data
    FOR r_ua IN c_ua
    LOOP
     --v_data := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,r_ua.data,v_num_dias,'S');
     v_data := r_ua.data + v_num_dias;
     --
     UPDATE os_usuario_data
        SET data = v_data
      WHERE ordem_servico_id = p_ordem_servico_id
        AND usuario_id = r_ua.usuario_id
        AND tipo_ender = 'EXE'
        AND data = r_ua.data;
    END LOOP;
   END IF;
   --
   -- tratamento da alocacao
   v_data_inicio  := v_data_inicio_new;
   v_data_termino := v_data_termino_new;
   --
   IF v_data_inicio_old < v_data_inicio
   THEN
    v_data_inicio := v_data_inicio_old;
   END IF;
   --
   IF v_data_termino_old > v_data_termino
   THEN
    v_data_termino := v_data_termino_old;
   END IF;
   --
   FOR r_oe IN c_oe
   LOOP
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_oe.usuario_id,
                                          v_data_inicio,
                                          v_data_termino,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORDEM_SERVICO_ATUALIZAR',
                           p_empresa_id,
                           p_ordem_servico_id,
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
  IF v_data_interna <> v_data_interna_old OR
     v_data_interna IS NOT NULL AND v_data_interna_old IS NULL
  THEN
   v_identif_objeto := numero_formatar(p_ordem_servico_id);
   v_compl_histor   := 'Prazo alterado de ' ||
                       nvl(TRIM(data_hora_mostrar(v_data_interna_old)), '-') || ' para ' ||
                       data_hora_mostrar(v_data_interna);
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORDEM_SERVICO',
                    'ALTERAR_ESP2',
                    v_identif_objeto,
                    p_ordem_servico_id,
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
  END IF;
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END data_interna_atualizar;
 --
 --
 PROCEDURE tamanho_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/02/2013
  -- DESCRICAO: Atualização de tamanho de ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/03/2015  Teste de novo flag p/ obrigar o tamanho.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tamanho           IN ordem_servico.tamanho%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_numero_os       ordem_servico.numero%TYPE;
  v_tipo_os         tipo_os.codigo%TYPE;
  v_tipo_os_id      tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc    tipo_os.nome%TYPE;
  v_flag_obriga_tam tipo_os.flag_obriga_tam%TYPE;
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         ti.flag_obriga_tam
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_flag_obriga_tam
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'OS_TAM_A',
                                v_job_id,
                                v_tipo_os_id,
                                p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_flag_obriga_tam = 'S' AND TRIM(p_tamanho) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tamanho é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tamanho) IS NOT NULL AND p_tamanho NOT IN ('P', 'M', 'G')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho inválido (' || p_tamanho || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET tamanho = TRIM(p_tamanho)
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Alteração de tamanho';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END tamanho_atualizar;
 --
 --
 PROCEDURE enderecados_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/02/2013
  -- DESCRICAO: Atualização de enderecados da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/03/2017  Novo parâmetro para habilitar a volta do status qdo
  --                               o executor mudar.
  -- Silvia            29/03/2018  Horas estimadas na execucao (os_usuario). Novos param.
  -- Silvia            28/01/2019  Horas planej passou de inteiro para decimal.
  -- Silvia            11/02/2019  Novos eventos do historico (ENDERECAR SOL/DIS/EXE)
  -- Silvia            12/08/2020  Essa proc nao sera mais utlizada para EXECUTORES
  -- Silvia            30/09/2020  Exclusao de os_usuario_data
  -- Joel Dias         26/06/2024  Exclusão de usuário EXE sem excluir os_usuario_data de
  --                               refações anteriores
  -- Ana Luiza         21/11/2024  Tratando num_refacao os_usuario_data
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_enderecados  IN VARCHAR2,
  p_vetor_horas_planej IN VARCHAR2,
  p_vetor_sequencia    IN VARCHAR2,
  p_tipo_ender         IN VARCHAR2,
  p_flag_volta_status  IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_job_id             job.job_id%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_numero_os_char     VARCHAR2(50);
  v_numero_os          ordem_servico.numero%TYPE;
  v_status_os          ordem_servico.status%TYPE;
  v_tipo_os            tipo_os.codigo%TYPE;
  v_tipo_os_id         tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc       tipo_os.nome%TYPE;
  v_delimitador        CHAR(1);
  v_vetor_enderecados  LONG;
  v_vetor_horas_planej LONG;
  v_vetor_sequencia    LONG;
  v_sequencia_char     VARCHAR2(20);
  v_horas_char         VARCHAR2(20);
  v_sequencia          os_usuario.sequencia%TYPE;
  v_horas_planej       os_usuario.horas_planej%TYPE;
  v_usuario_id         usuario.usuario_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_tipo_ender_desc    VARCHAR2(100);
  v_apelido            pessoa.apelido%TYPE;
  --v_papel_id                       papel.papel_id%TYPE;
  v_volta_status CHAR(1);
  v_qt_reg_alt   NUMBER(5);
  v_cod_acao     tipo_acao.codigo%TYPE;
  v_enderecados  VARCHAR2(4000);
  --v_papel                          papel.nome%TYPE;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  v_num_refacao   ordem_servico.qtd_refacao%TYPE;
  --
  -- seleciona executores da OS
  CURSOR c_us IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = p_tipo_ender
      AND controle IS NULL;
  --
  -- seleciona executores do cronograma
  CURSOR c_uc IS
   SELECT usuario_id
     FROM item_crono_usu
    WHERE item_crono_id = v_item_crono_id;
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_ender) IS NULL OR p_tipo_ender NOT IN ('EXE', 'SOL', 'DIS', 'AVA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de endereçamento inválido (' || p_tipo_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_volta_status) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag volta status inválido (' || p_flag_volta_status || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT decode(p_tipo_ender,
                'EXE',
                'Executor',
                'SOL',
                'Solicitante',
                'DIS',
                'Distribuidor',
                'AVA',
                'Avaliador')
    INTO v_tipo_ender_desc
    FROM dual;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  v_numero_os_char := ordem_servico_pkg.numero_formatar(p_ordem_servico_id);
  --
  IF p_tipo_ender = 'EXE'
  THEN
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cod_objeto = 'ORDEM_SERVICO'
      AND objeto_id = p_ordem_servico_id;
  END IF;
  --
  v_delimitador := '|';
  ------------------------------------------------------------
  -- tratamento do vetor de enderecados
  ------------------------------------------------------------
  -- marca todos os registros como candidatos a serem deletados
  UPDATE os_usuario
     SET controle = 'DEL'
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = p_tipo_ender;
  --
  v_vetor_enderecados  := TRIM(p_vetor_enderecados);
  v_vetor_horas_planej := TRIM(p_vetor_horas_planej);
  v_vetor_sequencia    := TRIM(p_vetor_sequencia);
  --
  v_qt_reg_alt  := 0;
  v_enderecados := NULL;
  --
  WHILE nvl(length(rtrim(v_vetor_enderecados)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_enderecados, v_delimitador));
   v_apelido    := NULL;
   --v_papel := NULL;
   --
   IF p_tipo_ender <> 'EXE' OR (v_vetor_enderecados IS NULL AND v_vetor_sequencia IS NULL)
   THEN
    -- despreza os demais vetores
    v_horas_planej := NULL;
    v_sequencia    := 1;
   ELSE
    v_horas_char     := prox_valor_retornar(v_vetor_horas_planej, v_delimitador);
    v_sequencia_char := prox_valor_retornar(v_vetor_sequencia, v_delimitador);
    --
    IF inteiro_validar(v_sequencia_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Sequência inválida (' || v_sequencia_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_sequencia := nvl(to_number(v_sequencia_char), 1);
    --
    IF v_sequencia <= 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Sequência inválida (' || v_sequencia_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF numero_validar(v_horas_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Estimativa de horas inválida (' || v_horas_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_horas_planej := nvl(round(numero_converter(v_horas_char), 2), 0);
   END IF;
   --
   SELECT apelido
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = v_usuario_id
      AND tipo_ender = p_tipo_ender;
   --
   IF v_qt = 0
   THEN
    -- novo usuario enderecado
    v_qt_reg_alt := v_qt_reg_alt + 1;
    --
    IF p_tipo_ender = 'EXE'
    THEN
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
      (p_ordem_servico_id,
       v_usuario_id,
       'EMEX',
       SYSDATE,
       p_tipo_ender,
       v_horas_planej,
       v_sequencia);
    ELSE
     IF p_tipo_ender = 'AVA'
     THEN
      DELETE FROM os_usuario
       WHERE ordem_servico_id = p_ordem_servico_id
         AND usuario_id = v_usuario_id
         AND tipo_ender = 'AVA';
     END IF;
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
      (p_ordem_servico_id,
       v_usuario_id,
       NULL,
       NULL,
       p_tipo_ender,
       v_horas_planej,
       v_sequencia);
    END IF;
   ELSE
    -- usuario ja enderecado. Desmarca a delecao e atualiza
    UPDATE os_usuario
       SET controle     = NULL,
           horas_planej = v_horas_planej,
           sequencia    = v_sequencia
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = v_usuario_id
       AND tipo_ender = p_tipo_ender;
   END IF;
   --
   historico_pkg.hist_ender_registrar(v_usuario_id,
                                      'OS',
                                      p_ordem_servico_id,
                                      p_tipo_ender,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   /*
   -- tenta achar um papel com privilegio
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv_tos pt,
          privilegio pr
    WHERE up.usuario_id = v_usuario_id
      AND up.papel_id = pt.papel_id
      AND pt.tipo_os_id = v_tipo_os_id
      AND pt.privilegio_id = pr.privilegio_id
      AND pr.codigo = DECODE(p_tipo_ender,'SOL','OS_C','DIS','OS_DI','EXE','OS_EX');
   --
   IF v_papel_id IS NOT NULL THEN
      SELECT nome
        INTO v_papel
        FROM papel
       WHERE papel_id = v_papel_id;
   END IF;
   */
   --
   -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'S',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             v_usuario_id,
                             v_apelido || ' indicado como ' || v_tipo_ender_desc || ' no Workflow ' ||
                             v_numero_os_char || ' de ' || v_tipo_os_desc,
                             'Endereçamento Manual de Workflow',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- monta lista de usuarios enderecados para gravar no historico
   v_enderecados := v_enderecados || '; ' || v_apelido;
   /*
   IF v_papel IS NOT NULL THEN
      v_enderecados := v_enderecados || ' (' || v_papel || ')';
   END IF;
   */
  END LOOP;
  --
  -- retira o separador + espaco do comeco
  v_enderecados := substr(v_enderecados, 3);
  --
  -----------------------------------------------------------
  --  tratamaento do cronograma
  -----------------------------------------------------------
  IF p_tipo_ender = 'EXE' AND nvl(v_item_crono_id, 0) > 0
  THEN
   -- exclui usuarios ja associados ao item do cronograma (atividade)
   FOR r_uc IN c_uc
   LOOP
    cronograma_pkg.usuario_excluir(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   v_item_crono_id,
                                   r_uc.usuario_id,
                                   p_erro_cod,
                                   p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
   --
   -- replica usuarios para o item do cronograma (atividade)
   FOR r_us IN c_us
   LOOP
    cronograma_pkg.usuario_adicionar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     'N',
                                     v_item_crono_id,
                                     r_us.usuario_id,
                                     p_erro_cod,
                                     p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- trata usuarios a serem deletados
  ------------------------------------------------------------
  -- conta registros que serao deletados
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND controle = 'DEL'
     AND tipo_ender = p_tipo_ender;
  --
  v_qt_reg_alt := v_qt_reg_alt + v_qt;
  --
  UPDATE os_usuario_data da
     SET da.horas = 0
   WHERE EXISTS (SELECT 1
            FROM os_usuario ou
           WHERE ou.controle = 'DEL'
             AND da.ordem_servico_id = p_ordem_servico_id
             AND ou.ordem_servico_id = da.ordem_servico_id
             AND ou.usuario_id = da.usuario_id
             AND ou.tipo_ender = da.tipo_ender
             AND da.tipo_ender = p_tipo_ender)
     AND da.data > (SELECT re.data_envio
                      FROM os_refacao re
                     INNER JOIN ordem_servico os
                        ON os.ordem_servico_id = re.ordem_servico_id
                     WHERE re.ordem_servico_id = p_ordem_servico_id
                       AND re.num_refacao = os.qtd_refacao);
  --
  DELETE FROM os_usuario_data od
   WHERE EXISTS (SELECT 1
            FROM os_usuario ou
           WHERE ou.ordem_servico_id = p_ordem_servico_id
             AND ou.controle = 'DEL'
             AND ou.tipo_ender = p_tipo_ender
             AND od.ordem_servico_id = ou.ordem_servico_id
             AND od.tipo_ender = ou.tipo_ender
             AND od.usuario_id = ou.usuario_id
             AND od.num_refacao = v_num_refacao) --ALCBO_211124
     AND NOT EXISTS (SELECT 1
            FROM os_usuario_refacao re
           INNER JOIN ordem_servico os
              ON os.ordem_servico_id = re.ordem_servico_id
           WHERE re.usuario_id = od.usuario_id
             AND re.ordem_servico_id = od.ordem_servico_id
             AND re.num_refacao = os.qtd_refacao);
  --
  DELETE FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND controle = 'DEL'
     AND tipo_ender = p_tipo_ender;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = p_tipo_ender;
  --
  IF v_qt = 0 AND p_tipo_ender <> 'AVA'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário ' || v_tipo_ender_desc || ' foi indicado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- trata volta status de EMEX p/ ACEI caso o executor seja alterado
  ------------------------------------------------------------
  v_volta_status := 'N';
  IF p_tipo_ender = 'EXE' AND p_flag_volta_status = 'S' AND v_status_os = 'EMEX' AND
     v_qt_reg_alt > 0
  THEN
   --
   -- verifica se a transicacao p/ voltar status existe
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os_transicao ti,
          os_transicao      ot
    WHERE ti.tipo_os_id = v_tipo_os_id
      AND ti.os_transicao_id = ot.os_transicao_id
      AND ot.status_de = 'EMEX'
      AND ot.status_para = 'ACEI';
   --
   IF v_qt > 0
   THEN
    -- verifica se o usuario da acao eh um executor
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = p_usuario_sessao_id
       AND tipo_ender = 'EXE';
    --
    IF v_qt = 0
    THEN
     -- nao eh o proprio executor. Pode voltar o status
     v_volta_status := 'S';
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  IF p_tipo_ender = 'SOL'
  THEN
   it_controle_pkg.integrar('ORDEM_SERVICO_ATUALIZAR',
                            p_empresa_id,
                            p_ordem_servico_id,
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
  IF p_tipo_ender = 'SOL'
  THEN
   v_cod_acao := 'ENDERECAR_SOL';
  ELSIF p_tipo_ender = 'DIS'
  THEN
   v_cod_acao := 'ENDERECAR_DIS';
  ELSIF p_tipo_ender = 'EXE'
  THEN
   v_cod_acao := 'ENDERECAR_EXE';
  ELSIF p_tipo_ender = 'AVA'
  THEN
   v_cod_acao := 'ENDERECAR_AVA';
  END IF;
  --
  v_identif_objeto := v_numero_os_char;
  v_compl_histor   := 'Endereçados: ' || substr(v_enderecados, 1, 950);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   v_cod_acao,
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  ------------------------------------------------------------
  -- verifica se precisa voltar o status
  ------------------------------------------------------------
  IF v_volta_status = 'S'
  THEN
   -- executa a transicao de status para ACEI
   ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   p_ordem_servico_id,
                                   'RETORNAR',
                                   0,
                                   'Alteração de executores',
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_erro_cod,
                                   p_erro_msg);
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
 END enderecados_atualizar;
 --
 --
 PROCEDURE executores_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/08/2020
  -- DESCRICAO: Atualização de executores da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2020  Atualizacao do prazo interno com a data termino.
  -- Silvia            16/10/2020  Retirada da atualizacao do prazo interno.
  -- Silvia            17/08/2022  Geracao de apontamento a partir de horas alocadas
  -- Silvia            25/04/2023  Ajuste na exclusao de apontam automatico (horas alocadas)
  -- Ana Luiza         18/07/2023  Retirado arredondamento de horas.
  -- Ana Luiza         02/01/2024  Adicionado status_aux e motivo_prazo no update
  -- Ana Luiaz         21/11/2024  Tratando num_refacao os_usuario_data
  -- Ana Luiza         06/02/2025  Adicionando condicao de num_refacao no teste 
  -- Ana Luiza         21/02/2025  Adicionando num_refacao em apontam_data
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_hora_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_hora_termino      IN VARCHAR2,
  p_vetor_enderecados IN LONG,
  p_vetor_datas       IN LONG,
  p_vetor_horas       IN LONG,
  p_flag_volta_status IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_cont                  INTEGER;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_exception             EXCEPTION;
  v_job_id                job.job_id%TYPE;
  v_numero_job            job.numero%TYPE;
  v_status_job            job.status%TYPE;
  v_numero_os_char        VARCHAR2(50);
  v_numero_os             ordem_servico.numero%TYPE;
  v_status_os             ordem_servico.status%TYPE;
  v_data_inicio           ordem_servico.data_inicio%TYPE;
  v_data_termino          ordem_servico.data_termino%TYPE;
  v_data_execucao         ordem_servico.data_execucao%TYPE;
  v_data_inicio_aux       ordem_servico.data_inicio%TYPE;
  v_data_termino_aux      ordem_servico.data_termino%TYPE;
  v_tipo_os               tipo_os.codigo%TYPE;
  v_tipo_os_id            tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc          tipo_os.nome%TYPE;
  v_flag_apont_horas_aloc tipo_os.flag_apont_horas_aloc%TYPE;
  v_delimitador           CHAR(1);
  v_vetor_enderecados     LONG;
  v_vetor_horas           LONG;
  v_vetor_datas           LONG;
  v_data_char             VARCHAR2(20);
  v_horas_char            VARCHAR2(20);
  v_horas_planej          os_usuario.horas_planej%TYPE;
  v_tipo_ender            os_usuario.tipo_ender%TYPE;
  v_data                  os_usuario_data.data%TYPE;
  v_horas                 os_usuario_data.horas%TYPE;
  v_usuario_id            usuario.usuario_id%TYPE;
  v_lbl_job               VARCHAR2(100);
  v_tipo_ender_desc       VARCHAR2(100);
  v_apelido               pessoa.apelido%TYPE;
  v_volta_status          CHAR(1);
  v_qt_reg_alt            NUMBER(5);
  v_enderecados           VARCHAR2(4000);
  v_item_crono_id         item_crono.item_crono_id%TYPE;
  v_flag_planejado        item_crono.flag_planejado%TYPE;
  v_num_refacao           NUMBER(5);
  --
  -- seleciona executores da OS
  CURSOR c_us IS
   SELECT ou.usuario_id,
          pe.apelido,
          ou.controle
     FROM os_usuario ou,
          pessoa     pe
    WHERE ou.ordem_servico_id = p_ordem_servico_id
      AND ou.tipo_ender = v_tipo_ender
      AND ou.usuario_id = pe.usuario_id;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  v_tipo_ender      := 'EXE';
  v_tipo_ender_desc := 'Executor';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         os.data_inicio,
         os.data_termino,
         os.data_execucao,
         ti.flag_apont_horas_aloc
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_data_inicio_aux,
         v_data_termino_aux,
         v_data_execucao,
         v_flag_apont_horas_aloc
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  v_numero_os_char := ordem_servico_pkg.numero_formatar(p_ordem_servico_id);
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'ORDEM_SERVICO'
     AND objeto_id = p_ordem_servico_id;
  --
  IF v_item_crono_id > 0
  THEN
   SELECT flag_planejado
     INTO v_flag_planejado
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_volta_status) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag volta status inválido (' || p_flag_volta_status || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_inicio) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de início é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_inicio) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_inicio) IS NOT NULL AND hora_validar(p_hora_inicio) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de início inválida (' || p_hora_inicio || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_termino) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data de término é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_termino) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida (' || p_data_termino || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_termino) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora de término inválida (' || p_hora_termino || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_inicio  := data_hora_converter(p_data_inicio || ' ' || p_hora_inicio);
  v_data_termino := data_hora_converter(p_data_termino || ' ' || p_hora_termino);
  --
  IF v_data_termino < v_data_inicio
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de término não pode ser anterior à data de início.';
   RAISE v_exception;
  END IF;
  --
  -- salva a data de inicio mais antiga para processar alocacao
  IF v_data_inicio_aux IS NULL OR v_data_inicio < v_data_inicio_aux
  THEN
   v_data_inicio_aux := v_data_inicio;
  END IF;
  --
  IF v_data_execucao < v_data_inicio_aux
  THEN
   v_data_inicio_aux := v_data_execucao;
  END IF;
  --
  -- salva a data de termino mais recente para processar alocacao
  IF v_data_termino_aux IS NULL OR v_data_termino > v_data_termino_aux
  THEN
   v_data_termino_aux := v_data_termino;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de enderecados
  ------------------------------------------------------------
  -- marca todos os registros como candidatos a serem deletados
  UPDATE os_usuario
     SET controle = 'DEL'
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = v_tipo_ender;
  --ALCBO_211124
  SELECT MAX(qtd_refacao)
    INTO v_num_refacao
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --Apaga so se a refacao for a mesma da ordem_servico
  IF v_num_refacao IS NOT NULL
  THEN
   DELETE FROM os_usuario_data
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = v_tipo_ender
      AND trunc(data) >= trunc(v_data_inicio_aux)
      AND num_refacao = v_num_refacao; --ALCBO_211124
  END IF;
  --
  v_vetor_enderecados := TRIM(p_vetor_enderecados);
  v_vetor_horas       := TRIM(p_vetor_horas);
  v_vetor_datas       := TRIM(p_vetor_datas);
  --
  v_qt_reg_alt  := 0;
  v_delimitador := '|';
  v_cont        := 0;
  --
  WHILE nvl(length(rtrim(v_vetor_enderecados)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_enderecados, v_delimitador));
   v_data_char  := prox_valor_retornar(v_vetor_datas, v_delimitador);
   v_horas_char := prox_valor_retornar(v_vetor_horas, v_delimitador);
   v_cont       := v_cont + 1;
   --
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
   --
   IF v_apelido IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe (' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(v_data_char) IS NULL OR data_validar(v_data_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data := data_converter(v_data_char);
   --
   IF numero_validar(v_horas_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Estimativa de horas inválida (' || v_apelido || ': ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas := nvl(numero_converter(v_horas_char), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = v_usuario_id
      AND tipo_ender = v_tipo_ender;
   --
   IF v_qt = 0
   THEN
    -- novo usuario enderecado
    v_qt_reg_alt := v_qt_reg_alt + 1;
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
     (p_ordem_servico_id,
      v_usuario_id,
      'EMEX',
      SYSDATE,
      v_tipo_ender,
      0,
      1);
    --ALCBO_210225
   
   ELSE
    -- usuario ja enderecado. Desmarca a delecao
    UPDATE os_usuario
       SET controle     = NULL,
           status_aux   = 'PEND', --ALCBO_020124
           motivo_prazo = NULL
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = v_usuario_id
       AND tipo_ender = v_tipo_ender;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario_data
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = v_usuario_id
      AND tipo_ender = v_tipo_ender
      AND data = v_data
      AND num_refacao = v_num_refacao; --ALCBO_060225
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_usuario_data
     (ordem_servico_id,
      usuario_id,
      tipo_ender,
      data,
      horas,
      num_refacao) --ALCBO_211124
    VALUES
     (p_ordem_servico_id,
      v_usuario_id,
      v_tipo_ender,
      v_data,
      v_horas,
      v_num_refacao); --ALCBO_211124
   ELSE
    UPDATE os_usuario_data
       SET horas = v_horas
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = v_usuario_id
       AND tipo_ender = v_tipo_ender
       AND data = v_data
       AND num_refacao = v_num_refacao; --ALCBO_211124
   END IF;
   --
   historico_pkg.hist_ender_registrar(v_usuario_id,
                                      'OS',
                                      p_ordem_servico_id,
                                      v_tipo_ender,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'S',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             v_usuario_id,
                             v_apelido || ' indicado como ' || v_tipo_ender_desc || ' no Workflow ' ||
                             v_numero_os_char || ' de ' || v_tipo_os_desc,
                             'Endereçamento Manual de Workflow',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF v_flag_apont_horas_aloc = 'S'
   THEN
    -- apontamento automatico de horas alocadas ligado.
    -- usa as horas alocadas para gerar o apontamento (timesheet)
    apontam_pkg.horas_os_apontar(v_usuario_id,
                                 p_empresa_id,
                                 'N',
                                 p_ordem_servico_id,
                                 data_mostrar(v_data),
                                 numero_mostrar(v_horas, 2, 'N'),
                                 NULL,
                                 p_erro_cod,
                                 p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  -- limpa todas as datas/estimativas dos usuarios
  /*
  UPDATE os_usuario_data da
     SET da.horas = 0
   WHERE EXISTS (SELECT 1
            FROM os_usuario ou
           WHERE ou.controle = 'DEL'
             AND da.ordem_servico_id = p_ordem_servico_id
             AND ou.ordem_servico_id = da.ordem_servico_id
             AND ou.usuario_id = da.usuario_id
             AND ou.tipo_ender = da.tipo_ender
             AND da.tipo_ender = v_tipo_ender)
     AND da.data >= (SELECT re.data_envio
                       FROM os_refacao re
                      INNER JOIN ordem_servico os
                         ON os.ordem_servico_id = re.ordem_servico_id
                      WHERE re.ordem_servico_id = p_ordem_servico_id
                        AND re.num_refacao = os.qtd_refacao);
  --
  DELETE FROM os_usuario_data od
   WHERE EXISTS (SELECT 1
            FROM os_usuario ou
           WHERE ou.ordem_servico_id = p_ordem_servico_id
             AND ou.controle = 'DEL'
             AND ou.tipo_ender = v_tipo_ender
             AND od.ordem_servico_id = ou.ordem_servico_id
             AND od.tipo_ender = ou.tipo_ender
             AND od.usuario_id = ou.usuario_id)
     AND NOT EXISTS (SELECT 1
            FROM os_usuario_refacao re
           WHERE re.ordem_servico_id = p_ordem_servico_id
             AND re.usuario_id = od.usuario_id
             AND re.ordem_servico_id = od.ordem_servico_id);
  --
  */
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = v_tipo_ender
     AND controle IS NULL;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário ' || v_tipo_ender_desc || ' foi indicado.';
   RAISE v_exception;
  END IF;
  --
  UPDATE ordem_servico
     SET data_inicio  = v_data_inicio,
         data_termino = v_data_termino
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- atualizacoes finais dos usuarios executores
  ------------------------------------------------------------
  -- conta registros que serao deletados
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND controle = 'DEL'
     AND tipo_ender = v_tipo_ender;
  --
  v_qt_reg_alt := v_qt_reg_alt + v_qt;
  --
  v_enderecados := NULL;
  --
  FOR r_us IN c_us
  LOOP
   IF r_us.controle = 'DEL'
   THEN
    IF v_flag_apont_horas_aloc = 'S'
    THEN
     -- apontamento automatico de horas alocadas ligado.
     -- exclui eventual apontamento de horas do usuario nessa OS
     DELETE FROM apontam_hora ah
      WHERE ordem_servico_id = p_ordem_servico_id
        AND EXISTS (SELECT 1
               FROM apontam_data ad
              WHERE ad.apontam_data_id = ah.apontam_data_id
                AND ad.usuario_id = r_us.usuario_id
                AND ad.status <> 'ENCE');
    END IF;
    --
    DELETE FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND controle = 'DEL'
       AND tipo_ender = v_tipo_ender
       AND usuario_id = r_us.usuario_id;
   ELSE
    -- monta lista de usuarios enderecados para gravar no historico
    v_enderecados := v_enderecados || '; ' || r_us.apelido;
    --
    SELECT nvl(SUM(horas), 0)
      INTO v_horas_planej
      FROM os_usuario_data
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = r_us.usuario_id
       AND tipo_ender = v_tipo_ender;
    --
    UPDATE os_usuario
       SET horas_planej = v_horas_planej
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = r_us.usuario_id
       AND tipo_ender = v_tipo_ender;
   END IF;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_id,
                                         v_data_inicio_aux,
                                         v_data_termino_aux,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- retira o separador + espaco do comeco
  v_enderecados := substr(v_enderecados, 3);
  --
  -----------------------------------------------------------
  --  tratamento do cronograma
  -----------------------------------------------------------
  IF v_flag_planejado = 'N' AND nvl(v_item_crono_id, 0) > 0
  THEN
   UPDATE item_crono
      SET data_planej_ini = trunc(v_data_inicio),
          data_planej_fim = trunc(v_data_termino)
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- trata volta status de EMEX p/ ACEI caso o executor seja alterado
  ------------------------------------------------------------
  v_volta_status := 'N';
  IF v_tipo_ender = 'EXE' AND p_flag_volta_status = 'S' AND v_status_os = 'EMEX' AND
     v_qt_reg_alt > 0
  THEN
   --
   -- verifica se a transicacao p/ voltar status existe
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os_transicao ti,
          os_transicao      ot
    WHERE ti.tipo_os_id = v_tipo_os_id
      AND ti.os_transicao_id = ot.os_transicao_id
      AND ot.status_de = 'EMEX'
      AND ot.status_para = 'ACEI';
   --
   IF v_qt > 0
   THEN
    -- verifica se o usuario da acao eh um executor
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = p_usuario_sessao_id
       AND tipo_ender = 'EXE';
    --
    IF v_qt = 0
    THEN
     -- nao eh o proprio executor. Pode voltar o status
     v_volta_status := 'S';
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_numero_os_char;
  v_compl_histor   := 'Endereçados: ' || substr(v_enderecados, 1, 950);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ENDERECAR_EXE',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  ------------------------------------------------------------
  -- verifica se precisa voltar o status
  ------------------------------------------------------------
  IF v_volta_status = 'S'
  THEN
   -- executa a transicao de status para ACEI
   ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   p_ordem_servico_id,
                                   'RETORNAR',
                                   0,
                                   'Alteração de executores',
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_erro_cod,
                                   p_erro_msg);
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
 END executores_atualizar;
 --
 --
 PROCEDURE fluxo_papel_desabilitar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/03/2017
  -- DESCRICAO: desabilita o papel indicado nos fluxos de aprovacao em andamento, para
  -- os tipos de OS passados no vetor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_vetor_tipo_os_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_papel_nome       papel.nome%TYPE;
  v_numero_os_char   VARCHAR2(50);
  v_tipo_os_id       tipo_os.tipo_os_id%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_tipo_os_id LONG;
  v_lbl_job          VARCHAR2(100);
  v_tipo_aprov       os_fluxo_aprov.tipo_aprov%TYPE;
  v_usuario_admin_id usuario.usuario_id%TYPE;
  --
  CURSOR c_os IS
   SELECT os.ordem_servico_id,
          os.os_estim_id,
          oe.status AS status_estim
     FROM ordem_servico os,
          os_estim      oe
    WHERE os.tipo_os_id = v_tipo_os_id
      AND os.status = 'EMAP'
      AND os.os_estim_id = oe.os_estim_id(+)
      AND EXISTS (SELECT 1
             FROM os_fluxo_aprov oa
            WHERE oa.ordem_servico_id = os.ordem_servico_id
              AND oa.papel_id = p_papel_id
              AND oa.usuario_aprov_id IS NULL
              AND oa.flag_habilitado = 'S');
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  IF nvl(p_papel_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do papel é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_papel_nome
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo_os
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_tipo_os_id := p_vetor_tipo_os_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_os_id)), 0) > 0
  LOOP
   v_tipo_os_id := to_number(prox_valor_retornar(v_vetor_tipo_os_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os
    WHERE tipo_os_id = v_tipo_os_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Tipo de Workflow não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_os_id) || ').';
    RAISE v_exception;
   END IF;
   --
   FOR r_os IN c_os
   LOOP
    v_numero_os_char := ordem_servico_pkg.numero_formatar(r_os.ordem_servico_id);
    --
    v_tipo_aprov := 'EXE';
    IF nvl(r_os.os_estim_id, 0) > 0 AND r_os.status_estim = 'ANDA'
    THEN
     -- OS em processo de estimativa
     v_tipo_aprov := 'EST';
    END IF;
    --
    UPDATE os_fluxo_aprov
       SET flag_habilitado = 'N'
     WHERE ordem_servico_id = r_os.ordem_servico_id
       AND papel_id = p_papel_id
       AND usuario_aprov_id IS NULL
       AND flag_habilitado = 'S';
    --
    ------------------------------------------------------------
    -- geracao de evento
    ------------------------------------------------------------
    v_identif_objeto := v_numero_os_char;
    v_compl_histor   := 'Desabilitação de papel do fluxo de aprovação (' || v_papel_nome || ')';
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
    --
    IF ordem_servico_pkg.fluxo_seq_ok_verificar(r_os.ordem_servico_id, v_tipo_aprov) = 1
    THEN
     -- nenhuma aprovacao pendente. Precisa executar a transicao como usuário administrador.
     ordem_servico_pkg.acao_executar(v_usuario_admin_id,
                                     p_empresa_id,
                                     'N',
                                     r_os.ordem_servico_id,
                                     'APROVAR',
                                     0,
                                     'Aprovação automática (papel desabilitado)',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     p_erro_cod,
                                     p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
    --
   END LOOP;
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
 END fluxo_papel_desabilitar;
 --
 --
 PROCEDURE fluxo_papel_habilitar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 03/04/2017
  -- DESCRICAO: habilita o papel indicado nos fluxos de aprovacao em andamento, para
  -- os tipos de OS passados no vetor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_vetor_tipo_os_id  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_papel_nome       papel.nome%TYPE;
  v_numero_os_char   VARCHAR2(50);
  v_tipo_os_id       tipo_os.tipo_os_id%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_tipo_os_id LONG;
  v_lbl_job          VARCHAR2(100);
  v_tipo_aprov       os_fluxo_aprov.tipo_aprov%TYPE;
  --
  CURSOR c_os IS
   SELECT os.ordem_servico_id,
          os.os_estim_id,
          oe.status AS status_estim
     FROM ordem_servico os,
          os_estim      oe
    WHERE os.tipo_os_id = v_tipo_os_id
      AND os.status = 'EMAP'
      AND os.os_estim_id = oe.os_estim_id(+)
      AND EXISTS (SELECT 1
             FROM os_fluxo_aprov oa
            WHERE oa.ordem_servico_id = os.ordem_servico_id
              AND oa.papel_id = p_papel_id
              AND oa.usuario_aprov_id IS NULL
              AND oa.flag_habilitado = 'N');
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_papel_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do papel é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_papel_nome
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de tipo_os
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_tipo_os_id := p_vetor_tipo_os_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_os_id)), 0) > 0
  LOOP
   v_tipo_os_id := to_number(prox_valor_retornar(v_vetor_tipo_os_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os
    WHERE tipo_os_id = v_tipo_os_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Tipo de Workflow não existe ou não pertence a essa empresa (' ||
                  to_char(v_tipo_os_id) || ').';
    RAISE v_exception;
   END IF;
   --
   FOR r_os IN c_os
   LOOP
    v_numero_os_char := ordem_servico_pkg.numero_formatar(r_os.ordem_servico_id);
    --
    v_tipo_aprov := 'EXE';
    IF nvl(r_os.os_estim_id, 0) > 0 AND r_os.status_estim = 'ANDA'
    THEN
     -- OS em processo de estimativa
     v_tipo_aprov := 'EST';
    END IF;
    --
    UPDATE os_fluxo_aprov
       SET flag_habilitado = 'S'
     WHERE ordem_servico_id = r_os.ordem_servico_id
       AND papel_id = p_papel_id
       AND usuario_aprov_id IS NULL
       AND flag_habilitado = 'N';
    --
    ------------------------------------------------------------
    -- geracao de evento
    ------------------------------------------------------------
    v_identif_objeto := v_numero_os_char;
    v_compl_histor   := 'Habilitação de papel do fluxo de aprovação (' || v_papel_nome || ')';
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
    --
   END LOOP;
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
 END fluxo_papel_habilitar;
 --
 --
 PROCEDURE fluxo_aprov_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/03/2016
  -- DESCRICAO: subrotina que processa o fluxo de aprovacao de OS.
  --  Retorna o papel_id que permite a aprovacao e a sequencia encontrada.
  --  Quando nao existe uma sequencia definida, retorna 0 no seq_aprov.
  --   NAO FAZ COMMIT
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/03/2017  Novo campo flag_habilitado na tabela os_fluxo_aprov
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov        IN VARCHAR2,
  p_papel_id          OUT papel.papel_id%TYPE,
  p_seq_aprov         OUT os_fluxo_aprov.seq_aprov%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_saida              EXCEPTION;
  v_flag_sequencial    faixa_aprov.flag_sequencial%TYPE;
  v_faixa_aprov_id     faixa_aprov.faixa_aprov_id%TYPE;
  v_qtd_aprov_max      faixa_aprov_papel.seq_aprov%TYPE;
  v_qtd_aprov_atu      faixa_aprov_papel.seq_aprov%TYPE;
  v_seq_aprov          os_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_maior    os_fluxo_aprov.seq_aprov%TYPE;
  v_papel_id           papel.papel_id%TYPE;
  v_papel_aux_id       papel.papel_id%TYPE;
  v_flag_faixa_aprov   ordem_servico.flag_faixa_aprov%TYPE;
  v_flag_aprov_est_seq ordem_servico.flag_aprov_est_seq%TYPE;
  v_flag_aprov_exe_seq ordem_servico.flag_aprov_exe_seq%TYPE;
  v_qtd_fluxo          INTEGER;
  v_flag_admin         usuario.flag_admin%TYPE;
  v_usuario            VARCHAR2(200);
  v_numero_os_char     VARCHAR2(50);
  --
  -- cursor de papeis para aprovacao sequencial
  CURSOR c_ap1 IS
   SELECT up.papel_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 'OS_AP',
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
      AND EXISTS (SELECT 1
             FROM os_fluxo_aprov fa
            WHERE fa.ordem_servico_id = p_ordem_servico_id
              AND fa.tipo_aprov = p_tipo_aprov
              AND fa.papel_id = up.papel_id
              AND fa.seq_aprov = v_seq_aprov
              AND fa.data_aprov IS NULL
              AND fa.flag_habilitado = 'S')
    ORDER BY nvl(pa.ordem, 99999),
             pa.papel_id;
  --
  -- cursor de papeis para aprovacao nao sequencial
  CURSOR c_ap2 IS
   SELECT up.papel_id
     FROM usuario_papel  up,
          os_fluxo_aprov fa,
          papel          pa
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 'OS_AP',
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
      AND fa.ordem_servico_id = p_ordem_servico_id
      AND fa.tipo_aprov = p_tipo_aprov
      AND fa.papel_id = up.papel_id
      AND fa.data_aprov IS NULL
      AND fa.flag_habilitado = 'S'
      AND NOT EXISTS (SELECT 1
             FROM os_fluxo_aprov f2
            WHERE f2.ordem_servico_id = fa.ordem_servico_id
              AND f2.tipo_aprov = fa.tipo_aprov
              AND f2.seq_aprov = fa.seq_aprov
              AND f2.data_aprov IS NOT NULL)
    ORDER BY nvl(pa.ordem, 99999),
             pa.papel_id;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de aprovacao
  ------------------------------------------------------------
  v_faixa_aprov_id := 0;
  v_qtd_fluxo      := 0;
  v_seq_aprov      := 0;
  p_papel_id       := 0;
  p_seq_aprov      := 0;
  --
  SELECT us.flag_admin,
         pe.apelido || '(' || us.login || ')'
    INTO v_flag_admin,
         v_usuario
    FROM usuario us,
         pessoa  pe
   WHERE us.usuario_id = p_usuario_sessao_id
     AND us.usuario_id = pe.usuario_id;
  --
  v_numero_os_char := ordem_servico_pkg.numero_formatar(p_ordem_servico_id);
  --
  SELECT flag_faixa_aprov,
         flag_aprov_est_seq,
         flag_aprov_exe_seq
    INTO v_flag_faixa_aprov,
         v_flag_aprov_est_seq,
         v_flag_aprov_exe_seq
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF p_tipo_aprov = 'EST'
  THEN
   v_flag_sequencial := v_flag_aprov_est_seq;
  ELSE
   v_flag_sequencial := v_flag_aprov_exe_seq;
  END IF;
  --
  IF v_flag_faixa_aprov = 'N'
  THEN
   -- OS criada sem fluxo de aprovacao.
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- OS criada com fluxo de aprovacao.
  -- Verifica se precisa instanciar o fluxo
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qtd_fluxo
    FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_aprov = p_tipo_aprov;
  --
  IF v_qtd_fluxo = 0
  THEN
   -- fluxo nao instanciado.
   -- precisa verificar faixa.
   v_faixa_aprov_id := ordem_servico_pkg.faixa_aprov_id_retornar(p_usuario_sessao_id,
                                                                 p_empresa_id,
                                                                 p_ordem_servico_id,
                                                                 p_tipo_aprov);
   --
   -- retorno 0 indica que nao usa faixa ou o usuario nao necessita de verificacao (admin)
   -- retorno -1 indica que o usuario nao pode aprovar essa OS
   IF v_faixa_aprov_id = -1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não pode aprovar essa faixa de Workflow.';
    RAISE v_exception;
   END IF;
   --
   IF v_faixa_aprov_id > 0
   THEN
    -- precisa instanciar o fluxo
    SELECT flag_sequencial
      INTO v_flag_sequencial
      FROM faixa_aprov
     WHERE faixa_aprov_id = v_faixa_aprov_id;
    --
    INSERT INTO os_fluxo_aprov
     (ordem_servico_id,
      tipo_aprov,
      papel_id,
      seq_aprov,
      flag_habilitado)
     SELECT p_ordem_servico_id,
            p_tipo_aprov,
            papel_id,
            seq_aprov,
            'S'
       FROM faixa_aprov_papel
      WHERE faixa_aprov_id = v_faixa_aprov_id;
    --
    IF p_tipo_aprov = 'EST'
    THEN
     UPDATE ordem_servico
        SET flag_aprov_est_seq = v_flag_sequencial,
            faixa_aprov_est_id = v_faixa_aprov_id
      WHERE ordem_servico_id = p_ordem_servico_id;
    ELSE
     UPDATE ordem_servico
        SET flag_aprov_exe_seq = v_flag_sequencial,
            faixa_aprov_exe_id = v_faixa_aprov_id
      WHERE ordem_servico_id = p_ordem_servico_id;
    END IF;
   END IF;
  END IF; -- fim do IF v_qtd_fluxo = 0
  --
  -- testa novamente para atualizar a qtd
  SELECT COUNT(*)
    INTO v_qtd_fluxo
    FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_aprov = p_tipo_aprov;
  --
  ------------------------------------------------------------
  -- tratamento do fluxo instanciado
  ------------------------------------------------------------
  IF v_qtd_fluxo > 0
  THEN
   -- existe um fluxo em andamento.
   IF v_flag_sequencial = 'S'
   THEN
    ----------------------------------------------------------------
    -- aprovacao deve obedecer a sequencia
    ----------------------------------------------------------------
    -- pega a maior sequencia ja aprovada
    SELECT nvl(MAX(seq_aprov), 0)
      INTO v_seq_aprov_maior
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_aprov = p_tipo_aprov
       AND data_aprov IS NOT NULL;
    --
    -- pega a proxima sequencia com aprovacao pendente
    SELECT nvl(MIN(seq_aprov), 0)
      INTO v_seq_aprov
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_aprov = p_tipo_aprov
       AND data_aprov IS NULL
       AND flag_habilitado = 'S'
       AND seq_aprov > v_seq_aprov_maior;
    --
    IF v_seq_aprov = 0
    THEN
     -- nada a processar
     RAISE v_saida;
    END IF;
    --
    -- Verifica o papel do usuario que pode aprovar nessa sequencia.
    FOR r_ap1 IN c_ap1
    LOOP
     IF v_papel_id IS NULL
     THEN
      -- pega o primeiro papel do cursor
      v_papel_id := r_ap1.papel_id;
     END IF;
    END LOOP;
    --
    IF v_papel_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário ' || v_usuario || ' não tem papel de aprovador para essa sequência ' ||
                   to_char(v_seq_aprov) || ' (' || v_numero_os_char || ' - ' || p_tipo_aprov || ').';
     RAISE v_exception;
    END IF;
    --
    -- marca como aprovado o papel/sequencia encontrados e eventualmente
    -- as proximas sequencias (se forem do mesmo papel).
    v_papel_aux_id := v_papel_id;
    --
    WHILE v_seq_aprov <= v_qtd_fluxo AND v_papel_aux_id = v_papel_id
    LOOP
     UPDATE os_fluxo_aprov
        SET usuario_aprov_id = p_usuario_sessao_id,
            data_aprov       = SYSDATE
      WHERE ordem_servico_id = p_ordem_servico_id
        AND tipo_aprov = p_tipo_aprov
        AND papel_id = v_papel_id
        AND seq_aprov = v_seq_aprov
        AND flag_habilitado = 'S';
     --
     v_seq_aprov := v_seq_aprov + 1;
     --
     SELECT nvl(MAX(papel_id), 0)
       INTO v_papel_aux_id
       FROM os_fluxo_aprov
      WHERE ordem_servico_id = p_ordem_servico_id
        AND tipo_aprov = p_tipo_aprov
        AND papel_id = v_papel_id
        AND seq_aprov = v_seq_aprov
        AND flag_habilitado = 'S';
    END LOOP;
   ELSE
    ----------------------------------------------------------------
    -- aprovacao nao precisa obedecer a sequencia. Verifica o papel
    -- do usuario que pode aprovar em qualquer sequencia ainda nao
    -- aprovada.
    ----------------------------------------------------------------
    FOR r_ap2 IN c_ap2
    LOOP
     IF v_papel_id IS NULL
     THEN
      -- pega o primeiro papel do cursor
      v_papel_id := r_ap2.papel_id;
     END IF;
    END LOOP;
    --
    IF v_papel_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Usuário não tem papel de aprovador para esse fluxo (' || v_usuario || ').';
     RAISE v_exception;
    END IF;
    --
    v_seq_aprov := 0;
    --
    -- marca como aprovada todas as sequencias do papel encontrado
    UPDATE os_fluxo_aprov fa
       SET usuario_aprov_id = p_usuario_sessao_id,
           data_aprov       = SYSDATE
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_aprov = p_tipo_aprov
       AND papel_id = v_papel_id
       AND flag_habilitado = 'S'
       AND data_aprov IS NULL
       AND NOT EXISTS (SELECT 1
              FROM os_fluxo_aprov f2
             WHERE f2.ordem_servico_id = fa.ordem_servico_id
               AND f2.tipo_aprov = fa.tipo_aprov
               AND f2.seq_aprov = fa.seq_aprov
               AND f2.data_aprov IS NOT NULL);
   END IF; -- fim do IF v_flag_sequencial = 'S'
  ELSE
   ----------------------------------------------------------------
   -- fluxo de aprovacao nao encontrado.
   -- pega o papel_id do aprovador para gravar no log
   ----------------------------------------------------------------
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv    pp,
          privilegio    pr
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo IN ('OS_AP', 'OS_DI');
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não tem papel de aprovador.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO os_fluxo_aprov
    (ordem_servico_id,
     tipo_aprov,
     papel_id,
     seq_aprov,
     flag_habilitado,
     data_aprov,
     usuario_aprov_id)
   VALUES
    (p_ordem_servico_id,
     p_tipo_aprov,
     v_papel_id,
     1,
     'S',
     SYSDATE,
     p_usuario_sessao_id);
   --
   IF p_tipo_aprov = 'EST'
   THEN
    UPDATE ordem_servico
       SET flag_aprov_est_seq = 'N'
     WHERE ordem_servico_id = p_ordem_servico_id;
   ELSE
    UPDATE ordem_servico
       SET flag_aprov_exe_seq = 'N'
     WHERE ordem_servico_id = p_ordem_servico_id;
   END IF;
   --
   v_seq_aprov := 1;
  END IF; -- fim do IF v_qtd_fluxo > 0
  --
  p_papel_id  := v_papel_id;
  p_seq_aprov := v_seq_aprov;
  p_erro_cod  := '00000';
  p_erro_msg  := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_papel_id  := v_papel_id;
   p_seq_aprov := v_seq_aprov;
   p_erro_cod  := '00000';
   p_erro_msg  := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END fluxo_aprov_processar;
 --
 --
 PROCEDURE acao_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/02/2013
  -- DESCRICAO: Executa acao de transicao de status da ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/03/2014  Novo parametro complex_refacao
  -- Silvia            31/03/2014  Consistencia de itens no envio, apos refacao.
  -- Silvia            21/11/2014  Consistencia de tamanho da OS.
  -- Silvia            18/03/2015  Nova tabela os_refacao p/ guardar datas.
  -- Silvia            24/03/2015  Nova transicao conclusao imediata.
  -- Silvia            20/05/2015  Novos vetores de job_tipo_produto e arquivo_id
  -- Silvia            25/05/2015  Novos vetores de usuarios avulsos a serem notificados
  -- Silvia            10/12/2015  Novo parametro p_flag_commit
  -- Silvia            11/02/2016  Consiste executores no envio sem distribuicao
  -- Silvia            07/03/2016  Fluxo de aprovacao
  -- Silvia            22/09/2016  Retirada de OS cancelada ou descartada do grupo de estim.
  -- Silvia            28/10/2016  Revisao da obrigatoriedade do tamanho (OS em PREP).
  -- Silvia            22/11/2016  Grava datas/prazos tb da iteracao de estimativa.
  -- Silvia            23/03/2017  Grava data limite p/ distribuicao
  -- Silvia            30/03/2017  Novo campo flag_habilitado na tabela os_fluxo_aprov
  -- Silvia            03/04/2017  Tratamento de conclusao automativa (papel desabilitado).
  -- Silvia            28/06/2017  Nova transicao PREP -> EMAP
  -- Silvia            25/07/2017  Integracao Comunicacao Visual
  -- Silvia            22/09/2017  Recalculo da data da atividade do Cronograma de concl do job
  -- Silvia            14/11/2017  No termino imediato, coloca usuario como executor.
  -- Silvia            15/12/2017  Ajuste no recalculo data JOB_CONC (so qdo ativ planejada).
  -- Silvia            29/03/2018  Horas estimadas na execucao (os_usuario).
  -- Silvia            28/05/2018  Novo parametro de empresa NUM_DIAS_REFAZ_OS.
  -- Silvia            25/06/2018  Novo parametro p_nota_aval
  -- Silvia            25/07/2018  Novo parametro p_vetor_os_link_id
  -- Silvia            13/02/2019  Tratamento de novo atributo flag_em_negociacao
  -- Silvia            06/08/2020  Numa nova distribuição numa refação, retirar o distribuidor
  --                               anterior e acrescentar o atual.
  -- Silvia            12/08/2020  Na distribuicao, copia a data de termino para o prazo interno.
  -- Silvia            18/08/2020  Grava data_execucao. Recalcula alocacao ao termino da exec.
  -- Silvia            24/09/2020  Nao deixa terminar qdo houver pendencia de executor.
  -- Silvia            16/10/2020  Na distribuicao, nao copia mais o prazo interno para o termino
  -- Silvia            20/10/2020  Ajuste na data_solicitada no caso de refacao
  -- Silvia            10/09/2021  Enderecamento automatico de distribuidores na refacao 0
  -- Silvia            24/01/2022  Processa alocacao dos executores no cancelamento
  -- Silvia            08/02/2022  Tratamento de descarte de refacao p/ recuperar data_solicitada
  -- Silvia            01/04/2022  Retirada do parametro p_nota_aval e tabela os_nota_aval
  --                               Retirada de param empresa: USAR_NOTA_AVAL_OS
  -- Silvia            07/04/2022  Grava data_aceite
  -- Silvia            19/04/2022  Novas datas: data_distr, data_aprov_exec, data_aprov_cli
  -- Silvia            09/09/2022  Limpa avaliacao do cliente na refacao
  -- Ana Luiza         17/06/2024  Obrigatoriedade de avaliador
  -- Ana Luiza         26/11/2024  Inclusao de teste para solicitar avaliador
  -- Ana Luiza         20/12/2024  Tratamento num_refacao os_usuario_data
  -- Ana Luiza         16/07/2025  Tratamento para excluir somente se for refação
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_flag_commit            IN VARCHAR2,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_cod_acao_os            IN VARCHAR2,
  p_evento_motivo_id       IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario             IN VARCHAR2,
  p_complex_refacao        IN os_evento.complex_refacao%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_vetor_os_link_id       IN VARCHAR2,
  p_vetor_usuario_id       IN VARCHAR2,
  p_vetor_tipo_notifica    IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_qt_2                   INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_os_evento_id           os_evento.os_evento_id%TYPE;
  v_briefing_id            os_evento.briefing_id%TYPE;
  v_complex_refacao        os_evento.complex_refacao%TYPE;
  v_flag_em_estim          os_evento.flag_estim%TYPE;
  v_cod_acao_ant           os_evento.cod_acao%TYPE;
  v_numero_os_char         VARCHAR2(50);
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_old             ordem_servico.status%TYPE;
  v_status_new             ordem_servico.status%TYPE;
  v_qtd_refacao            ordem_servico.qtd_refacao%TYPE;
  v_num_ref_antes          ordem_servico.qtd_refacao%TYPE;
  v_num_ref_aux            ordem_servico.qtd_refacao%TYPE;
  v_dias_estim             ordem_servico.dias_estim%TYPE;
  v_tamanho                ordem_servico.tamanho%TYPE;
  v_os_estim_id            ordem_servico.os_estim_id%TYPE;
  v_flag_faixa_aprov       ordem_servico.flag_faixa_aprov%TYPE;
  v_data_solicitada        ordem_servico.data_solicitada%TYPE;
  v_data_interna           ordem_servico.data_interna%TYPE;
  v_data_inicio            ordem_servico.data_inicio%TYPE;
  v_data_termino           ordem_servico.data_termino%TYPE;
  v_data_aprov_limite      ordem_servico.data_aprov_limite%TYPE;
  v_data_dist_limite       ordem_servico.data_dist_limite%TYPE;
  v_data_execucao          ordem_servico.data_execucao%TYPE;
  v_distribuidor_id        os_usuario.usuario_id%TYPE;
  v_avaliador_id           os_usuario.usuario_id%TYPE;
  v_flag_tem_itens         tipo_os.flag_tem_itens%TYPE;
  v_flag_tem_tamanho       tipo_os.flag_tem_pontos_tam%TYPE;
  v_flag_obriga_tam        tipo_os.flag_obriga_tam%TYPE;
  v_flag_pode_aval_exec    tipo_os.flag_pode_aval_exec%TYPE;
  v_tipo_os                tipo_os.codigo%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc           tipo_os.nome%TYPE;
  v_tipo_termino_exec      tipo_os.tipo_termino_exec%TYPE;
  v_status_integracao      tipo_os.status_integracao%TYPE;
  v_flag_acei_todas        tipo_os.flag_acei_todas%TYPE;
  v_flag_obriga_apont_exec tipo_os.flag_obriga_apont_exec%TYPE;
  v_flag_estim_horas_usu   tipo_os.flag_estim_horas_usu%TYPE;
  v_usuario_id             usuario.usuario_id%TYPE;
  v_usuario_ant_id         usuario.usuario_id%TYPE;
  v_nota_aval              os_usuario_refacao.nota_aval%TYPE;
  v_os_transicao_id        os_transicao.os_transicao_id%TYPE;
  v_cod_acao_evento        os_transicao.cod_acao_evento%TYPE;
  v_flag_recusa            os_transicao.flag_recusa%TYPE;
  v_cod_priv               os_transicao.cod_priv%TYPE;
  v_motivo                 evento_motivo.nome%TYPE;
  v_arquivo_id_aux         arquivo.arquivo_id%TYPE;
  v_xml                    CLOB;
  v_acao_os_desc           VARCHAR2(100);
  v_lbl_job                VARCHAR2(100);
  v_forca_integracao       CHAR(1);
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(8000);
  v_vetor_arquivo_id       VARCHAR2(8000);
  v_vetor_os_link_id       VARCHAR2(8000);
  v_vetor_usuario_id       VARCHAR2(8000);
  v_vetor_tipo_notifica    VARCHAR2(8000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_arquivo_id             arquivo.arquivo_id%TYPE;
  v_tipo_notifica          notifica_usu_avulso.tipo_notifica%TYPE;
  v_papel_id               papel.papel_id%TYPE;
  v_status_estim           os_estim.status%TYPE;
  v_tipo_aprov             os_fluxo_aprov.tipo_aprov%TYPE;
  v_seq_aprov              os_fluxo_aprov.seq_aprov%TYPE;
  v_os_link_id             os_link.os_link_id%TYPE;
  v_tem_usu_exec_geral     NUMBER(5);
  v_tem_usu_exec_ender     NUMBER(5);
  v_tem_usu_com_priv_geral NUMBER(5);
  v_tem_usu_com_priv_ender NUMBER(5);
  v_qtd_fluxo              INTEGER;
  v_hora_fim               VARCHAR2(10);
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_item_crono_conc_id     item_crono.item_crono_id%TYPE;
  v_data_planej_ini        item_crono.data_planej_ini%TYPE;
  v_data_planej_fim        item_crono.data_planej_fim%TYPE;
  v_duracao                item_crono.duracao_ori%TYPE;
  v_item_crono_pai_id      item_crono.item_crono_pai_id%TYPE;
  v_flag_planejado         item_crono.flag_planejado%TYPE;
  v_num_crono              cronograma.numero%TYPE;
  v_papel_aux_id           papel.papel_id%TYPE;
  v_cod_acao_os            VARCHAR2(100);
  v_flag_recalc_data       VARCHAR2(10);
  v_num_dias_refaz_os      NUMBER(5);
  v_tipo_cliente_agencia   evento_motivo.tipo_cliente_agencia%TYPE;
  v_avaliador              os_usuario.tipo_ender%TYPE;
  v_qt_priv_todos          NUMBER;
  --
  -- seleciona executores da OS
  CURSOR c_ou IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
  -- seleciona usuarios com priv de distribuir
  CURSOR c_od IS
   SELECT usuario_id
     FROM usuario
    WHERE flag_ativo = 'S'
      AND flag_admin = 'N'
      AND usuario_pkg.priv_verificar(usuario_id, 'OS_DI', v_job_id, v_tipo_os_id, p_empresa_id) = 1;
  --
 BEGIN
  v_qt                := 0;
  v_lbl_job           := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_hora_fim          := empresa_pkg.parametro_retornar(p_empresa_id, 'HORA_PADRAO_NOVA_OS');
  v_flag_recalc_data  := empresa_pkg.parametro_retornar(p_empresa_id,
                                                        'RECALC_DATA_CONC_JOB_APEST_OS');
  v_num_dias_refaz_os := empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_DIAS_REFAZ_OS');
  v_cod_acao_os       := TRIM(p_cod_acao_os);
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_acao_os_desc := util_pkg.desc_retornar('cod_acao_os', v_cod_acao_os);
  --
  IF v_acao_os_desc IS NULL OR v_cod_acao_os = 'CRIAR'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || v_cod_acao_os || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         os.qtd_refacao,
         os.data_solicitada,
         os.data_interna,
         os.data_inicio,
         os.data_termino,
         os.tamanho,
         os.os_estim_id,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         ti.flag_tem_itens,
         ti.flag_tem_pontos_tam,
         ti.flag_obriga_tam,
         ti.tipo_termino_exec,
         ti.flag_acei_todas,
         TRIM(ti.status_integracao),
         oe.status,
         os.flag_faixa_aprov,
         nvl(os.dias_estim, 0),
         ti.flag_obriga_apont_exec,
         ti.flag_estim_horas_usu,
         os.data_execucao,
         ti.flag_pode_aval_exec
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_old,
         v_qtd_refacao,
         v_data_solicitada,
         v_data_interna,
         v_data_inicio,
         v_data_termino,
         v_tamanho,
         v_os_estim_id,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_flag_tem_itens,
         v_flag_tem_tamanho,
         v_flag_obriga_tam,
         v_tipo_termino_exec,
         v_flag_acei_todas,
         v_status_integracao,
         v_status_estim,
         v_flag_faixa_aprov,
         v_dias_estim,
         v_flag_obriga_apont_exec,
         v_flag_estim_horas_usu,
         v_data_execucao,
         v_flag_pode_aval_exec
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  v_numero_os_char := numero_formatar(p_ordem_servico_id);
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'ORDEM_SERVICO'
     AND objeto_id = p_ordem_servico_id;
  --
  -- salva o nro da refacao antes da transicao
  v_num_ref_antes := v_qtd_refacao;
  --
  v_flag_em_estim := 'N';
  IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
  THEN
   -- OS em processo de estimativa
   v_flag_em_estim := 'S';
  END IF;
  --
  IF v_status_job IN ('CANC')
  THEN
   IF (v_cod_acao_os = 'REFAZER') OR (v_cod_acao_os = 'RETOMAR' AND v_status_old = 'CANC')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_complex_refacao IS NOT NULL AND
     util_pkg.desc_retornar('complex_refacao', p_complex_refacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade da refação inválida (' || p_complex_refacao || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_acao_os = 'REFAZER' AND v_flag_em_estim = 'N'
  THEN
   IF TRIM(p_complex_refacao) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da complexidade da refação é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   v_complex_refacao := p_complex_refacao;
  ELSE
   v_complex_refacao := NULL;
  END IF;
  --
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = v_job_id
     AND status = 'APROV';
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF (v_cod_acao_os LIKE 'RECUSAR%' OR v_cod_acao_os LIKE 'DESISTIR%' OR
     v_cod_acao_os LIKE 'DESCARTAR%' OR v_cod_acao_os LIKE 'CANCELAR%') AND
     TRIM(p_comentario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do comentário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_comentario) > 1048576
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 1048576 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_transicao      tr,
         tipo_os_transicao ti
   WHERE tr.status_de = v_status_old
     AND tr.cod_acao = v_cod_acao_os
     AND ti.tipo_os_id = v_tipo_os_id
     AND ti.os_transicao_id = tr.os_transicao_id;
  --
  IF v_qt <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (' || v_status_old || ' - ' || v_cod_acao_os || ' - ' ||
                 v_tipo_os_desc || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT tr.os_transicao_id,
         tr.status_para,
         tr.cod_acao_evento,
         tr.flag_recusa,
         tr.cod_priv
    INTO v_os_transicao_id,
         v_status_new,
         v_cod_acao_evento,
         v_flag_recusa,
         v_cod_priv
    FROM os_transicao      tr,
         tipo_os_transicao ti
   WHERE tr.status_de = v_status_old
     AND tr.cod_acao = v_cod_acao_os
     AND ti.tipo_os_id = v_tipo_os_id
     AND ti.os_transicao_id = tr.os_transicao_id;
  --
  IF v_cod_acao_os = 'DESCARTAR' AND v_status_old = 'PREP'
  THEN
   IF v_qtd_refacao < 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Somente Workflows com uma ou mais refações ' ||
                  'podem ter uma refação descartada.';
    RAISE v_exception;
   END IF;
   --
   IF v_qtd_refacao > 0
   THEN
    v_qtd_refacao := v_qtd_refacao - 1;
   END IF;
   --
   -- recupera a data_solicitada para restaurar na OS
   SELECT MAX(data_solicitada)
     INTO v_data_solicitada
     FROM os_refacao
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_qtd_refacao;
   --
   IF v_data_solicitada IS NOT NULL
   THEN
    UPDATE ordem_servico
       SET data_solicitada = v_data_solicitada
     WHERE ordem_servico_id = p_ordem_servico_id;
   END IF;
  END IF;
  --
  IF v_cod_acao_os = 'REFAZER'
  THEN
   v_qtd_refacao := v_qtd_refacao + 1;
  END IF;
  --
  -- verificacoes ao termino da execucao (pendencia de executor)
  IF v_cod_acao_os = 'TERMINAR' AND v_status_old = 'EMEX'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE tipo_ender = 'EXE'
      AND status = 'EMEX'
      AND ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem executores que ainda não terminaram a execução desse Workflow.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- verificacoes ao termino da execucao (apontamentos)
  IF ((v_cod_acao_os = 'TERMINAR' AND v_status_old = 'EMEX') OR
     (v_cod_acao_os = 'SOLICITAR' AND v_status_old = 'EMEX'))
  THEN
   --
   IF v_flag_em_estim = 'N' AND v_data_execucao IS NULL
   THEN
    -- guarda a data da primeira execucao
    v_data_execucao := SYSDATE;
   END IF;
   --ALCBO_011124
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario us
    INNER JOIN pessoa pe
       ON pe.usuario_id = us.usuario_id
    INNER JOIN usuario_papel up
       ON up.usuario_id = us.usuario_id
    INNER JOIN papel_priv_tos ppt
       ON ppt.papel_id = up.papel_id
      AND ppt.privilegio_id = (SELECT privilegio_id
                                 FROM privilegio
                                WHERE codigo = 'OS_AV')
      AND ppt.tipo_os_id = (SELECT tipo_os_id
                              FROM ordem_servico
                             WHERE ordem_servico_id = p_ordem_servico_id)
    WHERE NOT EXISTS (SELECT 1
             FROM os_usuario ou
            WHERE ou.ordem_servico_id = p_ordem_servico_id
              AND ou.usuario_id = pe.usuario_id
              AND ou.tipo_ender = 'AVA')
      AND ppt.abrangencia = 'T';
   -- 
   SELECT COUNT(*)
     INTO v_qt_2
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'AVA';
   --ALCBO_261127
   IF v_cod_acao_os = 'SOLICITAR'
   THEN
    IF v_qt = 0 AND v_qt_2 = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Pelo menos um Avaliador deve ser informado.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF v_flag_obriga_apont_exec = 'S' AND v_flag_em_estim = 'N'
   THEN
    -- verifica se todos os executores apontaram horas nessa OS
    FOR r_ou IN c_ou
    LOOP
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_data ad,
            apontam_hora ah
      WHERE ad.usuario_id = r_ou.usuario_id
        AND ad.apontam_data_id = ah.apontam_data_id
        AND ah.ordem_servico_id = p_ordem_servico_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existem executores que não apontaram horas nesse Workflow.';
      RAISE v_exception;
     END IF;
    END LOOP;
   END IF;
   --
   IF v_flag_estim_horas_usu = 'S' AND v_flag_em_estim = 'S'
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM os_horas
     WHERE ordem_servico_id = p_ordem_servico_id
       AND horas_planej > 0;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não existem horas estimadas para esse Workflow.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF; -- fim das verificacoes ao termino da execucao
  --
  -- verifica tamanho
  IF v_flag_em_estim = 'N' AND v_flag_tem_tamanho = 'S' AND v_flag_obriga_tam = 'S' AND
     TRIM(v_tamanho) IS NULL
  THEN
   IF (v_status_old = 'DIST' AND v_status_new IN ('ACEI', 'EMEX')) OR
      (v_status_old = 'ACEI' AND v_status_new IN ('EMEX')) OR
      (v_status_old = 'PREP' AND v_status_new IN ('CONC')) OR
      (v_status_old = 'PREP' AND v_status_new IN ('EMAP'))
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O tamanho do Workflow ainda não foi informado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- verifica se essa transicao precisa de um motivo
  SELECT COUNT(*)
    INTO v_qt
    FROM evento       ev,
         tipo_objeto  tb,
         tipo_acao    ta,
         os_transicao ot
   WHERE ev.tipo_objeto_id = tb.tipo_objeto_id
     AND tb.codigo = 'ORDEM_SERVICO'
     AND ev.tipo_acao_id = ta.tipo_acao_id
     AND ta.codigo = ot.cod_acao_evento
     AND ot.os_transicao_id = v_os_transicao_id
     AND ev.flag_tem_motivo = 'S';
  --
  IF v_qt > 0 AND nvl(p_evento_motivo_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de ação, o motivo deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_itens = 'S' AND v_status_old = 'PREP' AND
     v_status_new IN ('DIST', 'ACEI', 'CONC', 'EMAP')
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Pelo menos um Entregável deve ser associado ao Workflow.';
    RAISE v_exception;
   END IF;
   --
   IF v_qtd_refacao > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM os_tipo_produto_ref
     WHERE ordem_servico_id = p_ordem_servico_id
       AND num_refacao = v_qtd_refacao;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Pelo menos um Entregável deve ser marcado para essa refação.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  IF nvl(p_evento_motivo_id, 0) > 0
  THEN
   SELECT nome,
          tipo_cliente_agencia
     INTO v_motivo,
          v_tipo_cliente_agencia
     FROM evento_motivo
    WHERE evento_motivo_id = p_evento_motivo_id;
  END IF;
  --ALCBO_240624
  v_vetor_usuario_id := p_vetor_usuario_id;
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   --Verifica se algum usuario tem priv com abrangencia TODOS
   IF usuario_pkg.priv_verificar(v_usuario_id, 'OS_AV', NULL, v_tipo_os_id, p_empresa_id) <> 0
   THEN
    v_qt_priv_todos := v_qt_priv_todos + 1;
   END IF;
  END LOOP;
  --ALCBO_170624
  /*
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = 'AVA';
  --
  IF v_qt_priv_todos = 0 AND v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pelo menos um Avaliador deve ser informado.';
   RAISE v_exception;
  END IF;
  */
  --
  IF v_status_old = 'PREP' AND v_status_new IN ('DIST', 'ACEI', 'CONC', 'EMAP')
  THEN
   --
   IF v_data_solicitada IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A data solicitada não foi definida.';
    RAISE v_exception;
   END IF;
   --
   v_data_interna := v_data_solicitada;
   --
   ordem_servico_pkg.metadados_validar(p_usuario_sessao_id,
                                       p_ordem_servico_id,
                                       p_erro_cod,
                                       p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_old = 'DIST' AND v_status_new IN ('ACEI', 'EMEX')
  THEN
   v_distribuidor_id := p_usuario_sessao_id;
   /*
   -- na distribuicao, copia a data de termino para o prazo interno
   IF v_data_termino IS NOT NULL THEN
      v_data_interna := v_data_termino;
   END IF;
   */
   --
   IF v_num_ref_antes = 0
   THEN
    -- na refacao 0, retira todos os distribuidores para
    -- depois incluir o usuario da sessao.
    DELETE FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_ender = 'DIS';
   END IF;
  END IF;
  IF v_status_old = 'AVAL' AND v_status_new IN ('EXEC')
  THEN
   v_avaliador_id := p_usuario_sessao_id;
   --
   DELETE FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'AVA';
  END IF;
  --
  IF v_status_old = 'PREP' AND v_status_new = 'ACEI'
  THEN
   -- envio sem distribuicao. Verifica executores.
   SELECT COUNT(*)
     INTO v_tem_usu_exec_geral
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE'
      AND rownum = 1;
   --
   SELECT COUNT(*)
     INTO v_tem_usu_exec_ender
     FROM os_usuario ou
    WHERE ou.ordem_servico_id = p_ordem_servico_id
      AND ou.tipo_ender = 'EXE'
      AND EXISTS (SELECT 1
             FROM job_usuario ju
            WHERE ju.job_id = v_job_id
              AND ju.usuario_id = ou.usuario_id)
      AND rownum = 1;
   --
   SELECT COUNT(*)
     INTO v_tem_usu_com_priv_geral
     FROM usuario        us,
          usuario_papel  up,
          papel_priv_tos pp,
          privilegio     pr,
          papel          pa
    WHERE pa.empresa_id = p_empresa_id
      AND pa.papel_id = up.papel_id
      AND up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = 'OS_EX'
      AND pp.tipo_os_id = v_tipo_os_id
      AND pp.abrangencia = 'T'
      AND rownum = 1;
   --
   SELECT COUNT(*)
     INTO v_tem_usu_com_priv_ender
     FROM usuario        us,
          usuario_papel  up,
          papel_priv_tos pp,
          privilegio     pr,
          papel          pa
    WHERE pa.empresa_id = p_empresa_id
      AND pa.papel_id = up.papel_id
      AND up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND up.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = 'OS_EX'
      AND pp.tipo_os_id = v_tipo_os_id
      AND EXISTS (SELECT 1
             FROM job_usuario ju
            WHERE ju.job_id = v_job_id
              AND ju.usuario_id = us.usuario_id)
      AND rownum = 1;
   --
   IF v_flag_acei_todas = 'S'
   THEN
    -- precisa existir usuario com priv ou executor, mesmo nao enderecado
    IF v_tem_usu_exec_geral > 0 OR v_tem_usu_exec_ender > 0 OR v_tem_usu_com_priv_geral > 0 OR
       v_tem_usu_com_priv_ender > 0
    THEN
     NULL;
    ELSE
     p_erro_cod := '90000';
     p_erro_msg := 'Não existem usuários que podem executar esse Workflow.';
     RAISE v_exception;
    END IF;
   ELSE
    -- precisa existir usuario com priv ou executor, enderecado no job
    IF v_tem_usu_exec_ender > 0 OR v_tem_usu_com_priv_ender > 0
    THEN
     NULL;
    ELSE
     p_erro_cod := '90000';
     p_erro_msg := 'Não existem usuários que podem executar esse Workflow.';
     RAISE v_exception;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia de avaliacao
  ------------------------------------------------------------
  IF v_status_old = 'EXEC' AND v_status_new IN ('EMAP', 'CONC') AND v_flag_pode_aval_exec = 'S'
  THEN
   SELECT nvl(MAX(nota_aval), 0)
     INTO v_nota_aval
     FROM os_usuario_refacao
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_sessao_id
      AND tipo_ender = 'SOL'
      AND num_refacao = v_qtd_refacao;
   --
   IF v_nota_aval = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Avalie a execução para prosseguir.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do fluxo de aprovacao
  ------------------------------------------------------------
  IF v_flag_em_estim = 'N'
  THEN
   v_tipo_aprov := 'EXE';
  ELSE
   v_tipo_aprov := 'EST';
  END IF;
  --
  IF (v_flag_em_estim = 'N' AND v_status_old = 'EMAP' AND v_cod_acao_os = 'APROVAR') OR
     (v_flag_em_estim = 'S' AND v_status_old = 'EMAP' AND v_cod_acao_os = 'APROVAR_EST')
  THEN
   --
   IF ordem_servico_pkg.fluxo_seq_ok_verificar(p_ordem_servico_id, v_tipo_aprov) <> 1
   THEN
    -- existem aprovacoes pendentes
    ordem_servico_pkg.fluxo_aprov_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_ordem_servico_id,
                                            v_tipo_aprov,
                                            v_papel_id,
                                            v_seq_aprov,
                                            p_erro_cod,
                                            p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qtd_fluxo
     FROM os_fluxo_aprov
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_aprov = v_tipo_aprov;
   --
   IF v_flag_faixa_aprov = 'S' AND v_qtd_fluxo > 0
   THEN
    IF ordem_servico_pkg.fluxo_seq_ok_verificar(p_ordem_servico_id, v_tipo_aprov) <> 1
    THEN
     -- nao atingiu a qtd de aprovacoes.
     -- Gera evento de notificar aprovadores da vez, e PULA todo o resto do processamento,
     -- nao executando a transicao.
     v_identif_objeto := v_numero_os_char;
     v_compl_histor   := NULL;
     --
     evento_pkg.gerar(p_usuario_sessao_id,
                      p_empresa_id,
                      'ORDEM_SERVICO',
                      'NOTIFICAR_APROV',
                      v_identif_objeto,
                      p_ordem_servico_id,
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
     -- PULA o restante do processamento
     RAISE v_saida;
    END IF;
   END IF;
  END IF; -- fim do APROVAR estimativa ou execucao
  --
  ------------------------------------------------------------
  -- tratamento da primeira iteracao de execucao com estimativa
  ------------------------------------------------------------
  IF v_flag_em_estim = 'S' AND v_status_old IN ('EMAP', 'EXEC') AND v_cod_acao_os = 'APROVAR_EST'
  THEN
   -- recalcula a data_solicitada
   v_dias_estim := dias_depend_retornar(p_ordem_servico_id);
   --
   v_data_solicitada := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           trunc(SYSDATE),
                                                           v_dias_estim,
                                                           'S');
   v_data_solicitada := data_hora_converter(data_mostrar(v_data_solicitada) || ' ' || v_hora_fim);
   --
   v_qtd_refacao := 0;
   --
   UPDATE ordem_servico
      SET data_solicitada = v_data_solicitada
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   UPDATE os_usuario
      SET status      = 'EMEX',
          data_status = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   IF v_flag_recalc_data = 'S'
   THEN
    -- recupera a duracao da atividade de concluir job
    SELECT MAX(ic.duracao_ori),
           MAX(ic.item_crono_id),
           MAX(ic.item_crono_pai_id),
           MAX(cr.numero)
      INTO v_duracao,
           v_item_crono_conc_id,
           v_item_crono_pai_id,
           v_num_crono
      FROM item_crono ic,
           cronograma cr
     WHERE ic.cod_objeto = 'JOB_CONC'
       AND ic.cronograma_id = cr.cronograma_id
       AND cr.job_id = v_job_id
       AND cr.status <> 'ARQUI';
    --
    IF v_duracao IS NOT NULL
    THEN
     -- verifica se a atividade pai eh planejada
     SELECT nvl(MAX(flag_planejado), 'N')
       INTO v_flag_planejado
       FROM item_crono
      WHERE item_crono_id = nvl(v_item_crono_pai_id, 0);
     --
     IF v_flag_planejado = 'S'
     THEN
      -- recalcula as datas dessa atividade
      v_data_planej_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                              trunc(SYSDATE),
                                                              v_duracao - 1,
                                                              'S');
      v_data_planej_ini := trunc(SYSDATE);
      --
      UPDATE item_crono
         SET data_planej_ini = v_data_planej_ini,
             data_planej_fim = v_data_planej_fim,
             num_versao      = v_num_crono
       WHERE item_crono_id = v_item_crono_conc_id;
     END IF;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento da data solicitada e interna em caso de refacao
  ------------------------------------------------------------
  IF v_cod_acao_os = 'REFAZER'
  THEN
   UPDATE ordem_servico
      SET data_solicitada = NULL
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   IF v_flag_em_estim = 'N' AND nvl(v_dias_estim, 0) > 0
   THEN
    -- refacao de OS em iteracao de execucao com estimativa.
    -- usa dias estimados na OS.
    v_data_solicitada := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            trunc(SYSDATE),
                                                            v_dias_estim,
                                                            'S');
    v_data_solicitada := data_hora_converter(data_mostrar(v_data_solicitada) || ' ' || v_hora_fim);
    --
    UPDATE ordem_servico
       SET data_solicitada = v_data_solicitada
     WHERE ordem_servico_id = p_ordem_servico_id;
   END IF;
   --
   -- tratamento da data interna
   v_data_interna := NULL;
  END IF; -- fim do v_cod_acao_os = 'REFAZER'
  --
  ------------------------------------------------------------
  -- tratamento de envio para aprovacao ou OS executada
  ------------------------------------------------------------
  IF (v_status_old IN ('EXEC', 'PREP') AND v_status_new = 'EMAP') OR v_status_new = 'EXEC'
  THEN
   -- Calcula o prazo para aprovacao
   v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                              p_empresa_id,
                                                              SYSDATE,
                                                              'NUM_HORAS_APROV_OS',
                                                              0);
   UPDATE ordem_servico
      SET data_aprov_limite = v_data_aprov_limite
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de envio para distribuicao
  ------------------------------------------------------------
  IF v_status_old = 'PREP' AND v_status_new IN ('DIST', 'ACEI')
  THEN
   -- Calcula o prazo para distribuicao
   v_data_dist_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_DIST_OS',
                                                             0);
   UPDATE ordem_servico
      SET data_dist_limite = v_data_dist_limite
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  IF v_num_ref_antes = 0 AND v_status_old = 'PREP' AND v_status_new = 'DIST'
  THEN
   -- na refacao 0 endereca todos os usuarios com priv de distribuir
   FOR r_od IN c_od
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = r_od.usuario_id
       AND tipo_ender = 'DIS';
    --
    IF v_qt = 0
    THEN
     -- insere o distribuidor
     --
     INSERT INTO os_usuario
      (ordem_servico_id,
       usuario_id,
       tipo_ender,
       flag_lido,
       horas_planej,
       sequencia)
     VALUES
      (p_ordem_servico_id,
       r_od.usuario_id,
       'DIS',
       'N',
       NULL,
       1);
     --
     historico_pkg.hist_ender_registrar(r_od.usuario_id,
                                        'OS',
                                        p_ordem_servico_id,
                                        'DIS',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  ordem_servico_pkg.xml_gerar(p_ordem_servico_id, v_xml, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET qtd_refacao   = v_qtd_refacao,
         status        = v_status_new,
         data_interna  = v_data_interna,
         data_execucao = v_data_execucao
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- tratamento do distribuidor
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = v_distribuidor_id
     AND tipo_ender = 'DIS';
  --
  IF v_qt = 0 AND v_distribuidor_id IS NOT NULL
  THEN
   -- insere o distribuidor atual
   --
   INSERT INTO os_usuario
    (ordem_servico_id,
     usuario_id,
     tipo_ender,
     flag_lido,
     horas_planej,
     sequencia)
   VALUES
    (p_ordem_servico_id,
     v_distribuidor_id,
     'DIS',
     'N',
     NULL,
     1);
   --
   historico_pkg.hist_ender_registrar(v_distribuidor_id,
                                      'OS',
                                      p_ordem_servico_id,
                                      'DIS',
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   /*
   -- tenta achar um papel com privilegio para essa transicao
   SELECT MAX(up.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel_priv_tos pt,
          privilegio pr
    WHERE up.usuario_id = v_distribuidor_id
      AND up.papel_id = pt.papel_id
      AND pt.tipo_os_id = v_tipo_os_id
      AND pt.privilegio_id = pr.privilegio_id
      AND pr.codigo = v_cod_priv;
   */
   --
   -- endereca automaticamente o distribuidor ao job com co-ender e sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'S',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             v_distribuidor_id,
                             'Distribuiu Workflow ' || v_numero_os_char || ' de ' || v_tipo_os_desc,
                             'Distribuição de Workflow',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  IF v_avaliador_id IS NOT NULL
  THEN
   -- insere o distribuidor atual
   --ALCBO_291123
   INSERT INTO os_usuario
    (ordem_servico_id,
     usuario_id,
     tipo_ender,
     flag_lido,
     horas_planej,
     sequencia,
     status_aux)
   VALUES
    (p_ordem_servico_id,
     v_avaliador_id,
     'AVA',
     'N',
     NULL,
     1,
     'PEND');
   --
   historico_pkg.hist_ender_registrar(v_avaliador_id,
                                      'OS',
                                      p_ordem_servico_id,
                                      'AVA',
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   -- endereca automaticamente o distribuidor ao job com co-ender e sem pula notif
   job_pkg.enderecar_usuario(p_usuario_sessao_id,
                             'N',
                             'S',
                             'N',
                             p_empresa_id,
                             v_job_id,
                             v_avaliador_id,
                             'Avaliou Workflow ' || v_numero_os_char || ' de ' || v_tipo_os_desc,
                             'Avaliação de Workflow',
                             p_erro_cod,
                             p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_qtd_refacao > 0 AND v_status_old = 'DIST' AND v_status_new IN ('ACEI', 'EMEX') AND
     v_distribuidor_id > 0
  THEN
   -- exclui eventuais distribuidores antigos
   DELETE FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id <> v_distribuidor_id
      AND tipo_ender = 'DIS';
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de OS cancelada/descartada num grupo de estim
  ------------------------------------------------------------
  IF nvl(v_os_estim_id, 0) > 0 AND v_status_new IN ('CANC', 'DESC')
  THEN
   -- retira a OS do grupo de estimativa
   UPDATE ordem_servico
      SET os_estim_id = NULL
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de OS cancelada (processa alocacao dos executores)
  ------------------------------------------------------------
  IF v_status_new = 'CANC'
  THEN
   -- recalcula alocacao
   SELECT MIN(data),
          MAX(data)
     INTO v_data_inicio,
          v_data_termino
     FROM os_usuario_data
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   IF v_flag_em_estim = 'N'
   THEN
    FOR r_ou IN c_ou
    LOOP
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           r_ou.usuario_id,
                                           v_data_inicio,
                                           v_data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END LOOP;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de OS retomada apos cancelamento ou
  -- OS em aprovação refeita ou devolvida
  ------------------------------------------------------------
  IF (v_status_old = 'CANC' AND v_status_new = 'PREP') OR
     (v_status_old IN ('EMAP', 'CONC') AND v_cod_acao_os IN ('DEVOLVER', 'REFAZER'))
  THEN
   DELETE FROM os_fluxo_aprov
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_aprov = v_tipo_aprov;
   --
   IF v_tipo_aprov = 'EST'
   THEN
    UPDATE ordem_servico
       SET faixa_aprov_est_id = NULL
     WHERE ordem_servico_id = p_ordem_servico_id;
   ELSE
    UPDATE ordem_servico
       SET faixa_aprov_exe_id = NULL
     WHERE ordem_servico_id = p_ordem_servico_id;
   END IF;
  END IF;
  --
  /*
  ------------------------------------------------------------
  -- tratamento de OS em aprovação refeita ou devolvida
  ------------------------------------------------------------
    IF v_status_old IN ('EMAP','CONC') AND v_cod_acao_os IN ('DEVOLVER','REFAZER') THEN
       UPDATE os_fluxo_aprov
          SET data_aprov = NULL,
              usuario_aprov_id = NULL
        WHERE ordem_servico_id = p_ordem_servico_id
          AND tipo_aprov = v_tipo_aprov;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- tratamento de usuario solicitante
  ------------------------------------------------------------
  IF v_status_old = 'PREP' AND v_status_new IN ('DIST', 'ACEI', 'CONC', 'EMAP')
  THEN
   -- verifica se o evento anterior foi uma aprovacao de estimativa
   SELECT MAX(cod_acao),
          MAX(usuario_id)
     INTO v_cod_acao_ant,
          v_usuario_ant_id
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND os_evento_id = (SELECT MAX(os_evento_id)
                            FROM ordem_servico
                           WHERE ordem_servico_id = p_ordem_servico_id);
   --
   IF nvl(v_cod_acao_ant, 'ZZZ') = 'APROVAR_EST' AND nvl(v_usuario_ant_id, 0) = p_usuario_sessao_id
   THEN
    -- o mesmo usuario que aprovou a estimativa deu inicio a uma nova transicao
    -- automatica. Nao marca esse usuario como solicitante.
    NULL;
   ELSE
    -- verifica se o usuario ja eh solicitante
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_ender = 'SOL'
       AND usuario_id = p_usuario_sessao_id;
    --
    IF v_qt = 0
    THEN
     --
     INSERT INTO os_usuario
      (ordem_servico_id,
       usuario_id,
       tipo_ender,
       flag_lido,
       horas_planej,
       sequencia)
     VALUES
      (p_ordem_servico_id,
       p_usuario_sessao_id,
       'SOL',
       'S',
       NULL,
       1);
     --
     historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                        'OS',
                                        p_ordem_servico_id,
                                        'SOL',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     /*
     -- tenta achar um papel com privilegio
     SELECT MAX(up.papel_id)
       INTO v_papel_id
       FROM usuario_papel up,
            papel_priv_tos pt,
            privilegio pr
      WHERE up.usuario_id = p_usuario_sessao_id
        AND up.papel_id = pt.papel_id
        AND pt.tipo_os_id = v_tipo_os_id
        AND pt.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'OS_C';
     */
     --
     -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
     job_pkg.enderecar_usuario(p_usuario_sessao_id,
                               'N',
                               'S',
                               'N',
                               p_empresa_id,
                               v_job_id,
                               p_usuario_sessao_id,
                               'Solicitou Workflow ' || v_numero_os_char || ' de ' ||
                               v_tipo_os_desc,
                               'Solicitação de Workflow',
                               p_erro_cod,
                               p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de negociacao de prazo
  ------------------------------------------------------------
  IF v_status_old IN ('DIST', 'ACEI', 'EMEX') AND v_status_new IN ('DIST', 'ACEI', 'EMEX')
  THEN
   -- a OS manteve um status que pode ter negociacao de prazo.
   NULL;
  ELSE
   -- demais transicoes, encerra eventual negociacao de prazo
   UPDATE ordem_servico
      SET flag_em_negociacao = 'N'
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  IF v_status_old IN ('EXEC', 'AVAL') AND v_status_new = 'EMEX'
  THEN
   -- a OS voltou para em execucao. Verifica se precisa reabrir
   -- a negociacao de prazo.
   SELECT COUNT(*)
     INTO v_qt
     FROM os_negociacao
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_qtd_refacao;
   --
   IF v_qt > 0
   THEN
    -- houve alguma negociacao nessa refacao.
    -- verifica se ela foi aceita (o ultimo registro na tabela
    -- eh de aceitacao)
    SELECT COUNT(*)
      INTO v_qt
      FROM os_negociacao n1
     WHERE n1.ordem_servico_id = p_ordem_servico_id
       AND n1.num_refacao = v_qtd_refacao
       AND n1.cod_acao = 'ACEITAR_PRAZO'
       AND NOT EXISTS (SELECT 1
              FROM os_negociacao n2
             WHERE n2.ordem_servico_id = n1.ordem_servico_id
               AND n2.num_refacao = n1.num_refacao
               AND n2.cod_acao = 'PROPOR_PRAZO'
               AND n2.data_evento > n1.data_evento);
    --
    IF v_qt = 0
    THEN
     -- nao tem aceitacao final. Reabre a negociacao de prazo
     UPDATE ordem_servico
        SET flag_em_negociacao = 'S'
      WHERE ordem_servico_id = p_ordem_servico_id;
    END IF;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de termino da execucao
  ------------------------------------------------------------
  IF v_status_old = 'EMEX' AND v_status_new IN ('AVAL', 'EXEC')
  THEN
   -- a execucao esta sendo terminada
   -- Marca todos usuarios como terminados.
   UPDATE os_usuario
      SET status      = 'EXEC',
          data_status = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   -- registra as horas planejadas na refacao para todos os executores.
   ordem_servico_pkg.usuario_refacao_gravar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_ordem_servico_id,
                                            0,
                                            p_erro_cod,
                                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   SELECT MIN(data),
          MAX(data)
     INTO v_data_inicio,
          v_data_termino
     FROM os_usuario_data
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   -- recalcula alocacao
   IF v_flag_em_estim = 'N'
   THEN
    FOR r_ou IN c_ou
    LOOP
     cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                           p_empresa_id,
                                           r_ou.usuario_id,
                                           v_data_inicio,
                                           v_data_termino,
                                           p_erro_cod,
                                           p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END LOOP;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de execucao retomada
  ------------------------------------------------------------
  IF (v_status_old IN ('AVAL', 'EXEC') AND v_status_new = 'EMEX') OR v_cod_acao_os = 'REFAZER'
  THEN
   -- a execucao esta sendo retomada ou refeita
   --ALCBO_211124 --ALCBO_160725
   IF v_cod_acao_os = 'REFAZER'
   THEN
    DELETE FROM os_usuario
     WHERE tipo_ender = 'EXE'
       AND ordem_servico_id = p_ordem_servico_id;
   END IF;
   /*
   UPDATE os_usuario
      SET status      = 'EMEX',
          data_status = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
   */
   --
   -- limpa dados de avaliacao do cliente
   UPDATE ordem_servico
      SET nota_aval_cli   = NULL,
          data_aval_cli   = NULL,
          coment_aval_cli = NULL
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de usuario executor - aceitacao
  ------------------------------------------------------------
  IF v_status_old = 'ACEI' AND v_status_new = 'EMEX'
  THEN
   -- verifica se o usuario ja eh executor
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_sessao_id
      AND tipo_ender = 'EXE';
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_usuario
     (ordem_servico_id,
      usuario_id,
      status,
      data_status,
      tipo_ender,
      horas_planej,
      sequencia)
    VALUES
     (p_ordem_servico_id,
      p_usuario_sessao_id,
      'EMEX',
      SYSDATE,
      'EXE',
      NULL,
      1);
    --ALCBO_201224
    SELECT qtd_refacao
      INTO v_qt
      FROM ordem_servico
     WHERE ordem_servico_id = p_ordem_servico_id;
    --
    INSERT INTO os_usuario_data
     (ordem_servico_id,
      usuario_id,
      tipo_ender,
      data,
      horas,
      num_refacao)
    VALUES
     (p_ordem_servico_id,
      p_usuario_sessao_id,
      'EXE',
      nvl(v_data_inicio, trunc(SYSDATE)),
      0,
      v_qt);
    --
    historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                       'OS',
                                       p_ordem_servico_id,
                                       'EXE',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    /*
    -- tenta achar um papel com privilegio
    SELECT MAX(up.papel_id)
      INTO v_papel_id
      FROM usuario_papel up,
           papel_priv_tos pt,
           privilegio pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pt.papel_id
       AND pt.tipo_os_id = v_tipo_os_id
       AND pt.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'OS_EX';
    */
    --
    -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'S',
                              'N',
                              p_empresa_id,
                              v_job_id,
                              p_usuario_sessao_id,
                              'Aceitou Workflow para Execução' || v_numero_os_char || ' de ' ||
                              v_tipo_os_desc,
                              'Aceitação de Workflow para Execução',
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
  -- tratamento de usuario executor - termino imediato
  ------------------------------------------------------------
  IF (v_status_old = 'PREP' AND v_status_new = 'CONC') OR
     (v_status_old = 'PREP' AND v_status_new = 'EMAP' AND v_flag_em_estim = 'N')
  THEN
   -- verifica se usuario ja eh executor
   SELECT COUNT(*)
     INTO v_qt
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_sessao_id
      AND tipo_ender = 'EXE';
   --
   IF v_qt = 0
   THEN
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
     (p_ordem_servico_id,
      p_usuario_sessao_id,
      'EXEC',
      SYSDATE,
      'EXE',
      NULL,
      1);
    --ALCBO_201224
    SELECT qtd_refacao
      INTO v_qt
      FROM ordem_servico
     WHERE ordem_servico_id = p_ordem_servico_id;
    --
    INSERT INTO os_usuario_data
     (ordem_servico_id,
      usuario_id,
      tipo_ender,
      data,
      horas,
      num_refacao)
    VALUES
     (p_ordem_servico_id,
      p_usuario_sessao_id,
      'EXE',
      nvl(v_data_inicio, trunc(SYSDATE)),
      0,
      v_qt);
    --
    historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                       'OS',
                                       p_ordem_servico_id,
                                       'EXE',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    /*
    -- tenta achar um papel com privilegio
    SELECT MAX(up.papel_id)
      INTO v_papel_id
      FROM usuario_papel up,
           papel_priv_tos pt,
           privilegio pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pt.papel_id
       AND pt.tipo_os_id = v_tipo_os_id
       AND pt.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'OS_EX';
    */
    --
    -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
    job_pkg.enderecar_usuario(p_usuario_sessao_id,
                              'N',
                              'S',
                              'N',
                              p_empresa_id,
                              v_job_id,
                              p_usuario_sessao_id,
                              'Concluiu Workflow imediatamente' || v_numero_os_char || ' de ' ||
                              v_tipo_os_desc,
                              'Conclusão imediata de Workflow',
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
  -- geracao de OS_EVENTO
  ------------------------------------------------------------
  SELECT seq_os_evento.nextval
    INTO v_os_evento_id
    FROM dual;
  --
  INSERT INTO os_evento
   (os_evento_id,
    ordem_servico_id,
    usuario_id,
    briefing_id,
    data_evento,
    cod_acao,
    comentario,
    num_refacao,
    complex_refacao,
    status_de,
    status_para,
    motivo,
    texto_xml,
    flag_recusa,
    flag_estim,
    tipo_cliente_agencia)
  VALUES
   (v_os_evento_id,
    p_ordem_servico_id,
    p_usuario_sessao_id,
    v_briefing_id,
    SYSDATE,
    v_cod_acao_os,
    TRIM(p_comentario),
    v_qtd_refacao,
    v_complex_refacao,
    v_status_old,
    v_status_new,
    v_motivo,
    v_xml,
    v_flag_recusa,
    v_flag_em_estim,
    v_tipo_cliente_agencia);
  --
  ------------------------------------------------------------
  -- tratamento de refacao
  ------------------------------------------------------------
  IF v_cod_acao_os = 'REFAZER'
  THEN
   ------------------------------------------------------------
   -- vetor de itens a serem refeitos
   ------------------------------------------------------------
   v_delimitador            := '|';
   v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
   --
   WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
   LOOP
    v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM os_tipo_produto
     WHERE job_tipo_produto_id = v_job_tipo_produto_id
       AND ordem_servico_id = p_ordem_servico_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse produto não existe ou não pertence a esse Workflow (' ||
                   to_char(v_job_tipo_produto_id) || ').';
     RAISE v_exception;
    END IF;
    --
    -- marcao produto da refacao anterior para ser refeito
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
    VALUES
     (p_ordem_servico_id,
      v_job_tipo_produto_id,
      v_qtd_refacao,
      SYSDATE);
   END LOOP;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt > 0
   THEN
    -- OS tem itens. Obriga pelo menos 1 a ser refeito
    SELECT COUNT(*)
      INTO v_qt
      FROM os_tipo_produto_ref
     WHERE ordem_servico_id = p_ordem_servico_id
       AND num_refacao = v_qtd_refacao;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Nenhum Entregável foi selecionado para refação.';
     RAISE v_exception;
    END IF;
   END IF;
   --
   ------------------------------------------------------------
   -- vetor de arquivos de execucao a serem refeitos
   ------------------------------------------------------------
   -- move arquivos de "execucao" para "execucao aprovados/aceitos"
   UPDATE arquivo_os
      SET tipo_arq_os = 'EXEC_APR'
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_arq_os = 'EXEC';
   --
   v_delimitador      := '|';
   v_vetor_arquivo_id := p_vetor_arquivo_id;
   --
   WHILE nvl(length(rtrim(v_vetor_arquivo_id)), 0) > 0
   LOOP
    v_arquivo_id := to_number(prox_valor_retornar(v_vetor_arquivo_id, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM arquivo_os
     WHERE arquivo_id = v_arquivo_id
       AND ordem_servico_id = p_ordem_servico_id
       AND tipo_arq_os LIKE 'EXEC%';
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse arquivo não existe ou não pertence a esse Workflow (' ||
                   to_char(v_arquivo_id) || ').';
     RAISE v_exception;
    END IF;
    --
    -- atualiza o arquivo a refazer
    UPDATE arquivo_os
       SET tipo_arq_os = 'EXEC_REP'
     WHERE arquivo_id = v_arquivo_id
       AND ordem_servico_id = p_ordem_servico_id;
   END LOOP;
   --
   ------------------------------------------------------------
   -- vetor de links de execucao a serem refeitos
   ------------------------------------------------------------
   -- atualiza links de "execucao" para "execucao aprovados/aceitos"
   UPDATE os_link
      SET tipo_link = 'EXEC_APR'
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_link = 'EXEC';
   --
   v_delimitador      := '|';
   v_vetor_os_link_id := p_vetor_os_link_id;
   --
   WHILE nvl(length(rtrim(v_vetor_os_link_id)), 0) > 0
   LOOP
    v_os_link_id := to_number(prox_valor_retornar(v_vetor_os_link_id, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM os_link
     WHERE os_link_id = v_os_link_id
       AND ordem_servico_id = p_ordem_servico_id
       AND tipo_link LIKE 'EXEC%';
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse hiperlink não existe ou não pertence a esse Workflow (' ||
                   to_char(v_os_link_id) || ').';
     RAISE v_exception;
    END IF;
    --
    -- atualiza o link a refazer
    UPDATE os_link
       SET tipo_link = 'EXEC_REP'
     WHERE os_link_id = v_os_link_id
       AND ordem_servico_id = p_ordem_servico_id;
   END LOOP;
  END IF; -- fim do IF v_cod_acao_os = 'REFAZER'
  --
  IF v_cod_acao_os = 'DESCARTAR' AND v_status_old = 'PREP'
  THEN
   -- descartou refacao. Apaga produtos da refacao descartada.
   DELETE FROM os_tipo_produto_ref
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao > v_qtd_refacao;
  END IF;
  --
  -- atualiza campos desnormalizados
  UPDATE ordem_servico
     SET os_evento_id  = v_os_evento_id,
         flag_recusada = v_flag_recusa
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- controle de lido / nao lido
  ------------------------------------------------------------
  IF v_status_new IN ('DIST', 'AVAL')
  THEN
   -- marca distribuidor como nao lido
   UPDATE os_usuario
      SET flag_lido = 'N'
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'DIS'
      AND usuario_id <> p_usuario_sessao_id;
  END IF;
  --
  IF v_status_new IN ('AVAL', 'EXEC') OR
     (v_status_new = 'PREP' AND v_status_old IN ('DIST', 'ACEI'))
  THEN
   -- marca solicitante como nao lido
   UPDATE os_usuario
      SET flag_lido = 'N'
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'SOL'
      AND usuario_id <> p_usuario_sessao_id;
  END IF;
  --
  IF v_status_new = 'ACEI' OR (v_status_new = 'EMEX' AND v_status_old = 'DIST')
  THEN
   -- marca executores como nao lido
   UPDATE os_usuario
      SET flag_lido = 'N'
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE'
      AND usuario_id <> p_usuario_sessao_id;
  END IF;
  --
  ------------------------------------------------------------
  -- calculo de datas
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_refacao
   WHERE ordem_servico_id = p_ordem_servico_id
     AND num_refacao = v_num_ref_antes
     AND flag_estim = v_flag_em_estim;
  --
  IF v_qt = 0
  THEN
   INSERT INTO os_refacao
    (ordem_servico_id,
     num_refacao,
     flag_estim,
     data_solicitada,
     data_interna)
   VALUES
    (p_ordem_servico_id,
     v_num_ref_antes,
     v_flag_em_estim,
     v_data_solicitada,
     v_data_interna);
  ELSE
   IF v_flag_em_estim = 'S' AND v_status_old IN ('EMAP', 'EXEC') AND v_cod_acao_os = 'APROVAR_EST'
   THEN
    -- primeira iteracao de execucao com estimativa.
    -- Pula a atualizacao do recalculo da data solicitada (vale apenas para a nova iteracao).
    NULL;
   ELSE
    UPDATE os_refacao
       SET data_solicitada = v_data_solicitada,
           data_interna    = v_data_interna
     WHERE ordem_servico_id = p_ordem_servico_id
       AND num_refacao = v_num_ref_antes
       AND flag_estim = v_flag_em_estim;
   END IF;
  END IF;
  --
  -- salva p/ usar no recalculo de dias
  v_num_ref_aux := v_num_ref_antes;
  --
  -- data de envio
  IF v_status_old = 'PREP' AND v_status_new IN ('DIST', 'ACEI', 'EMAP', 'CONC')
  THEN
   UPDATE os_refacao
      SET data_envio = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- distribuicao
  IF v_status_old = 'DIST' AND v_status_new IN ('ACEI', 'EMEX')
  THEN
   UPDATE os_refacao
      SET data_distr = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- data da aceitacao
  IF v_status_old = 'ACEI' AND v_status_new IN ('EMEX')
  THEN
   UPDATE os_refacao
      SET data_aceite = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- devolucao
  IF v_status_old IN ('DIST', 'ACEI') AND v_status_new = 'PREP'
  THEN
   UPDATE os_refacao
      SET data_envio = NULL
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- data de termino da execucao (ajustado em 11/12/2017)
  IF (v_status_old = 'EMEX' AND v_status_new IN ('EXEC', 'AVAL')) OR
     (v_status_old = 'PREP' AND v_status_new = 'CONC') OR
     (v_status_old = 'PREP' AND v_status_new = 'EMAP')
  THEN
   UPDATE os_refacao
      SET data_termino_exec = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- data de aprovacao da execucao
  IF v_status_old = 'EXEC' AND v_status_new IN ('CONC', 'EMAP', 'PREP')
  THEN
   UPDATE os_refacao
      SET data_aprov_exec = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- data de aprovacao do cliente
  IF v_status_old = 'EMAP' AND v_status_new IN ('CONC', 'PREP')
  THEN
   UPDATE os_refacao
      SET data_aprov_cli = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- retomada da execucao
  IF v_status_old IN ('EXEC', 'AVAL') AND v_status_new = 'EMEX'
  THEN
   UPDATE os_refacao
      SET data_termino_exec = NULL
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- data de conclusao
  IF (v_status_old IN ('EXEC', 'EMAP') AND v_status_new IN ('CONC', 'PREP')) OR
     (v_status_old = 'EXEC' AND v_status_new = 'DESC') OR
     (v_status_old = 'PREP' AND v_status_new = 'CONC')
  THEN
   UPDATE os_refacao
      SET data_conclusao = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  IF v_status_old <> 'CONC' AND v_status_new = 'CONC'
  THEN
   UPDATE ordem_servico
      SET data_conclusao = trunc(SYSDATE)
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  IF v_status_new <> 'CONC'
  THEN
   UPDATE ordem_servico
      SET data_conclusao = NULL
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  -- retomada
  IF v_status_old = 'DESC' AND v_status_new = 'EXEC'
  THEN
   UPDATE os_refacao
      SET data_conclusao = NULL
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_ref_antes
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  -- descarte de refacao
  IF v_status_old = 'PREP' AND v_status_new = 'EXEC'
  THEN
   v_num_ref_aux := v_qtd_refacao;
   --
   UPDATE os_refacao
      SET data_conclusao = NULL
    WHERE ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_qtd_refacao
      AND flag_estim = v_flag_em_estim;
  END IF;
  --
  ordem_servico_pkg.dias_calcular(p_usuario_sessao_id,
                                  p_ordem_servico_id,
                                  v_num_ref_aux,
                                  v_flag_em_estim,
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
  IF v_flag_em_estim = 'N'
  THEN
   -- nao eh um ciclo de estimativa
   v_forca_integracao := 'N';
   --
   IF v_status_old = 'PREP' AND v_status_new = 'CONC' AND v_status_integracao IS NOT NULL
   THEN
    -- Conclusao imediata, mas para esse tipo de OS existe integracao com
    -- sistema externo definida em alguma das transicoes.
    v_forca_integracao := 'S';
   END IF;
   --
   it_controle_pkg.integrar('ORDEM_SERVICO_ACAO_EXECUTAR',
                            p_empresa_id,
                            p_ordem_servico_id,
                            v_forca_integracao,
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
  -- integracao com sistemas externos na aprovacao final
  ------------------------------------------------------------
  IF v_status_old IN ('EXEC', 'EMAP') AND v_status_new = 'CONC'
  THEN
   it_controle_pkg.integrar('ORDEM_SERVICO_MCV_NOTIFICAR',
                            p_empresa_id,
                            p_ordem_servico_id,
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
  v_identif_objeto := v_numero_os_char;
  IF TRIM(p_comentario) IS NOT NULL
  THEN
   v_compl_histor := substr(TRIM(p_comentario), 1, 1000);
  ELSE
   v_compl_histor := 'Execução de transição';
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   v_cod_acao_evento,
                   v_identif_objeto,
                   p_ordem_servico_id,
                   v_compl_histor,
                   v_motivo,
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
  ------------------------------------------------------------
  -- vetor de usuarios avulsos a serem notificados
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_usuario_id    := p_vetor_usuario_id;
  v_vetor_tipo_notifica := p_vetor_tipo_notifica;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id    := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   v_tipo_notifica := prox_valor_retornar(v_vetor_tipo_notifica, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_usu_avulso
    WHERE historico_id = v_historico_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO notifica_usu_avulso
     (historico_id,
      usuario_id,
      tipo_notifica)
    VALUES
     (v_historico_id,
      v_usuario_id,
      v_tipo_notifica);
   END IF;
  END LOOP;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   IF p_flag_commit = 'S'
   THEN
    COMMIT;
   END IF;
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END acao_executar;
 --
 --
 PROCEDURE concluir_cancelar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/10/2016
  -- DESCRICAO: subrotina que conclui/cancela todas as OS de um job ou apenas uma
  --  determinada OS.
  --    NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/04/2018  Novo parametro p_ordem_servico_id, que aceita 0.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  TYPE row_cursor IS REF CURSOR;
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_lbl_job          VARCHAR2(100);
  v_briefing_id      briefing.briefing_id%TYPE;
  v_flag_em_estim    os_evento.flag_estim%TYPE;
  v_texto_xml        os_evento.texto_xml%TYPE;
  v_motivo           os_evento.motivo%TYPE;
  v_comentario       os_evento.comentario%TYPE;
  v_cod_acao         os_evento.cod_acao%TYPE;
  v_apelido          pessoa.apelido%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_status_de        ordem_servico.status%TYPE;
  v_status_para      ordem_servico.status%TYPE;
  v_qtd_refacao      ordem_servico.qtd_refacao%TYPE;
  v_os_estim_id      ordem_servico.os_estim_id%TYPE;
  v_status_estim     os_estim.status%TYPE;
  c_os               row_cursor;
  v_sql              VARCHAR2(10000);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  v_sql := 'SELECT os.ordem_servico_id,' || ' os.status,' || ' os.qtd_refacao,' ||
           ' os.os_estim_id,' || ' oe.status AS status_estim ' || ' FROM ordem_servico os,' ||
           ' os_estim oe ' || ' WHERE os.job_id = ' || to_char(p_job_id) ||
           ' AND os.status NOT IN (''CONC'',''CANC'',''DESC'')' ||
           ' AND os.os_estim_id = oe.os_estim_id (+) ';
  --
  IF nvl(p_ordem_servico_id, 0) > 0
  THEN
   v_sql := v_sql || ' AND os.ordem_servico_id = ' || to_char(p_ordem_servico_id);
  END IF;
  --
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = p_job_id;
  --
  SELECT MAX(apelido)
    INTO v_apelido
    FROM pessoa
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF nvl(p_ordem_servico_id, 0) = 0
  THEN
   -- a subrotina foi chamada via cancelamento do job
   v_motivo     := v_lbl_job || ' cancelado';
   v_comentario := v_lbl_job || ' cancelado por ' || v_apelido;
  ELSE
   -- a subrotina foi chamada via conclusao massiva de OS
   v_motivo     := 'Conclusão/Cancelamento massivo de Workflow';
   v_comentario := 'Workflow concluído/canceladO por ' || v_apelido;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  OPEN c_os FOR v_sql;
  LOOP
   FETCH c_os
   INTO v_ordem_servico_id,
        v_status_de,
        v_qtd_refacao,
        v_os_estim_id,
        v_status_estim;
   EXIT WHEN c_os%NOTFOUND;
   -- gera xml do log
   ordem_servico_pkg.xml_gerar(v_ordem_servico_id, v_texto_xml, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_flag_em_estim := 'N';
   IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
   THEN
    v_flag_em_estim := 'S';
   END IF;
   --
   IF v_status_de IN ('EMAP', 'EXEC')
   THEN
    v_status_para := 'CONC';
    v_cod_acao    := 'APROVAR';
   ELSE
    v_status_para := 'CANC';
    v_cod_acao    := 'CANCELAR';
    -- retira a OS do grupo de estimativa
    v_os_estim_id := NULL;
   END IF;
   --
   UPDATE ordem_servico
      SET status      = v_status_para,
          os_estim_id = v_os_estim_id
    WHERE ordem_servico_id = v_ordem_servico_id;
   --
   INSERT INTO os_evento
    (os_evento_id,
     ordem_servico_id,
     usuario_id,
     briefing_id,
     data_evento,
     cod_acao,
     comentario,
     num_refacao,
     complex_refacao,
     status_de,
     status_para,
     motivo,
     texto_xml,
     flag_recusa,
     flag_estim)
   VALUES
    (seq_os_evento.nextval,
     v_ordem_servico_id,
     p_usuario_sessao_id,
     v_briefing_id,
     SYSDATE,
     v_cod_acao,
     v_comentario,
     v_qtd_refacao,
     NULL,
     v_status_de,
     v_status_para,
     v_motivo,
     v_texto_xml,
     'N',
     v_flag_em_estim);
   --
   -- geracao de evento
   v_identif_objeto := numero_formatar(v_ordem_servico_id);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(p_usuario_sessao_id,
                    p_empresa_id,
                    'ORDEM_SERVICO',
                    v_cod_acao,
                    v_identif_objeto,
                    v_ordem_servico_id,
                    v_compl_histor,
                    v_motivo,
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
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   IF c_os%ISOPEN
   THEN
    CLOSE c_os;
   END IF;
   ROLLBACK;
  WHEN OTHERS THEN
   IF c_os%ISOPEN
   THEN
    CLOSE c_os;
   END IF;
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END concluir_cancelar;
 --
 --
 PROCEDURE concluir_em_massa
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/04/2018
  -- DESCRICAO: Conclusao em massa de ORDEM_SERVICO.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/06/2018  Novo parametro status.
  -- Silvia            05/10/2020  Troca da data_entrada por data_solicitada.
  --                               Novos parametros tipo_os_id, tipo_refacao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_data_de           IN VARCHAR2,
  p_data_ate          IN VARCHAR2,
  p_status            IN VARCHAR2,
  p_tipo_os_id        IN tipo_os.tipo_os_id%TYPE,
  p_tipo_refacao      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_data_de   DATE;
  v_data_ate  DATE;
  v_exception EXCEPTION;
  --
  -- OS a concluir/cancelar SEM tipo_os
  CURSOR c_os IS
   SELECT os.ordem_servico_id,
          os.job_id,
          os.status,
          os.qtd_refacao
     FROM ordem_servico os,
          job           jo
    WHERE os.status NOT IN ('CONC', 'CANC', 'DESC')
      AND trunc(os.data_solicitada) BETWEEN v_data_de AND v_data_ate
      AND os.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id
    ORDER BY os.ordem_servico_id;
  --
  -- OS a concluir/cancelar COM tipo_os
  CURSOR c_ot IS
   SELECT os.ordem_servico_id,
          os.job_id,
          os.status,
          os.qtd_refacao
     FROM ordem_servico os,
          job           jo
    WHERE os.status NOT IN ('CONC', 'CANC', 'DESC')
      AND trunc(os.data_solicitada) BETWEEN v_data_de AND v_data_ate
      AND os.job_id = jo.job_id
      AND os.tipo_os_id = p_tipo_os_id
      AND jo.empresa_id = p_empresa_id
    ORDER BY os.ordem_servico_id;
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
  IF p_tipo_os_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de workflow é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_status) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do status é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_refacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da refação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_refacao NOT IN ('QUALQUER', 'ZERO', 'DIFZERO')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Refação inválida (' || p_tipo_refacao || ').';
   RAISE v_exception;
  END IF;
  --
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
  -- atualizacao do banco para TIPO_OS nao informado
  ------------------------------------------------------------
  IF nvl(p_tipo_os_id, 0) = 0
  THEN
   FOR r_os IN c_os
   LOOP
    IF (p_status = 'TODOS' OR p_status = r_os.status) AND
       (p_tipo_refacao = 'QUALQUER' OR (p_tipo_refacao = 'ZERO' AND r_os.qtd_refacao = 0) OR
       (p_tipo_refacao = 'DIFZERO' AND r_os.qtd_refacao > 0))
    THEN
     ordem_servico_pkg.concluir_cancelar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_os.job_id,
                                         r_os.ordem_servico_id,
                                         p_erro_cod,
                                         p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para TIPO_OS informado
  ------------------------------------------------------------
  IF nvl(p_tipo_os_id, 0) > 0
  THEN
   FOR r_ot IN c_ot
   LOOP
    IF (p_status = 'TODOS' OR p_status = r_ot.status) AND
       (p_tipo_refacao = 'QUALQUER' OR (p_tipo_refacao = 'ZERO' AND r_ot.qtd_refacao = 0) OR
       (p_tipo_refacao = 'DIFZERO' AND r_ot.qtd_refacao > 0))
    THEN
     ordem_servico_pkg.concluir_cancelar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_ot.job_id,
                                         r_ot.ordem_servico_id,
                                         p_erro_cod,
                                         p_erro_msg);
     --
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
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
 END concluir_em_massa;
 --
 PROCEDURE usuario_confirmacao_atividade
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza                   ProcessMind     DATA: 29/11/2023
  -- DESCRICAO: Rotina responsavel por controlar status_aux da tab os_usuario
  -- e os_refacao_usuario
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  --------------------------------------------------------
  -- Ana Luiza         01/02/2024  Adicao do evento
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_vetor_ordem_servico IN VARCHAR2,
  p_vetor_status_aux    IN VARCHAR2,
  p_vetor_motivo        IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_delimitador         CHAR(1);
  v_vetor_ordem_servico VARCHAR2(4000);
  v_vetor_status_aux    VARCHAR2(4000);
  v_vetor_motivo        VARCHAR2(4000);
  --
  v_ordem_servico_id os_usuario.ordem_servico_id%TYPE;
  v_status_aux       os_usuario.status_aux%TYPE;
  v_motivo_prazo     os_usuario_refacao.motivo_prazo%TYPE;
  --
  v_num_refacao    os_usuario_refacao.num_refacao%TYPE;
  v_numero_os_char VARCHAR2(50);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_result  VARCHAR2(2000);
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_ordem_servico := p_vetor_ordem_servico;
  v_vetor_status_aux    := p_vetor_status_aux;
  v_vetor_motivo        := p_vetor_motivo;
  --
  WHILE nvl(length(rtrim(v_vetor_ordem_servico)), 0) > 0
  LOOP
   v_ordem_servico_id := to_number(prox_valor_retornar(v_vetor_ordem_servico, v_delimitador));
   --
   v_status_aux := prox_valor_retornar(v_vetor_status_aux, v_delimitador);
   --
   v_motivo_prazo := prox_valor_retornar(v_vetor_motivo, v_delimitador);
   --
   SELECT MAX(ordem_servico_id)
     INTO v_qt
     FROM os_usuario
    WHERE ordem_servico_id = v_ordem_servico_id;
   --
   IF v_qt IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Workflow não existe ' || v_ordem_servico_id;
    RAISE v_exception;
   END IF;
   --
   IF length(TRIM(v_status_aux)) > 20
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O status auxiliar do Workflow não pode ter mais que
                      20 caracteres (' || v_status_aux || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(TRIM(v_motivo_prazo)) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O motivo não pode ter mais que
                      500 caracteres (' || v_motivo_prazo || ').';
    RAISE v_exception;
   END IF;
   ------------------------------------------------------------
   -- recuperacao de dados
   ------------------------------------------------------------
   SELECT MAX(num_refacao)
     INTO v_num_refacao
     FROM os_usuario_refacao osf
    WHERE osf.ordem_servico_id = v_ordem_servico_id;
   -------------------------------------------------------
   --Alteracao banco de dados
   -------------------------------------------------------
   --
   IF v_status_aux IN ('PRAZ')
   THEN
    UPDATE os_usuario osu
       SET osu.status_aux   = v_status_aux,
           osu.motivo_prazo = v_motivo_prazo
     WHERE osu.ordem_servico_id = v_ordem_servico_id
       AND osu.tipo_ender = 'EXE'
       AND osu.usuario_id = p_usuario_sessao_id;
   END IF;
   --
   IF v_status_aux IN ('PEND', 'ATRA')
   THEN
    UPDATE os_usuario osu
       SET osu.status_aux   = v_status_aux,
           osu.motivo_prazo = v_motivo_prazo
     WHERE osu.ordem_servico_id = v_ordem_servico_id
       AND osu.tipo_ender = 'EXE'
       AND osu.usuario_id = p_usuario_sessao_id;
    --
    UPDATE os_usuario_refacao osr
       SET osr.status_aux   = v_status_aux,
           osr.motivo_prazo = v_motivo_prazo
     WHERE osr.ordem_servico_id = v_ordem_servico_id
       AND osr.num_refacao = v_num_refacao
       AND osr.tipo_ender = 'EXE'
       AND osr.usuario_id = p_usuario_sessao_id;
   END IF;
   --
  END LOOP;
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  IF v_status_aux = 'PEND'
  THEN
   v_status_result := 'Status pendente.';
  ELSIF v_status_aux = 'ATRA'
  THEN
   v_status_result := 'Indicou que não vai terminar no prazo.';
  ELSIF v_status_aux = 'PRAZ'
  THEN
   v_status_result := 'Indicou que vai terminar no prazo.';
  ELSE
   v_status_result := 'Status desconhecido';
  END IF;
  --
  IF v_motivo_prazo IS NOT NULL
  THEN
   v_status_result := v_status_result || ' Motivo: ' || v_motivo_prazo;
  END IF;
  --
  v_numero_os_char := numero_formatar(v_ordem_servico_id);
  v_identif_objeto := v_numero_os_char;
  v_compl_histor   := v_status_result;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END usuario_confirmacao_atividade;
 --
 PROCEDURE usuario_refacao_gravar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 07/04/2022
  -- DESCRICAO: subrotina que grava na tabela OS_USUARIO_REFACAO dados de horas
  --   planejadas para um executor em especifico (qdo p_usuario_executor_id > 0)
  --   ou para todos os executores (qdo p_usuario_executor_id = 0).
  --    NAO FAZ COMMIT
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         06/12/2023  Adicionado status_aux
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt           INTEGER;
  v_exception    EXCEPTION;
  v_num_refacao  ordem_servico.qtd_refacao%TYPE;
  v_horas_planej os_usuario.horas_planej%TYPE;
  --
  CURSOR c_us IS
   SELECT usuario_id,
          nvl(horas_planej, 0) horas_planej
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- recuperacao de dados
  ------------------------------------------------------------
  SELECT MAX(os.qtd_refacao)
    INTO v_num_refacao
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_us IN c_us
  LOOP
   IF nvl(p_usuario_executor_id, 0) = 0 OR nvl(p_usuario_executor_id, 0) = r_us.usuario_id
   THEN
    --
    SELECT nvl(SUM(horas), 0)
      INTO v_horas_planej
      FROM os_usuario_data
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = r_us.usuario_id
       AND tipo_ender = 'EXE';
    --
    IF v_horas_planej = 0
    THEN
     -- nao existem horas planejadas para o executor por data.
     -- tenta pegar o total planejado para o usuario.
     v_horas_planej := r_us.horas_planej;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario_refacao
     WHERE ordem_servico_id = p_ordem_servico_id
       AND usuario_id = r_us.usuario_id
       AND tipo_ender = 'EXE'
       AND num_refacao = v_num_refacao;
    --
    IF v_qt = 0
    THEN
     --ALCBO_061223
     INSERT INTO os_usuario_refacao
      (ordem_servico_id,
       usuario_id,
       tipo_ender,
       num_refacao,
       nota_aval,
       data_aval,
       horas_planej,
       data_termino,
       status_aux)
     VALUES
      (p_ordem_servico_id,
       r_us.usuario_id,
       'EXE',
       v_num_refacao,
       0,
       SYSDATE,
       v_horas_planej,
       SYSDATE,
       'PEND');
    ELSE
     UPDATE os_usuario_refacao
        SET horas_planej = v_horas_planej,
            data_termino = SYSDATE
      WHERE ordem_servico_id = p_ordem_servico_id
        AND usuario_id = r_us.usuario_id
        AND tipo_ender = 'EXE'
        AND num_refacao = v_num_refacao;
    END IF;
   END IF;
  END LOOP;
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
 END usuario_refacao_gravar;
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 03/09/2013
  -- DESCRICAO: marca o trabalho de um determinado usuario executor como terminado
  --   (executado).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/04/2016  Verificacao de apontamentos.
  -- Silvia            03/11/2016  Evento de termino individual/parcial
  -- Silvia            01/04/2022  Tratamento de avaliacao do WF pelo executor
  -- Silvia            06/04/2022  Guarda horas planejadas
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_num_refacao            ordem_servico.qtd_refacao%TYPE;
  v_os_estim_id            ordem_servico.os_estim_id%TYPE;
  v_tipo_os                tipo_os.codigo%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc           tipo_os.nome%TYPE;
  v_flag_obriga_apont_exec tipo_os.flag_obriga_apont_exec%TYPE;
  v_flag_estim_horas_usu   tipo_os.flag_estim_horas_usu%TYPE;
  v_flag_pode_aval_solic   tipo_os.flag_pode_aval_solic%TYPE;
  v_status_usu             os_usuario.status%TYPE;
  v_horas_planej           os_usuario.horas_planej%TYPE;
  v_flag_em_estim          os_evento.flag_estim%TYPE;
  v_status_estim           os_estim.status%TYPE;
  v_nota_aval              os_usuario_refacao.nota_aval%TYPE;
  v_exec_apelido           pessoa.apelido%TYPE;
  v_exec_login             usuario.login%TYPE;
  v_usu_apelido            pessoa.apelido%TYPE;
  v_usu_login              usuario.login%TYPE;
  v_lbl_job                VARCHAR2(100);
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         os.qtd_refacao,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         ti.flag_obriga_apont_exec,
         ti.flag_estim_horas_usu,
         oe.os_estim_id,
         oe.status,
         ti.flag_pode_aval_solic
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_num_refacao,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_flag_obriga_apont_exec,
         v_flag_estim_horas_usu,
         v_os_estim_id,
         v_status_estim,
         v_flag_pode_aval_solic
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  IF v_status_os <> 'EMEX'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_flag_em_estim := 'N';
  IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
  THEN
   -- OS em processo de estimativa
   v_flag_em_estim := 'S';
  END IF;
  --
  SELECT pe.apelido,
         us.login
    INTO v_usu_apelido,
         v_usu_login
    FROM pessoa  pe,
         usuario us
   WHERE pe.usuario_id = p_usuario_sessao_id
     AND pe.usuario_id = us.usuario_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(status)
    INTO v_status_usu
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_executor_id
     AND tipo_ender = 'EXE';
  --
  IF v_status_usu IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário executor não encontrado.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_usu <> 'EMEX'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do usuário executor não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.apelido,
         us.login
    INTO v_exec_apelido,
         v_exec_login
    FROM pessoa  pe,
         usuario us
   WHERE pe.usuario_id = p_usuario_executor_id
     AND pe.usuario_id = us.usuario_id;
  --
  SELECT nvl(SUM(horas), 0)
    INTO v_horas_planej
    FROM os_usuario_data
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_executor_id
     AND tipo_ender = 'EXE';
  --
  IF v_flag_obriga_apont_exec = 'S' AND v_flag_em_estim = 'N'
  THEN
   -- verifica se o executor apontou horas nessa OS
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_data ad,
          apontam_hora ah
    WHERE ad.usuario_id = p_usuario_executor_id
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário ' || v_exec_apelido || ' ainda não apontou horas nesse Workflow.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_estim_horas_usu = 'S' AND v_flag_em_estim = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM os_horas
    WHERE ordem_servico_id = p_ordem_servico_id
      AND horas_planej > 0;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existem horas estimadas para esse Workflow.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_flag_pode_aval_solic = 'S'
  THEN
   SELECT nvl(MAX(nota_aval), 0)
     INTO v_nota_aval
     FROM os_usuario_refacao
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_executor_id
      AND tipo_ender = 'EXE'
      AND num_refacao = v_num_refacao;
   --
   IF v_nota_aval = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Avalie a solicitação antes de terminar.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_usuario
     SET status      = 'EXEC',
         data_status = SYSDATE
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_executor_id
     AND tipo_ender = 'EXE';
  --
  -- eh o proprio executor que esta terminando.
  -- registra as horas planejadas na refacao.
  IF p_usuario_sessao_id <> p_usuario_executor_id
  THEN
   ordem_servico_pkg.usuario_refacao_gravar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_ordem_servico_id,
                                            p_usuario_executor_id,
                                            p_erro_cod,
                                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := NULL;
  IF p_usuario_sessao_id <> p_usuario_executor_id
  THEN
   v_compl_histor := 'Terminado por: ' || v_usu_apelido || ' - ' || v_usu_login;
  END IF;
  --
  -- o usuario da sessao nao vai para o historico pois sera necessario saber o executor
  -- cujo trabalho foi terminado, para gerar notificacoes para os demais
  evento_pkg.gerar(p_usuario_executor_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'TERMINAR_PARC',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END terminar;
 --
 --
 PROCEDURE retomar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 03/09/2013
  -- DESCRICAO: marca o trabalho de um determinado usuario executor como retomado
  --   (volta para em execucao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         27/06/2024  Trativa se vier 0 da web não faz nada
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_numero_os      ordem_servico.numero%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_tipo_os        tipo_os.codigo%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc   tipo_os.nome%TYPE;
  v_status_usu     os_usuario.status%TYPE;
  v_exec_apelido   pessoa.apelido%TYPE;
  v_exec_login     usuario.login%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --ACLBO_270624
  IF p_usuario_executor_id = 0
  THEN
   RETURN; --PULA TODA A VERIFICACAO
  END IF;
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF v_status_os NOT IN ('EMEX', 'EXEC', 'AVAL')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(status)
    INTO v_status_usu
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_executor_id
     AND tipo_ender = 'EXE';
  --
  IF v_status_usu IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário executor não encontrado.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_usu <> 'EXEC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do usuário executor não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT pe.apelido,
         us.login
    INTO v_exec_apelido,
         v_exec_login
    FROM pessoa  pe,
         usuario us
   WHERE pe.usuario_id = p_usuario_executor_id
     AND pe.usuario_id = us.usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- 
  UPDATE os_usuario
     SET status      = 'EMEX',
         data_status = SYSDATE
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_executor_id
     AND tipo_ender = 'EXE';
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := v_exec_apelido || ' (' || v_exec_login || ') - Retomado';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END retomar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 19/10/2007
  -- DESCRICAO: Exclusão de ORDEM_SERVICO
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/12/2010  Consistencia de apontamento de horas.
  --                               Exclusao automatica de tipo_produto_os.
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS.
  -- Silvia            10/03/2014  Exclusao automatica de os_tipo_produto_ref.
  -- Silvia            18/03/2015  Exclusao automatica de os_refacao.
  -- Silvia            07/07/2015  Exclusao de arquivos qdo OS em preparacao
  -- Silvia            19/01/2016  Tratamento de cronograma
  -- Silvia            25/07/2018  Tratamento de hiperlink (os_link)
  -- Silvia            22/07/2020  Consistencia de Tarefa.
  -- Silvia            25/08/2020  Recalculo das alocacoes dos executores excluidos
  -- Silvia            28/03/2022  Tabela os_nota_aval substiuida por os_usuario_refacao
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_numero_os       ordem_servico.numero%TYPE;
  v_status_os       ordem_servico.status%TYPE;
  v_data_inicio     ordem_servico.data_inicio%TYPE;
  v_data_termino    ordem_servico.data_termino%TYPE;
  v_tipo_os_id      tipo_os.tipo_os_id%TYPE;
  v_tipo_os         tipo_os.codigo%TYPE;
  v_tipo_os_desc    VARCHAR2(100);
  v_item_crono_id   item_crono.item_crono_id%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_lbl_job         VARCHAR2(100);
  --
  CURSOR c_arq_os IS
   SELECT arquivo_id
     FROM arquivo_os
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- seleciona executores da OS
  CURSOR c_us IS
   SELECT usuario_id
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
  -- seleciona executores do item do cronograma
  CURSOR c_uc IS
   SELECT usuario_id
     FROM item_crono_usu
    WHERE item_crono_id = v_item_crono_id;
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome,
         os.data_inicio,
         os.data_termino
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc,
         v_data_inicio,
         v_data_termino
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_E', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  IF v_status_os <> 'PREP'
  THEN
   -- deixa excluir arquivos apenas no status Em Preparacao
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_os
    WHERE ordem_servico_id = p_ordem_servico_id
      AND rownum = 1;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Workflow tem arquivos associados.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE ordem_servico_id = p_ordem_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow já foi referenciado em apontamento de horas.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_afazer
   WHERE ordem_servico_id = p_ordem_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe TO-DO List relacionado a esse Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE ordem_servico_ori_id = p_ordem_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow tem itens que foram refeitos num novo Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE ordem_servico_id = p_ordem_servico_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow está sendo referenciado por Tasks.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono ic
   WHERE cod_objeto = 'ORDEM_SERVICO'
     AND objeto_id = p_ordem_servico_id
     AND EXISTS (SELECT 1
            FROM item_crono_usu iu
           WHERE iu.item_crono_id = ic.item_crono_id);
  --
  IF nvl(v_item_crono_id, 0) > 0
  THEN
   SELECT data_planej_ini,
          data_planej_fim
     INTO v_data_planej_ini,
          v_data_planej_fim
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- integracao com sistemas externos
  ------------------------------------------------------------
  it_controle_pkg.integrar('ORDEM_SERVICO_EXCLUIR',
                           p_empresa_id,
                           p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  ------------------------------------------------------------
  -- exclusoes dos usuarios executores
  ------------------------------------------------------------
  SELECT MIN(data),
         MAX(data)
    INTO v_data_inicio,
         v_data_termino
    FROM os_usuario_data
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_ender = 'EXE';
  --
  DELETE FROM os_usuario_data
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  FOR r_us IN c_us
  LOOP
   DELETE FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = r_us.usuario_id
      AND tipo_ender = 'EXE';
   --
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_id,
                                         v_data_inicio,
                                         v_data_termino,
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
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_arq_os IN c_arq_os
  LOOP
   -- verifica o arquivo eh usado por outra OS
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_os
    WHERE arquivo_id = r_arq_os.arquivo_id
      AND ordem_servico_id <> p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    -- nao esta. Pode excluir o arquivo.
    arquivo_pkg.excluir(p_usuario_sessao_id, r_arq_os.arquivo_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- esta associado a outras. Exclui apenas o relacionamento.
    DELETE FROM arquivo_os
     WHERE arquivo_id = r_arq_os.arquivo_id
       AND ordem_servico_id = p_ordem_servico_id;
   END IF;
  END LOOP;
  --
  DELETE FROM hist_ender
   WHERE tipo_objeto = 'OS'
     AND objeto_id = p_ordem_servico_id;
  --
  DELETE FROM os_tp_atributo_valor
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_atributo_valor
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_horas
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_tipo_produto_ref
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id;
  UPDATE ordem_servico
     SET os_evento_id = NULL
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_evento
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_refacao
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_usuario_refacao
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_link
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_negociacao
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id;
  DELETE FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- exclui produtos que ficaram soltos (sem nenhuma OS associada e sem
  -- nenhuma tarefa associada)
  DELETE FROM job_tipo_produto jp
   WHERE jp.job_id = v_job_id
     AND NOT EXISTS (SELECT 1
            FROM os_tipo_produto op
           WHERE jp.job_tipo_produto_id = op.job_tipo_produto_id)
     AND NOT EXISTS (SELECT 1
            FROM tarefa_tipo_produto tp
           WHERE jp.job_tipo_produto_id = tp.job_tipo_produto_id);
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  UPDATE item_crono ic
     SET objeto_id = NULL
   WHERE cod_objeto = 'ORDEM_SERVICO'
     AND objeto_id = p_ordem_servico_id;
  --
  IF nvl(v_item_crono_id, 0) > 0
  THEN
   FOR r_uc IN c_uc
   LOOP
    -- recalcula alocacao dos executores do cronograma
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_uc.usuario_id,
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
 PROCEDURE refazer_em_nova
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/07/2014
  -- DESCRICAO: refacao parcial de itens em nova OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/05/2015  Novo vetor de arquivo_id
  -- Silvia            20/01/2016  Tratamento de cronograma
  -- Silvia            26/03/2018  Tipo de demanda.
  -- Silvia            29/03/2018  Horas estimadas na execucao (os_usuario).
  -- Silvia            25/07/2018  Novo parametro p_vetor_os_link_id
  -- Silvia            11/11/2021  Copia os_usuario_data com horas zeradas
  -- Ana Luiza         16/10/2024  Alteracao tipo de dado para clob comentario
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_evento_motivo_id       IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario             IN CLOB,
  p_complex_refacao        IN os_evento.complex_refacao%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_vetor_arquivo_id       IN VARCHAR2,
  p_vetor_os_link_id       IN VARCHAR2,
  p_ordem_servico_new_id   OUT ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_emp_resp_id            job.emp_resp_id%TYPE;
  v_os_evento_id           os_evento.os_evento_id%TYPE;
  v_briefing_id            os_evento.briefing_id%TYPE;
  v_numero_os              ordem_servico.numero%TYPE;
  v_numero_os_aux          ordem_servico.numero%TYPE;
  v_status_os_old          ordem_servico.status%TYPE;
  v_descricao_os_old       ordem_servico.descricao%TYPE;
  v_ordem_servico_new_id   ordem_servico.ordem_servico_id%TYPE;
  v_comentario             VARCHAR2(8000);
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_tipo_os_cod            tipo_os.codigo%TYPE;
  v_motivo                 evento_motivo.nome%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(8000);
  v_vetor_arquivo_id       VARCHAR2(8000);
  v_vetor_os_link_id       VARCHAR2(8000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_padrao_numeracao_os    VARCHAR2(50);
  v_cod_emp_resp           empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_cod_empresa            empresa_sist_ext.cod_ext_empresa%TYPE;
  v_sistema_externo_id     sistema_externo.sistema_externo_id%TYPE;
  v_num_os_old             VARCHAR2(100);
  v_qt_item_old            NUMBER(10);
  v_comentario_id          comentario.comentario_id%TYPE;
  v_arquivo_id             arquivo.arquivo_id%TYPE;
  v_cronograma_id          item_crono.cronograma_id%TYPE;
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_os_link_id             os_link.os_link_id%TYPE;
  --
  CURSOR c_co IS
   SELECT co.comentario_id,
          co.tipo_objeto_id,
          co.usuario_id,
          co.comentario_pai_id,
          co.objeto_id,
          co.data_coment,
          co.comentario,
          co.classe
     FROM comentario  co,
          tipo_objeto ti
    WHERE co.objeto_id = p_ordem_servico_id
      AND co.tipo_objeto_id = ti.tipo_objeto_id
      AND ti.codigo = 'ORDEM_SERVICO'
      AND co.classe = 'PRINCIPAL'
      AND co.comentario_pai_id IS NULL
    ORDER BY co.comentario_id;
  --
 BEGIN
  v_qt                   := 0;
  p_ordem_servico_new_id := 0;
  v_lbl_job              := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_padrao_numeracao_os  := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_OS');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF v_padrao_numeracao_os NOT IN ('SEQUENCIAL_POR_JOB', 'SEQUENCIAL_POR_TIPO_OS') OR
     TRIM(v_padrao_numeracao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Padrão de numeração de Workflow inválido ou não definido (' ||
                 v_padrao_numeracao_os || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         jo.emp_resp_id,
         os.status,
         os.tipo_os_id,
         ti.codigo,
         ordem_servico_pkg.numero_formatar(os.ordem_servico_id),
         os.descricao
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_emp_resp_id,
         v_status_os_old,
         v_tipo_os_id,
         v_tipo_os_cod,
         v_num_os_old,
         v_descricao_os_old
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_transicao      tr,
         tipo_os_transicao ti
   WHERE tr.status_de = v_status_os_old
     AND tr.cod_acao = 'REFAZER'
     AND ti.tipo_os_id = v_tipo_os_id
     AND ti.os_transicao_id = tr.os_transicao_id;
  --
  IF v_qt <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (' || v_status_os_old || ' - ' || 'REFAZER' || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = v_job_id
     AND status = 'APROV';
  --
  -- recupera dados para gerar numero da OS por tipo, com base em
  -- numeracao ja existente em sistemas legados.
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE tipo_sistema = 'FIN'
     AND flag_ativo = 'S';
  --
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_empresa
    FROM empresa_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND empresa_id = p_empresa_id;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_emp_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  IF nvl(p_evento_motivo_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_comentario) > 1048576
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 1048576 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_refacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da complexidade da refação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_refacao', p_complex_refacao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade da refação inválida (' || p_complex_refacao || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_evento_motivo_id, 0) > 0
  THEN
   SELECT nome
     INTO v_motivo
     FROM evento_motivo
    WHERE evento_motivo_id = p_evento_motivo_id;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_JOB'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico
    WHERE job_id = v_job_id;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_TIPO_OS'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico os,
          tipo_os       ti
    WHERE os.job_id = v_job_id
      AND os.tipo_os_id = ti.tipo_os_id
      AND ti.codigo = v_tipo_os_cod;
   --
   -- verifica numeracao de sistema legado
   SELECT nvl(MAX(num_ult_os), 0) + 1
     INTO v_numero_os_aux
     FROM numero_os
    WHERE cod_empresa = v_cod_empresa
      AND cod_emp_resp = v_cod_emp_resp
      AND num_job = v_numero_job
      AND cod_tipo_os = v_tipo_os_cod;
   --
   IF v_numero_os_aux > v_numero_os
   THEN
    v_numero_os := v_numero_os_aux;
   END IF;
  END IF;
  --
  --
  SELECT COUNT(*)
    INTO v_qt_item_old
    FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_ordem_servico.nextval
    INTO v_ordem_servico_new_id
    FROM dual;
  --
  INSERT INTO ordem_servico
   (ordem_servico_id,
    ordem_servico_ori_id,
    job_id,
    tipo_os_id,
    tipo_financeiro_id,
    numero,
    descricao,
    data_entrada,
    data_solicitada,
    data_interna,
    texto_os,
    qtd_refacao,
    status,
    tamanho,
    cod_hash,
    flag_faixa_aprov,
    flag_com_estim,
    flag_estim_custo,
    flag_estim_prazo,
    flag_estim_arq,
    flag_estim_horas_usu,
    flag_estim_obs,
    flag_exec_estim,
    demanda)
   SELECT v_ordem_servico_new_id,
          p_ordem_servico_id,
          job_id,
          tipo_os_id,
          tipo_financeiro_id,
          v_numero_os,
          descricao,
          SYSDATE,
          NULL,
          NULL,
          texto_os,
          0,
          'PREP',
          tamanho,
          rawtohex(sys_guid()),
          flag_faixa_aprov,
          flag_com_estim,
          flag_estim_custo,
          flag_estim_prazo,
          flag_estim_arq,
          flag_estim_horas_usu,
          flag_estim_obs,
          flag_exec_estim,
          'IME'
     FROM ordem_servico
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  INSERT INTO os_usuario
   (ordem_servico_id,
    usuario_id,
    tipo_ender,
    flag_lido,
    horas_planej,
    sequencia)
   SELECT v_ordem_servico_new_id,
          usuario_id,
          tipo_ender,
          'N',
          NULL,
          1
     FROM os_usuario
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  INSERT INTO os_usuario_data
   (ordem_servico_id,
    usuario_id,
    tipo_ender,
    data,
    horas,
    num_refacao)
   SELECT v_ordem_servico_new_id,
          usuario_id,
          tipo_ender,
          data,
          0,
          0
     FROM os_usuario_data
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = 'EXE';
  --
  -- a execucao esta sendo refeita
  UPDATE os_usuario
     SET status      = 'EMEX',
         data_status = SYSDATE
   WHERE ordem_servico_id = v_ordem_servico_new_id
     AND tipo_ender = 'EXE';
  --
  INSERT INTO os_atributo_valor
   (ordem_servico_id,
    metadado_id,
    valor_atributo)
   SELECT v_ordem_servico_new_id,
          metadado_id,
          valor_atributo
     FROM os_atributo_valor
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- vetor de itens a serem refeitos
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe ou não pertence a esse Workflow (' ||
                  to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- bloqueia o item na OS original
   UPDATE os_tipo_produto
      SET flag_bloqueado = 'S'
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   INSERT INTO os_tipo_produto
    (ordem_servico_id,
     job_tipo_produto_id,
     descricao,
     num_refacao,
     tempo_exec_prev,
     fator_tempo_calc,
     data_entrada,
     obs,
     quantidade)
    SELECT v_ordem_servico_new_id,
           v_job_tipo_produto_id,
           descricao,
           0,
           tempo_exec_prev,
           fator_tempo_calc,
           data_entrada,
           'Refeito no Workflow: ' || v_num_os_old,
           quantidade
      FROM os_tipo_produto
     WHERE ordem_servico_id = p_ordem_servico_id
       AND job_tipo_produto_id = v_job_tipo_produto_id;
   --
   INSERT INTO os_tipo_produto_ref
    (ordem_servico_id,
     job_tipo_produto_id,
     num_refacao,
     data_entrada)
   VALUES
    (v_ordem_servico_new_id,
     v_job_tipo_produto_id,
     0,
     SYSDATE);
   --
   INSERT INTO os_tp_atributo_valor
    (ordem_servico_id,
     job_tipo_produto_id,
     metadado_id,
     valor_atributo)
    SELECT v_ordem_servico_new_id,
           v_job_tipo_produto_id,
           metadado_id,
           valor_atributo
      FROM os_tp_atributo_valor
     WHERE ordem_servico_id = p_ordem_servico_id
       AND job_tipo_produto_id = v_job_tipo_produto_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- vetor de arquivos a serem refeitos
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_arquivo_id := p_vetor_arquivo_id;
  --
  WHILE nvl(length(rtrim(v_vetor_arquivo_id)), 0) > 0
  LOOP
   v_arquivo_id := to_number(prox_valor_retornar(v_vetor_arquivo_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_os
    WHERE arquivo_id = v_arquivo_id
      AND ordem_servico_id = p_ordem_servico_id
      AND tipo_arq_os LIKE 'EXEC%';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse arquivo não existe ou não pertence a esse Workflow (' ||
                  to_char(v_arquivo_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- atualiza o arquivo na OS original
   UPDATE arquivo_os
      SET tipo_arq_os = 'EXEC_REP'
    WHERE arquivo_id = v_arquivo_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   -- copia o arquivo para a nova OS
   INSERT INTO arquivo_os
    (arquivo_id,
     ordem_servico_id,
     tipo_arq_os,
     flag_thumb,
     chave_thumb,
     num_refacao)
    SELECT v_arquivo_id,
           v_ordem_servico_new_id,
           'EXEC_REP',
           flag_thumb,
           chave_thumb,
           0
      FROM arquivo_os
     WHERE ordem_servico_id = p_ordem_servico_id
       AND arquivo_id = v_arquivo_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- vetor de links de execucao a serem refeitos
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_os_link_id := p_vetor_os_link_id;
  --
  WHILE nvl(length(rtrim(v_vetor_os_link_id)), 0) > 0
  LOOP
   v_os_link_id := to_number(prox_valor_retornar(v_vetor_os_link_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_link
    WHERE os_link_id = v_os_link_id
      AND ordem_servico_id = p_ordem_servico_id
      AND tipo_link LIKE 'EXEC%';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse hiperlink não existe ou não pertence a esse Workflow (' ||
                  to_char(v_os_link_id) || ').';
    RAISE v_exception;
   END IF;
   --
   -- atualiza o link na OS original
   UPDATE os_link
      SET tipo_link = 'EXEC_REP'
    WHERE os_link_id = v_os_link_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   -- copia o link para a nova OS
   INSERT INTO os_link
    (os_link_id,
     ordem_servico_id,
     usuario_id,
     data_entrada,
     tipo_link,
     url,
     descricao,
     num_refacao)
    SELECT seq_os_link.nextval,
           v_ordem_servico_new_id,
           p_usuario_sessao_id,
           SYSDATE,
           'EXEC_REP',
           url,
           descricao,
           0
      FROM os_link
     WHERE ordem_servico_id = p_ordem_servico_id
       AND os_link_id = v_os_link_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencias finais
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tipo_produto
   WHERE ordem_servico_id = v_ordem_servico_new_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum Entregável foi selecionado para refação.';
   RAISE v_exception;
  END IF;
  --
  IF v_qt = v_qt_item_old
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para refazer todos os Entregáveis use a refação normal do Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- copia dos comentarios
  ------------------------------------------------------------
  FOR r_co IN c_co
  LOOP
   -- loop por comentario raiz
   SELECT seq_comentario.nextval
     INTO v_comentario_id
     FROM dual;
   --
   -- copia comentario raiz para a nova OS
   INSERT INTO comentario
    (comentario_id,
     tipo_objeto_id,
     usuario_id,
     comentario_pai_id,
     objeto_id,
     data_coment,
     comentario,
     classe)
   VALUES
    (v_comentario_id,
     r_co.tipo_objeto_id,
     r_co.usuario_id,
     NULL,
     v_ordem_servico_new_id,
     r_co.data_coment,
     r_co.comentario,
     r_co.classe);
   --
   -- copia os filhos do comentario raiz para a nova OS
   INSERT INTO comentario
    (comentario_id,
     tipo_objeto_id,
     usuario_id,
     comentario_pai_id,
     objeto_id,
     data_coment,
     comentario,
     classe)
    SELECT seq_comentario.nextval,
           tipo_objeto_id,
           usuario_id,
           v_comentario_id,
           v_ordem_servico_new_id,
           data_coment,
           comentario,
           classe
      FROM comentario
     WHERE objeto_id = p_ordem_servico_id
       AND tipo_objeto_id = r_co.tipo_objeto_id
       AND classe = 'PRINCIPAL'
       AND comentario_pai_id = r_co.comentario_id;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(v_job_id);
  --
  IF nvl(v_cronograma_id, 0) = 0
  THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_job_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- cria a atividade de OS
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'ORDEM_SERVICO',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- vincula a atividade de OS a OS criada
  UPDATE item_crono
     SET objeto_id = v_ordem_servico_new_id,
         nome      = nvl(v_descricao_os_old, 'Workflow ' || numero_formatar(v_ordem_servico_new_id))
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  SELECT seq_os_evento.nextval
    INTO v_os_evento_id
    FROM dual;
  --
  v_comentario := 'Criado a partir do Workflow: ' || v_num_os_old;
  IF TRIM(p_comentario) IS NOT NULL
  THEN
   v_comentario := substr(v_comentario || ' - ' || TRIM(p_comentario), 1, 2000);
  END IF;
  --
  INSERT INTO os_evento
   (os_evento_id,
    ordem_servico_id,
    usuario_id,
    briefing_id,
    data_evento,
    cod_acao,
    num_refacao,
    status_de,
    status_para,
    motivo,
    complex_refacao,
    comentario,
    flag_recusa,
    flag_estim)
  VALUES
   (v_os_evento_id,
    v_ordem_servico_new_id,
    p_usuario_sessao_id,
    v_briefing_id,
    SYSDATE,
    'CRIAR',
    0,
    NULL,
    'PREP',
    v_motivo,
    p_complex_refacao,
    v_comentario,
    'N',
    'N');
  --
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         v_ordem_servico_new_id,
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
  it_controle_pkg.integrar('ORDEM_SERVICO_ADICIONAR',
                           p_empresa_id,
                           v_ordem_servico_new_id,
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
  v_identif_objeto := numero_formatar(v_ordem_servico_new_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_ordem_servico_new_id,
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
  p_ordem_servico_new_id := v_ordem_servico_new_id;
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
 END refazer_em_nova;
 --
 --
 PROCEDURE concluir_automatico
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 11/01/2017
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a concluir
  --     automaticamente OS executadas, caso o parametro esteja ligado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/02/2021  Eliminacao do parametro NUM_DIAS_CONC_OS
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_num_dias_conc_os NUMBER(10);
  v_empresa_id       empresa.empresa_id%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_data_exec        DATE;
  v_usuario_admin_id usuario.usuario_id%TYPE;
  --
  CURSOR c_em IS
   SELECT empresa_id
     FROM empresa
    WHERE flag_ativo = 'S'
    ORDER BY empresa_id;
  --
  -- OS executadas na iteracao de execucao
  CURSOR c_os IS
   SELECT os.ordem_servico_id,
          ti.num_dias_conc_os
     FROM ordem_servico os,
          tipo_os       ti,
          job           jo,
          os_estim      oe
    WHERE os.job_id = jo.job_id
      AND jo.empresa_id = v_empresa_id
      AND os.status = 'EXEC'
      AND os.tipo_os_id = ti.tipo_os_id
      AND ti.num_dias_conc_os > 0
      AND os.os_estim_id = oe.os_estim_id(+)
      AND (os.os_estim_id IS NULL OR oe.status = 'CONC')
    ORDER BY os.ordem_servico_id;
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
  FOR r_em IN c_em
  LOOP
   v_empresa_id := r_em.empresa_id;
   --
   FOR r_os IN c_os
   LOOP
    v_ordem_servico_id := r_os.ordem_servico_id;
    v_num_dias_conc_os := r_os.num_dias_conc_os;
    --
    v_data_exec := ordem_servico_pkg.data_retornar(v_ordem_servico_id, 'EXEC');
    --
    IF v_data_exec IS NOT NULL AND trunc(v_data_exec) + v_num_dias_conc_os < trunc(SYSDATE)
    THEN
     -- tenta executar transicao de status para CONC
     ordem_servico_pkg.acao_executar(v_usuario_admin_id,
                                     v_empresa_id,
                                     'N',
                                     v_ordem_servico_id,
                                     'APROVAR',
                                     0,
                                     'Conclusão automática de Workflow Executado',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     v_erro_cod,
                                     v_erro_msg);
     COMMIT;
    END IF;
   END LOOP;
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
     'ordem_servico_pkg.concluir_automatico',
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
     'ordem_servico_pkg.concluir_automatico',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END concluir_automatico;
 --
 --
 PROCEDURE custo_estimar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 09/12/2015
  -- DESCRICAO: Atualização de custo e prazo estimado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/03/2017  Novo parametro: obs_estim
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_custo_estim       IN VARCHAR2,
  p_dias_estim        IN VARCHAR2,
  p_obs_estim         IN VARCHAR2,
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
  v_tipo_os_id       tipo_os.tipo_os_id%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_custo_estim      ordem_servico.custo_estim%TYPE;
  v_dias_estim       ordem_servico.dias_estim%TYPE;
  v_flag_estim_custo ordem_servico.flag_estim_custo%TYPE;
  v_flag_estim_prazo ordem_servico.flag_estim_prazo%TYPE;
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ti.tipo_os_id,
         os.flag_estim_custo,
         os.flag_estim_prazo
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_tipo_os_id,
         v_flag_estim_custo,
         v_flag_estim_prazo
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_EX', v_job_id, v_tipo_os_id, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_flag_estim_custo = 'S' AND TRIM(p_custo_estim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do custo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_custo_estim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo inválido.';
   RAISE v_exception;
  END IF;
  --
  v_custo_estim := nvl(moeda_converter(p_custo_estim), 0);
  --
  IF v_custo_estim < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Custo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_estim_prazo = 'S' AND TRIM(p_dias_estim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_dias_estim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo inválido.';
   RAISE v_exception;
  END IF;
  --
  v_dias_estim := nvl(to_number(p_dias_estim), 0);
  --
  IF v_dias_estim < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Prazo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_obs_estim)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As observações não podem ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET custo_estim = v_custo_estim,
         dias_estim  = v_dias_estim,
         obs_estim   = TRIM(p_obs_estim)
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Estimativa de custo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END custo_estimar;
 --
 --
 PROCEDURE estimativa_aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2015
  -- DESCRICAO: Aprovacao de estimativa de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_estim_id       IN ordem_servico.os_estim_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_saida           EXCEPTION;
  v_lbl_job         VARCHAR2(100);
  v_status_estim    os_estim.status%TYPE;
  v_num_estim       os_estim.num_estim%TYPE;
  v_cod_acao_os     os_transicao.cod_acao%TYPE;
  v_data_solicitada ordem_servico.data_solicitada%TYPE;
  --
  CURSOR c_os IS
   SELECT jo.job_id,
          jo.status              AS status_job,
          os.ordem_servico_id,
          os.status              AS status_os,
          os.dias_estim,
          os.tipo_os_id,
          ti.codigo              AS cod_tipo_os,
          ti.flag_tem_pontos_tam AS flag_tem_tamanho,
          os.tamanho
     FROM ordem_servico os,
          job           jo,
          tipo_os       ti
    WHERE os.os_estim_id = p_os_estim_id
      AND os.job_id = jo.job_id
      AND os.tipo_os_id = ti.tipo_os_id;
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
    FROM os_estim
   WHERE os_estim_id = p_os_estim_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa estimativa de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         num_estim
    INTO v_status_estim,
         v_num_estim
    FROM os_estim
   WHERE os_estim_id = p_os_estim_id;
  --
  IF v_status_estim = 'CONC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa não permite essa operação';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- primeira parte da atualizacao (pode haver fluxo de aprovacao)
  ------------------------------------------------------------
  FOR r_os IN c_os
  LOOP
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OS_AP',
                                 r_os.job_id,
                                 r_os.tipo_os_id,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   -- tenta executar transicao de status para PREP
   ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   r_os.ordem_servico_id,
                                   'APROVAR_EST',
                                   0,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_erro_cod,
                                   p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE os_estim_id = p_os_estim_id
     AND status <> 'PREP';
  --
  IF v_qt > 0
  THEN
   -- existe aprovacao pendente. Pula o processamento.
   RAISE v_saida;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_estim
     SET status      = 'CONC',
         data_status = SYSDATE
   WHERE os_estim_id = p_os_estim_id;
  --
  FOR r_os IN c_os
  LOOP
   -- seleciona o codigo da acao para enviar (com ou sem distribuicao)
   SELECT MAX(tr.cod_acao)
     INTO v_cod_acao_os
     FROM os_transicao      tr,
          tipo_os_transicao ti
    WHERE tr.status_de = 'PREP'
      AND tr.cod_acao LIKE 'ENVIAR%DIST'
      AND ti.tipo_os_id = r_os.tipo_os_id
      AND ti.os_transicao_id = tr.os_transicao_id;
   --
   IF v_cod_acao_os IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Código da ação ENVIAR não encontrado para esse tipo de Workflow (' ||
                  r_os.cod_tipo_os || ') .';
    RAISE v_exception;
   END IF;
   --
   -- executa transicao de enviar
   ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   r_os.ordem_servico_id,
                                   v_cod_acao_os,
                                   0,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_erro_cod,
                                   p_erro_msg);
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
  WHEN v_saida THEN
   COMMIT;
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END estimativa_aprovar;
 --
 --
 PROCEDURE estimativa_recusar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/12/2015
  -- DESCRICAO: Recusa de estimativa de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_estim_id       IN ordem_servico.os_estim_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN CLOB,
  p_complex_refacao   IN os_evento.complex_refacao%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_lbl_job         VARCHAR2(100);
  v_status_estim    os_estim.status%TYPE;
  v_num_estim       os_estim.num_estim%TYPE;
  v_cod_acao_os     os_transicao.cod_acao%TYPE;
  v_data_solicitada ordem_servico.data_solicitada%TYPE;
  v_complex_refacao VARCHAR2(20);
  --
  CURSOR c_os IS
   SELECT jo.job_id,
          jo.status           AS status_job,
          os.ordem_servico_id,
          os.status           AS status_os,
          os.dias_estim,
          os.tipo_os_id,
          ti.codigo           AS cod_tipo_os
     FROM ordem_servico os,
          job           jo,
          tipo_os       ti
    WHERE os.os_estim_id = p_os_estim_id
      AND os.job_id = jo.job_id
      AND os.tipo_os_id = ti.tipo_os_id;
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
    FROM os_estim
   WHERE os_estim_id = p_os_estim_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa estimativa de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         num_estim
    INTO v_status_estim,
         v_num_estim
    FROM os_estim
   WHERE os_estim_id = p_os_estim_id;
  --
  IF v_status_estim = 'CONC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa não permite essa operação';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_refacao) IS NULL
  THEN
   SELECT MAX(codigo)
     INTO v_complex_refacao
     FROM dicionario
    WHERE tipo = 'complex_refacao';
  ELSE
   v_complex_refacao := p_complex_refacao;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_os IN c_os
  LOOP
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'OS_AP',
                                 r_os.job_id,
                                 r_os.tipo_os_id,
                                 p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
   --
   -- executa transicao de status para PREP
   ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                   p_empresa_id,
                                   'N',
                                   r_os.ordem_servico_id,
                                   'REFAZER',
                                   p_evento_motivo_id,
                                   p_comentario,
                                   v_complex_refacao,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   p_erro_cod,
                                   p_erro_msg);
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
 END estimativa_recusar;
 --
 --
 PROCEDURE lido_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/12/2013
  -- DESCRICAO: marca a ordem de servico como lida pela usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_usuario
     SET flag_lido = 'S'
   WHERE ordem_servico_id = p_ordem_servico_id
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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/12/2013
  -- DESCRICAO: marca a ordem de servico como nao lida pela usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_usuario
     SET flag_lido = 'N'
   WHERE ordem_servico_id = p_ordem_servico_id
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
 END nao_lido_marcar;
 --
 --
 PROCEDURE metadados_validar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 12/04/2013
  -- DESCRICAO: subrotina de validacao de metadados de uma determinadada OS (tanto do
  --   corpo como dos itens). NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/08/2017  Alteracao em tipo_dado_pkg.validar.
  -- Silvia            03/10/2022  Novo parametro usuario_sessao_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_exception          EXCEPTION;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_valor_atributo_sai LONG;
  --
  CURSOR c_md1 IS
   SELECT os.valor_atributo,
          me.nome             nome_atributo,
          me.tamanho,
          me.flag_obrigatorio,
          td.codigo           cod_dado
     FROM os_atributo_valor os,
          metadado          me,
          tipo_dado         td
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.metadado_id = me.metadado_id
      AND me.tipo_dado_id = td.tipo_dado_id
    ORDER BY me.ordem;
  --
  CURSOR c_md2 IS
   SELECT os.valor_atributo,
          me.nome nome_atributo,
          me.tamanho,
          me.flag_obrigatorio,
          td.codigo cod_dado,
          TRIM(tp.nome || ' ' || jp.complemento) nome_produto
     FROM os_tp_atributo_valor os,
          metadado             me,
          tipo_dado            td,
          job_tipo_produto     jp,
          tipo_produto         tp
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.metadado_id = me.metadado_id
      AND me.tipo_dado_id = td.tipo_dado_id
      AND os.job_tipo_produto_id = jp.job_tipo_produto_id
      AND jp.tipo_produto_id = tp.tipo_produto_id
    ORDER BY nome_produto,
             me.ordem;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.empresa_id
    INTO v_empresa_id
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos metadados do corpo
  ------------------------------------------------------------
  FOR r_md1 IN c_md1
  LOOP
   tipo_dado_pkg.validar(p_usuario_sessao_id,
                         v_empresa_id,
                         r_md1.cod_dado,
                         r_md1.flag_obrigatorio,
                         'N',
                         r_md1.tamanho,
                         r_md1.valor_atributo,
                         v_valor_atributo_sai,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    p_erro_msg := r_md1.nome_atributo || ': ' || p_erro_msg;
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- consistencia dos metadados dos itens
  ------------------------------------------------------------
  FOR r_md2 IN c_md2
  LOOP
   tipo_dado_pkg.validar(p_usuario_sessao_id,
                         v_empresa_id,
                         r_md2.cod_dado,
                         r_md2.flag_obrigatorio,
                         'N',
                         r_md2.tamanho,
                         r_md2.valor_atributo,
                         v_valor_atributo_sai,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    p_erro_msg := r_md2.nome_produto || ' - ' || r_md2.nome_atributo || ': ' || p_erro_msg;
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
 END metadados_validar;
 --
 --
 PROCEDURE nota_aval_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/03/2022
  -- DESCRICAO: Registra a nota de avaliacao da execucao pelo solicitante (tipo_ender = 'SOL'
  --   ou a nota de avaliacao do briefing/solicitacao pelo executor (tipo_ender = 'EXE'
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2022  Para nota de solicitante, soh grava a mais recente.
  -- Silvia            12/12/2022  Novo atributo comentario.
  -- Ana               06/12/2023  Adicionado status_aux
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_ender        IN VARCHAR2,
  p_nota_aval         IN VARCHAR2,
  p_comentario        IN CLOB,
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
  v_status_job         job.status%TYPE;
  v_nota_aval          os_usuario_refacao.nota_aval%TYPE;
  v_num_refacao        ordem_servico.qtd_refacao%TYPE;
  v_tipo_os_id         ordem_servico.tipo_os_id%TYPE;
  v_num_estrelas_param NUMBER(5);
  --
 BEGIN
  v_qt                 := 0;
  v_num_estrelas_param := nvl(to_number(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                       'NUM_ESTRELAS_COMENT_AVAL_OS')),
                              0);
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.qtd_refacao,
         os.tipo_os_id
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_num_refacao,
         v_tipo_os_id
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_tipo_ender) IS NULL OR p_tipo_ender NOT IN ('EXE', 'SOL')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de endereçamento inválido (' || p_tipo_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_nota_aval) = 0 OR nvl(to_number(p_nota_aval), 0) NOT BETWEEN 0 AND 5
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nota de avaliação inválida (' || p_nota_aval || ').';
   RAISE v_exception;
  END IF;
  --
  v_nota_aval := nvl(to_number(p_nota_aval), 0); --
  --
  IF length(TRIM(p_comentario)) > 4000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_nota_aval > 0 AND v_num_estrelas_param > 0 AND v_nota_aval <= v_num_estrelas_param AND
     TRIM(p_comentario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para essa nota de avaliação, o preenchimento ' || 'do comentário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_tipo_ender = 'SOL'
  THEN
   -- deleta eventual avaliacao anterior de solicitante
   DELETE FROM os_usuario_refacao
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_ender = p_tipo_ender
      AND num_refacao = v_num_refacao;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario_refacao
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_sessao_id
     AND tipo_ender = p_tipo_ender
     AND num_refacao = v_num_refacao;
  --
  IF v_qt = 0
  THEN
   --ALCBO_061223
   INSERT INTO os_usuario_refacao
    (ordem_servico_id,
     usuario_id,
     tipo_ender,
     num_refacao,
     nota_aval,
     data_aval,
     comentario,
     status_aux)
   VALUES
    (p_ordem_servico_id,
     p_usuario_sessao_id,
     p_tipo_ender,
     v_num_refacao,
     v_nota_aval,
     SYSDATE,
     TRIM(p_comentario),
     'PEND');
  ELSE
   UPDATE os_usuario_refacao
      SET nota_aval  = v_nota_aval,
          data_aval  = SYSDATE,
          comentario = TRIM(p_comentario)
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_sessao_id
      AND tipo_ender = p_tipo_ender
      AND num_refacao = v_num_refacao;
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
 END nota_aval_registrar;
 --
 --
 PROCEDURE horas_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/01/2013
  -- DESCRICAO: Inclusão de horas planejadas na OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/04/2016  Novo parametro (tipo_formulario, usuario_id)
  -- Silvia            18/05/2020  Retirada de papel/nivel
  -- Silvia            31/07/2020  Inclusao de cargo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_ordem_servico_id  IN os_horas.ordem_servico_id%TYPE,
  p_usuario_id        IN os_horas.usuario_id%TYPE,
  p_cargo_id          IN os_horas.cargo_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_horas_planej   os_horas.horas_planej%TYPE;
  v_job_id         job.job_id%TYPE;
  v_numero_os      ordem_servico.numero%TYPE;
  v_tipo_os        tipo_os.codigo%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc   tipo_os.nome%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_nome           VARCHAR2(200);
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         ti.tipo_os_id,
         ti.codigo,
         ti.nome
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_tipo_os_id,
         v_tipo_os,
         v_tipo_os_desc
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_usuario_id, 0) = 0 AND nvl(p_cargo_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário ou do cargo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) <> 0 AND nvl(p_cargo_id, 0) <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas o usuário ou o cargo deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_horas_planej) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das horas é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_horas_planej) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  v_horas_planej := nvl(to_number(p_horas_planej), 0);
  --
  IF v_horas_planej < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) > 0
  THEN
   SELECT MAX(apelido)
     INTO v_nome
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_horas
    WHERE ordem_servico_id = p_ordem_servico_id
      AND usuario_id = p_usuario_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe estimativa de horas para esse usuário.';
    RAISE v_exception;
   END IF;
  ELSE
   SELECT MAX(nome)
     INTO v_nome
     FROM cargo
    WHERE cargo_id = p_cargo_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_horas
    WHERE ordem_servico_id = p_ordem_servico_id
      AND cargo_id = p_cargo_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe estimativa de horas para esse cargo.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO os_horas
   (os_horas_id,
    ordem_servico_id,
    usuario_id,
    cargo_id,
    horas_planej)
  VALUES
   (seq_os_horas.nextval,
    p_ordem_servico_id,
    zvl(p_usuario_id, NULL),
    zvl(p_cargo_id, NULL),
    v_horas_planej);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Inclusão de estimativa de horas: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END horas_adicionar;
 --
 --
 PROCEDURE horas_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/01/2013
  -- DESCRICAO: Alteração de horas planejadas da OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/05/2020  Retirada de papel/nivel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_os_horas_id       IN os_horas.os_horas_id%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_usuario_id       usuario.usuario_id%TYPE;
  v_cargo_id         cargo.cargo_id%TYPE;
  v_horas_planej     os_horas.horas_planej%TYPE;
  v_job_id           job.job_id%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_tipo_os_id       tipo_os.tipo_os_id%TYPE;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_nome             VARCHAR2(200);
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
    FROM os_horas
   WHERE os_horas_id = p_os_horas_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ordem_servico_id,
         usuario_id,
         cargo_id
    INTO v_ordem_servico_id,
         v_usuario_id,
         v_cargo_id
    FROM os_horas
   WHERE os_horas_id = p_os_horas_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ti.tipo_os_id
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_tipo_os_id
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(v_usuario_id, 0) > 0
  THEN
   SELECT MAX(apelido)
     INTO v_nome
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
  ELSE
   SELECT MAX(nome)
     INTO v_nome
     FROM cargo
    WHERE cargo_id = v_cargo_id;
  END IF;
  --
  IF inteiro_validar(p_horas_planej) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  v_horas_planej := nvl(to_number(p_horas_planej), 0);
  --
  IF v_horas_planej < 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_horas
     SET horas_planej = v_horas_planej
   WHERE os_horas_id = p_os_horas_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Exclusão de estimativa de horas: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END horas_atualizar;
 --
 --
 PROCEDURE horas_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 20/04/2016
  -- DESCRICAO: Exclusao de horas planejadas da OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/05/2020  Retirada de papel/nivel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_horas_id       IN os_horas.os_horas_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_numero_job       job.numero%TYPE;
  v_status_job       job.status%TYPE;
  v_usuario_id       os_horas.usuario_id%TYPE;
  v_cargo_id         os_horas.cargo_id%TYPE;
  v_job_id           job.job_id%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_tipo_os_id       tipo_os.tipo_os_id%TYPE;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_nome             VARCHAR2(200);
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
    FROM os_horas
   WHERE os_horas_id = p_os_horas_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ordem_servico_id,
         usuario_id,
         cargo_id
    INTO v_ordem_servico_id,
         v_usuario_id,
         v_cargo_id
    FROM os_horas
   WHERE os_horas_id = p_os_horas_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ti.tipo_os_id
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_tipo_os_id
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF nvl(v_usuario_id, 0) > 0
  THEN
   SELECT MAX(apelido)
     INTO v_nome
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
  ELSE
   SELECT MAX(nome)
     INTO v_nome
     FROM cargo
    WHERE cargo_id = v_cargo_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM os_horas
   WHERE os_horas_id = p_os_horas_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Exclusão de estimativa de horas: ' || v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END horas_excluir;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/10/2007
  -- DESCRICAO: Adicionar arquivo no ordem de servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS.
  -- Silvia            10/10/2014  Novo tipo de arquivo (aprovacao).
  -- Silvia            20/04/2016  Novo tipo de arquivo (estimativa).
  -- Silvia            29/06/2017  Novo tipo de arquivo (refacao).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN NUMBER,
  p_arquivo_id          IN arquivo.arquivo_id%TYPE,
  p_volume_id           IN arquivo.volume_id%TYPE,
  p_ordem_servico_id    IN arquivo_os.ordem_servico_id%TYPE,
  p_descricao           IN arquivo.descricao%TYPE,
  p_nome_original       IN arquivo.nome_original%TYPE,
  p_nome_fisico         IN arquivo.nome_fisico%TYPE,
  p_mime_type           IN arquivo.mime_type%TYPE,
  p_tamanho             IN arquivo.tamanho%TYPE,
  p_palavras_chave      IN VARCHAR2,
  p_thumb_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb_nome_original IN arquivo.nome_original%TYPE,
  p_thumb_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_os         IN arquivo_os.tipo_arq_os%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_exception       EXCEPTION;
  v_job_id          job.job_id%TYPE;
  v_numero_job      job.numero%TYPE;
  v_status_job      job.status%TYPE;
  v_numero_os       ordem_servico.numero%TYPE;
  v_tam_max_arq_ref tipo_os.tam_max_arq_ref%TYPE;
  v_qtd_max_arq_ref tipo_os.qtd_max_arq_ref%TYPE;
  v_extensoes_ref   tipo_os.extensoes_ref%TYPE;
  v_tam_max_arq_exe tipo_os.tam_max_arq_exe%TYPE;
  v_qtd_max_arq_exe tipo_os.qtd_max_arq_exe%TYPE;
  v_extensoes_exe   tipo_os.extensoes_exe%TYPE;
  v_tam_max_arq_apr tipo_os.tam_max_arq_apr%TYPE;
  v_qtd_max_arq_apr tipo_os.qtd_max_arq_apr%TYPE;
  v_extensoes_apr   tipo_os.extensoes_apr%TYPE;
  v_tam_max_arq_est tipo_os.tam_max_arq_est%TYPE;
  v_qtd_max_arq_est tipo_os.qtd_max_arq_est%TYPE;
  v_extensoes_est   tipo_os.extensoes_est%TYPE;
  v_tam_max_arq_rfa tipo_os.tam_max_arq_rfa%TYPE;
  v_qtd_max_arq_rfa tipo_os.qtd_max_arq_rfa%TYPE;
  v_extensoes_rfa   tipo_os.extensoes_rfa%TYPE;
  v_tam_max_arq     tipo_os.tam_max_arq_exe%TYPE;
  v_qtd_max_arq     tipo_os.qtd_max_arq_exe%TYPE;
  v_extensoes       tipo_os.extensoes_exe%TYPE;
  v_status_os       ordem_servico.status%TYPE;
  v_qtd_refacao     ordem_servico.qtd_refacao%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_extensao        VARCHAR2(200);
  v_qtd_arq         NUMBER(10);
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
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status,
         os.qtd_refacao,
         ti.tam_max_arq_ref,
         ti.qtd_max_arq_ref,
         ti.extensoes_ref,
         ti.tam_max_arq_exe,
         ti.qtd_max_arq_exe,
         ti.extensoes_exe,
         ti.tam_max_arq_apr,
         ti.qtd_max_arq_apr,
         ti.extensoes_apr,
         ti.tam_max_arq_est,
         ti.qtd_max_arq_est,
         ti.extensoes_est,
         ti.tam_max_arq_rfa,
         ti.qtd_max_arq_rfa,
         ti.extensoes_rfa
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os,
         v_qtd_refacao,
         v_tam_max_arq_ref,
         v_qtd_max_arq_ref,
         v_extensoes_ref,
         v_tam_max_arq_exe,
         v_qtd_max_arq_exe,
         v_extensoes_exe,
         v_tam_max_arq_apr,
         v_qtd_max_arq_apr,
         v_extensoes_apr,
         v_tam_max_arq_est,
         v_qtd_max_arq_est,
         v_extensoes_est,
         v_tam_max_arq_rfa,
         v_qtd_max_arq_rfa,
         v_extensoes_rfa
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF rtrim(p_tipo_arq_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('tipo_arq_os', p_tipo_arq_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do tipo de arquivo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_os IN ('EXEC_APR', 'EXEC_REP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de arquivo não pode ser inserido diretamente via interface (' ||
                 p_tipo_arq_os || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_arq_os = 'REFER'
  THEN
   v_tam_max_arq := v_tam_max_arq_ref;
   v_qtd_max_arq := v_qtd_max_arq_ref;
   v_extensoes   := v_extensoes_ref;
  ELSIF p_tipo_arq_os = 'EXEC'
  THEN
   v_tam_max_arq := v_tam_max_arq_exe;
   v_qtd_max_arq := v_qtd_max_arq_exe;
   v_extensoes   := v_extensoes_exe;
  ELSIF p_tipo_arq_os = 'APROV'
  THEN
   v_tam_max_arq := v_tam_max_arq_apr;
   v_qtd_max_arq := v_qtd_max_arq_apr;
   v_extensoes   := v_extensoes_apr;
  ELSIF p_tipo_arq_os = 'ESTIM'
  THEN
   v_tam_max_arq := v_tam_max_arq_est;
   v_qtd_max_arq := v_qtd_max_arq_est;
   v_extensoes   := v_extensoes_est;
  ELSIF p_tipo_arq_os = 'REFA'
  THEN
   v_tam_max_arq := v_tam_max_arq_rfa;
   v_qtd_max_arq := v_qtd_max_arq_rfa;
   v_extensoes   := v_extensoes_rfa;
  END IF;
  --
  /*
    IF p_tipo_arq_os = 'REFER' AND v_status_os NOT IN ('PREP','DIST','ACEI','EMEX')  THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O status do Workflow não permite a inclusão desse tipo de arquivo.';
       RAISE v_exception;
    END IF;
  --
    IF p_tipo_arq_os = 'EXEC' AND v_status_os NOT IN ('PREP','EMEX','AVAL','EXEC') THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O status do Workflow não permite a inclusão desse tipo de arquivo.';
       RAISE v_exception;
    END IF;
  --
    IF p_tipo_arq_os = 'APROV' AND v_status_os NOT IN ('EXEC','CONC','EMAP','STAN','PREP','AVAL') THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O status do Workflow não permite a inclusão desse tipo de arquivo.';
       RAISE v_exception;
    END IF;
  */
  --
  SELECT COUNT(*)
    INTO v_qtd_arq
    FROM arquivo_os
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_arq_os = p_tipo_arq_os
     AND flag_thumb = 'N';
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
  IF v_tam_max_arq IS NOT NULL AND p_tamanho > v_tam_max_arq
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tamanho do arquivo não pode ser maior que ' || to_char(v_tam_max_arq) ||
                 ' bytes.';
   RAISE v_exception;
  END IF;
  --
  IF v_extensoes IS NOT NULL
  THEN
   v_extensao := substr(p_nome_fisico, instr(p_nome_fisico, '.') + 1);
   --
   IF instr(upper(',' || v_extensoes || ','), upper(',' || v_extensao || ',')) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa extensão do arquivo (' || upper(v_extensao) ||
                  ') não é uma das extensões válidas (' || upper(v_extensoes) || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_qtd_max_arq IS NOT NULL AND v_qtd_arq + 1 > v_qtd_max_arq
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A quantidade de arquivos anexados não pode ser maior que ' ||
                 to_char(v_qtd_max_arq) || '.';
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
     AND codigo = 'ORDEM_SERVICO';
  --
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_ordem_servico_id,
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
  IF p_tipo_arq_os = 'REFA'
  THEN
   -- arquivo de refacao entra na proxima refacao
   v_qtd_refacao := v_qtd_refacao + 1;
  END IF;
  --
  UPDATE arquivo_os
     SET tipo_arq_os = TRIM(p_tipo_arq_os),
         flag_thumb  = 'N',
         num_refacao = v_qtd_refacao
   WHERE arquivo_id = p_arquivo_id;
  --
  -- verifica se veio thumbnail
  IF nvl(p_thumb_arquivo_id, 0) > 0
  THEN
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_thumb_arquivo_id,
                         p_thumb_volume_id,
                         p_ordem_servico_id,
                         v_tipo_arquivo_id,
                         p_thumb_nome_original,
                         p_thumb_nome_fisico,
                         p_descricao,
                         p_thumb_mime_type,
                         p_thumb_tamanho,
                         NULL,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE arquivo_os
      SET tipo_arq_os = TRIM(p_tipo_arq_os),
          flag_thumb  = 'S',
          chave_thumb = p_arquivo_id,
          num_refacao = v_qtd_refacao
    WHERE arquivo_id = p_thumb_arquivo_id;
   --
   UPDATE arquivo_os
      SET chave_thumb = p_arquivo_id
    WHERE arquivo_id = p_arquivo_id;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Anexação de arquivo no Workflow (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 PROCEDURE arquivo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 09/03/2018
  -- DESCRICAO: Atualizar arquivo de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_ordem_servico_id  IN arquivo_os.ordem_servico_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_nome_original  arquivo.nome_original%TYPE;
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
    FROM ordem_servico os,
         arquivo_os    ar,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND ar.arquivo_id = p_arquivo_id
     AND os.ordem_servico_id = ar.ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe ou não está associado a esse Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT ar.nome_original
    INTO v_nome_original
    FROM arquivo_os os,
         arquivo    ar
   WHERE os.arquivo_id = p_arquivo_id
     AND os.ordem_servico_id = p_ordem_servico_id
     AND os.arquivo_id = ar.arquivo_id;
  --
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE arquivo
     SET descricao = TRIM(p_descricao)
   WHERE arquivo_id = p_arquivo_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Atualização da descrição do arquivo (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END arquivo_atualizar;
 --
 --
 PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/10/2007
  -- DESCRICAO: Excluir arquivo da OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS.
  -- Silvia            07/06/2018  Deixa excluir arq de EXEC no status de OS PREP.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_ordem_servico_id  IN arquivo_os.ordem_servico_id%TYPE,
  p_flag_remover      OUT VARCHAR2,
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
  v_numero_os      ordem_servico.numero%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_nome_original  arquivo.nome_original%TYPE;
  v_tipo_arq_os    arquivo_os.tipo_arq_os%TYPE;
  v_chave_thumb    arquivo_os.chave_thumb%TYPE;
  v_arquivo_id_aux arquivo.arquivo_id%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  -- inicializa variavel de output que indica se o arquivo
  -- deve ser realmente removido do file system.
  p_flag_remover := 'S';
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         arquivo_os    ar,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND ar.arquivo_id = p_arquivo_id
     AND os.ordem_servico_id = ar.ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe ou não está associado a esse Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT ar.nome_original,
         os.tipo_arq_os,
         os.chave_thumb
    INTO v_nome_original,
         v_tipo_arq_os,
         v_chave_thumb
    FROM arquivo_os os,
         arquivo    ar
   WHERE os.arquivo_id = p_arquivo_id
     AND os.ordem_servico_id = p_ordem_servico_id
     AND os.arquivo_id = ar.arquivo_id;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a exclusão desse tipo de arquivo.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o arquivo tem thumbnail
  SELECT MAX(arquivo_id)
    INTO v_arquivo_id_aux
    FROM arquivo_os
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_arq_os = v_tipo_arq_os
     AND chave_thumb = v_chave_thumb
     AND arquivo_id <> p_arquivo_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se o arquivo esta associado a outras OS
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_os
   WHERE arquivo_id = p_arquivo_id
     AND ordem_servico_id <> p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   -- nao esta. Pode excluir o arquivo.
   arquivo_pkg.excluir(p_usuario_sessao_id, p_arquivo_id, p_erro_cod, p_erro_msg);
   --
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF v_arquivo_id_aux IS NOT NULL
   THEN
    -- exlui tb o thumbnail
    arquivo_pkg.excluir(p_usuario_sessao_id, v_arquivo_id_aux, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  ELSE
   -- esta associado a outras. Exclui apenas o relacionamento.
   DELETE FROM arquivo_os
    WHERE arquivo_id = p_arquivo_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   -- nao se exclui o arquivo fisicamente
   p_flag_remover := 'N';
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Exclusão de arquivo de Workflow (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 PROCEDURE arquivo_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/03/2015
  -- DESCRICAO: Muda (move) o tipo de arquivo de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_arquivo_id        IN arquivo.arquivo_id%TYPE,
  p_novo_tipo_arq_os  IN VARCHAR2,
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
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_numero_os        ordem_servico.numero%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_nome_original    arquivo.nome_original%TYPE;
  v_tipo_arq_os      arquivo_os.tipo_arq_os%TYPE;
  v_chave_thumb      arquivo_os.chave_thumb%TYPE;
  v_arquivo_id_aux   arquivo.arquivo_id%TYPE;
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
    FROM ordem_servico os,
         arquivo_os    ar,
         job           jo
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.ordem_servico_id = os.ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_novo_tipo_arq_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O novo tipo de arquivo deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  IF p_novo_tipo_arq_os NOT IN ('EXEC', 'EXEC_APR', 'EXEC_REP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Novo tipo de arquivo inválido (' || p_novo_tipo_arq_os || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT os.ordem_servico_id,
         ar.nome_original,
         os.tipo_arq_os,
         os.chave_thumb
    INTO v_ordem_servico_id,
         v_nome_original,
         v_tipo_arq_os,
         v_chave_thumb
    FROM arquivo_os os,
         arquivo    ar
   WHERE os.arquivo_id = p_arquivo_id
     AND os.arquivo_id = ar.arquivo_id;
  --
  IF v_tipo_arq_os NOT IN ('EXEC', 'EXEC_APR', 'EXEC_REP')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de arquivo não pode ser movimentado (' || v_tipo_arq_os || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         os.numero,
         os.status
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_numero_os,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a movimentação desse tipo de arquivo.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o arquivo tem thumbnail
  SELECT MAX(arquivo_id)
    INTO v_arquivo_id_aux
    FROM arquivo_os
   WHERE ordem_servico_id = v_ordem_servico_id
     AND tipo_arq_os = v_tipo_arq_os
     AND chave_thumb = v_chave_thumb
     AND arquivo_id <> p_arquivo_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE arquivo_os
     SET tipo_arq_os = p_novo_tipo_arq_os
   WHERE arquivo_id = p_arquivo_id;
  --
  IF v_arquivo_id_aux IS NOT NULL
  THEN
   UPDATE arquivo_os
      SET tipo_arq_os = p_novo_tipo_arq_os
    WHERE arquivo_id = v_arquivo_id_aux;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Movimentação de arquivo de Workflow (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END arquivo_mover;
 --
 --
 PROCEDURE os_link_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/07/2018
  -- DESCRICAO: Adiciona um link na ordem de servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/01/2019  Parametros passaram a ser vetor.
  -- Silvia            28/07/2020  Inclusao individual e novos parametros
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN os_link.tipo_link%TYPE,
  p_os_link_id        OUT os_link.os_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_qtd_refacao    ordem_servico.qtd_refacao%TYPE;
  v_os_link_id     os_link.os_link_id%TYPE;
  v_desc_tipo_link VARCHAR2(100);
  --
 BEGIN
  v_qt         := 0;
  p_os_link_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status,
         os.qtd_refacao
    INTO v_job_id,
         v_status_job,
         v_status_os,
         v_qtd_refacao
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a inclusão de hiperlink.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_url) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do hiperlink é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_url) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O hiperlink não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_tipo_link) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de hiperlink é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_tipo_link := util_pkg.desc_retornar('tipo_link', p_tipo_link);
  --
  IF v_desc_tipo_link IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de hiperlink inválido (' || p_tipo_link || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_os_link.nextval
    INTO v_os_link_id
    FROM dual;
  --
  INSERT INTO os_link
   (os_link_id,
    ordem_servico_id,
    usuario_id,
    data_entrada,
    url,
    descricao,
    tipo_link,
    num_refacao)
  VALUES
   (v_os_link_id,
    p_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    TRIM(p_url),
    TRIM(p_descricao),
    TRIM(p_tipo_link),
    v_qtd_refacao);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Inclusão de hiperlink de ' || v_desc_tipo_link || ' (' || p_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  p_os_link_id := v_os_link_id;
  p_erro_cod   := '00000';
  p_erro_msg   := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END os_link_adicionar;
 --
 --
 PROCEDURE os_link_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 25/07/2018
  -- DESCRICAO: Exclui um link da OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_os_link_id        IN os_link.os_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_status_job       job.status%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_url              os_link.url%TYPE;
  v_tipo_link        os_link.tipo_link%TYPE;
  v_desc_tipo_link   VARCHAR2(100);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(os.ordem_servico_id)
    INTO v_ordem_servico_id
    FROM ordem_servico os,
         os_link       ol,
         job           jo
   WHERE ol.os_link_id = p_os_link_id
     AND ol.ordem_servico_id = os.ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_ordem_servico_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse hiperlink não existe ou não está associado a esse Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status
    INTO v_job_id,
         v_status_job,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = v_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  SELECT url,
         tipo_link
    INTO v_url,
         v_tipo_link
    FROM os_link
   WHERE os_link_id = p_os_link_id;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a exclusão de hiperlink.';
   RAISE v_exception;
  END IF;
  --
  IF v_tipo_link LIKE 'EXEC%'
  THEN
   v_desc_tipo_link := 'Entrega';
  ELSE
   v_desc_tipo_link := 'Referência';
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM os_link
   WHERE os_link_id = p_os_link_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Exclusão de hiperlink de ' || v_desc_tipo_link || ' (' || v_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END os_link_excluir;
 --
 --
 PROCEDURE afazer_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 11/01/2022
  -- DESCRICAO: Adicionar item a fazer (TO-DO) na OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_afazer.ordem_servico_id%TYPE,
  p_usuario_resp_id   IN os_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_os_afazer_id      OUT os_afazer.os_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_os_afazer_id   os_afazer.os_afazer_id%TYPE;
  v_ordem          os_afazer.ordem%TYPE;
  v_data           os_afazer.data%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
 BEGIN
  v_qt           := 0;
  p_os_afazer_id := 0;
  v_lbl_job      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         os.status
    INTO v_status_job,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(ordem), 0) + 10
    INTO v_ordem
    FROM os_afazer
   WHERE ordem_servico_id = p_ordem_servico_id
     AND flag_feito = 'N';
  --
  SELECT seq_os_afazer.nextval
    INTO v_os_afazer_id
    FROM dual;
  --
  INSERT INTO os_afazer
   (os_afazer_id,
    ordem_servico_id,
    usuario_resp_id,
    data,
    descricao,
    flag_feito,
    ordem)
  VALUES
   (v_os_afazer_id,
    p_ordem_servico_id,
    zvl(p_usuario_resp_id, NULL),
    v_data,
    TRIM(p_descricao),
    'N',
    v_ordem);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Inclusão de TO-DO (' || TRIM(p_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
  p_os_afazer_id := v_os_afazer_id;
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
 END afazer_adicionar;
 --
 --
 PROCEDURE afazer_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 11/01/2022
  -- DESCRICAO: Atualizar a fazer (TO-DO) da OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_usuario_resp_id   IN os_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_data             os_afazer.data%TYPE;
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
    FROM os_afazer
   WHERE os_afazer_id = p_os_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT os.ordem_servico_id,
         os.status,
         jo.status
    INTO v_ordem_servico_id,
         v_status_os,
         v_status_job
    FROM ordem_servico os,
         os_afazer     af,
         job           jo
   WHERE af.os_afazer_id = p_os_afazer_id
     AND af.ordem_servico_id = os.ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 200
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 200 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_data := data_converter(p_data);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_afazer
     SET descricao       = TRIM(p_descricao),
         data            = v_data,
         usuario_resp_id = zvl(p_usuario_resp_id, NULL)
   WHERE os_afazer_id = p_os_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Atualização de TO-DO (' || TRIM(p_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END afazer_atualizar;
 --
 --
 PROCEDURE afazer_feito_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 12/01/2022
  -- DESCRICAO: Atualizar flag_feito do a fazer (TO-DO) de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_flag_feito        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_descricao        os_afazer.descricao%TYPE;
  v_ordem            os_afazer.ordem%TYPE;
  v_lbl_job          VARCHAR2(100);
  v_acao             VARCHAR2(20);
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
    FROM os_afazer
   WHERE os_afazer_id = p_os_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT os.ordem_servico_id,
         os.status,
         af.descricao,
         jo.status
    INTO v_ordem_servico_id,
         v_status_os,
         v_descricao,
         v_status_job
    FROM ordem_servico os,
         os_afazer     af,
         job           jo
   WHERE af.os_afazer_id = p_os_afazer_id
     AND af.ordem_servico_id = os.ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_feito) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag feito inválido (' || p_flag_feito || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_feito = 'S'
  THEN
   v_acao := 'Feito';
  ELSE
   v_acao := 'A Fazer';
  END IF;
  --
  SELECT nvl(MAX(ordem), 0) + 10
    INTO v_ordem
    FROM os_afazer
   WHERE ordem_servico_id = v_ordem_servico_id
     AND flag_feito = p_flag_feito;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_afazer
     SET flag_feito = p_flag_feito,
         ordem      = v_ordem
   WHERE os_afazer_id = p_os_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Atualização de TO-DO como ' || v_acao || ' (' || TRIM(v_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END afazer_feito_atualizar;
 --
 --
 PROCEDURE afazer_reordenar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 12/01/2022
  -- DESCRICAO: Reordenar itens a fazer (TO-DO) de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN NUMBER,
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_os_afazer_id IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_status_job         job.status%TYPE;
  v_status_os          ordem_servico.status%TYPE;
  v_ordem              os_afazer.ordem%TYPE;
  v_os_afazer_id       os_afazer.os_afazer_id%TYPE;
  v_vetor_os_afazer_id VARCHAR2(2000);
  v_lbl_job            VARCHAR2(100);
  v_delimitador        CHAR(1);
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
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         os.status
    INTO v_status_job,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  v_ordem       := 0;
  --
  v_vetor_os_afazer_id := p_vetor_os_afazer_id;
  --
  WHILE nvl(length(rtrim(v_vetor_os_afazer_id)), 0) > 0
  LOOP
   v_os_afazer_id := to_number(prox_valor_retornar(v_vetor_os_afazer_id, v_delimitador));
   v_ordem        := v_ordem + 10;
   --
   UPDATE os_afazer
      SET ordem = v_ordem
    WHERE os_afazer_id = v_os_afazer_id;
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
 END afazer_reordenar;
 --
 --
 PROCEDURE afazer_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 11/01/2022
  -- DESCRICAO: Excluir item a fazer (TO-DO) da OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_os_afazer_id      IN os_afazer.os_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_descricao        os_afazer.descricao%TYPE;
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
    FROM os_afazer
   WHERE os_afazer_id = p_os_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT os.ordem_servico_id,
         os.status,
         af.descricao,
         jo.status
    INTO v_ordem_servico_id,
         v_status_os,
         v_descricao,
         v_status_job
    FROM ordem_servico os,
         os_afazer     af,
         job           jo
   WHERE af.os_afazer_id = p_os_afazer_id
     AND af.ordem_servico_id = os.ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM os_afazer
   WHERE os_afazer_id = p_os_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(v_ordem_servico_id);
  v_compl_histor   := 'Exclusão de TO-DO (' || TRIM(v_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   v_ordem_servico_id,
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
 END afazer_excluir;
 --
 --
 PROCEDURE os_negociacao_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 13/02/2019
  -- DESCRICAO: Adiciona uma negociacao de prazo na ordem de servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_data_sugerida     IN VARCHAR2,
  p_hora_sugerida     IN VARCHAR2,
  p_comentario        IN CLOB,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_qtd_refacao      ordem_servico.qtd_refacao%TYPE;
  v_os_negociacao_id os_negociacao.os_negociacao_id%TYPE;
  v_data_sugerida    os_negociacao.data_sugerida%TYPE;
  v_atuacao_usuario  os_negociacao.atuacao_usuario%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status,
         os.qtd_refacao
    INTO v_job_id,
         v_status_job,
         v_status_os,
         v_qtd_refacao
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF v_status_os NOT IN ('DIST', 'ACEI', 'EMEX')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a inclusão de negociação de prazo.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_sugerida) IS NULL OR rtrim(p_hora_sugerida) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_sugerida) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo inválida (' || p_data_sugerida || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_sugerida) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo inválida (' || p_hora_sugerida || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_sugerida := data_hora_converter(p_data_sugerida || ' ' || p_hora_sugerida);
  --
  IF TRIM(p_comentario) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do comentário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_comentario)) > 32767
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do comentário não pode ter mais que 32767 caracteres.';
   RAISE v_exception;
  END IF;
  v_atuacao_usuario := ordem_servico_pkg.atuacao_usuario_retornar(p_usuario_sessao_id,
                                                                  p_empresa_id,
                                                                  p_ordem_servico_id);
  --
  IF v_atuacao_usuario = 'ERRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na recuperação da atuação do usuário no Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_os_negociacao.nextval
    INTO v_os_negociacao_id
    FROM dual;
  --
  INSERT INTO os_negociacao
   (os_negociacao_id,
    ordem_servico_id,
    usuario_id,
    data_evento,
    data_sugerida,
    comentario,
    num_refacao,
    cod_acao,
    desc_acao,
    atuacao_usuario)
  VALUES
   (v_os_negociacao_id,
    p_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    v_data_sugerida,
    TRIM(p_comentario),
    v_qtd_refacao,
    'PROPOR_PRAZO',
    'Propôs o Prazo',
    v_atuacao_usuario);
  --
  UPDATE ordem_servico
     SET flag_em_negociacao = 'S'
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'PROPOR_PRAZO',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END os_negociacao_adicionar;
 --
 --
 PROCEDURE os_negociacao_aceitar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 13/02/2019
  -- DESCRICAO: Aceita a negociacao de prazo da ordem de servico
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_ordem_servico_id  IN os_link.ordem_servico_id%TYPE,
  p_data_sugerida     IN VARCHAR2,
  p_hora_sugerida     IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_os        ordem_servico.status%TYPE;
  v_qtd_refacao      ordem_servico.qtd_refacao%TYPE;
  v_data_solicitada  ordem_servico.data_solicitada%TYPE;
  v_data_interna     ordem_servico.data_interna%TYPE;
  v_os_negociacao_id os_negociacao.os_negociacao_id%TYPE;
  v_data_sugerida    os_negociacao.data_sugerida%TYPE;
  v_atuacao_usuario  os_negociacao.atuacao_usuario%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status,
         os.qtd_refacao,
         os.data_solicitada,
         os.data_interna
    INTO v_job_id,
         v_status_job,
         v_status_os,
         v_qtd_refacao,
         v_data_solicitada,
         v_data_interna
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF v_status_os NOT IN ('DIST', 'ACEI', 'EMEX')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite a aceitação de negociação de prazo.';
   RAISE v_exception;
  END IF;
  --
  v_atuacao_usuario := ordem_servico_pkg.atuacao_usuario_retornar(p_usuario_sessao_id,
                                                                  p_empresa_id,
                                                                  p_ordem_servico_id);
  --
  IF v_atuacao_usuario = 'ERRO'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na recuperação da atuação do usuário no Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_sugerida) IS NULL OR rtrim(p_hora_sugerida) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do prazo (data e hora) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_sugerida) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data do prazo inválida (' || p_data_sugerida || ').';
   RAISE v_exception;
  END IF;
  --
  IF hora_validar(p_hora_sugerida) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Hora do prazo inválida (' || p_hora_sugerida || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_sugerida := data_hora_converter(p_data_sugerida || ' ' || p_hora_sugerida);
  --
  IF v_data_solicitada = v_data_interna
  THEN
   -- a data interna deve ser alterada junto com a solicitada
   v_data_solicitada := v_data_sugerida;
   v_data_interna    := v_data_sugerida;
  ELSE
   -- apenas a data solicitada eh alterada
   v_data_solicitada := v_data_sugerida;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_os_negociacao.nextval
    INTO v_os_negociacao_id
    FROM dual;
  --
  INSERT INTO os_negociacao
   (os_negociacao_id,
    ordem_servico_id,
    usuario_id,
    data_evento,
    data_sugerida,
    comentario,
    num_refacao,
    cod_acao,
    desc_acao,
    atuacao_usuario)
  VALUES
   (v_os_negociacao_id,
    p_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    v_data_sugerida,
    NULL,
    v_qtd_refacao,
    'ACEITAR_PRAZO',
    'Aceitou o Prazo',
    v_atuacao_usuario);
  --
  UPDATE ordem_servico
     SET flag_em_negociacao = 'N',
         data_solicitada    = v_data_solicitada,
         data_interna       = v_data_interna
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ACEITAR_PRAZO',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END os_negociacao_aceitar;
 --
 --
 PROCEDURE tipos_produtos_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/03/2013
  -- DESCRICAO: Associacao de tipos de produtos do job x OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/03/2014  Guarda o numero da refacao em que o produto foi adicionado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_num_refacao            ordem_servico.qtd_refacao%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc           tipo_os.nome%TYPE;
  v_flag_tem_itens         tipo_os.flag_tem_itens%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(4000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_tipo_produto_id        tipo_produto.tipo_produto_id%TYPE;
  v_tempo_exec_info        tipo_produto.tempo_exec_info%TYPE;
  v_lbl_job                VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.nome,
         ti.tipo_os_id,
         ti.flag_tem_itens,
         os.numero,
         os.status,
         os.qtd_refacao
    INTO v_tipo_os_desc,
         v_tipo_os_id,
         v_flag_tem_itens,
         v_numero_os,
         v_status_os,
         v_num_refacao
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação (atualização de itens).';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse job_tipo_produto não existe (' || to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT tp.tipo_produto_id,
          tp.tempo_exec_info
     INTO v_tipo_produto_id,
          v_tempo_exec_info
     FROM tipo_produto     tp,
          job_tipo_produto jp
    WHERE jp.job_tipo_produto_id = v_job_tipo_produto_id
      AND jp.tipo_produto_id = tp.tipo_produto_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_tipo_produto
     (ordem_servico_id,
      job_tipo_produto_id,
      tempo_exec_prev,
      num_refacao,
      data_entrada,
      quantidade)
    VALUES
     (p_ordem_servico_id,
      v_job_tipo_produto_id,
      v_tempo_exec_info,
      v_num_refacao,
      SYSDATE,
      1);
    --
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
    VALUES
     (p_ordem_servico_id,
      v_job_tipo_produto_id,
      v_num_refacao,
      SYSDATE);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- verifica se o tipo de produto desse item tem metadado
    SELECT COUNT(*)
      INTO v_qt
      FROM metadado
     WHERE tipo_objeto = 'TIPO_PRODUTO'
       AND objeto_id = v_tipo_produto_id
       AND flag_ativo = 'S'
       AND grupo = 'ITEM_OS';
    --
    IF v_qt > 0
    THEN
     -- usa preferencialmente o metadado do tipo de produto
     INSERT INTO os_tp_atributo_valor
      (ordem_servico_id,
       job_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT p_ordem_servico_id,
             v_job_tipo_produto_id,
             metadado_id,
             NULL
        FROM metadado
       WHERE tipo_objeto = 'TIPO_PRODUTO'
         AND objeto_id = v_tipo_produto_id
         AND flag_ativo = 'S'
         AND grupo = 'ITEM_OS';
    ELSE
     -- usa o metadado de item definido para o tipo de OS (se houver)
     INSERT INTO os_tp_atributo_valor
      (ordem_servico_id,
       job_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT p_ordem_servico_id,
             v_job_tipo_produto_id,
             metadado_id,
             NULL
        FROM metadado
       WHERE tipo_objeto = 'TIPO_OS'
         AND objeto_id = v_tipo_os_id
         AND flag_ativo = 'S'
         AND grupo = 'ITEM_OS';
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Associação de itens';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END tipos_produtos_adicionar;
 --
 --
 PROCEDURE tipos_produtos_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 14/06/2013
  -- DESCRICAO: Desassocia todos os tipos de produtos de uma determinada OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_numero_os      ordem_servico.numero%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc   tipo_os.nome%TYPE;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_lbl_job        VARCHAR2(100);
  --
  CURSOR c_it IS
   SELECT job_tipo_produto_id
     FROM os_tipo_produto
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.nome,
         ti.tipo_os_id,
         os.numero,
         os.status
    INTO v_tipo_os_desc,
         v_tipo_os_id,
         v_numero_os,
         v_status_os
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_it IN c_it
  LOOP
   DELETE FROM os_tp_atributo_valor
    WHERE ordem_servico_id = p_ordem_servico_id
      AND job_tipo_produto_id = r_it.job_tipo_produto_id;
   --
   DELETE FROM os_tipo_produto_ref
    WHERE ordem_servico_id = p_ordem_servico_id
      AND job_tipo_produto_id = r_it.job_tipo_produto_id;
   --
   DELETE FROM os_tipo_produto
    WHERE ordem_servico_id = p_ordem_servico_id
      AND job_tipo_produto_id = r_it.job_tipo_produto_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = r_it.job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    DELETE FROM job_tipo_produto
     WHERE job_tipo_produto_id = r_it.job_tipo_produto_id;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         p_ordem_servico_id,
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
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Desassociação de todos os itens';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END tipos_produtos_excluir;
 --
 --
 PROCEDURE tipo_produto_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/12/2010
  -- DESCRICAO: Associacao de tipo_produto x OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS.
  -- Silvia            10/03/2014  Guarda o numero da refacao em que o produto foi adicionado
  -- Silvia            16/08/2017  Alteracao em tipo_dado_pkg.validar.
  -- Silvia            19/06/2019  Troca do delimitador para ^
  -- Silvia            05/03/2020  Deixa atualizar em varios status da OS
  -- Silvia            05/10/2021  Novo parametro quantidade
  -- Silvia            04/10/2022  Novo parametro vetor_flag_ignora_obrig
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN os_tipo_produto.ordem_servico_id%TYPE,
  p_tipo_produto_id         IN job_tipo_produto.tipo_produto_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_descricao               IN CLOB,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_numero_os               ordem_servico.numero%TYPE;
  v_status_os               ordem_servico.status%TYPE;
  v_num_refacao             ordem_servico.qtd_refacao%TYPE;
  v_quantidade              os_tipo_produto.quantidade%TYPE;
  v_job_id                  job.job_id%TYPE;
  v_numero_job              job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_tipo_os_desc            tipo_os.nome%TYPE;
  v_tipo_os_id              tipo_os.tipo_os_id%TYPE;
  v_tipo_os_cod             tipo_os.codigo%TYPE;
  v_nome_produto            tipo_produto.nome%TYPE;
  v_tempo_exec_info         tipo_produto.tempo_exec_info%TYPE;
  v_job_tipo_produto_id     job_tipo_produto.job_tipo_produto_id%TYPE;
  v_nome_atributo           metadado.nome%TYPE;
  v_tamanho                 metadado.tamanho%TYPE;
  v_flag_obrigatorio        metadado.flag_obrigatorio%TYPE;
  v_tipo_dado               tipo_dado.codigo%TYPE;
  v_lbl_job                 VARCHAR2(100);
  v_vetor_atributo_id       LONG;
  v_vetor_atributo_valor    LONG;
  v_vetor_flag_ignora_obrig LONG;
  v_metadado_id             os_atributo_valor.metadado_id%TYPE;
  v_valor_atributo          LONG;
  v_valor_atributo_sai      LONG;
  v_delimitador             CHAR(1);
  v_flag_ignora_obrig       VARCHAR2(10);
  v_descricao               ordem_servico.descricao%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_produto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Tipo de Entregável deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.nome,
         ti.tipo_os_id,
         ti.codigo,
         os.numero,
         os.status,
         os.qtd_refacao
    INTO v_tipo_os_desc,
         v_tipo_os_id,
         v_tipo_os_cod,
         v_numero_os,
         v_status_os,
         v_num_refacao
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = nvl(p_tipo_produto_id, 0);
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de Entregável inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do Entregável não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade de Entregáveis inválida (' || p_quantidade || ').';
   RAISE v_exception;
  END IF;
  --
  v_quantidade := nvl(round(numero_converter(p_quantidade), 2), 0);
  --
  IF v_quantidade <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade de Entregáveis inválida (' || p_quantidade || ').';
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
  SELECT nome,
         tempo_exec_info
    INTO v_nome_produto,
         v_tempo_exec_info
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  -- verifica se o tipo de produto ja esta associado ao job
  IF TRIM(p_complemento) IS NOT NULL
  THEN
   SELECT MAX(job_tipo_produto_id)
     INTO v_job_tipo_produto_id
     FROM job_tipo_produto
    WHERE job_id = v_job_id
      AND tipo_produto_id = p_tipo_produto_id
      AND upper(TRIM(complemento)) = upper(TRIM(p_complemento));
  ELSE
   SELECT MAX(job_tipo_produto_id)
     INTO v_job_tipo_produto_id
     FROM job_tipo_produto
    WHERE job_id = v_job_id
      AND tipo_produto_id = p_tipo_produto_id
      AND TRIM(complemento) IS NULL;
  END IF;
  --
  IF v_job_tipo_produto_id IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE ordem_servico_id = p_ordem_servico_id
      AND job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Entregável já se encontra associado ao Workflow.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_job_tipo_produto_id IS NULL
  THEN
   SELECT seq_job_tipo_produto.nextval
     INTO v_job_tipo_produto_id
     FROM dual;
   --
   INSERT INTO job_tipo_produto
    (job_tipo_produto_id,
     job_id,
     tipo_produto_id,
     complemento)
   VALUES
    (v_job_tipo_produto_id,
     v_job_id,
     p_tipo_produto_id,
     TRIM(p_complemento));
  END IF;
  --
  INSERT INTO os_tipo_produto
   (ordem_servico_id,
    job_tipo_produto_id,
    descricao,
    tempo_exec_prev,
    num_refacao,
    data_entrada,
    quantidade)
  VALUES
   (p_ordem_servico_id,
    v_job_tipo_produto_id,
    TRIM(p_descricao),
    v_tempo_exec_info,
    v_num_refacao,
    SYSDATE,
    v_quantidade);
  --
  INSERT INTO os_tipo_produto_ref
   (ordem_servico_id,
    job_tipo_produto_id,
    num_refacao,
    data_entrada)
  VALUES
   (p_ordem_servico_id,
    v_job_tipo_produto_id,
    v_num_refacao,
    SYSDATE);
  --
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         p_ordem_servico_id,
                                         p_erro_cod,
                                         p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_delimitador             := '^';
  v_vetor_atributo_id       := p_vetor_atributo_id;
  v_vetor_atributo_valor    := p_vetor_atributo_valor;
  v_vetor_flag_ignora_obrig := p_vetor_flag_ignora_obrig;
  --
  WHILE nvl(length(rtrim(v_vetor_atributo_id)), 0) > 0
  LOOP
   v_metadado_id       := to_number(prox_valor_retornar(v_vetor_atributo_id, v_delimitador));
   v_valor_atributo    := prox_valor_retornar(v_vetor_atributo_valor, v_delimitador);
   v_flag_ignora_obrig := prox_valor_retornar(v_vetor_flag_ignora_obrig, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE metadado_id = v_metadado_id
      AND grupo = 'ITEM_OS';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado do item inválido (' || to_char(v_metadado_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(v_flag_ignora_obrig) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag ignora obrigatoriedade inválido (' || v_flag_ignora_obrig || ').';
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
                         v_flag_ignora_obrig,
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
   INSERT INTO os_tp_atributo_valor
    (ordem_servico_id,
     job_tipo_produto_id,
     metadado_id,
     valor_atributo)
   VALUES
    (p_ordem_servico_id,
     v_job_tipo_produto_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  v_descricao := ordem_servico_pkg.nome_retornar(p_ordem_servico_id);
  --
  UPDATE ordem_servico
     SET descricao = v_descricao
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Associação de Entregável: ' || TRIM(v_nome_produto || ' ' || p_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END; -- tipo_produto_adicionar
 --
 --
 PROCEDURE tipo_produto_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 08/02/2013
  -- DESCRICAO: Atualizacao de tipo_produto x OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/08/2017  Alteracao em tipo_dado_pkg.validar.
  -- Silvia            19/06/2019  Troca do delimitador para ^
  -- Silvia            05/03/2020  Deixa atualizar em varios status da OS
  -- Silvia            05/10/2021  Novo parametro quantidade
  -- Silvia            04/10/2022  Novo parametro vetor_flag_ignora_obrig
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_ordem_servico_id        IN os_tipo_produto.ordem_servico_id%TYPE,
  p_job_tipo_produto_id     IN job_tipo_produto.job_tipo_produto_id%TYPE,
  p_complemento             IN VARCHAR2,
  p_quantidade              IN VARCHAR2,
  p_descricao               IN CLOB,
  p_vetor_atributo_id       IN VARCHAR2,
  p_vetor_atributo_valor    IN CLOB,
  p_vetor_flag_ignora_obrig IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt                      INTEGER;
  v_identif_objeto          historico.identif_objeto%TYPE;
  v_compl_histor            historico.complemento%TYPE;
  v_historico_id            historico.historico_id%TYPE;
  v_exception               EXCEPTION;
  v_numero_os               ordem_servico.numero%TYPE;
  v_status_os               ordem_servico.status%TYPE;
  v_quantidade              os_tipo_produto.quantidade%TYPE;
  v_job_id                  job.job_id%TYPE;
  v_numero_job              job.numero%TYPE;
  v_status_job              job.status%TYPE;
  v_tipo_os_desc            tipo_os.nome%TYPE;
  v_tipo_os_id              tipo_os.tipo_os_id%TYPE;
  v_tipo_os_cod             tipo_os.codigo%TYPE;
  v_nome_produto            tipo_produto.nome%TYPE;
  v_tipo_produto_id         job_tipo_produto.tipo_produto_id%TYPE;
  v_nome_atributo           metadado.nome%TYPE;
  v_tamanho                 metadado.tamanho%TYPE;
  v_flag_obrigatorio        metadado.flag_obrigatorio%TYPE;
  v_tipo_dado               tipo_dado.codigo%TYPE;
  v_lbl_job                 VARCHAR2(100);
  v_vetor_atributo_id       LONG;
  v_vetor_atributo_valor    LONG;
  v_vetor_flag_ignora_obrig LONG;
  v_metadado_id             os_atributo_valor.metadado_id%TYPE;
  v_valor_atributo          LONG;
  v_valor_atributo_sai      LONG;
  v_delimitador             CHAR(1);
  v_flag_ignora_obrig       VARCHAR2(10);
  v_descricao               ordem_servico.descricao%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.nome,
         ti.tipo_os_id,
         ti.codigo,
         os.numero,
         os.status
    INTO v_tipo_os_desc,
         v_tipo_os_id,
         v_tipo_os_cod,
         v_numero_os,
         v_status_os
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_tipo_produto jt,
         os_tipo_produto  ot
   WHERE jt.job_tipo_produto_id = nvl(p_job_tipo_produto_id, 0)
     AND jt.job_tipo_produto_id = ot.job_tipo_produto_id
     AND ot.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Entregável não existe ou não está associado ao Workflow.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         jo.tipo_produto_id
    INTO v_nome_produto,
         v_tipo_produto_id
    FROM job_tipo_produto jo,
         tipo_produto     tp
   WHERE jo.job_tipo_produto_id = p_job_tipo_produto_id
     AND jo.tipo_produto_id = tp.tipo_produto_id;
  --
  IF length(TRIM(p_complemento)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do Entregável não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_quantidade) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade de Entregáveis inválida (' || p_quantidade || ').';
   RAISE v_exception;
  END IF;
  --
  v_quantidade := nvl(round(numero_converter(p_quantidade), 2), 0);
  --
  IF v_quantidade <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade de Entregáveis inválida (' || p_quantidade || ').';
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
  -- verifica se o tipo de produto ja existe com esse nome + complemento
  IF TRIM(p_complemento) IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_id = v_job_id
      AND tipo_produto_id = v_tipo_produto_id
      AND upper(TRIM(complemento)) = upper(TRIM(p_complemento))
      AND job_tipo_produto_id <> p_job_tipo_produto_id;
  ELSE
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_id = v_job_id
      AND tipo_produto_id = v_tipo_produto_id
      AND TRIM(complemento) IS NULL
      AND job_tipo_produto_id <> p_job_tipo_produto_id;
  END IF;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe outro Entregável com esse nome associado ao ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE os_tipo_produto
     SET descricao  = TRIM(p_descricao),
         quantidade = v_quantidade
   WHERE ordem_servico_id = p_ordem_servico_id
     AND job_tipo_produto_id = p_job_tipo_produto_id;
  --
  UPDATE job_tipo_produto
     SET complemento = TRIM(p_complemento)
   WHERE job_tipo_produto_id = p_job_tipo_produto_id;
  --
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         p_ordem_servico_id,
                                         p_erro_cod,
                                         p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  DELETE FROM os_tp_atributo_valor
   WHERE ordem_servico_id = p_ordem_servico_id
     AND job_tipo_produto_id = p_job_tipo_produto_id;
  --
  v_delimitador             := '^';
  v_vetor_atributo_id       := p_vetor_atributo_id;
  v_vetor_atributo_valor    := p_vetor_atributo_valor;
  v_vetor_flag_ignora_obrig := p_vetor_flag_ignora_obrig;
  --
  WHILE nvl(length(rtrim(v_vetor_atributo_id)), 0) > 0
  LOOP
   v_metadado_id       := to_number(prox_valor_retornar(v_vetor_atributo_id, v_delimitador));
   v_valor_atributo    := prox_valor_retornar(v_vetor_atributo_valor, v_delimitador);
   v_flag_ignora_obrig := prox_valor_retornar(v_vetor_flag_ignora_obrig, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE metadado_id = v_metadado_id
      AND grupo = 'ITEM_OS';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado do item inválido (' || to_char(v_metadado_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF flag_validar(v_flag_ignora_obrig) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag ignora obrigatoriedade inválido (' || v_flag_ignora_obrig || ').';
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
                         v_flag_ignora_obrig,
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
   INSERT INTO os_tp_atributo_valor
    (ordem_servico_id,
     job_tipo_produto_id,
     metadado_id,
     valor_atributo)
   VALUES
    (p_ordem_servico_id,
     p_job_tipo_produto_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  v_descricao := ordem_servico_pkg.nome_retornar(p_ordem_servico_id);
  --
  UPDATE ordem_servico
     SET descricao = v_descricao
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Alteração de Entregável: ' || TRIM(v_nome_produto || ' ' || p_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END; -- tipo_produto_atualizar
 --
 --
 PROCEDURE tipo_produto_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/12/2010
  -- DESCRICAO: Desassociacao de tipo_produto x OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/07/2012  Ajustes em privilegios por tipo de OS.
  -- Silvia            05/03/2020  Deixa atualizar em varios status da OS
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_ordem_servico_id    IN os_tipo_produto.ordem_servico_id%TYPE,
  p_job_tipo_produto_id IN os_tipo_produto.job_tipo_produto_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_numero_os      ordem_servico.numero%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_tipo_os_id     tipo_os.tipo_os_id%TYPE;
  v_tipo_os_desc   tipo_os.nome%TYPE;
  v_tipo_os_cod    tipo_os.codigo%TYPE;
  v_nome_produto   tipo_produto.nome%TYPE;
  v_complemento    job_tipo_produto.complemento%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_descricao      ordem_servico.descricao%TYPE;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  --
  SELECT ti.nome,
         ti.tipo_os_id,
         ti.codigo,
         os.numero,
         os.status
    INTO v_tipo_os_desc,
         v_tipo_os_id,
         v_tipo_os_cod,
         v_numero_os,
         v_status_os
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_tipo_produto
   WHERE job_tipo_produto_id = nvl(p_job_tipo_produto_id, 0);
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Entregável não associado ao ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         jo.complemento
    INTO v_nome_produto,
         v_complemento
    FROM job_tipo_produto jo,
         tipo_produto     tp
   WHERE jo.job_tipo_produto_id = p_job_tipo_produto_id
     AND jo.tipo_produto_id = tp.tipo_produto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM os_tp_atributo_valor
   WHERE ordem_servico_id = p_ordem_servico_id
     AND job_tipo_produto_id = p_job_tipo_produto_id;
  --
  DELETE FROM os_tipo_produto_ref
   WHERE ordem_servico_id = p_ordem_servico_id
     AND job_tipo_produto_id = p_job_tipo_produto_id;
  --
  DELETE FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id
     AND job_tipo_produto_id = p_job_tipo_produto_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tipo_produto
   WHERE job_tipo_produto_id = p_job_tipo_produto_id;
  --
  IF v_qt = 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE job_tipo_produto_id = p_job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    DELETE FROM job_tipo_produto
     WHERE job_tipo_produto_id = p_job_tipo_produto_id;
   END IF;
  END IF;
  --
  ordem_servico_pkg.fator_tempo_calcular(p_usuario_sessao_id,
                                         p_ordem_servico_id,
                                         p_erro_cod,
                                         p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  v_descricao := ordem_servico_pkg.nome_retornar(p_ordem_servico_id);
  --
  UPDATE ordem_servico
     SET descricao = v_descricao
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Desassociação de Entregável: ' ||
                      TRIM(v_nome_produto || ' ' || v_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END; -- tipo_produto_excluir
 --
 --
 PROCEDURE tipo_produto_refacao_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/03/2014
  -- DESCRICAO: Marca os tipos de produto passados no vetor como fazendo parte da
  --   refacao informada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_num_refacao            IN VARCHAR2,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_qtd_refacao            ordem_servico.qtd_refacao%TYPE;
  v_num_refacao            ordem_servico.qtd_refacao%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(4000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.tipo_os_id,
         os.numero,
         os.status,
         os.qtd_refacao
    INTO v_tipo_os_id,
         v_numero_os,
         v_status_os,
         v_qtd_refacao
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação (atualização de itens).';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_num_refacao) IS NULL OR inteiro_validar(p_num_refacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da refação inválido (' || p_num_refacao || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_refacao := nvl(to_number(p_num_refacao), 0);
  --
  IF v_num_refacao <> v_qtd_refacao
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os itens da última refação podem ser marcados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe ou não pertence a esse Workflow (' ||
                  to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto_ref
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_refacao;
   --
   IF v_qt = 0
   THEN
    INSERT INTO os_tipo_produto_ref
     (ordem_servico_id,
      job_tipo_produto_id,
      num_refacao,
      data_entrada)
    VALUES
     (p_ordem_servico_id,
      v_job_tipo_produto_id,
      v_num_refacao,
      SYSDATE);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Marcação de itens para refação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END tipo_produto_refacao_marcar;
 --
 --
 PROCEDURE tipo_produto_refacao_desmarcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/03/2014
  -- DESCRICAO: Desmarca os tipos de produto passados no vetor como fazendo parte da
  --   refacao informada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_ordem_servico_id       IN ordem_servico.ordem_servico_id%TYPE,
  p_num_refacao            IN VARCHAR2,
  p_vetor_job_tipo_produto IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_numero_os              ordem_servico.numero%TYPE;
  v_status_os              ordem_servico.status%TYPE;
  v_qtd_refacao            ordem_servico.qtd_refacao%TYPE;
  v_num_refacao            ordem_servico.qtd_refacao%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_numero_job             job.numero%TYPE;
  v_status_job             job.status%TYPE;
  v_tipo_os_id             tipo_os.tipo_os_id%TYPE;
  v_delimitador            CHAR(1);
  v_vetor_job_tipo_produto VARCHAR2(4000);
  v_job_tipo_produto_id    job_tipo_produto.job_tipo_produto_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(jo.job_id)
    INTO v_job_id
    FROM job           jo,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT status,
         numero
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT ti.tipo_os_id,
         os.numero,
         os.status,
         os.qtd_refacao
    INTO v_tipo_os_id,
         v_numero_os,
         v_status_os,
         v_qtd_refacao
    FROM tipo_os       ti,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação (atualização de itens).';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_num_refacao) IS NULL OR inteiro_validar(p_num_refacao) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número da refação inválido (' || p_num_refacao || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_refacao := nvl(to_number(p_num_refacao), 0);
  --
  IF v_num_refacao <> v_qtd_refacao
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os itens da última refação podem ser desmarcados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador            := '|';
  v_vetor_job_tipo_produto := p_vetor_job_tipo_produto;
  --
  WHILE nvl(length(rtrim(v_vetor_job_tipo_produto)), 0) > 0
  LOOP
   v_job_tipo_produto_id := to_number(prox_valor_retornar(v_vetor_job_tipo_produto, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM os_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse produto não existe ou não pertence a esse Workflow (' ||
                  to_char(v_job_tipo_produto_id) || ').';
    RAISE v_exception;
   END IF;
   --
   DELETE FROM os_tipo_produto_ref
    WHERE job_tipo_produto_id = v_job_tipo_produto_id
      AND ordem_servico_id = p_ordem_servico_id
      AND num_refacao = v_num_refacao;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Desmarcação de itens para refação';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END tipo_produto_refacao_desmarcar;
 --
 --
 PROCEDURE fator_tempo_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 08/12/2010
  -- DESCRICAO: subrotina que calcula o percentual de rateio para cada tipo de produto de
  --   uma determinada OS, a ser usado no calculo do tempo gasto. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_tempo_tot_prev   NUMBER;
  v_fator_tempo_calc os_tipo_produto.fator_tempo_calc%TYPE;
  v_qt_prod          INTEGER;
  v_qt_nd            INTEGER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  -- recupera totais de produtos e tempos previstos da OS
  SELECT nvl(SUM(tempo_exec_prev), 0),
         COUNT(*)
    INTO v_tempo_tot_prev,
         v_qt_prod
    FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- verifica se tem algum tempo previsto nao definido
  SELECT COUNT(*)
    INTO v_qt_nd
    FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tempo_exec_prev IS NULL;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_qt_prod = 1
  THEN
   -- OS só tem 1 produto
   v_fator_tempo_calc := 100;
   --
   UPDATE os_tipo_produto
      SET fator_tempo_calc = v_fator_tempo_calc
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  IF v_qt_prod > 1 AND v_qt_nd > 0
  THEN
   -- OS tem produtos sem tempo definido. O rateio entre eles
   -- será igual.
   v_fator_tempo_calc := round(100.0 / v_qt_prod, 2);
   --
   UPDATE os_tipo_produto
      SET fator_tempo_calc = v_fator_tempo_calc
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  IF v_qt_prod > 1 AND v_qt_nd = 0
  THEN
   -- todos os produtos da OS tem tempo definido. O rateio é
   -- proporcional ao tempo previsto informado.
   IF v_tempo_tot_prev <> 0
   THEN
    UPDATE os_tipo_produto
       SET fator_tempo_calc = round(tempo_exec_prev / v_tempo_tot_prev * 100.0, 2)
     WHERE ordem_servico_id = p_ordem_servico_id;
   ELSE
    UPDATE os_tipo_produto
       SET fator_tempo_calc = 0
     WHERE ordem_servico_id = p_ordem_servico_id;
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
 END; -- fator_tempo_calcular
 --
 --
 PROCEDURE dias_calcular
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 23/03/2015
  -- DESCRICAO: subrotina que calcula nro de dias uteis entre datas de OS numa
  --  determinada refacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/11/2016  Grava tb datas referentes a iteracao de estimativa.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN os_refacao.ordem_servico_id%TYPE,
  p_num_refacao       IN os_refacao.num_refacao%TYPE,
  p_flag_estim        IN os_refacao.flag_estim%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_saida                  EXCEPTION;
  v_data_interna           ordem_servico.data_interna%TYPE;
  v_data_solicitada        ordem_servico.data_solicitada%TYPE;
  v_data_envio             os_refacao.data_envio%TYPE;
  v_data_termino_exec      os_refacao.data_termino_exec%TYPE;
  v_data_conclusao         os_refacao.data_conclusao%TYPE;
  v_dias_prazo_interno     INTEGER;
  v_dias_prazo_solicitado  INTEGER;
  v_dias_atraso_interno    INTEGER;
  v_dias_atraso_solicitado INTEGER;
  v_dias_termino_exec      INTEGER;
  v_dias_avaliacao         INTEGER;
  v_dias_totais            INTEGER;
  --
 BEGIN
  v_qt                     := 0;
  v_dias_prazo_interno     := NULL;
  v_dias_prazo_solicitado  := NULL;
  v_dias_atraso_interno    := NULL;
  v_dias_atraso_solicitado := NULL;
  v_dias_termino_exec      := NULL;
  v_dias_avaliacao         := NULL;
  v_dias_totais            := NULL;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_refacao
   WHERE ordem_servico_id = p_ordem_servico_id
     AND num_refacao = p_num_refacao
     AND flag_estim = p_flag_estim;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow/Refação/Iteração não existe (' || to_char(p_ordem_servico_id) || '/' ||
                 to_char(p_num_refacao) || '/' || p_flag_estim || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_estim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag estimativa inválido (' || p_flag_estim || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_refacao
   WHERE ordem_servico_id = p_ordem_servico_id
     AND num_refacao = p_num_refacao
     AND flag_estim = p_flag_estim;
  --
  IF v_qt = 0
  THEN
   -- datas dessa refacao/iteracao nao instanciadas.
   -- pula o processamento.
   RAISE v_saida;
  END IF;
  --
  SELECT data_envio,
         data_termino_exec,
         data_conclusao,
         data_interna,
         data_solicitada
    INTO v_data_envio,
         v_data_termino_exec,
         v_data_conclusao,
         v_data_interna,
         v_data_solicitada
    FROM os_refacao
   WHERE ordem_servico_id = p_ordem_servico_id
     AND num_refacao = p_num_refacao
     AND flag_estim = p_flag_estim;
  --
  v_dias_prazo_interno     := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_envio,
                                                                  v_data_interna);
  v_dias_prazo_solicitado  := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_envio,
                                                                  v_data_solicitada);
  v_dias_atraso_solicitado := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_solicitada,
                                                                  v_data_termino_exec);
  v_dias_atraso_interno    := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_interna,
                                                                  v_data_termino_exec);
  v_dias_termino_exec      := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_envio,
                                                                  v_data_termino_exec);
  v_dias_avaliacao         := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_termino_exec,
                                                                  v_data_conclusao);
  v_dias_totais            := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                                  v_data_envio,
                                                                  v_data_conclusao);
  --
  IF v_dias_prazo_interno < 0
  THEN
   v_dias_prazo_interno := 0;
  ELSIF v_dias_prazo_interno > 99999
  THEN
   v_dias_prazo_interno := 99999;
  END IF;
  --
  IF v_dias_prazo_solicitado < 0
  THEN
   v_dias_prazo_solicitado := 0;
  ELSIF v_dias_prazo_solicitado > 99999
  THEN
   v_dias_prazo_solicitado := 99999;
  END IF;
  --
  IF v_dias_atraso_solicitado < 0
  THEN
   v_dias_atraso_solicitado := 0;
  ELSIF v_dias_atraso_solicitado > 99999
  THEN
   v_dias_atraso_solicitado := 99999;
  END IF;
  --
  IF v_dias_atraso_interno < 0
  THEN
   v_dias_atraso_interno := 0;
  ELSIF v_dias_atraso_interno > 99999
  THEN
   v_dias_atraso_interno := 99999;
  END IF;
  --
  IF v_dias_termino_exec < 0
  THEN
   v_dias_termino_exec := 0;
  ELSIF v_dias_termino_exec > 99999
  THEN
   v_dias_termino_exec := 99999;
  END IF;
  --
  IF v_dias_avaliacao < 0
  THEN
   v_dias_avaliacao := 0;
  ELSIF v_dias_avaliacao > 99999
  THEN
   v_dias_avaliacao := 99999;
  END IF;
  --
  IF v_dias_totais < 0
  THEN
   v_dias_totais := 0;
  ELSIF v_dias_totais > 99999
  THEN
   v_dias_totais := 99999;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  UPDATE os_refacao
     SET dias_prazo_interno     = v_dias_prazo_interno,
         dias_prazo_solicitado  = v_dias_prazo_solicitado,
         dias_atraso_solicitado = v_dias_atraso_solicitado,
         dias_atraso_interno    = v_dias_atraso_interno,
         dias_termino_exec      = v_dias_termino_exec,
         dias_avaliacao         = v_dias_avaliacao,
         dias_totais            = v_dias_totais
   WHERE ordem_servico_id = p_ordem_servico_id
     AND num_refacao = p_num_refacao
     AND flag_estim = p_flag_estim;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END dias_calcular;
 --
 --
 PROCEDURE aprovacao_autom_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 07/04/2017
  -- DESCRICAO: procedure a ser chamada de tempos em tempos (via job) para processar a
  --  aprovacao automativa de OS para os usuarios programados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/11/2017  Implementacao de flag_ativo.
  -- Silvia            22/02/2019  Nao executa o processamento de madrugada.
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_saida            EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_faixa_aprov_id   faixa_aprov.faixa_aprov_id%TYPE;
  v_flag_sequencial  faixa_aprov.flag_sequencial%TYPE;
  v_tipo_aprov       os_fluxo_aprov.tipo_aprov%TYPE;
  v_seq_aprov        os_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_max    os_fluxo_aprov.seq_aprov%TYPE;
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_os_estim_id      ordem_servico.os_estim_id%TYPE;
  v_usuario_id       usuario.usuario_id%TYPE;
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_papel_id         papel.papel_id%TYPE;
  v_cliente_id       job.cliente_id%TYPE;
  v_tipo_job_id      job.tipo_job_id%TYPE;
  v_complex_job      job.complex_job%TYPE;
  v_empresa_id       job.empresa_id%TYPE;
  v_cod_acao_os      VARCHAR2(100);
  v_qt_seq_tot       NUMBER(5);
  v_qt_seq_aprov     NUMBER(5);
  v_qt_seq_pula      NUMBER(5);
  v_seq_completa     NUMBER(5);
  v_verif_transicao  NUMBER(5);
  v_para_loop_seq    NUMBER(5);
  v_continua         NUMBER(5);
  v_qt_inst          NUMBER(5);
  v_numero_os_char   VARCHAR2(50);
  v_hora             NUMBER(5);
  --
  -- cursor de OS em aprovacao
  CURSOR c_os IS
   SELECT os.ordem_servico_id,
          os.flag_aprov_est_seq,
          os.flag_aprov_exe_seq,
          jo.empresa_id,
          oe.os_estim_id,
          oe.status AS status_estim,
          jo.cliente_id,
          jo.tipo_job_id,
          jo.complex_job
     FROM ordem_servico os,
          job           jo,
          os_estim      oe
    WHERE os.status = 'EMAP'
      AND os.job_id = jo.job_id
      AND os.os_estim_id = oe.os_estim_id(+);
  --
  -- cursor de papeis habilitados na sequencia atual
  CURSOR c_pa IS
   SELECT papel_id
     FROM os_fluxo_aprov
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_aprov = v_tipo_aprov
      AND seq_aprov = v_seq_aprov
      AND data_aprov IS NULL
      AND flag_habilitado = 'S';
  --
  -- cursor de OS na mesma estimativa
  CURSOR c_oe IS
   SELECT jo.job_id,
          jo.status              AS status_job,
          os.ordem_servico_id,
          os.status              AS status_os,
          os.dias_estim,
          os.tipo_os_id,
          ti.codigo              AS cod_tipo_os,
          ti.flag_tem_pontos_tam AS flag_tem_tamanho,
          os.tamanho
     FROM ordem_servico os,
          job           jo,
          tipo_os       ti
    WHERE os.os_estim_id = v_os_estim_id
      AND os.job_id = jo.job_id
      AND os.tipo_os_id = ti.tipo_os_id;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  v_hora := to_number(to_char(SYSDATE, 'HH24'));
  --
  -- pula o processamento nesse intervalo de horas
  IF (v_hora BETWEEN 23 AND 24) OR (v_hora BETWEEN 0 AND 7)
  THEN
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- verifica se existe aprovacao automatica a processar
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE flag_os_aprov_auto = 'S'
     AND trunc(SYSDATE) BETWEEN data_ini AND data_fim;
  --
  IF v_qt = 0
  THEN
   -- nao existe. pula o processamento
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- LOOP POR OS EM APROVACAO
  ------------------------------------------------------------
  FOR r_os IN c_os
  LOOP
   v_ordem_servico_id := r_os.ordem_servico_id;
   v_empresa_id       := r_os.empresa_id;
   v_cliente_id       := r_os.cliente_id;
   v_tipo_job_id      := r_os.tipo_job_id;
   v_complex_job      := r_os.complex_job;
   v_os_estim_id      := r_os.os_estim_id;
   --
   v_numero_os_char := numero_formatar(v_ordem_servico_id);
   --dbms_output.put_line('Workflow: ' || v_numero_os_char);
   --
   v_verif_transicao := 1;
   --
   -- verifica o tipo de iteracao da aprovacao (estimativa ou execucao)
   IF v_os_estim_id IS NOT NULL AND r_os.status_estim = 'ANDA'
   THEN
    v_tipo_aprov      := 'EST';
    v_flag_sequencial := r_os.flag_aprov_est_seq;
   ELSE
    v_tipo_aprov      := 'EXE';
    v_flag_sequencial := r_os.flag_aprov_exe_seq;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt_inst
     FROM os_fluxo_aprov
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_aprov = v_tipo_aprov;
   --
   --
   IF v_qt_inst = 0 AND v_tipo_aprov = 'EST'
   THEN
    ------------------------------------------------------------
    -- FLUXO NAO INSTANCIADO DE ESTIMATIVA
    ------------------------------------------------------------
    v_continua := 1;
    -- aprovacao de ESTIMATIVA. Verifica se existe algum usuario que pode aprovar
    -- (na posicao 1 para sequencial ou qualquer posicao para nao sequencial)
    SELECT COUNT(*)
      INTO v_qt
      FROM faixa_aprov       fa,
           faixa_aprov_papel fp,
           faixa_aprov_os    fo,
           usuario_papel     up
     WHERE fa.empresa_id = v_empresa_id
       AND fa.tipo_faixa = 'OS'
       AND fa.flag_ativo = 'S'
       AND fa.faixa_aprov_id = fo.faixa_aprov_id
       AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
       AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
       AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
       AND fo.flag_aprov_est = 'S'
       AND fa.faixa_aprov_id = fp.faixa_aprov_id
       AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
       AND fp.papel_id = up.papel_id
       AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                  'OS_AP',
                                                  up.papel_id,
                                                  v_ordem_servico_id) = 1;
    --
    IF v_qt = 0
    THEN
     -- nenhum usuario aprovador encontrado nas regras
     v_continua        := 0;
     v_verif_transicao := 0;
    END IF;
    --
    IF v_continua = 1
    THEN
     -- verifica se existe algum usuario aprovador que nao esteja com aprovacao
     -- automatica nas regras (na posicao 1 para sequencial ou qualquer posicao
     -- para nao sequencial)
     SELECT COUNT(*)
       INTO v_qt
       FROM faixa_aprov       fa,
            faixa_aprov_papel fp,
            faixa_aprov_os    fo,
            usuario_papel     up
      WHERE fa.empresa_id = v_empresa_id
        AND fa.tipo_faixa = 'OS'
        AND fa.flag_ativo = 'S'
        AND fa.faixa_aprov_id = fo.faixa_aprov_id
        AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
        AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
        AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
        AND fo.flag_aprov_est = 'S'
        AND fa.faixa_aprov_id = fp.faixa_aprov_id
        AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
        AND fp.papel_id = up.papel_id
        AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                   'OS_AP',
                                                   up.papel_id,
                                                   v_ordem_servico_id) = 1
        AND NOT EXISTS (SELECT 1
               FROM apontam_progr ap
              WHERE ap.flag_os_aprov_auto = 'S'
                AND ap.usuario_id = up.usuario_id
                AND trunc(SYSDATE) BETWEEN ap.data_ini AND ap.data_fim);
     --
     IF v_qt > 0
     THEN
      -- existe usuario que pode aprovar
      v_continua        := 0;
      v_verif_transicao := 0;
     END IF;
    END IF;
    --
    IF v_continua = 1
    THEN
     -- se checou ate aqui, indica que todas as regras estao com aprovacao automatica.
     -- Pega uma das regras para instanciar
     v_faixa_aprov_id := ordem_servico_pkg.faixa_aprov_id_retornar(0,
                                                                   v_empresa_id,
                                                                   v_ordem_servico_id,
                                                                   v_tipo_aprov);
     IF v_faixa_aprov_id > 0
     THEN
      -- precisa instanciar o fluxo
      SELECT flag_sequencial
        INTO v_flag_sequencial
        FROM faixa_aprov
       WHERE faixa_aprov_id = v_faixa_aprov_id;
      --
      INSERT INTO os_fluxo_aprov
       (ordem_servico_id,
        tipo_aprov,
        papel_id,
        seq_aprov,
        flag_habilitado)
       SELECT v_ordem_servico_id,
              v_tipo_aprov,
              papel_id,
              seq_aprov,
              'S'
         FROM faixa_aprov_papel
        WHERE faixa_aprov_id = v_faixa_aprov_id;
      --
      UPDATE ordem_servico
         SET flag_aprov_est_seq = v_flag_sequencial,
             faixa_aprov_est_id = v_faixa_aprov_id
       WHERE ordem_servico_id = v_ordem_servico_id;
     END IF;
    END IF; -- fim do IF v_continua = 1
   END IF; -- fim do IF v_qt_inst = 0 AND v_tipo_aprov = 'EST'
   --
   --
   IF v_qt_inst = 0 AND v_tipo_aprov = 'EXE'
   THEN
    ------------------------------------------------------------
    -- FLUXO NAO INSTANCIADO DE EXECUCAO
    ------------------------------------------------------------
    v_continua := 1;
    -- aprovacao de EXECUCAO. Verifica se existe algum usuario que pode aprovar
    -- (na posicao 1 para sequencial ou qualquer posicao para nao sequencial)
    SELECT COUNT(*)
      INTO v_qt
      FROM faixa_aprov       fa,
           faixa_aprov_papel fp,
           faixa_aprov_os    fo,
           usuario_papel     up
     WHERE fa.empresa_id = v_empresa_id
       AND fa.tipo_faixa = 'OS'
       AND fa.flag_ativo = 'S'
       AND fa.faixa_aprov_id = fo.faixa_aprov_id
       AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
       AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
       AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
       AND fo.flag_aprov_exe = 'S'
       AND fa.faixa_aprov_id = fp.faixa_aprov_id
       AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
       AND fp.papel_id = up.papel_id
       AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                  'OS_AP',
                                                  up.papel_id,
                                                  v_ordem_servico_id) = 1;
    --
    IF v_qt = 0
    THEN
     -- nenhum usuario aprovador encontrado nas regras
     v_continua        := 0;
     v_verif_transicao := 0;
    END IF;
    --
    IF v_continua = 1
    THEN
     -- verifica se existe algum usuario aprovador que nao esteja com aprovacao
     -- automatica nas regras (na posicao 1 para sequencial ou qualquer posicao
     -- para nao sequencial)
     SELECT COUNT(*)
       INTO v_qt
       FROM faixa_aprov       fa,
            faixa_aprov_papel fp,
            faixa_aprov_os    fo,
            usuario_papel     up
      WHERE fa.empresa_id = v_empresa_id
        AND fa.tipo_faixa = 'OS'
        AND fa.flag_ativo = 'S'
        AND fa.faixa_aprov_id = fo.faixa_aprov_id
        AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
        AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
        AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
        AND fo.flag_aprov_exe = 'S'
        AND fa.faixa_aprov_id = fp.faixa_aprov_id
        AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
        AND fp.papel_id = up.papel_id
        AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                   'OS_AP',
                                                   up.papel_id,
                                                   v_ordem_servico_id) = 1
        AND NOT EXISTS (SELECT 1
               FROM apontam_progr ap
              WHERE ap.flag_os_aprov_auto = 'S'
                AND ap.usuario_id = up.usuario_id
                AND trunc(SYSDATE) BETWEEN ap.data_ini AND ap.data_fim);
     --
     IF v_qt > 0
     THEN
      -- existe usuario que pode aprovar
      v_continua        := 0;
      v_verif_transicao := 0;
     END IF;
    END IF;
    --
    IF v_continua = 1
    THEN
     -- se checou ate aqui, indica que todas as regras estao com aprovacao automatica.
     -- Pega uma das regras para instanciar
     v_faixa_aprov_id := ordem_servico_pkg.faixa_aprov_id_retornar(0,
                                                                   v_empresa_id,
                                                                   v_ordem_servico_id,
                                                                   v_tipo_aprov);
     IF v_faixa_aprov_id > 0
     THEN
      -- precisa instanciar o fluxo
      SELECT flag_sequencial
        INTO v_flag_sequencial
        FROM faixa_aprov
       WHERE faixa_aprov_id = v_faixa_aprov_id;
      --
      INSERT INTO os_fluxo_aprov
       (ordem_servico_id,
        tipo_aprov,
        papel_id,
        seq_aprov,
        flag_habilitado)
       SELECT v_ordem_servico_id,
              v_tipo_aprov,
              papel_id,
              seq_aprov,
              'S'
         FROM faixa_aprov_papel
        WHERE faixa_aprov_id = v_faixa_aprov_id;
      --
      UPDATE ordem_servico
         SET flag_aprov_exe_seq = v_flag_sequencial,
             faixa_aprov_exe_id = v_faixa_aprov_id
       WHERE ordem_servico_id = v_ordem_servico_id;
     END IF;
    END IF; -- fim do IF v_continua = 1
   END IF; -- fim do IF v_qt_inst = 0 AND v_tipo_aprov = 'EXE'
   --
   --
   IF v_qt_inst > 0
   THEN
    ------------------------------------------------------------
    -- FLUXO JA INSTANCIADO
    ------------------------------------------------------------
    SELECT nvl(MAX(seq_aprov), 0)
      INTO v_seq_aprov_max
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = v_ordem_servico_id
       AND tipo_aprov = v_tipo_aprov;
    --
    v_seq_aprov     := 1;
    v_para_loop_seq := 0;
    -- loop por sequencia de aprovacao
    WHILE v_seq_aprov <= v_seq_aprov_max AND v_para_loop_seq = 0
    LOOP
     v_continua := 1;
     --
     -- verifica aprovacoes ou desabilitacoes nessa sequencia
     SELECT COUNT(seq_aprov),
            COUNT(usuario_aprov_id),
            nvl(SUM(decode(flag_habilitado, 'S', 0, 'N', 1)), 0)
       INTO v_qt_seq_tot,
            v_qt_seq_aprov,
            v_qt_seq_pula
       FROM os_fluxo_aprov
      WHERE ordem_servico_id = v_ordem_servico_id
        AND tipo_aprov = v_tipo_aprov
        AND seq_aprov = v_seq_aprov;
     --
     v_seq_completa := 0;
     IF v_qt_seq_aprov > 0 OR v_qt_seq_tot = v_qt_seq_pula
     THEN
      -- a sequencia esta completa. Passa para a proxima.
      v_seq_completa := 1;
     END IF;
     --
     IF v_seq_completa = 0
     THEN
      -- a sequencia esta incompleta.
      -- verifica se algum papel dessa sequencia tem usuario que pode aprovar
      SELECT COUNT(*)
        INTO v_qt
        FROM os_fluxo_aprov oa,
             usuario_papel  up
       WHERE oa.ordem_servico_id = v_ordem_servico_id
         AND oa.tipo_aprov = v_tipo_aprov
         AND oa.seq_aprov = v_seq_aprov
         AND oa.flag_habilitado = 'S'
         AND oa.papel_id = up.papel_id
         AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                    'OS_AP',
                                                    up.papel_id,
                                                    v_ordem_servico_id) = 1;
      --
      IF v_qt = 0
      THEN
       -- nenhum usuario encontrado nessa sequencia
       v_continua := 0;
       --
       IF v_flag_sequencial = 'S'
       THEN
        -- Interrompe o processamento das demais sequencias
        v_para_loop_seq   := 1;
        v_verif_transicao := 0;
       END IF;
      END IF;
      --
      IF v_continua = 1
      THEN
       -- verifica se existe algum usuario aprovador que nao esteja com aprovacao
       -- automatica.
       SELECT COUNT(*)
         INTO v_qt
         FROM os_fluxo_aprov oa,
              usuario_papel  up
        WHERE oa.ordem_servico_id = v_ordem_servico_id
          AND oa.tipo_aprov = v_tipo_aprov
          AND oa.seq_aprov = v_seq_aprov
          AND oa.flag_habilitado = 'S'
          AND oa.papel_id = up.papel_id
          AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                     'OS_AP',
                                                     up.papel_id,
                                                     v_ordem_servico_id) = 1
          AND NOT EXISTS (SELECT 1
                 FROM apontam_progr ap
                WHERE ap.flag_os_aprov_auto = 'S'
                  AND ap.usuario_id = up.usuario_id
                  AND trunc(SYSDATE) BETWEEN ap.data_ini AND ap.data_fim);
       --
       IF v_qt > 0
       THEN
        -- existe usuario que pode aprovar.
        v_continua := 0;
        --
        IF v_flag_sequencial = 'S'
        THEN
         -- interrompe o processamento das demais sequencias
         v_para_loop_seq   := 1;
         v_verif_transicao := 0;
        END IF;
       END IF;
      END IF; -- fim do IF v_continua = 1
      --
      IF v_continua = 1
      THEN
       -- se chegou ate aqui, indica que todos os usuarios dessa sequencia estao com
       -- aprovacao automatica.
       v_usuario_id := NULL;
       v_papel_id   := NULL;
       --
       FOR r_pa IN c_pa
       LOOP
        -- varre papeis habilitados e busca o primeiro usuario com aprovacao automatica
        IF v_usuario_id IS NULL
        THEN
         SELECT MAX(up.usuario_id)
           INTO v_usuario_id
           FROM usuario_papel up,
                apontam_progr ap
          WHERE up.papel_id = r_pa.papel_id
            AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                       'OS_AP',
                                                       r_pa.papel_id,
                                                       v_ordem_servico_id) = 1
            AND up.usuario_id = ap.usuario_id
            AND ap.flag_os_aprov_auto = 'S'
            AND trunc(SYSDATE) BETWEEN ap.data_ini AND ap.data_fim;
         --
         v_papel_id := r_pa.papel_id;
        END IF;
       END LOOP;
       --
       IF v_usuario_id IS NOT NULL
       THEN
        -- registra a aprovacao automatica nessa sequencia
        UPDATE os_fluxo_aprov
           SET flag_aprov_auto  = 'S',
               usuario_aprov_id = v_usuario_id,
               data_aprov       = SYSDATE
         WHERE ordem_servico_id = v_ordem_servico_id
           AND tipo_aprov = v_tipo_aprov
           AND seq_aprov = v_seq_aprov
           AND papel_id = v_papel_id;
       END IF;
      END IF; -- fom do IF v_continua = 1
      --
     END IF; -- fim do IF v_seq_completa = 0
     --
     v_seq_aprov := v_seq_aprov + 1;
    END LOOP; -- fim do loop por sequencia
   END IF; -- fim do IF v_qt_inst > 0
   --
   ---------------------------------------------------------
   -- verifica se precisa executar a transicao de APROVAR
   ---------------------------------------------------------
   IF v_verif_transicao = 1 AND
      ordem_servico_pkg.fluxo_seq_ok_verificar(v_ordem_servico_id, v_tipo_aprov) = 1
   THEN
    --
    IF v_tipo_aprov = 'EST'
    THEN
     v_cod_acao_os := 'APROVAR_EST';
    ELSE
     v_cod_acao_os := 'APROVAR';
    END IF;
    --
    -- nenhuma aprovacao pendente. Precisa executar a transicao como usuário administrador.
    ordem_servico_pkg.acao_executar(v_usuario_admin_id,
                                    v_empresa_id,
                                    'N',
                                    v_ordem_servico_id,
                                    v_cod_acao_os,
                                    0,
                                    'Aprovação automática',
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL,
                                    v_erro_cod,
                                    v_erro_msg);
    IF v_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    IF v_cod_acao_os = 'APROVAR_EST' AND v_os_estim_id IS NOT NULL
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM ordem_servico
      WHERE os_estim_id = v_os_estim_id
        AND status <> 'PREP';
     --
     IF v_qt = 0
     THEN
      -- todas as OS da estimativa estao em PREP. Pode continuar.
      UPDATE os_estim
         SET status      = 'CONC',
             data_status = SYSDATE
       WHERE os_estim_id = v_os_estim_id;
      --
      FOR r_oe IN c_oe
      LOOP
       -- seleciona o codigo da acao para enviar (com ou sem distribuicao)
       SELECT MAX(tr.cod_acao)
         INTO v_cod_acao_os
         FROM os_transicao      tr,
              tipo_os_transicao ti
        WHERE tr.status_de = 'PREP'
          AND tr.cod_acao LIKE 'ENVIAR%DIST'
          AND ti.tipo_os_id = r_oe.tipo_os_id
          AND ti.os_transicao_id = tr.os_transicao_id;
       --
       IF v_cod_acao_os IS NULL
       THEN
        v_erro_cod := '90000';
        v_erro_msg := 'Código da ação ENVIAR não encontrado para esse tipo de Workflow (' ||
                      r_oe.cod_tipo_os || ') .';
        RAISE v_exception;
       END IF;
       --
       -- executa transicao de enviar
       ordem_servico_pkg.acao_executar(v_usuario_admin_id,
                                       v_empresa_id,
                                       'N',
                                       r_oe.ordem_servico_id,
                                       v_cod_acao_os,
                                       0,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       v_erro_cod,
                                       v_erro_msg);
       IF v_erro_cod <> '00000'
       THEN
        RAISE v_exception;
       END IF;
      END LOOP;
     END IF; -- fim do IF v_qt = 0
    END IF; -- fim do IF v_cod_acao_os = 'APROVAR_EST' AND v_os_estim_id IS NOT NULL
   END IF; -- fim do IF v_verif_transicao = 1
   --
   COMMIT;
  END LOOP; -- fim do loop por OS
  --
  COMMIT;
  --
 EXCEPTION
  WHEN v_saida THEN
   COMMIT;
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
     'ordem_servico_pkg.aprovacao_autom_processar',
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
     'ordem_servico_pkg.aprovacao_autom_processar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END aprovacao_autom_processar;
 --
 --
 PROCEDURE aval_cliente_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 09/09/2022
  -- DESCRICAO: Registra a avaliacao dos entregaveis pelo cliente
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_nota_aval_cli     IN VARCHAR2,
  p_coment_aval_cli   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_nota_aval_cli  ordem_servico.nota_aval_cli%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status
    INTO v_job_id,
         v_status_job,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF v_status_os <> 'CONC'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nota_aval_cli) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da nota de avaliação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_nota_aval_cli) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nota de avaliação inválida (' || p_nota_aval_cli || ').';
   RAISE v_exception;
  END IF;
  --
  v_nota_aval_cli := nvl(to_number(p_nota_aval_cli), 0);
  --
  IF v_nota_aval_cli NOT BETWEEN 1 AND 5
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nota de avaliação inválida (' || p_nota_aval_cli || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE ordem_servico
     SET coment_aval_cli = TRIM(p_coment_aval_cli),
         nota_aval_cli   = v_nota_aval_cli,
         data_aval_cli   = SYSDATE
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := numero_formatar(p_ordem_servico_id);
  v_compl_histor   := 'Avaliação do cliente';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'ORDEM_SERVICO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_ordem_servico_id,
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
 END aval_cliente_registrar;
 --
 --
 PROCEDURE aprov_cliente_registrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 09/09/2022
  -- DESCRICAO: Registra a avaliacao dos entregaveis pelo cliente e executa a
  --  transicao de status de aprovacao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_flag_com_aval     IN VARCHAR2,
  p_nota_aval_cli     IN VARCHAR2,
  p_coment_aval_cli   IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_os      ordem_servico.status%TYPE;
  v_nota_aval_cli  ordem_servico.nota_aval_cli%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_os_evento_id   os_evento.os_evento_id%TYPE;
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
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.status,
         os.status
    INTO v_job_id,
         v_status_job,
         v_status_os
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF flag_validar(p_flag_com_aval) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag com avaliação inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_os <> 'EMAP'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Workflow não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_flag_com_aval = 'S' AND TRIM(p_nota_aval_cli) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da nota de avaliação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_nota_aval_cli) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nota de avaliação inválida (' || p_nota_aval_cli || ').';
   RAISE v_exception;
  END IF;
  --
  v_nota_aval_cli := nvl(to_number(p_nota_aval_cli), 0);
  --
  IF p_flag_com_aval = 'S' AND v_nota_aval_cli NOT BETWEEN 1 AND 5
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nota de avaliação inválida (' || p_nota_aval_cli || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_com_aval = 'S'
  THEN
   UPDATE ordem_servico
      SET coment_aval_cli = TRIM(p_coment_aval_cli),
          nota_aval_cli   = v_nota_aval_cli,
          data_aval_cli   = SYSDATE
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  -- executa a transicao de status
  IF p_flag_com_aval = 'S'
  THEN
   v_compl_histor := 'Aprovação do cliente com avaliação';
  ELSE
   v_compl_histor := 'Aprovação do cliente sem avaliação';
  END IF;
  --
  ordem_servico_pkg.acao_executar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  'N',
                                  p_ordem_servico_id,
                                  'APROVAR',
                                  0,
                                  v_compl_histor,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  p_erro_cod,
                                  p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(os_evento_id)
    INTO v_os_evento_id
    FROM os_evento
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  -- marca o ultimo evento registrado na transicao como
  -- sendo da interface de cliente.
  UPDATE os_evento
     SET tipo_cliente_agencia = 'CLI'
   WHERE os_evento_id = v_os_evento_id;
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
 END aprov_cliente_registrar;
 --
 PROCEDURE duplicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias                   ProcessMind     DATA: 14/11/2023
  -- DESCRICAO: Duplica uma ordem de serviço no mesmo job ou em outro, colocando-o
  --            no status PREP e sem histórico, sem executores, sem arquivos de execução,
  --            sem refação - como se estivesse tendo sido criada nova
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         02/07/2024  Alteracao para tratar complemento nulo
  -- Ana Luiza         09/06/2025  Adicionando para pegar ultimo job_tipo_produto_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_os_nova_id        OUT ordem_servico.ordem_servico_id%TYPE,
  p_os_nova_numero    OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_os_evento_id         os_evento.os_evento_id%TYPE;
  v_exception            EXCEPTION;
  v_job_status           job.status%TYPE;
  v_job_numero           job.numero%TYPE;
  v_lbl_job              VARCHAR2(100);
  v_ordem_servico_id     ordem_servico.ordem_servico_id%TYPE;
  v_tipo_os_id           tipo_os.tipo_os_id%TYPE;
  v_padrao_numeracao_os  VARCHAR2(50);
  v_cod_empresa          empresa_sist_ext.cod_ext_empresa%TYPE;
  v_sistema_externo_id   sistema_externo.sistema_externo_id%TYPE;
  v_cod_emp_resp         empr_resp_sist_ext.cod_ext_resp%TYPE;
  v_emp_resp_id          job.emp_resp_id%TYPE;
  v_numero_job           job.numero%TYPE;
  v_numero_os            ordem_servico.numero%TYPE;
  v_descricao_os         ordem_servico.descricao%TYPE;
  v_numero_os_aux        ordem_servico.numero%TYPE;
  v_comentario           os_evento.comentario%TYPE;
  v_num_os_old           VARCHAR2(100);
  v_numero_os_char       VARCHAR2(50);
  v_tipo_os_desc         tipo_os.nome%TYPE;
  v_tipo_os_cod          tipo_os.codigo%TYPE;
  v_tipo_os_old_id       tipo_os.tipo_os_id%TYPE;
  v_flag_faixa_aprov     tipo_os.flag_faixa_aprov%TYPE;
  v_flag_tem_estim       tipo_os.flag_tem_estim%TYPE;
  v_flag_estim_custo     tipo_os.flag_estim_custo%TYPE;
  v_flag_estim_prazo     tipo_os.flag_estim_prazo%TYPE;
  v_flag_estim_arq       tipo_os.flag_estim_arq%TYPE;
  v_flag_estim_horas_usu tipo_os.flag_estim_horas_usu%TYPE;
  v_flag_estim_obs       tipo_os.flag_estim_obs%TYPE;
  v_flag_exec_estim      tipo_os.flag_exec_estim%TYPE;
  v_cronograma_id        cronograma.cronograma_id%TYPE;
  v_item_crono_id        item_crono.item_crono_id%TYPE;
  v_job_tipo_produto_id  job_tipo_produto.job_tipo_produto_id%TYPE;
  --
 BEGIN
  v_qt                  := 0;
  v_lbl_job             := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_padrao_numeracao_os := empresa_pkg.parametro_retornar(p_empresa_id, 'PADRAO_NUMERACAO_OS');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --
  SELECT tipo_os_id,
         ordem_servico_pkg.numero_formatar(ordem_servico_id),
         descricao
    INTO v_tipo_os_id,
         v_num_os_old,
         v_descricao_os
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'OS_C', p_job_id, v_tipo_os_id, p_empresa_id) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job jo
   WHERE jo.job_id = p_job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         jo.numero
    INTO v_job_status,
         v_job_numero
    FROM job jo
   WHERE jo.job_id = p_job_id;
  --
  IF v_job_status NOT IN ('PREP', 'ANDA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' escolhido não permite esta operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_padrao_numeracao_os NOT IN ('SEQUENCIAL_POR_JOB', 'SEQUENCIAL_POR_TIPO_OS') OR
     TRIM(v_padrao_numeracao_os) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Padrão de numeração de Workflow inválido ou não definido (' ||
                 v_padrao_numeracao_os || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  SELECT codigo,
         nome,
         flag_faixa_aprov,
         flag_tem_estim,
         flag_estim_custo,
         flag_estim_prazo,
         flag_estim_arq,
         flag_estim_horas_usu,
         flag_estim_obs,
         flag_exec_estim
    INTO v_tipo_os_cod,
         v_tipo_os_desc,
         v_flag_faixa_aprov,
         v_flag_tem_estim,
         v_flag_estim_custo,
         v_flag_estim_prazo,
         v_flag_estim_arq,
         v_flag_estim_horas_usu,
         v_flag_estim_obs,
         v_flag_exec_estim
    FROM tipo_os
   WHERE tipo_os_id = v_tipo_os_id;
  --
  SELECT seq_ordem_servico.nextval
    INTO v_ordem_servico_id
    FROM dual;
  --
  -- recupera dados para gerar numero da OS por tipo, com base em 
  -- numeracao ja existente em sistemas legados.
  SELECT MAX(sistema_externo_id)
    INTO v_sistema_externo_id
    FROM sistema_externo
   WHERE tipo_sistema = 'FIN'
     AND flag_ativo = 'S';
  --
  SELECT MAX(cod_ext_empresa)
    INTO v_cod_empresa
    FROM empresa_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND empresa_id = p_empresa_id;
  --
  SELECT MAX(cod_ext_resp)
    INTO v_cod_emp_resp
    FROM empr_resp_sist_ext
   WHERE sistema_externo_id = v_sistema_externo_id
     AND pessoa_id = v_emp_resp_id;
  --
  SELECT nvl(MAX(num_ult_os), 0) + 1
    INTO v_numero_os_aux
    FROM numero_os
   WHERE cod_empresa = v_cod_empresa
     AND cod_emp_resp = v_cod_emp_resp
     AND num_job = v_numero_job
     AND cod_tipo_os = v_tipo_os_cod;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_JOB'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico
    WHERE job_id = p_job_id;
  END IF;
  --
  IF v_padrao_numeracao_os = 'SEQUENCIAL_POR_TIPO_OS'
  THEN
   SELECT nvl(MAX(numero), 0) + 1
     INTO v_numero_os
     FROM ordem_servico os,
          tipo_os       ti
    WHERE os.job_id = p_job_id
      AND os.tipo_os_id = ti.tipo_os_id
      AND ti.codigo = v_tipo_os_cod;
   --
   -- verifica numeracao de sistema legado
   SELECT nvl(MAX(num_ult_os), 0) + 1
     INTO v_numero_os_aux
     FROM numero_os
    WHERE cod_empresa = v_cod_empresa
      AND cod_emp_resp = v_cod_emp_resp
      AND num_job = v_numero_job
      AND cod_tipo_os = v_tipo_os_cod;
   --
   IF v_numero_os_aux > v_numero_os
   THEN
    v_numero_os := v_numero_os_aux;
   END IF;
  END IF;
  --
  -- criar workflow diplicado
  --
  INSERT INTO ordem_servico
   (ordem_servico_id,
    job_id,
    milestone_id,
    tipo_os_id,
    tipo_financeiro_id,
    os_evento_id,
    ordem_servico_ori_id,
    os_estim_id,
    numero,
    descricao,
    data_entrada,
    data_solicitada,
    data_interna,
    data_dist_limite,
    data_aprov_limite,
    texto_os,
    qtd_refacao,
    status,
    tamanho,
    cod_ext_os,
    cod_hash,
    flag_recusada,
    flag_faixa_aprov,
    flag_com_estim,
    flag_aprov_est_seq,
    flag_aprov_exe_seq,
    faixa_aprov_est_id,
    faixa_aprov_exe_id,
    custo_estim,
    dias_estim,
    flag_estim_custo,
    flag_estim_prazo,
    flag_estim_arq,
    flag_estim_horas_usu,
    flag_estim_obs,
    flag_exec_estim,
    obs_estim,
    demanda,
    data_demanda,
    flag_em_negociacao,
    data_inicio,
    data_termino,
    data_execucao,
    acao_executada,
    data_conclusao,
    nota_aval_cli,
    data_aval_cli,
    coment_aval_cli)
   SELECT v_ordem_servico_id, --novo id
          p_job_id, --mesmo ou novo job_id
          NULL, --milestone_id
          tipo_os_id,
          tipo_financeiro_id,
          NULL, --os_evento_id
          NULL, --ordem_servico_ori_id
          NULL, --os_estim_id
          v_numero_os, --novo número
          descricao,
          SYSDATE, --data_entrada
          data_solicitada,
          NULL, --data_interna
          NULL, --data_dist_limite
          NULL, --data_aprov_limite
          texto_os,
          0, --qtd_refacao
          'PREP', --status
          tamanho,
          NULL, --cod_ext_os
          rawtohex(sys_guid()), --cod_hash
          'N', --flag_recusada
          v_flag_faixa_aprov, --flag_faixa_aprov
          v_flag_tem_estim, --flag_com_estim
          'N', --flag_aprov_est_seq
          'N', --flag_aprov_exe_seq
          NULL, --faixa_aprov_est_id
          NULL, --faixa_aprov_exe_id
          NULL, --custo_estim
          NULL, --dias_estim
          v_flag_estim_custo, --flag_estim_custo
          v_flag_estim_prazo, --flag_estim_prazo
          v_flag_estim_arq, --flag_estim_arq
          v_flag_estim_horas_usu, --flag_estim_horas_usu
          v_flag_estim_obs, --flag_estim_obs
          v_flag_exec_estim, --flag_exec_estim
          NULL, --obs_estim
          'IME', --demanda
          NULL, --data_demanda
          'N', --flag_em_negociacao
          NULL, --data_inicio
          NULL, --data_termino
          NULL, --data_execucao
          'CRIAR', --acao_executada
          NULL, --data_conclusao
          NULL, --nota_aval_cli
          NULL, --data_aval_cli
          NULL --coment_aval_cli
     FROM ordem_servico
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- copia metadados
  --
  INSERT INTO os_atributo_valor
   (ordem_servico_id,
    metadado_id,
    valor_atributo)
   SELECT v_ordem_servico_id,
          metadado_id,
          valor_atributo
     FROM os_atributo_valor
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- copia todo list
  --
  INSERT INTO os_afazer
   (os_afazer_id,
    ordem_servico_id,
    usuario_resp_id,
    descricao,
    data,
    flag_feito,
    ordem)
   SELECT seq_os_afazer.nextval,
          v_ordem_servico_id,
          usuario_resp_id,
          descricao,
          data,
          'N',
          ordem
     FROM os_afazer
    WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- copia entregáveis
  --
  FOR r_os_tp IN (SELECT jo.job_tipo_produto_id,
                         jo.tipo_produto_id,
                         jo.complemento,
                         os.descricao,
                         os.obs,
                         os.quantidade
                    FROM job_tipo_produto jo
                   INNER JOIN os_tipo_produto os
                      ON os.job_tipo_produto_id = jo.job_tipo_produto_id
                   WHERE os.ordem_servico_id = p_ordem_servico_id)
  LOOP
   SELECT COUNT(*)
     INTO v_qt
     FROM job_tipo_produto
    WHERE job_id = p_job_id
      AND tipo_produto_id = r_os_tp.tipo_produto_id
         --ALCBO_020724
      AND (TRIM(complemento) IS NULL OR TRIM(complemento) = TRIM(r_os_tp.complemento));
   --AND complemento like r_os_tp.complemento;
   --
   IF v_qt = 0
   THEN
    SELECT seq_job_tipo_produto.nextval
      INTO v_job_tipo_produto_id
      FROM dual;
    --
    INSERT INTO job_tipo_produto
     (job_tipo_produto_id,
      job_id,
      tipo_produto_id,
      complemento)
    VALUES
     (v_job_tipo_produto_id,
      p_job_id,
      r_os_tp.tipo_produto_id,
      r_os_tp.complemento);
   ELSE
    SELECT MAX(job_tipo_produto_id)
      INTO v_job_tipo_produto_id
      FROM job_tipo_produto
     WHERE job_id = p_job_id
       AND tipo_produto_id = r_os_tp.tipo_produto_id
          --ALCBO_020724
       AND (TRIM(complemento) IS NULL OR TRIM(complemento) = TRIM(r_os_tp.complemento));
    --AND complemento = r_os_tp.complemento;
   END IF;
   --
   INSERT INTO os_tipo_produto
    (ordem_servico_id,
     job_tipo_produto_id,
     descricao,
     num_refacao,
     flag_bloqueado,
     data_entrada,
     obs,
     quantidade)
   VALUES
    (v_ordem_servico_id,
     v_job_tipo_produto_id,
     r_os_tp.descricao,
     0,
     'N',
     SYSDATE,
     r_os_tp.obs,
     r_os_tp.quantidade);
   --
   INSERT INTO os_tp_atributo_valor
    (ordem_servico_id,
     job_tipo_produto_id,
     metadado_id,
     valor_atributo)
    SELECT v_ordem_servico_id,
           v_job_tipo_produto_id,
           metadado_id,
           valor_atributo
      FROM os_tp_atributo_valor
     WHERE ordem_servico_id = p_ordem_servico_id
       AND job_tipo_produto_id = r_os_tp.job_tipo_produto_id;
  END LOOP;
  --
  -- copia arquivos de referência
  --
  INSERT INTO arquivo_os
   (arquivo_id,
    ordem_servico_id,
    tipo_arq_os,
    flag_thumb,
    chave_thumb,
    num_refacao)
   SELECT arquivo_id,
          v_ordem_servico_id,
          tipo_arq_os,
          flag_thumb,
          chave_thumb,
          0
     FROM arquivo_os
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_arq_os = 'REFER';
  --
  -- insere usuário solicitante
  --
  INSERT INTO os_usuario
   (ordem_servico_id,
    usuario_id,
    tipo_ender,
    flag_lido,
    horas_planej,
    sequencia)
  VALUES
   (v_ordem_servico_id,
    p_usuario_sessao_id,
    'SOL',
    'S',
    NULL,
    1);
  --
  -- tratamento de cronograma
  --
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
  -- cria a atividade de OS
  cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       v_cronograma_id,
                                       'ORDEM_SERVICO',
                                       'IME',
                                       v_item_crono_id,
                                       p_erro_cod,
                                       p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- vincula a atividade de OS a OS criada
  UPDATE item_crono
     SET objeto_id = v_ordem_servico_id,
         nome      = nvl(v_descricao_os, 'Workflow ' || numero_formatar(v_ordem_servico_id))
   WHERE item_crono_id = v_item_crono_id;
  --
  -- copia links
  --
  INSERT INTO os_link
   (os_link_id,
    ordem_servico_id,
    usuario_id,
    data_entrada,
    url,
    descricao,
    tipo_link,
    num_refacao)
   SELECT seq_os_link.nextval,
          v_ordem_servico_id,
          p_usuario_sessao_id,
          SYSDATE,
          url,
          descricao,
          'REFER',
          0
     FROM os_link
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_link = 'REFER';
  --
  -- criar evento de inclusão do workflow duplicado
  --
  v_comentario := 'Duplicado a partir do Workflow: ' || v_job_numero || '-' || v_num_os_old;
  --
  INSERT INTO os_evento
   (os_evento_id,
    ordem_servico_id,
    usuario_id,
    data_evento,
    cod_acao,
    comentario,
    num_refacao,
    status_de,
    status_para,
    flag_estim)
  VALUES
   (seq_os_evento.nextval,
    v_ordem_servico_id,
    p_usuario_sessao_id,
    SYSDATE,
    'CRIAR',
    v_comentario,
    0,
    NULL,
    'PREP',
    'N');
  --
  -- registra o solicitante no historico de enderecamentos
  --
  historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                     'OS',
                                     v_ordem_servico_id,
                                     'SOL',
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --  
  v_numero_os_char := numero_formatar(v_ordem_servico_id);
  --
  -- endereca automaticamente o solicitante ao job com co-ender e sem pula notificação
  --
  job_pkg.enderecar_usuario(p_usuario_sessao_id,
                            'N',
                            'S',
                            'N',
                            p_empresa_id,
                            p_job_id,
                            p_usuario_sessao_id,
                            'Criou Workflow ' || v_numero_os_char || ' de ' || v_tipo_os_desc,
                            'duplicado do Workflow: ' || v_job_numero || '-' || v_num_os_old,
                            p_erro_cod,
                            p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  --retorna id do worklfow criado para navegação
  p_os_nova_id := v_ordem_servico_id;
  --retorna número do workflow criado para mensagem de confirmação
  p_os_nova_numero := numero_formatar(v_ordem_servico_id);
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
 END duplicar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 18/02/2013
  -- DESCRICAO: Subrotina que gera o xml da ordem de servico para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/04/2022  Novas tags para OS_LINK
  -- Silvia            14/10/2022  Acrescentado arquivos de refacao(REFA)
  -- Ana Luiza         16/12/2024  Acrescentado atributo flag_tem_produto
  ------------------------------------------------------------------------------------------
 (
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_data_distribuicao   DATE;
  v_desc_milestone      VARCHAR2(200);
  v_milestone_id        ordem_servico.milestone_id%TYPE;
  v_tipo_financeiro_id  ordem_servico.tipo_financeiro_id%TYPE;
  v_job_id              ordem_servico.job_id%TYPE;
  v_texto_os            ordem_servico.texto_os%TYPE;
  v_custo_estim         ordem_servico.custo_estim%TYPE;
  v_dias_estim          ordem_servico.dias_estim%TYPE;
  v_obs_estim           ordem_servico.obs_estim%TYPE;
  v_num_refacao         ordem_servico.qtd_refacao%TYPE;
  v_briefing_id         briefing.briefing_id%TYPE;
  v_empresa_id          job.empresa_id%TYPE;
  v_job_tipo_produto_id job_tipo_produto.job_tipo_produto_id%TYPE;
  v_tipo_financeiro     tipo_financeiro.nome%TYPE;
  v_flag_tem_tipo_finan tipo_os.flag_tem_tipo_finan%TYPE;
  v_flag_tem_produto    tipo_os.flag_tem_produto%TYPE; --ALCBO_161224
  v_xml                 xmltype;
  v_xml_info_geral      xmltype;
  v_xml_equipe          xmltype;
  v_xml_corpo           xmltype;
  v_xml_item            xmltype;
  v_xml_itens           xmltype;
  v_xml_arq_refer       xmltype;
  v_xml_arq_exec        xmltype;
  v_xml_arq_refa        xmltype;
  v_xml_link            xmltype;
  v_xml_est_horas       xmltype;
  v_xml_aux             xmltype;
  v_xml_aux2            xmltype;
  v_xml_doc             VARCHAR2(100);
  v_tipo_ender          os_usuario.tipo_ender%TYPE;
  --
  CURSOR c_usu IS
   SELECT pe.apelido AS exec_apelido,
          pe.nome    AS exec_nome
     FROM os_usuario os,
          pessoa     pe
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.usuario_id = pe.usuario_id
      AND os.tipo_ender = v_tipo_ender
    ORDER BY upper(pe.apelido);
  --
  CURSOR c_atr IS
   SELECT ab.nome           AS nome,
          os.valor_atributo AS valor,
          ab.instrucoes     AS instrucoes
     FROM os_atributo_valor os,
          metadado          ab
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.metadado_id = ab.metadado_id
    ORDER BY upper(ab.nome);
  --
  CURSOR c_it IS
   SELECT jt.job_tipo_produto_id,
          tp.nome,
          jt.complemento,
          os.descricao,
          numero_mostrar(os.quantidade, 2, 'N') quantidade
     FROM os_tipo_produto  os,
          job_tipo_produto jt,
          tipo_produto     tp
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.job_tipo_produto_id = jt.job_tipo_produto_id
      AND jt.tipo_produto_id = tp.tipo_produto_id
    ORDER BY upper(tp.nome),
             upper(jt.complemento);
  --
  CURSOR c_atr2 IS
   SELECT ab.nome           AS nome,
          os.valor_atributo AS valor,
          ab.instrucoes     AS instrucoes
     FROM os_tp_atributo_valor os,
          metadado             ab
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.job_tipo_produto_id = v_job_tipo_produto_id
      AND os.metadado_id = ab.metadado_id
    ORDER BY upper(ab.nome);
  --
  CURSOR c_est IS
   SELECT ar.area_id,
          nvl(ar.nome, 'ND') AS nome_area,
          to_char(ordem_servico_pkg.horas_retornar(p_ordem_servico_id, NULL, NULL, 'PLANEJ')) AS horas_planej,
          numero_mostrar(ordem_servico_pkg.horas_retornar(p_ordem_servico_id, NULL, NULL, 'GASTA'),
                         2,
                         'N') AS horas_gastas
     FROM area ar,
          usuario us,
          (SELECT oh.usuario_id
             FROM os_horas oh
            WHERE oh.ordem_servico_id = p_ordem_servico_id
           UNION
           SELECT ad.usuario_id
             FROM apontam_hora ah,
                  apontam_data ad
            WHERE ah.ordem_servico_id = p_ordem_servico_id
              AND ah.apontam_data_id = ad.apontam_data_id) vp
    WHERE vp.usuario_id = us.usuario_id
      AND us.area_id = ar.area_id(+)
    ORDER BY upper(nome_area);
  --
  CURSOR c_arq1 IS
   SELECT ar.arquivo_id,
          ar.volume_id,
          ar.nome_original,
          ar.nome_fisico
     FROM arquivo_os os,
          arquivo    ar
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.arquivo_id = ar.arquivo_id
      AND os.tipo_arq_os = 'REFER'
      AND flag_thumb = 'N'
    ORDER BY os.arquivo_id;
  --
  CURSOR c_arq2 IS
   SELECT ar.arquivo_id,
          ar.volume_id,
          ar.nome_original,
          ar.nome_fisico
     FROM arquivo_os os,
          arquivo    ar
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.arquivo_id = ar.arquivo_id
      AND os.tipo_arq_os = 'EXEC'
      AND flag_thumb = 'N'
    ORDER BY os.arquivo_id;
  --
  CURSOR c_arq3 IS
   SELECT ar.arquivo_id,
          ar.volume_id,
          ar.nome_original,
          ar.nome_fisico
     FROM arquivo_os os,
          arquivo    ar
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.arquivo_id = ar.arquivo_id
      AND os.tipo_arq_os = 'REFA'
      AND flag_thumb = 'N'
    ORDER BY os.arquivo_id;
  --
  CURSOR c_lk1 IS
   SELECT os.os_link_id,
          os.url,
          os.descricao,
          pe.apelido AS usuario,
          data_hora_mostrar(os.data_entrada) AS data_link,
          decode(os.tipo_link,
                 'EXEC',
                 'Entrega',
                 'EXEC_REP',
                 'Entrega',
                 'EXEC_APR',
                 'Entrega',
                 'REFER',
                 'Referência',
                 'APROVCLI',
                 'Aprovação do Cliente',
                 'Não definido') AS tipo_link
     FROM os_link os,
          pessoa  pe
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.usuario_id = pe.usuario_id(+)
    ORDER BY os.os_link_id;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --v_xml_doc := '<?xml version="1.0" ?>';
  --
  SELECT os.milestone_id,
         os.tipo_financeiro_id,
         os.job_id,
         os.texto_os,
         os.custo_estim,
         os.dias_estim,
         os.obs_estim,
         os.qtd_refacao,
         jo.empresa_id,
         ti.flag_tem_tipo_finan,
         ti.flag_tem_produto
    INTO v_milestone_id,
         v_tipo_financeiro_id,
         v_job_id,
         v_texto_os,
         v_custo_estim,
         v_dias_estim,
         v_obs_estim,
         v_num_refacao,
         v_empresa_id,
         v_flag_tem_tipo_finan,
         v_flag_tem_produto
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  v_data_distribuicao := ordem_servico_pkg.data_retornar(p_ordem_servico_id, 'DIST');
  --
  IF v_milestone_id IS NOT NULL
  THEN
   SELECT data_mostrar(data_milestone) || ' ' || hora_ini || ' - ' || descricao
     INTO v_desc_milestone
     FROM milestone
    WHERE milestone_id = v_milestone_id;
  END IF;
  --
  IF v_tipo_financeiro_id IS NOT NULL
  THEN
   SELECT nome
     INTO v_tipo_financeiro
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = v_tipo_financeiro_id;
  END IF;
  --
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = v_job_id;
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("informacoes_gerais",
                           xmlelement("numero", os.numero),
                           xmlelement("refacao", os.qtd_refacao),
                           xmlelement("status", util_pkg.desc_retornar('status_os', os.status)),
                           xmlelement("entrada", data_hora_mostrar(os.data_entrada)),
                           xmlelement("distribuicao", data_hora_mostrar(v_data_distribuicao)),
                           xmlelement("prazo_solicitado", data_hora_mostrar(os.data_solicitada)),
                           xmlelement("prazo_interno", data_hora_mostrar(os.data_interna)),
                           xmlelement("tipo_demanda", util_pkg.desc_retornar('demanda', os.demanda)),
                           xmlelement("demandar_em", data_mostrar(os.data_demanda)),
                           xmlelement("apresentar_em", v_desc_milestone),
                           xmlelement("fase_job", NULL),
                           xmlelement("tamanho", os.tamanho),
                           xmlelement("custo_estim", numero_mostrar(v_custo_estim, 2, 'N')),
                           xmlelement("prazo_estim", v_dias_estim),
                           xmlelement("obs_estim", v_obs_estim)))
    INTO v_xml_info_geral
    FROM ordem_servico os,
         milestone     mi
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.milestone_id = mi.milestone_id(+);
  --
  ------------------------------------------------------------
  -- monta equipe
  ------------------------------------------------------------
  v_xml_equipe := NULL;
  v_xml_aux2   := NULL;
  --
  -- seleciona os solicitantes
  v_tipo_ender := 'SOL';
  --
  FOR r_usu IN c_usu
  LOOP
   SELECT xmlagg(xmlelement("solicitante",
                            xmlelement("apelido", r_usu.exec_apelido),
                            xmlelement("nome", r_usu.exec_nome)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_equipe, v_xml_aux2)
     INTO v_xml_equipe
     FROM dual;
  END LOOP;
  --
  -- seleciona os distribuidores
  v_tipo_ender := 'DIS';
  --
  FOR r_usu IN c_usu
  LOOP
   SELECT xmlagg(xmlelement("distribuidor",
                            xmlelement("apelido", r_usu.exec_apelido),
                            xmlelement("nome", r_usu.exec_nome)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_equipe, v_xml_aux2)
     INTO v_xml_equipe
     FROM dual;
  END LOOP;
  --
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  -- seleciona os executores
  v_tipo_ender := 'EXE';
  --
  FOR r_usu IN c_usu
  LOOP
   SELECT xmlagg(xmlelement("executor",
                            xmlelement("apelido", r_usu.exec_apelido),
                            xmlelement("nome", r_usu.exec_nome)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("executores", v_xml_aux))
    INTO v_xml_aux
    FROM dual;
  --
  SELECT xmlconcat(v_xml_equipe, v_xml_aux)
    INTO v_xml_equipe
    FROM dual;
  --
  SELECT xmlagg(xmlelement("equipe", v_xml_equipe))
    INTO v_xml_equipe
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta o corpo
  ------------------------------------------------------------
  IF v_flag_tem_tipo_finan = 'S' AND v_tipo_financeiro IS NOT NULL
  THEN
   --  XMLElement("texto",'<![CDATA[' || v_texto_os || ']]>'),
   SELECT xmlconcat(xmlelement("tipo_financeiro", v_tipo_financeiro),
                    xmlelement("texto", v_texto_os),
                    xmlelement("briefing_id", TRIM(to_char(v_briefing_id))),
                    --ALCBO_161224
                    CASE
                     WHEN v_flag_tem_produto IS NOT NULL THEN
                      xmlelement("produto", v_flag_tem_produto)
                     ELSE
                      NULL
                    END)
     INTO v_xml_corpo
     FROM dual;
  ELSE
   SELECT xmlconcat(xmlelement("texto", v_texto_os),
                    xmlelement("briefing_id", TRIM(to_char(v_briefing_id))),
                    --ALCBO_161224
                    CASE
                     WHEN v_flag_tem_produto IS NOT NULL THEN
                      xmlelement("produto", v_flag_tem_produto)
                     ELSE
                      NULL
                    END)
     INTO v_xml_corpo
     FROM dual;
  END IF;
  --
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_atr IN c_atr
  LOOP
   SELECT xmlagg(xmlelement("metadado",
                            xmlelement("nome", r_atr.nome),
                            xmlelement("valor", r_atr.valor),
                            xmlelement("instrucoes", r_atr.instrucoes)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("metadados", v_xml_aux))
    INTO v_xml_aux
    FROM dual;
  --
  SELECT xmlconcat(v_xml_corpo, v_xml_aux)
    INTO v_xml_corpo
    FROM dual;
  --
  SELECT xmlagg(xmlelement("corpo", v_xml_corpo))
    INTO v_xml_corpo
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta os itens
  ------------------------------------------------------------
  v_xml_itens := NULL;
  --
  FOR r_it IN c_it
  LOOP
   v_xml_aux  := NULL;
   v_xml_aux2 := NULL;
   v_xml_item := NULL;
   --
   v_job_tipo_produto_id := r_it.job_tipo_produto_id;
   --
   SELECT xmlconcat(xmlelement("tipo_produto", r_it.nome),
                    xmlelement("complemento", r_it.complemento),
                    xmlelement("descricao", r_it.descricao),
                    xmlelement("quantidade", r_it.quantidade))
     INTO v_xml_item
     FROM dual;
   --
   FOR r_atr2 IN c_atr2
   LOOP
    SELECT xmlagg(xmlelement("metadado",
                             xmlelement("nome", r_atr2.nome),
                             xmlelement("valor", r_atr2.valor),
                             xmlelement("instrucoes", r_atr2.instrucoes)))
      INTO v_xml_aux2
      FROM dual;
    --
    SELECT xmlconcat(v_xml_aux, v_xml_aux2)
      INTO v_xml_aux
      FROM dual;
   END LOOP;
   --
   SELECT xmlagg(xmlelement("metadados", v_xml_aux))
     INTO v_xml_aux
     FROM dual;
   --
   SELECT xmlconcat(v_xml_item, v_xml_aux)
     INTO v_xml_item
     FROM dual;
   --
   SELECT xmlagg(xmlelement("item", v_xml_item))
     INTO v_xml_item
     FROM dual;
   --
   SELECT xmlconcat(v_xml_itens, v_xml_item)
     INTO v_xml_itens
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("itens", v_xml_itens))
    INTO v_xml_itens
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta estimativas de horas
  ------------------------------------------------------------
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_est IN c_est
  LOOP
   SELECT xmlagg(xmlelement("estimativa",
                            xmlelement("area", r_est.nome_area),
                            xmlelement("horas_planejadas", r_est.horas_planej),
                            xmlelement("horas_gastas", r_est.horas_gastas)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("estimativas", v_xml_aux))
    INTO v_xml_est_horas
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta arquivos de referencia
  ------------------------------------------------------------
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_arq1 IN c_arq1
  LOOP
   SELECT xmlagg(xmlelement("arquivo_referencia",
                            xmlelement("arquivo_id", r_arq1.arquivo_id),
                            xmlelement("nome_original", r_arq1.nome_original)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("arquivos_referencia", v_xml_aux))
    INTO v_xml_arq_refer
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta arquivos de execucao
  ------------------------------------------------------------
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_arq2 IN c_arq2
  LOOP
   SELECT xmlagg(xmlelement("arquivo_execucao",
                            xmlelement("arquivo_id", r_arq2.arquivo_id),
                            xmlelement("nome_original", r_arq2.nome_original)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("arquivos_execucao", v_xml_aux))
    INTO v_xml_arq_exec
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta arquivos de refacao
  ------------------------------------------------------------
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_arq3 IN c_arq3
  LOOP
   SELECT xmlagg(xmlelement("arquivo_refacao",
                            xmlelement("arquivo_id", r_arq3.arquivo_id),
                            xmlelement("nome_original", r_arq3.nome_original)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("arquivos_refacao", v_xml_aux))
    INTO v_xml_arq_refa
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta lnks
  ------------------------------------------------------------
  v_xml_aux  := NULL;
  v_xml_aux2 := NULL;
  --
  FOR r_lk1 IN c_lk1
  LOOP
   SELECT xmlagg(xmlelement("link",
                            xmlelement("tipo", r_lk1.tipo_link),
                            xmlelement("url", r_lk1.url),
                            xmlelement("descricao", r_lk1.descricao),
                            xmlelement("usuario", r_lk1.usuario),
                            xmlelement("data", r_lk1.data_link)))
     INTO v_xml_aux2
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux, v_xml_aux2)
     INTO v_xml_aux
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("links", v_xml_aux))
    INTO v_xml_link
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo na tag ordem_servico
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("ordem_servico",
                           v_xml_info_geral,
                           v_xml_equipe,
                           v_xml_corpo,
                           v_xml_itens,
                           v_xml_arq_refer,
                           v_xml_arq_exec,
                           v_xml_arq_refa,
                           v_xml_link,
                           v_xml_est_horas))
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
 FUNCTION atuacao_usuario_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 13/02/2019
  -- DESCRICAO: verifica a atuacao do usuario na OS (usado na negociacao do prazo)
  --  Retorna:
  --   DIST - usuario tem privilegio de distribuidor
  --   EXEC - usuario tem privilegio de executor
  --   SOLI - usuario tem privilegio de alterar e atua como solicitante
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/10/2019  Teste de solicitante primeiro.
  ------------------------------------------------------------------------------------------
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt         INTEGER;
  v_retorno    VARCHAR2(20);
  v_exception  EXCEPTION;
  v_job_id     job.job_id%TYPE;
  v_tipo_os_id tipo_os.tipo_os_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  ------------------------------------------------------------
  -- verifica privilegios
  ------------------------------------------------------------
  SELECT tipo_os_id,
         job_id
    INTO v_tipo_os_id,
         v_job_id
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_usuario
   WHERE ordem_servico_id = p_ordem_servico_id
     AND usuario_id = p_usuario_id
     AND tipo_ender = 'SOL';
  --
  IF v_qt > 0 AND
     usuario_pkg.priv_verificar(p_usuario_id, 'OS_C', v_job_id, v_tipo_os_id, p_empresa_id) = 1
  THEN
   v_retorno := 'SOLI';
  ELSIF usuario_pkg.priv_verificar(p_usuario_id, 'OS_DI', v_job_id, v_tipo_os_id, p_empresa_id) = 1
  THEN
   v_retorno := 'DIST';
  ELSIF usuario_pkg.priv_verificar(p_usuario_id, 'OS_EX', v_job_id, v_tipo_os_id, p_empresa_id) = 1
  THEN
   v_retorno := 'EXEC';
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END atuacao_usuario_retornar;
 --
 --
 FUNCTION enderecados_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 01/12/2004
  -- DESCRICAO: retorna os apelidos dos usuarios enderecados na ordem de servico
  --  (o retorno e' feito em forma de vetor, separado por virgulas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/05/2014  tag para usuarios inativos.
  -- Silvia            14/07/2014  novo parametro para ligar/desligar tag de inativos.
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id   IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_ender         IN VARCHAR2,
  p_flag_marca_inativo IN VARCHAR2
 ) RETURN VARCHAR2 AS
  v_usuarios VARCHAR2(2000);
  v_qt       INTEGER;
  --
  CURSOR c_usu IS
   SELECT /*+ ORDERED */
    pe.apelido,
    us.flag_ativo
     FROM os_usuario os,
          usuario    us,
          pessoa     pe
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.tipo_ender = p_tipo_ender
      AND os.usuario_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
    ORDER BY upper(pe.apelido);
  --
 BEGIN
  v_usuarios := NULL;
  --
  FOR r_usu IN c_usu
  LOOP
   IF r_usu.flag_ativo = 'N' AND p_flag_marca_inativo = 'S'
   THEN
    v_usuarios := v_usuarios || ', <span class="texto-inativo">' || r_usu.apelido || '</span>';
   ELSE
    v_usuarios := v_usuarios || ', ' || r_usu.apelido;
   END IF;
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
 END enderecados_retornar;
 --
 --
 FUNCTION com_usuarios_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 01/09/2017
  -- DESCRICAO: retorna os apelidos dos usuarios que estao com atividades pendentes na ordem
  --    de servico (a OS esta aguardando alguma acao deles).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_usuarios           VARCHAR2(30000);
  v_qt                 INTEGER;
  v_saida              EXCEPTION;
  v_empresa_id         job.empresa_id%TYPE;
  v_job_id             job.job_id%TYPE;
  v_status_job         job.status%TYPE;
  v_tipo_os_id         ordem_servico.tipo_os_id%TYPE;
  v_status_os          ordem_servico.status%TYPE;
  v_flag_faixa_aprov   ordem_servico.flag_faixa_aprov%TYPE;
  v_flag_com_estim     ordem_servico.flag_com_estim%TYPE;
  v_os_estim_id        ordem_servico.os_estim_id%TYPE;
  v_flag_aprov_est_seq ordem_servico.flag_aprov_est_seq%TYPE;
  v_flag_aprov_exe_seq ordem_servico.flag_aprov_exe_seq%TYPE;
  v_status_estim       os_estim.status%TYPE;
  v_cod_priv1          privilegio.codigo%TYPE;
  v_cod_priv2          privilegio.codigo%TYPE;
  v_tipo_fluxo         VARCHAR2(10);
  v_seq_aprov          NUMBER(5);
  v_seq_aprov_maior    NUMBER(5);
  --
  /*
  CURSOR c_us1 IS
    SELECT pe.apelido
      FROM usuario us,
           pessoa pe
     WHERE us.flag_ativo = 'S'
       AND us.flag_admin = 'N'
       AND us.usuario_id = pe.usuario_id
       AND USUARIO_PKG.PRIV_VERIFICAR(us.usuario_id,v_cod_priv1,v_job_id,v_tipo_os_id,v_empresa_id) = 1
     UNION
    SELECT pe.apelido
      FROM usuario us,
           pessoa pe
     WHERE us.flag_ativo = 'S'
       AND us.flag_admin = 'N'
       AND us.usuario_id = pe.usuario_id
       AND USUARIO_PKG.PRIV_VERIFICAR(us.usuario_id,v_cod_priv2,v_job_id,v_tipo_os_id,v_empresa_id) = 1
     ORDER BY 1;*/
  --
  -- usuario/papel com priv em OS
  CURSOR c_us IS
   SELECT pe.apelido,
          pa.nome AS papel
     FROM usuario_papel up,
          usuario       us,
          pessoa        pe,
          papel         pa
    WHERE up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND us.usuario_id = pe.usuario_id
      AND up.papel_id = pa.papel_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 v_cod_priv1,
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
   UNION
   SELECT pe.apelido,
          pa.nome AS papel
     FROM usuario_papel up,
          usuario       us,
          pessoa        pe,
          papel         pa
    WHERE up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND us.usuario_id = pe.usuario_id
      AND up.papel_id = pa.papel_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 v_cod_priv2,
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
    ORDER BY 1,
             2;
  --
  -- fluxo nao instanciado. Usuarios que podem iniciar o fluxo.
  CURSOR c_fa IS
   SELECT pe.apelido
     FROM usuario us,
          pessoa  pe
    WHERE us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND us.usuario_id = pe.usuario_id
      AND ordem_servico_pkg.faixa_aprov_id_retornar(us.usuario_id,
                                                    v_empresa_id,
                                                    p_ordem_servico_id,
                                                    v_tipo_fluxo) > 0
    ORDER BY 1;
  --
  -- fluxo sequencial instanciado. Usuario/papel da vez.
  CURSOR c_fs IS
   SELECT pe.apelido,
          pa.nome AS papel
     FROM usuario_papel up,
          usuario       us,
          papel         pa,
          pessoa        pe
    WHERE up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND up.papel_id = pa.papel_id
      AND us.usuario_id = pe.usuario_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 'OS_AP',
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
      AND EXISTS (SELECT 1
             FROM os_fluxo_aprov fa
            WHERE fa.ordem_servico_id = p_ordem_servico_id
              AND fa.tipo_aprov = v_tipo_fluxo
              AND fa.papel_id = up.papel_id
              AND fa.seq_aprov = v_seq_aprov
              AND fa.data_aprov IS NULL
              AND fa.flag_habilitado = 'S')
    ORDER BY 1,
             2;
  --
  -- fluxo nao sequencial instanciado. Usuario/papel de sequencias nao aprovadas.
  CURSOR c_ns IS
   SELECT pe.apelido,
          pa.nome AS papel
     FROM usuario_papel  up,
          usuario        us,
          os_fluxo_aprov fa,
          papel          pa,
          pessoa         pe
    WHERE up.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND up.papel_id = pa.papel_id
      AND us.usuario_id = pe.usuario_id
      AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                 'OS_AP',
                                                 up.papel_id,
                                                 p_ordem_servico_id) = 1
      AND fa.ordem_servico_id = p_ordem_servico_id
      AND fa.tipo_aprov = v_tipo_fluxo
      AND fa.papel_id = up.papel_id
      AND fa.data_aprov IS NULL
      AND fa.flag_habilitado = 'S'
      AND NOT EXISTS (SELECT 1
             FROM os_fluxo_aprov f2
            WHERE f2.ordem_servico_id = fa.ordem_servico_id
              AND f2.tipo_aprov = fa.tipo_aprov
              AND f2.seq_aprov = fa.seq_aprov
              AND f2.data_aprov IS NOT NULL)
    ORDER BY 1,
             2;
  --
 BEGIN
  v_usuarios := NULL;
  --
  SELECT os.tipo_os_id,
         jo.job_id,
         jo.status,
         jo.empresa_id,
         os.status,
         os.flag_faixa_aprov,
         os.flag_com_estim,
         os.os_estim_id,
         oe.status,
         os.flag_aprov_est_seq,
         os.flag_aprov_exe_seq
    INTO v_tipo_os_id,
         v_job_id,
         v_status_job,
         v_empresa_id,
         v_status_os,
         v_flag_faixa_aprov,
         v_flag_com_estim,
         v_os_estim_id,
         v_status_estim,
         v_flag_aprov_est_seq,
         v_flag_aprov_exe_seq
    FROM ordem_servico os,
         job           jo,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  v_tipo_fluxo := 'EXE';
  IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
  THEN
   -- OS em processo de estimativa
   v_tipo_fluxo := 'EST';
  END IF;
  --
  ------------------------------------------------------------
  -- OS que nao esta com ninguem
  ------------------------------------------------------------
  IF v_status_os IN ('CONC', 'CANC', 'DESC')
  THEN
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- OS que esta com quem tem privilegio
  ------------------------------------------------------------
  IF v_status_os = 'PREP'
  THEN
   v_cod_priv1 := 'OS_C';
   v_cod_priv2 := 'OS_EN';
  ELSIF v_status_os = 'DIST'
  THEN
   v_cod_priv1 := 'OS_DI';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'ACEI'
  THEN
   v_cod_priv1 := 'OS_EX';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'EMEX'
  THEN
   v_cod_priv1 := 'OS_EX';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'AVAL'
  THEN
   v_cod_priv1 := 'OS_DI';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'EXEC' AND v_tipo_fluxo = 'EXE'
  THEN
   v_cod_priv1 := 'OS_C';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'EXEC' AND v_tipo_fluxo = 'EST'
  THEN
   v_cod_priv1 := 'OS_AP';
   v_cod_priv2 := 'OS_C';
  ELSIF v_status_os = 'STAN'
  THEN
   v_cod_priv1 := 'OS_C';
   v_cod_priv2 := NULL;
  ELSIF v_status_os = 'EMAP'
  THEN
   v_cod_priv1 := 'OS_AP';
   v_cod_priv2 := NULL;
  END IF;
  --
  IF v_status_os <> 'EMAP' OR (v_status_os = 'EMAP' AND v_flag_faixa_aprov = 'N')
  THEN
   FOR r_us IN c_us
   LOOP
    --v_usuarios := v_usuarios || ', ' || r_us.apelido || ' (' || r_us.papel || ')';
    --v_usuarios := v_usuarios || ', ' || r_us.apelido;
    IF nvl(length(v_usuarios), 0) <= 3800
    THEN
     v_usuarios := v_usuarios || ', ' || r_us.apelido;
    END IF;
   END LOOP;
   --
   -- retira a primeira virgula
   v_usuarios := substr(v_usuarios, 3);
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- OS que esta no fluxo de aprovacao
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_aprov = v_tipo_fluxo;
  --
  IF v_qt = 0
  THEN
   ----------------------------------
   -- fluxo nao instanciado.
   ----------------------------------
   FOR r_fa IN c_fa
   LOOP
    IF nvl(length(v_usuarios), 0) <= 3800
    THEN
     v_usuarios := v_usuarios || ', ' || r_fa.apelido;
    END IF;
   END LOOP;
   --
   -- retira a primeira virgula
   v_usuarios := substr(v_usuarios, 3);
   RAISE v_saida;
  ELSE
   ----------------------------------
   -- fluxo instanciado.
   ----------------------------------
   IF (v_tipo_fluxo = 'EST' AND v_flag_aprov_est_seq = 'S') OR
      (v_tipo_fluxo = 'EXE' AND v_flag_aprov_exe_seq = 'S')
   THEN
    -- aprovacao deve obedecer a sequencia.
    -- pega a maior sequencia aprovada
    SELECT nvl(MAX(seq_aprov), 0)
      INTO v_seq_aprov_maior
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_aprov = v_tipo_fluxo
       AND data_aprov IS NOT NULL;
    --
    -- pega a proxima sequencia com aprovacao pendente
    SELECT nvl(MIN(seq_aprov), 0)
      INTO v_seq_aprov
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND data_aprov IS NULL
       AND flag_habilitado = 'S'
       AND tipo_aprov = v_tipo_fluxo
       AND seq_aprov > v_seq_aprov_maior;
    --
    FOR r_fs IN c_fs
    LOOP
     --v_usuarios := v_usuarios || ', ' || r_fs.apelido || ' (' || r_fs.papel || ')';
     IF nvl(length(v_usuarios), 0) <= 3800
     THEN
      v_usuarios := v_usuarios || ', ' || r_fs.apelido;
     END IF;
    END LOOP;
    --
    -- retira a primeira virgula
    v_usuarios := substr(v_usuarios, 3);
    RAISE v_saida;
   ELSE
    -- aprovacao nao precisa obedecer a sequencia.
    FOR r_ns IN c_ns
    LOOP
     --v_usuarios := v_usuarios || ', ' || r_ns.apelido || ' (' || r_ns.papel || ')';
     IF nvl(length(v_usuarios), 0) <= 3800
     THEN
      v_usuarios := v_usuarios || ', ' || r_ns.apelido;
     END IF;
    END LOOP;
    --
    -- retira a primeira virgula
    v_usuarios := substr(v_usuarios, 3);
    RAISE v_saida;
   END IF;
  END IF;
  --
  RETURN v_usuarios;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_usuarios;
  WHEN OTHERS THEN
   v_usuarios := 'ERRO';
   RETURN v_usuarios;
 END com_usuarios_retornar;
 --
 --
 FUNCTION desc_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/12/2010
  -- DESCRICAO: retorna a descricao de um determinado evento de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_cod_acao    IN os_transicao.cod_acao%TYPE,
  p_status_de   IN os_transicao.status_de%TYPE,
  p_status_para IN os_transicao.status_para%TYPE
 ) RETURN VARCHAR2 AS
  v_descricao os_transicao.descricao%TYPE;
  v_qt        INTEGER;
  --
 BEGIN
  v_descricao := NULL;
  --
  IF p_cod_acao = 'CRIAR'
  THEN
   v_descricao := 'Criou Workflow';
  ELSE
   SELECT nvl(MAX(descricao), '-')
     INTO v_descricao
     FROM os_transicao
    WHERE cod_acao = p_cod_acao
      AND status_de = p_status_de
      AND status_para = p_status_para;
  END IF;
  --
  RETURN v_descricao;
 EXCEPTION
  WHEN OTHERS THEN
   v_descricao := 'ERRO';
   RETURN v_descricao;
 END desc_evento_retornar;
 --
 --
 FUNCTION dias_depend_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 11/08/2016
  -- DESCRICAO: retorna o numero de dias (prazo) de uma determinada OS, somado aos
  -- prazos de eventuais OS das quais essa OS depende (via cronograma), desde
  -- que essas OS tb pertencam a mesma estimativa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN NUMBER AS
  v_qt                   INTEGER;
  v_os_estim_id          ordem_servico.os_estim_id%TYPE;
  v_dias_estim           ordem_servico.dias_estim%TYPE;
  v_dias_estim_aux       ordem_servico.dias_estim%TYPE;
  v_ordem_servico_aux_id ordem_servico.ordem_servico_id%TYPE;
  v_empresa_id           empresa.empresa_id%TYPE;
  v_nome_ativ_pre        VARCHAR2(500);
  v_cod_objeto_pre       VARCHAR2(100);
  v_nome_objeto_pre      VARCHAR2(500);
  v_status_objeto_pre    VARCHAR2(100);
  v_objeto_pre_id        NUMBER;
  v_data_fim_pre         VARCHAR2(100);
  v_erro_cod             VARCHAR2(20);
  v_erro_msg             VARCHAR2(200);
  v_exception            EXCEPTION;
  --
 BEGIN
  SELECT os.os_estim_id,
         nvl(os.dias_estim, 0),
         jo.empresa_id
    INTO v_os_estim_id,
         v_dias_estim,
         v_empresa_id
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  v_ordem_servico_aux_id := p_ordem_servico_id;
  --
  WHILE nvl(v_ordem_servico_aux_id, 0) > 0
  LOOP
   -- verifica se existe objeto predecessor
   cronograma_pkg.info_pre_retornar(0,
                                    v_empresa_id,
                                    'ORDEM_SERVICO',
                                    v_ordem_servico_aux_id,
                                    v_nome_ativ_pre,
                                    v_cod_objeto_pre,
                                    v_nome_objeto_pre,
                                    v_status_objeto_pre,
                                    v_objeto_pre_id,
                                    v_data_fim_pre,
                                    v_erro_cod,
                                    v_erro_msg);
   IF v_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   v_ordem_servico_aux_id := 0;
   --
   IF nvl(v_objeto_pre_id, 0) > 0 AND v_cod_objeto_pre = 'ORDEM_SERVICO'
   THEN
    -- verifica se a OS predecessora faz parte da estimativa
    SELECT COUNT(*)
      INTO v_qt
      FROM ordem_servico
     WHERE os_estim_id = v_os_estim_id
       AND ordem_servico_id = v_objeto_pre_id;
    --
    IF v_qt > 0
    THEN
     v_ordem_servico_aux_id := v_objeto_pre_id;
     --
     SELECT nvl(dias_estim, 0)
       INTO v_dias_estim_aux
       FROM ordem_servico
      WHERE ordem_servico_id = v_ordem_servico_aux_id;
     --
     v_dias_estim := v_dias_estim + v_dias_estim_aux;
    END IF;
   END IF;
  END LOOP;
  --
  RETURN v_dias_estim;
 EXCEPTION
  WHEN OTHERS THEN
   v_dias_estim := 999999;
   RETURN v_dias_estim;
 END dias_depend_retornar;
 --
 --
 FUNCTION tempo_exec_prev_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/12/2010
  -- DESCRICAO: retorna o tempo previsto na execução da OS, em horas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN NUMBER AS
  v_retorno NUMBER(10, 2);
  v_qt      INTEGER;
  --
 BEGIN
  SELECT nvl(SUM(tempo_exec_prev), 0)
    INTO v_retorno
    FROM os_tipo_produto
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END tempo_exec_prev_retornar;
 --
 --
 FUNCTION tempo_exec_gasto_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/12/2010
  -- DESCRICAO: retorna o tempo gasto na execução da OS, em horas. Se o tipo_produto_id for
  --    informado, calcula o tempo gasto só nesse produto.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN os_tipo_produto.ordem_servico_id%TYPE,
  p_tipo_produto_id  IN job_tipo_produto.tipo_produto_id%TYPE
 ) RETURN NUMBER AS
  v_retorno          NUMBER(10, 2);
  v_tempo_tot_gasto  NUMBER(10, 2);
  v_fator_tempo_calc os_tipo_produto.fator_tempo_calc%TYPE;
  v_qt               INTEGER;
  --
 BEGIN
  SELECT nvl(SUM(horas), 0)
    INTO v_tempo_tot_gasto
    FROM apontam_hora
   WHERE ordem_servico_id = p_ordem_servico_id;
  IF nvl(p_tipo_produto_id, 0) = 0
  THEN
   v_retorno := v_tempo_tot_gasto;
  ELSE
   SELECT nvl(MAX(os.fator_tempo_calc), 0)
     INTO v_fator_tempo_calc
     FROM os_tipo_produto  os,
          job_tipo_produto jo
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.job_tipo_produto_id = jo.job_tipo_produto_id
      AND jo.tipo_produto_id = p_tipo_produto_id;
   --
   v_retorno := round(v_tempo_tot_gasto * v_fator_tempo_calc / 100.0, 2);
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END tempo_exec_gasto_retornar;
 --
 --
 FUNCTION descricao_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 26/07/2012
  -- DESCRICAO: retorna a descricao ou os produtos associados a uma determinada OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN os_tipo_produto.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno VARCHAR2(4000);
  v_qt      INTEGER;
  --
  CURSOR c_pr IS
   SELECT TRIM(tp.nome || ' ' || jo.complemento) AS produto
     FROM os_tipo_produto  os,
          job_tipo_produto jo,
          tipo_produto     tp
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.job_tipo_produto_id = jo.job_tipo_produto_id
      AND jo.tipo_produto_id = tp.tipo_produto_id
    ORDER BY upper(TRIM(tp.nome || ' ' || jo.complemento));
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT descricao
    INTO v_retorno
    FROM ordem_servico
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  IF v_retorno IS NULL
  THEN
   FOR r_pr IN c_pr
   LOOP
    v_retorno := v_retorno || ', ' || r_pr.produto;
   END LOOP;
   -- retira a primeira virgula
   v_retorno := substr(v_retorno, 3);
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END descricao_retornar;
 --
 --
 FUNCTION ultima_os_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/08/2012
  -- DESCRICAO: retorna a ordem de servico mais recente relacionada a um determinado
  --  produto/item do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_job_tipo_produto_id IN job_tipo_produto.job_tipo_produto_id%TYPE
 ) RETURN NUMBER AS
  v_retorno ordem_servico.ordem_servico_id%TYPE;
  v_qt      INTEGER;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(ot.ordem_servico_id)
    INTO v_retorno
    FROM os_tipo_produto ot,
         ordem_servico   os
   WHERE ot.job_tipo_produto_id = p_job_tipo_produto_id
     AND ot.ordem_servico_id = os.ordem_servico_id
     AND os.status <> 'CANC';
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END ultima_os_retornar;
 --
 --
 FUNCTION ultimo_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 03/08/2012
  -- DESCRICAO: retorna o ultimo os_evento_id relacionado a uma determinada OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN NUMBER AS
  v_retorno os_evento.os_evento_id%TYPE;
  v_qt      INTEGER;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(os_evento_id)
    INTO v_retorno
    FROM os_evento
   WHERE ordem_servico_id = p_ordem_servico_id;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END ultimo_evento_retornar;
 --
 --
 FUNCTION horas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 17/01/2013
  -- DESCRICAO: retorna as horas gastas ou planejadas para uma determinada OS/papel/nivel.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/05/2020  Retirada de papel/nivel de os_horas
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_papel_id         IN papel.papel_id%TYPE,
  p_nivel            IN usuario_cargo.nivel%TYPE,
  p_tipo             IN VARCHAR2
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
  -- retorna horas planejadas para a OS
  -------------------------------------------
  IF p_tipo = 'PLANEJ'
  THEN
   -- Retorna o total da OS
   SELECT nvl(SUM(horas_planej), 0)
     INTO v_retorno
     FROM os_horas
    WHERE ordem_servico_id = p_ordem_servico_id;
  END IF;
  --
  -------------------------------------------
  -- retorna horas gastas na OS
  -------------------------------------------
  IF p_tipo = 'GASTA'
  THEN
   IF nvl(p_papel_id, 0) = 0
   THEN
    -- papel nao informado. Retorna o total da OS
    SELECT nvl(SUM(horas), 0)
      INTO v_retorno
      FROM apontam_hora
     WHERE ordem_servico_id = p_ordem_servico_id;
   ELSE
    -- papel informado. Retorna o total da OS/papel/nivel
    IF TRIM(p_nivel) IS NOT NULL
    THEN
     SELECT nvl(SUM(ah.horas), 0)
       INTO v_retorno
       FROM apontam_hora ah,
            apontam_data ad
      WHERE ah.ordem_servico_id = p_ordem_servico_id
        AND ah.papel_id = p_papel_id
        AND ah.apontam_data_id = ad.apontam_data_id
        AND ad.nivel = p_nivel;
    ELSE
     SELECT nvl(SUM(horas), 0)
       INTO v_retorno
       FROM apontam_hora
      WHERE ordem_servico_id = p_ordem_servico_id
        AND papel_id = p_papel_id;
    END IF;
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
 FUNCTION data_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/02/2013
  -- DESCRICAO: retorna a data do evento de uma determinada OS (para o tipo de evento
  --   passado no parametro).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/03/2014  Novo tipo ENVI.
  -- Silvia            10/12/2015  Ignora datas de eventos de estimativa.
  -- Silvia            11/01/2017  Novo tipo EXEC
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo             IN VARCHAR2
 ) RETURN DATE AS
  v_retorno   DATE;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_tipo = 'DIST'
  THEN
   -- retorna a data mais recente em que a OS foi distribuida
   SELECT MAX(data_evento)
     INTO v_retorno
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND flag_estim = 'N'
      AND ((status_de = 'DIST' AND status_para = 'ACEI') OR
          (status_de = 'DIST' AND status_para = 'EMEX'));
  END IF;
  --
  IF p_tipo = 'CONC'
  THEN
   -- retorna a data em que a OS foi concluida
   SELECT MAX(data_evento)
     INTO v_retorno
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND flag_estim = 'N'
         --AND status_de = 'EXEC' AND status_para = 'CONC'
      AND status_para = 'CONC';
  END IF;
  --
  IF p_tipo = 'ENVI'
  THEN
   -- retorna a data em que a OS foi enviada
   SELECT MAX(data_evento)
     INTO v_retorno
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND flag_estim = 'N'
      AND status_de = 'PREP'
      AND status_para = 'DIST';
   --
   IF v_retorno IS NULL
   THEN
    SELECT MAX(data_evento)
      INTO v_retorno
      FROM os_evento
     WHERE ordem_servico_id = p_ordem_servico_id
       AND flag_estim = 'N'
       AND status_de = 'PREP'
       AND status_para = 'ACEI';
   END IF;
  END IF;
  --
  IF p_tipo = 'EXEC'
  THEN
   -- retorna a data mais recente em que a OS foi p/ o status
   -- executada
   SELECT MAX(data_evento)
     INTO v_retorno
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND flag_estim = 'N'
      AND status_para = 'EXEC';
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_retornar;
 --
 --
 FUNCTION data_status_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 14/11/2018
  -- DESCRICAO: retorna a data do status atual de uma determinada OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN DATE AS
  v_retorno   DATE;
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(data_evento)
    INTO v_retorno
    FROM os_evento     oe,
         ordem_servico os
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.ordem_servico_id = oe.ordem_servico_id
     AND os.status = oe.status_para;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_status_retornar;
 --
 --
 FUNCTION data_apont_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/02/2013
  -- DESCRICAO: retorna a data de inicio ou termino do periodo de apontamento de horas para
  --  uma determinada OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/10/2019  mudanca na data de inicio de apontamento
  -- Silvia            01/06/2021  mudandas nos calculos das duas datas; novo parametro
  --                               p_usuario_sessao_id
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo              IN VARCHAR2
 ) RETURN DATE AS
  v_retorno        DATE;
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_status         ordem_servico.status%TYPE;
  v_data_entrada   ordem_servico.data_entrada%TYPE;
  v_job_id         ordem_servico.job_id%TYPE;
  v_qtd_refacao    ordem_servico.qtd_refacao%TYPE;
  v_data_apont_ini job.data_apont_ini%TYPE;
  v_data_apont_fim job.data_apont_fim%TYPE;
  v_empresa_id     job.empresa_id%TYPE;
  v_data_envio     DATE;
  v_data_status    DATE;
  v_data_exec      DATE;
  v_num_dias       NUMBER(10);
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT trunc(os.data_entrada),
         os.job_id,
         os.status,
         os.qtd_refacao,
         trunc(jo.data_apont_ini),
         trunc(jo.data_apont_fim),
         jo.empresa_id
    INTO v_data_entrada,
         v_job_id,
         v_status,
         v_qtd_refacao,
         v_data_apont_ini,
         v_data_apont_fim,
         v_empresa_id
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF p_tipo = 'INI'
  THEN
   SELECT MIN(trunc(data_evento))
     INTO v_data_envio
     FROM os_evento
    WHERE ordem_servico_id = p_ordem_servico_id
      AND flag_estim = 'N'
      AND num_refacao = 0
      AND status_de = 'PREP'
      AND status_para IN ('DIST', 'ACEI');
   --
   IF v_data_apont_ini IS NULL AND v_data_envio IS NULL
   THEN
    v_retorno := v_data_entrada;
   ELSIF v_data_apont_ini IS NOT NULL AND v_data_envio IS NOT NULL
   THEN
    -- pega a menor
    IF v_data_apont_ini <= v_data_envio
    THEN
     v_retorno := v_data_apont_ini;
    ELSE
     v_retorno := v_data_envio;
    END IF;
   ELSE
    -- uma delas eh nula
    v_retorno := nvl(v_data_apont_ini, v_data_entrada);
   END IF;
  END IF; -- fim do IF p_tipo = 'INI'
  --
  IF p_tipo = 'FIM'
  THEN
   v_num_dias := nvl(to_number(empresa_pkg.parametro_retornar(v_empresa_id,
                                                              'NUM_DIAS_UTEIS_OCULT_OSEXEC')),
                     0);
   --
   IF v_status IN ('CANC', 'DESC')
   THEN
    -- pega a data do cancelamento ou descarte
    SELECT MAX(data_evento)
      INTO v_retorno
      FROM os_evento
     WHERE ordem_servico_id = p_ordem_servico_id
       AND status_para = v_status;
   ELSE
    IF v_num_dias > 0
    THEN
     SELECT MAX(trunc(data_evento))
       INTO v_data_exec
       FROM os_evento
      WHERE ordem_servico_id = p_ordem_servico_id
        AND flag_estim = 'N'
        AND num_refacao = v_qtd_refacao
        AND status_de = 'EMEX'
        AND status_para IN ('AVAL', 'EXEC');
     --
     v_retorno := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                     v_data_exec,
                                                     v_num_dias,
                                                     'S');
    ELSE
     IF v_data_apont_fim IS NULL AND v_status = 'CONC'
     THEN
      -- pega a data da conclusao
      SELECT MAX(trunc(data_evento))
        INTO v_retorno
        FROM os_evento
       WHERE ordem_servico_id = p_ordem_servico_id
         AND flag_estim = 'N'
         AND status_para = 'CONC';
     END IF;
    END IF;
   END IF; -- fim do IF v_status IN ('CANC','DESC'
   --
   -- se nao foi possivel calcular o FIM, pega o previsto no job
   IF v_retorno IS NULL
   THEN
    v_retorno := v_data_apont_fim;
   END IF;
  END IF; -- fim do IF p_tipo = 'FIM'
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END data_apont_retornar;
 --
 --
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/04/2013
  -- DESCRICAO: retorna o numero formatado de uma determinada OS, COM o numero do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/02/2019  Testa parametro para acrescentar o cod_ext_job.
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno         VARCHAR2(100);
  v_qt              INTEGER;
  v_numero_os       ordem_servico.numero%TYPE;
  v_num_job         job.numero%TYPE;
  v_cod_tipo        tipo_os.codigo%TYPE;
  v_empresa_id      empresa.empresa_id%TYPE;
  v_flag_com_codext VARCHAR2(10);
  v_cod_ext_job     job.cod_ext_job%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         jo.empresa_id,
         os.numero,
         ti.codigo,
         TRIM(jo.cod_ext_job)
    INTO v_num_job,
         v_empresa_id,
         v_numero_os,
         v_cod_tipo,
         v_cod_ext_job
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  v_flag_com_codext := empresa_pkg.parametro_retornar(v_empresa_id, 'NUMERACAO_OS_COM_CODEXT');
  --
  IF v_flag_com_codext = 'S' AND v_cod_ext_job IS NOT NULL
  THEN
   -- eh para acrescentar tb o codigo externo do job
   IF length(v_numero_os) <= 3
   THEN
    v_retorno := to_char(v_num_job) || '-' || v_cod_ext_job || '-' || v_cod_tipo ||
                 TRIM(to_char(v_numero_os, '000'));
   ELSE
    v_retorno := to_char(v_num_job) || '-' || v_cod_ext_job || '-' || v_cod_tipo ||
                 to_char(v_numero_os);
   END IF;
  ELSE
   -- nao acrescenta o codigo externo do job
   IF length(v_numero_os) <= 3
   THEN
    v_retorno := to_char(v_num_job) || '-' || v_cod_tipo || TRIM(to_char(v_numero_os, '000'));
   ELSE
    v_retorno := to_char(v_num_job) || '-' || v_cod_tipo || to_char(v_numero_os);
   END IF;
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
 FUNCTION numero_formatar2
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/04/2013
  -- DESCRICAO: retorna o numero formatado de uma determinada OS, SEM o numero do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno   VARCHAR2(100);
  v_qt        INTEGER;
  v_numero_os ordem_servico.numero%TYPE;
  v_num_job   job.numero%TYPE;
  v_cod_tipo  tipo_os.codigo%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT jo.numero,
         os.numero,
         ti.codigo
    INTO v_num_job,
         v_numero_os,
         v_cod_tipo
    FROM ordem_servico os,
         job           jo,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF length(v_numero_os) <= 3
  THEN
   v_retorno := v_cod_tipo || TRIM(to_char(v_numero_os, '000'));
  ELSE
   v_retorno := v_cod_tipo || to_char(v_numero_os);
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END numero_formatar2;
 --
 --
 FUNCTION nome_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia/Ana      ProcessMind     DATA: 11/04/2023
  -- DESCRICAO: retorna o nome/descricao com base no nome do entregavel, caso a
  --    descricao nao seja configurada como campo de entrada na interface.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt                 INTEGER;
  v_flag_tem_descricao tipo_os.flag_tem_descricao%TYPE;
  v_descricao          ordem_servico.descricao%TYPE;
  --
 BEGIN
  --
  SELECT ti.flag_tem_descricao,
         os.descricao
    INTO v_flag_tem_descricao,
         v_descricao
    FROM ordem_servico os,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tipo_produto op
   WHERE op.ordem_servico_id = p_ordem_servico_id;
  IF v_flag_tem_descricao = 'N'
  THEN
   IF v_qt = 0
   THEN
    v_descricao := 'Sem entregável definido';
   ELSIF v_qt = 1
   THEN
    SELECT CASE
            WHEN jp.complemento IS NULL THEN
             tp.nome
            ELSE
             tp.nome || ' - ' || jp.complemento
           END AS nome
      INTO v_descricao
      FROM os_tipo_produto  op,
           job_tipo_produto jp,
           tipo_produto     tp
     WHERE op.job_tipo_produto_id = jp.job_tipo_produto_id
       AND jp.tipo_produto_id = tp.tipo_produto_id
       AND op.ordem_servico_id = p_ordem_servico_id
     ORDER BY tp.nome;
   ELSE
    SELECT MIN(CASE
                WHEN jp.complemento IS NULL THEN
                 tp.nome || ' e outro(s) ' || (v_qt - 1)
               /*WHEN jp.complemento IS NOT NULL THEN
               tp.nome || ' - ' || jp.complemento*/
                ELSE
                 tp.nome || ' - ' || jp.complemento || ' e outro(s) ' || (v_qt - 1)
               END) AS nome
      INTO v_descricao
      FROM os_tipo_produto  op,
           job_tipo_produto jp,
           tipo_produto     tp
     WHERE op.job_tipo_produto_id = jp.job_tipo_produto_id
       AND jp.tipo_produto_id = tp.tipo_produto_id
       AND op.ordem_servico_id = p_ordem_servico_id
     ORDER BY tp.nome;
   END IF;
  END IF;
  --
  RETURN v_descricao;
 EXCEPTION
  WHEN OTHERS THEN
   v_descricao := 'ERRO';
   RETURN v_descricao;
 END nome_retornar;
 --
 --
 FUNCTION faixa_aprov_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/03/2016
  -- DESCRICAO: verifica se o usuario pode aprovar OS com essas caracteristicas.
  --  Retorna 1 caso possa e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/01/2017  Teste adicional de privilegio, caso a OS nao tenha
  --                               fluxo de aprovacao.
  -- Silvia            30/03/2017  Novo campo flag_habilitado na tabela os_fluxo_aprov
  ------------------------------------------------------------------------------------------
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN INTEGER AS
  v_qt                 INTEGER;
  v_retorno            INTEGER;
  v_exception          EXCEPTION;
  v_saida              EXCEPTION;
  v_flag_faixa_aprov   ordem_servico.flag_faixa_aprov%TYPE;
  v_flag_aprov_est_seq ordem_servico.flag_aprov_est_seq%TYPE;
  v_flag_aprov_exe_seq ordem_servico.flag_aprov_exe_seq%TYPE;
  v_job_id             ordem_servico.job_id%TYPE;
  v_tipo_os_id         ordem_servico.tipo_os_id%TYPE;
  v_flag_admin         usuario.flag_admin%TYPE;
  v_seq_aprov          os_fluxo_aprov.seq_aprov%TYPE;
  v_seq_aprov_maior    os_fluxo_aprov.seq_aprov%TYPE;
  v_tipo_aprov         os_fluxo_aprov.tipo_aprov%TYPE;
  v_faixa_aprov_id     faixa_aprov.faixa_aprov_id%TYPE;
  v_flag_aprov_seq     faixa_aprov.flag_sequencial%TYPE;
  v_os_estim_id        os_estim.os_estim_id%TYPE;
  v_status_estim       os_estim.status%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  ------------------------------------------------------------
  -- verifica casos especiais
  ------------------------------------------------------------
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_flag_admin = 'S'
  THEN
   -- eh o usuario admin, nao tem fluxo
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  SELECT oe.os_estim_id,
         oe.status,
         os.flag_faixa_aprov,
         os.flag_aprov_est_seq,
         os.flag_aprov_exe_seq,
         os.job_id,
         os.tipo_os_id
    INTO v_os_estim_id,
         v_status_estim,
         v_flag_faixa_aprov,
         v_flag_aprov_est_seq,
         v_flag_aprov_exe_seq,
         v_job_id,
         v_tipo_os_id
    FROM ordem_servico os,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
  THEN
   -- fluxo de estimativa
   v_tipo_aprov := 'EST';
  ELSE
   -- fluxo de execucao
   v_tipo_aprov := 'EXE';
  END IF;
  --
  IF v_flag_faixa_aprov = 'N'
  THEN
   -- OS criada sem fluxo de aprovacao
   -- testa apenas o privilegio.
   IF usuario_pkg.priv_verificar(p_usuario_id, 'OS_AP', v_job_id, v_tipo_os_id, p_empresa_id) = 1
   THEN
    v_retorno := 1;
   END IF;
   --
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- verifica se o fluxo de aprovacao ja foi instanciado
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_aprov = v_tipo_aprov;
  --
  IF v_qt > 0
  THEN
   -- existe um fluxo em andamento.
   IF (v_tipo_aprov = 'EST' AND v_flag_aprov_est_seq = 'S') OR
      (v_tipo_aprov = 'EXE' AND v_flag_aprov_exe_seq = 'S')
   THEN
    -- aprovacao deve obedecer a sequencia.
    -- pega a maior sequencia aprovada
    SELECT nvl(MAX(seq_aprov), 0)
      INTO v_seq_aprov_maior
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND tipo_aprov = v_tipo_aprov
       AND data_aprov IS NOT NULL;
    --
    -- pega a proxima sequencia com aprovacao pendente
    SELECT nvl(MIN(seq_aprov), 0)
      INTO v_seq_aprov
      FROM os_fluxo_aprov
     WHERE ordem_servico_id = p_ordem_servico_id
       AND data_aprov IS NULL
       AND flag_habilitado = 'S'
       AND tipo_aprov = v_tipo_aprov
       AND seq_aprov > v_seq_aprov_maior;
    --
    -- Verifica se algum papel do usuario pode aprovar nessa sequencia.
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_papel up
     WHERE up.usuario_id = p_usuario_id
       AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                  'OS_AP',
                                                  up.papel_id,
                                                  p_ordem_servico_id) = 1
       AND EXISTS (SELECT 1
              FROM os_fluxo_aprov fa
             WHERE fa.ordem_servico_id = p_ordem_servico_id
               AND fa.tipo_aprov = v_tipo_aprov
               AND fa.papel_id = up.papel_id
               AND fa.seq_aprov = v_seq_aprov
               AND fa.data_aprov IS NULL
               AND fa.flag_habilitado = 'S');
    --
    IF v_qt > 0
    THEN
     v_retorno := 1;
     RAISE v_saida;
    END IF;
   ELSE
    -- aprovacao nao precisa obedecer a sequencia. Verifica se algum papel do
    -- usuario pode aprovar em qualquer sequencia, desde que a sequencia nao
    -- tenha aprovacao.
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario_papel  up,
           os_fluxo_aprov fa
     WHERE up.usuario_id = p_usuario_id
       AND ordem_servico_pkg.papel_priv_verificar(up.usuario_id,
                                                  'OS_AP',
                                                  up.papel_id,
                                                  p_ordem_servico_id) = 1
       AND fa.ordem_servico_id = p_ordem_servico_id
       AND fa.tipo_aprov = v_tipo_aprov
       AND fa.papel_id = up.papel_id
       AND fa.data_aprov IS NULL
       AND fa.flag_habilitado = 'S'
       AND NOT EXISTS (SELECT 1
              FROM os_fluxo_aprov f2
             WHERE f2.ordem_servico_id = fa.ordem_servico_id
               AND f2.tipo_aprov = fa.tipo_aprov
               AND f2.seq_aprov = fa.seq_aprov
               AND f2.data_aprov IS NOT NULL);
    --
    IF v_qt > 0
    THEN
     v_retorno := 1;
     RAISE v_saida;
    END IF;
   END IF;
   --
   -- forca a saida com retorno 0 (usuario sem permissao)
   RAISE v_saida;
  END IF; -- fim do fluxo em andamento
  --
  ------------------------------------------------------------
  -- nao tem fluxo instanciado
  -- verifica fluxos de aprovacao configurados
  ------------------------------------------------------------
  v_faixa_aprov_id := ordem_servico_pkg.faixa_aprov_id_retornar(p_usuario_id,
                                                                p_empresa_id,
                                                                p_ordem_servico_id,
                                                                v_tipo_aprov);
  --
  IF v_faixa_aprov_id < 0
  THEN
   -- forca a saida com retorno 0 (usuario sem permissao)
   v_retorno := 0;
   RAISE v_saida;
  END IF;
  --
  IF v_faixa_aprov_id = 0
  THEN
   -- forca a saida com retorno 1 (usuario ADMIN)
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  SELECT flag_sequencial
    INTO v_flag_aprov_seq
    FROM faixa_aprov
   WHERE faixa_aprov_id = v_faixa_aprov_id;
  --
  IF v_flag_aprov_seq = 'N'
  THEN
   -- nao precisa verificar a sequencia
   v_retorno := 1;
   RAISE v_saida;
  END IF;
  --
  -- verifica a sequencia (primeiro aprovador)
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_papel fa,
         usuario_papel     up
   WHERE fa.faixa_aprov_id = v_faixa_aprov_id
     AND fa.seq_aprov = 1
     AND fa.papel_id = up.papel_id
     AND up.usuario_id = p_usuario_id;
  --
  IF v_qt > 0
  THEN
   -- usuario tem papel para ser o primeiro aprovador
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END faixa_aprov_verificar;
 --
 --
 FUNCTION faixa_aprov_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 04/03/2016
  -- DESCRICAO: verifica se o usuario pode aprovar a OS de acordo com as regras, retornando
  --   o respectivo faixa_aprov_id. Retorno -1 indica faixa nao encontrada. Retorno 0 indica
  --   usuario ou OS sem necessidade de fluxo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/05/2016  Tratamento de cliente_id
  -- Silvia            09/08/2016  Aceita usuario_id = 0 (retorna qualquer faixa que sirva)
  -- Silvia            09/08/2016  Novo parametro tipo_aprov (EXE ou EST)
  -- Silvia            27/10/2016  Ordenacao do cursor p/ regras mais especificas.
  -- Silvia            16/11/2017  Implementacao de flag_ativo.
  ------------------------------------------------------------------------------------------
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov       IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt               INTEGER;
  v_faixa_aprov_id   faixa_aprov.faixa_aprov_id%TYPE;
  v_exception        EXCEPTION;
  v_saida            EXCEPTION;
  v_cliente_id       job.cliente_id%TYPE;
  v_tipo_job_id      job.tipo_job_id%TYPE;
  v_complex_job      job.complex_job%TYPE;
  v_flag_admin       usuario.flag_admin%TYPE;
  v_flag_faixa_aprov ordem_servico.flag_faixa_aprov%TYPE;
  v_os_estim_id      os_estim.os_estim_id%TYPE;
  v_status_estim     os_estim.status%TYPE;
  v_tipo_aprov       os_fluxo_aprov.tipo_aprov%TYPE;
  --
  CURSOR c_fa IS
  -- faixas para aprovacao de estimativa
  -- (com preferencia para as regras mais especificas)
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov       fa,
          faixa_aprov_papel fp,
          faixa_aprov_os    fo,
          papel             pa
    WHERE fa.empresa_id = p_empresa_id
      AND fa.tipo_faixa = 'OS'
      AND fa.flag_ativo = 'S'
      AND fa.faixa_aprov_id = fo.faixa_aprov_id
      AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
      AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
      AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
      AND fo.flag_aprov_est = 'S'
      AND fa.faixa_aprov_id = fp.faixa_aprov_id
      AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
      AND fp.papel_id = pa.papel_id
    ORDER BY decode(fo.cliente_id, NULL, 999, 1),
             decode(fo.tipo_job_id, NULL, 999, 1),
             decode(fo.complex_job, 'ND', 999, 1),
             fp.seq_aprov,
             pa.ordem,
             fa.faixa_aprov_id;
  --
  CURSOR c_fb IS
  -- faixas para aprovacao de execucao
  -- (com preferencia para as regras mais especificas)
   SELECT fa.faixa_aprov_id,
          fp.seq_aprov,
          fp.papel_id
     FROM faixa_aprov       fa,
          faixa_aprov_papel fp,
          faixa_aprov_os    fo,
          papel             pa
    WHERE fa.empresa_id = p_empresa_id
      AND fa.tipo_faixa = 'OS'
      AND fa.flag_ativo = 'S'
      AND fa.faixa_aprov_id = fo.faixa_aprov_id
      AND (fo.cliente_id IS NULL OR fo.cliente_id = v_cliente_id)
      AND (fo.tipo_job_id IS NULL OR fo.tipo_job_id = v_tipo_job_id)
      AND (fo.complex_job = 'ND' OR fo.complex_job = v_complex_job)
      AND fo.flag_aprov_exe = 'S'
      AND fa.faixa_aprov_id = fp.faixa_aprov_id
      AND ((fa.flag_sequencial = 'S' AND fp.seq_aprov = 1) OR fa.flag_sequencial = 'N')
      AND fp.papel_id = pa.papel_id
    ORDER BY decode(fo.cliente_id, NULL, 999, 1),
             decode(fo.tipo_job_id, NULL, 999, 1),
             decode(fo.complex_job, 'ND', 999, 1),
             fp.seq_aprov,
             pa.ordem,
             fa.faixa_aprov_id;
  --
 BEGIN
  -- valor padrao para faixa nao encontrada/configurada
  v_faixa_aprov_id := -1;
  v_flag_admin     := 'N';
  --
  IF nvl(p_usuario_id, 0) > 0
  THEN
   SELECT flag_admin
     INTO v_flag_admin
     FROM usuario
    WHERE usuario_id = p_usuario_id;
  END IF;
  --
  IF v_flag_admin = 'S'
  THEN
   -- eh o usuario admin, nao tem fluxo aprovacao
   v_faixa_aprov_id := 0;
   RAISE v_saida;
  END IF;
  --
  SELECT jo.cliente_id,
         jo.tipo_job_id,
         jo.complex_job,
         oe.os_estim_id,
         oe.status,
         os.flag_faixa_aprov
    INTO v_cliente_id,
         v_tipo_job_id,
         v_complex_job,
         v_os_estim_id,
         v_status_estim,
         v_flag_faixa_aprov
    FROM ordem_servico os,
         job           jo,
         os_estim      oe
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id
     AND os.os_estim_id = oe.os_estim_id(+);
  --
  IF v_flag_faixa_aprov = 'N'
  THEN
   -- OS sem fluxo de aprovacao
   v_faixa_aprov_id := 0;
   RAISE v_saida;
  END IF;
  --
  IF TRIM(p_tipo_aprov) IS NULL
  THEN
   -- o tipo de aprovacao nao foi especificado.
   -- pega pelo status da OS.
   IF nvl(v_os_estim_id, 0) > 0 AND v_status_estim = 'ANDA'
   THEN
    -- OS em processo de estimativa
    v_tipo_aprov := 'EST';
   ELSE
    -- OS em processo de execucao
    v_tipo_aprov := 'EXE';
   END IF;
  ELSE
   -- o tipo de aprovacao foi especificado.
   v_tipo_aprov := p_tipo_aprov;
  END IF;
  --
  IF v_tipo_aprov = 'EST'
  THEN
   -- faixa para estimativa
   FOR r_fa IN c_fa
   LOOP
    -- pega a primeira faixa encontrada. Se nao achar nada,
    -- a variavel continua com o valor -1.
    IF v_faixa_aprov_id = -1
    THEN
     IF nvl(p_usuario_id, 0) > 0
     THEN
      -- veio o usuario. Precisa pegar a faixa com o papel que sirva
      IF ordem_servico_pkg.papel_priv_verificar(p_usuario_id,
                                                'OS_AP',
                                                r_fa.papel_id,
                                                p_ordem_servico_id) = 1
      THEN
       v_faixa_aprov_id := r_fa.faixa_aprov_id;
      END IF;
     ELSE
      -- nao veio o usuario. Pega a primeira faixa
      v_faixa_aprov_id := r_fa.faixa_aprov_id;
     END IF;
    END IF;
   END LOOP;
  ELSE
   -- faixa para execucao
   FOR r_fb IN c_fb
   LOOP
    -- pega a primeira faixa encontrada. Se nao achar nada,
    -- a variavel continua com o valor -1.
    IF v_faixa_aprov_id = -1
    THEN
     IF nvl(p_usuario_id, 0) > 0
     THEN
      -- veio o usuario. Precisa pegar a faixa com o papel que sirva
      IF ordem_servico_pkg.papel_priv_verificar(p_usuario_id,
                                                'OS_AP',
                                                r_fb.papel_id,
                                                p_ordem_servico_id) = 1
      THEN
       v_faixa_aprov_id := r_fb.faixa_aprov_id;
      END IF;
     ELSE
      -- nao veio o usuario. Pega a primeira faixa
      v_faixa_aprov_id := r_fb.faixa_aprov_id;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  RETURN v_faixa_aprov_id;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_faixa_aprov_id;
  WHEN OTHERS THEN
   v_faixa_aprov_id := -1;
   RETURN v_faixa_aprov_id;
 END faixa_aprov_id_retornar;
 --
 --
 FUNCTION fluxo_seq_ok_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/03/2017
  -- DESCRICAO: verifica se o fluxo de aprovacao da OS esta completo (todas as
  --  sequencias aprovadas ou desabilitadas).
  --  Retorna 1 caso sim e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE,
  p_tipo_aprov       IN VARCHAR2
 ) RETURN INTEGER IS
  v_qt          INTEGER;
  v_retorno     INTEGER;
  v_exception   EXCEPTION;
  v_saida       EXCEPTION;
  v_qtd_seq_max faixa_aprov_papel.seq_aprov%TYPE;
  v_qtd_seq_ok  faixa_aprov_papel.seq_aprov%TYPE;
  --
  CURSOR c_os IS
   SELECT COUNT(seq_aprov) qtd_tot,
          COUNT(usuario_aprov_id) qtd_aprov,
          nvl(SUM(decode(flag_habilitado, 'S', 0, 'N', 1)), 0) qtd_pula
     FROM os_fluxo_aprov
    WHERE ordem_servico_id = p_ordem_servico_id
      AND tipo_aprov = p_tipo_aprov
    GROUP BY seq_aprov;
  --
 BEGIN
  v_retorno    := 0;
  v_qtd_seq_ok := 0;
  --
  -- seleciona o numero maximo de sequencias
  SELECT nvl(MAX(seq_aprov), 0)
    INTO v_qtd_seq_max
    FROM os_fluxo_aprov
   WHERE ordem_servico_id = p_ordem_servico_id
     AND tipo_aprov = p_tipo_aprov;
  --
  IF v_qtd_seq_max = 0
  THEN
   -- nao existe fluxo instanciado
   RAISE v_saida;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de aprovacao para cada sequencia
  ------------------------------------------------------------
  FOR r_os IN c_os
  LOOP
   IF r_os.qtd_aprov > 0 OR r_os.qtd_tot = r_os.qtd_pula
   THEN
    -- a sequencia ja foi aprovada ou estah totalmente desabilitada.
    -- conta a sequencia como completa.
    v_qtd_seq_ok := v_qtd_seq_ok + 1;
   END IF;
  END LOOP;
  --
  -- todas as sequencias estao completas
  IF v_qtd_seq_ok >= v_qtd_seq_max
  THEN
   v_retorno := 1;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := -1;
   RETURN v_retorno;
 END fluxo_seq_ok_verificar;
 --
 --
 FUNCTION papel_priv_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/10/2016
  -- DESCRICAO: verifica se o usuario possui esse papel e se esse papel lhe da o privilegio
  --  indicado nessa OS (apenas privilegios do grupo OSEND).
  --
  --  Retorna '1' caso o usuario possua o privilegio ou '0', caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia). Remocao do
  --                               parametro USAR_PRIV_PAPEL_ENDER.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_codigo_priv       IN privilegio.codigo%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN INTEGER AS
  v_ret         INTEGER;
  v_qt          INTEGER;
  v_flag_admin  usuario.flag_admin%TYPE;
  v_flag_ativo  usuario.flag_ativo%TYPE;
  v_abrangencia papel_priv.abrangencia%TYPE;
  v_grupo       privilegio.grupo%TYPE;
  v_empresa_id  job.empresa_id%TYPE;
  v_job_id      job.job_id%TYPE;
  v_tipo_os_id  ordem_servico.tipo_os_id%TYPE;
  --
 BEGIN
  v_ret := 0;
  --
  -- verifica o tipo de usuario
  SELECT flag_admin,
         flag_ativo
    INTO v_flag_admin,
         v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- usuario administrador pode tudo.
  IF v_flag_admin = 'S'
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -- usuario inativo nao tem privilegio.
  IF v_flag_ativo = 'N'
  THEN
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  SELECT grupo
    INTO v_grupo
    FROM privilegio
   WHERE codigo = p_codigo_priv;
  --
  IF v_grupo <> 'OSEND'
  THEN
   -- foi informado o grupo errado
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  SELECT os.tipo_os_id,
         jo.empresa_id,
         jo.job_id
    INTO v_tipo_os_id,
         v_empresa_id,
         v_job_id
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  -----------------------------------------------------------
  -- verifica se o papel do usuario garante privilegio
  -- para realizar a operacao.
  -----------------------------------------------------------
  SELECT COUNT(*),
         to_char(MAX(pp.abrangencia))
    INTO v_qt,
         v_abrangencia
    FROM usuario_papel up,
         papel_priv    pp,
         privilegio    pr,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = v_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = p_codigo_priv
     AND pa.papel_id = p_papel_id;
  --
  IF v_qt = 0
  THEN
   -- usuario nao tem privilegio
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- usuario tem privilegio sobre qualquer objeto, sem
  -- necessidade de se verificar enderecamento
  -----------------------------------------------------------
  IF v_abrangencia = 'T'
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- verificacoes por tipo de OS
  -----------------------------------------------------------
  SELECT COUNT(*),
         to_char(MAX(pp.abrangencia))
    INTO v_qt,
         v_abrangencia
    FROM usuario_papel  up,
         papel_priv_tos pp,
         privilegio     pr,
         papel          pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.empresa_id = v_empresa_id
     AND up.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = p_codigo_priv
     AND pp.tipo_os_id = v_tipo_os_id
     AND pa.papel_id = p_papel_id;
  --
  IF v_qt = 0
  THEN
   -- usuario nao tem privilegio para esse tipo de OS
   v_ret := 0;
   RETURN v_ret;
  END IF;
  --
  IF v_abrangencia = 'T'
  THEN
   -- usuario tem privilegio, independente do enderecamento do job
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  -----------------------------------------------------------
  -- verificacoes de enderecamento
  -----------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job_usuario ju
   WHERE ju.usuario_id = p_usuario_sessao_id
     AND ju.job_id = v_job_id;
  --
  IF v_qt > 0
  THEN
   v_ret := 1;
   RETURN v_ret;
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN OTHERS THEN
   v_ret := 0;
   RETURN v_ret;
 END papel_priv_verificar;
 --
 --
 FUNCTION preenchimento_ok_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 28/01/2020
  -- DESCRICAO: verifica se as informações principais + metadados da OS estao
  --  preenchidas ou nao.
  --  Retorna 1 caso sim e 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/07/2021  Ajuste no teste de tamanho ogrigatorio
  -- Ana Luiza         16/12/2024  Adicionado verificacao do servico_id
  ------------------------------------------------------------------------------------------
  p_ordem_servico_id IN ordem_servico.ordem_servico_id%TYPE
 ) RETURN INTEGER IS
  v_qt                  INTEGER;
  v_retorno             INTEGER;
  v_exception           EXCEPTION;
  v_saida               EXCEPTION;
  v_flag_tem_corpo      tipo_os.flag_tem_corpo%TYPE;
  v_flag_tem_tipo_finan tipo_os.flag_tem_tipo_finan%TYPE;
  v_flag_tem_produto    tipo_os.flag_tem_produto%TYPE;
  v_flag_tem_descricao  tipo_os.flag_tem_descricao%TYPE;
  v_flag_tem_tamanho    tipo_os.flag_tem_pontos_tam%TYPE;
  v_flag_obriga_tam     tipo_os.flag_obriga_tam%TYPE;
  v_flag_obrigatorio    metadado.flag_obrigatorio%TYPE;
  v_descricao           ordem_servico.descricao%TYPE;
  v_tamanho             ordem_servico.tamanho%TYPE;
  v_data_solicitada     ordem_servico.data_solicitada%TYPE;
  v_tipo_financeiro_id  ordem_servico.tipo_financeiro_id%TYPE;
  v_texto_os            ordem_servico.texto_os%TYPE;
  v_servico_id          ordem_servico.servico_id%TYPE;
  --
  CURSOR c_md IS
   SELECT os.valor_atributo,
          me.flag_obrigatorio
     FROM os_atributo_valor os,
          metadado          me
    WHERE os.ordem_servico_id = p_ordem_servico_id
      AND os.metadado_id = me.metadado_id
    ORDER BY me.ordem;
  --
 BEGIN
  v_retorno := 1;
  --
  SELECT ti.flag_tem_corpo,
         ti.flag_tem_tipo_finan,
         ti.flag_tem_produto,
         ti.flag_tem_descricao,
         ti.flag_tem_pontos_tam,
         ti.flag_obriga_tam,
         os.texto_os,
         os.tipo_financeiro_id,
         os.descricao,
         os.tamanho,
         os.data_solicitada,
         os.servico_id --ALCBO_161224
    INTO v_flag_tem_corpo,
         v_flag_tem_tipo_finan,
         v_flag_tem_produto,
         v_flag_tem_descricao,
         v_flag_tem_tamanho,
         v_flag_obriga_tam,
         v_texto_os,
         v_tipo_financeiro_id,
         v_descricao,
         v_tamanho,
         v_data_solicitada,
         v_servico_id --ALCBO_161224
    FROM ordem_servico os,
         tipo_os       ti
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.tipo_os_id = ti.tipo_os_id;
  --
  IF (TRIM(v_texto_os) IS NULL AND v_flag_tem_corpo = 'S') OR
     (TRIM(v_descricao) IS NULL AND v_flag_tem_descricao = 'S') OR
     (TRIM(v_tamanho) IS NULL AND v_flag_tem_tamanho = 'S' AND v_flag_obriga_tam = 'S') OR
     (v_tipo_financeiro_id IS NULL AND v_flag_tem_tipo_finan = 'S') OR v_data_solicitada IS NULL
    --ALCBO_161224
     OR (v_servico_id IS NULL AND v_flag_tem_produto = 'S')
  THEN
   --
   v_retorno := 0;
   RAISE v_saida;
  END IF;
  --
  -- validacao dos metadados do corpo
  FOR r_md IN c_md
  LOOP
   IF r_md.flag_obrigatorio = 'S' AND TRIM(r_md.valor_atributo) IS NULL
   THEN
    v_retorno := 0;
   END IF;
  END LOOP;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := -1;
   RETURN v_retorno;
 END preenchimento_ok_verificar;
 --
--
END; -- ORDEM_SERVICO_PKG

/
