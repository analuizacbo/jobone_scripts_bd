--------------------------------------------------------
--  DDL for Package Body APONTAM_PROGR_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APONTAM_PROGR_PKG" IS
 --
 g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 26/06/2008
  -- DESCRICAO: Inclusão de Programacao de Apontamentos administrativos (ferias, outros).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/10/2008  Implementacao de salario.
  -- Silvia            13/03/2009  Consistencia do tipo de programacao via dicionario.
  -- Silvia            13/11/2009  Consistencias adicionais para o periodo informado.
  -- Silvia            12/04/2010  Implementacao de multiagencia.
  -- Silvia            24/04/2013  Nova tabela para tipo de apontamento.
  -- Silvia            30/05/2016  Tratamento de encriptacao.
  -- Silvia            19/12/2016  Horas admin sao incluidas no status APRO ao inves de ENCE
  -- Silvia            11/04/2017  Novo parametro flag_os_aprov_auto
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Silvia            14/09/2017  Programacao liberada para usuarios que nao apontam horas.
  -- Silvia            20/02/2018  Inclusao de area do papel.
  -- Silvia            27/03/2018  Novo priviletio AUSENCIA_C.
  -- Silvia            14/01/2020  Chamada da alocacao_processar.
  -- Silvia            18/06/2020  Novos parametros para horario
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            25/11/2020  Retirada de teste de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_usuario_id         IN usuario.usuario_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_hora_ini           IN VARCHAR2,
  p_data_fim           IN VARCHAR2,
  p_hora_fim           IN VARCHAR2,
  p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
  p_obs                IN VARCHAR2,
  p_flag_os_aprov_auto IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_data               apontam_data.data%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_papel_id           apontam_hora.papel_id%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_custo              apontam_data.custo_hora%TYPE;
  v_custo_en           apontam_data.custo_hora%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_status             apontam_data.status%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_horas              apontam_hora.horas%TYPE;
  v_area_papel_id      apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id    apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id    apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id    apontam_hora.unid_neg_job_id%TYPE;
  v_apontam_progr_id   apontam_progr.apontam_progr_id%TYPE;
  v_data_ini           apontam_progr.data_ini%TYPE;
  v_data_fim           apontam_progr.data_fim%TYPE;
  v_nivel              usuario_cargo.nivel%TYPE;
  v_cod_apontam        tipo_apontam.codigo%TYPE;
  v_flag_ausencia      tipo_apontam.flag_ausencia%TYPE;
  v_flag_ausencia_full tipo_apontam.flag_ausencia_full%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_salario_id         salario.salario_id%TYPE;
  v_lbl_jobs           VARCHAR2(100);
  v_flag_salario_obrig VARCHAR2(50);
  v_usuario            pessoa.apelido%TYPE;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_xml_atual          CLOB;
  v_horas_info         NUMBER(20, 2);
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_jobs           := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  --ALCBO
  /*
  IF 1 = 1
    THEN
      p_erro_cod := '90000';
      p_erro_msg := 'HORA_INI => '||  p_hora_ini ||  ' HORA_FIM =>' ||  p_hora_fim;
      RAISE v_exception;
  END IF;
  */
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário de sessão não existe.';
   RAISE v_exception;
  END IF;
  --
  IF p_usuario_id IS NULL OR p_usuario_id = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do usuário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  /*
    IF p_usuario_sessao_id <> p_usuario_id THEN
       -- verifica se o usuario tem privilegio
       IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'AUSENCIA_C', NULL, NULL, p_empresa_id) <> 1 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
          RAISE v_exception;
       END IF;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_apontam_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se eh mesmo um apontamento administrativo pertencente a empresa
  SELECT MAX(codigo),
         MAX(flag_ausencia),
         MAX(flag_ausencia_full)
    INTO v_cod_apontam,
         v_flag_ausencia,
         v_flag_ausencia_full
    FROM tipo_apontam
   WHERE empresa_id = p_empresa_id
     AND tipo_apontam_id = p_tipo_apontam_id
     AND flag_sistema = 'N';
  --
  IF v_cod_apontam IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento inválido ou inexistente.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_ini) IS NULL OR rtrim(p_data_fim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_ausencia = 'S' AND v_flag_ausencia_full = 'N' AND
     (TRIM(p_hora_ini) IS NULL OR TRIM(p_hora_fim) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de programação, o preenchimento do horário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_ini) IS NULL THEN
   v_data_ini := data_converter(p_data_ini);
  ELSE
   IF hora_validar(p_hora_ini) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Hora inválida (' || p_hora_ini || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_ini := data_hora_converter(p_data_ini || ' ' || p_hora_ini);
  END IF;
  --
  IF data_validar(p_data_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_fim) IS NULL THEN
   v_data_fim := data_converter(p_data_fim);
  ELSE
   IF hora_validar(p_hora_fim) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Hora inválida (' || p_hora_fim || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_fim := data_hora_converter(p_data_fim || ' ' || p_hora_fim);
  END IF;
  --
  IF v_data_ini > v_data_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início do período não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  -- horas informadas na interface
  v_horas_info := 0;
  IF v_flag_ausencia = 'S' AND v_flag_ausencia_full = 'N' THEN
   IF trunc(v_data_ini) <> trunc(v_data_fim) THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de programação, a data de início deve ser igual à data final.';
    RAISE v_exception;
   END IF;
   --
   -- quando as horas sao informadas, o periodo nao pode passar de 1 dia
   v_horas_info := (v_data_fim - v_data_ini) * 24;
   IF v_horas_info > 24 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Intervalo de horas inválido.';
    RAISE v_exception;
   END IF;
   --
   v_horas_info := nvl(feriado_pkg.dif_horas_uteis_retornar(p_usuario_id,
                                                            p_empresa_id,
                                                            v_data_ini,
                                                            v_data_fim,
                                                            'N'),
                       0);

  END IF;
  --
  IF length(TRIM(p_obs)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do motivo/observações não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_apontam = 'OUT' AND rtrim(p_obs) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação do motivo/observações é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_apontam <> 'OUT' AND rtrim(p_obs) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação do motivo só deve ser preenchida ' ||
                 'quando a opção "Outros" for selecionada.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_os_aprov_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação automática de Workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  /*--ALCBO
  IF 1 = 1
    THEN
      p_erro_cod := '90000';
      p_erro_msg := 'DATA_INI => '||  v_data_ini ||  ' HORA_INI =>' ||  v_data_fim;
      RAISE v_exception;
  END IF;
  */
  -- verifica se ja existe alguma programacao nesse periodo
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE usuario_id = p_usuario_id
     AND (trunc(v_data_ini) BETWEEN trunc(data_ini) AND trunc(data_fim) OR
         trunc(v_data_fim) BETWEEN trunc(data_ini) AND trunc(data_fim) OR
         trunc(data_ini) BETWEEN trunc(v_data_ini) AND trunc(v_data_fim));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe uma programação de férias/ausência nesse período.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se ja existem apontamentos nesse periodo
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data ad,
         apontam_hora ah,
         tipo_apontam ti
   WHERE ad.usuario_id = p_usuario_id
     AND ad.data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim)
     AND ad.apontam_data_id = ah.apontam_data_id
     AND ah.tipo_apontam_id = ti.tipo_apontam_id
     AND ti.flag_sistema = 'S';
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário já tem apontamento de horas nesse período.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o usuario tem papel para apontar horas.
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
  IF v_qt = 0 THEN
   -- pega qualquer papel do usuario
   SELECT MAX(pa.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = p_usuario_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id;
   --
   IF v_papel_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não tem papel associado.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  SELECT NULL,
         min_horas_apont_dia,
         num_horas_prod_dia
    INTO v_nivel,
         v_num_horas_dia,
         v_num_horas_prod_dia
    FROM usuario
   WHERE usuario_id = p_usuario_id;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = p_usuario_id;
  --
  IF v_num_horas_dia IS NULL THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(p_usuario_id, p_empresa_id, NULL, NULL);
  --
  v_unid_neg_job_id := NULL;
  v_unid_neg_cli_id := NULL;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM apontam_hora ah
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_id = p_usuario_id
             AND ad.apontam_data_id = ah.apontam_data_id
             AND ad.data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim));
  --
  --
  DELETE FROM apontam_data_ev ae
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ad.usuario_id = p_usuario_id
             AND ad.data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim)
             AND ad.apontam_data_id = ae.apontam_data_id);
  --
  DELETE FROM apontam_data
   WHERE usuario_id = p_usuario_id
     AND data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim);
  --
  v_data := trunc(v_data_ini);
  --
  WHILE v_data <= trunc(v_data_fim)
  LOOP
   IF feriado_pkg.dia_util_verificar(p_usuario_id, v_data, 'S') = 1 THEN
    v_cargo_id      := cargo_pkg.do_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
    v_area_cargo_id := NULL;
    --
    IF v_cargo_id IS NOT NULL THEN
     SELECT MAX(area_id)
       INTO v_area_cargo_id
       FROM cargo
      WHERE cargo_id = v_cargo_id;
     --
     v_nivel := cargo_pkg.nivel_usuario_retornar(p_usuario_id, v_data, p_empresa_id);
    END IF;
    --
    SELECT seq_apontam_data.nextval
      INTO v_apontam_data_id
      FROM dual;
    --
    v_salario_id    := salario_pkg.salario_id_retornar(p_usuario_id, v_data);
    v_custo_hora    := 0;
    v_venda_hora    := 0;
    v_custo_hora_en := 0;
    v_venda_hora_en := 0;
    --
    IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (' ||
                   data_mostrar(v_data) || ').';
     RAISE v_exception;
    END IF;
    --
    IF nvl(v_salario_id, 0) > 0 THEN
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
    IF v_horas_info > 0 THEN
     -- usa horas informadas na interface
     v_horas  := v_horas_info;
     v_status := 'PEND';
     --
     IF v_horas_info >= v_num_horas_dia THEN
      v_status := 'APRO';
     END IF;
    ELSE
     -- usa total de horas diarias
     v_horas  := v_num_horas_dia;
     v_status := 'APRO';
    END IF;
    --
    v_custo := round(v_horas * v_custo_hora, 2);
    v_venda := round(v_horas * v_venda_hora, 2);
    --
    -- encripta para salvar
    v_custo_en := util_pkg.num_encode(v_custo);
    --
    IF v_custo_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    v_venda_en := util_pkg.num_encode(v_venda);
    --
    IF v_venda_en = -99999 THEN
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
      data_apont,
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
      v_status,
      SYSDATE,
      v_cargo_id,
      v_area_cargo_id);
    --
    -- cria o apontamento
    INSERT INTO apontam_hora
     (apontam_hora_id,
      apontam_data_id,
      job_id,
      papel_id,
      area_papel_id,
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
      NULL,
      v_papel_id,
      v_area_papel_id,
      v_horas,
      v_custo_en,
      v_venda_en,
      TRIM(p_obs),
      p_tipo_apontam_id,
      v_unid_neg_usu_id,
      v_unid_neg_job_id,
      v_unid_neg_cli_id);
    --
    -- preenche a coluna de horas ajustadas
    apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
    IF p_erro_cod <> '00000' THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   v_data := v_data + 1;
  END LOOP;
  --
  SELECT seq_apontam_progr.nextval
    INTO v_apontam_progr_id
    FROM dual;
  --
  INSERT INTO apontam_progr
   (apontam_progr_id,
    usuario_id,
    data_ini,
    data_fim,
    tipo_apontam_id,
    obs,
    flag_os_aprov_auto)
  VALUES
   (v_apontam_progr_id,
    p_usuario_id,
    v_data_ini,
    v_data_fim,
    p_tipo_apontam_id,
    TRIM(p_obs),
    p_flag_os_aprov_auto);
  --
  ------------------------------------------------------------
  -- tratamento da alocacao
  ------------------------------------------------------------
  IF v_flag_ausencia = 'S' THEN
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         p_usuario_id,
                                         v_data_ini,
                                         v_data_fim,
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
  apontam_progr_pkg.xml_gerar(v_apontam_progr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_usuario || ' - ' || data_hora_mostrar(v_data_ini) || ' a ' ||
                      data_hora_mostrar(v_data_fim);

  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'APONTAM_PROGR',
                   'INCLUIR',
                   v_identif_objeto,
                   v_apontam_progr_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 04/09/2015
  -- DESCRICAO: Atualizacao de Programacao de Apontamentos administrativos (ferias, outros).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            19/12/2016  Horas admin sao incluidas no status APRO ao inves de ENCE
  -- Silvia            11/04/2017  Novo parametro flag_os_aprov_auto
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Silvia            14/09/2017  Programacao liberada para usuarios que nao apontam horas.
  -- Silvia            20/02/2018  Inclusao de area do papel.
  -- Silvia            27/03/2018  Novo priviletio AUSENCIA_C.
  -- Silvia            14/01/2020  Chamada da alocacao_processar.
  -- Silvia            18/06/2020  Novos parametros para horario
  -- Silvia            09/07/2020  Instancia unidade negocio (cli, job, usu)
  -- Silvia            25/11/2020  Retirada de teste de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN usuario.usuario_id%TYPE,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_apontam_progr_id   IN apontam_progr.apontam_progr_id%TYPE,
  p_data_ini           IN VARCHAR2,
  p_hora_ini           IN VARCHAR2,
  p_data_fim           IN VARCHAR2,
  p_hora_fim           IN VARCHAR2,
  p_tipo_apontam_id    IN tipo_apontam.tipo_apontam_id%TYPE,
  p_obs                IN VARCHAR2,
  p_flag_os_aprov_auto IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS

  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_apontam_data_id    apontam_data.apontam_data_id%TYPE;
  v_data               apontam_data.data%TYPE;
  v_status_apontam     apontam_data.status%TYPE;
  v_papel_id           apontam_hora.papel_id%TYPE;
  v_custo_hora         apontam_data.custo_hora%TYPE;
  v_custo_hora_en      apontam_data.custo_hora%TYPE;
  v_custo              apontam_data.custo_hora%TYPE;
  v_custo_en           apontam_data.custo_hora%TYPE;
  v_status             apontam_data.status%TYPE;
  v_venda_hora         apontam_data.venda_hora%TYPE;
  v_venda_hora_en      apontam_data.venda_hora%TYPE;
  v_cargo_id           apontam_data.cargo_id%TYPE;
  v_area_cargo_id      apontam_data.area_cargo_id%TYPE;
  v_venda              apontam_hora.venda%TYPE;
  v_venda_en           apontam_hora.venda%TYPE;
  v_horas              apontam_hora.horas%TYPE;
  v_horas_atu          apontam_hora.horas%TYPE;
  v_area_papel_id      apontam_hora.area_papel_id%TYPE;
  v_unid_neg_usu_id    apontam_hora.unid_neg_usu_id%TYPE;
  v_unid_neg_cli_id    apontam_hora.unid_neg_cli_id%TYPE;
  v_unid_neg_job_id    apontam_hora.unid_neg_job_id%TYPE;
  v_usuario_id         apontam_progr.usuario_id%TYPE;
  v_data_ini           apontam_progr.data_ini%TYPE;
  v_data_fim           apontam_progr.data_fim%TYPE;
  v_data_ini_old       apontam_progr.data_ini%TYPE;
  v_data_fim_old       apontam_progr.data_fim%TYPE;
  v_data_ini_aux       apontam_progr.data_ini%TYPE;
  v_data_fim_aux       apontam_progr.data_fim%TYPE;
  v_cod_apontam        tipo_apontam.codigo%TYPE;
  v_flag_ausencia      tipo_apontam.flag_ausencia%TYPE;
  v_flag_ausencia_full tipo_apontam.flag_ausencia_full%TYPE;
  v_num_horas_dia      NUMBER;
  v_num_horas_prod_dia NUMBER;
  v_salario_id         salario.salario_id%TYPE;
  v_usuario            pessoa.apelido%TYPE;
  v_nivel              usuario_cargo.nivel%TYPE;
  v_lbl_jobs           VARCHAR2(100);
  v_flag_salario_obrig VARCHAR2(50);
  v_tem_apont_normal   NUMBER(10);
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  v_horas_info         NUMBER(20, 2);
  --
 BEGIN
  v_qt                 := 0;
  v_lbl_jobs           := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  v_flag_salario_obrig := empresa_pkg.parametro_retornar(p_empresa_id, 'FLAG_SALARIO_OBRIGATORIO');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário de sessão não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE apontam_progr_id = p_apontam_progr_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa programação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT usuario_id,
         data_ini,
         data_fim
    INTO v_usuario_id,
         v_data_ini_old,
         v_data_fim_old
    FROM apontam_progr
   WHERE apontam_progr_id = p_apontam_progr_id;
  --
  /*
    IF p_usuario_sessao_id <> v_usuario_id THEN
       -- verifica se o usuario tem privilegio
       IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'AUSENCIA_C', NULL, NULL, p_empresa_id) <> 1 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
          RAISE v_exception;
       END IF;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_tipo_apontam_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de apontamento é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se eh mesmo um apontamento administrativo pertencente a empresa
  SELECT MAX(codigo),
         MAX(flag_ausencia),
         MAX(flag_ausencia_full)
    INTO v_cod_apontam,
         v_flag_ausencia,
         v_flag_ausencia_full
    FROM tipo_apontam
   WHERE empresa_id = p_empresa_id
     AND tipo_apontam_id = p_tipo_apontam_id
     AND flag_sistema = 'N';
  --
  IF v_cod_apontam IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de apontamento inválido ou inexistente.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_data_ini) IS NULL OR rtrim(p_data_fim) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do período é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_ausencia = 'S' AND v_flag_ausencia_full = 'N' AND
     (TRIM(p_hora_ini) IS NULL OR TRIM(p_hora_fim) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de programação, o preenchimento do horário é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF data_validar(p_data_ini) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_ini || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_ini) IS NULL THEN
   v_data_ini := data_converter(p_data_ini);
  ELSE
   IF hora_validar(p_hora_ini) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Hora inválida (' || p_hora_ini || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_ini := data_hora_converter(p_data_ini || ' ' || p_hora_ini);
  END IF;
  --
  IF data_validar(p_data_fim) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Data inválida (' || p_data_fim || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_hora_fim) IS NULL THEN
   v_data_fim := data_converter(p_data_fim);
  ELSE
   IF hora_validar(p_hora_fim) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Hora inválida (' || p_hora_fim || ').';
    RAISE v_exception;
   END IF;
   --
   v_data_fim := data_hora_converter(p_data_fim || ' ' || p_hora_fim);
  END IF;
  --
  IF v_data_ini > v_data_fim THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de início do período não pode ser maior que a data final.';
   RAISE v_exception;
  END IF;
  --
  -- horas informadas na interface
  v_horas_info := 0;
  IF v_flag_ausencia = 'S' AND v_flag_ausencia_full = 'N' THEN
   IF trunc(v_data_ini) <> trunc(v_data_fim) THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de programação, a data de início deve ser igual à data final.';
    RAISE v_exception;
   END IF;
   --
   -- quando as horas sao informadas, o periodo nao pode passar de 1 dia
   v_horas_info := (v_data_fim - v_data_ini) * 24;
   IF v_horas_info > 24 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Intervalo de horas inválido.';
    RAISE v_exception;
   END IF;
   --
   v_horas_info := nvl(feriado_pkg.dif_horas_uteis_retornar(v_usuario_id,
                                                            p_empresa_id,
                                                            v_data_ini,
                                                            v_data_fim,
                                                            'N'),
                       0);

  END IF;
  --
  IF length(TRIM(p_obs)) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O texto do motivo/observações não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_apontam = 'OUT' AND rtrim(p_obs) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação do motivo/observações é obrigatória.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_apontam <> 'OUT' AND rtrim(p_obs) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A especificação do motivo só deve ser preenchida ' ||
                 'quando a opção "Outros" for selecionada.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_os_aprov_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag aprovação automática de Workflow inválido.';
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
   WHERE usuario_id = v_usuario_id;
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = v_usuario_id;
  --
  -- verifica se o usuario tem papel para apontar horas.
  SELECT COUNT(*),
         MAX(pa.papel_id)
    INTO v_qt,
         v_papel_id
    FROM usuario_papel up,
         papel         pa
   WHERE up.usuario_id = v_usuario_id
     AND up.papel_id = pa.papel_id
     AND pa.flag_apontam_form = 'S'
     AND pa.empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   -- pega qualquer papel do usuario
   SELECT MAX(pa.papel_id)
     INTO v_papel_id
     FROM usuario_papel up,
          papel         pa
    WHERE up.usuario_id = v_usuario_id
      AND up.papel_id = pa.papel_id
      AND pa.empresa_id = p_empresa_id;
   --
   IF v_papel_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário não tem papel associado.';
    RAISE v_exception;
   END IF;

  END IF;
  --
  IF v_num_horas_dia IS NULL THEN
   v_num_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                      'NUM_MIN_HORAS_APONTADAS_DIA'));
  END IF;
  --
  IF v_num_horas_prod_dia IS NULL THEN
   v_num_horas_prod_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                           'NUM_HORAS_PRODUTIVAS'));
  END IF;
  --
  v_unid_neg_usu_id := usuario_pkg.unid_negocio_retornar(v_usuario_id, p_empresa_id, NULL, NULL);
  --
  v_unid_neg_job_id := NULL;
  v_unid_neg_cli_id := NULL;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  apontam_progr_pkg.xml_gerar(p_apontam_progr_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- limpa eventuais registros futuros
  DELETE FROM apontam_hora ah
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ah.apontam_data_id = ad.apontam_data_id
             AND ad.usuario_id = v_usuario_id
             AND ad.data BETWEEN trunc(v_data_ini_old) AND trunc(v_data_fim_old)
             AND ad.data > trunc(SYSDATE));
  --
  DELETE FROM apontam_data ad
   WHERE usuario_id = v_usuario_id
     AND data BETWEEN trunc(v_data_ini_old) AND trunc(v_data_fim_old)
     AND data > trunc(SYSDATE)
     AND NOT EXISTS (SELECT 1
            FROM apontam_hora ah
           WHERE ah.apontam_data_id = ad.apontam_data_id);
  --
  v_data := trunc(v_data_ini);
  WHILE v_data <= trunc(v_data_fim)
  LOOP
   -- verifica o status do apontamento nessa data
   SELECT MAX(status),
          MAX(apontam_data_id)
     INTO v_status_apontam,
          v_apontam_data_id
     FROM apontam_data ad
    WHERE ad.usuario_id = v_usuario_id
      AND ad.data = v_data;
   --
   -- verifica se existem apontamentos normais (nao administrativos)
   SELECT COUNT(*)
     INTO v_tem_apont_normal
     FROM apontam_data ad,
          apontam_hora ah,
          tipo_apontam ti
    WHERE ad.usuario_id = v_usuario_id
      AND ad.data = v_data
      AND ad.apontam_data_id = ah.apontam_data_id
      AND ah.tipo_apontam_id = ti.tipo_apontam_id
      AND ti.flag_sistema = 'S';
   --
   IF nvl(v_status_apontam, 'PEND') = 'PEND' AND
      feriado_pkg.dia_util_verificar(v_usuario_id, v_data, 'S') = 1 THEN
    -- dia util pendente (ou inexistente)
    v_cargo_id      := cargo_pkg.do_usuario_retornar(v_usuario_id, v_data, p_empresa_id);
    v_area_cargo_id := NULL;
    --
    IF v_cargo_id IS NOT NULL THEN
     SELECT MAX(area_id)
       INTO v_area_cargo_id
       FROM cargo
      WHERE cargo_id = v_cargo_id;
     --
     v_nivel := cargo_pkg.nivel_usuario_retornar(v_usuario_id, v_data, p_empresa_id);
    END IF;
    --
    v_salario_id    := salario_pkg.salario_id_retornar(v_usuario_id, v_data);
    v_custo_hora    := 0;
    v_venda_hora    := 0;
    v_custo_hora_en := 0;
    v_venda_hora_en := 0;
    --
    IF v_flag_salario_obrig = 'S' AND nvl(v_salario_id, 0) = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Não existe salário definido para esse usuário ' || 'nessa data (' ||
                   data_mostrar(v_data) || ').';
     RAISE v_exception;
    END IF;
    --
    IF nvl(v_salario_id, 0) > 0 THEN
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
    IF v_horas_info > 0 THEN
     -- usa horas informadas na interface
     v_horas  := v_horas_info;
     v_status := 'PEND';
     --
     IF v_horas_info >= v_num_horas_dia THEN
      v_status := 'APRO';
     END IF;
    ELSE
     -- usa total de horas diarias
     v_horas  := v_num_horas_dia;
     v_status := 'APRO';
    END IF;
    --
    IF v_apontam_data_id IS NULL THEN
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
       data_apont,
       cargo_id,
       area_cargo_id)
     VALUES
      (v_apontam_data_id,
       v_usuario_id,
       v_data,
       v_custo_hora_en,
       v_venda_hora_en,
       v_nivel,
       v_num_horas_dia,
       v_num_horas_prod_dia,
       v_status,
       SYSDATE,
       v_cargo_id,
       v_area_cargo_id);

    ELSE
     UPDATE apontam_data
        SET status             = v_status,
            data_apont         = SYSDATE,
            custo_hora         = v_custo_hora_en,
            venda_hora         = v_venda_hora_en,
            num_horas_dia      = v_num_horas_dia,
            num_horas_prod_dia = v_num_horas_prod_dia,
            nivel              = v_nivel,
            cargo_id           = v_cargo_id,
            area_cargo_id      = v_area_cargo_id
      WHERE apontam_data_id = v_apontam_data_id;
     --
     IF v_tem_apont_normal = 0 THEN
      -- so tem apontam admin. Pode apagar.
      DELETE FROM apontam_hora
       WHERE apontam_data_id = v_apontam_data_id;

     ELSE
      -- ja foram feitos apontam normais. Mantem e complementa com o saldo,
      -- caso as horas nao tenham sido informadas.
      SELECT nvl(SUM(ah.horas), 0)
        INTO v_horas_atu
        FROM apontam_data ad,
             apontam_hora ah
       WHERE ad.usuario_id = v_usuario_id
         AND ad.data = v_data
         AND ad.apontam_data_id = ah.apontam_data_id;
      --
      IF v_horas_info > 0 THEN
       -- mantem as horas informadas
       IF v_horas_info + v_horas_atu >= v_num_horas_dia THEN
        v_status := 'APRO';
       END IF;
      ELSE
       -- complementa o dia com o saldo
       v_horas := v_num_horas_dia - v_horas_atu;
      END IF;

     END IF;

    END IF;
    --
    -- lanca o apontamento administrativo
    IF v_horas > 0 THEN
     v_custo := round(v_horas * v_custo_hora, 2);
     v_venda := round(v_horas * v_venda_hora, 2);
     --
     -- encripta para salvar
     v_custo_en := util_pkg.num_encode(v_custo);
     --
     IF v_custo_en = -99999 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_custo, 'N') || ').';
      RAISE v_exception;
     END IF;
     --
     v_venda_en := util_pkg.num_encode(v_venda);
     --
     IF v_venda_en = -99999 THEN
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
       papel_id,
       area_papel_id,
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
       NULL,
       v_papel_id,
       v_area_papel_id,
       v_horas,
       v_custo_en,
       v_venda_en,
       TRIM(p_obs),
       p_tipo_apontam_id,
       v_unid_neg_usu_id,
       v_unid_neg_job_id,
       v_unid_neg_cli_id);
     --
     -- preenche a coluna de horas ajustadas
     apontam_pkg.apontamento_horas_ajustar(v_apontam_data_id, p_erro_cod, p_erro_msg);
     IF p_erro_cod <> '00000' THEN
      RAISE v_exception;
     END IF;
    END IF;

   END IF;
   --
   v_data := v_data + 1;
  END LOOP;
  --
  UPDATE apontam_progr
     SET data_ini           = v_data_ini,
         data_fim           = v_data_fim,
         tipo_apontam_id    = p_tipo_apontam_id,
         obs                = TRIM(p_obs),
         flag_os_aprov_auto = p_flag_os_aprov_auto
   WHERE apontam_progr_id = p_apontam_progr_id;
  --
  ------------------------------------------------------------
  -- tratamento da alocacao
  ------------------------------------------------------------
  v_data_ini_aux := v_data_ini;
  v_data_fim_aux := v_data_fim;
  --
  IF v_data_ini_old < v_data_ini THEN
   v_data_ini_aux := v_data_ini_old;
  END IF;
  --
  IF v_data_fim_old > v_data_fim THEN
   v_data_fim_aux := v_data_fim_old;
  END IF;
  --
  cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_usuario_id,
                                        v_data_ini_aux,
                                        v_data_fim_aux,
                                        p_erro_cod,
                                        p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  apontam_progr_pkg.xml_gerar(p_apontam_progr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_usuario || ' - ' || data_hora_mostrar(v_data_ini) || ' a ' ||
                      data_hora_mostrar(v_data_fim);

  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'APONTAM_PROGR',
                   'ALTERAR',
                   v_identif_objeto,
                   p_apontam_progr_id,
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 26/06/2008
  -- DESCRICAO: Exclusão de Programacao de Apontamentos
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/11/2009  Consistencias adicionais para o periodo informado.
  -- Silvia            24/04/2013  Nova tabela para tipo de apontamento.
  -- Silvia            12/09/2017  Implementacao de historico c/ XML.
  -- Silvia            27/03/2018  Novo priviletio AUSENCIA_C.
  -- Silvia            14/01/2020  Chamada da alocacao_processar.
  -- Silvia            25/11/2020  Retirada de teste de privilegio
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_apontam_progr_id  IN apontam_progr.apontam_progr_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS

  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_data_ini       apontam_progr.data_ini%TYPE;
  v_data_fim       apontam_progr.data_fim%TYPE;
  v_data           apontam_data.data%TYPE;
  v_usuario_id     apontam_data.usuario_id%TYPE;
  v_usuario        pessoa.apelido%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_flag_ausencia  tipo_apontam.flag_ausencia%TYPE;
  --
 BEGIN
  v_qt       := 0;
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse usuário de sessão não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_progr
   WHERE apontam_progr_id = p_apontam_progr_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa programação não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT ap.usuario_id,
         ap.data_ini,
         ap.data_fim,
         ta.flag_ausencia
    INTO v_usuario_id,
         v_data_ini,
         v_data_fim,
         v_flag_ausencia
    FROM apontam_progr ap,
         tipo_apontam  ta
   WHERE ap.apontam_progr_id = p_apontam_progr_id
     AND ap.tipo_apontam_id = ta.tipo_apontam_id;
  --
  /*
    IF p_usuario_sessao_id <> v_usuario_id THEN
       -- verifica se o usuario tem privilegio
       IF USUARIO_PKG.PRIV_VERIFICAR(p_usuario_sessao_id,'AUSENCIA_C', NULL, NULL, p_empresa_id) <> 1 THEN
          p_erro_cod := '90000';
          p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
          RAISE v_exception;
       END IF;
    END IF;
  */
  --
  SELECT MAX(apelido)
    INTO v_usuario
    FROM pessoa
   WHERE usuario_id = v_usuario_id;
  --
  -- verifica se ja existem apontamentos nesse periodo
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_data ad,
         apontam_hora ah,
         tipo_apontam ti
   WHERE ad.usuario_id = v_usuario_id
     AND ad.data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim)
     AND ad.apontam_data_id = ah.apontam_data_id
     AND ah.tipo_apontam_id = ti.tipo_apontam_id
     AND ti.flag_sistema = 'S';
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O usuário já tem apontamentos não administrativos nesse período.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  apontam_progr_pkg.xml_gerar(p_apontam_progr_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- mantem as datas geradas, mas como pendentes
  UPDATE apontam_data
     SET status     = 'PEND',
         data_apont = NULL
   WHERE usuario_id = v_usuario_id
     AND data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim);
  --
  -- apaga as horas nesse intervalo
  DELETE FROM apontam_hora ah
   WHERE EXISTS (SELECT 1
            FROM apontam_data ad
           WHERE ah.apontam_data_id = ad.apontam_data_id
             AND ad.usuario_id = v_usuario_id
             AND ad.data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim));
  --
  -- limpa as datas futuras
  DELETE FROM apontam_data ad
   WHERE usuario_id = v_usuario_id
     AND data BETWEEN trunc(v_data_ini) AND trunc(v_data_fim)
     AND data > trunc(SYSDATE)
     AND NOT EXISTS (SELECT 1
            FROM apontam_hora ah
           WHERE ah.apontam_data_id = ad.apontam_data_id);
  --
  DELETE FROM apontam_progr
   WHERE apontam_progr_id = p_apontam_progr_id;
  --
  ------------------------------------------------------------
  -- tratamento da alocacao
  ------------------------------------------------------------
  IF v_flag_ausencia = 'S' THEN
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         v_usuario_id,
                                         v_data_ini,
                                         v_data_fim,
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
  v_identif_objeto := v_usuario || ' - ' || data_hora_mostrar(v_data_ini) || ' a ' ||
                      data_hora_mostrar(v_data_fim);

  v_compl_histor := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'APONTAM_PROGR',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_apontam_progr_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);

   ROLLBACK;
 END excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 12/09/2017
  -- DESCRICAO: Subrotina que gera o xml de APONTAM_PROGR para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_apontam_progr_id IN apontam_progr.apontam_progr_id%TYPE,
  p_xml              OUT CLOB,
  p_erro_cod         OUT VARCHAR2,
  p_erro_msg         OUT VARCHAR2
 ) IS

  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("apontam_progr_id", ap.apontam_progr_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("usuario_program", pe.apelido),
                   xmlelement("tipo_program", ta.nome),
                   xmlelement("data_inicio", data_hora_mostrar(ap.data_ini)),
                   xmlelement("data_fim", data_hora_mostrar(ap.data_fim)),
                   xmlelement("obs", ap.obs),
                   xmlelement("workflow_aprov_autom", ap.flag_os_aprov_auto))
    INTO v_xml
    FROM apontam_progr ap,
         tipo_apontam  ta,
         pessoa        pe
   WHERE ap.apontam_progr_id = p_apontam_progr_id
     AND ap.tipo_apontam_id = ta.tipo_apontam_id
     AND ap.usuario_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "apontam_progr"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("apontam_progr", v_xml))
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
END; -- APONTAM_PROGR_PKG


/
