--------------------------------------------------------
--  DDL for Package Body EVENTO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "EVENTO_PKG" IS
 v_lbl_agencia_singular parametro.descricao%TYPE;
 --
 --
 PROCEDURE notifica_fila_usu_inserir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 15/07/2013
  -- DESCRICAO: subrotina que insere registro na tabela notifica_fila_usu.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/04/2015  Verifica se o usuario ja foi registrado para essa
  --                               notificacao antes de inserir.
  ------------------------------------------------------------------------------------------
 (
  p_notifica_fila_id IN notifica_fila_usu.notifica_fila_id%TYPE,
  p_usuario_para_id  IN notifica_fila_usu.usuario_para_id%TYPE,
  p_nome_para        IN notifica_fila_usu.nome_para%TYPE,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM notifica_fila_usu
   WHERE notifica_fila_id = p_notifica_fila_id
     AND usuario_para_id = p_usuario_para_id;
  --
  IF v_qt = 0 THEN
   INSERT INTO notifica_fila_usu
    (notifica_fila_usu_id,
     notifica_fila_id,
     usuario_para_id,
     nome_para,
     flag_lido)
   VALUES
    (seq_notifica_fila_usu.nextval,
     p_notifica_fila_id,
     p_usuario_para_id,
     substr(TRIM(p_nome_para), 1, 100),
     'N');
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
 END notifica_fila_usu_inserir;
 --
 --
 PROCEDURE notifica_fila_email_inserir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 15/07/2013
  -- DESCRICAO: subrotina que insere registro na tabela notifica_fila_email.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/04/2015  Verifica se o email ja foi registrado para essa
  --                               notificacao antes de inserir.
  ------------------------------------------------------------------------------------------
 (
  p_notifica_fila_id IN notifica_fila_email.notifica_fila_id%TYPE,
  p_emails_para      IN notifica_fila_email.emails_para%TYPE,
  p_nome_para        IN notifica_fila_email.nome_para%TYPE,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF TRIM(p_emails_para) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_fila_email
    WHERE notifica_fila_id = p_notifica_fila_id
      AND emails_para = substr(lower(TRIM(p_emails_para)), 1, 500);
   --
   IF v_qt = 0 THEN
    INSERT INTO notifica_fila_email
     (notifica_fila_email_id,
      notifica_fila_id,
      emails_para,
      nome_para,
      flag_enviado)
    VALUES
     (seq_notifica_fila_email.nextval,
      p_notifica_fila_id,
      substr(lower(TRIM(p_emails_para)), 1, 500),
      substr(TRIM(p_nome_para), 1, 100),
      'N');
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
 END notifica_fila_email_inserir;
 --
 --
 PROCEDURE gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 14/10/2004
  -- DESCRICAO: Executa o registro de um determinado evento. NAO FAZ COMMIT.
  --  p_flag_pula_notif: permite desligar a notificacao na chamada da procedure
  --  p_xml_antes: xml com alguns atributos do objeto antes do evento
  --  p_xml_atual: xml com alguns atributos do objeto no momento do evento
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/10/2008  Novos parametros: justificativa e retorno do historico_id
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            19/01/2011  Tratamento do texto de notificacao p/ faturamento.
  -- Silvia            10/01/2017  Novos param.: p_flag_pula_notif, p_xml_antes, p_xml_atual
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_cod_objeto        IN tipo_objeto.codigo%TYPE,
  p_cod_acao          IN tipo_acao.codigo%TYPE,
  p_identif_objeto    IN historico.identif_objeto%TYPE,
  p_objeto_id         IN historico.objeto_id%TYPE,
  p_complemento       IN VARCHAR2,
  p_justificativa     IN VARCHAR2,
  p_flag_pula_notif   IN VARCHAR2,
  p_xml_antes         IN CLOB,
  p_xml_atual         IN CLOB,
  p_historico_id      OUT historico.historico_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_historico_id        historico.historico_id%TYPE;
  v_data_evento         historico.data_evento%TYPE;
  v_desc_evento         evento.descricao%TYPE;
  v_classe_evento       evento.classe%TYPE;
  v_flag_historico      evento_config.flag_historico%TYPE;
  v_flag_notifica_email evento_config.flag_notifica_email%TYPE;
  v_flag_notifica_tela  evento_config.flag_notifica_tela%TYPE;
  v_evento_id           evento.evento_id%TYPE;
  v_tipo_objeto_id      evento.tipo_objeto_id%TYPE;
  v_tipo_acao_id        evento.tipo_acao_id%TYPE;
  v_evento_config_id    evento_config.evento_config_id%TYPE;
  v_tipo_os_id          evento_config.tipo_os_id%TYPE;
  v_notif_os_por_tipo   VARCHAR2(10);
  --
 BEGIN
  v_qt                := 0;
  p_historico_id      := 0;
  v_notif_os_por_tipo := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_NOTIF_ENTREGA_POR_TIPO');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_pula_notif) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: flag_pula_notif inválido (' || p_flag_pula_notif || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: usuário inexistente.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: código do objeto não fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_cod_acao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: código da ação não fornecido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_objeto_id)
    INTO v_tipo_objeto_id
    FROM tipo_objeto
   WHERE codigo = p_cod_objeto;
  --
  IF v_tipo_objeto_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: objeto não encontrado (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_acao_id)
    INTO v_tipo_acao_id
    FROM tipo_acao
   WHERE codigo = p_cod_acao;
  --
  IF v_tipo_acao_id IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: ação não encontrada (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM evento
   WHERE tipo_objeto_id = v_tipo_objeto_id
     AND tipo_acao_id = v_tipo_acao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'EVENTO_PKG: evento não encontrado (' || p_cod_objeto || ' - ' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT descricao,
         evento_id,
         classe
    INTO v_desc_evento,
         v_evento_id,
         v_classe_evento
    FROM evento
   WHERE tipo_objeto_id = v_tipo_objeto_id
     AND tipo_acao_id = v_tipo_acao_id;
  --
  v_tipo_os_id := NULL;
  --
  IF v_notif_os_por_tipo = 'S' AND p_cod_objeto = 'ORDEM_SERVICO' THEN
   -- precisa descobrir o tipo de OS
   SELECT MAX(tipo_os_id)
     INTO v_tipo_os_id
     FROM ordem_servico
    WHERE ordem_servico_id = p_objeto_id;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM evento_config
   WHERE evento_id = v_evento_id
     AND empresa_id = p_empresa_id
     AND nvl(tipo_os_id, 0) = nvl(v_tipo_os_id, 0);
  --
  ------------------------------------------------------------
  -- gera configuracao padrao
  ------------------------------------------------------------
  IF v_qt = 0 THEN
   -- evento ainda nao configurado.
   -- gera configuracao padrao.
   evento_pkg.config_padrao_criar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  v_evento_id,
                                  v_tipo_os_id,
                                  v_evento_config_id,
                                  p_erro_cod,
                                  p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT evento_config_id,
         flag_historico,
         flag_notifica_email,
         flag_notifica_tela
    INTO v_evento_config_id,
         v_flag_historico,
         v_flag_notifica_email,
         v_flag_notifica_tela
    FROM evento_config
   WHERE evento_id = v_evento_id
     AND empresa_id = p_empresa_id
     AND nvl(tipo_os_id, 0) = nvl(v_tipo_os_id, 0);
  --
  v_data_evento := SYSDATE;
  --
  IF v_flag_historico = 'S' THEN
   -- esse evento gera registro no historico
   SELECT seq_historico.nextval
     INTO v_historico_id
     FROM dual;
   --
   INSERT INTO historico
    (historico_id,
     empresa_id,
     usuario_id,
     evento_id,
     data_evento,
     identif_objeto,
     objeto_id,
     complemento,
     justificativa,
     flag_pula_notif,
     xml_antes,
     xml_atual)
   VALUES
    (v_historico_id,
     p_empresa_id,
     p_usuario_sessao_id,
     v_evento_id,
     v_data_evento,
     p_identif_objeto,
     p_objeto_id,
     substr(TRIM(p_complemento), 1, 1000),
     substr(TRIM(p_justificativa), 1, 500),
     p_flag_pula_notif,
     p_xml_antes,
     p_xml_atual);
  END IF;
  --
  IF p_flag_pula_notif = 'N' THEN
   -- a chamada da procedure nao forcou a desligada da notificacao.
   -- gera a fila de notificacao pendente.
   IF v_flag_notifica_email = 'S' OR v_flag_notifica_tela = 'S' THEN
    INSERT INTO notifica_fila
     (notifica_fila_id,
      empresa_id,
      historico_id,
      evento_config_id,
      usuario_de_id,
      data_evento,
      classe_evento,
      cod_acao,
      cod_objeto,
      objeto_id,
      identif_objeto,
      flag_pend)
    VALUES
     (seq_notifica_fila.nextval,
      p_empresa_id,
      v_historico_id,
      v_evento_config_id,
      p_usuario_sessao_id,
      v_data_evento,
      v_classe_evento,
      p_cod_acao,
      p_cod_objeto,
      p_objeto_id,
      p_identif_objeto,
      'S');
   END IF;
  END IF;
  --
  p_historico_id := nvl(v_historico_id, 0);
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'Geração de evento: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END gerar;
 --
 --
 PROCEDURE carregar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 25/07/2014
  -- DESCRICAO: procedure que carrega configuracoes basicas de notificacao para todos os
  -- eventos x empresas que por acaso ainda nao estejam configurados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_empresa_id       NUMBER(20);
  v_evento_id        NUMBER(20);
  v_evento_config_id NUMBER(20);
  v_tipo_os_id       NUMBER(20);
  --
  CURSOR c_ev IS
   SELECT ev.evento_id,
          ti.codigo AS cod_objeto,
          em.empresa_id
     FROM evento      ev,
          tipo_objeto ti,
          empresa     em
    WHERE ev.tipo_objeto_id = ti.tipo_objeto_id
    ORDER BY em.empresa_id,
             ev.evento_id;
  --
  CURSOR c_to IS
   SELECT tipo_os_id
     FROM tipo_os
    WHERE empresa_id = v_empresa_id
    ORDER BY tipo_os_id;
  --
 BEGIN
  v_qt := 0;
  --
  FOR r_ev IN c_ev
  LOOP
   v_empresa_id := r_ev.empresa_id;
   v_evento_id  := r_ev.evento_id;
   --------------------------------------------------------
   -- carga geral para todos os eventos, sem tipo de OS
   --------------------------------------------------------
   SELECT MAX(evento_config_id)
     INTO v_evento_config_id
     FROM evento_config
    WHERE empresa_id = v_empresa_id
      AND evento_id = v_evento_id
      AND tipo_os_id IS NULL;
   --
   IF v_evento_config_id IS NULL THEN
    SELECT seq_evento_config.nextval
      INTO v_evento_config_id
      FROM dual;
    --
    INSERT INTO evento_config
     (evento_config_id,
      empresa_id,
      evento_id,
      tipo_os_id,
      flag_historico,
      flag_notifica_email,
      flag_notifica_tela)
    VALUES
     (v_evento_config_id,
      v_empresa_id,
      v_evento_id,
      NULL,
      'S',
      'N',
      'N');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_config
    WHERE evento_config_id = v_evento_config_id
      AND tipo_notific = 'EMAIL';
   --
   IF v_qt = 0 THEN
    INSERT INTO notifica_config
     (notifica_config_id,
      evento_config_id,
      tipo_notific,
      flag_ender_todos,
      flag_ender_papel,
      flag_usu_papel,
      flag_usu_indicado,
      flag_job_criador,
      flag_job_respint,
      flag_os_solicit,
      flag_os_distr,
      flag_os_exec,
      flag_emails)
    VALUES
     (seq_notifica_config.nextval,
      v_evento_config_id,
      'EMAIL',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM notifica_config
    WHERE evento_config_id = v_evento_config_id
      AND tipo_notific = 'TELA';
   --
   IF v_qt = 0 THEN
    INSERT INTO notifica_config
     (notifica_config_id,
      evento_config_id,
      tipo_notific,
      flag_ender_todos,
      flag_ender_papel,
      flag_usu_papel,
      flag_usu_indicado,
      flag_job_criador,
      flag_job_respint,
      flag_os_solicit,
      flag_os_distr,
      flag_os_exec,
      flag_emails)
    VALUES
     (seq_notifica_config.nextval,
      v_evento_config_id,
      'TELA',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N',
      'N');
   END IF;
   --
   IF r_ev.cod_objeto = 'ORDEM_SERVICO' THEN
    --------------------------------------------------------
    -- carga do evento X tipo OS
    --------------------------------------------------------
    FOR r_to IN c_to
    LOOP
     v_tipo_os_id := r_to.tipo_os_id;
     --
     SELECT MAX(evento_config_id)
       INTO v_evento_config_id
       FROM evento_config
      WHERE empresa_id = v_empresa_id
        AND evento_id = v_evento_id
        AND tipo_os_id = v_tipo_os_id;
     --
     IF v_evento_config_id IS NULL THEN
      SELECT seq_evento_config.nextval
        INTO v_evento_config_id
        FROM dual;
      --
      INSERT INTO evento_config
       (evento_config_id,
        empresa_id,
        evento_id,
        tipo_os_id,
        flag_historico,
        flag_notifica_email,
        flag_notifica_tela)
      VALUES
       (v_evento_config_id,
        v_empresa_id,
        v_evento_id,
        v_tipo_os_id,
        'S',
        'N',
        'N');
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM notifica_config
      WHERE evento_config_id = v_evento_config_id
        AND tipo_notific = 'EMAIL';
     --
     IF v_qt = 0 THEN
      INSERT INTO notifica_config
       (notifica_config_id,
        evento_config_id,
        tipo_notific,
        flag_ender_todos,
        flag_ender_papel,
        flag_usu_papel,
        flag_usu_indicado,
        flag_job_criador,
        flag_job_respint,
        flag_os_solicit,
        flag_os_distr,
        flag_os_exec,
        flag_emails)
      VALUES
       (seq_notifica_config.nextval,
        v_evento_config_id,
        'EMAIL',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N');
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM notifica_config
      WHERE evento_config_id = v_evento_config_id
        AND tipo_notific = 'TELA';
     --
     IF v_qt = 0 THEN
      INSERT INTO notifica_config
       (notifica_config_id,
        evento_config_id,
        tipo_notific,
        flag_ender_todos,
        flag_ender_papel,
        flag_usu_papel,
        flag_usu_indicado,
        flag_job_criador,
        flag_job_respint,
        flag_os_solicit,
        flag_os_distr,
        flag_os_exec,
        flag_emails)
      VALUES
       (seq_notifica_config.nextval,
        v_evento_config_id,
        'TELA',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N',
        'N');
     END IF;
    END LOOP; -- fim do loop por tipo de OS
    --
   END IF; -- fim do IF r_ev.cod_objeto = 'ORDEM_SERVICO'
  END LOOP; -- fim do loop por evento
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
     'evento_pkg.carregar',
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
     'evento_pkg.carregar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END carregar;
 --
 --
 PROCEDURE config_padrao_criar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia             ProcessMind     DATA: 05/08/2013
  -- DESCRICAO: subrotina que cria registros de configuracao padrao para notificacoes de
  --   um determinado evento x empresa. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/07/2014  Novo parametro para enventos por tipo de OS
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_evento_id         IN evento.evento_id%TYPE,
  p_tipo_os_id        IN evento_config.tipo_os_id%TYPE,
  p_evento_config_id  OUT evento_config.evento_config_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_evento_config_id evento_config.evento_config_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- gera configuracao padrao
  ------------------------------------------------------------
  SELECT seq_evento_config.nextval
    INTO v_evento_config_id
    FROM dual;
  --
  INSERT INTO evento_config
   (evento_config_id,
    empresa_id,
    evento_id,
    tipo_os_id,
    flag_historico,
    flag_notifica_email,
    flag_notifica_tela)
  VALUES
   (v_evento_config_id,
    p_empresa_id,
    p_evento_id,
    zvl(p_tipo_os_id, NULL),
    'S',
    'N',
    'N');
  --
  INSERT INTO notifica_config
   (notifica_config_id,
    evento_config_id,
    tipo_notific,
    flag_ender_todos,
    flag_ender_papel,
    flag_usu_papel,
    flag_usu_indicado,
    flag_job_criador,
    flag_job_respint,
    flag_os_solicit,
    flag_os_distr,
    flag_os_exec,
    flag_emails)
  VALUES
   (seq_notifica_config.nextval,
    v_evento_config_id,
    'EMAIL',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N');
  --
  INSERT INTO notifica_config
   (notifica_config_id,
    evento_config_id,
    tipo_notific,
    flag_ender_todos,
    flag_ender_papel,
    flag_usu_papel,
    flag_usu_indicado,
    flag_job_criador,
    flag_job_respint,
    flag_os_solicit,
    flag_os_distr,
    flag_os_exec,
    flag_emails)
  VALUES
   (seq_notifica_config.nextval,
    v_evento_config_id,
    'TELA',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N',
    'N');
  --
  p_evento_config_id := v_evento_config_id;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := 'Geração de evento: ' ||
                 substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
 END config_padrao_criar;
 --
 --
 PROCEDURE config_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                 ProcessMind     DATA: 05/08/2013
  -- DESCRICAO: Atualizacao da configuracao de notificacao do evento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/01/2014  Novos parametros para produtor de carta acordo
  -- Silvia            23/07/2014  Novos parametros para aprovador de OS
  -- Silvia            25/07/2014  Novo parametro para enventos por tipo de OS
  -- Silvia            05/09/2014  Novos parametros p/ criador e responsavel por CONTRATO
  -- Silvia            19/05/2015  Novo parametro classe do evento
  -- Silvia            15/07/2015  Novos parametros para criador e aprovador de estimativa
  -- Silvia            31/10/2016  Novos parametros para criador e aprovador do documento
  -- Silvia            28/03/2017  Novos parametros para aprovador de briefing
  -- Silvia            17/05/2017  Novo parametro para papeis que recebem notif de ender.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN evento_config.empresa_id%TYPE,
  p_evento_id              IN evento_config.evento_id%TYPE,
  p_classe_evento          IN evento.classe%TYPE,
  p_tipo_os_id             IN evento_config.tipo_os_id%TYPE,
  p_flag_historico         IN evento_config.flag_historico%TYPE,
  p_flag_notifica_tela     IN evento_config.flag_notifica_tela%TYPE,
  p_nt_flag_ender_todos    IN VARCHAR2,
  p_nt_flag_ender_papel    IN VARCHAR2,
  p_nt_vetor_ender_papel   IN VARCHAR2,
  p_nt_flag_usu_papel      IN VARCHAR2,
  p_nt_vetor_usu_papel     IN VARCHAR2,
  p_nt_flag_usu_indicado   IN VARCHAR2,
  p_nt_vetor_usu_indicado  IN VARCHAR2,
  p_nt_flag_job_criador    IN VARCHAR2,
  p_nt_flag_job_respint    IN VARCHAR2,
  p_nt_flag_ca_produtor    IN VARCHAR2,
  p_nt_flag_os_solicit     IN VARCHAR2,
  p_nt_flag_os_distr       IN VARCHAR2,
  p_nt_flag_os_exec        IN VARCHAR2,
  p_nt_flag_os_aprov       IN VARCHAR2,
  p_nt_flag_ctr_criador    IN VARCHAR2,
  p_nt_flag_ctr_respint    IN VARCHAR2,
  p_nt_flag_ad_criador     IN VARCHAR2,
  p_nt_flag_ad_solicit     IN VARCHAR2,
  p_nt_flag_ad_aprov       IN VARCHAR2,
  p_nt_flag_est_criador    IN VARCHAR2,
  p_nt_flag_est_aprov      IN VARCHAR2,
  p_nt_flag_doc_criador    IN VARCHAR2,
  p_nt_flag_doc_aprov      IN VARCHAR2,
  p_nt_flag_bri_aprov      IN VARCHAR2,
  p_nt_flag_pa_notif_ender IN VARCHAR2,
  p_flag_notifica_email    IN evento_config.flag_notifica_email%TYPE,
  p_ne_flag_ender_todos    IN VARCHAR2,
  p_ne_flag_ender_papel    IN VARCHAR2,
  p_ne_vetor_ender_papel   IN VARCHAR2,
  p_ne_flag_usu_papel      IN VARCHAR2,
  p_ne_vetor_usu_papel     IN VARCHAR2,
  p_ne_flag_usu_indicado   IN VARCHAR2,
  p_ne_vetor_usu_indicado  IN VARCHAR2,
  p_ne_flag_job_criador    IN VARCHAR2,
  p_ne_flag_job_respint    IN VARCHAR2,
  p_ne_flag_ca_produtor    IN VARCHAR2,
  p_ne_flag_os_solicit     IN VARCHAR2,
  p_ne_flag_os_distr       IN VARCHAR2,
  p_ne_flag_os_exec        IN VARCHAR2,
  p_ne_flag_os_aprov       IN VARCHAR2,
  p_ne_flag_ctr_criador    IN VARCHAR2,
  p_ne_flag_ctr_respint    IN VARCHAR2,
  p_ne_flag_ad_criador     IN VARCHAR2,
  p_ne_flag_ad_solicit     IN VARCHAR2,
  p_ne_flag_ad_aprov       IN VARCHAR2,
  p_ne_flag_est_criador    IN VARCHAR2,
  p_ne_flag_est_aprov      IN VARCHAR2,
  p_ne_flag_doc_criador    IN VARCHAR2,
  p_ne_flag_doc_aprov      IN VARCHAR2,
  p_ne_flag_bri_aprov      IN VARCHAR2,
  p_ne_flag_pa_notif_ender IN VARCHAR2,
  p_ne_flag_emails         IN VARCHAR2,
  p_ne_emails              IN VARCHAR2,
  p_notif_corpo            IN VARCHAR2,
  p_email_assunto          IN VARCHAR2,
  p_email_corpo            IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_evento_config_id    evento_config.evento_config_id%TYPE;
  v_notifica_config_id  notifica_config.notifica_config_id%TYPE;
  v_tipo_notific        notifica_config.tipo_notific%TYPE;
  v_flag_ender_todos    VARCHAR2(10);
  v_flag_ender_papel    VARCHAR2(10);
  v_vetor_ender_papel   VARCHAR2(1000);
  v_flag_usu_papel      VARCHAR2(10);
  v_vetor_usu_papel     VARCHAR2(1000);
  v_flag_usu_indicado   VARCHAR2(10);
  v_vetor_usu_indicado  VARCHAR2(1000);
  v_flag_job_criador    VARCHAR2(10);
  v_flag_job_respint    VARCHAR2(10);
  v_flag_ca_produtor    VARCHAR2(10);
  v_flag_os_solicit     VARCHAR2(10);
  v_flag_os_distr       VARCHAR2(10);
  v_flag_os_exec        VARCHAR2(10);
  v_flag_os_aprov       VARCHAR2(10);
  v_flag_ctr_criador    VARCHAR2(10);
  v_flag_ctr_respint    VARCHAR2(10);
  v_flag_ad_criador     VARCHAR2(10);
  v_flag_ad_solicit     VARCHAR2(10);
  v_flag_ad_aprov       VARCHAR2(10);
  v_flag_est_criador    VARCHAR2(10);
  v_flag_est_aprov      VARCHAR2(10);
  v_flag_doc_criador    VARCHAR2(10);
  v_flag_doc_aprov      VARCHAR2(10);
  v_flag_bri_aprov      VARCHAR2(10);
  v_flag_pa_notif_ender VARCHAR2(10);
  v_flag_emails         VARCHAR2(10);
  v_emails              VARCHAR2(2000);
  v_delimitador         CHAR(1);
  v_papel_id            papel.papel_id%TYPE;
  v_usuario_id          usuario.usuario_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EVENTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('classe_evento', p_classe_evento) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Classificação do evento inválida (' || p_classe_evento || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(evento_config_id)
    INTO v_evento_config_id
    FROM evento_config
   WHERE evento_id = p_evento_id
     AND empresa_id = p_empresa_id
     AND nvl(tipo_os_id, 0) = nvl(p_tipo_os_id, 0);
  --
  IF v_evento_config_id IS NULL THEN
   evento_pkg.config_padrao_criar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_evento_id,
                                  p_tipo_os_id,
                                  v_evento_config_id,
                                  p_erro_cod,
                                  p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_historico) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag histórico inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notifica_tela) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag notifica via tela inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notifica_email) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag notifica via email inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_historico = 'N' AND p_flag_notifica_tela = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para gerar notificações, a geração do log também deve estar ativa.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_historico = 'N' AND p_flag_notifica_email = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para gerar emails, a geração do log também deve estar ativa.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_notif_corpo) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto da notificação não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_email_assunto) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O assunto do email não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_email_corpo) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do email não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE evento
     SET classe = TRIM(p_classe_evento)
   WHERE evento_id = p_evento_id;
  --
  UPDATE evento_config
     SET flag_historico      = p_flag_historico,
         flag_notifica_tela  = p_flag_notifica_tela,
         flag_notifica_email = p_flag_notifica_email,
         notif_corpo         = TRIM(p_notif_corpo),
         email_assunto       = TRIM(p_email_assunto),
         email_corpo         = TRIM(p_email_corpo)
   WHERE evento_config_id = v_evento_config_id;
  --
  v_delimitador := '|';
  --
  -- processa primeiro as configuracoes de notificacao via interface
  v_tipo_notific := 'TELA';
  --
  WHILE v_tipo_notific IN ('TELA', 'EMAIL')
  LOOP
   SELECT MAX(notifica_config_id)
     INTO v_notifica_config_id
     FROM notifica_config
    WHERE evento_config_id = v_evento_config_id
      AND tipo_notific = v_tipo_notific;
   --
   IF v_tipo_notific = 'TELA' THEN
    v_flag_ender_todos    := p_nt_flag_ender_todos;
    v_flag_ender_papel    := p_nt_flag_ender_papel;
    v_vetor_ender_papel   := p_nt_vetor_ender_papel;
    v_flag_usu_papel      := p_nt_flag_usu_papel;
    v_vetor_usu_papel     := p_nt_vetor_usu_papel;
    v_flag_usu_indicado   := p_nt_flag_usu_indicado;
    v_vetor_usu_indicado  := p_nt_vetor_usu_indicado;
    v_flag_job_criador    := p_nt_flag_job_criador;
    v_flag_job_respint    := p_nt_flag_job_respint;
    v_flag_ca_produtor    := p_nt_flag_ca_produtor;
    v_flag_os_solicit     := p_nt_flag_os_solicit;
    v_flag_os_distr       := p_nt_flag_os_distr;
    v_flag_os_exec        := p_nt_flag_os_exec;
    v_flag_os_aprov       := p_nt_flag_os_aprov;
    v_flag_ctr_criador    := p_nt_flag_ctr_criador;
    v_flag_ctr_respint    := p_nt_flag_ctr_respint;
    v_flag_ad_criador     := p_nt_flag_ad_criador;
    v_flag_ad_solicit     := p_nt_flag_ad_solicit;
    v_flag_ad_aprov       := p_nt_flag_ad_aprov;
    v_flag_est_criador    := p_nt_flag_est_criador;
    v_flag_est_aprov      := p_nt_flag_est_aprov;
    v_flag_doc_criador    := p_nt_flag_doc_criador;
    v_flag_doc_aprov      := p_nt_flag_doc_aprov;
    v_flag_bri_aprov      := p_nt_flag_bri_aprov;
    v_flag_pa_notif_ender := p_nt_flag_pa_notif_ender;
    v_flag_emails         := 'N';
    v_emails              := NULL;
   ELSE
    v_flag_ender_todos    := p_ne_flag_ender_todos;
    v_flag_ender_papel    := p_ne_flag_ender_papel;
    v_vetor_ender_papel   := p_ne_vetor_ender_papel;
    v_flag_usu_papel      := p_ne_flag_usu_papel;
    v_vetor_usu_papel     := p_ne_vetor_usu_papel;
    v_flag_usu_indicado   := p_ne_flag_usu_indicado;
    v_vetor_usu_indicado  := p_ne_vetor_usu_indicado;
    v_flag_job_criador    := p_ne_flag_job_criador;
    v_flag_job_respint    := p_ne_flag_job_respint;
    v_flag_ca_produtor    := p_ne_flag_ca_produtor;
    v_flag_os_solicit     := p_ne_flag_os_solicit;
    v_flag_os_distr       := p_ne_flag_os_distr;
    v_flag_os_exec        := p_ne_flag_os_exec;
    v_flag_os_aprov       := p_ne_flag_os_aprov;
    v_flag_ctr_criador    := p_ne_flag_ctr_criador;
    v_flag_ctr_respint    := p_ne_flag_ctr_respint;
    v_flag_ad_criador     := p_ne_flag_ad_criador;
    v_flag_ad_solicit     := p_ne_flag_ad_solicit;
    v_flag_ad_aprov       := p_ne_flag_ad_aprov;
    v_flag_est_criador    := p_ne_flag_est_criador;
    v_flag_est_aprov      := p_ne_flag_est_aprov;
    v_flag_doc_criador    := p_ne_flag_doc_criador;
    v_flag_doc_aprov      := p_ne_flag_doc_aprov;
    v_flag_bri_aprov      := p_ne_flag_bri_aprov;
    v_flag_pa_notif_ender := p_ne_flag_pa_notif_ender;
    v_flag_emails         := p_ne_flag_emails;
    v_emails              := TRIM(p_ne_emails);
   END IF;
   --
   IF flag_validar(v_flag_ender_todos) = 0 OR flag_validar(v_flag_ender_papel) = 0 OR
      flag_validar(v_flag_usu_papel) = 0 OR flag_validar(v_flag_usu_indicado) = 0 OR
      flag_validar(v_flag_job_criador) = 0 OR flag_validar(v_flag_job_respint) = 0 OR
      flag_validar(v_flag_os_solicit) = 0 OR flag_validar(v_flag_os_distr) = 0 OR
      flag_validar(v_flag_os_exec) = 0 OR flag_validar(v_flag_os_aprov) = 0 OR
      flag_validar(v_flag_emails) = 0 OR flag_validar(v_flag_ca_produtor) = 0 OR
      flag_validar(v_flag_ctr_criador) = 0 OR flag_validar(v_flag_ctr_respint) = 0 OR
      flag_validar(v_flag_ad_criador) = 0 OR flag_validar(v_flag_ad_solicit) = 0 OR
      flag_validar(v_flag_ad_aprov) = 0 OR flag_validar(v_flag_est_criador) = 0 OR
      flag_validar(v_flag_est_aprov) = 0 OR flag_validar(v_flag_doc_criador) = 0 OR
      flag_validar(v_flag_doc_aprov) = 0 OR flag_validar(v_flag_bri_aprov) = 0 OR
      flag_validar(v_flag_pa_notif_ender) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag inválido.';
    RAISE v_exception;
   END IF;
   --
   IF length(v_emails) > 500 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A lista de emails não pode ter mais que 500 caracteres.';
    RAISE v_exception;
   END IF;
   --
   UPDATE notifica_config
      SET flag_ender_todos    = v_flag_ender_todos,
          flag_ender_papel    = v_flag_ender_papel,
          flag_usu_papel      = v_flag_usu_papel,
          flag_usu_indicado   = v_flag_usu_indicado,
          flag_job_criador    = v_flag_job_criador,
          flag_job_respint    = v_flag_job_respint,
          flag_ca_produtor    = v_flag_ca_produtor,
          flag_os_solicit     = v_flag_os_solicit,
          flag_os_distr       = v_flag_os_distr,
          flag_os_exec        = v_flag_os_exec,
          flag_os_aprov       = v_flag_os_aprov,
          flag_ctr_criador    = v_flag_ctr_criador,
          flag_ctr_respint    = v_flag_ctr_respint,
          flag_ad_criador     = v_flag_ad_criador,
          flag_ad_solicit     = v_flag_ad_solicit,
          flag_ad_aprov       = v_flag_ad_aprov,
          flag_est_criador    = v_flag_est_criador,
          flag_est_aprov      = v_flag_est_aprov,
          flag_doc_criador    = v_flag_doc_criador,
          flag_doc_aprov      = v_flag_doc_aprov,
          flag_bri_aprov      = v_flag_bri_aprov,
          flag_pa_notif_ender = v_flag_pa_notif_ender,
          flag_emails         = v_flag_emails,
          emails              = v_emails
    WHERE notifica_config_id = v_notifica_config_id;
   --
   --
   DELETE FROM notifica_papel
    WHERE notifica_config_id = v_notifica_config_id;
   --
   WHILE nvl(length(rtrim(v_vetor_ender_papel)), 0) > 0
   LOOP
    v_papel_id := to_number(prox_valor_retornar(v_vetor_ender_papel, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse papel não existe ou não pertence à empresa (' || to_char(v_papel_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO notifica_papel
     (notifica_config_id,
      papel_id,
      flag_usu_ender)
    VALUES
     (v_notifica_config_id,
      v_papel_id,
      'S');
   END LOOP;
   --
   WHILE nvl(length(rtrim(v_vetor_usu_papel)), 0) > 0
   LOOP
    v_papel_id := to_number(prox_valor_retornar(v_vetor_usu_papel, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse papel não existe ou não pertence à empresa (' || to_char(v_papel_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO notifica_papel
     (notifica_config_id,
      papel_id,
      flag_usu_ender)
    VALUES
     (v_notifica_config_id,
      v_papel_id,
      'N');
   END LOOP;
   --
   --
   DELETE FROM notifica_usuario
    WHERE notifica_config_id = v_notifica_config_id;
   --
   WHILE nvl(length(rtrim(v_vetor_usu_indicado)), 0) > 0
   LOOP
    v_usuario_id := to_number(prox_valor_retornar(v_vetor_usu_indicado, v_delimitador));
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM usuario
     WHERE usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse usuário não existe(' || to_char(v_usuario_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO notifica_usuario
     (notifica_config_id,
      usuario_id)
    VALUES
     (v_notifica_config_id,
      v_usuario_id);
   END LOOP;
   --
   --
   IF v_tipo_notific = 'TELA' THEN
    -- chaveia para processar EMAIL
    v_tipo_notific := 'EMAIL';
   ELSE
    v_tipo_notific := NULL;
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
 END config_atualizar;
 --
 --
 PROCEDURE notifica_atraso_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/01/2015
  -- DESCRICAO: procedure que gera eventos para notificacoes de atraso (para ser chamada
  --    diariamente via job). Roda via Cold Fusion as 05:00h.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/05/2015  Novas notificacoes (tarefa, projeto, OS).
  -- Silvia            16/11/2015  Novo atraso em OS (am aprovacao)
  -- Silvia            09/03/2020  Nova notificacao de renovacao de contrato.
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_data_ref         DATE;
  v_lbl_job          VARCHAR2(100);
  --
  -- cursor para atrasos em cronograma
  CURSOR c_cr IS
  -- tarefas atrasadas
   SELECT jo.empresa_id,
          jo.job_id,
          cr.cronograma_id,
          jo.numero        AS num_job,
          cr.numero        AS num_crono
     FROM cronograma cr,
          job        jo,
          item_crono it,
          tarefa     ta
    WHERE cr.job_id = jo.job_id
      AND cr.cronograma_id = it.cronograma_id
      AND it.objeto_id = ta.tarefa_id
      AND it.cod_objeto = 'TAREFA'
      AND ta.status NOT IN ('CONC', 'CANC')
      AND it.data_planej_fim < trunc(SYSDATE)
   UNION
   SELECT jo.empresa_id,
          jo.job_id,
          cr.cronograma_id,
          jo.numero        AS num_job,
          cr.numero        AS num_crono
     FROM cronograma    cr,
          job           jo,
          item_crono    it,
          ordem_servico os
    WHERE cr.job_id = jo.job_id
      AND cr.cronograma_id = it.cronograma_id
      AND it.objeto_id = os.ordem_servico_id
      AND it.cod_objeto = 'DOCUMENTO'
      AND os.status NOT IN ('CONC', 'CANC')
      AND it.data_planej_fim < trunc(SYSDATE)
   UNION
   SELECT jo.empresa_id,
          jo.job_id,
          cr.cronograma_id,
          jo.numero        AS num_job,
          cr.numero        AS num_crono
     FROM cronograma cr,
          job        jo,
          item_crono it,
          documento  dc
    WHERE cr.job_id = jo.job_id
      AND cr.cronograma_id = it.cronograma_id
      AND it.objeto_id = dc.documento_id
      AND it.cod_objeto = 'DOCUMENTO'
      AND dc.status NOT IN ('OK')
      AND it.data_planej_fim < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em aprovacao de adiantamento
  CURSOR c_ad1 IS
   SELECT jo.empresa_id,
          jo.job_id,
          ad.adiant_desp_id,
          moeda_mostrar(ad.valor_solicitado, 'S') AS valor_solicitado_char,
          adiant_desp_pkg.numero_formatar(ad.adiant_desp_id, 'S') AS num_adiant_char
     FROM adiant_desp ad,
          job         jo
    WHERE ad.job_id = jo.job_id
      AND ad.status IN ('EMAP', 'REPR')
      AND ad.data_limite < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em execucao de adiantamento
  CURSOR c_ad2 IS
   SELECT jo.empresa_id,
          jo.job_id,
          ad.adiant_desp_id,
          moeda_mostrar(ad.valor_solicitado, 'S') AS valor_solicitado_char,
          adiant_desp_pkg.numero_formatar(ad.adiant_desp_id, 'S') AS num_adiant_char
     FROM adiant_desp ad,
          job         jo
    WHERE ad.job_id = jo.job_id
      AND ad.status = 'APRO'
      AND ad.data_limite < trunc(SYSDATE)
      AND adiant_desp_pkg.valor_retornar(ad.adiant_desp_id, 'DISPONIVEL') > 0
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em prestacao de contas de adiantamento
  CURSOR c_ad3 IS
   SELECT jo.empresa_id,
          jo.job_id,
          ad.adiant_desp_id,
          moeda_mostrar(ad.valor_solicitado, 'S') AS valor_solicitado_char,
          adiant_desp_pkg.numero_formatar(ad.adiant_desp_id, 'S') AS num_adiant_char
     FROM adiant_desp ad,
          job         jo
    WHERE ad.job_id = jo.job_id
      AND ad.status IN ('APRO', 'PCON')
      AND ad.data_limite < trunc(SYSDATE)
      AND adiant_desp_pkg.valor_retornar(ad.adiant_desp_id, 'CONTA_PRESTAR') <> 0
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em TAREFA
  CURSOR c_ta IS
   SELECT ta.empresa_id,
          jo.job_id,
          ta.tarefa_id,
          ta.descricao,
          jo.numero AS num_job
     FROM tarefa ta,
          job    jo
    WHERE ta.job_id = jo.job_id(+)
      AND ta.status IN ('EMEX', 'RECU')
      AND ta.data_termino < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em JOB
  CURSOR c_jo IS
   SELECT jo.empresa_id,
          jo.job_id,
          jo.numero AS num_job
     FROM job jo
    WHERE jo.status IN ('PREP', 'ANDA')
      AND jo.data_prev_fim < trunc(SYSDATE)
    ORDER BY 1,
             2;
  --
  -- cursor para atrasos em OS com o executor (prazo interno)
  CURSOR c_os1 IS
   SELECT jo.empresa_id,
          jo.job_id,
          os.ordem_servico_id,
          ordem_servico_pkg.numero_formatar(os.ordem_servico_id) AS num_os
     FROM ordem_servico os,
          job           jo
    WHERE os.job_id = jo.job_id
      AND os.status IN ('ACEI', 'EMEX')
      AND os.data_interna < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em OS com o solicitante (prazo solicitado)
  CURSOR c_os2 IS
   SELECT jo.empresa_id,
          jo.job_id,
          os.ordem_servico_id,
          ordem_servico_pkg.numero_formatar(os.ordem_servico_id) AS num_os
     FROM ordem_servico os,
          job           jo
    WHERE os.job_id = jo.job_id
      AND (os.status IN ('PREP', 'EXEC') OR os.flag_recusada = 'S')
      AND os.data_solicitada < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em OS em aprovacao (prazo solicitado)
  CURSOR c_os3 IS
   SELECT jo.empresa_id,
          jo.job_id,
          os.ordem_servico_id,
          ordem_servico_pkg.numero_formatar(os.ordem_servico_id) AS num_os
     FROM ordem_servico os,
          job           jo
    WHERE os.job_id = jo.job_id
      AND os.status = 'EMAP'
      AND os.data_solicitada < trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em OPORTUNIDADE
  -- NOTIFICAR2 -> Necessidade de realizar Follow-up
  -- NOTIFICAR3 -> Data de fechamento atingiga
  CURSOR c_op1 IS
   SELECT 'NOTIFICAR2' AS cod_acao,
          op.empresa_id,
          op.oportunidade_id,
          op.numero AS num_oport
     FROM oportunidade op
    WHERE op.status IN ('PREP', 'ANDA')
      AND op.data_prox_int <= trunc(SYSDATE)
   UNION
   SELECT 'NOTIFICAR3' AS cod_acao,
          op.empresa_id,
          op.oportunidade_id,
          op.numero AS num_oport
     FROM oportunidade op
    WHERE op.status IN ('PREP', 'ANDA')
      AND op.data_prov_fech <= trunc(SYSDATE)
    ORDER BY 1,
             2,
             3;
  --
  -- cursor para atrasos em CONTRATO
  CURSOR c_co IS
   SELECT co.contrato_id,
          co.empresa_id,
          co.numero
     FROM contrato co
    WHERE co.status = 'ANDA'
      AND to_number(empresa_pkg.parametro_retornar(co.empresa_id, 'NUM_DIAS_NOTIF_RENOV_CTR')) > 0
      AND trunc(co.data_termino) -
          to_number(empresa_pkg.parametro_retornar(co.empresa_id, 'NUM_DIAS_NOTIF_RENOV_CTR')) =
          trunc(SYSDATE)
    ORDER BY 1;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - CRONOGRAMA
  ------------------------------------------------------------
  FOR r_cr IN c_cr
  LOOP
   v_identif_objeto := to_char(r_cr.num_job) || '/' || to_char(r_cr.num_crono);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_cr.empresa_id,
                    'CRONOGRAMA',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_cr.cronograma_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - ADIANTAMENTO
  ------------------------------------------------------------
  -- atraso em aprovacao de adiant
  FOR r_ad IN c_ad1
  LOOP
   v_identif_objeto := r_ad.num_adiant_char;
   v_compl_histor   := 'Valor solicitado: ' || r_ad.valor_solicitado_char;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_ad.empresa_id,
                    'ADIANT_DESP',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_ad.adiant_desp_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- atraso em execucao de adiant
  FOR r_ad IN c_ad2
  LOOP
   v_identif_objeto := r_ad.num_adiant_char;
   v_compl_histor   := 'Valor solicitado: ' || r_ad.valor_solicitado_char;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_ad.empresa_id,
                    'ADIANT_DESP',
                    'NOTIFICAR2',
                    v_identif_objeto,
                    r_ad.adiant_desp_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- atraso em prestacao de contas de adiant
  FOR r_ad IN c_ad3
  LOOP
   -- verifica a menor data de fecham do check-in
   SELECT MIN(oc.data_prev_fec_check)
     INTO v_data_ref
     FROM item_adiant ia,
          item        it,
          orcamento   oc
    WHERE ia.adiant_desp_id = r_ad.adiant_desp_id
      AND ia.item_id = it.item_id
      AND it.orcamento_id = oc.orcamento_id;
   --
   IF v_data_ref < trunc(SYSDATE) THEN
    v_identif_objeto := r_ad.num_adiant_char;
    v_compl_histor   := 'Valor solicitado: ' || r_ad.valor_solicitado_char;
    --
    evento_pkg.gerar(v_usuario_admin_id,
                     r_ad.empresa_id,
                     'ADIANT_DESP',
                     'NOTIFICAR3',
                     v_identif_objeto,
                     r_ad.adiant_desp_id,
                     v_compl_histor,
                     NULL,
                     'N',
                     NULL,
                     NULL,
                     v_historico_id,
                     v_erro_cod,
                     v_erro_msg);
    --
    IF v_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - TAREFA
  ------------------------------------------------------------
  FOR r_ta IN c_ta
  LOOP
   v_lbl_job := empresa_pkg.parametro_retornar(r_ta.empresa_id, 'LABEL_JOB_SINGULAR');
   --
   IF r_ta.job_id IS NOT NULL THEN
    v_identif_objeto := v_lbl_job || ' ' || r_ta.num_job || ': ' ||
                        substr(TRIM(r_ta.descricao), 1, 100);
   ELSE
    v_identif_objeto := substr(TRIM(r_ta.descricao), 1, 100);
   END IF;
   --
   v_compl_histor := substr(TRIM(r_ta.descricao), 1, 500);
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_ta.empresa_id,
                    'TAREFA',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_ta.tarefa_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - JOB
  ------------------------------------------------------------
  FOR r_jo IN c_jo
  LOOP
   v_identif_objeto := to_char(r_jo.num_job);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_jo.empresa_id,
                    'JOB',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_jo.job_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - ORDEM_SERVICO
  ------------------------------------------------------------
  -- atrasos em OS com o executor (prazo interno)
  FOR r_os1 IN c_os1
  LOOP
   v_identif_objeto := r_os1.num_os;
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_os1.empresa_id,
                    'ORDEM_SERVICO',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_os1.ordem_servico_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- atrasos em OS com o solicitante (prazo solicitado)
  FOR r_os2 IN c_os2
  LOOP
   v_identif_objeto := r_os2.num_os;
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_os2.empresa_id,
                    'ORDEM_SERVICO',
                    'NOTIFICAR2',
                    v_identif_objeto,
                    r_os2.ordem_servico_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  -- atrasos em OS em aprovacao (prazo solicitado)
  FOR r_os3 IN c_os3
  LOOP
   v_identif_objeto := r_os3.num_os;
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_os3.empresa_id,
                    'ORDEM_SERVICO',
                    'NOTIFICAR4',
                    v_identif_objeto,
                    r_os3.ordem_servico_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - OPORTUNIDADE
  ------------------------------------------------------------
  FOR r_op1 IN c_op1
  LOOP
   v_identif_objeto := r_op1.num_oport;
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_op1.empresa_id,
                    'OPORTUNIDADE',
                    r_op1.cod_acao,
                    v_identif_objeto,
                    r_op1.oportunidade_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes - CONTRATO
  ------------------------------------------------------------
  FOR r_co IN c_co
  LOOP
   v_identif_objeto := to_char(r_co.numero);
   v_compl_histor   := NULL;
   --
   evento_pkg.gerar(v_usuario_admin_id,
                    r_co.empresa_id,
                    'CONTRATO',
                    'NOTIFICAR',
                    v_identif_objeto,
                    r_co.contrato_id,
                    v_compl_histor,
                    NULL,
                    'N',
                    NULL,
                    NULL,
                    v_historico_id,
                    v_erro_cod,
                    v_erro_msg);
   --
   IF v_erro_cod <> '00000' THEN
    RAISE v_exception;
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
     'evento_pkg.notifica_atraso_gerar',
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
     'evento_pkg.notifica_atraso_gerar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END notifica_atraso_gerar;
 --
 --
 PROCEDURE notifica_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/08/2013
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a processar a fila
  --   de notificacoes pendentes. Roda via Cold Fusion de minuto em minuto.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/12/2013  Fechamento automatico de notificacoes nao lidas.
  -- Silvia            23/07/2014  Notificacao p/ aprovador de OS
  -- Silvia            05/09/2014  Notificacao p/ criador e responsavel de CONTRATO
  -- Silvia            26/05/2015  Notificacao p/ usuarios avulsos
  -- Silvia            15/07/2015  Notificacao p/ criador e aprovador de estimativa
  -- Silvia            03/12/2015  Novo curinga job_numero
  -- Silvia            31/10/2016  Notificacao p/ criador e aprovador de documento
  -- Silvia            28/03/2017  Notificacao para aprovador do briefing
  -- Silvia            06/10/2017  Troca de Job por label do parametro na descr do evento
  -- Silvia            05/07/2018  Retirada do processamento de marcar notificacoes antigas
  --                               como lidas.
  -- Silvia            03/10/2018  Notificacao de inativacao automatica de usuario.
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  -- Silvia            06/12/2019  Eliminacao de oport_usuario_papel e contrato_usuario_papel
  -- Silvia            27/01/2020  Novos coringas para contrato e oportunidade
  -- Silvia            26/05/2020  Generalizacao do coringa cliente
  -- Silvia            15/06/2020  Alteracao em notificacao p/ distribuidor de OS
  -- Silvia            27/08/2020  Retirada do autor do evento do texto padrão da
  --                               notificacao via tela (a interface ja mostra)
  -- Ana Luiza         22/10/2024  Adicionado informacoes da tarefa
  ------------------------------------------------------------------------------------------
  IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_erro_cod               VARCHAR2(20);
  v_erro_msg               VARCHAR2(200);
  v_data_atual             DATE;
  v_flag_notifica_tela     evento_config.flag_notifica_tela%TYPE;
  v_flag_notifica_email    evento_config.flag_notifica_email%TYPE;
  v_notifica_config_id     notifica_config.notifica_config_id%TYPE;
  v_nt_notifica_config_id  notifica_config.notifica_config_id%TYPE;
  v_nt_flag_ender_todos    notifica_config.flag_ender_todos%TYPE;
  v_nt_flag_ender_papel    notifica_config.flag_ender_papel%TYPE;
  v_nt_flag_usu_papel      notifica_config.flag_usu_papel%TYPE;
  v_nt_flag_usu_indicado   notifica_config.flag_usu_indicado%TYPE;
  v_nt_flag_job_criador    notifica_config.flag_job_criador%TYPE;
  v_nt_flag_job_respint    notifica_config.flag_job_respint%TYPE;
  v_nt_flag_os_solicit     notifica_config.flag_os_solicit%TYPE;
  v_nt_flag_os_distr       notifica_config.flag_os_distr%TYPE;
  v_nt_flag_os_exec        notifica_config.flag_os_exec%TYPE;
  v_nt_flag_os_aprov       notifica_config.flag_os_aprov%TYPE;
  v_nt_flag_ca_produtor    notifica_config.flag_ca_produtor%TYPE;
  v_nt_flag_ctr_criador    notifica_config.flag_ctr_criador%TYPE;
  v_nt_flag_ctr_respint    notifica_config.flag_ctr_respint%TYPE;
  v_nt_flag_ad_criador     notifica_config.flag_ad_criador%TYPE;
  v_nt_flag_ad_solicit     notifica_config.flag_ad_solicit%TYPE;
  v_nt_flag_ad_aprov       notifica_config.flag_ad_aprov%TYPE;
  v_nt_flag_est_criador    notifica_config.flag_est_criador%TYPE;
  v_nt_flag_est_aprov      notifica_config.flag_est_aprov%TYPE;
  v_nt_flag_doc_criador    notifica_config.flag_doc_criador%TYPE;
  v_nt_flag_doc_aprov      notifica_config.flag_doc_aprov%TYPE;
  v_nt_flag_bri_aprov      notifica_config.flag_bri_aprov%TYPE;
  v_nt_flag_pa_notif_ender notifica_config.flag_pa_notif_ender%TYPE;
  v_ne_notifica_config_id  notifica_config.notifica_config_id%TYPE;
  v_ne_flag_ender_todos    notifica_config.flag_ender_todos%TYPE;
  v_ne_flag_ender_papel    notifica_config.flag_ender_papel%TYPE;
  v_ne_flag_usu_papel      notifica_config.flag_usu_papel%TYPE;
  v_ne_flag_usu_indicado   notifica_config.flag_usu_indicado%TYPE;
  v_ne_flag_job_criador    notifica_config.flag_job_criador%TYPE;
  v_ne_flag_job_respint    notifica_config.flag_job_respint%TYPE;
  v_ne_flag_os_solicit     notifica_config.flag_os_solicit%TYPE;
  v_ne_flag_os_distr       notifica_config.flag_os_distr%TYPE;
  v_ne_flag_os_exec        notifica_config.flag_os_exec%TYPE;
  v_ne_flag_os_aprov       notifica_config.flag_os_aprov%TYPE;
  v_ne_flag_ca_produtor    notifica_config.flag_ca_produtor%TYPE;
  v_ne_flag_ctr_criador    notifica_config.flag_ctr_criador%TYPE;
  v_ne_flag_ctr_respint    notifica_config.flag_ctr_respint%TYPE;
  v_ne_flag_ad_criador     notifica_config.flag_ad_criador%TYPE;
  v_ne_flag_ad_solicit     notifica_config.flag_ad_solicit%TYPE;
  v_ne_flag_ad_aprov       notifica_config.flag_ad_aprov%TYPE;
  v_ne_flag_est_criador    notifica_config.flag_est_criador%TYPE;
  v_ne_flag_est_aprov      notifica_config.flag_est_aprov%TYPE;
  v_ne_flag_doc_criador    notifica_config.flag_doc_criador%TYPE;
  v_ne_flag_doc_aprov      notifica_config.flag_doc_aprov%TYPE;
  v_ne_flag_bri_aprov      notifica_config.flag_bri_aprov%TYPE;
  v_ne_flag_pa_notif_ender notifica_config.flag_pa_notif_ender%TYPE;
  v_ne_flag_emails         notifica_config.flag_emails%TYPE;
  v_empresa_id             notifica_fila.empresa_id%TYPE;
  v_notifica_fila_id       notifica_fila.notifica_fila_id%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_complemento            historico.complemento%TYPE;
  v_justificativa          historico.justificativa%TYPE;
  v_assunto                VARCHAR2(1000);
  v_corpo                  VARCHAR2(10000);
  v_texto                  VARCHAR2(10000);
  v_usuario_de_id          notifica_fila.usuario_de_id%TYPE;
  v_usuario_id             usuario.usuario_id%TYPE;
  v_usu_apelido            pessoa.apelido%TYPE;
  v_classe                 comentario.classe%TYPE;
  v_comentario_id          comentario.comentario_id%TYPE;
  v_emails                 VARCHAR2(32000);
  v_job_id                 job.job_id%TYPE;
  v_job_nome               job.nome%TYPE;
  v_job_numero             job.numero%TYPE;
  v_cronograma_numero      VARCHAR2(100);
  v_os_numero              VARCHAR2(100);
  v_doc_nome               VARCHAR2(200);
  v_cliente_apelido        pessoa.apelido%TYPE;
  v_ordem_servico_id       ordem_servico.ordem_servico_id%TYPE;
  v_os_evento_id           os_evento.os_evento_id%TYPE;
  v_flag_estim             os_evento.flag_estim%TYPE;
  v_flag_faixa_aprov       tipo_os.flag_faixa_aprov%TYPE;
  v_tarefa_id              tarefa.tarefa_id%TYPE;
  v_carta_acordo_id        carta_acordo.carta_acordo_id%TYPE;
  v_contrato_id            contrato.contrato_id%TYPE;
  v_orcamento_id           orcamento.orcamento_id%TYPE;
  v_adiant_desp_id         adiant_desp.adiant_desp_id%TYPE;
  v_documento_id           documento.documento_id%TYPE;
  v_oportunidade_id        oportunidade.oportunidade_id%TYPE;
  v_cod_priv               privilegio.codigo%TYPE;
  v_contrato_nome          contrato.nome%TYPE;
  v_contrato_numero        VARCHAR2(40);
  v_oport_nome             oportunidade.nome%TYPE;
  v_oport_numero           oportunidade.numero%TYPE;
  v_liga_solic             NUMBER(5);
  v_liga_distr             NUMBER(5);
  v_liga_distr_cpriv       NUMBER(5);
  v_liga_exec              NUMBER(5);
  v_liga_aprov_cpriv       NUMBER(5);
  v_liga_aprov_davez       NUMBER(5);
  v_liga_tudo              NUMBER(5);
  v_liga_usu_sessao        NUMBER(5);
  v_liga_doc_cria          NUMBER(5);
  v_liga_doc_aprov         NUMBER(5);
  v_lbl_job                VARCHAR2(100);
  v_texto_adicional        VARCHAR2(100);
  v_desc_evento            VARCHAR2(200);
  v_nome_objeto            VARCHAR2(200);
  v_flag_notifica_ender    VARCHAR2(10);
  --ALCBO_221024
  v_tarefa_numero    VARCHAR2(100);
  v_tarefa_desc      tarefa.descricao%TYPE;
  v_tarefa_ent_desc  tarefa_tipo_produto.descricao%TYPE;
  v_tarefa_ent_compl job_tipo_produto.complemento%TYPE;
  --
  -- cursor de notificacoes pendentes
  CURSOR c_nt IS
   SELECT nf.notifica_fila_id,
          nf.empresa_id,
          nf.historico_id,
          nf.evento_config_id,
          nf.usuario_de_id,
          nf.data_evento,
          nf.cod_acao,
          nf.cod_objeto,
          nf.objeto_id,
          nf.identif_objeto,
          ec.flag_notifica_tela,
          ec.flag_notifica_email,
          ev.descricao AS desc_evento,
          pe.apelido AS usuario_de,
          tb.nome AS nome_objeto,
          TRIM(ec.notif_corpo) AS notif_corpo,
          TRIM(ec.email_assunto) AS email_assunto,
          TRIM(ec.email_corpo) AS email_corpo,
          ec.tipo_os_id
     FROM notifica_fila nf,
          evento_config ec,
          evento        ev,
          pessoa        pe,
          tipo_objeto   tb
    WHERE nf.flag_pend = 'S'
      AND nf.data_evento < v_data_atual
      AND nf.evento_config_id = ec.evento_config_id
      AND ec.evento_id = ev.evento_id
      AND nf.usuario_de_id = pe.usuario_id
      AND nf.cod_objeto = tb.codigo
    ORDER BY nf.notifica_fila_id;
  --
  -- cursor de usuarios associados a comentario
  -- (exceto o proprio usuario que fez o comentario)
  CURSOR c_co IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM coment_usuario co,
          comentario     cm,
          usuario        us,
          pessoa         pe
    WHERE cm.comentario_id = v_comentario_id
      AND cm.comentario_id = co.comentario_id
      AND co.usuario_id <> cm.usuario_id
      AND co.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id;
  --
  -- cursor de usuarios indicados
  CURSOR c_us IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM notifica_usuario nu,
          usuario          us,
          pessoa           pe
    WHERE nu.notifica_config_id = v_notifica_config_id
      AND nu.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id;
  --
  -- cursor de papeis indicados
  CURSOR c_pa IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM notifica_papel np,
          usuario_papel  up,
          usuario        us,
          pessoa         pe
    WHERE np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'N'
      AND np.papel_id = up.papel_id
      AND up.usuario_id = us.usuario_id
      AND us.usuario_id <> v_usuario_de_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id;
  --
  -- cursor de usuarios avulsos (enderecados no job, no orcamento ou
  -- avulsos indicados em transicao de OS)
  CURSOR c_av IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          nu.tipo_notifica,
          us.flag_notifica_email AS flag_recebe_email,
          nu.papel_id,
          pa.nome AS papel_nome,
          pa.flag_notif_ender
     FROM notifica_usu_avulso nu,
          usuario             us,
          pessoa              pe,
          papel               pa
    WHERE nu.historico_id = v_historico_id
      AND nu.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id <> v_usuario_de_id
      AND us.usuario_id = pe.usuario_id
      AND nu.papel_id = pa.papel_id(+);
  --
  --------------------------------------------------
  -- cursores p/ JOB
  --------------------------------------------------
  --
  -- cursor de usuarios enderecados no job
  CURSOR c_jo IS
   SELECT ju.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job_usuario ju,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ju.job_id = v_job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ju.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuarios c/ PAPEL enderecados no job
  CURSOR c_ja IS
   SELECT ju.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job_usuario    ju,
          notifica_papel np,
          usuario_papel  up,
          pessoa         pe,
          usuario        us,
          job            jo
    WHERE ju.job_id = v_job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ju.job_id = jo.job_id
      AND ju.usuario_id = up.usuario_id
      AND up.papel_id = np.papel_id
      AND np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuarios enderecados no job com privilegio no grupo JOB/JOBEND
  CURSOR c_jp IS
   SELECT ju.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job_usuario ju,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ju.job_id = v_job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND usuario_pkg.priv_verificar(ju.usuario_id, v_cod_priv, v_job_id, NULL, v_empresa_id) = 1
      AND ju.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuarios responsaveis internos do job
  CURSOR c_ri IS
   SELECT ju.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job_usuario ju,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ju.job_id = v_job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ju.flag_responsavel = 'S'
      AND ju.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuarios enderecados no job com privilegio no grupo ORCEND
  CURSOR c_op IS
   SELECT ju.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job_usuario ju,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ju.job_id = v_job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ju.job_id = jo.job_id
      AND EXISTS (SELECT 1
             FROM orcamento oc
            WHERE oc.job_id = jo.job_id
              AND usuario_pkg.priv_verificar(ju.usuario_id,
                                             v_cod_priv,
                                             oc.orcamento_id,
                                             NULL,
                                             v_empresa_id) = 1)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuario criador do job
  CURSOR c_js IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM job     jo,
          pessoa  pe,
          usuario us
    WHERE jo.job_id = v_job_id
      AND jo.usuario_solic_id <> v_usuario_de_id
      AND jo.usuario_solic_id = pe.usuario_id
      AND jo.usuario_solic_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  --------------------------------------------------
  -- cursores p/ ORCAMENTO
  --------------------------------------------------
  --
  -- cursor de usuario criador da estimativa
  CURSOR c_oc IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM orcamento oc,
          job       jo,
          pessoa    pe,
          usuario   us
    WHERE oc.orcamento_id = v_orcamento_id
      AND oc.job_id = jo.job_id
      AND oc.usuario_autor_id <> v_usuario_de_id
      AND oc.usuario_autor_id = pe.usuario_id
      AND oc.usuario_autor_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  --------------------------------------------------
  -- cursores p/ DOCUMENTO
  --------------------------------------------------
  --
  -- usuario criador do documento
  CURSOR c_dc IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM documento dc,
          job       jo,
          pessoa    pe,
          usuario   us
    WHERE dc.documento_id = v_documento_id
      AND dc.job_id = jo.job_id
      AND dc.usuario_id <> v_usuario_de_id
      AND dc.usuario_id = pe.usuario_id
      AND dc.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND v_liga_doc_cria = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- usuario aprovador do documento
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM documento     dc,
          job           jo,
          pessoa        pe,
          usuario       us,
          job_usuario   ju,
          usuario_papel up
    WHERE dc.documento_id = v_documento_id
      AND dc.job_id = jo.job_id
      AND dc.job_id = ju.job_id
      AND ju.usuario_id <> v_usuario_de_id
      AND ju.usuario_id = pe.usuario_id
      AND ju.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ju.usuario_id = up.usuario_id
      AND usuario_pkg.priv_verificar(ju.usuario_id,
                                     'DOCUMENTO_V',
                                     dc.job_id,
                                     dc.tipo_documento_id,
                                     v_empresa_id) = 1
      AND EXISTS (SELECT 1
             FROM task ta
            WHERE ta.job_id = jo.job_id
              AND ta.objeto_id = dc.documento_id
              AND ta.papel_resp_id = up.papel_id)
      AND v_liga_doc_aprov = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  --------------------------------------------------
  -- cursores p/ CONTRATO
  --------------------------------------------------
  --
  -- cursor de usuario criador do contrato
  CURSOR c_ct1 IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM contrato ct,
          pessoa   pe,
          usuario  us
    WHERE ct.contrato_id = v_contrato_id
      AND ct.usuario_solic_id <> v_usuario_de_id
      AND ct.usuario_solic_id = pe.usuario_id
      AND ct.usuario_solic_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = ct.contratante_id);
  --
  -- cursor de usuarios enderecados no contrato com privilegio
  CURSOR c_ct2 IS
   SELECT cs.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM contrato_usuario cs,
          pessoa           pe,
          usuario          us,
          contrato         ct
    WHERE cs.contrato_id = v_contrato_id
      AND cs.usuario_id <> v_usuario_de_id
      AND cs.usuario_id = pe.usuario_id
      AND cs.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND usuario_pkg.priv_verificar(cs.usuario_id, v_cod_priv, v_contrato_id, NULL, v_empresa_id) = 1
      AND cs.contrato_id = ct.contrato_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = ct.contratante_id);
  --
  -- cursor de usuarios enderecados no contrato
  CURSOR c_ct3 IS
   SELECT cs.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM contrato_usuario cs,
          pessoa           pe,
          usuario          us,
          contrato         ct
    WHERE cs.contrato_id = v_contrato_id
      AND cs.usuario_id <> v_usuario_de_id
      AND cs.usuario_id = pe.usuario_id
      AND cs.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND cs.contrato_id = ct.contrato_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = ct.contratante_id);
  --
  -- cursor de usuarios enderecados no contrato com papel
  CURSOR c_ct4 IS
   SELECT cs.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM contrato_usuario cs,
          notifica_papel   np,
          usuario_papel    up,
          pessoa           pe,
          usuario          us,
          contrato         ct
    WHERE cs.contrato_id = v_contrato_id
      AND cs.usuario_id <> v_usuario_de_id
      AND cs.usuario_id = pe.usuario_id
      AND cs.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND cs.contrato_id = ct.contrato_id
      AND cs.usuario_id = up.usuario_id
      AND up.papel_id = np.papel_id
      AND np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = ct.contratante_id);
  --
  --------------------------------------------------
  -- cursores p/ ADIANTAMENTO DESPESAS
  --------------------------------------------------
  --
  -- cursor de usuario criador do adiantamento
  CURSOR c_ad1 IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM adiant_desp ad,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ad.adiant_desp_id = v_adiant_desp_id
      AND ad.job_id = jo.job_id
      AND ad.criador_id <> v_usuario_de_id
      AND ad.criador_id = pe.usuario_id
      AND ad.criador_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuario solicitante do adiantamento
  CURSOR c_ad2 IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM adiant_desp ad,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ad.adiant_desp_id = v_adiant_desp_id
      AND ad.job_id = jo.job_id
      AND ad.solicitante_id <> v_usuario_de_id
      AND ad.solicitante_id = pe.usuario_id
      AND ad.solicitante_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  -- cursor de usuario aprovador do adiantamento
  CURSOR c_ad3 IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM adiant_desp ad,
          pessoa      pe,
          usuario     us,
          job         jo
    WHERE ad.adiant_desp_id = v_adiant_desp_id
      AND ad.job_id = jo.job_id
      AND ad.aprovador_id <> v_usuario_de_id
      AND ad.aprovador_id = pe.usuario_id
      AND ad.aprovador_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  --------------------------------------------------
  -- cursor de usuario produtor da carta acordo
  --------------------------------------------------
  CURSOR c_ca IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM carta_acordo ca,
          job          jo,
          pessoa       pe,
          usuario      us
    WHERE ca.carta_acordo_id = v_carta_acordo_id
      AND ca.job_id = jo.job_id(+)
      AND ca.produtor_id <> v_usuario_de_id
      AND ca.produtor_id = pe.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = ca.cliente_id);
  --
  --------------------------------------------------
  -- cursor de usuarios enderecados na OS
  --------------------------------------------------
  CURSOR c_os IS
  -- solicitante (enderecado na OS)
   SELECT os.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM os_usuario    os,
          pessoa        pe,
          usuario       us,
          ordem_servico oo,
          job           jo
    WHERE os.ordem_servico_id = v_ordem_servico_id
      AND os.tipo_ender = 'SOL'
      AND os.usuario_id <> v_usuario_de_id
      AND os.usuario_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND v_liga_solic = 1
      AND os.ordem_servico_id = oo.ordem_servico_id
      AND oo.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- distribuidores (enderecados na OS)
   SELECT os.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM os_usuario    os,
          pessoa        pe,
          usuario       us,
          ordem_servico oo,
          job           jo
    WHERE os.ordem_servico_id = v_ordem_servico_id
      AND os.tipo_ender = 'DIS'
      AND os.usuario_id <> v_usuario_de_id
      AND os.usuario_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND v_liga_distr = 1
      AND os.ordem_servico_id = oo.ordem_servico_id
      AND oo.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- distribuidor (com privilegio de distribuir)
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM ordem_servico oo,
          pessoa        pe,
          usuario       us,
          job           jo
    WHERE oo.ordem_servico_id = v_ordem_servico_id
      AND oo.job_id = jo.job_id
      AND usuario_pkg.priv_verificar(us.usuario_id, 'OS_DI', jo.job_id, oo.tipo_os_id, v_empresa_id) = 1
      AND us.usuario_id <> v_usuario_de_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND v_liga_distr = 1
      AND v_liga_distr_cpriv = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- executores (enderecados na OS)
   SELECT os.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM os_usuario    os,
          pessoa        pe,
          usuario       us,
          ordem_servico oo,
          job           jo
    WHERE os.ordem_servico_id = v_ordem_servico_id
      AND os.tipo_ender = 'EXE'
      AND os.usuario_id <> v_usuario_de_id
      AND os.usuario_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND v_liga_exec = 1
      AND os.ordem_servico_id = oo.ordem_servico_id
      AND oo.job_id = jo.job_id
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- aprovador (com privilegio de aprovar)
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM ordem_servico oo,
          pessoa        pe,
          usuario       us,
          job           jo
    WHERE oo.ordem_servico_id = v_ordem_servico_id
      AND oo.job_id = jo.job_id
      AND usuario_pkg.priv_verificar(us.usuario_id, 'OS_AP', jo.job_id, oo.tipo_os_id, v_empresa_id) = 1
      AND us.usuario_id <> v_usuario_de_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND v_liga_aprov_cpriv = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- aprovador da vez
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM ordem_servico oo,
          pessoa        pe,
          usuario       us,
          job           jo,
          tipo_os       ti
    WHERE oo.ordem_servico_id = v_ordem_servico_id
      AND oo.job_id = jo.job_id
         --AND usuario_pkg.priv_verificar(us.usuario_id,'OS_AP',jo.job_id,oo.tipo_os_id,v_empresa_id) = 1
      AND ordem_servico_pkg.faixa_aprov_verificar(us.usuario_id, v_empresa_id, v_ordem_servico_id) = 1
      AND us.usuario_id <> v_usuario_de_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND oo.tipo_os_id = ti.tipo_os_id
      AND ti.flag_faixa_aprov = 'S'
      AND v_liga_aprov_davez = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id)
   UNION
   -- usuario da sessao (autor do evento)
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM ordem_servico oo,
          pessoa        pe,
          usuario       us,
          job           jo
    WHERE oo.ordem_servico_id = v_ordem_servico_id
      AND oo.job_id = jo.job_id
      AND us.usuario_id = v_usuario_de_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.flag_admin = 'N'
      AND v_liga_usu_sessao = 1
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.job_id = jo.job_id)
      AND NOT EXISTS (SELECT 1
             FROM notifica_desliga nd
            WHERE nd.usuario_id = us.usuario_id
              AND nd.cliente_id = jo.cliente_id);
  --
  --------------------------------------------------
  -- cursores p/ TAREFA
  --------------------------------------------------
  -- cursor de usuarios enderecados na TAREFA
  CURSOR c_ta IS
   SELECT ta.usuario_de_id usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM tarefa  ta,
          pessoa  pe,
          usuario us
    WHERE ta.tarefa_id = v_tarefa_id
      AND ta.usuario_de_id <> v_usuario_de_id
      AND ta.usuario_de_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
   UNION
   SELECT ta.usuario_para_id usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM tarefa_usuario ta,
          pessoa         pe,
          usuario        us
    WHERE ta.tarefa_id = v_tarefa_id
      AND ta.usuario_para_id <> v_usuario_de_id
      AND ta.usuario_para_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S';
  --
  -- cursor de usuarios c/ PAPEL enderecados na TAREFA
  CURSOR c_tp IS
   SELECT ta.usuario_de_id usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM tarefa         ta,
          pessoa         pe,
          usuario        us,
          usuario_papel  up,
          notifica_papel np
    WHERE ta.tarefa_id = v_tarefa_id
      AND ta.usuario_de_id <> v_usuario_de_id
      AND ta.usuario_de_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = up.usuario_id
      AND up.papel_id = np.papel_id
      AND np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'S'
   UNION
   SELECT ta.usuario_para_id usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM tarefa_usuario ta,
          pessoa         pe,
          usuario        us,
          usuario_papel  up,
          notifica_papel np
    WHERE ta.tarefa_id = v_tarefa_id
      AND ta.usuario_para_id <> v_usuario_de_id
      AND ta.usuario_para_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
      AND us.flag_ativo = 'S'
      AND us.usuario_id = up.usuario_id
      AND up.papel_id = np.papel_id
      AND np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'S';
  --
  --------------------------------------------------
  -- cursores p/ OPORTUNIDADE
  --------------------------------------------------
  --
  -- cursor de usuarios enderecados na oportunidade
  CURSOR c_op1 IS
   SELECT DISTINCT ou.usuario_id,
                   pe.apelido AS nome_para,
                   TRIM(pe.email) AS email_para,
                   us.flag_notifica_email AS flag_recebe_email
     FROM oport_usuario ou,
          pessoa        pe,
          usuario       us,
          oportunidade  op
    WHERE ou.oportunidade_id = v_oportunidade_id
      AND ou.usuario_id <> v_usuario_de_id
      AND ou.usuario_id = pe.usuario_id
      AND ou.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ou.oportunidade_id = op.oportunidade_id;
  --
  -- cursor de usuarios enderecados na oportuniadade com papel
  CURSOR c_op2 IS
   SELECT DISTINCT ou.usuario_id,
                   pe.apelido AS nome_para,
                   TRIM(pe.email) AS email_para,
                   us.flag_notifica_email AS flag_recebe_email
     FROM oport_usuario  ou,
          notifica_papel np,
          usuario_papel  up,
          pessoa         pe,
          usuario        us,
          oportunidade   op
    WHERE ou.oportunidade_id = v_oportunidade_id
      AND ou.usuario_id <> v_usuario_de_id
      AND ou.usuario_id = pe.usuario_id
      AND ou.usuario_id = us.usuario_id
      AND us.flag_ativo = 'S'
      AND ou.oportunidade_id = op.oportunidade_id
      AND ou.usuario_id = up.usuario_id
      AND up.papel_id = np.papel_id
      AND np.notifica_config_id = v_notifica_config_id
      AND np.flag_usu_ender = 'S';
  --
 BEGIN
  v_qt         := 0;
  v_data_atual := SYSDATE;
  --
  ------------------------------------------------------------
  -- processamento da fila
  ------------------------------------------------------------
  FOR r_nt IN c_nt
  LOOP
   v_empresa_id   := r_nt.empresa_id;
   v_historico_id := r_nt.historico_id;
   --
   SELECT MAX(TRIM(complemento)),
          MAX(TRIM(justificativa))
     INTO v_complemento,
          v_justificativa
     FROM historico
    WHERE historico_id = v_historico_id;
   --
   v_usuario_de_id    := r_nt.usuario_de_id;
   v_notifica_fila_id := r_nt.notifica_fila_id;
   -- no caso de comentario direcionado a determinados usuarios,
   -- permite desligar todas as demais notificacoes configuradas.
   v_liga_tudo := 1;
   --
   -- tenta recuperar o job_id (nem todos os eventos sao relacionados a job)
   v_job_id := job_id_retornar(r_nt.cod_objeto, r_nt.objeto_id);
   -- tenta recuperar o contrato_id (nem todos os eventos sao relacionados a contrato)
   v_contrato_id := contrato_id_retornar(r_nt.cod_objeto, r_nt.objeto_id);
   --
   v_job_nome          := NULL;
   v_job_numero        := NULL;
   v_doc_nome          := NULL;
   v_cliente_apelido   := NULL;
   v_cronograma_numero := NULL;
   v_os_numero         := NULL;
   v_os_evento_id      := NULL;
   v_flag_estim        := 'N';
   v_texto_adicional   := NULL;
   v_contrato_nome     := NULL;
   v_contrato_numero   := NULL;
   v_oport_nome        := NULL;
   v_oport_numero      := NULL;
   --
   v_lbl_job := empresa_pkg.parametro_retornar(v_empresa_id, 'LABEL_JOB_SINGULAR');
   --
   IF v_job_id IS NOT NULL THEN
    SELECT MAX(jo.nome),
           MAX(jo.numero),
           MAX(cl.apelido)
      INTO v_job_nome,
           v_job_numero,
           v_cliente_apelido
      FROM job    jo,
           pessoa cl
     WHERE jo.job_id = v_job_id
       AND jo.cliente_id = cl.pessoa_id;
   END IF;
   --
   IF v_contrato_id IS NOT NULL THEN
    SELECT MAX(ct.nome),
           MAX(contrato_pkg.numero_formatar(ct.contrato_id)),
           MAX(cl.apelido)
      INTO v_contrato_nome,
           v_contrato_numero,
           v_cliente_apelido
      FROM contrato ct,
           pessoa   cl
     WHERE ct.contrato_id = v_contrato_id
       AND ct.contratante_id = cl.pessoa_id;
    --
    IF TRIM(v_contrato_numero) IS NULL THEN
     v_contrato_numero := substr(r_nt.identif_objeto, 1, 100);
    END IF;
   END IF;
   --
   IF r_nt.cod_objeto = 'CRONOGRAMA' THEN
    v_cronograma_numero := substr(r_nt.identif_objeto, 1, 100);
   END IF;
   --
   IF r_nt.cod_objeto = 'DOCUMENTO' THEN
    SELECT MAX(td.nome || ' - ' || dc.nome)
      INTO v_doc_nome
      FROM documento      dc,
           tipo_documento td
     WHERE dc.documento_id = r_nt.objeto_id
       AND dc.tipo_documento_id = td.tipo_documento_id;
   END IF;
   --
   IF r_nt.cod_objeto = 'ORDEM_SERVICO' THEN
    v_os_numero := substr(r_nt.identif_objeto, 1, 100);
    --
    SELECT MAX(os_evento_id)
      INTO v_os_evento_id
      FROM ordem_servico
     WHERE ordem_servico_id = r_nt.objeto_id;
    --
    SELECT nvl(MAX(flag_estim), 'N')
      INTO v_flag_estim
      FROM os_evento
     WHERE os_evento_id = v_os_evento_id;
    --
    IF v_flag_estim = 'S' THEN
     v_texto_adicional := ' (Estimativa)';
    ELSIF r_nt.cod_acao = 'TERMINAR' THEN
     v_texto_adicional := ' (Execução)';
    END IF;
    --
    SELECT nvl(MAX(ti.flag_faixa_aprov), 'N')
      INTO v_flag_faixa_aprov
      FROM ordem_servico os,
           tipo_os       ti
     WHERE os.ordem_servico_id = r_nt.objeto_id
       AND os.tipo_os_id = ti.tipo_os_id;
   END IF;
   --ALCBO_221024
   IF r_nt.cod_objeto = 'TAREFA' THEN
    v_tarefa_numero := substr(r_nt.identif_objeto, 1, 100);
    --
    SELECT t.descricao,
           tp.descricao    AS entregavel,
           jtp.complemento AS complemento_entreg
      INTO v_tarefa_desc,
           v_tarefa_ent_desc,
           v_tarefa_ent_compl
      FROM tarefa t
      LEFT JOIN tarefa_tipo_produto tp
        ON t.tarefa_id = tp.tarefa_id
      LEFT JOIN job_tipo_produto jtp
        ON tp.job_tipo_produto_id = jtp.job_tipo_produto_id
     WHERE t.tarefa_id = r_nt.objeto_id;
   END IF;
   --
   IF r_nt.cod_objeto = 'OPORTUNIDADE' THEN
    SELECT MAX(op.nome),
           MAX(op.numero),
           MAX(cl.apelido)
      INTO v_oport_nome,
           v_oport_numero,
           v_cliente_apelido
      FROM oportunidade op,
           pessoa       cl
     WHERE op.oportunidade_id = r_nt.objeto_id
       AND op.cliente_id = cl.pessoa_id;
   END IF;
   --
   -- recupera configuracoes para interface
   SELECT nc.notifica_config_id,
          ec.flag_notifica_tela,
          nc.flag_ender_todos,
          nc.flag_ender_papel,
          nc.flag_usu_papel,
          nc.flag_usu_indicado,
          nc.flag_job_criador,
          nc.flag_job_respint,
          nc.flag_os_solicit,
          nc.flag_os_distr,
          nc.flag_os_exec,
          nc.flag_os_aprov,
          nc.flag_ca_produtor,
          nc.flag_ctr_criador,
          nc.flag_ctr_respint,
          nc.flag_ad_criador,
          nc.flag_ad_solicit,
          nc.flag_ad_aprov,
          nc.flag_est_criador,
          nc.flag_est_aprov,
          nc.flag_doc_criador,
          nc.flag_doc_aprov,
          nc.flag_bri_aprov,
          nc.flag_pa_notif_ender
     INTO v_nt_notifica_config_id,
          v_flag_notifica_tela,
          v_nt_flag_ender_todos,
          v_nt_flag_ender_papel,
          v_nt_flag_usu_papel,
          v_nt_flag_usu_indicado,
          v_nt_flag_job_criador,
          v_nt_flag_job_respint,
          v_nt_flag_os_solicit,
          v_nt_flag_os_distr,
          v_nt_flag_os_exec,
          v_nt_flag_os_aprov,
          v_nt_flag_ca_produtor,
          v_nt_flag_ctr_criador,
          v_nt_flag_ctr_respint,
          v_nt_flag_ad_criador,
          v_nt_flag_ad_solicit,
          v_nt_flag_ad_aprov,
          v_nt_flag_est_criador,
          v_nt_flag_est_aprov,
          v_nt_flag_doc_criador,
          v_nt_flag_doc_aprov,
          v_nt_flag_bri_aprov,
          v_nt_flag_pa_notif_ender
     FROM notifica_config nc,
          evento_config   ec
    WHERE nc.evento_config_id = r_nt.evento_config_id
      AND nc.tipo_notific = 'TELA'
      AND nc.evento_config_id = ec.evento_config_id;
   --
   -- recupera configuracoes para email
   SELECT nc.notifica_config_id,
          ec.flag_notifica_email,
          nc.flag_ender_todos,
          nc.flag_ender_papel,
          nc.flag_usu_papel,
          nc.flag_usu_indicado,
          nc.flag_job_criador,
          nc.flag_job_respint,
          nc.flag_os_solicit,
          nc.flag_os_distr,
          nc.flag_os_exec,
          nc.flag_os_aprov,
          nc.flag_ca_produtor,
          nc.flag_emails,
          emails,
          nc.flag_ctr_criador,
          nc.flag_ctr_respint,
          nc.flag_ad_criador,
          nc.flag_ad_solicit,
          nc.flag_ad_aprov,
          nc.flag_est_criador,
          nc.flag_est_aprov,
          nc.flag_doc_criador,
          nc.flag_doc_aprov,
          nc.flag_bri_aprov,
          nc.flag_pa_notif_ender
     INTO v_ne_notifica_config_id,
          v_flag_notifica_email,
          v_ne_flag_ender_todos,
          v_ne_flag_ender_papel,
          v_ne_flag_usu_papel,
          v_ne_flag_usu_indicado,
          v_ne_flag_job_criador,
          v_ne_flag_job_respint,
          v_ne_flag_os_solicit,
          v_ne_flag_os_distr,
          v_ne_flag_os_exec,
          v_ne_flag_os_aprov,
          v_ne_flag_ca_produtor,
          v_ne_flag_emails,
          v_emails,
          v_ne_flag_ctr_criador,
          v_ne_flag_ctr_respint,
          v_ne_flag_ad_criador,
          v_ne_flag_ad_solicit,
          v_ne_flag_ad_aprov,
          v_ne_flag_est_criador,
          v_ne_flag_est_aprov,
          v_ne_flag_doc_criador,
          v_ne_flag_doc_aprov,
          v_ne_flag_bri_aprov,
          v_ne_flag_pa_notif_ender
     FROM notifica_config nc,
          evento_config   ec
    WHERE nc.evento_config_id = r_nt.evento_config_id
      AND nc.tipo_notific = 'EMAIL'
      AND nc.evento_config_id = ec.evento_config_id;
   --
   v_desc_evento := REPLACE(r_nt.desc_evento, 'Job', v_lbl_job);
   v_nome_objeto := REPLACE(r_nt.nome_objeto, 'Job', v_lbl_job);
   --
   --------------------------------------------
   -- texto da notificacao por tela
   --------------------------------------------
   IF r_nt.notif_corpo IS NOT NULL THEN
    -- usa modelo customizado de corpo da notificacao
    v_texto := r_nt.notif_corpo;
   ELSE
    -- USA MODELO PADRAO PARA NOTIF VIA TELA
    v_texto := v_desc_evento || v_texto_adicional || chr(10) || v_nome_objeto || ': ' ||
               r_nt.identif_objeto || chr(10);
    --
    IF v_doc_nome IS NOT NULL THEN
     v_texto := v_texto || 'Nome do Documento: ' || v_doc_nome || chr(10);
    END IF;
    --
    IF v_cliente_apelido IS NOT NULL THEN
     v_texto := v_texto || 'Cliente: ' || v_cliente_apelido || chr(10);
    END IF;
    --
    IF v_job_nome IS NOT NULL THEN
     v_texto := v_texto || v_lbl_job || ': ' || v_job_nome || chr(10);
     v_texto := v_texto || 'Número do ' || v_lbl_job || ': ' || v_job_numero || chr(10);
    END IF;
    --
    IF v_os_numero IS NOT NULL THEN
     v_texto := v_texto || 'Número do Workflow: ' || v_os_numero || chr(10);
    END IF;
    --
    IF v_contrato_nome IS NOT NULL THEN
     v_texto := v_texto || 'Nome do Contrato: ' || v_contrato_nome || chr(10);
     v_texto := v_texto || 'Número do Contrato: ' || v_contrato_numero || chr(10);
    END IF;
    --
    IF v_oport_nome IS NOT NULL THEN
     v_texto := v_texto || 'Nome da Oportunidade: ' || v_oport_nome || chr(10);
     v_texto := v_texto || 'Número da Oportunidade: ' || v_oport_numero || chr(10);
    END IF;
    --
    IF v_justificativa IS NOT NULL THEN
     v_texto := v_texto || 'Motivo: ' || v_justificativa || chr(10);
    END IF;
    --
    IF v_complemento IS NOT NULL THEN
     v_texto := v_texto || 'Complemento: ' || v_complemento || chr(10);
    END IF;
    --
    /*
    v_texto := v_texto || 'Autor do evento: ' || r_nt.usuario_de || chr(10)||
                          'Data do evento: ' || data_hora_mostrar(r_nt.data_evento);
    */
   END IF;
   --
   --------------------------------------------
   -- texto do assunto do email
   --------------------------------------------
   IF r_nt.email_assunto IS NOT NULL THEN
    -- usa modelo customizado de assunto do email
    v_assunto := r_nt.email_assunto;
   ELSE
    -- USA MODELO PADRAO PARA ASSUNTO DO EMAIL
    v_assunto := v_desc_evento || v_texto_adicional || ': ' || r_nt.identif_objeto;
    --
    IF v_job_nome IS NOT NULL THEN
     v_assunto := v_assunto || ' - ' || v_lbl_job || ': ' || v_job_nome;
    END IF;
   END IF;
   --
   --------------------------------------------
   -- texto do corpo do email
   --------------------------------------------
   IF r_nt.email_corpo IS NOT NULL THEN
    -- usa modelo customizado de corpo do email
    v_corpo := r_nt.email_corpo;
   ELSE
    -- USA MODELO PADRAO PARA CORPO DO EMAIL
    v_corpo := '<b>Este e-mail de Notificação foi gerado automaticamente pelo JobOne. Favor não responder.</b>' ||
               chr(10) || chr(10) || v_desc_evento || v_texto_adicional || chr(10) || v_nome_objeto || ': ' ||
               r_nt.identif_objeto || chr(10);
    --
    IF v_cliente_apelido IS NOT NULL THEN
     v_corpo := v_corpo || 'Cliente: ' || v_cliente_apelido || chr(10);
    END IF;
    --
    IF v_job_nome IS NOT NULL THEN
     v_corpo := v_corpo || v_lbl_job || ': ' || v_job_nome || chr(10);
     v_corpo := v_corpo || 'Número do ' || v_lbl_job || ': ' || v_job_numero || chr(10);
    END IF;
    --
    IF v_os_numero IS NOT NULL THEN
     v_corpo := v_corpo || 'Número do Workflow: ' || v_os_numero || chr(10);
    END IF;
    --
    IF v_contrato_nome IS NOT NULL THEN
     v_corpo := v_corpo || 'Nome do Contrato: ' || v_contrato_nome || chr(10);
     v_corpo := v_corpo || 'Número do Contrato: ' || v_contrato_numero || chr(10);
    END IF;
    --
    IF v_oport_nome IS NOT NULL THEN
     v_corpo := v_corpo || 'Nome da Oportunidade: ' || v_oport_nome || chr(10);
     v_corpo := v_corpo || 'Número da Oportunidade: ' || v_oport_numero || chr(10);
    END IF;
    --
    IF v_justificativa IS NOT NULL THEN
     v_corpo := v_corpo || 'Motivo: ' || v_justificativa || chr(10);
    END IF;
    --
    IF v_complemento IS NOT NULL THEN
     v_corpo := v_corpo || 'Complemento: ' || v_complemento || chr(10);
    END IF;
    --ALCBO_221024 
    IF v_tarefa_numero IS NOT NULL THEN
     v_corpo := v_corpo || 'Número da Task: ' || v_tarefa_numero || chr(10) ||
                'Descrição da Task: ' || v_tarefa_desc || chr(10) ||
                'Descrição do Entregável da Task: ' || v_tarefa_ent_desc || chr(10) ||
                'Complemento do Entregável da Task: ' || v_tarefa_ent_compl || chr(10);
    END IF;
    --
    v_corpo := v_corpo || 'Autor do evento: ' || r_nt.usuario_de || chr(10) || 'Data do evento: ' ||
               data_hora_mostrar(r_nt.data_evento) || chr(10);
   END IF;
   --
   v_texto   := REPLACE(v_texto, '[usuario]', r_nt.usuario_de);
   v_assunto := REPLACE(v_assunto, '[usuario]', r_nt.usuario_de);
   v_corpo   := REPLACE(v_corpo, '[usuario]', r_nt.usuario_de);
   --
   v_texto   := REPLACE(v_texto, '[data_hora]', data_hora_mostrar(r_nt.data_evento));
   v_assunto := REPLACE(v_assunto, '[data_hora]', data_hora_mostrar(r_nt.data_evento));
   v_corpo   := REPLACE(v_corpo, '[data_hora]', data_hora_mostrar(r_nt.data_evento));
   --
   v_texto   := REPLACE(v_texto, '[cliente_apelido]', v_cliente_apelido);
   v_assunto := REPLACE(v_assunto, '[cliente_apelido]', v_cliente_apelido);
   v_corpo   := REPLACE(v_corpo, '[cliente_apelido]', v_cliente_apelido);
   --
   v_texto   := REPLACE(v_texto, '[job_nome]', v_job_nome);
   v_assunto := REPLACE(v_assunto, '[job_nome]', v_job_nome);
   v_corpo   := REPLACE(v_corpo, '[job_nome]', v_job_nome);
   --
   v_texto   := REPLACE(v_texto, '[job_numero]', v_job_numero);
   v_assunto := REPLACE(v_assunto, '[job_numero]', v_job_numero);
   v_corpo   := REPLACE(v_corpo, '[job_numero]', v_job_numero);
   --
   v_texto   := REPLACE(v_texto, '[cronograma_numero]', v_cronograma_numero);
   v_assunto := REPLACE(v_assunto, '[cronograma_numero]', v_cronograma_numero);
   v_corpo   := REPLACE(v_corpo, '[cronograma_numero]', v_cronograma_numero);
   --
   v_texto   := REPLACE(v_texto, '[entrega_numero]', v_os_numero);
   v_assunto := REPLACE(v_assunto, '[entrega_numero]', v_os_numero);
   v_corpo   := REPLACE(v_corpo, '[entrega_numero]', v_os_numero);
   --
   v_texto   := REPLACE(v_texto, '[contrato_nome]', v_contrato_nome);
   v_assunto := REPLACE(v_assunto, '[contrato_nome]', v_contrato_nome);
   v_corpo   := REPLACE(v_corpo, '[contrato_nome]', v_contrato_nome);
   --
   v_texto   := REPLACE(v_texto, '[contrato_numero]', v_contrato_numero);
   v_assunto := REPLACE(v_assunto, '[contrato_numero]', v_contrato_numero);
   v_corpo   := REPLACE(v_corpo, '[contrato_numero]', v_contrato_numero);
   --
   v_texto   := REPLACE(v_texto, '[oportunidade_nome]', v_oport_nome);
   v_assunto := REPLACE(v_assunto, '[oportunidade_nome]', v_oport_nome);
   v_corpo   := REPLACE(v_corpo, '[oportunidade_nome]', v_oport_nome);
   --
   v_texto   := REPLACE(v_texto, '[oportunidade_numero]', v_oport_numero);
   v_assunto := REPLACE(v_assunto, '[oportunidade_numero]', v_oport_numero);
   v_corpo   := REPLACE(v_corpo, '[oportunidade_numero]', v_oport_numero);
   --
   v_texto   := REPLACE(v_texto, '[objeto_do_evento]', r_nt.identif_objeto);
   v_assunto := REPLACE(v_assunto, '[objeto_do_evento]', r_nt.identif_objeto);
   v_corpo   := REPLACE(v_corpo, '[objeto_do_evento]', r_nt.identif_objeto);
   --
   ----------------------------------------------------------
   -- notificacao para usuarios ativos indicados no comentario
   ----------------------------------------------------------
   IF r_nt.cod_acao LIKE 'COMENTAR%' THEN
    SELECT nvl(MAX(to_number(justificativa)), 0)
      INTO v_comentario_id
      FROM historico
     WHERE historico_id = r_nt.historico_id;
    --
    IF v_comentario_id > 0 THEN
     FOR r_co IN c_co
     LOOP
      notifica_fila_usu_inserir(v_notifica_fila_id,
                                r_co.usuario_id,
                                r_co.nome_para,
                                v_erro_cod,
                                v_erro_msg);
      --
     -- despreza as demais configuracoes de notificacao para esse evento
     -- v_liga_tudo := 0; (comentado para nao desprezar mais)
     END LOOP;
    END IF;
   END IF;
   --
   ----------------------------------------------------------
   -- notificacao para o usuario objeto da acao
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_acao = 'INATIVAR_AUTO' THEN
    SELECT MAX(objeto_id)
      INTO v_usuario_id
      FROM historico
     WHERE historico_id = r_nt.historico_id;
    --
    IF nvl(v_usuario_id, 0) > 0 THEN
     SELECT MAX(apelido)
       INTO v_usu_apelido
       FROM pessoa
      WHERE usuario_id = v_usuario_id;
     --
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               v_usuario_id,
                               v_usu_apelido,
                               v_erro_cod,
                               v_erro_msg);
    END IF;
   END IF;
   --
   ----------------------------------------------------------
   -- email para o usuario objeto da acao
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_acao = 'INATIVAR_AUTO' THEN
    SELECT MAX(objeto_id)
      INTO v_usuario_id
      FROM historico
     WHERE historico_id = r_nt.historico_id;
    --
    IF nvl(v_usuario_id, 0) > 0 THEN
     SELECT MAX(email)
       INTO v_emails
       FROM pessoa
      WHERE usuario_id = v_usuario_id;
     --
     notifica_fila_email_inserir(v_notifica_fila_id, v_emails, NULL, v_erro_cod, v_erro_msg);
    END IF;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ emails especificos indicados
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_emails = 'S' AND v_liga_tudo = 1 THEN
    notifica_fila_email_inserir(v_notifica_fila_id, v_emails, NULL, v_erro_cod, v_erro_msg);
   END IF;
   --
   ----------------------------------------------------------
   -- notifica usuarios especificos indicados (ativos)
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_usu_indicado = 'S' AND v_liga_tudo = 1 THEN
    v_notifica_config_id := v_nt_notifica_config_id;
    --
    FOR r_us IN c_us
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_us.usuario_id,
                               r_us.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ usuarios especificos indicados (ativos)
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_usu_indicado = 'S' AND v_liga_tudo = 1 THEN
    v_notifica_config_id := v_ne_notifica_config_id;
    --
    FOR r_us IN c_us
    LOOP
     IF r_us.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_us.email_para,
                                  r_us.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica qualquer usuario ativo com papeis indicados
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_usu_papel = 'S' AND v_liga_tudo = 1 THEN
    v_notifica_config_id := v_nt_notifica_config_id;
    --
    FOR r_pa IN c_pa
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_pa.usuario_id,
                               r_pa.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ qualquer usuario ativo com papeis indicados
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_usu_papel = 'S' AND v_liga_tudo = 1 THEN
    v_notifica_config_id := v_ne_notifica_config_id;
    --
    FOR r_pa IN c_pa
    LOOP
     IF r_pa.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_pa.email_para,
                                  r_pa.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica usuarios avulsos ativos nomeados (indicados)
   -- ou implicitos (enderecamento solidario)
   ----------------------------------------------------------
   FOR r_av IN c_av
   LOOP
    v_texto   := REPLACE(v_texto, '[papel_nome]', r_av.papel_nome);
    v_assunto := REPLACE(v_assunto, '[papel_nome]', r_av.papel_nome);
    v_corpo   := REPLACE(v_corpo, '[papel_nome]', r_av.papel_nome);
    --
    v_texto   := REPLACE(v_texto, '[usuario_para]', r_av.nome_para);
    v_assunto := REPLACE(v_assunto, '[usuario_para]', r_av.nome_para);
    v_corpo   := REPLACE(v_corpo, '[usuario_para]', r_av.nome_para);
    --
    IF r_av.flag_notif_ender IS NULL THEN
     SELECT nvl(MAX(pa.flag_notif_ender), 'N')
       INTO v_flag_notifica_ender
       FROM papel         pa,
            usuario_papel up
      WHERE pa.empresa_id = r_nt.empresa_id
        AND pa.papel_id = up.papel_id
        AND up.usuario_id = r_av.usuario_id;
    ELSE
     v_flag_notifica_ender := r_av.flag_notif_ender;
    END IF;
    --
    -- usuarios nomeados em transicao de OS - notificaco forcada
    IF r_av.tipo_notifica IN ('TELA', 'AMBOS') THEN
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_av.usuario_id,
                               r_av.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END IF;
    --
    IF r_av.tipo_notifica IN ('EMAIL', 'AMBOS') AND r_av.email_para IS NOT NULL THEN
     notifica_fila_email_inserir(v_notifica_fila_id,
                                 r_av.email_para,
                                 r_av.nome_para,
                                 v_erro_cod,
                                 v_erro_msg);
    END IF;
    --
    -- usuarios enderecados em job ou orcamento - respeita a configuracao do evento
    -- e do papel
    IF r_av.tipo_notifica = 'PADRAO' AND v_flag_notifica_tela = 'S' AND
       v_nt_flag_pa_notif_ender = 'S' AND v_flag_notifica_ender = 'S' AND v_liga_tudo = 1 THEN
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_av.usuario_id,
                               r_av.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END IF;
    --
    IF r_av.tipo_notifica = 'PADRAO' AND r_av.email_para IS NOT NULL AND
       v_flag_notifica_email = 'S' AND v_ne_flag_pa_notif_ender = 'S' AND
       r_av.flag_recebe_email = 'S' AND v_flag_notifica_ender = 'S' AND v_liga_tudo = 1 THEN
     notifica_fila_email_inserir(v_notifica_fila_id,
                                 r_av.email_para,
                                 r_av.nome_para,
                                 v_erro_cod,
                                 v_erro_msg);
    END IF;
   END LOOP;
   --
   ----------------------------------------------------------
   -- notifica todos os usuarios enderecados no job
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_ender_todos = 'S' AND v_liga_tudo = 1 AND
      r_nt.cod_objeto <> 'TAREFA' THEN
    FOR r_jo IN c_jo
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_jo.usuario_id,
                               r_jo.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ todos os usuarios enderecados no job
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_ender_todos = 'S' AND v_liga_tudo = 1 AND
      r_nt.cod_objeto <> 'TAREFA' THEN
    FOR r_jo IN c_jo
    LOOP
     IF r_jo.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_jo.email_para,
                                  r_jo.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica os usuarios enderecados no job c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_ender_papel = 'S' AND v_liga_tudo = 1 AND
      r_nt.cod_objeto <> 'TAREFA' THEN
    v_notifica_config_id := v_nt_notifica_config_id;
    FOR r_ja IN c_ja
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ja.usuario_id,
                               r_ja.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ os usuarios enderecados no job c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_ender_papel = 'S' AND v_liga_tudo = 1 AND
      r_nt.cod_objeto <> 'TAREFA' THEN
    v_notifica_config_id := v_ne_notifica_config_id;
    FOR r_ja IN c_ja
    LOOP
     IF r_ja.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ja.email_para,
                                  r_ja.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica criador do job
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_job_criador = 'S' AND v_liga_tudo = 1 THEN
    FOR r_js IN c_js
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_js.usuario_id,
                               r_js.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ o criador do job
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_job_criador = 'S' AND v_liga_tudo = 1 THEN
    FOR r_js IN c_js
    LOOP
     IF r_js.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_js.email_para,
                                  r_js.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica responsavel interno pelo job
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_job_respint = 'S' AND v_liga_tudo = 1 THEN
    --v_cod_priv := 'JOB_RESP_INT_V';
    --
    FOR r_ri IN c_ri
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ri.usuario_id,
                               r_ri.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ responsavel interno pelo job
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_job_respint = 'S' AND v_liga_tudo = 1 THEN
    --v_cod_priv := 'JOB_RESP_INT_V';
    --
    FOR r_ri IN c_ri
    LOOP
     IF r_ri.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ri.email_para,
                                  r_ri.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica criador da estimatica
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_est_criador = 'S' AND v_liga_tudo = 1 THEN
    v_orcamento_id := r_nt.objeto_id;
    --
    FOR r_oc IN c_oc
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_oc.usuario_id,
                               r_oc.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ o criador da estimativa
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_est_criador = 'S' AND v_liga_tudo = 1 THEN
    v_orcamento_id := r_nt.objeto_id;
    --
    FOR r_oc IN c_oc
    LOOP
     IF r_oc.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_oc.email_para,
                                  r_oc.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica aprovador da estimativa
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_est_aprov = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv := 'ORCAMENTO_AP';
    --
    FOR r_op IN c_op
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_op.usuario_id,
                               r_op.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ aprovador da estimativa
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_est_aprov = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv := 'ORCAMENTO_AP';
    --
    FOR r_op IN c_op
    LOOP
     IF r_op.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_op.email_para,
                                  r_op.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica aprovador do briefing
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_bri_aprov = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv := 'BRIEF_AP';
    --
    FOR r_jp IN c_jp
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_jp.usuario_id,
                               r_jp.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ aprovador do briefing
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_bri_aprov = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv := 'BRIEF_AP';
    --
    FOR r_jp IN c_jp
    LOOP
     IF r_jp.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_jp.email_para,
                                  r_jp.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica os usuarios de DOCUMENTO
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'DOCUMENTO' AND v_liga_tudo = 1 AND
      (v_nt_flag_doc_criador = 'S' OR v_nt_flag_doc_aprov = 'S') THEN
    v_liga_doc_cria  := 0;
    v_liga_doc_aprov := 0;
    v_documento_id   := r_nt.objeto_id;
    --
    IF v_nt_flag_doc_criador = 'S' THEN
     v_liga_doc_cria := 1;
    END IF;
    --
    IF v_nt_flag_doc_aprov = 'S' THEN
     v_liga_doc_aprov := 1;
    END IF;
    --
    FOR r_dc IN c_dc
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_dc.usuario_id,
                               r_dc.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ os usuarios de DOCUMENTO
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'DOCUMENTO' AND v_liga_tudo = 1 AND
      (v_ne_flag_doc_criador = 'S' OR v_ne_flag_doc_aprov = 'S') THEN
    v_liga_doc_cria  := 0;
    v_liga_doc_aprov := 0;
    v_documento_id   := r_nt.objeto_id;
    --
    IF v_ne_flag_doc_criador = 'S' THEN
     v_liga_doc_cria := 1;
    END IF;
    --
    IF v_ne_flag_doc_aprov = 'S' THEN
     v_liga_doc_aprov := 1;
    END IF;
    --
    FOR r_dc IN c_dc
    LOOP
     IF r_dc.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_dc.email_para,
                                  r_dc.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica criador do contrato
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_liga_tudo = 1 AND
      v_nt_flag_ctr_criador = 'S' THEN
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct1 IN c_ct1
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ct1.usuario_id,
                               r_ct1.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ criador do contrato
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_liga_tudo = 1 AND
      v_ne_flag_ctr_criador = 'S' THEN
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct1 IN c_ct1
    LOOP
     IF r_ct1.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ct1.email_para,
                                  r_ct1.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica responsavel interno pelo contrato
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND v_nt_flag_ctr_respint = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv    := 'CONTRATO_RESP_INT_V';
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct2 IN c_ct2
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ct2.usuario_id,
                               r_ct2.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ responsavel interno pelo contrato
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND v_ne_flag_ctr_respint = 'S' AND v_liga_tudo = 1 THEN
    v_cod_priv    := 'CONTRATO_RESP_INT_V';
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct2 IN c_ct2
    LOOP
     IF r_ct2.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ct2.email_para,
                                  r_ct2.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica todos os usuarios enderecados no contrato
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_nt_flag_ender_todos = 'S' AND
      v_liga_tudo = 1 THEN
    --
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct3 IN c_ct3
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ct3.usuario_id,
                               r_ct3.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ todos os usuarios enderecados no contrato
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_ne_flag_ender_todos = 'S' AND
      v_liga_tudo = 1 THEN
    --
    v_contrato_id := r_nt.objeto_id;
    --
    FOR r_ct3 IN c_ct3
    LOOP
     IF r_ct3.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ct3.email_para,
                                  r_ct3.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica os usuarios enderecados no contrato c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_nt_flag_ender_papel = 'S' AND
      v_liga_tudo = 1 THEN
    --
    v_contrato_id        := r_nt.objeto_id;
    v_notifica_config_id := v_nt_notifica_config_id;
    --
    FOR r_ct4 IN c_ct4
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ct4.usuario_id,
                               r_ct4.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ os usuarios enderecados no contrato c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'CONTRATO' AND v_ne_flag_ender_papel = 'S' AND
      v_liga_tudo = 1 THEN
    --
    v_contrato_id        := r_nt.objeto_id;
    v_notifica_config_id := v_ne_notifica_config_id;
    --
    FOR r_ct4 IN c_ct4
    LOOP
     IF r_ct4.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ct4.email_para,
                                  r_ct4.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica criador do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_nt_flag_ad_criador = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad1 IN c_ad1
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ad1.usuario_id,
                               r_ad1.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ criador do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_ne_flag_ad_criador = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad1 IN c_ad1
    LOOP
     IF r_ad1.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ad1.email_para,
                                  r_ad1.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica solicitante do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_nt_flag_ad_solicit = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad2 IN c_ad2
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ad2.usuario_id,
                               r_ad2.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ solicitante do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_ne_flag_ad_solicit = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad2 IN c_ad2
    LOOP
     IF r_ad2.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ad2.email_para,
                                  r_ad2.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica aprovador do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_nt_flag_ad_aprov = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad3 IN c_ad3
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ad3.usuario_id,
                               r_ad3.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ aprovador do adiantamento
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'ADIANT_DESP' AND v_liga_tudo = 1 AND
      v_ne_flag_ad_aprov = 'S' THEN
    v_adiant_desp_id := r_nt.objeto_id;
    --
    FOR r_ad3 IN c_ad3
    LOOP
     IF r_ad3.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ad3.email_para,
                                  r_ad3.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica produtor da carta acordo
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'CARTA_ACORDO' AND v_liga_tudo = 1 AND
      v_nt_flag_ca_produtor = 'S' THEN
    v_carta_acordo_id := r_nt.objeto_id;
    --
    FOR r_ca IN c_ca
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_ca.usuario_id,
                               r_ca.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ produtor da carta acordo
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'CARTA_ACORDO' AND v_liga_tudo = 1 AND
      v_ne_flag_ca_produtor = 'S' THEN
    v_carta_acordo_id := r_nt.objeto_id;
    --
    FOR r_ca IN c_ca
    LOOP
     IF r_ca.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_ca.email_para,
                                  r_ca.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica os usuarios de OS
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'ORDEM_SERVICO' AND v_liga_tudo = 1 AND
      (v_nt_flag_os_solicit = 'S' OR v_nt_flag_os_distr = 'S' OR v_nt_flag_os_exec = 'S' OR
      v_nt_flag_os_aprov = 'S' OR r_nt.cod_acao = 'NOTIFICAR3') THEN
    v_liga_solic       := 0;
    v_liga_distr       := 0;
    v_liga_distr_cpriv := 0;
    v_liga_exec        := 0;
    v_liga_aprov_cpriv := 0;
    v_liga_aprov_davez := 0;
    v_liga_usu_sessao  := 0;
    v_ordem_servico_id := r_nt.objeto_id;
    --
    IF v_nt_flag_os_solicit = 'S' THEN
     v_liga_solic := 1;
    END IF;
    --
    IF v_nt_flag_os_distr = 'S' THEN
     v_liga_distr := 1;
     --
     -- verifica se OS tem distribuidor
     SELECT COUNT(*)
       INTO v_qt
       FROM os_usuario
      WHERE ordem_servico_id = r_nt.objeto_id
        AND tipo_ender = 'DIS';
     --
     IF v_qt = 0 THEN
      -- ainda nao tem distribuidor. Vai pelo privilegio
      v_liga_distr_cpriv := 1;
     END IF;
    END IF;
    --
    IF v_nt_flag_os_exec = 'S' THEN
     v_liga_exec := 1;
    END IF;
    --
    IF v_nt_flag_os_aprov = 'S' THEN
     -- inclui qualquer usuario com priv de aprovar essa OS
     v_liga_aprov_cpriv := 1;
    END IF;
    --
    -- verifica se eh envio de OS para aprovacao, notificacao do
    -- proximo aprovador, ou atraso em OS em aprovacao (apenas tipo OS
    -- com fluxo).
    IF r_nt.cod_acao IN ('ENVIAR_APROV', 'NOTIFICAR_APROV', 'NOTIFICAR4') AND
       v_nt_flag_os_aprov = 'S' AND v_flag_faixa_aprov = 'S' THEN
     -- inclui apenas os aprovadores da vez
     v_liga_aprov_cpriv := 0;
     v_liga_aprov_davez := 1;
    END IF;
    --
    IF r_nt.cod_acao = 'NOTIFICAR3' THEN
     -- evento de upload de arquivo (notifica o usuario da sessao)
     v_liga_usu_sessao := 1;
    END IF;
    --
    FOR r_os IN c_os
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_os.usuario_id,
                               r_os.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
    --
    IF r_nt.cod_acao = 'NOTIFICAR4' THEN
     -- evento de notificacao de atraso na aprovacao. Verifica se achou alguum
     -- aprovador da vez. Se nao, notifica pelo privilegio de aprovar.
     SELECT COUNT(*)
       INTO v_qt
       FROM notifica_fila_usu
      WHERE notifica_fila_id = v_notifica_fila_id;
     --
     IF v_qt = 0 THEN
      v_liga_aprov_cpriv := 1;
      v_liga_aprov_davez := 0;
      --
      FOR r_os IN c_os
      LOOP
       notifica_fila_usu_inserir(v_notifica_fila_id,
                                 r_os.usuario_id,
                                 r_os.nome_para,
                                 v_erro_cod,
                                 v_erro_msg);
      END LOOP;
     END IF;
    END IF;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ os usuarios de OS
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'ORDEM_SERVICO' AND v_liga_tudo = 1 AND
      (v_ne_flag_os_solicit = 'S' OR v_ne_flag_os_distr = 'S' OR v_ne_flag_os_exec = 'S' OR
      v_ne_flag_os_aprov = 'S' OR r_nt.cod_acao = 'NOTIFICAR3') THEN
    v_liga_solic       := 0;
    v_liga_distr       := 0;
    v_liga_distr_cpriv := 0;
    v_liga_exec        := 0;
    v_liga_aprov_cpriv := 0;
    v_liga_aprov_davez := 0;
    v_liga_usu_sessao  := 0;
    v_ordem_servico_id := r_nt.objeto_id;
    --
    IF v_ne_flag_os_solicit = 'S' THEN
     v_liga_solic := 1;
    END IF;
    --
    IF v_ne_flag_os_distr = 'S' THEN
     v_liga_distr := 1;
     --
     -- verifica se OS tem distribuidor
     SELECT COUNT(*)
       INTO v_qt
       FROM os_usuario
      WHERE ordem_servico_id = r_nt.objeto_id
        AND tipo_ender = 'DIS';
     --
     IF v_qt = 0 THEN
      -- ainda nao tem distribuidor. Vai pelo privilegio
      v_liga_distr_cpriv := 1;
     END IF;
    END IF;
    --
    IF v_ne_flag_os_exec = 'S' THEN
     v_liga_exec := 1;
    END IF;
    --
    IF v_nt_flag_os_aprov = 'S' THEN
     -- inclui qualquer usuario com priv de aprovar essa OS
     v_liga_aprov_cpriv := 1;
    END IF;
    --
    -- verifica se eh envio de OS para aprovacao ou notificacao do
    -- proximo aprovador
    IF r_nt.cod_acao IN ('ENVIAR_APROV', 'NOTIFICAR_APROV', 'NOTIFICAR4') AND
       v_nt_flag_os_aprov = 'S' AND v_flag_faixa_aprov = 'S' THEN
     -- inclui apenas os aprovadores da vez
     v_liga_aprov_cpriv := 0;
     v_liga_aprov_davez := 1;
    END IF;
    --
    IF r_nt.cod_acao = 'NOTIFICAR3' THEN
     -- evento de upload de arquivo (notifica o usuario da sessao)
     v_liga_usu_sessao := 1;
    END IF;
    --
    FOR r_os IN c_os
    LOOP
     IF r_os.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_os.email_para,
                                  r_os.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
    --
    IF r_nt.cod_acao = 'NOTIFICAR4' THEN
     -- evento de notificacao de atraso na aprovacao. Verifica se achou alguum
     -- aprovador da vez. Se nao, notifica pelo privilegio de aprovar.
     SELECT COUNT(*)
       INTO v_qt
       FROM notifica_fila_email
      WHERE notifica_fila_id = v_notifica_fila_id;
     --
     IF v_qt = 0 THEN
      v_liga_aprov_cpriv := 1;
      v_liga_aprov_davez := 0;
      --
      FOR r_os IN c_os
      LOOP
       notifica_fila_email_inserir(v_notifica_fila_id,
                                   r_os.email_para,
                                   r_os.nome_para,
                                   v_erro_cod,
                                   v_erro_msg);
      END LOOP;
     END IF;
    END IF;
   END IF;
   --
   ----------------------------------------------------------
   -- tratamento especial para TAREFA
   ----------------------------------------------------------
   IF r_nt.cod_objeto = 'TAREFA' THEN
    --
    IF v_flag_notifica_tela = 'S' AND v_nt_flag_ender_todos = 'S' AND v_liga_tudo = 1 THEN
     -- notifica todos os usuarios enderecados na tarefa
     v_tarefa_id := r_nt.objeto_id;
     --
     FOR r_ta IN c_ta
     LOOP
      notifica_fila_usu_inserir(v_notifica_fila_id,
                                r_ta.usuario_id,
                                r_ta.nome_para,
                                v_erro_cod,
                                v_erro_msg);
     END LOOP;
    END IF;
    --
    IF v_flag_notifica_email = 'S' AND v_ne_flag_ender_todos = 'S' AND v_liga_tudo = 1 THEN
     -- email p/ todos os usuarios enderecados na tarefa
     v_tarefa_id := r_nt.objeto_id;
     --
     FOR r_ta IN c_ta
     LOOP
      IF r_ta.flag_recebe_email = 'S' THEN
       notifica_fila_email_inserir(v_notifica_fila_id,
                                   r_ta.email_para,
                                   r_ta.nome_para,
                                   v_erro_cod,
                                   v_erro_msg);
      END IF;
     END LOOP;
    END IF;
    --
    --
    IF v_flag_notifica_tela = 'S' AND v_nt_flag_ender_papel = 'S' AND v_liga_tudo = 1 THEN
     -- notifica todos os usuarios c/ PAPEL enderecados na tarefa
     v_notifica_config_id := v_nt_notifica_config_id;
     v_tarefa_id          := r_nt.objeto_id;
     --
     FOR r_tp IN c_tp
     LOOP
      notifica_fila_usu_inserir(v_notifica_fila_id,
                                r_tp.usuario_id,
                                r_tp.nome_para,
                                v_erro_cod,
                                v_erro_msg);
     END LOOP;
    END IF;
    --
    IF v_flag_notifica_email = 'S' AND v_ne_flag_ender_papel = 'S' AND v_liga_tudo = 1 THEN
     -- email p/ todos os usuarios c/ PAPEL enderecados na tarefa
     v_notifica_config_id := v_nt_notifica_config_id;
     v_tarefa_id          := r_nt.objeto_id;
     --
     FOR r_tp IN c_tp
     LOOP
      IF r_tp.flag_recebe_email = 'S' THEN
       notifica_fila_email_inserir(v_notifica_fila_id,
                                   r_tp.email_para,
                                   r_tp.nome_para,
                                   v_erro_cod,
                                   v_erro_msg);
      END IF;
     END LOOP;
    END IF;
   END IF; -- fim do IF r_nt.cod_objeto = 'TAREFA'
   --
   ----------------------------------------------------------
   -- notifica todos os usuarios enderecados na OPORTUNIDADE
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'OPORTUNIDADE' AND
      v_nt_flag_ender_todos = 'S' AND v_liga_tudo = 1 THEN
    --
    v_oportunidade_id := r_nt.objeto_id;
    --
    FOR r_op1 IN c_op1
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_op1.usuario_id,
                               r_op1.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ todos os usuarios enderecados na OPORTUNIDADE
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'OPORTUNIDADE' AND
      v_ne_flag_ender_todos = 'S' AND v_liga_tudo = 1 THEN
    --
    v_oportunidade_id := r_nt.objeto_id;
    --
    FOR r_op1 IN c_op1
    LOOP
     IF r_op1.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_op1.email_para,
                                  r_op1.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- notifica os usuarios enderecados na OPORTUNIDADE c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_tela = 'S' AND r_nt.cod_objeto = 'OPORTUNIDADE' AND
      v_nt_flag_ender_papel = 'S' AND v_liga_tudo = 1 THEN
    --
    v_oportunidade_id    := r_nt.objeto_id;
    v_notifica_config_id := v_nt_notifica_config_id;
    --
    FOR r_op2 IN c_op2
    LOOP
     notifica_fila_usu_inserir(v_notifica_fila_id,
                               r_op2.usuario_id,
                               r_op2.nome_para,
                               v_erro_cod,
                               v_erro_msg);
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- email p/ os usuarios enderecados na OPORTUNIDADE c/ papel indicado
   ----------------------------------------------------------
   IF v_flag_notifica_email = 'S' AND r_nt.cod_objeto = 'OPORTUNIDADE' AND
      v_ne_flag_ender_papel = 'S' AND v_liga_tudo = 1 THEN
    --
    v_oportunidade_id    := r_nt.objeto_id;
    v_notifica_config_id := v_ne_notifica_config_id;
    --
    FOR r_op2 IN c_op2
    LOOP
     IF r_op2.flag_recebe_email = 'S' THEN
      notifica_fila_email_inserir(v_notifica_fila_id,
                                  r_op2.email_para,
                                  r_op2.nome_para,
                                  v_erro_cod,
                                  v_erro_msg);
     END IF;
    END LOOP;
   END IF;
   --
   ----------------------------------------------------------
   -- deleta usuarios duplicados
   ----------------------------------------------------------
   DELETE FROM notifica_fila_usu
    WHERE notifica_fila_id = v_notifica_fila_id
      AND notifica_fila_usu_id NOT IN (SELECT MIN(notifica_fila_usu_id)
                                         FROM notifica_fila_usu
                                        WHERE notifica_fila_id = v_notifica_fila_id
                                        GROUP BY usuario_para_id);
   --
   ----------------------------------------------------------
   -- deleta emails duplicados
   ----------------------------------------------------------
   DELETE FROM notifica_fila_email
    WHERE notifica_fila_id = v_notifica_fila_id
      AND notifica_fila_email_id NOT IN (SELECT MIN(notifica_fila_email_id)
                                           FROM notifica_fila_email
                                          WHERE notifica_fila_id = v_notifica_fila_id
                                          GROUP BY emails_para);
   ----------------------------------------------------------
   --  marca como processado
   ----------------------------------------------------------
   v_texto   := substr(v_texto, 1, 500);
   v_assunto := substr(v_assunto, 1, 100);
   v_corpo   := substr(v_corpo, 1, 1000);
   --
   UPDATE notifica_fila
      SET flag_pend = 'N',
          assunto   = v_assunto,
          corpo     = v_corpo,
          texto     = v_texto
    WHERE notifica_fila_id = v_notifica_fila_id;
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
     'evento_pkg.notifica_processar',
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
     'evento_pkg.notifica_processar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END notifica_processar;
 --
 --
 PROCEDURE notifica_especial_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/08/2013
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a gerar notificacoes
  --  especiais que nao sao configuradas via eventos, como notificacoes de timesheet.
  --  Roda via Cold Fusion as 06:00h.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/03/2018  Nova notificação de monitoramento posicao OS.
  ------------------------------------------------------------------------------------------
  IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_erro_cod         VARCHAR2(20);
  v_erro_msg         VARCHAR2(200);
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_notifica_fila_id notifica_fila.notifica_fila_id%TYPE;
  v_assunto          notifica_fila.assunto%TYPE;
  v_corpo            notifica_fila.corpo%TYPE;
  v_texto            notifica_fila.texto%TYPE;
  v_tipo_notific     VARCHAR2(20);
  v_num_dias_limite  INTEGER;
  v_num_dias_pend    INTEGER;
  v_dia_util         INTEGER;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  --
  CURSOR c_us IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email,
          usuario_pkg.empresa_padrao_retornar(us.usuario_id) AS empresa_id
     FROM usuario us,
          pessoa  pe
    WHERE us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
      AND apontam_pkg.em_dia_verificar(us.usuario_id, v_tipo_notific) = 0
    ORDER BY empresa_id;
  --
  -- cursor para monitoramento da posicao das OS
  CURSOR c_os1 IS
  -- configuracao por tipo de OS
   SELECT DISTINCT jo.empresa_id,
                   ti.tipo_os_id,
                   ti.codigo,
                   ti.nome,
                   ev.descricao AS evento,
                   nc.emails,
                   ec.email_assunto,
                   ec.email_corpo
     FROM ordem_servico   os,
          job             jo,
          tipo_os         ti,
          evento_config   ec,
          evento          ev,
          tipo_objeto     tb,
          tipo_acao       ta,
          notifica_config nc
    WHERE os.job_id = jo.job_id
      AND os.status IN ('DIST', 'ACEI', 'EMEX', 'AVAL')
      AND os.tipo_os_id = ti.tipo_os_id
      AND ec.empresa_id = jo.empresa_id
      AND ec.tipo_os_id = os.tipo_os_id
      AND ec.evento_id = ev.evento_id
      AND ev.tipo_objeto_id = tb.tipo_objeto_id
      AND tb.codigo = 'ORDEM_SERVICO'
      AND ev.tipo_acao_id = ta.tipo_acao_id
      AND ta.codigo = 'NOTIFICAR_POS'
      AND ec.flag_notifica_email = 'S'
      AND ec.evento_config_id = nc.evento_config_id
      AND nc.tipo_notific = 'EMAIL'
      AND nc.emails IS NOT NULL
   UNION
   -- configuracao generica, sem ser por tipo de OS
   SELECT DISTINCT jo.empresa_id,
                   ti.tipo_os_id,
                   ti.codigo,
                   ti.nome,
                   ev.descricao AS evento,
                   nc.emails,
                   ec.email_assunto,
                   ec.email_corpo
     FROM ordem_servico   os,
          job             jo,
          tipo_os         ti,
          evento_config   ec,
          evento          ev,
          tipo_objeto     tb,
          tipo_acao       ta,
          notifica_config nc
    WHERE os.job_id = jo.job_id
      AND os.status IN ('DIST', 'ACEI', 'EMEX', 'AVAL')
      AND os.tipo_os_id = ti.tipo_os_id
      AND ec.empresa_id = jo.empresa_id
      AND ec.tipo_os_id IS NULL
      AND ec.evento_id = ev.evento_id
      AND ev.tipo_objeto_id = tb.tipo_objeto_id
      AND tb.codigo = 'ORDEM_SERVICO'
      AND ev.tipo_acao_id = ta.tipo_acao_id
      AND ta.codigo = 'NOTIFICAR_POS'
      AND ec.flag_notifica_email = 'S'
      AND ec.evento_config_id = nc.evento_config_id
      AND nc.tipo_notific = 'EMAIL'
      AND nc.emails IS NOT NULL
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  ------------------------------------------------------------
  -- geracao de notificacoes para TS - APONTAMENTO
  ------------------------------------------------------------
  v_tipo_notific := 'NOTIF_APONT';
  --
  FOR r_us IN c_us
  LOOP
   -- verifica se eh dia util (nao gera notificacoes aos
   -- sabados, domingos e feriados)
   v_dia_util := feriado_pkg.dia_util_verificar(r_us.usuario_id, trunc(SYSDATE), 'S');
   --
   IF v_dia_util = 1 THEN
    -- verifica quantos dias o usuario ficou sem apontar ou sem submeter
    SELECT COUNT(*)
      INTO v_num_dias_pend
      FROM apontam_data
     WHERE usuario_id = r_us.usuario_id
       AND status IN ('PEND', 'APON', 'REPR')
       AND data <= trunc(SYSDATE);
    --
    v_num_dias_limite := round(numero_converter(empresa_pkg.parametro_retornar(r_us.empresa_id,
                                                                               'NUM_DIAS_UTEIS_SEM_APONTAM')),
                               0);
    --
    v_assunto := empresa_pkg.parametro_retornar(r_us.empresa_id, 'NOTIF_APONTAM_PEND_ASSUNTO');
    v_texto   := v_assunto;
    v_corpo   := empresa_pkg.parametro_retornar(r_us.empresa_id, 'NOTIF_APONTAM_PEND_CORPO');
    --
    v_corpo := REPLACE(v_corpo, '[dias_max]', to_char(v_num_dias_limite));
    v_corpo := REPLACE(v_corpo, '[dias_pend]', to_char(v_num_dias_pend));
    --
    SELECT seq_notifica_fila.nextval
      INTO v_notifica_fila_id
      FROM dual;
    --
    v_identif_objeto := 'Bloqueio eminente de timesheet/apontamento: ' || r_us.nome_para;
    --
    INSERT INTO notifica_fila
     (notifica_fila_id,
      empresa_id,
      historico_id,
      evento_config_id,
      usuario_de_id,
      data_evento,
      classe_evento,
      cod_acao,
      cod_objeto,
      objeto_id,
      identif_objeto,
      flag_pend,
      texto,
      assunto,
      corpo)
    VALUES
     (v_notifica_fila_id,
      r_us.empresa_id,
      NULL,
      NULL,
      v_usuario_admin_id,
      SYSDATE,
      'AVISO',
      'NOTIFICAR',
      'SISTEMA',
      0,
      v_identif_objeto,
      'N',
      v_texto,
      v_assunto,
      v_corpo);
    --
    /* nao gera notificacao via interface
    notifica_fila_usu_inserir(v_notifica_fila_id,r_us.usuario_id,r_us.nome_para,
                              v_erro_cod, v_erro_msg); */
    --
    IF r_us.email_para IS NOT NULL THEN
     notifica_fila_email_inserir(v_notifica_fila_id,
                                 r_us.email_para,
                                 r_us.nome_para,
                                 v_erro_cod,
                                 v_erro_msg);
    END IF;
   END IF; -- fom do IF v_dia_util = 1
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de notificacoes para TS - APROVACAO
  ------------------------------------------------------------
  v_tipo_notific := 'NOTIF_APROV';
  --
  FOR r_us IN c_us
  LOOP
   v_assunto := empresa_pkg.parametro_retornar(r_us.empresa_id, 'NOTIF_APROV_PEND_ASSUNTO');
   v_texto   := v_assunto;
   v_corpo   := empresa_pkg.parametro_retornar(r_us.empresa_id, 'NOTIF_APROV_PEND_CORPO');
   --
   SELECT seq_notifica_fila.nextval
     INTO v_notifica_fila_id
     FROM dual;
   --
   v_identif_objeto := 'Bloqueio eminente de timesheet/aprovação: ' || r_us.nome_para;
   --
   INSERT INTO notifica_fila
    (notifica_fila_id,
     empresa_id,
     historico_id,
     evento_config_id,
     usuario_de_id,
     data_evento,
     classe_evento,
     cod_acao,
     cod_objeto,
     objeto_id,
     identif_objeto,
     flag_pend,
     texto,
     assunto,
     corpo)
   VALUES
    (v_notifica_fila_id,
     r_us.empresa_id,
     NULL,
     NULL,
     v_usuario_admin_id,
     SYSDATE,
     'AVISO',
     'NOTIFICAR',
     'SISTEMA',
     0,
     v_identif_objeto,
     'N',
     v_texto,
     v_assunto,
     v_corpo);
   --
   notifica_fila_usu_inserir(v_notifica_fila_id,
                             r_us.usuario_id,
                             r_us.nome_para,
                             v_erro_cod,
                             v_erro_msg);
   --
   IF r_us.email_para IS NOT NULL THEN
    notifica_fila_email_inserir(v_notifica_fila_id,
                                r_us.email_para,
                                r_us.nome_para,
                                v_erro_cod,
                                v_erro_msg);
   END IF;
  END LOOP;
  ------------------------------------------------------------
  -- geracao de notificacoes - ORDEM_SERVICO
  ------------------------------------------------------------
  -- monitoramento da posicao das OS
  --
  FOR r_os1 IN c_os1
  LOOP
   v_assunto := nvl(r_os1.email_assunto, r_os1.evento);
   v_corpo   := r_os1.email_corpo;
   v_texto   := NULL;
   --
   SELECT seq_notifica_fila.nextval
     INTO v_notifica_fila_id
     FROM dual;
   --
   v_identif_objeto := r_os1.codigo || ' - ' || r_os1.nome;
   --
   INSERT INTO notifica_fila
    (notifica_fila_id,
     empresa_id,
     historico_id,
     evento_config_id,
     usuario_de_id,
     data_evento,
     classe_evento,
     cod_acao,
     cod_objeto,
     objeto_id,
     identif_objeto,
     flag_pend,
     texto,
     assunto,
     corpo)
   VALUES
    (v_notifica_fila_id,
     r_os1.empresa_id,
     NULL,
     NULL,
     v_usuario_admin_id,
     SYSDATE,
     'AVISO',
     'NOTIFICAR_POS',
     'ORDEM_SERVICO',
     r_os1.tipo_os_id,
     v_identif_objeto,
     'N',
     v_texto,
     v_assunto,
     v_corpo);
   --
   notifica_fila_email_inserir(v_notifica_fila_id, r_os1.emails, NULL, v_erro_cod, v_erro_msg);
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
     'evento_pkg.notifica_especial_processar',
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
     'evento_pkg.notifica_especial_processar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END notifica_especial_processar;
 --
 --
 PROCEDURE notifica_aprovador_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 05/08/2013
  -- DESCRICAO: procedure que gera notificacoes para usuarios aprovadores de TSH com
  --   pendencias de aprovacao. Disparada manualmente via relatório de Monitorar Aprovação
  --   de Horas Atrasadas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_notifica_fila_id notifica_fila.notifica_fila_id%TYPE;
  v_identif_objeto   notifica_fila.identif_objeto%TYPE;
  v_assunto          notifica_fila.assunto%TYPE;
  v_corpo            notifica_fila.corpo%TYPE;
  v_texto            notifica_fila.texto%TYPE;
  v_tipo_notific     VARCHAR2(20);
  --
  CURSOR c_us IS
   SELECT us.usuario_id,
          pe.apelido AS nome_para,
          TRIM(pe.email) AS email_para,
          us.flag_notifica_email AS flag_recebe_email
     FROM usuario us,
          pessoa  pe
    WHERE us.flag_ativo = 'S'
      AND us.usuario_id = pe.usuario_id
      AND apontam_pkg.em_dia_verificar(us.usuario_id, v_tipo_notific) = 0
      AND usuario_pkg.empresa_padrao_retornar(us.usuario_id) = p_empresa_id
    ORDER BY us.usuario_id;
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  ------------------------------------------------------------
  -- geracao de notificacoes para TS - APROVACAO
  ------------------------------------------------------------
  v_tipo_notific := 'BLOQ_APROV';
  v_assunto      := empresa_pkg.parametro_retornar(p_empresa_id, 'NOTIF_APROV_PEND_ASSUNTO');
  v_texto        := v_assunto;
  v_corpo        := empresa_pkg.parametro_retornar(p_empresa_id, 'NOTIF_APROV_PEND_CORPO');
  --
  FOR r_us IN c_us
  LOOP
   SELECT seq_notifica_fila.nextval
     INTO v_notifica_fila_id
     FROM dual;
   --
   v_identif_objeto := 'Aprovação de timesheet em atraso: ' || r_us.nome_para;
   --
   INSERT INTO notifica_fila
    (notifica_fila_id,
     empresa_id,
     historico_id,
     evento_config_id,
     usuario_de_id,
     data_evento,
     classe_evento,
     cod_acao,
     cod_objeto,
     objeto_id,
     identif_objeto,
     flag_pend,
     texto,
     assunto,
     corpo)
   VALUES
    (v_notifica_fila_id,
     p_empresa_id,
     NULL,
     NULL,
     v_usuario_admin_id,
     SYSDATE,
     'AVISO',
     'NOTIFICAR',
     'SISTEMA',
     0,
     v_identif_objeto,
     'N',
     v_texto,
     v_assunto,
     v_corpo);
   --
   notifica_fila_usu_inserir(v_notifica_fila_id,
                             r_us.usuario_id,
                             r_us.nome_para,
                             p_erro_cod,
                             p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   IF r_us.email_para IS NOT NULL THEN
    notifica_fila_email_inserir(v_notifica_fila_id,
                                r_us.email_para,
                                r_us.nome_para,
                                p_erro_cod,
                                p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
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
 END notifica_aprovador_processar;
 --
 --
 PROCEDURE notifica_usuario_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza               ProcessMind     DATA: 24/11/2023
  -- DESCRICAO: procedure que gera notificacoes para usuarios executores que possuem workflows a serem executados
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         02/01/2023  Ajuste query usuario e verificacao de parametro
  -- Ana Luiza         26/03/2024  Notifica usuario mesmo que ja tenha respondido
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_usuario_admin_id usuario.usuario_id%TYPE;
  v_notifica_fila_id notifica_fila.notifica_fila_id%TYPE;
  v_identif_objeto   notifica_fila.identif_objeto%TYPE;
  v_assunto          notifica_fila.assunto%TYPE;
  v_corpo            notifica_fila.corpo%TYPE;
  v_texto            notifica_fila.texto%TYPE;
  --
  v_parametro VARCHAR2(50);
  --
  --
 BEGIN
  v_qt := 0;
  --
  SELECT MAX(usuario_id)
    INTO v_usuario_admin_id
    FROM usuario
   WHERE flag_admin_sistema = 'S';
  --
  FOR r_emp IN (SELECT empresa_id
                  FROM empresa
                 WHERE empresa_pkg.parametro_retornar(empresa_id, 'USAR_CONFIRM_PRAZO_ATIV') = 'S')
  LOOP
   ------------------------------------------------------------
   -- geracao de notificacoes
   ------------------------------------------------------------
   v_assunto := 'Notificação por Worflow em execução/aceite';
   v_texto   := 'Confirmar execução de Atividades';
   v_corpo   := 'Existe Worflows em execução ou em aceite na data de hoje';
   --
   /*
   FOR r_us IN
     (SELECT us.usuario_id,
             pe.apelido AS nome_para,
             TRIM(pe.email) AS email_para,
             us.flag_notifica_email AS flag_recebe_email
     FROM   ordem_servico os
     INNER  JOIN os_usuario osu ON os.ordem_servico_id = osu.ordem_servico_id
     INNER  JOIN usuario us ON osu.usuario_id = us.usuario_id
     INNER  JOIN pessoa pe ON us.usuario_id = pe.usuario_id
     WHERE TRUNC(os.data_termino) = TRUNC(SYSDATE)
     AND    osu.status IN ('EMEX', 'ACEI')
     AND    us.flag_ativo = 'S'
     AND    usuario_pkg.empresa_padrao_retornar(us.usuario_id) = p_empresa_id
     ORDER BY us.usuario_id)*/
   FOR r_us IN (SELECT us.usuario_id,
                       pe.apelido AS nome_para,
                       TRIM(pe.email) AS email_para,
                       us.flag_notifica_email AS flag_recebe_email
                  FROM usuario us
                 INNER JOIN pessoa pe
                    ON us.usuario_id = pe.usuario_id
                 WHERE us.flag_ativo = 'S'
                   AND usuario_pkg.empresa_padrao_retornar(us.usuario_id) = r_emp.empresa_id
                   AND EXISTS
                 (SELECT 1
                          FROM ordem_servico os
                         INNER JOIN os_usuario osu
                            ON os.ordem_servico_id = osu.ordem_servico_id
                         INNER JOIN os_usuario_data osd
                            ON os.ordem_servico_id = osd.ordem_servico_id
                           AND osd.usuario_id = osu.usuario_id
                         WHERE osu.usuario_id = us.usuario_id
                              --AND trunc(os.data_termino) = trunc(SYSDATE)--ALCBO_260324
                           AND osu.status IN ('EMEX', 'ACEI')
                              --AND (osu.status_aux IS NULL OR osu.status_aux = 'PEND')--ALCBO_260324
                           AND osd.data = (SELECT MAX(o1.data)
                                             FROM os_usuario_data o1
                                            WHERE o1.ordem_servico_id = osd.ordem_servico_id
                                              AND o1.usuario_id = osd.usuario_id)
                           AND trunc(osd.data) = trunc(SYSDATE))
                 ORDER BY us.usuario_id)
   LOOP
    SELECT seq_notifica_fila.nextval
      INTO v_notifica_fila_id
      FROM dual;
    --
    --v_identif_objeto := 'Aprovação de timesheet em atraso: ' || r_us.nome_para;
    v_identif_objeto := 'Aviso de workfow em execução ou aceite: ' || r_us.nome_para;
    --
    INSERT INTO notifica_fila
     (notifica_fila_id,
      empresa_id,
      historico_id,
      evento_config_id,
      usuario_de_id,
      data_evento,
      classe_evento,
      cod_acao,
      cod_objeto,
      objeto_id,
      identif_objeto,
      flag_pend,
      texto,
      assunto,
      corpo)
    VALUES
     (v_notifica_fila_id,
      r_emp.empresa_id,
      NULL,
      NULL,
      v_usuario_admin_id,
      SYSDATE,
      'AVISO',
      'NOTIFICAR_EXEC',
      'SISTEMA',
      0,
      v_identif_objeto,
      'N',
      v_texto,
      v_assunto,
      v_corpo);
    --
    notifica_fila_usu_inserir(v_notifica_fila_id,
                              r_us.usuario_id,
                              r_us.nome_para,
                              p_erro_cod,
                              p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
    --
    IF r_us.email_para IS NOT NULL THEN
     notifica_fila_email_inserir(v_notifica_fila_id,
                                 r_us.email_para,
                                 r_us.nome_para,
                                 p_erro_cod,
                                 p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
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
 END notifica_usuario_processar;
 --
 --
 PROCEDURE notifica_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 15/07/2013
  -- DESCRICAO: marca a notificacao como lida ou nao lida.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_notifica_fila_usu_id IN notifica_fila_usu.notifica_fila_usu_id%TYPE,
  p_flag_lido            IN notifica_fila_usu.flag_lido%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_usuario_para_id notifica_fila_usu.usuario_para_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM notifica_fila_usu
   WHERE notifica_fila_usu_id = p_notifica_fila_usu_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa notificação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT usuario_para_id
    INTO v_usuario_para_id
    FROM notifica_fila_usu
   WHERE notifica_fila_usu_id = p_notifica_fila_usu_id;
  --
  IF v_usuario_para_id <> p_usuario_sessao_id THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa notificação não está endereçada à você.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_lido) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag lido inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE notifica_fila_usu
     SET flag_lido = p_flag_lido
   WHERE notifica_fila_usu_id = p_notifica_fila_usu_id;
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
 END notifica_marcar;
 --
 --
 PROCEDURE email_enviado_marcar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 15/07/2013
  -- DESCRICAO: marca o email como enviado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_notifica_fila_id       IN notifica_fila_email.notifica_fila_id%TYPE,
  p_notifica_fila_email_id IN notifica_fila_email.notifica_fila_email_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_notifica_fila_email_id, 0) <> 0 THEN
   -- marca apenas o email especificado  como enviado
   UPDATE notifica_fila_email
      SET flag_enviado = 'S'
    WHERE notifica_fila_email_id = p_notifica_fila_email_id;
  END IF;
  --
  IF nvl(p_notifica_fila_id, 0) <> 0 THEN
   -- marca todos os emails associados a um evento como enviados
   UPDATE notifica_fila_email
      SET flag_enviado = 'S'
    WHERE notifica_fila_id = p_notifica_fila_id;
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
 END email_enviado_marcar;
 --
 --
 PROCEDURE motivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 23/12/2015
  -- DESCRICAO: Inclusao de motivo do evento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Henrique          16/08/2019  Novo parametro p_tipo_cliente_agencia (Cliente/Agência)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_evento_id            IN evento_motivo.evento_id%TYPE,
  p_tipo_os_id           IN evento_motivo.tipo_os_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_ordem                IN VARCHAR2,
  p_tipo_cliente_agencia IN evento_motivo.tipo_cliente_agencia%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_ordem            evento_motivo.ordem%TYPE;
  v_evento_motivo_id evento_motivo.evento_motivo_id%TYPE;
  v_cod_objeto       tipo_objeto.codigo%TYPE;
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
    FROM evento
   WHERE evento_id = p_evento_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse evento não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EVENTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_os_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_os
    WHERE tipo_os_id = p_tipo_os_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de Workflow não existe.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT ti.codigo
    INTO v_cod_objeto
    FROM evento      ev,
         tipo_objeto ti
   WHERE ev.evento_id = p_evento_id
     AND ev.tipo_objeto_id = ti.tipo_objeto_id;
  --
  IF nvl(p_tipo_os_id, 0) > 0 AND v_cod_objeto <> 'ORDEM_SERVICO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O Tipo de Workflow só deve ser especificado para eventos de Workflow.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := 0;
  IF TRIM(p_ordem) IS NOT NULL THEN
   IF inteiro_validar(p_ordem) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
    RAISE v_exception;
   END IF;
   --
   v_ordem := to_number(p_ordem);
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM evento_motivo
   WHERE empresa_id = p_empresa_id
     AND evento_id = p_evento_id
     AND nvl(tipo_os_id, 0) = nvl(p_tipo_os_id, 0)
     AND upper(nome) = upper(TRIM(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse motivo já existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_cliente_agencia) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo Cliente/' || v_lbl_agencia_singular || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_evento_motivo.nextval
    INTO v_evento_motivo_id
    FROM dual;
  --
  INSERT INTO evento_motivo
   (evento_motivo_id,
    empresa_id,
    evento_id,
    tipo_os_id,
    nome,
    ordem,
    tipo_cliente_agencia)
  VALUES
   (v_evento_motivo_id,
    p_empresa_id,
    p_evento_id,
    zvl(p_tipo_os_id, NULL),
    TRIM(p_nome),
    v_ordem,
    TRIM(p_tipo_cliente_agencia));
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
 END motivo_adicionar;
 --
 --
 PROCEDURE motivo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 23/12/2015
  -- DESCRICAO: Atualizacao de motivo do evento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Henrique          16/08/2019  Novo parametro p_tipo_cliente_agencia (Cliente/Agência)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_evento_motivo_id     IN evento_motivo.evento_motivo_id%TYPE,
  p_nome                 IN VARCHAR2,
  p_ordem                IN VARCHAR2,
  p_tipo_cliente_agencia IN evento_motivo.tipo_cliente_agencia%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_ordem      evento_motivo.ordem%TYPE;
  v_evento_id  evento_motivo.evento_id%TYPE;
  v_tipo_os_id evento_motivo.tipo_os_id%TYPE;
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
    FROM evento_motivo
   WHERE evento_motivo_id = p_evento_motivo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse motivo não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EVENTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT evento_id,
         tipo_os_id
    INTO v_evento_id,
         v_tipo_os_id
    FROM evento_motivo
   WHERE evento_motivo_id = p_evento_motivo_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := 0;
  IF TRIM(p_ordem) IS NOT NULL THEN
   IF inteiro_validar(p_ordem) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Ordem inválida (' || p_ordem || ').';
    RAISE v_exception;
   END IF;
   --
   v_ordem := to_number(p_ordem);
  END IF;
  --
  IF TRIM(p_tipo_cliente_agencia) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do Tipo Cliente/' || v_lbl_agencia_singular || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM evento_motivo
   WHERE empresa_id = p_empresa_id
     AND evento_id = v_evento_id
     AND upper(nome) = upper(TRIM(p_nome))
     AND nvl(tipo_os_id, 0) = nvl(v_tipo_os_id, 0)
     AND evento_motivo_id <> p_evento_motivo_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse motivo já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE evento_motivo
     SET nome                 = TRIM(p_nome),
         ordem                = v_ordem,
         tipo_cliente_agencia = TRIM(p_tipo_cliente_agencia)
   WHERE evento_motivo_id = p_evento_motivo_id;
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
 END motivo_atualizar;
 --
 --
 PROCEDURE motivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                  ProcessMind     DATA: 23/12/2015
  -- DESCRICAO: Exclusao de motivo do evento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
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
    FROM evento_motivo
   WHERE evento_motivo_id = p_evento_motivo_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse motivo não existe.';
   RAISE v_exception;
  END IF;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'EVENTO_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM evento_motivo
   WHERE evento_motivo_id = p_evento_motivo_id;
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
 END motivo_excluir;
 --
 --
 FUNCTION job_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 08/08/2013
  -- DESCRICAO: retorna o job_id do objeto indicado (Briefing, OS, etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/05/2020  Novos objetos: SOBRA, ABATIMENTO
  ------------------------------------------------------------------------------------------
  p_cod_objeto IN tipo_objeto.codigo%TYPE,
  p_objeto_id  IN NUMBER
 ) RETURN NUMBER AS
  v_qt             INTEGER;
  v_retorno        NUMBER;
  v_objeto_aux_id  comentario.objeto_id%TYPE;
  v_cod_objeto_aux tipo_objeto.codigo%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_cod_objeto IN ('JOB', 'JOB_HORAS') THEN
   v_retorno := p_objeto_id;
  ELSIF p_cod_objeto = 'BRIEFING' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM briefing
    WHERE briefing_id = p_objeto_id;
  ELSIF p_cod_objeto = 'ORDEM_SERVICO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM ordem_servico
    WHERE ordem_servico_id = p_objeto_id;
  ELSIF p_cod_objeto = 'CRONOGRAMA' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM cronograma
    WHERE cronograma_id = p_objeto_id;
  ELSIF p_cod_objeto = 'DOCUMENTO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM documento
    WHERE documento_id = p_objeto_id;
  ELSIF p_cod_objeto = 'ORCAMENTO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM orcamento
    WHERE orcamento_id = p_objeto_id;
  ELSIF p_cod_objeto = 'ADIANT_DESP' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM adiant_desp
    WHERE adiant_desp_id = p_objeto_id;
  ELSIF p_cod_objeto = 'SOBRA' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM sobra
    WHERE sobra_id = p_objeto_id;
  ELSIF p_cod_objeto = 'ABATIMENTO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM abatimento
    WHERE abatimento_id = p_objeto_id;
  ELSIF p_cod_objeto = 'CARTA_ACORDO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM carta_acordo
    WHERE carta_acordo_id = p_objeto_id;
   --
   IF v_retorno IS NULL THEN
    SELECT MAX(it.job_id)
      INTO v_retorno
      FROM item_carta ic,
           item       it
     WHERE ic.carta_acordo_id = p_objeto_id
       AND ic.item_id = it.item_id;
   END IF;
  ELSIF p_cod_objeto = 'NOTA_FISCAL' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM nota_fiscal
    WHERE nota_fiscal_id = p_objeto_id;
   --
   IF v_retorno IS NULL THEN
    SELECT MAX(it.job_id)
      INTO v_retorno
      FROM item_nota io,
           item      it
     WHERE io.nota_fiscal_id = p_objeto_id
       AND io.item_id = it.item_id;
   END IF;
  ELSIF p_cod_objeto = 'FATURAMENTO' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM faturamento
    WHERE faturamento_id = p_objeto_id;
   --
   IF v_retorno IS NULL THEN
    SELECT MAX(it.job_id)
      INTO v_retorno
      FROM item_fatur ia,
           item       it
     WHERE ia.faturamento_id = p_objeto_id
       AND ia.item_id = it.item_id;
   END IF;
  ELSIF p_cod_objeto = 'TAREFA' THEN
   SELECT MAX(job_id)
     INTO v_retorno
     FROM tarefa
    WHERE tarefa_id = p_objeto_id;
  ELSIF p_cod_objeto = 'COMENTARIO' THEN
   -- recupera o objeto do comentario
   SELECT MAX(co.objeto_id),
          MAX(ti.codigo)
     INTO v_objeto_aux_id,
          v_cod_objeto_aux
     FROM comentario  co,
          tipo_objeto ti
    WHERE co.comentario_id = p_objeto_id
      AND co.tipo_objeto_id = ti.tipo_objeto_id;
   --
   IF v_cod_objeto_aux = 'JOB' THEN
    v_retorno := v_objeto_aux_id;
   ELSIF v_cod_objeto_aux = 'ORDEM_SERVICO' THEN
    SELECT MAX(job_id)
      INTO v_retorno
      FROM ordem_servico
     WHERE ordem_servico_id = v_objeto_aux_id;
   ELSIF v_cod_objeto_aux = 'TAREFA' THEN
    SELECT MAX(job_id)
      INTO v_retorno
      FROM tarefa
     WHERE tarefa_id = v_objeto_aux_id;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END job_id_retornar;
 --
 --
 FUNCTION contrato_id_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 26/05/2020
  -- DESCRICAO: retorna o contrato_id do objeto indicado (Faturamento, abatimento, etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_cod_objeto IN tipo_objeto.codigo%TYPE,
  p_objeto_id  IN NUMBER
 ) RETURN NUMBER AS
  v_qt             INTEGER;
  v_retorno        NUMBER;
  v_objeto_aux_id  comentario.objeto_id%TYPE;
  v_cod_objeto_aux tipo_objeto.codigo%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  IF p_cod_objeto IN ('CONTRATO') THEN
   v_retorno := p_objeto_id;
  ELSIF p_cod_objeto = 'ABATIMENTO_CTR' THEN
   SELECT MAX(pc.contrato_id)
     INTO v_retorno
     FROM abatimento_ctr   ab,
          parcela_contrato pc
    WHERE ab.abatimento_ctr_id = p_objeto_id
      AND ab.parcela_contrato_id = pc.parcela_contrato_id;
  ELSIF p_cod_objeto = 'FATURAMENTO_CTR' THEN
   SELECT MAX(contrato_id)
     INTO v_retorno
     FROM faturamento_ctr
    WHERE faturamento_ctr_id = p_objeto_id;
  ELSIF p_cod_objeto = 'COMENTARIO' THEN
   -- recupera o objeto do comentario
   SELECT MAX(co.objeto_id),
          MAX(ti.codigo)
     INTO v_objeto_aux_id,
          v_cod_objeto_aux
     FROM comentario  co,
          tipo_objeto ti
    WHERE co.comentario_id = p_objeto_id
      AND co.tipo_objeto_id = ti.tipo_objeto_id;
   --
   IF v_cod_objeto_aux = 'CONTRATO' THEN
    v_retorno := v_objeto_aux_id;
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := NULL;
   RETURN v_retorno;
 END contrato_id_retornar;
 --
END; -- EVENTO_PKG

/
