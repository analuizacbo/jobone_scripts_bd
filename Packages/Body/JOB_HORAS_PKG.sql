--------------------------------------------------------
--  DDL for Package Body JOB_HORAS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "JOB_HORAS_PKG" IS
 --
 g_key_num VARCHAR2(100) := 'C06C35872C9B409A8AB38C7A7E360F3C';
 --
 --
 PROCEDURE horas_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/01/2013
  -- DESCRICAO: Inclusão de horas planejadas no job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            09/03/2015  Novos parametros (usuario_id, venda_hora_rev)
  -- Silvia            23/03/2016  Fator de ajuste.
  -- Silvia            27/05/2016  Encriptacao de valores
  -- Silvia            23/09/2016  Novo tipo POR_CARGO
  -- Silvia            26/12/2017  Testa definicao de cargo do usuario.
  -- Silvia            02/01/2018  Guarda area_id.
  -- Silvia            15/05/2020  Retirada do papel
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_id            IN job_horas.job_id%TYPE,
  p_tipo_formulario   IN VARCHAR2,
  p_usuario_id        IN job_horas.usuario_id%TYPE,
  p_cargo_id          IN job_horas.cargo_id%TYPE,
  p_nivel             IN job_horas.nivel%TYPE,
  p_horas_planej      IN VARCHAR2,
  p_venda_hora_rev    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_status_horas       job.status_horas%TYPE;
  v_nome_cargo         cargo.nome%TYPE;
  v_cargo_id           cargo.cargo_id%TYPE;
  v_horas_planej       job_horas.horas_planej%TYPE;
  v_venda_hora_rev     job_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr     job_horas.venda_hora_pdr%TYPE;
  v_custo_hora_pdr     job_horas.custo_hora_pdr%TYPE;
  v_venda_hora_rev_en  job_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr_en  job_horas.venda_hora_pdr%TYPE;
  v_custo_hora_pdr_en  job_horas.custo_hora_pdr%TYPE;
  v_venda_fator_ajuste job_horas.venda_fator_ajuste%TYPE;
  v_area_id            job_horas.area_id%TYPE;
  v_nome_area          area.nome%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_nome_usuario       pessoa.apelido%TYPE;
  v_salario_id         salario.salario_id%TYPE;
  v_salario_cargo_id   salario_cargo.salario_cargo_id%TYPE;
  v_cronograma_id      item_crono.cronograma_id%TYPE;
  v_item_crono_id      item_crono.item_crono_id%TYPE;
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
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
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                p_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_status_horas, 'PREP') NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_formulario) IS NULL OR p_tipo_formulario NOT IN ('POR_USUARIO', 'POR_CARGO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de formulário inválido (' || p_tipo_formulario || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   IF nvl(p_usuario_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do usuário é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_cargo_id, 0) <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O cargo não deve ser informado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF p_tipo_formulario = 'POR_CARGO' THEN
   IF nvl(p_cargo_id, 0) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento do cargo é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF nvl(p_usuario_id, 0) <> 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O usuário não deve ser informado.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF nvl(p_usuario_id, 0) > 0 THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = p_usuario_id;
   --
   SELECT MAX(area_id)
     INTO v_area_id
     FROM usuario
    WHERE usuario_id = p_usuario_id;
   --
   IF v_area_id IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Usuário ' || v_nome_usuario ||
                  ' sem área definida. Ir em Configuração de Usuários para definir.';
    RAISE v_exception;
   END IF;
   --
   SELECT nome
     INTO v_nome_area
     FROM area
    WHERE area_id = v_area_id;
  END IF;
  --
  IF nvl(p_cargo_id, 0) > 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM cargo
    WHERE cargo_id = p_cargo_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse cargo não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT nome,
          area_id
     INTO v_nome_cargo,
          v_area_id
     FROM cargo
    WHERE cargo_id = p_cargo_id;
  END IF;
  --
  IF TRIM(p_nivel) IS NOT NULL AND util_pkg.desc_retornar('nivel_usuario', p_nivel) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível inválido (' || p_nivel || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_horas_planej) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das horas é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_horas_planej) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  v_horas_planej := nvl(to_number(p_horas_planej), 0);
  --
  IF v_horas_planej < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_venda_hora_rev) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço da hora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_hora_rev) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_rev := nvl(moeda_converter(p_venda_hora_rev), 0);
  --
  IF v_venda_hora_rev < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_horas
    WHERE job_id = p_job_id
      AND usuario_id = p_usuario_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe estimativa de horas para esse usuário.';
    RAISE v_exception;
   END IF;
  ELSIF p_tipo_formulario = 'POR_CARGO' THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM job_horas
    WHERE job_id = p_job_id
      AND cargo_id = p_cargo_id
      AND nvl(nivel, '-') = nvl(TRIM(p_nivel), '-');
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Já existe estimativa de horas para esse cargo/nível.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- recupera valores padrao encriptados
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   v_salario_id := salario_pkg.salario_id_atu_retornar(p_usuario_id);
   --
   SELECT MAX(custo_hora),
          MAX(venda_hora)
     INTO v_custo_hora_pdr_en,
          v_venda_hora_pdr_en
     FROM salario
    WHERE salario_id = v_salario_id;
  ELSIF p_tipo_formulario = 'POR_CARGO' THEN
   v_salario_cargo_id := cargo_pkg.salario_id_atu_retornar(p_cargo_id, p_nivel);
   --
   SELECT MAX(custo_hora),
          MAX(venda_hora)
     INTO v_custo_hora_pdr_en,
          v_venda_hora_pdr_en
     FROM salario_cargo
    WHERE salario_cargo_id = v_salario_cargo_id;
  END IF;
  --
  -- desencripta para poder comparar
  v_venda_hora_pdr := util_pkg.num_decode(v_venda_hora_pdr_en, g_key_num);
  --
  v_venda_fator_ajuste := NULL;
  --
  IF v_venda_hora_pdr = v_venda_hora_rev THEN
   v_venda_fator_ajuste := 1;
  END IF;
  --
  -- encripta para salvar
  v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
  --
  IF v_venda_hora_rev_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  INSERT INTO job_horas
   (job_horas_id,
    job_id,
    usuario_id,
    cargo_id,
    area_id,
    nivel,
    horas_planej,
    venda_hora_rev,
    venda_hora_pdr,
    custo_hora_pdr,
    venda_fator_ajuste)
  VALUES
   (seq_job_horas.nextval,
    p_job_id,
    zvl(p_usuario_id, NULL),
    zvl(p_cargo_id, NULL),
    v_area_id,
    TRIM(p_nivel),
    v_horas_planej,
    v_venda_hora_rev_en,
    v_venda_hora_pdr_en,
    v_custo_hora_pdr_en,
    v_venda_fator_ajuste);
  --
  IF v_status_horas IS NULL THEN
   UPDATE job
      SET status_horas        = 'PREP',
          data_status_horas   = SYSDATE,
          usu_status_horas_id = p_usuario_sessao_id
    WHERE job_id = p_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do cronograma
  ------------------------------------------------------------
  v_cronograma_id := cronograma_pkg.ultimo_retornar(p_job_id);
  --
  IF nvl(v_cronograma_id, 0) = 0 THEN
   -- cria o primeiro cronograma com as atividades obrigatorias
   cronograma_pkg.adicionar(p_usuario_sessao_id,
                            p_empresa_id,
                            'N',
                            p_job_id,
                            v_cronograma_id,
                            p_erro_cod,
                            p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  ELSE
   -- verifica se precisa instanciar a atividade de horas
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'JOB_HORAS',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
   IF p_erro_cod <> '00000' THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  -- vincula a atividade de estimatima de horas ao job
  UPDATE item_crono
     SET objeto_id = p_job_id
   WHERE item_crono_id = v_item_crono_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  IF p_tipo_formulario = 'POR_USUARIO' THEN
   v_compl_histor := 'Inclusão de estimativa de horas: ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  ELSIF p_tipo_formulario = 'POR_CARGO' THEN
   v_compl_histor := 'Inclusão de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(p_nivel), 'ND');
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
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
 END horas_adicionar;
 --
 --
 PROCEDURE horas_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 16/01/2013
  -- DESCRICAO: Alteração de horas planejadas do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            10/04/2015  Novos parametros
  -- Silvia            23/03/2016  Fator de ajuste.
  -- Silvia            27/05/2016  Encriptacao de valores
  -- Silvia            23/09/2016  Novo tipo POR_CARGO
  -- Silvia            15/05/2020  Eliminacao do papel_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_horas_id       IN job_horas.job_horas_id%TYPE,
  p_horas_planej       IN VARCHAR2,
  p_venda_fator_ajuste IN VARCHAR2,
  p_venda_hora_rev     IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_job_id             job.job_id%TYPE;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_status_horas       job.status_horas%TYPE;
  v_usuario_id         job_horas.usuario_id%TYPE;
  v_horas_planej       job_horas.horas_planej%TYPE;
  v_venda_hora_rev     job_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr     job_horas.venda_hora_pdr%TYPE;
  v_venda_hora_rev_en  job_horas.venda_hora_rev%TYPE;
  v_venda_hora_pdr_en  job_horas.venda_hora_pdr%TYPE;
  v_nivel              job_horas.nivel%TYPE;
  v_venda_fator_ajuste job_horas.venda_fator_ajuste%TYPE;
  v_nome_usuario       pessoa.apelido%TYPE;
  v_cargo_id           cargo.cargo_id%TYPE;
  v_nome_cargo         cargo.nome%TYPE;
  v_nome_area          area.nome%TYPE;
  v_area_id            area.area_id%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
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
    FROM job_horas
   WHERE job_horas_id = p_job_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.status_horas,
         jo.job_id,
         jh.usuario_id,
         jh.nivel,
         jh.venda_hora_pdr,
         jh.cargo_id,
         jh.area_id
    INTO v_numero_job,
         v_status_job,
         v_status_horas,
         v_job_id,
         v_usuario_id,
         v_nivel,
         v_venda_hora_pdr_en,
         v_cargo_id,
         v_area_id
    FROM job       jo,
         job_horas jh
   WHERE jh.job_horas_id = p_job_horas_id
     AND jh.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_status_horas, 'PREP') NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;
  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  IF TRIM(p_horas_planej) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento das horas é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_horas_planej) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  v_horas_planej := nvl(to_number(p_horas_planej), 0);
  --
  IF v_horas_planej < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Horas inválidas.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_venda_fator_ajuste) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_fator_ajuste := taxa_converter(TRIM(p_venda_fator_ajuste));
  --
  IF v_venda_fator_ajuste < 0 OR v_venda_fator_ajuste > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_venda_hora_rev) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do preço da hora é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF moeda_validar(p_venda_hora_rev) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_hora_rev := nvl(moeda_converter(p_venda_hora_rev), 0);
  --
  IF v_venda_hora_rev < 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Preço da hora inválido.';
   RAISE v_exception;
  END IF;
  --
  -- desencripta para poder comparar
  v_venda_hora_pdr := util_pkg.num_decode(v_venda_hora_pdr_en, g_key_num);
  --
  IF v_venda_fator_ajuste IS NULL AND v_venda_hora_rev = v_venda_hora_pdr THEN
   v_venda_fator_ajuste := 1;
  END IF;
  --
  -- encripta para salvar
  v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
  --
  IF v_venda_hora_rev_en = -99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job_horas
     SET horas_planej       = v_horas_planej,
         venda_hora_rev     = v_venda_hora_rev_en,
         venda_fator_ajuste = v_venda_fator_ajuste
   WHERE job_horas_id = p_job_horas_id;
  --
  IF v_status_horas IS NULL THEN
   UPDATE job
      SET status_horas        = 'PREP',
          data_status_horas   = SYSDATE,
          usu_status_horas_id = p_usuario_sessao_id
    WHERE job_id = v_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Alteração de estimativa de horas: ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END horas_atualizar;
 --
 --
 PROCEDURE horas_ajustar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 24/03/2016
  -- DESCRICAO: Aplica fator de ajuste no preco de venda das horas do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/05/2016  Encriptacao de valores
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN job.empresa_id%TYPE,
  p_job_id             IN job.job_id%TYPE,
  p_venda_fator_ajuste IN VARCHAR2,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_numero_job         job.numero%TYPE;
  v_status_job         job.status%TYPE;
  v_status_horas       job.status_horas%TYPE;
  v_venda_fator_ajuste job_horas.venda_fator_ajuste%TYPE;
  v_venda_hora_pdr     job_horas.venda_hora_pdr%TYPE;
  v_venda_hora_rev     job_horas.venda_hora_rev%TYPE;
  v_venda_hora_rev_en  job_horas.venda_hora_rev%TYPE;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_xml_antes          CLOB;
  v_xml_atual          CLOB;
  --
  CURSOR c_jh IS
   SELECT job_horas_id,
          venda_hora_pdr AS venda_hora_pdr_en
     FROM job_horas
    WHERE job_id = p_job_id;
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
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse job não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                p_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_status_horas, 'PREP') NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_venda_fator_ajuste) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do fator de ajuste é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF taxa_validar(p_venda_fator_ajuste) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  v_venda_fator_ajuste := taxa_converter(TRIM(p_venda_fator_ajuste));
  --
  IF v_venda_fator_ajuste < 0 OR v_venda_fator_ajuste > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Fator de ajuste inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  FOR r_jh IN c_jh
  LOOP
   -- desencripta para poder usar
   v_venda_hora_pdr := util_pkg.num_decode(r_jh.venda_hora_pdr_en, g_key_num);
   --
   -- aplica o fator de ajuste
   IF nvl(v_venda_hora_pdr, 0) <> 0 THEN
    v_venda_hora_rev := round(v_venda_hora_pdr * v_venda_fator_ajuste, 2);
    --
    -- encripta para salvar
    v_venda_hora_rev_en := util_pkg.num_encode(v_venda_hora_rev);
    --
    IF v_venda_hora_rev_en = -99999 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Erro na encriptação (' || moeda_mostrar(v_venda_hora_rev, 'N') || ').';
     RAISE v_exception;
    END IF;
    --
    UPDATE job_horas
       SET venda_hora_rev     = v_venda_hora_rev_en,
           venda_fator_ajuste = v_venda_fator_ajuste
     WHERE job_horas_id = r_jh.job_horas_id;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := 'Ajuste de preços com o fator: ' || taxa_mostrar(v_venda_fator_ajuste) || '.';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
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
 END horas_ajustar;
 --
 --
 PROCEDURE horas_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 10/04/2015
  -- DESCRICAO: Exclusao de horas planejadas do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/09/2016  Novo tipo POR_CARGO
  -- Silvia            15/05/2020  Eliminacao do papel_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN job.empresa_id%TYPE,
  p_job_horas_id      IN job_horas.job_horas_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_job_id         job.job_id%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
  v_status_horas   job.status_horas%TYPE;
  v_nome_area      area.nome%TYPE;
  v_area_id        area.area_id%TYPE;
  v_nivel          job_horas.nivel%TYPE;
  v_usuario_id     job_horas.usuario_id%TYPE;
  v_nome_usuario   pessoa.apelido%TYPE;
  v_cargo_id       cargo.cargo_id%TYPE;
  v_nome_cargo     cargo.nome%TYPE;
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
  SELECT COUNT(*)
    INTO v_qt
    FROM job_horas
   WHERE job_horas_id = p_job_horas_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse registro de horas de ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.numero,
         jo.status,
         jo.status_horas,
         jo.job_id,
         jh.nivel,
         jh.usuario_id,
         jh.cargo_id,
         jh.area_id
    INTO v_numero_job,
         v_status_job,
         v_status_horas,
         v_job_id,
         v_nivel,
         v_usuario_id,
         v_cargo_id,
         v_area_id
    FROM job       jo,
         job_horas jh
   WHERE jh.job_horas_id = p_job_horas_id
     AND jh.job_id = jo.job_id;
  --
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                v_job_id,
                                NULL,
                                p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job NOT IN ('PREP', 'ANDA') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(v_status_horas, 'PREP') NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_usuario_id IS NOT NULL THEN
   SELECT MAX(apelido)
     INTO v_nome_usuario
     FROM pessoa
    WHERE usuario_id = v_usuario_id;
  END IF;
  --
  IF v_cargo_id IS NOT NULL THEN
   SELECT nome
     INTO v_nome_cargo
     FROM cargo
    WHERE cargo_id = v_cargo_id;
  END IF;
  --
  SELECT nome
    INTO v_nome_area
    FROM area
   WHERE area_id = v_area_id;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM job_horas
   WHERE job_horas_id = p_job_horas_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_horas
   WHERE job_id = v_job_id;
  --
  IF v_qt = 0 THEN
   -- job ficou sem estimatima de horas
   UPDATE job
      SET status_horas        = NULL,
          data_status_horas   = NULL,
          usu_status_horas_id = NULL,
          usu_autor_horas_id  = NULL
    WHERE job_id = v_job_id;
  ELSE
   IF v_status_horas IS NULL THEN
    UPDATE job
       SET status_horas        = 'PREP',
           data_status_horas   = SYSDATE,
           usu_status_horas_id = p_usuario_sessao_id
     WHERE job_id = v_job_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(v_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  --
  IF v_cargo_id IS NOT NULL THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_cargo || ' / ' ||
                     nvl(TRIM(v_nivel), 'ND');
  ELSIF v_usuario_id IS NOT NULL THEN
   v_compl_histor := 'Exclusão de estimativa de horas: ' || v_nome_usuario || ' / ' ||
                     v_nome_area;
  END IF;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'ALTERAR',
                   v_identif_objeto,
                   v_job_id,
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
 END horas_excluir;
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Termino de estimativa de horas do job (envia para aprovacao ou aprova
  --            automaticamente).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                  INTEGER;
  v_identif_objeto      historico.identif_objeto%TYPE;
  v_compl_histor        historico.complemento%TYPE;
  v_historico_id        historico.historico_id%TYPE;
  v_exception           EXCEPTION;
  v_status_horas        job.status_horas%TYPE;
  v_numero_job          job.numero%TYPE;
  v_status_job          job.status%TYPE;
  v_data_aprov_limite   job.data_aprov_horas_limite%TYPE;
  v_flag_apr_horas_auto tipo_job.flag_apr_horas_auto%TYPE;
  v_lbl_job             VARCHAR2(100);
  v_xml_antes           CLOB;
  v_xml_atual           CLOB;
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
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT j.numero,
         j.status,
         j.status_horas,
         t.flag_apr_horas_auto
    INTO v_numero_job,
         v_status_job,
         v_status_horas,
         v_flag_apr_horas_auto
    FROM job      j,
         tipo_job t
   WHERE j.job_id = p_job_id
     AND j.tipo_job_id = t.tipo_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                p_job_id,
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
  IF nvl(v_status_horas, 'PREP') NOT IN ('PREP', 'REPROV') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM job_horas
   WHERE job_id = p_job_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Não existe estimativa de horas.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_data_aprov_limite := feriado_pkg.prazo_em_horas_retornar(p_usuario_sessao_id,
                                                             p_empresa_id,
                                                             SYSDATE,
                                                             'NUM_HORAS_APROV_JOBHORAS',
                                                             0);
  UPDATE job
     SET status_horas            = 'EMAPRO',
         data_status_horas       = SYSDATE,
         usu_autor_horas_id      = p_usuario_sessao_id,
         usu_status_horas_id     = p_usuario_sessao_id,
         motivo_status_horas     = NULL,
         compl_status_horas      = NULL,
         data_aprov_horas_limite = v_data_aprov_limite
   WHERE job_id = p_job_id;
  --
  IF v_flag_apr_horas_auto = 'N' THEN
   -- nao tem aprovacao automatica de horas.
   -- marca as horas como tendo transicao de aprovacao.
   UPDATE job
      SET flag_com_aprov_horas = 'S'
    WHERE job_id = p_job_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'TERMINAR',
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
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  IF v_flag_apr_horas_auto = 'S' THEN
   -- aprova as horas automaticamente
   job_horas_pkg.aprovar(p_usuario_sessao_id,
                         p_empresa_id,
                         'N',
                         p_job_id,
                         p_erro_cod,
                         p_erro_msg);
   --
   IF p_erro_cod <> '00000' THEN
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END terminar;
 --
 --
 PROCEDURE retomar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Retomada de estimativa de horas do job (volta para preparacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_status_horas   job.status_horas%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
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
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_C',
                                p_job_id,
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
  IF v_status_horas <> ('EMAPRO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_horas        = 'PREP',
         data_status_horas   = SYSDATE,
         usu_autor_horas_id  = NULL,
         usu_status_horas_id = p_usuario_sessao_id
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'RETOMAR',
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
 END retomar;
 --
 --
 PROCEDURE aprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Aprovacao de estimativa de horas do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN job.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_status_horas   job.status_horas%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
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
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  IF p_flag_commit = 'S' THEN
   -- chamada via interface. Precisa testar o privilegio normalmente.
   IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                 'JOB_HORA_AP',
                                 p_job_id,
                                 NULL,
                                 p_empresa_id) = 0 THEN
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
  IF v_status_horas <> 'EMAPRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_horas        = 'APROV',
         data_status_horas   = SYSDATE,
         usu_status_horas_id = p_usuario_sessao_id,
         motivo_status_horas = NULL,
         compl_status_horas  = NULL
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'APROVAR',
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END aprovar;
 --
 --
 PROCEDURE reprovar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Reprovacao de estimativa de horas do job.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
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
  v_status_horas   job.status_horas%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
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
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_AP',
                                p_job_id,
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
  IF v_status_horas <> 'EMAPRO' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
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
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_horas        = 'REPROV',
         data_status_horas   = SYSDATE,
         usu_status_horas_id = p_usuario_sessao_id,
         motivo_status_horas = TRIM(p_motivo_reprov),
         compl_status_horas  = TRIM(p_compl_reprov)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := TRIM(p_compl_reprov);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'REPROVAR',
                   v_identif_objeto,
                   p_job_id,
                   v_compl_histor,
                   TRIM(p_motivo_reprov),
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
 END reprovar;
 --
 --
 PROCEDURE revisar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 04/01/2016
  -- DESCRICAO: Revisao de estimativa de horas aprovada (volta para preparacao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_job_id            IN job.job_id%TYPE,
  p_motivo_rev        IN VARCHAR2,
  p_compl_rev         IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_status_horas   job.status_horas%TYPE;
  v_numero_job     job.numero%TYPE;
  v_status_job     job.status%TYPE;
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
  SELECT numero,
         status,
         status_horas
    INTO v_numero_job,
         v_status_job,
         v_status_horas
    FROM job
   WHERE job_id = p_job_id;
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id,
                                'JOB_HORA_RV',
                                p_job_id,
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
  IF v_status_horas <> 'APROV' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da estimativa de horas não permite essa operação.';
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
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE job
     SET status_horas        = 'PREP',
         data_status_horas   = SYSDATE,
         usu_autor_horas_id  = NULL,
         usu_status_horas_id = p_usuario_sessao_id,
         motivo_status_horas = TRIM(p_motivo_rev),
         compl_status_horas  = TRIM(p_compl_rev)
   WHERE job_id = p_job_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  job_pkg.xml_gerar(p_job_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := to_char(v_numero_job);
  v_compl_histor   := TRIM(p_compl_rev);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'JOB_HORAS',
                   'REVISAR',
                   v_identif_objeto,
                   p_job_id,
                   v_compl_histor,
                   TRIM(p_motivo_rev),
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
 END revisar;
 --
END; -- JOB_HORAS_PKG



/
