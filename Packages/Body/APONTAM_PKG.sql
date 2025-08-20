--------------------------------------------------------
--  DDL for Package Body APONTAM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APONTAM_PKG" IS
 --
 g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 --
 --
 PROCEDURE acao_executar
 -----------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/02/2013
  -- DESCRICAO: Executa acao de transicao de status do apontamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  -------------------------------------------------------
  -- Silvia            27/12/2013  Na aprovacao de horas de um determinado usuario,
  --                               verifica
  --                               apontamentos pendentes em fim-de-semana ou feriado
  --                               anteriores ao periodo, e exclui.
  -- Silvia            28/05/2013  Guardar usuario aprovador.
  -- Silvia            18/07/2014  Novo parametro motivo e nova tabela que grava eventos.
  -- Silvia            23/06/2015  Grava data do submeter (data_apont).
  -- Silvia            16/12/2016  Novo parametro flag_verifica_horas que permite desligar
  --                               consistencias de preenchimento de horas.
  -- Silvia            14/01/2020  Despreza config de aprovacao do usuario caso a empresa
  --                               nao tenha aprovacao.
  -- Silvia            16/07/2020  Submete o que der e Aprova o que der
  -- Silvia            06/07/2021  Salva o status antes do encerramento
  -- Silvia            15/09/2022  Nova tabela apontam_oport
  -- Ana Luiza         16/08/2024  Adicionado condicao para
  --                               quando usuário aponta 0 status volta pendente
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_usuario_apontam_id  IN apontam_data.usuario_id%TYPE,
  p_data_ini            IN apontam_data.data%TYPE,
  p_data_fim            IN apontam_data.data%TYPE,
  p_cod_acao            IN ts_transicao.cod_acao%TYPE,
  p_motivo              IN apontam_data_ev.motivo%TYPE,
  p_flag_verifica_horas IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_exception            EXCEPTION;
  v_status_new           apontam_data.status%TYPE;
  v_flag_aprov_empresa   ts_transicao.flag_aprov_empresa%TYPE;
  v_flag_aprov_usuario   ts_transicao.flag_aprov_usuario%TYPE;
  v_flag_sem_aprov_horas usuario.flag_sem_aprov_horas%TYPE;
  v_cod_acao             ts_transicao.cod_acao%TYPE;
  v_completo             INTEGER;
  v_pula_acao            INTEGER;
  v_tem_transicao        INTEGER;
  v_apontam_data_ev_id   apontam_data_ev.apontam_data_ev_id%TYPE;
  --
  -- apontamentos a serem processados
  CURSOR c_ap IS
   SELECT apontam_data_id,
          status,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_apontam_id
      AND data BETWEEN trunc(p_data_ini) AND trunc(p_data_fim)
    ORDER BY data;
  --
  -- pendencias em dias nao uteis (para acao de APROVAR)
  CURSOR c_pe IS
   SELECT apontam_data_id,
          status,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_apontam_id
      AND data < trunc(p_data_ini)
      AND status IN ('PEND', 'APON', 'SUBM', 'REPR')
      AND feriado_pkg.dia_util_verificar(p_usuario_apontam_id, data, 'S') = 0
    ORDER BY data;
  --
 BEGIN
  v_qt                 := 0;
  v_flag_aprov_empresa := empresa_pkg.parametro_retornar(p_empresa_id, 'APONTAM_COM_APROV_GESEQP');
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_commit) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_verifica_horas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag verifica horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_acao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação não informado.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM ts_transicao
   WHERE cod_acao = p_cod_acao;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario precisa de aprovacao de horas
  SELECT flag_sem_aprov_horas
    INTO v_flag_sem_aprov_horas
    FROM usuario
   WHERE usuario_id = p_usuario_apontam_id;
  --
  IF v_flag_sem_aprov_horas = 'S'
  THEN
   v_flag_aprov_usuario := 'N';
  ELSE
   v_flag_aprov_usuario := 'S';
  END IF;
  --
  IF v_flag_aprov_empresa = 'N' AND v_flag_aprov_usuario = 'S'
  THEN
   -- a configuracao da empresa nao tem aprovacao. Despreza a cofig
   -- do usuario.
   v_flag_aprov_usuario := 'N';
  END IF;
  --
  IF p_cod_acao = 'SUBMETER'
  THEN
   -- verifica se existem apontamentos a serem submetidos ou pendentes
   -- antes desse periodo.
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_data
    WHERE usuario_id = p_usuario_apontam_id
      AND data < trunc(p_data_ini)
      AND status IN ('PEND', 'APON', 'REPR');
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem apontamentos não submetidos ou pendentes anteriores a ' ||
                  data_hora_mostrar(p_data_ini) || '.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  --
  FOR r_ap IN c_ap
  LOOP
   v_cod_acao  := p_cod_acao;
   v_pula_acao := 0;
   v_completo  := apontam_pkg.completo_verificar(p_usuario_apontam_id,
                                                 p_empresa_id,
                                                 r_ap.data,
                                                 r_ap.data);
   --
   SELECT COUNT(*)
     INTO v_tem_transicao
     FROM ts_transicao
    WHERE status_de = r_ap.status
      AND cod_acao = v_cod_acao
      AND flag_aprov_usuario = v_flag_aprov_usuario
      AND flag_aprov_empresa = v_flag_aprov_empresa;
   --
   IF v_cod_acao = 'SALVAR' AND v_completo = 0
   THEN
    v_cod_acao := 'SALVAR_INCOMPLETO';
    --ALCBO_160824
    IF v_cod_acao = 'SALVAR_INCOMPLETO'
    THEN
     v_status_new := 'PEND';
     -- salva o status antes do encerramento
     UPDATE apontam_data
        SET status_antes_ence = r_ap.status,
            status            = v_status_new
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
   
   END IF;
   --
   IF p_flag_verifica_horas = 'S'
   THEN
    -- antes esse paramento servia para controlar se as horas
    -- completas iriam ser consistidas ou nao. Com a mudanca para
    -- salvamento unitario, a transicao eh pulada caso incompleto.
    IF v_cod_acao = 'SUBMETER' AND v_completo = 0
    THEN
     v_pula_acao := 1;
     /*
     p_erro_cod := '90000';
     p_erro_msg := 'Os apontamentos não estão completos para serem submetidos (' ||
                   data_mostrar(r_ap.data) || ').';
     RAISE v_exception;*/
    END IF;
    --
    IF v_cod_acao = 'APROVAR' AND v_completo = 0
    THEN
     v_pula_acao := 1;
     /*
     p_erro_cod := '90000';
     p_erro_msg := 'Os apontamentos não estão completos para serem aprovados (' ||
                   data_mostrar(r_ap.data) || ').';
     RAISE v_exception;*/
    END IF;
   END IF;
   --
   IF v_tem_transicao > 0 AND v_pula_acao = 0
   THEN
    -- transicao encontrada e nao pula a acao de transicao de status.
    -- Faz o processamento.
    SELECT status_para
      INTO v_status_new
      FROM ts_transicao
     WHERE status_de = r_ap.status
       AND cod_acao = v_cod_acao
       AND flag_aprov_usuario = v_flag_aprov_usuario
       AND flag_aprov_empresa = v_flag_aprov_empresa;
    --
    IF v_cod_acao = 'ENCERRAR'
    THEN
     -- salva o status antes do encerramento
     UPDATE apontam_data
        SET status_antes_ence = r_ap.status
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
    --
    IF v_cod_acao = 'REABRIR'
    THEN
     -- limpa o status antes do encerramento
     UPDATE apontam_data
        SET status_antes_ence = NULL
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
    --
    UPDATE apontam_data
       SET status = v_status_new
     WHERE usuario_id = p_usuario_apontam_id
       AND data = r_ap.data;
    --
    IF v_cod_acao = 'APROVAR'
    THEN
     UPDATE apontam_data
        SET usuario_aprov_id = p_usuario_sessao_id,
            data_aprov       = SYSDATE
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
    --
    IF v_cod_acao = 'SUBMETER'
    THEN
     UPDATE apontam_data
        SET data_apont = SYSDATE
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
    --
    IF r_ap.status = 'APRO' AND v_cod_acao IN ('DEVOLVER', 'REPROVAR')
    THEN
     UPDATE apontam_data
        SET usuario_aprov_id = NULL,
            data_aprov       = NULL
      WHERE usuario_id = p_usuario_apontam_id
        AND data = r_ap.data;
    
    END IF;
    --
    IF v_cod_acao NOT LIKE 'SALVAR%'
    THEN
     -- desmarca o mesmo evento anterior como recente
     UPDATE apontam_data_ev
        SET flag_recente = 'N'
      WHERE apontam_data_id = r_ap.apontam_data_id
        AND status_de = r_ap.status
        AND cod_acao = v_cod_acao;
     --
     -- grava novo evento associado ao apontamento
     SELECT seq_apontam_data_ev.nextval
       INTO v_apontam_data_ev_id
       FROM dual;
     --
     INSERT INTO apontam_data_ev
      (apontam_data_ev_id,
       apontam_data_id,
       usuario_resp_id,
       data_evento,
       motivo,
       status_de,
       status_para,
       cod_acao,
       flag_recente)
     VALUES
      (v_apontam_data_ev_id,
       r_ap.apontam_data_id,
       p_usuario_sessao_id,
       SYSDATE,
       TRIM(p_motivo),
       r_ap.status,
       v_status_new,
       v_cod_acao,
       'S');
     --
    END IF;
   
   END IF;
  
  END LOOP;
  --
  IF p_cod_acao = 'APROVAR'
  THEN
   -- verifica se existem apontamentos pendentes em fim-de-semana ou feriado
   -- antes desse periodo.
   FOR r_pe IN c_pe
   LOOP
    DELETE FROM apontam_hora
     WHERE apontam_data_id = r_pe.apontam_data_id;
   
    DELETE FROM apontam_job
     WHERE apontam_data_id = r_pe.apontam_data_id;
   
    DELETE FROM apontam_oport
     WHERE apontam_data_id = r_pe.apontam_data_id;
   
    DELETE FROM apontam_data_ev
     WHERE apontam_data_id = r_pe.apontam_data_id;
   
    DELETE FROM apontam_data
     WHERE apontam_data_id = r_pe.apontam_data_id;
   
   END LOOP;
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
 END acao_executar;
 --
 --
 PROCEDURE data_criar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2004
  -- DESCRICAO: procedure a ser chamada logo apos o login do usuario, de modo a analisar e
  --  eventualmente criar registros de apontamento de data pendentes. Se a chamada da
  --  procedure for via job do sistema, cria apontamentos apenas para os usuarios que já
  --  possuem algum apontamento. (p_tipo_chamada: LOGIN ou SISTEMA).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  -- Silvia            04/05/2009  Ajuste para gerar pendencias mesmo no caso de
  --                               apontamentos futuros pre-programados.
  -- Silvia            19/08/2009  Implementação do valor de venda do usuario.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            21/05/2013  Implementacao de datas de inicio e termino de apontam.
  -- Silvia            28/12/2017  Inclusao de cargo e area do cargo.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id   IN usuario.usuario_id%TYPE,
  p_tipo_chamada IN VARCHAR2,
  p_erro_cod     OUT VARCHAR2,
  p_erro_msg     OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_aponta             INTEGER;
  v_gera_apontam       INTEGER;
  v_exception          EXCEPTION;
  v_data               apontam_data.data%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_salario_id         salario.salario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_data_apontam_ini   usuario.data_apontam_ini%TYPE;
  v_data_apontam_fim   usuario.data_apontam_fim%TYPE;
  v_nivel              apontam_data.nivel%TYPE;
  v_data_ini           DATE;
  v_data_fim           DATE;
  --
 BEGIN
  v_qt           := 0;
  v_aponta       := 0;
  v_gera_apontam := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  IF p_tipo_chamada NOT IN ('LOGIN', 'SISTEMA')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de chamada inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT data_apontam_ini,
         data_apontam_fim,
         NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_data_apontam_ini,
         v_data_apontam_fim,
         v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  v_custo_hora_en := 0;
  v_venda_hora_en := 0;
  v_salario_id    := salario_pkg.salario_id_atu_retornar(p_usuario_id);
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(venda_hora, 0)
     INTO v_custo_hora_en,
          v_venda_hora_en
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  -- verifica se o usuario é obrigado a apontar horas
  SELECT COUNT(*)
    INTO v_aponta
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S';
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- pega o ultimo apontamento gerado para o usuario
  SELECT MAX(data)
    INTO v_data
    FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND data <= trunc(SYSDATE);
  --
  IF p_tipo_chamada = 'LOGIN'
  THEN
   -- no login sempre tenta gerar o apontamento.
   v_gera_apontam := 1;
  END IF;
  --
  IF p_tipo_chamada = 'SISTEMA' AND (v_data IS NOT NULL OR v_data_apontam_ini IS NOT NULL)
  THEN
   -- no job do sistema, so tenta gerar se o usuario ja apontou alguma
   -- vez ou se tem a data de inicio definida.
   v_gera_apontam := 1;
  END IF;
  --
  IF v_data_apontam_ini IS NOT NULL
  THEN
   v_data_ini := v_data_apontam_ini - 1;
  ELSE
   IF v_data IS NULL
   THEN
    v_data_ini := trunc(SYSDATE) - 1;
   ELSE
    v_data_ini := v_data;
   END IF;
  END IF;
  --
  IF v_data_apontam_fim IS NOT NULL AND v_data_apontam_fim < trunc(SYSDATE)
  THEN
   v_data_fim := v_data_apontam_fim;
  ELSE
   v_data_fim := trunc(SYSDATE);
  END IF;
  --
  IF v_aponta > 0 AND v_gera_apontam > 0
  THEN
   -- tenta gerar o apontamento.
   v_data := v_data_ini;
   --
   -- verifica se precisa criar novos registros de apontamentos de data.
   WHILE v_data < v_data_fim
   LOOP
    v_data          := feriado_pkg.prox_dia_util_retornar(p_usuario_id, v_data, 1, 'S');
    v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_id, v_data, NULL);
    v_area_cargo_id := NULL;
    --
    IF v_cargo_id IS NOT NULL
    THEN
     SELECT MAX(area_id)
       INTO v_area_cargo_id
       FROM cargo
      WHERE cargo_id = v_cargo_id;
     --
     v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, v_data, NULL);
    END IF;
    --
    IF v_data <= v_data_fim
    THEN
     -- verifica se nessa data ja existe registro
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_data
      WHERE data = v_data
        AND usuario_id = p_usuario_id;
     --
     IF v_qt = 0
     THEN
      SELECT seq_apontam_data.nextval
        INTO v_apontam_data_id
        FROM dual;
      --
      INSERT INTO apontam_data
       (apontam_data_id,
        usuario_id,
        data,
        custo_hora,
        venda_hora,
        nivel,
        num_horas_dia,
        num_horas_prod_dia,
        status,
        cargo_id,
        area_cargo_id)
      VALUES
       (v_apontam_data_id,
        p_usuario_id,
        v_data,
        v_custo_hora_en,
        v_venda_hora_en,
        v_nivel,
        v_num_horas_dia,
        v_num_horas_prod_dia,
        'PEND',
        v_cargo_id,
        v_area_cargo_id);
     
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
 END data_criar;
 --
 --
 PROCEDURE data_geral_criar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 16/06/2004
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a analisar e
  --  eventualmente criar registros de apontamento de data pendentes para todos os usuarios.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  ------------------------------------------------------------------------------------------
  IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(20);
  v_erro_msg  VARCHAR2(200);
  --
  CURSOR c_usuario IS
   SELECT usuario_id
     FROM usuario
    WHERE flag_ativo = 'S';
  --
  r_usuario c_usuario%ROWTYPE;
  --
 BEGIN
  v_qt := 0;
  --
  FOR r_usuario IN c_usuario
  LOOP
   data_criar(r_usuario.usuario_id, 'SISTEMA', v_erro_cod, v_erro_msg);
   --
   IF v_erro_cod <> '00000'
   THEN
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
     'apontam_pkg.data_geral_criar',
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
     'apontam_pkg.data_geral_criar',
     v_erro_cod,
     v_erro_msg);
  
   COMMIT;
 END data_geral_criar;
 --
 --
 PROCEDURE data_pendente_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 29/06/2022
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo a executar a
  --   transicao de status dos apontamentos pendentes cuja hora minima a ser apontada
  --   seja igual a zero.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  ------------------------------------------------------------------------------------------
  IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(20);
  v_erro_msg  VARCHAR2(200);
  --
  CURSOR c_ts IS
   SELECT usuario_id,
          data,
          usuario_pkg.empresa_padrao_retornar(usuario_id) empresa_id
     FROM apontam_data ad
    WHERE status = 'PEND'
      AND num_horas_dia = 0;
  --
 BEGIN
  v_qt := 0;
  --
  FOR r_ts IN c_ts
  LOOP
   -- executa eventual transicao de status
   apontam_pkg.acao_executar(r_ts.usuario_id,
                             r_ts.empresa_id,
                             'N',
                             r_ts.usuario_id,
                             r_ts.data,
                             r_ts.data,
                             'SALVAR',
                             NULL,
                             'S',
                             v_erro_cod,
                             v_erro_msg);
  
   IF v_erro_cod <> '00000'
   THEN
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
     'apontam_pkg.data_geral_criar',
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
     'apontam_pkg.data_pendente_processar',
     v_erro_cod,
     v_erro_msg);
  
   COMMIT;
 END data_pendente_processar;
 --
 --
 PROCEDURE periodo_ence_criar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 19/12/2016
  -- DESCRICAO: procedure a ser chamada diariamente (via job) de modo gerar registros de
  --  periodo (mes/ano) de apontamentos a serem encerrados.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_apontam_ence_id apontam_ence.apontam_ence_id%TYPE;
  v_mes_ano         DATE;
  v_erro_cod        VARCHAR2(20);
  v_erro_msg        VARCHAR2(200);
  --
  CURSOR c_ap IS
   SELECT DISTINCT usuario_pkg.empresa_padrao_retornar(usuario_id) empresa_id,
                   substr(data_mostrar(data), 4) mes_ano
     FROM apontam_data
    WHERE status <> 'ENCE';
  --
 BEGIN
  v_qt := 0;
  --
  FOR r_ap IN c_ap
  LOOP
   v_mes_ano := data_converter('01/' || r_ap.mes_ano);
   --
   IF r_ap.empresa_id IS NOT NULL
   THEN
    SELECT MAX(apontam_ence_id)
      INTO v_apontam_ence_id
      FROM apontam_ence
     WHERE empresa_id = r_ap.empresa_id
       AND mes_ano = v_mes_ano;
    --
    IF v_apontam_ence_id IS NULL
    THEN
     SELECT seq_apontam_ence.nextval
       INTO v_apontam_ence_id
       FROM dual;
     --
     INSERT INTO apontam_ence
      (apontam_ence_id,
       empresa_id,
       mes_ano,
       flag_encerrado)
     VALUES
      (v_apontam_ence_id,
       r_ap.empresa_id,
       v_mes_ano,
       'N');
    
    END IF;
   
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
     'apontam_pkg.periodo_ence_criar',
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
     'apontam_pkg.periodo_ence_criar',
     v_erro_cod,
     v_erro_msg);
  
   COMMIT;
 END periodo_ence_criar;
 --
 --
 PROCEDURE periodo_criar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/01/2012
  -- DESCRICAO: gera pendencia de apontamentos para um determinado usuario num determinado
  --    periodo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/12/2017  Inclusao de cargo e area do cargo.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_data_ini   IN VARCHAR2,
  p_data_fim   IN VARCHAR2,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_aponta             INTEGER;
  v_exception          EXCEPTION;
  v_data               apontam_data.data%TYPE;
  v_data_ini           apontam_data.data%TYPE;
  v_data_fim           apontam_data.data%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_salario_id         salario.salario_id%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_nivel              apontam_data.nivel%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  IF data_validar(p_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inicial inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := nvl(data_converter(p_data_ini), trunc(SYSDATE));
  --
  IF data_validar(p_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_fim := nvl(data_converter(p_data_fim), trunc(SYSDATE));
  --
  IF v_data_fim < v_data_ini
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final não pode ser anterior à data inicial.';
   RAISE v_exception;
  END IF;
  --
  v_custo_hora_en := 0;
  v_venda_hora_en := 0;
  v_salario_id    := salario_pkg.salario_id_atu_retornar(p_usuario_id);
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(venda_hora, 0)
     INTO v_custo_hora_en,
          v_venda_hora_en
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  SELECT min_horas_apont_dia,
         num_horas_prod_dia,
         NULL
    INTO v_num_horas_dia,
         v_num_horas_prod_dia,
         v_nivel
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  -- verifica se o usuario é obrigado a apontar horas
  SELECT COUNT(*)
    INTO v_aponta
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S';
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data := v_data_ini - 1;
  --
  IF v_aponta > 0
  THEN
   --
   -- verifica se precisa criar novos registros de apontamentos de data.
   WHILE v_data <= v_data_fim
   LOOP
    v_data          := feriado_pkg.prox_dia_util_retornar(p_usuario_id, v_data, 1, 'S');
    v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_id, v_data, NULL);
    v_area_cargo_id := NULL;
    --
    IF v_cargo_id IS NOT NULL
    THEN
     SELECT MAX(area_id)
       INTO v_area_cargo_id
       FROM cargo
      WHERE cargo_id = v_cargo_id;
     --
     v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, v_data, NULL);
    END IF;
    --
    IF v_data <= v_data_fim
    THEN
     -- verifica se nessa data ja existe registro
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_data
      WHERE data = v_data
        AND usuario_id = p_usuario_id;
     --
     IF v_qt = 0
     THEN
      SELECT seq_apontam_data.nextval
        INTO v_apontam_data_id
        FROM dual;
      --
      INSERT INTO apontam_data
       (apontam_data_id,
        usuario_id,
        data,
        custo_hora,
        venda_hora,
        nivel,
        num_horas_dia,
        num_horas_prod_dia,
        status,
        cargo_id,
        area_cargo_id)
      VALUES
       (v_apontam_data_id,
        p_usuario_id,
        v_data,
        v_custo_hora_en,
        v_venda_hora_en,
        v_nivel,
        v_num_horas_dia,
        v_num_horas_prod_dia,
        'PEND',
        v_cargo_id,
        v_area_cargo_id);
     
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
 END periodo_criar;
 --
 --
 PROCEDURE periodo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 15/04/2015
  -- DESCRICAO: exclui apontamentos por periodo de um determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/09/2022  Nova tabela apontam_oport
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_tipo_exclusao     IN VARCHAR2,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_data_ini       DATE;
  v_data_fim       DATE;
  v_empresa_id     empresa.empresa_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_login          usuario.login%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id IS NULL OR p_usuario_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário para apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_ADMIN_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_tipo_exclusao NOT IN ('PENDENTES', 'TODOS') OR TRIM(p_tipo_exclusao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de exclusão inválida (' || p_tipo_exclusao || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_ini) IS NULL OR rtrim(p_data_fim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  v_data_fim := data_converter(p_data_fim);
  --
  IF v_data_ini > v_data_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início do período não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_obs) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_tipo_exclusao = 'TODOS'
  THEN
   DELETE FROM apontam_hora ah
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = ah.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim);
   --
   DELETE FROM apontam_job aj
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = aj.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim);
   --
   DELETE FROM apontam_oport aj
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = aj.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim);
   --
   DELETE FROM apontam_data_ev ae
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim
              AND ad.apontam_data_id = ae.apontam_data_id);
   --
   DELETE FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND data BETWEEN v_data_ini AND v_data_fim;
  
  ELSIF p_tipo_exclusao = 'PENDENTES'
  THEN
   DELETE FROM apontam_hora ah
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = ah.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim
              AND ad.status = 'PEND');
   --
   DELETE FROM apontam_job aj
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = aj.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim
              AND ad.status = 'PEND');
   --
   DELETE FROM apontam_oport aj
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.apontam_data_id = aj.apontam_data_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim
              AND ad.status = 'PEND');
   --
   DELETE FROM apontam_data_ev ae
    WHERE EXISTS (SELECT 1
             FROM apontam_data ad
            WHERE ad.usuario_id = p_usuario_id
              AND ad.data BETWEEN v_data_ini AND v_data_fim
              AND ad.apontam_data_id = ae.apontam_data_id
              AND ad.status = 'PEND');
   --
   DELETE FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status = 'PEND';
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(v_login);
  v_compl_histor   := 'Pessoa: ' || v_nome || ' - Exclusão de apontamentos no período: ' ||
                      data_mostrar(v_data_ini) || ' a ' || data_mostrar(v_data_fim) || ' - ' ||
                      p_tipo_exclusao;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   v_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
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
 END periodo_excluir;
 --
 --
 PROCEDURE periodo_aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 16/12/2016
  -- DESCRICAO: aprova apontamentos por periodo de um determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_data_ini       DATE;
  v_data_fim       DATE;
  v_empresa_id     empresa.empresa_id%TYPE;
  v_nome           pessoa.nome%TYPE;
  v_login          usuario.login%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  --
  -- apontamentos a serem processados (submetidos)
  CURSOR c_ap IS
   SELECT apontam_data_id,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status = 'SUBM'
    ORDER BY data;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id IS NULL OR p_usuario_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário para aprovação é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  SELECT MAX(u.login),
         MAX(p.nome)
    INTO v_login,
         v_nome
    FROM pessoa  p,
         usuario u
   WHERE u.usuario_id = p_usuario_id
     AND u.usuario_id = p.usuario_id;
  --
  IF v_login IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe.';
   RAISE v_exception;
  END IF;
  --
  IF p_empresa_id <> nvl(v_empresa_id, 0)
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não pertence a essa empresa (' || v_nome || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_ini) IS NULL OR rtrim(p_data_fim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  v_data_fim := data_converter(p_data_fim);
  --
  IF v_data_ini > v_data_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início do período não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   -- executa transicao de status sem consistir horas apontadas
   apontam_pkg.acao_executar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             p_usuario_id,
                             r_ap.data,
                             r_ap.data,
                             'APROVAR',
                             NULL,
                             'N',
                             p_erro_cod,
                             p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := rtrim(v_login);
  v_compl_histor   := 'Pessoa: ' || v_nome || ' - Aprovação de apontamentos no período: ' ||
                      data_mostrar(v_data_ini) || ' a ' || data_mostrar(v_data_fim);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'USUARIO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_usuario_id,
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
 END periodo_aprovar;
 --
 --
 PROCEDURE encerrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 19/12/2016
  -- DESCRICAO: encerra apontamentos da empresa/mes.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/08/2020  Novo parametro flag_forca_encer
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_flag_forca_encer  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_mes_ano         DATE;
  v_data_ini        DATE;
  v_data_fim        DATE;
  v_apontam_ence_id apontam_ence.apontam_ence_id%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_qt_pend         INTEGER;
  v_tipo_apontam_id tipo_apontam.tipo_apontam_id%TYPE;
  v_num_horas_dia   usuario.min_horas_apont_dia%TYPE;
  v_horas_atu       apontam_hora.horas%TYPE;
  v_horas_pend      apontam_hora.horas%TYPE;
  v_unid_neg_usu_id apontam_hora.unid_neg_usu_id%TYPE;
  v_papel_id        papel.papel_id%TYPE;
  v_area_papel_id   papel.area_id%TYPE;
  --
  -- apontamentos pendentes a serem completados
  -- no caso de encerramento forcado
  CURSOR c_pd IS
   SELECT ad.usuario_id,
          ad.apontam_data_id,
          ad.data,
          ad.data_apont,
          pe.apelido AS nome_usu
     FROM apontam_data ad,
          pessoa       pe
    WHERE usuario_pkg.empresa_padrao_retornar(ad.usuario_id) = p_empresa_id
      AND ad.data BETWEEN v_data_ini AND v_data_fim
      AND ad.status = 'PEND'
      AND ad.usuario_id = pe.usuario_id
    ORDER BY 1,
             2;
  --
  -- apontamentos a serem processados
  CURSOR c_ap IS
   SELECT usuario_id,
          apontam_data_id,
          data
     FROM apontam_data
    WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status = 'APRO'
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_ENCE_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_forca_encer) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag força encerramento inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_apontam_id)
    INTO v_tipo_apontam_id
    FROM tipo_apontam
   WHERE empresa_id = p_empresa_id
     AND codigo = 'ENCE';
  --
  IF v_tipo_apontam_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento de Enderramento não encontrado para essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_mes_ano) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do mês/ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_mes_ano) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_mes_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_mes_ano  := data_converter(p_mes_ano);
  v_data_ini := v_mes_ano;
  v_data_fim := last_day(v_data_ini);
  --
  SELECT MAX(apontam_ence_id)
    INTO v_apontam_ence_id
    FROM apontam_ence
   WHERE mes_ano = v_mes_ano
     AND empresa_id = p_empresa_id;
  --
  IF v_apontam_ence_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe registro na tabela encerramento para esse período (' ||
                 substr(data_mostrar(v_mes_ano), 4) || ').';
  
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt_pend
    FROM apontam_data
   WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
     AND data BETWEEN v_data_ini AND v_data_fim
     AND status NOT IN ('ENCE', 'APRO');
  --
  IF v_qt_pend > 0 AND p_flag_forca_encer = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem pendências de apontamentos nesse período (' ||
                 substr(data_mostrar(v_mes_ano), 4) || ').';
  
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco para encerramento forcado
  ------------------------------------------------------------
  IF p_flag_forca_encer = 'S'
  THEN
   -- completa apontamentos pendentes
   FOR r_pd IN c_pd
   LOOP
    -- verifica se o usuario tem papel para apontar horas.
    SELECT COUNT(*),
           MAX(pa.papel_id)
      INTO v_qt,
           v_papel_id
      FROM usuario_papel up,
           papel         pa
     WHERE up.usuario_id = r_pd.usuario_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = p_empresa_id;
    --
    IF v_qt = 0
    THEN
     -- pega qualquer papel do usuario
     SELECT MAX(pa.papel_id)
       INTO v_papel_id
       FROM usuario_papel up,
            papel         pa
      WHERE up.usuario_id = r_pd.usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.empresa_id = p_empresa_id;
     --
     IF v_papel_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Usuário não tem papel associado (' || r_pd.nome_usu || ').';
      RAISE v_exception;
     END IF;
    
    END IF;
    --
    SELECT MAX(area_id)
      INTO v_area_papel_id
      FROM papel
     WHERE papel_id = v_papel_id;
    --
    -- verifia quantas horas o usuario deve apontar
    SELECT min_horas_apont_dia
      INTO v_num_horas_dia
      FROM usuario
     WHERE usuario_id = r_pd.usuario_id;
    --
    IF v_num_horas_dia IS NULL
    THEN
     v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                        'NUM_MIN_HORAS_APONTADAS_DIA'));
    END IF;
    --
    -- verifica quantas horas o usuario ja apontou
    SELECT nvl(SUM(ah.horas), 0)
      INTO v_horas_atu
      FROM apontam_hora ah
     WHERE ah.apontam_data_id = r_pd.apontam_data_id;
    --
    -- calcula horas pendentes
    v_horas_pend := v_num_horas_dia - v_horas_atu;
    --
    IF v_horas_pend > 0
    THEN
     v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(r_pd.usuario_id,
                                                            p_empresa_id,
                                                            NULL,
                                                            NULL);
     --
     INSERT INTO apontam_hora
      (apontam_hora_id,
       apontam_data_id,
       job_id,
       papel_id,
       area_papel_id,
       horas,
       custo,
       venda,
       tipo_apontam_id,
       unid_neg_usu_id)
     VALUES
      (seq_apontam_hora.nextval,
       r_pd.apontam_data_id,
       NULL,
       v_papel_id,
       v_area_papel_id,
       v_horas_pend,
       0,
       0,
       v_tipo_apontam_id,
       v_unid_neg_usu_id);
     --
     -- preenche a coluna de horas ajustadas
     apontam_pkg.apontamento_horas_ajustar(r_pd.apontam_data_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     IF r_pd.data_apont IS NULL
     THEN
      UPDATE apontam_data
         SET data_apont = SYSDATE
       WHERE apontam_data_id = r_pd.apontam_data_id;
     
     END IF;
    
    END IF;
   
   END LOOP;
   --
   -- aprova eventuais apontamentos ainda nao aprovados
   UPDATE apontam_data
      SET status = 'APRO'
    WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status NOT IN ('ENCE', 'APRO');
  
  END IF;
  --
  ------------------------------------------------------------
  -- executa transicao de status para encerrado
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   apontam_pkg.acao_executar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             r_ap.usuario_id,
                             r_ap.data,
                             r_ap.data,
                             'ENCERRAR',
                             NULL,
                             'N',
                             p_erro_cod,
                             p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  UPDATE apontam_ence
     SET flag_encerrado  = 'S',
         data_encerrado  = SYSDATE,
         usuario_ence_id = p_usuario_sessao_id
   WHERE apontam_ence_id = v_apontam_ence_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := substr(data_mostrar(v_mes_ano), 4);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'APONTAMENTO',
                   'CONCLUIR',
                   v_identif_objeto,
                   v_apontam_ence_id,
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
 END encerrar;
 --
 --
 PROCEDURE reabrir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 19/12/2016
  -- DESCRICAO: reabre apontamentos da empresa/mes.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_mes_ano         DATE;
  v_data_ini        DATE;
  v_data_fim        DATE;
  v_apontam_ence_id apontam_ence.apontam_ence_id%TYPE;
  v_flag_encerrado  apontam_ence.flag_encerrado%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  --
  -- apontamentos a serem processados
  CURSOR c_ap IS
   SELECT usuario_id,
          apontam_data_id,
          data
     FROM apontam_data
    WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status = 'ENCE'
    ORDER BY 1,
             2;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_ENCE_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_mes_ano) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do mês/ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_mes_ano) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_mes_ano || ').';
   RAISE v_exception;
  END IF;
  --
  v_mes_ano  := data_converter(p_mes_ano);
  v_data_ini := v_mes_ano;
  v_data_fim := last_day(v_data_ini);
  --
  SELECT MAX(apontam_ence_id)
    INTO v_apontam_ence_id
    FROM apontam_ence
   WHERE mes_ano = v_mes_ano
     AND empresa_id = p_empresa_id;
  --
  IF v_apontam_ence_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe registro na tabela encerramento para esse período (' ||
                 substr(data_mostrar(v_mes_ano), 4) || ').';
  
   RAISE v_exception;
  END IF;
  --
  SELECT flag_encerrado
    INTO v_flag_encerrado
    FROM apontam_ence
   WHERE apontam_ence_id = v_apontam_ence_id;
  --
  IF v_flag_encerrado = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse período já se encontra aberto (' || substr(data_mostrar(v_mes_ano), 4) || ').';
  
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   apontam_pkg.acao_executar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             r_ap.usuario_id,
                             r_ap.data,
                             r_ap.data,
                             'REABRIR',
                             NULL,
                             'N',
                             p_erro_cod,
                             p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  UPDATE apontam_ence
     SET flag_encerrado  = 'N',
         data_encerrado  = NULL,
         usuario_ence_id = NULL
   WHERE apontam_ence_id = v_apontam_ence_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := substr(data_mostrar(v_mes_ano), 4);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'APONTAMENTO',
                   'REABRIR',
                   v_identif_objeto,
                   v_apontam_ence_id,
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
 PROCEDURE horas_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2004
  -- DESCRICAO: procedure de atualizacao em lista das horas apontadas de um determinado
  --   usuario numa determinada data.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  -- Silvia            01/10/2008  Novos parametros (cliente_id e horas_cliente).
  -- Silvia            20/08/2009  Novo parametro de vetor de obs do job.
  -- Silvia            06/12/2010  Novo parametro vetor de OS.
  -- Silvia            16/01/2012  Parametrizacao do numero max de horas apontadas no dia.
  -- Silvia            30/01/2012  Novos parametros de vetores (produto e cliente).
  -- Silvia            25/04/2013  Unificacao dos diversos vetores por tipo de apontamento.
  -- Silvia            20/03/2015  Novo parametro flag_home_office.
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            28/12/2017  Inclusao de area do papel.
  -- Silvia            10/07/2018  Controle de status em apontam_hora.
  -- Silvia            04/09/2018  Consiste obrigatoriedade da obs.
  -- Silvia            29/07/2019  Novo tipo de apontam: Oportunidade
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            08/04/2022  Novo tipo apontam hora em contrato
  -- Silvia            15/09/2022  Nova tabela apontam_oport
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN usuario.usuario_id%TYPE,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_apontam_data_id       IN apontam_data.apontam_data_id%TYPE,
  p_flag_home_office      IN VARCHAR2,
  p_vetor_tipo_apontam_id IN VARCHAR2,
  p_vetor_objeto_id       IN VARCHAR2,
  p_vetor_horas           IN VARCHAR2,
  p_vetor_obs             IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_vetor_tipo_apontam_id  LONG;
  v_vetor_objeto_id        LONG;
  v_vetor_horas            LONG;
  v_vetor_obs              LONG;
  v_data_char              VARCHAR2(20);
  v_objeto_char            VARCHAR2(100);
  v_horas_char             VARCHAR2(20);
  v_delimitador            CHAR(1);
  v_data                   apontam_data.data%TYPE;
  v_custo_hora             apontam_data.custo_hora%TYPE;
  v_custo                  apontam_data.custo_hora%TYPE;
  v_custo_en               apontam_data.custo_hora%TYPE;
  v_venda_hora             apontam_data.venda_hora%TYPE;
  v_tipo_apontam_id        apontam_hora.tipo_apontam_id%TYPE;
  v_venda                  apontam_hora.venda%TYPE;
  v_venda_en               apontam_hora.venda%TYPE;
  v_horas                  apontam_hora.horas%TYPE;
  v_horas_ajustadas        apontam_hora.horas_ajustadas%TYPE;
  v_job_id                 apontam_hora.job_id%TYPE;
  v_cliente_id             apontam_hora.cliente_id%TYPE;
  v_contrato_id            apontam_hora.contrato_id%TYPE;
  v_ordem_servico_id       apontam_hora.ordem_servico_id%TYPE;
  v_oportunidade_id        apontam_hora.oportunidade_id%TYPE;
  v_produto_cliente_id     apontam_hora.produto_cliente_id%TYPE;
  v_tarefa_id              apontam_hora.tarefa_id%TYPE;
  v_papel_id               apontam_hora.papel_id%TYPE;
  v_papel_aux_id           apontam_hora.papel_id%TYPE;
  v_papel_pdr_id           apontam_hora.papel_id%TYPE;
  v_area_papel_id          apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id        apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id        apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id        apontam_hora.unid_neg_job_id%TYPE;
  v_cod_apontam            tipo_apontam.codigo%TYPE;
  v_nome_apontam           tipo_apontam.nome%TYPE;
  v_flag_sistema           tipo_apontam.flag_sistema%TYPE;
  v_obs                    VARCHAR2(4000);
  v_usuario_id             usuario.usuario_id%TYPE;
  v_salario_id             salario.salario_id%TYPE;
  v_tipo_os_id             ordem_servico.tipo_os_id%TYPE;
  v_num_max_horas_dia      NUMBER;
  v_horas_unidade          NUMBER;
  v_tot_horas_dia          NUMBER;
  v_lbl_job                VARCHAR2(100);
  v_lbl_prodcli            VARCHAR2(100);
  v_flag_salario_obrig     VARCHAR2(50);
  v_flag_aprov_job         VARCHAR2(50);
  v_status_hora            apontam_hora.status%TYPE;
  v_flag_obriga_desc_horas job.flag_obriga_desc_horas%TYPE;
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_job            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  v_flag_aprov_job     := empresa_pkg.parametro_retornar(p_empresa_id, 'APONTAM_COM_APROV_GESJOB');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_num_max_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_MAX_HORAS_APONTADAS_DIA'));
  v_horas_unidade     := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'UNIDADE_APONTAM'));
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data
   WHERE apontam_data_id = p_apontam_data_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse apontamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT usuario_id,
         data
    INTO v_usuario_id,
         v_data
    FROM apontam_data
   WHERE apontam_data_id = p_apontam_data_id;
  --
  v_data_char := rtrim(data_mostrar(v_data));
  --
  v_salario_id := salario_pkg.salario_id_retornar(v_usuario_id, v_data);
  v_custo_hora := 0;
  v_venda_hora := 0;
  --
  IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' ||
                 v_data_char || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
     INTO v_custo_hora,
          v_venda_hora
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  IF v_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- verifica o papel que permite o usuario fazer apontamentos pela
  -- empresa da sessao.
  SELECT MAX(pa.papel_id)
    INTO v_papel_pdr_id
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = v_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id;
  --
  IF v_papel_pdr_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não tem papel que permita fazer apontamentos por essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_home_office) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag home office inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- limpa apontamentos de horas
  ------------------------------------------------------------
  DELETE FROM apontam_hora
   WHERE apontam_data_id = p_apontam_data_id;
 
  DELETE FROM apontam_job
   WHERE apontam_data_id = p_apontam_data_id;
 
  DELETE FROM apontam_oport
   WHERE apontam_data_id = p_apontam_data_id;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_tipo_apontam_id := p_vetor_tipo_apontam_id;
  v_vetor_objeto_id       := p_vetor_objeto_id;
  v_vetor_horas           := p_vetor_horas;
  v_vetor_obs             := p_vetor_obs;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_apontam_id)), 0) > 0
  LOOP
   v_tipo_apontam_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_apontam_id, v_delimitador)),
                            0);
   v_objeto_char     := TRIM(prox_valor_retornar(v_vetor_objeto_id, v_delimitador));
   v_horas_char      := prox_valor_retornar(v_vetor_horas, v_delimitador);
   v_obs             := TRIM(prox_valor_retornar(v_vetor_obs, v_delimitador));
   --
   v_cliente_id         := NULL;
   v_contrato_id        := NULL;
   v_job_id             := NULL;
   v_ordem_servico_id   := NULL;
   v_oportunidade_id    := NULL;
   v_produto_cliente_id := NULL;
   v_tarefa_id          := NULL;
   v_papel_aux_id       := NULL;
   v_unid_neg_usu_id    := NULL;
   v_unid_neg_job_id    := NULL;
   v_unid_neg_cli_id    := NULL;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_apontam
    WHERE tipo_apontam_id = v_tipo_apontam_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de apontamento inválido (Dia: ' || v_data_char || ', Tipo: ' ||
                  to_char(v_tipo_apontam_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT codigo,
          nome,
          flag_sistema
     INTO v_cod_apontam,
          v_nome_apontam,
          v_flag_sistema
     FROM tipo_apontam
    WHERE tipo_apontam_id = v_tipo_apontam_id;
   --
   IF numero_validar(v_horas_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas := nvl(round(numero_converter(v_horas_char), 2), 0);
   v_custo := round(v_horas * v_custo_hora, 2);
   v_venda := round(v_horas * v_venda_hora, 2);
   --
   IF v_flag_sistema = 'S' AND nvl(v_objeto_char, '0') = '0' AND v_horas <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_nome_apontam || ' não informado(a) (Dia: ' || v_data_char || ', Horas: ' ||
                  v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_objeto_char, '0') <> '0' OR v_horas <> 0 OR v_obs IS NOT NULL
   THEN
    IF v_cod_apontam = 'JOB'
    THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM job
      WHERE numero = v_objeto_char
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa (Dia: ' ||
                    v_data_char || ', ID ' || v_lbl_job || ': ' || v_objeto_char || ').';
     
      RAISE v_exception;
     END IF;
     --
     SELECT job_id,
            cliente_id,
            contrato_id,
            flag_obriga_desc_horas
       INTO v_job_id,
            v_cliente_id,
            v_contrato_id,
            v_flag_obriga_desc_horas
       FROM job
      WHERE numero = v_objeto_char
        AND empresa_id = p_empresa_id;
     --
     IF v_horas > 0 AND v_flag_obriga_desc_horas = 'S' AND TRIM(v_obs) IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento da descrição do apontamento é obrigatório (Dia: ' ||
                    v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND job_id = v_job_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento no mesmo ' || v_lbl_job || ' (Dia: ' ||
                    v_data_char || ', ID ' || v_lbl_job || ': ' || v_objeto_char || ').';
     
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel que deixa apontar em job
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel up,
            papel         pa,
            papel_priv    pp,
            privilegio    pr
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'APONTAM_JOB_C';
    
    END IF; -- fim do 'JOB'
    --
    IF v_cod_apontam = 'CLI'
    THEN
     IF inteiro_validar(v_objeto_char) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Cliente inválido (Dia: ' || v_data_char || ',  ID Cliente: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_cliente_id := nvl(to_number(v_objeto_char), 0);
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM pessoa
      WHERE pessoa_id = v_cliente_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse cliente não existe ou não pertence a essa empresa (Dia: ' || v_data_char ||
                    ', ID Cliente: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND cliente_id = v_cliente_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento no mesmo Cliente' || ' (Dia: ' || v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel que deixa apontar em cliente
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel up,
            papel         pa,
            papel_priv    pp,
            privilegio    pr
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'APONTAM_CLI_C';
    
    END IF; -- fim do 'CLI'
    --
    IF v_cod_apontam = 'OS'
    THEN
     IF inteiro_validar(v_objeto_char) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Workflow inválido (Dia: ' || v_data_char || ', ID Workflow: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_ordem_servico_id := nvl(to_number(v_objeto_char), 0);
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
      p_erro_msg := 'Esse Workflow não existe ou não pertence a essa empresa (Dia: ' || v_data_char ||
                    ', ID Workflow: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT jo.job_id,
            jo.cliente_id,
            jo.contrato_id,
            os.tipo_os_id,
            jo.flag_obriga_desc_horas
       INTO v_job_id,
            v_cliente_id,
            v_contrato_id,
            v_tipo_os_id,
            v_flag_obriga_desc_horas
       FROM job           jo,
            ordem_servico os
      WHERE os.ordem_servico_id = v_ordem_servico_id
        AND os.job_id = jo.job_id;
     --
     IF v_horas > 0 AND v_flag_obriga_desc_horas = 'S' AND TRIM(v_obs) IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento da descrição do apontamento é obrigatório (Dia: ' ||
                    v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND ordem_servico_id = v_ordem_servico_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento no mesmo Workflow' || ' (Dia: ' || v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel do usuario em OS desse tipo
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel  up,
            papel          pa,
            papel_priv     pp,
            privilegio     pr,
            papel_priv_tos pt
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo IN ('OS_C', 'OS_EN', 'OS_EX', 'OS_DI', 'OS_AP')
        AND pt.papel_id = pp.papel_id
        AND pt.privilegio_id = pp.privilegio_id
        AND pt.tipo_os_id = v_tipo_os_id;
    
    END IF; -- fim do 'OS'
    --
    IF v_cod_apontam = 'PRO'
    THEN
     IF inteiro_validar(v_objeto_char) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := v_lbl_prodcli || ' inválido (Dia: ' || v_data_char || ', ID: ' || v_objeto_char || ').';
     
      RAISE v_exception;
     END IF;
     --
     v_produto_cliente_id := nvl(to_number(v_objeto_char), 0);
     --
     SELECT MAX(pc.pessoa_id)
       INTO v_cliente_id
       FROM produto_cliente pc,
            pessoa          cl
      WHERE pc.produto_cliente_id = v_produto_cliente_id
        AND pc.pessoa_id = cl.pessoa_id
        AND cl.empresa_id = p_empresa_id;
     --
     IF v_cliente_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Esse ' || v_lbl_prodcli || ' não existe ou não pertence a essa empresa (Dia: ' ||
                    v_data_char || ', ID: ' || v_objeto_char || ').';
     
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND produto_cliente_id = v_produto_cliente_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento no mesmo ' || v_lbl_prodcli || ' (Dia: ' ||
                    v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel que deixa apontar em produto do cliente
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel up,
            papel         pa,
            papel_priv    pp,
            privilegio    pr
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'APONTAM_PRO_C';
    
    END IF; -- fim do 'PRO'
    --
    IF v_cod_apontam = 'TAR'
    THEN
     IF inteiro_validar(v_objeto_char) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Task inválida (Dia: ' || v_data_char || ', ID: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_tarefa_id := nvl(to_number(v_objeto_char), 0);
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM tarefa
      WHERE tarefa_id = v_tarefa_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Essa Task não existe ou não pertence a essa empresa (Dia: ' || v_data_char ||
                    ', ID: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT ta.job_id,
            jo.cliente_id,
            jo.contrato_id
       INTO v_job_id,
            v_cliente_id,
            v_contrato_id
       FROM tarefa ta,
            job    jo
      WHERE ta.tarefa_id = v_tarefa_id
        AND ta.job_id = jo.job_id(+);
     --
     IF v_job_id IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Essa Task não tem vínculo com ' || v_lbl_job || ' (Dia: ' || v_data_char ||
                    ', ID: ' || v_objeto_char || ').';
     
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND tarefa_id = v_tarefa_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento para a mesma Task' || ' (Dia: ' || v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel que deixa apontar em tarefa
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel up,
            papel         pa,
            papel_priv    pp,
            privilegio    pr
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'APONTAM_TAR_C';
    
    END IF; -- fim do 'TAR'
    --
    IF v_cod_apontam = 'OPO'
    THEN
     IF inteiro_validar(v_objeto_char) = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Oportunidade inválida (Dia: ' || v_data_char || ', ID Oportunidade: ' ||
                    v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_oportunidade_id := nvl(to_number(v_objeto_char), 0);
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM oportunidade
      WHERE oportunidade_id = v_oportunidade_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Essa Oportunidade não existe ou não pertence a essa empresa (Dia: ' ||
                    v_data_char || ', ID Oportunidade: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT cliente_id
       INTO v_cliente_id
       FROM oportunidade
      WHERE oportunidade_id = v_oportunidade_id;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id
        AND oportunidade_id = v_oportunidade_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento na mesma Oportunidade (Dia: ' || v_data_char ||
                    ', ID Oportunidade: ' || v_objeto_char || ').';
      RAISE v_exception;
     END IF;
     --
     -- preferencia pelo papel que deixa apontar em oportunidade
     SELECT MAX(pa.papel_id)
       INTO v_papel_aux_id
       FROM usuario_papel up,
            papel         pa,
            papel_priv    pp,
            privilegio    pr
      WHERE up.usuario_id = v_usuario_id
        AND up.papel_id = pa.papel_id
        AND pa.flag_apontam_form = 'S'
        AND pa.empresa_id = p_empresa_id
        AND pa.papel_id = pp.papel_id
        AND pp.privilegio_id = pr.privilegio_id
        AND pr.codigo = 'APONTAM_OPORT_C';
    
    END IF; -- fim do 'OPO'
    --
    IF v_flag_sistema = 'N'
    THEN
     -- apontamento de horas administrativas
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = p_apontam_data_id
        AND tipo_apontam_id = v_tipo_apontam_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Existe mais de um apontamento no administrativo do mesmo tipo' || ' (Dia: ' ||
                    v_data_char || ').';
      RAISE v_exception;
     END IF;
    
    END IF;
    --
    --
    IF v_horas <= 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', ' || v_nome_apontam ||
                   ', Horas: ' || v_horas_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    IF MOD(v_horas, v_horas_unidade) <> 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                   numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || v_data_char || ', ' ||
                   v_nome_apontam || ', Horas: ' || v_horas_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    IF length(v_obs) > 500
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'A descrição não pode ter mais que 500 caracteres (Dia: ' || v_data_char || ').';
     RAISE v_exception;
    END IF;
    --
    IF v_papel_aux_id IS NOT NULL
    THEN
     v_papel_id := v_papel_aux_id;
    ELSE
     v_papel_id := v_papel_pdr_id;
    END IF;
    --
    SELECT MAX(area_id)
      INTO v_area_papel_id
      FROM papel
     WHERE papel_id = v_papel_id;
    --
    -- encripta para salvar
    v_custo_en := util_pkg.num_encode(v_custo);
    --
    IF v_custo_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_venda_en := util_pkg.num_encode(v_venda);
    --
    IF v_venda_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_status_hora := NULL;
    IF v_job_id IS NOT NULL AND v_flag_aprov_job = 'S'
    THEN
     v_status_hora := 'PEND';
    END IF;
    --
    v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(v_usuario_id,
                                                           p_empresa_id,
                                                           v_cliente_id,
                                                           v_job_id);
    --
    IF v_job_id IS NOT NULL
    THEN
     SELECT unidade_negocio_id
       INTO v_unid_neg_job_id
       FROM job
      WHERE job_id = v_job_id;
    
    END IF;
    --
    IF v_cliente_id IS NOT NULL
    THEN
     v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, v_job_id, v_usuario_id);
    END IF;
    --
    INSERT INTO apontam_hora
     (apontam_hora_id,
      apontam_data_id,
      job_id,
      ordem_servico_id,
      oportunidade_id,
      produto_cliente_id,
      tarefa_id,
      cliente_id,
      contrato_id,
      papel_id,
      area_papel_id,
      horas,
      horas_ajustadas,
      custo,
      venda,
      obs,
      tipo_apontam_id,
      status,
      unid_neg_usu_id,
      unid_neg_job_id,
      unid_neg_cli_id)
    VALUES
     (seq_apontam_hora.nextval,
      p_apontam_data_id,
      v_job_id,
      v_ordem_servico_id,
      v_oportunidade_id,
      v_produto_cliente_id,
      v_tarefa_id,
      v_cliente_id,
      v_contrato_id,
      v_papel_id,
      v_area_papel_id,
      v_horas,
      0,
      v_custo_en,
      v_venda_en,
      v_obs,
      v_tipo_apontam_id,
      v_status_hora,
      v_unid_neg_usu_id,
      v_unid_neg_job_id,
      v_unid_neg_cli_id);
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  UPDATE apontam_data
     SET flag_home_office = p_flag_home_office,
         data_apont       = SYSDATE
   WHERE apontam_data_id = p_apontam_data_id;
  --
  -- verifica total de horas apontadas no dia
  SELECT nvl(SUM(horas), 0)
    INTO v_tot_horas_dia
    FROM apontam_hora
   WHERE apontam_data_id = p_apontam_data_id;
  --
  IF v_tot_horas_dia > v_num_max_horas_dia
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de horas apontadas por dia não pode exceder ' ||
                 numero_mostrar(v_num_max_horas_dia, 2, 'N') || ' horas (Dia: ' || v_data_char ||
                 ' - ' || numero_mostrar(v_tot_horas_dia, 2, 'N') || ' horas apontadas).';
  
   RAISE v_exception;
  END IF;
  --
  apontam_pkg.apontamento_horas_ajustar(p_apontam_data_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- executa eventual transicao de status
  apontam_pkg.acao_executar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            v_usuario_id,
                            v_data,
                            v_data,
                            'SALVAR',
                            NULL,
                            'S',
                            p_erro_cod,
                            p_erro_msg);
 
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
 END horas_apontar;
 --
 --
 PROCEDURE horas_semanal_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/05/2013
  -- DESCRICAO: procedure de atualizacao em lista das horas semanais apontadas pelo usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/03/2015  Novo parametro vetor_flag_home_office.
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            03/12/2015  Label customizado para produto do cliente.
  -- Silvia            03/05/2016  Uso do empresa_id do objeto apontado ou pdr do usuario.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            28/12/2017  Inclusao de area do papel, cargo e area do cargo.
  -- Silvia            10/07/2018  Controle de status em apontam_hora.
  -- Silvia            04/09/2018  Consiste obrigatoriedade da obs.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  -- Silvia            29/07/2019  Novo tipo de apontam: Oportunidade
  -- Silvia            09/07/2020  Instancia unidades de negocio (cli, job, usu)
  -- Silvia            18/01/2022  Novo tipo de apontam em contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN usuario.usuario_id%TYPE,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_vetor_data             IN VARCHAR2,
  p_vetor_flag_home_office IN VARCHAR2,
  p_vetor_tipo_apontam_id  IN VARCHAR2,
  p_vetor_objeto_id        IN VARCHAR2,
  p_vetor_horas            IN VARCHAR2,
  p_vetor_obs              IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_vetor_data             LONG;
  v_vetor_flag_home_office LONG;
  v_vetor_tipo_apontam_id  LONG;
  v_vetor_objeto_id        LONG;
  v_vetor_horas            LONG;
  v_vetor_obs              LONG;
  v_data_char              VARCHAR2(20);
  v_objeto_char            VARCHAR2(100);
  v_horas_char             VARCHAR2(20);
  v_delimitador            CHAR(1);
  v_apontam_data_id        apontam_data.apontam_data_id%TYPE;
  v_data                   apontam_data.data%TYPE;
  v_data_min               apontam_data.data%TYPE;
  v_data_max               apontam_data.data%TYPE;
  v_custo_hora             apontam_data.custo_hora%TYPE;
  v_custo_hora_en          apontam_data.custo_hora%TYPE;
  v_custo                  apontam_data.custo_hora%TYPE;
  v_custo_en               apontam_data.custo_hora%TYPE;
  v_venda_hora             apontam_data.venda_hora%TYPE;
  v_venda_hora_en          apontam_data.venda_hora%TYPE;
  v_flag_home_office       apontam_data.flag_home_office%TYPE;
  v_cargo_id               apontam_data.cargo_id%TYPE;
  v_area_cargo_id          apontam_data.area_cargo_id%TYPE;
  v_apontam_hora_id        apontam_hora.apontam_hora_id%TYPE;
  v_tipo_apontam_id        apontam_hora.tipo_apontam_id%TYPE;
  v_venda                  apontam_hora.venda%TYPE;
  v_venda_en               apontam_hora.venda%TYPE;
  v_horas                  apontam_hora.horas%TYPE;
  v_horas_ajustadas        apontam_hora.horas_ajustadas%TYPE;
  v_horas_job              NUMBER;
  v_contrato_id            contrato.contrato_id%TYPE;
  v_num_contrato           contrato.numero%TYPE;
  v_job_id                 apontam_hora.job_id%TYPE;
  v_cliente_id             apontam_hora.cliente_id%TYPE;
  v_ordem_servico_id       apontam_hora.ordem_servico_id%TYPE;
  v_oportunidade_id        apontam_hora.oportunidade_id%TYPE;
  v_produto_cliente_id     apontam_hora.produto_cliente_id%TYPE;
  v_tarefa_id              apontam_hora.tarefa_id%TYPE;
  v_papel_id               apontam_hora.papel_id%TYPE;
  v_papel_aux_id           apontam_hora.papel_id%TYPE;
  v_papel_pdr_id           apontam_hora.papel_id%TYPE;
  v_area_papel_id          apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id        apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id        apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id        apontam_hora.unid_neg_job_id%TYPE;
  v_cod_apontam            tipo_apontam.codigo%TYPE;
  v_nome_apontam           tipo_apontam.nome%TYPE;
  v_flag_sistema           tipo_apontam.flag_sistema%TYPE;
  v_obs                    VARCHAR2(4000);
  v_salario_id             salario.salario_id%TYPE;
  v_nivel                  apontam_data.nivel%TYPE;
  v_num_horas_dia          NUMBER;
  v_num_max_horas_dia      NUMBER;
  v_horas_unidade          NUMBER;
  v_tot_horas_dia          NUMBER;
  v_num_horas_prod_dia     NUMBER;
  v_lbl_job                VARCHAR2(100);
  v_lbl_prodcli            VARCHAR2(100);
  v_flag_salario_obrig     VARCHAR2(50);
  v_tipo_os_id             ordem_servico.tipo_os_id%TYPE;
  v_empresa_obj_id         empresa.empresa_id%TYPE;
  v_empresa_pdr_id         empresa.empresa_id%TYPE;
  v_empresa_ta_id          empresa.empresa_id%TYPE;
  v_flag_aprov_job         VARCHAR2(50);
  v_status_hora            apontam_hora.status%TYPE;
  v_flag_obriga_desc_horas job.flag_obriga_desc_horas%TYPE;
  v_num_job                job.numero%TYPE;
  v_num_os                 VARCHAR2(100);
  --
  CURSOR c_ap IS
   SELECT apontam_data_id,
          status,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_sessao_id
      AND data BETWEEN v_data_min AND v_data_max
    ORDER BY data;
  --
 BEGIN
  v_qt := 0;
  --
  -- empresa da sessao usada apenas para textos
  v_lbl_job     := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_lbl_prodcli := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_PRODCLI_SINGULAR');
  --
  -- recupera a empresa padrao do usuario para salario e horas administrativas
  v_empresa_pdr_id     := usuario_pkg.empresa_padrao_retornar(p_usuario_sessao_id);
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                         'FLAG_SALARIO_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT min_horas_apont_dia,
         num_horas_prod_dia,
         NULL
    INTO v_num_horas_dia,
         v_num_horas_prod_dia,
         v_nivel
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  v_num_max_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                         'NUM_MAX_HORAS_APONTADAS_DIA'));
  v_horas_unidade     := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                         'UNIDADE_APONTAM'));
  --
  -- verifica o papel que permite o usuario fazer apontamentos pela empresa padrao.
  SELECT MAX(pa.papel_id)
    INTO v_papel_pdr_id
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = v_empresa_pdr_id;
  --
  IF v_papel_pdr_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário não tem papel que permita fazer apontamentos pela empresa padrão.';
   RAISE v_exception;
  END IF;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_data             := p_vetor_data;
  v_vetor_flag_home_office := p_vetor_flag_home_office;
  v_vetor_tipo_apontam_id  := p_vetor_tipo_apontam_id;
  v_vetor_objeto_id        := p_vetor_objeto_id;
  v_vetor_horas            := p_vetor_horas;
  v_vetor_obs              := p_vetor_obs;
  --
  WHILE nvl(length(rtrim(v_vetor_data)), 0) > 0
  LOOP
   v_data_char        := TRIM(prox_valor_retornar(v_vetor_data, v_delimitador));
   v_flag_home_office := TRIM(prox_valor_retornar(v_vetor_flag_home_office, v_delimitador));
   v_tipo_apontam_id  := nvl(to_number(prox_valor_retornar(v_vetor_tipo_apontam_id, v_delimitador)),
                             0);
   v_objeto_char      := TRIM(prox_valor_retornar(v_vetor_objeto_id, v_delimitador));
   v_horas_char       := prox_valor_retornar(v_vetor_horas, v_delimitador);
   v_obs              := TRIM(prox_valor_retornar(v_vetor_obs, v_delimitador));
   --
   v_apontam_data_id := NULL;
   v_apontam_hora_id := NULL;
   --
   v_cliente_id         := NULL;
   v_contrato_id        := NULL;
   v_job_id             := NULL;
   v_ordem_servico_id   := NULL;
   v_oportunidade_id    := NULL;
   v_produto_cliente_id := NULL;
   v_tarefa_id          := NULL;
   v_papel_aux_id       := NULL;
   v_empresa_obj_id     := NULL;
   v_unid_neg_usu_id    := NULL;
   v_unid_neg_job_id    := NULL;
   v_unid_neg_cli_id    := NULL;
   --
   IF data_validar(v_data_char) = 0 OR v_data_char IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data          := data_converter(v_data_char);
   v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   v_area_cargo_id := NULL;
   --
   IF v_cargo_id IS NOT NULL
   THEN
    SELECT MAX(area_id)
      INTO v_area_cargo_id
      FROM cargo
     WHERE cargo_id = v_cargo_id;
    --
    v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   END IF;
   --
   -- guarda a menor data do intervalo
   IF v_data_min IS NULL OR v_data < v_data_min
   THEN
    v_data_min := v_data;
   END IF;
   --
   -- guarda a maior data do intervalo
   IF v_data_max IS NULL OR v_data > v_data_max
   THEN
    v_data_max := v_data;
   END IF;
   --
   IF flag_validar(v_flag_home_office) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Flag home office inválido.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(apontam_data_id)
     INTO v_apontam_data_id
     FROM apontam_data
    WHERE usuario_id = p_usuario_sessao_id
      AND data = v_data;
   --
   v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_sessao_id, v_data);
   v_custo_hora    := 0;
   v_venda_hora    := 0;
   v_custo_hora_en := 0;
   v_venda_hora_en := 0;
   --
   IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' ||
                  v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_salario_id, 0) > 0
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora
      FROM salario
     WHERE salario_id = v_salario_id;
   
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_apontam
    WHERE tipo_apontam_id = v_tipo_apontam_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de apontamento inválido (Dia: ' || v_data_char || ', Tipo: ' ||
                  to_char(v_tipo_apontam_id) || ').';
   
    RAISE v_exception;
   END IF;
   --
   SELECT codigo,
          nome,
          flag_sistema,
          empresa_id
     INTO v_cod_apontam,
          v_nome_apontam,
          v_flag_sistema,
          v_empresa_ta_id
     FROM tipo_apontam
    WHERE tipo_apontam_id = v_tipo_apontam_id;
   --
   IF numero_validar(v_horas_char) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas := nvl(round(numero_converter(v_horas_char), 2), 0);
   v_custo := round(v_horas * v_custo_hora, 2);
   v_venda := round(v_horas * v_venda_hora, 2);
   --
   IF v_flag_sistema = 'S' AND nvl(v_objeto_char, '0') = '0'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := v_nome_apontam || ' não informado(a) (Dia: ' || v_data_char || ', Horas: ' ||
                  v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_horas < 0 OR v_horas > 24
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', ' || v_nome_apontam ||
                  ', Horas: ' || v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF MOD(v_horas, v_horas_unidade) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                  numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || v_data_char || ', ' ||
                  v_nome_apontam || ', Horas: ' || v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF length(v_obs) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A descrição não pode ter mais que 500 caracteres (Dia: ' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   -------------------------------------------
   -- consistencia do objeto e busca do papel
   -- para cada tipo de apontamento
   -------------------------------------------
   IF v_cod_apontam = 'CTR'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Contrato inválido (Dia: ' || v_data_char || ', ID Contrato: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_contrato_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM contrato
     WHERE contrato_id = v_contrato_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de Contrato' || ' não existe (Dia: ' || v_data_char ||
                   ', ID Contrato: ' || v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    SELECT numero,
           contratante_id,
           empresa_id
      INTO v_num_contrato,
           v_cliente_id,
           v_empresa_obj_id
      FROM contrato
     WHERE contrato_id = v_contrato_id;
    --
    -- preferencia pelo papel que deixa apontar em contrato
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_CTR_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em Contrato' || ' não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'CTR'
   --
   IF v_cod_apontam = 'JOB'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := v_lbl_job || ' inválido (Dia: ' || v_data_char || ', ID ' || v_lbl_job || ': ' ||
                   v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    v_job_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM job
     WHERE job_id = v_job_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de ' || v_lbl_job || ' não existe (Dia: ' || v_data_char || ', ID ' ||
                   v_lbl_job || ': ' || v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    SELECT numero,
           cliente_id,
           contrato_id,
           empresa_id,
           flag_obriga_desc_horas
      INTO v_num_job,
           v_cliente_id,
           v_contrato_id,
           v_empresa_obj_id,
           v_flag_obriga_desc_horas
      FROM job
     WHERE job_id = v_job_id;
    --
    IF v_horas > 0 AND v_flag_obriga_desc_horas = 'S' AND TRIM(v_obs) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da descrição do apontamento é obrigatório (Dia: ' ||
                   v_data_char || ' ' || v_lbl_job || ': ' || v_num_job || ').';
    
     RAISE v_exception;
    END IF;
    --
    -- preferencia pelo papel que deixa apontar em job
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_JOB_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em ' || v_lbl_job || ' não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'JOB'
   --
   IF v_cod_apontam = 'CLI'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Cliente inválido (Dia: ' || v_data_char || ', ID Cliente: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_cliente_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT MAX(empresa_id)
      INTO v_empresa_obj_id
      FROM pessoa
     WHERE pessoa_id = v_cliente_id;
    --
    IF v_empresa_obj_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de cliente não existe (Dia: ' || v_data_char || ', ID Cliente: ' ||
                   v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    -- preferencia pelo papel que deixa apontar em cliente
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_CLI_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em cliente' || ' não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'CLI'
   --
   IF v_cod_apontam = 'OS'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Workflow inválido (Dia: ' || v_data_char || ', ID Workflow: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_ordem_servico_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM ordem_servico os,
           job           jo
     WHERE os.ordem_servico_id = v_ordem_servico_id
       AND os.job_id = jo.job_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de Workflow não existe (Dia: ' || v_data_char || ', ID Workflow: ' ||
                   v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT jo.job_id,
           jo.cliente_id,
           jo.contrato_id,
           jo.empresa_id,
           os.tipo_os_id,
           jo.flag_obriga_desc_horas,
           ordem_servico_pkg.numero_formatar(os.ordem_servico_id)
      INTO v_job_id,
           v_cliente_id,
           v_contrato_id,
           v_empresa_obj_id,
           v_tipo_os_id,
           v_flag_obriga_desc_horas,
           v_num_os
      FROM job           jo,
           ordem_servico os
     WHERE os.ordem_servico_id = v_ordem_servico_id
       AND os.job_id = jo.job_id;
    --
    IF v_horas > 0 AND v_flag_obriga_desc_horas = 'S' AND TRIM(v_obs) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento da descrição do apontamento é obrigatório (Dia: ' ||
                   v_data_char || ' Workflow: ' || v_num_os || ').';
     RAISE v_exception;
    END IF;
    --
    -- preferencia pelo papel do usuario em OS desse tipo
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel  up,
           papel          pa,
           papel_priv     pp,
           privilegio     pr,
           papel_priv_tos pt
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo IN ('OS_C', 'OS_EN', 'OS_EX', 'OS_DI', 'OS_AP')
       AND pt.papel_id = pp.papel_id
       AND pt.privilegio_id = pp.privilegio_id
       AND pt.tipo_os_id = v_tipo_os_id;
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em Workflow' || ' não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'OS'
   --
   IF v_cod_apontam = 'PRO'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := v_lbl_prodcli || ' inválido (Dia: ' || v_data_char || ', ID: ' || v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    v_produto_cliente_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT MAX(pc.pessoa_id),
           MAX(cl.empresa_id)
      INTO v_cliente_id,
           v_empresa_obj_id
      FROM produto_cliente pc,
           pessoa          cl
     WHERE pc.produto_cliente_id = v_produto_cliente_id
       AND pc.pessoa_id = cl.pessoa_id;
    --
    IF v_empresa_obj_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de ' || v_lbl_prodcli || ' não existe (Dia: ' || v_data_char ||
                   ', ID: ' || v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    -- preferencia pelo papel que deixa apontar em produto do cliente
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_PRO_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em ' || v_lbl_prodcli ||
                   ' não encontrado (Dia: ' || v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'PRO'
   --
   IF v_cod_apontam = 'TAR'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Task inválida (Dia: ' || v_data_char || ', ID: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_tarefa_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM tarefa
     WHERE tarefa_id = v_tarefa_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de Task não existe (Dia: ' || v_data_char || ', ID: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT ta.job_id,
           jo.cliente_id,
           jo.contrato_id,
           ta.empresa_id
      INTO v_job_id,
           v_cliente_id,
           v_contrato_id,
           v_empresa_obj_id
      FROM tarefa ta,
           job    jo
     WHERE ta.tarefa_id = v_tarefa_id
       AND ta.job_id = jo.job_id(+);
    --
    IF v_job_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa Task não tem vínculo com ' || v_lbl_job || ' (Dia: ' || v_data_char ||
                   ', ID: ' || v_objeto_char || ').';
    
     RAISE v_exception;
    END IF;
    --
    -- preferencia pelo papel que deixa apontar em tarefa
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_TAR_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em Task ' || ' não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'TAR'
   --
   IF v_cod_apontam = 'OPO'
   THEN
    IF inteiro_validar(v_objeto_char) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Oportunidade inválido (Dia: ' || v_data_char || ', ID Oportunidade: ' ||
                   v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    v_oportunidade_id := nvl(to_number(v_objeto_char), 0);
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM oportunidade
     WHERE oportunidade_id = v_oportunidade_id;
    --
    IF v_qt = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse ID de Oportunidade não existe (Dia: ' || v_data_char ||
                   ', ID Oportunidade: ' || v_objeto_char || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT cliente_id,
           empresa_id
      INTO v_cliente_id,
           v_empresa_obj_id
      FROM oportunidade
     WHERE oportunidade_id = v_oportunidade_id;
    --
    -- preferencia pelo papel que deixa apontar em oportunidade
    SELECT MAX(pa.papel_id)
      INTO v_papel_aux_id
      FROM usuario_papel up,
           papel         pa,
           papel_priv    pp,
           privilegio    pr
     WHERE up.usuario_id = p_usuario_sessao_id
       AND up.papel_id = pa.papel_id
       AND pa.flag_apontam_form = 'S'
       AND pa.empresa_id = v_empresa_obj_id
       AND pa.papel_id = pp.papel_id
       AND pp.privilegio_id = pr.privilegio_id
       AND pr.codigo = 'APONTAM_OPORT_C';
    --
    IF v_papel_aux_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Papel que permite apontar horas em Oportunidade não encontrado (Dia: ' ||
                   v_data_char || ').';
     RAISE v_exception;
    END IF;
   
   END IF; -- fim do 'OPO'
   --
   -------------------------------------------
   -- verifica se precisa corrigir o tipo de
   -- apontamento que veio no vetor (pode ter
   -- vindo o tipo da empresa errada)
   -------------------------------------------
   IF v_empresa_ta_id <> nvl(v_empresa_obj_id, v_empresa_pdr_id)
   THEN
    SELECT MAX(tipo_apontam_id)
      INTO v_tipo_apontam_id
      FROM tipo_apontam
     WHERE empresa_id = nvl(v_empresa_obj_id, v_empresa_pdr_id)
       AND codigo = v_cod_apontam;
    --
    IF v_tipo_apontam_id IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Tipo de apontamento não encontrado na empresa (' || v_cod_apontam || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   -------------------------------------------
   -- verifica existencia de apontamento
   -------------------------------------------
   IF v_cod_apontam = 'JOB' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nesse job
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND job_id = v_job_id;
    --
    -- verifica se existem horas detalhadas nesse job
    SELECT nvl(SUM(horas), 0)
      INTO v_horas_job
      FROM apontam_job
     WHERE apontam_data_id = v_apontam_data_id
       AND job_id = v_job_id;
    --
    IF v_horas_job > 0 AND v_horas_job <> v_horas
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'As horas totais não batem com as horas detalhadas (Dia: ' || v_data_char || ' ' ||
                   v_lbl_job || ': ' || v_num_job || ').';
    
     RAISE v_exception;
    END IF;
   
   ELSIF v_cod_apontam = 'CTR' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nesse contrato
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND contrato_id = v_contrato_id;
   
   ELSIF v_cod_apontam = 'CLI' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nesse cliente
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND cliente_id = v_cliente_id;
   
   ELSIF v_cod_apontam = 'OS' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nessa OS
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND ordem_servico_id = v_ordem_servico_id;
   
   ELSIF v_cod_apontam = 'OPO' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nessa Oportunidade
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND oportunidade_id = v_oportunidade_id;
   
   ELSIF v_cod_apontam = 'PRO' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nesse produto
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND produto_cliente_id = v_produto_cliente_id;
   
   ELSIF v_cod_apontam = 'TAR' AND v_apontam_data_id IS NOT NULL
   THEN
    -- verifica se ja existe hora apontada nessa tarefa
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id
       AND tarefa_id = v_tarefa_id;
   
   ELSIF v_flag_sistema = 'N'
   THEN
    -- verifica se ja existe hora admin apontada desse tipo
    SELECT MAX(apontam_hora_id)
      INTO v_apontam_hora_id
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tipo_apontam_id = v_tipo_apontam_id;
   
   END IF;
   --
   IF v_horas > 0
   THEN
    v_flag_aprov_job := empresa_pkg.parametro_retornar(v_empresa_obj_id, 'APONTAM_COM_APROV_GESJOB');
    --
    v_status_hora := NULL;
    IF v_job_id IS NOT NULL AND v_flag_aprov_job = 'S'
    THEN
     v_status_hora := 'PEND';
    END IF;
    --
    IF v_apontam_data_id IS NULL
    THEN
     SELECT seq_apontam_data.nextval
       INTO v_apontam_data_id
       FROM dual;
     --
     INSERT INTO apontam_data
      (apontam_data_id,
       usuario_id,
       data,
       nivel,
       custo_hora,
       venda_hora,
       num_horas_dia,
       num_horas_prod_dia,
       status,
       flag_home_office,
       cargo_id,
       area_cargo_id)
     VALUES
      (v_apontam_data_id,
       p_usuario_sessao_id,
       v_data,
       v_nivel,
       v_custo_hora_en,
       v_venda_hora_en,
       v_num_horas_dia,
       v_num_horas_prod_dia,
       'PEND',
       v_flag_home_office,
       v_cargo_id,
       v_area_cargo_id);
    
    ELSE
     UPDATE apontam_data
        SET flag_home_office = v_flag_home_office
      WHERE apontam_data_id = v_apontam_data_id;
    
    END IF;
    --
    IF v_apontam_hora_id IS NULL
    THEN
     IF v_empresa_obj_id IS NOT NULL
     THEN
      -- trata-se de objeto
      v_papel_id := v_papel_aux_id;
     ELSE
      -- trata-se de horas admin
      v_papel_id := v_papel_pdr_id;
     END IF;
     --
     -- encripta para salvar
     v_custo_en := util_pkg.num_encode(v_custo);
     --
     IF v_custo_en = -99999
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
      RAISE v_exception;
     END IF;
     --
     v_venda_en := util_pkg.num_encode(v_venda);
     --
     IF v_venda_en = -99999
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT MAX(area_id)
       INTO v_area_papel_id
       FROM papel
      WHERE papel_id = v_papel_id;
     --
     IF v_empresa_obj_id IS NOT NULL
     THEN
      v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                             v_empresa_obj_id,
                                                             v_cliente_id,
                                                             v_job_id);
     ELSE
      -- horas administrativas
      v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                             v_empresa_pdr_id,
                                                             NULL,
                                                             NULL);
     END IF;
     --
     IF v_job_id IS NOT NULL
     THEN
      SELECT unidade_negocio_id
        INTO v_unid_neg_job_id
        FROM job
       WHERE job_id = v_job_id;
     
     END IF;
     --
     IF v_cliente_id IS NOT NULL
     THEN
      v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id,
                                                            v_job_id,
                                                            p_usuario_sessao_id);
     END IF;
     --
     SELECT seq_apontam_hora.nextval
       INTO v_apontam_hora_id
       FROM dual;
     --
     INSERT INTO apontam_hora
      (apontam_hora_id,
       apontam_data_id,
       job_id,
       contrato_id,
       ordem_servico_id,
       oportunidade_id,
       produto_cliente_id,
       tarefa_id,
       cliente_id,
       papel_id,
       area_papel_id,
       horas,
       horas_ajustadas,
       custo,
       venda,
       obs,
       tipo_apontam_id,
       status,
       unid_neg_usu_id,
       unid_neg_job_id,
       unid_neg_cli_id)
     VALUES
      (v_apontam_hora_id,
       v_apontam_data_id,
       v_job_id,
       v_contrato_id,
       v_ordem_servico_id,
       v_oportunidade_id,
       v_produto_cliente_id,
       v_tarefa_id,
       v_cliente_id,
       v_papel_id,
       v_area_papel_id,
       v_horas,
       0,
       v_custo_en,
       v_venda_en,
       v_obs,
       v_tipo_apontam_id,
       v_status_hora,
       v_unid_neg_usu_id,
       v_unid_neg_job_id,
       v_unid_neg_cli_id);
    
    ELSE
     UPDATE apontam_hora
        SET horas           = v_horas,
            obs             = v_obs,
            status          = v_status_hora,
            usuario_acao_id = NULL,
            data_acao       = NULL,
            coment_acao     = NULL
      WHERE apontam_hora_id = v_apontam_hora_id;
    
    END IF;
   
   END IF; -- fim do IF v_horas > 0
   --
   --
   IF v_horas = 0
   THEN
    IF v_apontam_hora_id IS NOT NULL
    THEN
     DELETE FROM apontam_hora
      WHERE apontam_hora_id = v_apontam_hora_id;
    
    END IF;
   END IF; -- fim do IF v_horas = 0
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   v_apontam_data_id := r_ap.apontam_data_id;
   v_data_char       := data_mostrar(r_ap.data);
   --
   -- verifica total de horas apontadas no dia
   SELECT nvl(SUM(horas), 0)
     INTO v_tot_horas_dia
     FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id;
   --
   IF v_tot_horas_dia > v_num_max_horas_dia
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número de horas apontadas por dia não pode exceder ' ||
                  numero_mostrar(v_num_max_horas_dia, 2, 'N') || ' horas (Dia: ' || v_data_char ||
                  ' - ' || numero_mostrar(v_tot_horas_dia, 2, 'N') || ' horas apontadas).';
   
    RAISE v_exception;
   END IF;
   --
   apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- executa eventual transicao de status
   apontam_pkg.acao_executar(p_usuario_sessao_id,
                             p_empresa_id,
                             'N',
                             p_usuario_sessao_id,
                             r_ap.data,
                             r_ap.data,
                             'SALVAR',
                             NULL,
                             'S',
                             p_erro_cod,
                             p_erro_msg);
  
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   UPDATE apontam_data
      SET data_apont = SYSDATE
    WHERE apontam_data_id = v_apontam_data_id;
  
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
 END horas_semanal_apontar;
 --
 --
 PROCEDURE horas_job_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 26/07/2019
  -- DESCRICAO: apontamento de horas em JOB, numa determinada data, por tipo de apontamento.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/02/2020  Novo parametro obs
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            01/09/2020  Consistencia de unidade de apontamento
  -- Silvia            08/04/2022  Novo tipo apontam hora em contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id         IN usuario.usuario_id%TYPE,
  p_empresa_id                IN empresa.empresa_id%TYPE,
  p_job_id                    IN job.job_id%TYPE,
  p_data                      IN VARCHAR2,
  p_vetor_tipo_apontam_job_id IN VARCHAR2,
  p_vetor_horas               IN VARCHAR2,
  p_obs                       IN VARCHAR2,
  p_erro_cod                  OUT VARCHAR2,
  p_erro_msg                  OUT VARCHAR2
 ) IS
 
  v_qt                        INTEGER;
  v_exception                 EXCEPTION;
  v_vetor_horas               LONG;
  v_vetor_tipo_apontam_job_id LONG;
  v_horas_char                VARCHAR2(20);
  v_delimitador               CHAR(1);
  v_apontam_data_id           apontam_data.apontam_data_id%TYPE;
  v_data                      apontam_data.data%TYPE;
  v_cargo_id                  apontam_data.cargo_id%TYPE;
  v_area_cargo_id             apontam_data.area_cargo_id%TYPE;
  v_custo                     apontam_data.custo_hora%TYPE;
  v_custo_en                  apontam_data.custo_hora%TYPE;
  v_custo_hora                apontam_data.custo_hora%TYPE;
  v_custo_hora_en             apontam_data.custo_hora%TYPE;
  v_venda                     apontam_hora.venda%TYPE;
  v_venda_en                  apontam_hora.venda%TYPE;
  v_venda_hora                apontam_data.venda_hora%TYPE;
  v_venda_hora_en             apontam_data.venda_hora%TYPE;
  v_tipo_apontam_job_id       apontam_job.tipo_apontam_job_id%TYPE;
  v_horas                     apontam_job.horas%TYPE;
  v_empresa_pdr_id            empresa.empresa_id%TYPE;
  v_salario_id                salario.salario_id%TYPE;
  v_nivel                     apontam_data.nivel%TYPE;
  v_apontam_hora_id           apontam_hora.apontam_hora_id%TYPE;
  v_tipo_apontam_id           apontam_hora.tipo_apontam_id%TYPE;
  v_cliente_id                apontam_hora.cliente_id%TYPE;
  v_contrato_id               apontam_hora.contrato_id%TYPE;
  v_papel_id                  apontam_hora.papel_id%TYPE;
  v_status_hora               apontam_hora.status%TYPE;
  v_area_papel_id             apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id           apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id           apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id           apontam_hora.unid_neg_job_id%TYPE;
  v_num_horas_dia             NUMBER;
  v_num_horas_prod_dia        NUMBER;
  v_flag_salario_obrig        VARCHAR2(50);
  v_lbl_job                   VARCHAR2(100);
  v_flag_aprov_job            VARCHAR2(50);
  v_horas_unidade             NUMBER;
  --
 BEGIN
  v_qt            := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_horas_unidade := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                     'UNIDADE_APONTAM'));
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- recupera a empresa padrao do usuario para salario e horas administrativas
  v_empresa_pdr_id     := usuario_pkg.empresa_padrao_retornar(p_usuario_sessao_id);
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                         'FLAG_SALARIO_OBRIGATORIO');
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job jo
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
  IF TRIM(p_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data não informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT cliente_id,
         contrato_id
    INTO v_cliente_id,
         v_contrato_id
    FROM job jo
   WHERE job_id = p_job_id;
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
  v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
  v_area_cargo_id := NULL;
  --
  IF v_cargo_id IS NOT NULL
  THEN
   SELECT MAX(area_id)
     INTO v_area_cargo_id
     FROM cargo
    WHERE cargo_id = v_cargo_id;
   --
   v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
  END IF;
  --
  v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_sessao_id, v_data);
  v_custo_hora    := 0;
  v_custo_hora_en := 0;
  v_venda_hora    := 0;
  v_venda_hora_en := 0;
  --
  IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(venda_hora, 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
     INTO v_custo_hora_en,
          v_custo_hora,
          v_venda_hora_en,
          v_venda_hora
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  SELECT MAX(tipo_apontam_id)
    INTO v_tipo_apontam_id
    FROM tipo_apontam
   WHERE empresa_id = p_empresa_id
     AND codigo = 'JOB';
  --
  -- procura papel que deixa apontar em job
  SELECT MAX(pa.papel_id)
    INTO v_papel_id
    FROM usuario_papel up,
         papel         pa,
         papel_priv    pp,
         privilegio    pr
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id
     AND pa.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = 'APONTAM_JOB_C';
  --
  IF v_papel_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Papel que permite apontar horas em ' || v_lbl_job || ' não encontrado (Dia: ' ||
                 p_data || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(length(p_obs)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A observação não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                         p_empresa_id,
                                                         v_cliente_id,
                                                         p_job_id);
  --
  SELECT unidade_negocio_id
    INTO v_unid_neg_job_id
    FROM job
   WHERE job_id = p_job_id;
  --
  v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, p_job_id, p_usuario_sessao_id);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se já existe apontamento nessa data.
  SELECT MAX(apontam_data_id)
    INTO v_apontam_data_id
    FROM apontam_data
   WHERE usuario_id = p_usuario_sessao_id
     AND data = v_data;
  --
  IF v_apontam_data_id IS NOT NULL
  THEN
   -- limpa eventuais apontamentos nesse job
   DELETE FROM apontam_job
    WHERE apontam_data_id = v_apontam_data_id
      AND job_id = p_job_id;
   --
   DELETE FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id
      AND tipo_apontam_id = v_tipo_apontam_id
      AND job_id = p_job_id;
  
  ELSE
   SELECT seq_apontam_data.nextval
     INTO v_apontam_data_id
     FROM dual;
   --
   INSERT INTO apontam_data
    (apontam_data_id,
     usuario_id,
     data,
     nivel,
     custo_hora,
     venda_hora,
     num_horas_dia,
     num_horas_prod_dia,
     status,
     cargo_id,
     area_cargo_id)
   VALUES
    (v_apontam_data_id,
     p_usuario_sessao_id,
     v_data,
     v_nivel,
     v_custo_hora_en,
     v_venda_hora_en,
     v_num_horas_dia,
     v_num_horas_prod_dia,
     'PEND',
     v_cargo_id,
     v_area_cargo_id);
  
  END IF;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_tipo_apontam_job_id := p_vetor_tipo_apontam_job_id;
  v_vetor_horas               := p_vetor_horas;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_apontam_job_id)), 0) > 0
  LOOP
   v_tipo_apontam_job_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_apontam_job_id,
                                                              v_delimitador)),
                                0);
   v_horas_char          := prox_valor_retornar(v_vetor_horas, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_apontam_job
    WHERE tipo_apontam_job_id = v_tipo_apontam_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de apontamento em ' || v_lbl_job || '  inválido.';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(TRIM(v_horas_char)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || p_data || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas := nvl(round(numero_converter(TRIM(v_horas_char)), 2), 0);
   --
   IF v_horas < 0 OR v_horas > 24
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || p_data || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF MOD(v_horas, v_horas_unidade) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                  numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || p_data || ', Horas: ' ||
                  v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_horas > 0 AND v_tipo_apontam_job_id > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_job
     WHERE apontam_data_id = v_apontam_data_id
       AND job_id = p_job_id
       AND tipo_apontam_job_id = v_tipo_apontam_job_id;
    --
    IF v_qt > 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem tipos de apontamentos repetidos.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO apontam_job
     (apontam_data_id,
      job_id,
      tipo_apontam_job_id,
      horas)
    VALUES
     (v_apontam_data_id,
      p_job_id,
      v_tipo_apontam_job_id,
      v_horas);
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- grava apontam_hora com total de horas apontadas no job
  ------------------------------------------------------------
  SELECT nvl(SUM(horas), 0)
    INTO v_horas
    FROM apontam_job
   WHERE apontam_data_id = v_apontam_data_id
     AND job_id = p_job_id;
  --
  /*
    IF v_horas = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Nenhuma hora foi informada (Dia: ' || p_data || ').';
       RAISE v_exception;
    END IF;
  */
  --
  IF v_horas > 24
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mais de 24 horas foram informadas (Dia: ' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo := round(v_horas * v_custo_hora, 2);
  v_venda := round(v_horas * v_venda_hora, 2);
  --
  v_status_hora := NULL;
  IF v_flag_aprov_job = 'S'
  THEN
   v_status_hora := 'PEND';
  END IF;
  --
  -- encripta para salvar
  v_custo_en := util_pkg.num_encode(v_custo);
  --
  IF v_custo_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_en := util_pkg.num_encode(v_venda);
  --
  IF v_venda_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(area_id)
    INTO v_area_papel_id
    FROM papel
   WHERE papel_id = v_papel_id;
  --
  SELECT seq_apontam_hora.nextval
    INTO v_apontam_hora_id
    FROM dual;
  --
  IF v_horas > 0
  THEN
   INSERT INTO apontam_hora
    (apontam_hora_id,
     apontam_data_id,
     job_id,
     cliente_id,
     contrato_id,
     papel_id,
     area_papel_id,
     horas,
     horas_ajustadas,
     custo,
     venda,
     obs,
     tipo_apontam_id,
     status,
     unid_neg_usu_id,
     unid_neg_job_id,
     unid_neg_cli_id)
   VALUES
    (v_apontam_hora_id,
     v_apontam_data_id,
     p_job_id,
     v_cliente_id,
     v_contrato_id,
     v_papel_id,
     v_area_papel_id,
     v_horas,
     0,
     v_custo_en,
     v_venda_en,
     TRIM(p_obs),
     v_tipo_apontam_id,
     v_status_hora,
     v_unid_neg_usu_id,
     v_unid_neg_job_id,
     v_unid_neg_cli_id);
  
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
 END horas_job_apontar;
 --
 --
 PROCEDURE horas_oport_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 15/09/2022
  -- DESCRICAO: apontamento de horas em OPORTUNIDADE, numa determinada data, por servico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_oportunidade_id   IN oportunidade.oportunidade_id%TYPE,
  p_data              IN VARCHAR2,
  p_vetor_servico_id  IN VARCHAR2,
  p_vetor_horas       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_vetor_horas        LONG;
  v_vetor_servico_id   LONG;
  v_horas_char         VARCHAR2(20);
  v_delimitador        CHAR(1);
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_data               apontam_data.data%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_custo              apontam_data.custo_hora%TYPE;
  v_custo_en           apontam_data.custo_hora%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_servico_id         apontam_oport.servico_id%TYPE;
  v_horas              apontam_oport.horas%TYPE;
  v_job_id             job.job_id%TYPE;
  v_empresa_pdr_id     empresa.empresa_id%TYPE;
  v_salario_id         salario.salario_id%TYPE;
  v_nivel              apontam_data.nivel%TYPE;
  v_apontam_hora_id    apontam_hora.apontam_hora_id%TYPE;
  v_tipo_apontam_id    apontam_hora.tipo_apontam_id%TYPE;
  v_cliente_id         apontam_hora.cliente_id%TYPE;
  v_contrato_id        apontam_hora.contrato_id%TYPE;
  v_papel_id           apontam_hora.papel_id%TYPE;
  v_status_hora        apontam_hora.status%TYPE;
  v_area_papel_id      apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id    apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id    apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id    apontam_hora.unid_neg_job_id%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_flag_salario_obrig VARCHAR2(50);
  v_flag_aprov_job     VARCHAR2(50);
  v_horas_unidade      NUMBER;
  --
 BEGIN
  v_qt            := 0;
  v_job_id        := NULL;
  v_contrato_id   := NULL;
  v_horas_unidade := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                     'UNIDADE_APONTAM'));
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  -- recupera a empresa padrao do usuario para salario e horas administrativas
  v_empresa_pdr_id     := usuario_pkg.empresa_padrao_retornar(p_usuario_sessao_id);
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                         'FLAG_SALARIO_OBRIGATORIO');
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa oportunidade não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data não informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT cliente_id
    INTO v_cliente_id
    FROM oportunidade
   WHERE oportunidade_id = p_oportunidade_id;
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
  v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
  v_area_cargo_id := NULL;
  --
  IF v_cargo_id IS NOT NULL
  THEN
   SELECT MAX(area_id)
     INTO v_area_cargo_id
     FROM cargo
    WHERE cargo_id = v_cargo_id;
   --
   v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
  END IF;
  --
  v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_sessao_id, v_data);
  v_custo_hora    := 0;
  v_custo_hora_en := 0;
  v_venda_hora    := 0;
  v_venda_hora_en := 0;
  --
  IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(venda_hora, 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
     INTO v_custo_hora_en,
          v_custo_hora,
          v_venda_hora_en,
          v_venda_hora
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  SELECT MAX(tipo_apontam_id)
    INTO v_tipo_apontam_id
    FROM tipo_apontam
   WHERE empresa_id = p_empresa_id
     AND codigo = 'OPO';
  --
  -- procura papel que deixa apontar em oportunidade
  SELECT MAX(pa.papel_id)
    INTO v_papel_id
    FROM usuario_papel up,
         papel         pa,
         papel_priv    pp,
         privilegio    pr
   WHERE up.usuario_id = p_usuario_sessao_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id
     AND pa.papel_id = pp.papel_id
     AND pp.privilegio_id = pr.privilegio_id
     AND pr.codigo = 'APONTAM_OPORT_C';
  --
  IF v_papel_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Papel que permite apontar horas em Oportunidade' || ' não encontrado (Dia: ' ||
                 p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                         p_empresa_id,
                                                         v_cliente_id,
                                                         v_job_id);
  --
  v_unid_neg_job_id := NULL;
  --
  v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, v_job_id, p_usuario_sessao_id);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se já existe apontamento nessa data.
  SELECT MAX(apontam_data_id)
    INTO v_apontam_data_id
    FROM apontam_data
   WHERE usuario_id = p_usuario_sessao_id
     AND data = v_data;
  --
  IF v_apontam_data_id IS NOT NULL
  THEN
   -- limpa eventuais apontamentos nessa oportunidade
   DELETE FROM apontam_oport
    WHERE apontam_data_id = v_apontam_data_id
      AND oportunidade_id = p_oportunidade_id;
   --
   DELETE FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id
      AND tipo_apontam_id = v_tipo_apontam_id
      AND oportunidade_id = p_oportunidade_id;
  
  ELSE
   SELECT seq_apontam_data.nextval
     INTO v_apontam_data_id
     FROM dual;
   --
   INSERT INTO apontam_data
    (apontam_data_id,
     usuario_id,
     data,
     nivel,
     custo_hora,
     venda_hora,
     num_horas_dia,
     num_horas_prod_dia,
     status,
     cargo_id,
     area_cargo_id)
   VALUES
    (v_apontam_data_id,
     p_usuario_sessao_id,
     v_data,
     v_nivel,
     v_custo_hora_en,
     v_venda_hora_en,
     v_num_horas_dia,
     v_num_horas_prod_dia,
     'PEND',
     v_cargo_id,
     v_area_cargo_id);
  
  END IF;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_servico_id := p_vetor_servico_id;
  v_vetor_horas      := p_vetor_horas;
  --
  WHILE nvl(length(rtrim(v_vetor_servico_id)), 0) > 0
  LOOP
   v_servico_id := nvl(to_number(prox_valor_retornar(v_vetor_servico_id, v_delimitador)), 0);
   v_horas_char := prox_valor_retornar(v_vetor_horas, v_delimitador);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM servico
    WHERE servico_id = v_servico_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse serviço não existe (' || to_char(v_servico_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(TRIM(v_horas_char)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || p_data || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas := nvl(round(numero_converter(TRIM(v_horas_char)), 2), 0);
   --
   IF v_horas < 0 OR v_horas > 24
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || p_data || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF MOD(v_horas, v_horas_unidade) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                  numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || p_data || ', Horas: ' ||
                  v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   IF v_horas > 0 AND v_servico_id > 0
   THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_oport
     WHERE apontam_data_id = v_apontam_data_id
       AND oportunidade_id = p_oportunidade_id
       AND servico_id = v_servico_id;
    --
    IF v_qt > 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Existem serviços repetidos.';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO apontam_oport
     (apontam_data_id,
      oportunidade_id,
      servico_id,
      horas)
    VALUES
     (v_apontam_data_id,
      p_oportunidade_id,
      v_servico_id,
      v_horas);
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- grava apontam_hora com total de horas apontadas no job
  ------------------------------------------------------------
  SELECT nvl(SUM(horas), 0)
    INTO v_horas
    FROM apontam_oport
   WHERE apontam_data_id = v_apontam_data_id
     AND oportunidade_id = p_oportunidade_id;
  --
  /*
    IF v_horas = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Nenhuma hora foi informada (Dia: ' || p_data || ').';
       RAISE v_exception;
    END IF;
  */
  --
  IF v_horas > 24
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mais de 24 horas foram informadas (Dia: ' || p_data || ').';
   RAISE v_exception;
  END IF;
  --
  v_custo := round(v_horas * v_custo_hora, 2);
  v_venda := round(v_horas * v_venda_hora, 2);
  --
  v_status_hora := NULL;
  IF v_flag_aprov_job = 'S'
  THEN
   v_status_hora := 'PEND';
  END IF;
  --
  -- encripta para salvar
  v_custo_en := util_pkg.num_encode(v_custo);
  --
  IF v_custo_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_en := util_pkg.num_encode(v_venda);
  --
  IF v_venda_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(area_id)
    INTO v_area_papel_id
    FROM papel
   WHERE papel_id = v_papel_id;
  --
  SELECT seq_apontam_hora.nextval
    INTO v_apontam_hora_id
    FROM dual;
  --
  IF v_horas > 0
  THEN
   INSERT INTO apontam_hora
    (apontam_hora_id,
     apontam_data_id,
     job_id,
     cliente_id,
     contrato_id,
     oportunidade_id,
     papel_id,
     area_papel_id,
     horas,
     horas_ajustadas,
     custo,
     venda,
     obs,
     tipo_apontam_id,
     status,
     unid_neg_usu_id,
     unid_neg_job_id,
     unid_neg_cli_id)
   VALUES
    (v_apontam_hora_id,
     v_apontam_data_id,
     v_job_id,
     v_cliente_id,
     v_contrato_id,
     p_oportunidade_id,
     v_papel_id,
     v_area_papel_id,
     v_horas,
     0,
     v_custo_en,
     v_venda_en,
     NULL,
     v_tipo_apontam_id,
     v_status_hora,
     v_unid_neg_usu_id,
     v_unid_neg_job_id,
     v_unid_neg_cli_id);
  
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
 END horas_oport_apontar;
 --
 --
 PROCEDURE horas_os_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/02/2013
  -- DESCRICAO: apontamento de horas em OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/04/2013  Tipo de apontamento virou tabela.
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            28/12/2017  Inclusao de area do papel, cargo e area do cargo.
  -- Silvia            10/07/2018  Controle de status em apontam_hora.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  -- Silvia            28/08/2019  Inclusao de obs.
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            08/04/2022  Novo tipo apontam hora em contrato
  -- Silvia            16/08/2022  Novo parametro flag_commit para chamada
  --                               como subrotina no caso de horas alocadas
  --                               que viram horas apontadas.
  -- Ana Luiza         01/11/2024  Alterado para agir de acordo com a proc horas_os_apontar,  
  --                               definido em reuniao com Joel e Veronica
  -- Ana Luiza         21/02/2025  Pegando num_refacao atual para gravar na apontam_hora mesmo
  --                               que hora esteja 0 (Definido Joel em 21/02/25)         
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_ordem_servico_id  IN ordem_servico.ordem_servico_id%TYPE,
  p_vetor_data        IN LONG,
  p_vetor_horas       IN LONG,
  p_vetor_obs         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_vetor_horas            LONG;
  v_vetor_data             LONG;
  v_vetor_obs              LONG;
  v_data_char              VARCHAR2(20);
  v_horas_char             VARCHAR2(20);
  v_delimitador            CHAR(1);
  v_apontam_data_id        apontam_data.apontam_data_id%TYPE;
  v_data                   apontam_data.data%TYPE;
  v_custo_hora             apontam_data.custo_hora%TYPE;
  v_custo_hora_en          apontam_data.custo_hora%TYPE;
  v_custo                  apontam_data.custo_hora%TYPE;
  v_custo_en               apontam_data.custo_hora%TYPE;
  v_venda_hora             apontam_data.venda_hora%TYPE;
  v_venda_hora_en          apontam_data.venda_hora%TYPE;
  v_cargo_id               apontam_data.cargo_id%TYPE;
  v_area_cargo_id          apontam_data.area_cargo_id%TYPE;
  v_status_apontam         apontam_data.status%TYPE;
  v_venda                  apontam_hora.venda%TYPE;
  v_venda_en               apontam_hora.venda%TYPE;
  v_horas                  apontam_hora.horas%TYPE;
  v_horas_ajustadas        apontam_hora.horas_ajustadas%TYPE;
  v_cliente_id             apontam_hora.cliente_id%TYPE;
  v_contrato_id            apontam_hora.contrato_id%TYPE;
  v_papel_id               apontam_hora.papel_id%TYPE;
  v_area_papel_id          apontam_hora.area_papel_id%TYPE;
  v_tipo_apontam_id        apontam_hora.tipo_apontam_id%TYPE;
  v_unid_neg_usu_id        apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id        apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id        apontam_hora.unid_neg_job_id%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_flag_obriga_desc_horas job.flag_obriga_desc_horas%TYPE;
  v_salario_id             salario.salario_id%TYPE;
  v_nivel                  apontam_data.nivel%TYPE;
  v_tipo_os_id             ordem_servico.tipo_os_id%TYPE;
  v_num_horas_dia          NUMBER;
  v_num_max_horas_dia      NUMBER;
  v_horas_unidade          NUMBER;
  v_tot_horas_dia          NUMBER;
  v_num_horas_prod_dia     NUMBER;
  v_flag_salario_obrig     VARCHAR2(50);
  v_os_data_apontam_ini    DATE;
  v_os_data_apontam_fim    DATE;
  v_us_data_apontam_ini    DATE;
  v_us_data_apontam_fim    DATE;
  v_priv_apont_futuro      INTEGER;
  v_priv_apont_folga       INTEGER;
  v_flag_aprov_job         VARCHAR2(50);
  v_status_hora            apontam_hora.status%TYPE;
  v_obs                    VARCHAR2(4000);
  v_num_refacao_atual      os_usuario_data.num_refacao%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  v_num_max_horas_dia  := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'NUM_MAX_HORAS_APONTADAS_DIA'));
  v_horas_unidade      := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'UNIDADE_APONTAM'));
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  v_flag_aprov_job     := empresa_pkg.parametro_retornar(p_empresa_id, 'APONTAM_COM_APROV_GESJOB');
  --
  v_priv_apont_futuro := usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                                    'APONTAM_FUT_C',
                                                    NULL,
                                                    NULL,
                                                    p_empresa_id);
  v_priv_apont_folga  := usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                                    'APONTAM_FOL_C',
                                                    NULL,
                                                    NULL,
                                                    p_empresa_id);
  --
  v_os_data_apontam_ini := ordem_servico_pkg.data_apont_retornar(p_usuario_sessao_id,
                                                                 p_ordem_servico_id,
                                                                 'INI');
  v_os_data_apontam_fim := ordem_servico_pkg.data_apont_retornar(p_usuario_sessao_id,
                                                                 p_ordem_servico_id,
                                                                 'FIM');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
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
  SELECT data_apontam_ini,
         data_apontam_fim,
         NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_us_data_apontam_ini,
         v_us_data_apontam_fim,
         v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
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
  SELECT MAX(tipo_apontam_id)
    INTO v_tipo_apontam_id
    FROM tipo_apontam
   WHERE codigo = 'OS'
     AND empresa_id = p_empresa_id;
  --
  IF v_tipo_apontam_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento Workflow não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT os.job_id,
         jo.cliente_id,
         jo.contrato_id,
         os.tipo_os_id,
         jo.flag_obriga_desc_horas
    INTO v_job_id,
         v_cliente_id,
         v_contrato_id,
         v_tipo_os_id,
         v_flag_obriga_desc_horas
    FROM ordem_servico os,
         job           jo
   WHERE os.ordem_servico_id = p_ordem_servico_id
     AND os.job_id = jo.job_id;
  --
  IF TRIM(p_vetor_data) IS NOT NULL
  THEN
   -- verifica o papel que permite o usuario fazer acoes em OS desse tipo
   SELECT MAX(pa.papel_id)
     INTO v_papel_id
     FROM usuario_papel  up,
          papel          pa,
          papel_priv     pp,
          privilegio     pr,
          papel_priv_tos pt
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.flag_apontam_form = 'S'
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo IN ('OS_C', 'OS_EN', 'OS_EX', 'OS_DI', 'OS_AP')
      AND pt.papel_id = pp.papel_id
      AND pt.privilegio_id = pp.privilegio_id
      AND pt.tipo_os_id = v_tipo_os_id;
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário não tem papel que permita fazer apontamentos em Workflow desse tipo.';
    RAISE v_exception;
   END IF;
   --
   IF v_os_data_apontam_ini > v_os_data_apontam_fim
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Apontamentos só permitidos até ' || data_mostrar(v_os_data_apontam_fim) || '.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(area_id)
     INTO v_area_papel_id
     FROM papel
    WHERE papel_id = v_papel_id;
  
  END IF;
  --
  v_status_hora := NULL;
  IF v_flag_aprov_job = 'S'
  THEN
   v_status_hora := 'PEND';
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                         p_empresa_id,
                                                         v_cliente_id,
                                                         v_job_id);
  --
  SELECT unidade_negocio_id
    INTO v_unid_neg_job_id
    FROM job
   WHERE job_id = v_job_id;
  --
  v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, v_job_id, p_usuario_sessao_id);
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de dias
  ------------------------------------------------------------
  v_vetor_data  := p_vetor_data;
  v_vetor_horas := p_vetor_horas;
  v_vetor_obs   := p_vetor_obs;
  --
  WHILE nvl(length(rtrim(v_vetor_data)), 0) > 0
  LOOP
   v_data_char  := TRIM(prox_valor_retornar(v_vetor_data, v_delimitador));
   v_horas_char := prox_valor_retornar(v_vetor_horas, v_delimitador);
   v_obs        := TRIM(prox_valor_retornar(v_vetor_obs, v_delimitador));
   --
   IF data_validar(v_data_char) = 0 OR TRIM(v_data_char) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(TRIM(v_horas_char)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF length(v_obs) > 500
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A descrição não pode ter mais que 500 caracteres (Dia: ' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data  := data_converter(v_data_char);
   v_horas := nvl(round(numero_converter(TRIM(v_horas_char)), 2), 0);
  
   v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   v_area_cargo_id := NULL;
   --
   IF v_cargo_id IS NOT NULL
   THEN
    SELECT MAX(area_id)
      INTO v_area_cargo_id
      FROM cargo
     WHERE cargo_id = v_cargo_id;
    --
    v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   END IF;
   --
   IF v_us_data_apontam_ini IS NOT NULL AND v_data < v_us_data_apontam_ini
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Apontamentos configurados para você só são permitidos a partir de ' ||
                  data_mostrar(v_us_data_apontam_ini) || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_us_data_apontam_fim IS NOT NULL AND v_data > v_us_data_apontam_fim
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Apontamentos configurados para você só são permitidos até ' ||
                  data_mostrar(v_us_data_apontam_fim) || '.';
    RAISE v_exception;
   END IF;
   --
   IF v_data > trunc(SYSDATE) AND v_priv_apont_futuro = 0 AND p_flag_commit = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para apontar datas futuras.';
    RAISE v_exception;
   END IF;
   --
   IF feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data, 'S') = 0 AND
      v_priv_apont_folga = 0 AND p_flag_commit = 'S'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para apontar aos sábados, domingos e feriados.';
    RAISE v_exception;
   END IF;
   --
   IF v_data NOT BETWEEN v_os_data_apontam_ini AND v_os_data_apontam_fim
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse Workflow só permite apontamentos entre ' ||
                  data_mostrar(v_os_data_apontam_ini) || ' e ' ||
                  data_mostrar(v_os_data_apontam_fim) || '.';
   
    RAISE v_exception;
   END IF;
   --
   IF v_horas < 0 OR v_horas > 24
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF MOD(v_horas, v_horas_unidade) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                  numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || v_data_char ||
                  ', Horas: ' || v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   v_salario_id     := salario_pkg.salario_id_retornar(p_usuario_sessao_id, v_data);
   v_custo_hora     := 0;
   v_venda_hora     := 0;
   v_custo_hora_en  := 0;
   v_venda_hora_en  := 0;
   v_status_apontam := NULL;
   --
   IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' ||
                  v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_salario_id, 0) > 0
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora
      FROM salario
     WHERE salario_id = v_salario_id;
   
   END IF;
   --
   -- verifica se já existe apontamento nessa data.
   SELECT MAX(apontam_data_id)
     INTO v_apontam_data_id
     FROM apontam_data
    WHERE usuario_id = p_usuario_sessao_id
      AND data = v_data;
   --   
   IF v_apontam_data_id IS NOT NULL
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0),
           num_horas_dia,
           num_horas_prod_dia,
           status
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora,
           v_num_horas_dia,
           v_num_horas_prod_dia,
           v_status_apontam
      FROM apontam_data
     WHERE apontam_data_id = v_apontam_data_id;
    --
    IF p_flag_commit = 'N' AND v_status_apontam = 'ENCE'
    THEN
     -- chamada via subrotina pela funcionalidade de alocacao.
     -- Se apontamento ja estiver encerrado, pula o processamento.
     NULL;
    ELSE
     DELETE FROM apontam_hora
      WHERE apontam_data_id = v_apontam_data_id
        AND ordem_servico_id = p_ordem_servico_id;
    
    END IF;
   ELSIF v_horas > 0
   THEN
    --
    --
    SELECT seq_apontam_data.nextval
      INTO v_apontam_data_id
      FROM dual;
    --
    INSERT INTO apontam_data
     (apontam_data_id,
      usuario_id,
      data,
      nivel,
      custo_hora,
      venda_hora,
      num_horas_dia,
      num_horas_prod_dia,
      status,
      cargo_id,
      area_cargo_id)
    VALUES
     (v_apontam_data_id,
      p_usuario_sessao_id,
      v_data,
      v_nivel,
      v_custo_hora_en,
      v_venda_hora_en,
      v_num_horas_dia,
      v_num_horas_prod_dia,
      'PEND',
      v_cargo_id,
      v_area_cargo_id);
   ELSIF v_horas = 0
   THEN
    --
    SELECT seq_apontam_data.nextval
      INTO v_apontam_data_id
      FROM dual;
    --
    INSERT INTO apontam_data
     (apontam_data_id,
      usuario_id,
      data,
      nivel,
      custo_hora,
      venda_hora,
      num_horas_dia,
      num_horas_prod_dia,
      status,
      cargo_id,
      area_cargo_id)
    VALUES
     (v_apontam_data_id,
      p_usuario_sessao_id,
      v_data,
      v_nivel,
      v_custo_hora_en,
      v_venda_hora_en,
      v_num_horas_dia,
      v_num_horas_prod_dia,
      'PEND',
      v_cargo_id,
      v_area_cargo_id);
    --
   END IF;
   --
   IF p_flag_commit = 'N' AND v_status_apontam = 'ENCE'
   THEN
    -- chamada via subrotina pela funcionalidade de alocacao.
    -- Se apontamento ja estiver encerrado, pula o processamento.
    NULL;
   ELSE
    --ALCBO_210225
    IF v_horas > 0 --OR v_horas = 0
    THEN
     IF v_flag_obriga_desc_horas = 'S' AND TRIM(v_obs) IS NULL
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento da descrição do apontamento é obrigatório (Dia: ' ||
                    v_data_char || ').';
      RAISE v_exception;
     END IF;
     --
     v_custo := round(v_horas * v_custo_hora, 2);
     v_venda := round(v_horas * v_venda_hora, 2);
     --
     -- encripta para salvar
     v_custo_en := util_pkg.num_encode(v_custo);
     --
     IF v_custo_en = -99999
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
      RAISE v_exception;
     END IF;
     --
     v_venda_en := util_pkg.num_encode(v_venda);
     --
     IF v_venda_en = -99999
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM apontam_hora
      WHERE apontam_data_id = v_apontam_data_id
        AND ordem_servico_id = p_ordem_servico_id;
     --
     IF v_qt > 0
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Já existe apontamento para esse Workflow nessa data (' || data_mostrar(v_data) || ').';
      RAISE v_exception;
     END IF;
     --
     --ALCBO_210225
     --Verifica se tem uma ou mais refacoes
     SELECT COUNT(num_refacao)
       INTO v_qt
       FROM os_usuario_data
      WHERE ordem_servico_id = p_ordem_servico_id
        AND data = v_data
        AND usuario_id = p_usuario_sessao_id;
     --Se uma refacao pega ela que sera a atual
     IF v_qt = 1
     THEN
      SELECT num_refacao
        INTO v_num_refacao_atual
        FROM os_usuario_data
       WHERE ordem_servico_id = p_ordem_servico_id
         AND data = v_data
         AND usuario_id = p_usuario_sessao_id;
     END IF;
     /*Se não encontra refacao ou tem mais de uma refacao,
     entao pega a maior refacao entre o periodo de datas que usuario esta apontando*/
     IF v_qt = 0 OR v_qt > 1
     THEN
      SELECT MAX(num_refacao)
        INTO v_num_refacao_atual
        FROM os_refacao
       WHERE ordem_servico_id = p_ordem_servico_id
         AND trunc(data_termino_exec) <= v_data;
     END IF;
     --ALCBO_210225_FIM
     --  
     INSERT INTO apontam_hora
      (apontam_hora_id,
       apontam_data_id,
       job_id,
       ordem_servico_id,
       cliente_id,
       contrato_id,
       papel_id,
       area_papel_id,
       horas,
       horas_ajustadas,
       custo,
       venda,
       obs,
       tipo_apontam_id,
       status,
       unid_neg_usu_id,
       unid_neg_job_id,
       unid_neg_cli_id,
       num_refacao)
     VALUES
      (seq_apontam_hora.nextval,
       v_apontam_data_id,
       v_job_id,
       p_ordem_servico_id,
       v_cliente_id,
       v_contrato_id,
       v_papel_id,
       v_area_papel_id,
       v_horas,
       0,
       v_custo_en,
       v_venda_en,
       v_obs,
       v_tipo_apontam_id,
       v_status_hora,
       v_unid_neg_usu_id,
       v_unid_neg_job_id,
       v_unid_neg_cli_id,
       v_num_refacao_atual);
    
    END IF; -- fim do IF v_horas > 0
    --
    ------------------------------------------------------------
    -- atualizacoes finais
    ------------------------------------------------------------
    IF v_apontam_data_id > 0
    THEN
     -- verifica total de horas apontadas no dia
     SELECT nvl(SUM(horas), 0)
       INTO v_tot_horas_dia
       FROM apontam_hora
      WHERE apontam_data_id = v_apontam_data_id;
     --
     IF v_tot_horas_dia > v_num_max_horas_dia
     THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O número de horas apontadas por dia não pode exceder ' ||
                    numero_mostrar(v_num_max_horas_dia, 2, 'N') || ' horas (Dia: ' || v_data_char ||
                    ' - ' || numero_mostrar(v_tot_horas_dia, 2, 'N') || ' horas apontadas).';
     
      RAISE v_exception;
     END IF;
     --
     apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     -- executa eventual transicao de status
     apontam_pkg.acao_executar(p_usuario_sessao_id,
                               p_empresa_id,
                               'N',
                               p_usuario_sessao_id,
                               v_data,
                               v_data,
                               'SALVAR',
                               NULL,
                               p_flag_commit, --ALCBO_011124
                               p_erro_cod,
                               p_erro_msg);
    
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
     --
     UPDATE apontam_data
        SET data_apont = SYSDATE
      WHERE apontam_data_id = v_apontam_data_id;
    
    END IF; -- fim do IF v_apontam_data_id > 0
   END IF; -- fim do IF p_flag_commit = 'N'
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
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END horas_os_apontar;
 --
 --
 PROCEDURE horas_tarefa_apontar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 10/06/2013
  -- DESCRICAO: apontamento de horas em tarefa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            28/12/2017  Inclusao de area do papel, cargo e area do cargo.
  -- Silvia            10/07/2018  Controle de status em apontam_hora.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            08/04/2022  Novo tipo apontam hora em contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_vetor_data        IN LONG,
  p_vetor_horas       IN LONG,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_vetor_horas        LONG;
  v_vetor_data         LONG;
  v_data_char          VARCHAR2(20);
  v_horas_char         VARCHAR2(20);
  v_delimitador        CHAR(1);
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_data               apontam_data.data%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_custo              apontam_data.custo_hora%TYPE;
  v_custo_en           apontam_data.custo_hora%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_horas              apontam_hora.horas%TYPE;
  v_horas_ajustadas    apontam_hora.horas_ajustadas%TYPE;
  v_cliente_id         apontam_hora.cliente_id%TYPE;
  v_contrato_id        apontam_hora.contrato_id%TYPE;
  v_papel_id           apontam_hora.papel_id%TYPE;
  v_area_papel_id      apontam_hora.area_papel_id%TYPE;
  v_tipo_apontam_id    apontam_hora.tipo_apontam_id%TYPE;
  v_unid_neg_usu_id    apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id    apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id    apontam_hora.unid_neg_job_id%TYPE;
  v_job_id             job.job_id%TYPE;
  v_salario_id         salario.salario_id%TYPE;
  v_nivel              apontam_data.nivel%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_max_horas_dia  NUMBER;
  v_horas_unidade      NUMBER;
  v_tot_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_flag_salario_obrig VARCHAR2(50);
  v_flag_aprov_job     VARCHAR2(50);
  v_status_hora        apontam_hora.status%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  v_num_max_horas_dia  := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'NUM_MAX_HORAS_APONTADAS_DIA'));
  v_horas_unidade      := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                          'UNIDADE_APONTAM'));
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  v_flag_aprov_job     := empresa_pkg.parametro_retornar(p_empresa_id, 'APONTAM_COM_APROV_GESJOB');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT min_horas_apont_dia,
         num_horas_prod_dia,
         NULL
    INTO v_num_horas_dia,
         v_num_horas_prod_dia,
         v_nivel
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(tipo_apontam_id)
    INTO v_tipo_apontam_id
    FROM tipo_apontam
   WHERE codigo = 'TAR'
     AND empresa_id = p_empresa_id;
  --
  IF v_tipo_apontam_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento de Task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ta.job_id,
         jo.cliente_id,
         jo.contrato_id
    INTO v_job_id,
         v_cliente_id,
         v_contrato_id
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF TRIM(p_vetor_data) IS NOT NULL
  THEN
   -- verifica o papel que permite o usuario fazer apontamentos pela
   -- empresa da sessao.
   SELECT MAX(pa.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel         pa,
          papel_priv    pp,
          privilegio    pr
    WHERE up.usuario_id = p_usuario_sessao_id
      AND up.papel_id = pa.papel_id
      AND pa.flag_apontam_form = 'S'
      AND pa.empresa_id = p_empresa_id
      AND pa.papel_id = pp.papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo = 'APONTAM_TAR_C';
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário não tem papel que permita fazer apontamentos em Task nessa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(area_id)
     INTO v_area_papel_id
     FROM papel
    WHERE papel_id = v_papel_id;
  
  END IF;
  --
  v_status_hora := NULL;
  IF v_flag_aprov_job = 'S'
  THEN
   v_status_hora := 'PEND';
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_sessao_id,
                                                         p_empresa_id,
                                                         v_cliente_id,
                                                         v_job_id);
  --
  SELECT MAX(unidade_negocio_id)
    INTO v_unid_neg_job_id
    FROM job
   WHERE job_id = v_job_id;
  --
  v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, v_job_id, p_usuario_sessao_id);
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores de dias
  ------------------------------------------------------------
  v_vetor_data  := p_vetor_data;
  v_vetor_horas := p_vetor_horas;
  --
  WHILE nvl(length(rtrim(v_vetor_data)), 0) > 0
  LOOP
   v_data_char  := TRIM(prox_valor_retornar(v_vetor_data, v_delimitador));
   v_horas_char := prox_valor_retornar(v_vetor_horas, v_delimitador);
   --
   IF data_validar(v_data_char) = 0 OR TRIM(v_data_char) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Data inválida (' || v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(TRIM(v_horas_char)) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_data  := data_converter(v_data_char);
   v_horas := nvl(round(numero_converter(TRIM(v_horas_char)), 2), 0);
  
   v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   v_area_cargo_id := NULL;
   --
   IF v_cargo_id IS NOT NULL
   THEN
    SELECT MAX(area_id)
      INTO v_area_cargo_id
      FROM cargo
     WHERE cargo_id = v_cargo_id;
    --
    v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_sessao_id, v_data, p_empresa_id);
   END IF;
   --
   IF v_horas < 0 OR v_horas > 24
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (Dia: ' || v_data_char || ', Horas: ' || v_horas_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF MOD(v_horas, v_horas_unidade) <> 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                  numero_mostrar(v_horas_unidade, 2, 'N') || ' (Dia: ' || v_data_char ||
                  ', Horas: ' || v_horas_char || ').';
   
    RAISE v_exception;
   END IF;
   --
   v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_sessao_id, v_data);
   v_custo_hora    := 0;
   v_venda_hora    := 0;
   v_custo_hora_en := 0;
   v_venda_hora_en := 0;
   --
   IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (Dia: ' ||
                  v_data_char || ').';
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_salario_id, 0) > 0
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora
      FROM salario
     WHERE salario_id = v_salario_id;
   
   END IF;
   --
   -- verifica se já existe apontamento nessa data.
   SELECT MAX(apontam_data_id)
     INTO v_apontam_data_id
     FROM apontam_data
    WHERE usuario_id = p_usuario_sessao_id
      AND data = v_data;
   --
   IF v_apontam_data_id IS NOT NULL
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0),
           num_horas_dia,
           num_horas_prod_dia
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora,
           v_num_horas_dia,
           v_num_horas_prod_dia
      FROM apontam_data
     WHERE apontam_data_id = v_apontam_data_id;
    --
    DELETE FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id
       AND tarefa_id = p_tarefa_id;
    --
   ELSIF v_horas > 0
   THEN
    SELECT seq_apontam_data.nextval
      INTO v_apontam_data_id
      FROM dual;
    --
    INSERT INTO apontam_data
     (apontam_data_id,
      usuario_id,
      data,
      nivel,
      custo_hora,
      venda_hora,
      num_horas_dia,
      num_horas_prod_dia,
      status,
      cargo_id,
      area_cargo_id)
    VALUES
     (v_apontam_data_id,
      p_usuario_sessao_id,
      v_data,
      v_nivel,
      v_custo_hora_en,
      v_venda_hora_en,
      v_num_horas_dia,
      v_num_horas_prod_dia,
      'PEND',
      v_cargo_id,
      v_area_cargo_id);
   
   END IF;
   --
   IF v_horas > 0
   THEN
    v_custo := round(v_horas * v_custo_hora, 2);
    v_venda := round(v_horas * v_venda_hora, 2);
    --
    -- encripta para salvar
    v_custo_en := util_pkg.num_encode(v_custo);
    --
    IF v_custo_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_venda_en := util_pkg.num_encode(v_venda);
    --
    IF v_venda_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO apontam_hora
     (apontam_hora_id,
      apontam_data_id,
      job_id,
      tarefa_id,
      cliente_id,
      contrato_id,
      papel_id,
      area_papel_id,
      horas,
      horas_ajustadas,
      custo,
      venda,
      obs,
      tipo_apontam_id,
      status,
      unid_neg_usu_id,
      unid_neg_job_id,
      unid_neg_cli_id)
    VALUES
     (seq_apontam_hora.nextval,
      v_apontam_data_id,
      v_job_id,
      p_tarefa_id,
      v_cliente_id,
      v_contrato_id,
      v_papel_id,
      v_area_papel_id,
      v_horas,
      0,
      v_custo_en,
      v_venda_en,
      NULL,
      v_tipo_apontam_id,
      v_status_hora,
      v_unid_neg_usu_id,
      v_unid_neg_job_id,
      v_unid_neg_cli_id);
   
   END IF;
   --
   ------------------------------------------------------------
   -- atualizacoes finais
   ------------------------------------------------------------
   IF v_apontam_data_id > 0
   THEN
    -- verifica total de horas apontadas no dia
    SELECT nvl(SUM(horas), 0)
      INTO v_tot_horas_dia
      FROM apontam_hora
     WHERE apontam_data_id = v_apontam_data_id;
    --
    IF v_tot_horas_dia > v_num_max_horas_dia
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O número de horas apontadas por dia não pode exceder ' ||
                   numero_mostrar(v_num_max_horas_dia, 2, 'N') || ' horas (Dia: ' || v_data_char ||
                   ' - ' || numero_mostrar(v_tot_horas_dia, 2, 'N') || ' horas apontadas).';
    
     RAISE v_exception;
    END IF;
    --
    apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    -- executa eventual transicao de status
    apontam_pkg.acao_executar(p_usuario_sessao_id,
                              p_empresa_id,
                              'N',
                              p_usuario_sessao_id,
                              v_data,
                              v_data,
                              'SALVAR',
                              NULL,
                              'S',
                              p_erro_cod,
                              p_erro_msg);
   
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
    --
    UPDATE apontam_data
       SET data_apont = SYSDATE
     WHERE apontam_data_id = v_apontam_data_id;
   
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
 END horas_tarefa_apontar;
 --
 --
 PROCEDURE horas_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2004
  -- DESCRICAO: adiciona um apontamento de horas para um determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            01/10/2008  Guarda o cliente do job. Nova tabela salario.
  -- Silvia            19/08/2009  Implementação do valor de venda do usuario.
  -- Silvia            20/08/2009  Novo parametro com tipo de apontamento (antes só
  --                               permitia JOB e ADM).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            16/01/2012  Parametrizacao do numero max de horas apontadas no dia.
  -- Silvia            23/04/2013  Tipo de apontamento virou tabela.
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            28/12/2017  Inclusao de area do papel, cargo e area do cargo.
  -- Silvia            10/07/2018  Controle de status em apontam_hora.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            08/04/2022  Novo tipo apontam hora em contrato
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_data              IN VARCHAR2,
  p_horas             IN VARCHAR2,
  p_job               IN VARCHAR2,
  p_tipo_apontam_id   IN apontam_hora.tipo_apontam_id%TYPE,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_apontam_data_id     apontam_data.apontam_data_id%TYPE;
  v_data                apontam_data.data%TYPE;
  v_custo_hora          apontam_data.custo_hora%TYPE;
  v_custo_hora_en       apontam_data.custo_hora%TYPE;
  v_custo               apontam_hora.custo%TYPE;
  v_custo_en            apontam_hora.custo%TYPE;
  v_venda_hora          apontam_data.venda_hora%TYPE;
  v_venda_hora_en       apontam_data.venda_hora%TYPE;
  v_cargo_id            apontam_data.cargo_id%TYPE;
  v_area_cargo_id       apontam_data.area_cargo_id%TYPE;
  v_venda               apontam_hora.venda%TYPE;
  v_venda_en            apontam_hora.venda%TYPE;
  v_papel_id            apontam_hora.papel_id%TYPE;
  v_area_papel_id       apontam_hora.area_papel_id%TYPE;
  v_horas               apontam_hora.horas%TYPE;
  v_cliente_id          apontam_hora.cliente_id%TYPE;
  v_contrato_id         apontam_hora.contrato_id%TYPE;
  v_unid_neg_usu_id     apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id     apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id     apontam_hora.unid_neg_job_id%TYPE;
  v_job_id              job.job_id%TYPE;
  v_salario_id          salario.salario_id%TYPE;
  v_nivel               apontam_data.nivel%TYPE;
  v_num_horas_dia       NUMBER;
  v_num_max_horas_dia   NUMBER;
  v_horas_unidade       NUMBER;
  v_tot_horas_dia       NUMBER;
  v_num_horas_prod_dia  NUMBER;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_tipo_apontam_id     tipo_apontam.tipo_apontam_id%TYPE;
  v_cod_apontam         tipo_apontam.codigo%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_flag_salario_obrig  VARCHAR2(50);
  v_us_data_apontam_ini DATE;
  v_us_data_apontam_fim DATE;
  v_flag_aprov_job      VARCHAR2(50);
  v_status_hora         apontam_hora.status%TYPE;
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_job            := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  v_flag_aprov_job     := empresa_pkg.parametro_retornar(p_empresa_id, 'APONTAM_COM_APROV_GESJOB');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id IS NULL OR p_usuario_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário para apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT data_apontam_ini,
         data_apontam_fim,
         NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_us_data_apontam_ini,
         v_us_data_apontam_fim,
         v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF p_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  v_num_max_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                         'NUM_MAX_HORAS_APONTADAS_DIA'));
  v_horas_unidade     := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                         'UNIDADE_APONTAM'));
  --
  -- verifica se o usuario pode apontar horas pela empresa da sessao
  SELECT COUNT(*),
         MAX(pa.papel_id)
    INTO v_qt,
         v_papel_id
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário não está configurado para fazer apontamento de horas nessa empresa.';
   RAISE v_exception;
  END IF;
  --
  v_salario_id    := salario_pkg.salario_id_atu_retornar(p_usuario_id);
  v_custo_hora    := 0;
  v_venda_hora    := 0;
  v_custo_hora_en := 0;
  v_venda_hora_en := 0;
  --
  IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe salário definido para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(venda_hora, 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
     INTO v_custo_hora_en,
          v_custo_hora,
          v_venda_hora_en,
          v_venda_hora
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  v_job_id      := NULL;
  v_cliente_id  := NULL;
  v_contrato_id := NULL;
  --
  IF rtrim(p_data) IS NULL
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
  v_data          := data_converter(p_data);
  v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
  v_area_cargo_id := NULL;
  --
  IF v_cargo_id IS NOT NULL
  THEN
   SELECT MAX(area_id)
     INTO v_area_cargo_id
     FROM cargo
    WHERE cargo_id = v_cargo_id;
   --
   v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
  END IF;
  --
  IF v_us_data_apontam_ini IS NOT NULL AND v_data < v_us_data_apontam_ini
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apontamentos só permitidos a partir de ' || data_mostrar(v_us_data_apontam_ini) || '.';
   RAISE v_exception;
  END IF;
  --
  IF v_us_data_apontam_fim IS NOT NULL AND v_data > v_us_data_apontam_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apontamentos só permitidos até ' || data_mostrar(v_us_data_apontam_fim) || '.';
   RAISE v_exception;
  END IF;
  --
  IF v_data > trunc(SYSDATE)
  THEN
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_FUT_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para apontar datas futuras.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_data > trunc(SYSDATE) + 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível antecipar apontamentos com mais de 60 dias da data atual.';
   RAISE v_exception;
  END IF;
  --
  IF feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 0
  THEN
   -- nao eh dia util. Testa privilegio.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_FOL_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para apontar aos sábados, domingos e feriados.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_job) IS NOT NULL
  THEN
   SELECT MAX(job_id),
          MAX(cliente_id),
          MAX(contrato_id)
     INTO v_job_id,
          v_cliente_id,
          v_contrato_id
     FROM job
    WHERE numero = TRIM(p_job)
      AND empresa_id = p_empresa_id;
   --
   IF v_job_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa (' || p_job || ').';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_job_id IS NULL AND nvl(p_tipo_apontam_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job || ' ou outro tipo de apontamento ' ||
                 'deve ser fornecido.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_apontam_id, 0) > 0
  THEN
   v_tipo_apontam_id := p_tipo_apontam_id;
   --
   SELECT MAX(codigo)
     INTO v_cod_apontam
     FROM tipo_apontam
    WHERE empresa_id = p_empresa_id
      AND tipo_apontam_id = v_tipo_apontam_id;
   --
   IF v_cod_apontam IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de apontamento não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  
  ELSE
   v_cod_apontam := 'JOB';
   --
   SELECT MAX(tipo_apontam_id)
     INTO v_tipo_apontam_id
     FROM tipo_apontam
    WHERE empresa_id = p_empresa_id
      AND codigo = v_cod_apontam;
   --
   IF v_tipo_apontam_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de apontamento ' || v_lbl_job || ' não encontrado.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  IF v_job_id IS NOT NULL AND v_cod_apontam <> 'JOB'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número do ' || v_lbl_job || ' não deve ser preenchido juntamente com a ' ||
                 'indicação de outro tipo de apontamento.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_horas) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número de horas é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_horas) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas inválido.';
   RAISE v_exception;
  END IF;
  --
  v_horas := round(numero_converter(p_horas), 2);
  --
  IF v_horas <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas inválido.';
   RAISE v_exception;
  END IF;
  --
  IF MOD(v_horas, v_horas_unidade) <> 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de horas precisa ser múltiplo de ' ||
                 numero_mostrar(v_horas_unidade, 2, 'N') || '.';
   RAISE v_exception;
  END IF;
  --
  v_status_hora := NULL;
  IF v_job_id IS NOT NULL AND v_flag_aprov_job = 'S'
  THEN
   v_status_hora := 'PEND';
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_id,
                                                         p_empresa_id,
                                                         v_cliente_id,
                                                         v_job_id);
  --
  SELECT MAX(unidade_negocio_id)
    INTO v_unid_neg_job_id
    FROM job
   WHERE job_id = v_job_id;
  --
  v_unid_neg_cli_id := pessoa_pkg.unid_negocio_retornar(v_cliente_id, v_job_id, p_usuario_id);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- verifica se já existe apontamento nessa data.
  SELECT MAX(apontam_data_id)
    INTO v_apontam_data_id
    FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND data = v_data;
  --
  IF v_apontam_data_id IS NOT NULL
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(venda_hora, 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0),
          num_horas_dia,
          num_horas_prod_dia
     INTO v_custo_hora_en,
          v_custo_hora,
          v_venda_hora_en,
          v_venda_hora,
          v_num_horas_dia,
          v_num_horas_prod_dia
     FROM apontam_data
    WHERE apontam_data_id = v_apontam_data_id;
  
  ELSE
   SELECT seq_apontam_data.nextval
     INTO v_apontam_data_id
     FROM dual;
   --
   INSERT INTO apontam_data
    (apontam_data_id,
     usuario_id,
     data,
     nivel,
     custo_hora,
     venda_hora,
     num_horas_dia,
     num_horas_prod_dia,
     status,
     cargo_id,
     area_cargo_id)
   VALUES
    (v_apontam_data_id,
     p_usuario_id,
     v_data,
     v_nivel,
     v_custo_hora_en,
     v_venda_hora_en,
     v_num_horas_dia,
     v_num_horas_prod_dia,
     'PEND',
     v_cargo_id,
     v_area_cargo_id);
  
  END IF;
  --
  v_custo := round(v_horas * v_custo_hora, 2);
  v_venda := round(v_horas * v_venda_hora, 2);
  --
  IF v_job_id IS NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id
      AND tipo_apontam_id = v_tipo_apontam_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe registro desse tipo de apontamento nessa data.';
    RAISE v_exception;
   END IF;
  
  ELSE
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id
      AND tipo_apontam_id = v_tipo_apontam_id
      AND job_id = v_job_id;
   --
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe registro de apontamento para esse ' || v_lbl_job || ' nessa data.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  -- encripta para salvar
  v_custo_en := util_pkg.num_encode(v_custo);
  --
  IF v_custo_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_en := util_pkg.num_encode(v_venda);
  --
  IF v_venda_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(area_id)
    INTO v_area_papel_id
    FROM papel
   WHERE papel_id = v_papel_id;
  --
  INSERT INTO apontam_hora
   (apontam_hora_id,
    apontam_data_id,
    job_id,
    cliente_id,
    contrato_id,
    papel_id,
    area_papel_id,
    horas,
    custo,
    venda,
    obs,
    tipo_apontam_id,
    status,
    unid_neg_usu_id,
    unid_neg_job_id,
    unid_neg_cli_id)
  VALUES
   (seq_apontam_hora.nextval,
    v_apontam_data_id,
    v_job_id,
    v_cliente_id,
    v_contrato_id,
    v_papel_id,
    v_area_papel_id,
    v_horas,
    v_custo_en,
    v_venda_en,
    p_obs,
    v_tipo_apontam_id,
    v_status_hora,
    v_unid_neg_usu_id,
    v_unid_neg_job_id,
    v_unid_neg_cli_id);
  --
  -- preenche a coluna de horas ajustadas
  apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  -- verifica total de horas apontadas no dia
  SELECT nvl(SUM(horas), 0)
    INTO v_tot_horas_dia
    FROM apontam_hora
   WHERE apontam_data_id = v_apontam_data_id;
  --
  IF v_tot_horas_dia > v_num_max_horas_dia
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O número de horas apontadas por dia não pode exceder ' ||
                 numero_mostrar(v_num_max_horas_dia, 2, 'N') || ' horas.';
   RAISE v_exception;
  END IF;
  --
  -- executa eventual transicao de status
  apontam_pkg.acao_executar(p_usuario_id,
                            p_empresa_id,
                            'N',
                            p_usuario_id,
                            v_data,
                            v_data,
                            'SALVAR',
                            NULL,
                            'S',
                            p_erro_cod,
                            p_erro_msg);
 
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE apontam_data
     SET data_apont = SYSDATE
   WHERE apontam_data_id = v_apontam_data_id;
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
 PROCEDURE horas_admin_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2004
  -- DESCRICAO: adiciona apontamentos administrativos para um determinado usuario e
  --   determinado intervalo de datas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  -- Silvia            19/08/2009  Implementação do valor de venda do usuario.
  -- Silvia            13/11/2009  Consistencias adicionais para o periodo informado.
  -- Silvia            05/04/2010  Ajuste em privilegio.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            23/04/2013  Novo parametro para indicar o tipo de apontamento.
  -- Silvia            15/04/2015  Realiza os apontamentos nos dias que derem, mantendo os
  --                               ja realizados.
  -- Silvia            23/06/2015  Grava data do apontamento.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            19/12/2016  Horas admin sao incluidas no status APRO ao inves de ENCE
  -- Silvia            28/12/2017  Inclusao de area do papel, cargo e area do cargo.
  -- Silvia            05/04/2019  Instancia nivel (vindo do usuario ou cargo)
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_tipo_apontam_id   IN apontam_hora.tipo_apontam_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_obs               IN apontam_hora.obs%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_data_ini           DATE;
  v_data_fim           DATE;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_data               apontam_data.data%TYPE;
  v_status             apontam_data.status%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_custo              apontam_hora.custo%TYPE;
  v_custo_en           apontam_hora.custo%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_papel_id           apontam_hora.papel_id%TYPE;
  v_area_papel_id      apontam_hora.area_papel_id%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_horas              apontam_hora.horas%TYPE;
  v_unid_neg_usu_id    apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id    apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id    apontam_hora.unid_neg_job_id%TYPE;
  v_horas_apontadas    NUMBER;
  v_num_horas_dia      NUMBER;
  v_horas_unidade      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_salario_id         salario.salario_id%TYPE;
  v_nivel              apontam_data.nivel%TYPE;
  v_empresa_id         empresa.empresa_id%TYPE;
  v_flag_salario_obrig VARCHAR2(50);
  --
 BEGIN
  v_qt                 := 0;
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id IS NULL OR p_usuario_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário para apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id <> p_usuario_sessao_id
  THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_ADMIN_C', NULL, NULL, p_empresa_id) <> 1
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  SELECT min_horas_apont_dia,
         num_horas_prod_dia,
         NULL
    INTO v_num_horas_dia,
         v_num_horas_prod_dia,
         v_nivel
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  v_horas_unidade := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                     'UNIDADE_APONTAM'));
  --
  IF v_num_horas_dia IS NULL
  THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL
  THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_apontam_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se eh mesmo um apontamento administrativo pertencente a empresa
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_apontam
   WHERE empresa_id = v_empresa_id
     AND tipo_apontam_id = p_tipo_apontam_id
     AND flag_sistema = 'N';
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento inválido ou inexistente.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_ini) IS NULL OR rtrim(p_data_fim) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_fim) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  v_data_fim := data_converter(p_data_fim);
  --
  IF v_data_ini > v_data_fim
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início do período não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_fim > trunc(SYSDATE) + 60
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não é possível antecipar apontamentos com mais de 60 dias da data atual.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_obs) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_obs) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  -- seleciona o papel do apontamento
  SELECT MAX(pa.papel_id)
    INTO v_papel_id
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id;
  --
  IF v_papel_id IS NULL
  THEN
   -- seleciona qualquer papel
   SELECT MAX(pa.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id;
   --
   IF v_papel_id IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não possui papel nessa empresa.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT MAX(area_id)
    INTO v_area_papel_id
    FROM papel
   WHERE papel_id = v_papel_id;
  --
  v_salario_id    := salario_pkg.salario_id_atu_retornar(p_usuario_id);
  v_custo_hora    := 0;
  v_venda_hora    := 0;
  v_custo_hora_en := 0;
  v_venda_hora_en := 0;
  --
  IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe salário definido para esse usuário.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_salario_id, 0) > 0
  THEN
   SELECT nvl(custo_hora, 0),
          nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
          nvl(venda_hora, 0),
          nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
     INTO v_custo_hora_en,
          v_custo_hora,
          v_venda_hora_en,
          v_venda_hora
     FROM salario
    WHERE salario_id = v_salario_id;
  
  END IF;
  --
  v_custo := round(v_horas * v_custo_hora, 2);
  v_venda := round(v_horas * v_venda_hora, 2);
  --
  -- encripta para salvar
  v_custo_en := util_pkg.num_encode(v_custo);
  --
  IF v_custo_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_venda_en := util_pkg.num_encode(v_venda);
  --
  IF v_venda_en = -99999
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_id, v_empresa_id, NULL, NULL);
  --
  v_unid_neg_job_id := NULL;
  v_unid_neg_cli_id := NULL;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data := v_data_ini;
  --
  WHILE v_data <= v_data_fim
  LOOP
   SELECT MAX(apontam_data_id)
     INTO v_apontam_data_id
     FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND data = v_data;
   --
   v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
   v_area_cargo_id := NULL;
   --
   IF v_cargo_id IS NOT NULL
   THEN
    SELECT MAX(area_id)
      INTO v_area_cargo_id
      FROM cargo
     WHERE cargo_id = v_cargo_id;
    --
    v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
   END IF;
   --
   IF v_apontam_data_id IS NULL
   THEN
    -- apontamento nao existe. Cria se for dia util.
    IF feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 1
    THEN
     SELECT seq_apontam_data.nextval
       INTO v_apontam_data_id
       FROM dual;
     --
     v_horas := v_num_horas_dia;
     --
     INSERT INTO apontam_data
      (apontam_data_id,
       usuario_id,
       data,
       nivel,
       custo_hora,
       venda_hora,
       num_horas_dia,
       num_horas_prod_dia,
       status,
       data_apont,
       cargo_id,
       area_cargo_id)
     VALUES
      (v_apontam_data_id,
       p_usuario_id,
       v_data,
       v_nivel,
       v_custo_hora_en,
       v_venda_hora_en,
       v_num_horas_dia,
       v_num_horas_prod_dia,
       'APRO',
       SYSDATE,
       v_cargo_id,
       v_area_cargo_id);
     --
     -- cria o apontamento administrativo
     INSERT INTO apontam_hora
      (apontam_hora_id,
       apontam_data_id,
       papel_id,
       area_papel_id,
       job_id,
       cliente_id,
       horas,
       custo,
       venda,
       obs,
       tipo_apontam_id,
       unid_neg_usu_id,
       unid_neg_job_id,
       unid_neg_cli_id)
     VALUES
      (seq_apontam_hora.nextval,
       v_apontam_data_id,
       v_papel_id,
       v_area_papel_id,
       NULL,
       NULL,
       v_horas,
       v_custo_en,
       v_venda_en,
       p_obs,
       p_tipo_apontam_id,
       v_unid_neg_usu_id,
       v_unid_neg_job_id,
       v_unid_neg_cli_id);
     --
     -- preenche a coluna de horas ajustadas
     apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000'
     THEN
      RAISE v_exception;
     END IF;
    END IF;
   ELSE
    -- apontamento ja existe. Verifica pendencia.
    SELECT status
      INTO v_status
      FROM apontam_data
     WHERE apontam_data_id = v_apontam_data_id;
    --
    IF v_status = 'PEND'
    THEN
     -- verifica horas apontadas
     SELECT nvl(SUM(horas), 0)
       INTO v_horas_apontadas
       FROM apontam_hora
      WHERE apontam_data_id = v_apontam_data_id;
     --
     IF v_horas_apontadas < v_num_horas_dia
     THEN
      -- completa com o apontamento administrativo
      v_horas := v_num_horas_dia - v_horas_apontadas;
      -- cria o apontamento administrativo
      INSERT INTO apontam_hora
       (apontam_hora_id,
        apontam_data_id,
        papel_id,
        area_papel_id,
        job_id,
        cliente_id,
        horas,
        custo,
        venda,
        obs,
        tipo_apontam_id,
        unid_neg_usu_id,
        unid_neg_job_id,
        unid_neg_cli_id)
      VALUES
       (seq_apontam_hora.nextval,
        v_apontam_data_id,
        v_papel_id,
        v_area_papel_id,
        NULL,
        NULL,
        v_horas,
        v_custo_en,
        v_venda_en,
        p_obs,
        p_tipo_apontam_id,
        v_unid_neg_usu_id,
        v_unid_neg_job_id,
        v_unid_neg_cli_id);
      --
      -- preenche a coluna de horas ajustadas
      apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF;
     --
     -- atualiza o apontamento existente
     UPDATE apontam_data
        SET status     = 'APRO',
            data_apont = SYSDATE
      WHERE apontam_data_id = v_apontam_data_id;
    
    END IF;
   
   END IF;
   --
   v_data := v_data + 1;
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
 END horas_admin_adicionar;
 --
 --
 PROCEDURE objeto_mostrar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/05/2013
  -- DESCRICAO: associa um determinado tipo de apontamento/objeto ao usuario de forma a
  --     mostrar no formulario de apontamento semanal.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/04/2022  Novo tipo de objeto CTR
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_objeto       IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id         IN hist_ender.objeto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_hist_ender_id hist_ender.hist_ender_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_objeto NOT IN ('JOB', 'OS', 'CLI', 'TAR', 'PRO', 'OPO', 'CTR') OR
     TRIM(p_tipo_objeto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de objeto inválido (' || p_tipo_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_objeto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da identificação do objeto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM pessoa
   WHERE empresa_id = p_empresa_id
     AND pessoa_id = p_objeto_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cliente não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(hist_ender_id)
    INTO v_hist_ender_id
    FROM hist_ender
   WHERE usuario_id = p_usuario_sessao_id
     AND tipo_objeto = p_tipo_objeto
     AND objeto_id = p_objeto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_hist_ender_id IS NOT NULL
  THEN
   UPDATE hist_ender
      SET flag_mostrar = 'S'
    WHERE hist_ender_id = v_hist_ender_id;
  
  ELSE
   INSERT INTO hist_ender
    (hist_ender_id,
     usuario_id,
     tipo_objeto,
     objeto_id,
     data_entrada,
     flag_mostrar)
   VALUES
    (seq_hist_ender.nextval,
     p_usuario_sessao_id,
     p_tipo_objeto,
     p_objeto_id,
     trunc(SYSDATE),
     'S');
  
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
 END objeto_mostrar;
 --
 --
 PROCEDURE objeto_ocultar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/05/2013
  -- DESCRICAO: oculta um determinado tipo de apontamento/objeto do usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/04/2022  Novo tipo de objeto CTR
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_objeto       IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id         IN hist_ender.objeto_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_hist_ender_id hist_ender.hist_ender_id%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_objeto NOT IN ('JOB', 'OS', 'CLI', 'TAR', 'PRO', 'OPO', 'CTR') OR
     TRIM(p_tipo_objeto) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de objeto inválido (' || p_tipo_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_objeto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da identificação do objeto é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT MAX(hist_ender_id)
    INTO v_hist_ender_id
    FROM hist_ender
   WHERE usuario_id = p_usuario_sessao_id
     AND tipo_objeto = p_tipo_objeto
     AND objeto_id = p_objeto_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF v_hist_ender_id IS NOT NULL
  THEN
   UPDATE hist_ender
      SET flag_mostrar = 'N'
    WHERE hist_ender_id = v_hist_ender_id;
  
  ELSE
   INSERT INTO hist_ender
    (hist_ender_id,
     usuario_id,
     tipo_objeto,
     objeto_id,
     data_entrada,
     flag_mostrar)
   VALUES
    (seq_hist_ender.nextval,
     p_usuario_sessao_id,
     p_tipo_objeto,
     p_objeto_id,
     trunc(SYSDATE),
     'N');
  
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
 END objeto_ocultar;
 --
 --
 PROCEDURE objeto_reexibir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/05/2013
  -- DESCRICAO: reexibe os tipos de apontamentos/objetos do usuario passados no vetor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN usuario.usuario_id%TYPE,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_vetor_hist_ender_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_vetor_hist_ender_id LONG;
  v_hist_ender_id       hist_ender.hist_ender_id%TYPE;
  v_tipo_objeto         hist_ender.tipo_objeto%TYPE;
  v_delimitador         CHAR(1);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_vetor_hist_ender_id := p_vetor_hist_ender_id;
  --
  WHILE nvl(length(rtrim(v_vetor_hist_ender_id)), 0) > 0
  LOOP
   v_hist_ender_id := nvl(to_number(prox_valor_retornar(v_vetor_hist_ender_id, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM hist_ender
    WHERE usuario_id = p_usuario_sessao_id
      AND hist_ender_id = v_hist_ender_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de apontamento não existe ou não pertence ao usuário (' ||
                  to_char(v_hist_ender_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT tipo_objeto
     INTO v_tipo_objeto
     FROM hist_ender
    WHERE hist_ender_id = v_hist_ender_id;
   --
   UPDATE hist_ender
      SET flag_mostrar = 'S'
    WHERE hist_ender_id = v_hist_ender_id;
  
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
 END objeto_reexibir;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 06/04/2004
  -- DESCRICAO: Exclusão de APONTAM
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/09/2022  Nova tabela apontam_oport
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_apontam_data_id   IN apontam_data.apontam_data_id%TYPE,
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
    FROM apontam_data
   WHERE apontam_data_id = p_apontam_data_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse apontamento não existe.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM apontam_hora
   WHERE apontam_data_id = p_apontam_data_id;
  --
  DELETE FROM apontam_job
   WHERE apontam_data_id = p_apontam_data_id;
  --
  DELETE FROM apontam_oport
   WHERE apontam_data_id = p_apontam_data_id;
  --
  DELETE FROM apontam_data_ev
   WHERE apontam_data_id = p_apontam_data_id;
  --
  DELETE FROM apontam_data
   WHERE apontam_data_id = p_apontam_data_id;
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
 END excluir;
 --
 --
 PROCEDURE horas_pend_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 21/05/2014
  -- DESCRICAO: Exclusão de apontamento de horas pendentes para usuarios inativos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia             dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN usuario.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_flag_ativo usuario.flag_ativo%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'APONTAM_C', NULL, NULL, p_empresa_id) <> 1
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_usuario_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Eliminação não confirmada.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(flag_ativo)
    INTO v_flag_ativo
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_flag_ativo IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_ativo = 'S'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Usuário ativo não pode ter apontamentos pendentes eliminados.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- exclusao de apontamentos pendentes sem horas apontadas
  DELETE FROM apontam_data_ev ae
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_id = p_usuario_id
             AND ad.status = 'PEND'
             AND ad.apontam_data_id = ae.apontam_data_id
             AND NOT EXISTS (SELECT 1
                    FROM apontam_hora ah
                   WHERE ah.apontam_data_id = ad.apontam_data_id));
 
  DELETE FROM apontam_data ad
   WHERE usuario_id = p_usuario_id
     AND status = 'PEND'
     AND NOT EXISTS (SELECT 1
            FROM apontam_hora ah
           WHERE ah.apontam_data_id = ad.apontam_data_id);
  --
  -- encerramento de apontamentos parciais (o que ja foi submetido,
  -- permanece para aprovacao)
  UPDATE apontam_data ad
     SET status = 'ENCE'
   WHERE usuario_id = p_usuario_id
     AND status IN ('PEND', 'APON');
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
 END horas_pend_excluir;
 --
 --
 PROCEDURE apontamento_horas_ajustar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias               ProcessMind     DATA: 18/07/2005
  -- DESCRICAO: subrotina que ajusta as horas apontadas, fazendo a proporção para a
  --    quantidade de horas do campo apontam_data.num_horas_dia e preenche no campo
  --    apontam_hora.horas_ajustadas.      NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Joel Dias         dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_apontam_data_id IN apontam_data.apontam_data_id%TYPE,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_total_dia       NUMBER;
  v_num_horas_dia   NUMBER;
  v_horas_ajustadas apontam_hora.horas_ajustadas%TYPE;
  v_exception       EXCEPTION;
  v_erro_cod        VARCHAR2(20);
  v_erro_msg        VARCHAR2(200);
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- consistência do parâmetro de entrada
  ------------------------------------------------------------
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data
   WHERE apontam_data_id = p_apontam_data_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa data para apontamento não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE apontam_data_id = p_apontam_data_id;
  --
  ------------------------------------------------------------
  -- atualização do banco de dados
  ------------------------------------------------------------
  IF v_qt > 0
  THEN
   SELECT num_horas_dia
     INTO v_num_horas_dia
     FROM apontam_data
    WHERE apontam_data_id = p_apontam_data_id;
   --
   SELECT nvl(SUM(horas), 0)
     INTO v_total_dia
     FROM apontam_hora
    WHERE apontam_data_id = p_apontam_data_id;
   --
   IF v_total_dia > 0
   THEN
    UPDATE apontam_hora h
       SET horas_ajustadas = round(v_num_horas_dia / v_total_dia * horas, 2)
     WHERE h.apontam_data_id = p_apontam_data_id;
   
   ELSE
    UPDATE apontam_hora h
       SET horas_ajustadas = 0
     WHERE h.apontam_data_id = p_apontam_data_id;
   
   END IF;
  
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_cod := '90000';
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
 END apontamento_horas_ajustar;
 --
 --
 PROCEDURE apontamento_custo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 02/10/2008
  -- DESCRICAO: subrotina que atualiza os custos dos apontamentos de um determinado usuario,
  --   desde uma determinada data.    NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/08/2009  Implementação do valor de venda do usuario.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data       IN DATE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_erro_cod           VARCHAR2(20);
  v_erro_msg           VARCHAR2(200);
  v_salario_id         salario.salario_id%TYPE;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_custo              apontam_hora.custo%TYPE;
  v_custo_en           apontam_hora.custo%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_flag_salario_obrig VARCHAR2(50);
  --
  CURSOR c_ap IS
   SELECT apontam_data_id,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND trunc(data) >= trunc(p_data)
    ORDER BY data;
  --
  CURSOR c_ah IS
   SELECT apontam_hora_id,
          horas
     FROM apontam_hora
    WHERE apontam_data_id = v_apontam_data_id
    ORDER BY apontam_hora_id;
  --
 BEGIN
  v_qt                 := 0;
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- atualização do banco de dados
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_id, r_ap.data);
   v_custo_hora    := 0;
   v_venda_hora    := 0;
   v_custo_hora_en := 0;
   v_venda_hora_en := 0;
   --
   IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Não existe salário definido para esse usuário ' || 'na data de ' ||
                  data_mostrar(r_ap.data) || '.';
   
    RAISE v_exception;
   END IF;
   --
   IF nvl(v_salario_id, 0) > 0
   THEN
    SELECT nvl(custo_hora, 0),
           nvl(util_pkg.num_decode(custo_hora, g_key_num), 0),
           nvl(venda_hora, 0),
           nvl(util_pkg.num_decode(venda_hora, g_key_num), 0)
      INTO v_custo_hora_en,
           v_custo_hora,
           v_venda_hora_en,
           v_venda_hora
      FROM salario
     WHERE salario_id = v_salario_id;
   
   END IF;
   --
   v_apontam_data_id := r_ap.apontam_data_id;
   --
   UPDATE apontam_data
      SET custo_hora = v_custo_hora_en,
          venda_hora = v_venda_hora_en
    WHERE apontam_data_id = v_apontam_data_id;
   --
   FOR r_ah IN c_ah
   LOOP
    v_custo := round(r_ah.horas * v_custo_hora, 2);
    v_venda := round(r_ah.horas * v_venda_hora, 2);
    --
    -- encripta para salvar
    v_custo_en := util_pkg.num_encode(v_custo);
    --
    IF v_custo_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_venda_en := util_pkg.num_encode(v_venda);
    --
    IF v_venda_en = -99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE apontam_hora
       SET custo = v_custo_en,
           venda = v_venda_en
     WHERE apontam_data_id = r_ap.apontam_data_id;
   
   END LOOP;
  
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_cod := '90000';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END apontamento_custo_atualizar;
 --
 --
 PROCEDURE apontamento_cargo_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 28/12/2017
  -- DESCRICAO: subrotina que atualiza o cargo/area dos apontamentos de um determinado usuario,
  --   desde uma determinada data.    NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/04/2019  Atualiza nivel vindo do cargo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data       IN DATE,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
 
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_erro_cod      VARCHAR2(20);
  v_erro_msg      VARCHAR2(200);
  v_cargo_id      apontam_data.cargo_id%TYPE;
  v_area_cargo_id apontam_data.area_cargo_id%TYPE;
  v_nivel         apontam_data.nivel%TYPE;
  --
  CURSOR c_ap IS
   SELECT apontam_data_id,
          data,
          nivel
     FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND trunc(data) >= trunc(p_data)
    ORDER BY data;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- atualização do banco
  ------------------------------------------------------------
  FOR r_ap IN c_ap
  LOOP
   v_cargo_id := cargo_pkg.do_usuario_retornar(p_usuario_id, r_ap.data, p_empresa_id);
   v_nivel    := r_ap.nivel;
   --
   IF v_cargo_id IS NOT NULL
   THEN
    SELECT MAX(area_id)
      INTO v_area_cargo_id
      FROM cargo
     WHERE cargo_id = v_cargo_id;
    --
    v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, r_ap.data, p_empresa_id);
   END IF;
   --
   UPDATE apontam_data
      SET cargo_id      = v_cargo_id,
          area_cargo_id = v_area_cargo_id,
          nivel         = v_nivel
    WHERE apontam_data_id = r_ap.apontam_data_id;
  
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   p_erro_cod := '90000';
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END apontamento_cargo_atualizar;
 --
 --
 PROCEDURE horas_job_acao_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 10/07/2018
  -- DESCRICAO: aprovacao de horas pelo gestor do job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id     IN usuario.usuario_id%TYPE,
  p_empresa_id            IN empresa.empresa_id%TYPE,
  p_vetor_apontam_hora_id IN LONG,
  p_cod_acao              IN VARCHAR2,
  p_coment_acao           IN VARCHAR2,
  p_erro_cod              OUT VARCHAR2,
  p_erro_msg              OUT VARCHAR2
 ) IS
 
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_delimitador           CHAR(1);
  v_vetor_apontam_hora_id LONG;
  v_status_hora           apontam_hora.status%TYPE;
  v_apontam_hora_id       apontam_hora.apontam_hora_id%TYPE;
  v_status_old            apontam_hora.status%TYPE;
  v_status                apontam_hora.status%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF p_usuario_sessao_id IS NULL OR p_usuario_sessao_id = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário da sessão é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao IS NULL OR p_cod_acao NOT IN ('APROVAR', 'REPROVAR')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_cod_acao = 'APROVAR' AND TRIM(p_coment_acao) IS NOT NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para a ação de Aprovar, o comentário não deve ser preenchido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_coment_acao)) > 500
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- tratamento do vetor
  ------------------------------------------------------------
  v_vetor_apontam_hora_id := p_vetor_apontam_hora_id;
  --
  WHILE nvl(length(rtrim(v_vetor_apontam_hora_id)), 0) > 0
  LOOP
   v_apontam_hora_id := nvl(to_number(prox_valor_retornar(v_vetor_apontam_hora_id, v_delimitador)),
                            0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_hora
    WHERE apontam_hora_id = v_apontam_hora_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Apontamento de hora inválido (' || to_char(v_apontam_hora_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT status
     INTO v_status_old
     FROM apontam_hora
    WHERE apontam_hora_id = v_apontam_hora_id;
   --
   IF v_status_old IS NULL OR (p_cod_acao = 'APROVAR' AND v_status_old NOT IN ('PEND', 'REPR')) OR
      (p_cod_acao = 'REPROVAR' AND v_status_old <> 'PEND')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Transisão inválida (' || to_char(v_apontam_hora_id) || ' - ' || v_status_old ||
                  ' - ' || p_cod_acao || ').';
   
    RAISE v_exception;
   END IF;
   --
   v_status := NULL;
   IF p_cod_acao = 'APROVAR'
   THEN
    v_status := 'APRO';
   ELSIF p_cod_acao = 'REPROVAR'
   THEN
    v_status := 'REPR';
   END IF;
   --
   UPDATE apontam_hora
      SET usuario_acao_id = p_usuario_sessao_id,
          data_acao       = SYSDATE,
          status          = v_status,
          coment_acao     = TRIM(p_coment_acao)
    WHERE apontam_hora_id = v_apontam_hora_id;
  
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
 END horas_job_acao_executar;
 --
 --
 --
 PROCEDURE marcar_home_office
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Ana Luiza               ProcessMind     DATA: 13/03/2024
  -- DESCRICAO: Rotina que marca home office mesmo apos apontamento de horas.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_flag_home_office  IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_hist_ender_id hist_ender.hist_ender_id%TYPE;
  --
  v_data_ini apontam_data.data%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF nvl(p_usuario_sessao_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_empresa_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da empresa é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_ini) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF flag_validar(p_flag_home_office) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag home office inválido.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE apontam_data
     SET flag_home_office = p_flag_home_office
   WHERE data = v_data_ini
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
 END marcar_home_office;
 --
 --
 FUNCTION em_dia_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2000
  -- DESCRICAO: verifica se um determinado usuario esta' com os apontamentos em dia.
  --  Retorna 1 caso esteja, 0 caso nao. Parametro p_tipo:
  --    BLOQ_APONT - verificacao de bloqueio de login por falta de apontamento
  --    BLOQ_APROV - verificacao de boqueio de login por falta de aprovacao
  --    NOTIF_APONT - verificacao de envio de notificacao por falta de apontamento
  --    NOTIF_APROV - verificacao de envio de notificacao por falta de aprovacao
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            24/05/2013  Novo parametro p_tipo_verificacao
  -- Silvia            27/12/2013  Despreza fim-de-semana ou feriados.
  -- Silvia            30/05/2016  Verifica tb parametros da empresa.
  ------------------------------------------------------------------------------------------
  p_usuario_id       IN usuario.usuario_id%TYPE,
  p_tipo_verificacao IN VARCHAR2
 ) RETURN INTEGER AS
 
  v_qt                   INTEGER;
  v_qt_pend              INTEGER;
  v_qt_eqp               INTEGER;
  v_qt_job               INTEGER;
  v_em_dia               INTEGER;
  v_num_dias_sem_apontam INTEGER;
  v_empresa_id           empresa.empresa_id%TYPE;
  v_flag_sem_bloq_apont  usuario.flag_sem_bloq_apont%TYPE;
  v_flag_sem_bloq_aprov  usuario.flag_sem_bloq_aprov%TYPE;
  v_flag_admin           usuario.flag_admin%TYPE;
  v_dia_aprov            INTEGER;
  v_data_ref             DATE;
  v_data_aprov           DATE;
  v_data_hoje            DATE;
  v_exception            EXCEPTION;
  v_flag_bloq_apont_emp  VARCHAR2(10);
  v_flag_bloq_aprov_emp  VARCHAR2(10);
  v_flag_com_aprov_job   VARCHAR2(10);
  --
 BEGIN
  v_em_dia := 0;
  --
  IF TRIM(p_tipo_verificacao) IS NULL OR
     p_tipo_verificacao NOT IN ('BLOQ_APONT', 'BLOQ_APROV', 'NOTIF_APONT', 'NOTIF_APROV')
  THEN
   RAISE v_exception;
  END IF;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  -- recupera configuracoes da empresa
  v_flag_bloq_apont_emp := empresa_pkg.parametro_retornar(v_empresa_id,
                                                          'FLAG_BLOQ_USU_APONTAM_PEND');
  v_flag_bloq_aprov_emp := empresa_pkg.parametro_retornar(v_empresa_id, 'FLAG_BLOQ_USU_APROV_PEND');
  v_flag_com_aprov_job  := empresa_pkg.parametro_retornar(v_empresa_id, 'APONTAM_COM_APROV_GESJOB');
  --
  -- recupera configuracoes do usuario
  SELECT flag_sem_bloq_apont,
         flag_sem_bloq_aprov,
         flag_admin
    INTO v_flag_sem_bloq_apont,
         v_flag_sem_bloq_aprov,
         v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_flag_admin = 'S'
  THEN
   v_flag_sem_bloq_apont := 'S';
   v_flag_sem_bloq_aprov := 'S';
  END IF;
  --
  IF p_tipo_verificacao IN ('BLOQ_APONT', 'NOTIF_APONT') AND
     (v_flag_sem_bloq_apont = 'S' OR v_flag_bloq_apont_emp = 'N')
  THEN
   -- verificacao de bloqueio de login por falta de apontamento.
   -- usuario sem bloqueio ou empresa sem bloqueio. Pode liberar.
   v_em_dia := 1;
   --
  ELSIF p_tipo_verificacao IN ('BLOQ_APROV', 'NOTIF_APROV') AND
        (v_flag_sem_bloq_aprov = 'S' OR v_flag_bloq_aprov_emp = 'N')
  THEN
   -- verificacao de bloqueio de login por falta de aprovacao.
   -- usuario sem bloqueio ou empresa sem bloqueio. Pode liberar.
   v_em_dia := 1;
   --
  ELSIF p_tipo_verificacao IN ('BLOQ_APONT', 'NOTIF_APONT')
  THEN
   -- verifica se o usuario deve apontar horas.
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_id
      AND up.papel_id = pa.papel_id
      AND pa.flag_apontam_form = 'S';
   --
   IF v_qt > 0
   THEN
    -- verifica o numero max de dias que o usuario pode ficar sem apontar
    v_num_dias_sem_apontam := round(numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                                    'NUM_DIAS_UTEIS_SEM_APONTAM')),
                                    0);
    --
    -- verifica quantos dias o usuario ficou sem apontar ou sem submeter (nao
    -- leva em conta apontamentos em fim-de-semana ou feriado).
    SELECT COUNT(*)
      INTO v_qt_pend
      FROM apontam_data
     WHERE usuario_id = p_usuario_id
       AND status IN ('PEND', 'APON', 'REPR')
       AND data <= trunc(SYSDATE)
       AND feriado_pkg.dia_util_verificar(p_usuario_id, data, 'S') = 1;
    --
    IF p_tipo_verificacao IN ('BLOQ_APONT', 'NOTIF_APONT') AND v_qt_pend <= v_num_dias_sem_apontam
    THEN
     -- ok, as pendencias sao menores do que o limite
     v_em_dia := 1;
    END IF;
    --
    /*
    IF p_tipo_verificacao = 'NOTIF_APONT' AND
       v_qt_pend NOT IN(v_num_dias_sem_apontam +1) THEN
       -- nao gera notificacao. So dispara no dia do bloqueio.
       v_em_dia := 1;
    END IF; */
   ELSE
    -- usuario nao aponta horas
    v_em_dia := 1;
   END IF;
   --
  ELSIF p_tipo_verificacao IN ('BLOQ_APROV', 'NOTIF_APROV')
  THEN
   v_qt_eqp := 0;
   v_qt_job := 0;
   --
   -- verifica se o usuario deve aprovar horas da equipe.
   SELECT COUNT(*)
     INTO v_qt_eqp
     FROM ts_aprovador
    WHERE usuario_id = p_usuario_id;
   --
   -- verifica se o usuario deve aprovar horas de job.
   IF v_flag_com_aprov_job = 'S'
   THEN
    SELECT COUNT(*)
      INTO v_qt_job
      FROM job jo
     WHERE usuario_pkg.priv_verificar(p_usuario_id,
                                      'HORA_APONT_JOB_AP',
                                      jo.job_id,
                                      NULL,
                                      v_empresa_id) = 1
       AND jo.empresa_id = v_empresa_id
       AND EXISTS (SELECT 1
              FROM apontam_hora ah
             WHERE ah.job_id = jo.job_id
               AND ah.status = 'PEND');
   
   END IF;
   --
   IF v_qt_eqp > 0 OR v_qt_job > 0
   THEN
    v_dia_aprov := nvl(to_number(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                'DIA_LIMITE_APROV_HORAS')),
                       10);
    --
    IF v_dia_aprov >= 28
    THEN
     v_dia_aprov := 27;
    END IF;
    --
    IF p_tipo_verificacao = 'BLOQ_APROV'
    THEN
     IF to_number(to_char(SYSDATE, 'DD')) > v_dia_aprov
     THEN
      -- passou do dia da aprovacao. Pega o ultimo dia do mes anterior
      v_data_ref := trunc(last_day(add_months(SYSDATE, -1)));
     ELSE
      -- nao passou do dia da aprovacao. Pega o ultimo dia de dois meses antes
      v_data_ref := trunc(last_day(add_months(SYSDATE, -2)));
     END IF;
     --
     IF v_qt_eqp > 0
     THEN
      SELECT COUNT(*)
        INTO v_qt_pend
        FROM ts_aprovador ap,
             ts_equipe    eq,
             apontam_data ad
       WHERE ap.usuario_id = p_usuario_id
         AND ap.ts_grupo_id = eq.ts_grupo_id
         AND eq.usuario_id = ad.usuario_id
         AND ad.status = 'SUBM'
         AND ad.data <= v_data_ref;
      --
      IF v_qt_pend = 0
      THEN
       v_em_dia := 1;
      END IF;
     END IF;
     --
     IF v_qt_job > 0
     THEN
      SELECT COUNT(*)
        INTO v_qt_pend
        FROM job jo
       WHERE usuario_pkg.priv_verificar(p_usuario_id,
                                        'HORA_APONT_JOB_AP',
                                        jo.job_id,
                                        NULL,
                                        v_empresa_id) = 1
         AND jo.empresa_id = v_empresa_id
         AND EXISTS (SELECT 1
                FROM apontam_hora ah,
                     apontam_data ad
               WHERE ah.job_id = jo.job_id
                 AND ah.status = 'PEND'
                 AND ah.apontam_data_id = ad.apontam_data_id
                 AND ad.data <= v_data_ref);
      --
      IF v_qt_pend = 0
      THEN
       v_em_dia := 1;
      END IF;
     END IF;
    
    END IF; -- fim do IF p_tipo_verificacao = 'BLOQ_APROV'
    --
    IF p_tipo_verificacao = 'NOTIF_APROV'
    THEN
     v_data_hoje  := trunc(SYSDATE);
     v_data_aprov := data_converter(v_dia_aprov || '/' || to_char(v_data_hoje, 'MM/YYYY'));
     --
     IF v_data_hoje = v_data_aprov
     THEN
      -- eh a data limite para aprovacao. Verifica se precisa notificar.
      -- Pega o ultimo dia do mes anterior.
      v_data_ref := trunc(last_day(add_months(v_data_hoje, -1)));
      --
      IF v_qt_eqp > 0
      THEN
       SELECT COUNT(*)
         INTO v_qt_pend
         FROM ts_aprovador ap,
              ts_equipe    eq,
              apontam_data ad
        WHERE ap.usuario_id = p_usuario_id
          AND ap.ts_grupo_id = eq.ts_grupo_id
          AND eq.usuario_id = ad.usuario_id
          AND ad.status = 'SUBM'
          AND ad.data <= v_data_ref;
       --
       IF v_qt_pend = 0
       THEN
        v_em_dia := 1;
       END IF;
      END IF;
      --
      IF v_qt_job > 0
      THEN
       SELECT COUNT(*)
         INTO v_qt_pend
         FROM job jo
        WHERE usuario_pkg.priv_verificar(p_usuario_id,
                                         'HORA_APONT_JOB_AP',
                                         jo.job_id,
                                         NULL,
                                         v_empresa_id) = 1
          AND jo.empresa_id = v_empresa_id
          AND EXISTS (SELECT 1
                 FROM apontam_hora ah,
                      apontam_data ad
                WHERE ah.job_id = jo.job_id
                  AND ah.status = 'PEND'
                  AND ah.apontam_data_id = ad.apontam_data_id
                  AND ad.data <= v_data_ref);
       --
       IF v_qt_pend = 0
       THEN
        v_em_dia := 1;
       END IF;
      END IF;
     
     ELSE
      -- nao chegou o dia da notificacao
      v_em_dia := 1;
     END IF; -- fim do IF v_data_hoje = v_data_aprov
    END IF; -- fim do IF p_tipo_verificacao = 'NOTIF_APROV'
    --
   ELSE
    -- usuario nao precisa aprovar horas
    v_em_dia := 1;
   END IF; -- fim do IF v_qt_eqp > 0 OR v_qt_job > 0
  END IF; -- fim do IF p_tipo_verificacao
  --
  RETURN v_em_dia;
  --
 EXCEPTION
  WHEN v_exception THEN
   v_em_dia := 0;
   RETURN v_em_dia;
  WHEN OTHERS THEN
   v_em_dia := 0;
   RETURN v_em_dia;
 END em_dia_verificar;
 --
 --
 FUNCTION apontam_ence_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 19/12/2016
  -- DESCRICAO: verifica se no periodo (mes/ano) dessa empresa, os apontamentos estao no
  --   status em que podem ser encerrados
  --  Retorna 1 caso esteja ok, 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_empresa_id       IN empresa.empresa_id%TYPE,
  p_mes_ano          IN apontam_ence.mes_ano%TYPE,
  p_tipo_verificacao IN VARCHAR2
 ) RETURN INTEGER AS
  v_qt        INTEGER;
  v_ok        INTEGER;
  v_data_ini  DATE;
  v_data_fim  DATE;
  v_exception EXCEPTION;
  --
 BEGIN
  v_ok := 0;
  --
  v_data_ini := data_converter('01/' || substr(data_mostrar(p_mes_ano), 4));
 
  v_data_fim := last_day(v_data_ini);
  --
  IF TRIM(p_tipo_verificacao) IS NULL OR p_tipo_verificacao NOT IN ('APONT', 'APROV')
  THEN
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_verificacao = 'APONT'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_data
    WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status IN ('PEND', 'APON', 'REPR')
      AND rownum = 1;
   --
   IF v_qt = 0
   THEN
    -- nao existe pendencia de apontamento
    v_ok := 1;
   END IF;
  END IF;
  --
  IF p_tipo_verificacao = 'APROV'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_data
    WHERE usuario_pkg.empresa_padrao_retornar(usuario_id) = p_empresa_id
      AND data BETWEEN v_data_ini AND v_data_fim
      AND status = 'SUBM'
      AND rownum = 1;
   --
   IF v_qt = 0
   THEN
    -- nao existe pendencia de aprovacao
    v_ok := 1;
   END IF;
  END IF;
  --
  RETURN v_ok;
  --
 EXCEPTION
  WHEN v_exception THEN
   v_ok := 0;
   RETURN v_ok;
  WHEN OTHERS THEN
   v_ok := 0;
   RETURN v_ok;
 END apontam_ence_verificar;
 --
 --
 FUNCTION num_dias_status_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2000
  -- DESCRICAO: retorna o numero de dias com apontamentos do usuario que estao num
  --   determinado status. Despreza datas futuras.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_status     IN apontam_data.status%TYPE
 ) RETURN INTEGER AS
  v_qt       INTEGER;
  v_num_dias INTEGER;
  --
 BEGIN
  v_num_dias := 0;
  --
  SELECT COUNT(*)
    INTO v_num_dias
    FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND status = p_status
     AND data <= trunc(SYSDATE);
  --
  RETURN v_num_dias;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_num_dias := -1;
   RETURN v_num_dias;
 END num_dias_status_retornar;
 --
 --
 FUNCTION completo_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/05/2013
  -- DESCRICAO: verifica se um determinado usuario esta' com os apontamentos completos
  --  num periodo.  Retorna 1 caso esteja, 0 caso nao.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/01/2015  Despreza apontamentos encerrados.
  ------------------------------------------------------------------------------------------
  p_usuario_id IN apontam_data.usuario_id%TYPE,
  p_empresa_id IN empresa.empresa_id%TYPE,
  p_data_ini   IN apontam_data.data%TYPE,
  p_data_fim   IN apontam_data.data%TYPE
 ) RETURN INTEGER AS
 
  v_qt              INTEGER;
  v_completo        INTEGER;
  v_aponta          INTEGER;
  v_apontam_data_id apontam_data.apontam_data_id%TYPE;
  v_num_horas_dia   NUMBER;
  v_tot_horas_dia   NUMBER;
  --
  CURSOR c_ap IS
   SELECT apontam_data_id,
          data
     FROM apontam_data
    WHERE usuario_id = p_usuario_id
      AND data BETWEEN trunc(p_data_ini) AND trunc(p_data_fim)
      AND status <> 'ENCE'
    ORDER BY data;
  --
 BEGIN
  v_completo := 1;
  --
  -- verifica se o usuario precisa apontar horas
  SELECT COUNT(*)
    INTO v_aponta
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = p_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S';
  --
  IF v_aponta > 0
  THEN
   FOR r_ap IN c_ap
   LOOP
    SELECT nvl(num_horas_dia, 0)
      INTO v_num_horas_dia
      FROM apontam_data
     WHERE apontam_data_id = r_ap.apontam_data_id;
    --
    SELECT nvl(SUM(horas), 0)
      INTO v_tot_horas_dia
      FROM apontam_hora
     WHERE apontam_data_id = r_ap.apontam_data_id;
    --
    IF v_tot_horas_dia < v_num_horas_dia AND
       feriado_pkg.dia_util_verificar(p_usuario_id, r_ap.data, 'S') = 1
    THEN
     v_completo := 0;
    END IF;
   
   END LOOP;
  END IF;
  --
  RETURN v_completo;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_completo := 0;
   RETURN v_completo;
 END completo_verificar;
 --
 --
 FUNCTION horas_apontadas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 30/06/2008
  -- DESCRICAO: retorna o total de horas apontadas p/ um determinado usuario/data
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_apontam_data_id IN apontam_data.apontam_data_id%TYPE,
  p_tipo_apontam    IN VARCHAR2
 ) RETURN NUMBER AS
 
  v_qt           INTEGER;
  v_retorno      NUMBER;
  v_aux          NUMBER;
  v_tipo_apontam VARCHAR2(500);
  v_tipo_aux     tipo_apontam.codigo%TYPE;
  v_delimitador  CHAR(1);
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_apontam = 'TOT'
  THEN
   -- total de horas apontadas no dia
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora
    WHERE apontam_data_id = p_apontam_data_id;
  
  ELSIF instr(p_tipo_apontam, ',') = 0
  THEN
   -- horas apontadas para um tipo especifico
   SELECT nvl(SUM(ah.horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          tipo_apontam ti
    WHERE ah.apontam_data_id = p_apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam;
  
  ELSE
   -- horas apontadas para os tipos passados no vetor
   v_delimitador  := ',';
   v_tipo_apontam := p_tipo_apontam;
   --
   WHILE nvl(length(rtrim(v_tipo_apontam)), 0) > 0
   LOOP
    v_tipo_aux := prox_valor_retornar(v_tipo_apontam, v_delimitador);
    --
    SELECT nvl(SUM(ah.horas), 0)
      INTO v_aux
      FROM apontam_hora ah,
           tipo_apontam ti
     WHERE ah.apontam_data_id = p_apontam_data_id
       AND ah.tipo_apontam_id = ti.tipo_apontam_id
       AND ti.codigo = v_tipo_aux;
    --
    v_retorno := v_retorno + v_aux;
   END LOOP;
  
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999999;
   RETURN v_retorno;
 END horas_apontadas_retornar;
 --
 --
 FUNCTION horas_apontadas_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 07/05/2013
  -- DESCRICAO: retorna o total de horas apontadas p/ um determinado usuario/data
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            29/07/2019  Novo tipo de apontam: Oportunidade
  -- Silvia            06/04/2022  Novo tipo de apontam: Contrato
  ------------------------------------------------------------------------------------------
  p_usuario_id   IN apontam_data.usuario_id%TYPE,
  p_data         IN apontam_data.data%TYPE,
  p_tipo_apontam IN VARCHAR2,
  p_objeto_id    IN NUMBER
 ) RETURN NUMBER AS
  v_qt      INTEGER;
  v_retorno NUMBER;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_apontam = 'JOB'
  THEN
   -- horas apontadas no job
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.job_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'CLI'
  THEN
   -- horas apontadas no cliente
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.cliente_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'OS'
  THEN
   -- horas apontadas na OS
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.ordem_servico_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'OPO'
  THEN
   -- horas apontadas na Oportunidade
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.oportunidade_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'CTR'
  THEN
   -- horas apontadas em contrato
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.contrato_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'PRO'
  THEN
   -- horas apontadas no produto do cliente
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.produto_cliente_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'TAR'
  THEN
   -- horas apontadas na tarefa
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.tarefa_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'TOT'
  THEN
   -- total de horas apontadas
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id;
  
  ELSE
   -- horas de determinado tipo administrativo
   SELECT nvl(SUM(horas), 0)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam;
  
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999999;
   RETURN v_retorno;
 END horas_apontadas_retornar;
 --
 --
 FUNCTION obs_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/09/2019
  -- DESCRICAO: retorna a obs p/ um determinado apontam/usuario/data
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            06/04/2022  Novo tipo de objeto: CTR
  ------------------------------------------------------------------------------------------
  p_usuario_id   IN apontam_data.usuario_id%TYPE,
  p_data         IN apontam_data.data%TYPE,
  p_tipo_apontam IN VARCHAR2,
  p_objeto_id    IN NUMBER
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno apontam_hora.obs%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_tipo_apontam = 'JOB'
  THEN
   -- horas apontadas no job
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.job_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'CLI'
  THEN
   -- horas apontadas no cliente
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.cliente_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'OS'
  THEN
   -- horas apontadas na OS
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.ordem_servico_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'OPO'
  THEN
   -- horas apontadas na Oportunidade
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.oportunidade_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'CTR'
  THEN
   -- horas apontadas no contrato
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.contrato_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'PRO'
  THEN
   -- horas apontadas no produto do cliente
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.produto_cliente_id = p_objeto_id;
  
  ELSIF p_tipo_apontam = 'TAR'
  THEN
   -- horas apontadas na tarefa
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam
      AND ah.tarefa_id = p_objeto_id;
  
  ELSE
   -- horas de determinado tipo administrativo
   SELECT MAX(ah.obs)
     INTO v_retorno
     FROM apontam_hora ah,
          apontam_data ad,
          tipo_apontam ti
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = p_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.codigo = p_tipo_apontam;
  
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999999;
   RETURN v_retorno;
 END obs_retornar;
 --
 --
 FUNCTION data_ult_apontam_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2000
  -- DESCRICAO: retorna a data do ultimo apontam de um determinado usuario.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE
 ) RETURN DATE AS
  v_qt               INTEGER;
  v_data_ult_apontam DATE;
  --
 BEGIN
  v_data_ult_apontam := NULL;
  --
  SELECT MAX(data)
    INTO v_data_ult_apontam
    FROM apontam_data ad
   WHERE usuario_id = p_usuario_id
     AND EXISTS (SELECT 1
            FROM apontam_hora ah
           WHERE ad.apontam_data_id = ah.apontam_data_id
             AND ah.horas > 0);
  --
  RETURN v_data_ult_apontam;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_data_ult_apontam := NULL;
   RETURN v_data_ult_apontam;
 END data_ult_apontam_retornar;
 --
 --
 FUNCTION status_periodo_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/05/2013
  -- DESCRICAO: retorna o menor status dos apontamentos do usuario no periodo informado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         01/03/2024  Ajuste para meses encerrados
  ------------------------------------------------------------------------------------------
  p_usuario_id IN apontam_data.usuario_id%TYPE,
  p_data_ini   IN apontam_data.data%TYPE,
  p_data_fim   IN apontam_data.data%TYPE
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno VARCHAR2(20);
  v_ordem   dicionario.ordem%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MIN(di.ordem)
    INTO v_ordem
    FROM apontam_data ad,
         dicionario   di
   WHERE ad.usuario_id = p_usuario_id
     AND ad.data BETWEEN p_data_ini AND p_data_fim
     AND ad.status = di.codigo
     AND di.tipo = 'status_apontam';
  --
  SELECT MIN(codigo)
    INTO v_retorno
    FROM dicionario
   WHERE tipo = 'status_apontam'
     AND ordem = v_ordem;
  --ALCBO_010324
  IF v_retorno IS NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM apontam_ence ae
    WHERE ae.mes_ano = data_converter('01/' || to_char(p_data_ini, 'MM/YYYY'))
      AND ae.empresa_id = (SELECT ue.empresa_id
                             FROM usuario_empresa ue
                            WHERE ue.usuario_id = p_usuario_id
                              AND ue.flag_padrao = 'S')
      AND flag_encerrado = 'S';
   --
   IF v_qt <> 0
   THEN
    v_retorno := 'ENCE';
   END IF;
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END status_periodo_retornar;
 --
 --
 FUNCTION custo_job_mes_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2000
  -- DESCRICAO: retorna o custo ajustado de um determinado usuario, de acordo com os
  --  apontamentos feitos para um determinado job e num determinado mes. Quando o job_id
  --  nao for informado (nulo ou zero), retorna o custo das demais horas (administrativas,
  --  ferias, etc.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2008  Implementação de outros tipos de apontam (ferias, etc).
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_job_id     IN job.job_id%TYPE,
  p_mes_ano    IN VARCHAR2
 ) RETURN NUMBER AS
 
  v_qt              INTEGER;
  v_retorno         NUMBER;
  v_data_ini        DATE;
  v_data_fim        DATE;
  v_horas_apont_job NUMBER;
  v_horas_apont_mes NUMBER;
  v_apontam_data_id apontam_data.apontam_data_id%TYPE;
  v_custo_hora      apontam_data.custo_hora%TYPE;
  v_qt_horas_padrao NUMBER;
  v_empresa_id      empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  v_qt_horas_padrao := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                       'QT_HORAS_MENSAIS'));
  --
  v_data_ini := to_date('01/' || p_mes_ano, 'DD/MM/YYYY');
  v_data_fim := last_day(v_data_ini);
  --
  -- verifica o ultimo custo_hora apontado no mes
  SELECT MAX(apontam_data_id)
    INTO v_apontam_data_id
    FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND data BETWEEN v_data_ini AND v_data_fim;
  --
  SELECT nvl(MAX(util_pkg.num_decode(custo_hora, g_key_num)), 0)
    INTO v_custo_hora
    FROM apontam_data
   WHERE apontam_data_id = v_apontam_data_id;
  --
  -- verifica o total de horas apontadas no mes
  SELECT nvl(SUM(ah.horas), 0)
    INTO v_horas_apont_mes
    FROM apontam_data ad,
         apontam_hora ah
   WHERE ad.usuario_id = p_usuario_id
     AND ad.data BETWEEN v_data_ini AND v_data_fim
     AND ad.apontam_data_id = ah.apontam_data_id;
  --
  IF nvl(p_job_id, 0) > 0
  THEN
   -- verifica o total de horas apontadas no job
   SELECT nvl(SUM(ah.horas), 0)
     INTO v_horas_apont_job
     FROM apontam_data ad,
          apontam_hora ah
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data BETWEEN v_data_ini AND v_data_fim
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.job_id = p_job_id;
  
  ELSE
   -- verifica o total das demais horas apontadas
   SELECT nvl(SUM(ah.horas), 0)
     INTO v_horas_apont_job
     FROM apontam_data ad,
          apontam_hora ah
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data BETWEEN v_data_ini AND v_data_fim
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.job_id IS NULL;
  
  END IF;
  --
  -- calcula o custo ajustado
  IF v_horas_apont_mes > 0
  THEN
   v_retorno := round(v_custo_hora * v_qt_horas_padrao * v_horas_apont_job / v_horas_apont_mes, 2);
  ELSE
   v_retorno := 0;
  END IF;
  --
  -- encripta para retornar
  v_retorno := util_pkg.num_encode(v_retorno);
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END custo_job_mes_retornar;
 --
 --
 FUNCTION custo_horario_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 12/09/2008
  -- DESCRICAO: retorna o custo horario de um determinado usuario, de acordo com o
  --  o tipo especificado (contabil ou gerencial).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            08/12/2008  Alteracao p/ horas gerenciais abaixo de 160 horas.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            23/04/2019  Retirada de consistencia no calculo gerencial
  -- Ana Luiza         17/09/2024  Adicionado parametro de horas estagiario
  -- Ana Luiza         18/09/2024  Adicionado condicao para calculo gerencial
  ------------------------------------------------------------------------------------------
  p_usuario_id IN usuario.usuario_id%TYPE,
  p_tipo       IN VARCHAR2,
  p_mes_ano    IN VARCHAR2
 ) RETURN NUMBER AS
 
  v_qt                  INTEGER;
  v_retorno             NUMBER;
  v_data_ini            DATE;
  v_data_fim            DATE;
  v_horas_apont_mes     NUMBER;
  v_apontam_data_id     apontam_data.apontam_data_id%TYPE;
  v_custo_hora          apontam_data.custo_hora%TYPE;
  v_qt_horas_padrao     NUMBER;
  v_empresa_id          empresa.empresa_id%TYPE;
  v_qt_horas_estagiario NUMBER;
  v_nivel               salario_cargo.nivel%TYPE;
  v_cargo_id            cargo.cargo_id%TYPE;
  v_salario_cargo_id    salario_cargo.salario_cargo_id%TYPE;
  v_custo_mensal        salario_cargo.custo_mensal%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  v_empresa_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  v_qt_horas_padrao := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                       'QT_HORAS_MENSAIS'));
  --ALCBO_170924
  v_qt_horas_estagiario := numero_converter(empresa_pkg.parametro_retornar(v_empresa_id,
                                                                           'QT_HORAS_MENSAIS_ESTAG'));
  --ALCBO_170924
  v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, SYSDATE, v_empresa_id);
  --
  v_data_ini := to_date('01/' || p_mes_ano, 'DD/MM/YYYY');
  v_data_fim := last_day(v_data_ini);
  --
  -- verifica o ultimo custo_hora apontado no mes
  SELECT MAX(apontam_data_id)
    INTO v_apontam_data_id
    FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND data BETWEEN v_data_ini AND v_data_fim;
  --
  SELECT nvl(MAX(util_pkg.num_decode(custo_hora, g_key_num)), 0)
    INTO v_custo_hora
    FROM apontam_data
   WHERE apontam_data_id = v_apontam_data_id;
  --
  -- verifica o total de horas apontadas no mes
  SELECT nvl(SUM(ah.horas), 0)
    INTO v_horas_apont_mes
    FROM apontam_data ad,
         apontam_hora ah
   WHERE ad.usuario_id = p_usuario_id
     AND ad.data BETWEEN v_data_ini AND v_data_fim
     AND ad.apontam_data_id = ah.apontam_data_id;
  --
  v_retorno := 0;
  --
  -- IF p_tipo = 'GER' AND v_horas_apont_mes >= v_qt_horas_padrao THEN
  IF p_tipo = 'GER'
  THEN
   --ALCBO_180924
   IF v_qt_horas_estagiario > 0 OR v_qt_horas_padrao > 0
   THEN
    --retornar a v_cargo_id
    SELECT cargo_pkg.do_usuario_retornar(p_usuario_id, SYSDATE, NULL)
      INTO v_cargo_id
      FROM dual;
    --retornar a v_salario_cargo_id
    SELECT cargo_pkg.salario_id_atu_retornar(v_cargo_id, v_nivel)
      INTO v_salario_cargo_id
      FROM dual;
    --
    SELECT util_pkg.num_decode(custo_mensal, 'C06C35872C9B409A8AB38C7A7E360F3C')
      INTO v_custo_mensal
      FROM salario_cargo
     WHERE salario_cargo_id = v_salario_cargo_id;
    --
    IF v_nivel = 'E'
    THEN
     v_retorno := round(v_custo_mensal / v_qt_horas_estagiario, 2);
    ELSE
     v_retorno := round(v_custo_mensal / v_qt_horas_padrao, 2);
    END IF;
   
   END IF;
   -- retorna o custo gerencial
   --v_retorno := v_custo_hora; --ALCBO_180924 fim
  ELSE
   -- retorna o custo contabil (p/ tipo = 'CON' ou horas apontadas < 160)
   IF v_horas_apont_mes > 0
   THEN
    --ALCBO_170924
    IF v_qt_horas_estagiario <> 0 AND v_nivel = 'E'
    THEN
     v_retorno := round(v_custo_hora * v_qt_horas_estagiario / v_horas_apont_mes, 2);
    ELSE
     IF v_qt_horas_padrao <> 0
     THEN
      v_retorno := round(v_custo_hora * v_qt_horas_padrao / v_horas_apont_mes, 2);
     END IF;
    END IF;
    --
   END IF;
  END IF;
  --
  -- encripta para retornar
  v_retorno := util_pkg.num_encode(v_retorno);
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 999999;
   RETURN v_retorno;
 END custo_horario_retornar;
 --
 --
 FUNCTION flag_mostrar_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/05/2013
  -- DESCRICAO: retorna o flag_mostrar da tabela hist_ender (mostrar ou ocultar o
  --   apontamento desse objeto no formulario de apontamento semanal).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_usuario_id  IN hist_ender.usuario_id%TYPE,
  p_tipo_objeto IN hist_ender.tipo_objeto%TYPE,
  p_objeto_id   IN hist_ender.objeto_id%TYPE
 ) RETURN VARCHAR2 AS
  v_qt      INTEGER;
  v_retorno VARCHAR2(20);
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(flag_mostrar)
    INTO v_retorno
    FROM hist_ender
   WHERE usuario_id = p_usuario_id
     AND tipo_objeto = p_tipo_objeto
     AND objeto_id = p_objeto_id;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END flag_mostrar_retornar;
 --
--
END; -- APONTAM_PKG

/
