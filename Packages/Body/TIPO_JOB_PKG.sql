--------------------------------------------------------
--  DDL for Package Body TIPO_JOB_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TIPO_JOB_PKG" IS
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/07/2008
  -- DESCRICAO: Inclusão de TIPO_JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/08/2011  Novo parametro cod_ext_tipo_job.
  -- Silvia            06/03/2012  Novo parametro modelo_briefing.
  -- Silvia            15/01/2013  Novo parametro flag_padrao.
  -- Silvia            30/11/2015  Novos parametros mod_crono_id, flags aprov autom.
  -- Silvia            12/01/2016  Retirada de flag_data_evento.
  -- Silvia            02/03/2016  Complexidade do job.
  -- Silvia            25/04/2016  Novo flag_alt_tipo_est.
  -- Silvia            11/05/2016  Novos flags p/ campanha.
  -- Silvia            28/06/2016  Novos flags p/ periodo job.
  -- Silvia            10/08/2016  Novos: flag_obriga_data_cli, estrat_job.
  -- Silvia            26/10/2016  Novo: flag_usa_matriz.
  -- Silvia            06/02/2017  Novos: flag_usa_crono_cria_job, flag_obr_crono_cria_job,
  --                               flag_usa_data_cria_job. Retirado: mod_crono_id.
  -- Silvia            16/08/2017  Novo flag_ativo.
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev
  -- Silvia            14/10/2019  Retirada de flag_usa_budget,flag_usa_receita_prev
  -- Silvia            14/08/2020  Novos: flag_usa_data_golive; flag_obr_data_golive
  -- Silvia            26/03/2021  Novos: flag_ender_todos, flag_topo_apont
  -- Silvia            20/07/2021  Novos flag_pode_qq_serv, flag_pode_os, flag_pode_tarefa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_codigo                  IN tipo_job.codigo%TYPE,
  p_nome                    IN tipo_job.nome%TYPE,
  p_cod_ext_tipo_job        IN tipo_job.cod_ext_tipo_job%TYPE,
  p_modelo_briefing         IN tipo_job.modelo_briefing %TYPE,
  p_flag_padrao             IN VARCHAR2,
  p_complex_job_pdr         IN VARCHAR2,
  p_flag_alt_complex        IN VARCHAR2,
  p_flag_alt_tipo_est       IN VARCHAR2,
  p_flag_tem_camp           IN VARCHAR2,
  p_flag_camp_obr           IN VARCHAR2,
  p_flag_pode_qq_serv       IN VARCHAR2,
  p_flag_pode_os            IN VARCHAR2,
  p_flag_pode_tarefa        IN VARCHAR2,
  p_estrat_job              IN VARCHAR2,
  p_flag_usa_per_job        IN VARCHAR2,
  p_flag_usa_data_cli       IN VARCHAR2,
  p_flag_obriga_data_cli    IN VARCHAR2,
  p_flag_usa_data_golive    IN VARCHAR2,
  p_flag_obr_data_golive    IN VARCHAR2,
  p_flag_apr_brief_auto     IN VARCHAR2,
  p_flag_apr_crono_auto     IN VARCHAR2,
  p_flag_apr_horas_auto     IN VARCHAR2,
  p_flag_apr_orcam_auto     IN VARCHAR2,
  p_flag_cria_crono_auto    IN VARCHAR2,
  p_flag_usa_crono_cria_job IN VARCHAR2,
  p_flag_obr_crono_cria_job IN VARCHAR2,
  p_flag_usa_data_cria_job  IN VARCHAR2,
  p_flag_usa_matriz         IN VARCHAR2,
  p_flag_ender_todos        IN VARCHAR2,
  p_flag_topo_apont         IN VARCHAR2,
  p_tipo_job_id             OUT tipo_job.tipo_job_id%TYPE,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_tipo_job_id    tipo_job.tipo_job_id%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt          := 0;
  p_tipo_job_id := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_job_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade padrão não informada.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade padrão inválida (' || p_complex_job_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_alt_complex) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera complexidade inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_alt_tipo_est) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera tipo da estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_camp) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita campanha inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_camp_obr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga preenchimento da campanha inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tem_camp = 'N' AND p_flag_camp_obr = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da campanha só pode ser obrigatório quando ' ||
                 'o uso da campanha estiver habilitado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_qq_serv) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode qualquer produto inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_os) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode ter workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_tarefa) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode ter task inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_matriz) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita matriz inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ender_todos) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag endereçar todos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_topo_apont) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag topo da lista de apontamentos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_estrat_job) IS NOT NULL AND
     util_pkg.desc_retornar('estrat_job', p_estrat_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Estrategia inválida (' || p_estrat_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_per_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar período do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar data de apresentação ao cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_data_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigar data de apresentação ao cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_golive) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar data de golive inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obr_data_golive) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigar data de golive inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_apr_brief_auto) = 0 OR flag_validar(p_flag_apr_crono_auto) = 0 OR
     flag_validar(p_flag_apr_orcam_auto) = 0 OR flag_validar(p_flag_apr_horas_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de aprovação automática inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_cria_crono_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag cria cronograma automático inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_crono_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag usa cronograma na criação do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obr_crono_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga cronograma na criação do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag usa data da criação do job no cronograma inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tipo_job.nextval
    INTO v_tipo_job_id
    FROM dual;
  --
  INSERT INTO tipo_job
   (tipo_job_id,
    empresa_id,
    codigo,
    nome,
    cod_ext_tipo_job,
    modelo_briefing,
    flag_padrao,
    flag_apr_brief_auto,
    flag_apr_crono_auto,
    flag_apr_orcam_auto,
    flag_apr_horas_auto,
    flag_cria_crono_auto,
    flag_usa_crono_cria_job,
    flag_obr_crono_cria_job,
    flag_usa_data_cria_job,
    complex_job_pdr,
    flag_alt_complex,
    flag_alt_tipo_est,
    flag_tem_camp,
    flag_camp_obr,
    flag_pode_qq_serv,
    flag_pode_os,
    flag_pode_tarefa,
    flag_usa_per_job,
    flag_usa_data_cli,
    flag_obriga_data_cli,
    flag_usa_matriz,
    flag_ender_todos,
    flag_topo_apont,
    estrat_job,
    flag_ativo,
    flag_usa_data_golive,
    flag_obr_data_golive)
  VALUES
   (v_tipo_job_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    TRIM(p_cod_ext_tipo_job),
    p_modelo_briefing,
    p_flag_padrao,
    p_flag_apr_brief_auto,
    p_flag_apr_crono_auto,
    p_flag_apr_orcam_auto,
    p_flag_apr_horas_auto,
    p_flag_cria_crono_auto,
    p_flag_usa_crono_cria_job,
    p_flag_obr_crono_cria_job,
    p_flag_usa_data_cria_job,
    p_complex_job_pdr,
    p_flag_alt_complex,
    p_flag_alt_tipo_est,
    p_flag_tem_camp,
    p_flag_camp_obr,
    p_flag_pode_qq_serv,
    p_flag_pode_os,
    p_flag_pode_tarefa,
    p_flag_usa_per_job,
    p_flag_usa_data_cli,
    p_flag_obriga_data_cli,
    p_flag_usa_matriz,
    p_flag_ender_todos,
    p_flag_topo_apont,
    p_estrat_job,
    'S',
    p_flag_usa_data_golive,
    p_flag_obr_data_golive);
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo de job pode ser padrao.
   UPDATE tipo_job
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_job_id <> v_tipo_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(v_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo));
  v_compl_histor   := TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tipo_job_id,
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
  p_tipo_job_id := v_tipo_job_id;
  p_erro_cod    := '00000';
  p_erro_msg    := 'Operação realizada com sucesso.';
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/07/2008
  -- DESCRICAO: Atualização de TIPO_JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/08/2011  Novo parametro cod_ext_tipo_job.
  -- Silvia            06/03/2012  Novo parametro modelo_briefing.
  -- Silvia            15/01/2013  Novo parametro flag_padrao.
  -- Silvia            30/11/2015  Novos parametros mod_crono_id, flags aprov autom.
  -- Silvia            12/01/2016  Retirada de flag_data_evento.
  -- Silvia            02/03/2016  Complexidade do job.
  -- Silvia            25/04/2016  Novo flag_alt_tipo_est.
  -- Silvia            11/05/2016  Novos flags p/ campanha.
  -- Silvia            28/06/2016  Novos flags p/ periodo job.
  -- Silvia            10/08/2016  Novos: flag_obriga_data_cli, estrat_job.
  -- Silvia            26/10/2016  Novo: flag_usa_matriz.
  -- Silvia            06/02/2017  Novos: flag_usa_crono_cria_job, flag_obr_crono_cria_job,
  --                               flag_usa_data_cria_job. Retirado: mod_crono_id.
  -- Silvia            16/08/2017  Novo flag_ativo.
  -- Silvia            04/10/2018  Novos: flag_usa_budget, flag_usa_receita_prev
  -- Silvia            14/10/2019  Retirada de flag_usa_budget,flag_usa_receita_prev
  -- Silvia            14/08/2020  Novos: flag_usa_data_golive; flag_obr_data_golive
  -- Silvia            26/03/2021  Novos: flag_ender_todos, flag_topo_apont
  -- Silvia            20/07/2021  Novos flag_pode_qq_serv, flag_pode_os, flag_pode_tarefa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id       IN NUMBER,
  p_empresa_id              IN empresa.empresa_id%TYPE,
  p_tipo_job_id             IN tipo_job.tipo_job_id%TYPE,
  p_codigo                  IN tipo_job.codigo%TYPE,
  p_nome                    IN tipo_job.nome%TYPE,
  p_cod_ext_tipo_job        IN tipo_job.cod_ext_tipo_job%TYPE,
  p_modelo_briefing         IN tipo_job.modelo_briefing %TYPE,
  p_flag_ativo              IN VARCHAR2,
  p_flag_padrao             IN VARCHAR2,
  p_complex_job_pdr         IN VARCHAR2,
  p_flag_alt_complex        IN VARCHAR2,
  p_flag_alt_tipo_est       IN VARCHAR2,
  p_flag_tem_camp           IN VARCHAR2,
  p_flag_camp_obr           IN VARCHAR2,
  p_flag_pode_qq_serv       IN VARCHAR2,
  p_flag_pode_os            IN VARCHAR2,
  p_flag_pode_tarefa        IN VARCHAR2,
  p_estrat_job              IN VARCHAR2,
  p_flag_usa_per_job        IN VARCHAR2,
  p_flag_usa_data_cli       IN VARCHAR2,
  p_flag_obriga_data_cli    IN VARCHAR2,
  p_flag_usa_data_golive    IN VARCHAR2,
  p_flag_obr_data_golive    IN VARCHAR2,
  p_flag_apr_brief_auto     IN VARCHAR2,
  p_flag_apr_crono_auto     IN VARCHAR2,
  p_flag_apr_horas_auto     IN VARCHAR2,
  p_flag_apr_orcam_auto     IN VARCHAR2,
  p_flag_cria_crono_auto    IN VARCHAR2,
  p_flag_usa_crono_cria_job IN VARCHAR2,
  p_flag_obr_crono_cria_job IN VARCHAR2,
  p_flag_usa_data_cria_job  IN VARCHAR2,
  p_flag_usa_matriz         IN VARCHAR2,
  p_flag_ender_todos        IN VARCHAR2,
  p_flag_topo_apont         IN VARCHAR2,
  p_erro_cod                OUT VARCHAR2,
  p_erro_msg                OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_ativo = 'N' AND p_flag_padrao = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de ' || v_lbl_job || ' padrão não pode estar inativo.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_complex_job_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade padrão não informada.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('complex_job', p_complex_job_pdr) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Complexidade padrão inválida (' || p_complex_job_pdr || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_alt_complex) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera complexidade inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_alt_tipo_est) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag altera tipo da estimativa inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_tem_camp) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita campanha inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_camp_obr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga preenchimento da campanha inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tem_camp = 'N' AND p_flag_camp_obr = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da campanha só pode ser obrigatório quando ' ||
                 'o uso da campanha estiver habilitado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_qq_serv) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode qualquer produto inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_os) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode ter workflow inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_pode_tarefa) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag pode ter task inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_matriz) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilita matriz inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ender_todos) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag endereçar todos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_topo_apont) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag topo da lista de apontamentos inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_estrat_job) IS NOT NULL AND
     util_pkg.desc_retornar('estrat_job', p_estrat_job) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Estrategia inválida (' || p_estrat_job || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_per_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar período do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar data de apresentação ao cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_data_cli) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigar data de apresentação ao cliente inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_golive) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag habilitar data de golive inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obr_data_golive) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigar data de golive inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_apr_brief_auto) = 0 OR flag_validar(p_flag_apr_crono_auto) = 0 OR
     flag_validar(p_flag_apr_orcam_auto) = 0 OR flag_validar(p_flag_apr_horas_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de aprovação automática inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_cria_crono_auto) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag cria cronograma automático inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_crono_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag usa cronograma na criação do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obr_crono_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga cronograma na criação do job inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_usa_data_cria_job) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag usa data da criação do job no cronograma inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE upper(codigo) = TRIM(upper(p_codigo))
     AND empresa_id = p_empresa_id
     AND tipo_job_id <> p_tipo_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código já existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE upper(nome) = TRIM(upper(p_nome))
     AND empresa_id = p_empresa_id
     AND tipo_job_id <> p_tipo_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tipo_job
     SET codigo                  = TRIM(upper(p_codigo)),
         nome                    = TRIM(p_nome),
         cod_ext_tipo_job        = TRIM(p_cod_ext_tipo_job),
         modelo_briefing         = p_modelo_briefing,
         flag_ativo              = p_flag_ativo,
         flag_padrao             = p_flag_padrao,
         flag_apr_brief_auto     = p_flag_apr_brief_auto,
         flag_apr_crono_auto     = p_flag_apr_crono_auto,
         flag_apr_orcam_auto     = p_flag_apr_orcam_auto,
         flag_apr_horas_auto     = p_flag_apr_horas_auto,
         flag_cria_crono_auto    = p_flag_cria_crono_auto,
         flag_usa_crono_cria_job = p_flag_usa_crono_cria_job,
         flag_obr_crono_cria_job = p_flag_obr_crono_cria_job,
         flag_usa_data_cria_job  = p_flag_usa_data_cria_job,
         complex_job_pdr         = p_complex_job_pdr,
         flag_alt_complex        = p_flag_alt_complex,
         flag_alt_tipo_est       = p_flag_alt_tipo_est,
         flag_tem_camp           = p_flag_tem_camp,
         flag_camp_obr           = p_flag_camp_obr,
         flag_pode_qq_serv       = p_flag_pode_qq_serv,
         flag_pode_os            = p_flag_pode_os,
         flag_pode_tarefa        = p_flag_pode_tarefa,
         flag_usa_per_job        = p_flag_usa_per_job,
         flag_usa_data_cli       = p_flag_usa_data_cli,
         flag_obriga_data_cli    = p_flag_obriga_data_cli,
         flag_usa_matriz         = p_flag_usa_matriz,
         flag_ender_todos        = p_flag_ender_todos,
         flag_topo_apont         = p_flag_topo_apont,
         estrat_job              = p_estrat_job,
         flag_usa_data_golive    = p_flag_usa_data_golive,
         flag_obr_data_golive    = p_flag_obr_data_golive
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF p_flag_padrao = 'S' THEN
   -- apenas um tipo de job pode ser padrao.
   UPDATE tipo_job
      SET flag_padrao = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_job_id <> p_tipo_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(p_codigo));
  v_compl_histor   := TRIM(p_nome);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END; -- atualizar
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 28/07/2008
  -- DESCRICAO: Exclusão de TIPO_JOB
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            02/02/2010  Consistencia de orcamento.
  -- Silvia            27/05/2015  Exclusao automatica de tipo_job_usuario
  -- Silvia            30/11/2015  Tabela fase_crono deixou de existir.
  -- Silvia            21/07/2016  Consistencia de regra de co-enderecamento.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_lbl_jobs       VARCHAR2(100);
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem ' || v_lbl_jobs || ' associados a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcamento
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem Estimativas de Custos associadas a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv_tjob
   WHERE tipo_job_id = p_tipo_job_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem papéis configurados com privilégios para esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM faixa_aprov_os
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem faixas de aprovação associadas a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM regra_coender
   WHERE tipo_job_id = p_tipo_job_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de endereçamento associadas a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_job_usuario
   WHERE tipo_job_id = p_tipo_job_id;
  DELETE FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id;
  DELETE FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_codigo;
  v_compl_histor   := v_nome;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
 END; -- excluir
 --
 --
 PROCEDURE enderecar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 27/05/2015
  -- DESCRICAO: Enderecamento de usuarios no tipo de job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            05/12/2019  Eliminacao de papel da tabela tipo_job_usuario
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN tipo_job.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_area_id           IN papel.area_id%TYPE,
  p_vetor_usuarios    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_vetor_usuarios VARCHAR2(1000);
  v_delimitador    CHAR(1);
  v_usuario_id     usuario.usuario_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_area_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A área não foi informada.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  -- limpa enderecamento atual da area passada no parametro
  DELETE FROM tipo_job_usuario tj
   WHERE tipo_job_id = p_tipo_job_id
     AND EXISTS (SELECT 1
            FROM usuario us
           WHERE us.area_id = p_area_id
             AND us.usuario_id = tj.usuario_id);
  --
  v_delimitador    := '|';
  v_vetor_usuarios := rtrim(p_vetor_usuarios);
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_usuarios)), 0) > 0
  LOOP
   v_usuario_id := nvl(to_number(prox_valor_retornar(v_vetor_usuarios, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM usuario
    WHERE usuario_id = v_usuario_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuario não existe (usuario_id = ' || to_char(v_usuario_id) || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_usuario_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM tipo_job_usuario
     WHERE tipo_job_id = p_tipo_job_id
       AND usuario_id = v_usuario_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO tipo_job_usuario
      (tipo_job_id,
       usuario_id)
     VALUES
      (p_tipo_job_id,
       v_usuario_id);
     --
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome) || ' (alteração regra ender usuário)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END enderecar;
 --
 --
 PROCEDURE papel_priv_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 21/12/2015
  -- DESCRICAO: Alteracao de privilegios para criar job desse tipo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            21/10/2016  Novo atributo em papel_priv (abrangencia).
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN tipo_job.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_vetor_papeis      IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_vetor_papeis   VARCHAR2(1000);
  v_delimitador    CHAR(1);
  v_papel_id       papel.papel_id%TYPE;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
  v_privilegio_id  privilegio.privilegio_id%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'JOB_I';
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_priv_tjob
   WHERE tipo_job_id = p_tipo_job_id;
  --
  DELETE FROM papel_priv pp
   WHERE privilegio_id = v_privilegio_id
     AND NOT EXISTS (SELECT 1
            FROM papel_priv_tjob pt
           WHERE pp.papel_id = pt.papel_id
             AND pp.privilegio_id = pt.privilegio_id);
  --
  v_delimitador  := '|';
  v_vetor_papeis := rtrim(p_vetor_papeis);
  --
  -- loop por papel no vetor
  WHILE nvl(length(rtrim(v_vetor_papeis)), 0) > 0
  LOOP
   v_papel_id := nvl(to_number(prox_valor_retornar(v_vetor_papeis, v_delimitador)), 0);
   --
   IF v_papel_id > 0 THEN
    SELECT COUNT(*)
      INTO v_qt
      FROM papel
     WHERE papel_id = v_papel_id
       AND empresa_id = p_empresa_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Esse papel não existe (papel_id = ' || to_char(v_papel_id) || ').';
     RAISE v_exception;
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_priv
     WHERE papel_id = v_papel_id
       AND privilegio_id = v_privilegio_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO papel_priv
      (papel_id,
       privilegio_id,
       abrangencia)
     VALUES
      (v_papel_id,
       v_privilegio_id,
       'P');
    END IF;
    --
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_priv_tjob
     WHERE tipo_job_id = p_tipo_job_id
       AND papel_id = v_papel_id
       AND privilegio_id = v_privilegio_id;
    --
    IF v_qt = 0 THEN
     INSERT INTO papel_priv_tjob
      (papel_id,
       privilegio_id,
       tipo_job_id)
     VALUES
      (v_papel_id,
       v_privilegio_id,
       p_tipo_job_id);
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome) || ' (alteração privilégio - criar jobs do tipo)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END papel_priv_atualizar;
 --
 --
 PROCEDURE mod_crono_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/02/2017
  -- DESCRICAO: Inclusao de modelo de cronograma ao tipo de job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN tipo_job.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_flag_padrao       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_mod_crono_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do modelo de Cronograma é obrigatório.';
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
   p_erro_msg := 'Esse modelo de Cronograma não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND mod_crono_id = p_mod_crono_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma já está associado a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   UPDATE tipo_job_mod_crono
      SET flag_padrao = 'N'
    WHERE tipo_job_id = p_tipo_job_id;
  END IF;
  --
  INSERT INTO tipo_job_mod_crono
   (tipo_job_id,
    mod_crono_id,
    flag_padrao)
  VALUES
   (p_tipo_job_id,
    p_mod_crono_id,
    p_flag_padrao);
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome) || ' (inclusão de modelo de Cronograma)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END mod_crono_adicionar;
 --
 --
 PROCEDURE mod_crono_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/02/2017
  -- DESCRICAO: Alteração de modelo de cronograma ao tipo de job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN tipo_job.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_flag_padrao       IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND mod_crono_id = p_mod_crono_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não está associado a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  IF flag_validar(p_flag_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag padrão inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_padrao = 'S' THEN
   UPDATE tipo_job_mod_crono
      SET flag_padrao = 'N'
    WHERE tipo_job_id = p_tipo_job_id
      AND mod_crono_id <> p_mod_crono_id;
  END IF;
  --
  UPDATE tipo_job_mod_crono
     SET flag_padrao = p_flag_padrao
   WHERE tipo_job_id = p_tipo_job_id
     AND mod_crono_id = p_mod_crono_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome) || ' (alteração de modelo de Cronograma)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END mod_crono_atualizar;
 --
 --
 PROCEDURE mod_crono_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 06/02/2017
  -- DESCRICAO: Alteração de modelo de cronograma ao tipo de job
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN tipo_job.empresa_id%TYPE,
  p_tipo_job_id       IN tipo_job.tipo_job_id%TYPE,
  p_mod_crono_id      IN mod_crono.mod_crono_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_codigo         tipo_job.codigo%TYPE;
  v_nome           tipo_job.nome%TYPE;
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
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'TIPO_JOB_C', NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND mod_crono_id = p_mod_crono_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse modelo de Cronograma não está associado a esse tipo de ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome
    INTO v_codigo,
         v_nome
    FROM tipo_job
   WHERE tipo_job_id = p_tipo_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tipo_job_mod_crono
   WHERE tipo_job_id = p_tipo_job_id
     AND mod_crono_id = p_mod_crono_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  tipo_job_pkg.xml_gerar(p_tipo_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(upper(v_codigo));
  v_compl_histor   := TRIM(v_nome) || ' (exclusão de modelo de Cronograma)';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TIPO_JOB',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tipo_job_id,
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END mod_crono_excluir;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 13/01/2017
  -- DESCRICAO: Subrotina que gera o xml do tipo de job para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_tipo_job_id IN tipo_job.tipo_job_id%TYPE,
  p_xml         OUT CLOB,
  p_erro_cod    OUT VARCHAR2,
  p_erro_msg    OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_us IS
   SELECT pe.apelido AS usuario
     FROM tipo_job_usuario ju,
          pessoa           pe
    WHERE ju.tipo_job_id = p_tipo_job_id
      AND ju.usuario_id = pe.usuario_id
    ORDER BY pe.apelido;
  --
  CURSOR c_tj IS
   SELECT pr.nome,
          pr.codigo,
          pa.nome AS papel
     FROM privilegio      pr,
          papel_priv_tjob pt,
          papel           pa
    WHERE pt.tipo_job_id = p_tipo_job_id
      AND pt.privilegio_id = pr.privilegio_id
      AND pt.papel_id = pa.papel_id
    ORDER BY pr.nome,
             pa.nome;
  --
  CURSOR c_mc IS
   SELECT mc.nome,
          tm.flag_padrao
     FROM tipo_job_mod_crono tm,
          mod_crono          mc
    WHERE tm.tipo_job_id = p_tipo_job_id
      AND tm.mod_crono_id = mc.mod_crono_id
    ORDER BY mc.nome;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tipo_job_id", tj.tipo_job_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", tj.codigo),
                   xmlelement("nome", tj.nome),
                   xmlelement("ativo", tj.flag_ativo),
                   xmlelement("tipo_padrao", tj.flag_padrao),
                   xmlelement("complex_job_pdr", tj.complex_job_pdr),
                   xmlelement("pode_alt_complex", tj.flag_alt_complex),
                   xmlelement("estrategia_pdr", tj.estrat_job),
                   xmlelement("aprov_autom_brief", tj.flag_apr_brief_auto),
                   xmlelement("aprov_autom_crono", tj.flag_apr_crono_auto),
                   xmlelement("aprov_autom_estim", tj.flag_apr_orcam_auto),
                   xmlelement("aprov_autom_horas", tj.flag_apr_horas_auto),
                   xmlelement("cria_autom_crono", tj.flag_cria_crono_auto),
                   xmlelement("indica_crono_cria_job", tj.flag_usa_crono_cria_job),
                   xmlelement("obriga_crono_cria_job", tj.flag_obr_crono_cria_job),
                   xmlelement("usa_crono_data_cria_job", tj.flag_usa_data_cria_job),
                   xmlelement("pode_alt_tipo_estim", tj.flag_alt_tipo_est),
                   xmlelement("usa_matriz", tj.flag_usa_matriz),
                   xmlelement("ender_todos", tj.flag_ender_todos),
                   xmlelement("topo_lista_apont", tj.flag_topo_apont),
                   xmlelement("usa_periodo_job", tj.flag_usa_per_job),
                   xmlelement("usa_data_apres_cli", tj.flag_usa_data_cli),
                   xmlelement("obriga_data_apres_cli", tj.flag_obriga_data_cli),
                   xmlelement("usa_data_golive", tj.flag_usa_data_golive),
                   xmlelement("obriga_data_golive", tj.flag_obr_data_golive),
                   xmlelement("usa_campanha", tj.flag_tem_camp),
                   xmlelement("obriga_campanha", tj.flag_camp_obr),
                   xmlelement("pode_qq_servico", tj.flag_pode_qq_serv),
                   xmlelement("pode_ter_os", tj.flag_pode_os),
                   xmlelement("pode_ter_tarefa", tj.flag_pode_tarefa),
                   xmlelement("cod_ext_tipo_job", tj.cod_ext_tipo_job))
    INTO v_xml
    FROM tipo_job tj
   WHERE tj.tipo_job_id = p_tipo_job_id;
  --
  ------------------------------------------------------------
  -- monta MODELO CRONO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_mc IN c_mc
  LOOP
   SELECT xmlagg(xmlelement("modelo_crono",
                            xmlelement("nome", r_mc.nome),
                            xmlelement("padrao", r_mc.flag_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("modelos_crono", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta REGRAS ENDER
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_us IN c_us
  LOOP
   SELECT xmlagg(xmlelement("regra_ender", xmlelement("usuario", r_us.usuario)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("regras_ender", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO JOB
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_tj IN c_tj
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_tj.codigo),
                            xmlelement("priv_nome", r_tj.nome),
                            xmlelement("papel", r_tj.papel)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_criar_job_tipo", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tipo_job"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tipo_job", v_xml))
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
END; -- TIPO_JOB_PKG



/
