--------------------------------------------------------
--  DDL for Package Body CRONOGRAMA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CRONOGRAMA_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Inclusão de CRONOGRAMA. Copia itens do cronograma anterior, se houver.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/09/2017  Novo atributo duracao_ori.
  -- Silvia            15/03/2018  Novo atributo demanda. Ajuste no incremento da versao
  --                               do item.
  -- Silvia            12/05/2020  Copia dos predecessores do crono anterior.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN cronograma.job_id%TYPE,
  p_cronograma_id     OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_cronograma_id     cronograma.cronograma_id%TYPE;
  v_cronograma_ant_id cronograma.cronograma_id%TYPE;
  v_num_crono         cronograma.numero%TYPE;
  v_num_crono_ant     cronograma.numero%TYPE;
  v_item_crono_id     item_crono.item_crono_id%TYPE;
  v_item_crono1_id    item_crono.item_crono_id%TYPE;
  v_item_crono2_id    item_crono.item_crono_id%TYPE;
  v_num_seq           item_crono.num_seq%TYPE;
  v_ordem             item_crono.ordem%TYPE;
  v_item_crono_pai_id item_crono.item_crono_pai_id%TYPE;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_tipo_job_id       job.tipo_job_id%TYPE;
  v_briefing_id       briefing.briefing_id%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_lbl_job           VARCHAR2(100);
  v_tem_financeiro    VARCHAR2(20);
  --
  CURSOR c_ic IS
   SELECT item_crono_id,
          num_seq,
          nome,
          ordem,
          data_planej_ini,
          data_planej_fim,
          objeto_id,
          item_crono_pai_id,
          cod_objeto,
          flag_obrigatorio,
          tipo_objeto_id,
          sub_tipo_objeto,
          papel_resp_id,
          flag_enviar,
          flag_planejado,
          duracao_ori,
          demanda,
          situacao,
          data_situacao,
          usuario_situacao_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_ant_id
    ORDER BY num_seq;
  --
  CURSOR c_ip IS
   SELECT ic1.item_crono_id,
          ic1.num_seq          AS num_seq1,
          ip.item_crono_pre_id,
          ic2.num_seq          AS num_seq2,
          ip.lag,
          ip.tipo
     FROM item_crono     ic1,
          item_crono_pre ip,
          item_crono     ic2
    WHERE ic1.cronograma_id = v_cronograma_ant_id
      AND ic1.item_crono_id = ip.item_crono_id
      AND ip.item_crono_pre_id = ic2.item_crono_id
    ORDER BY ic1.num_seq;
  --
  CURSOR c_pd IS
   SELECT cod_objeto
     FROM objeto_crono
    WHERE flag_obrigatorio = 'S'
    ORDER BY fase_ordem,
             ordem;
  --
 BEGIN
  v_qt             := 0;
  v_cronograma_id  := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_tem_financeiro := empresa_pkg.parametro_retornar(p_empresa_id, 'FINANCE');
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
  IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', p_job_id, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         tj.tipo_job_id
    INTO v_numero_job,
         v_status_job,
         v_tipo_job_id
    FROM job      jo,
         tipo_job tj
   WHERE jo.job_id = p_job_id
     AND jo.tipo_job_id = tj.tipo_job_id;
  --
  IF p_flag_commit = 'S' AND v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cronograma
   WHERE job_id = p_job_id
     AND status NOT IN ('ARQUI');
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe Cronograma que ainda não foi aprovado.';
   RAISE v_exception;
  END IF;
  --
  v_cronograma_ant_id := ultimo_retornar(p_job_id);
  --
  IF nvl(v_cronograma_ant_id, 0) > 0 THEN
   SELECT MAX(numero)
     INTO v_num_crono_ant
     FROM cronograma
    WHERE cronograma_id = v_cronograma_ant_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(numero), 0) + 1
    INTO v_num_crono
    FROM cronograma
   WHERE job_id = p_job_id;
  --
  SELECT seq_cronograma.nextval
    INTO v_cronograma_id
    FROM dual;
  --
  INSERT INTO cronograma
   (cronograma_id,
    job_id,
    numero,
    status,
    data_status,
    usuario_status_id,
    data_criacao)
  VALUES
   (v_cronograma_id,
    p_job_id,
    v_num_crono,
    'PREP',
    SYSDATE,
    p_usuario_sessao_id,
    SYSDATE);
  --
  IF nvl(v_cronograma_ant_id, 0) > 0 THEN
   -- copia os itens do cronograma anterior
   FOR r_it IN c_ic
   LOOP
    SELECT seq_item_crono.nextval
      INTO v_item_crono_id
      FROM dual;
    --
    INSERT INTO item_crono
     (item_crono_id,
      cronograma_id,
      num_seq,
      nome,
      ordem,
      data_planej_ini,
      data_planej_fim,
      objeto_id,
      cod_objeto,
      flag_obrigatorio,
      tipo_objeto_id,
      sub_tipo_objeto,
      papel_resp_id,
      flag_enviar,
      flag_planejado,
      num_versao,
      duracao_ori,
      demanda,
      situacao,
      data_situacao,
      usuario_situacao_id)
    VALUES
     (v_item_crono_id,
      v_cronograma_id,
      r_it.num_seq,
      r_it.nome,
      r_it.ordem,
      r_it.data_planej_ini,
      r_it.data_planej_fim,
      r_it.objeto_id,
      r_it.cod_objeto,
      r_it.flag_obrigatorio,
      r_it.tipo_objeto_id,
      r_it.sub_tipo_objeto,
      r_it.papel_resp_id,
      r_it.flag_enviar,
      r_it.flag_planejado,
      nvl(v_num_crono_ant, v_num_crono),
      r_it.duracao_ori,
      r_it.demanda,
      r_it.situacao,
      r_it.data_situacao,
      r_it.usuario_situacao_id);
    --
    IF r_it.item_crono_pai_id IS NOT NULL THEN
     SELECT num_seq
       INTO v_num_seq
       FROM item_crono
      WHERE item_crono_id = r_it.item_crono_pai_id;
     --
     SELECT MAX(item_crono_id)
       INTO v_item_crono_pai_id
       FROM item_crono
      WHERE cronograma_id = v_cronograma_id
        AND num_seq = v_num_seq;
     --
     IF v_item_crono_pai_id IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na recuperação do item pai do cronograma (seq: ' || to_char(v_num_seq) || ').';
      RAISE v_exception;
     END IF;
     --
     UPDATE item_crono
        SET item_crono_pai_id = v_item_crono_pai_id
      WHERE item_crono_id = v_item_crono_id;
    
    END IF;
    --
    INSERT INTO item_crono_usu
     (item_crono_id,
      usuario_id,
      horas_diarias,
      horas_totais)
     SELECT v_item_crono_id,
            usuario_id,
            horas_diarias,
            horas_totais
       FROM item_crono_usu
      WHERE item_crono_id = r_it.item_crono_id;
   
   END LOOP;
   --
   FOR r_ip IN c_ip
   LOOP
    SELECT MAX(item_crono_id)
      INTO v_item_crono1_id
      FROM item_crono
     WHERE cronograma_id = v_cronograma_id
       AND num_seq = r_ip.num_seq1;
    --
    IF v_item_crono1_id IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na replicação dos predecessores';
     RAISE v_exception;
    END IF;
    --
    SELECT MAX(item_crono_id)
      INTO v_item_crono2_id
      FROM item_crono
     WHERE cronograma_id = v_cronograma_id
       AND num_seq = r_ip.num_seq2;
    --
    IF v_item_crono2_id IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na replicação dos predecessores';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO item_crono_pre
     (item_crono_id,
      item_crono_pre_id,
      lag,
      tipo)
    VALUES
     (v_item_crono1_id,
      v_item_crono2_id,
      r_ip.lag,
      r_ip.tipo);
   
   END LOOP;
  
  ELSE
   -- carrega apenas os objetos obrigatorios
   FOR r_pd IN c_pd
   LOOP
    IF v_tem_financeiro = 'N' AND r_pd.cod_objeto IN ('CHECKIN_CONC', 'FATUR_CONC') THEN
     -- nao tem modulo financeiro. Pula essas atividades.
     NULL;
    ELSE
     cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          v_cronograma_id,
                                          r_pd.cod_objeto,
                                          'IME',
                                          v_item_crono_id,
                                          p_erro_cod,
                                          p_erro_msg);
    
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               v_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(v_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento da linha do cronograma
  ------------------------------------------------------------
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND cod_objeto = 'CRONOGRAMA';
  --
  IF v_item_crono_id IS NULL THEN
   -- precisa instanciar a atividade de cronograma
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'CRONOGRAMA',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
  
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  UPDATE item_crono
     SET objeto_id = v_cronograma_id
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- tratamento da linha do briefing
  ------------------------------------------------------------
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = p_job_id;
  --
  IF v_briefing_id IS NOT NULL THEN
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND cod_objeto = 'BRIEFING';
   --
   IF v_item_crono_id IS NULL THEN
    -- precisa instanciar a atividade de briefing
    cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_cronograma_id,
                                         'BRIEFING',
                                         'IME',
                                         v_item_crono_id,
                                         p_erro_cod,
                                         p_erro_msg);
   
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   UPDATE item_crono
      SET objeto_id = v_briefing_id
    WHERE item_crono_id = v_item_crono_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cronograma_id,
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
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_cronograma_id := v_cronograma_id;
  p_erro_cod      := '00000';
  p_erro_msg      := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de Cronograma já existe (' || to_char(v_numero_job) || '/' ||
                 to_char(v_num_crono) || '). Tente novamente.';
  
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE adicionar_com_modelo
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 08/01/2016
  -- DESCRICAO: Inclusão de CRONOGRAMA usando modelo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            12/09/2016  Ajuste nas datas de apontamento do job.
  -- Silvia            21/09/2017  Novo atributo duracao_ori.
  -- Silvia            15/03/2018  Novo atributo demanda.
  -- Silvia            15/10/2018  Tratamento de repeticao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN cronograma.job_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_data_base         IN VARCHAR2,
  p_cronograma_id     OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_cronograma_id       cronograma.cronograma_id%TYPE;
  v_num_crono           cronograma.numero%TYPE;
  v_item_crono_id       item_crono.item_crono_id%TYPE;
  v_item_crono_pai_id   item_crono.item_crono_pai_id%TYPE;
  v_data_planej_ini     item_crono.data_planej_ini%TYPE;
  v_data_planej_fim     item_crono.data_planej_fim%TYPE;
  v_item_crono_pre_id   item_crono.item_crono_id%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_data_prev_ini       job.data_prev_ini%TYPE;
  v_data_prev_fim       job.data_prev_fim%TYPE;
  v_data_crono_ini      job.data_apont_ini%TYPE;
  v_data_crono_fim      job.data_apont_fim%TYPE;
  v_data_crono_fim_oper job.data_apont_fim%TYPE;
  v_data_pri_aprov      job.data_pri_aprov%TYPE;
  v_briefing_id         briefing.briefing_id%TYPE;
  v_tipo_data_base      mod_crono.tipo_data_base%TYPE;
  v_data_base           DATE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_tipo_os_id          tipo_os.tipo_os_id%TYPE;
  v_flag_tem_estim      tipo_os.flag_tem_estim%TYPE;
  v_ordem_servico_id    ordem_servico.ordem_servico_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_duracao_tot         NUMBER(10);
  v_flag_periodo_job    tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli  tipo_job.flag_usa_data_cli%TYPE;
  --
  -- itens do modelo
  CURSOR c_mc IS
   SELECT mod_item_crono_id,
          mod_item_crono_pai_id,
          ordem,
          num_seq,
          nome,
          dia_inicio,
          duracao,
          cod_objeto,
          flag_obrigatorio,
          tipo_objeto_id,
          sub_tipo_objeto,
          papel_resp_id,
          flag_enviar,
          demanda,
          frequencia_id,
          repet_a_cada,
          repet_term_tipo,
          repet_term_ocor
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id
    START WITH mod_item_crono_pai_id IS NULL
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id ORDER SIBLINGS BY ordem;
  --
  -- precedessores dos itens do modelo
  CURSOR c_pr IS
   SELECT pr.mod_item_crono_id,
          pr.mod_item_crono_pre_id
     FROM mod_item_crono_pre pr,
          mod_item_crono     md
    WHERE md.mod_crono_id = p_mod_crono_id
      AND md.mod_item_crono_id = pr.mod_item_crono_id;
  --
 BEGIN
  v_qt            := 0;
  v_cronograma_id := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', p_job_id, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.data_prev_ini,
         jo.data_prev_fim,
         ti.flag_usa_per_job,
         ti.flag_usa_data_cli
    INTO v_numero_job,
         v_status_job,
         v_data_prev_ini,
         v_data_prev_fim,
         v_flag_periodo_job,
         v_flag_data_apre_cli
    FROM job      jo,
         tipo_job ti
   WHERE jo.job_id = p_job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cronograma
   WHERE job_id = p_job_id
     AND status NOT IN ('ARQUI');
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existe Cronograma que ainda não foi aprovado.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_mod_crono_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do modelo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_data_base
    INTO v_tipo_data_base
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  IF p_flag_commit = 'S' AND TRIM(p_data_base) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_base) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_base || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_base := data_converter(p_data_base);
  --
  IF v_data_base IS NULL THEN
   -- tenta usar a data definida para o job
   IF v_tipo_data_base = 'INI' THEN
    v_data_base := v_data_prev_ini;
   ELSE
    v_data_base := v_data_prev_fim;
   END IF;
  END IF;
  --
  IF v_data_base IS NULL THEN
   -- usa a data do sistema
   IF v_tipo_data_base = 'INI' THEN
    v_data_base := trunc(SYSDATE);
   ELSE
    -- calcula a data base final, com base na atividade de maior duracao
    SELECT MAX(duracao)
      INTO v_duracao_tot
      FROM mod_item_crono
     WHERE mod_crono_id = p_mod_crono_id;
    --
    v_data_base := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                      trunc(SYSDATE),
                                                      v_duracao_tot - 1,
                                                      'S');
   
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT nvl(MAX(numero), 0) + 1
    INTO v_num_crono
    FROM cronograma
   WHERE job_id = p_job_id;
  --
  SELECT seq_cronograma.nextval
    INTO v_cronograma_id
    FROM dual;
  --
  INSERT INTO cronograma
   (cronograma_id,
    job_id,
    numero,
    status,
    data_status,
    usuario_status_id,
    data_criacao)
  VALUES
   (v_cronograma_id,
    p_job_id,
    v_num_crono,
    'PREP',
    SYSDATE,
    p_usuario_sessao_id,
    SYSDATE);
  --
  ------------------------------------------------------------
  -- carga do modelo
  ------------------------------------------------------------
  FOR r_mc IN c_mc
  LOOP
   v_data_planej_ini := NULL;
   v_data_planej_fim := NULL;
   --
   IF r_mc.dia_inicio IS NOT NULL AND r_mc.duracao IS NOT NULL THEN
    v_data_planej_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_base,
                                                            r_mc.dia_inicio,
                                                            'S');
    v_data_planej_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_planej_ini,
                                                            r_mc.duracao - 1,
                                                            'S');
   
   END IF;
   --
   IF v_data_planej_fim < v_data_planej_ini THEN
    v_data_planej_fim := v_data_planej_ini;
   END IF;
   --
   IF r_mc.mod_item_crono_pai_id IS NULL THEN
    v_item_crono_pai_id := NULL;
   ELSE
    -- precisa localizar o ID do pai que ja foi criado
    SELECT MAX(item_crono_id)
      INTO v_item_crono_pai_id
      FROM item_crono
     WHERE cronograma_id = v_cronograma_id
       AND oper = to_char(r_mc.mod_item_crono_pai_id);
    --
    IF v_item_crono_pai_id IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não achou o pai da atividade (' || r_mc.nome || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   SELECT seq_item_crono.nextval
     INTO v_item_crono_id
     FROM dual;
   --
   INSERT INTO item_crono
    (item_crono_id,
     cronograma_id,
     item_crono_pai_id,
     num_seq,
     ordem,
     nome,
     data_planej_ini,
     data_planej_fim,
     cod_objeto,
     flag_obrigatorio,
     tipo_objeto_id,
     sub_tipo_objeto,
     papel_resp_id,
     flag_enviar,
     oper,
     num_versao,
     flag_planejado,
     duracao_ori,
     demanda,
     frequencia_id,
     repet_a_cada,
     repet_term_tipo,
     repet_term_ocor)
   VALUES
    (v_item_crono_id,
     v_cronograma_id,
     v_item_crono_pai_id,
     r_mc.num_seq,
     r_mc.ordem,
     r_mc.nome,
     v_data_planej_ini,
     v_data_planej_fim,
     r_mc.cod_objeto,
     r_mc.flag_obrigatorio,
     r_mc.tipo_objeto_id,
     r_mc.sub_tipo_objeto,
     r_mc.papel_resp_id,
     r_mc.flag_enviar,
     to_char(r_mc.mod_item_crono_id),
     v_num_crono,
     'S',
     r_mc.duracao,
     r_mc.demanda,
     r_mc.frequencia_id,
     r_mc.repet_a_cada,
     r_mc.repet_term_tipo,
     r_mc.repet_term_ocor);
   --
   IF r_mc.frequencia_id IS NOT NULL THEN
    -- tem repeticao. Copia eventual dia da semana do modelo.
    INSERT INTO item_crono_dia
     (item_crono_id,
      dia_semana_id)
     SELECT v_item_crono_id,
            dia_semana_id
       FROM mod_item_crono_dia
      WHERE mod_item_crono_id = r_mc.mod_item_crono_id;
   
   END IF;
   --
   -- copia eventuais papeis destino
   INSERT INTO item_crono_dest
    (item_crono_id,
     papel_id)
    SELECT v_item_crono_id,
           papel_id
      FROM mod_item_crono_dest
     WHERE mod_item_crono_id = r_mc.mod_item_crono_id;
   --
  /*
                                                                                                                                                 IF r_mc.cod_objeto = 'ORDEM_SERVICO' AND 
                                                                                                                                                    r_mc.tipo_objeto_id IS NOT NULL AND
                                                                                                                                                    r_mc.papel_resp_id IS NOT NULL THEN
                                                                                                                                                    --
                                                                                                                                                    v_tipo_os_id := r_mc.tipo_objeto_id;
                                                                                                                                                    SELECT NVL(MAX(flag_tem_estim),'N')
                                                                                                                                                      INTO v_flag_tem_estim
                                                                                                                                                      FROM tipo_os
                                                                                                                                                     WHERE tipo_os_id = v_tipo_os_id;
                                                                                                                                                    --
                                                                                                                                                    ordem_servico_pkg.adicionar(p_usuario_sessao_id, p_empresa_id, 
                                                                                                                                                                                p_job_id, 0, v_tipo_os_id, r_mc.nome, 
                                                                                                                                                                                data_mostrar(v_data_planej_fim), '17:00',
                                                                                                                                                                                NULL,NULL,NULL,NULL,NULL,
                                                                                                                                                                                v_item_crono_id, v_flag_tem_estim,
                                                                                                                                                                                v_ordem_servico_id, p_erro_cod, p_erro_msg);
                                                                                                                                                    IF p_erro_cod <> '00000' THEN
                                                                                                                                                       RAISE v_exception;
                                                                                                                                                    END IF;
                                                                                                                                                 END IF;*/
  END LOOP;
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               v_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(v_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de predecessor
  ------------------------------------------------------------
  FOR r_pr IN c_pr
  LOOP
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND oper = to_char(r_pr.mod_item_crono_id);
   --
   SELECT MAX(item_crono_id)
     INTO v_item_crono_pre_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND oper = to_char(r_pr.mod_item_crono_pre_id);
   --
   IF v_item_crono_id IS NOT NULL AND v_item_crono_pre_id IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_crono_pre
     WHERE item_crono_id = v_item_crono_id
       AND item_crono_pre_id = v_item_crono_pre_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO item_crono_pre
      (item_crono_id,
       item_crono_pre_id,
       lag,
       tipo)
     VALUES
      (v_item_crono_id,
       v_item_crono_pre_id,
       0,
       0);
    
    END IF;
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais
  ------------------------------------------------------------
  UPDATE item_crono
     SET oper = NULL
   WHERE cronograma_id = v_cronograma_id;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND cod_objeto = 'CRONOGRAMA';
  --
  UPDATE item_crono
     SET objeto_id = v_cronograma_id
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- tratamento da linha do briefing
  ------------------------------------------------------------
  SELECT MAX(briefing_id)
    INTO v_briefing_id
    FROM briefing
   WHERE job_id = p_job_id;
  --
  IF v_briefing_id IS NOT NULL THEN
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND cod_objeto = 'BRIEFING';
   --
   IF v_item_crono_id IS NULL THEN
    -- precisa instanciar a atividade de briefing
    cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_cronograma_id,
                                         'BRIEFING',
                                         'IME',
                                         v_item_crono_id,
                                         p_erro_cod,
                                         p_erro_msg);
   
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   UPDATE item_crono
      SET objeto_id = v_briefing_id
    WHERE item_crono_id = v_item_crono_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- processamento das repeticoes
  ------------------------------------------------------------
  cronograma_pkg.repeticao_processar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     v_cronograma_id,
                                     NULL,
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  -- seleciona menor data do cronograma
  SELECT MIN(data_planej_ini)
    INTO v_data_crono_ini
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id;
  --
  -- seleciona maior data do cronograma
  SELECT MAX(data_planej_fim)
    INTO v_data_crono_fim
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id;
  --
  -- seleciona data de fim do operacional
  SELECT MAX(data_planej_fim)
    INTO v_data_crono_fim_oper
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND cod_objeto = 'JOB_CONC';
  --
  IF v_data_crono_fim_oper IS NULL THEN
   v_data_crono_fim_oper := v_data_crono_fim;
  END IF;
  --
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job. Instancia datas no job.
   -- (se datas do cronograma estiverem nulas, mantem o que estava.
   UPDATE job
      SET data_prev_ini = nvl(v_data_crono_ini, data_prev_ini),
          data_prev_fim = nvl(v_data_crono_fim_oper, data_prev_fim)
    WHERE job_id = p_job_id;
  
  END IF;
  --
  -- atualiza data de inicio do apontamento com a menor das 
  -- datas do cronograma ou do job
  IF v_data_prev_ini < v_data_crono_ini THEN
   v_data_crono_ini := v_data_prev_ini;
  END IF;
  --
  -- atualiza data de termino do apontamento com a maior das 
  -- datas do cronograma ou do job
  IF v_data_prev_fim > v_data_crono_fim THEN
   v_data_crono_fim := v_data_prev_fim;
  END IF;
  --
  UPDATE job
     SET data_apont_ini = nvl(v_data_crono_ini, data_apont_ini),
         data_apont_fim = nvl(v_data_crono_fim, data_apont_fim)
   WHERE job_id = p_job_id;
  --
  IF v_flag_data_apre_cli = 'N' THEN
   -- nao se usa a data de apresentacao cliente da tabela job.
   -- instancia data no job.
   SELECT MIN(data_planej_fim)
     INTO v_data_pri_aprov
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND cod_objeto = 'DATA_APR_CLI';
   --
   UPDATE job
      SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
    WHERE job_id = p_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_cronograma_id,
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
  IF p_flag_commit = 'S' THEN
   COMMIT;
  END IF;
  p_cronograma_id := v_cronograma_id;
  p_erro_cod      := '00000';
  p_erro_msg      := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN dup_val_on_index THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse número de Cronograma já existe (' || to_char(v_numero_job) || '/' ||
                 to_char(v_num_crono) || '). Tente novamente.';
  
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END adicionar_com_modelo;
 --
 --
 PROCEDURE acrescentar_com_modelo
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 08/01/2016
  -- DESCRICAO: Inclusão itens no CRONOGRAMA usando modelo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/09/2017  Novo atributo duracao_ori.
  -- Silvia            15/03/2018  Novo atributo demanda.
  -- Silvia            18/10/2018  Tratamento de repeticao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_data_base         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_num_crono         cronograma.numero%TYPE;
  v_status_crono      cronograma.status%TYPE;
  v_item_crono_id     item_crono.item_crono_id%TYPE;
  v_item_crono_pai_id item_crono.item_crono_pai_id%TYPE;
  v_data_planej_ini   item_crono.data_planej_ini%TYPE;
  v_data_planej_fim   item_crono.data_planej_fim%TYPE;
  v_item_crono_pre_id item_crono.item_crono_id%TYPE;
  v_ordem             item_crono.ordem%TYPE;
  v_job_id            job.job_id%TYPE;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_tipo_data_base    mod_crono.tipo_data_base%TYPE;
  v_flag_unico        objeto_crono.flag_unico%TYPE;
  v_data_base         DATE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_lbl_job           VARCHAR2(100);
  --
  CURSOR c_mc IS
   SELECT mod_item_crono_id,
          mod_item_crono_pai_id,
          ordem,
          num_seq,
          nome,
          dia_inicio,
          duracao,
          cod_objeto,
          flag_obrigatorio,
          tipo_objeto_id,
          sub_tipo_objeto,
          papel_resp_id,
          flag_enviar,
          demanda,
          frequencia_id,
          repet_a_cada,
          repet_term_tipo,
          repet_term_ocor
     FROM mod_item_crono
    WHERE mod_crono_id = p_mod_crono_id
    START WITH mod_item_crono_pai_id IS NULL
   CONNECT BY PRIOR mod_item_crono_id = mod_item_crono_pai_id ORDER SIBLINGS BY ordem;
  --
  -- precedessores dos itens do modelo
  CURSOR c_pr IS
   SELECT pr.mod_item_crono_id,
          pr.mod_item_crono_pre_id
     FROM mod_item_crono_pre pr,
          mod_item_crono     md
    WHERE md.mod_crono_id = p_mod_crono_id
      AND md.mod_item_crono_id = pr.mod_item_crono_id;
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_mod_crono_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do modelo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_data_base
    INTO v_tipo_data_base
    FROM mod_crono
   WHERE mod_crono_id = p_mod_crono_id;
  --
  IF TRIM(p_data_base) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_base) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_base || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_base := data_converter(p_data_base);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_mc IN c_mc
  LOOP
   v_data_planej_ini := NULL;
   v_data_planej_fim := NULL;
   --
   -- verifica se o item aceita repeticao
   SELECT nvl(MAX(flag_unico), 'N')
     INTO v_flag_unico
     FROM objeto_crono
    WHERE cod_objeto = nvl(r_mc.cod_objeto, 'ZZZZZZZZ');
   --
   -- verifica se esse codigo ja existe
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND cod_objeto = nvl(r_mc.cod_objeto, 'ZZZZZZZZ');
   --
   IF v_flag_unico = 'S' AND v_qt > 0 THEN
    -- item unico ja existe. Pula o processamento
    NULL;
   ELSE
    -- item nao eh unico ou nao existe. Pode incluir.
    IF r_mc.dia_inicio IS NOT NULL AND r_mc.duracao IS NOT NULL THEN
     v_data_planej_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                             v_data_base,
                                                             r_mc.dia_inicio,
                                                             'S');
     v_data_planej_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                             v_data_planej_ini,
                                                             r_mc.duracao - 1,
                                                             'S');
    
    END IF;
    --
    IF v_data_planej_fim < v_data_planej_ini THEN
     v_data_planej_fim := v_data_planej_ini;
    END IF;
    --
    IF r_mc.mod_item_crono_pai_id IS NULL THEN
     v_item_crono_pai_id := NULL;
    ELSE
     -- precisa localizar o ID do pai que ja foi criado
     SELECT MAX(item_crono_id)
       INTO v_item_crono_pai_id
       FROM item_crono
      WHERE cronograma_id = p_cronograma_id
        AND oper = to_char(r_mc.mod_item_crono_pai_id);
     --
     IF v_item_crono_pai_id IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Não achou o pai da atividade (' || r_mc.nome || ').';
      RAISE v_exception;
     END IF;
    
    END IF;
    --
    SELECT MAX(ordem)
      INTO v_ordem
      FROM item_crono
     WHERE cronograma_id = p_cronograma_id;
    --
    IF v_ordem IS NULL THEN
     -- primeiro item do cronograma
     v_ordem := 100000;
    ELSE
     v_ordem := v_ordem + 100000;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM item_crono
     WHERE cronograma_id = p_cronograma_id
       AND ordem = v_ordem;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Essa ordem já existe (' || to_char(v_ordem) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT seq_item_crono.nextval
      INTO v_item_crono_id
      FROM dual;
    --
    INSERT INTO item_crono
     (item_crono_id,
      cronograma_id,
      item_crono_pai_id,
      num_seq,
      ordem,
      nome,
      data_planej_ini,
      data_planej_fim,
      cod_objeto,
      flag_obrigatorio,
      tipo_objeto_id,
      sub_tipo_objeto,
      papel_resp_id,
      flag_enviar,
      oper,
      num_versao,
      flag_planejado,
      duracao_ori,
      demanda,
      frequencia_id,
      repet_a_cada,
      repet_term_tipo,
      repet_term_ocor)
    VALUES
     (v_item_crono_id,
      p_cronograma_id,
      v_item_crono_pai_id,
      r_mc.num_seq,
      v_ordem,
      r_mc.nome,
      v_data_planej_ini,
      v_data_planej_fim,
      r_mc.cod_objeto,
      r_mc.flag_obrigatorio,
      r_mc.tipo_objeto_id,
      r_mc.sub_tipo_objeto,
      r_mc.papel_resp_id,
      r_mc.flag_enviar,
      to_char(r_mc.mod_item_crono_id),
      v_num_crono,
      'S',
      r_mc.duracao,
      r_mc.demanda,
      r_mc.frequencia_id,
      r_mc.repet_a_cada,
      r_mc.repet_term_tipo,
      r_mc.repet_term_ocor);
   
   END IF; -- fim do IF v_flag_unico 
   --
   IF r_mc.frequencia_id IS NOT NULL THEN
    -- tem repeticao. Copia eventual dia da semana do modelo.
    INSERT INTO item_crono_dia
     (item_crono_id,
      dia_semana_id)
     SELECT v_item_crono_id,
            dia_semana_id
       FROM mod_item_crono_dia
      WHERE mod_item_crono_id = r_mc.mod_item_crono_id;
   
   END IF;
   --
   -- copia eventuais papeis destino
   INSERT INTO item_crono_dest
    (item_crono_id,
     papel_id)
    SELECT v_item_crono_id,
           papel_id
      FROM mod_item_crono_dest
     WHERE mod_item_crono_id = r_mc.mod_item_crono_id;
  
  END LOOP;
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(p_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de predecessor
  ------------------------------------------------------------
  FOR r_pr IN c_pr
  LOOP
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND oper = to_char(r_pr.mod_item_crono_id);
   --
   SELECT MAX(item_crono_id)
     INTO v_item_crono_pre_id
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND oper = to_char(r_pr.mod_item_crono_pre_id);
   --
   IF v_item_crono_id IS NOT NULL AND v_item_crono_pre_id IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_crono_pre
     WHERE item_crono_id = v_item_crono_id
       AND item_crono_pre_id = v_item_crono_pre_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO item_crono_pre
      (item_crono_id,
       item_crono_pre_id,
       lag,
       tipo)
     VALUES
      (v_item_crono_id,
       v_item_crono_pre_id,
       0,
       0);
    
    END IF;
   
   END IF;
  
  END LOOP;
  --
  UPDATE item_crono
     SET oper = NULL
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- processamento das repeticoes
  ------------------------------------------------------------
  cronograma_pkg.repeticao_processar(p_usuario_sessao_id,
                                     p_empresa_id,
                                     p_cronograma_id,
                                     NULL,
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Inclusão de itens do modelo';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 END acrescentar_com_modelo;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Exclusão de CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_job      job.numero%TYPE;
  v_job_id          job.job_id%TYPE;
  v_status_job      job.status%TYPE;
  v_num_crono       cronograma.numero%TYPE;
  v_status_crono    cronograma.status%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  --
  CURSOR c_us IS
   SELECT iu.usuario_id,
          iu.item_crono_id,
          ic.data_planej_ini,
          ic.data_planej_fim
     FROM item_crono_usu iu,
          item_crono     ic
    WHERE ic.cronograma_id = p_cronograma_id
      AND ic.item_crono_id = iu.item_crono_id
      AND iu.controle = 'DEL';
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- deleta usuarios e processa alocacao                 
  FOR r_us IN c_us
  LOOP
   DELETE FROM item_crono_usu
    WHERE item_crono_id = r_us.item_crono_id
      AND usuario_id = r_us.usuario_id;
   --
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_id,
                                         r_us.data_planej_ini,
                                         r_us.data_planej_fim,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  DELETE FROM item_crono_pre ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic
           WHERE ic.cronograma_id = p_cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
 
  DELETE FROM item_crono_pre ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic
           WHERE ic.cronograma_id = p_cronograma_id
             AND ic.item_crono_id = ip.item_crono_pre_id);
 
  DELETE FROM item_crono_dia ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic
           WHERE ic.cronograma_id = p_cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
 
  DELETE FROM item_crono_dest ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic
           WHERE ic.cronograma_id = p_cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
 
  DELETE FROM item_crono_usu ip
   WHERE EXISTS (SELECT 1
            FROM item_crono ic
           WHERE ic.cronograma_id = p_cronograma_id
             AND ic.item_crono_id = ip.item_crono_id);
 
  DELETE FROM item_crono
   WHERE cronograma_id = p_cronograma_id;
 
  DELETE FROM cronograma
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 END excluir;
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Termino de cronograma (envia para aprovacao ou aprova automaticamente).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_num_crono           cronograma.numero%TYPE;
  v_status_crono        cronograma.status%TYPE;
  v_data_aprov_limite   cronograma.data_aprov_limite%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_job_id              job.job_id%TYPE;
  v_flag_apr_crono_auto tipo_job.flag_apr_crono_auto%TYPE;
  v_lbl_job             VARCHAR2(100);
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status,
         t.flag_apr_crono_auto
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono,
         v_flag_apr_crono_auto
    FROM job        j,
         cronograma c,
         tipo_job   t
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_APROV_CRONO',
                                                             0);
  UPDATE cronograma
     SET status            = 'EMAPRO',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id,
         data_aprov_limite = v_data_aprov_limite
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'TERMINAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
  IF v_flag_apr_crono_auto = 'S' THEN
   -- aprova o cronograma automaticamente
   cronograma_pkg.aprovar(p_usuario_sessao_id,
                          p_empresa_id,
                          'N',
                          p_cronograma_id,
                          p_erro_cod,
                          p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- marca o cronograma como tendo transicao de aprovacao (o padrao na hora de 
   -- criar o cronograma eh nao.
   UPDATE cronograma
      SET flag_com_aprov = 'S'
    WHERE cronograma_id = p_cronograma_id;
  
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
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Retomada de cronograma (volta para preparacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_crono      cronograma.numero%TYPE;
  v_status_crono   cronograma.status%TYPE;
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono <> ('EMAPRO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE cronograma
     SET status            = 'PREP',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'RETOMAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Aprovacao de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_crono      cronograma.numero%TYPE;
  v_status_crono   cronograma.status%TYPE;
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
  IF flag_validar(p_flag_commit) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag commit inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_AP', v_job_id, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_crono <> 'EMAPRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE cronograma
     SET status            = 'APROV',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'APROVAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 END aprovar;
 --
 --
 PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Reprovacao de cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_motivo_reprov     IN VARCHAR2,
  p_compl_reprov      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_num_crono      cronograma.numero%TYPE;
  v_status_crono   cronograma.status%TYPE;
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_AP', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono <> 'EMAPRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_reprov) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo_reprov)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_reprov)) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE cronograma
     SET status            = 'REPROV',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := TRIM(p_compl_reprov);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'REPROVAR',
                   v_identif_objeto,
                   p_cronograma_id,
                   v_compl_histor,
                   TRIM(p_motivo_reprov),
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
 PROCEDURE revisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Revisao de cronograma aprovado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/01/2020  Ao inves de arquivar atual e abrir novo cronograma, 
  --                               volta ao status PREP.
  -- Silvia            03/03/2020  Voltou a arquivar o atual e abrir novo cronograma.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN cronograma.cronograma_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_cronograma_new_id OUT cronograma.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_num_crono         cronograma.numero%TYPE;
  v_status_crono      cronograma.status%TYPE;
  v_cronograma_new_id cronograma.cronograma_id%TYPE;
  v_numero_job        job.numero%TYPE;
  v_status_job        job.status%TYPE;
  v_job_id            job.job_id%TYPE;
  v_lbl_job           VARCHAR2(100);
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_RV', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF v_status_crono <> 'APROV' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do Cronograma não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_motivo_rev) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do motivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_motivo_rev)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O motivo não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_compl_rev)) > 1000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento não pode ter mais que 1000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE cronograma
     SET status            = 'ARQUI',
         data_status       = SYSDATE,
         usuario_status_id = p_usuario_sessao_id
   WHERE cronograma_id = p_cronograma_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := TRIM(p_compl_rev);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'REVISAR',
                   v_identif_objeto,
                   p_cronograma_id,
                   v_compl_histor,
                   TRIM(p_motivo_rev),
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
  ------------------------------------------------------------
  -- criacao da nova versao
  ------------------------------------------------------------
  cronograma_pkg.adicionar(p_usuario_sessao_id,
                           p_empresa_id,
                           'N',
                           v_job_id,
                           v_cronograma_new_id,
                           p_erro_cod,
                           p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  COMMIT;
  p_cronograma_new_id := v_cronograma_new_id;
  p_erro_cod          := '00000';
  p_erro_msg          := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END revisar;
 --
 --
 PROCEDURE item_crono_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Inclusao de item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            18/05/2016  Novos params cod_objeto, tipo_objeto_id, etc
  -- Silvia            19/10/2018  Novos parametros: flag_commit, repeticoes
  -- Silvia            26/10/2018  Papel destino virou vetor.
  -- Silvia            28/02/2020  Novo parametro obs
  -- Silvia            13/04/2020  Retirada do teste de privilegio.
  -- Silvia            
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_cronograma_id       IN item_crono.cronograma_id%TYPE,
  p_item_crono_pai_id   IN item_crono.item_crono_pai_id%TYPE,
  p_nome                IN item_crono.nome%TYPE,
  p_data_planej_ini     IN VARCHAR2,
  p_data_planej_fim     IN VARCHAR2,
  p_cod_objeto          IN objeto_crono.cod_objeto%TYPE,
  p_tipo_objeto_id      IN mod_item_crono.tipo_objeto_id%TYPE,
  p_sub_tipo_objeto     IN mod_item_crono.sub_tipo_objeto%TYPE,
  p_papel_resp_id       IN mod_item_crono.papel_resp_id%TYPE,
  p_vetor_papel_dest_id IN VARCHAR2,
  p_flag_enviar         IN VARCHAR2,
  p_repet_a_cada        IN VARCHAR2,
  p_frequencia_id       IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id IN VARCHAR2,
  p_repet_term_tipo     IN VARCHAR2,
  p_repet_term_ocor     IN VARCHAR2,
  p_obs                 IN VARCHAR2,
  p_item_crono_id       OUT item_crono.item_crono_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_numero_job          job.numero%TYPE;
  v_job_id              job.job_id%TYPE;
  v_status_job          job.status%TYPE;
  v_data_pri_aprov      job.data_pri_aprov%TYPE;
  v_data_prev_ini       job.data_prev_ini%TYPE;
  v_data_prev_fim       job.data_prev_fim%TYPE;
  v_num_crono           cronograma.numero%TYPE;
  v_item_crono_id       item_crono.item_crono_id%TYPE;
  v_item_crono_max_id   item_crono.item_crono_id%TYPE;
  v_data_planej_ini     item_crono.data_planej_ini%TYPE;
  v_data_planej_fim     item_crono.data_planej_fim%TYPE;
  v_ordem               item_crono.ordem%TYPE;
  v_ordem_aux           item_crono.ordem%TYPE;
  v_objeto_id           item_crono.objeto_id%TYPE;
  v_repet_a_cada        item_crono.repet_a_cada%TYPE;
  v_repet_term_ocor     item_crono.repet_term_ocor%TYPE;
  v_dia_semana_id       dia_semana.dia_semana_id%TYPE;
  v_cod_freq            frequencia.codigo%TYPE;
  v_papel_dest_id       papel.papel_id%TYPE;
  v_flag_obrigatorio    objeto_crono.flag_obrigatorio%TYPE;
  v_flag_unico          objeto_crono.flag_unico%TYPE;
  v_nome_objeto         objeto_crono.nome%TYPE;
  v_vetor_dia_semana_id LONG;
  v_vetor_papel_dest_id LONG;
  v_delimitador         CHAR(1);
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_flag_periodo_job    tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli  tipo_job.flag_usa_data_cli%TYPE;
  --
 BEGIN
  v_qt            := 0;
  p_item_crono_id := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         t.flag_usa_per_job,
         t.flag_usa_data_cli
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_flag_periodo_job,
         v_flag_data_apre_cli
    FROM job        j,
         cronograma c,
         tipo_job   t
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  /*
    IF p_flag_commit = 'S' THEN
       -- verifica se o usuario tem privilegio
       IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
          RAISE v_exception;
       END IF;
    END IF;
  */
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
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_planej_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida (' || p_data_planej_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_planej_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_planej_ini := data_converter(p_data_planej_ini);
  v_data_planej_fim := data_converter(p_data_planej_fim);
  --
  IF v_data_planej_ini > v_data_planej_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início não pode ser maior que a data de término.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_obs)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A observação não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos objetos de sistema
  ------------------------------------------------------------
  IF TRIM(p_cod_objeto) IS NOT NULL THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Objeto do Cronograma não existe (' || p_cod_objeto || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          flag_unico,
          flag_obrigatorio
     INTO v_nome_objeto,
          v_flag_unico,
          v_flag_obrigatorio
     FROM objeto_crono
    WHERE cod_objeto = p_cod_objeto;
   --
   IF v_flag_unico = 'S' THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM item_crono
     WHERE cronograma_id = p_cronograma_id
       AND cod_objeto = p_cod_objeto;
    --
    IF v_qt > 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Já existe esse tipo de demanda no Cronograma (' || v_nome_objeto || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   IF p_cod_objeto = 'ORDEM_SERVICO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do tipo de Workflow é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF nvl(p_papel_resp_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do responsável é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = p_papel_resp_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O papel responsável não existe ou não pertence a essa empresa.';
     RAISE v_exception;
    END IF;
    --
    IF flag_validar(p_flag_enviar) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Flag enviar inválido (' || p_flag_enviar || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   IF p_cod_objeto = 'TAREFA' THEN
    IF p_flag_commit = 'S' THEN
     IF nvl(p_papel_resp_id, 0) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento do papel demandante é obrigatório.';
      RAISE v_exception;
     END IF;
     --
     SELECT COUNT(*)
       INTO v_qt
       FROM papel
      WHERE papel_id = p_papel_resp_id
        AND empresa_id = p_empresa_id;
     --
     IF v_qt = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O papel demandante não existe ou não pertence a essa empresa.';
      RAISE v_exception;
     END IF;
     --
     IF TRIM(p_vetor_papel_dest_id) IS NULL THEN
      p_erro_cod := '90000';
      p_erro_msg := 'O preenchimento do papel demandado é obrigatório.';
      RAISE v_exception;
     END IF;
     --
     -- deveria vir apenas um inteiro no vetor
     IF inteiro_validar(p_vetor_papel_dest_id) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Papel demandado inválido (' || p_vetor_papel_dest_id || '|.';
      RAISE v_exception;
     END IF;
    
    END IF;
   END IF;
   --
   IF p_cod_objeto = 'DOCUMENTO' THEN
    IF nvl(p_tipo_objeto_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do tipo de documento é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF TRIM(p_sub_tipo_objeto) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O preenchimento do fluxo é obrigatório.';
     RAISE v_exception;
    END IF;
    --
    IF util_pkg.desc_retornar('tipo_fluxo', p_sub_tipo_objeto) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Fluxo inválido (' || p_sub_tipo_objeto || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia de repeticoes
  ------------------------------------------------------------
  v_repet_a_cada    := NULL;
  v_repet_term_ocor := NULL;
  --
  IF nvl(p_frequencia_id, 0) > 0 THEN
   IF v_data_planej_ini IS NULL OR v_data_planej_fim IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para demandas com repetição, o preenchimento do período é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo)
     INTO v_cod_freq
     FROM frequencia
    WHERE frequencia_id = p_frequencia_id;
   --
   IF TRIM(p_repet_a_cada) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência da repetição é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(p_repet_a_cada) = 0 OR to_number(p_repet_a_cada) > 99999 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   v_repet_a_cada := nvl(to_number(p_repet_a_cada), 0);
   --
   IF v_repet_a_cada <= 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq = 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, um ou mais dias da semana ' ||
                  'devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq <> 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, os dias da semana ' || 'não devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_repet_term_tipo) IS NULL OR p_repet_term_tipo NOT IN ('FIMJOB', 'QTOCOR') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de término da repetição inválido (' || p_repet_term_tipo || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_repet_term_tipo = 'QTOCOR' THEN
    IF TRIM(p_repet_term_ocor) IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                   'de ocorrências deve ser informada.';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(p_repet_term_ocor) = 0 OR to_number(p_repet_term_ocor) > 99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
    --
    v_repet_term_ocor := nvl(to_number(p_repet_term_ocor), 0);
    --
    IF v_repet_term_ocor <= 1 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   IF p_repet_term_tipo <> 'QTOCOR' AND TRIM(p_repet_term_ocor) IS NOT NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                  'de ocorrências não deve ser informada.';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento da ordem
  ------------------------------------------------------------
  IF nvl(p_item_crono_pai_id, 0) > 0 THEN
   SELECT objeto_id
     INTO v_objeto_id
     FROM item_crono
    WHERE item_crono_id = p_item_crono_pai_id;
   --
   -- descobre o ultimo item do mesmo nivel 
   SELECT MAX(ordem)
     INTO v_ordem
     FROM item_crono
    WHERE item_crono_pai_id = p_item_crono_pai_id;
   --
   IF v_ordem IS NULL THEN
    -- nenhum item filho encontrado. Esse vai ser o primeiro.
    -- pega a ordem do pai
    SELECT ordem
      INTO v_ordem
      FROM item_crono
     WHERE item_crono_id = p_item_crono_pai_id;
   
   END IF;
   --
   -- descobre a proxima ordem
   SELECT MIN(ordem)
     INTO v_ordem_aux
     FROM item_crono
    WHERE ordem > v_ordem
      AND cronograma_id = p_cronograma_id;
   --
   IF v_ordem_aux IS NULL THEN
    -- proximo item nao encontrado. O novo item vai 
    -- ser inserido no final.
    v_ordem := v_ordem + 100000;
   ELSE
    -- proximo item encontrado. O novo item vai ser 
    -- inserido no meio.
    v_ordem := round((v_ordem + v_ordem_aux) / 2, 0);
   END IF;
  
  ELSE
   -- inclusao no nivel 1. Descobre a maior ordem (o item vai entrar no fim)
   SELECT MAX(ordem)
     INTO v_ordem
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id;
   --
   IF v_ordem IS NULL THEN
    -- primeiro item do cronograma
    v_ordem := 100000;
   ELSE
    v_ordem := v_ordem + 100000;
   END IF;
  
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE cronograma_id = p_cronograma_id
     AND ordem = v_ordem;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ordem já existe (' || to_char(v_ordem) || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_item_crono.nextval
    INTO v_item_crono_id
    FROM dual;
  --
  INSERT INTO item_crono
   (item_crono_id,
    cronograma_id,
    item_crono_pai_id,
    nome,
    data_planej_ini,
    data_planej_fim,
    ordem,
    num_seq,
    num_versao,
    cod_objeto,
    flag_obrigatorio,
    tipo_objeto_id,
    sub_tipo_objeto,
    papel_resp_id,
    flag_enviar,
    flag_planejado,
    demanda,
    frequencia_id,
    repet_a_cada,
    repet_term_tipo,
    repet_term_ocor,
    obs)
  VALUES
   (v_item_crono_id,
    p_cronograma_id,
    zvl(p_item_crono_pai_id, NULL),
    TRIM(p_nome),
    v_data_planej_ini,
    v_data_planej_fim,
    v_ordem,
    0,
    v_num_crono,
    TRIM(p_cod_objeto),
    nvl(v_flag_obrigatorio, 'N'),
    zvl(p_tipo_objeto_id, NULL),
    TRIM(p_sub_tipo_objeto),
    zvl(p_papel_resp_id, NULL),
    nvl(TRIM(p_flag_enviar), 'N'),
    'S',
    'IME',
    zvl(p_frequencia_id, NULL),
    v_repet_a_cada,
    p_repet_term_tipo,
    v_repet_term_ocor,
    TRIM(p_obs));
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(p_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de papel demandado (destino)
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_papel_dest_id := p_vetor_papel_dest_id;
  --
  WHILE nvl(length(rtrim(v_vetor_papel_dest_id)), 0) > 0
  LOOP
   v_papel_dest_id := nvl(to_number(prox_valor_retornar(v_vetor_papel_dest_id, v_delimitador)), 0);
   --
   IF v_papel_dest_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_dest_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O papel demandado não existe ou não pertence a essa empresa (' ||
                   to_char(v_papel_dest_id) || ').';
     RAISE v_exception;
    END IF;
    --
    INSERT INTO item_crono_dest
     (item_crono_id,
      papel_id)
    VALUES
     (v_item_crono_id,
      v_papel_dest_id);
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de dia da semana (repeticoes)
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_dia_semana_id := p_vetor_dia_semana_id;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana_id)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana_id, v_delimitador)), 0);
   --
   IF v_dia_semana_id > 0 THEN
    INSERT INTO item_crono_dia
     (item_crono_id,
      dia_semana_id)
    VALUES
     (v_item_crono_id,
      v_dia_semana_id);
   
   END IF;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- processamento das repeticoes (apenas chamadas via interface)
  ------------------------------------------------------------
  IF p_flag_commit = 'S' THEN
   cronograma_pkg.repeticao_processar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_cronograma_id,
                                      NULL,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job.
   -- instancia datas no job.
   SELECT MIN(data_planej_ini)
     INTO v_data_prev_ini
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id;
   --
   UPDATE job
      SET data_prev_ini = nvl(v_data_prev_ini, data_prev_ini)
    WHERE job_id = v_job_id;
   --
   IF p_cod_objeto = 'JOB_CONC' THEN
    v_data_prev_fim := v_data_planej_fim;
    --
    UPDATE job
       SET data_prev_fim = nvl(v_data_prev_fim, data_prev_fim)
     WHERE job_id = v_job_id;
   
   END IF;
  
  END IF;
  --
  IF v_flag_data_apre_cli = 'N' AND p_cod_objeto = 'DATA_APR_CLI' THEN
   -- nao se usa a data de apresentacao cliente da tabela job.
   -- instancia data no job.
   SELECT MIN(data_planej_fim)
     INTO v_data_pri_aprov
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND cod_objeto = 'DATA_APR_CLI';
   --
   UPDATE job
      SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Inclusão de item: ' || TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
  p_item_crono_id := v_item_crono_id;
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
 END item_crono_adicionar;
 --
 --
 PROCEDURE item_objeto_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 12/01/2016
  -- DESCRICAO: Inclusao de item do CRONOGRAMA que corresponde a um objeto.
  --            Subrotina que NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/09/2016  Novo atributo flag_planejado
  -- Silvia            15/03/2018  Novo atributo demanda.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_cod_objeto        IN objeto_crono.cod_objeto%TYPE,
  p_demanda           IN VARCHAR2,
  p_item_crono_id     OUT item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_saida              EXCEPTION;
  v_numero_job         job.numero%TYPE;
  v_job_id             job.job_id%TYPE;
  v_status_job         job.status%TYPE;
  v_obj_nome           objeto_crono.nome%TYPE;
  v_obj_ordem          objeto_crono.ordem%TYPE;
  v_flag_unico         objeto_crono.flag_unico%TYPE;
  v_flag_obrigatorio   objeto_crono.flag_obrigatorio%TYPE;
  v_fase_nome          objeto_crono.fase_nome%TYPE;
  v_fase_ordem         objeto_crono.fase_ordem%TYPE;
  v_num_crono          cronograma.numero%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
  v_item_crono_fase_id item_crono.item_crono_id%TYPE;
  v_ordem              item_crono.ordem%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  --
 BEGIN
  v_qt            := 0;
  v_lbl_job       := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  p_item_crono_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono
    FROM job        j,
         cronograma c
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_cod_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código do objeto do Cronograma é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM objeto_crono
   WHERE cod_objeto = p_cod_objeto;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Objeto do Cronograma não existe (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('demanda', p_demanda) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Demanda inválida (' || p_demanda || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT nome,
         ordem,
         flag_unico,
         flag_obrigatorio,
         fase_nome,
         fase_ordem
    INTO v_obj_nome,
         v_obj_ordem,
         v_flag_unico,
         v_flag_obrigatorio,
         v_fase_nome,
         v_fase_ordem
    FROM objeto_crono
   WHERE cod_objeto = p_cod_objeto;
  --
  IF v_fase_nome IS NULL OR v_obj_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Objeto do Cronograma não configurado (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_unico = 'S' THEN
   -- verifica se esse objeto ja existe no cronograma
   SELECT MAX(item_crono_id)
     INTO v_item_crono_id
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND cod_objeto = p_cod_objeto;
   --
   IF nvl(v_item_crono_id, 0) > 0 THEN
    -- pula o processamento, retornando o ID existente
    p_item_crono_id := v_item_crono_id;
    RAISE v_saida;
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - tratamento da fase
  ------------------------------------------------------------
  -- verifica se o nome da fase ja existe no nivel 1
  -- como nao planejada
  SELECT MAX(item_crono_id)
    INTO v_item_crono_fase_id
    FROM item_crono
   WHERE cronograma_id = p_cronograma_id
     AND item_crono_pai_id IS NULL
     AND flag_planejado = 'N'
     AND nome = v_fase_nome;
  --
  -- a fase e o item a serem adicionados vao entrar como 
  -- nao planejado.
  IF v_item_crono_fase_id IS NULL THEN
   -- Precisa criar a fase.
   -- Descobre a maior ordem (vai entrar no fim)
   SELECT MAX(ordem)
     INTO v_ordem
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id;
   --
   IF v_ordem IS NULL THEN
    -- primeiro item do cronograma
    v_ordem := 100000;
   ELSE
    v_ordem := v_ordem + 100000;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND ordem = v_ordem;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa ordem já existe (' || to_char(v_ordem) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT seq_item_crono.nextval
     INTO v_item_crono_fase_id
     FROM dual;
   --
   INSERT INTO item_crono
    (item_crono_id,
     cronograma_id,
     item_crono_pai_id,
     nome,
     data_planej_ini,
     data_planej_fim,
     ordem,
     num_seq,
     flag_obrigatorio,
     cod_objeto,
     num_versao,
     flag_planejado,
     demanda)
   VALUES
    (v_item_crono_fase_id,
     p_cronograma_id,
     NULL,
     v_fase_nome,
     NULL,
     NULL,
     v_ordem,
     0,
     'N',
     NULL,
     v_num_crono,
     'N',
     p_demanda);
   --
   cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                                p_empresa_id,
                                p_cronograma_id,
                                p_erro_cod,
                                p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                  p_empresa_id,
                                  p_cronograma_id,
                                  p_erro_cod,
                                  p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
   --
   cronograma_pkg.num_gantt_processar(p_cronograma_id, p_erro_cod, p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco - tratamento do objeto
  ------------------------------------------------------------
  -- inclusao debaixo da fase. Descobre a maior ordem (o item vai entrar no fim)
  SELECT MAX(ordem)
    INTO v_ordem
    FROM item_crono
   WHERE cronograma_id = p_cronograma_id;
  --
  IF v_ordem IS NULL THEN
   -- primeiro item do cronograma
   v_ordem := 100000;
  ELSE
   v_ordem := v_ordem + 100000;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE cronograma_id = p_cronograma_id
     AND ordem = v_ordem;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa ordem já existe (' || to_char(v_ordem) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT seq_item_crono.nextval
    INTO v_item_crono_id
    FROM dual;
  --
  INSERT INTO item_crono
   (item_crono_id,
    cronograma_id,
    item_crono_pai_id,
    nome,
    data_planej_ini,
    data_planej_fim,
    ordem,
    num_seq,
    flag_obrigatorio,
    cod_objeto,
    num_versao,
    flag_planejado,
    demanda)
  VALUES
   (v_item_crono_id,
    p_cronograma_id,
    v_item_crono_fase_id,
    v_obj_nome,
    NULL,
    NULL,
    v_ordem,
    0,
    v_flag_obrigatorio,
    p_cod_objeto,
    v_num_crono,
    'N',
    p_demanda);
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               p_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 p_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(p_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Inclusão de item: ' || v_obj_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
  p_item_crono_id := v_item_crono_id;
  p_erro_cod      := '00000';
  p_erro_msg      := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END item_objeto_adicionar;
 --
 --
 PROCEDURE item_crono_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Atualizacao de item do CRONOGRAMA
  --  *** A CHAMADA WEB NAO ESTA MAIS FAZENDO USO DOS FLAGS ALTERA DEPEND/FILHOS ***
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/10/2018  Tratamento de predecessor
  -- Silvia            30/10/2018  Novos parametros (flags p/ alterar datas)
  -- Silvia            10/01/2020  Chamada da alocacao_usu_processar.
  -- Silvia            28/02/2020  Novo parametro obs
  -- Silvia            16/06/2020  Retirada do teste de privilegio.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_item_crono_id      IN item_crono.item_crono_id%TYPE,
  p_nome               IN item_crono.nome%TYPE,
  p_data_planej_ini    IN VARCHAR2,
  p_data_planej_fim    IN VARCHAR2,
  p_flag_altera_depend IN VARCHAR2,
  p_flag_altera_filhos IN VARCHAR2,
  p_obs                IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
 
  v_qt                       INTEGER;
  v_exception                EXCEPTION;
  v_numero_job               job.numero%TYPE;
  v_job_id                   job.job_id%TYPE;
  v_status_job               job.status%TYPE;
  v_data_pri_aprov           job.data_pri_aprov%TYPE;
  v_data_prev_ini            job.data_prev_ini%TYPE;
  v_data_prev_fim            job.data_prev_fim%TYPE;
  v_flag_restringe_alt_crono job.flag_restringe_alt_crono%TYPE;
  v_num_crono                cronograma.numero%TYPE;
  v_cronograma_id            cronograma.cronograma_id%TYPE;
  v_data_planej_ini          item_crono.data_planej_ini%TYPE;
  v_data_planej_fim          item_crono.data_planej_fim%TYPE;
  v_data_planej_ini_old      item_crono.data_planej_ini%TYPE;
  v_data_planej_fim_old      item_crono.data_planej_fim%TYPE;
  v_nome_old                 item_crono.nome%TYPE;
  v_cod_objeto               item_crono.cod_objeto%TYPE;
  v_objeto_id                item_crono.objeto_id%TYPE;
  v_flag_planejado           item_crono.flag_planejado%TYPE;
  v_identif_objeto           historico.identif_objeto%TYPE;
  v_compl_histor             historico.complemento%TYPE;
  v_historico_id             historico.historico_id%TYPE;
  v_lbl_job                  VARCHAR2(100);
  v_flag_periodo_job         tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli       tipo_job.flag_usa_data_cli%TYPE;
  v_num_dias_uteis           NUMBER(20);
  v_horas_totais             item_crono_usu.horas_totais%TYPE;
  v_duracao                  NUMBER(20);
  v_hora_fim                 VARCHAR2(10);
  v_data_solicitada          ordem_servico.data_solicitada%TYPE;
  v_data_interna             ordem_servico.data_interna%TYPE;
  v_data_inicio              ordem_servico.data_inicio%TYPE;
  v_data_termino             ordem_servico.data_termino%TYPE;
  --
  CURSOR c_ic IS
   SELECT usuario_id,
          horas_diarias
     FROM item_crono_usu
    WHERE item_crono_id = p_item_crono_id;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_job  := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_hora_fim := empresa_pkg.parametro_retornar(p_empresa_id, 'HORA_PADRAO_NOVA_OS');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF flag_validar(p_flag_altera_depend) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera dependentes inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_altera_filhos) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera filhos inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.cod_objeto,
         ic.objeto_id,
         ti.flag_usa_per_job,
         ti.flag_usa_data_cli,
         ic.data_planej_ini,
         ic.data_planej_fim,
         ic.nome,
         jo.flag_restringe_alt_crono,
         ic.flag_planejado
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_cod_objeto,
         v_objeto_id,
         v_flag_periodo_job,
         v_flag_data_apre_cli,
         v_data_planej_ini_old,
         v_data_planej_fim_old,
         v_nome_old,
         v_flag_restringe_alt_crono,
         v_flag_planejado
    FROM job        jo,
         tipo_job   ti,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  /*
    -- verifica se o usuario tem privilegio
    IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
       RAISE v_exception;
    END IF;
  */
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
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_nome)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_planej_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de início inválida.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_planej_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data de término inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_planej_ini := data_converter(p_data_planej_ini);
  v_data_planej_fim := data_converter(p_data_planej_fim);
  --
  IF v_data_planej_ini > v_data_planej_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início não pode ser maior que a data de término.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_obs)) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A observação não pode ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item_crono
     SET nome            = TRIM(p_nome),
         data_planej_ini = v_data_planej_ini,
         data_planej_fim = v_data_planej_fim,
         obs             = TRIM(p_obs)
   WHERE item_crono_id = p_item_crono_id;
  --
  -- verifica se alguma informacao foi alterada nessa versao
  IF TRIM(v_nome_old) <> TRIM(p_nome) OR
     nvl(v_data_planej_ini_old, to_date('01/01/1900', 'DD/MM/YYYY')) <>
     nvl(v_data_planej_ini, to_date('01/01/1900', 'DD/MM/YYYY')) OR
     nvl(v_data_planej_fim_old, to_date('01/01/1900', 'DD/MM/YYYY')) <>
     nvl(v_data_planej_fim, to_date('01/01/1900', 'DD/MM/YYYY')) THEN
   --
   UPDATE item_crono
      SET num_versao = v_num_crono
    WHERE item_crono_id = p_item_crono_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de predecessor
  ------------------------------------------------------------
  -- verifica se esse item eh predecessor de algum item
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_pre
   WHERE item_crono_pre_id = p_item_crono_id;
  --
  IF v_qt > 0 AND v_data_planej_fim <> v_data_planej_fim_old AND p_flag_altera_depend = 'S' THEN
   -- eh predecessor, mudou a data FINAL e usuario escolheu mudar os dependentes
   -- calcula o deslocamento em dias uteis
   IF v_data_planej_fim > v_data_planej_fim_old THEN
    v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                            v_data_planej_fim_old,
                                                            v_data_planej_fim);
   ELSE
    v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                            v_data_planej_fim,
                                                            v_data_planej_fim_old);
    v_num_dias_uteis := v_num_dias_uteis * -1;
   END IF;
   --
   cronograma_pkg.datas_depend_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         p_item_crono_id,
                                         v_num_dias_uteis,
                                         p_erro_cod,
                                         p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de filhos
  ------------------------------------------------------------
  -- verifica se esse item eh pai de algum item
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE item_crono_pai_id = p_item_crono_id;
  --
  IF v_qt > 0 AND v_data_planej_ini <> v_data_planej_ini_old AND p_flag_altera_filhos = 'S' THEN
   -- tem filhos, mudou a data de INICIO e usuario escolheu mudar os filhos
   -- calcula o deslocamento em dias uteis
   IF v_data_planej_ini > v_data_planej_ini_old THEN
    v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                            v_data_planej_ini_old,
                                                            v_data_planej_ini);
   ELSE
    v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                            v_data_planej_ini,
                                                            v_data_planej_ini_old);
    v_num_dias_uteis := v_num_dias_uteis * -1;
   END IF;
   --
   cronograma_pkg.datas_hierarq_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          p_item_crono_id,
                                          v_num_dias_uteis,
                                          p_erro_cod,
                                          p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job.
   -- instancia datas no job.
   SELECT MIN(data_planej_ini)
     INTO v_data_prev_ini
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id;
   --
   UPDATE job
      SET data_prev_ini = nvl(v_data_prev_ini, data_prev_ini)
    WHERE job_id = v_job_id;
   --
   IF v_cod_objeto = 'JOB_CONC' THEN
    v_data_prev_fim := v_data_planej_fim;
    --
    UPDATE job
       SET data_prev_fim = nvl(v_data_prev_fim, data_prev_fim)
     WHERE job_id = v_job_id;
   
   END IF;
  
  END IF;
  --
  IF v_flag_data_apre_cli = 'N' AND v_cod_objeto = 'DATA_APR_CLI' THEN
   -- nao se usa a data de apresentacao cliente da tabela job.
   -- instancia data no job.
   SELECT MIN(data_planej_fim)
     INTO v_data_pri_aprov
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND cod_objeto = 'DATA_APR_CLI';
   --
   UPDATE job
      SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento para OS/TAREFA (atualiza datas)
  ------------------------------------------------------------ 
  IF v_flag_restringe_alt_crono = 'S' AND v_flag_planejado = 'S' AND
     v_cod_objeto IN ('ORDEM_SERVICO', 'TAREFA') AND v_objeto_id IS NOT NULL THEN
   --
   IF v_cod_objeto = 'ORDEM_SERVICO' THEN
    v_data_solicitada := data_hora_converter(data_mostrar(v_data_planej_fim) || ' ' || v_hora_fim);
    v_data_interna    := v_data_solicitada;
    --
    v_data_inicio  := v_data_planej_ini;
    v_data_termino := v_data_solicitada;
    --
    UPDATE ordem_servico
       SET data_solicitada = v_data_solicitada,
           data_interna    = v_data_interna,
           data_inicio     = v_data_inicio,
           data_termino    = v_data_termino
     WHERE ordem_servico_id = v_objeto_id;
   
   END IF;
   --
   IF v_cod_objeto = 'TAREFA' THEN
    v_data_inicio  := v_data_planej_ini;
    v_data_termino := v_data_planej_fim;
    --
    UPDATE tarefa
       SET data_inicio  = v_data_inicio,
           data_termino = v_data_termino
     WHERE tarefa_id = v_objeto_id;
   
   END IF;
   --
   cronograma_pkg.executores_replicar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_item_crono_id,
                                      'ALT_EXEC_CRONO',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- processamento das alocacoes
  ------------------------------------------------------------ 
  v_data_inicio := v_data_planej_ini;
  IF v_data_planej_ini_old < v_data_planej_ini THEN
   v_data_inicio := v_data_planej_ini_old;
  END IF;
  --
  v_data_termino := v_data_planej_fim;
  IF v_data_planej_fim_old > v_data_planej_fim THEN
   v_data_termino := v_data_planej_fim_old;
  END IF;
  --
  FOR r_ic IN c_ic
  LOOP
   -- recalcula horas totais para o novo periodo
   v_duracao      := nvl(cronograma_pkg.item_duracao_retornar(p_usuario_sessao_id, p_item_crono_id),
                         0);
   v_horas_totais := r_ic.horas_diarias * v_duracao;
   --
   UPDATE item_crono_usu
      SET horas_totais = v_horas_totais
    WHERE item_crono_id = p_item_crono_id
      AND usuario_id = r_ic.usuario_id;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_ic.usuario_id,
                                         v_data_inicio,
                                         v_data_termino,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Alteração de item: ' || TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_atualizar;
 --
 --
 PROCEDURE item_crono_situacao_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/08/2020
  -- DESCRICAO: Atualizacao da situacao do item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_situacao          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_num_crono      cronograma.numero%TYPE;
  v_cronograma_id  cronograma.cronograma_id%TYPE;
  v_nome           item_crono.nome%TYPE;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  /*
    -- verifica se o usuario tem privilegio
    IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
       RAISE v_exception;
    END IF;
  */
  --
  /*
    IF v_status_job NOT IN ('ANDA','PREP') THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF length(TRIM(p_situacao)) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário da situação não pode ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item_crono
     SET situacao            = TRIM(p_situacao),
         data_situacao       = SYSDATE,
         usuario_situacao_id = p_usuario_sessao_id
   WHERE item_crono_id = p_item_crono_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Alteração da situação do item: ' || TRIM(v_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_situacao_atualizar;
 --
 --
 PROCEDURE item_crono_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Exclusao de item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            11/12/2019  Exclusao automatica de item_crono_usu
  -- Silvia            10/01/2020  Chamada da alocacao_usu_processar.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_numero_job         job.numero%TYPE;
  v_job_id             job.job_id%TYPE;
  v_status_job         job.status%TYPE;
  v_data_pri_aprov     job.data_pri_aprov%TYPE;
  v_data_prev_ini      job.data_prev_ini%TYPE;
  v_num_crono          cronograma.numero%TYPE;
  v_cronograma_id      cronograma.cronograma_id%TYPE;
  v_nome_item          item_crono.nome%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
  v_data_planej_ini    item_crono.data_planej_ini%TYPE;
  v_data_planej_fim    item_crono.data_planej_fim%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_flag_periodo_job   tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli tipo_job.flag_usa_data_cli%TYPE;
  v_usuario_id         usuario.usuario_id%TYPE;
  --
  CURSOR c_ic IS
   SELECT item_crono_id,
          nome,
          num_seq,
          objeto_id,
          flag_obrigatorio,
          cod_objeto
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
    START WITH item_crono_id = p_item_crono_id
   CONNECT BY PRIOR item_crono_id = item_crono_pai_id ORDER SIBLINGS BY num_seq;
  --
  CURSOR c_us IS
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item/atividade não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ti.flag_usa_per_job,
         ti.flag_usa_data_cli
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_flag_periodo_job,
         v_flag_data_apre_cli
    FROM job        jo,
         tipo_job   ti,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item_crono
     SET oper = NULL
   WHERE cronograma_id = v_cronograma_id;
  --
  FOR r_ic IN c_ic
  LOOP
   v_item_crono_id := r_ic.item_crono_id;
   --
   SELECT data_planej_ini,
          data_planej_fim
     INTO v_data_planej_ini,
          v_data_planej_fim
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   IF r_ic.flag_obrigatorio = 'S' AND r_ic.cod_objeto <> 'DATA_APR_CLI' THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A atividade "' || r_ic.nome || '" é obrigatória e não pode ser excluída.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(r_ic.objeto_id, 0) > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A atividade "' || r_ic.nome ||
                  '" refere-se a uma demanda e não pode ser excluída.';
    RAISE v_exception;
   END IF;
   --
   IF r_ic.cod_objeto = 'DATA_APR_CLI' THEN
    -- verifica se vai sobrar outra data de apresentacao
    SELECT COUNT(*)
      INTO v_qt
      FROM item_crono
     WHERE cronograma_id = v_cronograma_id
       AND cod_objeto = 'DATA_APR_CLI'
       AND item_crono_id <> v_item_crono_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Pelo menos uma atividade "' || r_ic.nome || '" deve existir no Cronograma.';
     RAISE v_exception;
    END IF;
   
   END IF;
   --
   UPDATE item_crono
      SET oper              = 'DEL',
          item_crono_pai_id = NULL
    WHERE item_crono_id = v_item_crono_id;
   --
   DELETE FROM item_crono_pre
    WHERE item_crono_id = v_item_crono_id;
   --
   DELETE FROM item_crono_pre
    WHERE item_crono_pre_id = v_item_crono_id;
   --
   DELETE FROM item_crono_dia
    WHERE item_crono_id = v_item_crono_id;
   --
   DELETE FROM item_crono_dest
    WHERE item_crono_id = v_item_crono_id;
   --
   --loop por usuario alocado na atividade
   FOR r_us IN c_us
   LOOP
    v_usuario_id := r_us.usuario_id;
    --
    DELETE FROM item_crono_usu
     WHERE item_crono_id = v_item_crono_id
       AND usuario_id = v_usuario_id;
    --
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          v_usuario_id,
                                          v_data_planej_ini,
                                          v_data_planej_fim,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  
  END LOOP;
  --
  DELETE FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND oper = 'DEL';
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               v_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(v_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job.
   -- instancia datas no job.
   SELECT MIN(data_planej_ini)
     INTO v_data_prev_ini
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id;
   --
   UPDATE job
      SET data_prev_ini = nvl(v_data_prev_ini, data_prev_ini)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  IF v_flag_data_apre_cli = 'N' THEN
   -- nao se usa a data de apresentacao cliente da tabela job.
   -- instancia data no job.
   SELECT MIN(data_planej_fim)
     INTO v_data_pri_aprov
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND cod_objeto = 'DATA_APR_CLI';
   --
   UPDATE job
      SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Exclusão de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_excluir;
 --
 --
 PROCEDURE item_crono_mover
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Move o item de CRONOGRAMA origem para baixo do item destino.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/09/2016  Nao deixa mover do bloco planejado p/ o nao planejado.
  -- Silvia            07/02/2020  Deixa mover planejado/nao planejado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_ori_id IN item_crono.item_crono_id%TYPE,
  p_item_crono_des_id IN item_crono.item_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_numero_job             job.numero%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_num_crono              cronograma.numero%TYPE;
  v_cronograma_id          cronograma.cronograma_id%TYPE;
  v_ordem                  item_crono.ordem%TYPE;
  v_nome_item              item_crono.nome%TYPE;
  v_item_crono_pai_prox_id item_crono.item_crono_pai_id%TYPE;
  v_ordem_prox             item_crono.ordem%TYPE;
  v_nivel_prox             item_crono.nivel%TYPE;
  v_nivel_ori              item_crono.nivel%TYPE;
  v_nivel_des              item_crono.nivel%TYPE;
  v_ordem_des              item_crono.ordem%TYPE;
  v_num_seq_des            item_crono.num_seq%TYPE;
  v_item_crono_pai_des_id  item_crono.item_crono_pai_id%TYPE;
  v_objeto_des_id          item_crono.objeto_id%TYPE;
  v_flag_planej_ori        item_crono.flag_planejado%TYPE;
  v_flag_planej_des        item_crono.flag_planejado%TYPE;
  v_tem_filho_des          NUMBER(5);
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  --
  CURSOR c_ic IS
   SELECT item_crono_id
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
    START WITH item_crono_id = p_item_crono_ori_id
   CONNECT BY PRIOR item_crono_id = item_crono_pai_id ORDER SIBLINGS BY num_seq;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_ori_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item origem não existe (' || to_char(p_item_crono_ori_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_item_crono_des_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM cronograma cr,
          job        jo,
          item_crono ic
    WHERE ic.item_crono_id = p_item_crono_des_id
      AND ic.cronograma_id = cr.cronograma_id
      AND cr.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item destino não existe (' || to_char(p_item_crono_des_id) || ').';
    RAISE v_exception;
   END IF;
  
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.nivel,
         ic.flag_planejado
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_nivel_ori,
         v_flag_planej_ori
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_ori_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  v_nivel_des     := 1;
  v_ordem_des     := 0;
  v_tem_filho_des := 0;
  --
  IF nvl(p_item_crono_des_id, 0) > 0 THEN
   SELECT nivel,
          ordem,
          num_seq,
          item_crono_pai_id,
          objeto_id,
          flag_planejado
     INTO v_nivel_des,
          v_ordem_des,
          v_num_seq_des,
          v_item_crono_pai_des_id,
          v_objeto_des_id,
          v_flag_planej_des
     FROM item_crono
    WHERE item_crono_id = p_item_crono_des_id;
   --
   /*
   IF v_flag_planej_ori <> v_flag_planej_des THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Movimentação inválida entre itens planejados e não planejados.';
      RAISE v_exception;
   END IF;
   */
   --
   -- verifica se o destino tem filhos
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE item_crono_pai_id = p_item_crono_des_id;
   --
   IF v_qt > 0 THEN
    v_tem_filho_des := 1;
   END IF;
  END IF;
  --
  -- seleciona a ordem, o nivel e o pai 
  -- do item abaixo ao destino
  SELECT MIN(ordem)
    INTO v_ordem_prox
    FROM item_crono
   WHERE ordem > v_ordem_des
     AND cronograma_id = v_cronograma_id;
  --
  IF v_ordem_prox IS NULL THEN
   v_ordem_prox             := 1000000000;
   v_nivel_prox             := 1;
   v_item_crono_pai_prox_id := NULL;
  ELSE
   SELECT nivel,
          item_crono_pai_id
     INTO v_nivel_prox,
          v_item_crono_pai_prox_id
     FROM item_crono
    WHERE ordem = v_ordem_prox
      AND cronograma_id = v_cronograma_id;
  
  END IF;
  --
  IF v_nivel_ori = v_nivel_des AND v_tem_filho_des = 1 THEN
   -- o item acima (destino) tem o mesmo nivel do item movido. 
   -- Pode mover desde que o item acima nao tenha filhos.
   p_erro_cod := '90000';
   p_erro_msg := 'Movimentação inválida.';
   RAISE v_exception;
  END IF;
  --
  IF v_nivel_ori = v_nivel_des OR v_nivel_ori = v_nivel_prox THEN
   -- o item vai manter o nivel do item abaixo ou acima, com o mesmo 
   -- pai do item acima ou abaixo.
   IF v_nivel_ori = v_nivel_des THEN
    v_item_crono_pai_prox_id := v_item_crono_pai_des_id;
   END IF;
  ELSE
   --
   IF v_nivel_ori < v_nivel_des OR v_nivel_ori - v_nivel_des > 1 OR p_item_crono_des_id = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Movimentação inválida.';
    RAISE v_exception;
   END IF;
   --
   v_item_crono_pai_prox_id := p_item_crono_des_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- a nova posicao sera entre o item destino e o proximo
  v_ordem := round((v_ordem_des + v_ordem_prox) / 2, 0);
  --
  IF v_nivel_ori = v_nivel_des THEN
   v_item_crono_pai_prox_id := v_item_crono_pai_des_id;
  END IF;
  --
  -- trata a arvore movida
  FOR r_ic IN c_ic
  LOOP
   IF r_ic.item_crono_id = p_item_crono_ori_id THEN
    -- apenas o proprio item movido muda de pai
    UPDATE item_crono
       SET item_crono_pai_id = v_item_crono_pai_prox_id,
           ordem             = v_ordem
     WHERE item_crono_id = r_ic.item_crono_id;
   
   ELSE
    -- acerta a ordem dos demais itens
    v_ordem := v_ordem + 10;
    --
    UPDATE item_crono
       SET ordem = v_ordem
     WHERE item_crono_id = r_ic.item_crono_id;
   
   END IF;
  END LOOP;
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               v_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(v_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Movimentação de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_mover;
 --
 --
 PROCEDURE item_crono_deslocar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: Desloca o item de CRONOGRAMA para a direita ou para a esquerda.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/09/2016  Nao deixa deslocar do bloco planejado p/ o nao planejado.
  -- Silvia            20/02/2020  Deixa mover planejado/nao planejado
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_direcao           IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_numero_job             job.numero%TYPE;
  v_job_id                 job.job_id%TYPE;
  v_status_job             job.status%TYPE;
  v_num_crono              cronograma.numero%TYPE;
  v_cronograma_id          cronograma.cronograma_id%TYPE;
  v_nome_item              item_crono.nome%TYPE;
  v_item_crono_pai_id      item_crono.item_crono_pai_id%TYPE;
  v_item_crono_pai_novo_id item_crono.item_crono_pai_id%TYPE;
  v_nivel                  item_crono.nivel%TYPE;
  v_ordem                  item_crono.ordem%TYPE;
  v_ordem_aux              item_crono.ordem%TYPE;
  v_objeto_id              item_crono.objeto_id%TYPE;
  v_flag_planej_ori        item_crono.flag_planejado%TYPE;
  v_flag_planej_pai        item_crono.flag_planejado%TYPE;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.item_crono_pai_id,
         ic.nivel,
         ic.ordem,
         ic.flag_planejado
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_item_crono_pai_id,
         v_nivel,
         v_ordem,
         v_flag_planej_ori
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF TRIM(p_direcao) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção do deslocamento não informada.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao NOT IN ('DIR', 'ESQ') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Direção do deslocamento inválida.';
   RAISE v_exception;
  END IF;
  --
  IF p_direcao = 'ESQ' THEN
   IF v_item_crono_pai_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deslocamento inválido.';
    RAISE v_exception;
   ELSE
    -- pega o avo do item atual
    SELECT item_crono_pai_id
      INTO v_item_crono_pai_novo_id
      FROM item_crono
     WHERE item_crono_id = v_item_crono_pai_id;
   
   END IF;
  END IF;
  --
  IF p_direcao = 'DIR' THEN
   -- pega 1ro irmao acima (mesmo nivel, com mesmo pai)
   SELECT MAX(ordem)
     INTO v_ordem_aux
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND nvl(item_crono_pai_id, 0) = nvl(v_item_crono_pai_id, 0)
      AND nivel = v_nivel
      AND ordem < v_ordem;
   --
   IF v_ordem_aux IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Deslocamento inválido.';
    RAISE v_exception;
   ELSE
    SELECT item_crono_id,
           objeto_id
      INTO v_item_crono_pai_novo_id,
           v_objeto_id
      FROM item_crono
     WHERE cronograma_id = v_cronograma_id
       AND nivel = v_nivel
       AND ordem = v_ordem_aux;
   
   END IF;
  
  END IF;
  --
  /*
    IF v_item_crono_pai_novo_id IS NOT NULL THEN
       SELECT flag_planejado
         INTO v_flag_planej_pai
         FROM item_crono
        WHERE item_crono_id = v_item_crono_pai_novo_id;
       --
       IF v_flag_planej_ori <> v_flag_planej_pai THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Deslocamento inválido entre itens planejados e não planejados.';
          RAISE v_exception;
       END IF;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE item_crono
     SET item_crono_pai_id = v_item_crono_pai_novo_id
   WHERE item_crono_id = p_item_crono_id;
  --
  cronograma_pkg.seq_renumerar(p_usuario_sessao_id,
                               p_empresa_id,
                               v_cronograma_id,
                               p_erro_cod,
                               p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.ordem_renumerar(p_usuario_sessao_id,
                                 p_empresa_id,
                                 v_cronograma_id,
                                 p_erro_cod,
                                 p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  cronograma_pkg.num_gantt_processar(v_cronograma_id, p_erro_cod, p_erro_msg);
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Deslocamento de item: ' || TRIM(v_nome_item);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_deslocar;
 --
 --
 PROCEDURE item_crono_pre_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 17/02/2022
  -- DESCRICAO: Inclusao de predecessores de um item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono_pre.item_crono_id%TYPE,
  p_item_crono_pre_id IN item_crono_pre.item_crono_pre_id%TYPE,
  p_tipo              IN item_crono_pre.tipo%TYPE,
  p_lag               IN item_crono_pre.lag%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_numero_job        job.numero%TYPE;
  v_job_id            job.job_id%TYPE;
  v_status_job        job.status%TYPE;
  v_num_crono         cronograma.numero%TYPE;
  v_cronograma_id     cronograma.cronograma_id%TYPE;
  v_nome_atu          item_crono.nome%TYPE;
  v_num_seq_atu       item_crono.num_seq%TYPE;
  v_item_crono_pre_id item_crono_pre.item_crono_pre_id%TYPE;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_lbl_job           VARCHAR2(100);
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.num_seq
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_atu,
         v_num_seq_atu
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  /*
    -- verifica se o usuario tem privilegio
    IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
       RAISE v_exception;
    END IF;
  */
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND item_crono_id = p_item_crono_pre_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse predecessor não existe no cronograma (' || to_char(p_item_crono_pre_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_lag IS NULL OR p_tipo IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo e Lag não podem ser nulos.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_pre
   WHERE item_crono_id = p_item_crono_id
     AND item_crono_pre_id = p_item_crono_pre_id
     AND tipo = p_tipo
     AND lag = p_lag;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item já está associado a um predecessor (' || to_char(v_num_seq_atu) || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO item_crono_pre
   (item_crono_id,
    item_crono_pre_id,
    tipo,
    lag)
  VALUES
   (p_item_crono_id,
    p_item_crono_pre_id,
    p_tipo,
    p_lag);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Inclusão de predecessores do item: ' || to_char(v_num_seq_atu);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_pre_adicionar;
 --
 --
 PROCEDURE item_crono_pre_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 26/08/2013
  -- DESCRICAO: Atualizacao de predecessores de um item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia           14/01/2020   Novos parametros type e lag. Vetor num_seq passou a ser
  --                               vetor de item_crono_id.
  -- Silvia            13/04/2020  Retirada do teste de privilegio.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_item_crono_id        IN item_crono.item_crono_id%TYPE,
  p_vetor_item_crono_pre IN VARCHAR2,
  p_vetor_tipo           IN VARCHAR2,
  p_vetor_lag            IN VARCHAR2,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
 
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_numero_job           job.numero%TYPE;
  v_job_id               job.job_id%TYPE;
  v_status_job           job.status%TYPE;
  v_num_crono            cronograma.numero%TYPE;
  v_cronograma_id        cronograma.cronograma_id%TYPE;
  v_nome_atu             item_crono.nome%TYPE;
  v_num_seq_atu          item_crono.num_seq%TYPE;
  v_item_crono_pre_id    item_crono_pre.item_crono_pre_id%TYPE;
  v_identif_objeto       historico.identif_objeto%TYPE;
  v_compl_histor         historico.complemento%TYPE;
  v_historico_id         historico.historico_id%TYPE;
  v_delimitador          CHAR(1);
  v_vetor_item_crono_pre LONG;
  v_vetor_tipo           LONG;
  v_vetor_lag            LONG;
  v_lbl_job              VARCHAR2(100);
  v_tipo                 item_crono_pre.tipo%TYPE;
  v_lag                  item_crono_pre.lag%TYPE;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.num_seq
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_atu,
         v_num_seq_atu
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  /*
    -- verifica se o usuario tem privilegio
    IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
       RAISE v_exception;
    END IF;
  */
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM item_crono_pre
   WHERE item_crono_id = p_item_crono_id;
  --
  v_delimitador          := '|';
  v_vetor_item_crono_pre := p_vetor_item_crono_pre;
  v_vetor_tipo           := p_vetor_tipo;
  v_vetor_lag            := p_vetor_lag;
  --
  WHILE nvl(length(rtrim(v_vetor_item_crono_pre)), 0) > 0
  LOOP
   v_item_crono_pre_id := nvl(to_number(prox_valor_retornar(v_vetor_item_crono_pre, v_delimitador)),
                              0);
   v_tipo              := nvl(to_number(prox_valor_retornar(v_vetor_tipo, v_delimitador)), 0);
   v_lag               := nvl(to_number(prox_valor_retornar(v_vetor_lag, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE cronograma_id = v_cronograma_id
      AND item_crono_id = v_item_crono_pre_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse número de predecessor não existe (' || to_char(v_item_crono_pre_id) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO item_crono_pre
    (item_crono_id,
     item_crono_pre_id,
     tipo,
     lag)
   VALUES
    (p_item_crono_id,
     v_item_crono_pre_id,
     v_tipo,
     v_lag);
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Alteração de predecessores do item: ' || to_char(v_num_seq_atu);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_pre_atualizar;
 --
 --
 PROCEDURE item_crono_pre_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/01/2020
  -- DESCRICAO: Exclusao de predecessor de um item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/02/2022  Novos parametros tipo e lag
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono_pre.item_crono_id%TYPE,
  p_item_crono_pre_id IN item_crono_pre.item_crono_pre_id%TYPE,
  p_tipo              IN item_crono_pre.tipo%TYPE,
  p_lag               IN item_crono_pre.lag%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_numero_job     job.numero%TYPE;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_num_crono      cronograma.numero%TYPE;
  v_cronograma_id  cronograma.cronograma_id%TYPE;
  v_nome_atu       item_crono.nome%TYPE;
  v_num_seq_atu    item_crono.num_seq%TYPE;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.num_seq
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_atu,
         v_num_seq_atu
    FROM job        jo,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM item_crono_pre
   WHERE item_crono_id = p_item_crono_id
     AND item_crono_pre_id = p_item_crono_pre_id
     AND tipo = p_tipo
     AND lag = p_lag;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Alteração de predecessores do item: ' || to_char(v_num_seq_atu);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END item_crono_pre_excluir;
 --
 --
 PROCEDURE executores_replicar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 13/08/2020
  -- DESCRICAO: subrotina que replica os executores do item do cronograma para
  --  o objeto (ORDEM_SERVICO, TAREFA).  *** NAO FAZ COMMIT ***
  -- P_ORIGEM: PLAY_CRONO -> chamada via play na atividade do cronograma
  --           ALT_EXEC_CRONO -> chamada via tela de alteração de executores do crono
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         20/12/2024  Tratamento num_refacao os_usuario_data
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_origem            IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_job_id           job.job_id%TYPE;
  v_objeto_id        item_crono.objeto_id%TYPE;
  v_cod_objeto       item_crono.cod_objeto%TYPE;
  v_data_planej_ini  item_crono.data_planej_ini%TYPE;
  v_data_planej_fim  item_crono.data_planej_fim%TYPE;
  v_tipo_os_desc     tipo_os.nome%TYPE;
  v_numero_os_char   VARCHAR2(50);
  v_ordem_servico_id ordem_servico.ordem_servico_id%TYPE;
  v_apelido          pessoa.apelido%TYPE;
  v_tarefa_id        tarefa.tarefa_id%TYPE;
  v_data             DATE;
  v_complemento      historico.complemento%TYPE;
  v_justificativa    historico.justificativa%TYPE;
  --
  CURSOR c_us IS
   SELECT usuario_id,
          horas_totais,
          horas_diarias
     FROM item_crono_usu
    WHERE item_crono_id = p_item_crono_id
      AND controle IS NULL;
  --
 BEGIN
  SELECT ic.objeto_id,
         ic.cod_objeto,
         ic.data_planej_fim,
         ic.data_planej_ini,
         cr.job_id
    INTO v_objeto_id,
         v_cod_objeto,
         v_data_planej_fim,
         v_data_planej_ini,
         v_job_id
    FROM item_crono ic,
         cronograma cr
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id;
  --
  IF TRIM(p_origem) IS NULL OR p_origem NOT IN ('PLAY_CRONO', 'ALT_EXEC_CRONO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Origem inválida na replicação de executores (' || p_origem || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- copia da equipe do cronograma como executores da OS
  ------------------------------------------------------------
  IF v_cod_objeto = 'ORDEM_SERVICO' AND nvl(v_objeto_id, 0) > 0 THEN
   v_ordem_servico_id := v_objeto_id;
   v_numero_os_char   := ordem_servico_pkg.numero_formatar(v_ordem_servico_id);
   --
   SELECT ti.nome
     INTO v_tipo_os_desc
     FROM ordem_servico os,
          tipo_os       ti
    WHERE os.ordem_servico_id = v_ordem_servico_id
      AND os.tipo_os_id = ti.tipo_os_id;
   --
   -- marca todos os executores como candidatos a serem excluidos
   UPDATE os_usuario
      SET controle = 'DEL'
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   -- exclui todas as estimativas por data
   DELETE FROM os_usuario_data
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_ender = 'EXE';
   --
   -- loop por executor do cronograma
   FOR r_us IN c_us
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM os_usuario
     WHERE usuario_id = r_us.usuario_id
       AND ordem_servico_id = v_ordem_servico_id
       AND tipo_ender = 'EXE';
    --
    IF v_qt = 0 THEN
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
       r_us.usuario_id,
       'EXE',
       'N',
       r_us.horas_totais,
       1,
       'EMEX',
       SYSDATE);
     --
     historico_pkg.hist_ender_registrar(r_us.usuario_id,
                                        'OS',
                                        v_ordem_servico_id,
                                        'EXE',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     SELECT MAX(apelido)
       INTO v_apelido
       FROM pessoa
      WHERE usuario_id = r_us.usuario_id;
     --
     IF p_origem = 'PLAY_CRONO' THEN
      -- play do cronograma cria a OS
      v_complemento   := v_apelido || ' endereçado via cronograma no Workflow ' || v_numero_os_char ||
                         ' de ' || v_tipo_os_desc;
      v_justificativa := 'Criação de Workflow';
     ELSIF p_origem = 'ALT_EXEC_CRONO' THEN
      -- alteracao dos executores da atividade do cronograma
      v_complemento   := v_apelido || ' endereçado via cronograma no Workflow ' || v_numero_os_char ||
                         ' de ' || v_tipo_os_desc;
      v_justificativa := 'Alteração de Executor na Atividade';
     END IF;
     --
     -- endereca automaticamente o usuario ao job com co-ender e sem pula notif
     job_pkg.enderecar_usuario(p_usuario_sessao_id,
                               'N',
                               'S',
                               'N',
                               p_empresa_id,
                               v_job_id,
                               r_us.usuario_id,
                               v_justificativa,
                               v_complemento,
                               p_erro_cod,
                               p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    ELSE
     -- executor ja enderecado na OS. Desmarca exclusao e atualiza
     UPDATE os_usuario
        SET horas_planej = r_us.horas_totais,
            controle     = NULL
      WHERE usuario_id = r_us.usuario_id
        AND ordem_servico_id = v_ordem_servico_id
        AND tipo_ender = 'EXE';
    END IF;
    --
    -- cria as estimativas diarias do usuario
    v_data := trunc(v_data_planej_ini);
    WHILE v_data <= trunc(v_data_planej_fim)
    LOOP
     IF feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data, 'S') = 1 THEN
      --ALCBO_201224
      SELECT os.qtd_refacao
        INTO v_qt
        FROM ordem_servico os
       WHERE os.ordem_servico_id = v_ordem_servico_id;
      --
      INSERT INTO os_usuario_data
       (ordem_servico_id,
        usuario_id,
        tipo_ender,
        data,
        horas,
        num_refacao)
      VALUES
       (v_ordem_servico_id,
        r_us.usuario_id,
        'EXE',
        v_data,
        r_us.horas_diarias,
        v_qt);
     END IF;
     --
     v_data := v_data + 1;
    END LOOP;
   END LOOP;
   --
   DELETE FROM os_usuario
    WHERE ordem_servico_id = v_ordem_servico_id
      AND tipo_ender = 'EXE'
      AND controle = 'DEL';
  END IF; -- fim do IF v_cod_objeto = 'ORDEM_SERVICO'
  --
  --
  ------------------------------------------------------------
  -- copia da equipe do cronograma como executores da TAREFA
  ------------------------------------------------------------
  IF v_cod_objeto = 'TAREFA' AND nvl(v_objeto_id, 0) > 0 THEN
   v_tarefa_id := v_objeto_id;
   --
   -- marca todos os executores como candidatos a serem excluidos
   UPDATE tarefa_usuario
      SET controle = 'DEL'
    WHERE tarefa_id = v_tarefa_id;
   --
   -- exclui todas as estimativas por data
   DELETE FROM tarefa_usuario_data
    WHERE tarefa_id = v_tarefa_id;
   --
   -- loop por executor do cronograma
   FOR r_us IN c_us
   LOOP
    SELECT COUNT(*)
      INTO v_qt
      FROM tarefa_usuario
     WHERE usuario_para_id = r_us.usuario_id
       AND tarefa_id = v_tarefa_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO tarefa_usuario
      (tarefa_id,
       usuario_para_id,
       horas_totais,
       status,
       data_status)
     VALUES
      (v_tarefa_id,
       r_us.usuario_id,
       r_us.horas_totais,
       'EMEX',
       SYSDATE);
     --
     historico_pkg.hist_ender_registrar(r_us.usuario_id,
                                        'TAR',
                                        v_tarefa_id,
                                        'EXE',
                                        p_erro_cod,
                                        p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    ELSE
     UPDATE tarefa_usuario
        SET horas_totais = r_us.horas_totais,
            controle     = NULL
      WHERE usuario_para_id = r_us.usuario_id
        AND tarefa_id = v_tarefa_id;
    END IF;
    --
    -- cria as estimativas diarias do usuario
    v_data := trunc(v_data_planej_ini);
    WHILE v_data <= trunc(v_data_planej_fim)
    LOOP
     IF feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data, 'S') = 1 THEN
      INSERT INTO tarefa_usuario_data
       (tarefa_id,
        usuario_para_id,
        data,
        horas)
      VALUES
       (v_tarefa_id,
        r_us.usuario_id,
        v_data,
        r_us.horas_diarias);
     END IF;
     --
     v_data := v_data + 1;
    END LOOP;
   END LOOP;
   --
   DELETE FROM tarefa_usuario
    WHERE tarefa_id = v_tarefa_id
      AND controle = 'DEL';
  END IF; -- fim do IF v_cod_objeto = 'TAREFA'
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
 END executores_replicar;
 --
 --
 PROCEDURE datas_depend_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/10/2018
  -- DESCRICAO: subrotina que processa a alteracao de datas de atividades dependentes 
  --   (vinculadas a uma atividade predecessora), com base num deslocamento em dias uteis.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_num_dias_uteis    IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  v_ind           NUMBER(20);
  v_ind_tot       NUMBER(20);
  v_achou         NUMBER(5);
  v_ind_aux       NUMBER(20);
  v_duracao       NUMBER(20);
  v_data_ativ_ini DATE;
  v_data_ativ_fim DATE;
  --
  TYPE id_type IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE data_type IS TABLE OF DATE INDEX BY PLS_INTEGER;
  --
  t_item_crono_id   id_type;
  t_data_planej_ini data_type;
  t_data_planej_fim data_type;
  --
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          ic.data_planej_ini,
          ic.data_planej_fim
     FROM item_crono     ic,
          item_crono_pre ip
    WHERE ip.item_crono_pre_id = v_item_crono_id
      AND ip.item_crono_id = ic.item_crono_id
    ORDER BY ic.num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_ind := 1;
  --
  t_item_crono_id(v_ind) := p_item_crono_id;
  v_ind_tot := v_ind;
  --
  -- inicializa uma linha a mais para permitir o
  -- fim do loop da tabela em memoria
  t_item_crono_id(v_ind_tot + 1) := NULL;
  --
  -- loop por registro na tabela em memoria
  WHILE t_item_crono_id(v_ind) IS NOT NULL
  LOOP
   dbms_output.put_line('ind ' || to_char(v_ind));
   -- item cuja dependencia sera verificada
   v_item_crono_id := t_item_crono_id(v_ind);
   --
   -- procura itens dependentes de v_item_crono_id
   FOR r_ic IN c_ic
   LOOP
    -- verifica se item dependente ja foi carregado na memoria
    v_achou   := 0;
    v_ind_aux := 1;
    WHILE v_achou = 0 AND v_ind_aux <= v_ind_tot
    LOOP
     IF t_item_crono_id(v_ind_aux) = r_ic.item_crono_id THEN
      v_achou := 1;
     END IF;
     --
     v_ind_aux := v_ind_aux + 1;
    END LOOP;
    --
    IF v_achou = 0 THEN
     -- item ainda nao carregado
     -- calcula a duracao original da atividade
     v_duracao := nvl(feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                          r_ic.data_planej_ini,
                                                          r_ic.data_planej_fim),
                      0);
     --
     -- calcula a nova data FINAL aplicando o deslocamento
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           r_ic.data_planej_fim,
                                                           p_num_dias_uteis,
                                                           'S');
     v_data_ativ_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_fim,
                                                           -v_duracao,
                                                           'S');
     --                       
     v_ind_tot := v_ind_tot + 1;
     dbms_output.put_line('ind_tot ' || to_char(v_ind_tot));
     --
     -- carrega item dependente na tabela em memoria
     t_item_crono_id(v_ind_tot) := r_ic.item_crono_id;
     t_data_planej_ini(v_ind_tot) := v_data_ativ_ini;
     t_data_planej_fim(v_ind_tot) := v_data_ativ_fim;
     dbms_output.put_line(to_char(t_item_crono_id(v_ind_tot)));
     dbms_output.put_line(data_mostrar(t_data_planej_ini(v_ind_tot)));
     dbms_output.put_line(data_mostrar(t_data_planej_fim(v_ind_tot)));
     dbms_output.put_line('---------------------');
     -- inicializa uma linha a mais para permitir o
     -- fim do loop da tabela em memoria
     t_item_crono_id(v_ind_tot + 1) := NULL;
    END IF;
   
   END LOOP;
   --
   -- atualiza o item cuja dependencia foi verificada (exceto o primeiro)
   IF v_ind > 1 THEN
    UPDATE item_crono
       SET data_planej_ini = t_data_planej_ini(v_ind),
           data_planej_fim = t_data_planej_fim(v_ind)
     WHERE item_crono_id = t_item_crono_id(v_ind);
   
   END IF;
   --
   v_ind := v_ind + 1;
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
   p_erro_msg := substr(SQLERRM || ' *** ' || dbms_utility.format_error_backtrace, 1, 300);
  
 END datas_depend_processar;
 --
 --
 PROCEDURE datas_hierarq_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/10/2018
  -- DESCRICAO: subrotina que processa a alteracao de datas de atividades filhas  
  --   (nivel hierarquico abaixo), com base num deslocamento em dias uteis.
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_item_crono_id     IN item_crono.item_crono_id%TYPE,
  p_num_dias_uteis    IN NUMBER,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  v_ind           NUMBER(20);
  v_ind_tot       NUMBER(20);
  v_achou         NUMBER(5);
  v_ind_aux       NUMBER(20);
  v_duracao       NUMBER(20);
  v_data_ativ_ini DATE;
  v_data_ativ_fim DATE;
  --
  TYPE id_type IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE data_type IS TABLE OF DATE INDEX BY PLS_INTEGER;
  --
  t_item_crono_id   id_type;
  t_data_planej_ini data_type;
  t_data_planej_fim data_type;
  --
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          ic.data_planej_ini,
          ic.data_planej_fim
     FROM item_crono ic
    WHERE ic.item_crono_pai_id = v_item_crono_id
    ORDER BY ic.num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_ind := 1;
  --
  t_item_crono_id(v_ind) := p_item_crono_id;
  v_ind_tot := v_ind;
  --
  -- inicializa uma linha a mais para permitir o
  -- fim do loop da tabela em memoria
  t_item_crono_id(v_ind_tot + 1) := NULL;
  --
  -- loop por registro na tabela em memoria
  WHILE t_item_crono_id(v_ind) IS NOT NULL
  LOOP
   dbms_output.put_line('ind ' || to_char(v_ind));
   -- item cujos filhos serao verificados
   v_item_crono_id := t_item_crono_id(v_ind);
   --
   -- procura itens filhos de v_item_crono_id
   FOR r_ic IN c_ic
   LOOP
    -- verifica se item filho ja foi carregado na memoria
    v_achou   := 0;
    v_ind_aux := 1;
    WHILE v_achou = 0 AND v_ind_aux <= v_ind_tot
    LOOP
     IF t_item_crono_id(v_ind_aux) = r_ic.item_crono_id THEN
      v_achou := 1;
     END IF;
     --
     v_ind_aux := v_ind_aux + 1;
    END LOOP;
    --
    IF v_achou = 0 THEN
     -- item ainda nao carregado
     -- calcula a duracao original da atividade
     v_duracao := nvl(feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                          r_ic.data_planej_ini,
                                                          r_ic.data_planej_fim),
                      0);
     --
     -- calcula a nova data INICIAL aplicando o deslocamento
     v_data_ativ_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           r_ic.data_planej_ini,
                                                           p_num_dias_uteis,
                                                           'S');
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao,
                                                           'S');
     --                       
     v_ind_tot := v_ind_tot + 1;
     dbms_output.put_line('ind_tot ' || to_char(v_ind_tot));
     --
     -- carrega item filho na tabela em memoria
     t_item_crono_id(v_ind_tot) := r_ic.item_crono_id;
     t_data_planej_ini(v_ind_tot) := v_data_ativ_ini;
     t_data_planej_fim(v_ind_tot) := v_data_ativ_fim;
     dbms_output.put_line(to_char(t_item_crono_id(v_ind_tot)));
     dbms_output.put_line(data_mostrar(t_data_planej_ini(v_ind_tot)));
     dbms_output.put_line(data_mostrar(t_data_planej_fim(v_ind_tot)));
     dbms_output.put_line('---------------------');
     -- inicializa uma linha a mais para permitir o
     -- fim do loop da tabela em memoria
     t_item_crono_id(v_ind_tot + 1) := NULL;
    END IF;
   
   END LOOP;
   --
   -- atualiza o item cuja dependencia foi verificada (exceto o primeiro)
   IF v_ind > 1 THEN
    UPDATE item_crono
       SET data_planej_ini = t_data_planej_ini(v_ind),
           data_planej_fim = t_data_planej_fim(v_ind)
     WHERE item_crono_id = t_item_crono_id(v_ind);
   
   END IF;
   --
   v_ind := v_ind + 1;
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
   p_erro_msg := substr(SQLERRM || ' *** ' || dbms_utility.format_error_backtrace, 1, 300);
  
 END datas_hierarq_processar;
 --
 --
 PROCEDURE repeticao_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 15/10/2018
  -- DESCRICAO: subrotina que processa a programacao de repeticoes de atividades. 
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         28/10/2024  Adicao de novo parametro 
  --                               para controle data de repeticao mensal
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_data_mes_old      IN DATE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_cod_freq        frequencia.codigo%TYPE;
  v_item_crono_id   item_crono.item_crono_id%TYPE;
  v_data_term_repet item_crono.data_term_repet%TYPE;
  v_data_ativ_ini   item_crono.data_planej_ini%TYPE;
  v_data_ativ_fim   item_crono.data_planej_fim%TYPE;
  v_repet_grupo     item_crono.repet_grupo%TYPE;
  v_num_seq         item_crono.num_seq%TYPE;
  v_data_aux        DATE;
  v_data_aux2       DATE;
  v_data_aux3       VARCHAR2(10);
  v_data_aux4       VARCHAR2(10);
  v_qt_repet        NUMBER(10);
  v_duracao         NUMBER(20);
  v_dia_semana_atu  NUMBER(5);
  v_dia_semana_prox NUMBER(5);
  v_mudou_semana    NUMBER(5);
  --
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          ic.data_planej_ini,
          ic.data_planej_fim,
          ic.frequencia_id,
          ic.repet_a_cada,
          ic.repet_term_tipo,
          ic.repet_term_ocor,
          ic.data_term_repet,
          jo.data_prev_fim,
          ic.item_crono_pai_id,
          ic.nome,
          ic.cod_objeto,
          ic.tipo_objeto_id,
          ic.sub_tipo_objeto,
          ic.papel_resp_id,
          ic.flag_enviar,
          ic.duracao_ori,
          fr.codigo AS cod_freq
     FROM item_crono ic,
          cronograma cr,
          job        jo,
          frequencia fr
    WHERE ic.cronograma_id = p_cronograma_id
      AND ic.frequencia_id = fr.frequencia_id
      AND ic.repet_grupo IS NULL
      AND ic.cronograma_id = cr.cronograma_id
      AND cr.job_id = jo.job_id
    ORDER BY ic.num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  FOR r_ic IN c_ic
  LOOP
   v_data_term_repet := r_ic.data_term_repet;
   v_cod_freq        := r_ic.cod_freq;
   --
   -- subtrai um pois o item original ja foi criado fora dessa rotina
   v_qt_repet := nvl(r_ic.repet_term_ocor, 0) - 1;
   --
   v_duracao := nvl(feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                        r_ic.data_planej_ini,
                                                        r_ic.data_planej_fim) + 1,
                    0);
   --
   IF r_ic.data_planej_ini IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Repetição Processar: Data da atividade não definida.';
    RAISE v_exception;
   END IF;
   --
   -- inicializa variavel que vai ser usada no loop de datas
   v_data_aux := r_ic.data_planej_ini;
   --
   IF r_ic.repet_term_tipo = 'FIMJOB' AND v_data_term_repet IS NULL THEN
    IF r_ic.data_prev_fim IS NULL THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Repetição Processar: Data prevista para o término do job não definida.';
     RAISE v_exception;
    END IF;
    --
    v_data_term_repet := r_ic.data_prev_fim;
   END IF;
   --
   -- tratamento especial para frequencia semanal
   IF v_cod_freq = 'SEM' THEN
    -- verifica se precisa ajustar a primeira data para o dia da 
    -- semana correto (previsto na programacao)
    v_dia_semana_atu := to_number(to_char(r_ic.data_planej_ini, 'D'));
    --
    -- seleciona o proximo dia da semana (dentro da propria semana)
    SELECT nvl(MIN(ds.ordem), 0)
      INTO v_dia_semana_prox
      FROM item_crono_dia id,
           dia_semana     ds
     WHERE id.item_crono_id = r_ic.item_crono_id
       AND id.dia_semana_id = ds.dia_semana_id
       AND ds.ordem >= v_dia_semana_atu;
    --
    IF v_dia_semana_prox = 0 THEN
     -- seleciona o proximo dia da semana (na proxima semana)
     SELECT nvl(MIN(ds.ordem), 0)
       INTO v_dia_semana_prox
       FROM item_crono_dia id,
            dia_semana     ds
      WHERE id.item_crono_id = r_ic.item_crono_id
        AND id.dia_semana_id = ds.dia_semana_id
        AND ds.ordem >= 1;
    
    END IF;
    --
    IF v_dia_semana_atu <> v_dia_semana_prox THEN
     -- precisa de ajuste.
     -- calcula o proximo dia da semana
     v_data_ativ_ini := util_pkg.prox_dia_semana_retornar(r_ic.data_planej_ini, v_dia_semana_prox);
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao - 1,
                                                           'S');
     --
     UPDATE item_crono
        SET data_planej_ini = v_data_ativ_ini,
            data_planej_fim = v_data_ativ_fim
      WHERE item_crono_id = r_ic.item_crono_id;
     --
     v_data_aux := v_data_ativ_ini;
    END IF;
   
   END IF;
   --
   -- gera a sequencia do grupo de repeticao
   SELECT seq_repet_grupo.nextval
     INTO v_repet_grupo
     FROM dual;
   --
   -- atualiza o primeito item da sequencia
   v_num_seq := 1;
   --
   UPDATE item_crono
      SET repet_grupo = v_repet_grupo,
          repet_seq   = v_num_seq
    WHERE item_crono_id = r_ic.item_crono_id;
   --
   -- inicializa a sequencia dentro do grupo de repeticao com a
   -- sequencia do item de origem (ja criado)
   --
   WHILE (r_ic.repet_term_tipo = 'QTOCOR' AND v_qt_repet > 0) OR
         (r_ic.repet_term_tipo = 'FIMJOB' AND v_data_aux <= v_data_term_repet)
   LOOP
    --
    v_data_ativ_ini := NULL;
    v_data_ativ_fim := NULL;
    v_num_seq       := v_num_seq + 1;
    --
    IF v_cod_freq = 'DIA' THEN
     -- calcula o proximo dia util
     v_data_ativ_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_aux,
                                                           r_ic.repet_a_cada,
                                                           'S');
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao - 1,
                                                           'S');
    END IF;
    --
    IF v_cod_freq = 'MES' THEN
     -- soma o numero de meses
     --ALCBO_281024
     /*
     IF p_data_mes_old IS NOT NULL THEN
     
      IF p_data_mes_old <> v_data_aux THEN
       v_data_aux2 := add_months(p_data_mes_old, r_ic.repet_a_cada);
      ELSE
       v_data_aux2 := add_months(v_data_aux, r_ic.repet_a_cada);
      END IF;
     END IF;
     */
     v_data_aux3 := to_char(p_data_mes_old, 'DD');
     v_data_aux4 := to_char(v_data_aux, 'MM/YYYY');
     v_data_aux  := to_date(v_data_aux3 || '/' || v_data_aux4, 'DD/MM/YYYY');
     v_data_aux2 := add_months(v_data_aux, r_ic.repet_a_cada);
     --
     -- verifica proximo dia util (soma zero para pegar o proprio dia calculado, caso 
     -- seja dia util).
     v_data_ativ_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_aux2, 0, 'S');
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao - 1,
                                                           'S');
    END IF;
    --
    IF v_cod_freq = 'ANO' THEN
     -- soma o numero de anos
     v_data_aux2 := add_months(v_data_aux, r_ic.repet_a_cada * 12);
     --
     -- verifica proximo dia util (soma zero para pegar o proprio dia calculado, caso 
     -- seja dia util).
     v_data_ativ_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_aux2, 0, 'S');
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao - 1,
                                                           'S');
    END IF;
    --
    IF v_cod_freq = 'SEM' THEN
     v_dia_semana_atu := to_number(to_char(v_data_aux, 'D'));
     v_mudou_semana   := 0;
     --
     -- seleciona o proximo dia da semana (dentro da propria semana)
     SELECT nvl(MIN(ds.ordem), 0)
       INTO v_dia_semana_prox
       FROM item_crono_dia id,
            dia_semana     ds
      WHERE id.item_crono_id = r_ic.item_crono_id
        AND id.dia_semana_id = ds.dia_semana_id
        AND ds.ordem > v_dia_semana_atu;
     --
     IF v_dia_semana_prox = 0 THEN
      -- seleciona o proximo dia da semana (na proxima semana)
      v_mudou_semana := 1;
      --
      SELECT nvl(MIN(ds.ordem), 0)
        INTO v_dia_semana_prox
        FROM item_crono_dia id,
             dia_semana     ds
       WHERE id.item_crono_id = r_ic.item_crono_id
         AND id.dia_semana_id = ds.dia_semana_id
         AND ds.ordem >= 1;
     
     END IF;
     --
     -- calcula o proximo dia da semana
     v_data_ativ_ini := util_pkg.prox_dia_semana_retornar(v_data_aux, v_dia_semana_prox);
     --
     IF v_mudou_semana = 1 THEN
      IF r_ic.repet_a_cada > 1 THEN
       v_data_ativ_ini := v_data_ativ_ini + (r_ic.repet_a_cada - 1) * 7;
      END IF;
     END IF;
     --
     v_data_ativ_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                           v_data_ativ_ini,
                                                           v_duracao - 1,
                                                           'S');
    END IF;
    --
    v_data_aux := v_data_ativ_ini;
    --
    IF r_ic.repet_term_tipo = 'QTOCOR' THEN
     v_qt_repet := v_qt_repet - 1;
    END IF;
    --
    IF r_ic.repet_term_tipo = 'FIMJOB' AND v_data_aux > v_data_term_repet THEN
     -- a data calculada ultrapassou o limite.
     -- pula o processamento.
     NULL;
    ELSE
     -- cria o item repetido (passa o vetor de papel dest nulo pois essa
     -- informacao sera copiada mais abaixo).
     cronograma_pkg.item_crono_adicionar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         'N',
                                         p_cronograma_id,
                                         r_ic.item_crono_pai_id,
                                         r_ic.nome,
                                         data_mostrar(v_data_ativ_ini),
                                         data_mostrar(v_data_ativ_fim),
                                         r_ic.cod_objeto,
                                         r_ic.tipo_objeto_id,
                                         r_ic.sub_tipo_objeto,
                                         r_ic.papel_resp_id,
                                         NULL,
                                         r_ic.flag_enviar,
                                         NULL,
                                         0,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         v_item_crono_id,
                                         p_erro_cod,
                                         p_erro_msg);
     --
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
     --
     -- atualiza o novo item criado com informacoes do grupo
     UPDATE item_crono
        SET duracao_ori     = r_ic.duracao_ori,
            repet_grupo     = v_repet_grupo,
            repet_seq       = v_num_seq,
            frequencia_id   = r_ic.frequencia_id,
            repet_a_cada    = r_ic.repet_a_cada,
            repet_term_tipo = r_ic.repet_term_tipo,
            repet_term_ocor = r_ic.repet_term_ocor
      WHERE item_crono_id = v_item_crono_id;
     --
     -- copia eventual predecessor
     INSERT INTO item_crono_pre
      (item_crono_id,
       item_crono_pre_id,
       lag,
       tipo)
      SELECT v_item_crono_id,
             item_crono_pre_id,
             lag,
             tipo
        FROM item_crono_pre
       WHERE item_crono_id = r_ic.item_crono_id;
     --
     -- copia eventual dia da semana
     INSERT INTO item_crono_dia
      (item_crono_id,
       dia_semana_id)
      SELECT v_item_crono_id,
             dia_semana_id
        FROM item_crono_dia
       WHERE item_crono_id = r_ic.item_crono_id;
     --
     -- copia eventual papel destino
     INSERT INTO item_crono_dest
      (item_crono_id,
       papel_id)
      SELECT v_item_crono_id,
             papel_id
        FROM item_crono_dest
       WHERE item_crono_id = r_ic.item_crono_id;
     --
     -- copia eventual usuario
     INSERT INTO item_crono_usu
      (item_crono_id,
       usuario_id,
       horas_diarias,
       horas_totais)
      SELECT v_item_crono_id,
             usuario_id,
             horas_diarias,
             horas_totais
        FROM item_crono_usu
       WHERE item_crono_id = r_ic.item_crono_id;
    
    END IF;
    --
   END LOOP; -- fim do loop das repeticoes
   --
   -- seleciona a data da ultima repeticao desse grupo
   SELECT MAX(data_planej_ini)
     INTO v_data_aux
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND repet_grupo = v_repet_grupo;
   --
   -- salva a data de termino da repeticao nos itens do grupo.
   UPDATE item_crono
      SET data_term_repet = v_data_aux
    WHERE cronograma_id = p_cronograma_id
      AND repet_grupo = v_repet_grupo
      AND repet_term_tipo = 'QTOCOR';
   --
   UPDATE item_crono
      SET data_term_repet = v_data_term_repet
    WHERE cronograma_id = p_cronograma_id
      AND repet_grupo = v_repet_grupo
      AND repet_term_tipo = 'FIMJOB';
  
  END LOOP; -- fim do loop por item do cronograma
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
  
 END repeticao_processar;
 --
 --
 PROCEDURE dias_replanejar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/07/2016
  -- DESCRICAO: atualiza datas planejadas com base em dias uteis.
  --     TIPO_CALC: A - acrescentar, R - retirar
  --  *** ESSA PROC NAO ESTA MAIS SENDO USADA ***
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --- Silvia            10/01/2020  Chamada da alocacao_usu_processar.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_cronograma_id       IN cronograma.cronograma_id%TYPE,
  p_tipo_calc           IN VARCHAR2,
  p_num_dias_uteis      IN VARCHAR2,
  p_vetor_item_crono_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_numero_job          job.numero%TYPE;
  v_job_id              job.job_id%TYPE;
  v_status_job          job.status%TYPE;
  v_data_pri_aprov      job.data_pri_aprov%TYPE;
  v_data_prev_ini       job.data_prev_ini%TYPE;
  v_data_prev_fim       job.data_prev_fim%TYPE;
  v_flag_periodo_job    tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli  tipo_job.flag_usa_data_cli%TYPE;
  v_num_crono           cronograma.numero%TYPE;
  v_status_crono        cronograma.status%TYPE;
  v_item_crono_id       item_crono.item_crono_id%TYPE;
  v_data_planej_ini     item_crono.data_planej_ini%TYPE;
  v_data_planej_fim     item_crono.data_planej_fim%TYPE;
  v_data_planej_ini_old item_crono.data_planej_ini%TYPE;
  v_data_planej_fim_old item_crono.data_planej_fim%TYPE;
  v_cod_objeto          item_crono.cod_objeto%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_num_dias_uteis      NUMBER(10);
  v_delimitador         CHAR(1);
  v_vetor_item_crono_id VARCHAR2(4000);
  --
  CURSOR c_ic IS
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status,
         t.flag_usa_per_job,
         t.flag_usa_data_cli
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono,
         v_flag_periodo_job,
         v_flag_data_apre_cli
    FROM job        j,
         cronograma c,
         tipo_job   t
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF TRIM(p_tipo_calc) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de cálculo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_calc NOT IN ('A', 'R') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de cálculo inválido (' || p_tipo_calc || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_num_dias_uteis) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do número de dias úteis é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_dias_uteis) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias úteis inválido (' || p_num_dias_uteis || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_dias_uteis := nvl(to_number(p_num_dias_uteis), 0);
  --
  IF v_num_dias_uteis <= 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número de dias úteis inválido (' || p_num_dias_uteis || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_item_crono_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma atividade foi selecionada.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_calc = 'R' THEN
   -- retirar dias uteis
   v_num_dias_uteis := v_num_dias_uteis * -1;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_item_crono_id := p_vetor_item_crono_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_crono_id)), 0) > 0
  LOOP
   v_item_crono_id := to_number(prox_valor_retornar(v_vetor_item_crono_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND item_crono_id = v_item_crono_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não existe (' || to_char(v_item_crono_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT data_planej_ini,
          data_planej_fim,
          cod_objeto
     INTO v_data_planej_ini_old,
          v_data_planej_fim_old,
          v_cod_objeto
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   v_data_planej_ini := v_data_planej_ini_old;
   v_data_planej_fim := v_data_planej_fim_old;
   --
   IF v_data_planej_ini IS NOT NULL THEN
    v_data_planej_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_planej_ini,
                                                            v_num_dias_uteis,
                                                            'S');
   END IF;
   --
   IF v_data_planej_fim IS NOT NULL THEN
    v_data_planej_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_planej_fim,
                                                            v_num_dias_uteis,
                                                            'S');
   END IF;
   --
   UPDATE item_crono
      SET data_planej_ini = v_data_planej_ini,
          data_planej_fim = v_data_planej_fim,
          num_versao      = v_num_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   IF v_flag_periodo_job = 'N' AND v_cod_objeto = 'JOB_CONC' THEN
    -- nao se usa o periodo da tabela job. Instancia datas no job.
    v_data_prev_fim := v_data_planej_fim;
    --
    UPDATE job
       SET data_prev_fim = nvl(v_data_prev_fim, data_prev_fim)
     WHERE job_id = v_job_id;
   
   END IF;
   --
   IF v_flag_data_apre_cli = 'N' AND v_cod_objeto = 'DATA_APR_CLI' THEN
    -- nao se usa a data de apresentacao cliente da tabela job.
    -- Instancia data no job.
    v_data_pri_aprov := v_data_planej_fim;
    --
    UPDATE job
       SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
     WHERE job_id = v_job_id;
   
   END IF;
   --
   ------------------------------------------------------------
   -- processamento das alocacoes
   ------------------------------------------------------------  
   IF v_data_planej_ini_old < v_data_planej_ini THEN
    v_data_planej_ini := v_data_planej_ini_old;
   END IF;
   --
   IF v_data_planej_fim_old > v_data_planej_fim THEN
    v_data_planej_fim := v_data_planej_fim_old;
   END IF;
   --
   FOR r_ic IN c_ic
   LOOP
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_ic.usuario_id,
                                          v_data_planej_ini,
                                          v_data_planej_fim,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job. Instancia datas no job.
   SELECT MIN(data_planej_ini)
     INTO v_data_prev_ini
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id;
   --
   UPDATE job
      SET data_prev_ini = nvl(v_data_prev_ini, data_prev_ini)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Replanejamento (dias úteis)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 END dias_replanejar;
 --
 --
 PROCEDURE datas_replanejar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/07/2016
  -- DESCRICAO: atualiza datas planejadas com base em datas de uma atividade.
  --  *** ESSA PROC NAO ESTA MAIS SENDO USADA ***
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/01/2020  Chamada da alocacao_usu_processar.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_cronograma_id       IN cronograma.cronograma_id%TYPE,
  p_tipo_data           IN VARCHAR2,
  p_data_nova           IN VARCHAR2,
  p_item_crono_base_id  IN item_crono.item_crono_id%TYPE,
  p_vetor_item_crono_id IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                  INTEGER;
  v_exception           EXCEPTION;
  v_numero_job          job.numero%TYPE;
  v_job_id              job.job_id%TYPE;
  v_status_job          job.status%TYPE;
  v_data_pri_aprov      job.data_pri_aprov%TYPE;
  v_data_prev_ini       job.data_prev_ini%TYPE;
  v_data_prev_fim       job.data_prev_fim%TYPE;
  v_flag_periodo_job    tipo_job.flag_usa_per_job%TYPE;
  v_flag_data_apre_cli  tipo_job.flag_usa_data_cli%TYPE;
  v_num_crono           cronograma.numero%TYPE;
  v_status_crono        cronograma.status%TYPE;
  v_item_crono_id       item_crono.item_crono_id%TYPE;
  v_data_planej_ini     item_crono.data_planej_ini%TYPE;
  v_data_planej_fim     item_crono.data_planej_fim%TYPE;
  v_data_planej_ini_old item_crono.data_planej_ini%TYPE;
  v_data_planej_fim_old item_crono.data_planej_fim%TYPE;
  v_cod_objeto          item_crono.cod_objeto%TYPE;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_num_dias_uteis      NUMBER(10);
  v_delimitador         CHAR(1);
  v_vetor_item_crono_id VARCHAR2(4000);
  v_data_planej_base    DATE;
  v_data_nova           DATE;
  --
  CURSOR c_ic IS
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
    FROM cronograma c,
         job        j
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse cronograma não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.job_id,
         j.status,
         c.numero,
         c.status,
         t.flag_usa_per_job,
         t.flag_usa_data_cli
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_status_crono,
         v_flag_periodo_job,
         v_flag_data_apre_cli
    FROM job        j,
         cronograma c,
         tipo_job   t
   WHERE c.cronograma_id = p_cronograma_id
     AND c.job_id = j.job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
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
  IF TRIM(p_tipo_data) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo da data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_data NOT IN ('I', 'F') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de data inválido (' || p_tipo_data || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_data_nova) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da nova data é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_nova) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nova data inválida (' || p_data_nova || ').';
   RAISE v_exception;
  END IF;
  --
  v_data_nova := data_converter(p_data_nova);
  --
  IF TRIM(p_vetor_item_crono_id) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhuma atividade foi selecionada.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_item_crono_base_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'É necessário indicar uma atividade base para a alteração das datas.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_data = 'I' THEN
   SELECT data_planej_ini
     INTO v_data_planej_base
     FROM item_crono
    WHERE item_crono_id = p_item_crono_base_id;
  
  ELSE
   SELECT data_planej_fim
     INTO v_data_planej_base
     FROM item_crono
    WHERE item_crono_id = p_item_crono_base_id;
  
  END IF;
  --
  IF v_data_nova > v_data_planej_base THEN
   v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                           v_data_planej_base,
                                                           v_data_nova);
  ELSE
   v_num_dias_uteis := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                           v_data_nova,
                                                           v_data_planej_base);
   v_num_dias_uteis := v_num_dias_uteis * -1;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_item_crono_id := p_vetor_item_crono_id;
  --
  WHILE nvl(length(rtrim(v_vetor_item_crono_id)), 0) > 0
  LOOP
   v_item_crono_id := to_number(prox_valor_retornar(v_vetor_item_crono_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
      AND item_crono_id = v_item_crono_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não existe (' || to_char(v_item_crono_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT data_planej_ini,
          data_planej_fim,
          cod_objeto
     INTO v_data_planej_ini_old,
          v_data_planej_fim_old,
          v_cod_objeto
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   v_data_planej_ini := v_data_planej_ini_old;
   v_data_planej_fim := v_data_planej_fim_old;
   --
   IF v_data_planej_ini IS NOT NULL THEN
    v_data_planej_ini := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_planej_ini,
                                                            v_num_dias_uteis,
                                                            'S');
   END IF;
   --
   IF v_data_planej_fim IS NOT NULL THEN
    v_data_planej_fim := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                            v_data_planej_fim,
                                                            v_num_dias_uteis,
                                                            'S');
   END IF;
   --
   UPDATE item_crono
      SET data_planej_ini = v_data_planej_ini,
          data_planej_fim = v_data_planej_fim,
          num_versao      = v_num_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   IF v_flag_periodo_job = 'N' AND v_cod_objeto = 'JOB_CONC' THEN
    -- nao se usa o periodo da tabela job. Instancia datas no job.
    v_data_prev_fim := v_data_planej_fim;
    --
    UPDATE job
       SET data_prev_fim = nvl(v_data_prev_fim, data_prev_fim)
     WHERE job_id = v_job_id;
   
   END IF;
   --
   IF v_flag_data_apre_cli = 'N' AND v_cod_objeto = 'DATA_APR_CLI' THEN
    -- nao se usa a data de apresentacao cliente da tabela job.
    -- Instancia data no job.
    v_data_pri_aprov := v_data_planej_fim;
    --
    UPDATE job
       SET data_pri_aprov = nvl(v_data_pri_aprov, data_pri_aprov)
     WHERE job_id = v_job_id;
   
   END IF;
   --
   ------------------------------------------------------------
   -- processamento das alocacoes
   ------------------------------------------------------------  
   IF v_data_planej_ini_old < v_data_planej_ini THEN
    v_data_planej_ini := v_data_planej_ini_old;
   END IF;
   --
   IF v_data_planej_fim_old > v_data_planej_fim THEN
    v_data_planej_fim := v_data_planej_fim_old;
   END IF;
   --
   FOR r_ic IN c_ic
   LOOP
    cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                          p_empresa_id,
                                          r_ic.usuario_id,
                                          v_data_planej_ini,
                                          v_data_planej_fim,
                                          p_erro_cod,
                                          p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END LOOP;
  
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacoes finais das datas
  ------------------------------------------------------------
  IF v_flag_periodo_job = 'N' THEN
   -- nao se usa o periodo da tabela job. Instancia datas no job.
   SELECT MIN(data_planej_ini)
     INTO v_data_prev_ini
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id;
   --
   UPDATE job
      SET data_prev_ini = nvl(v_data_prev_ini, data_prev_ini)
    WHERE job_id = v_job_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Replanejamento (datas)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_cronograma_id,
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
 END datas_replanejar;
 --
 --
 PROCEDURE seq_renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: subrotina que renumera a sequencia e o nivel dos itens do CRONOGRAMA. 
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/09/2016  Renumera primeiro os planejados e depois os nao planejados 
  -- Silvia            07/02/2020  Renumera tudo junto (planejado + nao planejado)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_num_seq   item_crono.num_seq%TYPE;
  --
  CURSOR c_ic1 IS
   SELECT item_crono_id,
          LEVEL
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
    START WITH item_crono_pai_id IS NULL
   CONNECT BY PRIOR item_crono_id = item_crono_pai_id ORDER SIBLINGS BY ordem;
  --
  /*
    CURSOR c_ic1 IS
      SELECT item_crono_id,
             LEVEL
        FROM item_crono
       WHERE cronograma_id = p_cronograma_id
         AND flag_planejado = 'S'
       START WITH item_crono_pai_id IS NULL
     CONNECT BY PRIOR  item_crono_id = item_crono_pai_id
       ORDER SIBLINGS BY ordem;
  --
    CURSOR c_ic2 IS
      SELECT item_crono_id,
             LEVEL
        FROM item_crono
       WHERE cronograma_id = p_cronograma_id
         AND flag_planejado = 'N'
       START WITH item_crono_pai_id IS NULL
     CONNECT BY PRIOR  item_crono_id = item_crono_pai_id
       ORDER SIBLINGS BY ordem;
  */
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_num_seq := 0;
  --
  FOR r_ic1 IN c_ic1
  LOOP
   v_num_seq := v_num_seq + 1;
   --
   UPDATE item_crono
      SET num_seq = v_num_seq,
          nivel   = r_ic1.level
    WHERE item_crono_id = r_ic1.item_crono_id;
  
  END LOOP;
  --
  /*
    FOR r_ic2 IN c_ic2 LOOP
       v_num_seq := v_num_seq + 1;
       --
       UPDATE item_crono
          SET num_seq = v_num_seq,
              nivel = r_ic2.LEVEL
        WHERE item_crono_id = r_ic2.item_crono_id;
    END LOOP;
  */
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
  
 END seq_renumerar;
 --
 --
 PROCEDURE ordem_renumerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: subrotina que renumera a ordem dos itens do CRONOGRAMA. 
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/09/2016  Ordenacao direta pelo num_seq (sem CONNECT BY).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cronograma_id     IN item_crono.cronograma_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_ordem     item_crono.ordem%TYPE;
  --
  CURSOR c_ic IS
   SELECT item_crono_id
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
    ORDER BY num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_ordem := 0;
  --
  FOR r_ic IN c_ic
  LOOP
   v_ordem := v_ordem + 100000;
   --
   UPDATE item_crono
      SET ordem = v_ordem
    WHERE item_crono_id = r_ic.item_crono_id;
  
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
  
 END ordem_renumerar;
 --
 --
 PROCEDURE num_gantt_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 05/03/2020
  -- DESCRICAO: subrotina que preenche a coluna num_gantt dos itens do CRONOGRAMA. 
  --  NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_cronograma_id IN item_crono.cronograma_id%TYPE,
  p_erro_cod      OUT VARCHAR2,
  p_erro_msg      OUT VARCHAR2
 ) IS
 
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_num_p1    NUMBER(5);
  v_num_p2    NUMBER(5);
  v_num_p3    NUMBER(5);
  v_num_p4    NUMBER(5);
  v_num_p5    NUMBER(5);
  v_num_p6    NUMBER(5);
  v_num_p7    NUMBER(5);
  v_num_p8    NUMBER(5);
  v_num_p9    NUMBER(5);
  v_num_p10   NUMBER(5);
  v_num_p11   NUMBER(5);
  v_num_p12   NUMBER(5);
  v_num_gantt VARCHAR2(50);
  --
  CURSOR c_ic IS
   SELECT item_crono_id,
          item_crono_pai_id,
          nivel
     FROM item_crono
    WHERE cronograma_id = p_cronograma_id
    ORDER BY num_seq;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_num_p1  := 0;
  v_num_p2  := 0;
  v_num_p3  := 0;
  v_num_p4  := 0;
  v_num_p5  := 0;
  v_num_p6  := 0;
  v_num_p7  := 0;
  v_num_p8  := 0;
  v_num_p9  := 0;
  v_num_p10 := 0;
  v_num_p11 := 0;
  v_num_p12 := 0;
  --
  FOR r_ic IN c_ic
  LOOP
   IF r_ic.nivel = 1 THEN
    v_num_p2  := 0;
    v_num_p3  := 0;
    v_num_p4  := 0;
    v_num_p5  := 0;
    v_num_p6  := 0;
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 2 THEN
    v_num_p3  := 0;
    v_num_p4  := 0;
    v_num_p5  := 0;
    v_num_p6  := 0;
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 3 THEN
    v_num_p4  := 0;
    v_num_p5  := 0;
    v_num_p6  := 0;
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 4 THEN
    v_num_p5  := 0;
    v_num_p6  := 0;
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 5 THEN
    v_num_p6  := 0;
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 6 THEN
    v_num_p7  := 0;
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 7 THEN
    v_num_p8  := 0;
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 8 THEN
    v_num_p9  := 0;
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 9 THEN
    v_num_p10 := 0;
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 10 THEN
    v_num_p11 := 0;
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 11 THEN
    v_num_p12 := 0;
   END IF;
   --
   IF r_ic.nivel = 1 THEN
    v_num_p1    := v_num_p1 + 1;
    v_num_gantt := to_char(v_num_p1);
   END IF;
   --
   IF r_ic.nivel = 2 THEN
    v_num_p2    := v_num_p2 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2);
   END IF;
   --
   IF r_ic.nivel = 3 THEN
    v_num_p3    := v_num_p3 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3);
   
   END IF;
   --
   IF r_ic.nivel = 4 THEN
    v_num_p4    := v_num_p4 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4);
   
   END IF;
   --
   IF r_ic.nivel = 5 THEN
    v_num_p5    := v_num_p5 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5);
   
   END IF;
   --
   IF r_ic.nivel = 6 THEN
    v_num_p6    := v_num_p6 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6);
   
   END IF;
   --
   IF r_ic.nivel = 7 THEN
    v_num_p7    := v_num_p7 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7);
   
   END IF;
   --
   IF r_ic.nivel = 8 THEN
    v_num_p8    := v_num_p8 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7) || '.' || to_char(v_num_p8);
   
   END IF;
   --
   IF r_ic.nivel = 9 THEN
    v_num_p9    := v_num_p9 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7) || '.' || to_char(v_num_p8) || '.' || to_char(v_num_p9);
   
   END IF;
   --
   IF r_ic.nivel = 10 THEN
    v_num_p10   := v_num_p10 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7) || '.' || to_char(v_num_p8) || '.' || to_char(v_num_p9) || '.' ||
                   to_char(v_num_p10);
   
   END IF;
   --
   IF r_ic.nivel = 11 THEN
    v_num_p11   := v_num_p11 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7) || '.' || to_char(v_num_p8) || '.' || to_char(v_num_p9) || '.' ||
                   to_char(v_num_p10) || '.' || to_char(v_num_p11);
   
   END IF;
   --
   IF r_ic.nivel = 12 THEN
    v_num_p12   := v_num_p12 + 1;
    v_num_gantt := to_char(v_num_p1) || '.' || to_char(v_num_p2) || '.' || to_char(v_num_p3) || '.' ||
                   to_char(v_num_p4) || '.' || to_char(v_num_p5) || '.' || to_char(v_num_p6) || '.' ||
                   to_char(v_num_p7) || '.' || to_char(v_num_p8) || '.' || to_char(v_num_p9) || '.' ||
                   to_char(v_num_p10) || '.' || to_char(v_num_p11) || '.' || to_char(v_num_p12);
   
   END IF;
   --
   UPDATE item_crono
      SET num_gantt = v_num_gantt
    WHERE item_crono_id = r_ic.item_crono_id;
  
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
  
 END num_gantt_processar;
 --
 --
 PROCEDURE info_pre_retornar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 23/05/2016
  -- DESCRICAO: retorna informacoes da atividade/objeto predecessor.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_cod_objeto        IN objeto_crono.cod_objeto%TYPE,
  p_objeto_id         IN NUMBER,
  p_nome_ativ_pre     OUT VARCHAR2,
  p_cod_objeto_pre    OUT VARCHAR2,
  p_nome_objeto_pre   OUT VARCHAR2,
  p_status_objeto_pre OUT VARCHAR2,
  p_objeto_pre_id     OUT NUMBER,
  p_data_fim_pre      OUT VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                INTEGER;
  v_exception         EXCEPTION;
  v_saida             EXCEPTION;
  v_item_crono_id     item_crono.item_crono_id%TYPE;
  v_item_crono_pre_id item_crono.item_crono_id%TYPE;
  v_cod_objeto_pre    item_crono.cod_objeto%TYPE;
  v_objeto_pre_id     item_crono.objeto_id%TYPE;
  v_nome_ativ_pre     item_crono.nome%TYPE;
  v_data_fim_pre      item_crono.data_planej_fim%TYPE;
  v_job_id            cronograma.job_id%TYPE;
  v_nome_objeto_pre   VARCHAR2(200);
  v_num_objeto_pre    VARCHAR2(50);
  v_status_objeto_pre VARCHAR2(100);
  v_status_cod        VARCHAR2(50);
  v_tipo_doc          tipo_documento.nome%TYPE;
  --
 BEGIN
  v_qt            := 0;
  p_objeto_pre_id := 0;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  --
  IF p_cod_objeto IS NULL OR nvl(p_objeto_id, 0) = 0 THEN
   RAISE v_saida;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM objeto_crono
   WHERE cod_objeto = p_cod_objeto;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do objeto inválido (' || p_cod_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  -- verifica se existe algum item do cronograma atual que faz referencia
  -- ao objeto (p.ex. ORDEM_SERVICO / ordem_servico_id).
  SELECT MAX(ic.item_crono_id),
         MAX(cr.job_id)
    INTO v_item_crono_id,
         v_job_id
    FROM item_crono ic,
         cronograma cr
   WHERE ic.cod_objeto = p_cod_objeto
     AND ic.objeto_id = p_objeto_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.status <> 'ARQUI';
  --
  IF v_item_crono_id IS NULL THEN
   -- objeto nao referenciado no cronograma
   RAISE v_saida;
  END IF;
  --
  -- verifica se esse item do cronograma tem dependencia de outro
  SELECT MAX(item_crono_pre_id)
    INTO v_item_crono_pre_id
    FROM item_crono_pre
   WHERE item_crono_id = v_item_crono_id;
  --
  IF v_item_crono_pre_id IS NULL THEN
   -- nao existe dependencia
   RAISE v_saida;
  END IF;
  --
  -- recupera informacoes do objeto predecessor
  SELECT ic.cod_objeto,
         ic.objeto_id,
         oc.nome,
         ic.nome,
         ic.data_planej_fim
    INTO v_cod_objeto_pre,
         v_objeto_pre_id,
         v_nome_objeto_pre,
         v_nome_ativ_pre,
         v_data_fim_pre
    FROM item_crono   ic,
         objeto_crono oc
   WHERE ic.item_crono_id = v_item_crono_pre_id
     AND ic.cod_objeto = oc.cod_objeto(+);
  --  
  IF v_nome_objeto_pre IS NULL THEN
   RAISE v_saida;
  END IF;
  --
  -- recupera informacoes complementares
  IF v_cod_objeto_pre = 'ORDEM_SERVICO' THEN
   SELECT MAX(status)
     INTO v_status_cod
     FROM ordem_servico
    WHERE ordem_servico_id = v_objeto_pre_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := util_pkg.desc_retornar('status_os', v_status_cod);
    v_num_objeto_pre    := ordem_servico_pkg.numero_formatar2(v_objeto_pre_id);
    v_nome_objeto_pre   := v_nome_objeto_pre || ' ' || v_num_objeto_pre;
   END IF;
  
  ELSIF v_cod_objeto_pre = 'ORCAMENTO' THEN
   SELECT MAX(status)
     INTO v_status_cod
     FROM orcamento
    WHERE orcamento_id = v_objeto_pre_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := util_pkg.desc_retornar('status_orcam', v_status_cod);
    v_num_objeto_pre    := orcamento_pkg.numero_formatar2(v_objeto_pre_id);
    v_nome_objeto_pre   := v_nome_objeto_pre || ' ' || v_num_objeto_pre;
   END IF;
  
  ELSIF v_cod_objeto_pre = 'TAREFA' THEN
   SELECT MAX(status)
     INTO v_status_cod
     FROM tarefa
    WHERE tarefa_id = v_objeto_pre_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := util_pkg.desc_retornar('status_tarefa', v_status_cod);
   END IF;
  
  ELSIF v_cod_objeto_pre = 'BRIEFING' THEN
   IF v_objeto_pre_id IS NULL THEN
    SELECT MAX(briefing_id)
      INTO v_objeto_pre_id
      FROM briefing
     WHERE job_id = v_job_id;
   
   END IF;
   --
   SELECT MAX(status)
     INTO v_status_cod
     FROM briefing
    WHERE briefing_id = v_objeto_pre_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := nvl(util_pkg.desc_retornar('status_brief', v_status_cod), 'Não iniciado');
   END IF;
  
  ELSIF v_cod_objeto_pre = 'JOB_HORAS' THEN
   SELECT MAX(status_horas)
     INTO v_status_cod
     FROM job
    WHERE job_id = v_job_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := nvl(util_pkg.desc_retornar('status_job_horas', v_status_cod),
                               'Não iniciado');
   END IF;
  
  ELSIF v_cod_objeto_pre = 'CRONOGRAMA' THEN
   SELECT MAX(status)
     INTO v_status_cod
     FROM cronograma
    WHERE cronograma_id = v_objeto_pre_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := util_pkg.desc_retornar('status_crono', v_status_cod);
   END IF;
  
  ELSIF v_cod_objeto_pre = 'DOCUMENTO' THEN
   SELECT MAX(dc.status),
          MAX(td.nome)
     INTO v_status_cod,
          v_tipo_doc
     FROM documento      dc,
          tipo_documento td
    WHERE dc.documento_id = v_objeto_pre_id
      AND dc.tipo_documento_id = td.tipo_documento_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := documento_pkg.status_retornar(v_objeto_pre_id);
    v_nome_objeto_pre   := v_nome_objeto_pre || ' ' || v_tipo_doc;
   END IF;
  
  ELSIF v_cod_objeto_pre = 'JOB_CONC' THEN
   SELECT MAX(status)
     INTO v_status_cod
     FROM job
    WHERE job_id = v_job_id;
   --
   IF v_status_cod IS NOT NULL THEN
    v_status_objeto_pre := util_pkg.desc_retornar('status_job', v_status_cod);
   END IF;
  
  ELSIF v_cod_objeto_pre = 'CHECKIN_CONC' THEN
   SELECT MAX(status_checkin)
     INTO v_status_cod
     FROM job
    WHERE job_id = v_job_id;
   --
   IF v_status_cod IS NOT NULL THEN
    IF v_status_cod = 'A' THEN
     v_status_objeto_pre := 'Aberto';
    ELSE
     v_status_objeto_pre := 'Fechado';
    END IF;
   
   END IF;
  
  ELSIF v_cod_objeto_pre = 'FATUR_CONC' THEN
   SELECT MAX(status_fatur)
     INTO v_status_cod
     FROM job
    WHERE job_id = v_job_id;
   --
   IF v_status_cod IS NOT NULL THEN
    IF v_status_cod = 'A' THEN
     v_status_objeto_pre := 'Aberto';
    ELSE
     v_status_objeto_pre := 'Fechado';
    END IF;
   
   END IF;
  
  END IF;
  --
  p_nome_ativ_pre     := v_nome_ativ_pre;
  p_nome_objeto_pre   := v_nome_objeto_pre;
  p_cod_objeto_pre    := v_cod_objeto_pre;
  p_status_objeto_pre := nvl(v_status_objeto_pre, 'Não demandado');
  p_objeto_pre_id     := v_objeto_pre_id;
  p_data_fim_pre      := data_mostrar(v_data_fim_pre);
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   NULL;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
 END info_pre_retornar;
 --
 --
 PROCEDURE usuario_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/12/2019
  -- DESCRICAO: Subrotina de Inclusao de usuario no item do CRONOGRAMA (nao usada via web)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2020  Tratamento de TAREFA
  -- Ana Luiza         18/07/2023  Retirado arredondamento de horas_darias.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_item_crono_id     IN item_crono_usu.item_crono_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_job      job.numero%TYPE;
  v_job_id          job.job_id%TYPE;
  v_status_job      job.status%TYPE;
  v_num_crono       cronograma.numero%TYPE;
  v_cronograma_id   cronograma.cronograma_id%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_nome_usu        pessoa.apelido%TYPE;
  v_nome_item       item_crono.nome%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_cod_objeto      item_crono.cod_objeto%TYPE;
  v_objeto_id       item_crono.objeto_id%TYPE;
  v_horas_diarias   item_crono_usu.horas_diarias%TYPE;
  v_horas_totais    item_crono_usu.horas_totais%TYPE;
  v_horas_planej    os_usuario.horas_planej%TYPE;
  v_duracao         NUMBER(20);
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.data_planej_ini,
         ic.data_planej_fim,
         ic.cod_objeto,
         ic.objeto_id
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_data_planej_ini,
         v_data_planej_fim,
         v_cod_objeto,
         v_objeto_id
    FROM job        jo,
         tipo_job   ti,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  IF p_flag_commit = 'S' THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  v_horas_planej  := 0;
  v_horas_diarias := 0;
  v_horas_totais  := 0;
  v_duracao       := nvl(cronograma_pkg.item_duracao_retornar(p_usuario_sessao_id, p_item_crono_id),
                         0);
  -- 
  IF v_cod_objeto = 'ORDEM_SERVICO' THEN
   SELECT nvl(MAX(horas_planej), 0)
     INTO v_horas_planej
     FROM os_usuario
    WHERE ordem_servico_id = v_objeto_id
      AND usuario_id = p_usuario_id
      AND tipo_ender = 'EXE';
   --
   v_horas_totais := v_horas_planej;
   IF v_duracao > 0 THEN
    --ALCBO_180723
    v_horas_diarias := v_horas_totais / v_duracao;
   ELSE
    v_horas_diarias := v_horas_totais;
   END IF;
  
  ELSIF v_cod_objeto = 'TAREFA' THEN
   SELECT nvl(MAX(horas_totais), 0)
     INTO v_horas_totais
     FROM tarefa_usuario
    WHERE tarefa_id = v_objeto_id
      AND usuario_para_id = p_usuario_id;
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_usu
   WHERE item_crono_id = p_item_crono_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt = 0 THEN
   INSERT INTO item_crono_usu
    (item_crono_id,
     usuario_id,
     horas_diarias,
     horas_totais)
   VALUES
    (p_item_crono_id,
     p_usuario_id,
     v_horas_diarias,
     v_horas_totais);
  
  ELSIF v_cod_objeto IN ('ORDEM_SERVICO', 'TAREFA') THEN
   UPDATE item_crono_usu
      SET horas_diarias = v_horas_diarias,
          horas_totais  = v_horas_totais
    WHERE item_crono_id = p_item_crono_id
      AND usuario_id = p_usuario_id;
  
  END IF;
  --
  cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        p_usuario_id,
                                        v_data_planej_ini,
                                        v_data_planej_fim,
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
  /*
    v_identif_objeto := TO_CHAR(v_numero_job) || '/' || TO_CHAR(v_num_crono);
    v_compl_histor := 'Inclusão do usuário ' || v_nome_usu || ' no item ' || v_nome_item;
    --
    evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CRONOGRAMA', 'ALTERAR',
                     v_identif_objeto, v_cronograma_id, v_compl_histor, NULL,
                     'N', NULL, NULL,
                     v_historico_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
    END IF;
  */
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
 END usuario_adicionar;
 --
 --
 PROCEDURE usuario_horas_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/12/2019
  -- DESCRICAO: Atualizacao das horas diarias dos usuarios do item do CRONOGRAMA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/01/2020  Chamada da alocacao_usu_processar.
  -- Silvia            13/04/2020  Retirada do teste de privilegio.
  -- Ana Luiza         18/07/2023  Retirado arredondamento de horas_darias.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_item_crono_id       IN item_crono_usu.item_crono_id%TYPE,
  p_vetor_usuario_id    IN VARCHAR2,
  p_vetor_horas_diarias IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
 
  v_qt                       INTEGER;
  v_exception                EXCEPTION;
  v_numero_job               job.numero%TYPE;
  v_job_id                   job.job_id%TYPE;
  v_status_job               job.status%TYPE;
  v_flag_restringe_alt_crono job.flag_restringe_alt_crono%TYPE;
  v_num_crono                cronograma.numero%TYPE;
  v_cronograma_id            cronograma.cronograma_id%TYPE;
  v_cod_objeto               item_crono.cod_objeto%TYPE;
  v_objeto_id                item_crono.objeto_id%TYPE;
  v_identif_objeto           historico.identif_objeto%TYPE;
  v_compl_histor             historico.complemento%TYPE;
  v_historico_id             historico.historico_id%TYPE;
  v_lbl_job                  VARCHAR2(100);
  v_nome_item                item_crono.nome%TYPE;
  v_data_planej_ini          item_crono.data_planej_ini%TYPE;
  v_data_planej_fim          item_crono.data_planej_fim%TYPE;
  v_flag_planejado           item_crono.flag_planejado%TYPE;
  v_nome_usu                 pessoa.apelido%TYPE;
  v_vetor_usuario_id         LONG;
  v_vetor_horas_diarias      LONG;
  v_delimitador              CHAR(1);
  v_usuario_id               item_crono_usu.usuario_id%TYPE;
  v_horas_diarias            item_crono_usu.horas_diarias%TYPE;
  v_horas_totais             item_crono_usu.horas_totais%TYPE;
  v_horas_diarias_char       VARCHAR2(20);
  v_duracao                  NUMBER(20);
  v_numero_os_char           VARCHAR2(50);
  v_tipo_os_desc             tipo_os.nome%TYPE;
  --
  CURSOR c_us IS
   SELECT usuario_id,
          controle
     FROM item_crono_usu
    WHERE item_crono_id = p_item_crono_id;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         jo.flag_restringe_alt_crono,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.data_planej_ini,
         ic.data_planej_fim,
         ic.cod_objeto,
         ic.objeto_id,
         ic.flag_planejado
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_flag_restringe_alt_crono,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_data_planej_ini,
         v_data_planej_fim,
         v_cod_objeto,
         v_objeto_id,
         v_flag_planejado
    FROM job        jo,
         tipo_job   ti,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  /*
    -- verifica se o usuario tem privilegio
    IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'CRONO_C',v_job_id,NULL,p_empresa_id) <> 1 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
       RAISE v_exception;
    END IF;
  */
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  v_duracao := nvl(cronograma_pkg.item_duracao_retornar(p_usuario_sessao_id, p_item_crono_id), 0);
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  UPDATE item_crono_usu
     SET controle = 'DEL'
   WHERE item_crono_id = p_item_crono_id;
  --
  v_delimitador         := '|';
  v_vetor_usuario_id    := p_vetor_usuario_id;
  v_vetor_horas_diarias := p_vetor_horas_diarias;
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_id         := nvl(to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador)), 0);
   v_horas_diarias_char := prox_valor_retornar(v_vetor_horas_diarias, v_delimitador);
   --
   SELECT MAX(apelido)
     INTO v_nome_usu
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
   --
   IF v_nome_usu IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF numero_validar(v_horas_diarias_char) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (' || v_horas_diarias_char || ').';
    RAISE v_exception;
   END IF;
   --ALCBO_180723
   v_horas_diarias := nvl(numero_converter(v_horas_diarias_char), 0);
   --
   IF v_horas_diarias < 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Número de horas inválido (' || v_horas_diarias_char || ').';
    RAISE v_exception;
   END IF;
   --
   v_horas_totais := v_horas_diarias * v_duracao;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM item_crono_usu
    WHERE item_crono_id = p_item_crono_id
      AND usuario_id = v_usuario_id;
   --
   IF v_qt > 0 THEN
    UPDATE item_crono_usu
       SET horas_diarias = v_horas_diarias,
           horas_totais  = v_horas_totais,
           controle      = NULL
     WHERE item_crono_id = p_item_crono_id
       AND usuario_id = v_usuario_id;
   
   ELSE
    INSERT INTO item_crono_usu
     (item_crono_id,
      usuario_id,
      horas_diarias,
      horas_totais)
    VALUES
     (p_item_crono_id,
      v_usuario_id,
      v_horas_diarias,
      v_horas_totais);
   
   END IF;
  
  END LOOP; -- fim do loop por usuario
  --
  ------------------------------------------------------------
  -- replica usuarios executores para a OS ou TAREFA
  ------------------------------------------------------------
  IF v_flag_restringe_alt_crono = 'S' AND v_flag_planejado = 'S' AND
     v_cod_objeto IN ('ORDEM_SERVICO', 'TAREFA') AND v_objeto_id IS NOT NULL THEN
   cronograma_pkg.executores_replicar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      p_item_crono_id,
                                      'ALT_EXEC_CRONO',
                                      p_erro_cod,
                                      p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- processa dia_alocacao para todos os usuarios envolvidos
  ------------------------------------------------------------
  FOR r_us IN c_us
  LOOP
   v_usuario_id := r_us.usuario_id;
   --
   IF r_us.controle = 'DEL' THEN
    DELETE FROM item_crono_usu
     WHERE item_crono_id = p_item_crono_id
       AND usuario_id = v_usuario_id;
   
   END IF;
   --
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_usuario_id,
                                         v_data_planej_ini,
                                         v_data_planej_fim,
                                         p_erro_cod,
                                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job) || '/' || to_char(v_num_crono);
  v_compl_histor   := 'Alteração de horas diárias do item ' || v_nome_item;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'CRONOGRAMA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_cronograma_id,
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
 END usuario_horas_atualizar;
 --
 --
 PROCEDURE usuario_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 11/12/2019
  -- DESCRICAO: Subrotina de Exclusao de usuario do item do CRONOGRAMA (nao usada via web)
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            14/01/2020  Chamada da alocacao_usu_processar.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_item_crono_id     IN item_crono_usu.item_crono_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_numero_job      job.numero%TYPE;
  v_job_id          job.job_id%TYPE;
  v_status_job      job.status%TYPE;
  v_num_crono       cronograma.numero%TYPE;
  v_cronograma_id   cronograma.cronograma_id%TYPE;
  v_cod_objeto      item_crono.cod_objeto%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_lbl_job         VARCHAR2(100);
  v_nome_usu        pessoa.apelido%TYPE;
  v_nome_item       item_crono.nome%TYPE;
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
    FROM cronograma cr,
         job        jo,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse item não existe (' || to_char(p_item_crono_id) || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.job_id,
         jo.status,
         cr.numero,
         cr.cronograma_id,
         ic.nome,
         ic.data_planej_ini,
         ic.data_planej_fim
    INTO v_numero_job,
         v_job_id,
         v_status_job,
         v_num_crono,
         v_cronograma_id,
         v_nome_item,
         v_data_planej_ini,
         v_data_planej_fim
    FROM job        jo,
         tipo_job   ti,
         cronograma cr,
         item_crono ic
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id
     AND jo.tipo_job_id = ti.tipo_job_id;
  --
  IF p_flag_commit = 'S' THEN
   -- verifica se o usuario tem privilegio
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'CRONO_C', v_job_id, NULL, p_empresa_id) <> 1 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF v_status_job NOT IN ('ANDA', 'PREP') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(apelido)
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_usu
   WHERE item_crono_id = p_item_crono_id
     AND usuario_id = p_usuario_id;
  --
  IF v_qt > 0 THEN
   DELETE FROM item_crono_usu
    WHERE item_crono_id = p_item_crono_id
      AND usuario_id = p_usuario_id;
   --
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         p_usuario_id,
                                         v_data_planej_ini,
                                         v_data_planej_fim,
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
  /*
    v_identif_objeto := TO_CHAR(v_numero_job) || '/' || TO_CHAR(v_num_crono);
    v_compl_histor := 'Exclusão do usuário ' || v_nome_usu || ' do item ' || v_nome_item;
    --
    evento_pkg.gerar(p_usuario_sessao_id, p_empresa_id, 'CRONOGRAMA', 'ALTERAR',
                     v_identif_objeto, v_cronograma_id, v_compl_histor, NULL,
                     'N', NULL, NULL,
                     v_historico_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000' THEN
       RAISE v_exception;
    END IF;
  */
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
 END usuario_excluir;
 --
 --
 PROCEDURE alocacao_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 05/03/2020
  -- DESCRICAO: completa a tabela de alocacao com horas livres de todos os usuarios (chamada 
  --  via job SISTEMA_PKG.JOBS_DIARIOS_EXECUTAR).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  IS
 
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_erro_cod        VARCHAR2(20);
  v_erro_msg        VARCHAR2(200);
  v_data_atual      DATE;
  v_data_max        DATE;
  v_data_aux        DATE;
  v_mes             dia_alocacao.mes%TYPE;
  v_ano             dia_alocacao.ano%TYPE;
  v_dia_semana      dia_alocacao.dia_semana%TYPE;
  v_horas_diarias   dia_alocacao.horas_diarias%TYPE;
  v_horas_total     dia_alocacao.horas_total%TYPE;
  v_horas_reservado dia_alocacao.horas_reservado%TYPE;
  v_horas_alocado   dia_alocacao.horas_alocado%TYPE;
  v_horas_ausencia  dia_alocacao.horas_ausencia%TYPE;
  v_horas_overtime  dia_alocacao.horas_overtime%TYPE;
  v_horas_livre     dia_alocacao.horas_livre%TYPE;
  --
  CURSOR c_usu IS
   SELECT us.usuario_id,
          usuario_pkg.empresa_padrao_retornar(us.usuario_id) AS empresa_pdr_id,
          nvl(num_horas_prod_dia, 0) AS horas_diarias
     FROM usuario us
    WHERE us.flag_ativo = 'S';
  --
 BEGIN
  v_data_atual := trunc(SYSDATE);
  --
  -- pega a maior data de termino dos contratos vigentes
  SELECT MAX(data_termino)
    INTO v_data_max
    FROM contrato
   WHERE status = 'ANDA'
     AND data_termino >= v_data_atual;
  --
  -- pega a maior data de termino dos contratos vigentes
  SELECT MAX(data_prev_fim)
    INTO v_data_aux
    FROM job
   WHERE status IN ('ANDA', 'CONC')
     AND data_prev_fim >= v_data_atual;
  --
  -- pega a maior data das duas
  IF v_data_aux > v_data_max OR v_data_max IS NULL THEN
   v_data_max := v_data_aux;
  END IF;
  --
  v_data_aux := v_data_atual;
  --
  -- loop por data
  WHILE v_data_aux <= v_data_max
  LOOP
   -- loop por usuario
   FOR r_usu IN c_usu
   LOOP
    IF feriado_pkg.dia_util_verificar(r_usu.usuario_id, v_data_aux, 'S') = 1 THEN
     SELECT COUNT(*)
       INTO v_qt
       FROM dia_alocacao
      WHERE usuario_id = r_usu.usuario_id
        AND data = v_data_aux;
     --
     IF v_qt = 0 THEN
      v_mes        := to_number(to_char(v_data_aux, 'MM'));
      v_ano        := to_number(to_char(v_data_aux, 'YYYY'));
      v_dia_semana := upper(dia_semana_mostrar(v_data_aux, 'N'));
      --
      v_horas_diarias := r_usu.horas_diarias;
      --
      IF v_horas_diarias = 0 THEN
       v_horas_diarias := nvl(numero_converter(empresa_pkg.parametro_retornar(r_usu.empresa_pdr_id,
                                                                              'NUM_HORAS_PRODUTIVAS')),
                              0);
      END IF;
      --
      v_horas_total     := 0;
      v_horas_reservado := 0;
      v_horas_alocado   := 0;
      v_horas_ausencia  := 0;
      v_horas_overtime  := 0;
      v_horas_livre     := v_horas_diarias;
      --
      INSERT INTO dia_alocacao
       (dia_alocacao_id,
        usuario_id,
        data,
        mes,
        ano,
        dia_semana,
        horas_diarias,
        horas_total,
        horas_reservado,
        horas_alocado,
        horas_ausencia,
        horas_overtime,
        horas_livre)
      VALUES
       (seq_dia_alocacao.nextval,
        r_usu.usuario_id,
        v_data_aux,
        v_mes,
        v_ano,
        v_dia_semana,
        v_horas_diarias,
        v_horas_total,
        v_horas_reservado,
        v_horas_alocado,
        v_horas_ausencia,
        v_horas_overtime,
        v_horas_livre);
     
     END IF;
    
    END IF;
   END LOOP; -- fim do loop por usuario
   --
   v_data_aux := v_data_aux + 1;
  END LOOP; -- fim do loop por data
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
     'cronograma_pkg.alocacao_processar',
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
     'cronograma_pkg.alocacao_processar',
     v_erro_cod,
     v_erro_msg);
  
   COMMIT;
 END alocacao_processar;
 --
 --
 PROCEDURE alocacao_usu_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 09/01/2020
  -- DESCRICAO: subrotina de processamento das horas alocacadas do usuario.
  --   NAO FAZ COMMIT
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/08/2021  Troca de horas apontadas para horas produtivas
  -- Silvia            22/12/2021  Simplificacao do calculo de horas alocadas (nao leva
  --                               em conta a data de execucao)
  -- Silvia            24/01/2022  Nao contabiliza OS e TAREFA canceladas
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_usuario_id        IN item_crono_usu.usuario_id%TYPE,
  p_data_ini          IN DATE,
  p_data_fim          IN DATE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
 
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_saida                 EXCEPTION;
  v_nome_usu              pessoa.apelido%TYPE;
  v_dia_alocacao_id       dia_alocacao.dia_alocacao_id%TYPE;
  v_horas_diarias         dia_alocacao.horas_diarias%TYPE;
  v_horas_diarias_usu     dia_alocacao.horas_diarias%TYPE;
  v_horas_total           dia_alocacao.horas_total%TYPE;
  v_horas_reservado       dia_alocacao.horas_reservado%TYPE;
  v_horas_alocado         dia_alocacao.horas_alocado%TYPE;
  v_horas_alocado_os1     dia_alocacao.horas_alocado%TYPE;
  v_horas_alocado_os2     dia_alocacao.horas_alocado%TYPE;
  v_horas_alocado_tarefa1 dia_alocacao.horas_alocado%TYPE;
  v_horas_alocado_tarefa2 dia_alocacao.horas_alocado%TYPE;
  v_horas_ausencia        dia_alocacao.horas_ausencia%TYPE;
  v_horas_overtime        dia_alocacao.horas_overtime%TYPE;
  v_horas_livre           dia_alocacao.horas_livre%TYPE;
  v_mes                   dia_alocacao.mes%TYPE;
  v_ano                   dia_alocacao.ano%TYPE;
  v_dia_semana            dia_alocacao.dia_semana%TYPE;
  v_flag_ausencia_full    dia_alocacao.flag_ausencia_full%TYPE;
  v_empresa_pdr_id        empresa.empresa_id%TYPE;
  v_data                  DATE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT MAX(apelido)
    INTO v_nome_usu
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_nome_usu IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário não existe (' || to_char(p_usuario_id) || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_data_ini IS NULL OR p_data_fim IS NULL THEN
   -- sai sem processar
   RAISE v_saida;
  END IF;
  --
  v_empresa_pdr_id := usuario_pkg.empresa_padrao_retornar(p_usuario_id);
  --
  ------------------------------------------------------------
  -- verifica quantas horas diarias o usuario deve trabalhar.
  -- se a empresa padrao nao for a mesma da empresa da alocacao,
  -- pega o maior valor.
  ------------------------------------------------------------
  SELECT nvl(num_horas_prod_dia, 0)
    INTO v_horas_diarias_usu
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  IF v_horas_diarias_usu = 0 THEN
   v_horas_diarias_usu := nvl(numero_converter(empresa_pkg.parametro_retornar(v_empresa_pdr_id,
                                                                              'NUM_HORAS_PRODUTIVAS')),
                              0);
   --
   IF p_empresa_id <> v_empresa_pdr_id THEN
    IF nvl(numero_converter(empresa_pkg.parametro_retornar(p_empresa_id, 'NUM_HORAS_PRODUTIVAS')),
           0) > v_horas_diarias_usu THEN
     v_horas_diarias_usu := nvl(numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                                'NUM_HORAS_PRODUTIVAS')),
                                0);
    
    END IF;
   
   END IF;
  
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM dia_alocacao
   WHERE usuario_id = p_usuario_id
     AND data BETWEEN trunc(p_data_ini) AND trunc(p_data_fim);
  --
  v_data := trunc(p_data_ini);
  --
  WHILE v_data <= trunc(p_data_fim)
  LOOP
   IF feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 0 THEN
    -- nao eh dia util. Calcula como overtime.
    v_horas_diarias := 0;
    v_horas_livre   := 0; --ALCBO_021224
   ELSE
    v_horas_diarias := v_horas_diarias_usu;
   END IF;
   --
   v_horas_total           := 0;
   v_horas_reservado       := 0;
   v_horas_alocado         := 0;
   v_horas_alocado_os1     := 0;
   v_horas_alocado_os2     := 0;
   v_horas_alocado_tarefa1 := 0;
   v_horas_alocado_tarefa2 := 0;
   v_horas_ausencia        := 0;
   v_horas_overtime        := 0;
   v_horas_livre           := 0;
   --
   v_mes        := to_number(to_char(v_data, 'MM'));
   v_ano        := to_number(to_char(v_data, 'YYYY'));
   v_dia_semana := upper(dia_semana_mostrar(v_data, 'N'));
   --
   -- horas reservadas no cronograma
   SELECT nvl(SUM(iu.horas_diarias), 0)
     INTO v_horas_reservado
     FROM item_crono     ic,
          item_crono_usu iu,
          cronograma     cr
    WHERE iu.usuario_id = p_usuario_id
      AND iu.item_crono_id = ic.item_crono_id
      AND ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND v_data BETWEEN ic.data_planej_ini AND ic.data_planej_fim
      AND ic.objeto_id IS NULL;
   --
   -- horas alocadas diretamente na OS 
   SELECT nvl(SUM(od.horas), 0)
     INTO v_horas_alocado_os1
     FROM os_usuario_data od,
          ordem_servico   os
    WHERE od.usuario_id = p_usuario_id
      AND od.tipo_ender = 'EXE'
      AND od.data = v_data
      AND od.ordem_servico_id = os.ordem_servico_id
      AND os.status <> 'CANC';
   /*
   --
   -- horas alocadas diretamente na OS qdo a data de execucao for 
   -- maior ou igual a data de inicio
   SELECT NVL(SUM(od.horas),0)
     INTO v_horas_alocado_os1
     FROM os_usuario_data od,
          ordem_servico os
    WHERE od.usuario_id = p_usuario_id
      AND od.tipo_ender = 'EXE'
      AND od.data = v_data
      AND od.ordem_servico_id = os.ordem_servico_id
      AND NVL(TRUNC(os.data_execucao),v_data) >= TRUNC(os.data_inicio)
      AND NVL(TRUNC(os.data_execucao),v_data) >= v_data;
   --
   -- horas alocadas diretamente na OS qdo a data de execucao for 
   -- igual a data processada mas menor que a data de inicio 
   SELECT NVL(SUM(od.horas),0)
     INTO v_horas_alocado_os2
     FROM os_usuario_data od,
          ordem_servico os
    WHERE od.usuario_id = p_usuario_id
      AND od.tipo_ender = 'EXE'
      AND TRUNC(os.data_execucao) = v_data
      AND od.ordem_servico_id = os.ordem_servico_id
      AND TRUNC(os.data_execucao) < TRUNC(os.data_inicio);
   */
   --
   -- horas alocadas diretamente na TAREFA 
   SELECT nvl(SUM(td.horas), 0)
     INTO v_horas_alocado_tarefa1
     FROM tarefa_usuario_data td,
          tarefa              ta
    WHERE td.usuario_para_id = p_usuario_id
      AND td.data = v_data
      AND td.tarefa_id = ta.tarefa_id
      AND ta.status <> 'CANC';
   /*
   --
   -- horas alocadas diretamente na TAREFA qdo a data de execucao for 
   -- maior ou igual a data de inicio
   SELECT NVL(SUM(td.horas),0)
     INTO v_horas_alocado_tarefa1
     FROM tarefa_usuario_data td,
          tarefa ta
    WHERE td.usuario_para_id = p_usuario_id
      AND td.data = v_data
      AND td.tarefa_id = ta.tarefa_id
      AND NVL(TRUNC(ta.data_execucao),v_data) >= TRUNC(ta.data_inicio)
      AND NVL(TRUNC(ta.data_execucao),v_data) >= v_data;
   --
   -- horas alocadas diretamente na TAREFA qdo a data de execucao for 
   -- igual a data processada mas menor que a data de inicio
   SELECT NVL(SUM(td.horas),0)
     INTO v_horas_alocado_tarefa2
     FROM tarefa_usuario_data td,
          tarefa ta
    WHERE td.usuario_para_id = p_usuario_id
      AND td.data = v_data
      AND td.tarefa_id = ta.tarefa_id
      AND TRUNC(ta.data_execucao) < TRUNC(ta.data_inicio);
   */
   --
   SELECT nvl(SUM(ah.horas), 0),
          nvl(MAX(ta.flag_ausencia_full), 'N')
     INTO v_horas_ausencia,
          v_flag_ausencia_full
     FROM apontam_data ad,
          apontam_hora ah,
          tipo_apontam ta
    WHERE ad.usuario_id = p_usuario_id
      AND ad.data = v_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ta.tipo_apontam_id
      AND ta.flag_ausencia = 'S';
   --
   --
   v_horas_alocado := v_horas_alocado_os1 + v_horas_alocado_os2 + v_horas_alocado_tarefa1 +
                      v_horas_alocado_tarefa2;
   v_horas_total   := v_horas_reservado + v_horas_alocado + v_horas_ausencia;
   --
   IF v_horas_total > v_horas_diarias THEN
    v_horas_overtime := v_horas_total - v_horas_diarias;
   END IF;
   --
   IF v_horas_diarias > v_horas_total THEN
    v_horas_livre := v_horas_diarias - v_horas_total;
   END IF;
   --
   SELECT seq_dia_alocacao.nextval
     INTO v_dia_alocacao_id
     FROM dual;
   --
   INSERT INTO dia_alocacao
    (dia_alocacao_id,
     usuario_id,
     data,
     mes,
     ano,
     dia_semana,
     horas_diarias,
     horas_total,
     horas_reservado,
     horas_alocado,
     horas_ausencia,
     horas_overtime,
     horas_livre,
     flag_ausencia_full)
   VALUES
    (v_dia_alocacao_id,
     p_usuario_id,
     v_data,
     v_mes,
     v_ano,
     v_dia_semana,
     v_horas_diarias,
     v_horas_total,
     v_horas_reservado,
     v_horas_alocado,
     v_horas_ausencia,
     v_horas_overtime,
     v_horas_livre,
     v_flag_ausencia_full);
   --
   v_data := v_data + 1;
  END LOOP;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   p_erro_cod := '00000';
   p_erro_msg := 'Operação realizada com sucesso.';
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
  
   ROLLBACK;
 END alocacao_usu_processar;
 --
 --
 FUNCTION ultimo_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: retorna o id do cronograma mais recente do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_job_id IN job.job_id%TYPE
 ) RETURN INTEGER AS
  v_qt            INTEGER;
  v_cronograma_id cronograma.cronograma_id%TYPE;
  --
 BEGIN
  v_cronograma_id := NULL;
  --
  SELECT MAX(cronograma_id)
    INTO v_cronograma_id
    FROM cronograma
   WHERE job_id = p_job_id;
  --
  RETURN v_cronograma_id;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_cronograma_id := NULL;
   RETURN v_cronograma_id;
 END ultimo_retornar;
 --
 --
 FUNCTION item_duracao_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 18/03/2013
  -- DESCRICAO: retorna a duracao de um determinado item do cronograma.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/12/2019  Novo parametro usuario_id
  ------------------------------------------------------------------------------------------
  p_usuario_id    IN usuario.usuario_id%TYPE,
  p_item_crono_id IN item_crono.item_crono_id%TYPE
 ) RETURN INTEGER AS
 
  v_qt              INTEGER;
  v_ret             INTEGER;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_empresa_id      job.empresa_id%TYPE;
  v_usuario_id      usuario.usuario_id%TYPE;
  --
 BEGIN
  v_ret := NULL;
  --
  v_usuario_id := p_usuario_id;
  --
  IF nvl(v_usuario_id, 0) = 0 THEN
   -- nao veio o usuario. Pega o admin
   SELECT MAX(usuario_id)
     INTO v_usuario_id
     FROM usuario
    WHERE flag_admin_sistema = 'S';
  
  END IF;
  --
  SELECT ic.data_planej_ini,
         ic.data_planej_fim,
         jo.empresa_id
    INTO v_data_planej_ini,
         v_data_planej_fim,
         v_empresa_id
    FROM item_crono ic,
         cronograma cr,
         job        jo
   WHERE ic.item_crono_id = p_item_crono_id
     AND ic.cronograma_id = cr.cronograma_id
     AND cr.job_id = jo.job_id;
  --
  IF v_data_planej_ini IS NOT NULL AND v_data_planej_fim IS NOT NULL THEN
   -- dias corridos
   -- v_ret := v_data_planej_fim - v_data_planej_ini + 1;
   --
   -- dias uteis
   v_ret := feriado_pkg.qtd_dias_uteis_retornar(v_usuario_id, v_data_planej_ini, v_data_planej_fim) + 1;
  END IF;
  --
  RETURN v_ret;
  --
 EXCEPTION
  WHEN OTHERS THEN
   v_ret := 99999;
   RETURN v_ret;
 END item_duracao_retornar;
 --
 --
 FUNCTION num_seq_pre_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 27/08/2013
  -- DESCRICAO: retorna os numeros de sequencia dos predecessores associados a um 
  --   determinado item de cronograma.
  --  (o retorno e' feito em forma de vetor, separado por virgulas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_item_crono_id IN item_crono.item_crono_id%TYPE
 ) RETURN VARCHAR2 AS
 
  v_retorno VARCHAR2(1000);
  v_qt      INTEGER;
  --
  CURSOR c_it IS
   SELECT ic.num_seq
     FROM item_crono_pre ip,
          item_crono     ic
    WHERE ip.item_crono_id = p_item_crono_id
      AND ip.item_crono_pre_id = ic.item_crono_id
    ORDER BY ic.num_seq;
  --
 BEGIN
  v_retorno := NULL;
  --
  FOR r_it IN c_it
  LOOP
   v_retorno := v_retorno || ',' || to_char(r_it.num_seq);
  END LOOP;
  --
  -- retira a primeira virgula
  v_retorno := substr(v_retorno, 2);
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END num_seq_pre_retornar;
 --
 --
 FUNCTION ativ_do_objeto_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/12/2017
  -- DESCRICAO: retorna a fase/atividade/sequencia do objeto, no cronograma atual do job.
  --   p_tipo_texto: FASE - apenas o nome da fase
  --                 ATIV - apenas o nome da atividade
  --                 NUM_SEQ - apenas o numero da sequencia da atividade
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- xxxxxxxxxxxx      dd/mm/yyyy
  ------------------------------------------------------------------------------------------
  p_job_id     IN job.job_id%TYPE,
  p_cod_objeto IN item_crono.cod_objeto%TYPE,
  p_objeto_id  IN item_crono.objeto_id%TYPE,
  p_tipo_texto IN VARCHAR2
 ) RETURN VARCHAR2 AS
 
  v_qt            INTEGER;
  v_saida         EXCEPTION;
  v_retorno       VARCHAR2(500);
  v_cronograma_id cronograma.cronograma_id%TYPE;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(cronograma_id)
    INTO v_cronograma_id
    FROM cronograma
   WHERE job_id = p_job_id;
  --
  IF v_cronograma_id IS NULL THEN
   RAISE v_saida;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cronograma_id = v_cronograma_id
     AND cod_objeto = p_cod_objeto
     AND objeto_id = p_objeto_id;
  --
  IF v_item_crono_id IS NULL THEN
   RAISE v_saida;
  END IF;
  --
  IF p_tipo_texto = 'ATIV' THEN
   SELECT MAX(nome)
     INTO v_retorno
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  
  END IF;
  --
  IF p_tipo_texto = 'NUM_SEQ' THEN
   SELECT MAX(num_seq)
     INTO v_retorno
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  
  END IF;
  --
  IF p_tipo_texto = 'FASE' THEN
   SELECT MAX(nome)
     INTO v_retorno
     FROM item_crono
    WHERE connect_by_isleaf = 1
    START WITH item_crono_id = v_item_crono_id
   CONNECT BY PRIOR item_crono_pai_id = item_crono_id;
  
  END IF;
  --
  RETURN v_retorno;
  --
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_retorno;
  WHEN OTHERS THEN
   v_retorno := 'ERRO';
   RETURN v_retorno;
 END ativ_do_objeto_retornar;
 --
--
END; -- cronograma_pkg

/
