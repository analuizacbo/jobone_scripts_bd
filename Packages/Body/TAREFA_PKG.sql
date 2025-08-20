--------------------------------------------------------
--  DDL for Package Body TAREFA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "TAREFA_PKG" IS
 --
 --
 PROCEDURE adicionar_temp
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/07/2021
  -- DESCRICAO: Inclusão de TAREFA no status TEMP
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza         23/10/2024  Adicao de cod_hash para vincular link
  -- Ana Luiza         26/02/2025  Tratamento para incluir tipo_tarefa_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id  IN NUMBER,
  p_empresa_id         IN empresa.empresa_id%TYPE,
  p_job_id             IN tarefa.job_id%TYPE,
  p_flag_desc_usuario  IN VARCHAR2,
  p_num_max_itens      IN VARCHAR2,
  p_num_max_dias_prazo IN VARCHAR2,
  p_flag_obriga_item   IN VARCHAR2,
  p_descricao          IN VARCHAR2,
  p_tarefa_id          OUT tarefa.tarefa_id%TYPE,
  p_erro_cod           OUT VARCHAR2,
  p_erro_msg           OUT VARCHAR2
 ) IS
  v_qt                 INTEGER;
  v_exception          EXCEPTION;
  v_identif_objeto     historico.identif_objeto%TYPE;
  v_compl_histor       historico.complemento%TYPE;
  v_historico_id       historico.historico_id%TYPE;
  v_tarefa_id          tarefa.tarefa_id%TYPE;
  v_num_tarefa         tarefa.numero%TYPE;
  v_num_max_itens      tarefa.num_max_itens%TYPE;
  v_num_max_dias_prazo tarefa.num_max_dias_prazo%TYPE;
  v_data_atual         DATE;
  v_num_job            job.numero%TYPE;
  v_lbl_job            VARCHAR2(100);
  v_tipo_tarefa_id     tarefa.tipo_tarefa_id%TYPE;
  --
 BEGIN
  v_qt         := 0;
  v_lbl_job    := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  p_tarefa_id  := 0;
  v_data_atual := SYSDATE;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  /*
    IF NVL(p_job_id,0) = 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'O preenchimento do ' || v_lbl_job || ' é obrigatório.';
       RAISE v_exception;
    END IF;
  */
  --
  IF nvl(p_job_id, 0) > 0
  THEN
   SELECT MAX(numero)
     INTO v_num_job
     FROM job
    WHERE job_id = p_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_num_job IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF flag_validar(p_flag_desc_usuario) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag descrição do usuário inválido';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do título é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 255
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O título não pode ter mais que 255 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obriga_item) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obriga item inválido.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_max_itens) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_max_itens := to_number(p_num_max_itens);
  --
  IF v_num_max_itens <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Quantidade limite de entregáveis inválida (' || p_num_max_itens || ').';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_num_max_dias_prazo) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número máximo de dias de prazo inválido (' || p_num_max_dias_prazo || ').';
   RAISE v_exception;
  END IF;
  --
  v_num_max_dias_prazo := to_number(p_num_max_dias_prazo);
  --
  IF v_num_max_dias_prazo <= 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Número máximo de dias de prazo inválido (' || p_num_max_dias_prazo || ').';
   RAISE v_exception;
  END IF;
  --
  --ALCBO_260225
  SELECT MAX(tipo_tarefa_id)
    INTO v_tipo_tarefa_id
    FROM tipo_tarefa
   WHERE empresa_id = p_empresa_id
     AND flag_padrao = 'S';
  --   
  IF v_tipo_tarefa_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de tarefa não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_tarefa.nextval
    INTO v_tarefa_id
    FROM dual;
  --
  v_num_tarefa := v_tarefa_id;
  --ALCBO_231024
  INSERT INTO tarefa
   (tarefa_id,
    empresa_id,
    usuario_de_id,
    job_id,
    numero,
    descricao,
    flag_volta_exec,
    flag_devolvida,
    data_entrada,
    data_envio,
    status,
    data_status,
    num_max_itens,
    num_max_dias_prazo,
    flag_desc_usuario,
    flag_obriga_item,
    cod_hash,
    tipo_tarefa_id)
  VALUES
   (v_tarefa_id,
    p_empresa_id,
    p_usuario_sessao_id,
    zvl(p_job_id, NULL),
    v_num_tarefa,
    TRIM(p_descricao),
    'N',
    'N',
    v_data_atual,
    v_data_atual,
    'TEMP',
    v_data_atual,
    v_num_max_itens,
    v_num_max_dias_prazo,
    p_flag_desc_usuario,
    p_flag_obriga_item,
    rawtohex(sys_guid()),
    v_tipo_tarefa_id);
  --
  p_tarefa_id := v_tarefa_id;
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
 END adicionar_temp;
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 12/05/2009
  -- DESCRICAO: Inclusão de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/09/2012  Novo parametro flag_commit.
  -- Silvia            02/05/2013  Registro no historico de enderecamentos.
  -- Silvia            28/08/2015  Alteração do nome do objeto (de pedido para tarefa).
  -- Silvia            14/01/2016  Novo parametro item_crono_id (abertura atraves do crono)
  -- Silvia            19/09/2017  Grava XML no historico.
  -- Silvia            18/03/2020  Sincronismo de usuarios com o item do cronograma.
  -- Silvia            15/07/2020  Novos parametros de data, estimativa, etc
  -- Silvia            24/11/2020  Novos parametros para repeticao
  -- Silvia            29/07/2021  Novo parametro tarefa_temp_id, indicando tarefa existente
  -- Ana Luiza         18/07/2023  Removido arredondamento de horas.
  -- Ana Luiza         23/10/2024  Adicao de cod_hash para vincular link
  -- Ana Luiza         28/10/2024  Verificacao se dia informado não é feriado
  -- Ana Luiza         21/01/2025  Adicao de novo parametro tipo_tarefa_id
  -- Ana Luiza         22/01/2025  Tratamento para quando vir 0 no tipo_tarefa_id pega o padrao
  -- Ana Luiza         07/03/2025  chamada para apontar horas automático na criação na task
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_flag_commit         IN VARCHAR2,
  p_tarefa_temp_id      IN tarefa.tarefa_id%TYPE,
  p_job_id              IN job.job_id%TYPE,
  p_tipo_tarefa_id      IN tarefa.tipo_tarefa_id%TYPE,
  p_descricao           IN VARCHAR2,
  p_detalhes            IN tarefa.detalhes%TYPE,
  p_flag_volta_exec     IN VARCHAR2,
  p_data_inicio         IN VARCHAR2,
  p_hora_inicio         IN VARCHAR2,
  p_data_termino        IN VARCHAR2,
  p_hora_termino        IN VARCHAR2,
  p_vetor_usuario_id    IN VARCHAR2,
  p_vetor_datas         IN VARCHAR2,
  p_vetor_horas         IN VARCHAR2,
  p_item_crono_id       IN item_crono.item_crono_id%TYPE,
  p_ordem_servico_id    IN ordem_servico.ordem_servico_id%TYPE,
  p_repet_a_cada        IN VARCHAR2,
  p_frequencia_id       IN mod_item_crono.frequencia_id%TYPE,
  p_vetor_dia_semana_id IN VARCHAR2,
  p_repet_term_tipo     IN VARCHAR2,
  p_data_term_repet     IN VARCHAR2,
  p_repet_term_ocor     IN VARCHAR2,
  p_tarefa_id           OUT tarefa.tarefa_id%TYPE,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_tarefa_id             tarefa.tarefa_id%TYPE;
  v_data_inicio           tarefa.data_inicio%TYPE;
  v_data_termino          tarefa.data_termino%TYPE;
  v_num_tarefa            tarefa.numero%TYPE;
  v_flag_obriga_item      tarefa.flag_obriga_item%TYPE;
  v_num_max_itens         tarefa.num_max_itens%TYPE;
  v_num_max_dias_prazo    tarefa.num_max_dias_prazo%TYPE;
  v_horas_totais          tarefa_usuario.horas_totais%TYPE;
  v_data                  tarefa_usuario_data.data%TYPE;
  v_horas                 tarefa_usuario_data.horas%TYPE;
  v_vetor_usuario_id      LONG;
  v_vetor_horas           LONG;
  v_vetor_datas           LONG;
  v_data_char             VARCHAR2(20);
  v_horas_char            VARCHAR2(20);
  v_usuario_para_id       usuario.usuario_id%TYPE;
  v_delimitador           CHAR(1);
  v_lbl_job               VARCHAR2(100);
  v_usa_hora_ini          VARCHAR2(10);
  v_data_atual            DATE;
  v_objeto_id             item_crono.objeto_id%TYPE;
  v_cod_objeto            item_crono.cod_objeto%TYPE;
  v_cronograma_id         item_crono.cronograma_id%TYPE;
  v_item_crono_id         item_crono.item_crono_id%TYPE;
  v_flag_planejado        item_crono.flag_planejado%TYPE;
  v_repet_a_cada          item_crono.repet_a_cada%TYPE;
  v_repet_term_ocor       item_crono.repet_term_ocor%TYPE;
  v_data_term_repet       item_crono.data_term_repet%TYPE;
  v_repet_grupo           item_crono.repet_grupo%TYPE;
  v_dia_semana_id         dia_semana.dia_semana_id%TYPE;
  v_cod_freq              frequencia.codigo%TYPE;
  v_apelido               pessoa.apelido%TYPE;
  v_xml_atual             CLOB;
  v_duracao               NUMBER(20);
  v_vetor_dia_semana_id   LONG;
  v_data_inicio_old       tarefa.data_inicio%TYPE;
  v_tipo_tarefa_id        tarefa.tipo_tarefa_id%TYPE;
  v_flag_apont_horas_aloc tipo_tarefa.flag_apont_horas_aloc%TYPE;
  --
  -- seleciona executores da tarefa
  CURSOR c_us IS
   SELECT usuario_para_id
     FROM tarefa_usuario
    WHERE tarefa_id = v_tarefa_id;
  --
 BEGIN
  v_qt           := 0;
  p_tarefa_id    := 0;
  v_lbl_job      := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  v_usa_hora_ini := empresa_pkg.parametro_retornar(p_empresa_id, 'USAR_HORA_INI_TAREFA');
  v_data_atual   := SYSDATE;
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
  --ALCBO_220125
  IF p_tipo_tarefa_id = 0
  THEN
   SELECT MAX(tipo_tarefa_id)
     INTO v_tipo_tarefa_id
     FROM tipo_tarefa
    WHERE empresa_id = p_empresa_id
      AND flag_padrao = 'S';
  ELSE
   --ALCBO_210125
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_tarefa
    WHERE tipo_tarefa_id = p_tipo_tarefa_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de tarefa não existe ou não pertence a essa empresa' ||
                  p_tipo_tarefa_id;
    RAISE v_exception;
   END IF;
   v_tipo_tarefa_id := p_tipo_tarefa_id;
  END IF;
  --
  --ALCBO_070325
  SELECT flag_apont_horas_aloc
    INTO v_flag_apont_horas_aloc
    FROM tipo_tarefa
   WHERE tipo_tarefa_id = v_tipo_tarefa_id;
  --
  IF nvl(p_tarefa_temp_id, 0) > 0
  THEN
   -- verifica se qtd de itens esta de acordo
   SELECT flag_obriga_item,
          num_max_itens,
          num_max_dias_prazo
     INTO v_flag_obriga_item,
          v_num_max_itens,
          v_num_max_dias_prazo
     FROM tarefa
    WHERE tarefa_id = p_tarefa_temp_id;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE tarefa_id = p_tarefa_temp_id;
   --
   IF v_flag_obriga_item = 'S' AND v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'É necessário indicar ao menos 1 Entregável.';
    RAISE v_exception;
   END IF;
   --
   IF v_num_max_itens IS NOT NULL AND v_qt > v_num_max_itens
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número máximo de Entregáveis por Task é ' || to_char(v_num_max_itens) || ' .';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do título é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 255
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O título não pode ter mais que 255 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_volta_exec) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag enviar de volta inválido.';
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
  IF v_num_max_dias_prazo IS NOT NULL AND
     trunc(v_data_termino) >= trunc(v_data_inicio) + v_num_max_dias_prazo
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de término não pode ser maior que a data de início acrescida de ' ||
                 to_char(v_num_max_dias_prazo) || ' dias.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_vetor_usuario_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pelo menos um usuário deve ser especificado.';
   RAISE v_exception;
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
          flag_planejado
     INTO v_objeto_id,
          v_cod_objeto,
          v_flag_planejado
     FROM item_crono
    WHERE item_crono_id = p_item_crono_id;
   --
   IF v_objeto_id IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma já está associado a algum tipo de objeto.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_objeto IS NOT NULL AND v_cod_objeto <> 'TAREFA'
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse item de cronograma não pode ser usado para Taks (' || v_cod_objeto || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  v_duracao := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                   v_data_inicio,
                                                   v_data_termino) + 1;
  --
  ------------------------------------------------------------
  -- consistencia de repeticoes
  ------------------------------------------------------------
  v_repet_a_cada    := NULL;
  v_repet_term_ocor := NULL;
  v_data_term_repet := NULL;
  --
  IF nvl(p_frequencia_id, 0) > 0
  THEN
   SELECT MAX(codigo)
     INTO v_cod_freq
     FROM frequencia
    WHERE frequencia_id = p_frequencia_id;
   --
   IF TRIM(p_repet_a_cada) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O preenchimento da frequência da repetição é obrigatório.';
    RAISE v_exception;
   END IF;
   --
   IF inteiro_validar(p_repet_a_cada) = 0 OR to_number(p_repet_a_cada) > 99999
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   v_repet_a_cada := nvl(to_number(p_repet_a_cada), 0);
   --
   IF v_repet_a_cada <= 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Frequência da repetição inválida (' || p_repet_a_cada || ').';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq = 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, um ou mais dias da semana ' ||
                  'devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF v_cod_freq <> 'SEM' AND TRIM(p_vetor_dia_semana_id) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de repetição, os dias da semana ' || 'não devem ser indicados.';
    RAISE v_exception;
   END IF;
   --
   IF TRIM(p_repet_term_tipo) IS NULL OR p_repet_term_tipo NOT IN ('FIMJOB', 'QTOCOR')
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Tipo de término da repetição inválido (' || p_repet_term_tipo || ').';
    RAISE v_exception;
   END IF;
   --
   IF p_repet_term_tipo = 'FIMJOB'
   THEN
    IF TRIM(p_data_term_repet) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para esse tipo de término da repetição, a data ' || 'deve ser informada.';
     RAISE v_exception;
    END IF;
    --
    IF data_validar(p_data_term_repet) = 0
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Data de término da repetição inválida (' || p_data_term_repet || ').';
     RAISE v_exception;
    END IF;
    --
    v_data_term_repet := data_converter(p_data_term_repet);
   END IF;
   --
   IF p_repet_term_tipo = 'QTOCOR'
   THEN
    IF TRIM(p_repet_term_ocor) IS NULL
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                   'de ocorrências deve ser informada.';
     RAISE v_exception;
    END IF;
    --
    IF inteiro_validar(p_repet_term_ocor) = 0 OR to_number(p_repet_term_ocor) > 99999
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
    --
    v_repet_term_ocor := nvl(to_number(p_repet_term_ocor), 0);
    --
    IF v_repet_term_ocor <= 1
    THEN
     p_erro_cod := '90000';
     p_erro_msg := 'Quantidade de ocorrências da repetição inválida (' || p_repet_term_ocor || ').';
     RAISE v_exception;
    END IF;
   END IF;
   --
   IF p_repet_term_tipo <> 'QTOCOR' AND TRIM(p_repet_term_ocor) IS NOT NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de término da repetição, a quantidade ' ||
                  'de ocorrências não deve ser informada.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF nvl(p_tarefa_temp_id, 0) = 0
  THEN
   -- registro temporario nao existe.
   -- cria registro definitivo.
   SELECT seq_tarefa.nextval
     INTO v_tarefa_id
     FROM dual;
   --
   v_num_tarefa := v_tarefa_id;
   --ALCBO_231024
   INSERT INTO tarefa
    (tarefa_id,
     empresa_id,
     usuario_de_id,
     job_id,
     numero,
     descricao,
     detalhes,
     flag_volta_exec,
     data_entrada,
     data_inicio,
     data_termino,
     data_envio,
     status,
     data_status,
     ordem_servico_id,
     cod_hash,
     tipo_tarefa_id)
   VALUES
    (v_tarefa_id,
     p_empresa_id,
     p_usuario_sessao_id,
     p_job_id,
     v_num_tarefa,
     TRIM(p_descricao),
     p_detalhes,
     TRIM(p_flag_volta_exec),
     v_data_atual,
     v_data_inicio,
     v_data_termino,
     v_data_atual,
     'EMEX',
     v_data_atual,
     zvl(p_ordem_servico_id, NULL),
     rawtohex(sys_guid()),
     v_tipo_tarefa_id);
  ELSE
   -- existe registro temporario.
   -- atualiza e muda de status.
   v_tarefa_id := p_tarefa_temp_id;
   --
   UPDATE tarefa
      SET job_id           = p_job_id,
          descricao        = TRIM(p_descricao),
          detalhes         = p_detalhes,
          flag_volta_exec  = TRIM(p_flag_volta_exec),
          data_entrada     = v_data_atual,
          data_inicio      = v_data_inicio,
          data_termino     = v_data_termino,
          data_envio       = v_data_atual,
          status           = 'EMEX',
          data_status      = v_data_atual,
          ordem_servico_id = zvl(p_ordem_servico_id, NULL),
          tipo_tarefa_id   = v_tipo_tarefa_id
    WHERE tarefa_id = v_tarefa_id;
  END IF;
  --
  INSERT INTO tarefa_evento
   (tarefa_evento_id,
    tarefa_id,
    usuario_id,
    data_evento,
    cod_acao,
    comentario,
    status_de,
    status_para)
  VALUES
   (seq_tarefa_evento.nextval,
    v_tarefa_id,
    p_usuario_sessao_id,
    SYSDATE,
    'ENVIAR',
    NULL,
    NULL,
    'EMEX');
  --
  historico_pkg.hist_ender_registrar(p_usuario_sessao_id,
                                     'TAR',
                                     v_tarefa_id,
                                     'SOL',
                                     p_erro_cod,
                                     p_erro_msg);
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento do vetor
  ------------------------------------------------------------
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  v_vetor_horas      := TRIM(p_vetor_horas);
  v_vetor_datas      := TRIM(p_vetor_datas);
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_para_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   v_data_char       := prox_valor_retornar(v_vetor_datas, v_delimitador);
   v_horas_char      := prox_valor_retornar(v_vetor_horas, v_delimitador);
   --
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_para_id;
   --
   IF v_apelido IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe (' || to_char(v_usuario_para_id) || ').';
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
     FROM tarefa_usuario
    WHERE tarefa_id = v_tarefa_id
      AND usuario_para_id = v_usuario_para_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO tarefa_usuario
     (tarefa_id,
      usuario_para_id,
      horas_totais,
      status,
      data_status)
    VALUES
     (v_tarefa_id,
      v_usuario_para_id,
      0,
      'EMEX',
      SYSDATE);
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_usuario_data
    WHERE tarefa_id = v_tarefa_id
      AND usuario_para_id = v_usuario_para_id
      AND data = v_data;
   --
   IF v_qt = 0
   THEN
    INSERT INTO tarefa_usuario_data
     (tarefa_id,
      usuario_para_id,
      data,
      horas)
    VALUES
     (v_tarefa_id,
      v_usuario_para_id,
      v_data,
      v_horas);
   ELSE
    p_erro_cod := '90000';
    p_erro_msg := 'Existem usuários responsáveis repetidos.';
    RAISE v_exception;
   END IF;
   --
   historico_pkg.hist_ender_registrar(v_usuario_para_id,
                                      'TAR',
                                      v_tarefa_id,
                                      'EXE',
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --ALCBO_07032025
   IF v_flag_apont_horas_aloc = 'S'
   THEN
    -- apontamento automatico de horas alocadas ligado.
    -- usa as horas alocadas para gerar o apontamento (timesheet)
    apontam_pkg.horas_tarefa_apontar(v_usuario_para_id,
                                     p_empresa_id,
                                     v_tarefa_id,
                                     data_mostrar(v_data),
                                     numero_mostrar(v_horas, 2, 'N'),
                                     p_erro_cod,
                                     p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de cronograma
  ------------------------------------------------------------
  --ALCBO_281024
  v_data_inicio_old := v_data_inicio;
  --
  IF nvl(p_item_crono_id, 0) <> 0
  THEN
   -- tarefa criada via cronograma
   UPDATE item_crono
      SET objeto_id  = v_tarefa_id,
          cod_objeto = 'TAREFA'
    WHERE item_crono_id = p_item_crono_id;
   --
   v_item_crono_id := p_item_crono_id;
   --
   SELECT cronograma_id
     INTO v_cronograma_id
     FROM item_crono
    WHERE item_crono_id = p_item_crono_id;
  ELSIF nvl(p_job_id, 0) > 0
  THEN
   -- tarefa criada por fora do cronograma
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
   -- cria a atividade de tarefa
   cronograma_pkg.item_objeto_adicionar(p_usuario_sessao_id,
                                        p_empresa_id,
                                        v_cronograma_id,
                                        'TAREFA',
                                        'IME',
                                        v_item_crono_id,
                                        p_erro_cod,
                                        p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   IF feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data_inicio, 'S') = 0 OR
      feriado_pkg.dia_util_verificar(p_usuario_sessao_id, v_data_termino, 'S') = 0
   THEN
    v_data_inicio  := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id, v_data_inicio, 0, 'S');
    v_data_termino := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,
                                                         v_data_termino,
                                                         v_duracao - 1,
                                                         'S');
   END IF;
   -- vincula a atividade de tarefa a tarefa criada
   UPDATE item_crono
      SET objeto_id       = v_tarefa_id,
          nome            = substr('Task ' || TRIM(p_descricao), 1, 100),
          data_planej_ini = trunc(v_data_inicio),
          data_planej_fim = trunc(v_data_termino)
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  -- grava eventuais dados de repeticao
  IF nvl(p_frequencia_id, 0) > 0
  THEN
   UPDATE item_crono
      SET frequencia_id   = zvl(p_frequencia_id, NULL),
          repet_a_cada    = v_repet_a_cada,
          repet_term_tipo = TRIM(p_repet_term_tipo),
          data_term_repet = v_data_term_repet,
          repet_term_ocor = v_repet_term_ocor
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais dos usuarios executores
  ------------------------------------------------------------
  FOR r_us IN c_us
  LOOP
   SELECT nvl(SUM(horas), 0)
     INTO v_horas
     FROM tarefa_usuario_data
    WHERE tarefa_id = v_tarefa_id
      AND usuario_para_id = r_us.usuario_para_id;
   --
   UPDATE tarefa_usuario
      SET horas_totais = v_horas
    WHERE tarefa_id = v_tarefa_id
      AND usuario_para_id = r_us.usuario_para_id;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_para_id,
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
  -- tratamento do vetor de dia da semana (repeticoes)
  ------------------------------------------------------------
  v_delimitador         := '|';
  v_vetor_dia_semana_id := p_vetor_dia_semana_id;
  --
  WHILE nvl(length(rtrim(v_vetor_dia_semana_id)), 0) > 0
  LOOP
   v_dia_semana_id := nvl(to_number(prox_valor_retornar(v_vetor_dia_semana_id, v_delimitador)), 0);
   --
   IF v_dia_semana_id > 0
   THEN
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
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(v_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := substr(TRIM(p_descricao), 1, 500);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'INCLUIR',
                   v_identif_objeto,
                   v_tarefa_id,
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
  -- processamento das repeticoes (apenas chamadas via interface)
  ------------------------------------------------------------
  IF nvl(p_frequencia_id, 0) > 0 AND p_flag_commit = 'S'
  THEN
   cronograma_pkg.repeticao_processar(p_usuario_sessao_id,
                                      p_empresa_id,
                                      v_cronograma_id,
                                      v_data_inicio_old,
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- cria as demais tarefas das repeticoes
  ------------------------------------------------------------
  IF nvl(p_frequencia_id, 0) > 0
  THEN
   SELECT MAX(repet_grupo)
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
   --
   tarefa_pkg.adicionar_demais(p_usuario_sessao_id,
                               p_empresa_id,
                               'N',
                               p_job_id,
                               v_repet_grupo,
                               p_erro_cod,
                               p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
  END IF;
  --
  p_tarefa_id := v_tarefa_id;
  --
  IF p_flag_commit = 'S'
  THEN
   COMMIT;
  END IF;
  --
  p_erro_cod := '00000';
  p_erro_msg := 'Operação realizada com sucesso.';
  --
 EXCEPTION
  WHEN v_exception THEN
   ROLLBACK;
   /*
   WHEN DUP_VAL_ON_INDEX THEN
        p_erro_cod := '90000';
        p_erro_msg := 'Esse número de Task já existe (' || TO_CHAR(v_num_tarefa) || 
                      '). Tente novamente.';
        ROLLBACK; */
  WHEN OTHERS THEN
   p_erro_cod := SQLCODE;
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace, 1, 200);
   ROLLBACK;
 END adicionar;
 --
 --
 PROCEDURE adicionar_demais
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 22/10/2018
  -- DESCRICAO: subrotina de Inclusão de TAREFA(s) resultante(s) de repeticoes de um 
  --   determinado grupo.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            15/07/2020  Novos parametros de data, estimativa, etc
  -- Silvia            27/11/2020  Transformacao em subrotina
  -- Silvia            11/08/2022  Replicacao de todo-list, links, itens
  -- Ana Luiza         21/01/2025  Adicao de parametro na chamada tarefa_pkg.adicionar         
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_flag_commit       IN VARCHAR2,
  p_job_id            IN job.job_id%TYPE,
  p_repet_grupo       IN item_crono.repet_grupo%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_identif_objeto         historico.identif_objeto%TYPE;
  v_compl_histor           historico.complemento%TYPE;
  v_historico_id           historico.historico_id%TYPE;
  v_exception              EXCEPTION;
  v_tarefa_new_id          tarefa.tarefa_id%TYPE;
  v_tarefa_id              tarefa.tarefa_id%TYPE;
  v_descricao              tarefa.descricao%TYPE;
  v_detalhes               tarefa.detalhes%TYPE;
  v_flag_volta_exec        tarefa.flag_volta_exec%TYPE;
  v_ordem_servico_id       tarefa.ordem_servico_id%TYPE;
  v_data_inicio_ori        tarefa.data_inicio%TYPE;
  v_data_termino_ori       tarefa.data_termino%TYPE;
  v_data_inicio_new        tarefa.data_inicio%TYPE;
  v_tarefa_tipo_produto_id tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE;
  v_vetor_usuario_id       LONG;
  v_vetor_datas            LONG;
  v_vetor_horas            LONG;
  v_data                   DATE;
  v_dias                   NUMBER(5);
  v_hora_inicio            VARCHAR2(10);
  v_hora_termino           VARCHAR2(10);
  v_tipo_tarefa_id         tarefa.tipo_tarefa_id%TYPE;
  --
  -- seleciona repeticoes do grupo sem tarefa criada
  CURSOR c_ic IS
   SELECT ic.item_crono_id,
          data_mostrar(ic.data_planej_ini) AS data_inicio,
          data_mostrar(ic.data_planej_fim) AS data_limite
     FROM item_crono ic,
          cronograma cr
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = p_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = p_job_id
      AND ic.objeto_id IS NULL
    ORDER BY ic.num_seq;
  --
  -- seleciona executores/horas da tarefa original
  CURSOR c_ta IS
   SELECT usuario_para_id,
          data AS data_ori,
          horas
     FROM tarefa_usuario_data
    WHERE tarefa_id = v_tarefa_id
    ORDER BY usuario_para_id,
             data;
  --
  -- seleciona todo-list da tarefa original
  CURSOR c_td IS
   SELECT usuario_resp_id,
          data,
          descricao,
          ordem
     FROM tarefa_afazer
    WHERE tarefa_id = v_tarefa_id;
  --
  -- seleciona itens original
  CURSOR c_it IS
   SELECT tarefa_tipo_produto_id,
          job_tipo_produto_id,
          descricao
     FROM tarefa_tipo_produto
    WHERE tarefa_id = v_tarefa_id;
  --
 BEGIN
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
  -- seleciona a tarefa original do grupo de repeticao
  SELECT MAX(objeto_id)
    INTO v_tarefa_id
    FROM item_crono ic,
         cronograma cr
   WHERE ic.cronograma_id = cr.cronograma_id
     AND cr.status <> 'ARQUI'
     AND ic.repet_grupo = p_repet_grupo
     AND ic.cod_objeto = 'TAREFA'
     AND cr.job_id = p_job_id
     AND ic.objeto_id IS NOT NULL;
  --
  IF v_tarefa_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Erro na recuperação da tarefa original do grupo de repetição.';
   RAISE v_exception;
  END IF;
  --
  SELECT descricao,
         detalhes,
         flag_volta_exec,
         ordem_servico_id,
         data_inicio,
         data_termino,
         tipo_tarefa_id
    INTO v_descricao,
         v_detalhes,
         v_flag_volta_exec,
         v_ordem_servico_id,
         v_data_inicio_ori,
         v_data_termino_ori,
         v_tipo_tarefa_id
    FROM tarefa
   WHERE tarefa_id = v_tarefa_id;
  --
  -- guarda as horas da tarefa original pois no cronograma nao tem
  -- essa informacao.
  v_hora_inicio  := hora_mostrar(v_data_inicio_ori);
  v_hora_termino := hora_mostrar(v_data_termino_ori);
  --
  ------------------------------------------------------------
  -- loop por repeticao da tarefa definida no cronograma
  ------------------------------------------------------------
  FOR r_ic IN c_ic
  LOOP
   v_vetor_usuario_id := NULL;
   v_vetor_datas      := NULL;
   v_vetor_horas      := NULL;
   v_data_inicio_new  := data_converter(r_ic.data_inicio);
   --
   -- loop por executore/hora da tarefa original
   FOR r_ta IN c_ta
   LOOP
    v_vetor_usuario_id := v_vetor_usuario_id || '|' || to_char(r_ta.usuario_para_id);
    v_vetor_horas      := v_vetor_horas || '|' || numero_mostrar(r_ta.horas, 1, 'N');
    --
    -- calcula o deslocamento da data planejada em relacao a data de inicio da
    -- tarefa original
    --v_dias := NVL(feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,v_data_inicio_ori,r_ta.data_ori),0);
    v_dias := trunc(r_ta.data_ori) - trunc(v_data_inicio_ori);
    --
    -- aplica o deslocamento para montar o vetor com as novas datas
    --v_data := feriado_pkg.prox_dia_util_retornar(p_usuario_sessao_id,v_data_inicio_new,v_dias,'S');
    v_data := v_data_inicio_new + v_dias;
    --
    v_vetor_datas := v_vetor_datas || '|' || data_mostrar(v_data);
   END LOOP;
   --
   -- retira o primeiro pipe dos vetores
   v_vetor_usuario_id := substr(v_vetor_usuario_id, 2);
   v_vetor_datas      := substr(v_vetor_datas, 2);
   v_vetor_horas      := substr(v_vetor_horas, 2);
   --
   -- cria a nova tarefa com base na original
   tarefa_pkg.adicionar(p_usuario_sessao_id,
                        p_empresa_id,
                        'N',
                        0,
                        p_job_id,
                        v_tipo_tarefa_id,
                        v_descricao,
                        v_detalhes,
                        v_flag_volta_exec,
                        r_ic.data_inicio,
                        v_hora_inicio,
                        r_ic.data_limite,
                        v_hora_termino,
                        v_vetor_usuario_id,
                        v_vetor_datas,
                        v_vetor_horas,
                        r_ic.item_crono_id,
                        v_ordem_servico_id,
                        NULL,
                        0,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        v_tarefa_new_id,
                        p_erro_cod,
                        p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   -- replica to-list da tarefa original para a nova tarefa
   FOR r_td IN c_td
   LOOP
    -- calcula o deslocamento da data do to-do em relacao a data de inicio da
    -- tarefa original
    v_dias := trunc(r_td.data) - trunc(v_data_inicio_ori);
    --
    -- aplica o deslocamento para calcular a nova data do to-do
    v_data := v_data_inicio_new + v_dias;
    --
    INSERT INTO tarefa_afazer
     (tarefa_afazer_id,
      tarefa_id,
      usuario_resp_id,
      data,
      descricao,
      flag_feito,
      ordem)
    VALUES
     (seq_tarefa_afazer.nextval,
      v_tarefa_new_id,
      r_td.usuario_resp_id,
      v_data,
      r_td.descricao,
      'N',
      r_td.ordem);
   END LOOP;
   -- 
   -- replica links da tarefa original para a nova tarefa
   INSERT INTO tarefa_link
    (tarefa_link_id,
     tarefa_id,
     usuario_id,
     data_entrada,
     tipo_link,
     url,
     descricao)
    SELECT seq_tarefa_link.nextval,
           v_tarefa_new_id,
           p_usuario_sessao_id,
           SYSDATE,
           tipo_link,
           url,
           descricao
      FROM tarefa_link
     WHERE tarefa_id = v_tarefa_id;
   -- 
   -- replica itens/produtos e metadados da tarefa original para 
   -- a nova tarefa  
   FOR r_it IN c_it
   LOOP
    SELECT seq_tarefa_tipo_produto.nextval
      INTO v_tarefa_tipo_produto_id
      FROM dual;
    --
    INSERT INTO tarefa_tipo_produto
     (tarefa_tipo_produto_id,
      tarefa_id,
      job_tipo_produto_id,
      descricao,
      data_entrada)
    VALUES
     (v_tarefa_tipo_produto_id,
      v_tarefa_new_id,
      r_it.job_tipo_produto_id,
      r_it.descricao,
      SYSDATE);
    --
    INSERT INTO tarefa_tp_atrib_valor
     (tarefa_tipo_produto_id,
      metadado_id,
      valor_atributo)
     SELECT v_tarefa_tipo_produto_id,
            metadado_id,
            valor_atributo
       FROM tarefa_tp_atrib_valor
      WHERE tarefa_tipo_produto_id = r_it.tarefa_tipo_produto_id;
   END LOOP;
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
 END adicionar_demais;
 --
 --
 PROCEDURE atualizar_job
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 30/07/2021
  -- DESCRICAO: Atualizacao de JOB de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_job_id            IN tarefa.job_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_num_job        job.numero%TYPE;
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
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe ou não petence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_job_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do ' || v_lbl_job || ' é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(numero)
    INTO v_num_job
    FROM job
   WHERE job_id = p_job_id
     AND empresa_id = p_empresa_id;
  --
  IF v_num_job IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse ' || v_lbl_job || ' não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa
     SET job_id = p_job_id
   WHERE tarefa_id = p_tarefa_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Indicação do Job: ' || v_num_job;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
 END atualizar_job;
 --
 --
 PROCEDURE atualizar_principal
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 07/06/2013
  -- DESCRICAO: Atualizacao de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/08/2015  Alteração do nome do objeto (de pedido para tarefa).
  -- Silvia            25/04/2017  Libera alteracao para o usuario admin.
  -- Silvia            19/09/2017  Grava XML no historico.
  -- Silvia            18/03/2020  Sincronismo de usuarios com o item do cronograma.
  -- Silvia            21/07/2020  Separacao em duas procs de atualizar
  -- Silvia            27/11/2020  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_detalhes          IN tarefa.detalhes%TYPE,
  p_flag_volta_exec   IN VARCHAR2,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_job_id         job.job_id%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_item_crono_id  item_crono.item_crono_id%TYPE;
  v_repet_grupo    item_crono.repet_grupo%TYPE;
  v_data_inicio    tarefa.data_inicio%TYPE;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  v_tipo_tarefa_id tarefa.tipo_tarefa_id%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> p_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
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
   p_erro_msg := 'Essa task não existe ou não petence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id,
         data_inicio
    INTO v_job_id,
         v_data_inicio
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF rtrim(p_descricao) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do título é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_descricao) > 255
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O título não pode ter mais que 255 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_volta_exec) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag enviar de volta inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa
     SET descricao       = TRIM(p_descricao),
         detalhes        = p_detalhes,
         flag_volta_exec = p_flag_volta_exec
   WHERE tarefa_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   UPDATE item_crono
      SET nome = substr('Task ' || TRIM(p_descricao), 1, 100)
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     UPDATE tarefa
        SET descricao       = TRIM(p_descricao),
            detalhes        = p_detalhes,
            flag_volta_exec = p_flag_volta_exec
      WHERE tarefa_id = r_ta.tarefa_id;
     --
     UPDATE item_crono
        SET nome = substr('Task ' || TRIM(p_descricao), 1, 100)
      WHERE item_crono_id = r_ta.item_crono_id;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := substr(TRIM(p_descricao), 1, 500);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
 END atualizar_principal;
 --
 --
 PROCEDURE atualizar_estimativa
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 21/07/2020
  -- DESCRICAO: Atualizacao de estimaiva de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            23/08/2022  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  -- Ana Luiza         18/07/2023  Removido arredondamento de v_horas e v_horas_totais
  -- Ana Luiza         07/02/2025  Sugestao de horas no timesheet
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_data_inicio       IN VARCHAR2,
  p_hora_inicio       IN VARCHAR2,
  p_data_termino      IN VARCHAR2,
  p_hora_termino      IN VARCHAR2,
  p_vetor_usuario_id  IN VARCHAR2,
  p_vetor_datas       IN VARCHAR2,
  p_vetor_horas       IN VARCHAR2,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt                    INTEGER;
  v_exception             EXCEPTION;
  v_identif_objeto        historico.identif_objeto%TYPE;
  v_compl_histor          historico.complemento%TYPE;
  v_historico_id          historico.historico_id%TYPE;
  v_job_id                job.job_id%TYPE;
  v_data_inicio           tarefa.data_inicio%TYPE;
  v_data_termino          tarefa.data_termino%TYPE;
  v_data_execucao         tarefa.data_execucao%TYPE;
  v_data_inicio_aux       tarefa.data_inicio%TYPE;
  v_data_termino_aux      tarefa.data_termino%TYPE;
  v_num_max_dias_prazo    tarefa.num_max_dias_prazo%TYPE;
  v_num_dias              INTEGER;
  v_descricao             tarefa.descricao%TYPE;
  v_horas_totais          tarefa_usuario.horas_totais%TYPE;
  v_data                  tarefa_usuario_data.data%TYPE;
  v_horas                 tarefa_usuario_data.horas%TYPE;
  v_vetor_usuario_id      LONG;
  v_vetor_horas           LONG;
  v_vetor_datas           LONG;
  v_data_char             VARCHAR2(20);
  v_horas_char            VARCHAR2(20);
  v_usuario_para_id       usuario.usuario_id%TYPE;
  v_delimitador           CHAR(1);
  v_flag_admin            usuario.flag_admin%TYPE;
  v_xml_antes             CLOB;
  v_xml_atual             CLOB;
  v_item_crono_id         item_crono.item_crono_id%TYPE;
  v_flag_planejado        item_crono.flag_planejado%TYPE;
  v_apelido               pessoa.apelido%TYPE;
  v_enderecados           VARCHAR2(4000);
  v_flag_apont_horas_aloc tipo_tarefa.flag_apont_horas_aloc%TYPE;
  --
  -- seleciona executores da tarefa
  CURSOR c_us IS
   SELECT tu.usuario_para_id,
          pe.apelido,
          tu.controle
     FROM tarefa_usuario tu,
          pessoa         pe
    WHERE tu.tarefa_id = p_tarefa_id
      AND tu.usuario_para_id = pe.usuario_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  v_flag_planejado := 'N';
  --
  IF nvl(v_item_crono_id, 0) > 0
  THEN
   SELECT flag_planejado
     INTO v_flag_planejado
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  SELECT descricao,
         data_inicio,
         data_termino,
         data_execucao,
         num_max_dias_prazo,
         job_id
    INTO v_descricao,
         v_data_inicio_aux,
         v_data_termino_aux,
         v_data_execucao,
         v_num_max_dias_prazo,
         v_job_id
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
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
  IF v_num_max_dias_prazo IS NOT NULL AND
     trunc(v_data_termino) >= trunc(v_data_inicio) + v_num_max_dias_prazo
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A data de término não pode ser maior que a data de início acrescida de ' ||
                 to_char(v_num_max_dias_prazo) || ' dias.';
   RAISE v_exception;
  END IF;
  --
  v_num_dias := feriado_pkg.qtd_dias_uteis_retornar(p_usuario_sessao_id,
                                                    v_data_inicio,
                                                    v_data_termino) + 1;
  --
  IF TRIM(p_vetor_usuario_id) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Pelo menos um usuário deve ser especificado.';
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
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa
     SET data_inicio  = v_data_inicio,
         data_termino = v_data_termino
   WHERE tarefa_id = p_tarefa_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor
  ------------------------------------------------------------
  -- marca todos os registros como candidatos a serem deletados
  UPDATE tarefa_usuario
     SET controle = 'DEL'
   WHERE tarefa_id = p_tarefa_id;
  --
  -- limpa todas as datas/estimativas dos usuarios
  DELETE FROM tarefa_usuario_data
   WHERE tarefa_id = p_tarefa_id;
  --
  v_delimitador      := '|';
  v_vetor_usuario_id := p_vetor_usuario_id;
  v_vetor_horas      := TRIM(p_vetor_horas);
  v_vetor_datas      := TRIM(p_vetor_datas);
  --
  WHILE nvl(length(rtrim(v_vetor_usuario_id)), 0) > 0
  LOOP
   v_usuario_para_id := to_number(prox_valor_retornar(v_vetor_usuario_id, v_delimitador));
   v_data_char       := prox_valor_retornar(v_vetor_datas, v_delimitador);
   v_horas_char      := prox_valor_retornar(v_vetor_horas, v_delimitador);
   --
   SELECT MAX(apelido)
     INTO v_apelido
     FROM pessoa
    WHERE usuario_id = v_usuario_para_id;
   --
   IF v_apelido IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse usuário não existe (' || to_char(v_usuario_para_id) || ').';
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
   --ALCBO_180723
   v_horas        := nvl(numero_converter(v_horas_char), 0);
   v_horas_totais := v_num_dias * v_horas;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_usuario
    WHERE tarefa_id = p_tarefa_id
      AND usuario_para_id = v_usuario_para_id;
   --
   IF v_qt = 0
   THEN
    INSERT INTO tarefa_usuario
     (tarefa_id,
      usuario_para_id,
      horas_totais,
      status,
      data_status)
    VALUES
     (p_tarefa_id,
      v_usuario_para_id,
      0,
      'EMEX',
      SYSDATE);
   ELSE
    -- usuario ja enderecado. Desmarca a exclusao
    UPDATE tarefa_usuario
       SET controle = NULL
     WHERE tarefa_id = p_tarefa_id
       AND usuario_para_id = v_usuario_para_id;
   END IF;
   --
   INSERT INTO tarefa_usuario_data
    (tarefa_id,
     usuario_para_id,
     data,
     horas)
   VALUES
    (p_tarefa_id,
     v_usuario_para_id,
     v_data,
     v_horas);
   --
   historico_pkg.hist_ender_registrar(v_usuario_para_id,
                                      'TAR',
                                      p_tarefa_id,
                                      'EXE',
                                      p_erro_cod,
                                      p_erro_msg);
   IF p_erro_cod <> '00000'
   THEN
    RAISE v_exception;
   END IF;
   --
   --ALCBO_070225
   SELECT flag_apont_horas_aloc
     INTO v_flag_apont_horas_aloc
     FROM tipo_tarefa
    WHERE tipo_tarefa_id IN (SELECT tipo_tarefa_id
                               FROM tarefa
                              WHERE tarefa_id = p_tarefa_id);
   --                        
   IF v_flag_apont_horas_aloc = 'S'
   THEN
    -- apontamento automatico de horas alocadas ligado.
    -- usa as horas alocadas para gerar o apontamento (timesheet)
    apontam_pkg.horas_tarefa_apontar(v_usuario_para_id,
                                     p_empresa_id,
                                     p_tarefa_id,
                                     data_mostrar(v_data),
                                     numero_mostrar(v_horas, 2, 'N'),
                                     p_erro_cod,
                                     p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
  END LOOP;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_usuario
   WHERE tarefa_id = p_tarefa_id
     AND controle IS NULL;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum usuário executor foi indicado.';
   RAISE v_exception;
  END IF;
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
  -- atualizacoes finais dos usuarios executores
  ------------------------------------------------------------
  v_enderecados := NULL;
  --
  FOR r_us IN c_us
  LOOP
   IF r_us.controle = 'DEL'
   THEN
    DELETE FROM tarefa_usuario
     WHERE tarefa_id = p_tarefa_id
       AND usuario_para_id = r_us.usuario_para_id;
    --
    -- exclui executor das tarefas repetidas
    tarefa_pkg.usuario_repet_processar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       p_tipo_alteracao,
                                       p_tarefa_id,
                                       r_us.usuario_para_id,
                                       'E',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- monta lista de usuarios enderecados para gravar no historico
    v_enderecados := v_enderecados || '; ' || r_us.apelido;
    --
    SELECT nvl(SUM(horas), 0)
      INTO v_horas
      FROM tarefa_usuario_data
     WHERE tarefa_id = p_tarefa_id
       AND usuario_para_id = r_us.usuario_para_id;
    --
    UPDATE tarefa_usuario
       SET horas_totais = v_horas
     WHERE tarefa_id = p_tarefa_id
       AND usuario_para_id = r_us.usuario_para_id;
    --
    --
    -- inclui executor nas tarefas repetidas (caso nao exista)
    tarefa_pkg.usuario_repet_processar(p_usuario_sessao_id,
                                       p_empresa_id,
                                       p_tipo_alteracao,
                                       p_tarefa_id,
                                       r_us.usuario_para_id,
                                       'I',
                                       p_erro_cod,
                                       p_erro_msg);
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   END IF;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_para_id,
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
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Endereçados: ' || substr(v_enderecados, 1, 950);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
 END atualizar_estimativa;
 --
 --
 PROCEDURE usuario_repet_processar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 23/08/2022
  -- DESCRICAO: subrotina que processa o enderecamento de um usuario nas tarefas repetidas, 
  -- de acordo com o codigo de acao passado.   NAO FAZ COMMIT.
  -- p_cod_acao: I - incluir o executor nas tarefas repetidas;
  --             E - excluir o executor das tarefas repetidas).
  -- p_tipo_alteracao para repeticoes:
  --             COR - corrente, SEG - seguintes, TOD - todas
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tipo_alteracao      IN VARCHAR2,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
  p_usuario_executor_id IN NUMBER,
  p_cod_acao_usu        IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt                INTEGER;
  v_identif_objeto    historico.identif_objeto%TYPE;
  v_compl_histor      historico.complemento%TYPE;
  v_historico_id      historico.historico_id%TYPE;
  v_exception         EXCEPTION;
  v_job_id            job.job_id%TYPE;
  v_data_inicio       tarefa.data_inicio%TYPE;
  v_data              tarefa_usuario_data.data%TYPE;
  v_data_aux          tarefa_usuario_data.data%TYPE;
  v_horas             tarefa_usuario_data.horas%TYPE;
  v_item_crono_id     item_crono.item_crono_id%TYPE;
  v_repet_grupo       item_crono.repet_grupo%TYPE;
  v_num_max_horas_dia NUMBER;
  -- 
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> p_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt                := 0;
  v_num_max_horas_dia := numero_converter(empresa_pkg.parametro_retornar(p_empresa_id,
                                                                         'NUM_MAX_HORAS_APONTADAS_DIA'));
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------ 
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_cod_acao_usu) IS NULL OR p_cod_acao_usu NOT IN ('I', 'E')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao_usu || ').';
   RAISE v_exception;
  END IF;
  --
  -- seleciona dados da tarefa original
  SELECT job_id,
         data_inicio
    INTO v_job_id,
         v_data_inicio
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  SELECT nvl(MAX(horas_totais), 0)
    INTO v_horas
    FROM tarefa_usuario
   WHERE tarefa_id = p_tarefa_id
     AND usuario_para_id = p_usuario_executor_id;
  --
  IF v_horas > v_num_max_horas_dia
  THEN
   -- ultrapassou o limite de horas apontadas por dia.
   -- grava zero nas tarefas repetidas
   v_horas := 0;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF nvl(v_item_crono_id, 0) > 0
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco (tarefas repetidas)
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   -- loop por tarefa repetida
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     -- verifica se o executor ja esta na tarefa repetida
     SELECT COUNT(*)
       INTO v_qt
       FROM tarefa_usuario
      WHERE tarefa_id = r_ta.tarefa_id
        AND usuario_para_id = p_usuario_executor_id;
     --
     IF p_cod_acao_usu = 'I' AND v_qt = 0
     THEN
      -- precisa incluir o executor na tarefa repetida.
      -- descobre a primeira data da tarefa.
      SELECT MIN(data)
        INTO v_data
        FROM tarefa_usuario_data
       WHERE tarefa_id = r_ta.tarefa_id;
      --
      IF v_data IS NULL
      THEN
       SELECT data_inicio
         INTO v_data
         FROM tarefa
        WHERE tarefa_id = r_ta.tarefa_id;
      END IF;
      --
      INSERT INTO tarefa_usuario
       (tarefa_id,
        usuario_para_id,
        horas_totais,
        status,
        data_status)
      VALUES
       (r_ta.tarefa_id,
        p_usuario_executor_id,
        v_horas,
        'EMEX',
        SYSDATE);
      --             
      INSERT INTO tarefa_usuario_data
       (tarefa_id,
        usuario_para_id,
        data,
        horas)
      VALUES
       (r_ta.tarefa_id,
        p_usuario_executor_id,
        v_data,
        v_horas);
      --
      historico_pkg.hist_ender_registrar(p_usuario_executor_id,
                                         'TAR',
                                         r_ta.tarefa_id,
                                         'EXE',
                                         p_erro_cod,
                                         p_erro_msg);
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
      --
      -- recalcula alocacao
      cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_usuario_executor_id,
                                            v_data,
                                            v_data,
                                            p_erro_cod,
                                            p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF; -- fim do IF p_cod_acao_usu = 'I'
     --
     IF p_cod_acao_usu = 'E' AND v_qt > 0
     THEN
      -- precisa excluir o executor da tarefa repetida.
      -- descobre o intervalo de datas da repeticao.
      SELECT MIN(data)
        INTO v_data
        FROM tarefa_usuario_data
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_executor_id;
      --
      SELECT MAX(data)
        INTO v_data_aux
        FROM tarefa_usuario_data
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_executor_id;
      --
      DELETE FROM tarefa_usuario_data
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_executor_id;
      --
      DELETE FROM tarefa_usuario
       WHERE tarefa_id = r_ta.tarefa_id
         AND usuario_para_id = p_usuario_executor_id;
      --
      -- recalcula alocacao
      cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                            p_empresa_id,
                                            p_usuario_executor_id,
                                            v_data,
                                            v_data_aux,
                                            p_erro_cod,
                                            p_erro_msg);
      --
      IF p_erro_cod <> '00000'
      THEN
       RAISE v_exception;
      END IF;
     END IF; -- IF p_cod_acao_usu = 'E'
    END IF; -- fim do IF (p_tipo_alteracao
   END LOOP; -- fim do loop por tarefa repetida
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
 END usuario_repet_processar;
 --
 --
 PROCEDURE excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia          ProcessMind     DATA: 12/05/2009
  -- DESCRICAO: Exclusão de TAREFA
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            28/08/2015  Alteração do nome do objeto (de pedido para tarefa).
  -- Silvia            19/01/2016  Tratamento de cronograma
  -- Silvia            25/04/2017  Libera exclusao para o usuario admin.
  -- Silvia            19/09/2017  Grava XML no historico.
  -- Silvia            30/07/2020  Exclusao de metadados.
  -- Silvia            18/08/2020  Exclusao de tarefa_usuario_data
  -- Silvia            25/08/2020  Recalculo das alocacoes dos executores excluidos
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_descricao       tarefa.descricao%TYPE;
  v_data_inicio     tarefa.data_inicio%TYPE;
  v_data_termino    tarefa.data_termino%TYPE;
  v_job_id          tarefa.job_id%TYPE;
  v_status_tarefa   tarefa.status%TYPE;
  v_flag_admin      usuario.flag_admin%TYPE;
  v_item_crono_id   item_crono.item_crono_id%TYPE;
  v_data_planej_ini item_crono.data_planej_ini%TYPE;
  v_data_planej_fim item_crono.data_planej_fim%TYPE;
  v_xml_atual       CLOB;
  --
  CURSOR c_arq_ta IS
   SELECT arquivo_id
     FROM arquivo_tarefa
    WHERE tarefa_id = p_tarefa_id;
  --
  -- seleciona executores da tarefa
  CURSOR c_us IS
   SELECT usuario_para_id
     FROM tarefa_usuario
    WHERE tarefa_id = p_tarefa_id;
  --
  -- seleciona executores do item do cronograma
  CURSOR c_uc IS
   SELECT usuario_id
     FROM item_crono_usu
    WHERE item_crono_id = v_item_crono_id;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT ta.descricao,
         ta.data_inicio,
         ta.data_termino,
         ta.job_id,
         ta.status
    INTO v_descricao,
         v_data_inicio,
         v_data_termino,
         v_job_id,
         v_status_tarefa
    FROM tarefa ta
   WHERE ta.tarefa_id = p_tarefa_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem excluir a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE tarefa_id = p_tarefa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existem apontamentos de horas relacionados a essa task.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_afazer
   WHERE tarefa_id = p_tarefa_id
     AND rownum = 1;
  --
  IF v_qt > 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Já existe TO-DO List relacionado a essa task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono ic
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id
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
  SELECT COUNT(*)
    INTO v_qt
    FROM arquivo_tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  IF v_qt > 0 AND v_status_tarefa <> 'TEMP'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem arquivos associados a essa task.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'S', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := substr(TRIM(v_descricao), 1, 500);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_tarefa_id,
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
  -- exclusao dos arquivos associados a tarefas temporarias
  ------------------------------------------------------------
  FOR r_arq_ta IN c_arq_ta
  LOOP
   -- verifica o arquivo eh usado por outra TAREFA
   SELECT COUNT(*)
     INTO v_qt
     FROM arquivo_tarefa
    WHERE arquivo_id = r_arq_ta.arquivo_id
      AND tarefa_id <> p_tarefa_id;
   --
   IF v_qt = 0
   THEN
    -- nao esta. Pode excluir o arquivo.
    arquivo_pkg.excluir(p_usuario_sessao_id, r_arq_ta.arquivo_id, p_erro_cod, p_erro_msg);
    --
    IF p_erro_cod <> '00000'
    THEN
     RAISE v_exception;
    END IF;
   ELSE
    -- esta associado a outras. Exclui apenas o relacionamento.
    DELETE FROM arquivo_tarefa
     WHERE arquivo_id = r_arq_ta.arquivo_id
       AND tarefa_id = p_tarefa_id;
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- exclusoes dos usuarios executores da tarefa
  ------------------------------------------------------------
  DELETE FROM tarefa_usuario_data
   WHERE tarefa_id = p_tarefa_id;
  --
  FOR r_us IN c_us
  LOOP
   DELETE FROM tarefa_usuario
    WHERE tarefa_id = p_tarefa_id
      AND usuario_para_id = r_us.usuario_para_id;
   --
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_para_id,
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
  UPDATE item_crono
     SET objeto_id  = NULL,
         cod_objeto = NULL
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  DELETE FROM hist_ender
   WHERE tipo_objeto = 'TAR'
     AND objeto_id = p_tarefa_id;
  --
  DELETE FROM tarefa_evento
   WHERE tarefa_id = p_tarefa_id;
  --
  DELETE FROM tarefa_tp_atrib_valor tv
   WHERE EXISTS (SELECT 1
            FROM tarefa_tipo_produto tt
           WHERE tt.tarefa_id = p_tarefa_id
             AND tt.tarefa_tipo_produto_id = tv.tarefa_tipo_produto_id);
  --
  DELETE FROM tarefa_tipo_produto
   WHERE tarefa_id = p_tarefa_id;
  --
  DELETE FROM tarefa_link
   WHERE tarefa_id = p_tarefa_id;
  --
  DELETE FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
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
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
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
 END excluir;
 --
 --
 PROCEDURE terminar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/07/2020
  -- DESCRICAO: marca o trabalho de um determinado usuario executor como terminado 
  --   (executado).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Ana Luiza       25/06/2024  Ajuste para concluir/terminar task apos executores ok
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
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
  v_status_tarefa  tarefa.status%TYPE;
  v_status_usu     tarefa_usuario.status%TYPE;
  v_exec_apelido   pessoa.apelido%TYPE;
  v_exec_login     usuario.login%TYPE;
  v_total_count    NUMBER;
  v_exec_count     NUMBER;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ta.status
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id;
  --
  IF v_status_tarefa <> 'EMEX'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------  
  SELECT MAX(status)
    INTO v_status_usu
    FROM tarefa_usuario
   WHERE tarefa_id = p_tarefa_id
     AND usuario_para_id = p_usuario_executor_id;
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
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa_usuario
     SET status      = 'EXEC',
         data_status = SYSDATE
   WHERE tarefa_id = p_tarefa_id
     AND usuario_para_id = p_usuario_executor_id;
  --
  ---ALCBO_250624
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_usuario
   WHERE tarefa_id = p_tarefa_id;
  --So chama se tiver mais de um usuario na task, se nao chamada e na web
  IF v_qt > 1
  THEN
   -- Conta o número total de linhas e o número de linhas com status 'EXEC'
   SELECT COUNT(*),
          SUM(CASE
               WHEN status = 'EXEC' THEN
                1
               ELSE
                0
              END)
     INTO v_total_count,
          v_exec_count
     FROM tarefa_usuario
    WHERE tarefa_id = p_tarefa_id;
   -- Verifica se todos os status são 'EXEC'
   IF v_total_count = v_exec_count
   THEN
    -- Chama a função tarefa_pkg.acao_executar
    tarefa_pkg.acao_executar(p_usuario_sessao_id,
                             p_empresa_id,
                             p_tarefa_id,
                             'TERMINAR',
                             NULL,
                             NULL,
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
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := v_exec_apelido || ' (' || v_exec_login || ') - Terminou';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 31/07/2020
  -- DESCRICAO: marca o trabalho de um determinado usuario executor como retomado  
  --   (volta para em execucao).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN empresa.empresa_id%TYPE,
  p_tarefa_id           IN tarefa.tarefa_id%TYPE,
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
  v_status_tarefa  tarefa.status%TYPE;
  v_status_usu     tarefa_usuario.status%TYPE;
  v_exec_apelido   pessoa.apelido%TYPE;
  v_exec_login     usuario.login%TYPE;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         jo.numero,
         jo.status,
         ta.status
    INTO v_job_id,
         v_numero_job,
         v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id;
  --
  IF v_status_tarefa <> 'EMEX'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da Task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------  
  SELECT MAX(status)
    INTO v_status_usu
    FROM tarefa_usuario
   WHERE tarefa_id = p_tarefa_id
     AND usuario_para_id = p_usuario_executor_id;
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
  UPDATE tarefa_usuario
     SET status      = 'EMEX',
         data_status = SYSDATE
   WHERE tarefa_id = p_tarefa_id
     AND usuario_para_id = p_usuario_executor_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := v_exec_apelido || ' (' || v_exec_login || ') - Retomado';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
 PROCEDURE acao_executar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia           ProcessMind     DATA: 07/06/2013
  -- DESCRICAO: Troca o status da tarefa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            25/04/2017  Libera acao para o usuario admin. Gera evento p/ CANCELAR
  -- Silvia            19/09/2017  Grava XML no historico.
  -- Silvia            30/07/2020  Novas transicoes. Grava data_execucao.
  -- Silvia            19/08/2020  Recalcula alocacao ao termino da exececucao.
  -- Silvia            06/10/2020  Tratamento de execucao retomada (status dos executores)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_cod_acao_tarefa   IN VARCHAR2,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_descricao       tarefa.descricao%TYPE;
  v_status_de       tarefa.status%TYPE;
  v_status_para     tarefa.status%TYPE;
  v_data_envio      tarefa.data_envio%TYPE;
  v_flag_volta_exec tarefa.flag_volta_exec%TYPE;
  v_flag_devolvida  tarefa.flag_devolvida%TYPE;
  v_data_execucao   tarefa.data_execucao%TYPE;
  v_data_inicio     tarefa.data_inicio%TYPE;
  v_data_termino    tarefa.data_termino%TYPE;
  v_motivo          evento_motivo.nome%TYPE;
  v_data_hoje       DATE;
  v_flag_admin      usuario.flag_admin%TYPE;
  v_xml_atual       CLOB;
  --
  -- seleciona executores da tarefa
  CURSOR c_us IS
   SELECT usuario_para_id
     FROM tarefa_usuario
    WHERE tarefa_id = p_tarefa_id;
  --
 BEGIN
  v_qt        := 0;
  v_data_hoje := SYSDATE;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  IF util_pkg.desc_retornar('cod_acao_tarefa', p_cod_acao_tarefa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código da ação inválido (' || p_cod_acao_tarefa || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT ta.status,
         ta.data_envio,
         ta.flag_volta_exec,
         ta.flag_devolvida,
         ta.data_execucao,
         ta.data_inicio,
         ta.data_termino
    INTO v_status_de,
         v_data_envio,
         v_flag_volta_exec,
         v_flag_devolvida,
         v_data_execucao,
         v_data_inicio,
         v_data_termino
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem executar a ação.';
   RAISE v_exception;
  END IF;
  --
  -- a acao de RECUSAR corresponde na tela ao AJUSTAR
  --
  IF v_status_de = 'EMEX' AND p_cod_acao_tarefa = 'TERMINAR' AND v_flag_volta_exec = 'S'
  THEN
   v_status_para := 'EXEC';
   IF v_data_execucao IS NULL
   THEN
    -- guarda a data da primeira execucao
    v_data_execucao := SYSDATE;
   END IF;
  ELSIF v_status_de = 'EMEX' AND p_cod_acao_tarefa = 'TERMINAR' AND v_flag_volta_exec = 'N'
  THEN
   v_status_para := 'CONC';
   IF v_data_execucao IS NULL
   THEN
    -- guarda a data da primeira execucao
    v_data_execucao := SYSDATE;
   END IF;
  ELSIF v_status_de = 'EMEX' AND p_cod_acao_tarefa = 'CANCELAR'
  THEN
   v_status_para := 'CANC';
  ELSIF v_status_de = 'EXEC' AND p_cod_acao_tarefa = 'RECUSAR'
  THEN
   v_status_para    := 'EMEX';
   v_flag_devolvida := 'S';
  ELSIF v_status_de = 'EXEC' AND p_cod_acao_tarefa = 'CONCLUIR'
  THEN
   v_status_para := 'CONC';
  ELSIF v_status_de = 'EXEC' AND p_cod_acao_tarefa = 'CANCELAR'
  THEN
   v_status_para := 'CANC';
  ELSIF v_status_de = 'CONC' AND p_cod_acao_tarefa = 'RECUSAR'
  THEN
   v_status_para := 'EMEX';
  ELSIF v_status_de = 'CANC' AND p_cod_acao_tarefa = 'RETOMAR'
  THEN
   v_status_para := 'EMEX';
  ELSE
   p_erro_cod := '90000';
   p_erro_msg := 'Transição inválida (status: ' || v_status_de || ' ação: ' || p_cod_acao_tarefa || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------  
  IF p_cod_acao_tarefa IN ('RECUSAR', 'CANCELAR')
  THEN
   /*
   IF NVL(p_evento_motivo_id,0) = 0 THEN
      p_erro_cod := '90000';
      p_erro_msg := 'Para esse tipo de ação, o motivo deve ser especificado.';
      RAISE v_exception;
   END IF;
   */
   --
   IF TRIM(p_comentario) IS NULL
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Para esse tipo de ação, o preenchimento do comentário é obrigatório.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  IF length(p_comentario) > 2000
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O comentário não pode ter mais que 2000 caracteres.';
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
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa
     SET status         = v_status_para,
         data_status    = v_data_hoje,
         flag_devolvida = v_flag_devolvida,
         data_execucao  = v_data_execucao
   WHERE tarefa_id = p_tarefa_id;
  --
  INSERT INTO tarefa_evento
   (tarefa_evento_id,
    tarefa_id,
    usuario_id,
    data_evento,
    cod_acao,
    comentario,
    status_de,
    status_para,
    motivo)
  VALUES
   (seq_tarefa_evento.nextval,
    p_tarefa_id,
    p_usuario_sessao_id,
    SYSDATE,
    p_cod_acao_tarefa,
    TRIM(p_comentario),
    v_status_de,
    v_status_para,
    v_motivo);
  --
  ------------------------------------------------------------
  -- tratamento de execucao retomada
  ------------------------------------------------------------
  IF p_cod_acao_tarefa IN ('RECUSAR', 'RETOMAR')
  THEN
   -- a execucao esta sendo retomada ou refeita
   UPDATE tarefa_usuario
      SET status      = 'EMEX',
          data_status = SYSDATE
    WHERE tarefa_id = p_tarefa_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacoes finais dos usuarios executores
  ------------------------------------------------------------
  FOR r_us IN c_us
  LOOP
   -- recalcula alocacao
   cronograma_pkg.alocacao_usu_processar(p_usuario_sessao_id,
                                         p_empresa_id,
                                         r_us.usuario_para_id,
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
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'S', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := substr(TRIM(v_descricao), 1, 500);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   p_cod_acao_tarefa,
                   v_identif_objeto,
                   p_tarefa_id,
                   v_compl_histor,
                   v_motivo,
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
 END acao_executar;
 --
 --
 PROCEDURE cancelar_demais
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 27/11/2020
  -- DESCRICAO: Cancelamento de TAREFA com repeticao
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_evento_motivo_id  IN evento_motivo.evento_motivo_id%TYPE,
  p_comentario        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt            INTEGER;
  v_exception     EXCEPTION;
  v_job_id        job.job_id%TYPE;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  v_repet_grupo   item_crono.repet_grupo%TYPE;
  v_data_inicio   tarefa.data_inicio%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> p_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
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
   p_erro_msg := 'Essa task não existe ou não petence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT job_id,
         data_inicio
    INTO v_job_id,
         v_data_inicio
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     tarefa_pkg.acao_executar(p_usuario_sessao_id,
                              p_empresa_id,
                              r_ta.tarefa_id,
                              'CANCELAR',
                              p_evento_motivo_id,
                              p_comentario,
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
 END cancelar_demais;
 --
 --
 PROCEDURE arquivo_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 07/06/2013
  -- DESCRICAO: Adicionar arquivo na tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            20/07/2020  Novo parametro tipo_arq_tarefa
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id   IN NUMBER,
  p_empresa_id          IN NUMBER,
  p_arquivo_id          IN arquivo.arquivo_id%TYPE,
  p_volume_id           IN arquivo.volume_id%TYPE,
  p_tarefa_id           IN arquivo_tarefa.tarefa_id%TYPE,
  p_descricao           IN arquivo.descricao%TYPE,
  p_nome_original       IN arquivo.nome_original%TYPE,
  p_nome_fisico         IN arquivo.nome_fisico%TYPE,
  p_mime_type           IN arquivo.mime_type%TYPE,
  p_tamanho             IN arquivo.tamanho%TYPE,
  p_thumb_arquivo_id    IN arquivo.arquivo_id%TYPE,
  p_thumb_volume_id     IN arquivo.volume_id%TYPE,
  p_thumb_nome_original IN arquivo.nome_original%TYPE,
  p_thumb_nome_fisico   IN arquivo.nome_fisico%TYPE,
  p_thumb_mime_type     IN arquivo.mime_type%TYPE,
  p_thumb_tamanho       IN arquivo.tamanho%TYPE,
  p_tipo_arq_tarefa     IN arquivo_tarefa.tipo_arq_tarefa%TYPE,
  p_palavras_chave      IN VARCHAR2,
  p_erro_cod            OUT VARCHAR2,
  p_erro_msg            OUT VARCHAR2
 ) IS
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_status_job      job.status%TYPE;
  v_status_tarefa   tarefa.status%TYPE;
  v_tipo_arquivo_id tipo_arquivo.tipo_arquivo_id%TYPE;
  v_tam_max_arq     tipo_arquivo.tam_max_arq%TYPE;
  v_qtd_max_arq     tipo_arquivo.qtd_max_arq%TYPE;
  v_extensoes       tipo_arquivo.extensoes%TYPE;
  v_flag_admin      usuario.flag_admin%TYPE;
  v_desc_tipo_arq   VARCHAR2(100);
  v_extensao        VARCHAR2(200);
  v_qtd_arq         NUMBER(10);
  v_lbl_job         VARCHAR2(100);
  v_xml_atual       CLOB;
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
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status
    INTO v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
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
  SELECT MAX(tipo_arquivo_id)
    INTO v_tipo_arquivo_id
    FROM tipo_arquivo
   WHERE empresa_id = p_empresa_id
     AND codigo = 'TAREFA';
  --
  IF v_tipo_arquivo_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de arquivo não encontrado (TAREFA).';
   RAISE v_exception;
  END IF;
  --
  SELECT tam_max_arq,
         qtd_max_arq,
         extensoes
    INTO v_tam_max_arq,
         v_qtd_max_arq,
         v_extensoes
    FROM tipo_arquivo
   WHERE tipo_arquivo_id = v_tipo_arquivo_id;
  --
  SELECT COUNT(*)
    INTO v_qtd_arq
    FROM arquivo_tarefa
   WHERE tarefa_id = p_tarefa_id;
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
  IF rtrim(p_tipo_arq_tarefa) IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do subtipo do arquivo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_tipo_arq := util_pkg.desc_retornar('tipo_arq_tarefa', p_tipo_arq_tarefa);
  --
  IF v_desc_tipo_arq IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Código do subtipo de arquivo inválido (' || p_tipo_arq_tarefa || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  arquivo_pkg.adicionar(p_usuario_sessao_id,
                        p_arquivo_id,
                        p_volume_id,
                        p_tarefa_id,
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
  UPDATE arquivo_tarefa
     SET tipo_arq_tarefa = TRIM(p_tipo_arq_tarefa),
         flag_thumb      = 'N'
   WHERE arquivo_id = p_arquivo_id;
  --
  -- verifica se veio thumbnail
  IF nvl(p_thumb_arquivo_id, 0) > 0
  THEN
   arquivo_pkg.adicionar(p_usuario_sessao_id,
                         p_thumb_arquivo_id,
                         p_thumb_volume_id,
                         p_tarefa_id,
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
   UPDATE arquivo_tarefa
      SET tipo_arq_tarefa = TRIM(p_tipo_arq_tarefa),
          flag_thumb      = 'S',
          chave_thumb     = p_arquivo_id
    WHERE arquivo_id = p_thumb_arquivo_id;
   --
   UPDATE arquivo_tarefa
      SET chave_thumb = p_arquivo_id
    WHERE arquivo_id = p_arquivo_id;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Inclusão de arquivo de ' || v_desc_tipo_arq || ' (' || p_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
 END arquivo_adicionar;
 --
 --
 PROCEDURE arquivo_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 07/06/2013
  -- DESCRICAO: Excluir arquivo de tarefa.
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
  v_qt              INTEGER;
  v_exception       EXCEPTION;
  v_identif_objeto  historico.identif_objeto%TYPE;
  v_compl_histor    historico.complemento%TYPE;
  v_historico_id    historico.historico_id%TYPE;
  v_status_job      job.status%TYPE;
  v_status_tarefa   tarefa.status%TYPE;
  v_tarefa_id       tarefa.tarefa_id%TYPE;
  v_nome_original   arquivo.nome_original%TYPE;
  v_flag_admin      usuario.flag_admin%TYPE;
  v_desc_tipo_arq   VARCHAR2(100);
  v_lbl_job         VARCHAR2(100);
  v_xml_atual       CLOB;
  v_arquivo_id_aux  arquivo.arquivo_id%TYPE;
  v_chave_thumb     arquivo_tarefa.chave_thumb%TYPE;
  v_tipo_arq_tarefa arquivo_tarefa.tipo_arq_tarefa%TYPE;
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
    FROM tarefa         ta,
         arquivo_tarefa ar
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.tarefa_id = ta.tarefa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse arquivo não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status,
         aq.nome_original,
         ar.tarefa_id,
         util_pkg.desc_retornar('tipo_arq_tarefa', ar.tipo_arq_tarefa),
         ar.chave_thumb,
         ar.tipo_arq_tarefa
    INTO v_status_job,
         v_status_tarefa,
         v_nome_original,
         v_tarefa_id,
         v_desc_tipo_arq,
         v_chave_thumb,
         v_tipo_arq_tarefa
    FROM arquivo_tarefa ar,
         tarefa         ta,
         job            jo,
         arquivo        aq
   WHERE ar.arquivo_id = p_arquivo_id
     AND ar.arquivo_id = aq.arquivo_id
     AND ar.tarefa_id = ta.tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  -- verifica se o arquivo tem thumbnail
  SELECT MAX(arquivo_id)
    INTO v_arquivo_id_aux
    FROM arquivo_tarefa
   WHERE tarefa_id = v_tarefa_id
     AND tipo_arq_tarefa = v_tipo_arq_tarefa
     AND chave_thumb = v_chave_thumb
     AND arquivo_id <> p_arquivo_id;
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
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(v_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Exclusão de arquivo de ' || v_desc_tipo_arq || ' (' || v_nome_original || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
 END arquivo_excluir;
 --
 --
 PROCEDURE link_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 23/07/2020
  -- DESCRICAO: Adicionar link na tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/08/2022  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_id         IN tarefa_link.tarefa_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_url               IN VARCHAR2,
  p_tipo_link         IN tarefa_link.tipo_link%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_tarefa_link_id    OUT tarefa_link.tarefa_link_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_tarefa  tarefa.status%TYPE;
  v_data_inicio    tarefa.data_inicio%TYPE;
  v_tarefa_link_id tarefa_link.tarefa_link_id%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_desc_tipo_link VARCHAR2(100);
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  v_item_crono_id  item_crono.item_crono_id%TYPE;
  v_repet_grupo    item_crono.repet_grupo%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> p_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt             := 0;
  p_tarefa_link_id := 0;
  v_lbl_job        := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
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
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status,
         ta.data_inicio,
         jo.job_id
    INTO v_status_job,
         v_status_tarefa,
         v_data_inicio,
         v_job_id
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
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
  SELECT seq_tarefa_link.nextval
    INTO v_tarefa_link_id
    FROM dual;
  --
  INSERT INTO tarefa_link
   (tarefa_link_id,
    tarefa_id,
    usuario_id,
    data_entrada,
    tipo_link,
    url,
    descricao)
  VALUES
   (v_tarefa_link_id,
    p_tarefa_id,
    p_usuario_sessao_id,
    SYSDATE,
    TRIM(p_tipo_link),
    TRIM(p_url),
    TRIM(p_descricao));
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(p_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     -- verifica se o link ja existe na tarefa repetida
     SELECT COUNT(*)
       INTO v_qt
       FROM tarefa_link
      WHERE tarefa_id = r_ta.tarefa_id
        AND tipo_link = p_tipo_link
        AND TRIM(upper(url)) = TRIM(upper(p_url));
     --
     IF v_qt = 0
     THEN
      INSERT INTO tarefa_link
       (tarefa_link_id,
        tarefa_id,
        usuario_id,
        data_entrada,
        tipo_link,
        url,
        descricao)
      VALUES
       (seq_tarefa_link.nextval,
        r_ta.tarefa_id,
        p_usuario_sessao_id,
        SYSDATE,
        TRIM(p_tipo_link),
        TRIM(p_url),
        TRIM(p_descricao));
     END IF;
    END IF; -- fim do IF (p_tipo_alteracao
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Inclusão de hiperlink de ' || v_desc_tipo_link || ' (' || p_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
  p_tarefa_link_id := v_tarefa_link_id;
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
 END link_adicionar;
 --
 --
 PROCEDURE link_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 23/07/2020
  -- DESCRICAO: Excluir link de tarefa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            24/08/2022  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tarefa_link_id    IN tarefa_link.tarefa_link_id%TYPE,
  p_tipo_alteracao    IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_job_id         job.job_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_tarefa  tarefa.status%TYPE;
  v_data_inicio    tarefa.data_inicio%TYPE;
  v_tarefa_id      tarefa.tarefa_id%TYPE;
  v_url            tarefa_link.url%TYPE;
  v_tipo_link      tarefa_link.tipo_link%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_desc_tipo_link VARCHAR2(100);
  v_lbl_job        VARCHAR2(100);
  v_xml_atual      CLOB;
  v_item_crono_id  item_crono.item_crono_id%TYPE;
  v_repet_grupo    item_crono.repet_grupo%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> v_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa      ta,
         tarefa_link tl
   WHERE tl.tarefa_link_id = p_tarefa_link_id
     AND tl.tarefa_id = ta.tarefa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse hiperlink não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         jo.job_id,
         ta.status,
         ta.data_inicio,
         tl.url,
         tl.tarefa_id,
         util_pkg.desc_retornar('tipo_link', tl.tipo_link),
         tl.tipo_link
    INTO v_status_job,
         v_job_id,
         v_status_tarefa,
         v_data_inicio,
         v_url,
         v_tarefa_id,
         v_desc_tipo_link,
         v_tipo_link
    FROM tarefa      ta,
         tarefa_link tl,
         job         jo
   WHERE tl.tarefa_link_id = p_tarefa_link_id
     AND tl.tarefa_id = ta.tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = v_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tarefa_link
   WHERE tarefa_link_id = p_tarefa_link_id;
  --
  ------------------------------------------------------------
  -- gera xml do log 
  ------------------------------------------------------------
  tarefa_pkg.xml_gerar(v_tarefa_id, 'N', v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000'
  THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     -- exclui o link da tarefa repetida
     DELETE FROM tarefa_link
      WHERE tarefa_id = r_ta.tarefa_id
        AND tipo_link = v_tipo_link
        AND TRIM(upper(url)) = TRIM(upper(v_url));
    END IF; -- fim do IF (p_tipo_alteracao
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Exclusão de hiperlink de ' || v_desc_tipo_link || ' (' || v_url || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
 END link_excluir;
 --
 --
 PROCEDURE afazer_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2020
  -- DESCRICAO: Adicionar item a fazer (TO-DO) na tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_id         IN tarefa_afazer.tarefa_id%TYPE,
  p_usuario_resp_id   IN tarefa_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_tarefa_afazer_id  OUT tarefa_afazer.tarefa_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_exception        EXCEPTION;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_status_job       job.status%TYPE;
  v_status_tarefa    tarefa.status%TYPE;
  v_tarefa_afazer_id tarefa_afazer.tarefa_afazer_id%TYPE;
  v_ordem            tarefa_afazer.ordem%TYPE;
  v_data             tarefa_afazer.data%TYPE;
  v_flag_admin       usuario.flag_admin%TYPE;
  v_lbl_job          VARCHAR2(100);
  --
 BEGIN
  v_qt               := 0;
  p_tarefa_afazer_id := 0;
  v_lbl_job          := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status
    INTO v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
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
    FROM tarefa_afazer
   WHERE tarefa_id = p_tarefa_id
     AND flag_feito = 'N';
  --
  SELECT seq_tarefa_afazer.nextval
    INTO v_tarefa_afazer_id
    FROM dual;
  --
  INSERT INTO tarefa_afazer
   (tarefa_afazer_id,
    tarefa_id,
    usuario_resp_id,
    data,
    descricao,
    flag_feito,
    ordem)
  VALUES
   (v_tarefa_afazer_id,
    p_tarefa_id,
    zvl(p_usuario_resp_id, NULL),
    v_data,
    TRIM(p_descricao),
    'N',
    v_ordem);
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Inclusão de TO-DO (' || TRIM(p_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
  p_tarefa_afazer_id := v_tarefa_afazer_id;
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
 END afazer_adicionar;
 --
 --
 PROCEDURE afazer_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2020
  -- DESCRICAO: Atualizar a fazer (TO-DO) da tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_usuario_resp_id   IN tarefa_afazer.usuario_resp_id%TYPE,
  p_descricao         IN VARCHAR2,
  p_data              IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_tarefa  tarefa.status%TYPE;
  v_tarefa_id      tarefa.tarefa_id%TYPE;
  v_data           tarefa_afazer.data%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
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
    FROM tarefa_afazer
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  -- 
  SELECT ta.tarefa_id,
         ta.status
    INTO v_tarefa_id,
         v_status_tarefa
    FROM tarefa        ta,
         tarefa_afazer tf
   WHERE tf.tarefa_afazer_id = p_tarefa_afazer_id
     AND tf.tarefa_id = ta.tarefa_id;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status
    INTO v_status_job
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = v_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
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
  UPDATE tarefa_afazer
     SET descricao       = TRIM(p_descricao),
         data            = v_data,
         usuario_resp_id = zvl(p_usuario_resp_id, NULL)
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Atualização de TO-DO (' || TRIM(p_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2020
  -- DESCRICAO: Atualizar flag_feito do a fazer (TO-DO) da tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_flag_feito        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_tarefa  tarefa.status%TYPE;
  v_tarefa_id      tarefa.tarefa_id%TYPE;
  v_descricao      tarefa_afazer.descricao%TYPE;
  v_ordem          tarefa_afazer.ordem%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_lbl_job        VARCHAR2(100);
  v_acao           VARCHAR2(20);
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
    FROM tarefa_afazer
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  -- 
  SELECT ta.tarefa_id,
         ta.status,
         tf.descricao
    INTO v_tarefa_id,
         v_status_tarefa,
         v_descricao
    FROM tarefa        ta,
         tarefa_afazer tf
   WHERE tf.tarefa_afazer_id = p_tarefa_afazer_id
     AND tf.tarefa_id = ta.tarefa_id;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status
    INTO v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = v_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
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
    FROM tarefa_afazer
   WHERE tarefa_id = v_tarefa_id
     AND flag_feito = p_flag_feito;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE tarefa_afazer
     SET flag_feito = p_flag_feito,
         ordem      = v_ordem
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Atualização de TO-DO como ' || v_acao || ' (' || TRIM(v_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2020
  -- DESCRICAO: Reordenar itens a fazer (TO-DO) da tarefa 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN NUMBER,
  p_tarefa_id              IN tarefa.tarefa_id%TYPE,
  p_vetor_tarefa_afazer_id IN VARCHAR2,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                     INTEGER;
  v_exception              EXCEPTION;
  v_status_job             job.status%TYPE;
  v_status_tarefa          tarefa.status%TYPE;
  v_ordem                  tarefa_afazer.ordem%TYPE;
  v_tarefa_afazer_id       tarefa_afazer.tarefa_afazer_id%TYPE;
  v_flag_admin             usuario.flag_admin%TYPE;
  v_vetor_tarefa_afazer_id VARCHAR2(2000);
  v_lbl_job                VARCHAR2(100);
  v_delimitador            CHAR(1);
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
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa task não existe ou não petence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status
    INTO v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  v_delimitador := '|';
  v_ordem       := 0;
  --
  v_vetor_tarefa_afazer_id := p_vetor_tarefa_afazer_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tarefa_afazer_id)), 0) > 0
  LOOP
   v_tarefa_afazer_id := to_number(prox_valor_retornar(v_vetor_tarefa_afazer_id, v_delimitador));
   v_ordem            := v_ordem + 10;
   --
   UPDATE tarefa_afazer
      SET ordem = v_ordem
    WHERE tarefa_afazer_id = v_tarefa_afazer_id;
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
  -- DESENVOLVEDOR: Silvia              ProcessMind     DATA: 27/07/2020
  -- DESCRICAO: Excluir item a fazer (TO-DO) da tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN NUMBER,
  p_tarefa_afazer_id  IN tarefa_afazer.tarefa_afazer_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_status_job     job.status%TYPE;
  v_status_tarefa  tarefa.status%TYPE;
  v_tarefa_id      tarefa.tarefa_id%TYPE;
  v_descricao      tarefa_afazer.descricao%TYPE;
  v_flag_admin     usuario.flag_admin%TYPE;
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
    FROM tarefa_afazer
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse TO-DO não existe.';
   RAISE v_exception;
  END IF;
  -- 
  SELECT ta.tarefa_id,
         ta.status,
         tf.descricao
    INTO v_tarefa_id,
         v_status_tarefa,
         v_descricao
    FROM tarefa        ta,
         tarefa_afazer tf
   WHERE tf.tarefa_afazer_id = p_tarefa_afazer_id
     AND tf.tarefa_id = ta.tarefa_id;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.status,
         ta.status
    INTO v_status_job,
         v_status_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = v_tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tarefa_afazer
   WHERE tarefa_afazer_id = p_tarefa_afazer_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Exclusão de TO-DO (' || TRIM(v_descricao) || ')';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
 PROCEDURE tipo_produto_adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/07/2020
  -- DESCRICAO: Inclusao de tipo_produto na tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/12/2020  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  -- Silvia            05/07/2021  Implementacao de job_tipo_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_id              IN tarefa_tipo_produto.tarefa_id%TYPE,
  p_tipo_produto_id        IN job_tipo_produto.tipo_produto_id%TYPE,
  p_complemento            IN VARCHAR2,
  p_descricao              IN CLOB,
  p_vetor_atributo_id      IN VARCHAR2,
  p_vetor_atributo_valor   IN CLOB,
  p_tipo_alteracao         IN VARCHAR2,
  p_tarefa_tipo_produto_id OUT tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_erro_cod               OUT VARCHAR2,
  p_erro_msg               OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_exception                  EXCEPTION;
  v_job_id                     job.job_id%TYPE;
  v_numero_job                 job.numero%TYPE;
  v_status_job                 job.status%TYPE;
  v_nome_produto               tipo_produto.nome%TYPE;
  v_status_tarefa              tarefa.status%TYPE;
  v_data_inicio                tarefa.data_inicio%TYPE;
  v_num_max_itens              tarefa.num_max_itens%TYPE;
  v_repet_grupo                item_crono.repet_grupo%TYPE;
  v_item_crono_id              item_crono.item_crono_id%TYPE;
  v_tarefa_tipo_produto_id     tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE;
  v_tarefa_tipo_produto_id_alt tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE;
  v_job_tipo_produto_id        tarefa_tipo_produto.job_tipo_produto_id%TYPE;
  v_nome_atributo              metadado.nome%TYPE;
  v_tamanho                    metadado.tamanho%TYPE;
  v_flag_obrigatorio           metadado.flag_obrigatorio%TYPE;
  v_tipo_dado                  tipo_dado.codigo%TYPE;
  v_lbl_job                    VARCHAR2(100);
  v_vetor_atributo_id          LONG;
  v_vetor_atributo_valor       LONG;
  v_metadado_id                tarefa_tp_atrib_valor.metadado_id%TYPE;
  v_valor_atributo             LONG;
  v_valor_atributo_sai         LONG;
  v_delimitador                CHAR(1);
  v_flag_admin                 usuario.flag_admin%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> p_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt                     := 0;
  p_tarefa_tipo_produto_id := 0;
  v_lbl_job                := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  -----------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = p_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(jo.job_id),
         MAX(ta.status),
         MAX(ta.data_inicio),
         MAX(ta.num_max_itens)
    INTO v_job_id,
         v_status_tarefa,
         v_data_inicio,
         v_num_max_itens
    FROM job    jo,
         tarefa ta
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id
     AND ta.empresa_id = p_empresa_id;
  --
  IF v_job_id IS NULL
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa Task não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_produto_id, 0) = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo do entregável deve ser informado.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(status),
         MAX(numero)
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_produto
   WHERE tipo_produto_id = nvl(p_tipo_produto_id, 0);
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de entregável inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(TRIM(p_complemento)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do entregável não pode ter mais que 100 caracteres.';
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
  SELECT nome
    INTO v_nome_produto
    FROM tipo_produto
   WHERE tipo_produto_id = p_tipo_produto_id;
  --
  -- verifica se o tipo de produto ja esta associado o job
  SELECT MAX(job_tipo_produto_id)
    INTO v_job_tipo_produto_id
    FROM job_tipo_produto
   WHERE job_id = v_job_id
     AND tipo_produto_id = p_tipo_produto_id
     AND nvl(upper(TRIM(complemento)), 'ZZZZZ') = nvl(upper(TRIM(p_complemento)), 'ZZZZZ');
  --
  -- verifica se o tipo de produto ja esta associado a tarefa
  IF v_job_tipo_produto_id IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE tarefa_id = p_tarefa_id
      AND job_tipo_produto_id = v_job_tipo_produto_id;
   -- 
   IF v_qt > 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse entregável já se encontra associado à Task (' || v_nome_produto || ' ' ||
                  TRIM(p_complemento) || ').';
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
  SELECT seq_tarefa_tipo_produto.nextval
    INTO v_tarefa_tipo_produto_id
    FROM dual;
  --
  INSERT INTO tarefa_tipo_produto
   (tarefa_tipo_produto_id,
    tarefa_id,
    job_tipo_produto_id,
    descricao,
    data_entrada)
  VALUES
   (v_tarefa_tipo_produto_id,
    p_tarefa_id,
    v_job_tipo_produto_id,
    TRIM(p_descricao),
    SYSDATE);
  --
  IF v_num_max_itens IS NOT NULL
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE tarefa_id = p_tarefa_id;
   --
   IF v_qt > v_num_max_itens
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O número máximo de Entregáveis por Task é ' || to_char(v_num_max_itens) || ' .';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  v_delimitador          := '^';
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
      AND grupo = 'ITEM_OS';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado do entregável inválido (' || to_char(v_metadado_id) || ').';
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
   INSERT INTO tarefa_tp_atrib_valor
    (tarefa_tipo_produto_id,
     metadado_id,
     valor_atributo)
   VALUES
    (v_tarefa_tipo_produto_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     SELECT MAX(tarefa_tipo_produto_id)
       INTO v_tarefa_tipo_produto_id_alt
       FROM tarefa_tipo_produto
      WHERE tarefa_id = r_ta.tarefa_id
        AND job_tipo_produto_id = v_job_tipo_produto_id;
     --
     IF v_tarefa_tipo_produto_id_alt IS NOT NULL
     THEN
      UPDATE tarefa_tipo_produto
         SET descricao = TRIM(p_descricao)
       WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id_alt;
     ELSE
      SELECT seq_tarefa_tipo_produto.nextval
        INTO v_tarefa_tipo_produto_id_alt
        FROM dual;
      --
      INSERT INTO tarefa_tipo_produto
       (tarefa_tipo_produto_id,
        tarefa_id,
        job_tipo_produto_id,
        descricao,
        data_entrada)
      VALUES
       (v_tarefa_tipo_produto_id_alt,
        r_ta.tarefa_id,
        v_job_tipo_produto_id,
        TRIM(p_descricao),
        SYSDATE);
     END IF;
     --
     -- copia os metadados do item original
     DELETE FROM tarefa_tp_atrib_valor
      WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id_alt;
     --
     INSERT INTO tarefa_tp_atrib_valor
      (tarefa_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT v_tarefa_tipo_produto_id_alt,
             metadado_id,
             valor_atributo
        FROM tarefa_tp_atrib_valor
       WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id;
    END IF; -- fim do IF p_tipo_alteracao = 'SEG'
   END LOOP; -- fim do loop por tarefa repetida
  END IF; -- fim do IF p_tipo_alteracao IN ('SEG','TOD')
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(p_tarefa_id);
  v_compl_histor   := 'Inclusão de item: ' || TRIM(v_nome_produto || ' ' || p_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   p_tarefa_id,
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
  p_tarefa_tipo_produto_id := v_tarefa_tipo_produto_id;
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
 END tipo_produto_adicionar;
 --
 --
 PROCEDURE tipo_produto_atualizar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/07/2020
  -- DESCRICAO: Atualizacao de tipo_produto da tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/12/2020  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  -- Silvia            05/07/2021  Implementacao de job_tipo_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_tipo_produto_id IN tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_complemento            IN VARCHAR2,
  p_descricao              IN CLOB,
  p_vetor_atributo_id      IN VARCHAR2,
  p_vetor_atributo_valor   IN CLOB,
  p_tipo_alteracao         IN VARCHAR2,
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
  v_nome_produto           tipo_produto.nome%TYPE;
  v_tipo_produto_id        job_tipo_produto.tipo_produto_id%TYPE;
  v_tarefa_tipo_produto_id tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE;
  v_job_tipo_produto_id    tarefa_tipo_produto.job_tipo_produto_id%TYPE;
  v_nome_atributo          metadado.nome%TYPE;
  v_tamanho                metadado.tamanho%TYPE;
  v_flag_obrigatorio       metadado.flag_obrigatorio%TYPE;
  v_tipo_dado              tipo_dado.codigo%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_vetor_atributo_id      LONG;
  v_vetor_atributo_valor   LONG;
  v_tarefa_id              tarefa.tarefa_id%TYPE;
  v_status_tarefa          tarefa.status%TYPE;
  v_data_inicio            tarefa.data_inicio%TYPE;
  v_repet_grupo            item_crono.repet_grupo%TYPE;
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_metadado_id            tarefa_tp_atrib_valor.metadado_id%TYPE;
  v_valor_atributo         LONG;
  v_valor_atributo_sai     LONG;
  v_delimitador            CHAR(1);
  v_flag_admin             usuario.flag_admin%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> v_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT jo.job_id,
         ta.tarefa_id,
         ta.status,
         ta.data_inicio,
         jt.job_tipo_produto_id
    INTO v_job_id,
         v_tarefa_id,
         v_status_tarefa,
         v_data_inicio,
         v_job_tipo_produto_id
    FROM tarefa_tipo_produto tt,
         job_tipo_produto    jt,
         tarefa              ta,
         job                 jo
   WHERE tt.tarefa_tipo_produto_id = p_tarefa_tipo_produto_id
     AND tt.tarefa_id = ta.tarefa_id
     AND ta.job_id = jo.job_id
     AND tt.job_tipo_produto_id = jt.job_tipo_produto_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(status),
         MAX(numero)
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = v_job_id;
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = v_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT tp.nome,
         jt.tipo_produto_id
    INTO v_nome_produto,
         v_tipo_produto_id
    FROM tarefa_tipo_produto tt,
         job_tipo_produto    jt,
         tipo_produto        tp
   WHERE tt.tarefa_tipo_produto_id = p_tarefa_tipo_produto_id
     AND tt.job_tipo_produto_id = jt.job_tipo_produto_id
     AND jt.tipo_produto_id = tp.tipo_produto_id;
  --
  IF length(TRIM(p_complemento)) > 100
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O complemento do entregável não pode ter mais que 100 caracteres.';
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
  SELECT COUNT(*)
    INTO v_qt
    FROM job_tipo_produto
   WHERE job_id = v_job_id
     AND tipo_produto_id = v_tipo_produto_id
     AND nvl(upper(TRIM(complemento)), 'ZZZZZ') = nvl(upper(TRIM(p_complemento)), 'ZZZZZ')
     AND job_tipo_produto_id <> v_job_tipo_produto_id;
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
  UPDATE tarefa_tipo_produto
     SET descricao = TRIM(p_descricao)
   WHERE tarefa_tipo_produto_id = p_tarefa_tipo_produto_id;
  --
  UPDATE job_tipo_produto
     SET complemento = TRIM(p_complemento)
   WHERE job_tipo_produto_id = v_job_tipo_produto_id;
  --
  ------------------------------------------------------------
  -- tratamento dos vetores
  ------------------------------------------------------------
  DELETE FROM tarefa_tp_atrib_valor
   WHERE tarefa_tipo_produto_id = p_tarefa_tipo_produto_id;
  -- 
  v_delimitador          := '^';
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
      AND grupo = 'ITEM_OS';
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Metadado do entregável inválido (' || to_char(v_metadado_id) || ').';
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
   INSERT INTO tarefa_tp_atrib_valor
    (tarefa_tipo_produto_id,
     metadado_id,
     valor_atributo)
   VALUES
    (p_tarefa_tipo_produto_id,
     v_metadado_id,
     TRIM(v_valor_atributo_sai));
  END LOOP;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     -- procura o registro do item antes da alteracao
     SELECT MAX(tarefa_tipo_produto_id)
       INTO v_tarefa_tipo_produto_id
       FROM tarefa_tipo_produto
      WHERE tarefa_id = r_ta.tarefa_id
        AND job_tipo_produto_id = v_job_tipo_produto_id;
     --
     IF v_tarefa_tipo_produto_id IS NOT NULL
     THEN
      -- atualiza o item com os novos atributos
      UPDATE tarefa_tipo_produto
         SET descricao = TRIM(p_descricao)
       WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id;
     ELSE
      --
      SELECT seq_tarefa_tipo_produto.nextval
        INTO v_tarefa_tipo_produto_id
        FROM dual;
      --
      INSERT INTO tarefa_tipo_produto
       (tarefa_tipo_produto_id,
        tarefa_id,
        job_tipo_produto_id,
        descricao,
        data_entrada)
      VALUES
       (v_tarefa_tipo_produto_id,
        r_ta.tarefa_id,
        v_job_tipo_produto_id,
        TRIM(p_descricao),
        SYSDATE);
     END IF;
     --
     -- copia os metadados do item original
     DELETE FROM tarefa_tp_atrib_valor
      WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id;
     --
     INSERT INTO tarefa_tp_atrib_valor
      (tarefa_tipo_produto_id,
       metadado_id,
       valor_atributo)
      SELECT v_tarefa_tipo_produto_id,
             metadado_id,
             valor_atributo
        FROM tarefa_tp_atrib_valor
       WHERE tarefa_tipo_produto_id = p_tarefa_tipo_produto_id;
    END IF; -- fim do IF (p_tipo_alteracao
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Alteração de item: ' || TRIM(v_nome_produto || ' ' || p_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
 END tipo_produto_atualizar;
 --
 --
 PROCEDURE tipo_produto_excluir
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia                   ProcessMind     DATA: 29/07/2020
  -- DESCRICAO: Exclusao de tipo_produto da tarefa
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            03/12/2020  Novo parametro tipo_alteracao para repeticoes
  --                               (COR - corrente, SEG - seguintes, TOD - todas)
  -- Silvia            05/07/2021  Implementacao de job_tipo_produto
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id      IN NUMBER,
  p_empresa_id             IN empresa.empresa_id%TYPE,
  p_tarefa_tipo_produto_id IN tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE,
  p_tipo_alteracao         IN VARCHAR2,
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
  v_nome_produto           tipo_produto.nome%TYPE;
  v_tarefa_id              tarefa.tarefa_id%TYPE;
  v_status_tarefa          tarefa.status%TYPE;
  v_flag_obriga_item       tarefa.flag_obriga_item%TYPE;
  v_data_inicio            tarefa.data_inicio%TYPE;
  v_repet_grupo            item_crono.repet_grupo%TYPE;
  v_item_crono_id          item_crono.item_crono_id%TYPE;
  v_complemento            job_tipo_produto.complemento%TYPE;
  v_tipo_produto_id        job_tipo_produto.tipo_produto_id%TYPE;
  v_tarefa_tipo_produto_id tarefa_tipo_produto.tarefa_tipo_produto_id%TYPE;
  v_job_tipo_produto_id    tarefa_tipo_produto.job_tipo_produto_id%TYPE;
  v_lbl_job                VARCHAR2(100);
  v_flag_admin             usuario.flag_admin%TYPE;
  --
  -- seleciona repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id <> v_tarefa_id
      AND ic.objeto_id = ta.tarefa_id
      AND ta.status NOT IN ('CONC', 'CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_qt      := 0;
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_alteracao) IS NULL OR p_tipo_alteracao NOT IN ('COR', 'SEG', 'TOD')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de alteração inválida (' || p_tipo_alteracao || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa_tipo_produto
   WHERE tarefa_tipo_produto_id = nvl(p_tarefa_tipo_produto_id, 0);
  --
  IF v_qt = 0
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse entregável não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT jo.job_id,
         ta.tarefa_id,
         ta.status,
         ta.data_inicio,
         ta.flag_obriga_item
    INTO v_job_id,
         v_tarefa_id,
         v_status_tarefa,
         v_data_inicio,
         v_flag_obriga_item
    FROM tarefa_tipo_produto tt,
         tarefa              ta,
         job                 jo
   WHERE tt.tarefa_tipo_produto_id = p_tarefa_tipo_produto_id
     AND tt.tarefa_id = ta.tarefa_id
     AND ta.job_id = jo.job_id(+);
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tarefa ta
   WHERE tarefa_id = v_tarefa_id
     AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
          (SELECT 1
             FROM tarefa_usuario tu
            WHERE tu.usuario_para_id = p_usuario_sessao_id
              AND ta.tarefa_id = tu.tarefa_id));
  --
  IF v_qt = 0 AND v_flag_admin = 'N'
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas os usuários solicitante ou endereçados podem atualizar a task.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(status),
         MAX(numero)
    INTO v_status_job,
         v_numero_job
    FROM job
   WHERE job_id = nvl(v_job_id, 0);
  --
  IF v_status_job IN ('CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status do ' || v_lbl_job || ' não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  IF v_status_tarefa IN ('CONC', 'CANC')
  THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O status da task não permite essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT tp.nome,
         jt.complemento,
         jt.tipo_produto_id,
         jt.job_tipo_produto_id
    INTO v_nome_produto,
         v_complemento,
         v_tipo_produto_id,
         v_job_tipo_produto_id
    FROM tarefa_tipo_produto tt,
         tipo_produto        tp,
         job_tipo_produto    jt
   WHERE tt.tarefa_tipo_produto_id = p_tarefa_tipo_produto_id
     AND tt.job_tipo_produto_id = jt.job_tipo_produto_id
     AND jt.tipo_produto_id = tp.tipo_produto_id;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = v_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM tarefa_tp_atrib_valor
   WHERE tarefa_tipo_produto_id = p_tarefa_tipo_produto_id;
  --
  DELETE FROM tarefa_tipo_produto
   WHERE tarefa_tipo_produto_id = p_tarefa_tipo_produto_id;
  --
  IF v_flag_obriga_item = 'S'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE tarefa_id = v_tarefa_id;
   --
   IF v_qt = 0
   THEN
    p_erro_cod := '90000';
    p_erro_msg := 'A Task deve ter ao menos 1 Entregável.';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao das repeticoes
  ------------------------------------------------------------
  IF p_tipo_alteracao IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    IF (p_tipo_alteracao = 'SEG' AND r_ta.data_inicio > v_data_inicio) OR p_tipo_alteracao = 'TOD'
    THEN
     --
     -- procura o registro do item 
     SELECT MAX(tarefa_tipo_produto_id)
       INTO v_tarefa_tipo_produto_id
       FROM tarefa_tipo_produto
      WHERE tarefa_id = r_ta.tarefa_id
        AND job_tipo_produto_id = v_job_tipo_produto_id;
     --
     IF v_tarefa_tipo_produto_id IS NOT NULL
     THEN
      DELETE FROM tarefa_tp_atrib_valor
       WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id;
      --
      DELETE FROM tarefa_tipo_produto
       WHERE tarefa_tipo_produto_id = v_tarefa_tipo_produto_id;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  ------------------------------------------------------------
  -- verifica se precisa eliminar job_tipo_produto
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tipo_produto
   WHERE job_tipo_produto_id = v_job_tipo_produto_id;
  --
  IF v_qt = 0
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa_tipo_produto
    WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   --
   IF v_qt = 0
   THEN
    DELETE FROM job_tipo_produto
     WHERE job_tipo_produto_id = v_job_tipo_produto_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := tarefa_pkg.numero_formatar(v_tarefa_id);
  v_compl_histor   := 'Exclusão de item: ' || TRIM(v_nome_produto || ' ' || v_complemento);
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'TAREFA',
                   'ALTERAR',
                   v_identif_objeto,
                   v_tarefa_id,
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
 END tipo_produto_excluir;
 --
 --
 FUNCTION numero_formatar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 02/04/2020
  -- DESCRICAO: retorna o numero formatado de uma determinada TAREFA, COM o numero do job,
  -- quando se aplicar.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- 
  ------------------------------------------------------------------------------------------
  p_tarefa_id IN tarefa.tarefa_id%TYPE
 ) RETURN VARCHAR2 AS
  v_retorno    VARCHAR2(100);
  v_qt         INTEGER;
  v_num_job    job.numero%TYPE;
  v_num_tarefa tarefa.numero%TYPE;
  v_empresa_id empresa.empresa_id%TYPE;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(jo.numero),
         MAX(ta.numero)
    INTO v_num_job,
         v_num_tarefa
    FROM tarefa ta,
         job    jo
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id;
  --
  IF v_num_job IS NOT NULL
  THEN
   IF length(v_num_tarefa) <= 4
   THEN
    v_retorno := to_char(v_num_job) || '-' || TRIM(to_char(v_num_tarefa, '0000'));
   ELSE
    v_retorno := to_char(v_num_job) || '-' || to_char(v_num_tarefa);
   END IF;
  ELSE
   IF length(v_num_tarefa) <= 4
   THEN
    v_retorno := TRIM(to_char(v_num_tarefa, '0000'));
   ELSE
    v_retorno := to_char(v_num_tarefa);
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
 FUNCTION enderecados_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2013
  -- DESCRICAO: retorna os apelidos dos usuarios ativos e enderecados na tarefa
  --  (o retorno e' feito em forma de vetor, separado por virgulas).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_tarefa_id IN tarefa.tarefa_id%TYPE
 ) RETURN VARCHAR2 AS
  v_usuarios VARCHAR2(2000);
  v_qt       INTEGER;
  --
  CURSOR c_usu IS
   SELECT pe.apelido
     FROM usuario        us,
          pessoa         pe,
          tarefa_usuario ta
    WHERE ta.tarefa_id = p_tarefa_id
      AND ta.usuario_para_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
    ORDER BY upper(pe.apelido);
  --
 BEGIN
  v_usuarios := NULL;
  --
  FOR r_usu IN c_usu
  LOOP
   v_usuarios := v_usuarios || ', ' || r_usu.apelido;
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
 FUNCTION priv_no_grupo_verificar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 22/12/2020
  -- DESCRICAO: verifica se o usuario esta enderecado em todas as tarefas indicadas
  -- (COR - corrente, 
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN NUMBER,
  p_tarefa_id         IN tarefa.tarefa_id%TYPE,
  p_tipo_verif        IN VARCHAR2
 ) RETURN INTEGER AS
  v_ret           INTEGER;
  v_qt            INTEGER;
  v_flag_admin    usuario.flag_admin%TYPE;
  v_repet_grupo   item_crono.repet_grupo%TYPE;
  v_item_crono_id item_crono.item_crono_id%TYPE;
  v_job_id        tarefa.job_id%TYPE;
  v_data_inicio   tarefa.data_inicio%TYPE;
  v_saida         EXCEPTION;
  --
  -- seleciona tarefas do grupo de repeticoes 
  CURSOR c_ta IS
   SELECT ta.tarefa_id,
          ta.data_inicio,
          ic.item_crono_id
     FROM item_crono ic,
          cronograma cr,
          tarefa     ta
    WHERE ic.cronograma_id = cr.cronograma_id
      AND cr.status <> 'ARQUI'
      AND ic.repet_grupo = v_repet_grupo
      AND ic.cod_objeto = 'TAREFA'
      AND cr.job_id = v_job_id
      AND ic.objeto_id IS NOT NULL
      AND ic.objeto_id = ta.tarefa_id
   --AND ta.status NOT IN ('CONC','CANC')
    ORDER BY ta.data_inicio;
  --
 BEGIN
  v_ret := 0;
  --
  IF TRIM(p_tipo_verif) IS NULL OR p_tipo_verif NOT IN ('COR', 'SEG', 'TOD')
  THEN
   RAISE v_saida;
  END IF;
  --
  SELECT flag_admin
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_flag_admin = 'S'
  THEN
   v_ret := 1;
   RAISE v_saida;
  END IF;
  --
  SELECT MAX(job_id),
         MAX(data_inicio)
    INTO v_job_id,
         v_data_inicio
    FROM tarefa
   WHERE tarefa_id = p_tarefa_id;
  --
  SELECT MAX(item_crono_id)
    INTO v_item_crono_id
    FROM item_crono
   WHERE cod_objeto = 'TAREFA'
     AND objeto_id = p_tarefa_id;
  --
  IF v_item_crono_id IS NOT NULL
  THEN
   SELECT repet_grupo
     INTO v_repet_grupo
     FROM item_crono
    WHERE item_crono_id = v_item_crono_id;
  END IF;
  --
  IF p_tipo_verif = 'COR'
  THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM tarefa ta
    WHERE tarefa_id = p_tarefa_id
      AND (usuario_de_id = p_usuario_sessao_id OR EXISTS
           (SELECT 1
              FROM tarefa_usuario tu
             WHERE tu.usuario_para_id = p_usuario_sessao_id
               AND ta.tarefa_id = tu.tarefa_id));
   IF v_qt > 0
   THEN
    v_ret := 1;
    RAISE v_saida;
   END IF;
  END IF;
  --
  IF p_tipo_verif IN ('SEG', 'TOD') AND v_repet_grupo IS NOT NULL
  THEN
   FOR r_ta IN c_ta
   LOOP
    v_ret := 1;
    IF (p_tipo_verif = 'SEG' AND r_ta.data_inicio >= v_data_inicio) OR p_tipo_verif = 'TOD'
    THEN
     v_ret := tarefa_pkg.priv_no_grupo_verificar(p_usuario_sessao_id, r_ta.tarefa_id, 'COR');
     IF v_ret = 0
     THEN
      RAISE v_saida;
     END IF;
    END IF;
   END LOOP;
  END IF;
  --
  RETURN v_ret;
 EXCEPTION
  WHEN v_saida THEN
   RETURN v_ret;
  WHEN OTHERS THEN
   v_ret := 0;
   RETURN v_ret;
 END priv_no_grupo_verificar;
 --
 --
 FUNCTION ultimo_evento_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 10/06/2013
  -- DESCRICAO: retorna o ultimo tarefa_evento_id relacionado a uma determinada tarefa.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_tarefa_id IN tarefa.tarefa_id%TYPE
 ) RETURN NUMBER AS
  v_retorno tarefa_evento.tarefa_evento_id%TYPE;
  v_qt      INTEGER;
  --
 BEGIN
  v_retorno := NULL;
  --
  SELECT MAX(tarefa_evento_id)
    INTO v_retorno
    FROM tarefa_evento
   WHERE tarefa_id = p_tarefa_id;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 0;
   RETURN v_retorno;
 END ultimo_evento_retornar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 19/09/2017
  -- DESCRICAO: Subrotina que gera o xml de TAREFA para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/07/2020  Novos atributos de datas, estmativa, etc
  ------------------------------------------------------------------------------------------
 (
  p_tarefa_id       IN tarefa.tarefa_id%TYPE,
  p_flag_com_evento IN VARCHAR2,
  p_xml             OUT CLOB,
  p_erro_cod        OUT VARCHAR2,
  p_erro_msg        OUT VARCHAR2
 ) IS
  v_qt        INTEGER;
  v_exception EXCEPTION;
  v_xml       xmltype;
  v_xml_aux1  xmltype;
  v_xml_aux99 xmltype;
  v_xml_doc   VARCHAR2(100);
  --
  CURSOR c_ar IS
   SELECT af.arquivo_id,
          ar.nome_fisico,
          ar.nome_original,
          vo.caminho || '\' || vo.prefixo || '\' || to_char(vo.numero) volume,
          util_pkg.desc_retornar('tipo_arq_tarefa', af.tipo_arq_tarefa) tipo_arquivo
     FROM arquivo_tarefa af,
          arquivo        ar,
          volume         vo
    WHERE af.tarefa_id = p_tarefa_id
      AND af.arquivo_id = ar.arquivo_id
      AND ar.volume_id = vo.volume_id
      AND af.flag_thumb = 'N'
    ORDER BY af.arquivo_id;
  --
  CURSOR c_lk IS
   SELECT tl.tipo_link,
          tl.url,
          tl.descricao
     FROM tarefa_link tl
    WHERE tl.tarefa_id = p_tarefa_id
    ORDER BY tl.tarefa_link_id;
  --
  CURSOR c_us IS
   SELECT pe.apelido,
          ta.horas_totais
     FROM usuario        us,
          pessoa         pe,
          tarefa_usuario ta
    WHERE ta.tarefa_id = p_tarefa_id
      AND ta.usuario_para_id = us.usuario_id
      AND us.usuario_id = pe.usuario_id
    ORDER BY upper(pe.apelido);
  --
  CURSOR c_ev IS
   SELECT ta.tarefa_evento_id,
          pe.apelido,
          data_hora_mostrar(ta.data_evento) AS data_evento,
          ta.cod_acao,
          ta.status_de,
          ta.status_para,
          ta.comentario,
          ta.motivo
     FROM tarefa_evento ta,
          pessoa        pe
    WHERE ta.tarefa_id = p_tarefa_id
      AND ta.usuario_id = pe.usuario_id
    ORDER BY ta.tarefa_evento_id;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("tarefa_id", ta.tarefa_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("numero_job", jo.numero),
                   xmlelement("criador", pe.apelido),
                   xmlelement("data_entrada", data_hora_mostrar(ta.data_entrada)),
                   xmlelement("data_inicio", data_hora_mostrar(ta.data_inicio)),
                   xmlelement("data_termino", data_hora_mostrar(ta.data_termino)),
                   xmlelement("data_envio", data_hora_mostrar(ta.data_envio)),
                   xmlelement("data_execucao", data_hora_mostrar(ta.data_execucao)),
                   xmlelement("descricao", ta.descricao),
                   xmlelement("volta_apos_exec", ta.flag_volta_exec),
                   xmlelement("status", util_pkg.desc_retornar('status_tarefa', ta.status)),
                   xmlelement("data_status", data_hora_mostrar(ta.data_status)))
    INTO v_xml
    FROM tarefa ta,
         job    jo,
         pessoa pe
   WHERE ta.tarefa_id = p_tarefa_id
     AND ta.job_id = jo.job_id(+)
     AND ta.usuario_de_id = pe.usuario_id;
  --
  ------------------------------------------------------------
  -- monta ENDERECADOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_us IN c_us
  LOOP
   SELECT xmlagg(xmlelement("usuario",
                            xmlelement("apelido", r_us.apelido),
                            xmlelement("horas_totais", numero_mostrar(r_us.horas_totais, 1, 'N'))))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("enderecados", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta ARQUIVOS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_ar IN c_ar
  LOOP
   SELECT xmlagg(xmlelement("arquivo",
                            xmlelement("arquivo_id", r_ar.arquivo_id),
                            xmlelement("tipo_arquivo", r_ar.tipo_arquivo),
                            xmlelement("nome_original", r_ar.nome_original),
                            xmlelement("nome_fisico", r_ar.nome_fisico),
                            xmlelement("volume", r_ar.volume)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("arquivos", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta LINKS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_lk IN c_lk
  LOOP
   SELECT xmlagg(xmlelement("link",
                            xmlelement("tipo_link", r_lk.tipo_link),
                            xmlelement("url", r_lk.url),
                            xmlelement("descricao", r_lk.descricao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("links", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta EVENTOS
  ------------------------------------------------------------
  IF p_flag_com_evento = 'S'
  THEN
   v_xml_aux1 := NULL;
   FOR r_ev IN c_ev
   LOOP
    SELECT xmlagg(xmlelement("evento",
                             xmlelement("usuario", r_ev.apelido),
                             xmlelement("data", r_ev.data_evento),
                             xmlelement("acao", r_ev.cod_acao),
                             xmlelement("status_de", r_ev.status_de),
                             xmlelement("status_para", r_ev.status_para),
                             xmlelement("comentario", r_ev.comentario),
                             xmlelement("motivo", r_ev.motivo)))
      INTO v_xml_aux99
      FROM dual;
    --
    SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
      INTO v_xml_aux1
      FROM dual;
   END LOOP;
   --
   SELECT xmlagg(xmlelement("eventos", v_xml_aux1))
     INTO v_xml_aux1
     FROM dual;
   --
   SELECT xmlconcat(v_xml, v_xml_aux1)
     INTO v_xml
     FROM dual;
  END IF;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "tarefa"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("tarefa", v_xml))
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
END; -- TAREFA_PKG

/
