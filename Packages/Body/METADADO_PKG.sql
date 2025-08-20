--------------------------------------------------------
--  DDL for Package Body METADADO_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "METADADO_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/01/2013
  -- DESCRICAO: Inclusão de metadado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/05/2015  Novo metadado de Briefing por tipo de job.
  -- Silvia            31/08/2015  Novo tipo MULTICKBOX.
  -- Silvia            17/10/2016  Implementacao de condicao.
  -- Silvia            05/06/2019  Libera metadado com nome que já existe.
  -- Silvia            30/09/2022  Novo atributo privilegio_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_tipo_objeto       IN metadado.tipo_objeto%TYPE,
  p_objeto_id         IN metadado.objeto_id%TYPE,
  p_grupo             IN metadado.grupo%TYPE,
  p_nome              IN metadado.nome%TYPE,
  p_tipo_dado_id      IN metadado.tipo_dado_id%TYPE,
  p_privilegio_id     IN metadado.privilegio_id%TYPE,
  p_tamanho           IN VARCHAR2,
  p_flag_obrigatorio  IN VARCHAR2,
  p_flag_ao_lado      IN VARCHAR2,
  p_flag_na_lista     IN VARCHAR2,
  p_flag_ordenar      IN VARCHAR2,
  p_sufixo            IN VARCHAR2,
  p_instrucoes        IN VARCHAR2,
  p_valores           IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_metadado_cond_id  IN metadado.metadado_cond_id%TYPE,
  p_valor_cond        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_metadado_id      metadado.metadado_id%TYPE;
  v_ordem            metadado.ordem%TYPE;
  v_tamanho          metadado.tamanho%TYPE;
  v_nome_cond        metadado.nome%TYPE;
  v_tipo_objeto_cond metadado.tipo_objeto%TYPE;
  v_objeto_id_cond   metadado.objeto_id%TYPE;
  v_grupo_cond       metadado.tipo_objeto%TYPE;
  v_valores_cond     metadado.valores%TYPE;
  v_cod_dado         tipo_dado.codigo%TYPE;
  v_tam_max          tipo_dado.tam_max%TYPE;
  v_flag_tem_tam     tipo_dado.flag_tem_tam%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_cod_priv         privilegio.codigo%TYPE;
  v_exception        EXCEPTION;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  IF TRIM(p_tipo_objeto) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O tipo de objeto do metadado não foi especificado.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo_objeto) NOT IN ('TIPO_OS', 'TIPO_PRODUTO', 'TIPO_JOB') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo de objeto do metadado inválido (' || p_tipo_objeto || ').';
   RAISE v_exception;
  END IF;
  --
  v_cod_priv := TRIM(p_tipo_objeto) || '_C';
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, v_cod_priv, NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_grupo) IS NULL OR p_grupo NOT IN ('CORPO_OS', 'ITEM_OS', 'BRIEFING') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Grupo inválido (' || p_grupo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ordem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  --
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_dado_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de dado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_dado
   WHERE tipo_dado_id = p_tipo_dado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de dado não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nvl(tam_max, 0),
         flag_tem_tam
    INTO v_cod_dado,
         v_tam_max,
         v_flag_tem_tam
    FROM tipo_dado
   WHERE tipo_dado_id = p_tipo_dado_id;
  --
  IF inteiro_validar(p_tamanho) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho inválido.';
   RAISE v_exception;
  END IF;
  --
  -- tamanho especificado pelo usuario
  v_tamanho := nvl(to_number(p_tamanho), 0);
  --
  IF v_flag_tem_tam = 'N' AND v_tamanho > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho não deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_tam = 'S' AND v_tamanho = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_tam = 'S' AND v_tamanho > v_tam_max THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho não pode ser maior que ' ||
                 to_char(v_tam_max) || '.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_obrigatorio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag brigatório não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obrigatorio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigatório inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_ao_lado) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ao lado não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ao_lado) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ao lado inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_na_lista) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag na lista não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_na_lista) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag na lista inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_ordenar) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ordenar por este não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ordenar) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ordenar por este inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_sufixo) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O sufixo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instrucoes) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As instruções não podem ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_valores) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Os valores não pdem ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_dado IN ('LOV', 'MULTICKBOX', 'RADBUTTON') AND TRIM(p_valores) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado os valores devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_dado NOT IN ('LOV', 'MULTICKBOX', 'RADBUTTON') AND TRIM(p_valores) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado os valores não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF (nvl(p_metadado_cond_id, 0) = 0 AND TRIM(p_valor_cond) IS NOT NULL) OR
     (nvl(p_metadado_cond_id, 0) <> 0 AND TRIM(p_valor_cond) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A configuração da condição está incompleta.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_metadado_cond_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE empresa_id = p_empresa_id
      AND metadado_id = p_metadado_cond_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT tipo_objeto,
          objeto_id,
          grupo,
          valores,
          nome
     INTO v_tipo_objeto_cond,
          v_objeto_id_cond,
          v_grupo_cond,
          v_valores_cond,
          v_nome_cond
     FROM metadado
    WHERE metadado_id = p_metadado_cond_id;
   --
   IF p_tipo_objeto <> v_tipo_objeto_cond OR p_objeto_id <> v_objeto_id_cond OR
      p_grupo <> v_grupo_cond THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição não pertence a esse grupo de metadados.';
    RAISE v_exception;
   END IF;
   --
   IF instr(v_valores_cond, p_valor_cond) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse valor de condição não existe (' || v_nome_cond || ': ' || p_valor_cond || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM metadado
     WHERE empresa_id = p_empresa_id
       AND tipo_objeto = p_tipo_objeto
       AND objeto_id = p_objeto_id
       AND grupo = p_grupo
       AND UPPER(nome) = UPPER(TRIM(p_nome));
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Esse metadado já existe (' || p_nome || ').';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_ordenar = 'S' THEN
   -- desmarca a ordenacao dos outros (so pode ter um atributo para ordenacao)
   UPDATE metadado
      SET flag_ordenar = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_objeto = p_tipo_objeto
      AND objeto_id = p_objeto_id
      AND grupo = p_grupo;
  END IF;
  --
  SELECT seq_metadado.nextval
    INTO v_metadado_id
    FROM dual;
  --
  INSERT INTO metadado
   (metadado_id,
    empresa_id,
    tipo_objeto,
    objeto_id,
    grupo,
    nome,
    tipo_dado_id,
    privilegio_id,
    tamanho,
    flag_obrigatorio,
    sufixo,
    instrucoes,
    valores,
    ordem,
    flag_ativo,
    flag_ao_lado,
    flag_na_lista,
    flag_ordenar,
    metadado_cond_id,
    valor_cond)
  VALUES
   (v_metadado_id,
    p_empresa_id,
    p_tipo_objeto,
    p_objeto_id,
    TRIM(p_grupo),
    TRIM(p_nome),
    p_tipo_dado_id,
    zvl(p_privilegio_id, NULL),
    v_tamanho,
    p_flag_obrigatorio,
    TRIM(p_sufixo),
    TRIM(p_instrucoes),
    TRIM(p_valores),
    v_ordem,
    'S',
    p_flag_ao_lado,
    p_flag_na_lista,
    p_flag_ordenar,
    zvl(p_metadado_cond_id, NULL),
    TRIM(p_valor_cond));
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  metadado_pkg.xml_gerar(v_metadado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := p_tipo_objeto || ': ' || to_char(p_objeto_id) || ' - ' || p_grupo || ': ' ||
                      p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'METADADO',
                   'INCLUIR',
                   v_identif_objeto,
                   v_metadado_id,
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
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/01/2013
  -- DESCRICAO: Atualizacao de metadado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            31/08/2015  Novo tipo MULTICKBOX.
  -- Silvia            17/10/2016  Implementacao de condicao.
  -- Silvia            05/06/2019  Libera metadado com nome que já existe.
  -- Silvia            30/09/2022  Novo atributo privilegio_id
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_metadado_id       IN metadado.metadado_id%TYPE,
  p_nome              IN metadado.nome%TYPE,
  p_tipo_dado_id      IN metadado.tipo_dado_id%TYPE,
  p_privilegio_id     IN metadado.privilegio_id%TYPE,
  p_tamanho           IN VARCHAR2,
  p_flag_obrigatorio  IN VARCHAR2,
  p_flag_ao_lado      IN VARCHAR2,
  p_flag_na_lista     IN VARCHAR2,
  p_flag_ordenar      IN VARCHAR2,
  p_sufixo            IN VARCHAR2,
  p_instrucoes        IN VARCHAR2,
  p_valores           IN VARCHAR2,
  p_ordem             IN VARCHAR2,
  p_metadado_cond_id  IN metadado.metadado_cond_id%TYPE,
  p_valor_cond        IN VARCHAR2,
  p_flag_ativo        IN VARCHAR2,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt               INTEGER;
  v_tipo_objeto      metadado.tipo_objeto%TYPE;
  v_objeto_id        metadado.objeto_id%TYPE;
  v_ordem            metadado.ordem%TYPE;
  v_tamanho          metadado.tamanho%TYPE;
  v_grupo            metadado.grupo%TYPE;
  v_nome_cond        metadado.nome%TYPE;
  v_tipo_objeto_cond metadado.tipo_objeto%TYPE;
  v_objeto_id_cond   metadado.objeto_id%TYPE;
  v_grupo_cond       metadado.tipo_objeto%TYPE;
  v_valores_cond     metadado.valores%TYPE;
  v_cod_dado         tipo_dado.codigo%TYPE;
  v_tam_max          tipo_dado.tam_max%TYPE;
  v_flag_tem_tam     tipo_dado.flag_tem_tam%TYPE;
  v_identif_objeto   historico.identif_objeto%TYPE;
  v_compl_histor     historico.complemento%TYPE;
  v_historico_id     historico.historico_id%TYPE;
  v_cod_priv         privilegio.codigo%TYPE;
  v_exception        EXCEPTION;
  v_xml_antes        CLOB;
  v_xml_atual        CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM metadado
   WHERE metadado_id = p_metadado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_objeto,
         objeto_id,
         grupo
    INTO v_tipo_objeto,
         v_objeto_id,
         v_grupo
    FROM metadado
   WHERE metadado_id = p_metadado_id;
  --
  v_cod_priv := TRIM(v_tipo_objeto) || '_C';
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, v_cod_priv, NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_ordem) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da ordem é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF inteiro_validar(p_ordem) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Ordem inválida.';
   RAISE v_exception;
  END IF;
  --
  v_ordem := nvl(to_number(p_ordem), 0);
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_tipo_dado_id, 0) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo de dado é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM tipo_dado
   WHERE tipo_dado_id = p_tipo_dado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse tipo de dado não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nvl(tam_max, 0),
         flag_tem_tam
    INTO v_cod_dado,
         v_tam_max,
         v_flag_tem_tam
    FROM tipo_dado
   WHERE tipo_dado_id = p_tipo_dado_id;
  --
  IF inteiro_validar(p_tamanho) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tamanho inválido.';
   RAISE v_exception;
  END IF;
  --
  -- tamanho especificado pelo usuario
  v_tamanho := nvl(to_number(p_tamanho), 0);
  --
  IF v_flag_tem_tam = 'N' AND v_tamanho > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho não deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_tam = 'S' AND v_tamanho = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho deve ser especificado.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_tem_tam = 'S' AND v_tamanho > v_tam_max THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado, o tamanho não pode ser maior que ' ||
                 to_char(v_tam_max) || '.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_obrigatorio) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigatório não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_obrigatorio) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag obrigatório inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_ao_lado) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ao lado não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ao_lado) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ao lado inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_na_lista) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag na lista não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_na_lista) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag na lista inválido.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_flag_ordenar) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ordenar por este não informado.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ordenar) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ordenar por este inválido.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_sufixo) > 20 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O sufixo não pode ter mais que 20 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_instrucoes) > 500 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'As instruções não podem ter mais que 500 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_valores) > 4000 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Os valores não pdem ter mais que 4000 caracteres.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_dado IN ('LOV', 'MULTICKBOX', 'RADBUTTON') AND TRIM(p_valores) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado os valores devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF v_cod_dado NOT IN ('LOV', 'MULTICKBOX', 'RADBUTTON') AND TRIM(p_valores) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Para esse tipo de dado os valores não devem ser especificados.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF (nvl(p_metadado_cond_id, 0) = 0 AND TRIM(p_valor_cond) IS NOT NULL) OR
     (nvl(p_metadado_cond_id, 0) <> 0 AND TRIM(p_valor_cond) IS NULL) THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A configuração da condição está incompleta.';
   RAISE v_exception;
  END IF;
  --
  IF nvl(p_metadado_cond_id, 0) <> 0 THEN
   SELECT COUNT(*)
     INTO v_qt
     FROM metadado
    WHERE empresa_id = p_empresa_id
      AND metadado_id = p_metadado_cond_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição não existe ou não pertence a essa empresa.';
    RAISE v_exception;
   END IF;
   --
   SELECT tipo_objeto,
          objeto_id,
          grupo,
          valores,
          nome
     INTO v_tipo_objeto_cond,
          v_objeto_id_cond,
          v_grupo_cond,
          v_valores_cond,
          v_nome_cond
     FROM metadado
    WHERE metadado_id = p_metadado_cond_id;
   --
   IF v_tipo_objeto <> v_tipo_objeto_cond OR v_objeto_id <> v_objeto_id_cond OR
      v_grupo <> v_grupo_cond THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa condição não pertence a esse grupo de metadados.';
    RAISE v_exception;
   END IF;
   --
   IF instr(v_valores_cond, p_valor_cond) = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Esse valor de condição não existe (' || v_nome_cond || ': ' || p_valor_cond || ').';
    RAISE v_exception;
   END IF;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  /*
    SELECT COUNT(*)
      INTO v_qt
      FROM metadado
     WHERE empresa_id = p_empresa_id
       AND tipo_objeto = v_tipo_objeto
       AND objeto_id = v_objeto_id
       AND grupo = v_grupo
       AND UPPER(nome) = UPPER(TRIM(p_nome))
       AND metadado_id <> p_metadado_id;
  --
    IF v_qt > 0 THEN
       p_erro_cod := '90000';
       p_erro_msg := 'Esse metadado já existe (' || p_nome || ').';
       RAISE v_exception;
    END IF;
  */
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  metadado_pkg.xml_gerar(p_metadado_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  IF p_flag_ordenar = 'S' THEN
   -- desmarca a ordenacao dos outros (so pode ter um atributo para ordenacao)
   UPDATE metadado
      SET flag_ordenar = 'N'
    WHERE empresa_id = p_empresa_id
      AND tipo_objeto = v_tipo_objeto
      AND objeto_id = v_objeto_id
      AND grupo = v_grupo
      AND metadado_id <> p_metadado_id;
  END IF;
  --
  UPDATE metadado
     SET nome             = TRIM(p_nome),
         tipo_dado_id     = p_tipo_dado_id,
         privilegio_id    = zvl(p_privilegio_id, NULL),
         tamanho          = v_tamanho,
         flag_obrigatorio = p_flag_obrigatorio,
         sufixo           = TRIM(p_sufixo),
         instrucoes       = TRIM(p_instrucoes),
         valores          = TRIM(p_valores),
         ordem            = v_ordem,
         flag_ativo       = p_flag_ativo,
         flag_ao_lado     = p_flag_ao_lado,
         flag_na_lista    = p_flag_na_lista,
         flag_ordenar     = p_flag_ordenar,
         metadado_cond_id = zvl(p_metadado_cond_id, NULL),
         valor_cond       = TRIM(p_valor_cond)
   WHERE metadado_id = p_metadado_id;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  metadado_pkg.xml_gerar(p_metadado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_tipo_objeto || ': ' || to_char(v_objeto_id) || ' - ' || v_grupo || ': ' ||
                      p_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'METADADO',
                   'ALTERAR',
                   v_identif_objeto,
                   p_metadado_id,
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
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 29/01/2013
  -- DESCRICAO: Exclusão de metadado.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            13/05/2015  Novo metadado de Briefing por tipo de job.
  -- Silvia            17/10/2016  Implementacao de condicao.
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_metadado_id       IN metadado.metadado_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_tipo_objeto    metadado.tipo_objeto%TYPE;
  v_objeto_id      metadado.objeto_id%TYPE;
  v_grupo          metadado.grupo%TYPE;
  v_nome           metadado.nome%TYPE;
  v_nome_cond      metadado.nome%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_cod_priv       privilegio.codigo%TYPE;
  v_exception      EXCEPTION;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM metadado
   WHERE metadado_id = p_metadado_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado não existe.';
   RAISE v_exception;
  END IF;
  --
  SELECT tipo_objeto,
         objeto_id,
         grupo,
         nome
    INTO v_tipo_objeto,
         v_objeto_id,
         v_grupo,
         v_nome
    FROM metadado
   WHERE metadado_id = p_metadado_id;
  --
  v_cod_priv := TRIM(v_tipo_objeto) || '_C';
  --
  IF usuario_pkg.priv_verificar(p_usuario_sessao_id, v_cod_priv, NULL, NULL, p_empresa_id) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM os_atributo_valor
   WHERE metadado_id = p_metadado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado já está associado a Workflows.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM os_tp_atributo_valor
   WHERE metadado_id = p_metadado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado já está associado a itens de Workflows.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM brief_atributo_valor
   WHERE metadado_id = p_metadado_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado já está associado Briefing.';
   RAISE v_exception;
  END IF;
  --
  SELECT MAX(nome)
    INTO v_nome_cond
    FROM metadado
   WHERE metadado_cond_id = p_metadado_id;
  --
  IF v_nome_cond IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse metadado está sendo usado como condição para o metadado ' ||
                 v_nome_cond || '.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  metadado_pkg.xml_gerar(p_metadado_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM metadado
   WHERE metadado_id = p_metadado_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := v_tipo_objeto || ': ' || to_char(v_objeto_id) || ' - ' || v_grupo || ': ' ||
                      v_nome;
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'METADADO',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_metadado_id,
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
 PROCEDURE xml_gerar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 30/09/2022
  -- DESCRICAO: Subrotina que gera o xml do metadado para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_metadado_id IN metadado.metadado_id%TYPE,
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
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("metadado_id", me.metadado_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("nome", me.nome),
                   xmlelement("sufixo", me.sufixo),
                   xmlelement("ativo", me.flag_ativo),
                   xmlelement("tipo_dado", ti.nome),
                   xmlelement("grupo", me.grupo),
                   xmlelement("obrigatorio", me.flag_obrigatorio),
                   xmlelement("ordem", to_char(me.ordem)),
                   xmlelement("tamanho", to_char(me.tamanho)),
                   xmlelement("ao_lado", me.flag_ao_lado),
                   xmlelement("na_lista", me.flag_na_lista),
                   xmlelement("ordenar", me.flag_ordenar),
                   xmlelement("valores", me.valores),
                   xmlelement("instrucoes", me.instrucoes),
                   xmlelement("condicao", m2.nome),
                   xmlelement("valor_condicao", me.valor_cond),
                   xmlelement("privilegio", pr.nome))
    INTO v_xml
    FROM metadado   me,
         tipo_dado  ti,
         privilegio pr,
         metadado   m2
   WHERE me.metadado_id = p_metadado_id
     AND me.tipo_dado_id = ti.tipo_dado_id
     AND me.privilegio_id = pr.privilegio_id(+)
     AND me.metadado_cond_id = m2.metadado_id(+);
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "metadado"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("metadado", v_xml))
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
END; -- METADADO_PKG



/
