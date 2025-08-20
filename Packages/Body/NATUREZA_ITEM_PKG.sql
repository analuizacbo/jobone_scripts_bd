--------------------------------------------------------
--  DDL for Package Body NATUREZA_ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NATUREZA_ITEM_PKG" IS
 --
 --
 PROCEDURE adicionar
 ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/09/2016
  -- DESCRICAO: Inclusão de natureza de item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2017  Novo parametro flag_vinc_ck_a
  -- Silvia            30/08/2017  Novo parametro tipo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id          IN NUMBER,
  p_empresa_id                 IN empresa.empresa_id%TYPE,
  p_nome                       IN VARCHAR2,
  p_ordem                      IN VARCHAR2,
  p_codigo                     IN VARCHAR2,
  p_tipo                       IN VARCHAR2,
  p_mod_calculo                IN VARCHAR2,
  p_valor_padrao               IN VARCHAR2,
  p_flag_inc_a                 IN VARCHAR2,
  p_flag_inc_b                 IN VARCHAR2,
  p_flag_inc_c                 IN VARCHAR2,
  p_flag_vinc_ck_a             IN VARCHAR2,
  p_vetor_natureza_item_inc_id IN VARCHAR2,
  p_erro_cod                   OUT VARCHAR2,
  p_erro_msg                   OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_natureza_item_id           natureza_item.natureza_item_id%TYPE;
  v_ordem                      natureza_item.ordem%TYPE;
  v_ordem_sis                  natureza_item.ordem%TYPE;
  v_ordem_inc                  natureza_item.ordem%TYPE;
  v_valor_padrao               natureza_item.valor_padrao%TYPE;
  v_delimitador                CHAR(1);
  v_vetor_natureza_item_inc_id VARCHAR2(1000);
  v_natureza_item_inc_id       natureza_item_inc.natureza_item_inc_id%TYPE;
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_desc_mod_calculo           VARCHAR2(200);
  v_exception                  EXCEPTION;
  v_flag_admin                 usuario.flag_admin%TYPE;
  v_xml_atual                  CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT nvl(MAX(flag_admin), 'N')
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 60 caracteres.';
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
  SELECT nvl(MAX(ordem), 0)
    INTO v_ordem_sis
    FROM natureza_item
   WHERE flag_sistema = 'S'
     AND empresa_id = p_empresa_id;
  --
  IF v_ordem <= v_ordem_sis THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas naturezas de item do sistema podem ter ordem menor ou igual a ' ||
                 to_char(v_ordem_sis) || '.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_codigo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do código é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo NOT IN ('HONOR', 'ENCARGO', 'CUSTO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo inválido (' || p_tipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mod_calculo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da modalidade de cálculo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_mod_calculo := util_pkg.desc_retornar('mod_calculo', p_mod_calculo);
  --
  IF v_desc_mod_calculo IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Modalidade de cálculo é inválida (' || p_mod_calculo || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_valor_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := v_desc_mod_calculo || ' inválido (' || p_valor_padrao || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_padrao := round(nvl(numero_converter(p_valor_padrao), 0), 6);
  --
  IF flag_validar(p_flag_inc_a) = 0 OR flag_validar(p_flag_inc_b) = 0 OR
     flag_validar(p_flag_inc_c) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag incidência sobre custos A, B, C inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_vinc_ck_a) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag vínculo com check-in de A inválido.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item
   WHERE empresa_id = p_empresa_id
     AND TRIM(upper(codigo)) = TRIM(upper(p_codigo));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse código de natureza de item já existe (' || p_codigo || ').';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item
   WHERE empresa_id = p_empresa_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome));
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de natureza de item já existe (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  SELECT seq_natureza_item.nextval
    INTO v_natureza_item_id
    FROM dual;
  --
  INSERT INTO natureza_item
   (natureza_item_id,
    empresa_id,
    codigo,
    nome,
    ordem,
    mod_calculo,
    valor_padrao,
    flag_inc_a,
    flag_inc_b,
    flag_inc_c,
    flag_vinc_ck_a,
    flag_sistema,
    flag_ativo,
    tipo)
  VALUES
   (v_natureza_item_id,
    p_empresa_id,
    TRIM(upper(p_codigo)),
    TRIM(p_nome),
    v_ordem,
    TRIM(p_mod_calculo),
    v_valor_padrao,
    p_flag_inc_a,
    p_flag_inc_b,
    p_flag_inc_c,
    p_flag_vinc_ck_a,
    'N',
    'S',
    TRIM(p_tipo));
  --
  ------------------------------------------------------------
  -- tratamento do vetor de incidencia
  ------------------------------------------------------------
  v_delimitador                := '|';
  v_vetor_natureza_item_inc_id := p_vetor_natureza_item_inc_id;
  --
  WHILE nvl(length(rtrim(v_vetor_natureza_item_inc_id)), 0) > 0
  LOOP
   v_natureza_item_inc_id := to_number(prox_valor_retornar(v_vetor_natureza_item_inc_id,
                                                           v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_inc_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não existe (' || to_char(v_natureza_item_inc_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(ordem, 0)
     INTO v_ordem_inc
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_inc_id;
   --
   IF v_ordem_inc >= v_ordem THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item (ordem: ' || to_char(v_ordem) ||
                  ') não pode incidir sobre outra de ordem maior (' || to_char(v_ordem_inc) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO natureza_item_inc
    (natureza_item_id,
     natureza_item_inc_id)
   VALUES
    (v_natureza_item_id,
     v_natureza_item_inc_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  natureza_item_pkg.xml_gerar(v_natureza_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(p_codigo) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NATUREZA_ITEM',
                   'INCLUIR',
                   v_identif_objeto,
                   v_natureza_item_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/09/2016
  -- DESCRICAO: Atualizacao de natureza de item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            26/06/2017  Novo parametro flag_vinc_ck_a
  -- Silvia            30/08/2017  Novo parametro tipo
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id          IN NUMBER,
  p_empresa_id                 IN empresa.empresa_id%TYPE,
  p_natureza_item_id           IN natureza_item.natureza_item_id%TYPE,
  p_nome                       IN VARCHAR2,
  p_ordem                      IN VARCHAR2,
  p_tipo                       IN VARCHAR2,
  p_flag_ativo                 IN VARCHAR2,
  p_mod_calculo                IN VARCHAR2,
  p_valor_padrao               IN VARCHAR2,
  p_flag_inc_a                 IN VARCHAR2,
  p_flag_inc_b                 IN VARCHAR2,
  p_flag_inc_c                 IN VARCHAR2,
  p_flag_vinc_ck_a             IN VARCHAR2,
  p_vetor_natureza_item_inc_id IN VARCHAR2,
  p_erro_cod                   OUT VARCHAR2,
  p_erro_msg                   OUT VARCHAR2
 ) IS
  v_qt                         INTEGER;
  v_codigo                     natureza_item.codigo%TYPE;
  v_ordem                      natureza_item.ordem%TYPE;
  v_ordem_old                  natureza_item.ordem%TYPE;
  v_ordem_sis                  natureza_item.ordem%TYPE;
  v_ordem_inc                  natureza_item.ordem%TYPE;
  v_flag_sistema               natureza_item.flag_sistema%TYPE;
  v_valor_padrao               natureza_item.valor_padrao%TYPE;
  v_delimitador                CHAR(1);
  v_vetor_natureza_item_inc_id VARCHAR2(1000);
  v_natureza_item_inc_id       natureza_item_inc.natureza_item_inc_id%TYPE;
  v_desc_mod_calculo           VARCHAR2(200);
  v_identif_objeto             historico.identif_objeto%TYPE;
  v_compl_histor               historico.complemento%TYPE;
  v_historico_id               historico.historico_id%TYPE;
  v_exception                  EXCEPTION;
  v_flag_admin                 usuario.flag_admin%TYPE;
  v_xml_antes                  CLOB;
  v_xml_atual                  CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT nvl(MAX(flag_admin), 'N')
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item
   WHERE natureza_item_id = p_natureza_item_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         flag_sistema,
         ordem
    INTO v_codigo,
         v_flag_sistema,
         v_ordem_old
    FROM natureza_item
   WHERE natureza_item_id = p_natureza_item_id;
  --
  ------------------------------------------------------------
  -- consistencia dos parametros de entrada
  ------------------------------------------------------------
  IF TRIM(p_nome) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da descrição é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF length(p_nome) > 60 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'A descrição não pode ter mais que 60 caracteres.';
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
  IF v_flag_sistema = 'S' AND v_ordem <> v_ordem_old THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Naturezas de item do sistema não podem ter a ordem alterada.';
   RAISE v_exception;
  END IF;
  --
  SELECT nvl(MAX(ordem), 0)
    INTO v_ordem_sis
    FROM natureza_item
   WHERE flag_sistema = 'S'
     AND empresa_id = p_empresa_id;
  --
  IF v_flag_sistema = 'N' AND v_ordem <= v_ordem_sis THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Apenas naturezas de item do sistema podem ter ordem menor ou igual a ' ||
                 to_char(v_ordem_sis) || '.';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_tipo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento do tipo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  IF p_tipo NOT IN ('HONOR', 'ENCARGO', 'CUSTO') THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Tipo inválido (' || p_tipo || ').';
   RAISE v_exception;
  END IF;
  --
  IF TRIM(p_mod_calculo) IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'O preenchimento da modalidade de cálculo é obrigatório.';
   RAISE v_exception;
  END IF;
  --
  v_desc_mod_calculo := util_pkg.desc_retornar('mod_calculo', p_mod_calculo);
  --
  IF v_desc_mod_calculo IS NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Modalidade de cálculo é inválida (' || p_mod_calculo || ').';
   RAISE v_exception;
  END IF;
  --
  IF numero_validar(p_valor_padrao) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := v_desc_mod_calculo || ' inválido (' || p_valor_padrao || ').';
   RAISE v_exception;
  END IF;
  --
  v_valor_padrao := round(nvl(numero_converter(p_valor_padrao), 0), 6);
  --
  IF flag_validar(p_flag_inc_a) = 0 OR flag_validar(p_flag_inc_b) = 0 OR
     flag_validar(p_flag_inc_c) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag incidência sobre custos A, B, C inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_vinc_ck_a) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag vínculo com check-in de A inválido.';
   RAISE v_exception;
  END IF;
  --
  IF flag_validar(p_flag_ativo) = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Flag ativo inválido.';
   RAISE v_exception;
  END IF;
  --
  IF v_flag_sistema = 'S' AND TRIM(p_vetor_natureza_item_inc_id) IS NOT NULL THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Naturezas de sistema não podem incidir sobre outras naturezas.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item
   WHERE empresa_id = p_empresa_id
     AND TRIM(upper(nome)) = TRIM(upper(p_nome))
     AND natureza_item_id <> p_natureza_item_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Esse nome de natureza de item já existe (' || p_nome || ').';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log antes da atualizacao
  ------------------------------------------------------------
  natureza_item_pkg.xml_gerar(p_natureza_item_id, v_xml_antes, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  UPDATE natureza_item
     SET nome           = TRIM(p_nome),
         ordem          = v_ordem,
         mod_calculo    = TRIM(p_mod_calculo),
         valor_padrao   = v_valor_padrao,
         flag_inc_a     = p_flag_inc_a,
         flag_inc_b     = p_flag_inc_b,
         flag_inc_c     = p_flag_inc_c,
         flag_vinc_ck_a = p_flag_vinc_ck_a,
         flag_ativo     = p_flag_ativo,
         tipo           = TRIM(p_tipo)
   WHERE natureza_item_id = p_natureza_item_id;
  --
  ------------------------------------------------------------
  -- tratamento do vetor de incidencia
  ------------------------------------------------------------
  DELETE FROM natureza_item_inc
   WHERE natureza_item_id = p_natureza_item_id;
  --
  v_delimitador                := '|';
  v_vetor_natureza_item_inc_id := p_vetor_natureza_item_inc_id;
  --
  WHILE nvl(length(rtrim(v_vetor_natureza_item_inc_id)), 0) > 0
  LOOP
   v_natureza_item_inc_id := to_number(prox_valor_retornar(v_vetor_natureza_item_inc_id,
                                                           v_delimitador));
   --
   SELECT COUNT(*)
     INTO v_qt
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_inc_id;
   --
   IF v_qt = 0 THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item não existe (' || to_char(v_natureza_item_inc_id) || ').';
    RAISE v_exception;
   END IF;
   --
   SELECT nvl(ordem, 0)
     INTO v_ordem_inc
     FROM natureza_item
    WHERE natureza_item_id = v_natureza_item_inc_id;
   --
   IF v_ordem_inc >= v_ordem THEN
    p_erro_cod := '90000';
    p_erro_msg := 'Essa natureza de item (ordem: ' || to_char(v_ordem) ||
                  ') não pode incidir sobre outra de ordem maior (' || to_char(v_ordem_inc) || ').';
    RAISE v_exception;
   END IF;
   --
   INSERT INTO natureza_item_inc
    (natureza_item_id,
     natureza_item_inc_id)
   VALUES
    (p_natureza_item_id,
     v_natureza_item_inc_id);
  END LOOP;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  natureza_item_pkg.xml_gerar(p_natureza_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_codigo) || ' - ' || TRIM(p_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NATUREZA_ITEM',
                   'ALTERAR',
                   v_identif_objeto,
                   p_natureza_item_id,
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
  -- DESENVOLVEDOR: Silvia            ProcessMind     DATA: 01/09/2016
  -- DESCRICAO: Exclusão de natureza de item.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
 (
  p_usuario_sessao_id IN NUMBER,
  p_empresa_id        IN empresa.empresa_id%TYPE,
  p_natureza_item_id  IN natureza_item.natureza_item_id%TYPE,
  p_erro_cod          OUT VARCHAR2,
  p_erro_msg          OUT VARCHAR2
 ) IS
  v_qt             INTEGER;
  v_codigo         natureza_item.codigo%TYPE;
  v_nome           natureza_item.nome%TYPE;
  v_flag_sistema   natureza_item.flag_sistema%TYPE;
  v_identif_objeto historico.identif_objeto%TYPE;
  v_compl_histor   historico.complemento%TYPE;
  v_historico_id   historico.historico_id%TYPE;
  v_cod_priv       privilegio.codigo%TYPE;
  v_exception      EXCEPTION;
  v_flag_admin     usuario.flag_admin%TYPE;
  v_xml_atual      CLOB;
  --
 BEGIN
  v_qt := 0;
  --
  ------------------------------------------------------------
  -- verificacao de seguranca
  ------------------------------------------------------------
  SELECT nvl(MAX(flag_admin), 'N')
    INTO v_flag_admin
    FROM usuario
   WHERE usuario_id = p_usuario_sessao_id;
  --
  IF v_flag_admin = 'N' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Você não tem privilégio para realizar essa operação.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item
   WHERE natureza_item_id = p_natureza_item_id
     AND empresa_id = p_empresa_id;
  --
  IF v_qt = 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de item não existe ou não pertence a essa empresa.';
   RAISE v_exception;
  END IF;
  --
  SELECT codigo,
         nome,
         flag_sistema
    INTO v_codigo,
         v_nome,
         v_flag_sistema
    FROM natureza_item
   WHERE natureza_item_id = p_natureza_item_id;
  --
  IF v_flag_sistema = 'S' THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Natureza do item de sistema não pode ser excluída.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- verificacao de integridade
  ------------------------------------------------------------
  SELECT COUNT(*)
    INTO v_qt
    FROM item it,
         job  jo
   WHERE it.job_id = jo.job_id
     AND jo.empresa_id = p_empresa_id
     AND natureza_item = v_codigo
     AND rownum = 1;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de item já está associada a itens do orçamento.';
   RAISE v_exception;
  END IF;
  --
  SELECT COUNT(*)
    INTO v_qt
    FROM natureza_item_inc
   WHERE natureza_item_inc_id = p_natureza_item_id;
  --
  IF v_qt > 0 THEN
   p_erro_cod := '90000';
   p_erro_msg := 'Essa natureza de item é usada no cálculo de outras naturezas.';
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- gera xml do log
  ------------------------------------------------------------
  natureza_item_pkg.xml_gerar(p_natureza_item_id, v_xml_atual, p_erro_cod, p_erro_msg);
  --
  IF p_erro_cod <> '00000' THEN
   RAISE v_exception;
  END IF;
  --
  ------------------------------------------------------------
  -- atualizacao do banco
  ------------------------------------------------------------
  DELETE FROM pessoa_nitem_pdr
   WHERE natureza_item_id = p_natureza_item_id;
  DELETE FROM orcam_nitem_pdr
   WHERE natureza_item_id = p_natureza_item_id;
  DELETE FROM job_nitem_pdr
   WHERE natureza_item_id = p_natureza_item_id;
  DELETE FROM contrato_nitem_pdr
   WHERE natureza_item_id = p_natureza_item_id;
  --
  DELETE FROM natureza_item_inc
   WHERE natureza_item_id = p_natureza_item_id;
  DELETE FROM natureza_item
   WHERE natureza_item_id = p_natureza_item_id;
  --
  ------------------------------------------------------------
  -- geracao de evento
  ------------------------------------------------------------
  v_identif_objeto := TRIM(v_codigo) || ' - ' || TRIM(v_nome);
  v_compl_histor   := NULL;
  --
  evento_pkg.gerar(p_usuario_sessao_id,
                   p_empresa_id,
                   'NATUREZA_ITEM',
                   'EXCLUIR',
                   v_identif_objeto,
                   p_natureza_item_id,
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
  -- DESENVOLVEDOR: Silvia               ProcessMind     DATA: 03/02/2017
  -- DESCRICAO: Subrotina que gera o xml de natureza do item para o historico.
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  -- Silvia            30/08/2017  Novo atributo tipo.
  ------------------------------------------------------------------------------------------
 (
  p_natureza_item_id IN natureza_item.natureza_item_id%TYPE,
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
  CURSOR c_nc IS
   SELECT ni.nome AS natureza_item_inc
     FROM natureza_item_inc nc,
          natureza_item     ni
    WHERE nc.natureza_item_id = p_natureza_item_id
      AND nc.natureza_item_inc_id = ni.natureza_item_id
    ORDER BY 1;
  --
 BEGIN
  v_qt      := 0;
  v_xml_doc := '<?xml version="1.0" encoding="ISO-8859-1" ?>';
  --
  ------------------------------------------------------------
  -- monta as informacoes gerais
  ------------------------------------------------------------
  SELECT xmlconcat(xmlelement("natureza_item_id", ni.natureza_item_id),
                   xmlelement("data_evento", data_hora_mostrar(SYSDATE)),
                   xmlelement("codigo", ni.codigo),
                   xmlelement("tipo", ni.tipo),
                   xmlelement("nome", ni.nome),
                   xmlelement("ativo", ni.flag_ativo),
                   xmlelement("do_sistema", ni.flag_sistema),
                   xmlelement("ordem", to_char(ni.ordem)),
                   xmlelement("modo_calculo",
                              util_pkg.desc_retornar('mod_calculo', ni.mod_calculo)),
                   xmlelement("valor_padrao", numero_mostrar(ni.valor_padrao, 6, 'N')),
                   xmlelement("indice_sobre_a", ni.flag_inc_a),
                   xmlelement("indice_sobre_b", ni.flag_inc_b),
                   xmlelement("indice_sobre_c", ni.flag_inc_c))
    INTO v_xml
    FROM natureza_item ni
   WHERE ni.natureza_item_id = p_natureza_item_id;
  --
  ------------------------------------------------------------
  -- monta privilegios de TIPO DOC
  ------------------------------------------------------------
  v_xml_aux1 := NULL;
  FOR r_nc IN c_nc
  LOOP
   SELECT xmlconcat(xmlelement("natureza", r_nc.natureza_item_inc))
     INTO v_xml_aux99
     FROM dual;
   --
   SELECT xmlconcat(v_xml_aux1, v_xml_aux99)
     INTO v_xml_aux1
     FROM dual;
  END LOOP;
  --
  SELECT xmlagg(xmlelement("incide_sobre", v_xml_aux1))
    INTO v_xml_aux1
    FROM dual;
  --
  SELECT xmlconcat(v_xml, v_xml_aux1)
    INTO v_xml
    FROM dual;
  --
  ------------------------------------------------------------
  -- junta tudo debaixo de "natureza_item"
  ------------------------------------------------------------
  SELECT xmlagg(xmlelement("natureza_item", v_xml))
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
 FUNCTION valor_padrao_retornar
 (
  ------------------------------------------------------------------------------------------
  -- DESENVOLVEDOR: Silvia        ProcessMind     DATA: 20/09/2016
  -- DESCRICAO: retorna o valor padrao (percentual ou indice) definido para determinado
  -- objeto (EMPRESA, JOB, ORCAMENTO, CONTRATO, PESSOA) e natureza do item (HONOR, ENCARGO,
  -- ENCARGO_HONOR, etc).
  --
  -- ALTERADO POR      DATA        MOTIVO ALTERACAO
  -- ----------------  ----------  ---------------------------------------------------------
  --
  ------------------------------------------------------------------------------------------
  p_cod_objeto    IN VARCHAR2,
  p_objeto_id     IN NUMBER,
  p_natureza_item IN VARCHAR2
 ) RETURN NUMBER AS
  v_qt         INTEGER;
  v_exception  EXCEPTION;
  v_empresa_id NUMBER;
  v_retorno    natureza_item.valor_padrao%TYPE;
  --
 BEGIN
  v_retorno := 0;
  --
  IF p_cod_objeto = 'EMPRESA' THEN
   v_empresa_id := p_objeto_id;
   --
   SELECT MAX(valor_padrao)
     INTO v_retorno
     FROM natureza_item
    WHERE empresa_id = v_empresa_id
      AND codigo = p_natureza_item;
   --
  ELSIF p_cod_objeto = 'JOB' THEN
   SELECT MAX(empresa_id)
     INTO v_empresa_id
     FROM job
    WHERE job_id = p_objeto_id;
   --
   SELECT MAX(jn.valor_padrao)
     INTO v_retorno
     FROM natureza_item na,
          job_nitem_pdr jn
    WHERE na.empresa_id = v_empresa_id
      AND na.codigo = p_natureza_item
      AND na.natureza_item_id = jn.natureza_item_id
      AND jn.job_id = p_objeto_id;
   --
  ELSIF p_cod_objeto = 'ORCAMENTO' THEN
   SELECT MAX(jo.empresa_id)
     INTO v_empresa_id
     FROM job       jo,
          orcamento oc
    WHERE oc.orcamento_id = p_objeto_id
      AND oc.job_id = jo.job_id;
   --
   SELECT MAX(oc.valor_padrao)
     INTO v_retorno
     FROM natureza_item   na,
          orcam_nitem_pdr oc
    WHERE na.empresa_id = v_empresa_id
      AND na.codigo = p_natureza_item
      AND na.natureza_item_id = oc.natureza_item_id
      AND oc.orcamento_id = p_objeto_id;
   --
  ELSIF p_cod_objeto = 'CONTRATO' THEN
   SELECT MAX(empresa_id)
     INTO v_empresa_id
     FROM contrato
    WHERE contrato_id = p_objeto_id;
   --
   SELECT MAX(cn.valor_padrao)
     INTO v_retorno
     FROM natureza_item      na,
          contrato_nitem_pdr cn
    WHERE na.empresa_id = v_empresa_id
      AND na.codigo = p_natureza_item
      AND na.natureza_item_id = cn.natureza_item_id
      AND cn.contrato_id = p_objeto_id;
   --
  ELSIF p_cod_objeto = 'PESSOA' THEN
   SELECT MAX(empresa_id)
     INTO v_empresa_id
     FROM pessoa
    WHERE pessoa_id = p_objeto_id;
   --
   SELECT MAX(pn.valor_padrao)
     INTO v_retorno
     FROM natureza_item    na,
          pessoa_nitem_pdr pn
    WHERE na.empresa_id = v_empresa_id
      AND na.codigo = p_natureza_item
      AND na.natureza_item_id = pn.natureza_item_id
      AND pn.pessoa_id = p_objeto_id;
   --
  END IF;
  --
  RETURN v_retorno;
 EXCEPTION
  WHEN OTHERS THEN
   v_retorno := 99999;
   RETURN v_retorno;
 END valor_padrao_retornar;
 --
--
END; -- NATUREZA_ITEM_PKG



/
