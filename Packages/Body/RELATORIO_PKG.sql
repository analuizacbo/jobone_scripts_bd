--------------------------------------------------------
--  DDL for Package Body RELATORIO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "RELATORIO_PKG" IS
 --
 PROCEDURE os_tline_processar_iniciar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias      ProcessMind     DATA: 12/04/2018
  -- DESCRICAO: Processamento inicial do Monitorar Timeline de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_str_data_inicial VARCHAR(10);
  v_str_hora_inicial VARCHAR(5);
  v_data_inicial     DATE;
  v_data_cursor      DATE;
  v_usuario_cursor   NUMBER;
  v_str_data_cursor  VARCHAR(10);
  v_str_hora_cursor  VARCHAR(5);
  v_cod_ori_est      VARCHAR(3);
  --
  CURSOR c_tline IS
   SELECT empresa_id,
          ordem_servico_id,
          usuario_exec_id,
          data_interna,
          data_demanda,
          horas_planej,
          sequencia,
          data_estimada
     FROM rel_os_tline
    ORDER BY empresa_id,
             usuario_exec_id,
             data_interna,
             sequencia;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- inserção dos registros de OS a serem calculadas
  ------------------------------------------------------------
  --
  --eliminar o cálculo velho da tabela de timeline
  DELETE FROM rel_os_tline;
  --
  --insere as OS em Aceitação e em Execução por Executor em ordem de prazo interno
  --preenche as horas_planej com horas estimadas na distribuição da OS (EXE)
  INSERT INTO rel_os_tline
   (empresa_id,
    ordem_servico_id,
    tipo_os_id,
    usuario_exec_id,
    data_interna,
    data_demanda,
    horas_planej,
    cod_ori_est,
    sequencia,
    flag_estim_atraso)
   SELECT ue.empresa_id,
          ou.ordem_servico_id,
          os.tipo_os_id,
          ou.usuario_id,
          nvl(os.data_interna, os.data_solicitada) AS data_interna,
          os.data_demanda,
          ou.horas_planej,
          'EXE',
          ou.sequencia,
          'N'
     FROM os_usuario ou
    INNER JOIN ordem_servico os
       ON os.ordem_servico_id = ou.ordem_servico_id
    INNER JOIN job jo
       ON jo.job_id = os.job_id
    INNER JOIN usuario us
       ON us.usuario_id = ou.usuario_id
    INNER JOIN usuario_empresa ue
       ON ue.usuario_id = us.usuario_id
      AND flag_padrao = 'S'
    WHERE os.status IN ('ACEI', 'EMEX') --<--somente OS em aceitação e em execução
      AND ou.status <> 'EXEC' --<--eliminar execuções individuais já realizadas
      AND ou.tipo_ender = 'EXE' --<--somente endereçamento de executores
      AND (os.data_interna IS NOT NULL OR os.data_solicitada IS NOT NULL);
  --
  --preenche as horas_planej com horas estimadas na elaboração da OS (EST)
  --somente para aquelas OS que ainda estão sem estimativa
  UPDATE rel_os_tline
     SET horas_planej =
         (SELECT SUM(horas_planej)
            FROM os_horas
           WHERE os_horas.ordem_servico_id = rel_os_tline.ordem_servico_id),
         cod_ori_est  = 'EST'
   WHERE (horas_planej IS NULL)
      OR (horas_planej = 0)
     AND EXISTS (SELECT 1
            FROM os_horas
           WHERE os_horas.ordem_servico_id = rel_os_tline.ordem_servico_id);
  --
  --preenche as horas_planej com horas em função do tamanho da OS (P,M,G)
  --definido no Tipo da OS (TAM)
  --somente para aquelas OS que ainda estão sem estimativa
  UPDATE rel_os_tline
     SET horas_planej =
         (SELECT SUM(pontos_tam_p)
            FROM tipo_os
           INNER JOIN ordem_servico
              ON tipo_os.tipo_os_id = ordem_servico.tipo_os_id
           WHERE ordem_servico.ordem_servico_id = rel_os_tline.ordem_servico_id
             AND ordem_servico.tamanho = 'P'),
         cod_ori_est  = 'TAM'
   WHERE (horas_planej IS NULL)
      OR (horas_planej = 0);
  --
  UPDATE rel_os_tline
     SET horas_planej =
         (SELECT SUM(pontos_tam_m)
            FROM tipo_os
           INNER JOIN ordem_servico
              ON tipo_os.tipo_os_id = ordem_servico.tipo_os_id
           WHERE ordem_servico.ordem_servico_id = rel_os_tline.ordem_servico_id
             AND ordem_servico.tamanho = 'M'),
         cod_ori_est  = 'TAM'
   WHERE (horas_planej IS NULL)
      OR (horas_planej = 0);
  --
  UPDATE rel_os_tline
     SET horas_planej =
         (SELECT SUM(pontos_tam_g)
            FROM tipo_os
           INNER JOIN ordem_servico
              ON tipo_os.tipo_os_id = ordem_servico.tipo_os_id
           WHERE ordem_servico.ordem_servico_id = rel_os_tline.ordem_servico_id
             AND ordem_servico.tamanho = 'G'),
         cod_ori_est  = 'TAM'
   WHERE (horas_planej IS NULL)
      OR (horas_planej = 0);
  --
  --preenche as horas_planej com horas padrão de Parâmetros da Empresa (PAR)
  --somente para aquelas OS que ainda estão sem estimativa
  UPDATE rel_os_tline
     SET horas_planej = to_number(empresa_pkg.parametro_retornar(empresa_id,
                                                                 'NUM_HORAS_PADRAO_OS_SEM_ESTIM')),
         cod_ori_est  = 'PAR'
   WHERE (horas_planej IS NULL)
      OR (horas_planej = 0);
  --
  ------------------------------------------------------------
  -- inicilização das variáveis
  ------------------------------------------------------------
  --
  --data de hoje que é o início do timeline
  v_str_data_inicial := to_char(SYSDATE, 'DD/MM/YYYY');
  --hora de hoje que é o horário de início do timeline (início do expediente da agência)
  v_str_hora_inicial := empresa_pkg.parametro_retornar(1, 'AG_HORA_INI_EXP');
  --data-hora inicial do timeline
  v_data_inicial := to_date(v_str_data_inicial || ' ' || v_str_hora_inicial, 'DD/MM/YYYY HH24:MI');
  --data-hora inicial para aplicar no cursor quando acrescentado dias úteis
  v_str_hora_cursor := v_str_hora_inicial;
  --variável de controle do cursor usada para verificar a mudança de usuário
  v_usuario_cursor := 0;
  --calcula o tempo de expediente da agência
  --v_expediente_horas := TO_DATE(TO_DATE(v_str_data_inicial || ' ' || v_str_hora_final, 'dd/mm/yyyy hh24:mi') - TO_DATE(v_str_data_inicial || ' ' || v_str_hora_inicial, 'dd/mm/yyyy hh24:mi'),'HH24:MI');
  --
  ------------------------------------------------------------
  -- cálculo da Data/Hora Estimada de Início das OS
  ------------------------------------------------------------
  --
  FOR r_tline IN c_tline
  LOOP
   --
   --ao encontrar um novo usuário no cursor, reiniciar o timeline
   IF v_usuario_cursor <> r_tline.usuario_exec_id THEN
    v_data_cursor    := v_data_inicial;
    v_usuario_cursor := r_tline.usuario_exec_id;
   END IF;
   --
   --acrescenta mais um dia enquanto v_data_cursor cair num dia de ausência programada do usuário
   LOOP
    --conta quantas ausências programadas existem configuradas para o usuário
    --no dia e v_data_cursor
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_progr
     WHERE usuario_id = r_tline.usuario_exec_id
       AND trunc(v_data_cursor) >= trunc(data_ini)
       AND trunc(v_data_cursor) <= trunc(data_fim);
    --
    --acrescenta um dia se o v_data_cursor cair numa ausência programada do usuário
    IF v_qt > 0 THEN
     v_str_hora_cursor := to_char(v_data_cursor, 'hh24:mi');
     --acrescenta um dia útil na data do cursor "saindo" da ausência programada do usuário
     v_str_data_cursor := to_char(feriado_pkg.prox_dia_util_retornar(r_tline.usuario_exec_id,
                                                                     v_data_cursor,
                                                                     1,
                                                                     'S'),
                                  'DD/MM/YYYY');
     --remontando a data do cursor com a data acrescida de um dia e a hora de início do expediente
     v_data_cursor := to_date(v_str_data_cursor || ' ' || v_str_hora_cursor, 'DD/MM/YYYY HH24:MI');
    END IF;
    --
    --repete até que o v_data_cursor não caia numa ausência programada do usuário
    EXIT WHEN v_qt = 0;
   END LOOP;
   --
   --verifica se a OS tem data para prevista para começar - data demanda
   IF trunc(v_data_cursor) < r_tline.data_demanda THEN
    v_str_hora_cursor := to_char(v_data_cursor, 'hh24:mi');
    --adota a data_demanda como a data de início da OS colocando-a no cursor
    v_str_data_cursor := to_char(feriado_pkg.prox_dia_util_retornar(r_tline.usuario_exec_id,
                                                                    trunc(r_tline.data_demanda),
                                                                    0,
                                                                    'S'),
                                 'DD/MM/YYYY');
    --remontando a data do cursor com a data acrescida de um dia e a hora de início do expediente
    v_data_cursor := to_date(v_str_data_cursor || ' ' || v_str_hora_cursor, 'DD/MM/YYYY HH24:MI');
   END IF;
   --
   --acrescenta mais um dia enquanto v_data_cursor cair num dia de ausência programada do usuário
   LOOP
    --conta quantas ausências programadas existem configuradas para o usuário
    --no dia e v_data_cursor
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_progr
     WHERE usuario_id = r_tline.usuario_exec_id
       AND trunc(v_data_cursor) >= trunc(data_ini)
       AND trunc(v_data_cursor) <= trunc(data_fim);
    --
    --acrescenta um dia se o v_data_cursor cair numa ausência programada do usuário
    IF v_qt > 0 THEN
     v_str_hora_cursor := to_char(v_data_cursor, 'hh24:mi');
     --acrescenta um dia útil na data do cursor "saindo" da ausência programada do usuário
     v_str_data_cursor := to_char(feriado_pkg.prox_dia_util_retornar(r_tline.usuario_exec_id,
                                                                     v_data_cursor,
                                                                     1,
                                                                     'S'),
                                  'DD/MM/YYYY');
     --remontando a data do cursor com a data acrescida de um dia e a hora de início do expediente
     v_data_cursor := to_date(v_str_data_cursor || ' ' || v_str_hora_cursor, 'DD/MM/YYYY HH24:MI');
    END IF;
    --
    --repete até que o v_data_cursor não caia numa ausência programada do usuário
    EXIT WHEN v_qt = 0;
   END LOOP;
   --
   --atualizar a data estimada de início para a data-hora do timeline
   UPDATE rel_os_tline
      SET data_estimada = v_data_cursor
    WHERE empresa_id = r_tline.empresa_id
      AND usuario_exec_id = r_tline.usuario_exec_id
      AND ordem_servico_id = r_tline.ordem_servico_id
      AND sequencia = r_tline.sequencia;
   --
   --acrescentar o tempo de execução da OS atual no timeline
   --que será a data estimada de início da próxima OS
   v_data_cursor := feriado_pkg.prazo_em_horas_retornar(r_tline.usuario_exec_id,
                                                        r_tline.empresa_id,
                                                        v_data_cursor,
                                                        'TLINE',
                                                        r_tline.horas_planej);
   --
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- os_tline_processar_iniciar
 --
 --
 PROCEDURE os_tline_processar_depend
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias      ProcessMind     DATA: 17/04/2018
  -- DESCRICAO: Processamento das dependências do Monitorar Timeline de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt                           INTEGER;
  v_exception                    EXCEPTION;
  v_usuario_cursor               NUMBER;
  v_usuario_exec_id              NUMBER;
  v_data_estimada                DATE;
  v_data_estim_mais_horas_planej DATE;
  v_horas_planej                 NUMBER;
  v_data_cursor                  DATE;
  v_str_data_cursor              VARCHAR(10);
  v_str_hora_cursor              VARCHAR(5);
  --
  CURSOR c_tline IS
   SELECT empresa_id,
          ordem_servico_id,
          usuario_exec_id,
          data_demanda,
          horas_planej,
          sequencia,
          data_estimada
     FROM rel_os_tline
    WHERE sequencia > 1
    ORDER BY ordem_servico_id,
             sequencia;
  --
  CURSOR c_usu_tline IS
   SELECT empresa_id,
          ordem_servico_id,
          usuario_exec_id,
          data_interna,
          data_demanda,
          horas_planej,
          sequencia,
          data_estimada
     FROM rel_os_tline
    WHERE usuario_exec_id = v_usuario_exec_id
      AND data_estimada >= v_data_estimada
    ORDER BY empresa_id,
             usuario_exec_id,
             data_estimada,
             sequencia;
  --
 BEGIN
  --
  p_erro_cod := '00000';
  --
  FOR r_tline IN c_tline
  LOOP
   --
   SELECT MAX(data_estimada)
     INTO v_data_estimada
     FROM rel_os_tline
    WHERE ordem_servico_id = r_tline.ordem_servico_id
      AND sequencia < r_tline.sequencia;
   --
   IF v_data_estimada IS NOT NULL THEN
    --
    -- max usado para evitar erro, a pedido do Joel.
    -- necessita revisao
    SELECT MAX(horas_planej)
      INTO v_horas_planej
      FROM rel_os_tline
     WHERE data_estimada = v_data_estimada
       AND ordem_servico_id = r_tline.ordem_servico_id
       AND sequencia < r_tline.sequencia;
    --
    v_data_estim_mais_horas_planej := feriado_pkg.prazo_em_horas_retornar(r_tline.usuario_exec_id,
                                                                          r_tline.empresa_id,
                                                                          v_data_estimada,
                                                                          'TLINE',
                                                                          v_horas_planej);
   END IF;
   --
   IF v_data_estim_mais_horas_planej > r_tline.data_estimada AND v_data_estimada IS NOT NULL THEN
    --
    -- max usado para evitar erro, a pedido do Joel.
    -- necessita revisao
    SELECT MAX(horas_planej)
      INTO v_horas_planej
      FROM rel_os_tline
     WHERE ordem_servico_id = r_tline.ordem_servico_id
       AND sequencia < r_tline.sequencia
       AND data_estimada = v_data_estimada;
    --
    v_data_cursor := feriado_pkg.prazo_em_horas_retornar(r_tline.usuario_exec_id,
                                                         r_tline.empresa_id,
                                                         v_data_estimada,
                                                         'TLINE',
                                                         v_horas_planej);
    --
    v_usuario_exec_id := r_tline.usuario_exec_id;
    --
    v_data_estimada := r_tline.data_estimada;
    --
    FOR r_usu_tline IN c_usu_tline
    LOOP
     --
     --acrescenta mais um dia enquanto v_data_cursor cair num dia de ausência programada do usuário
     LOOP
      --conta quantas ausências programadas existem configuradas para o usuário
      --no dia e v_data_cursor
      SELECT COUNT(*)
        INTO v_qt
        FROM apontam_progr
       WHERE usuario_id = r_usu_tline.usuario_exec_id
         AND trunc(v_data_cursor) >= trunc(data_ini)
         AND trunc(v_data_cursor) <= trunc(data_fim);
      --
      --acrescenta um dia se o v_data_cursor cair numa ausência programada do usuário
      IF v_qt > 0 THEN
       v_str_hora_cursor := to_char(v_data_cursor, 'hh24:mi');
       --acrescenta um dia útil na data do cursor "saindo" da ausência programada do usuário
       v_str_data_cursor := to_char(feriado_pkg.prox_dia_util_retornar(r_usu_tline.usuario_exec_id,
                                                                       v_data_cursor,
                                                                       1,
                                                                       'S'),
                                    'DD/MM/YYYY');
       --remontando a data do cursor com a data acrescida de um dia e a hora de início do expediente
       v_data_cursor := to_date(v_str_data_cursor || ' ' || v_str_hora_cursor, 'DD/MM/YYYY HH24:MI');
      END IF;
      --
      --repete até que o v_data_cursor não caia numa ausência programada do usuário
      EXIT WHEN v_qt = 0;
     END LOOP;
     --
     UPDATE rel_os_tline
        SET data_estimada = v_data_cursor
      WHERE empresa_id = r_usu_tline.empresa_id
        AND usuario_exec_id = r_usu_tline.usuario_exec_id
        AND ordem_servico_id = r_usu_tline.ordem_servico_id
        AND sequencia = r_usu_tline.sequencia;
     --
     p_erro_cod := '00010';
     --
     v_data_cursor := feriado_pkg.prazo_em_horas_retornar(r_usu_tline.usuario_exec_id,
                                                          r_usu_tline.empresa_id,
                                                          v_data_cursor,
                                                          'TLINE',
                                                          r_usu_tline.horas_planej);
    END LOOP;
   END IF;
   --
   EXIT WHEN p_erro_cod = '00010';
   --
  END LOOP;
  --
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- os_tline_processar_depend
 --
 --
 PROCEDURE os_tline_processar_usuario
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias      ProcessMind     DATA: 11/05/2018
  -- DESCRICAO: Processamento dos espaços do Monitorar Timeline de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_id IN NUMBER,
  p_erro_cod   OUT VARCHAR2,
  p_erro_msg   OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_str_data_inicial VARCHAR(10);
  v_str_hora_inicial VARCHAR(5);
  v_data_inicial     DATE;
  v_data_cursor      DATE;
  v_usuario_cursor   NUMBER;
  v_str_data_cursor  VARCHAR(10);
  v_str_hora_cursor  VARCHAR(5);
  v_espaco           NUMBER;
  v_data_atualizar   DATE;
  v_horas_planej     NUMBER;
  --
  CURSOR c_tline IS
   SELECT empresa_id,
          ordem_servico_id,
          usuario_exec_id,
          data_interna,
          data_demanda,
          horas_planej,
          sequencia,
          data_estimada
     FROM rel_os_tline
    WHERE usuario_exec_id = p_usuario_id
    ORDER BY data_estimada;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- inicilização das variáveis
  ------------------------------------------------------------
  --
  --data de hoje que é o início do timeline
  v_str_data_inicial := to_char(SYSDATE, 'DD/MM/YYYY');
  --hora de hoje que é o horário de início do timeline (início do expediente da agência)
  v_str_hora_inicial := empresa_pkg.parametro_retornar(1, 'AG_HORA_INI_EXP');
  --data-hora inicial do timeline
  v_data_inicial := to_date(v_str_data_inicial || ' ' || v_str_hora_inicial, 'DD/MM/YYYY HH24:MI');
  --data-hora inicial para aplicar no cursor quando acrescentado dias úteis
  v_str_hora_cursor := v_str_hora_inicial;
  --
  v_data_cursor := v_data_inicial;
  --
  p_erro_cod := '00000';
  --
  FOR r_tline IN c_tline
  LOOP
   --
   v_horas_planej := r_tline.horas_planej;
   --
   --acrescenta mais um dia enquanto v_data_cursor cair num dia de ausência programada do usuário
   LOOP
    --conta quantas ausências programadas existem configuradas para o usuário
    --no dia e v_data_cursor
    SELECT COUNT(*)
      INTO v_qt
      FROM apontam_progr
     WHERE usuario_id = r_tline.usuario_exec_id
       AND trunc(v_data_cursor) >= trunc(data_ini)
       AND trunc(v_data_cursor) <= trunc(data_fim);
    --
    --acrescenta um dia se o v_data_cursor cair numa ausência programada do usuário
    IF v_qt > 0 THEN
     v_str_hora_cursor := to_char(v_data_cursor, 'hh24:mi');
     v_str_data_cursor := to_char(feriado_pkg.prox_dia_util_retornar(r_tline.usuario_exec_id,
                                                                     v_data_cursor,
                                                                     1,
                                                                     'S'),
                                  'DD/MM/YYYY');
     v_data_cursor     := to_date(v_str_data_cursor || ' ' || v_str_hora_cursor,
                                  'DD/MM/YYYY HH24:MI');
    END IF;
    --
    --repete até que o v_data_cursor não caia numa ausência programada do usuário
    EXIT WHEN v_qt = 0;
   END LOOP;
   --
   v_espaco := feriado_pkg.dif_horas_uteis_retornar(r_tline.usuario_exec_id,
                                                    r_tline.empresa_id,
                                                    v_data_cursor,
                                                    r_tline.data_estimada,
                                                    'S');
   --
   IF v_espaco > 0 THEN
    /*
    IF r_tline.sequencia = 1 AND r_tline.data_demanda IS NULL THEN
      --
       UPDATE rel_os_tline
           SET data_estimada = v_data_cursor
         WHERE data_estimada = r_tline.data_estimada
           AND usuario_exec_id = r_tline.usuario_exec_id;
      --
      p_erro_cod := '00010';
      --
    ELSE */
    --
    SELECT MIN(data_estimada)
      INTO v_data_atualizar
      FROM rel_os_tline
     WHERE data_estimada > v_data_cursor
       AND usuario_exec_id = r_tline.usuario_exec_id
       AND data_demanda IS NULL
       AND sequencia = 1
       AND horas_planej <= v_espaco;
    --
    IF v_data_atualizar IS NOT NULL THEN
     --
     SELECT horas_planej
       INTO v_horas_planej
       FROM rel_os_tline
      WHERE data_estimada = v_data_atualizar
        AND usuario_exec_id = r_tline.usuario_exec_id;
     --
     UPDATE rel_os_tline
        SET data_estimada = v_data_cursor
      WHERE data_estimada = v_data_atualizar
        AND usuario_exec_id = r_tline.usuario_exec_id;
     --
     p_erro_cod := '00010';
     --
    ELSE
     v_data_cursor := feriado_pkg.prazo_em_horas_retornar(r_tline.usuario_exec_id,
                                                          r_tline.empresa_id,
                                                          v_data_cursor,
                                                          'TLINE',
                                                          v_espaco);
    END IF;
    --
    --END IF;
    --
   END IF;
   --
   v_data_cursor := feriado_pkg.prazo_em_horas_retornar(r_tline.usuario_exec_id,
                                                        r_tline.empresa_id,
                                                        v_data_cursor,
                                                        'TLINE',
                                                        v_horas_planej);
   --
   EXIT WHEN p_erro_cod = '00010';
   --
  END LOOP;
  --
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- os_tline_processar_usuario
 --
 --
 PROCEDURE os_tline_processar_espacos
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias      ProcessMind     DATA: 17/04/2018
  -- DESCRICAO: Processamento dos espaços do Monitorar Timeline de OS
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  --
  CURSOR c_tline IS
   SELECT usuario_exec_id
     FROM rel_os_tline
    GROUP BY usuario_exec_id
    ORDER BY usuario_exec_id;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- inicilização das variáveis
  ------------------------------------------------------------
  --
  FOR r_tline IN c_tline
  LOOP
   --
   LOOP
    os_tline_processar_usuario(r_tline.usuario_exec_id, p_erro_cod, p_erro_msg);
    EXIT WHEN p_erro_cod = '00000';
   END LOOP;
   --
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- os_tline_processar_espacos
 --
 --
 PROCEDURE os_tline_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Joel Dias      ProcessMind     DATA: 12/04/2018
  -- DESCRICAO: Processa o relatório de Monitorar Timeline de OS.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            22/02/2019  Nao executa o processamento de madrugada.
  ------------------------------------------------------------------------------------------
 (
  p_erro_cod OUT VARCHAR2,
  p_erro_msg OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_cont      INTEGER;
  v_exception EXCEPTION;
  v_saida     EXCEPTION;
  v_erro_code VARCHAR2(10);
  v_hora      NUMBER(5);
  --
  --
 BEGIN
  --
  v_hora := to_number(to_char(SYSDATE, 'HH24'));
  --
  -- pula o processamento nesse intervalo de horas
  IF (v_hora BETWEEN 23 AND 24) OR (v_hora BETWEEN 0 AND 7) THEN
   RAISE v_saida;
  END IF;
  --
  os_tline_processar_iniciar(p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  v_qt := 0;
  --
  SELECT COUNT(*)
    INTO v_cont
    FROM rel_os_tline
   WHERE sequencia > 1;
  --
  LOOP
   --
   v_qt := v_qt + 1;
   --
   os_tline_processar_depend(p_erro_cod, p_erro_msg);
   --
   IF (p_erro_cod <> '00000') AND (p_erro_cod <> '00010') THEN
    RAISE v_exception;
   END IF;
   --
   v_erro_code := p_erro_cod;
   --
   IF v_qt = v_cont * 3 THEN
    v_erro_code := '00000';
   END IF;
   --
   EXIT WHEN v_erro_code = '00000';
   --
  END LOOP;
  --
  os_tline_processar_espacos(p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  UPDATE rel_os_tline r
     SET r.flag_estim_atraso = 'S'
   WHERE EXISTS (SELECT 1
            FROM rel_os_tline u
           WHERE u.ordem_servico_id = r.ordem_servico_id
             AND trunc(u.data_estimada) > trunc(u.data_interna));
  --
  COMMIT;
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_saida THEN
   NULL;
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
     'relatorio_pkg.os_tline_processar',
     p_erro_cod,
     p_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
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
     'relatorio_pkg.os_tline_processar',
     p_erro_cod,
     p_erro_msg);
   COMMIT;
 END os_tline_processar;
 --
 --
 PROCEDURE rentab_job_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 22/02/2010
  -- DESCRICAO: Processa o relatorio de rentabilidade do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_data_ini          IN VARCHAR2,
  p_data_fim          IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_data_calculo       rel_rentab_job.data_calculo%TYPE;
  v_valor_economia     rel_rentab_job.valor_economia%TYPE;
  v_valor_honorario    rel_rentab_job.valor_honorario%TYPE;
  v_valor_bv_fat       rel_rentab_job.valor_bv_fat%TYPE;
  v_valor_bv_aba       rel_rentab_job.valor_bv_aba%TYPE;
  v_valor_ajuste_final rel_rentab_job.valor_ajuste_final%TYPE;
  v_valor_total        rel_rentab_job.valor_total%TYPE;
  v_valor_total_custo  rel_rentab_job.valor_total_custo%TYPE;
  v_rentab_com_honor   rel_rentab_job.rentab_com_honor%TYPE;
  v_rentab_sem_honor   rel_rentab_job.rentab_sem_honor%TYPE;
  v_data_ini           DATE;
  v_data_fim           DATE;
  --
  CURSOR c_job IS
   SELECT job_id,
          valor_ajuste_final
     FROM job jo
    WHERE jo.empresa_id = p_empresa_id
      AND jo.data_entrada >= v_data_ini
      AND jo.data_entrada <= v_data_fim;
  --
 BEGIN
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'REL_RENTABCLI_V', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_ini) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data inicial é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inicial inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_fim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data final é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  v_data_fim := data_converter(p_data_fim);
  --
  IF v_data_fim < v_data_ini THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final não pode ser anterior à data inicial.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_fim > trunc(SYSDATE) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final não pode ser maior que a data de hoje.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data_calculo := trunc(SYSDATE);
  --
  FOR r_job IN c_job
  LOOP
   DELETE FROM rel_rentab_job
    WHERE job_id = r_job.job_id;
   --
   v_valor_economia     := job_pkg.valor_realizado_retornar(r_job.job_id, 'SALDO', 'TUDO');
   v_valor_honorario    := job_pkg.valor_realizado_retornar(r_job.job_id, 'HONOR', 'TUDO');
   v_valor_bv_fat       := job_pkg.valor_realizado_retornar(r_job.job_id, 'BV_FAT', 'TUDO');
   v_valor_bv_aba       := job_pkg.valor_realizado_retornar(r_job.job_id, 'BV_ABA', 'TUDO');
   v_valor_ajuste_final := r_job.valor_ajuste_final;
   --
   v_valor_total := v_valor_economia + v_valor_honorario + v_valor_bv_fat + v_valor_bv_aba +
                    v_valor_ajuste_final;
   --
   v_valor_total_custo := job_pkg.valor_retornar(r_job.job_id, 'CUSTO_SALDO', 'TUDO');
   --
   IF v_valor_total_custo = 0 THEN
    v_rentab_com_honor := 0;
    v_rentab_sem_honor := 0;
   ELSE
    v_rentab_com_honor := v_valor_total / v_valor_total_custo * 100;
    v_rentab_sem_honor := (v_valor_total - v_valor_honorario) / v_valor_total_custo * 100;
   END IF;
   --
   INSERT INTO rel_rentab_job
    (job_id,
     data_calculo,
     valor_economia,
     valor_honorario,
     valor_bv_fat,
     valor_bv_aba,
     valor_ajuste_final,
     valor_total,
     valor_total_custo,
     rentab_com_honor,
     rentab_sem_honor)
   VALUES
    (r_job.job_id,
     v_data_calculo,
     v_valor_economia,
     v_valor_honorario,
     v_valor_bv_fat,
     v_valor_bv_aba,
     v_valor_ajuste_final,
     v_valor_total,
     v_valor_total_custo,
     v_rentab_com_honor,
     v_rentab_sem_honor);
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
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- rentab_job_processar
 --
 --
 PROCEDURE fluxo_checkin_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 30/10/2008
  -- DESCRICAO: Processa o relatorio de fluxo do checkin. O resultado é em milhares.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id    IN NUMBER,
  p_empresa_id           IN empresa.empresa_id%TYPE,
  p_data_ini             IN VARCHAR2,
  p_data_fim             IN VARCHAR2,
  p_rel_fluxo_checkin_id OUT rel_fluxo_checkin.rel_fluxo_checkin_id%TYPE,
  p_erro_cod             OUT VARCHAR2,
  p_erro_msg             OUT VARCHAR2
 ) IS
  v_qt                   INTEGER;
  v_exception            EXCEPTION;
  v_rel_fluxo_checkin_id rel_fluxo_checkin.rel_fluxo_checkin_id%TYPE;
  v_data                 rel_fluxo_checkin.data%TYPE;
  v_saldo_inicial        rel_fluxo_checkin.saldo_inicial%TYPE;
  v_entradas_tot         rel_fluxo_checkin.entradas%TYPE;
  v_entradas_a           rel_fluxo_checkin.entradas%TYPE;
  v_entradas_bc          rel_fluxo_checkin.entradas%TYPE;
  v_saidas_tot           rel_fluxo_checkin.saidas%TYPE;
  v_saidas_nf            rel_fluxo_checkin.saidas%TYPE;
  v_saidas_sobra         rel_fluxo_checkin.saidas%TYPE;
  v_saldo_final          rel_fluxo_checkin.saldo_final%TYPE;
  v_data_ini             DATE;
  v_data_fim             DATE;
  v_divisor              INTEGER;
  v_decimais             INTEGER;
  --
 BEGIN
  v_qt                   := 0;
  p_rel_fluxo_checkin_id := 0;
  --
  -- resultado em milhares
  v_divisor  := 1000;
  v_decimais := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'REL_FLUXO_CHECKIN_V',
                                NULL,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_data_ini) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data inicial é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inicial inválida.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_fim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da data final é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final inválida.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter(p_data_ini);
  v_data_fim := data_converter(p_data_fim);
  --
  IF v_data_fim < v_data_ini THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final não pode ser anterior à data inicial.';
   RAISE v_exception;
  END IF;
  --
  IF v_data_fim > trunc(SYSDATE) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data final não pode ser maior que a data de hoje.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_rel_fluxo_checkin.nextval
    INTO v_rel_fluxo_checkin_id
    FROM dual;
  --
  -- comeca o processamento com a data do dia
  v_data := trunc(SYSDATE);
  --
  SELECT round(nvl(SUM(it.valor_ckpend), 0) / v_divisor, v_decimais)
    INTO v_saldo_final
    FROM item      it,
         orcamento oc,
         job       jo
   WHERE it.orcamento_id = oc.orcamento_id
     AND oc.status = 'APROV'
     AND oc.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  WHILE v_data >= v_data_ini
  LOOP
   -- soma checkins efetuados na data (apenas com carta acordo).
   SELECT round(nvl(SUM(io.valor_aprovado), 0) / v_divisor, v_decimais)
     INTO v_saidas_nf
     FROM nota_fiscal nf,
          item_nota   io,
          item        it,
          pessoa      pe
    WHERE nf.data_entrada = v_data
      AND nf.tipo_ent_sai = 'E'
      AND nf.status NOT IN ('CHECKIN_PEND', 'CANC')
      AND nf.nota_fiscal_id = io.nota_fiscal_id
      AND io.item_id = it.item_id
      AND io.carta_acordo_id IS NOT NULL
      AND nf.emp_emissora_id = pe.pessoa_id
      AND pe.empresa_id = p_empresa_id;
   --
   -- soma sobras registradas na data (para B e C, apenas as
   -- sobras registradas em carta acordo).
   SELECT round(nvl(SUM(io.valor_sobra_item), 0) / v_divisor, v_decimais)
     INTO v_saidas_sobra
     FROM item       it,
          orcamento  oc,
          item_sobra io,
          sobra      so,
          job        jo
    WHERE it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND oc.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id
      AND it.item_id = io.item_id
      AND io.sobra_id = so.sobra_id
      AND so.data_entrada = v_data
      AND (it.tipo_item = 'A' OR (it.tipo_item IN ('B', 'C') AND so.carta_acordo_id IS NOT NULL));
   --
   v_saidas_tot := v_saidas_nf + v_saidas_sobra;
   --
   SELECT round(nvl(SUM(it.valor_aprovado), 0) / v_divisor, v_decimais)
     INTO v_entradas_a
     FROM item      it,
          orcamento oc,
          job       jo
    WHERE it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND oc.data_status = v_data
      AND oc.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id
      AND it.tipo_item = 'A';
   --
   SELECT round(nvl(SUM(ic.valor_aprovado), 0) / v_divisor, v_decimais)
     INTO v_entradas_bc
     FROM item       it,
          orcamento  oc,
          item_carta ic,
          job        jo
    WHERE it.orcamento_id = oc.orcamento_id
      AND oc.status = 'APROV'
      AND oc.data_status = v_data
      AND oc.job_id = jo.job_id
      AND jo.empresa_id = p_empresa_id
      AND it.tipo_item IN ('B', 'C')
      AND it.item_id = ic.item_id;
   --
   v_entradas_tot := v_entradas_a + v_entradas_bc;
   --
   v_saldo_inicial := v_saldo_final + v_saidas_tot - v_entradas_tot;
   --
   INSERT INTO rel_fluxo_checkin
    (rel_fluxo_checkin_id,
     data,
     saldo_inicial,
     entradas,
     saidas,
     saldo_final)
   VALUES
    (v_rel_fluxo_checkin_id,
     v_data,
     v_saldo_inicial,
     v_entradas_tot,
     v_saidas_tot,
     v_saldo_final);
   --
   v_data        := v_data - 1;
   v_saldo_final := v_saldo_inicial;
  END LOOP;
  --
  -- exclui as datas nao solicitadas
  DELETE FROM rel_fluxo_checkin
   WHERE rel_fluxo_checkin_id = v_rel_fluxo_checkin_id
     AND data > v_data_fim;
  --
  COMMIT;
  p_rel_fluxo_checkin_id := v_rel_fluxo_checkin_id;
  p_erro_cod             := '00000';
  p_erro_msg             := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- fluxo_checkin_processar
 --
 --
 PROCEDURE apontam_mensal_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 16/10/2009
  -- DESCRICAO: Processa o relatorio de apontamentos mensais.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_mes_ano           IN VARCHAR2,
  p_jobs              IN VARCHAR2,
  p_rel_apon_mens_id  OUT rel_apon_mens_val.rel_apon_mens_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_data_ini         DATE;
  v_data_fim         DATE;
  v_data             DATE;
  v_rel_apon_mens_id rel_apon_mens_col.rel_apon_mens_id%TYPE;
  v_dia              rel_apon_mens_col.dia_apontam%TYPE;
  v_flag_dia_util    rel_apon_mens_col.flag_dia_util%TYPE;
  v_delimitador      CHAR(1);
  v_vetor_job        VARCHAR2(2000);
  v_job_char         VARCHAR2(100);
  v_job_id           job.job_id%TYPE;
  v_lbl_job          VARCHAR2(100);
  --
 BEGIN
  v_qt               := 0;
  p_rel_apon_mens_id := 0;
  v_lbl_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'REL_TSMENS_V', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_mes_ano) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do mês/ano é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF mes_ano_validar(p_mes_ano) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Mês/ano inválido.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_jobs) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do(s) ' || v_lbl_job || '(s) é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_data_ini := data_converter('01' || '/' || p_mes_ano);
  v_data_fim := last_day(v_data_ini);
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_rel_apon_mens.nextval
    INTO v_rel_apon_mens_id
    FROM dual;
  --
  v_data := v_data_ini;
  --
  -------------------------
  -- montagem das colunas
  -------------------------
  WHILE v_data <= v_data_fim
  LOOP
   v_dia := to_number(to_char(v_data, 'DD'));
   --
   IF feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data, 'N') = 1 THEN
    v_flag_dia_util := 'S';
   ELSE
    v_flag_dia_util := 'N';
   END IF;
   --
   INSERT INTO rel_apon_mens_col
    (rel_apon_mens_id,
     data_apontam,
     dia_apontam,
     flag_dia_util)
   VALUES
    (v_rel_apon_mens_id,
     v_data,
     v_dia,
     v_flag_dia_util);
   --
   v_data := v_data + 1;
  END LOOP;
  --
  -------------------------
  -- tratamento dos jobs
  -------------------------
  v_delimitador := ',';
  v_vetor_job   := p_jobs;
  --
  WHILE nvl(length(rtrim(v_vetor_job)), 0) > 0
  LOOP
   v_job_char := TRIM(prox_valor_retornar(v_vetor_job, v_delimitador));
   --
   SELECT MAX(job_id)
     INTO v_job_id
     FROM job
    WHERE numero = TRIM(v_job_char)
      AND empresa_id = p_empresa_id;
   --
   IF v_job_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe (' || v_job_char || ').';
    RAISE v_exception;
   END IF;
   --
   -- montagem das linhas do job
   INSERT INTO rel_apon_mens_lin
    (rel_apon_mens_id,
     job_id,
     papel_id,
     nome_papel,
     valor_hora,
     total_horas)
    SELECT v_rel_apon_mens_id,
           v_job_id,
           ah.papel_id,
           pa.nome,
           nvl(MAX(ad.venda_hora), 0),
           nvl(SUM(ah.horas), 0)
      FROM apontam_data ad,
           apontam_hora ah,
           papel        pa
     WHERE ad.data BETWEEN v_data_ini AND v_data_fim
       AND ad.apontam_data_id = ah.apontam_data_id
       AND ah.job_id = v_job_id
       AND ah.papel_id = pa.papel_id
     GROUP BY ah.papel_id,
              pa.nome;
   --
   -- montagem dos valores dos jobs (todas as combinacoes c/ data)
   INSERT INTO rel_apon_mens_val
    (rel_apon_mens_id,
     data_apontam,
     job_id,
     papel_id,
     horas)
    SELECT co.rel_apon_mens_id,
           co.data_apontam,
           li.job_id,
           li.papel_id,
           0
      FROM rel_apon_mens_col co,
           rel_apon_mens_lin li
     WHERE co.rel_apon_mens_id = v_rel_apon_mens_id
       AND li.rel_apon_mens_id = v_rel_apon_mens_id
       AND li.job_id = v_job_id;
   --
   -- atualizacao dos valores de horas do job
   UPDATE rel_apon_mens_val re
      SET horas =
          (SELECT nvl(SUM(ah.horas), 0)
             FROM apontam_data ad,
                  apontam_hora ah
            WHERE ad.data = re.data_apontam
              AND ad.apontam_data_id = ah.apontam_data_id
              AND ah.job_id = re.job_id
              AND ah.papel_id = re.papel_id)
    WHERE re.rel_apon_mens_id = v_rel_apon_mens_id
      AND job_id = v_job_id;
  END LOOP;
  --
  --
  COMMIT;
  p_rel_apon_mens_id := v_rel_apon_mens_id;
  p_erro_cod         := '00000';
  p_erro_msg         := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END; -- apontam_mensal_processar
 --
 --
 PROCEDURE limpar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 31/10/2008
  -- DESCRICAO: limpa dados de relatorios antigos.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            16/10/2009  Limpeza do relatório de apontamentos mensais.
  ------------------------------------------------------------------------------------------
  IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_erro_cod  VARCHAR2(20);
  v_erro_msg  VARCHAR2(200);
  --
 BEGIN
  v_qt := 0;
  --
  DELETE FROM rel_fluxo_checkin
   WHERE data < trunc(SYSDATE);
  --
  DELETE FROM rel_apon_mens_val;
  DELETE FROM rel_apon_mens_col;
  DELETE FROM rel_apon_mens_lin;
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
     'relatorio_pkg.limpar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
  WHEN OTHERS THEN
   ROLLBACK;
   v_erro_cod := SQLCODE;
   v_erro_msg := substr(SQLERRM || ' Linha: ' || dbms_utility.format_error_backtrace, 1, 200);
   INSERT INTO erro_log
    (erro_log_id,
     data,
     nome_programa,
     cod_erro,
     msg_erro)
   VALUES
    (seq_erro_log.nextval,
     SYSDATE,
     'relatorio_pkg.limpar',
     v_erro_cod,
     v_erro_msg);
   COMMIT;
 END; -- limpar
--
--
END; -- RELATORIO_PKG

/
