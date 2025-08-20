--------------------------------------------------------
--  DDL for Package Body PAPEL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PAPEL_PKG" IS
 --
 PROCEDURE vetores_processar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/10/2016
  -- DESCRICAO: subrotina que trata das consistencias e atualizacoes referentes aos
  --  vetores com privilegios, inbox, etc. NAO FAZ COMMIT.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            27/02/2019  Novos vetores para Oportunidade
  -- Silvia            03/03/2020  Eliminacao de painel (dashboard)
  -- Silvia            28/04/2020  Eliminacao de inbox
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  -- Silvia            26/08/2021  Novo vetor para paineis associados ao papel
  -- Ana Luiza         24/10/2023  Criado novos grupos de enderecamento por area
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id            IN usuario.usuario_id%TYPE,
  p_empresa_id                   IN empresa.empresa_id%TYPE,
  p_papel_id                     IN papel.papel_id%TYPE,
  p_delimitador                  IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_somen IN VARCHAR2,
  p_flag_tipo_pessoa_v_todos     IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_somen IN VARCHAR2,
  p_flag_tipo_pessoa_c_todos     IN VARCHAR2,
  p_vetor_configurar_priv_id     IN VARCHAR2,
  p_vetor_oportun_priv_id        IN VARCHAR2,
  p_vetor_oportunend_priv_id     IN VARCHAR2,
  p_vetor_oportunend_abrang      IN VARCHAR2,
  p_vetor_contrato_priv_id       IN VARCHAR2,
  p_vetor_contratoend_priv_id    IN VARCHAR2,
  p_vetor_contratoend_abrang     IN VARCHAR2,
  p_vetor_job_priv_id            IN VARCHAR2,
  p_vetor_jobend_priv_id         IN VARCHAR2,
  p_vetor_jobend_abrang          IN VARCHAR2,
  p_vetor_orcend_priv_id         IN VARCHAR2,
  p_vetor_orcend_abrang          IN VARCHAR2,
  p_vetor_tipo_job_id            IN VARCHAR2,
  p_vetor_tipo_financeiro_id     IN VARCHAR2,
  p_vetor_enderecar_area_id      IN VARCHAR2,
  p_vetor_enderecar_abrang       IN VARCHAR2,
  p_vetor_entrega_priv_id        IN VARCHAR2,
  p_vetor_entrega_tipo_os_id     IN VARCHAR2,
  p_vetor_entrega_abrang         IN VARCHAR2,
  p_vetor_monitorar_priv_id      IN VARCHAR2,
  p_vetor_analisar_priv_id       IN VARCHAR2,
  p_vetor_docum_priv_id          IN VARCHAR2,
  p_vetor_docum_tipo_doc_id      IN VARCHAR2,
  p_vetor_docum_abrang           IN VARCHAR2,
  p_vetor_apontam_priv_id        IN VARCHAR2,
  p_vetor_navegacao_priv_id      IN VARCHAR2,
  p_vetor_painel_id              IN VARCHAR2,
  p_painel_pdr_id                IN VARCHAR2,
  p_vetor_oportunender_area_id   IN VARCHAR2, --ALCBO_241023
  p_vetor_oportunender_abrang    IN VARCHAR2,
  p_vetor_contratoender_area_id  IN VARCHAR2,
  p_vetor_contratoender_abrang   IN VARCHAR2,
  p_erro_cod                     OUT VARCHAR2,
  p_erro_msg                     OUT VARCHAR2
 ) AS
  v_qt                   INTEGER;
  v_delimitador          CHAR(1);
  v_vetor_privilegio_id  VARCHAR2(8000);
  v_vetor_abrangencia    VARCHAR2(8000);
  v_vetor_tipo_pessoa_id VARCHAR2(8000);
  v_vetor_tipo_doc_id    VARCHAR2(8000);
  v_vetor_tipo_os_id     VARCHAR2(8000);
  v_vetor_area_id        VARCHAR2(8000);
  v_vetor_tipo_job_id    VARCHAR2(8000);
  v_vetor_tipo_finan_id  VARCHAR2(8000);
  v_vetor_painel_id      VARCHAR2(8000);
  v_painel_id            painel.painel_id%TYPE;
  v_painel_pdr_id        painel.painel_id%TYPE;
  v_nome_painel          painel.nome%TYPE;
  v_abrangencia          VARCHAR2(100);
  v_cod_priv             privilegio.codigo%TYPE;
  v_grupo_priv           privilegio.grupo%TYPE;
  v_privilegio_id        privilegio.privilegio_id%TYPE;
  v_nome_priv            privilegio.nome%TYPE;
  v_tipo_pessoa_id       tipo_pessoa.tipo_pessoa_id%TYPE;
  v_tipo_documento_id    tipo_documento.tipo_documento_id%TYPE;
  v_tipo_os_id           tipo_os.tipo_os_id%TYPE;
  v_area_id              area.area_id%TYPE;
  v_tipo_job_id          tipo_job.tipo_job_id%TYPE;
  v_tipo_financeiro_id   tipo_financeiro.tipo_financeiro_id%TYPE;
  v_exception            EXCEPTION;
  v_lbl_job              VARCHAR2(100);
  --
 BEGIN
  v_lbl_job := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_SINGULAR');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- limpeza das tabelas
  ------------------------------------------------------------
  DELETE FROM papel_priv_tpessoa
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_area
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tdoc
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tos
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tjob
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tfin
   WHERE papel_id = p_papel_id;
  --
  DELETE FROM papel_priv
   WHERE papel_id = p_papel_id;
  --
  v_delimitador := p_delimitador;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONFIGURAR - Ver Pessoas
  ------------------------------------------------------------
  SELECT privilegio_id
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'PESSOA_V';
  --
  IF p_flag_tipo_pessoa_v_todos = 'S' AND (TRIM(p_vetor_tipo_pessoa_id_v_geral) IS NOT NULL OR
     TRIM(p_vetor_tipo_pessoa_id_v_somen) IS NOT NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O privilégio para Ver TODOS os tipos de pessoa não deve ser ' ||
                 'informado quando um ou mais tipos específicos são selecionados.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tipo_pessoa_v_todos = 'S' THEN
   v_abrangencia := 'T';
  ELSE
   v_abrangencia := 'P';
  END IF;
  --
  INSERT INTO papel_priv
   (papel_id,
    privilegio_id,
    abrangencia)
  VALUES
   (p_papel_id,
    v_privilegio_id,
    v_abrangencia);
  --
  -- trata vetor de tipos de pessoa SEM restricoes
  v_vetor_tipo_pessoa_id := p_vetor_tipo_pessoa_id_v_geral;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa_id)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa_id, v_delimitador));
   --
   INSERT INTO papel_priv_tpessoa
    (papel_id,
     privilegio_id,
     tipo_pessoa_id,
     abrangencia)
   VALUES
    (p_papel_id,
     v_privilegio_id,
     v_tipo_pessoa_id,
     'T');
  END LOOP;
  --
  -- trata vetor de tipos de pessoa COM restricoes
  v_vetor_tipo_pessoa_id := p_vetor_tipo_pessoa_id_v_somen;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa_id)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tpessoa
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O privilégio para Ver pessoas Somente do tipo ' ||
                  'não deve ser informado quando o mesmo tipo já está selecionado.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO papel_priv_tpessoa
    (papel_id,
     privilegio_id,
     tipo_pessoa_id,
     abrangencia)
   VALUES
    (p_papel_id,
     v_privilegio_id,
     v_tipo_pessoa_id,
     'P');
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONFIGURAR - Configurar Pessoas
  ------------------------------------------------------------
  SELECT privilegio_id
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'PESSOA_C';
  --
  IF p_flag_tipo_pessoa_c_todos = 'S' AND (TRIM(p_vetor_tipo_pessoa_id_c_geral) IS NOT NULL OR
     TRIM(p_vetor_tipo_pessoa_id_c_somen) IS NOT NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O privilégio para Configurar TODOS os tipos de pessoa não deve ser ' ||
                 'informado quando um ou mais tipos específicos são selecionados.';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_tipo_pessoa_c_todos = 'S' THEN
   v_abrangencia := 'T';
  ELSE
   v_abrangencia := 'P';
  END IF;
  --
  INSERT INTO papel_priv
   (papel_id,
    privilegio_id,
    abrangencia)
  VALUES
   (p_papel_id,
    v_privilegio_id,
    v_abrangencia);
  --
  -- trata vetor de tipos de pessoa SEM restricoes
  v_vetor_tipo_pessoa_id := p_vetor_tipo_pessoa_id_c_geral;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa_id)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa_id, v_delimitador));
   --
   INSERT INTO papel_priv_tpessoa
    (papel_id,
     privilegio_id,
     tipo_pessoa_id,
     abrangencia)
   VALUES
    (p_papel_id,
     v_privilegio_id,
     v_tipo_pessoa_id,
     'T');
  END LOOP;
  --
  -- trata vetor de tipos de pessoa COM restricoes
  v_vetor_tipo_pessoa_id := p_vetor_tipo_pessoa_id_c_somen;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_pessoa_id)), 0) > 0
  LOOP
   v_tipo_pessoa_id := to_number(prox_valor_retornar(v_vetor_tipo_pessoa_id, v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tpessoa
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_pessoa_id = v_tipo_pessoa_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'O privilégio para Configurar pessoas Somente do tipo ' ||
                  'não deve ser informado quando o mesmo tipo já está selecionado.';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO papel_priv_tpessoa
    (papel_id,
     privilegio_id,
     tipo_pessoa_id,
     abrangencia)
   VALUES
    (p_papel_id,
     v_privilegio_id,
     v_tipo_pessoa_id,
     'P');
  END LOOP;
  --
  -- deleta eventuais registros de abrangencia parcial que ficaram sem tipo de pessoa
  DELETE FROM papel_priv pp
   WHERE pp.abrangencia = 'P'
     AND pp.papel_id = p_papel_id
     AND EXISTS (SELECT 1
            FROM privilegio pr
           WHERE pr.privilegio_id = pp.privilegio_id
             AND pr.codigo IN ('PESSOA_C', 'PESSOA_V'))
     AND NOT EXISTS (SELECT 1
            FROM papel_priv_tpessoa pt
           WHERE pt.papel_id = pp.papel_id
             AND pt.privilegio_id = pp.privilegio_id);
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONFIGURAR - demais
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_configurar_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - configurar demais (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba OPORTUNIDADE
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_oportun_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - oportunidade (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba OPORTUNIDADE END (OPORTUNEND)
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_oportunend_priv_id;
  v_vetor_abrangencia   := p_vetor_oportunend_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   v_abrangencia   := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor OPORTUNIDADE END (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - oportunidade end (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  --ALCBO_241023
  ------------------------------------------------------------
  -- tratamento de vetor: aba OPORTUNIDADE ENDER AREA (OPORTUNENDERAREA)
  ------------------------------------------------------------
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'OPORTUN_ENDER_AREA';
  --
  v_vetor_area_id     := p_vetor_oportunender_area_id;
  v_vetor_abrangencia := p_vetor_oportunender_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0
  LOOP
   v_area_id     := nvl(to_number(prox_valor_retornar(v_vetor_area_id, v_delimitador)), 0);
   v_abrangencia := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor ENDERECAR (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = v_area_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa área não existe ou não pertene a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_area
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND area_id = v_area_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_area
     (papel_id,
      privilegio_id,
      area_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_area_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONTRATO
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_contrato_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - contrato (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONTRATO END (CONTRATOEND)
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_contratoend_priv_id;
  v_vetor_abrangencia   := p_vetor_contratoend_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   v_abrangencia   := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor CONTRATO END (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - contrato end (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  --ALCBO_241023
  ------------------------------------------------------------
  -- tratamento de vetor: aba CONTRATO ENDER AREA (CONTRATOENDERAREA)
  ------------------------------------------------------------
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'CONTRATO_ENDER_AREA';
  --
  v_vetor_area_id     := p_vetor_contratoender_area_id;
  v_vetor_abrangencia := p_vetor_contratoender_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0
  LOOP
   v_area_id     := nvl(to_number(prox_valor_retornar(v_vetor_area_id, v_delimitador)), 0);
   v_abrangencia := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor ENDERECAR (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = v_area_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa área não existe ou não pertene a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_area
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND area_id = v_area_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_area
     (papel_id,
      privilegio_id,
      area_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_area_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba JOB
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_job_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - job (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba JOB END
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_jobend_priv_id;
  v_vetor_abrangencia   := p_vetor_jobend_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   v_abrangencia   := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor JOB END (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - job end (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba ORC END
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_orcend_priv_id;
  v_vetor_abrangencia   := p_vetor_orcend_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   v_abrangencia   := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P', 'O') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor ESTIMATIVA END (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - estim end (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba TIPO JOB (criar job do tipo)
  ------------------------------------------------------------
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'JOB_I';
  --
  v_vetor_tipo_job_id := p_vetor_tipo_job_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_job_id)), 0) > 0
  LOOP
   v_tipo_job_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_job_id, v_delimitador)), 0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_job
    WHERE tipo_job_id = v_tipo_job_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo de ' || v_lbl_job ||
                  ' não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tjob
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_job_id = v_tipo_job_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_tjob
     (papel_id,
      privilegio_id,
      tipo_job_id)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_tipo_job_id);
   END IF;
  END LOOP;
  --
  -- verifica se o privilegio de criar job ficou sem especificacao do tipo
  SELECT COUNT(*)
    INTO v_qt
    FROM papel_priv pp
   WHERE papel_id = p_papel_id
     AND privilegio_id = v_privilegio_id
     AND NOT EXISTS (SELECT 1
            FROM papel_priv_tjob pt
           WHERE pp.papel_id = pt.papel_id
             AND pp.privilegio_id = pt.privilegio_id);
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nenhum tipo de ' || v_lbl_job ||
                 ' foi especificado para o privilégio de Criar ' || v_lbl_job || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba TIPO FINAN (indicar tipo finan no job)
  ------------------------------------------------------------
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'JOB_TIPO_FIN_C';
  --
  v_vetor_tipo_finan_id := p_vetor_tipo_financeiro_id;
  --
  WHILE nvl(length(rtrim(v_vetor_tipo_finan_id)), 0) > 0
  LOOP
   v_tipo_financeiro_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_finan_id,
                                                             v_delimitador)),
                               0);
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM tipo_financeiro
    WHERE tipo_financeiro_id = v_tipo_financeiro_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse tipo financeiro não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tfin
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_financeiro_id = v_tipo_financeiro_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_tfin
     (papel_id,
      privilegio_id,
      tipo_financeiro_id)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_tipo_financeiro_id);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba JOB ENDERECAR (area)
  ------------------------------------------------------------
  SELECT MAX(privilegio_id)
    INTO v_privilegio_id
    FROM privilegio
   WHERE codigo = 'ENDER_C';
  --
  v_vetor_area_id     := p_vetor_enderecar_area_id;
  v_vetor_abrangencia := p_vetor_enderecar_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_area_id)), 0) > 0
  LOOP
   v_area_id     := nvl(to_number(prox_valor_retornar(v_vetor_area_id, v_delimitador)), 0);
   v_abrangencia := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor ENDERECAR (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM area
    WHERE area_id = v_area_id
      AND empresa_id = p_empresa_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa área não existe ou não pertene a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_area
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND area_id = v_area_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_area
     (papel_id,
      privilegio_id,
      area_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_area_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba OS
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_entrega_priv_id;
  v_vetor_tipo_os_id    := p_vetor_entrega_tipo_os_id;
  v_vetor_abrangencia   := p_vetor_entrega_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   v_tipo_os_id    := nvl(to_number(prox_valor_retornar(v_vetor_tipo_os_id, v_delimitador)), 0);
   v_abrangencia   := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor OS (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tos
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_os_id = v_tipo_os_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_tos
     (papel_id,
      privilegio_id,
      tipo_os_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_tipo_os_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba MONITORAR
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_monitorar_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - monitorar (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba ANALISAR
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_analisar_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - analisar (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba DASHBOARDS
  ------------------------------------------------------------
  DELETE FROM papel_painel
   WHERE papel_id = p_papel_id;
  --
  v_vetor_painel_id := p_vetor_painel_id;
  --
  WHILE nvl(length(rtrim(v_vetor_painel_id)), 0) > 0
  LOOP
   v_painel_id := nvl(to_number(prox_valor_retornar(v_vetor_painel_id, v_delimitador)), 0);
   --
   SELECT MAX(nome)
     INTO v_nome_painel
     FROM painel
    WHERE painel_id = v_painel_id
      AND empresa_id = p_empresa_id;
   --
   IF v_nome_painel IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse painel não existe ou não pertence a essa empresa (' ||
                  to_char(v_painel_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_painel
    WHERE papel_id = p_papel_id
      AND painel_id = v_painel_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem painéis duplicados no vetor (' || v_nome_painel || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_painel
     (papel_id,
      painel_id,
      flag_padrao)
    VALUES
     (p_papel_id,
      v_painel_id,
      'N');
   END IF;
  END LOOP;
  --
  IF inteiro_validar(TRIM(p_painel_pdr_id)) = 1 THEN
   v_painel_pdr_id := nvl(to_number(TRIM(p_painel_pdr_id)), 0);
   --
   IF v_painel_pdr_id > 0 THEN
    -- veio o painel padrao
    SELECT COUNT(*)
      INTO v_qt
      FROM papel_painel
     WHERE papel_id = p_papel_id
       AND painel_id = v_painel_pdr_id;
    --
    IF v_qt = 0 THEN
     p_erro_cod := '90000';
     p_erro_msg := 'O dashboard marcado como padrão também deve ser associado ao papel.';
     RAISE v_exception;
    END IF;
    --
    UPDATE papel_painel
       SET flag_padrao = 'S'
     WHERE papel_id = p_papel_id
       AND painel_id = v_painel_pdr_id;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba DOCUMENTO
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_docum_priv_id;
  v_vetor_tipo_doc_id   := p_vetor_docum_tipo_doc_id;
  v_vetor_abrangencia   := p_vetor_docum_abrang;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id     := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id,
                                                            v_delimitador)),
                              0);
   v_tipo_documento_id := nvl(to_number(prox_valor_retornar(v_vetor_tipo_doc_id, v_delimitador)),
                              0);
   v_abrangencia       := prox_valor_retornar(v_vetor_abrangencia, v_delimitador);
   --
   IF TRIM(v_abrangencia) IS NULL OR v_abrangencia NOT IN ('T', 'P') THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Abrangência inválida no vetor DOCUMENTO (' || v_abrangencia || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv_tdoc
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id
      AND tipo_documento_id = v_tipo_documento_id;
   --
   IF v_qt = 0 THEN
    INSERT INTO papel_priv_tdoc
     (papel_id,
      privilegio_id,
      tipo_documento_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      v_tipo_documento_id,
      v_abrangencia);
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba APONTAMENTO - privilegios
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_apontam_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - apontamento (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
   END IF;
  END LOOP;
  --
  ------------------------------------------------------------
  -- tratamento de vetor: aba NAVEGACAO
  ------------------------------------------------------------
  v_vetor_privilegio_id := p_vetor_navegacao_priv_id;
  --
  WHILE nvl(length(rtrim(v_vetor_privilegio_id)), 0) > 0
  LOOP
   v_privilegio_id := nvl(to_number(prox_valor_retornar(v_vetor_privilegio_id, v_delimitador)),
                          0);
   --
   SELECT MAX(codigo),
          MAX(grupo)
     INTO v_cod_priv,
          v_grupo_priv
     FROM privilegio
    WHERE privilegio_id = v_privilegio_id;
   --
   IF v_cod_priv IS NULL THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse privilégio não existe (' || to_char(v_privilegio_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM papel_priv
    WHERE papel_id = p_papel_id
      AND privilegio_id = v_privilegio_id;
   --
   IF v_qt > 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Existem privilégios duplicados - navegacao (' || v_nome_priv || ').';
    RAISE v_exception;
   ELSE
    INSERT INTO papel_priv
     (papel_id,
      privilegio_id,
      abrangencia)
    VALUES
     (p_papel_id,
      v_privilegio_id,
      'P');
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
   p_erro_msg := substr(SQLERRM || ' Linha Erro: ' || dbms_utility.format_error_backtrace,
                        1,
                        200);
   ROLLBACK;
 END vetores_processar;
 --
 --
 PROCEDURE adicionar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: adiciona um novo registro em PAPEL, apos consistencia
  --  dos dados de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2007  Inclusao de parametros: flags de apontamento
  -- Silvia            11/04/2008  Novo parametro p/ vetor de tipo de documento
  -- Silvia            04/02/2011  Novos parametros area_id e vetor_painel.
  -- Silvia            28/10/2011  Novo parametro flag_auto_ender.
  -- Silvia            24/07/2012  Novo parametro vetor_tos (tipo de OS).
  -- Silvia            26/02/2013  Novo parametro tela_inicial.
  -- Silvia            06/03/2013  Novo parametro vetor_tos_painel (tipo de OS p/ painel)
  -- Silvia            20/05/2013  Retirada do parametro flag_apontam_cron
  -- Silvia            10/03/2015  Novos parametros (inbox_id, vetores $ hora)
  -- Silvia            05/05/2015  Novo parametro vetor_area
  -- Silvia            21/12/2015  Novo parametro vetor_tjob (tipo de job)
  -- Silvia            27/05/2016  Encriptacao de valores
  -- Silvia            01/06/2016  Novo parametro vetor_tfin (tipo financeiro)
  -- Silvia            21/10/2016  Reestruturacao dos vetores / abrangencia
  -- Silvia            17/05/2017  Novo paramento flag_notif_ender
  -- Silvia            17/08/2017  Novo parametro flag_restringe_ender
  -- Silvia            27/02/2019  Novos vetores para Oportunidade e flag_auto_ender_oport
  -- Silvia            07/08/2019  Novo flag_auto_ender_ctr
  -- Silvia            03/03/2020  Eliminacao de painel (dashboard)
  -- Silvia            24/04/2020  Retirada do parametro flag_restringe_ender
  -- Silvia            28/04/2020  Eliminacao de inbox
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  -- Ana Luiza         24/10/2023  Criado novos grupos para ser endereçado por papel
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id            IN usuario.usuario_id%TYPE,
  p_empresa_id                   IN empresa.empresa_id%TYPE,
  p_area_id                      IN papel.area_id%TYPE,
  p_nome                         IN papel.nome%TYPE,
  p_flag_ender                   IN papel.flag_ender%TYPE,
  p_flag_auto_ender              IN papel.flag_auto_ender%TYPE,
  p_flag_auto_ender_ctr          IN papel.flag_auto_ender_ctr%TYPE,
  p_flag_auto_ender_oport        IN papel.flag_auto_ender_oport%TYPE,
  p_flag_notif_ender             IN papel.flag_notif_ender%TYPE,
  p_flag_apontam_form            IN papel.flag_apontam_form%TYPE,
  p_ordem                        IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_somen IN VARCHAR2,
  p_flag_tipo_pessoa_v_todos     IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_somen IN VARCHAR2,
  p_flag_tipo_pessoa_c_todos     IN VARCHAR2,
  p_vetor_configurar_priv_id     IN VARCHAR2,
  p_vetor_oportun_priv_id        IN VARCHAR2,
  p_vetor_oportunend_priv_id     IN VARCHAR2,
  p_vetor_oportunend_abrang      IN VARCHAR2,
  p_vetor_contrato_priv_id       IN VARCHAR2,
  p_vetor_contratoend_priv_id    IN VARCHAR2,
  p_vetor_contratoend_abrang     IN VARCHAR2,
  p_vetor_job_priv_id            IN VARCHAR2,
  p_vetor_jobend_priv_id         IN VARCHAR2,
  p_vetor_jobend_abrang          IN VARCHAR2,
  p_vetor_orcend_priv_id         IN VARCHAR2,
  p_vetor_orcend_abrang          IN VARCHAR2,
  p_vetor_tipo_job_id            IN VARCHAR2,
  p_vetor_tipo_financeiro_id     IN VARCHAR2,
  p_vetor_enderecar_area_id      IN VARCHAR2,
  p_vetor_enderecar_abrang       IN VARCHAR2,
  p_vetor_entrega_priv_id        IN VARCHAR2,
  p_vetor_entrega_tipo_os_id     IN VARCHAR2,
  p_vetor_entrega_abrang         IN VARCHAR2,
  p_vetor_monitorar_priv_id      IN VARCHAR2,
  p_vetor_analisar_priv_id       IN VARCHAR2,
  p_vetor_docum_priv_id          IN VARCHAR2,
  p_vetor_docum_tipo_doc_id      IN VARCHAR2,
  p_vetor_docum_abrang           IN VARCHAR2,
  p_vetor_apontam_priv_id        IN VARCHAR2,
  p_vetor_navegacao_priv_id      IN VARCHAR2,
  p_vetor_painel_id              IN VARCHAR2,
  p_painel_pdr_id                IN VARCHAR2,
  p_vetor_oportunender_area_id   IN VARCHAR2, --ALCBO_241023
  p_vetor_oportunender_abrang    IN VARCHAR2,
  p_vetor_contratoender_area_id  IN VARCHAR2,
  p_vetor_contratoender_abrang   IN VARCHAR2,
  p_erro_cod                     OUT VARCHAR2,
  p_erro_msg                     OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_papel_id       papel.papel_id%TYPE;
  v_delimitador    CHAR(1);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAPEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_area_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
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
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do papel não pode ter mais que 100 caracteres (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de endereçamento inválido (' || p_flag_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em job inválido (' || p_flag_auto_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender_ctr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em contrato inválido (' || p_flag_auto_ender_ctr || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender_oport) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em oportunidade inválido (' ||
                 p_flag_auto_ender_oport || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_auto_ender = 'S' AND p_flag_ender = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas papéis endereçáveis podem ser marcados para endereçamento automático.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notif_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de notificar endereçamento inválido (' || p_flag_notif_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_apontam_form) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de apontamento via formulário inválido (' || p_flag_apontam_form || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nível hierárquico é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 OR to_number(p_ordem) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível hierárquico inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE upper(nome) = upper(p_nome)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de papel já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_papel.nextval
    INTO v_papel_id
    FROM dual;
  --
  INSERT INTO papel
   (papel_id,
    empresa_id,
    area_id,
    nome,
    ordem,
    flag_ender,
    flag_auto_ender,
    flag_auto_ender_ctr,
    flag_auto_ender_oport,
    flag_apontam_form,
    flag_notif_ender)
  VALUES
   (v_papel_id,
    p_empresa_id,
    p_area_id,
    p_nome,
    to_number(p_ordem),
    p_flag_ender,
    p_flag_auto_ender,
    p_flag_auto_ender_ctr,
    p_flag_auto_ender_oport,
    p_flag_apontam_form,
    p_flag_notif_ender);
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- processa os vetores
  ------------------------------------------------------------
  vetores_processar(p_usuario_sessao_id,
                    p_empresa_id,
                    v_papel_id,
                    v_delimitador,
                    p_vetor_tipo_pessoa_id_v_geral,
                    p_vetor_tipo_pessoa_id_v_somen,
                    p_flag_tipo_pessoa_v_todos,
                    p_vetor_tipo_pessoa_id_c_geral,
                    p_vetor_tipo_pessoa_id_c_somen,
                    p_flag_tipo_pessoa_c_todos,
                    p_vetor_configurar_priv_id,
                    p_vetor_oportun_priv_id,
                    p_vetor_oportunend_priv_id,
                    p_vetor_oportunend_abrang,
                    p_vetor_contrato_priv_id,
                    p_vetor_contratoend_priv_id,
                    p_vetor_contratoend_abrang,
                    p_vetor_job_priv_id,
                    p_vetor_jobend_priv_id,
                    p_vetor_jobend_abrang,
                    p_vetor_orcend_priv_id,
                    p_vetor_orcend_abrang,
                    p_vetor_tipo_job_id,
                    p_vetor_tipo_financeiro_id,
                    p_vetor_enderecar_area_id,
                    p_vetor_enderecar_abrang,
                    p_vetor_entrega_priv_id,
                    p_vetor_entrega_tipo_os_id,
                    p_vetor_entrega_abrang,
                    p_vetor_monitorar_priv_id,
                    p_vetor_analisar_priv_id,
                    p_vetor_docum_priv_id,
                    p_vetor_docum_tipo_doc_id,
                    p_vetor_docum_abrang,
                    p_vetor_apontam_priv_id,
                    p_vetor_navegacao_priv_id,
                    p_vetor_painel_id,
                    p_painel_pdr_id,
                    p_vetor_oportunender_area_id, --ALCBO_241023
                    p_vetor_oportunender_abrang,
                    p_vetor_contratoender_area_id,
                    p_vetor_contratoender_abrang,
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
  papel_pkg.xml_gerar(v_papel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAPEL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_papel_id,
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
 END adicionar;
 --
 --
 PROCEDURE atualizar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: atualiza um registro em PAPEL, apos consistencia
  --  dos dados de entrada.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2007  Inclusao de parametros: flags de apontamento
  -- Silvia            11/04/2008  Novo parametro p/ vetor de tipo de documento
  -- Silvia            04/02/2011  Novos parametros area_id e vetor_painel.
  -- Silvia            28/10/2011  Novo parametro flag_auto_ender.
  -- Silvia            24/07/2012  Novo parametro vetor_tos (tipo de OS).
  -- Silvia            26/02/2013  Novo parametro tela_inicial.
  -- Silvia            06/03/2013  Novo parametro vetor_tos_painel (tipo de OS p/ painel)
  -- Silvia            20/05/2013  Retirada do parametro flag_apontam_cron
  -- Silvia            10/03/2015  Novos parametros (inbox_id, vetores $ hora)
  -- Silvia            05/05/2015  Novo parametro vetor_area
  -- Silvia            21/12/2015  Novo parametro vetor_tjob (tipo de job)
  -- Silvia            27/05/2016  Encriptacao de valores
  -- Silvia            01/06/2016  Novo parametro vetor_tfin (tipo financeiro)
  -- Silvia            21/07/2016  Associacao/desassociacao automatica de usuario_painel
  -- Silvia            21/10/2016  Reestruturacao dos vetores / abrangencia
  -- Silvia            16/03/2017  Separacao de paineis em Analisar e Monitorar
  -- Silvia            17/05/2017  Novo paramento flag_notif_ender
  -- Silvia            17/08/2017  Novo parametro flag_restringe_ender
  -- Silvia            27/02/2019  Novos vetores para Oportunidade e flag_auto_ender_oport
  -- Silvia            07/08/2019  Novo flag_auto_ender_ctr
  -- Silvia            03/03/2020  Eliminacao de painel (dashboard)
  -- Silvia            24/04/2020  Retirada do parametro flag_restringe_ender
  -- Silvia            28/04/2020  Eliminacao de inbox
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  -- Silvia            26/08/2021  Novo vetor para paineis associados ao papel
  -- Ana Luiza         24/10/2023  Criado novos grupos para ser endereçado por papel
  -- Joel Dias         06/11/2023  Inclusão do flag_ativo
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id            IN usuario.usuario_id%TYPE,
  p_empresa_id                   IN empresa.empresa_id%TYPE,
  p_papel_id                     IN papel.papel_id%TYPE,
  p_area_id                      IN papel.area_id%TYPE,
  p_nome                         IN papel.nome%TYPE,
  p_flag_ender                   IN papel.flag_ender%TYPE,
  p_flag_auto_ender              IN papel.flag_auto_ender%TYPE,
  p_flag_auto_ender_ctr          IN papel.flag_auto_ender_ctr%TYPE,
  p_flag_auto_ender_oport        IN papel.flag_auto_ender_oport%TYPE,
  p_flag_notif_ender             IN papel.flag_notif_ender%TYPE,
  p_flag_apontam_form            IN papel.flag_apontam_form%TYPE,
  p_flag_ativo                   IN papel.flag_ativo%TYPE,
  p_ordem                        IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_v_somen IN VARCHAR2,
  p_flag_tipo_pessoa_v_todos     IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_geral IN VARCHAR2,
  p_vetor_tipo_pessoa_id_c_somen IN VARCHAR2,
  p_flag_tipo_pessoa_c_todos     IN VARCHAR2,
  p_vetor_configurar_priv_id     IN VARCHAR2,
  p_vetor_oportun_priv_id        IN VARCHAR2,
  p_vetor_oportunend_priv_id     IN VARCHAR2,
  p_vetor_oportunend_abrang      IN VARCHAR2,
  p_vetor_contrato_priv_id       IN VARCHAR2,
  p_vetor_contratoend_priv_id    IN VARCHAR2,
  p_vetor_contratoend_abrang     IN VARCHAR2,
  p_vetor_job_priv_id            IN VARCHAR2,
  p_vetor_jobend_priv_id         IN VARCHAR2,
  p_vetor_jobend_abrang          IN VARCHAR2,
  p_vetor_orcend_priv_id         IN VARCHAR2,
  p_vetor_orcend_abrang          IN VARCHAR2,
  p_vetor_tipo_job_id            IN VARCHAR2,
  p_vetor_tipo_financeiro_id     IN VARCHAR2,
  p_vetor_enderecar_area_id      IN VARCHAR2,
  p_vetor_enderecar_abrang       IN VARCHAR2,
  p_vetor_entrega_priv_id        IN VARCHAR2,
  p_vetor_entrega_tipo_os_id     IN VARCHAR2,
  p_vetor_entrega_abrang         IN VARCHAR2,
  p_vetor_monitorar_priv_id      IN VARCHAR2,
  p_vetor_analisar_priv_id       IN VARCHAR2,
  p_vetor_docum_priv_id          IN VARCHAR2,
  p_vetor_docum_tipo_doc_id      IN VARCHAR2,
  p_vetor_docum_abrang           IN VARCHAR2,
  p_vetor_apontam_priv_id        IN VARCHAR2,
  p_vetor_navegacao_priv_id      IN VARCHAR2,
  p_vetor_painel_id              IN VARCHAR2,
  p_painel_pdr_id                IN VARCHAR2,
  p_vetor_oportunender_area_id   IN VARCHAR2, --ALCBO_241023
  p_vetor_oportunender_abrang    IN VARCHAR2,
  p_vetor_contratoender_area_id  IN VARCHAR2,
  p_vetor_contratoender_abrang   IN VARCHAR2,
  p_erro_cod                     OUT VARCHAR2,
  p_erro_msg                     OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_delimitador    CHAR(1);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_antes      CLOB;
  v_xml_atual      CLOB;
  --
  -- usuarios afetados pela alteracao do papel
  CURSOR c_us IS
   SELECT DISTINCT usuario_id
     FROM usuario_papel
    WHERE papel_id = p_papel_id;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAPEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF nvl(p_area_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da área é obrigatório.';
   RAISE v_exception;
  END IF;
  --
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
  --
  IF rtrim(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nome é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do papel não pode ter mais que 100 caracteres (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de endereçamento inválido (' || p_flag_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em job inválido (' || p_flag_auto_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender_ctr) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em contrato inválido (' || p_flag_auto_ender_ctr || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_auto_ender_oport) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de auto endereçamento em oportunidade inválido (' ||
                 p_flag_auto_ender_oport || ').';
   RAISE v_exception;
  END IF;
  --
  IF p_flag_auto_ender = 'S' AND p_flag_ender = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas papéis endereçáveis podem ser marcados para endereçamento automático.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_notif_ender) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de notificar endereçamento inválido (' || p_flag_notif_ender || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_apontam_form) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag de apontamento via formulário inválido (' || p_flag_apontam_form || ').';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido (' || p_flag_ativo || ').';
   RAISE v_exception;
  END IF;
  --
  IF rtrim(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do nível hierárquico é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 OR to_number(p_ordem) > 99999 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Nível hierárquico inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE upper(nome) = upper(p_nome)
     AND papel_id <> p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de papel já existe.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  papel_pkg.xml_gerar(p_papel_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE papel
     SET nome                  = p_nome,
         ordem                 = to_number(p_ordem),
         area_id               = p_area_id,
         flag_ender            = p_flag_ender,
         flag_auto_ender       = p_flag_auto_ender,
         flag_auto_ender_ctr   = p_flag_auto_ender_ctr,
         flag_auto_ender_oport = p_flag_auto_ender_oport,
         flag_apontam_form     = p_flag_apontam_form,
         flag_notif_ender      = p_flag_notif_ender,
         flag_ativo            = p_flag_ativo
   WHERE papel_id = p_papel_id;
  --
  v_delimitador := '|';
  --
  ------------------------------------------------------------
  -- processa os vetores
  ------------------------------------------------------------
  vetores_processar(p_usuario_sessao_id,
                    p_empresa_id,
                    p_papel_id,
                    v_delimitador,
                    p_vetor_tipo_pessoa_id_v_geral,
                    p_vetor_tipo_pessoa_id_v_somen,
                    p_flag_tipo_pessoa_v_todos,
                    p_vetor_tipo_pessoa_id_c_geral,
                    p_vetor_tipo_pessoa_id_c_somen,
                    p_flag_tipo_pessoa_c_todos,
                    p_vetor_configurar_priv_id,
                    p_vetor_oportun_priv_id,
                    p_vetor_oportunend_priv_id,
                    p_vetor_oportunend_abrang,
                    p_vetor_contrato_priv_id,
                    p_vetor_contratoend_priv_id,
                    p_vetor_contratoend_abrang,
                    p_vetor_job_priv_id,
                    p_vetor_jobend_priv_id,
                    p_vetor_jobend_abrang,
                    p_vetor_orcend_priv_id,
                    p_vetor_orcend_abrang,
                    p_vetor_tipo_job_id,
                    p_vetor_tipo_financeiro_id,
                    p_vetor_enderecar_area_id,
                    p_vetor_enderecar_abrang,
                    p_vetor_entrega_priv_id,
                    p_vetor_entrega_tipo_os_id,
                    p_vetor_entrega_abrang,
                    p_vetor_monitorar_priv_id,
                    p_vetor_analisar_priv_id,
                    p_vetor_docum_priv_id,
                    p_vetor_docum_tipo_doc_id,
                    p_vetor_docum_abrang,
                    p_vetor_apontam_priv_id,
                    p_vetor_navegacao_priv_id,
                    p_vetor_painel_id,
                    p_painel_pdr_id,
                    p_vetor_oportunender_area_id, --ALCBO_241023
                    p_vetor_oportunender_abrang,
                    p_vetor_contratoender_area_id,
                    p_vetor_contratoender_abrang,
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
  papel_pkg.xml_gerar(p_papel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAPEL',
                   'ALTERAR',
                   v_identif_objeto,
                   p_papel_id,
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
 END atualizar;
 --
 --
 PROCEDURE excluir
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 06/10/2004
  -- DESCRICAO: exclui um registro de PAPEL.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            07/02/2007  Consistencia de apontamentos
  -- Silvia            09/04/2008  Nova tabela "papel_priv_tdoc"
  -- Silvia            15/10/2008  Consistencia de "notifica_papel"
  -- Silvia            24/07/2012  Exclusao de papel_priv_tos
  -- Silvia            12/12/2013  Exclusao de faixa_aprov_papel
  -- Silvia            04/03/2015  Exclusao de papel_nivel
  -- Silvia            05/05/2015  Nova tabela "papel_priv_area"
  -- Silvia            28/05/2015  Novas tabelas de regras de coenderecamento
  -- Silvia            21/12/2015  Nova tabela papel_priv_tjob
  -- Silvia            01/06/2016  Nova tabela papel_priv_tfin
  -- Silvia            18/10/2016  Consistencia de  "orcam_usuario"
  -- Silvia            26/10/2018  Consistencia de item_crono_dest e mod_item_crono_dest
  -- Silvia            11/03/2019  Consistencia de Oportunidade
  -- Silvia            30/09/2019  Eliminacao de job_usuario_papel
  -- Silvia            19/11/2019  Consistencia de item_crono (papel_resp_id)
  -- Silvia            06/12/2019  Eliminacao de oport_usuario_papel e contrato_usuario_papel
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  -- Silvia            01/06/2022  Consistencia de orcam_aprov
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_exception      EXCEPTION;
  v_nome           papel.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_lbl_jobs       VARCHAR2(100);
  v_xml_atual      CLOB;
  --
 BEGIN
  --
  v_lbl_jobs := empresa_pkg.parametro_retornar(p_empresa_id, 'LABEL_JOB_PLURAL');
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAPEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_nome IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse papel não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM usuario_papel
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem usuários associados a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM documento
   WHERE papel_resp_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem documentos associados a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM apontam_hora
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem apontamentos associados a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM orcam_fluxo_aprov
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem aprovações de estimativa de custos associadas a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM milestone
   WHERE papel_resp_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem milestones associados a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM task
   WHERE papel_resp_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem tasks associadas a esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM carta_fluxo_aprov
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de fluxo de aprovação de orçamento que fazem uso desse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_fluxo_aprov
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem regras de fluxo de aprovação de Workflow que fazem uso desse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono_dest
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem atividades de Cronograma endereçadas para esse papel.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM item_crono
   WHERE papel_resp_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem atividades de Cronograma endereçadas para esse papel (responsável).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono
   WHERE papel_resp_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem atividades de modelos de Cronograma endereçadas para esse papel (responsável).';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM mod_item_crono_dest
   WHERE papel_id = p_papel_id
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Existem atividades de modelos de Cronograma endereçadas para esse papel (destinatário).';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  papel_pkg.xml_gerar(p_papel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM papel_priv_tpessoa
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tdoc
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tos
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_area
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tjob
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv_tfin
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_priv
   WHERE papel_id = p_papel_id;
  DELETE FROM faixa_aprov_papel
   WHERE papel_id = p_papel_id;
  DELETE FROM notifica_papel
   WHERE papel_id = p_papel_id;
  DELETE FROM papel_painel
   WHERE papel_id = p_papel_id;
  DELETE FROM papel
   WHERE papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAPEL',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_papel_id,
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
 END excluir;
 --
 --
 PROCEDURE copiar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 16/05/2013
  -- DESCRICAO: cria um novo papel a partir de outro.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            04/03/2015  Copia papel_nivel, papel.inbox_id
  -- Silvia            05/05/2015  Nova tabela "papel_priv_area"
  -- Silvia            22/12/2015  Nova tabela papel_priv_tjob
  -- Silvia            01/06/2016  Nova tabela papel_priv_tfin
  -- Silvia            03/03/2020  Eliminacao de painel (dashboard)
  -- Silvia            24/04/2020  Retirada do parametro flag_restringe_ender
  -- Silvia            10/06/2020  Eliminacao de papel_nivel
  -- Rafael            17/03/2025  Inclusao da Aba (Dashboard - Painel)
  ------------------------------------------------------------------------------------------
  p_usuario_sessao_id IN usuario.usuario_id%TYPE,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_papel_id          IN papel.papel_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) AS
  v_qt             INTEGER;
  v_papel_id       papel.papel_id%TYPE;
  v_nome           VARCHAR2(200);
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  -- verifica se o usuario tem privilegio
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, 'PAPEL_C', NULL, NULL, p_empresa_id) <> 1 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE papel_id = p_papel_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa papel não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT nome
    INTO v_nome
    FROM papel
   WHERE papel_id = p_papel_id;
  --
  v_nome := v_nome || ' - cópia';
  --
  IF length(v_nome) > 100 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O nome do papel não pode ter mais que 100 caracteres.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM papel
   WHERE upper(nome) = upper(v_nome)
     AND empresa_id = p_empresa_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de papel já existe (' || v_nome || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_papel.nextval
    INTO v_papel_id
    FROM dual;
  --
  INSERT INTO papel
   (papel_id,
    empresa_id,
    area_id,
    nome,
    ordem,
    flag_ender,
    flag_apontam_form,
    flag_auto_ender,
    flag_auto_ender_ctr,
    flag_auto_ender_oport,
    flag_notif_ender)
   SELECT v_papel_id,
          empresa_id,
          area_id,
          v_nome,
          ordem,
          flag_ender,
          flag_apontam_form,
          flag_auto_ender,
          flag_auto_ender_ctr,
          flag_auto_ender_oport,
          flag_notif_ender
     FROM papel
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv
   (papel_id,
    privilegio_id,
    abrangencia)
   SELECT v_papel_id,
          privilegio_id,
          abrangencia
     FROM papel_priv
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_tpessoa
   (papel_id,
    privilegio_id,
    tipo_pessoa_id,
    abrangencia)
   SELECT v_papel_id,
          privilegio_id,
          tipo_pessoa_id,
          abrangencia
     FROM papel_priv_tpessoa
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_tdoc
   (papel_id,
    privilegio_id,
    tipo_documento_id,
    abrangencia)
   SELECT v_papel_id,
          privilegio_id,
          tipo_documento_id,
          abrangencia
     FROM papel_priv_tdoc
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_tos
   (papel_id,
    privilegio_id,
    tipo_os_id,
    abrangencia)
   SELECT v_papel_id,
          privilegio_id,
          tipo_os_id,
          abrangencia
     FROM papel_priv_tos
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_area
   (papel_id,
    privilegio_id,
    area_id,
    abrangencia)
   SELECT v_papel_id,
          privilegio_id,
          area_id,
          abrangencia
     FROM papel_priv_area
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_tjob
   (papel_id,
    privilegio_id,
    tipo_job_id)
   SELECT v_papel_id,
          privilegio_id,
          tipo_job_id
     FROM papel_priv_tjob
    WHERE papel_id = p_papel_id;
  --
  INSERT INTO papel_priv_tfin
   (papel_id,
    privilegio_id,
    tipo_financeiro_id)
   SELECT v_papel_id,
          privilegio_id,
          tipo_financeiro_id
     FROM papel_priv_tfin
    WHERE papel_id = p_papel_id;
  --
  -- RP - 17032025
  INSERT INTO papel_painel
   (papel_id,
    painel_id,
    flag_padrao)
   SELECT v_papel_id,
          painel_id,
          flag_padrao
     FROM papel_painel
    WHERE papel_id = p_papel_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  papel_pkg.xml_gerar(v_papel_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_nome;
  v_compl_histor   := 'Cópia';
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'PAPEL',
                   'INCLUIR',
                   v_identif_objeto,
                   v_papel_id,
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
 END copiar;
 --
 --
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/01/2017
  -- DESCRICAO: Subrotina que gera o xml do papel para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            17/05/2017  Novo atributo flag_notif_ender
  -- Silvia            17/08/2017  Novo atributo flag_restringe_ender
  ------------------------------------------------------------------------------------------
 (
  p_papel_id IN papel.papel_id%TYPE,
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
  CURSOR c_p1 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ti.nome AS tipo_pessoa,
          decode(pt.abrangencia, 'T', 'Total', 'P', 'Parcial') AS abrang_sec
     FROM papel_priv         pp,
          privilegio         pr,
          papel_priv_tpessoa pt,
          tipo_pessoa        ti
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo LIKE 'PESSOA%'
      AND pp.abrangencia <> 'T'
      AND pp.papel_id = pt.papel_id
      AND pp.privilegio_id = pt.privilegio_id
      AND pt.tipo_pessoa_id = ti.tipo_pessoa_id
   UNION
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          'Todas',
          'Total'
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.codigo LIKE 'PESSOA%'
      AND pp.abrangencia = 'T'
    ORDER BY 1;
  --
  CURSOR c_p2 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'ADMIN'
      AND pr.codigo NOT LIKE 'PESSOA%'
    ORDER BY 1;
  --
  CURSOR c_p3 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'CONTRATO'
    ORDER BY 1;
  --
  CURSOR c_p4 IS
   SELECT pr.nome,
          pr.codigo,
          decode(pp.abrangencia, 'T', 'Total', 'P', 'Ender Contrato') AS abrang
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'CONTRATOEND'
    ORDER BY 1;
  --
  CURSOR c_p5 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'JOB'
    ORDER BY 1;
  --
  CURSOR c_p6 IS
   SELECT pr.nome,
          pr.codigo,
          decode(pp.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'JOBEND'
    ORDER BY 1;
  --
  CURSOR c_p7 IS
   SELECT pr.nome,
          pr.codigo,
          decode(pp.abrangencia, 'T', 'Total', 'P', 'Ender Job', 'O', 'Ender Estim') AS abrang
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'ORCEND'
    ORDER BY 1;
  --
  CURSOR c_p8 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ti.nome        AS tipo_job
     FROM papel_priv      pp,
          privilegio      pr,
          papel_priv_tjob pt,
          tipo_job        ti
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pp.papel_id = pt.papel_id
      AND pp.privilegio_id = pt.privilegio_id
      AND pt.tipo_job_id = ti.tipo_job_id
    ORDER BY 1;
  --
  CURSOR c_p9 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ti.nome        AS tipo_finan
     FROM papel_priv      pp,
          privilegio      pr,
          papel_priv_tfin pt,
          tipo_financeiro ti
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pp.papel_id = pt.papel_id
      AND pp.privilegio_id = pt.privilegio_id
      AND pt.tipo_financeiro_id = ti.tipo_financeiro_id
    ORDER BY 1;
  --
  CURSOR c_p10 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ar.nome AS area,
          decode(pa.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang_sec
     FROM papel_priv      pp,
          privilegio      pr,
          papel_priv_area pa,
          area            ar
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pp.papel_id = pa.papel_id
      AND pp.privilegio_id = pa.privilegio_id
      AND pa.area_id = ar.area_id
    ORDER BY 1;
  --
  CURSOR c_p11 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ti.nome AS tipo_os,
          decode(pt.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang_sec
     FROM papel_priv     pp,
          privilegio     pr,
          papel_priv_tos pt,
          tipo_os        ti
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pp.papel_id = pt.papel_id
      AND pp.privilegio_id = pt.privilegio_id
      AND pt.tipo_os_id = ti.tipo_os_id
    ORDER BY 1;
  --
  CURSOR c_p12 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'MONITORAR'
    ORDER BY 1;
  --
  CURSOR c_p13 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'ANALISAR'
    ORDER BY 1;
  --
  CURSOR c_p14 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia AS abrang_prim,
          ti.nome AS tipo_doc,
          decode(pt.abrangencia, 'T', 'Total', 'P', 'Ender Job') AS abrang_sec
     FROM papel_priv      pp,
          privilegio      pr,
          papel_priv_tdoc pt,
          tipo_documento  ti
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pp.papel_id = pt.papel_id
      AND pp.privilegio_id = pt.privilegio_id
      AND pt.tipo_documento_id = ti.tipo_documento_id
    ORDER BY 1;
  --
  CURSOR c_p15 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'APONTAM'
    ORDER BY 1;
  --
  CURSOR c_p16 IS
   SELECT pr.nome,
          pr.codigo,
          pp.abrangencia
     FROM papel_priv pp,
          privilegio pr
    WHERE pp.papel_id = p_papel_id
      AND pp.privilegio_id = pr.privilegio_id
      AND pr.grupo = 'NAVEGACAO'
    ORDER BY 1;
  --
  CURSOR c_p17 IS
   SELECT pa.nome AS painel,
          pp.flag_padrao
     FROM papel_painel pp,
          painel       pa
    WHERE pp.papel_id = p_papel_id
      AND pp.painel_id = pa.painel_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("papel_id", pa.papel_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", pa.nome),
                   xmlelement("area", ar.nome),
                   xmlelement("ordem", to_char(pa.ordem)),
                   xmlelement("enderecavel", pa.flag_ender),
                   xmlelement("auto_ender", pa.flag_auto_ender),
                   xmlelement("auto_ender_oport", pa.flag_auto_ender_oport),
                   xmlelement("auto_ender_ctr", pa.flag_auto_ender_ctr),
                   xmlelement("notifica_ender", pa.flag_notif_ender),
                   xmlelement("apontam_horas", pa.flag_apontam_form))
    INTO v_xml
    FROM papel pa,
         area  ar
   WHERE pa.papel_id = p_papel_id
     AND pa.area_id = ar.area_id;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO PESSOA
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p1 IN c_p1
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p1.codigo),
                            xmlelement("priv_nome", r_p1.nome),
                            xmlelement("tipo_pessoa", r_p1.tipo_pessoa),
                            xmlelement("abrang", r_p1.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_tipo_pessoa", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de ADMIN
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p2 IN c_p2
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p2.codigo),
                            xmlelement("priv_nome", r_p2.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_admin", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de CONTRATO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p3 IN c_p3
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p3.codigo),
                            xmlelement("priv_nome", r_p3.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_contrato", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de CONTRATO END
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p4 IN c_p4
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p4.codigo),
                            xmlelement("priv_nome", r_p4.nome),
                            xmlelement("abrang", r_p4.abrang)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_contrato_end", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de JOB
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p5 IN c_p5
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p5.codigo),
                            xmlelement("priv_nome", r_p5.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_job", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de JOB END
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p6 IN c_p6
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p6.codigo),
                            xmlelement("priv_nome", r_p6.nome),
                            xmlelement("abrang", r_p6.abrang)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_job_end", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de ESTIMATIVA END
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p7 IN c_p7
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p7.codigo),
                            xmlelement("priv_nome", r_p7.nome),
                            xmlelement("abrang", r_p7.abrang)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_estim_end", v_xml_aux1))
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
  FOR r_p8 IN c_p8
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p8.codigo),
                            xmlelement("priv_nome", r_p8.nome),
                            xmlelement("tipo_job", r_p8.tipo_job)))
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
  -- monta privilegios de TIPO FINANCEIRO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p9 IN c_p9
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p9.codigo),
                            xmlelement("priv_nome", r_p9.nome),
                            xmlelement("tipo_financeiro", r_p9.tipo_finan)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_indicar_tipo_finan", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de enderecar AREA
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p10 IN c_p10
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p10.codigo),
                            xmlelement("priv_nome", r_p10.nome),
                            xmlelement("area", r_p10.area),
                            xmlelement("abrang", r_p10.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_ender_area", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO OS
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p11 IN c_p11
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p11.codigo),
                            xmlelement("priv_nome", r_p11.nome),
                            xmlelement("tipo_os", r_p11.tipo_os),
                            xmlelement("abrang", r_p11.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_tipo_os", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de MONITORAR
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p12 IN c_p12
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p12.codigo),
                            xmlelement("priv_nome", r_p12.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_monitorar", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de ANALISAR
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p13 IN c_p13
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p13.codigo),
                            xmlelement("priv_nome", r_p13.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_analisar", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO DOCUMENTO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p14 IN c_p14
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p14.codigo),
                            xmlelement("priv_nome", r_p14.nome),
                            xmlelement("tipo_documento", r_p14.tipo_doc),
                            xmlelement("abrang", r_p14.abrang_sec)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_tipo_docum", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de APONTAMENTO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p15 IN c_p15
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p15.codigo),
                            xmlelement("priv_nome", r_p15.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_apontam", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta privilegios de NAVEGACAO
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p16 IN c_p16
  LOOP
   SELECT xmlagg(xmlelement("priv",
                            xmlelement("priv_codigo", r_p16.codigo),
                            xmlelement("priv_nome", r_p16.nome)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("priv_navegacao", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- monta PAINEL associados
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_p17 IN c_p17
  LOOP
   SELECT xmlagg(xmlelement("painel",
                            xmlelement("nome", r_p17.painel),
                            xmlelement("padrao", r_p17.flag_padrao)))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("dashboards", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "papel"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("papel", v_xml))
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
END papel_pkg;

/
